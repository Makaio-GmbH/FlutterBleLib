#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <os/log.h>
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];

  if (@available(iOS 10.0, *)) {
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
  }
    
    NSArray * centralManagerIdentifiers = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];

    
    if (centralManagerIdentifiers != nil) {
        for (int i=0; i<[centralManagerIdentifiers count]; i++) {
            NSString * identifier = [centralManagerIdentifiers objectAtIndex:i];
            NSLog(@"ccddee bluetooth central key identifier %@", identifier);
        }
    }

    os_log(OS_LOG_DEFAULT, "App did finish launching");
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
