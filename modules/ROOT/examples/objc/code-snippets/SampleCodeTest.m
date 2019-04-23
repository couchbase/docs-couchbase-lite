//
//  SampleCodeTest.m
//  CouchbaseLite
//
//  Copyright (c) 2018 Couchbase, Inc All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface SampleCodeTest : NSObject

@end

@implementation SampleCodeTest

#pragma mark - Database

- (void) dontTestNewDatabase {
    // tag::new-database[]
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"my-database" error:&error];
    if (!database) {
        NSLog(@"Cannot open the database: %@", error);
    }
    // end::new-database[]
}

#if COUCHBASE_ENTERPRISE
- (void) dontTestDatabaseEncryption {
    // tag::database-encryption[]
    CBLDatabaseConfiguration *config = [[CBLDatabaseConfiguration alloc] init];
    config.encryptionKey = [[CBLEncryptionKey alloc] initWithPassword:@"secretpassword"];

    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"my-database" config:config error:&error];
    if (!database) {
        NSLog(@"Cannot open the database: %@", error);
    }
    // end::database-encryption[]
}
#endif

- (void) dontTestLogging {
    // tag::logging[]
    [CBLDatabase setLogLevel: kCBLLogLevelVerbose domain: kCBLLogDomainReplicator];
    [CBLDatabase setLogLevel: kCBLLogLevelVerbose domain: kCBLLogDomainQuery];
    // end::logging[]
}

- (void) dontTestLoadingPrebuilt {
    // tag::prebuilt-database[]
    // Note: Getting the path to a database is platform-specific.
    // For iOS you need to get the path from the main bundle.
    if (![CBLDatabase databaseExists:@"travel-sample" inDirectory:nil]) {
        NSError*error;
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"travel-sample" ofType:@"cblite2"];
        if (![CBLDatabase copyFromPath:path toDatabase:@"travel-sample" withConfig:nil error:&error]) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Could not load pre-built database: %@", error];
        }
    }
    // end::prebuilt-database[]
}

#pragma mark - Document

- (void) dontTestInitializer {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::initializer[]
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] init];
    [newTask setString:@"task" forKey:@"task"];
    [newTask setString:@"todo" forKey:@"owner"];
    [newTask setString:@"task" forKey:@"createdAt"];
    [database saveDocument:newTask error:&error];
    // end::initializer[]
}

- (void) dontTestMutability {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::update-document[]
    CBLDocument *document = [database documentWithID:@"xyz"];
    CBLMutableDocument *mutableDocument = [document toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];
    [database saveDocument:mutableDocument error:&error];
    // end::update-document[]
}

- (void) dontTestTypedAcessors {
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] init];
    
    // tag::date-getter[]
    [newTask setValue:[NSDate date] forKey:@"createdAt"];
    NSDate *date = [newTask dateForKey:@"createdAt"];
    // end::date-getter[]
    
    NSLog(@"Date: %@", date);
}

- (void) dontTestBatchOperations {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::batch[]
    [database inBatch:&error usingBlock:^{
        for (int i = 0; i < 10; i++) {
            CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
            [doc setValue:@"user" forKey:@"type"];
            [doc setValue:[NSString stringWithFormat:@"user %d", i] forKey:@"name"];
            [doc setBoolean:NO forKey:@"admin"];
            [database saveDocument:doc error:nil];
        }
    }];
    // end::batch[]
}

- (void) dontTestDocumentExpiration {
    NSError* error;
    CBLDatabase *database = self.db;
    
    // tag::document-expiration[]
    // Purge the document one day from now
    NSDate* ttl = [[NSCalendar currentCalendar] dateByAddingUnit: NSCalendarUnitDay
                                                           value: 1
                                                          toDate: [NSDate date]
                                                         options: 0];
    [database setDocumentExpirationWithID:@"doc123" expiration:ttl error:&error];

    // Reset expiration
    [database setDocumentExpirationWithID:@"doc1" expiration:nil error: &error];
    
    // Query documents that will be expired in less than five minutes
    NSTimeInterval fiveMintsFromNow = [[NSDate dateWithTimeIntervalSinceNow:60 * 5] timeIntervalSince1970];
    CBLQuery* query = [CBLQueryBuilder select: @[[CBLQuerySelectResult expression: [CBLQueryMeta id]]]
                                         from: [CBLQueryDataSource database: database]
                                        where: [[CBLQueryMeta expiration]
                                                lessThan: [CBLQueryExpression double: fiveMintsFromNow]]];
    // end::document-expiration[]
    NSLog(@"%@", query);
}

- (void) dontTestBlob {
#if TARGET_OS_IPHONE
    NSError *error;
    CBLDatabase *database = self.db;
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] initWithID:@"task1"];
    
    // tag::blob[]
    UIImage *appleImage = [UIImage imageNamed:@"avatar.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(appleImage, 1.0);
    
    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:imageData];
    [newTask setBlob:blob forKey:@"avatar"];
    [database saveDocument:newTask error:&error];
    
    CBLDocument *savedTask = [database documentWithID: @"task1"];
    CBLBlob *taskBlob = [savedTask blobForKey:@"avatar"];
    UIImage *taskImage = [UIImage imageWithData:taskBlob.content];
    // end::blob[]
    
    NSLog(@"%@", taskImage);
#endif
}

- (void) dontTest1xAttachment {
    CBLMutableDocument *document = [[CBLMutableDocument alloc] initWithID:@"task1"];
    
    // tag::1x-attachment[]
    CBLDictionary *attachments = [document dictionaryForKey:@"_attachments"];
    CBLBlob *avatar = [attachments blobForKey:@"avatar"];
    NSData *content = [avatar content];
    // end::1x-attachment[]
    
    NSLog(@"%@", content);
}

#pragma mark - Query

- (void) dontTestIndexing {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::query-index[]
    CBLValueIndexItem *type = [CBLValueIndexItem property:@"type"];
    CBLValueIndexItem *name = [CBLValueIndexItem property:@"name"];
    CBLIndex* index = [CBLIndexBuilder valueIndexWithItems:@[type, name]];
    [database createIndex:index withName:@"TypeNameIndex" error:&error];
    // end::query-index[]
}

- (void) dontTestSelect {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::query-select-meta[]
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuery *query = [CBLQueryBuilder select:@[name]
                                         from:[CBLQueryDataSource database:database]
                                        where:[[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression value:@"user"]] andExpression:
                                               [[CBLQueryExpression property:@"admin"] equalTo:[CBLQueryExpression boolean:NO]]]];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"user name :: %@", [result stringAtIndex:0]);
    }
    // end::query-select-meta[]
}

- (void) dontTestSelectAll {
    CBLDatabase *database = self.db;
    
    // tag::query-select-all[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:database]];
    // end::query-select-all[]
    
    // tag::live-query[]
    id<CBLListenerToken> token = [query addChangeListener:^(CBLQueryChange * _Nonnull change) {
        for (CBLQueryResultSet *result in [change results])
        {
            NSLog(@"%@", result);
            /* Update UI */
        }
    }];
    // end::live-query[]
    
    // tag::stop-live-query[]
    [query removeChangeListenerWithToken:token];
    // end::stop-live-query[]
    
    NSLog(@"%@", query);
}

- (void) dontTestWhere {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::query-where[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:database]
                                        where:[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:[CBLQueryLimit limit:[CBLQueryExpression integer:10]]];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        CBLDictionary *dict = [result valueForKey:@"travel-sample"];
        NSLog(@"document name :: %@", [dict stringForKey:@"name"]);
    }
    // end::query-where[]
    
    NSLog(@"%@", query);
}

- (void) dontTestCollectionOperatorContains {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::query-collection-operator-contains[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuerySelectResult *likes = [CBLQuerySelectResult property:@"public_likes"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]];
    CBLQueryExpression *contains = [CBLQueryArrayFunction contains:[CBLQueryExpression property:@"public_likes"]
                                                             value:[CBLQueryExpression string:@"Armani Langworth"]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, name, likes]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: contains]];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"public_likes :: %@", [[result arrayForKey:@"public_likes"] toArray]);
    }
    // end::query-collection-operator-contains[]
}

- (void) dontTestCollectionOperatorIn {
    CBLDatabase *database = self.db;
    
    // tag::query-collection-operator-in[]
    NSArray *values = @[[CBLQueryExpression property:@"first"],
                       [CBLQueryExpression property:@"last"],
                       [CBLQueryExpression property:@"username"]];
                       
    [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource database:database]
                      where:[[CBLQueryExpression string:@"Armani"] in:values]];
    // end::query-collection-operator-in[]
}

- (void) dontTestLikeOperator {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::query-like-operator[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryExpression property:@"name"] like:[CBLQueryExpression string:@"Royal engineers museum"]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: like]];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"name property :: %@", [result stringForKey:@"name"]);
    }
    // end::query-like-operator[]
}

- (void) dontTestWildCardMatch {
    CBLDatabase *database = self.db;
    
    // tag::query-like-operator-wildcard-match[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryExpression property:@"name"] like:[CBLQueryExpression string:@"eng%e%"]];
    
    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: like]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-like-operator-wildcard-match[]
    
    NSLog(@"%@", query);
}

- (void) dontTestWildCardCharacterMatch {
    CBLDatabase *database = self.db;
    
    // tag::query-like-operator-wildcard-character-match[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryExpression property:@"name"] like:[CBLQueryExpression string:@"eng____r"]];
    
    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: like]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-like-operator-wildcard-character-match[]
    
    NSLog(@"%@", query);
}

- (void) dontTestRegexMatch {
    CBLDatabase *database = self.db;
    
    // tag::query-regex-operator[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *regex = [[CBLQueryExpression property:@"name"] regex:[CBLQueryExpression string:@"\\bEng.*e\\b"]];
    
    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, name]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: regex]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-regex-operator[]
    
    NSLog(@"%@", query);
}

- (void) dontTestJoin {
    CBLDatabase *database = self.db;
    
    // tag::query-join[]
    CBLQuerySelectResult *name = [CBLQuerySelectResult expression:[CBLQueryExpression property:@"name" from:@"airline"]];
    CBLQuerySelectResult *callsign = [CBLQuerySelectResult expression:[CBLQueryExpression property:@"callsign" from:@"airline"]];
    CBLQuerySelectResult *dest = [CBLQuerySelectResult expression:[CBLQueryExpression property:@"destinationairport" from:@"route"]];
    CBLQuerySelectResult *stops = [CBLQuerySelectResult expression:[CBLQueryExpression property:@"stops" from:@"route"]];
    CBLQuerySelectResult *airline = [CBLQuerySelectResult expression:[CBLQueryExpression property:@"airline" from:@"route"]];
    
    CBLQueryJoin *join = [CBLQueryJoin join:[CBLQueryDataSource database:database as:@"route"]
                                         on:[[CBLQueryMeta idFrom:@"airline"] equalTo:[CBLQueryExpression property:@"airlineid" from:@"route"]]];
    
    CBLQueryExpression *typeRoute = [[CBLQueryExpression property:@"type" from:@"route"] equalTo:[CBLQueryExpression string:@"route"]];
    CBLQueryExpression *typeAirline = [[CBLQueryExpression property:@"type" from:@"airline"] equalTo:[CBLQueryExpression string:@"airline"]];
    CBLQueryExpression *sourceRIX = [[CBLQueryExpression property:@"sourceairport" from:@"route"] equalTo:[CBLQueryExpression string:@"RIX"]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[name, callsign, dest, stops, airline]
                                         from:[CBLQueryDataSource database:database as:@"airline"]
                                         join:@[join]
                                        where:[[typeRoute andExpression:typeAirline] andExpression:sourceRIX]];
    // end::query-join[]
    
    NSLog(@"%@", query);
}

- (void) dontTestGroupBy {
    CBLDatabase *database = self.db;
    
    // tag::query-groupby[]
    CBLQuerySelectResult *count = [CBLQuerySelectResult expression:[CBLQueryFunction count:[CBLQueryExpression all]]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *tz = [CBLQuerySelectResult property:@"tz"];
    
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"airport"]];
    CBLQueryExpression *geoAlt = [[CBLQueryExpression property:@"geo.alt"] greaterThanOrEqualTo:[CBLQueryExpression integer:300]];
    
    CBLQuery *query = [CBLQueryBuilder select:@[count, country, tz]
                                         from:[CBLQueryDataSource database:database]
                                        where:[type andExpression: geoAlt]
                                      groupBy:@[[CBLQueryExpression property:@"country"],
                                                [CBLQueryExpression property:@"tz"]]];
    // end::query-groupby[]
    
    NSLog(@"%@", query);
}

- (void) dontTestOrderBy {
    CBLDatabase *database = self.db;
    
    // tag::query-orderby[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *title = [CBLQuerySelectResult property:@"title"];
    
    CBLQuery *query = [CBLQueryBuilder select:@[id, title]
                                         from:[CBLQueryDataSource database:database]
                                        where:[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]]
                                      orderBy:@[[[CBLQueryOrdering property:@"title"] descending]]];
    // end::query-orderby[]
    
    NSLog(@"%@", query);
}

- (void) dontTestCreateFullTextIndex {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::fts-index[]
    // Insert documents
    NSArray *tasks = @[@"buy groceries", @"play chess", @"book travels", @"buy museum tickets"];
    for (NSString *task in tasks) {
        CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
        [doc setString:@"task" forKey:@"type"];
        [doc setString:task forKey:@"name"];
        [database saveDocument:doc error:&error];
    }
    
    // Create index
    CBLFullTextIndex *index = [CBLIndexBuilder fullTextIndexWithItems:@[[CBLFullTextIndexItem property:@"name"]]];
    index.ignoreAccents = NO;
    [database createIndex:index withName:@"nameFTSIndex" error:&error];
    // end::fts-index[]
}

- (void) dontTestFullTextSearch {
    NSError *error;
    CBLDatabase *database = self.db;
    
    // tag::fts-query[]
    CBLQueryExpression *where = [[CBLQueryFullTextExpression indexWithName:@"nameFTSIndex"] match:@"'buy'"];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
                                         from:[CBLQueryDataSource database:database]
                                        where:where];
    
    NSEnumerator* rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"document id %@", [result stringAtIndex:0]);
    }
    // end::fts-query[]
}

#pragma mark - Replication

/* The `tag::replication[]` example is inlined in objc.adoc */

- (void) dontTestEnableReplicatorLogging {
    // tag::replication-logging[]
    // Replicator
    [CBLDatabase setLogLevel:kCBLLogLevelVerbose domain:kCBLLogDomainReplicator];
    // Network
    [CBLDatabase setLogLevel:kCBLLogLevelVerbose domain:kCBLLogDomainNetwork];
    // end::replication-logging[]
}

- (void) dontTestReplicationBasicAuthentication {
    CBLDatabase *database = self.db;
    // tag::basic-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];
    
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::basic-authentication[]
}

- (void) dontTestReplicationSessionAuthentication {
    CBLDatabase *database = self.db;
    // tag::session-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    config.authenticator = [[CBLSessionAuthenticator alloc] initWithSessionID:@"904ac010862f37c8dd99015a33ab5a3565fd8447"];
    
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::session-authentication[]
}

- (void) dontTestReplicatorStatus {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    
    // tag::replication-status[]
    [replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
        }
    }];
    // end::replication-status[]
}

- (void) dontTestCustomReplicationHeader {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *endpoint = [[CBLURLEndpoint alloc] initWithURL:url];
    
    // tag::replication-custom-header[]
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:endpoint];
    config.headers = @{@"CustomHeaderName" : @"Value"};
    // end::replication-custom-header[]
}

- (void) dontTestHandlingReplicationError {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    
    // tag::replication-error-handling[]
    [replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code: %ld", change.status.error.code);
        }
    }];
    // end::replication-error-handling[]
}

- (void) dontTestReplicationResetCheckpoint {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::replication-reset-checkpoint[]
    [replicator resetCheckpoint];
    [replicator start];
    // end::replication-reset-checkpoint[]
}

#ifdef COUCHBASE_ENTERPRISE
- (void) dontTestDatabaseReplica {
    CBLDatabase *database = self.db;
    CBLDatabase *database2 = self.db;
    
    /* EE feature: code below might throw a compilation error
     if it's compiled against CBL Swift Community. */
    // tag::database-replica[]
    CBLDatabaseEndpoint *targetDatabase = [[CBLDatabaseEndpoint alloc] initWithDatabase:database2];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:targetDatabase];
    config.replicatorType = kCBLReplicatorTypePush;
    
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::database-replica[]
}
#endif

- (void) dontTestCertificatePinning {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    
    // tag::certificate-pinning[]
    NSData *data = [self dataFromResource: @"cert" ofType: @"cer"];
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database
                                                                                       target:target];
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(cert);
    // end::certificate-pinning[]
    
    NSLog(@"%@", config);
}

- (void) dontTestGettingStarted {
    // tag::getting-started[]
    // Get the database (and create it if it doesn’t exist).
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];
    
    // Create a new document (i.e. a record) in the database.
    CBLMutableDocument *mutableDoc = [[CBLMutableDocument alloc] init];
    [mutableDoc setFloat:2.0 forKey:@"version"];
    [mutableDoc setString:@"SDK" forKey:@"type"];
    
    // Save it to the database.
    [database saveDocument:mutableDoc error:&error];
    
    // Update a document.
    CBLMutableDocument *mutableDoc2 = [[database documentWithID:mutableDoc.id] toMutable];
    [mutableDoc2 setString:@"Swift" forKey:@"language"];
    [database saveDocument:mutableDoc2 error:&error];
    
    CBLDocument *document = [database documentWithID:mutableDoc2.id];
    // Log the document ID (generated by the database)
    // and properties
    NSLog(@"Document ID :: %@", document.id);
    NSLog(@"Learning %@", [document stringForKey:@"language"]);
    
    // Create a query to fetch documents of type SDK.
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"SDK"]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                          from:[CBLQueryDataSource database:database]
                                         where:type];
    
    // Run the query
    CBLQueryResultSet *result = [query execute:&error];
    NSLog(@"Number of rows :: %lu", (unsigned long)[[result allResults] count]);
    
    // Create replicators to push and pull changes to and from the cloud.
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/example_sg_db"];
    CBLURLEndpoint *targetEndpoint = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:targetEndpoint];
    replConfig.replicatorType = kCBLReplicatorTypePushAndPull;
    
    // Add authentication.
    replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];
    
    // Create replicator.
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    
    // Listen to replicator change events.
    [replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code: %ld", change.status.error.code);
        }
    }];
    
    // Start replication
    [replicator start];
    // end::getting-started[]
}

@end


// Singleton Pattern
// <doc>
@interface DataManager : NSObject

@property (nonatomic, readonly) CBLDatabase *database;

+ (id)sharedInstance;

@end

@implementation DataManager

@synthesize database=_database;

+ (id)sharedInstance {
    static DataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        NSError *error;
        _database = [[CBLDatabase alloc] initWithName:@"dbname" error:&error];
        if (!_database) {
            NSLog(@"Cannot open the database: %@", error);
            return nil;
        }
    }
    return self;
}

@end
// <doc>

// Peer-to-Peer Sample

/* ----------------------------------------------------------- */
/* ---------------------  ACTIVE SIDE  ----------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
@interface ActivePeer: NSObject <CBLMessageEndpointDelegate>

@end

@interface ActivePeerConnection: NSObject <CBLMessageEndpointConnection>
- (void)disconnect;
- (void)receive:(NSData*)data;
@end

@implementation ActivePeer

- (instancetype) init {
    self = [super init];
    if (self) {
        // tag::message-endpoint[]
        CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"dbname" error:nil];
        
        // The delegate must implement the `CBLMessageEndpointDelegate` protocol.
        NSString* id = @"";
        CBLMessageEndpoint *endpoint =
        [[CBLMessageEndpoint alloc] initWithUID:@"UID:123"
                                         target:id
                                   protocolType:kCBLProtocolTypeMessageStream
                                       delegate:self];
        // end::message-endpoint[]
        
        // tag::message-endpoint-replicator[]
        CBLReplicatorConfiguration *config =
        [[CBLReplicatorConfiguration alloc] initWithDatabase:database target: endpoint];
        
        // Create the replicator object.
        CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig: config];
        [replicator start];
        // end::message-endpoint-replicator[]
    }
    return self;
}

// tag::create-connection[]
- (id<CBLMessageEndpointConnection>)createConnectionForEndpoint:(CBLMessageEndpoint *)endpoint {
    return [[ActivePeerConnection alloc] init];
}
// end::create-connection[]

@end


@implementation ActivePeerConnection {
    id <CBLReplicatorConnection> _replicatorConnection;
}

- (void)disconnect {
    // tag::active-replicator-close[]
    [_replicatorConnection close:nil];
    // end::active-replicator-close[]
}

// tag::active-peer-open[]
/* implementation of CBLMessageEndpointConnection */
- (void)open:(nonnull id<CBLReplicatorConnection>)connection completion:(nonnull void (^)(BOOL, CBLMessagingError * _Nullable))completion {
    _replicatorConnection = connection;
    completion(YES, nil);
}
// end::active-peer-open[]

// tag::active-peer-send[]
/* implementation of CBLMessageEndpointConnection */
- (void)send:(nonnull CBLMessage *)message completion:(nonnull void (^)(BOOL, CBLMessagingError * _Nullable))completion {
    NSData *data = [message toData];
    NSLog(@"%@", data);
    /* send the data to the other peer */
    /* ... */
    /* call the completion handler once the message is sent */
    completion(YES, nil);
}
// end::active-peer-send[]

- (void)receive:(NSData*)data {
    // tag::active-peer-receive[]
    CBLMessage *message = [CBLMessage fromData:data];
    [_replicatorConnection receive:message];
    // end::active-peer-receive[]
}

// tag::active-peer-close[]
/* implementation of CBLMessageEndpointConnection */
- (void)close:(nullable NSError *)error completion:(nonnull void (^)(void))completion {
    /* disconnect with communications framework */
    /* ... */
    /* call completion handler */
    completion();
}
// end::active-peer-close[]

@end

/* ----------------------------------------------------------- */
/* ---------------------  PASSIVE SIDE  ---------------------- */
/* ---------------  stubs for documentation  ----------------- */
/* ----------------------------------------------------------- */
@interface PassivePeerConnection: NSObject <CBLMessageEndpointConnection>
- (void)startListener;
- (void)stopListener;
- (void)disconnect;
- (void)receive:(NSData*)data;
@end

@implementation PassivePeerConnection {
    CBLMessageEndpointListener *_messageEndpointListener;
    id <CBLReplicatorConnection> _replicatorConnection;
}

- (void)startListener {
    // tag::listener[]
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:nil];
    
    CBLMessageEndpointListenerConfiguration *config =
    [[CBLMessageEndpointListenerConfiguration alloc] initWithDatabase:database
                                                         protocolType:kCBLProtocolTypeMessageStream];
    _messageEndpointListener = [[CBLMessageEndpointListener alloc] initWithConfig:config];
    // end::listener[]
}

- (void)stopListener {
    // tag::passive-stop-listener[]
    [_messageEndpointListener closeAll];
    // end::passive-stop-listener[]
}

- (void)acceptConnection() {
    // tag::advertizer-accept[]
    PassivePeerConnection *connection = [[PassivePeerConnection alloc] init]; /* implements CBLMessageEndpointConnection */
    [_messageEndpointListener accept: connection];
    // end::advertizer-accept[]
}

- (void)disconnect {
    // tag::passive-replicator-close[]
    [_replicatorConnection close:nil];
    // end::passive-replicator-close[]
}

// tag::passive-peer-open[]
/* implementation of CBLMessageEndpointConnection */
- (void)open:(nonnull id<CBLReplicatorConnection>)connection completion:(nonnull void (^)(BOOL, CBLMessagingError * _Nullable))completion {
    _replicatorConnection = connection;
    completion(YES, nil);
}
// end::passive-peer-open[]

// tag::passive-peer-send[]
/* implementation of CBLMessageEndpointConnection */
- (void)send:(nonnull CBLMessage *)message completion:(nonnull void (^)(BOOL, CBLMessagingError * _Nullable))completion {
    NSData *data = [message toData];
    NSLog(@"%@", data);
    /* send the data to the other peer */
    /* ... */
    /* call the completion handler once the message is sent */
    completion(YES, nil);
}
// end::passive-peer-send[]

- (void)receive:(NSData*)data {
    // tag::passive-peer-receive[]
    CBLMessage *message = [CBLMessage fromData:data];
    [_replicatorConnection receive:message];
    // end::passive-peer-receive[]
}

// tag::passive-peer-close[]
/* implementation of CBLMessageEndpointConnection */
- (void)close:(nullable NSError *)error completion:(nonnull void (^)(void))completion {
    /* disconnect with communications framework */
    /* ... */
    /* call completion handler */
    completion();
}
// end::passive-peer-close[]
@end

