/********* InfineaSDKCordova.m Cordova Plugin Implementation *******/

#import <WebKit/WebKit.h>
#import <Cordova/CDV.h>
#import <InfineaSDK/InfineaSDK.h>

@interface InfineaSDKCordova : CDVPlugin <IPCDTDeviceDelegate>

@property (strong, nonatomic) IPCIQ *iq;
@property (strong, nonatomic) IPCDTDevices *ipc;

- (void)coolMethod:(CDVInvokedUrlCommand*)command;

// Available functions
- (void)setDeveloperKey:(CDVInvokedUrlCommand *)command;
- (void)connect:(CDVInvokedUrlCommand*)command;
- (void)disconnect:(CDVInvokedUrlCommand*)command;
- (void)getConnectedDeviceInfo:(CDVInvokedUrlCommand*)command;
- (void)getConnectedDevicesInfo:(CDVInvokedUrlCommand*)command;
- (void)setPassThroughSync:(CDVInvokedUrlCommand*)command;
- (void)getPassThroughSync:(CDVInvokedUrlCommand*)command;
- (void)setUSBChargeCurrent:(CDVInvokedUrlCommand*)command;
- (void)getUSBChargeCurrent:(CDVInvokedUrlCommand*)command;
- (void)getBatteryInfo:(CDVInvokedUrlCommand*)command;
- (void)setAutoOffWhenIdle:(CDVInvokedUrlCommand*)command;
- (void)rfInit:(CDVInvokedUrlCommand*)command;
- (void)rfClose:(CDVInvokedUrlCommand*)command;
- (void)barcodeGetScanButtonMode:(CDVInvokedUrlCommand*)command;
- (void)barcodeSetScanButtonMode:(CDVInvokedUrlCommand*)command;
- (void)barcodeGetScanMode:(CDVInvokedUrlCommand*)command;
- (void)barcodeSetScanMode:(CDVInvokedUrlCommand*)command;
- (void)barcodeStartScan:(CDVInvokedUrlCommand*)command;
- (void)barcodeStopScan:(CDVInvokedUrlCommand*)command;
- (void)setCharging:(CDVInvokedUrlCommand*)command;
- (void)getFirmwareFileInformation:(CDVInvokedUrlCommand*)command;
- (void)updateFirmwareData:(CDVInvokedUrlCommand*)command;
- (void)emsrSetEncryption:(CDVInvokedUrlCommand*)command;
- (void)emsrSetActiveHead:(CDVInvokedUrlCommand*)command;
- (void)emsrConfigMaskedDataShowExpiration:(CDVInvokedUrlCommand*)command;
- (void)emsrIsTampered:(CDVInvokedUrlCommand*)command;
- (void)emsrGetKeyVersion:(CDVInvokedUrlCommand*)command;
- (void)emsrGetDeviceInfo:(CDVInvokedUrlCommand*)command;
- (void)barcodeSetScanBeep: (CDVInvokedUrlCommand *)command;

@end

@implementation InfineaSDKCordova

// Prototype
- (void)coolMethod:(CDVInvokedUrlCommand*)command
{
    NSLog(@"Call coolMethod");
    
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];
    
    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
// *********

// Callback helper
- (void)callback:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    va_list args;
    va_start(args, format);
    NSString *javascript = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if ([self.webView isKindOfClass:WKWebView.class]) {
        [(WKWebView*)self.webView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {}];
    }
    else {
        [(UIWebView*)self.webView stringByEvaluatingJavaScriptFromString: javascript];
    }
}



// SDK API
- (void)barcodeSetScanBeep: (CDVInvokedUrlCommand *)command{
    NSLog(@"Call barocdeSetScanBeep");
    
    CDVPluginResult *pluginResult = nil;
    BOOL enabled = [command.arguments[0] boolValue];
    NSError *beepError = nil;
    int volume = 100;
    NSArray *beeps = command.arguments[1];

    int numberOfData = (int)beeps.count;

    int beepData[numberOfData];
    for (int x = 0; x < numberOfData; x++) {
        beepData[x] = [beeps[x] intValue];
    }

    BOOL isSuccess =[self.ipc barcodeSetScanBeep:enabled volume:volume beepData:beepData length:(int)sizeof(beepData) error:&beepError];
    if(isSuccess){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:enabled];
    }
    else{
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:beepError.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrGetKeyVersion:(CDVInvokedUrlCommand*)command{
    NSLog(@"Call emsrGetKeyVersion");
    
    CDVPluginResult* pluginResult = nil;
    int keyID = [command.arguments[0] intValue];
    int keyVersion = -1;
    NSError *error = nil;
    
    BOOL isSuccess = [self.ipc emsrGetKeyVersion:keyID keyVersion:&keyVersion error:&error];
    
    if(isSuccess){
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:keyVersion];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrGetDeviceInfo:(CDVInvokedUrlCommand *)command{
    NSLog(@"Call emsrGetDeviceInfo");
    
    CDVPluginResult* pluginResult = nil;
    NSError *error = nil;
    EMSRDeviceInfo *emsrInfo = [self.ipc emsrGetDeviceInfo:&error];
    
    if(emsrInfo){
        NSDictionary *emsrInfoDictionary = @{@"ident": emsrInfo.ident,
                                             @"serialNumber": [NSString stringWithFormat:@"%@", emsrInfo.serialNumber],
                                             @"serialNumberString": emsrInfo.serialNumberString,
                                             @"firmwareVersion": @(emsrInfo.firmwareVersion),
                                             @"firmwareVersionString": emsrInfo.firmwareVersionString,
                                             @"securityVersion": @(emsrInfo.securityVersion),
                                             @"securityVersionString": emsrInfo.securityVersionString
                                             };
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:emsrInfoDictionary];
    }else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrIsTampered:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call emsrIsTampered");
    
    CDVPluginResult* pluginResult = nil;
    BOOL isTampered = NO;
    
    NSError *error = nil;
    BOOL isSuccess = [self.ipc emsrIsTampered:&isTampered error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isTampered];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrConfigMaskedDataShowExpiration:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call emsrConfigMaskedDataShowExpiration");
    
    CDVPluginResult* pluginResult = nil;
    BOOL showExpiration = [[command.arguments objectAtIndex:0] boolValue];
    BOOL showServiceCode = [[command.arguments objectAtIndex:1] boolValue];
    int unmaskedDigitsAtStart = [[command.arguments objectAtIndex:2] intValue];
    int unmaskedDigitsAtEnd = [[command.arguments objectAtIndex:3] intValue];
    int unmaskedDigitsAfter = [[command.arguments objectAtIndex:4] intValue];
    
    NSError *error = nil;
    BOOL isSuccess = [self.ipc emsrConfigMaskedDataShowExpiration:showExpiration showServiceCode:showServiceCode unmaskedDigitsAtStart:unmaskedDigitsAtStart unmaskedDigitsAtEnd:unmaskedDigitsAtEnd unmaskedDigitsAfter:unmaskedDigitsAfter error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrSetActiveHead:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call emsrSetActiveHead");
    
    CDVPluginResult* pluginResult = nil;
    int active = [[command.arguments objectAtIndex:0] intValue];
    
    NSError *error = nil;
    BOOL isSuccess = [self.ipc emsrSetActiveHead:active error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)emsrSetEncryption:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call emsrSetEncryption");
    
    CDVPluginResult* pluginResult = nil;
    int encryption = [[command.arguments objectAtIndex:0] intValue];
    int keyID = [[command.arguments objectAtIndex:1] intValue];
    NSDictionary *params = nil;
    if (command.arguments.count > 2) {
        // Check for null
        id object = [command.arguments objectAtIndex:2];
        if ([object isKindOfClass:[NSDictionary class]]) {
            params = (NSDictionary *)object;
        }
    }
    
    NSError *error = nil;
    BOOL isSuccess = [self.ipc emsrSetEncryption:encryption keyID:keyID params:params error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCharging:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call setCharging");
    
    CDVPluginResult* pluginResult = nil;
    BOOL echo = [command.arguments objectAtIndex:0];
    
    NSError *error;
    BOOL isSuccess = [self.ipc setCharging:echo error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeStartScan:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeStartScan");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    BOOL isSuccess = [self.ipc barcodeStartScan:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeStopScan:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeStopScan");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    BOOL isSuccess = [self.ipc barcodeStopScan:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeGetScanMode:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeGetScanMode");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    int scanMode = 1;
    BOOL isSuccess = [self.ipc barcodeGetScanMode:&scanMode error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:scanMode];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeSetScanMode:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeSetScanMode");
    
    CDVPluginResult* pluginResult = nil;
    int echo = [[command.arguments objectAtIndex:0] intValue];
    
    NSError *error;
    BOOL isSuccess = [self.ipc barcodeSetScanMode:echo error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeGetScanButtonMode:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeGetScanButtonMode");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    int scanButtonMode = 1;
    BOOL isSuccess = [self.ipc barcodeGetScanButtonMode:&scanButtonMode error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:scanButtonMode];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)barcodeSetScanButtonMode:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call barcodeSetScanButtonMode");
    
    CDVPluginResult* pluginResult = nil;
    int echo = [[command.arguments objectAtIndex:0] intValue];
    
    NSError *error;
    BOOL isSuccess = [self.ipc barcodeSetScanButtonMode:echo error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)rfClose:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call rfClose");
    
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    BOOL isSuccess = [self.ipc rfClose:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)rfInit:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call rfInit");
    
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    BOOL isSuccess = [self.ipc rfInit:CARD_SUPPORT_PICOPASS_ISO15|CARD_SUPPORT_TYPE_A|CARD_SUPPORT_TYPE_B|CARD_SUPPORT_ISO15|CARD_SUPPORT_FELICA error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setAutoOffWhenIdle:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call setAutoOffWhenIdle");
    
    CDVPluginResult* pluginResult = nil;
    int timeIdle = [[command.arguments objectAtIndex:0] intValue];
    int timeDisconnected = [[command.arguments objectAtIndex:1] intValue];
    
    NSError *error;
    BOOL isSuccess = [self.ipc setAutoOffWhenIdle:timeIdle whenDisconnected:timeDisconnected error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getBatteryInfo:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getBatteryInfo");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error = nil;
    DTBatteryInfo *battInfo = [self.ipc getBatteryInfo:&error];
    if (!error) {
        NSDictionary *info = @{@"voltage": @(battInfo.voltage),
                               @"capacity": @(battInfo.capacity),
                               @"health": @(battInfo.health),
                               @"maximumCapacity": @(battInfo.maximumCapacity),
                               @"charging": @(battInfo.charging),
                               @"batteryChipType": @(battInfo.batteryChipType),
                               @"extendedInfo": battInfo.extendedInfo != nil ? battInfo.extendedInfo : @""
                               };
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getUSBChargeCurrent:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getUSBChargeCurrent");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    int current = 0;
    BOOL isSuccess = [self.ipc getUSBChargeCurrent:&current error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:current];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUSBChargeCurrent:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call setUSBChargeCurrent");
    
    CDVPluginResult* pluginResult = nil;
    int echo = [[command.arguments objectAtIndex:0] intValue];
    
    NSError *error;
    BOOL isSuccess = [self.ipc setUSBChargeCurrent:echo error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getPassThroughSync:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getPassThroughSync");
    
    CDVPluginResult* pluginResult = nil;
    
    NSError *error;
    BOOL isEnable = NO;
    BOOL isSuccess = [self.ipc getPassThroughSync:&isEnable error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isEnable];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setPassThroughSync:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call setPassThroughSync");
    
    CDVPluginResult* pluginResult = nil;
    BOOL echo = [command.arguments objectAtIndex:0];
    
    NSError *error;
    BOOL isSuccess = [self.ipc setPassThroughSync:echo error:&error];
    if (!error || isSuccess) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getConnectedDevicesInfo:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getConnectedDevicesInfo");
    
    CDVPluginResult* pluginResult = nil;
    NSError *error = nil;
    
    NSArray *connectedDevices = [self.ipc getConnectedDevicesInfo:&error];
    
    if (!error) {
        NSMutableArray *devicesInfo = [NSMutableArray new];
        for (DTDeviceInfo *deviceInfo in connectedDevices) {
            NSDictionary *device = @{@"deviceType": @(deviceInfo.deviceType),
                                     @"connectionType": @(deviceInfo.connectionType),
                                     @"name": deviceInfo.name,
                                     @"model": deviceInfo.model,
                                     @"firmwareRevision": deviceInfo.firmwareRevision,
                                     @"hardwareRevision": deviceInfo.hardwareRevision,
                                     @"serialNumber": deviceInfo.serialNumber
                                     };
            
            [devicesInfo addObject:device];
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:devicesInfo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getConnectedDeviceInfo:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getConnectedDeviceInfo");
    
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];
    
    NSError *error = nil;
    DTDeviceInfo *deviceInfo = [self.ipc getConnectedDeviceInfo:[echo intValue] error:&error];
    if (!error) {
        NSDictionary *info = @{@"deviceType": @(deviceInfo.deviceType),
                               @"connectionType": @(deviceInfo.connectionType),
                               @"name": deviceInfo.name,
                               @"model": deviceInfo.model,
                               @"firmwareRevision": deviceInfo.firmwareRevision,
                               @"hardwareRevision": deviceInfo.hardwareRevision,
                               @"serialNumber": deviceInfo.serialNumber
                               };
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setDeveloperKey:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call setDeveloperKey");
    
    NSString* key = [command.arguments objectAtIndex:0];
    
    self.iq = [IPCIQ registerIPCIQ];
    [self.iq setDeveloperKey:key];
    
    self.ipc = [IPCDTDevices sharedDevice];
}

- (NSURL *)resourcePath
{
    NSURL *pathURL = [[NSBundle mainBundle] resourceURL];
    return [pathURL URLByAppendingPathComponent:@"www/resources"];
}

- (void)getFirmwareFileInformation:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call getFirmwareFileInformation");
    
    CDVPluginResult *pluginResult = nil;
    NSString *filePath = [command.arguments objectAtIndex:0];
    filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSURL *fullFilePathURL = [[self resourcePath] URLByAppendingPathComponent:filePath];
    
    @try {
        NSData *fileData = [NSData dataWithContentsOfURL:fullFilePathURL];
        
        if (!fileData) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to read file. Check file path!"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        else {
            
            NSError *error = nil;
            NSDictionary *firmwareInfo = [self.ipc getFirmwareFileInformation:fileData error:&error];
            if (!error) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:firmwareInfo];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
            }
            
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
            return;
        }
        
    } @catch (NSException *exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        return;
    }
}

- (void)updateFirmwareData:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call updateFirmwareData");
    
    self.ipc = [IPCDTDevices sharedDevice];
    
    CDVPluginResult *pluginResult = nil;
    NSString *filePath = [command.arguments objectAtIndex:0];
    filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    NSURL *fullFilePathURL = [[self resourcePath] URLByAppendingPathComponent:filePath];
    
    if (self.ipc.connstate != CONN_CONNECTED) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device is not connected!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        
        return;
    }
    else {
        @try {
            NSData *fileData = [NSData dataWithContentsOfURL:fullFilePathURL];
            
            if (!fileData) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to read file. Check file path!"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }
            else {
                NSError *error = nil;
                BOOL isUpdate = [self.ipc updateFirmwareData:fileData validate:YES error:&error];
                if (!error || isUpdate) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                }
                
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
                return;
            }
            
        } @catch (NSException *exception) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            
            return;
        }
    }
}

- (void)connect:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call connect");
    
    self.ipc = [IPCDTDevices sharedDevice];
    [self.ipc addDelegate:self];
    [self.ipc connect];
}

- (void)disconnect:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Call disconnect");
    
    self.ipc = [IPCDTDevices sharedDevice];
    [self.ipc disconnect];
}

#pragma mark - IPCDeviceDelegate
- (void)connectionState:(int)state
{
    [self callback:@"Infinea.connectionState(%i)", state];
}

- (void)barcodeData:(NSString *)barcode type:(int)type
{
    //*************
    // This send to regular barcodeData as string
    [self callback:@"Infinea.barcodeData(\"%@\", %i)", barcode, type];
    
    
    //*************
    // Convert to decimal
    const char *barcodes = [barcode UTF8String];
    NSMutableArray *barcodeDecimalArray = [NSMutableArray new];
    for (int i = 0; i < sizeof(barcodes); i++) {
        NSString *string = [NSString stringWithFormat:@"%02d", barcodes[i]];
        NSLog(@"%@", string);
        [barcodeDecimalArray addObject:string];
    }
    NSString *barcodeDecimalString = [barcodeDecimalArray componentsJoinedByString:@","];
    
    // Send to barcodeDecimals as decimal array
    [self callback:@"Infinea.barcodeDecimals([%@], %i)", barcodeDecimalString, type];
}

- (void)barcodeNSData:(NSData *)barcode type:(int)type
{
    // Hex data
    NSString *hexData = [NSString stringWithFormat:@"%@", barcode];
    hexData = [hexData stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hexData = [hexData stringByReplacingOccurrencesOfString:@">" withString:@""];
    hexData = [hexData stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // Ascii string
    uint8_t *bytes=(uint8_t *)[barcode bytes];
    NSMutableString *escapedString = [@"" mutableCopy];
    for (int x = 0; x < barcode.length;x++)
    {
        [escapedString appendFormat:@"\\x%02X", bytes[x] ];
    }
    
    [self callback:@"Infinea.barcodeNSData(\"%@\", %i)", hexData, type];
}

- (void)rfCardDetected:(int)cardIndex info:(DTRFCardInfo *)info
{
    NSDictionary *cardInfo = @{@"type": @(info.type),
                               @"typeStr": info.typeStr,
                               @"UID": [NSString stringWithFormat:@"%@", info.UID],
                               @"ATQA": @(info.ATQA),
                               @"SAK": @(info.SAK),
                               @"AFI": @(info.AFI),
                               @"DSFID": @(info.DSFID),
                               @"blockSize": @(info.blockSize),
                               @"nBlocks": @(info.nBlocks),
                               @"felicaPMm": [NSString stringWithFormat:@"%@", info.felicaPMm],
                               @"felicaRequestData": [NSString stringWithFormat:@"%@", info.felicaRequestData],
                               @"cardIndex": @(info.cardIndex)
                               };
    
    [self callback:@"Infinea.rfCardDetected(%i, %@)", cardIndex, cardInfo];
}

- (void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
    [self callback:@"Infinea.magneticCardData(\"%@\", \"%@\", \"%@\")", track1, track2, track3];
}

- (void)magneticCardEncryptedData:(int)encryption tracks:(int)tracks data:(NSData *)data track1masked:(NSString *)track1masked track2masked:(NSString *)track2masked track3:(NSString *)track3 source:(int)source
{
    [self callback:@"Infinea.magneticCardEncryptedData(%i, %i, \"%@\", \"%@\", \"%@\", \"%@\", %i)", encryption, tracks, [NSString stringWithFormat:@"%@", data], track1masked, track2masked, track3, source];
}

- (void)magneticCardReadFailed:(int)source reason:(int)reason
{
    [self callback:@"Infinea.magneticCardReadFailed(%i, %i)", source, reason];
}

- (void)magneticCardReadFailed:(int)source
{
    [self callback:@"Infinea.magneticCardReadFailed(%i, %i)", source, -1];
}

- (void)deviceButtonPressed:(int)which
{
    [self callback:@"Infinea.deviceButtonPressed(%i)", which];
}

- (void)deviceButtonReleased:(int)which
{
    [self callback:@"Infinea.deviceButtonReleased(%i)", which];
}

- (void)firmwareUpdateProgress:(int)phase percent:(int)percent
{
    [self callback:@"Infinea.firmwareUpdateProgress(%i, %i)", phase, percent];
}


@end

