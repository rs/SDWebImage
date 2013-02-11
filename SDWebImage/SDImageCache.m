/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCache.h"
#import "SDWebImageDecoder.h"
#import <CommonCrypto/CommonDigest.h>
#import "SDWebImageDecoder.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@interface SDImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t ioQueue;

@end


@implementation SDImageCache

+ (SDImageCache *)sharedImageCache
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns
{
    if ((self = [super init]))
    {
        NSString *fullNamespace = [@"com.hackemist.SDWebImageCache." stringByAppendingString:ns];

        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);

        // Init default values
        _maxCacheAge = kDefaultCacheMaxCacheAge;

        // Init the memory cache
        _memCache = [[NSCache alloc] init];
        _memCache.name = fullNamespace;

        // Init the disk cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];

#if TARGET_OS_IPHONE
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SDDispatchQueueRelease(_ioQueue);
}

#pragma mark SDImageCache (private)

- (NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];

    return [self.diskCachePath stringByAppendingPathComponent:filename];
}

#pragma mark ImageCache

- (void)storeRedirect:(NSString*)redirect forKey:(NSString*)key toDisk:(BOOL)toDisk
{
    if (!redirect || !key)
    {
        return;
    }
    
    if (redirect)
        [self.memCache setObject:redirect forKey:key];
    
    if (toDisk)
    {
        dispatch_async(self.ioQueue, ^
                       {
                           // Can't use defaultManager another thread
                           NSFileManager *fileManager = NSFileManager.new;
                           
                           if (![fileManager fileExistsAtPath:_diskCachePath])
                           {
                               [fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                           }
                       
                       [redirect writeToFile:[self cachePathForKey:key] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                       
                       });
    }
}

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (!image || !key)
    {
        return;
    }

    [self.memCache setObject:image forKey:key cost:image.size.height * image.size.width * image.scale];

    if (toDisk)
    {
        dispatch_async(self.ioQueue, ^
        {
            NSData *data = imageData;

            if (!data)
            {
                if (image)
                {
#if TARGET_OS_IPHONE
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
#else
                    data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
                }
            }

            if (data)
            {
                // Can't use defaultManager another thread
                NSFileManager *fileManager = NSFileManager.new;

                if (![fileManager fileExistsAtPath:_diskCachePath])
                {
                    [fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }

                [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
            }
        });
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    [self storeImage:image imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk];
}

- (id)imageFromMemoryCacheForKey:(NSString *)key
{
    return [self.memCache objectForKey:key];
}

- (void)queryDiskCacheForKey:(NSString *)key done:(void (^)(UIImage *image, NSString *redirect, SDImageCacheType cacheType))doneBlock
{
    if (!doneBlock) return;

    if (!key)
    {
        doneBlock(nil, nil,SDImageCacheTypeNone);
        return;
    }

    // First check the in-memory cache...
    id imageOrRedirect = [self imageFromMemoryCacheForKey:key];
    if (imageOrRedirect)
    {
        // Check if it's an image.
        if ([imageOrRedirect isKindOfClass:[UIImage class]])
        {
            doneBlock(imageOrRedirect, nil, SDImageCacheTypeMemory);
            return;
        }
        
        // Check if it's a redirect
        if ([imageOrRedirect isKindOfClass:[NSString class]])
        {
            doneBlock(nil, imageOrRedirect, SDImageCacheTypeMemory);
            return;
        }
        
        //If it's neither, something went wrong. Delete the object from memory and continue.
        [self removeImageForKey:key fromDisk:NO];
    }

    dispatch_async(self.ioQueue, ^
    {
        NSData *diskData = [NSData dataWithContentsOfFile:[self cachePathForKey:key]];
        UIImage *diskImage = nil;
        NSString *diskRedirect = nil;
        
        if (diskData)
        {
            // The NSData object represents an image or a redirect string.
            
            // Check for the image first.
            diskImage = [UIImage decodedImageWithImage:SDScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]])];

            // If the file doesn't contain an UIImage, then we will get NSNull.
            if (diskImage != nil && ![diskImage isEqual:[NSNull null]])
            {
                CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
                [self.memCache setObject:diskImage forKey:key cost:cost];
            }
            else // It could be a redirect.
            {
                diskRedirect = [[NSString alloc] initWithData:diskData encoding:NSUTF8StringEncoding];

                if (diskRedirect)
                    [self.memCache setObject:diskRedirect forKey:key];
            }
            
            // Check if the file is valid and delete it if not.
            if (!diskImage && !diskRedirect)
            {
                // Can't use defaultManager another thread
                NSFileManager *fileManager = NSFileManager.new;
                [fileManager removeItemAtPath:[self cachePathForKey:key] error:nil];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            doneBlock(diskImage, diskRedirect, SDImageCacheTypeDisk);
        });
    });
}

- (void)removeImageForKey:(NSString *)key
{
    [self removeImageForKey:key fromDisk:YES];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk
{
    if (key == nil)
    {
        return;
    }

    [self.memCache removeObjectForKey:key];

    if (fromDisk)
    {
        dispatch_async(self.ioQueue, ^
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
        });
    }
}

- (void)clearMemory
{
    [self.memCache removeAllObjects];
}

- (void)clearDisk
{
    dispatch_async(self.ioQueue, ^
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    });
}

- (void)cleanDisk
{
    dispatch_async(self.ioQueue, ^
    {
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator)
        {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate])
            {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
        }
    });
}

-(int)getSize
{
    int size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (int)getDiskCount
{
    int count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        count += 1;
    }
    
    return count;
}

@end
