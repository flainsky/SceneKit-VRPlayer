//
//  MFBaseMovieViewController.m
//  VRDemo
//
//  Created by flainsky on 16/6/30.
//  Copyright © 2016年 ME Studio. All rights reserved.
//

#import "MFBaseMovieViewController.h"
#import <SceneKit/SceneKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import <MediaPlayer/MediaPlayer.h>
#import <GLKit/GLKit.h>
#import <SpriteKit/SpriteKit.h>
#import <AVFoundation/AVFoundation.h>

#define SCENE_R 200
#define SCENE_SIZE  2048
#define CAMERA_FOX  70             //50
#define CAMERA_HEIGHT   20          //20
#define GROUND_POS  -50
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define MENU_ZAN         @"MENU_ZAN"
#define TIMER_FPS   4

#define TAG_ANIMATION_KEY   @"animation_key"


@interface MFBaseMovieViewController ()<SCNSceneRendererDelegate,UIGestureRecognizerDelegate>
{
    UIImageView *centerLeftView;
    UIImageView *centerRightView;
    
    UIImageView *zanLeftView;
    UIImageView *zanRightView;
}

//视点相关
@property (nonatomic,assign)NSUInteger hitCount;
@property (nonatomic,retain)NSString *hitName;
@property (nonatomic,retain)CAKeyframeAnimation *animation;
@property (nonatomic,retain)CAKeyframeAnimation *zanAnimation;
@property(nonatomic,retain)NSTimer *tapTimer;

//基础Scene
@property (nonatomic,retain)SCNScene *rootScene;
@property (nonatomic,retain)SKScene *spriteKitScene;
@property (nonatomic,retain)SCNNode *floorNode;
@property (nonnull,retain)SCNLight *light;  //灯光

//摄像机
@property(nonatomic,retain)SCNView *leftView;
@property(nonatomic,retain)SCNView *rightView;
@property(nonatomic,retain)SCNNode *cameraLeftNode;
@property(nonatomic,retain)SCNNode *cameraRightNode;

@property(nonatomic,retain)SCNNode *cameraRollLeftNode;
@property(nonatomic,retain)SCNNode *cameraPitchLeftNode;
@property(nonatomic,retain)SCNNode *cameraYawLeftNode;

@property(nonatomic,retain)SCNNode *cameraRollRightNode;
@property(nonatomic,retain)SCNNode *cameraPitchRightNode;
@property(nonatomic,retain)SCNNode *cameraYawRightNode;

@property(nonatomic,retain)CMMotionManager *motionManager;

//全景视频播放
@property (nonatomic,retain)SCNNode *videoNode;
@property (nonatomic,retain)SKVideoNode *videoSpriteKitNode;
@property (nonatomic,retain)AVPlayer *videoAvplayer;
@property (nonatomic,retain)AVPlayerItem *videoAvplayerItem;

@property (nonatomic,assign)CMTime movieTime;

//场景
@property (nonatomic,retain)NSMutableArray *spaceTheatreArray;               //剧场
@property (nonatomic,retain)NSMutableArray *txtArray;

//信号量
@property (nonatomic,assign)BOOL isVR;

//播放地址
@property (nonatomic,retain)NSURL *playUrl;
@end

@implementation MFBaseMovieViewController
@synthesize hitName;
//摄像机
@synthesize leftView;
@synthesize rightView;
@synthesize cameraLeftNode;
@synthesize cameraRightNode;

@synthesize cameraRollLeftNode;
@synthesize cameraPitchLeftNode;
@synthesize cameraYawLeftNode;

@synthesize cameraRollRightNode;
@synthesize cameraPitchRightNode;
@synthesize cameraYawRightNode;

@synthesize motionManager;

//全景视频播放
@synthesize videoNode;
@synthesize videoSpriteKitNode;
@synthesize videoAvplayer;
@synthesize videoAvplayerItem;


- (id)initWithUrl:(NSURL *)playUrl
{
    self = [super initWithNibName:nil bundle:nil];
    if(self)
    {
        self.playUrl = playUrl;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isVR = YES;
    [self initDatas];
    
    [self initScene];
    //[self makeEyesVR];
    
    [self initSceneTheatre];
    
    
    [self init2D];
    
    UIButton *bt = [UIButton buttonWithType:UIButtonTypeCustom];
    bt.frame = CGRectMake(0, 0, 40, 40);
    bt.layer.cornerRadius = 5.0f;
    [bt setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
    bt.center = CGPointMake(ScreenWidth  - 40, ScreenHeight / 2);
    [bt setImage:[UIImage imageNamed:@"vr.png"] forState:UIControlStateNormal];
    [bt addTarget:self action:@selector(switchVR) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt];
    
    UIButton *closeBt = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBt.frame = CGRectMake(0, 0, 40, 40);
    closeBt.layer.cornerRadius = 5.0f;
    [closeBt setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:0.5]];
    closeBt.center = CGPointMake(40, ScreenHeight / 2);
    [closeBt setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeBt addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBt];
    
    
    
    
    [self addPlaneNodeControlWidth:30 Height:30 Scale:1 Position:SCNVector3Make(100, 0, 0) Rotation:SCNVector4Make(0, 1, 0, -(float)M_PI_2) andName:@"icon_praise.png" withTag:MENU_ZAN];
    
    [self addPlaneNodeControlWidth:30 Height:25 Scale:1 Position:SCNVector3Make(100, 0, 50) Rotation:SCNVector4Make(0, 1, 0, -(float)M_PI_2) andName:@"icon_praise.png" withTag:@"okok"];
}

- (void)close
{
    if(self.videoAvplayerItem != nil)
    {
        [self.spaceTheatreArray removeObject:self.videoNode];
        [self.videoAvplayer pause];
        [self.videoSpriteKitNode pause];
        [self.videoNode setPaused:YES];
        [self.videoSpriteKitNode removeFromParent];
        [self.videoNode removeFromParentNode];
        self.spriteKitScene.paused = YES;
        self.videoNode = nil;
        self.videoSpriteKitNode = nil;
        self.videoAvplayer = nil;
        self.videoAvplayerItem = nil;
        self.spriteKitScene = nil;
    }
    if(self.spaceTheatreArray != nil)
    {
        [self.spaceTheatreArray removeAllObjects];
        [self.spaceTheatreArray release];
        self.spaceTheatreArray = nil;
    }
    if(self.txtArray != nil)
    {
        [self.txtArray removeAllObjects];
        [self.txtArray release];
        self.txtArray = nil;
    }
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)switchVR
{
    if(self.isVR)
    {
        self.isVR = NO;
        
        [self makeIpad];
    }
    else{
        self.isVR = YES;
        [self makeVR];
    }
}


- (void)makeIpad
{
    self.leftView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
    self.rightView.alpha = 0;
    centerRightView.alpha = 0;
    centerLeftView.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
}
- (void)makeVR
{
    self.leftView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight / 2 );
    self.rightView.alpha = 1;
    centerRightView.alpha = 1;
    centerLeftView.frame = CGRectMake(ScreenWidth / 2 - 5, ScreenHeight / 4 - 5, 48, 48);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.leftView.playing = YES;
    self.leftView.scene.paused = NO;
    
    self.rightView.playing = YES;
    self.rightView.scene.paused = NO;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0f/(float)TIMER_FPS target:self selector:@selector(tapTimeAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if(self.leftView != nil)
    {
        self.leftView.playing = NO;
        self.leftView.scene.paused = YES;
    }
    if(self.rightView != nil)
    {
        self.rightView.playing = NO;
        self.rightView.scene.paused = YES;
    }
    if(self.tapTimer != nil)
    {
        [self.tapTimer invalidate];
        [self.tapTimer release];
        self.tapTimer = nil;
    }
}

- (void)initDatas
{
    if(self.spaceTheatreArray == nil)
    {
        self.spaceTheatreArray = [[NSMutableArray alloc] initWithCapacity:20];
    }
    if(self.txtArray == nil)
    {
        self.txtArray = [[NSMutableArray alloc] initWithCapacity:20];
    }
}

- (void)initScene
{
    self.rootScene = [SCNScene scene];
    self.leftView = [[SCNView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight / 2 ) options:nil];
    self.leftView.scene = self.rootScene;
    self.leftView.alpha = 0;
    self.leftView.playing = NO;
    self.leftView.autoenablesDefaultLighting = YES;
    self.leftView.userInteractionEnabled = YES;
    self.leftView.multipleTouchEnabled = YES;
    [self.leftView setJitteringEnabled:YES];
    [self.leftView autoenablesDefaultLighting];
    self.leftView.backgroundColor = [UIColor clearColor];
    self.leftView.delegate = self;
    [self.view addSubview:self.leftView];
    [self.leftView release];
    
    self.rightView = [[SCNView alloc] initWithFrame:CGRectMake(0, ScreenHeight / 2, ScreenWidth, ScreenHeight / 2 ) options:nil];
    self.rightView.scene = self.rootScene;
    self.rightView.alpha = 0;
    self.rightView.playing = NO;
    self.rightView.autoenablesDefaultLighting = YES;
    self.rightView.userInteractionEnabled = YES;
    self.rightView.multipleTouchEnabled = YES;
    [self.rightView setJitteringEnabled:YES];
    [self.rightView autoenablesDefaultLighting];
    self.rightView.backgroundColor = [UIColor clearColor];
    self.rightView.delegate = self;
    [self.view addSubview:self.rightView];
    [self.rightView release];
    
    
    //左－－－－－－－－－－－－－－－－－－－－－－－
    //VRCamera *cam = [VRCamera new];
    self.cameraLeftNode = [SCNNode node];
    SCNCamera *cameraLeft = [SCNCamera camera];
    cameraLeft.xFov = CAMERA_FOX;
    cameraLeft.yFov = CAMERA_FOX;
    cameraLeft.zFar = 700;
    self.cameraLeftNode.camera = cameraLeft;
    SCNVector3 v3Left = {-0.1,CAMERA_HEIGHT,0};
    self.cameraLeftNode.position = v3Left;
    self.cameraLeftNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0);
    
    //右－－－－－－－－－－－－－－－－－－－－－－－
    self.cameraRightNode = [SCNNode node];
    SCNCamera *cameraRight = [SCNCamera camera];
    cameraRight.xFov = CAMERA_FOX;
    cameraRight.yFov = CAMERA_FOX;
    cameraRight.zFar = 700;
    self.cameraRightNode.camera = cameraRight;
    SCNVector3 v3Right = {0.1,CAMERA_HEIGHT,0};
    self.cameraRightNode.position = v3Right;
    self.cameraRightNode.eulerAngles = SCNVector3Make(GLKMathDegreesToRadians(-90), 0, 0);
    
    self.cameraRollLeftNode = [SCNNode node];
    self.cameraPitchLeftNode = [SCNNode node];
    self.cameraYawLeftNode = [SCNNode node];
    [self.cameraRollLeftNode addChildNode:self.cameraLeftNode];
    [self.cameraPitchLeftNode addChildNode:self.cameraRollLeftNode];
    [self.cameraYawLeftNode addChildNode:self.cameraPitchLeftNode];
    
    self.cameraRollRightNode = [SCNNode node];
    self.cameraPitchRightNode = [SCNNode node];
    self.cameraYawRightNode = [SCNNode node];
    [self.cameraRollRightNode addChildNode:self.cameraRightNode];
    [self.cameraPitchRightNode addChildNode:self.cameraRollRightNode];
    [self.cameraYawRightNode addChildNode:self.cameraPitchRightNode];
    
    [self.rootScene.rootNode addChildNode:self.cameraYawLeftNode];
    self.leftView.pointOfView = self.cameraLeftNode;
    self.rightView.pointOfView = self.cameraRightNode;
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 1/60;
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue:[[NSOperationQueue alloc] init] withHandler:^(CMDeviceMotion *motion, NSError *error) {
    }];
    
    self.light = [SCNLight light];
    self.light.type = SCNLightTypeOmni;
    self.light.color = [UIColor whiteColor];
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = self.light;
    SCNVector3 lightV3 = {0,0,0};
    lightNode.position = lightV3;
    [self.rootScene.rootNode addChildNode:lightNode];
    
    SCNLight *light2 = [SCNLight light];
    light2.type = SCNLightTypeSpot;
    light2.color = [UIColor colorWithWhite:0.3 alpha:1.0f];
    SCNNode *lightNode2 = [SCNNode node];
    lightNode2.light = light2;
    lightNode2.rotation = SCNVector4Make(1, 0, 0, -M_PI/2);
    SCNVector3 light2V3 = {0,900,0};
    lightNode2.position = light2V3;
    [self.rootScene.rootNode addChildNode:lightNode2];
    
    self.leftView.alpha = 1;
    self.rightView.alpha = 1;
}

- (void)init2D
{
    centerLeftView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth / 2 - 5, ScreenHeight / 4 - 5, 48, 48)];
    centerLeftView.image = [UIImage imageNamed:@"selecting-vr_00000"];
    centerLeftView.alpha = 0.6;
    
    centerRightView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth / 2 - 5, ScreenHeight / 4 * 3 - 5, 48, 48)];
    centerRightView.image = [UIImage imageNamed:@"selecting-vr_00000"];
    centerRightView.alpha = 0.6;
    
    NSMutableArray *gifArray = [NSMutableArray arrayWithCapacity:60];
    self.animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    self.animation.duration = 2;
    self.animation.delegate = self;
    for(int i = 0 ; i< 60 ;i++)
    {
        NSString *name = [NSString stringWithFormat:@"selecting-vr_000%02d",i];
        UIImage *image = [UIImage imageNamed:name];
        CGImageRef cgimg = image.CGImage;
        [gifArray addObject:(__bridge UIImage *)cgimg];
    }
    self.animation.values = gifArray;
    [self.view addSubview:centerLeftView];
    [self.view addSubview:centerRightView];
    [centerRightView release];
    [centerLeftView release];
    
    
    zanLeftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 111, 154)];
    zanLeftView.image = [UIImage imageNamed:@"arrow000.png"];
    zanLeftView.alpha = 0;
    zanLeftView.transform=CGAffineTransformMakeRotation(M_PI/2);
    zanLeftView.center = self.leftView.center;
    [self.view addSubview:zanLeftView];
    [zanLeftView release];
    
    zanRightView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 111, 154)];
    zanRightView.image = [UIImage imageNamed:@"arrow000.png"];
    zanRightView.alpha = 0;
    zanRightView.transform=CGAffineTransformMakeRotation(M_PI/2);
    zanRightView.center = self.rightView.center;
    [self.view addSubview:zanRightView];
    [zanRightView release];
    
    NSMutableArray *gif2Array = [NSMutableArray arrayWithCapacity:60];
    self.zanAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    self.zanAnimation.duration = 1;
    self.zanAnimation.repeatCount = 9999999;
    self.zanAnimation.delegate = self;
    for(int i = 0 ; i< 151 ;i++)
    {
        NSString *name = [NSString stringWithFormat:@"1_00%03d",i];
        UIImage *image = [UIImage imageNamed:name];
        CGImageRef cgimg = image.CGImage;
        [gif2Array addObject:(__bridge UIImage *)cgimg];
    }
    self.zanAnimation.values = gif2Array;
}

- (void)initSceneTheatre
{
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"fly" ofType:@"mp4"];
    self.videoAvplayerItem = [AVPlayerItem playerItemWithURL:self.playUrl];
    
    self.videoAvplayer = [AVPlayer playerWithPlayerItem:self.videoAvplayerItem];
    self.videoSpriteKitNode = [SKVideoNode videoNodeWithAVPlayer:self.videoAvplayer];
    self.videoNode = [SCNNode node];
    self.videoNode.geometry = [SCNSphere sphereWithRadius:SCENE_R];
    SKScene *spriteKitScene = [SKScene sceneWithSize:CGSizeMake(SCENE_SIZE, SCENE_SIZE)];
    spriteKitScene.scaleMode = SKSceneScaleModeAspectFit;
    self.videoSpriteKitNode.position = CGPointMake(spriteKitScene.size.width / 2, spriteKitScene.size.height / 2);
    self.videoSpriteKitNode.size = spriteKitScene.size;
    [spriteKitScene addChild:self.videoSpriteKitNode];
    
    self.videoNode.geometry.firstMaterial.diffuse.contents = spriteKitScene;
    self.videoNode.geometry.firstMaterial.doubleSided = YES;
    SCNMatrix4 transform = SCNMatrix4MakeRotation((float)M_PI, 0.0, 0.0, 1.0);
    transform = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0);
    
    self.videoNode.pivot = SCNMatrix4MakeRotation((float)M_PI_2,0.0,-1.0,0.0);
    self.videoNode.geometry.firstMaterial.diffuse.contentsTransform = transform;
    self.videoNode.position = SCNVector3Make(0, 0, 0);
    [self.spaceTheatreArray addObject:self.videoNode];
    
    for(SCNNode *node in self.spaceTheatreArray)
    {
        [node setHidden:NO];
        [self.rootScene.rootNode addChildNode:node];
        [self.videoSpriteKitNode play];
    }
}

- (void)playVR:(NSString *)path
{
    if(self.videoAvplayerItem != nil)
    {
        [self.spaceTheatreArray removeObject:self.videoNode];
        [self.videoAvplayer pause];
        [self.videoSpriteKitNode pause];
        [self.videoNode setPaused:YES];
        [self.videoSpriteKitNode removeFromParent];
        [self.videoNode removeFromParentNode];
        self.spriteKitScene.paused = YES;
        self.videoNode = nil;
        self.videoSpriteKitNode = nil;
        self.videoAvplayer = nil;
        self.videoAvplayerItem = nil;
        self.spriteKitScene = nil;
        
    }
    
    self.videoAvplayerItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:path]];
    
    self.videoAvplayer = [AVPlayer playerWithPlayerItem:self.videoAvplayerItem];
    self.videoSpriteKitNode = [SKVideoNode videoNodeWithAVPlayer:self.videoAvplayer];
    self.videoNode = [SCNNode node];
    self.videoNode.geometry = [SCNSphere sphereWithRadius:SCENE_R];
    self.spriteKitScene = [SKScene sceneWithSize:CGSizeMake(SCENE_SIZE, SCENE_SIZE)];
    self.spriteKitScene.scaleMode = SKSceneScaleModeAspectFit;
    self.videoSpriteKitNode.position = CGPointMake(self.spriteKitScene.size.width / 2, self.spriteKitScene.size.height / 2);
    self.videoSpriteKitNode.size = self.spriteKitScene.size;
    [self.spriteKitScene addChild:self.videoSpriteKitNode];
    
    self.videoNode.geometry.firstMaterial.diffuse.contents = self.spriteKitScene;
    self.videoNode.geometry.firstMaterial.doubleSided = YES;
    SCNMatrix4 transform = SCNMatrix4MakeRotation((float)M_PI, 0.0, 0.0, 1.0);
    transform = SCNMatrix4Translate(transform, 1.0, 1.0, 0.0);
    
    self.videoNode.pivot = SCNMatrix4MakeRotation((float)M_PI_2,0.0,-1.0,0.0);
    self.videoNode.geometry.firstMaterial.diffuse.contentsTransform = transform;
    self.videoNode.position = SCNVector3Make(0, 0, 0);
    [self.spaceTheatreArray addObject:self.videoNode];
    [self.videoAvplayer play];
    [self.videoSpriteKitNode play];
    
    for(SCNNode *node in self.spaceTheatreArray)
    {
        [node setHidden:NO];
        [self.rootScene.rootNode addChildNode:node];
        [self.videoSpriteKitNode play];
    }
}


//眼控------------------------------------------------------------
- (void)runAnimi:(UIImageView *)iv
{
    [iv.layer addAnimation:self.animation forKey:TAG_ANIMATION_KEY];
}

- (void)stopAnimi:(UIImageView *)iv
{
    [iv.layer removeAnimationForKey:TAG_ANIMATION_KEY];
    [iv setImage:[UIImage imageNamed:@"selecting-vr_00000"]];
}


//模拟点击事件
- (void)tapTimeAction
{
    @autoreleasepool {
        //CGPoint point = centerLeftView.center;
        NSArray *hitArray = [self.leftView hitTest:centerLeftView.center options:nil];
        if([hitArray count] > 0)
        {
            SCNHitTestResult *result = [hitArray objectAtIndex:0];
            SCNNode *node = result.node;
            if(node.name == nil)
            {
                [self stopZanAnimi:zanLeftView];
                [self stopZanAnimi:zanRightView];
                [self clearHit];
                return;
            }
            if([self.hitName isEqualToString:node.name])
            {
                self.hitCount++;
                if(self.hitCount == TIMER_FPS)
                {
                    [self eyeDidHit];
                }
            }
            else if([node.name isEqualToString:MENU_ZAN])
            {
                [self runZanAnimi:zanLeftView];
                [self runZanAnimi:zanRightView];
            }
            else{
                self.hitName = [NSString stringWithFormat:@"%@",node.name];
                self.hitCount = 1;
                [self runAnimi:centerLeftView];
                [self runAnimi:centerRightView];
            }
            
        }
        else
        {
            [self stopZanAnimi:zanLeftView];
            [self stopZanAnimi:zanRightView];
            [self clearHit];
        }
        hitArray = nil;
    }
}

-(void)clearHit
{
    self.hitName = @"";
    self.hitCount = 0;
    [self stopAnimi:centerLeftView];
    [self stopAnimi:centerRightView];
}

//旋转一圈后响应事件
- (void)eyeDidHit
{
    [self stopAnimi:centerLeftView];
    [self stopAnimi:centerRightView];
    if(self.tapTimer != nil)
    {
        [self.tapTimer invalidate];
        [self.tapTimer release];
    }
    self.hitCount = 0;
    //增加响应
    NSLog(@"hit 4 %@",self.hitName);
    self.hitName = @"";
    return;
}

- (BOOL)addPlaneNodeControlWidth:(float)width Height:(float)height Scale:(float)scale Position:(SCNVector3)position Rotation:(SCNVector4)rotation andName:(NSString *)name withTag:(NSString *)tag
{
    
    SCNPlane *plane = [SCNPlane planeWithWidth:width height:height];
    plane.firstMaterial.doubleSided = YES;
    plane.firstMaterial.diffuse.contents = [UIImage imageNamed:name];
    plane.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
    plane.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
    plane.firstMaterial.diffuse.mipFilter = SCNFilterModeNearest;
    plane.firstMaterial.locksAmbientWithDiffuse = YES;
    plane.firstMaterial.shininess = 0.0f;
    SCNNode *node = [SCNNode node];
    node.name = tag;
    node.physicsBody = SCNPhysicsBodyTypeStatic;
    node.physicsBody.restitution = 1.0f;
    node.geometry = plane;
    node.scale = SCNVector3Make(scale, scale, scale);
    node.position = position;
    node.rotation = rotation;
    if(tag != nil){
        node.name = tag;
    }
    [self.rootScene.rootNode addChildNode:node];
    return YES;
}

- (BOOL)addPlaneNodeSingleWidth:(float)width Height:(float)height Scale:(float)scale Position:(SCNVector3)position Rotation:(SCNVector4)rotation andName:(NSString *)name withTag:(NSString *)tag
{
    
    SCNPlane *plane = [SCNPlane planeWithWidth:width height:height];
    plane.firstMaterial.doubleSided = YES;
    plane.firstMaterial.diffuse.contents = [UIImage imageNamed:name];
    plane.firstMaterial.diffuse.wrapS = SCNWrapModeClamp;
    plane.firstMaterial.diffuse.wrapT = SCNWrapModeClamp;
    plane.firstMaterial.diffuse.mipFilter = SCNFilterModeNearest;
    plane.firstMaterial.locksAmbientWithDiffuse = YES;
    plane.firstMaterial.shininess = 0.0f;
    SCNNode *node = [SCNNode node];
    node.name = tag;
    node.physicsBody = SCNPhysicsBodyTypeStatic;
    node.physicsBody.restitution = 1.0f;
    node.geometry = plane;
    node.scale = SCNVector3Make(scale, scale, scale);
    node.position = position;
    node.rotation = rotation;
    if(tag != nil){
        node.name = tag;
    }
    [self.txtArray addObject:node];
    //[self.rootScene.rootNode addChildNode:node];
    return YES;
}

- (BOOL)addTextNodeWithText:(NSString *)title Depth:(float)depth Scale:(float)scale Position:(SCNVector3)position Rotation:(SCNVector4)rotation withTag:(NSString *)tag
{
    SCNText *text = [SCNText textWithString:title extrusionDepth:depth];
    text.firstMaterial.diffuse.contents = [UIColor redColor];
    text.alignmentMode = @"kCAAlignmentCenter";
    
    SCNNode *node = [SCNNode node];
    node.name = tag;
    node.geometry = text;
    node.scale = SCNVector3Make(scale, scale, scale);
    node.position = position;
    node.rotation = rotation;
    [self.txtArray addObject:node];
    return YES;
}

- (BOOL)addContentNodeWithText:(NSString *)title Depth:(float)depth Scale:(float)scale Position:(SCNVector3)position Rotation:(SCNVector4)rotation withTag:(NSString *)tag
{
    SCNText *text = [SCNText textWithString:title extrusionDepth:depth];
    text.wrapped = YES;
    text.firstMaterial.diffuse.contents = [UIColor redColor];
    text.alignmentMode = @"kCAAlignmentCenter";
    text.containerFrame = CGRectMake(0.0, 0, 400, 60);
    
    SCNNode *node = [SCNNode node];
    node.name = tag;
    node.geometry = text;
    node.scale = SCNVector3Make(scale, scale, scale);
    node.position = position;
    node.rotation = rotation;
    [self.txtArray addObject:node];
    return YES;
}

//基础方法------------------------------------------------------------
- (SCNNode *)addNode:(NSString *)fileName{
    SCNNode *node = nil;
    NSString *path = [NSString stringWithFormat:@"art.scnassets/%@",fileName];
    SCNScene *subScene = [SCNScene sceneNamed:path];
    node = subScene.rootNode.childNodes.firstObject;
    return node;
}


- (SCNNode *)addNodeWithDurantion:(CFTimeInterval)duration FileName:(NSString *)fileName andNamePre:(NSString *)namePre
{
    SCNNode *node = [self addNode:fileName];
    [self stopAnimationWithDurantion:duration Node:node andNamePre:namePre];
    return node;
}

- (void)stopAnimationWithDurantion:(CFTimeInterval)durantion Node:(SCNNode *)node andNamePre:(NSString *)namePre
{
    if(node == nil)return;
    node.name = [NSString stringWithFormat:@"%@%@",namePre,node.name];
    if(durantion > 0)
    {
        for(NSString *key in node.animationKeys)
        {
            CAAnimation *animation = [node animationForKey:key];
            animation.duration = durantion;
            [node removeAnimationForKey:key];
            [node addAnimation:animation forKey:key];
        }
    }
    for(SCNNode *n in node.childNodes)
    {
        [self stopAnimationWithDurantion:durantion Node:n andNamePre:namePre];
    }
}

- (void)renderer:(id <SCNSceneRenderer>)renderer willRenderScene:(SCNScene *)scene atTime:(NSTimeInterval)time
{
    if(self.cameraRollLeftNode != nil && self.cameraPitchLeftNode != nil && self.cameraYawLeftNode != nil && self.motionManager != nil)
    {
        @autoreleasepool {
            SCNVector3 v13 = self.cameraRollLeftNode.eulerAngles;
            v13.z = (float)(0 - self.motionManager.deviceMotion.attitude.roll);
            self.cameraRollLeftNode.eulerAngles = v13;
            self.cameraRollRightNode.eulerAngles = v13;
            
            SCNVector3 v23 = self.cameraPitchLeftNode.eulerAngles;
            v23.x = self.motionManager.deviceMotion.attitude.pitch;
            self.cameraPitchLeftNode.eulerAngles = v23;
            self.cameraPitchRightNode.eulerAngles = v23;
            
            SCNVector3 v33 = self.cameraYawLeftNode.eulerAngles;
            v33.y = self.motionManager.deviceMotion.attitude.yaw;
            self.cameraYawLeftNode.eulerAngles = v33;
            self.cameraYawRightNode.eulerAngles = v33;
        }
        
    }
}


- (void)clearMenu
{
    for(SCNNode *node in self.txtArray)
    {
        [node setHidden:YES];
        [node removeFromParentNode];
    }
    [self.txtArray removeAllObjects];
}

- (void)dealloc
{
    if(self.videoAvplayerItem != nil)
    {
        [self.spaceTheatreArray removeObject:self.videoNode];
        [self.videoAvplayer pause];
        [self.videoSpriteKitNode pause];
        [self.videoNode setPaused:YES];
        [self.videoSpriteKitNode removeFromParent];
        [self.videoNode removeFromParentNode];
        self.spriteKitScene.paused = YES;
        self.videoNode = nil;
        self.videoSpriteKitNode = nil;
        self.videoAvplayer = nil;
        self.videoAvplayerItem = nil;
        self.spriteKitScene = nil;
    }
    if(self.spaceTheatreArray != nil)
    {
        [self.spaceTheatreArray removeAllObjects];
        [self.spaceTheatreArray release];
        self.spaceTheatreArray = nil;
    }
    if(self.txtArray != nil)
    {
        [self.txtArray removeAllObjects];
        [self.txtArray release];
        self.txtArray = nil;
    }
    [super dealloc];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//赞动画
- (void)runZanAnimi:(UIImageView *)iv
{
    if(iv.alpha == 1)return;
    [iv.layer addAnimation:self.zanAnimation forKey:TAG_ANIMATION_KEY];
    iv.alpha = 1;
}
- (void)stopZanAnimi:(UIImageView *)iv
{
    if(iv.alpha == 0)return;
    [iv.layer removeAnimationForKey:TAG_ANIMATION_KEY];
    [iv setImage:[UIImage imageNamed:@"arrow000"]];
    iv.alpha = 0;
}

@end
