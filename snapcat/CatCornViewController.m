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

typedef NS_ENUM(NSInteger, CatCornViewControllerState) {
    CatCornViewControllerStateUndefined,
    CatCornViewControllerStateLocalSave,
    CatCornViewControllerStateBoxSave,
    CatCornViewControllerStateLocalPicker,
    CatCornViewControllerStateBoxPicker,    
};
 

@interface CatCornViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, BoxFolderPickerDelegate>
@property (nonatomic, strong) UIImageView *catImageView;
@property (nonatomic, strong) UIImageView *unicornImageView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *btnSaveBackToPhotoLibrary;
@property (nonatomic, strong) UIBarButtonItem *btnSaveBackToBox;
@property (nonatomic, strong) UIBarButtonItem *btnPickFromBox;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIActivityIndicatorView *activitySpinner;

@property (nonatomic, strong) BoxFolderPickerViewController *photoPicker;
@property (nonatomic, strong) BoxFolderPickerViewController *destinationChooser;
@property (nonatomic, assign) CatCornViewControllerState state;

@property (nonatomic, strong) BoxFile *boxFile;
@property (nonatomic, strong) BoxFilesResourceManager *filesRM;

@end

@implementation CatCornViewController
- (id)init
{
    self = [super init];
    if (self) {
        self.state = CatCornViewControllerStateUndefined;
    }
    
    return self;
}

- (void)setupToolbar
{
    UIBarButtonItem *btnCameraRoll = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                   target:self
                                                                                   action:@selector(btnCameraRollSelected:)];    
    btnCameraRoll.style = UIBarButtonItemStyleBordered;
    btnCameraRoll.tintColor = [UIColor blackColor];
    
    self.btnSaveBackToPhotoLibrary = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                   target:self
                                                                                   action:@selector(btnSaveSelected:)];
    
    self.btnSaveBackToPhotoLibrary.style = UIBarButtonItemStyleBordered;
    self.btnSaveBackToPhotoLibrary.tintColor = [UIColor blackColor];
    self.btnSaveBackToPhotoLibrary.enabled = NO;
    
    self.btnSaveBackToBox = [[UIBarButtonItem alloc] initWithTitle:@"Save back to Box"
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(btnSaveBackToBoxSelected:)];
    self.btnSaveBackToBox.enabled = NO;
    self.btnSaveBackToBox.tintColor = [UIColor blackColor];
    
    
    self.btnPickFromBox = [[UIBarButtonItem alloc] initWithTitle:@"Pick from Box"
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(btnPickFromBoxSelected:)];
    self.btnPickFromBox.tintColor = [UIColor blackColor];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] 
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                      target:nil 
                                      action:nil];
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithObjects:btnCameraRoll, self.btnPickFromBox, flexibleSpace, self.btnSaveBackToBox, self.btnSaveBackToPhotoLibrary, nil];
    
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.tintColor = [UIColor whiteColor];
    [self.toolbar setItems:toolbarItems];

    [self.view addSubview:self.toolbar];
}

- (void)setupImageViews
{
    self.unicornImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unicorn"]];
    self.unicornImageView.contentMode = UIViewContentModeScaleToFill;
    self.unicornImageView.hidden = YES;
    self.unicornImageView.frame = CGRectMake(0, 0, 80, 128);
        
    self.catImageView = [[UIImageView alloc] init];
    self.catImageView.backgroundColor = [UIColor clearColor];
    self.catImageView.contentMode = UIViewContentModeScaleAspectFit;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandler:)];
    doubleTap.numberOfTapsRequired = 1;
    self.catImageView.userInteractionEnabled = YES;
    [self.catImageView addGestureRecognizer:doubleTap];

    [self.view addSubview:self.catImageView];    
    [self.view addSubview:self.unicornImageView];
}

- (void)setupImagePicker
{
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupToolbar];
    [self setupImageViews];
    [self setupImagePicker];

    self.activitySpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:self.activitySpinner];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BoxFilesResourceManager *)filesRM
{
    if (_filesRM == nil) {
        _filesRM = [[BoxSDK sharedSDK] filesManager];
    }
    return _filesRM;
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

    CGRect rect = self.view.bounds;
    // The activity indicator frame is going to be our start point to start drawing whatever the frame size is.
    self.activitySpinner.center = CGPointMake(floor(rect.size.width * 0.5f), floor(rect.size.height * 0.5f));

}


#pragma mark UIImagePickerController delegate handlers
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{    
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
        self.catImageView.image = originalImage;
        self.state = CatCornViewControllerStateUndefined;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Cancelled");
        self.state = CatCornViewControllerStateUndefined;
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
    self.btnSaveBackToBox.enabled = YES;
}


- (void)btnPickFromBoxSelected:(id)sender
{
    self.state = CatCornViewControllerStateBoxPicker;
    UINavigationController *controller = [[BoxFolderPickerNavigationController alloc] initWithRootViewController:self.photoPicker];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)btnSaveBackToBoxSelected:(id)sender
{
    self.state = CatCornViewControllerStateBoxSave;
    self.btnSaveBackToBox.enabled = NO;
    UINavigationController *controller = [[BoxFolderPickerNavigationController alloc] initWithRootViewController:self.destinationChooser];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark helpers
- (void)btnCameraRollSelected:(id)sender
{
    self.state = CatCornViewControllerStateLocalPicker;    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)btnSaveSelected:(id)sender
{
    self.state = CatCornViewControllerStateLocalSave;
    self.btnSaveBackToPhotoLibrary.enabled = NO;
    UIImage *image = [self renderCatCornImage];
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:[image CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"Failed to save image %@ to photo album", image);
            self.state = CatCornViewControllerStateUndefined;
        }
    }];
    
}

#pragma mark button handler
- (NSData *)renderCarCornImageData
{   
    UIImage *image = [self renderCatCornImage];
    return UIImageJPEGRepresentation(image, 1);
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

- (void)updateCatCornCanvasWithBoxFile:(BoxFile *)file
{
    [self.activitySpinner startAnimating];
    
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:file.SHA1];
    NSOutputStream *outputStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];

    [self.filesRM downloadFileWithID:file.modelID
                        outputStream:outputStream
                      requestBuilder:nil
                             success:^(NSString *fileID, long long expectedTotalBytes) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.catImageView.image = [UIImage imageWithContentsOfFile:filePath];
                                     self.state = CatCornViewControllerStateUndefined;
                                     [self.activitySpinner stopAnimating];
                                 });
                             } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.state = CatCornViewControllerStateUndefined;
                                     [self.activitySpinner stopAnimating];
                                 });
                             }];    
}

- (void)uploadCatCornImageToBoxFolder:(BoxFolder *)folder withName:(NSString *)name
{
    [self.activitySpinner startAnimating];
    
    NSData *uploadData = [self renderCarCornImageData];
    
    BoxFilesRequestBuilder *requestBuilder = [[BoxFilesRequestBuilder alloc] init];
    requestBuilder.parentID = folder.modelID;
    requestBuilder.name = name;

    [self.filesRM uploadFileWithData:uploadData
                      requestBuilder:requestBuilder
                             success:^(BoxFile *file) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.btnSaveBackToBox.enabled = YES;  
                                     self.state = CatCornViewControllerStateUndefined;
                                     [self.activitySpinner stopAnimating];
                                 });   
                             }
                             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSDictionary *JSONDictionary) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.btnSaveBackToBox.enabled = YES; 
                                     self.state = CatCornViewControllerStateUndefined;
                                     [self.activitySpinner stopAnimating];
                                 });
                             }];

}

#pragma mark BoxFolderPickerDelegate
- (void)folderPickerController:(BoxFolderPickerViewController *)controller didSelectBoxItem:(BoxItem *)item
{
    [self dismissViewControllerAnimated:YES completion:nil];    
    if (self.state == CatCornViewControllerStateBoxPicker) {
        if ([item isKindOfClass:[BoxFile class]]) {
            self.boxFile = (BoxFile*) item;
            [self updateCatCornCanvasWithBoxFile:self.boxFile];

        }
    } else  if (self.state == CatCornViewControllerStateBoxSave){
        if ([item isKindOfClass:[BoxFolder class]]) {     
            NSString *fileName = [[self.boxFile.name stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"_Unicorn.jpg"];

            // happens when user started not from box, but from local library
            if (fileName == nil) {
                fileName = @"Unnamed+Unicorn.jpg";
            }
            
            [self uploadCatCornImageToBoxFolder:(BoxFolder *)item withName:fileName];
        }
    } else {
        NSLog(@"Unexpected state %d", self.state);
    }
}

- (void)folderPickerControllerDidCancel:(BoxFolderPickerViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.state = CatCornViewControllerStateUndefined;
    if (self.catImageView.image != nil) {
        self.btnSaveBackToBox.enabled = YES;
    }
}

@end
