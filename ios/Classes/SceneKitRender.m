//
//  OpenGLRender.m
//  opengl_texture
//
//  Created by German Saprykin on 22/4/18.
//

#import "SceneKitRender.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <SceneKit/SceneKit.h>

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
@property (nonatomic) BOOL running;
@property (strong, nonatomic) SCNRenderer *renderer;
@end

@implementation SceneKitRender

- (instancetype)initWithSize:(CGSize)renderSize
                  onNewFrame:(void(^)(void))onNewFrame {
    self = [super init];
    if (self){
        self.renderSize = renderSize;
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
    SCNScene *scene = [SCNScene sceneNamed:@"ship.scn"];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:_context];
    
    [self createCVBufferWithSize:_renderSize withRenderTarget:&_target withTextureOut:&_texture];
    
    _renderer = [SCNRenderer rendererWithContext:_context options:nil];
    _renderer.scene = scene;
    
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _renderSize.width, _renderSize.height);

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture), 0);
    
    CGSize size = CGSizeMake(600, 400);
    
    //hack to make render work
    [_renderer snapshotAtTime:0 withSize:size antialiasingMode:SCNAntialiasingModeMultisampling4X];

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

@end
