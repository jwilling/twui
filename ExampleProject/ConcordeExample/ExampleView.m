/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ExampleView.h"
#import "ExampleTableViewCell.h"
#import "ExampleSectionHeaderView.h"

#define TAB_HEIGHT 60

@implementation ExampleView

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
		
		// if you're using a font a lot, it's best to allocate it once and re-use it
		exampleFont1 = [NSFont fontWithName:@"HelveticaNeue" size:15];
		exampleFont2 = [NSFont fontWithName:@"HelveticaNeue-Bold" size:15];
		
		CGRect b = self.bounds;
		b.origin.y += TAB_HEIGHT;
		b.size.height -= TAB_HEIGHT;
		
		/*
		 Note by default scroll views (and therefore table views) don't
		 have clipsToBounds enabled.  Set only if needed.  In this case
		 we don't, so it could potentially save us some rendering costs.
		 */
		_tableView = [[TUITableView alloc] initWithFrame:b];
		_tableView.alwaysBounceVertical = YES;
		_tableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
		_tableView.dataSource = self;
		_tableView.delegate = self;
		_tableView.maintainContentOffsetAfterReload = YES;
		[self addSubview:_tableView];
		
		_tabBar = [[ExampleTabBar alloc] initWithNumberOfTabs:5];
		_tabBar.delegate = self;
		// It'd be easier to just use .autoresizingmask, but for demonstration we'll use ^layout.
		_tabBar.layout = ^(TUIView *v) { // 'v' in this case will point to the same object as 'tabs'
			TUIView *superview = v.superview; // note we're using the passed-in 'v' argument, rather than referencing 'tabs' in the block, this avoids a retain cycle without jumping through hoops
			CGRect rect = superview.bounds; // take the superview bounds
			rect.size.height = TAB_HEIGHT; // only take up the bottom 60px
			return rect;
		};
		[self addSubview:_tabBar];
		
		// setup individual tabs
		for(TUIView *tabView in _tabBar.tabViews) {
			tabView.backgroundColor = [NSColor clearColor]; // will also set opaque=NO
			
			// let's just teach the tabs how to draw themselves right here - no need to subclass anything
			tabView.drawRect = ^(TUIView *v, CGRect rect) {
				CGRect b = v.bounds;
				CGContextRef ctx = TUIGraphicsGetCurrentContext();
				
				NSImage *image = [NSImage imageNamed:@"clock"];
				CGRect imageRect = ABIntegralRectWithSizeCenteredInRect([image size], b);

				if([v.nsView isTrackingSubviewOfView:v]) { // simple way to check if the mouse is currently down inside of 'v'.  See the other methods in TUINSView for more.
					
					// first draw a slight white emboss below
					CGContextSaveGState(ctx);
					
					CGImageRef cgImage = [image CGImageForProposedRect:&imageRect context:nil hints:nil];
					CGContextClipToMask(ctx, CGRectOffset(imageRect, 0, -1), cgImage);

					CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.5);
					CGContextFillRect(ctx, b);
					CGContextRestoreGState(ctx);

					// replace image with a dynamically generated fancy inset image
					// 1. use the image as a mask to draw a blue gradient
					// 2. generate an inner shadow image based on the mask, then overlay that on top
					image = [NSImage tui_imageWithSize:imageRect.size drawing:^(CGContextRef ctx) {
						CGRect r;
						r.origin = CGPointZero;
						r.size = imageRect.size;
						
						CGContextClipToMask(ctx, r, image.tui_CGImage);
						CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, r.size.height), (CGFloat[]){0,0,1,1}, CGPointZero, (CGFloat[]){0,0.6,1,1});
						NSImage *innerShadow = [image tui_innerShadowWithOffset:CGSizeMake(0, -1) radius:3.0 color:[NSColor blackColor] backgroundColor:[NSColor cyanColor]];
						CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
						CGContextDrawImage(ctx, r, innerShadow.tui_CGImage);
					}];
				}

				[image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0]; // draw 'image' (might be the regular one, or the dynamically generated one)

				// draw the index
				TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"%ld", v.tag]];
				[s ab_drawInRect:CGRectOffset(imageRect, imageRect.size.width, -15)];
			};
		}

		NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 180, 91, 22)];
		[textField.cell setUsesSingleLineMode:YES];
		[textField.cell setScrollable:YES];

		TUIViewNSViewContainer *textFieldContainer = [[TUIViewNSViewContainer alloc] initWithNSView:textField];
		textFieldContainer.backgroundColor = [NSColor blueColor];
		[self addSubview:textFieldContainer];
	}
	return self;
}


- (void)tabBar:(ExampleTabBar *)tabBar didSelectTab:(NSInteger)index
{
	NSLog(@"selected tab %ld", index);
	if(index == [[tabBar tabViews] count] - 1){
	  NSLog(@"Reload table data...");
	  [_tableView reloadData];
	}
}

- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView
{
	return 8;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
	return 25;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 50.0;
}

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section
{
	ExampleSectionHeaderView *view = [[ExampleSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
	TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", (int)section]];
	title.color = [NSColor blackColor];
	title.font = exampleFont2;
	view.labelRenderer.attributedString = title;
	return view;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ExampleTableViewCell *cell = reusableTableCellOfClass(tableView, ExampleTableViewCell);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", (int)indexPath.row]];
	s.color = [NSColor blackColor];
	s.font = exampleFont1;
	[s setFont:exampleFont2 inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
	cell.attributedString = s;
	
	return cell;
}

- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event
{
	if([event clickCount] == 1) {
		// do something cool
	}
	
	if(event.type == NSRightMouseUp){
		// show context menu
	}
}
- (BOOL)tableView:(TUITableView *)tableView shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath forEvent:(NSEvent *)event{
	switch (event.type) {
		case NSRightMouseDown:
			return NO;
	}

	return YES;
}

-(BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // return TRUE to enable row reordering by dragging; don't implement this method or return
  // FALSE to disable
  return TRUE;
}

-(void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  // update the model to reflect the changed index paths; since this example isn't backed by
  // a "real" model, after dropping a cell the table will revert to it's previous state
  NSLog(@"Move dragged row: %@ => %@", fromIndexPath, toIndexPath);
}

-(NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath {
  // optionally revise the drag-to-reorder drop target index path by returning a different index path
  // than proposedPath.  if proposedPath is suitable, return that.  if this method is not implemented,
  // proposedPath is used by default.
  return proposedPath;
}

@end
