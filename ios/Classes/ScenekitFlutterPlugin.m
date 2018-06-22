#import "ScenekitFlutterPlugin.h"
#import "SceneKitRender.h"

@interface ScenekitFlutterPlugin()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, SceneKitRender *> *renders;
@property (nonatomic, strong) NSObject<FlutterTextureRegistry> *textures;
@end

@implementation ScenekitFlutterPlugin

- (instancetype)initWithTextures:(NSObject<FlutterTextureRegistry> *)textures {
    self = [super init];
    if (self) {
        _renders = [[NSMutableDictionary alloc] init];
        _textures = textures;
    }
    return self;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"scenekit_flutter"
                                     binaryMessenger:[registrar messenger]];
    ScenekitFlutterPlugin* instance = [[ScenekitFlutterPlugin alloc] initWithTextures:[registrar textures]];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"create" isEqualToString:call.method]) {
        CGFloat width = [call.arguments[@"width"] floatValue];
        CGFloat height = [call.arguments[@"height"] floatValue];
        
        NSInteger __block textureId;
        id<FlutterTextureRegistry> __weak registry = self.textures;
        
        SceneKitRender *render = [[SceneKitRender alloc] initWithSize:CGSizeMake(width, height)
                                                       onNewFrame:^{
                                                           [registry textureFrameAvailable:textureId];
                                                       }];
        
        textureId = [self.textures registerTexture:render];
        self.renders[@(textureId)] = render;
        result(@(textureId));
    } else if ([@"dispose" isEqualToString:call.method]) {
        NSNumber *textureId = call.arguments[@"textureId"];
        SceneKitRender *render = self.renders[textureId];
        [render dispose];
        [self.renders removeObjectForKey:textureId];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
