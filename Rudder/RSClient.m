//
//  RSClient.m
//  RSSDKCore
//
//  Created by Arnab Pal on 17/10/19.
//  Copyright © 2019 RSlabs. All rights reserved.
//

#import "RSClient.h"
#import "RSEventRepository.h"
#import "RSMessageBuilder.h"
#import "RSElementCache.h"
#import "RSMessageType.h"
#import "RSLogger.h"

static RSClient *_instance = nil;
static RSEventRepository *_repository = nil;
static RSOption* _defaultOptions = nil;

@implementation RSClient

+ (instancetype) getInstance {
    return _instance;
}

+ (instancetype) getInstance:(NSString *)writeKey {
    return [RSClient getInstance:writeKey config:[[RSConfig alloc] init]];
}

+ (instancetype) getInstance:(NSString *)writeKey config: (RSConfig*) config options: (RSOption*) options {
    _defaultOptions = options;
    return [RSClient getInstance:writeKey config:config];
}

+ (instancetype) getInstance: (NSString *) writeKey config: (RSConfig*) config {
    if (_instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [[self alloc] init];
            _repository = [RSEventRepository initiate:writeKey config:config];
        });
    }
    return _instance;
}

- (void) trackMessage:(RSMessage *)message {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self dumpInternal:message type:RSTrack];
}

- (void) dumpInternal:(RSMessage *)message type:(NSString*) type {
    if (_repository != nil && message != nil) {
        if (type == RSIdentify) {
            [RSElementCache persistTraits];
            
            //  handle external Ids
            RSOption *option = message.option;
            if (option != nil) {
                NSMutableArray *externalIds = option.externalIds;
                if (externalIds != nil) {
                    [RSElementCache updateExternalIds:externalIds];
                }
            }
            
            [message updateContext:[RSElementCache getContext]];
        }
        message.type = type;
        [_repository dump:message];
    }
}

- (void)trackWithBuilder:(RSMessageBuilder *)builder{
    if ([RSClient getOptStatus]) {
        return;
    }
    [self dumpInternal:[builder build] type:RSTrack];
}

- (void)track:(NSString *)eventName {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:eventName];
    [self dumpInternal:[builder build] type:RSTrack];
}

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *,NSObject *> *)properties {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:eventName];
    [builder setPropertyDict:properties];
    [self dumpInternal:[builder build] type:RSTrack];
}

- (void)track:(NSString *)eventName properties:(NSDictionary<NSString *,NSObject *> *)properties options:(RSOption *)options {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:eventName];
    [builder setPropertyDict:properties];
    [builder setRSOption:options];
    [self dumpInternal:[builder build] type:RSTrack];
}

- (void) screenWithMessage:(RSMessage *)message {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self dumpInternal:message type:RSScreen];
}

- (void)screenWithBuilder:(RSMessageBuilder *)builder {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self dumpInternal:[builder build] type:RSScreen];
}

- (void)screen:(NSString *)screenName {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    NSMutableDictionary *property = [[NSMutableDictionary alloc] init];
    [property setValue:screenName forKey:@"name"];
    [builder setEventName:screenName];
    [builder setPropertyDict:property];
    [self dumpInternal:[builder build] type:RSScreen];
}

- (void)screen:(NSString *)screenName properties:(NSDictionary<NSString *,NSObject *> *)properties {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    NSMutableDictionary *property;
    if (properties == nil) {
        property = [[NSMutableDictionary alloc] init];
    } else {
        property = [properties mutableCopy];
    }
    [property setValue:screenName forKey:@"name"];
    [builder setEventName:screenName];
    [builder setPropertyDict:property];
    [self dumpInternal:[builder build] type:RSScreen];
}

- (void)screen:(NSString *)screenName properties:(NSDictionary<NSString *,NSObject *> *)properties options:(RSOption *)options {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    NSMutableDictionary *property;
    if (properties == nil) {
        property = [[NSMutableDictionary alloc] init];
    } else {
        property = [properties mutableCopy];
    }
    [property setValue:screenName forKey:@"name"];
    [builder setEventName:screenName];
    [builder setPropertyDict:property];
    [builder setRSOption:options];
    [self dumpInternal:[builder build] type:RSScreen];
}

- (void)group:(NSString *)groupId{
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setGroupId:groupId];
    [self dumpInternal:[builder build] type:RSGroup];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setGroupId:groupId];
    [builder setGroupTraits:traits];
    [self dumpInternal:[builder build] type:RSGroup];
}

- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(RSOption *)options {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setGroupId:groupId];
    [builder setGroupTraits:traits];
    [builder setRSOption:options];
    [self dumpInternal:[builder build] type:RSGroup];
}

- (void)alias:(NSString *)newId {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self alias:newId options:nil];
}

- (void) alias:(NSString *)newId options:(RSOption *) options {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSMessageBuilder *builder =[[RSMessageBuilder alloc] init];
    [builder setUserId:newId];
    [builder setRSOption:options];
    
    RSContext *rc = [RSElementCache getContext];
    NSMutableDictionary<NSString*,NSObject*>* traits = [rc.traits mutableCopy];
    
    NSObject *prevId = [traits objectForKey:@"userId"];
    if(prevId == nil) {
        prevId =[traits objectForKey:@"id"];
    }
    
    if (prevId != nil) {
        [builder setPreviousId:[NSString stringWithFormat:@"%@", prevId]];
    }
    traits[@"id"] = newId;
    traits[@"userId"] = newId;
    
    [RSElementCache updateTraitsDict:traits];
    [RSElementCache persistTraits];
    
    RSMessage *message = [builder build];
    [message updateTraitsDict:traits];
    
    [self dumpInternal:message type:RSAlias];
}

- (void) pageWithMessage:(RSMessage *)message {
    [RSLogger logWarn:@"Page call is no more supported for iOS source"];
}

- (void) identifyWithMessage:(RSMessage *)message {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self dumpInternal:message type:RSIdentify];
}

- (void)identifyWithBuilder:(RSMessageBuilder *)builder {
    if ([RSClient getOptStatus]) {
        return;
    }
    [self identifyWithMessage:[builder build]];
}

- (void)identify:(NSString*)userId {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSTraits* traitsCopy = [[RSTraits alloc] init];
    [traitsCopy setUserId:userId];
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:RSIdentify];
    [builder setUserId:userId];
    [builder setTraits:traitsCopy];
    [self dumpInternal:[builder build] type:RSIdentify];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSTraits* traitsObj = [[RSTraits alloc] initWithDict: traits];
    [traitsObj setUserId:userId];
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:RSIdentify];
    [builder setUserId:userId];
    [builder setTraits:traitsObj];
    [self dumpInternal:[builder build] type:RSIdentify];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(RSOption *)options {
    if ([RSClient getOptStatus]) {
        return;
    }
    RSTraits *traitsObj = [[RSTraits alloc] initWithDict:traits];
    [traitsObj setUserId:userId];
    RSMessageBuilder *builder = [[RSMessageBuilder alloc] init];
    [builder setEventName:RSIdentify];
    [builder setUserId:userId];
    [builder setTraits:traitsObj];
    [builder setRSOption:options];
    [self dumpInternal:[builder build] type:RSIdentify];
}

- (void)reset {
    [RSElementCache reset];
    if (_repository != nil) {
        [_repository reset];
    }
}

- (void)flush {
    if ([RSClient getOptStatus]) {
        return;
    }
    if (_repository != nil) {
        [_repository flush];
    }
}

+ (BOOL)getOptStatus {
    if (_repository == nil) {
        [RSLogger logError:@"SDK is not initialised. Hence dropping the event"];
        return true;
    }
    if ([_repository getOptStatus]) {
        [RSLogger logDebug:@"User Opted out for tracking the activity, hence dropping the event"];
        return true;
    }
    return false;
}

- (void)optOut:(BOOL) optOut {
    if (_repository != nil) {
        [_repository saveOptStatus:optOut];
        [RSLogger logInfo:[NSString stringWithFormat:@"optOut() flag is set to %@", optOut ? @"true" : @"false"]];
    }
    else {
        [RSLogger logError:@"SDK is not initialised. Hence aborting optOut API call"];
    }
}

- (void)shutdown {
    // TODO: decide shutdown behavior
}

- (NSString*)getAnonymousId {
    if ([RSClient getOptStatus]) {
        return nil;
    }
    // returns anonymousId
    return [RSElementCache getContext].device.identifier;
}

- (RSContext*) getContext {
    if ([RSClient getOptStatus]) {
        return nil;
    }
    return [RSElementCache getContext];
}

- (RSConfig*)configuration {
    if (_repository == nil) {
        return nil;
    }
    if ([RSClient getOptStatus]) {
        return nil;
    }
    return [_repository getConfig];
}

- (void)trackLifecycleEvents:(NSDictionary *)launchOptions {
    if ([RSClient getOptStatus]) {
        return;
    }
    [_repository _applicationDidFinishLaunchingWithOptions:launchOptions];
}

+ (instancetype)sharedInstance {
    return _instance;
}

+ (RSOption*) getDefaultOptions {
    return _defaultOptions;
}

+ (void)setAnonymousId:(NSString *)anonymousId {
    RSPreferenceManager *preferenceManager = [RSPreferenceManager getInstance];
    if ([preferenceManager getOptStatus]) {
        [RSLogger logDebug:@"User Opted out for tracking the activity, hence dropping the event"];
        return;
    }
    [preferenceManager saveAnonymousId:anonymousId];
}

@end
