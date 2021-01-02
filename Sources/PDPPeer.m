#import "IPAddress.h"
#import "Ed25519PublicKey.h"
#import "PDPPeer.h"
#import "PDPAgent.h"
#import "Ed25519KeyPair.h"

@implementation PDPPeer

@synthesize supportsUnencryptedConnection;
@synthesize supportsEncryptedConnectionV1;
@synthesize deviceName;
@synthesize deviceModel;
@synthesize publicKey;
@synthesize tcpListenPort;

-(id)init {
    self = [super init];
    if (self) {
        recentAddresses = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

+(PDPPeer*)localPeer {
	static PDPPeer *localPeer;
	if (!localPeer) {
		localPeer = [[PDPPeer alloc] init];

        localPeer.supportsUnencryptedConnection = NO;
        localPeer.supportsEncryptedConnectionV1 = YES;
        
		/* Get computer model, eg. MacBookPro12,1 */
		CFStringRef computerModel = nil;
		io_service_t pexpdev;
		if ((pexpdev = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))))
		{
			CFDataRef data = IORegistryEntryCreateCFProperty(pexpdev, CFSTR("model"), kCFAllocatorDefault, 0);
			if (data) {
				computerModel = CFStringCreateWithBytes(kCFAllocatorDefault, CFDataGetBytePtr(data), CFDataGetLength(data), kCFStringEncodingUTF8, false);
				CFRelease(data);
			}
		}
		if (computerModel) {
			localPeer.deviceModel = (id)computerModel;
			CFRelease(computerModel);
		} else {
			localPeer.deviceModel = @"UnknownDevice";
		}

	}
	
	/* Get computer name */
	CFStringRef deviceName = CSCopyMachineName();
	localPeer.deviceName = (id)deviceName;
	CFRelease(deviceName);
	// Alternative method to get computer name
	// #import <SystemConfiguration/SystemConfiguration.h>
	// CFStringRef computername = SCDynamicStoreCopyComputerName(nil, nil);
	
    localPeer.publicKey = [PDPAgent currentDeviceKeyPair].publicKey;
    
	return localPeer;
}

-(void)addRecentAddress:(IPAddress*)address {
    NSInteger numRecentAddresses = recentAddresses.count;
    if (numRecentAddresses) {
        if ([[recentAddresses objectAtIndex:numRecentAddresses-1] isEqual:address]) {
            return;
        }
        [recentAddresses removeObject:address];
    }
    [recentAddresses addObject:address];
}

-(NSArray *)recentAddresses {
    return [[recentAddresses copy] autorelease];
}

-(NSString*)mostRecentPresentationAddressAndPort {
    if (!recentAddresses.count) return @"no recent address";
    NSString *recentAddress = [[recentAddresses lastObject] presentationAddress];
    if (tcpListenPort == 0) {
        return recentAddress;
    }
    else if ([recentAddress rangeOfString:@":"].location == NSNotFound) {
        return [NSString stringWithFormat:@"%@:%hu", recentAddress, tcpListenPort];
    }
    else {
        return [NSString stringWithFormat:@"[%@]:%hu", recentAddress, tcpListenPort];
    }
}

-(BOOL)acceptIncomingTransfers {
    return [incomingTransferMode isEqual:@"accept"];
}

-(void)setAcceptIncomingTransfers:(BOOL)acceptIncomingTransfers {
    NSString *newMode;
    if (acceptIncomingTransfers) {
        newMode = @"accept";
    } else {
        newMode = @"reject";
    }
    NSString *oldMode = incomingTransferMode;
    incomingTransferMode = [newMode retain];
    [oldMode release];
}

-(BOOL)setDictionaryRepresentation:(NSDictionary *)dict error:(NSError**)outError {
    {
        NSString *deviceKey = [dict objectForKey:@"DeviceKey"];
        if ([deviceKey isKindOfClass:[NSString class]]) {
            Ed25519PublicKey *newKey = [Ed25519PublicKey publicKeyWithStringRepresentation:deviceKey error:outError];
            if (!newKey) return NO;
            [publicKey release];
            publicKey = [newKey retain];
        }
    }
    [dictionaryRepresentation release];
    dictionaryRepresentation = [dict copy];
    {
        NSString *newDeviceName = [dict objectForKey:@"DeviceName"];
        if ([newDeviceName isKindOfClass:[NSString class]]) {
            [deviceName release];
            deviceName = [newDeviceName copy];
        }
    }
    {
        NSString *newDeviceModel = [dict objectForKey:@"DeviceModel"];
        if ([newDeviceModel isKindOfClass:[NSString class]]) {
            [deviceModel release];
            deviceModel = [newDeviceModel copy];
        }
    }
    {
        NSString *newIncomingTransferMode = [dict objectForKey:@"IncomingTransferMode"];
        if ([newIncomingTransferMode isKindOfClass:[NSString class]]) {
            [incomingTransferMode release];
            incomingTransferMode = [newIncomingTransferMode copy];
        }
    }
    return YES;
}

-(NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [dictionaryRepresentation mutableCopy] ?: [[NSMutableDictionary alloc] init];
    if (publicKey) [dict setObject:publicKey.stringRepresentation forKey:@"DeviceKey"];
    if (deviceName) [dict setObject:deviceName forKey:@"DeviceName"];
    if (deviceModel) [dict setObject:deviceModel forKey:@"DeviceModel"];
    if (incomingTransferMode) [dict setObject:incomingTransferMode forKey:@"IncomingTransferMode"];
    return [dict autorelease];
}

-(void)writeToUserDefaults {
    if (!publicKey) return;
    NSArray *peers = [[NSUserDefaults standardUserDefaults] objectForKey:@"Peers"];
    NSMutableArray *mutablePeers = [peers isKindOfClass:[NSArray class]] ? [peers mutableCopy] : [[NSMutableArray alloc] init];
    for (int i = [peers count]; i-->0;) {
        NSDictionary *dict = [peers objectAtIndex:i];
        if (![dict isKindOfClass:[NSDictionary class]]) continue;
        NSString *deviceKey = [dict objectForKey:@"DeviceKey"];
        if ([deviceKey isKindOfClass:[NSString class]]) {
            Ed25519PublicKey *peerPublicKey = [Ed25519PublicKey publicKeyWithStringRepresentation:deviceKey error:nil];
            if ([peerPublicKey isEqual:publicKey]) {
                [mutablePeers replaceObjectAtIndex:i withObject:self.dictionaryRepresentation];
                [[NSUserDefaults standardUserDefaults] setObject:mutablePeers forKey:@"Peers"];
                [mutablePeers release];
                return;
            }
        }
    }
    [mutablePeers addObject:self.dictionaryRepresentation];
    [[NSUserDefaults standardUserDefaults] setObject:mutablePeers forKey:@"Peers"];
    [mutablePeers release];
}

-(void)dealloc {
    [recentAddresses release];
	[deviceModel release];
	[deviceName release];
	[publicKey release];
    [incomingTransferMode release];
    [dictionaryRepresentation release];
    [super dealloc];
}

@end
