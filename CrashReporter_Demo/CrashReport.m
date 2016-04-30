//
//  CrashReport.m
//  CrashReporter_Demo
//
//  Created by Victor John on 4/27/16.
//  Copyright © 2016 com.xiaoruigege. All rights reserved.
//

#import "CrashReport.h"
#import <CrashReporter/CrashReporter.h>
#import <sys/sysctl.h>

@interface CrashReport()
@property (nonatomic, strong) PLCrashReporter *plCrashReporter;
@property (nonatomic, assign) NSUncaughtExceptionHandler *exceptionHandler;
@property (nonatomic, assign) BOOL appStoreEnvironment;
@end

@implementation CrashReport

+ (instancetype)share
{
    static CrashReport *crport;
    static dispatch_once_t crash_report_once;
    dispatch_once(&crash_report_once, ^{
        crport = [[CrashReport alloc] init];
        [crport initCrashDir];
    });
    return crport;
}


- (void)initCrashDir{
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.crashesDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/crashes/"];
    if (![fileManager fileExistsAtPath:self.crashesDir]) {
        NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
        NSError *theError = NULL;
        
        [fileManager createDirectoryAtPath:self.crashesDir withIntermediateDirectories: YES attributes: attributes error: &theError];
    }
}

+ (void)enable
{
    [[CrashReport share] saveLastCrash];
}


- (void)saveLastCrash
{
    self.appStoreEnvironment = NO;
#if !TARGET_OS_SIMULATOR
    // check if we are really in an app store environment
    if (![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"]) {
        self.appStoreEnvironment = YES;
    }
#endif
    
    NSError *error = NULL;
    // Try loading the crash report
    PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
    //    if (self.isMachExceptionHandlerEnabled) {
    signalHandlerType = PLCrashReporterSignalHandlerTypeMach;
    //    }
    PLCrashReporterConfig *config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType: signalHandlerType
                                                                       symbolicationStrategy: PLCrashReporterSymbolicationStrategyAll];
    PLCrashReporter* plCrashReporter = [[PLCrashReporter alloc] initWithConfiguration: config];
    self.plCrashReporter = plCrashReporter;
    
    if (plCrashReporter.hasPendingCrashReport) {
        NSData *crashData = [[NSData alloc] initWithData:[plCrashReporter loadPendingCrashReportDataAndReturnError: &error]];
        
        // NSString *cacheFilename = [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate]];
        if (crashData.length == 0) {
        } else {
            // get the startup timestamp from the crash report, and the file timestamp to calculate the timeinterval when the crash happened after startup
            PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error:&error];
            
            if (report == nil) {
                // BWQuincyLog(@"WARNING: Could not parse crash report");
            } else {
                NSString *crashSourceCode = [PLCrashReportTextFormatter stringValueForCrashReport: report  withTextFormat: PLCrashReportTextFormatiOS];
                NSString *cacheFilename = [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate]];
                NSData* data = [crashSourceCode dataUsingEncoding:NSUTF8StringEncoding];
                [data writeToFile:[self.crashesDir stringByAppendingPathComponent: cacheFilename] atomically:YES];
                //*data = crashData;
            }
        }
        
        [plCrashReporter purgePendingCrashReport];
    }
    
    // error = NULL;
    // if (![plCrashReporter enableCrashReporterAndReturnError: &error])
    //     NSLog(@"[Quincy] WARNING: Could not enable crash reporter: %@", [error localizedDescription]);
    
    
    
    // The actual signal and mach handlers are only registered when invoking `enableCrashReporterAndReturnError`
    // So it is safe enough to only disable the following part when a debugger is attached no matter which
    // signal handler type is set
    // We only check for this if we are not in the App Store environment
//    
    BOOL debuggerIsAttached = NO;
    if (!self.appStoreEnvironment) {
        if ([self isDebuggerAttached]) {
            debuggerIsAttached = YES;
            NSLog(@"[Quincy] WARNING: Detecting crashes is NOT enabled due to running the app with a debugger attached.");
        }
    }
    
    if (!debuggerIsAttached) {
        // Multiple exception handlers can be set, but we can only query the top level error handler (uncaught exception handler).
        //
        // To check if PLCrashReporter's error handler is successfully added, we compare the top
        // level one that is set before and the one after PLCrashReporter sets up its own.
        //
        // With delayed processing we can then check if another error handler was set up afterwards
        // and can show a debug warning log message, that the dev has to make sure the "newer" error handler
        // doesn't exit the process itself, because then all subsequent handlers would never be invoked.
        //
        // Note: ANY error handler setup BEFORE HockeySDK initialization will not be processed!
        
        // get the current top level error handler
        NSUncaughtExceptionHandler *initialHandler = NSGetUncaughtExceptionHandler();
        
        // PLCrashReporter may only be initialized once. So make sure the developer
        // can't break this
        NSError *error = NULL;
        
        // set any user defined callbacks, hopefully the users knows what they do
        //        if (_crashCallBacks) {
        //            [_plCrashReporter setCrashCallbacks:_crashCallBacks];
        //        }
        
        // Enable the Crash Reporter
        if (![_plCrashReporter enableCrashReporterAndReturnError: &error])
            NSLog(@"[CrashReporter] WARNING: Could not enable crash reporter: %@", [error localizedDescription]);
        
        // get the new current top level error handler, which should now be the one from PLCrashReporter
        NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
        
        // do we have a new top level error handler? then we were successful
        if (currentHandler && currentHandler != initialHandler) {
            _exceptionHandler = currentHandler;
            
            //   BWQuincyLog(@"INFO: Exception handler successfully initialized.");
        } else {
            // this should never happen, theoretically only if NSSetUncaugtExceptionHandler() has some internal issues
            NSLog(@"CrashReporter ERROR: Exception handler could not be set. Make sure there is no other exception handler set up!");
        }
    }

}

- (BOOL)isDebuggerAttached {
    static BOOL debuggerIsAttached = NO;
    
    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];
        
        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();
        
        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            NSLog(@"[CrashReporter] ERROR: Checking for a running debugger via sysctl() failed: %s", strerror(errno));
            debuggerIsAttached = false;
        }
        
        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = true;
    });
    
    return debuggerIsAttached;
}
@end
