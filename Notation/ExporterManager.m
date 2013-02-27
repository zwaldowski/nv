/*Copyright (c) 2010, Zachary Schneirov. All rights reserved.
  Redistribution and use in source and binary forms, with or without modification, are permitted 
  provided that the following conditions are met:
   - Redistributions of source code must retain the above copyright notice, this list of conditions 
     and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice, this list of 
	 conditions and the following disclaimer in the documentation and/or other materials provided with
     the distribution.
   - Neither the name of Notational Velocity nor the names of its contributors may be used to endorse 
     or promote products derived from this software without specific prior written permission. */


#import "ExporterManager.h"
#import "NoteObject.h"
#import "NSString_NV.h"
#import "GlobalPrefs.h"

@implementation ExporterManager

+ (ExporterManager *)sharedManager {
	static dispatch_once_t onceToken;
	static ExporterManager *sharedManager = nil;
	dispatch_once(&onceToken, ^{
		sharedManager = [[ExporterManager alloc] init];
	});
	return sharedManager;
}

- (void)awakeFromNib {

	NoteStorageFormat storageFormat = [[[GlobalPrefs defaultPrefs] notationPrefs] notesStorageFormat];
	[formatSelectorPopup selectItemWithTag:storageFormat];
}

- (IBAction)formatSelectorChanged:(id)sender {
	NSSavePanel *panel = (NSSavePanel *) [sender window];

	NoteStorageFormat storageFormat = [[formatSelectorPopup selectedItem] tag];
	[panel setAllowedFileTypes:@[[NotationPrefs pathExtensionForFormat:storageFormat]]];
}

- (void)exportNotes:(NSArray *)notes forWindow:(NSWindow *)window {
	if (!accessoryView) {
		if (![NSBundle loadNibNamed:@"ExporterManager" owner:self]) {
			NSLog(@"Failed to load ExporterManager.nib");
			NSBeep();
			return;
		}
	}

	void (^completionHandler)(NSSavePanel *, NSInteger) = ^(NSSavePanel *sheet, NSInteger returnCode) {
		if (returnCode == NSFileHandlingPanelOKButton && notes) {
			//write notes in chosen format
			NSUInteger i;
			NSInteger result;
			NoteStorageFormat storageFormat = [[formatSelectorPopup selectedItem] tag];
			NSURL *URL = sheet.URL;
			NSString *filename = URL.lastPathComponent;
			BOOL overwriteNotes = NO;
			FSRef directoryRef;

			if (!URL || !CFURLGetFSRef((__bridge CFURLRef) URL, &directoryRef)) {
				NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"The notes couldn't be exported because the directory \"%@\" couldn't be accessed.", nil),
														   URL.URLByDeletingLastPathComponent.path.stringByAbbreviatingWithTildeInPath], @"", NSLocalizedString(@"OK", nil), nil, nil);
				return;
			}

			//re-uniqify file names here (if [notes count] > 1)?

			for (i = 0; i < [notes count]; i++) {
				BOOL lastNote = i != [notes count] - 1;
				NoteObject *note = notes[i];

				NSError *error = nil;
				BOOL success = [note exportToDirectory: URL filename: filename format: storageFormat overwrite: overwriteNotes error: &error];

				if (!success && error.code == NSFileWriteFileExistsError) {
					//ask about overwriting
					NSString *existingName = filename ? : note.filename;
					existingName = [[existingName stringByDeletingPathExtension] stringByAppendingPathExtension:[NotationPrefs pathExtensionForFormat:storageFormat]];
					result = NSRunAlertPanel([NSString stringWithFormat:NSLocalizedString(@"A file named quotemark%@quotemark already exists.", nil), existingName],
											 NSLocalizedString(@"Replace its current contents with that of the note?", @"replace the file's contents?"),
											 NSLocalizedString(@"Replace", nil), NSLocalizedString(@"Don't Replace", nil), lastNote ? NSLocalizedString(@"Replace All", nil) : nil, nil);
					if (result == NSAlertDefaultReturn || result == NSAlertOtherReturn) {
						if (result == NSAlertOtherReturn) overwriteNotes = YES;
						success = [note exportToDirectory: URL filename: filename format: storageFormat overwrite: YES error: &error];
					} else continue;
				}

				if (!success) {
					NSString *exportErrorTitleString = [NSString stringWithFormat:NSLocalizedString(@"The note quotemark%@quotemark couldn't be exported because %@.", nil),
														note.title, [NSString reasonStringFromCarbonFSError: (int)error.code]];
					if (!lastNote) {
						NSRunAlertPanel(exportErrorTitleString, NULL, NSLocalizedString(@"OK", nil), nil, nil, nil);
					} else {
						result = NSRunAlertPanel(exportErrorTitleString, NSLocalizedString(@"Continue exporting?", @"alert title for exporter interruption"),
												 NSLocalizedString(@"Continue", @"(exporting notes?)"), NSLocalizedString(@"Stop Exporting", @"(notes?)"), nil);
						if (result != NSAlertDefaultReturn) break;
					}

				}
			}

			[[NSWorkspace sharedWorkspace] noteFileSystemChanged: URL.path];
		}
	};

	if ([notes count] == 1) {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAccessoryView:accessoryView];
		[savePanel setCanCreateDirectories:YES];
		[savePanel setCanSelectHiddenExtension:YES];

		[self formatSelectorChanged:formatSelectorPopup];

		NSString *filename = [notes.lastObject filename];
		filename = [filename stringByDeletingPathExtension];
		filename = [filename stringByAppendingPathExtension:[NotationPrefs pathExtensionForFormat:(NoteStorageFormat) [[formatSelectorPopup selectedItem] tag]]];

		[savePanel setNameFieldStringValue: filename];

		[savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
			completionHandler(savePanel, result);
		}];
	} else if ([notes count] > 1) {
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setAccessoryView:accessoryView];
		[openPanel setCanCreateDirectories:YES];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setPrompt:NSLocalizedString(@"Export", @"title of button to export notes from folder selection dialog")];
		[openPanel setTitle:NSLocalizedString(@"Export Notes", @"title of export notes dialog")];
		[openPanel setMessage:[NSString stringWithFormat:NSLocalizedString(@"Choose a folder into which %d notes will be exported", nil), [notes count]]];

		[openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
			completionHandler(openPanel, result);
		}];
	} else {
		NSRunAlertPanel(NSLocalizedString(@"No notes were selected for exporting.", nil),
				NSLocalizedString(@"You must select at least one note to export.", nil), NSLocalizedString(@"OK", nil), NULL, NULL);
	}
}

@end
