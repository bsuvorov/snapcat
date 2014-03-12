//
//  CatCornViewController.m
//  snapcat
//
//  Created by Boris Suvorov on 3/11/14.
//  Copyright (c) 2014 SnapCatBox. All rights reserved.
//

#import "CatCornViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <BoxSDK/BoxSDK.h>
#import "BOXAccountService.h"
#import <BoxSDK/BoxFolderPickerViewController.h>

@interface CatCornViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, BoxFolderPickerDelegate>
@property (nonatomic, strong) UIImageView *catImageView;
@property (nonatomic, strong) UIImageView *unicornImageView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIBarButtonItem *btnSaveBackToPhotoLibrary;
@property (nonatomic, strong) UIBarButtonItem *btnPickFromBox;
@property (nonatomic, strong) BoxFolderPickerViewController *photoPicker;
@property (nonatomic, strong) BoxFolderPickerViewController *destinationChooser;

@end

@implementation CatCornViewController
- (id)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *btnCameraRoll = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                   target:self
                                                                                   action:@selector(btnCameraRollSelected:)];    
    btnCameraRoll.style = UIBarButtonItemStyleBordered;
    btnCameraRoll.tintColor = [UIColor blackColor];

    self.btnSaveBackToPhotoLibrary = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                     target:self
                                                                     action:@selector(btnSaveSelected:)];

    self.btnPickFromBox = [[UIBarButtonItem alloc] initWithTitle:@"Pick from Box" style:UIBarButtonItemStylePlain target:self action:@selector(btnPickFromBoxSelected:)];
    self.btnPickFromBox.tintColor = [UIColor blackColor];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] 
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                      target:nil 
                                      action:nil];
    
    self.unicornImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unicorn"]];
    self.unicornImageView.contentMode = UIViewContentModeScaleToFill;
    self.unicornImageView.hidden = YES;
    self.unicornImageView.frame = CGRectMake(0, 0, 80, 128);
    
    self.btnSaveBackToPhotoLibrary.style = UIBarButtonItemStyleBordered;
    self.btnSaveBackToPhotoLibrary.tintColor = [UIColor blackColor];
    self.btnSaveBackToPhotoLibrary.enabled = NO;
    


    
    self.catImageView = [[UIImageView alloc] init];
    self.catImageView.backgroundColor = [UIColor blueColor];
    self.catImageView.contentMode = UIViewContentModeScaleAspectFit;

    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithObjects:btnCameraRoll, self.btnPickFromBox, flexibleSpace, self.btnSaveBackToPhotoLibrary, nil];

    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.tintColor = [UIColor whiteColor];
    [self.toolbar setItems:toolbarItems];
    
    
    [self.view addSubview:self.catImageView];
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.unicornImageView];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandler:)];
    doubleTap.numberOfTapsRequired = 1;
    self.catImageView.userInteractionEnabled = YES;
    [self.catImageView addGestureRecognizer:doubleTap];
    

}

- (BoxFolderPickerViewController *)destinationChooser
{
    if (_destinationChooser == nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *cachesDirectory = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        _destinationChooser = [[BoxSDK sharedSDK] folderPickerWithRootFolderID:@"0"
                                                      thumbnailsEnabled:YES
                                                   cachedThumbnailsPath:[cachesDirectory absoluteString]
                                                   fileSelectionEnabled:NO];
        _destinationChooser.delegate = self;
    }
    
    return _destinationChooser;
}

- (BoxFolderPickerViewController *)photoPicker
{
    if (_photoPicker == nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *cachesDirectory = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
        _photoPicker = [[BoxSDK sharedSDK] folderPickerWithRootFolderID:@"0"
                                                       thumbnailsEnabled:YES
                                                    cachedThumbnailsPath:[cachesDirectory absoluteString]
                                                    fileSelectionEnabled:YES];
        _photoPicker.delegate = self;
    }
    
    return _photoPicker;
}

- (void)viewDidLayoutSubviews
{
    self.catImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 44);
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44);
}


#pragma mark UIImagePickerController delegate handlers
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{    
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        self.catImageView.image = originalImage;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Cancelled");
    }];
}

- (void)doubleTapHandler:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self.catImageView];

    // center unicorn image to touch of the user
    touchPoint.y -= self.unicornImageView.bounds.size.height/2-20;
    touchPoint.x += 20;
    self.unicornImageView.center = touchPoint;
    self.unicornImageView.hidden = NO;
    self.btnSaveBackToPhotoLibrary.enabled = YES;
}


- (void)btnPickFromBoxSelected:(id)sender
{
    UINavigationController *controller = [[BoxFolderPickerNavigationController alloc] initWithRootViewController:self.photoPicker];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)btnSaveBackToBoxSelected:(id)sender
{
    UINavigationController *controller = [[BoxFolderPickerNavigationController alloc] initWithRootViewController:self.destinationChooser];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark helpers
- (void)btnCameraRollSelected:(id)sender
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)btnSaveSelected:(id)sender
{
    self.btnSaveBackToPhotoLibrary.enabled = NO;
    [self saveImageToCameRoll:[self renderCatCornImage]];
}


#pragma mark button handler

- (void)saveImageToCameRoll:(UIImage *)image
{
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:[image CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"Failed to save image %@ to photo album", image);
        }
    }];
}

- (UIImage *)renderCatCornImage
{
	UIGraphicsBeginImageContextWithOptions(self.catImageView.bounds.size, NO, 0.0);
    [self.catImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), self.unicornImageView.frame.origin.x,self.unicornImageView.frame.origin.y);
    [self.unicornImageView.layer renderInContext:UIGraphicsGetCurrentContext()];    
    UIImage *bitmapImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return bitmapImage;
}

#pragma mark BoxFolderPickerDelegate
- (void)folderPickerController:(BoxFolderPickerViewController *)controller didSelectBoxItem:(BoxItem *)item
{
    if (controller == self.photoPicker) {
        [self dismissViewControllerAnimated:YES completion:nil];    
        if ([item isKindOfClass:[BoxFile class]]) {
            BoxFilesResourceManager *filesRM = [[BoxSDK sharedSDK] filesManager];
            BoxFile *file = (BoxFile *)item;
            
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:file.SHA1];
            
            NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
            [filesRM downloadFileWithID:item.modelID
                           outputStream:outputStream
                         requestBuilder:nil
                                success:^(NSString *fileID, long long expectedTotalBytes) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        NSLog(@"Finished downloading file with ID = %@", fileID);
                                        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
                                        self.catImageView.image = image;
                                    });
                                } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                    NSLog(@"Failed to download file with response = %@, error= %@", response, error);
                                }];
        }
    } else if (controller == self.destinationChooser) {
        
    } else {
        NSLog(@"Unexpected BoxFolderPickerViewController controller %@", controller);
    }
}

- (void)folderPickerControllerDidCancel:(BoxFolderPickerViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
