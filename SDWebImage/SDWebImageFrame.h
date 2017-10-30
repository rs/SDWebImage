/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@interface SDWebImageFrame : NSObject

// This class is used for creating animated images via `animatedImageWithFrames` in `SDWebImageCoderHelper`. Attension if you need animated images loop count, use `sd_imageLoopCount` property in `UIImage+MultiFormat`

/**
 The image of current frame. You should not set an animated image.
 */
@property (nonatomic, strong, readonly, nonnull) UIImage *image;
/**
 The duration of current frame to be displayed. The number is milliseconds but not seconds to avoid losing precision. You should not set this to zero.
 */
@property (nonatomic, readonly, assign) NSUInteger duration;

/**
 Create a frame instance with specify image and duration

 @param image current frame's image
 @param duration current frame's duration
 @return frame instance
 */
+ (instancetype _Nonnull)frameWithImage:(UIImage * _Nonnull)image duration:(NSUInteger)duration;

@end
