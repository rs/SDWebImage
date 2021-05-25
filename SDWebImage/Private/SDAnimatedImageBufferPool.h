/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDWebImageCompat.h"
#import "SDImageCoder.h"

/// Buffer Pool is used to track all animated image frame buffer. A buffer can be shared only when `(image data, decoding options, index)` are all equal.
/// The provide should implements `effectiveFrameOptions` to detect cache equality.
/// @note: The current tracking use weak reference to avoid effect buffer's lifecycle.
/// @note: In the future, we may use `cache key` instead of `image data` to detect cache equality. Which need to pass the cache key from top-level (`SDImageCacheDecodeImageData`/`SDImageLoaderDecodeImageData`) to the provider (`SDAnimatedImage`/`SDAnimatedImageCoder`)
@interface SDAnimatedImageBufferPool : NSObject

/// Query buffer from buffer pool.
/// @param provider The buffer provider
/// @param index The frame index
+ (nullable UIImage *)bufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Store buffer into buffer pool.
/// @param buffer The frame buffer
/// @param provider The buffer provider
/// @param index The frame index
+ (void)setBuffer:(nullable UIImage *)buffer forProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Remove the buffer from buffer pool.
/// @param provider The buffer provider
/// @param index The frame index
+ (void)removeBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Clear buffer from buffer pool.
/// @param provider The buffer provider
+ (void)clearBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider;

@end
