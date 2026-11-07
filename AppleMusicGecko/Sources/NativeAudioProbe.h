#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An in-process, observation-only Core Audio callback probe.
/// It never reads, persists, decrypts or changes audio samples.
@interface TimbreNativeAudioProbe : NSObject
+ (void)install;
+ (void)setNativePlaybackActive:(BOOL)active;
+ (NSString *)snapshot;
@end

NS_ASSUME_NONNULL_END
