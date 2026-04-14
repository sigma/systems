#import <CoreMIDI/CoreMIDI.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <sys/stat.h>

// MARK: - Configuration types

@interface MSMDeviceConfig : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSInteger port;
+ (instancetype)fromDict:(NSDictionary *)dict;
@end

@implementation MSMDeviceConfig
+ (instancetype)fromDict:(NSDictionary *)dict {
    MSMDeviceConfig *d = [MSMDeviceConfig new];
    d.name = dict[@"name"];
    d.host = [dict[@"host"] isKindOfClass:[NSNull class]] ? nil : dict[@"host"];
    id portVal = dict[@"port"];
    d.port = (portVal && ![portVal isKindOfClass:[NSNull class]]) ? [portVal integerValue] : 0;
    return d;
}
@end

@interface MSMSessionConfig : NSObject
@property (nonatomic, strong) NSString *localName;
@property (nonatomic, strong) NSString *networkName;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, strong) NSArray<MSMDeviceConfig *> *devices;
+ (instancetype)fromDict:(NSDictionary *)dict;
@end

@implementation MSMSessionConfig
+ (instancetype)fromDict:(NSDictionary *)dict {
    MSMSessionConfig *s = [MSMSessionConfig new];
    s.localName = dict[@"localName"];
    s.networkName = dict[@"networkName"];
    s.port = [dict[@"port"] integerValue];
    NSMutableArray *devs = [NSMutableArray new];
    for (NSDictionary *dd in dict[@"devices"]) {
        [devs addObject:[MSMDeviceConfig fromDict:dd]];
    }
    s.devices = devs;
    return s;
}
@end

// MARK: - Logger

static NSString *gLogPath = nil;
static FILE *gLogFile = NULL;
static const NSInteger kMaxLogSize = 1024 * 1024; // 1MB

static void logInit(void) {
    gLogPath = [NSString stringWithFormat:@"%@/Library/Logs/midi-session-manager.log",
                NSHomeDirectory()];
    NSString *dir = [gLogPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    gLogFile = fopen([gLogPath fileSystemRepresentation], "a");
}

static void logMessage(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void logMessage(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSDateFormatter *fmt = [NSDateFormatter new];
    fmt.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n",
                      [fmt stringFromDate:[NSDate date]], message];

    const char *utf8 = [line UTF8String];
    fprintf(stderr, "%s", utf8);
    if (gLogFile) {
        fprintf(gLogFile, "%s", utf8);
        fflush(gLogFile);
    }
}

static void logTruncateIfNeeded(void) {
    if (!gLogFile) return;
    struct stat st;
    if (fstat(fileno(gLogFile), &st) == 0 && st.st_size > kMaxLogSize) {
        fclose(gLogFile);
        gLogFile = fopen([gLogPath fileSystemRepresentation], "w");
        logMessage(@"Log truncated (exceeded 1MB)");
    }
}

// MARK: - CoreMIDI entity helpers

static CFStringRef const kRTPSessionKey = CFSTR("apple.midirtp.session");

/// Find the "Network" device (driver: com.apple.AppleMIDINetworkDriver, non-UMP)
static MIDIDeviceRef findNetworkDevice(void) {
    ItemCount n = MIDIGetNumberOfDevices();
    for (ItemCount i = 0; i < n; i++) {
        MIDIDeviceRef device = MIDIGetDevice(i);
        CFStringRef driver = NULL;
        MIDIObjectGetStringProperty(device, kMIDIPropertyDriverOwner, &driver);
        if (!driver) continue;

        BOOL isNetwork = CFStringCompare(driver, CFSTR("com.apple.AppleMIDINetworkDriver"),
                                         0) == kCFCompareEqualTo;
        CFRelease(driver);
        if (!isNetwork) continue;

        // Skip UMP Network device
        CFStringRef name = NULL;
        MIDIObjectGetStringProperty(device, kMIDIPropertyName, &name);
        BOOL isUMP = name && CFStringCompare(name, CFSTR("UMP Network"), 0) == kCFCompareEqualTo;
        if (name) CFRelease(name);
        if (isUMP) continue;

        return device;
    }
    return 0;
}

/// Find entity by local session name within the Network device
static MIDIEntityRef findEntityForSession(MIDIDeviceRef netDevice, NSString *sessionName) {
    ItemCount n = MIDIDeviceGetNumberOfEntities(netDevice);
    for (ItemCount i = 0; i < n; i++) {
        MIDIEntityRef entity = MIDIDeviceGetEntity(netDevice, i);
        CFStringRef name = NULL;
        MIDIObjectGetStringProperty(entity, kMIDIPropertyName, &name);
        if (name) {
            BOOL match = [(__bridge NSString *)name isEqualToString:sessionName];
            CFRelease(name);
            if (match) return entity;
        }
    }
    return 0;
}

/// Read the RTP session dictionary from an entity
static NSDictionary *readSessionDict(MIDIEntityRef entity) {
    CFDictionaryRef dict = NULL;
    OSStatus status = MIDIObjectGetDictionaryProperty(entity, kRTPSessionKey, &dict);
    if (status != noErr || !dict) return nil;
    NSDictionary *result = [(__bridge NSDictionary *)dict copy];
    CFRelease(dict);
    return result;
}

/// Write the RTP session dictionary to an entity
static BOOL writeSessionDict(MIDIEntityRef entity, NSDictionary *dict) {
    OSStatus status = MIDIObjectSetDictionaryProperty(entity, kRTPSessionKey,
                                                       (__bridge CFDictionaryRef)dict);
    return status == noErr;
}

/// Check if a peer with given name exists in the peers array
static BOOL hasPeerNamed(NSArray *peers, NSString *name) {
    for (NSDictionary *peer in peers) {
        NSString *peerName = peer[@"name"];
        if (peerName && [peerName caseInsensitiveCompare:name] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

// MARK: - Probe mode

static void probeClass(Class cls, NSString *className) {
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(cls, &methodCount);
    printf("Instance methods of %s (%u):\n", [className UTF8String], methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        printf("  -[%s %s]\n", [className UTF8String], sel_getName(method_getName(methods[i])));
    }
    if (methods) free(methods);

    Class metaClass = object_getClass(cls);
    methods = class_copyMethodList(metaClass, &methodCount);
    printf("Class methods of %s (%u):\n", [className UTF8String], methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        printf("  +[%s %s]\n", [className UTF8String], sel_getName(method_getName(methods[i])));
    }
    if (methods) free(methods);
    printf("\n");
}

static int runProbe(void) {
    printf("=== CoreMIDI Network Session API ===\n\n");
    probeClass([MIDINetworkSession class], @"MIDINetworkSession");

    printf("=== MIDI Devices ===\n");
    ItemCount numDevices = MIDIGetNumberOfDevices();
    for (ItemCount i = 0; i < numDevices; i++) {
        MIDIDeviceRef device = MIDIGetDevice(i);
        CFStringRef devName = NULL, devDriver = NULL;
        MIDIObjectGetStringProperty(device, kMIDIPropertyName, &devName);
        MIDIObjectGetStringProperty(device, kMIDIPropertyDriverOwner, &devDriver);
        SInt32 offline = 0;
        MIDIObjectGetIntegerProperty(device, kMIDIPropertyOffline, &offline);

        printf("Device %lu: %s (driver: %s, offline: %d)\n", (unsigned long)i,
               devName ? [(__bridge NSString *)devName UTF8String] : "?",
               devDriver ? [(__bridge NSString *)devDriver UTF8String] : "?",
               (int)offline);
        if (devName) CFRelease(devName);
        if (devDriver) CFRelease(devDriver);

        ItemCount numEntities = MIDIDeviceGetNumberOfEntities(device);
        for (ItemCount j = 0; j < numEntities; j++) {
            MIDIEntityRef entity = MIDIDeviceGetEntity(device, j);
            CFStringRef entName = NULL;
            MIDIObjectGetStringProperty(entity, kMIDIPropertyName, &entName);
            printf("  Entity %lu: %s\n", (unsigned long)j,
                   entName ? [(__bridge NSString *)entName UTF8String] : "?");
            if (entName) CFRelease(entName);

            // Read RTP session dict if present
            NSDictionary *sessionDict = readSessionDict(entity);
            if (sessionDict) {
                printf("    RTP session: %s\n", [[sessionDict description] UTF8String]);
            }
        }
    }

    return 0;
}

// MARK: - Session Manager

@interface MIDISessionManager : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) NSArray<MSMSessionConfig *> *sessions;
@property (nonatomic, assign) NSInteger pollInterval;
@property (nonatomic, assign) MIDIDeviceRef networkDevice;
@property (nonatomic, strong) NSNetServiceBrowser *browser;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNetService *> *activeServices;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *resolvedDevices;
@property (nonatomic, strong) NSTimer *healthCheckTimer;

- (instancetype)initWithConfigPath:(NSString *)path;
- (void)start;
@end

@implementation MIDISessionManager

- (instancetype)initWithConfigPath:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        fprintf(stderr, "Error: cannot read config file %s\n", [path UTF8String]);
        exit(1);
    }

    NSError *err = nil;
    NSDictionary *config = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) {
        fprintf(stderr, "Error: cannot parse config: %s\n", [[err description] UTF8String]);
        exit(1);
    }

    NSMutableArray *sessions = [NSMutableArray new];
    for (NSDictionary *sd in config[@"sessions"]) {
        [sessions addObject:[MSMSessionConfig fromDict:sd]];
    }
    _sessions = sessions;

    id pollVal = config[@"pollInterval"];
    _pollInterval = pollVal ? [pollVal integerValue] : 30;

    _activeServices = [NSMutableDictionary new];
    _resolvedDevices = [NSMutableDictionary new];

    _networkDevice = findNetworkDevice();
    if (!_networkDevice) {
        logMessage(@"ERROR: Network MIDI device not found");
        exit(1);
    }

    return self;
}

- (void)start {
    logMessage(@"Starting MIDI session manager (%lu session(s))",
               (unsigned long)_sessions.count);

    for (MSMSessionConfig *session in _sessions) {
        MIDIEntityRef entity = findEntityForSession(_networkDevice, session.localName);
        if (entity) {
            logMessage(@"  Session '%@' -> entity found", session.localName);
        } else {
            logMessage(@"  Session '%@' -> NOT FOUND (create in Audio MIDI Setup first)",
                       session.localName);
        }
        for (MSMDeviceConfig *dev in session.devices) {
            logMessage(@"    Device '%@'%@", dev.name,
                       dev.host ? [NSString stringWithFormat:@" (static: %@:%ld)",
                                   dev.host, (long)dev.port] : @"");
        }
    }

    // Sleep/wake notifications
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self selector:@selector(handleSleep:)
     name:NSWorkspaceWillSleepNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self selector:@selector(handleWake:)
     name:NSWorkspaceDidWakeNotification object:nil];

    // Connect any static hosts immediately
    [self connectStaticHosts];

    // Start Bonjour browsing
    [self startBrowsing];

    // Health check timer
    _healthCheckTimer = [NSTimer scheduledTimerWithTimeInterval:_pollInterval
                                                        target:self
                                                      selector:@selector(healthCheck:)
                                                      userInfo:nil
                                                       repeats:YES];

    logMessage(@"Running (health check every %lds)", (long)_pollInterval);
}

// MARK: - Bonjour

- (void)startBrowsing {
    _browser = [NSNetServiceBrowser new];
    _browser.delegate = self;
    [_browser searchForServicesOfType:@"_apple-midi._udp" inDomain:@""];
    logMessage(@"Bonjour browsing started");
}

- (void)stopBrowsing {
    [_browser stop];
    _browser = nil;
    for (NSNetService *svc in _activeServices.allValues) {
        [svc stop];
    }
    logMessage(@"Bonjour browsing stopped");
}

- (BOOL)isConfiguredDevice:(NSString *)name {
    for (MSMSessionConfig *session in _sessions) {
        for (MSMDeviceConfig *dev in session.devices) {
            if ([dev.name caseInsensitiveCompare:name] == NSOrderedSame) return YES;
        }
    }
    return NO;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)service
               moreComing:(BOOL)moreComing {
    if (![self isConfiguredDevice:service.name]) return;
    logMessage(@"Discovered: %@", service.name);
    _activeServices[service.name] = service;
    service.delegate = self;
    [service resolveWithTimeout:10.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)service
               moreComing:(BOOL)moreComing {
    if (![self isConfiguredDevice:service.name]) return;
    logMessage(@"Disappeared: %@", service.name);
    [_activeServices removeObjectForKey:service.name];
    [_resolvedDevices removeObjectForKey:service.name];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    // CoreMIDI uses Bonjour service references as peer addresses:
    // \t<serviceName>\t<domain>
    NSString *domain = sender.domain ?: @"local.";
    NSString *bonjourAddr = [NSString stringWithFormat:@"\t%@\t%@", sender.name, domain];
    logMessage(@"Resolved %@ (domain: %@, port: %ld)", sender.name, domain, (long)sender.port);

    _resolvedDevices[sender.name] = @{
        @"name": sender.name,
        @"address": bonjourAddr,
    };

    [self connectDeviceNamed:sender.name];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    logMessage(@"Resolve failed for %@: %@", sender.name, errorDict);
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
             didNotSearch:(NSDictionary *)errorDict {
    logMessage(@"Browse failed: %@, retrying in 5s", errorDict);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        [self startBrowsing];
    });
}

// MARK: - Connection management

- (void)connectStaticHosts {
    for (MSMSessionConfig *session in _sessions) {
        for (MSMDeviceConfig *dev in session.devices) {
            if (!dev.host) continue;
            NSInteger port = dev.port > 0 ? dev.port : 5004;
            // Static hosts use IP address format
            _resolvedDevices[dev.name] = @{
                @"name": dev.name,
                @"address": [NSString stringWithFormat:@"%@:%ld", dev.host, (long)port],
            };
            [self addPeer:dev.name toSession:session.localName];
        }
    }
}

- (void)connectDeviceNamed:(NSString *)deviceName {
    for (MSMSessionConfig *session in _sessions) {
        for (MSMDeviceConfig *dev in session.devices) {
            if ([dev.name caseInsensitiveCompare:deviceName] == NSOrderedSame) {
                [self addPeer:deviceName toSession:session.localName];
            }
        }
    }
}

- (void)addPeer:(NSString *)deviceName toSession:(NSString *)sessionName {
    MIDIEntityRef entity = findEntityForSession(_networkDevice, sessionName);
    if (!entity) {
        logMessage(@"Session '%@' entity not found", sessionName);
        return;
    }

    NSDictionary *sessionDict = readSessionDict(entity);
    if (!sessionDict) {
        logMessage(@"Cannot read session dict for '%@'", sessionName);
        return;
    }

    NSArray *peers = sessionDict[@"peers"] ?: @[];
    if (hasPeerNamed(peers, deviceName)) {
        return; // Already connected
    }

    NSDictionary *peerInfo = _resolvedDevices[deviceName];
    if (!peerInfo) {
        logMessage(@"No resolved address for '%@'", deviceName);
        return;
    }

    // Add peer
    NSMutableArray *newPeers = [peers mutableCopy];
    [newPeers addObject:peerInfo];

    NSMutableDictionary *newDict = [sessionDict mutableCopy];
    newDict[@"peers"] = newPeers;

    if (writeSessionDict(entity, newDict)) {
        logMessage(@"Added '%@' as peer to session '%@'", deviceName, sessionName);
    } else {
        logMessage(@"Failed to write peer for '%@' to session '%@'", deviceName, sessionName);
    }
}

// MARK: - Health check

- (void)healthCheck:(NSTimer *)timer {
    for (MSMSessionConfig *session in _sessions) {
        MIDIEntityRef entity = findEntityForSession(_networkDevice, session.localName);
        if (!entity) continue;

        NSDictionary *sessionDict = readSessionDict(entity);
        if (!sessionDict) continue;

        NSArray *peers = sessionDict[@"peers"] ?: @[];

        for (MSMDeviceConfig *dev in session.devices) {
            NSDictionary *resolved = _resolvedDevices[dev.name];
            if (!resolved) continue; // Not discovered yet

            if (!hasPeerNamed(peers, dev.name)) {
                logMessage(@"Health: '%@' missing from '%@', reconnecting",
                           dev.name, session.localName);
                [self addPeer:dev.name toSession:session.localName];
            }
        }
    }

    logTruncateIfNeeded();
}

// MARK: - Sleep/Wake

- (void)handleSleep:(NSNotification *)note {
    logMessage(@"System sleeping, stopping browsing");
    [self stopBrowsing];
}

- (void)handleWake:(NSNotification *)note {
    logMessage(@"System woke, restarting in 5s");
    [self performSelector:@selector(restartAfterWake) withObject:nil afterDelay:5.0];
}

- (void)restartAfterWake {
    logMessage(@"Restarting after wake");
    [self startBrowsing];
    [self healthCheck:nil];
}

@end

// MARK: - Main

static void printUsage(const char *prog) {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  %s --config <path>  Run daemon with config file\n", prog);
    fprintf(stderr, "  %s --probe          Dump CoreMIDI network session info\n", prog);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) { printUsage(argv[0]); return 1; }

        NSString *arg1 = [NSString stringWithUTF8String:argv[1]];

        if ([arg1 isEqualToString:@"--probe"]) {
            return runProbe();
        }

        if ([arg1 isEqualToString:@"--config"]) {
            if (argc < 3) {
                fprintf(stderr, "Error: --config requires a path\n");
                return 1;
            }
            logInit();

            NSString *configPath = [NSString stringWithUTF8String:argv[2]];
            MIDISessionManager *manager = [[MIDISessionManager alloc]
                                           initWithConfigPath:configPath];
            [manager start];
            [[NSRunLoop currentRunLoop] run];
            return 0;
        }

        printUsage(argv[0]);
        return 1;
    }
}
