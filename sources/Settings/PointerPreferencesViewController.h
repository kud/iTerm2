//
//  PointerPreferencesViewController.h
//  iTerm
//
//  Created by George Nachman on 4/7/14.
//
//

#import "iTermPreferencesBaseViewController.h"

extern NSString *const kPointerPrefsChangedNotification;
extern NSString *const kPointerPrefsSemanticHistoryEnabledChangedNotification;

NS_ASSUME_NONNULL_BEGIN

@class PointerPrefsController;

@interface PointerPreferencesViewController : iTermPreferencesBaseViewController

// Settings panes are moving out of PreferencePanel.xib into code, one at a time. While both
// builds of this pane exist, the NoSyncSettingsPointerPaneInCode user default selects the
// code-built one.
@property(nonatomic, readonly) BOOL viewIsBuiltInCode;
@property(nonatomic, readonly, nullable) PointerPrefsController *pointerPrefsController;
// Replaces the nib-loaded view with the code-built one when the user default is set. Idempotent.
- (void)loadViewInCodeIfEnabled;
// Builds the pane in code and defines its controls whatever the user default says. For the
// nib/code comparison test only: the bindings table points at pointerPrefsController but does
// not replace its nib-loaded table.
- (void)loadViewInCodeAndDefineControlsForTestingWithPointerPrefsController:(nullable PointerPrefsController *)pointerPrefsController
    NS_SWIFT_NAME(loadViewInCodeAndDefineControlsForTesting(pointerPrefsController:));

@end

NS_ASSUME_NONNULL_END
