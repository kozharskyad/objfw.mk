#import <ObjFW/ObjFW.h>
#import "app.h"

@implementation App
- (void)applicationDidFinishLaunching {
  OFLog(@"Hello, World!");
  [OFApplication terminate];
}
@end
