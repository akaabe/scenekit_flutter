#import <Flutter/Flutter.h>

@interface SceneKitRender : NSObject<FlutterTexture>

- (instancetype)initWithSize:(CGSize)renderSize
                  onNewFrame:(void(^)(void))onNewFrame;

- (void)dispose;

@end
