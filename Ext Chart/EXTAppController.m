//
//  EXTAppController.m
//  Ext Chart
//
//  Created by Michael Hopkins on 7/31/11.
//  Copyright 2011 Harvard University. All rights reserved.
//

#import "EXTAppController.h"
#import "EXTNewDocumentWindowController.h"
#import "EXTPreferencesWindowController.h"
#import "Sparkle/SUUpdater.h"
#import "Sparkle/SUConstants.h"

static inline bool isRunningTests(void) {
    return [[[NSProcessInfo processInfo] arguments] containsObject:@"-XCTest"];
}

@interface EXTAppController () <SUUpdaterDelegate>
@property (nonatomic, strong) IBOutlet SUUpdater *sparkleUpdater;
@end

@implementation EXTAppController {
    EXTNewDocumentWindowController *_newDocumentWindowController;
    EXTPreferencesWindowController *_preferencesWindowController;
    SUUpdater *_sparkleUpdater;
}

- (void)newDocument:(id)sender {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _newDocumentWindowController = [EXTNewDocumentWindowController new];
    });

    [_newDocumentWindowController showWindow:self];
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender {
    if (isRunningTests()) return NO;

    [self newDocument:nil];
    return YES;
}

- (IBAction)showPreferences:(id)sender {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _preferencesWindowController = [EXTPreferencesWindowController new];
    });

    [_preferencesWindowController showWindow:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // Default = automatically check for updates.
    // If SUEnableAutomaticChecksKey isn’t in user defaults, the user hasn’t made a choice yet.
    // Note that we cannot use .automaticallyChecksForUpdates because it uses -boolForKey: under the hood,
    // which returns NO if there is no such key OR the key is present with a value of NO.
    NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    if (!defaults[SUEnableAutomaticChecksKey]) {
        self.sparkleUpdater.automaticallyChecksForUpdates = YES;
    }
}

@end
