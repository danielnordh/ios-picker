//
//  FPNavigationController.m
//  FPPicker
//
//  Created by Ruben Nine on 22/08/14.
//  Copyright (c) 2014 Filepicker.io. All rights reserved.
//

#import "FPNavigationController.h"
#import "FPRepresentedSource.h"
#import "FPNavigationHistory.h"

typedef enum : NSUInteger
{
    FPNavigateBackDirection = 0,
    FPNavigateForwardDirection = 1
} FPNavigationDirection;

@interface FPNavigationController ()

@property (nonatomic, weak) IBOutlet NSPopUpButton *currentDirectoryPopupButton;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *navigationSegmentedControl;

@property (nonatomic, strong) FPNavigationHistory *navigationHistory;

@end

@implementation FPNavigationController

#pragma mark - Accessors

- (FPNavigationHistory *)navigationHistory
{
    if (!_navigationHistory)
    {
        _navigationHistory = [FPNavigationHistory new];
    }

    return _navigationHistory;
}

- (void)setSourcePath:(FPSourcePath *)sourcePath
{
    _sourcePath = sourcePath;

    if (![self.navigationHistory.currentNavigationItem isEqual:sourcePath])
    {
        [self.navigationHistory addNavigationItem:sourcePath];
        [self refreshNavigationControls];
    }
}

#pragma mark - Public Methods

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self refreshNavigationControls];
}

- (void)clearNavigation
{
    [self.navigationHistory clearNavigation];
    [self refreshNavigationControls];
}

#pragma mark - Actions

- (IBAction)navigate:(id)sender
{
    NSSegmentedControl *segmentedControl = sender;
    FPNavigationDirection direction = segmentedControl.selectedSegment;

    switch (direction)
    {
        case FPNavigateBackDirection:
            [self.navigationHistory navigateBack];

            break;
        case FPNavigateForwardDirection:
            [self.navigationHistory navigateForward];

            break;
        default:
            break;
    }

    [self refreshNavigationControls];

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(navigationChanged:)])
    {
        [self.delegate navigationChanged:[self.navigationHistory currentNavigationItem]];
    }
}

- (IBAction)currentDirectoryPopupButtonSelectionChanged:(id)sender
{
    FPSourcePath *sourcePath = [sender representedObject];

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(navigationChanged:)])
    {
        [self.delegate navigationChanged:sourcePath];
    }
}

#pragma mark - Private Methods

- (void)refreshDirectoriesPopup
{
    [self.currentDirectoryPopupButton removeAllItems];
    self.currentDirectoryPopupButton.autoenablesItems = NO;

    FPSourcePath *tmpSourcePath = [self.sourcePath copy];

    if (!tmpSourcePath)
    {
        return;
    }

    while (true)
    {
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];

        icon.size = NSMakeSize(16, 16);

        NSMenuItem *menuItem = [NSMenuItem new];

        menuItem.title = tmpSourcePath.path.lastPathComponent.stringByRemovingPercentEncoding;
        menuItem.image = icon;
        menuItem.representedObject = tmpSourcePath;
        menuItem.target = self;
        menuItem.action = @selector(currentDirectoryPopupButtonSelectionChanged:);

        [self.currentDirectoryPopupButton.menu addItem:menuItem];

        if ([tmpSourcePath.parentPath isEqualToString:tmpSourcePath.path])
        {
            break;
        }

        tmpSourcePath.path = tmpSourcePath.parentPath;
    }

    if (self.currentDirectoryPopupButton.itemArray.count > 0)
    {
        [self.currentDirectoryPopupButton selectItemAtIndex:0];
    }
}

- (void)refreshNavigationControls
{
    [self.navigationSegmentedControl setEnabled:[self.navigationHistory canNavigateBack]
                                     forSegment:FPNavigateBackDirection];

    [self.navigationSegmentedControl setEnabled:[self.navigationHistory canNavigateForward]
                                     forSegment:FPNavigateForwardDirection];
}

@end
