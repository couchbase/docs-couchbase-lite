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

- (CBLTLSIdentity *)peerIdentity {
    // tag::multipeer-tlsidentity
    // Note: This example is simplified for demonstration and does not include error handling.
    NSString *persistentLabel = @"com.myapp.identity";
    
    // Retrieve the TLS identity from the keychain using the persistent label.
    NSError *error = nil;
    CBLTLSIdentity *identity = [CBLTLSIdentity identityWithLabel:persistentLabel error:&error];
    
    // If the identity doesn't exist or expired, create a new one.
    if (!identity || [identity.expiration compare:[NSDate date]] == NSOrderedAscending) {
        // Create an issuer identity from the private key and certificate data in DER format.
        NSData *privateKey = [self getIssuerPrivateKeyData];
        NSData *cert = [self getIssuerCertificateData];
        CBLTLSIdentity *issuer = [CBLTLSIdentity createIdentityWithPrivateKey:privateKey
                                                                  certificate:cert
                                                                        error:&error];
        
        // Create a new identity signed with the issuer.
        NSDictionary *attrs = @{ kCBLCertAttrCommonName: @"MyApp" };
        NSDate *expiration = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitYear
                                                                     value:2
                                                                    toDate:[NSDate date]
                                                                   options:0];
        
        identity = [CBLTLSIdentity createIdentityForKeyUsages:kCBLKeyUsagesClientAuth|kCBLKeyUsagesServerAuth
                                                   attributes:attrs
                                                   expiration:expiration
                                                       issuer:issuer
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
    NSData *privateKey = [self getIssuerPrivateKeyData];
    NSData *cert = [self getIssuerCertificateData];
    NSError *error = nil;
    CBLTLSIdentity *issuer = [CBLTLSIdentity createIdentityWithPrivateKey:privateKey
                                                              certificate:cert
                                                                    error:&error];
    // tag::multipeer-authenticator-rootcerts
    id<CBLMultipeerAuthenticator> authenticator =
    [[CBLMultipeerCertificateAuthenticator alloc] initWithRootCerts:issuer.certs];
    // end::multipeer-authenticator-rootcerts
    return authenticator;
}

- (CBLMultipeerReplicatorConfiguration *)createConfig {
    CBLTLSIdentity *identity = [self peerIdentity];
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

- (void)statusListener {
    NSError *error = nil;
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-status-listener
    [replicator addStatusListenerWithQueue:nil listener:^(CBLMultipeerReplicatorStatus *status) {
        NSString *state = status.active ? @"active" : @"inactive";
        NSString *err = status.error ? status.error.localizedDescription : @"none";
        NSLog(@"Multipeer Replicator Status: %@, Error: %@", state, err);
    }];
    // end::multipeer-status-listener
}

- (void)peerDiscoveryListener {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-peer-discovery-listener
    [replicator addPeerDiscoveryStatusListenerWithQueue:nil listener:^(CBLPeerDiscoveryStatus *status) {
        NSString *online = status.online ? @"online" : @"offline";
        NSLog(@"Peer Discovery Status - Peer ID: %@, Status: %@", status.peerID, online);
    }];
    // end::multipeer-peer-discovery-listener
}

- (void)peerReplicatorStatus {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-replicator-status-listener
    NSArray<NSString *> *activities = @[ @"stopped", @"offline", @"connecting", @"idle", @"busy" ];
    [replicator addPeerReplicatorStatusListenerWithQueue:nil listener:^(CBLPeerReplicatorStatus *replStatus) {
        NSString *direction = replStatus.outgoing ? @"outgoing" : @"incoming";
        NSString *activity = activities[replStatus.status.activity];
        NSString *error = replStatus.status.error ? replStatus.status.error.localizedDescription : @"none";
        NSLog(@"Peer Replicator Status - "
              "Peer ID: %@, Direction: %@, Activity: %@, Error: %@",
              replStatus.peerID, direction, activity, error);
    }];
    // end::multipeer-replicator-status-listener
}

- (void)peerDocumentReplication {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-document-replication-listener
    [replicator addPeerDocumentReplicationListenerWithQueue:nil listener:^(CBLPeerDocumentReplication *docRepl) {
        NSString *direction = docRepl.isPush ? @"Push" : @"Pull";
        NSLog(@"Peer Document Replication - Peer ID: %@, Direction: %@", docRepl.peerID, direction);
        for (CBLReplicatedDocument *doc in docRepl.documents) {
            NSString *error = doc.error ? doc.error.localizedDescription : @"none";
            NSString *collection = [NSString stringWithFormat:@"%@.%@", doc.scope, doc.collection];
            NSLog(@" Collection: %@ Document ID: %@, Flags: %lu, Error: %@",
                  collection, doc.id, (unsigned long)doc.flags, error);
        }
    }];
    // end::multipeer-document-replication-listener
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
    NSArray<CBLPeerID *> *neighborPeers = replicator.neighborPeers;
    NSLog(@"Neighbor Peers:");
    for (CBLPeerID *peerID in neighborPeers) {
        NSLog(@" %@", peerID);
    }
    // end::multipeer-neighbor-peers
}

- (void)peerInfo {
    CBLMultipeerReplicator *replicator = [self createMultipeerReplicator];
    // tag::multipeer-peer-info
    NSArray<NSString *> *activities = @[ @"stopped", @"offline", @"connecting", @"idle", @"busy" ];
    
    void (^printPeerInfo)(CBLPeerInfo *) = ^(CBLPeerInfo *info) {
        NSLog(@"Peer ID: %@", info.peerID);
        NSLog(@" Status: %@", info.online ? @"online" : @"offline");
        NSArray<CBLPeerID *> *neighborPeers = replicator.neighborPeers;
        NSLog(@" Neighbor Peers:");
        for (CBLPeerID *peerID in neighborPeers) {
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
    // end::multipeer-peer-info
}

@end
