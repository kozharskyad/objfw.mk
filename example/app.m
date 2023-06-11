#import <ObjFW/ObjFW.h>
#import "app.h"

@implementation App
- (void)applicationDidFinishLaunching:(OFNotification *)notification {
  OFLog(@"Hello, World!");
  [OFApplication terminate];
}
@end
