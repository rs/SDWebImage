//
//  MSStickerView+WebCache.h
//  Xmessage
//
//  Created by Qiao on 16/6/29.
//  Copyright © 2016年 xinmei. All rights reserved.
//
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3
#import <Messages/Messages.h>
#import "SDWebImageCompat.h"
#import "SDWebImageManager.h"

@interface MSStickerView (WebCache)

- (void)sd_setStickerWithURL:(NSURL *)url
          placeholderSticker:(MSSticker *)placeholder
                     options:(SDWebImageOptions)options
                    progress:(SDWebImageDownloaderProgressBlock)progressBlock
                   completed:(SDWebImageCompletionBlock)completedBlock;
@end
#endif
