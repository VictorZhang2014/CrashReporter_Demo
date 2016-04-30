# CrashReporter_Demo

This is a simple Crash Reporter for iOS in Objective-C.

It needs a system library which name is CrashReporter.framework , a open source library.

Its authorization website is https://www.plcrashreporter.org/

The class names CrashReport's usage is easy to integrate in your project.



Usage

1.Drag drop the class to your project below any catalogue.

2.Write the following code in AppDelegate.m file at this event which is 
   - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
  the code:   [CrashReport enable];

3.There is property that name is "crashesDir" property which is a directory . 
  You can retrieve all files in the directory and upload these files to your own server.

4.The directory in sandbox path which is "/Library/Caches/", so you could open it directly.


Give a good suggestion, you can upload these crashed files when application is launched while there has some crashed files.