#import "SceneKitRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface SceneKitRender()
@property (strong, nonatomic) EAGLContext *context;
@property (copy, nonatomic) void(^onNewFrame)(void);

@property (nonatomic) GLuint frameBuffer;
@property (nonatomic) GLuint depthBuffer;
@property (nonatomic) GLuint outputTexture;
@property (nonatomic) CVPixelBufferRef target;
@property (nonatomic) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic) CVOpenGLESTextureRef texture;
@property (nonatomic) CGSize renderSize;
@property (nonatomic) SCNNode *freezer;
@property (nonatomic) SCNNode *camera;
@property (nonatomic) SCNScene *scene;
@property (nonatomic) BOOL running;
@property (strong, nonatomic) SCNRenderer *renderer;
@end

@implementation SceneKitRender

- (instancetype)initWithSize:(CGSize)renderSize
                  onNewFrame:(void(^)(void))onNewFrame {
    self = [super init];
    if (self){
        self.renderSize = CGSizeMake(renderSize.width * 1.5, renderSize.height * 1.5);
        self.running = YES;
        self.onNewFrame = onNewFrame;
        
        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        thread.name = @"SceneKitRender";
        [thread start];
    }
    return self;
}

- (void)run {
    [self initGL];
    
    while (_running) {
        CFTimeInterval loopStart = CACurrentMediaTime();
        CFTimeInterval waitDelta = 0.016 - (CACurrentMediaTime() - loopStart);
        
        glViewport(0, 0, _renderSize.width, _renderSize.height);
        glClearColor(1, 1, 1, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        [_renderer renderAtTime:CACurrentMediaTime()];
        glFlush();
        
        dispatch_async(dispatch_get_main_queue(), self.onNewFrame);
        if (waitDelta > 0) {
            [NSThread sleepForTimeInterval:waitDelta];
        }
    }
    [self deinitGL];
}

#pragma mark - Public

- (void)dispose {
    _running = NO;
}

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer {
    CVBufferRetain(_target);
    return _target;
}

#pragma mark - Private

// During init, enable debug output


- (void)initGL {
    _scene = [SCNScene sceneNamed:@"model.scn"];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
    
    [self createCVBufferWithSize:_renderSize withRenderTarget:&_target withTextureOut:&_texture];
    
    _renderer = [SCNRenderer rendererWithContext:_context options:nil];
    _renderer.scene = _scene;
    
    _camera = [_scene.rootNode childNodeWithName:@"camera" recursively:YES];
    _renderer.pointOfView = _camera;
    _camera.eulerAngles = SCNVector3Make(0, 0, M_PI);
    
//    [_renderer setJitteringEnabled:YES];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_STENCIL_TEST);
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);
    
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, _renderSize.width, _renderSize.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    
    //hack to make render to work
    [_renderer snapshotAtTime:0 withSize:CGSizeMake(0, 0) antialiasingMode:SCNAntialiasingModeNone];

}

- (void)createCVBufferWithSize:(CGSize)size
              withRenderTarget:(CVPixelBufferRef *)target
                withTextureOut:(CVOpenGLESTextureRef *)texture {
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCache);
    
    if (err) return;
    
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault,
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height,
                        kCVPixelFormatType_32BGRA, attrs, target);
    
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                 _textureCache,
                                                 *target,
                                                 NULL,
                                                 GL_TEXTURE_2D,
                                                 GL_RGBA,
                                                 size.width,
                                                 size.height,
                                                 GL_BGRA,
                                                 GL_UNSIGNED_BYTE,
                                                 0,
                                                 texture);
    
    CFRelease(empty);
    CFRelease(attrs);
}

- (void)deinitGL {
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteFramebuffers(1, &_depthBuffer);
    CFRelease(_target);
    CFRelease(_textureCache);
    CFRelease(_texture);
}

- (void)zoomTo:(SCNVector3)pos;
{
//    _freezer = [scene.rootNode childNodeWithName:@"ID5729" recursively:YES];
    if (_camera != nil) {
        SCNMaterial *material = _freezer.geometry.firstMaterial;
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.5];
        _camera.position = pos;
        [SCNTransaction setCompletionBlock:^{
            material.emission.contents = [UIColor blackColor];
        }];
        material.emission.contents = [UIColor redColor];
        [SCNTransaction commit];
    }
}

- (void)zoomToItem:(NSInteger)item
{
    NSArray *items = @[@"ID5729", @"ID5721", @"ID5737", @"ID5745", @"ID5713"];
    SCNVector3 pos[] = {SCNVector3Make(285, 57, 248), SCNVector3Make(245, 57, 248), SCNVector3Make(205, 57, 248), SCNVector3Make(165, 57, 248), SCNVector3Make(125, 57, 248)};
    if (item >= 0 && item < [items count])
    {
        SCNNode *door = [_scene.rootNode childNodeWithName:items[item] recursively:YES];
        if (_camera != nil) {
            SCNMaterial *material = door.geometry.firstMaterial;
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:1.5];
            _camera.position = pos[item];
            [SCNTransaction setCompletionBlock:^{
                material.emission.contents = [UIColor blackColor];
            }];
            material.emission.contents = [UIColor redColor];
            [SCNTransaction commit];
        }
    }
}

- (void)zoomOut
{
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:3.0];
    _camera.position = SCNVector3Make(207, 58, 330);
    [SCNTransaction commit];
}

@end
