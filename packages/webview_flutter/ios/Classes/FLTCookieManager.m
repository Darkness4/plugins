// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTCookieManager.h"

@implementation FLTCookieManager {
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTCookieManager *instance = [[FLTCookieManager alloc] init];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/cookie_manager"
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"clearCookies"]) {
    [self clearCookies:result];
  } else if ([[call method] isEqualToString:@"setCookie"]) {
    [self setCookie:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)clearCookies:(FlutterResult)result {
  if (@available(iOS 9.0, *)) {
    NSSet<NSString *> *websiteDataTypes = [NSSet setWithObject:WKWebsiteDataTypeCookies];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];

    void (^deleteAndNotify)(NSArray<WKWebsiteDataRecord *> *) =
        ^(NSArray<WKWebsiteDataRecord *> *cookies) {
          BOOL hasCookies = cookies.count > 0;
          [dataStore removeDataOfTypes:websiteDataTypes
                        forDataRecords:cookies
                     completionHandler:^{
                       result(@(hasCookies));
                     }];
        };

    [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:deleteAndNotify];
  } else {
    // support for iOS8 tracked in https://github.com/flutter/flutter/issues/27624.
    NSLog(@"Clearing cookies is not supported for Flutter WebViews prior to iOS 9.");
  }
}

- (void)setCookie:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (@available(iOS 11.0, *)) {
    NSString* urlString = call.arguments[@"url"];
    NSString* value = call.arguments[@"value"];
    WKWebsiteDataStore *dataStore = [WKWebsiteDataStore defaultDataStore];
    WKHTTPCookieStore *cookieStore = dataStore.httpCookieStore;
    NSDictionary<NSString *,NSString *> *cookieHeaderFields = @{
        @"Set-Cookie" : value
    };
    NSURL *url = [NSURL URLWithString:urlString];
    NSArray<NSHTTPCookie *> *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:cookieHeaderFields forURL:url];
    for (NSHTTPCookie *cookie in cookies) {
      [cookieStore setCookie:cookie
                completionHandler:^{
                  result(nil);
                }];
    }
  } else {
    NSLog(@"Adding cookies is not supported for Flutter WebViews prior to iOS 11.");
  }
}

@end
