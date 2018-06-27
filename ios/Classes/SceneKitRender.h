#import <Flutter/Flutter.h>
#import <SceneKit/SceneKit.h>

@interface SceneKitRender : NSObject<FlutterTexture>

- (instancetype)initWithSize:(CGSize)renderSize
                  onNewFrame:(void(^)(void))onNewFrame;

- (void)dispose;
//- (void)zoomTo:(SCNVector3)pos;
- (void)zoomToItem:(NSInteger)item;
- (void)zoomOut;

@end
