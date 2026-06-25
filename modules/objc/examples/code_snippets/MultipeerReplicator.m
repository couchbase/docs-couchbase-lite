//
//  MultipeerReplicator.m
//  CouchbaseLite
//
//  Copyright © 2025 couchbase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface MultipeerReplicatorSnippets : NSObject

@end

@interface CustomConflictResolver : NSObject <CBLMultipeerConflictResolver>
@end

@implementation CustomConflictResolver

- (nullable CBLDocument*) resolveConflict: (CBLConflict*)conflict forPeer: (CBLPeerID*)peerID {
    return conflict.remoteDocument;
}

@end

@implementation MultipeerReplicatorSnippets {
    CBLDatabase *database;
    CBLCollection *collection1;
    CBLCollection *collection2;
    CBLCollection *collection3;
}

- (NSArray<CBLMultipeerCollectionConfiguration *> *)collectionSimple {
    // tag::multipeer-collection-simple
    NSMutableArray<CBLMultipeerCollectionConfiguration*> *collections = [NSMutableArray array];
    for (CBLCollection *col in @[collection1, collection2, collection3]) {
        CBLMultipeerCollectionConfiguration *config =
        [[CBLMultipeerCollectionConfiguration alloc] initWithCollection:col];
        [collections addObject:config];
    }
    // end::multipeer-collection-simple
    return collections;
}

- (NSArray<CBLMultipeerCollectionConfiguration *> *)collectionConfig {
    // Config with custom conflict resolver
    CBLMultipeerCollectionConfiguration *config1 =
        [[CBLMultipeerCollectionConfiguration alloc] initWithCollection:collection1];
    config1.conflictResolver = [[CustomConflictResolver alloc] init];

    // Config with document IDs filter
    CBLMultipeerCollectionConfiguration *config2 =
        [[CBLMultipeerCollectionConfiguration alloc] initWithCollection:collection2];
    config2.documentIDs = @[@"doc1", @"doc2"];

    // Config with push replication filter
    CBLMultipeerCollectionConfiguration *config3 =
        [[CBLMultipeerCollectionConfiguration alloc] initWithCollection:collection3];
    config3.pushFilter = ^BOOL(CBLPeerID *peerID, CBLDocument *document, CBLDocumentFlags flags) {
        return [document integerForKey:@"access-level"] == 2;
    };

    NSArray *collections = @[config1, config2, config3];
    // end::multipeer-collection-config
    return collections;
}

- (CBLTLSIdentity *)createSelfSignedIdentity {
    // tag::multipeer-selfsigned-tlsidentity
    // Note: This example is simplified for demonstration and does not include error handling.
    NSString *persistentLabel = @"com.myapp.identity";

    // Retrieve the TLS identity from the keychain using the persistent label.
    NSError *error = nil;
    CBLTLSIdentity *identity = [CBLTLSIdentity identityWithLabel:persistentLabel error:&error];

    // If the identity exists but is expired, delete it.
    if (identity && [identity.expiration compare:[NSDate date]] == NSOrderedAscending) {
        [CBLTLSIdentity deleteIdentityWithLabel: persistentLabel error: &error];
        identity = nil;
    }

    // If the identity doesn't exist or expired, create a new one.
    if (!identity) {
        // Define certificate attributes and expiration date.
        NSDictionary *attrs = @{ kCBLCertAttrCommonName: @"MyApp" };
        NSDate *expiration = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear
            value:2
            toDate:[NSDate date]
            options:0];

        // Create and store a new self-signed identity in the keychain with a persistent label.
        identity = [CBLTLSIdentity createIdentityForKeyUsages:kCBLKeyUsagesClientAuth|kCBLKeyUsagesServerAuth
            attributes:attrs
            expiration:expiration
            label:persistentLabel
            error:&error];
    }
    // end::multipeer-selfsigned-tlsidentity
    return identity;
}

- (CBLTLSIdentity *)createCASignedIdentity {
    // tag::multipeer-tlsidentity
    // Note: This example is simplified for demonstration and does not include error handling.
    NSString *persistentLabel = @"com.myapp.identity";

    // Retrieve the TLS identity from the keychain using the persistent label.
    NSError *error = nil;
    CBLTLSIdentity *identity = [CBLTLSIdentity identityWithLabel:persistentLabel error:&error];

    // If the identity exists but is expired, delete it.
    if (identity && [identity.expiration compare:[NSDate date]] == NSOrderedAscending) {
        [CBLTLSIdentity deleteIdentityWithLabel: persistentLabel error: &error];
        identity = nil;
    }

    // If the identity doesn't exist or expired, create a new one.
    if (!identity) {
        // Get the issuer's private key and certificate data (DER format) for signing the identity's certificate.
        NSData *caKey = [self getIssuerPrivateKeyData];
        NSData *caCert = [self getIssuerCertificateData];

        // Define certificate attributes and expiration date.
        NSDictionary *attrs = @{ kCBLCertAttrCommonName: @"MyApp" };
        NSDate *expiration = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear
            value:2
            toDate:[NSDate date]
            options:0];

        // Create and store a new identity signed with the issuer in the keychain with a persistent label.
        identity = [CBLTLSIdentity createSignedIdentityInsecureForKeyUsages:kCBLKeyUsagesClientAuth|kCBLKeyUsagesServerAuth
            attributes:attrs
            expiration:expiration
            caKey:caKey
            caCertificate:caCert
            label:persistentLabel
            error:&error];
    }
    // end::multipeer-tlsidentity
    return identity;
}

- (NSData *)getIssuerPrivateKeyData {
    return [[NSData alloc] initWithBase64EncodedString:@"your_base64_encoded_private_key" options:0];
}

- (NSData *)getIssuerCertificateData {
    return [[NSData alloc] initWithBase64EncodedString:@"your_base64_encoded_certicate" options:0];
}

- (id<CBLMultipeerAuthenticator>)authenticatorWithCallback {
    // tag::multipeer-authenticator-callback
    id<CBLMultipeerAuthenticator> authenticator =
    [[CBLMultipeerCertificateAuthenticator alloc] initWithBlock:^BOOL(CBLPeerID *peerID, NSArray *certs) {
        return YES;
    }];
    // end::multipeer-authenticator-callback
    return authenticator;
}

- (id<CBLMultipeerAuthenticator>)authenticatorWithRootCerts {
    // tag::multipeer-authenticator-rootcerts
    // Get issuer's certificate data (DER format), which was used to sign the peer's certificate.
    NSData *caCert = [self getIssuerCertificateData];
    SecCertificateRef caCertRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)caCert);
    id<CBLMultipeerAuthenticator> authenticator =
    [[CBLMultipeerCertificateAuthenticator alloc] initWithRootCerts:@[(__bridge_transfer id)caCertRef]];
    // end::multipeer-authenticator-rootcerts
    return authenticator;
}

- (CBLMultipeerReplicatorConfiguration *)createConfig {
    CBLTLSIdentity *identity = [self createCASignedIdentity];
    id<CBLMultipeerAuthenticator> authenticator = [self authenticatorWithRootCerts];
    NSArray<CBLMultipeerCollectionConfiguration *> *collections = [self collectionConfig];

    // tag::multipeer-config
    CBLMultipeerReplicatorConfiguration *config =
    [[CBLMultipeerReplicatorConfiguration alloc] initWithPeerGroupID:@"com.myapp"
        identity:identity
        authenticator:authenticator
        collections:collections];
    // end::multipeer-config
    return config;
}

- (CBLMultipeerReplicatorConfiguration *)createConfigTransportsDefault {
    CBLTLSIdentity *identity = [self createCASignedIdentity];
    id<CBLMultipeerAuthenticator> authenticator = [self authenticatorWithRootCerts];
    NSArray<CBLMultipeerCollectionConfiguration *> *collections = [self collectionConfig];

    // tag::multipeer-config-transports-default[]
    // Wi-Fi is the default transport. No additional configuration is required.
    CBLMultipeerReplicatorConfiguration *config =
    [[CBLMultipeerReplicatorConfiguration alloc] initWithPeerGroupID:@"com.myapp"
        identity:identity
        authenticator:authenticator
        collections:collections];
    // config.transports defaults to kCBLMultipeerTransportWifi
    // end::multipeer-config-transports-default[]
    return config;
}

- (CBLMultipeerReplicatorConfiguration *)createConfigTransportsBoth {
    CBLTLSIdentity *identity = [self createCASignedIdentity];
    id<CBLMultipeerAuthenticator> authenticator = [self authenticatorWithRootCerts];
    NSArray<CBLMultipeerCollectionConfiguration *> *collections = [self collectionConfig];

    // tag::multipeer-config-transports-both[]
    CBLMultipeerReplicatorConfiguration *config =
    [[CBLMultipeerReplicatorConfiguration alloc] initWithPeerGroupID:@"com.myapp"
        identity:identity
        authenticator:authenticator
        collections:collections];
    config.transports = kCBLMultipeerTransportWifi | kCBLMultipeerTransportBluetooth;
    // end::multipeer-config-transports-both[]
    return config;
}

- (CBLMultipeerReplicatorConfiguration *)createConfigTransportsBluetoothOnly {
    CBLTLSIdentity *identity = [self createCASignedIdentity];
    id<CBLMultipeerAuthenticator> authenticator = [self authenticatorWithRootCerts];
    NSArray<CBLMultipeerCollectionConfiguration *> *collections = [self collectionConfig];

    // tag::multipeer-config-transports-bluetooth-only[]
    CBLMultipeerReplicatorConfiguration *config =
    [[CBLMultipeerReplicatorConfiguration alloc] initWithPeerGroupID:@"com.myapp"
        identity:identity
        authenticator:authenticator
        collections:collections];
    config.transports = kCBLMultipeerTransportBluetooth;
    // end::multipeer-config-transports-bluetooth-only[]
    return config;
}

- (void)statusListener {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-status-listener[]
    [replicator addStatusListenerWithQueue:nil listener:^(CBLMultipeerReplicatorStatus *status) {
        // transport is nil for the aggregated overall status;
        // non-nil for a per-transport status update.
        NSString *transport = status.transport == nil ? @"all"
            : (status.transport.unsignedIntegerValue == kCBLMultipeerTransportWifi ? @"wifi" : @"bluetooth");
        NSString *state = status.active ? @"active" : @"inactive";
        NSString *err = status.error ? status.error.localizedDescription : @"none";
        NSLog(@"Multipeer Replicator [%@]: %@, Error: %@", transport, state, err);
    }];
    // end::multipeer-status-listener[]
}

- (void)peerDiscoveryListener {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-peer-discovery-listener[]
    [replicator addPeerDiscoveryStatusListenerWithQueue:nil listener:^(CBLPeerDiscoveryStatus *status) {
        NSString *online = status.online ? @"online" : @"offline";
        NSString *transport = (status.transport == kCBLMultipeerTransportWifi) ? @"wifi" : @"bluetooth";
        NSLog(@"Peer Discovery Status - Peer ID: %@, Transport: %@, Status: %@",
              status.peerID, transport, online);
    }];
    // end::multipeer-peer-discovery-listener[]
}

- (void)peerReplicatorStatus {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-replicator-status-listener[]
    NSArray<NSString *> *activities = @[ @"stopped", @"offline", @"connecting", @"idle", @"busy" ];
    [replicator addPeerReplicatorStatusListenerWithQueue:nil listener:^(CBLPeerReplicatorStatus *replStatus) {
        NSString *direction = replStatus.outgoing ? @"outgoing" : @"incoming";
        NSString *activity = activities[replStatus.status.activity];
        NSString *transport = (replStatus.transport == kCBLMultipeerTransportWifi) ? @"wifi" : @"bluetooth";
        NSString *error = replStatus.status.error ? replStatus.status.error.localizedDescription : @"none";
        NSLog(@"Peer Replicator Status - "
              "Peer ID: %@, Transport: %@, Direction: %@, Activity: %@, Error: %@",
              replStatus.peerID, transport, direction, activity, error);
    }];
    // end::multipeer-replicator-status-listener[]
}

- (void)peerDocumentReplication {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-document-replication-listener[]
    [replicator addPeerDocumentReplicationListenerWithQueue:nil listener:^(CBLPeerDocumentReplication *docRepl) {
        NSString *direction = docRepl.isPush ? @"Push" : @"Pull";
        NSString *transport = (docRepl.transport == kCBLMultipeerTransportWifi) ? @"wifi" : @"bluetooth";
        NSLog(@"Peer Document Replication - Peer ID: %@, Transport: %@, Direction: %@",
              docRepl.peerID, transport, direction);
        for (CBLReplicatedDocument *doc in docRepl.documents) {
            NSString *error = doc.error ? doc.error.localizedDescription : @"none";
            NSString *collection = [NSString stringWithFormat:@"%@.%@", doc.scope, doc.collection];
            NSLog(@" Collection: %@ Document ID: %@, Flags: %lu, Error: %@",
                collection, doc.id, (unsigned long)doc.flags, error);
        }
    }];
    // end::multipeer-document-replication-listener[]
}

- (void)peerInfo {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-peer-info[]
    NSArray<NSString *> *activities = @[ @"stopped", @"offline", @"connecting", @"idle", @"busy" ];

    void (^printPeerInfo)(CBLPeerInfo *) = ^(CBLPeerInfo *info) {
        NSLog(@"Peer ID: %@", info.peerID);
        NSLog(@" Status: %@", info.online ? @"online" : @"offline");

        // transports: the set of transports on which this peer was discovered.
        NSMutableArray<NSString *> *transportNames = [NSMutableArray array];
        if ((info.transports & kCBLMultipeerTransportWifi) != 0) {
            [transportNames addObject:@"wifi"];
        }

        if ((info.transports & kCBLMultipeerTransportBluetooth) != 0) {
            [transportNames addObject:@"bluetooth"];
        }

        // replicatorTransport: the transport currently used for replication.
        // The value is kCBLMultipeerTransportWifi or kCBLMultipeerTransportBluetooth,
        // or 0 if replication is not active.
        NSString *replicatorTransport = (info.replicatorTransport == kCBLMultipeerTransportWifi) ? @"wifi"
            : (info.replicatorTransport == kCBLMultipeerTransportBluetooth) ? @"bluetooth"
            : @"none";
        NSLog(@" Replicating on: %@", replicatorTransport);

        NSLog(@" Neighbor Peers:");
        for (CBLPeerID *peerID in info.neighborPeers) {
            NSLog(@"  %@", peerID);
        }

        CBLReplicatorStatus *replStatus = info.replicatorStatus;
        NSString *activity = activities[(NSInteger)replStatus.activity];
        NSString *error = replStatus.error ? replStatus.error.localizedDescription : @"none";
        NSLog(@" Replicator Status: %@, Error: %@", activity, error);
    };

    for (CBLPeerID *peerID in replicator.neighborPeers) {
        CBLPeerInfo *peerInfo = [replicator peerInfoForPeerID: peerID];
        if (peerInfo) {
            printPeerInfo(peerInfo);
        }
    }
    // end::multipeer-peer-info[]
}


- (CBLMultipeerReplicator *)createMultipeerReplicator {
    CBLMultipeerReplicatorConfiguration *config = [self createConfig];
    NSError *error = nil;
    // tag::multipeer-replicator
    CBLMultipeerReplicator *replicator = [[CBLMultipeerReplicator alloc] initWithConfig:config error:&error];
    // end::multipeer-replicator
    return replicator;
}

- (void)startReplicator {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-replicator-start
    [replicator start];
    // end::multipeer-replicator-start
}

- (void)stopReplicator {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-replicator-stop
    [replicator stop];
    // end::multipeer-replicator-stop
}

- (void)peerID {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-peer-id
    CBLPeerID *peerID = replicator.peerID;
    NSLog(@"Peer ID: %@", peerID);
    // end::multipeer-peer-id
}

- (void)neighborPeers {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-neighbor-peers
    NSLog(@"Neighbor Peers:");
    for (CBLPeerID *peerID in replicator.neighborPeers) {
        NSLog(@" %@", peerID);
    }
    // end::multipeer-neighbor-peers
}

@end
