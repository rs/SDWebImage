/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <QuartzCore/CALayer.h>

#import "SDWebImageCompat.h"
#import "SDWebImageManager.h"

/**
 * Integrates SDWebImage async downloading and caching of remote images with CALayer.
 *
 */
@interface CALayer (WebCache)

/**
 * Set the layer `contents` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 */
- (void)setContentsWithURL:(NSURL *)url;

/**
 * Set the layer `contents` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @see setContentsWithURL:placeholderImage:options:
 */
- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

/**
 * Set the layer `contents` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;

/**
 * Set the layer `contents` with an `url`.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setContentsWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock;

/**
 * Set the layer `contents` with an `url`, placeholder.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock;

/**
 * Set the layer `contents` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock;

/**
 * Set the layer `contents` with an `url`, placeholder and custom options.
 *
 * The downloand is asynchronous and cached.
 *
 * @param url The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param progressBlock A block called while image is downloading
 * @param completedBlock A block called when operation has been completed. This block as no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 */
- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock;

/**
 * Cancel the current download
 */
- (void)cancelCurrentImageLoad;

@end
