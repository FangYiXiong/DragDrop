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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    UITouch *touch = [touches anyObject];
    
    CGPoint positionInScene = [touch locationInNode:self];
    
    [self selectNodeForTouch:positionInScene];
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

@end


