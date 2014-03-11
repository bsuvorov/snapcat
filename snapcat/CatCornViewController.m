//
//  CatCornViewController.m
//  snapcat
//
//  Created by Boris Suvorov on 3/11/14.
//  Copyright (c) 2014 SnapCatBox. All rights reserved.
//

#import "CatCornViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CatCornViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) UIImageView *catImageView;
@property (nonatomic, strong) UIImageView *unicornImageView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIBarButtonItem *btnSaveBack;
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

    self.btnSaveBack = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                     target:self
                                                                     action:@selector(btnSaveSelected:)];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] 
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                      target:nil 
                                      action:nil];
    
    self.unicornImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Unicorn"]];
    self.unicornImageView.contentMode = UIViewContentModeScaleToFill;
    self.unicornImageView.hidden = YES;
    self.unicornImageView.frame = CGRectMake(0, 0, 80, 128);
    
    self.btnSaveBack.style = UIBarButtonItemStyleBordered;
    self.btnSaveBack.tintColor = [UIColor blackColor];
    self.btnSaveBack.enabled = NO;
    
    btnCameraRoll.style = UIBarButtonItemStyleBordered;
    btnCameraRoll.tintColor = [UIColor blackColor];
    
    self.catImageView = [[UIImageView alloc] init];
    self.catImageView.backgroundColor = [UIColor blueColor];
    self.catImageView.contentMode = UIViewContentModeScaleAspectFit;

    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    
    NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithObjects:btnCameraRoll, flexibleSpace, self.btnSaveBack, nil];

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

- (void)viewDidLayoutSubviews
{
    self.catImageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 44);
    self.toolbar.frame = CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44);
}

- (void)btnCameraRollSelected:(id)sender
{
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)btnSaveSelected:(id)sender
{
    self.btnSaveBack.enabled = NO;
    [self saveImageToCameRoll:[self renderCatCornImage]];
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

- (void)saveImageToCameRoll:(UIImage *)image
{
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeImageToSavedPhotosAlbum:[image CGImage] metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        if(error) {
            NSLog(@"Failed to save image %@ to photo album", image);
        }
    }];
}

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
    self.btnSaveBack.enabled = YES;
}

@end
