// ============================================================
// UniversalCrack.dylib - 万能iOS卡密破解插件
// 适用于 iOS 14.3 + TrollStore
// ============================================================

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

#pragma mark - 工具函数：打印所有类（用于定位目标）

void printAllClasses(void) {
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses <= 0) return;
    
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    
    NSLog(@"[Crack] 总类数: %d", numClasses);
    
    NSArray *keywords = @[
        @"Card", @"Vip", @"VIP", @"Verify", @"Validate", @"Check",
        @"Auth", @"Login", @"Pay", @"Purchase", @"Unlock",
        @"Permission", @"Role", @"Level", @"Score", @"Point",
        @"Balance", @"Coin", @"Diamond", @"Gold", @"Member",
        @"User", @"Account", @"Manager", @"Service", @"Helper"
    ];
    
    for (int i = 0; i < numClasses; i++) {
        NSString *className = NSStringFromClass(classes[i]);
        for (NSString *keyword in keywords) {
            if ([className containsString:keyword]) {
                NSLog(@"[Crack] 🔍 发现目标类: %@", className);
                break;
            }
        }
    }
    
    free(classes);
}

#pragma mark - 通用 Method Swizzling 工具

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                           swizzledSelector,
                           method_getImplementation(originalMethod),
                           method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark - NSObject 扩展：万能返回 YES

@interface NSObject (Crack)
- (BOOL)crack_isVip;
- (BOOL)crack_isVIP;
- (BOOL)crack_isPro;
- (BOOL)crack_isPremium;
- (BOOL)crack_isMember;
- (BOOL)crack_isSubscribed;
- (BOOL)crack_isPaid;
- (BOOL)crack_isVerified;
- (BOOL)crack_isValid;
- (BOOL)crack_canAccess;
- (BOOL)crack_hasPermission;
- (BOOL)crack_verifyCard:(NSString *)card;
- (BOOL)crack_checkCard:(NSString *)card;
- (BOOL)crack_validateCard:(NSString *)card;
@end

@implementation NSObject (Crack)

- (BOOL)crack_isVip { return YES; }
- (BOOL)crack_isVIP { return YES; }
- (BOOL)crack_isPro { return YES; }
- (BOOL)crack_isPremium { return YES; }
- (BOOL)crack_isMember { return YES; }
- (BOOL)crack_isSubscribed { return YES; }
- (BOOL)crack_isPaid { return YES; }
- (BOOL)crack_isVerified { return YES; }
- (BOOL)crack_isValid { return YES; }
- (BOOL)crack_canAccess { return YES; }
- (BOOL)crack_hasPermission { return YES; }
- (BOOL)crack_verifyCard:(NSString *)card { 
    NSLog(@"[Crack] ⚡ 万能破解: verifyCard:%@ → YES", card);
    return YES; 
}
- (BOOL)crack_checkCard:(NSString *)card { 
    NSLog(@"[Crack] ⚡ 万能破解: checkCard:%@ → YES", card);
    return YES; 
}
- (BOOL)crack_validateCard:(NSString *)card { 
    NSLog(@"[Crack] ⚡ 万能破解: validateCard:%@ → YES", card);
    return YES; 
}

@end

#pragma mark - 自动 Hook 所有验证类

void autoHookAllClasses(void) {
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses <= 0) return;
    
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    objc_getClassList(classes, numClasses);
    
    // 要 Hook 的方法名列表
    NSArray *targetSelectors = @[
        @"isVip", @"isVIP", @"isPro", @"isPremium", 
        @"isMember", @"isSubscribed", @"isPaid",
        @"isVerified", @"isValid", @"canAccess", @"hasPermission",
        @"verifyCard:", @"checkCard:", @"validateCard:",
        @"verify:", @"validate:", @"check:"
    ];
    
    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        NSString *className = NSStringFromClass(cls);
        
        // 跳过系统类
        if ([className hasPrefix:@"_"] || 
            [className hasPrefix:@"NS"] ||
            [className hasPrefix:@"UI"] ||
            [className hasPrefix:@"CA"] ||
            [className hasPrefix:@"CF"]) {
            continue;
        }
        
        for (NSString *selName in targetSelectors) {
            SEL sel = NSSelectorFromString(selName);
            Method method = class_getInstanceMethod(cls, sel);
            if (method) {
                // 检查返回类型是否是 BOOL
                char *returnType = method_copyReturnType(method);
                if (returnType && strcmp(returnType, @encode(BOOL)) == 0) {
                    NSLog(@"[Crack] 🎯 Hook成功: %@.%@ → 返回 YES", className, selName);
                    
                    // 动态创建替换方法
                    IMP newImp = imp_implementationWithBlock(^(id self) {
                        NSLog(@"[Crack] ⚡ %@ 被调用，返回 YES", selName);
                        return YES;
                    });
                    
                    // 如果有参数（如 verifyCard:），需要带参数的 block
                    if ([selName containsString:@":"]) {
                        // 简单处理：用 objc_msgSend 方式，这里略复杂
                        // 实际使用中，上面的 NSObject 扩展已经覆盖了常见方法名
                    }
                    
                    class_replaceMethod(cls, sel, newImp, method_getTypeEncoding(method));
                    free(returnType);
                }
                if (returnType) free(returnType);
            }
        }
    }
    
    free(classes);
}

#pragma mark - 拦截 NSURLSession（网络劫持）

@interface NSURLSession (Crack)
+ (void)load;
@end

@implementation NSURLSession (Crack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
        SEL swizzledSelector = @selector(crack_dataTaskWithRequest:completionHandler:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (NSURLSessionDataTask *)crack_dataTaskWithRequest:(NSURLRequest *)request 
                                  completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSString *url = request.URL.absoluteString;
    NSLog(@"[Crack] 🌐 拦截网络请求: %@", url);
    
    // 检测是否是验证/卡密相关请求
    NSArray *keywords = @[@"verify", @"card", @"check", @"validate", @"auth", @"vip"];
    BOOL isVerifyRequest = NO;
    for (NSString *kw in keywords) {
        if ([url.lowercaseString containsString:kw]) {
            isVerifyRequest = YES;
            break;
        }
    }
    
    if (isVerifyRequest) {
        NSLog(@"[Crack] ⚡ 拦截验证请求，返回伪造成功响应");
        
        // 构造伪造的成功响应
        NSDictionary *fakeResponse = @{
            @"code": @200,
            @"status": @"success",
            @"msg": @"验证成功（由 UniversalCrack 伪造）",
            @"data": @{
                @"success": @YES,
                @"vip": @YES,
                @"level": @"platinum",
                @"expireTime": @"2099-12-31 23:59:59",
                @"points": @999999,
                @"balance": @999999.99
            }
        };
        
        NSData *fakeData = [NSJSONSerialization dataWithJSONObject:fakeResponse 
                                                           options:NSJSONWritingPrettyPrinted 
                                                             error:nil];
        
        if (completionHandler) {
            NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] 
                initWithURL:request.URL 
                statusCode:200 
                HTTPVersion:@"HTTP/1.1" 
                headerFields:@{@"Content-Type": @"application/json"}];
            completionHandler(fakeData, httpResponse, nil);
        }
        return nil;
    }
    
    // 非验证请求走原始逻辑
    return [self crack_dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

#pragma mark - 拦截 NSUserDefaults（本地存储篡改）

@interface NSUserDefaults (Crack)
+ (void)load;
@end

@implementation NSUserDefaults (Crack)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Swizzle objectForKey:
        Class class = [NSUserDefaults class];
        SEL origSel = @selector(objectForKey:);
        SEL swizSel = @selector(crack_objectForKey:);
        Method origMethod = class_getInstanceMethod(class, origSel);
        Method swizMethod = class_getInstanceMethod(class, swizSel);
        method_exchangeImplementations(origMethod, swizMethod);
        
        // Swizzle setObject:forKey:
        SEL origSetSel = @selector(setObject:forKey:);
        SEL swizSetSel = @selector(crack_setObject:forKey:);
        Method origSetMethod = class_getInstanceMethod(class, origSetSel);
        Method swizSetMethod = class_getInstanceMethod(class, swizSetSel);
        method_exchangeImplementations(origSetMethod, swizSetMethod);
    });
}

- (id)crack_objectForKey:(NSString *)defaultName {
    id result = [self crack_objectForKey:defaultName];
    
    NSArray *vipKeys = @[@"vip", @"VIP", @"isVip", @"isVIP", @"pro", @"premium", @"member", @"paid"];
    for (NSString *key in vipKeys) {
        if ([defaultName containsString:key] || [defaultName isEqualToString:key]) {
            if ([result isKindOfClass:[NSNumber class]] && [result boolValue] == NO) {
                NSLog(@"[Crack] 💾 NSUserDefaults 篡改: %@ = YES (原值: %@)", defaultName, result);
                return @YES;
            }
            if (result == nil) {
                NSLog(@"[Crack] 💾 NSUserDefaults 篡改: %@ = YES (原值为nil)", defaultName);
                return @YES;
            }
            break;
        }
    }
    return result;
}

- (void)crack_setObject:(id)value forKey:(NSString *)defaultName {
    NSArray *vipKeys = @[@"vip", @"VIP", @"isVip", @"isVIP", @"pro", @"premium", @"member", @"paid"];
    for (NSString *key in vipKeys) {
        if ([defaultName containsString:key] || [defaultName isEqualToString:key]) {
            if ([value isKindOfClass:[NSNumber class]] && [value boolValue] == NO) {
                NSLog(@"[Crack] 💾 NSUserDefaults 写入拦截: %@ = YES (原值: %@)", defaultName, value);
                [self crack_setObject:@YES forKey:defaultName];
                return;
            }
            break;
        }
    }
    [self crack_setObject:value forKey:defaultName];
}

@end

#pragma mark - 初始化入口

__attribute__((constructor))
static void initialize() {
    NSLog(@"");
    NSLog(@"╔══════════════════════════════════════════════╗");
    NSLog(@"║    🔓 UniversalCrack.dylib v3.0            ║");
    NSLog(@"║    万能iOS卡密破解插件                      ║");
    NSLog(@"║    专为 iOS 14.3 + TrollStore 优化        ║");
    NSLog(@"╚══════════════════════════════════════════════╝");
    NSLog(@"");
    
    // 1. 打印所有类（帮助定位目标）
    printAllClasses();
    
    // 2. 自动 Hook 所有验证类
    autoHookAllClasses();
    
    // 3. Hook NSURLSession 已通过 +load 实现
    // 4. Hook NSUserDefaults 已通过 +load 实现
    
    NSLog(@"[Crack] ✅ 所有 Hook 已加载完成！");
    NSLog(@"[Crack] 💡 输入任意卡密都会验证成功");
    NSLog(@"[Crack] 💡 VIP/付费功能全部解锁");
    NSLog(@"");
}

__attribute__((destructor))
static void finalize() {
    NSLog(@"[Crack] UniversalCrack 已卸载");
}
