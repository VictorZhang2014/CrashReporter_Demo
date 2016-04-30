//
//  CrashReport.h
//  CrashReporter_Demo
//
//  Created by Victor John on 4/27/16.
//  Copyright © 2016 com.xiaoruigege. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashReport : NSObject

/**
 * Crash Directory 
 * This is crash directory
 */
@property (nonatomic, strong) NSString *crashesDir;

+ (instancetype)share;

+ (void)enable;

@end
