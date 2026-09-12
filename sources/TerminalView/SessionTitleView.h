//
//  SessionTitleView.h
//  iTerm
//
//  Created by George Nachman on 10/21/11.
//  Copyright 2011 George Nachman. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTermStatusBarViewController.h"

@protocol PSMPUAFontProvider;

@protocol SessionTitleViewDelegate <NSObject>

- (NSMenu *)menu;
- (void)close;
- (void)beginDrag;
- (void)doubleClickOnTitleView;
- (void)sessionTitleViewBecomeFirstResponder;
- (NSColor *)sessionTitleViewBackgroundColor;
- (BOOL)sessionTitleViewIsLocked;
- (void)sessionTitleViewToggleLock;
- (BOOL)sessionTitleViewCanCollapse;
- (void)sessionTitleViewToggleCollapse;

@end

@interface SessionTitleView : NSView<iTermStatusBarContainer>

@property(nonatomic, copy) NSString *title;
@property(nonatomic, weak) id<SessionTitleViewDelegate> delegate;
@property(nonatomic, assign) double dimmingAmount;
@property(nonatomic, assign) int ordinal;
@property(nonatomic, weak) id<PSMPUAFontProvider> puaFontProvider;
// Set while the pane is collapsed to its title bar. The chevron reflects it and the
// view becomes the first responder in place of the hidden terminal.
@property(nonatomic) BOOL collapsed;

- (void)updateTextColor;
- (void)updateBackgroundColor;
- (void)updateLockButton;
- (void)updateCollapseButton;
- (void)invalidateTitleFont;

@end
