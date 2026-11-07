#import "NativeAudioProbe.h"
#import "Vendored/fishhook.h"

#import <AudioToolbox/AudioToolbox.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <os/lock.h>

#include <atomic>
#include <cmath>
#include <cstring>

// This is a deliberately passive counterpart to the Amazon Music + Timbre
// AUGraph callback adapter. It does not touch audio data or FairPlay keys.
// Only imports in our own app's non-Gecko images are eligible for rebinding.
namespace {
using GraphCallbackFn = OSStatus (*)(AUGraph, AUNode, UInt32, const AURenderCallbackStruct *);
using UnitPropertyFn = OSStatus (*)(AudioUnit, AudioUnitPropertyID, AudioUnitScope, AudioUnitElement, const void *, UInt32);

static GraphCallbackFn originalGraphCallback = &AUGraphSetNodeInputCallback;
static UnitPropertyFn originalUnitProperty = &AudioUnitSetProperty;
static std::atomic<bool> nativeActive{false};
static std::atomic<unsigned> candidateImages{0};
static std::atomic<unsigned> boundImages{0};
static std::atomic<unsigned> graphRegistrations{0};
static std::atomic<unsigned> unitRegistrations{0};
static std::atomic<unsigned long long> renderCallbacks{0};
static std::atomic<unsigned long long> renderFrames{0};
static std::atomic<unsigned long long> nonemptyBuffers{0};
static std::atomic<unsigned long long> renderFailures{0};
static std::atomic<unsigned> lastSampleRate{0};
static std::atomic<unsigned> lastChannels{0};
static std::atomic<unsigned> exhaustedSlots{0};

struct CallbackSlot {
    AURenderCallbackStruct source{};
    // Allocated slots are never freed or reused: render threads may still
    // reference them after a graph changes or stops.
};
static constexpr unsigned maximumSlots = 128;
static CallbackSlot slots[maximumSlots];
static unsigned nextSlot = 0;
static os_unfair_lock slotLock = OS_UNFAIR_LOCK_INIT;

static CallbackSlot *allocateSlot(const AURenderCallbackStruct *source) {
    os_unfair_lock_lock(&slotLock);
    CallbackSlot *slot = nullptr;
    if (nextSlot < maximumSlots) {
        slot = &slots[nextSlot++];
        slot->source = *source;
    } else {
        exhaustedSlots.fetch_add(1, std::memory_order_relaxed);
    }
    os_unfair_lock_unlock(&slotLock);
    return slot;
}

static OSStatus observeRender(void *refCon, AudioUnitRenderActionFlags *flags,
                              const AudioTimeStamp *time, UInt32 bus,
                              UInt32 frames, AudioBufferList *buffers) {
    CallbackSlot *slot = static_cast<CallbackSlot *>(refCon);
    if (!slot || !slot->source.inputProc) return kAudio_ParamError;
    OSStatus result = slot->source.inputProc(slot->source.inputProcRefCon, flags, time, bus, frames, buffers);
    if (nativeActive.load(std::memory_order_relaxed)) {
        renderCallbacks.fetch_add(1, std::memory_order_relaxed);
        if (result == noErr && frames && !(flags && (*flags & kAudioUnitRenderAction_OutputIsSilence))) {
            renderFrames.fetch_add(frames, std::memory_order_relaxed);
            if (buffers) {
                for (UInt32 i = 0; i < buffers->mNumberBuffers; i++) {
                    if (buffers->mBuffers[i].mData && buffers->mBuffers[i].mDataByteSize) {
                        nonemptyBuffers.fetch_add(1, std::memory_order_relaxed);
                        break;
                    }
                }
            }
        } else if (result != noErr) {
            renderFailures.fetch_add(1, std::memory_order_relaxed);
        }
    }
    return result;
}

static void readFormat(AudioUnit unit, AudioUnitScope scope, AudioUnitElement element) {
    if (!unit) return;
    AudioStreamBasicDescription format{};
    UInt32 length = sizeof(format);
    if (AudioUnitGetProperty(unit, kAudioUnitProperty_StreamFormat, scope, element, &format, &length) == noErr &&
        std::isfinite(format.mSampleRate) && format.mSampleRate >= 8000 && format.mSampleRate <= 384000) {
        lastSampleRate.store(static_cast<unsigned>(format.mSampleRate), std::memory_order_relaxed);
        lastChannels.store(format.mChannelsPerFrame, std::memory_order_relaxed);
    }
}

static OSStatus observeGraphRegistration(AUGraph graph, AUNode node, UInt32 bus,
                                          const AURenderCallbackStruct *callback) {
    if (!originalGraphCallback) return kAudio_ParamError;
    if (!callback || !callback->inputProc || callback->inputProc == observeRender) {
        return originalGraphCallback(graph, node, bus, callback);
    }
    CallbackSlot *slot = allocateSlot(callback);
    if (!slot) return originalGraphCallback(graph, node, bus, callback);
    AURenderCallbackStruct wrapper{observeRender, slot};
    OSStatus result = originalGraphCallback(graph, node, bus, &wrapper);
    if (result == noErr) {
        graphRegistrations.fetch_add(1, std::memory_order_relaxed);
        AudioUnit unit = nullptr;
        if (AUGraphNodeInfo(graph, node, nullptr, &unit) == noErr) {
            readFormat(unit, kAudioUnitScope_Input, bus);
        }
    }
    return result;
}

static OSStatus observeUnitRegistration(AudioUnit unit, AudioUnitPropertyID property,
                                         AudioUnitScope scope, AudioUnitElement element,
                                         const void *data, UInt32 size) {
    if (!originalUnitProperty) return kAudio_ParamError;
    if (property != kAudioUnitProperty_SetRenderCallback || !data || size != sizeof(AURenderCallbackStruct)) {
        return originalUnitProperty(unit, property, scope, element, data, size);
    }
    auto *callback = static_cast<const AURenderCallbackStruct *>(data);
    if (!callback->inputProc || callback->inputProc == observeRender) {
        return originalUnitProperty(unit, property, scope, element, data, size);
    }
    CallbackSlot *slot = allocateSlot(callback);
    if (!slot) return originalUnitProperty(unit, property, scope, element, data, size);
    AURenderCallbackStruct wrapper{observeRender, slot};
    OSStatus result = originalUnitProperty(unit, property, scope, element, &wrapper, sizeof(wrapper));
    if (result == noErr) {
        unitRegistrations.fetch_add(1, std::memory_order_relaxed);
        readFormat(unit, scope, element);
    }
    return result;
}

static void inspectImage(const struct mach_header *header, intptr_t slide) {
    Dl_info info{};
    if (!dladdr(header, &info) || !info.dli_fname) return;
    const char *path = info.dli_fname;
    if (!strstr(path, ".app/") || strstr(path, "GeckoView.framework") ||
        strstr(path, ".appex/") || strstr(path, "/System/Library/")) return;
    candidateImages.fetch_add(1, std::memory_order_relaxed);
    rebinding hooks[] = {
        {"AUGraphSetNodeInputCallback", reinterpret_cast<void *>(observeGraphRegistration), nullptr},
        {"AudioUnitSetProperty", reinterpret_cast<void *>(observeUnitRegistration), nullptr}
    };
    // Nonzero means setup failed. A successful call does NOT mean that the
    // image imported those symbols or that MusicKit runs inside this process.
    if (rebind_symbols_image(const_cast<struct mach_header *>(header), slide, hooks, 2) == 0) {
        boundImages.fetch_add(1, std::memory_order_relaxed);
    }
}
} // namespace

@implementation TimbreNativeAudioProbe
+ (void)install {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ _dyld_register_func_for_add_image(inspectImage); });
}

+ (void)setNativePlaybackActive:(BOOL)active {
    nativeActive.store(active, std::memory_order_relaxed);
}

+ (NSString *)snapshot {
    const auto grabs = graphRegistrations.load(std::memory_order_relaxed);
    const auto units = unitRegistrations.load(std::memory_order_relaxed);
    const auto callbacks = renderCallbacks.load(std::memory_order_relaxed);
    const auto frames = renderFrames.load(std::memory_order_relaxed);
    const auto buffers = nonemptyBuffers.load(std::memory_order_relaxed);
    const char *observation = buffers ? "Accessible output buffers observed (source unverified)" :
        "No accessible callback output buffer observed";
    return [NSString stringWithFormat:
        @"Native callback probe (passive; no DRM handling, sample reads or EQ)\n"
         @"Coverage: app-local imported AUGraph/AudioUnit symbols; excludes Gecko and Apple system frameworks\n"
         @"Probe active: %@\n"
         @"Candidate images / rebinding attempts: %u / %u\n"
         @"AUGraph callback registrations: %u\n"
         @"AudioUnit render callback registrations: %u\n"
         @"Observed render calls / non-silent frames: %llu / %llu\n"
         @"Calls with nonempty output buffers: %llu\n"
         @"Render failures: %llu\n"
         @"Last observed stream format: %u Hz, %u channels\n"
         @"Callback slots exhausted: %u\n"
         @"Interpretation: %s. These counts never establish that the stream was Apple Music, FairPlay-protected or EQ processed. A zero count cannot rule out a system-owned audio path.",
        nativeActive.load(std::memory_order_relaxed) ? @"yes" : @"no",
        candidateImages.load(std::memory_order_relaxed), boundImages.load(std::memory_order_relaxed),
        grabs, units, callbacks, frames, buffers,
        renderFailures.load(std::memory_order_relaxed),
        lastSampleRate.load(std::memory_order_relaxed),
        lastChannels.load(std::memory_order_relaxed), exhaustedSlots.load(std::memory_order_relaxed),
        observation];
}
@end
