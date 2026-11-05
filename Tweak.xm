#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

static NSString * const TBProbePrefix = @"[AppleMusicTimbreProbe]";

static BOOL TBIsAppleMusic(void) {
    return [NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.Music"];
}

static void TBLogSessionState(NSString *event) {
    if (!TBIsAppleMusic()) return;

    AVAudioSession *session = AVAudioSession.sharedInstance;
    NSMutableArray<NSString *> *ports = [NSMutableArray array];
    for (AVAudioSessionPortDescription *port in session.currentRoute.outputs) {
        [ports addObject:[NSString stringWithFormat:@"%@(%lu)", port.portType, (unsigned long)port.channels.count]];
    }
    NSLog(@"%@ event=%@ category=%@ mode=%@ rate=%.0fHz buffer=%.4fs outputs=%@",
          TBProbePrefix, event, session.category ?: @"", session.mode ?: @"",
          session.sampleRate, session.IOBufferDuration,
          ports.count ? [ports componentsJoinedByString:@","] : @"none");
}

%ctor {
    if (!TBIsAppleMusic()) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        AVAudioSession *session = AVAudioSession.sharedInstance;
        [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
            TBLogSessionState(@"appDidBecomeActive");
        }];
        [center addObserverForName:AVAudioSessionRouteChangeNotification object:session queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
            TBLogSessionState(@"routeChanged");
        }];
        [center addObserverForName:AVAudioSessionInterruptionNotification object:session queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
            TBLogSessionState(@"interruption");
        }];
        TBLogSessionState(@"loaded");
    });
}
