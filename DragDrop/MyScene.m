//
//  MyScene.m
//  DragDrop
//
//  Created by FangYiXiong on 14-6-24.
//  Copyright (c) 2014年 Fang YiXiong. All rights reserved.
//

#import "MyScene.h"

static NSString * const kAnimalNodeName = @"movable";

@interface MyScene ()
@property (nonatomic, strong) SKSpriteNode *background;
@property (nonatomic, strong) SKSpriteNode *selectedNode;
@end


@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        // 1. 加载背景图片
        _background = [SKSpriteNode spriteNodeWithImageNamed:@"blue-shooting-stars.png"];
        _background.name = @"background";
        _background.anchorPoint = CGPointZero;
        [self addChild:_background];
        
        // 2. 加载图片
        NSArray *imageNames = @[@"bird",@"cat",@"dog",@"turtle"];
        for(int i = 0; i < [imageNames count]; ++i) {
            NSString *imageName = imageNames[i];
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:imageName];
            sprite.name = kAnimalNodeName;
            float offsetFraction = ((float)(i+1))/([imageNames count]+1);
            sprite.position = CGPointMake(size.width * offsetFraction, size.height/ 2);
            [_background addChild:sprite];
        }
    }
    return self;
}

/*
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Called when a touch begins
    
    UITouch *touch = [touches anyObject];
    
    CGPoint positionInScene = [touch locationInNode:self];
    
    [self selectNodeForTouch:positionInScene];
}
*/

// 当scene第一次显示出来时会调用这个方法。在上面的方法中创建了一个pan手势识别器，并用当前的scene来对其做初始化，另外还传入一个callback：handlePanFrom:。接着把这个手势识别器添加到scene中的view里面。
- (void)didMoveToView:(SKView *)view{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.view addGestureRecognizer:pan];
}

//当手势开始、改变(例如用户持续drag)，以及结束时，上面这个callback函数都会被调用。该方法会进入不同的case，以处理不同的情况。

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:{
            //当手势开始时，将坐标系统转换为node坐标系(注意这里没有便捷的方法，只能这样处理).
            CGPoint touchLocation = [recognizer locationInView:recognizer.view];
            touchLocation = [self convertPointFromView:touchLocation];
            //调用之前写的helper方法selectNodeForTouch:
            [self selectNodeForTouch:touchLocation];
            break;
        }
        //当手势发生改变时，需要计算出手势移动的量。还在手势识别器已经为我们存储了手势移动的累计量(translation)！不过考虑到效果的差异，我们需要在UIKit坐标系和Sprite Kit坐标系中对坐标进行转换。
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [recognizer translationInView:recognizer.view];
            translation = CGPointMake(translation.x, -translation.y);
            [self panForTranslation:translation];
            //平移(pan)之后，需要把手势识别器上的translation设置为0，否则该值会继续被累加。
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
            break;
        }
        //当手势结束之后，UIPanGestureRecognizer可以为我们提供一个移动的速度。通过这个速度可以对node做一个动画——滑动一小点，这样用户可以对node做一个快速的摇动，就像table view上的那种效果一样。
        case UIGestureRecognizerStateEnded:{
            if (![_selectedNode.name isEqualToString:kAnimalNodeName]) {
                float scrollDuration = 0.2;
                CGPoint velocity = [recognizer velocityInView:recognizer.view];
                CGPoint pos = [_selectedNode position];
                CGPoint p = mult(velocity, scrollDuration);
                
                CGPoint newPos = CGPointMake(pos.x + p.x, pos.y + p.y);
                newPos = [self boundLayerPos:newPos];
                [_selectedNode removeAllActions];
                
                SKAction *moveTo = [SKAction moveTo:newPos duration:scrollDuration];
                [moveTo setTimingMode:SKActionTimingEaseOut];
                [_selectedNode runAction:moveTo];
            }
            break;
        }
        default:
            break;
    }
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        

        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
    }
}

- (void)selectNodeForTouch:(CGPoint)touchLocation{
    // 1. 通过scene(self)获得touchLocation位置对应的node。
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
    // 2
    if (![_selectedNode isEqual:touchedNode]) {
        [_selectedNode removeAllActions];
        [_selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.1]];
        
        _selectedNode = touchedNode;
        // 3
        if ([touchedNode.name isEqualToString:kAnimalNodeName]) {
            SKAction *sequence = [SKAction sequence:@[[SKAction rotateByAngle:degToRad(-4.0f) duration:0.1],
                                                      [SKAction rotateByAngle:0.0 duration:0.1],
                                                      [SKAction rotateByAngle:degToRad(4.0f) duration:0.1]]];
            [_selectedNode runAction:[SKAction repeatActionForever:sequence]];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint positionScene = [touch locationInNode:self];
    CGPoint previousPosition = [touch previousLocationInNode:self];
    CGPoint translation = CGPointMake(positionScene.x - previousPosition.x, positionScene.y - previousPosition.y);
    [self panForTranslation:translation];
}

// 确保不会将layer移动到背景图片范围之外。在这里传入一个需要移动到的位置，然后该方法会对位置做适当的判断处理，以确保不会移动太远
- (CGPoint)boundLayerPos:(CGPoint)newPos{
    CGSize winSize = self.size;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -[_background size].width + winSize.width);
    retval.y = self.position.y;
    return retval;
}


//  首先判断一下_selectedNode是否为动物node，如果是的话，根据传入的参数来为node设置新的位置。如果是background layer，同样也会设置一个新的位置，只不过新的位置需要调用boundLayerPos:方法获得。
- (void)panForTranslation:(CGPoint)translation{
    CGPoint position = _selectedNode.position;
    if ([_selectedNode.name isEqualToString:kAnimalNodeName]) {
        _selectedNode.position = CGPointMake(position.x + translation.x, position.y + translation.y);
    }else{
        CGPoint newPos = CGPointMake(position.x + translation.x, position.y + translation.y);
        _background.position = [self boundLayerPos:newPos];
    }
}



-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

float degToRad(float degree) {
	return degree / 180.0f * M_PI;
}

CGPoint mult(const CGPoint v, const CGFloat s) {
	return CGPointMake(v.x*s, v.y*s);
}

@end


