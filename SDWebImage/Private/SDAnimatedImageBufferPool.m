//
//  SDAnimatedImageBufferPool.m
//  SDWebImage
//
//  Created by 李卓立 on 2021/5/23.
//  Copyright © 2021 Dailymotion. All rights reserved.
//

#import "SDAnimatedImageBufferPool.h"
#import "SDInternalMacros.h"
#import <objc/runtime.h>

// <BufferID, Buffer>, BufferID = Hash(ProviderID, Index>), strog -> weak
static NSMapTable<NSString *, UIImage *> *_globalBufferTable;
// <ProviderID, Indexes>, strong -> strong
static NSMapTable<NSString *, NSMutableIndexSet *> *_globalProviderTable;

static void *kSDAnimatedImageProviderIDKey = &kSDAnimatedImageProviderIDKey;

SD_LOCK_DECLARE_STATIC(_globalBufferTableLock);
SD_LOCK_DECLARE_STATIC(_globalProviderTableLock);

static inline NSString * SDCalculateOptionsHash(SDImageFrameOptions *options) {
    NSMutableString *optionsHash = [NSMutableString string];
    [options enumerateKeysAndObjectsUsingBlock:^(SDImageFrameOption  _Nonnull key, id  _Nonnull option, BOOL * _Nonnull stop) {
        [optionsHash appendFormat:@"-%@(%@)", key, option];
    }];
    return [optionsHash copy];
}

static inline NSString * SDCalculateProviderID(id<SDAnimatedImageProvider> provider) {
    NSString *providerID = objc_getAssociatedObject(provider, &kSDAnimatedImageProviderIDKey);
    if (providerID) {
        return providerID;
    }
    NSUInteger frameCount = provider.animatedImageFrameCount;
    SDImageFrameOptions *supportedFrameOptions = provider.supportedFrameOptions;
    
    NSData *imageData = provider.animatedImageData;
    // 80 Bytes hashing, acceptable speed
    // https://stackoverflow.com/questions/10768467/how-does-nsdatas-implementation-of-the-hash-method-work
    NSUInteger dataHash = [imageData hash];
    NSString *optionsHash = SDCalculateOptionsHash(supportedFrameOptions);
    
    // Final hash string
    providerID = [NSString stringWithFormat:@"data(%lu)-frame(%lu)%@", dataHash, frameCount, optionsHash];
    
    objc_setAssociatedObject(provider, &kSDAnimatedImageProviderIDKey, providerID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return providerID;
}

static inline NSString * SDCalculateBufferID(NSString *providerID, NSUInteger index) {
    // Final hash string
    return [providerID stringByAppendingFormat:@":%lu", index];
}

@implementation SDAnimatedImageBufferPool

+ (void)initialize {
    _globalBufferTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    _globalProviderTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
    SD_LOCK_INIT(_globalBufferTableLock);
    SD_LOCK_INIT(_globalProviderTableLock);
}

+ (UIImage *)bufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index {
    NSParameterAssert(provider);
    NSString *providerID = SDCalculateProviderID(provider);
    NSString *bufferID = SDCalculateBufferID(providerID, index);
    SD_LOCK(_globalBufferTableLock);
    UIImage *buffer = [_globalBufferTable objectForKey:bufferID];
    SD_UNLOCK(_globalBufferTableLock);
    
//    // Update index, slow but not necessary
//    SD_LOCK(_globalProviderTableLock);
//    NSMutableIndexSet *indexes = [_globalProviderTable objectForKey:providerID];
//    NSAssert(indexes, @"Provider is not registered in buffer pool. Call `+registerProvider:` before using %@", NSStringFromSelector(_cmd));
//    if (!buffer) {
//        [indexes removeIndex:index];
//    } else {
//        [indexes addIndex:index];
//    }
//    SD_UNLOCK(_globalProviderTableLock);
    
    return buffer;
}

+ (void)setBuffer:(UIImage *)buffer forProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index {
    NSParameterAssert(provider);
    if (!buffer) {
        return [self removeBufferForProvider:provider index:index];
    }
    NSString *providerID = SDCalculateProviderID(provider);
    NSString *bufferID = SDCalculateBufferID(providerID, index);
    
    // Store buffer
    [_globalBufferTable setObject:buffer forKey:bufferID];
    
    // Update index
    SD_LOCK(_globalProviderTableLock);
    NSMutableIndexSet *indexes = [_globalProviderTable objectForKey:providerID];
    if (!indexes) {
        indexes = [NSMutableIndexSet indexSetWithIndex:index];
        [_globalProviderTable setObject:indexes forKey:providerID];
    } else {
        [indexes addIndex:index];
    }
    SD_UNLOCK(_globalProviderTableLock);
}

+ (void)removeBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index {
    NSParameterAssert(provider);
    NSString *providerID = SDCalculateProviderID(provider);
    NSString *bufferID = SDCalculateBufferID(providerID, index);
    
    // Store buffer
    [_globalBufferTable removeObjectForKey:bufferID];
    
    // Update index
    SD_LOCK(_globalProviderTableLock);
    NSMutableIndexSet *indexes = [_globalProviderTable objectForKey:providerID];
    if (!indexes) {
        indexes = [NSMutableIndexSet indexSetWithIndex:index];
        [_globalProviderTable setObject:indexes forKey:providerID];
    } else {
        [indexes removeIndex:index];
    }
    SD_UNLOCK(_globalProviderTableLock);
}

+ (void)clearBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider {
    NSParameterAssert(provider);
    NSString *providerID = SDCalculateProviderID(provider);
    
    // Query index
    SD_LOCK(_globalProviderTableLock);
    NSMutableIndexSet *indexes = [_globalProviderTable objectForKey:providerID];
    if (!indexes) {
        return;
    }
    NSMutableArray<NSString *> *bufferIDs = [NSMutableArray arrayWithCapacity:indexes.count];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL * _Nonnull stop) {
        NSString *bufferID = SDCalculateBufferID(providerID, index);
        [bufferIDs addObject:bufferID];
    }];
    SD_UNLOCK(_globalProviderTableLock);
    
    // Remove buffer
    SD_LOCK(_globalBufferTableLock);
    for (NSString *bufferID in bufferIDs) {
        [_globalBufferTable removeObjectForKey:bufferID];
    }
    SD_UNLOCK(_globalBufferTableLock);
}

@end
