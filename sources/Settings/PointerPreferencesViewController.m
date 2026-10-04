//
//  PointerPreferencesViewController.m
//  iTerm
//
//  Created by George Nachman on 4/7/14.
//
//

#import "PointerPreferencesViewController.h"
#import "PointerPrefsController.h"
#import "PreferencePanel.h"
#import "iTerm2SharedARC-Swift.h"
#import "iTermSizeRememberingView.h"
#import "iTermUserDefaults.h"

NSString *const kPointerPrefsChangedNotification = @"kPointerPrefsChangedNotification";
NSString *const kPointerPrefsSemanticHistoryEnabledChangedNotification = @"kPointerPrefsSemanticHistoryEnabledChangedNotification";

static NSString *const kPointerPaneInCodeUserDefaultsKey = @"NoSyncSettingsPointerPaneInCode";

@implementation PointerPreferencesViewController {
    IBOutlet NSTabView *_tabView;

    // Cmd-click to launch url.
    IBOutlet NSButton *_cmdSelection;

    // Control-click doesn't open the context menu, is mouse-reported as right click.
    IBOutlet NSButton *_controlLeftClickActsLikeRightClick;
    IBOutlet NSButton *_rightClickActsLikeRightClick;

    // Opt-click moves cursor.
    IBOutlet NSButton *_optionClickMovesCursor;

    // Three finger click emulates middle button.
    IBOutlet NSButton *_threeFingerEmulatesMiddle;

    // Focus follows mouse.
    IBOutlet NSButton *_focusFollowsMouse;

    // Focus on right or middle click
    IBOutlet NSButton *_focusOnRightOrMiddleClick;

    IBOutlet NSButton *_reportHorizontalScrollEvents;

    IBOutlet PointerPrefsController *_pointerPrefsController;

    BOOL _viewIsBuiltInCode;
    NSTableView *_bindingsTableView;
    NSTableColumn *_buttonColumn;
    NSTableColumn *_actionColumn;
    NSButton *_removeBindingButton;
}

- (PointerPrefsController *)pointerPrefsController {
    return _pointerPrefsController;
}

- (void)awakeFromNib {
    [self loadViewInCodeIfEnabled];
    [self defineControls];
}

- (void)loadViewInCodeIfEnabled {
    if (_viewIsBuiltInCode) {
        return;
    }
    if (![[iTermUserDefaults userDefaults] boolForKey:kPointerPaneInCodeUserDefaultsKey]) {
        return;
    }
    [self buildViewInCodeWithPointerPrefsController:_pointerPrefsController];
    [_pointerPrefsController setTableView:_bindingsTableView
                             buttonColumn:_buttonColumn
                             actionColumn:_actionColumn
                             removeButton:_removeBindingButton];
}

- (void)loadViewInCodeAndDefineControlsForTestingWithPointerPrefsController:(PointerPrefsController *)pointerPrefsController {
    [self buildViewInCodeWithPointerPrefsController:pointerPrefsController];
    [self defineControls];
}

- (void)defineControls {
    PreferenceInfo *info;

    __weak __typeof(self) weakSelf = self;
    info = [self defineControl:_cmdSelection
                            key:kPreferenceKeyCmdClickOpensURLs
                    relatedView:nil
                           type:kPreferenceInfoTypeCheckbox];
    info.onChange = ^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPointerPrefsSemanticHistoryEnabledChangedNotification
                                                             object:nil];
    };

    [self defineControl:_controlLeftClickActsLikeRightClick
                     key:kPreferenceKeyControlLeftClickBypassesContextMenu
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_rightClickActsLikeRightClick
                     key:kPreferenceKeyRightClickClickBypassesContextMenu
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];

    [self defineControl:_optionClickMovesCursor
                     key:kPreferenceKeyOptionClickMovesCursor
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];

    info = [self defineControl:_threeFingerEmulatesMiddle
                            key:kPreferenceKeyThreeFingerEmulatesMiddle
                    relatedView:nil
                           type:kPreferenceInfoTypeCheckbox];
    info.onChange = ^() {
        [weakSelf postRefreshNotification];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPointerPrefsChangedNotification
                                                             object:nil
                                                           userInfo:nil];
    };

    [self defineControl:_focusFollowsMouse
                     key:kPreferenceKeyFocusFollowsMouse
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_focusOnRightOrMiddleClick
                     key:kPreferenceKeyFocusOnRightOrMiddleClick
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];
    [self defineControl:_reportHorizontalScrollEvents
                     key:kPreferenceKeyReportHorizontalScrollEvents
             relatedView:nil
                    type:kPreferenceInfoTypeCheckbox];
}

#pragma mark - View creation

- (void)buildViewInCodeWithPointerPrefsController:(PointerPrefsController *)pointerPrefsController {
    _viewIsBuiltInCode = YES;

    iTermSizeRememberingView *root =
        [[iTermSizeRememberingView alloc] initWithFrame:NSMakeRect(0, 0, 892, 421)];
    root.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    // -initWithFrame: turns compact metrics on but the nib-decoded view never had them,
    // and this build matches the nib.
#ifdef MAC_OS_VERSION_26_0
    if (@available(macOS 26, *)) {
        root.prefersCompactControlSizeMetrics = NO;
    }
#endif
    [root setAccessibilityIdentifier:@"prefsPointer"];

    NSTabView *tabView = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 10, 879, 417)];
    tabView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    tabView.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    tabView.delegate = self;

    NSTabViewItem *generalItem = [[NSTabViewItem alloc] initWithIdentifier:@"2"];
    generalItem.label = NSLocalizedStringWithDefaultValue(@"PointerPreferences.GeneralTab", nil, [NSBundle mainBundle], @"General", @"Name of the General tab in Settings > Pointer");
    NSView *generalView = [[NSView alloc] initWithFrame:NSMakeRect(10, 33, 859, 371)];
    generalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    iTermPreferencesInnerTabContainerView *generalContainer =
        [[iTermPreferencesInnerTabContainerView alloc] initWithFrame:NSMakeRect(17, 144, 825, 224)];
    generalContainer.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin;

    NSButton *optionClickMovesCursor =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 180, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.OptionClickMovesCursor", nil, [NSBundle mainBundle], @"⌥-Click moves cursor", @"Checkbox in Settings > Pointer > General: option-click moves the text cursor")
                                            toolTip:NSLocalizedStringWithDefaultValue(@"PointerPreferences.OptionClickMovesCursorToolTip", nil, [NSBundle mainBundle], @"If enabled, option-click sends arrow keys to move the cursor's position. If Shell Integration is installed then it does not take effect at the command line.", @"Tooltip for the “⌥-Click moves cursor” checkbox in Settings > Pointer")
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *threeFingerEmulatesMiddle =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 158, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.ThreeFingerTapEmulatesMiddleClick", nil, [NSBundle mainBundle], @"Three-finger tap emulates middle click", @"Checkbox in Settings > Pointer > General: a three-finger tap acts as a middle click")
                                            toolTip:nil
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *cmdSelection =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 202, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.CmdClickOpensFilenameOrURL", nil, [NSBundle mainBundle], @"⌘-Click opens filename/URL (semantic history)", @"Checkbox in Settings > Pointer > General: command-click opens the filename or URL under the pointer")
                                            toolTip:nil
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *focusFollowsMouse =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 124, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.FocusFollowsMouse", nil, [NSBundle mainBundle], @"Focus follows mouse", @"Checkbox in Settings > Pointer > General: keyboard focus follows the mouse pointer")
                                            toolTip:nil
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *focusOnRightOrMiddleClick =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 104, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.FocusWindowAfterRightOrMiddleClick", nil, [NSBundle mainBundle], @"Focus window after right or middle click", @"Checkbox in Settings > Pointer > General: right or middle click also focuses the window")
                                            toolTip:nil
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *reportHorizontalScrollEvents =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 70, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.MouseReportingSupportsHorizontalScrolling", nil, [NSBundle mainBundle], @"Mouse reporting supports horizontal scrolling", @"Checkbox in Settings > Pointer > General: horizontal scroll events are reported to apps that use mouse reporting")
                                            toolTip:NSLocalizedStringWithDefaultValue(@"PointerPreferences.MouseReportingSupportsHorizontalScrollingToolTip", nil, [NSBundle mainBundle], @"When enabled, mouse reporting takes priority over swipe to switch tabs. Disable this if swiping to switch tabs sometimes doesn’t work.", @"Tooltip for the horizontal scrolling mouse reporting checkbox in Settings > Pointer")
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSTextField *clicksLabel =
        [iTermSettingsViewFactory labelWithFrame:NSMakeRect(18, 203, 284, 16)
                                           title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.ClicksLabel", nil, [NSBundle mainBundle], @"Clicks:", @"Section label in Settings > Pointer > General, to the left of the click settings")
                                       alignment:NSTextAlignmentRight
                                autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    NSTextField *focusLabel =
        [iTermSettingsViewFactory labelWithFrame:NSMakeRect(18, 125, 284, 16)
                                           title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.FocusLabel", nil, [NSBundle mainBundle], @"Focus:", @"Section label in Settings > Pointer > General, to the left of the focus settings")
                                       alignment:NSTextAlignmentRight
                                autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    NSTextField *mouseReportingLabel =
        [iTermSettingsViewFactory labelWithFrame:NSMakeRect(18, 71, 284, 16)
                                           title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.MouseReportingLabel", nil, [NSBundle mainBundle], @"Mouse Reporting:", @"Section label in Settings > Pointer > General, to the left of the mouse reporting settings")
                                       alignment:NSTextAlignmentRight
                                autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    NSButton *controlLeftClickActsLikeRightClick =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 48, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.ControlClickReportedToApps", nil, [NSBundle mainBundle], @"^-Click reported to apps, does not open menu", @"Checkbox in Settings > Pointer > General: control-click is sent to apps instead of opening the context menu")
                                            toolTip:NSLocalizedStringWithDefaultValue(@"PointerPreferences.ControlClickReportedToAppsToolTip", nil, [NSBundle mainBundle], @"For terminal applications that use mouse reporting, turning this on allows control-click to be reported instead of opening the context menu.", @"Tooltip for the control-click mouse reporting checkbox in Settings > Pointer")
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    NSButton *rightClickActsLikeRightClick =
        [iTermSettingsViewFactory checkboxWithFrame:NSMakeRect(309, 26, 501, 18)
                                              title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.RightClickReportedToApps", nil, [NSBundle mainBundle], @"Right click reported to apps, does not open menu", @"Checkbox in Settings > Pointer > General: right click is sent to apps instead of opening the context menu")
                                            toolTip:NSLocalizedStringWithDefaultValue(@"PointerPreferences.RightClickReportedToAppsToolTip", nil, [NSBundle mainBundle], @"For terminal applications that use mouse reporting, turning this on allows right click (or two finger tap on a trackpad) to be reported instead of opening the context menu.", @"Tooltip for the right-click mouse reporting checkbox in Settings > Pointer")
                                   autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                             target:self
                                             action:@selector(settingChanged:)];
    [generalContainer addSubview:optionClickMovesCursor];
    [generalContainer addSubview:threeFingerEmulatesMiddle];
    [generalContainer addSubview:cmdSelection];
    [generalContainer addSubview:focusFollowsMouse];
    [generalContainer addSubview:focusOnRightOrMiddleClick];
    [generalContainer addSubview:reportHorizontalScrollEvents];
    [generalContainer addSubview:clicksLabel];
    [generalContainer addSubview:focusLabel];
    [generalContainer addSubview:mouseReportingLabel];
    [generalContainer addSubview:controlLeftClickActsLikeRightClick];
    [generalContainer addSubview:rightClickActsLikeRightClick];
    [generalView addSubview:generalContainer];
    generalItem.view = generalView;
    _optionClickMovesCursor = optionClickMovesCursor;
    _threeFingerEmulatesMiddle = threeFingerEmulatesMiddle;
    _cmdSelection = cmdSelection;
    _focusFollowsMouse = focusFollowsMouse;
    _focusOnRightOrMiddleClick = focusOnRightOrMiddleClick;
    _reportHorizontalScrollEvents = reportHorizontalScrollEvents;
    _controlLeftClickActsLikeRightClick = controlLeftClickActsLikeRightClick;
    _rightClickActsLikeRightClick = rightClickActsLikeRightClick;

    NSTabViewItem *bindingsItem = [[NSTabViewItem alloc] initWithIdentifier:@"1"];
    bindingsItem.label = NSLocalizedStringWithDefaultValue(@"PointerPreferences.BindingsTab", nil, [NSBundle mainBundle], @"Bindings", @"Name of the Bindings tab in Settings > Pointer, which lists actions bound to mouse buttons and gestures");
    NSView *bindingsView = [[NSView alloc] initWithFrame:NSMakeRect(10, 33, 859, 371)];
    bindingsView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    iTermPreferencesInnerTabContainerView *bindingsContainer =
        [[iTermPreferencesInnerTabContainerView alloc] initWithFrame:NSMakeRect(0, 34, 891, 334)];
    bindingsContainer.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin;

    NSButton *removeBindingButton =
        [iTermSettingsViewFactory smallSquareButtonWithFrame:NSMakeRect(40, 19, 21, 23)
                                                       title:@""
                                                       image:[NSImage imageNamed:NSImageNameRemoveTemplate]
                                            autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                                      target:pointerPrefsController
                                                      action:@selector(remove:)];
    if (pointerPrefsController) {
        [removeBindingButton bind:NSEnabledBinding
                         toObject:pointerPrefsController
                      withKeyPath:@"self.hasSelection"
                          options:nil];
    }
    NSButton *addBindingButton =
        [iTermSettingsViewFactory smallSquareButtonWithFrame:NSMakeRect(20, 19, 21, 23)
                                                       title:@""
                                                       image:[NSImage imageNamed:NSImageNameAddTemplate]
                                            autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                                      target:pointerPrefsController
                                                      action:@selector(add:)];

    NSScrollView *bindingsScrollView =
        [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 49, 851, 285)];
    bindingsScrollView.autoresizingMask = NSViewMaxXMargin | NSViewMinYMargin;
    bindingsScrollView.borderType = NSBezelBorder;
    bindingsScrollView.hasVerticalScroller = YES;
    bindingsScrollView.hasHorizontalScroller = YES;
    bindingsScrollView.autohidesScrollers = YES;
    bindingsScrollView.horizontalLineScroll = 19;
    bindingsScrollView.horizontalPageScroll = 10;
    bindingsScrollView.verticalLineScroll = 19;
    bindingsScrollView.verticalPageScroll = 10;
    bindingsScrollView.usesPredominantAxisScrolling = NO;

    NSTableView *bindingsTableView =
        [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 849, 283)];
    bindingsTableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [bindingsTableView setContentHuggingPriority:NSLayoutPriorityDefaultHigh
                                  forOrientation:NSLayoutConstraintOrientationVertical];
    bindingsTableView.allowsExpansionToolTips = YES;
    bindingsTableView.columnAutoresizingStyle = NSTableViewNoColumnAutoresizing;
    bindingsTableView.allowsColumnReordering = NO;
    bindingsTableView.allowsColumnResizing = NO;
    bindingsTableView.allowsMultipleSelection = NO;
    bindingsTableView.autosaveTableColumns = NO;
    bindingsTableView.intercellSpacing = NSMakeSize(3, 2);
    bindingsTableView.rowHeight = 17;
    bindingsTableView.backgroundColor = [NSColor controlBackgroundColor];
    bindingsTableView.gridColor = [NSColor gridColor];
    bindingsTableView.headerView = nil;
    bindingsTableView.dataSource = (id<NSTableViewDataSource>)pointerPrefsController;
    bindingsTableView.delegate = (id<NSTableViewDelegate>)pointerPrefsController;
    bindingsTableView.target = pointerPrefsController;
    bindingsTableView.doubleAction = NSSelectorFromString(@"tableViewRowDoubleClicked:");

    // The nib compiler assigns AutomaticTableColumnIdentifier.N to a column with no identifier.
    NSTableColumn *actionColumn =
        [[NSTableColumn alloc] initWithIdentifier:@"AutomaticTableColumnIdentifier.0"];
    actionColumn.width = 525.5;
    actionColumn.minWidth = 10;
    actionColumn.maxWidth = FLT_MAX;
    actionColumn.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    actionColumn.title = NSLocalizedStringWithDefaultValue(@"PointerPreferences.ActionColumnHeader", nil, [NSBundle mainBundle], @"Action", @"Column header in Settings > Pointer > Bindings: the action a binding performs");
    actionColumn.headerCell.lineBreakMode = NSLineBreakByTruncatingTail;
    actionColumn.headerCell.alignment = NSTextAlignmentLeft;
    actionColumn.headerCell.textColor = [NSColor headerTextColor];
    // +headerColor is deprecated; the nib decodes the same catalog color by name.
    actionColumn.headerCell.backgroundColor = [NSColor colorWithCatalogName:@"System" colorName:@"headerColor"];
    NSTextFieldCell *actionDataCell = [[NSTextFieldCell alloc] init];
    // Localization unneeded
    actionDataCell.stringValue = @"Text Cell";
    actionDataCell.lineBreakMode = NSLineBreakByTruncatingTail;
    actionDataCell.selectable = YES;
    actionDataCell.editable = YES;
    actionDataCell.alignment = NSTextAlignmentLeft;
    actionDataCell.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    actionDataCell.textColor = [NSColor controlTextColor];
    actionDataCell.backgroundColor = [NSColor controlBackgroundColor];
    actionColumn.dataCell = actionDataCell;

    NSTableColumn *buttonColumn =
        [[NSTableColumn alloc] initWithIdentifier:@"AutomaticTableColumnIdentifier.1"];
    buttonColumn.width = 279.5;
    buttonColumn.minWidth = 40;
    buttonColumn.maxWidth = 1000;
    buttonColumn.resizingMask = NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask;
    buttonColumn.title = NSLocalizedStringWithDefaultValue(@"PointerPreferences.ButtonColumnHeader", nil, [NSBundle mainBundle], @"Mouse Button/Trackpad Gesture", @"Column header in Settings > Pointer > Bindings: the mouse button or trackpad gesture a binding responds to");
    buttonColumn.headerCell.lineBreakMode = NSLineBreakByTruncatingTail;
    buttonColumn.headerCell.alignment = NSTextAlignmentLeft;
    buttonColumn.headerCell.textColor = [NSColor headerTextColor];
    buttonColumn.headerCell.backgroundColor = [NSColor colorWithCalibratedWhite:0.33333298560000002 alpha:1];
    NSTextFieldCell *buttonDataCell = [[NSTextFieldCell alloc] init];
    buttonDataCell.lineBreakMode = NSLineBreakByTruncatingTail;
    buttonDataCell.selectable = YES;
    buttonDataCell.editable = YES;
    buttonDataCell.alignment = NSTextAlignmentLeft;
    buttonDataCell.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
    buttonDataCell.textColor = [NSColor controlTextColor];
    buttonDataCell.backgroundColor = [NSColor controlBackgroundColor];
    buttonColumn.dataCell = buttonDataCell;

    [bindingsTableView addTableColumn:actionColumn];
    [bindingsTableView addTableColumn:buttonColumn];
    bindingsScrollView.documentView = bindingsTableView;

    NSButton *loadDefaultsButton =
        [iTermSettingsViewFactory smallSquareButtonWithFrame:NSMakeRect(60, 19, 211, 23)
                                                       title:NSLocalizedStringWithDefaultValue(@"PointerPreferences.LoadDefaults", nil, [NSBundle mainBundle], @"Load Defaults", @"Button in Settings > Pointer > Bindings that restores the default pointer bindings")
                                                       image:nil
                                            autoresizingMask:NSViewMaxXMargin | NSViewMinYMargin
                                                      target:pointerPrefsController
                                                      action:@selector(loadDefaults:)];
    [bindingsContainer addSubview:removeBindingButton];
    [bindingsContainer addSubview:addBindingButton];
    [bindingsContainer addSubview:bindingsScrollView];
    [bindingsContainer addSubview:loadDefaultsButton];
    [bindingsView addSubview:bindingsContainer];
    bindingsItem.view = bindingsView;
    _bindingsTableView = bindingsTableView;
    _buttonColumn = buttonColumn;
    _actionColumn = actionColumn;
    _removeBindingButton = removeBindingButton;

    [tabView addTabViewItem:generalItem];
    [tabView addTabViewItem:bindingsItem];
    _tabView = tabView;

    [root addSubview:tabView];
    self.view = root;
}

- (NSTabView *)tabView {
    return _tabView;
}

- (CGFloat)minimumWidth {
    return 186;
}

@end
