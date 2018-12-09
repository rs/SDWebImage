/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

/**
 Return the memory cache cost for specify image. The cost function is the bytes size held in memory.
 
 For `UIImage`, this method return the single frame bytes size when `image.images` is nil for static image. Retuen full bytes per frame * frame count when `image.images` is not nil for animated image.
 For `NSImage`, this method return the single frame bytes size because `NSImage` does not store all frames in memory.
 For custom animated class conforms to `SDAnimatedImage` and implements `animatedImageMemoryCost` method, return that value instead.
 For any other case which cause the image's CGImage bitmap representation invalid (for example, vector image), return 0;

 @param image The image to store in cache
 @return The memory cost for the image
 */
FOUNDATION_EXPORT NSUInteger SDMemoryCacheCostForImage(UIImage * _Nullable image);

@class SDImageCacheConfig;
// A protocol to allow custom memory cache used in SDImageCache.
@protocol SDMemoryCache <NSObject>

@required
/**
 Create a new memory cache instance with the specify cache config. You can check `maxMemoryCost` and `maxMemoryCount` used for memory cache.

 @param config The cache config to be used to create the cache.
 @return The new memory cache instance.
 */
- (nonnull instancetype)initWithConfig:(nonnull SDImageCacheConfig *)config;

/**
 Returns the value associated with a given key.
 
 @param key An object identifying the value. If nil, just return nil.
 @return The value associated with key, or nil if no value is associated with key.
 */
- (nullable id)objectForKey:(nonnull id)key;

/**
 Sets the value of the specified key in the cache (0 cost).
 
 @param object The object to be stored in the cache. If nil, it calls `removeObjectForKey:`.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 @discussion Unlike an NSMutableDictionary object, a cache does not copy the key
 objects that are put into it.
 */
- (void)setObject:(nullable id)object forKey:(nonnull id)key;

/**
 Sets the value of the specified key in the cache, and associates the key-value
 pair with the specified cost.
 
 @param object The object to store in the cache. If nil, it calls `removeObjectForKey`.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 @param cost   The cost with which to associate the key-value pair.
 @discussion Unlike an NSMutableDictionary object, a cache does not copy the key
 objects that are put into it.
 */
- (void)setObject:(nullable id)object forKey:(nonnull id)key cost:(NSUInteger)cost;

/**
 Removes the value of the specified key in the cache.
 
 @param key The key identifying the value to be removed. If nil, this method has no effect.
 */
- (void)removeObjectForKey:(nonnull id)key;

/**
 Empties the cache immediately.
 */
- (void)removeAllObjects;

@end

// A memory cache which auto purge the cache on memory warning and support weak cache.
@interface SDMemoryCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType> <SDMemoryCache>

@property (nonatomic, strong, nonnull, readonly) SDImageCacheConfig *config;

@end
