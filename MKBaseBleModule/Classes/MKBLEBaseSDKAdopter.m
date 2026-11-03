//
//  MKBLEBaseSDKAdopter.m
//  Pods-MKBLEBaseModule_Example
//
//  Created by aa on 2019/11/14.
//

#import "MKBLEBaseSDKAdopter.h"
#import "MKBLEBaseSDKDefines.h"

#pragma mark - C 层辅助函数

/// 单个字符转十六进制值，非法字符返回 -1
static inline int mkb_hexCharValue(char c) {
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    return -1;
}

/// 整串是否全部为合法的十六进制字符，等价于原来的 "[a-fA-F0-9]*" 整串正则匹配
static BOOL mkb_isHexString(NSString *string) {
    const char *utf8 = [string UTF8String];
    if (utf8 == NULL) {
        return NO;
    }
    size_t length = strlen(utf8);
    for (size_t i = 0; i < length; i ++) {
        if (mkb_hexCharValue(utf8[i]) < 0) {
            return NO;
        }
    }
    return YES;
}

/// 十六进制字符串转无符号整数，遇到非法字符停止，与 NSScanner 的扫描行为一致
static unsigned long long mkb_hexToULL(const char *utf8, size_t length) {
    unsigned long long value = 0;
    for (size_t i = 0; i < length; i ++) {
        int digit = mkb_hexCharValue(utf8[i]);
        if (digit < 0) {
            break;
        }
        value = (value << 4) | (unsigned long long)digit;
    }
    return value;
}

/// 十六进制字符对应的 4 位二进制字符串
static const char * const kMKBHexBitStrings[16] = {
    "0000", "0001", "0010", "0011",
    "0100", "0101", "0110", "0111",
    "1000", "1001", "1010", "1011",
    "1100", "1101", "1110", "1111",
};

@implementation MKBLEBaseSDKAdopter

+ (NSError *)getErrorWithCode:(NSInteger)code message:(NSString *)message {
    NSError *error = [[NSError alloc] initWithDomain:@"com.moko.BLESDK"
                                                code:code
                                            userInfo:@{@"errorInfo":message}];
    return error;
}

+ (void)operationCentralBlePowerOffBlock:(void (^)(NSError *error))block{
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:-10001 message:@"Mobile phone bluetooth is currently unavailable"];
            block(error);
        }
    });
}

+ (void)operationConnectFailedBlock:(void (^)(NSError *error))block{
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:-10001 message:@"Connect Failed"];
            block(error);
        }
    });
}

+ (void)operationConnectingErrorBlock:(void (^)(NSError *error))block {
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:-10001 message:@"The devices are connectting"];
            block(error);
        }
    });
}

+ (void)operationProtocolErrorBlock:(void (^)(NSError *error))block {
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:-10001 message:@"The parameters passed in must conform to the protocol"];
            block(error);
        }
    });
}

+ (void)operationParamsErrorBlock:(void (^)(NSError *error))block {
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:10001 message:@"Params error"];
            block(error);
        }
    });
}

+ (void)operationSetParamsErrorBlock:(void (^)(NSError *error))block {
    MKBLEBase_main_safe(^{
        if (block) {
            NSError *error = [self getErrorWithCode:-10001 message:@"Set parameter error"];
            block(error);
        }
    });
}

+ (NSInteger)getDecimalWithHex:(NSString *)content range:(NSRange)range{
    if (!MKValidStr(content)) {
        return 0;
    }
    // 与原逻辑一致：整串必须是合法的十六进制字符串
    if (!mkb_isHexString(content)) {
        return 0;
    }
    if (range.location > content.length - 1 || range.length > content.length || (range.location + range.length > content.length)) {
        return 0;
    }
    const char *utf8 = [content UTF8String];
    if (utf8 == NULL) {
        return 0;
    }
    // 全部是 ASCII 字符，UTF-8 偏移与 NSString 的下标一致，可直接按字节解析
    return (NSInteger)mkb_hexToULL(utf8 + range.location, range.length);
}

+ (NSString *)getDecimalStringWithHex:(NSString *)content range:(NSRange)range{
    NSInteger decimalValue = [self getDecimalWithHex:content range:range];
    return [NSString stringWithFormat:@"%ld",(long)decimalValue];
}

+ (NSString *)hexStringFromSignedNumber:(NSInteger)number {
    NSString *tempNumber = [NSString stringWithFormat:@"%lX", (long)number];
    if (tempNumber.length == 1) {
        tempNumber = [@"0" stringByAppendingString:tempNumber];
    }
    // 原实现是转成 NSData 后取最后一个字节再转小写十六进制，等价于取最后两个字符后转小写
    if (tempNumber.length < 2) {
        return @"";
    }
    return [[tempNumber substringFromIndex:tempNumber.length - 2] lowercaseString];
}

+ (NSNumber *)signedHexTurnString:(NSString *)content{
    if (!MKValidStr(content)) {
        return @(0);
    }
    // 原来的 [self stringToData:content].length 就是字节数，这里直接用字符数计算，两者等价
    NSInteger lenth = (NSInteger)((content.length + 1) / 2);
    if (lenth > 8) {
        // 超过 64bit 的情况保持原有 NSScanner 逻辑，避免出现任何行为差异
        return [self signedHexTurnStringByScanner:content];
    }
    const char *utf8 = [content UTF8String];
    if (utf8 == NULL) {
        return @(0);
    }
    unsigned long long value = mkb_hexToULL(utf8, strlen(utf8));
    if (lenth == 8) {
        // 64bit 满宽度，本身即为补码表示
        return [NSNumber numberWithLongLong:(long long)value];
    }
    // centerHexString = "0x8" + (2*lenth-1) 个 "0"，即 2^(8*lenth-1)
    unsigned long long center = 1ULL << (8 * lenth - 1);
    if (value < center) {
        return [NSNumber numberWithLongLong:(long long)value];
    }
    // 等同于原实现的 maxValue - minValue - 1，即 value - 2^(8*lenth)
    return [NSNumber numberWithLongLong:(long long)(value - (center << 1))];
}

+ (NSData *)getCrc16VerifyCode:(NSData *)data{
    if (!MKValidData(data)) {
        return [NSData data];
    }
    NSInteger crcWord = 0xffff;
    Byte *dataArray = (Byte *)[data bytes];
    for (NSInteger i = 0; i < data.length; i ++) {
        Byte byte = dataArray[i];
        crcWord ^= (NSInteger)byte & 0x00ff;
        for (NSInteger j = 0; j < 8; j ++) {
            if ((crcWord & 0x0001) == 1) {
                crcWord = crcWord >> 1;
                crcWord = crcWord ^ 0xA001;
            }else{
                crcWord = (crcWord >> 1);
            }
        }
    }
    
    Byte crcL = (Byte)0xff & (crcWord >> 8);
    Byte crcH = (Byte)0xff & (crcWord);
    Byte arrayCrc[] = {crcH, crcL};
    NSData *dataCrc = [NSData dataWithBytes:arrayCrc length:sizeof(arrayCrc)];
    return dataCrc;
}

+ (NSString *)hexStringFromData:(NSData *)sourceData{
    if (!MKValidData(sourceData)) {
        return @"";
    }
    const Byte *bytes = (const Byte *)[sourceData bytes];
    NSUInteger length = [sourceData length];
    // 原来的实现每次循环都用 stringWithFormat 拼接整串，复杂度是 O(n²)，这里预分配容量一次写完
    NSMutableString *hexStr = [NSMutableString stringWithCapacity:length * 2];
    for (NSUInteger i = 0; i < length; i ++) {
        [hexStr appendFormat:@"%02x", (unsigned int)(bytes[i] & 0xff)];
    }
    return hexStr;
}

+ (NSData *)stringToData:(NSString *)dataString{
    if (!MKValidStr(dataString)) {
        return [NSData data];
    }
    const char *utf8 = [dataString UTF8String];
    if (utf8 == NULL) {
        return [NSData data];
    }
    size_t length = strlen(utf8);
    // 原来的实现每两个字符创建一次 substring + NSScanner + NSData，这里直接按字节解析
    NSMutableData *hexData = [[NSMutableData alloc] initWithCapacity:length / 2 + 1];
    size_t location = 0;
    // 奇数长度时首个字符单独作为一个字节，与原实现一致
    size_t currentLength = (length % 2 == 0) ? 2 : 1;
    while (location < length) {
        unsigned long long value = mkb_hexToULL(utf8 + location, currentLength);
        Byte byte = (Byte)(value & 0xff);
        [hexData appendBytes:&byte length:1];
        location += currentLength;
        currentLength = 2;
    }
    return hexData;
}

+ (BOOL)checkHexCharacter:(NSString *)character {
    if (!MKValidStr(character)) {
        return NO;
    }
    // 原来每次都创建 NSPredicate + 正则，这里改成逐字符查表
    return mkb_isHexString(character);
}

+ (NSString *)binaryByhex:(NSString *)hex {
    if (!MKValidStr(hex) || ![self checkHexCharacter:hex]) {
        return @"";
    }
    // 奇数长度前面补一个 "0"，与原实现一致
    if (hex.length % 2 != 0) {
        hex = [@"0" stringByAppendingString:hex];
    }
    const char *utf8 = [hex UTF8String];
    if (utf8 == NULL) {
        return @"";
    }
    NSUInteger length = hex.length;
    // 原来每次都创建 NSDictionary + O(n²) 拼接字符串，这里用静态查表 + NSMutableString
    NSMutableString *binaryString = [NSMutableString stringWithCapacity:length * 4];
    for (NSUInteger i = 0; i < length; i ++) {
        int digit = mkb_hexCharValue(utf8[i]);
        if (digit < 0) {
            continue;
        }
        [binaryString appendString:[NSString stringWithUTF8String:kMKBHexBitStrings[digit]]];
    }
    return binaryString;
}

+ (BOOL)asciiString:(NSString *)content {
    NSInteger strlen = content.length;
    NSInteger datalen = [[content dataUsingEncoding:NSUTF8StringEncoding] length];
    if (strlen != datalen) {
        return NO;
    }
    return YES;
}

+ (BOOL)isUUIDString:(NSString *)uuid{
    static NSRegularExpression *uuidRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *uuidPatternString = @"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$";
        uuidRegex = [NSRegularExpression regularExpressionWithPattern:uuidPatternString
                                                               options:NSRegularExpressionCaseInsensitive
                                                                 error:nil];
    });
    if (uuidRegex == nil) {
        return NO;
    }
    NSInteger numberOfMatches = [uuidRegex numberOfMatchesInString:uuid
                                                           options:kNilOptions
                                                             range:NSMakeRange(0, uuid.length)];
    return (numberOfMatches > 0);
}

+ (NSString *)getHexByBinary:(NSString *)binary {
    if (!MKValidStr(binary) || ![self checkHexCharacter:binary]) {
        return @"";
    }
    if (binary.length % 8 != 0) {
        NSMutableString *mStr = [[NSMutableString alloc] init];
        for (int i = 0; i < 8 - binary.length % 8; i ++) {
            [mStr appendString:@"0"];
        }
        binary = [mStr stringByAppendingString:binary];
    }
    const char *utf8 = [binary UTF8String];
    if (utf8 == NULL) {
        return @"";
    }
    NSUInteger length = binary.length;
    NSMutableString *tempString = [NSMutableString stringWithCapacity:length / 4];
    for (NSUInteger i = 0; i + 4 <= length; i += 4) {
        NSInteger value = 0;
        BOOL validGroup = YES;
        for (NSUInteger j = 0; j < 4; j ++) {
            char c = utf8[i + j];
            if (c == '1') {
                value = (value << 1) | 1;
            }else if (c == '0') {
                value = value << 1;
            }else {
                // 原实现从这里取不到字典值，会跳过该组
                validGroup = NO;
                break;
            }
        }
        if (!validGroup) {
            continue;
        }
        [tempString appendFormat:@"%lX", (long)value];
    }
    return tempString;
}

+ (NSString *)fetchHexValue:(unsigned long)value byteLen:(NSInteger)len {
    if (len <= 0) {
        return @"";
    }
    // 原来的实现循环在前面补 "0"，字符串越长越慢，这里一次格式化完成
    return [NSString stringWithFormat:@"%0*lx", (int)(2 * len), (unsigned long)value];
}

#pragma mark - private method

/// 原始 NSScanner 版本，仅用于长度超过 8 字节的极端情况
+ (NSNumber *)signedHexTurnStringByScanner:(NSString *)content {
    NSData *tempData = [self stringToData:content];
    NSInteger lenth = [tempData length];
    NSString *maxHexString = [self headString:@"F" trilString:@"F" strLenth:lenth];
    NSString *centerHexString = [self headString:@"8" trilString:@"0" strLenth:lenth];
    if ([[self numberHexString:content] longLongValue] - [[self numberHexString:centerHexString] longLongValue] < 0) {
        return [self numberHexString:content];
    }
    unsigned long long maxValue = [[self numberHexString:content] longLongValue];
    unsigned long long minValue = [[self numberHexString:maxHexString] longLongValue];
    return [NSNumber numberWithLongLong:(maxValue - minValue - 1)];
}

// 16进制转10进制
+ (NSNumber *) numberHexString:(NSString *)aHexString {
    if (nil == aHexString) {
        return nil;
    }
    NSScanner * scanner = [NSScanner scannerWithString:aHexString];
    unsigned long long longlongValue;
    [scanner scanHexLongLong:&longlongValue];
    NSNumber * hexNumber = [NSNumber numberWithLongLong:longlongValue];
    return hexNumber;
}

+ (NSString *)headString:(NSString *)headStr trilString:(NSString *)trilStr strLenth:(NSInteger)lenth {
    if (!headStr || !trilStr) {
        return nil;
    }
    NSMutableString *string = [NSMutableString stringWithFormat:@"0x%@", headStr];
    for (int i = 0; i < lenth * 2 - 1; i ++)
    {
        [string appendString:trilStr];
    }
    return string;
}

@end
