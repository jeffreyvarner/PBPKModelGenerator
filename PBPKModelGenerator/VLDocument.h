//
//  VLDocument.h
//  PBPKModelGenerator
//
//  Created by Jeffrey Varner on 10/2/13.
//  Copyright (c) 2013 Varnerlab. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VLCoreUtilitiesLib.h"
#import "VLBlocksAndConstanStrings.h"
#import "VLCodeGeneratorLibrary.h"

@interface VLDocument : NSDocument
{
    @private
    NSButton *_myGenerateCodeButton;
    NSButton *_myCancelButton;
    NSButton *_myOpenModelFileButton;
    NSButton *_myOverwriteModelFilesCheckBox;
    NSComboBox *_myModelOutputTypeComboBox;
    NSTextView *_myConsoleTextField;
    NSTextField *_myModelSpecificationPathTextField;
    NSProgressIndicator *_myCodeGenerationProgressIndicator;
    NSWindowController *_myWindowController;
    NSURL *_myBlueprintFileURL;
    CFTimeInterval _myExecutionStartTime;
    
    // defaults -
    NSArray *_myDefaultOutputTypes;
    NSString *_mySelectedLanguageAdaptor;
}

// actions -
-(IBAction)codeGenerationBeginGenerationButtonWasTapped:(NSButton *)button;
-(IBAction)codeGenerationCancelGenerationButtonWasTapped:(NSButton *)button;
-(IBAction)codeGenerationLoadTransformationBlueprintButtonWasTapped:(NSButton *)button;

@end
