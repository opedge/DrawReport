//
//  DRPBasecampProject.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DRPBasecampProject : NSObject

@property (nonatomic, strong) NSNumber *projectId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *projectDescription;
@property (nonatomic, strong) NSString *url;

@end
