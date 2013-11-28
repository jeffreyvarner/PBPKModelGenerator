//
//  VLDocument.m
//  PBPKModelGenerator
//
//  Created by Jeffrey Varner on 10/2/13.
//  Copyright (c) 2013 Varnerlab. All rights reserved.
//

#import "VLDocument.h"

@interface VLDocument ()

// private properties -
@property (strong) IBOutlet NSButton *myGenerateCodeButton;
@property (strong) IBOutlet NSButton *myCancelButton;
@property (strong) IBOutlet NSButton *myOpenModelFileButton;
@property (strong) IBOutlet NSButton *myClearConsoleButton;
@property (strong) IBOutlet NSButton *myOverwriteModelFilesCheckBox;
@property (strong) IBOutlet NSComboBox *myModelOutputTypeComboBox;
@property (strong) IBOutlet NSComboBox *myModelLanguageTypeComboBox;

@property (strong) IBOutlet NSTextView *myConsoleTextField;
@property (strong) IBOutlet NSTextField *myModelSpecificationPathTextField;
@property (strong) IBOutlet NSProgressIndicator *myCodeGenerationProgressIndicator;
@property (strong) NSWindowController *myWindowController;

@property (strong) NSArray *myDefaultLanguageTypes;
@property (strong) NSArray *myDefaultTransformationTypes;
@property (strong) NSString *mySelectedLanguageAdaptor;
@property (strong) NSURL *myBlueprintFileURL;

// private methdos
-(void)setup;
-(void)cleanMyMemory;


@end

@implementation VLDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

-(void)dealloc
{
    [self cleanMyMemory];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"VLDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
    // grab the controller -
    self.myWindowController = aController;
    
    // initialize me -
    [self setup];
    
    // Setup completion notification -
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    // VLTransformationJobUpdateNotification -
    [center addObserverForName:VLTransformationJobProgressUpdateNotification
                        object:nil
                         queue:mainQueue
                    usingBlock:^(NSNotification *notification){
                        
                        // Get the message from the notification -
                        NSString *message = [notification object];
                        
                        // update the label -
                        NSString *current_text = [[[self myConsoleTextField] textStorage] string];
                        NSString *new_text = [NSString stringWithFormat:@"%@\n%@",current_text,message];
                        [[self myConsoleTextField] setString:new_text];
                    }];
    
    // VLTransformationJobCompletedNotification -
    [center addObserverForName:VLTransformationJobDidCompleteNotification
                        object:nil
                         queue:mainQueue
                    usingBlock:^(NSNotification *notification){
                        
                        // shutdown the progress bar animation -
                        [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
                        
                        // what is my end time?
                        CFTimeInterval _myExecutionDuration = CFAbsoluteTimeGetCurrent() - _myExecutionStartTime;
                        
                        // Set the completed text -
                        NSString *current_text = [[[self myConsoleTextField] textStorage] string];
                        NSString *new_text = [NSString stringWithFormat:@"%@\n%@ in %f seconds",current_text,@"Status: Transformation completed ",_myExecutionDuration];
                        [[self myConsoleTextField] setString:new_text];
                    }];

}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    return NO;
}

#pragma mark - actions
-(IBAction)codeGenerationClearConsoleButtonWasTapped:(NSButton *)button
{
    // clear the console text -
    [[self myConsoleTextField] setString:@""];
}

-(IBAction)codeGenerationBeginGenerationButtonWasTapped:(NSButton *)button
{
    // ok, so check to make sure we have a URL - if we do then begin the generation
    // process. If not, then open the open panel -
    if ([self myBlueprintFileURL]!=nil)
    {
        if ([self mySelectedLanguageAdaptor]!=nil)
        {
            // grab my start time -
            _myExecutionStartTime = CFAbsoluteTimeGetCurrent();
            
            // start the progress bar animation -
            [[self myCodeGenerationProgressIndicator] startAnimation:nil];
            
            // clear out the console -
            [[self myConsoleTextField] insertText:@""];
            
            // Ok, so when I get here I have the blueprint file URL.
            // We need to start the code generation process for this blueprint file.
            // Get the blueprint URL -
            NSURL *localBlueprintURL = [self myBlueprintFileURL];
            
            // Load the blueprint file -
            NSXMLDocument *blueprintTree = [VLCoreUtilitiesLib createXMLDocumentFromFile:localBlueprintURL];
            if (blueprintTree != nil)
            {
                // Hand the blue print tree to the lib, and call execute.
                void (^MyCodeGenerationJobCompletionHandler)(BOOL) = ^(BOOL didFinish){
                    
                    [self jobDidComplete];
                    
                };
                
                // create the engine -
                VLCodeGeneratorLibrary *engine = [VLCodeGeneratorLibrary codeGeneratorInstance];
                [engine setMyTransformationBlueprintTree:blueprintTree];
                [engine setMyTransformationFilePath:[[self myBlueprintFileURL] absoluteString]];
                [engine setMyTransformationLanguageAdaptor:[self mySelectedLanguageAdaptor]];
                
                // could we have code type adaptor?
                // ...
                
                [engine executeCodeGenerationJobWithCompletionHandler:MyCodeGenerationJobCompletionHandler];
            }
            else
            {
                // stop progress bar
                [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
                
                // ok, we don't have a blueprint file ... through up a error view
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"Try again"];
                [alert setMessageText:@"Ooops! It seems we have encountered a major malfunction!"];
                [alert setInformativeText:@"Please check your transformation file format and try again."];
                [alert setAlertStyle:NSCriticalAlertStyle];
                
                [alert beginSheetModalForWindow:[[self myWindowController] window]
                                  modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
            }
        }
        else
        {
            // stop progress bar
            [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
            
            // ok, we don't have a blueprint file ... through up a error view
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Try again"];
            [alert setMessageText:@"Ooops! You have not selected a code output type."];
            [alert setInformativeText:@"Please select a code output type from the drop down list and try again."];
            [alert setAlertStyle:NSCriticalAlertStyle];
            
            [alert beginSheetModalForWindow:[[self myWindowController] window]
                              modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];

        }
    }
    else
    {
        [self codeGenerationLoadTransformationBlueprintButtonWasTapped:nil];
    }
}

-(void)jobDidComplete
{
    NSLog(@"Done ...");
}

-(IBAction)codeGenerationCancelGenerationButtonWasTapped:(NSButton *)button
{
    
}

-(IBAction)codeGenerationLoadTransformationBlueprintButtonWasTapped:(NSButton *)button
{
    // Launch the NSOpenPanel logic, capture the user filename and present the path in the text fld
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    // Configure the panel -
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:YES];
    
    // Run the panel as a sheet -
    [openPanel beginSheetModalForWindow:[[self myWindowController] window]
                      completionHandler:^(NSInteger resultIndex){
                          
                          // Ok, so this block gets executed *after* we have selected a file
                          if (resultIndex == NSFileHandlingPanelOKButton)
                          {
                              // Ok, so when I get here the user has hit the OK button
                              NSURL *mySelectedURL = [openPanel URL];
                              
                              // grab this URL for later -
                              self.myBlueprintFileURL = mySelectedURL;
                              
                              // Create a file path string -
                              NSString *pathString = [mySelectedURL absoluteString];
                              
                              // Set the value in the text fld -
                              [[self myModelSpecificationPathTextField] setStringValue:pathString];
                          }
                          else if (resultIndex == NSFileHandlingPanelCancelButton)
                          {
                              // Ok, so when I get here the user has hit the cancel button
                              // for now, do nothing.
                          }
                          
                      }];

}

#pragma mark - alert delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        
        // stop progress bar
        [[self myCodeGenerationProgressIndicator] stopAnimation:nil];
        
        // KIA my blueprint file URL -
        self.myBlueprintFileURL = nil;
        
        // clean the text fld -
        [[self myModelSpecificationPathTextField] setStringValue:@""];
    }
}

#pragma mark - combobox datasource/delegate methods
- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    // ok, the combox box selection changed. What item is selected?
    NSUInteger selected_language_index = [[self myModelOutputTypeComboBox] indexOfSelectedItem];
    
    // grab the node for this selection -
    NSXMLElement *node = [[self myDefaultLanguageTypes] objectAtIndex:selected_language_index];
    
    // get the language_adaptor attribute -
    NSString *language_adaptor_string = [[node attributeForName:@"language_adaptor"] stringValue];
    
    // grab this string -
    self.mySelectedLanguageAdaptor = language_adaptor_string;
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    if ([self myModelLanguageTypeComboBox] == aComboBox)
    {
        if ([self myDefaultLanguageTypes]!=nil)
        {
            return [[self myDefaultLanguageTypes] count];
        }
    }
    else if ([self myModelOutputTypeComboBox] == aComboBox)
    {
        if ([self myDefaultTransformationTypes]!=nil)
        {
            return [[self myDefaultTransformationTypes] count];
        }
    }
    
    
    return 0;
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    
    if ([self myModelLanguageTypeComboBox] == aComboBox)
    {
        if ([self myDefaultLanguageTypes] != nil &&
            [[self myDefaultLanguageTypes] count]>index)
        {
            // get the node, return the label attribute
            NSXMLElement *node = [[self myDefaultLanguageTypes] objectAtIndex:index];
            NSString *display_label = [[node attributeForName:@"label"] stringValue];
            return display_label;
        }
    }
    else if ([self myModelOutputTypeComboBox] == aComboBox)
    {
        if ([self myDefaultTransformationTypes] != nil &&
            [[self myDefaultTransformationTypes] count]>index)
        {
            // get the node, return the label attribute
            NSXMLElement *node = [[self myDefaultTransformationTypes] objectAtIndex:index];
            NSString *display_label = [[node attributeForName:@"label"] stringValue];
            return display_label;
        }
    }
    
    
    return nil;
}


#pragma mark - setup methods
-(void)setup
{
    
    // ok, have we loaded the default language types?
    if ([self myDefaultLanguageTypes] == nil)
    {
        // load the defaults -
        NSString *path_to_languages = [[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"xml"];
        if (path_to_languages!=nil)
        {
            // load XML file and get output nodes -
            NSXMLDocument *output_document = [VLCoreUtilitiesLib createXMLDocumentFromFile:[NSURL fileURLWithPath:path_to_languages]];
            
            // get the nodes -
            NSArray *nodes_array = [output_document nodesForXPath:@"//language" error:nil];
            if (nodes_array!=nil)
            {
                self.myDefaultLanguageTypes = [NSArray arrayWithArray:nodes_array];
            }
        }
    }
    
    // ok, have we load the default transformation types?
    if ([self myDefaultTransformationTypes] == nil)
    {
        // load the defaults -
        NSString *path_to_transformations = [[NSBundle mainBundle] pathForResource:@"TransformationTypes" ofType:@"xml"];
        if (path_to_transformations!=nil)
        {
            // load XML file and get output nodes -
            NSXMLDocument *output_document = [VLCoreUtilitiesLib createXMLDocumentFromFile:[NSURL fileURLWithPath:path_to_transformations]];
            
            // get the nodes -
            NSArray *nodes_array = [output_document nodesForXPath:@"//transform_type" error:nil];
            if (nodes_array!=nil)
            {
                self.myDefaultTransformationTypes = [NSArray arrayWithArray:nodes_array];
            }
        }
    }
}

-(void)cleanMyMemory
{
    // kia my ivars -
    self.myBlueprintFileURL = nil;
    self.myDefaultLanguageTypes = nil;
    self.myDefaultTransformationTypes = nil;
    self.myGenerateCodeButton = nil;
    self.myCancelButton = nil;
    self.myOpenModelFileButton = nil;
    self.myConsoleTextField = nil;
    self.myModelOutputTypeComboBox = nil;
}



@end
