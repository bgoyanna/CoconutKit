//
//  HLSTransformer.h
//  CoconutKit
//
//  Created by Samuel Défago on 20/03/14.
//  Copyright (c) 2014 Hortis. All rights reserved.
//

/**
 * Conversions to string. Other conventional conversions are already available as NSStringFrom... functions
 */
NSString *HLSStringFromBool(BOOL yesOrNo);
NSString *HLSStringFromInterfaceOrientation(UIInterfaceOrientation interfaceOrientation);
NSString *HLSStringFromDeviceOrientation(UIDeviceOrientation deviceOrientation);
NSString *HLSStringFromCATransform3D(CATransform3D transform);

/**
 * Block signatures
 */
typedef id (^HLSTransformerBlock)(id object);
typedef BOOL (^HLSReverseTransformerBlock)(id *pObject,id fromObject, NSError **pError);

/**
 * A protocol to define transformations between objects. Transformations in forward direction are mandatory and
 * can never fail (most probably they correspond to some kind of formatting), while transformations in reverse
 * direction are optional and might fail, in which case a corresponding error must be returned (most probably 
 * they correspond to some kind of parsing)
 *
 * Tranformers can be seen as a more general NSFormatter, though they are not limited to formatting / parsing.
 * For example, you can define an NSNumber to NSNumber transformer applying some kind of calculation to it. During
 * forward transformation, some information might get lost (e.g. through rounding), in which case implementing
 * a reverse transformation does not make sense. In other cases (e.g. multiplication with a constant factor), the
 * reverse transformation can be meaningfully implemented. The rule should be that applying the transform and 
 * reverse transform to some object should return an object equal to it
 */
@protocol HLSTransformer <NSObject>

/**
 * Transform the provided object of class A into another one of class B (the classes might be the same)
 */
- (id)transformObject:(id)object;

/**
 * Reverse transform the provided object of class B into another one of class A
 */
@optional
- (BOOL)getObject:(id *)pObject fromObject:(id)fromObject error:(NSError **)pError;

@end

/**
 * A convenience transformer class which makes it easy to define transformations using blocks
 *
 * Designated initializer: -initWithBlock:reverseBlock:
 */
@interface HLSBlockTransformer : NSObject <HLSTransformer>

/**
 * Convenience constructor
 */
+ (instancetype)blockTransformerWithBlock:(HLSTransformerBlock)transformerBlock
                             reverseBlock:(HLSReverseTransformerBlock)reverseBlock;

/**
 * Designated intializer. The forward transformer block is mandatory, the reverse one is optional. If no reverse
 * transformation block has been provided, the instance does not respond to -getObject:fromObject:error:
 */
- (id)initWithBlock:(HLSTransformerBlock)transformerBlock
       reverseBlock:(HLSReverseTransformerBlock)reverseBlock;

@end