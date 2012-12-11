/* NoteAttributeColumn */

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


#import <Cocoa/Cocoa.h>

@class NotesTableView;

@interface NoteAttributeColumn : NSTableColumn {
	float absoluteMinimumWidth;
}

+ (NSDictionary*)standardDictionary;
- (void)updateWidthForHighlight;

@property (nonatomic) SEL mutatingSelector;
@property (nonatomic) id (*attributeFunction)(id, id, NSInteger);
@property (nonatomic) NSInteger (*sortingFunction)(id*, id*);
@property (nonatomic) NSInteger (*reverseSortingFunction)(id*, id*);

- (void)setResizingMaskNumber:(NSNumber*)resizingMaskNumber;

@end
