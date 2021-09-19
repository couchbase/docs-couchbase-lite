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
#import <CoreML/CoreML.h>

// tag::predictive-model[]
// `myMLModel` is a fake implementation
// this would be the implementation of the ml model you have chosen
@interface myMLModel : NSObject

+ (NSDictionary*)predictImage: (NSData*)data;

@end

@interface ImageClassifierModel : NSObject <CBLPredictiveModel>

- (nullable CBLDictionary*) predict: (CBLDictionary*)input;

@end

@implementation ImageClassifierModel

- (nullable CBLDictionary*) predict: (CBLDictionary*)input; {
    CBLBlob* blob = [input blobForKey:@"photo"];

    NSData* imageData = blob.content;
    // `myMLModel` is a fake implementation
    // this would be the implementation of the ml model you have chosen
    NSDictionary* modelOutput = [myMLModel predictImage:imageData];

    CBLMutableDictionary* output = [[CBLMutableDictionary alloc] initWithData: modelOutput];
    return output; // <1>
}

@end
// end::predictive-model[]

// to avoid link error
@implementation myMLModel
+ (NSDictionary*)predictImage: (NSData*)data { return [NSDictionary dictionary]; }
@end

// tag::custom-logging[]
@interface LogTestLogger : NSObject<CBLLogger>

// set the log level
@property (nonatomic) CBLLogLevel level;

@end

@implementation LogTestLogger

@synthesize level=_level;

- (void) logWithLevel: (CBLLogLevel)level domain: (CBLLogDomain)domain message: (NSString*)message {
    // handle the message, for example piping it to
    // a third party framework
}

@end

// end::custom-logging[]

// tag::local-win-conflict-resolver[]
@interface LocalWinConflictResolver: NSObject<CBLConflictResolver>
@end

@implementation LocalWinConflictResolver
- (CBLDocument*) resolve: (CBLConflict*)conflict {
    return conflict.localDocument;
}

@end
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
@interface RemoteWinConflictResolver: NSObject<CBLConflictResolver>
@end

@implementation RemoteWinConflictResolver
- (CBLDocument*) resolve: (CBLConflict*)conflict {
    return conflict.remoteDocument;
}

@end
// end::remote-win-conflict-resolver[]


// tag::merge-conflict-resolver[]
@interface MergeConflictResolver: NSObject<CBLConflictResolver>
@end

@implementation MergeConflictResolver
- (CBLDocument*) resolve: (CBLConflict*)conflict {
    NSDictionary *localDict = conflict.localDocument.toDictionary;
    NSDictionary *remoteDict = conflict.remoteDocument.toDictionary;

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:localDict];
    [result addEntriesFromDictionary:remoteDict];

    return [[CBLMutableDocument alloc] initWithID:conflict.documentID
                                             data:result];
}

@end
// end::merge-conflict-resolver[]

@interface SampleCodeTest : NSObject
@property(nonatomic) CBLDatabase* db;
@property(nonatomic) NSArray* _allowlistedUsers;
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

    // tag::close-database[]
    tbd

    // end::close-database[]


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

- (void) dontTestEnableConsoleLogging {
    // tag::console-logging[]
    CBLDatabase.log.console.domains = kCBLLogDomainAll; // <.>
    CBLDatabase.log.console.level = kCBLLogLevelVerbose; // <.>

    // end::console-logging[]

    // tag::console-logging-db[]
    CBLDatabase.log.console.domains = kCBLLogDomainAll;

    // end::console-logging-db[]
}

- (void) dontTestFileLogging {
    // tag::file-logging[]
    NSString* tempFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cbllog"];
    CBLLogFileConfiguration* config = [[CBLLogFileConfiguration alloc] initWithDirectory:tempFolder]; // <.>
    config.maxRotateCount = 2; // <.>
    config.maxSize = 1024; // <.>
    config.usePlainText = YES; // <.>
    [CBLDatabase.log.file setConfig:config];
    [CBLDatabase.log.file setLevel: kCBLLogLevelInfo]; // <.>
    // end::file-logging[]
}

- (void) dontTestEnableCustomLogging {
    // tag::set-custom-logging[]
    [CBLDatabase.log setCustom:[[LogTestLogger alloc] initWithLogLevel: kCBLLogLevelWarning]];

    // end::set-custom-logging[]
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
            [database saveDocument:doc error: &error];
        }
    }];
    // end::batch[]
}

- (void) dontTestChangeListener {
    __weak CBLDatabase *database = self.db;

    // tag::document-listener[]
    [database addDocumentChangeListenerWithID: @"user.john" listener:^(CBLDocumentChange * change) {
        CBLDocument* document = [database documentWithID: change.documentID];
        NSLog(@"Status :: %@)", [document stringForKey: @"verified_account"]);
    }];
    // end::document-listener[]
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
    NSTimeInterval fiveMinutesFromNow = [[NSDate dateWithTimeIntervalSinceNow:60 * 5] timeIntervalSince1970];
    CBLQuery* query = [CBLQueryBuilder select: @[[CBLQuerySelectResult expression: [CBLQueryMeta id]]]
                                         from: [CBLQueryDataSource database: database]
                                        where: [[CBLQueryMeta expiration]
                                                lessThan: [CBLQueryExpression double: fiveMinutesFromNow]]];
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
    NSData *imageData = UIImageJPEGRepresentation(appleImage, 1.0);  // <.>

    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:imageData];  // <.>
    [newTask setBlob:blob forKey:@"avatar"]; // <.>
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

    NSLog(@"%@", query);
}

- (void) dontTestLiveQuery {
    NSError* error;
    CBLDatabase *database = self.db;

    // tag::live-query[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:database]]; // <.>

    // Adds a query change listener.
    // Changes will be posted on the main queue.
    id<CBLListenerToken> token = [query addChangeListener:^(CBLQueryChange * _Nonnull change) // <.>{
        for (CBLQueryResultSet *result in [change results]) {
            NSLog(@"%@", result);
            /* Update UI */
        }
    }]; // <.>

    // end::live-query[]

    // tag::stop-live-query[]
    [query removeChangeListenerWithToken:token]; // <.>
    // end::stop-live-query[]
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

- (void) dontTestQueryDeletedDocuments {
    CBLDatabase* database = self.db;

    // tag::query-deleted-documents[]
    // Query documents that have been deleted
    CBLQuery* query = [CBLQueryBuilder select: @[[CBLQuerySelectResult expression:CBLQueryMeta.id]]
                                         from: [CBLQueryDataSource database:database]
                                        where: CBLQueryMeta.isDeleted];
    // end::query-deleted-documents[]
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
    CBLQueryExpression *like = [[CBLQueryFunction lower:[CBLQueryExpression property:@"name"]] like:[CBLQueryExpression string:@"royal engineers museum"]];

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
    CBLQueryExpression *like = [[CBLQueryFunction lower:[CBLQueryExpression property:@"name"]] like:[CBLQueryExpression string:@"eng%e%"]];

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


- (void) dontTestExplainAll {
    CBLDatabase *database = self.db;
    NSError *error;
    // tag::query-explain-all[]
    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
            from:[CBLQueryDataSource database:database]
            where:[[CBLQueryExpression property:@"type"]
                   equalTo:[CBLQueryExpression string:@"university"]]
//            groupBy:@[[CBLQueryExpression property:@"country"]] // <.>
                          orderBy:@[[[CBLQueryOrdering property:@"title"] descending]] // <.>
       ];

    NSLog(@"%@", [query explain:&error]); // <.>

      // end::query-explain-all[]
}
- (void) dontTestExplainLike {
    CBLDatabase *database = self.db;
    NSError *error;
    // tag::query-explain-like[]
    CBLQueryExpression *type =
        [[CBLQueryExpression property:@"type"]
            like:[CBLQueryExpression string:@"%hotel%"]];
    CBLQueryExpression *name =
        [[CBLQueryExpression property:@"name"]
            like:[CBLQueryExpression string:@"%royal%"]];

    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
            from:[CBLQueryDataSource database:database]
            where:[type andExpression: name]
        ];
      NSLog(@"%@", [query explain:&error]); // <.>

      // end::query-explain-like[]

}
- (void) dontTestExplainNoPfx {
    CBLDatabase *database = self.db;
    NSError *error;

    // tag::query-explain-nopfx[]
    CBLQueryExpression *type =
        [[CBLQueryExpression property:@"type"]
            like:[CBLQueryExpression string:@"hotel%"]]; // <.>
    CBLQueryExpression *name =
        [[CBLQueryExpression property:@"name"]
            like:[CBLQueryExpression string:@"%royal%"]];

    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
            from:[CBLQueryDataSource database:database]
            where:[type andExpression: name]
        ];

    NSLog(@"%@", [query explain:&error]);

    // end::query-explain-nopfx[]
}

- (void) dontTestExplainFunction {
    CBLDatabase *database = self.db;
    NSError *error;

    // tag::query-explain-function[]
    CBLQueryExpression *type =
        [[CBLQueryFunction lower:[CBLQueryExpression property:@"type"]]
            equalTo:[CBLQueryExpression string:@"hotel"]]; // <.>
    CBLQueryExpression *name =
        [[CBLQueryExpression property:@"name"]
            like:[CBLQueryExpression string:@"%royal%"]];

    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
                from:[CBLQueryDataSource database:database]
                where:[type andExpression: name]];

    NSLog(@"%@", [query explain:&error]);

    // end::query-explain-function[]
}

- (void) dontTestExplainNoFunction {
    CBLDatabase *database = self.db;
    NSError *error;
      // tag::query-explain-nofunction[]
    CBLQueryExpression *type =
        [[CBLQueryExpression property:@"type"]
            equalTo:[CBLQueryExpression string:@"hotel"]]; // <.>
    CBLQueryExpression *name =
        [[CBLQueryExpression property:@"name"]
            like:[CBLQueryExpression string:@"%royal%"]];

    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
            from:[CBLQueryDataSource database:database]
            where:[type andExpression: name]
        ];

    NSLog(@"%@", [query explain:&error]);

      // end::query-explain-nofunction[]

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
    CBLQueryExpression *where =
      [[CBLQueryFullTextExpression indexWithName:@"nameFTSIndex"] match:@"'buy'"];
    CBLQuery *query =
      [CBLQueryBuilder
        select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
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


//  BEGIN PendingDocuments IB -- 11/Feb/21 --
//    public void testReplicationPendingDocs() throws URISyntaxException {
      // tag::replication-pendingdocuments[]

      CBLDatabase *database = self.db;
      NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
      CBLURLEndpoint *target =
        [[CBLURLEndpoint alloc] initWithURL: url];
      CBLReplicatorConfiguration *config =
        [[CBLReplicatorConfiguration alloc]
          initWithDatabase:database
          target:target];

      config.replicatorType = kCBLReplicatorTypePush;

      // tag::replication-push-pendingdocumentids[]
      CBLReplicator *replicator =
        [[CBLReplicator alloc] initWithConfig:config];

      // Get list of pending doc IDs
      NSError* err = nil;
      NSSet *mydocids =
        [NSSet setWithSet:[replicator pendingDocumentIDs:&err]]; // <.>

      // end::replication-push-pendingdocumentids[]

      if ([mydocids count] > 0) {

        NSLog(@"There are %lu documents pending", (unsigned long)[mydocids count]);

        [replicator addChangeListener:^(CBLReplicatorChange *change) {

          NSLog(@"Replicator activity level is %u", change.status.activity);
          // iterate and report-on the pending doc IDs  in 'mydocids'
          for (thisid in mydocids) {

            // tag::replication-push-isdocumentpending[]
            NSError* err = nil;
            if (![replicator isDocumentPending: thisid error: &err]) { // <.>
              NSLog(@"Doc ID %@ now pushed", thisid);
            }
            // end::replication-push-isdocumentpending[]
          }

        }];
        [replicator start];

      };

      // end::replication-pendingdocuments[]
    }
//  END PendingDocuments IB -- 11/Feb/21 --



- (void) dontTestReplicatorDocumentEvent {
    CBLDatabase *database = self.db;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::add-document-replication-listener[]
    id token = [replicator addDocumentReplicationListener:^(CBLDocumentReplication * _Nonnull replication) {
        NSLog(@"Replication type :: %@", replication.isPush ? @"Push" : @"Pull");
        for (CBLReplicatedDocument* document in replication.documents) {
            if (document.error == nil) {
                NSLog(@"Doc ID :: %@", document.id);
                if ((document.flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
                    NSLog(@"Successfully replicated a deleted document");
                }
            } else {
                // There was an error
            }
        }
    }];

    [replicator start];
    // end::add-document-replication-listener[]

    // tag::remove-document-replication-listener[]
    [replicator removeChangeListenerWithToken: token];
    // end::remove-document-replication-listener[]
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
    if (resetCheckpointRequired_Example) {
      [replicator startWithReset];  // <.>
    else
      [replicator start];
    }
    // end::replication-reset-checkpoint[]
}

- (void) dontTestReplicationPushFilter {
    CBLDatabase *database = self.db;

    // tag::replication-push-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    config.pushFilter = ^BOOL(CBLDocument * _Nonnull document, CBLDocumentFlags flags) { // <1>
        if ([[document stringForKey: @"type"] isEqualToString: @"draft"]) {
            return false;
        }
        return true;
    };

    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::replication-push-filter[]
}

- (void) dontTestReplicationPullFilter {
    CBLDatabase *database = self.db;

    // tag::replication-pull-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    config.pullFilter = ^BOOL(CBLDocument * _Nonnull document, CBLDocumentFlags flags) { // <1>
        if ((flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
            return false;
        }
        return true;
    };

    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::replication-pull-filter[]
}

//  Added 2/Feb/21 - Ian Bridge
    - void dontTestCustomRetryConfig {
        // tag::replication-retry-config[]
        id target =
          [[CBLURLEndpoint alloc] initWithURL: [NSURL URLWithString: @"ws://foo.cbl.com/db"]];

        CBLReplicatorConfiguration* config =
            [[CBLReplicatorConfiguration alloc] initWithDatabase: db target: target];
        config.type = kCBLReplicatorTypePush;
        config.continuous: YES;
        //  other config as required . . .

        // tag::replication-heartbeat[]
        config.heartbeat = 150; // <.>

        // end::replication-heartbeat[]
        // tag::replication-maxattempts[]
        config.maxattempts = 20; // <.>

        // end::replication-maxattempts[]
        // tag::replication-maxattemptwaittime[]
        config.maxattemptwaittime = 600; // <.>

        // end::replication-maxattemptwaittime[]
        //  other config as required . . .
        repl = [[CBLReplicator alloc] initWithConfig: config];

        // Cleanup:
        repl = nil;

        // end::replication-retry-config[]

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
    // Active - Example 4
    // tag::certificate-pinning[]
    // tag=p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource: @"cert" withExtension: @"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL: certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database
                                                                                       target:target];
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);

    // end=p2p-act-rep-config-cacert-pinned[]
    // end::certificate-pinning[]

    NSLog(@"%@", config);
}

- (NSData*) dataFromResource: (NSString*)file ofType: (NSString*)type {
    return [NSData data];
}

- (void) dontTestGettingStarted {
    CBLReplicator *_replicator;
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
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
    CBLURLEndpoint *targetEndpoint = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:targetEndpoint];
    replConfig.replicatorType = kCBLReplicatorTypePushAndPull;

    // Add authentication.
    replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

    // Create replicator (make sure to add an instance or static variable named _replicator)
    _replicator = [[CBLReplicator alloc] initWithConfig:replConfig];

    // Listen to replicator change events.
    [_replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code: %ld", change.status.error.code);
        }
    }];

    // Start replication
    [_replicator start];
    // end::getting-started[]
}

- (void) dontTestPredictiveModel {
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::register-model[]
    ImageClassifierModel* model = [[ImageClassifierModel alloc] init];
    [[CBLDatabase prediction] registerModel:model withName:@"ImageClassifier"];
    // end::register-model[]

    // tag::predictive-query-value-index[]
    CBLQueryExpression* input = [CBLQueryExpression dictionary: @{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction* prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input];

    CBLValueIndex* index = [CBLIndexBuilder valueIndexWithItems:@[[CBLValueIndexItem expression:[prediction property:@"label"]]]];
    [database createIndex:index withName:@"value-index-image-classifier" error:&error];
    // end::predictive-query-value-index[]

    // tag::unregister-model[]
    [[CBLDatabase prediction] unregisterModelWithName:@"ImageClassifier"];
    // end::unregister-model[]
}

- (void) dontTestPredictiveIndex {
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::predictive-query-predictive-index[]
    CBLQueryExpression* input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];

    CBLPredictiveIndex* index = [CBLIndexBuilder predictiveIndexWithModel:@"ImageClassifier" input:input properties:nil];
    [database createIndex:index withName:@"predictive-index-image-classifier" error:&error];
    // end::predictive-query-predictive-index[]
}

- (void) dontTestPredictiveQuery {
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::predictive-query[]
    CBLQueryExpression* input = [CBLQueryExpression dictionary: @{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction* prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input]; // <1>

    CBLQueryExpression* condition = [[[prediction property:@"label"] equalTo:[CBLQueryExpression string:@"car"]]
                                     andExpression:[[prediction property:@"probablity"] greaterThanOrEqualTo:[CBLQueryExpression double:0.8]]];
    CBLQuery* query = [CBLQueryBuilder select: @[[CBLQuerySelectResult all]]
                                         from: [CBLQueryDataSource database:database]
                                        where: condition];

    // Run the query.
    CBLQueryResultSet *result = [query execute:&error];
    NSLog(@"Number of rows :: %lu", (unsigned long)[[result allResults] count]);
    // end::predictive-query[]
}

- (void) dontTestCoreMLPredictiveModel {
    NSError *error;

    // tag::coreml-predictive-model[]
    // Load MLModel from `ImageClassifier.mlmodel`
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"ImageClassifier" withExtension:@"mlmodel"];
    NSURL* compiledModelURL = [MLModel compileModelAtURL:modelURL error:&error];
    MLModel* model = [MLModel modelWithContentsOfURL:compiledModelURL error:&error];
    CBLCoreMLPredictiveModel* predictiveModel = [[CBLCoreMLPredictiveModel alloc] initWithMLModel:model];

    // Register model
    [[CBLDatabase prediction] registerModel:predictiveModel withName:@"ImageClassifier"];
    // end::coreml-predictive-model[]
}

- (void) dontTestReplicatorConflictResolver {
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::replication-conflict-resolver[]
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:database target:target];
    config.conflictResolver = [[LocalWinConflictResolver alloc] init];

    CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
    [replicator start];
    // end::replication-conflict-resolver[]
}

- (void) dontTestSaveWithConflictHandler {
    NSError *error;
    CBLDatabase *database = self.db;

    // tag::update-document-with-conflict-handler[]
    CBLDocument *document = [database documentWithID:@"xyz"];
    CBLMutableDocument *mutableDocument = [document toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];

    [database saveDocument:mutableDocument
           conflictHandler:^BOOL(CBLMutableDocument *new, CBLDocument *current) {
               NSDictionary *currentDict = current.toDictionary;
               NSDictionary *newDict = new.toDictionary;

               NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:currentDict];
               [result addEntriesFromDictionary:newDict];
               [new setData: result];
               return YES;
           }
                     error: &error];
    // end::update-document-with-conflict-handler[]
}

#pragma mark - URLListener

- (BOOL) isValidCredentials: (NSString*)u password: (NSString*)p { return YES; } // helper
- (void) dontTestInitListener {
    CBLDatabase *database = self.db;
    CBLURLEndpointListener* listener = nil;

    // tag::init-urllistener[]
    CBLURLEndpointListenerConfiguration* config;
    config = [[CBLURLEndpointListenerConfiguration alloc] initWithDatabase: database];
    config.tlsIdentity = nil; // Use with anonymous self signed cert
    config.authenticator =
        [[CBLListenerPasswordAuthenticator alloc]
            initWithBlock: ^BOOL(
                NSString * username,
                NSString * password)
                {
                if ([self isValidCredentials: username password:password]) {
                    return  YES;
                }
                return NO;
            }];

    listener = [[CBLURLEndpointListener alloc] initWithConfig: config];
    // end::init-urllistener[]
}

- (void) dontTestListenerStart {
    NSError* error = nil;
    CBLURLEndpointListener* listener = nil;

    // tag::start-urllistener[]
    BOOL success = [listener startWithError: &error];
    if (!success) {
        NSLog(@"Cannot start the listener: %@", error);
    }
    // end::start-urllistener[]
}

- (void) dontTestListenerStop {
    CBLURLEndpointListener* listener = nil;

    // tag::stop-urllistener[]
    [listener stop];
    // end::stop-urllistener[]
}

- (void) dontTestCreateSelfSignedCert {
    NSError* error = nil;
    CBLTLSIdentity* identity = nil;
    // <site-rooot>/objc/advance/objc-p2psync-websocket-using-passive.html
    // Example-6
    // tag::create-self-signed-cert[]
    // tag::listener-config-tls-id-SelfSigned[]

    NSDictionary* attrs = @{ kCBLCertAttrCommonName: @"Couchbase Inc" };
    identity =
      [CBLTLSIdentity createIdentityForServer: YES /* isServer */
        attributes: attrs
        expiration: [NSDate dateWithTimeIntervalSinceNow: 86400]
        label: @"Server-Cert-Label"
        error: &error];
    // end::listener-config-tls-id-SelfSigned[]
    // end::create-self-signed-cert[]
}

- (void) dontTestListenerCertificateAuthenticatorRootCert {
    CBLURLEndpointListenerConfiguration* config;

    // Example 8-tab1
    // tag::listener-certificate-authenticator-root-urllistener[]
    // tag::listener-config-client-auth-root[]

    NSURL *certURL = [[NSBundle mainBundle] URLForResource: @"cert" withExtension: @"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL: certURL];
    SecCertificateRef rootCertRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    config.authenticator = [[CBLListenerCertificateAuthenticator alloc]
                            initWithRootCerts: @[(id)CFBridgingRelease(rootCertRef)]];
    // end::listener-config-client-auth-root[]
    // end::listener-certificate-authenticator-root-urllistener[]
}

- (void) dontTestListenerCertificateAuthenticatorCallback {
    CBLURLEndpointListenerConfiguration* config;
    // Example 8-tab2
    // tag::listener-certificate-authenticator-callback-urllistener[]
    // tag::listener-config-client-auth-lambda[]

    CBLListenerCertificateAuthenticator* listenerAuth =
    [[CBLListenerCertificateAuthenticator alloc] initWithBlock: ^BOOL(NSArray *certs) {
        SecCertificateRef cert = (__bridge SecCertificateRef)(certs[0]);
        CFStringRef cnRef;
        OSStatus status = SecCertificateCopyCommonName(cert, &cnRef);
        if (status == errSecSuccess) {
            NSString* cn = (NSString*)CFBridgingRelease(cnRef);
            if ([self._allowlistedUsers containsObject: cn])
                return YES;
        }
        return NO;
    }];

    config.authenticator = listenerAuth;
    // end::listener-config-client-auth-lambda[]
    // end::listener-certificate-authenticator-callback-urllistener[]
}

@end

#pragma mark -

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
        CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"dbname" error: &error];

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
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error: &error];

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

- (void)acceptConnection {
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



// QUERY RESULT SET HANDLING EXAMPLES
- (void) dontTestQuerySyntaxJson {
    // tag::query-syntax-all[]
    NSError *error;

    CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error: &error];

    CBLQuery *listQuery = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                             from:[CBLQueryDataSource database:db]]; // <.>

    // end::query-syntax-all[]


    // tag::query-access-all[]
        NSMutableArray* matches =
          [[NSMutableArray alloc] init];

        CBLQueryResultSet* resultset = [listQuery execute:&error];

        for (CBLQueryResult *result in resultset.allResults) { // access the resultSet.allResults

            NSDictionary *match = [result valueAtIndex: 0] ;
//             toDictionary];

            // Store dictionary in array
            [matches addObject: match];

            // Use dictionary values
            NSLog(@"id = %@", [match valueForKey:@"id"]);
            NSLog(@"name = %@", [match valueForKey:@"name"]);
            NSLog(@"type = %@", [match valueForKey:@"type"]);
            NSLog(@"city = %@", [match valueForKey:@"city"]);

        } // end for

    // end::query-access-all[]

    // tag::query-access-json[]
    NSMutableArray<Hotel *> *hotels = NSMutableArray.new;
    for (CBLQueryResult* result in [listQuery execute:&error]) {

        // Get result as a JSON string

        NSString* thisJsonString =
                    [result toJSON]; // <.>

        // Get an native Obj-C object from the Json String
        NSDictionary *thisDictFromJSON =
                [NSJSONSerialization JSONObjectWithData:
                 [thisJsonString dataUsingEncoding: NSUTF8StringEncoding]
                       options: NSJSONReadingAllowFragments
                       error: &error]; // <.>
        if (error) {
            NSLog(@"Error in serialization: %@",error);
            return;
        }


        // Populate a custom object from native dictionary
        Hotel *hotelFromJson = Hotel.new;

        hotelFromJson.id = thisDictFromJSON[@"id"];  // <.>
        hotelFromJson.name = thisDictFromJSON[@"name"];
        hotelFromJson.city = thisDictFromJSON[@"city"];
        hotelFromJson.country = thisDictFromJSON[@"country"];
        hotelFromJson.descriptive = thisDictFromJSON[@"description"];

        [hotels addObject:hotelFromJson];


        // Log generated Json and Native objects
        // For demo/example purposes
        NSLog(@"Json String %@", thisJsonString);
        NSLog(@"Native Object %@", thisDictFromJSON);
        NSLog(@"Custom Object: id: %@ name: %@ city: %@ country: %@ descriptive: %@", hotelFromJson.id, hotelFromJson.name, hotelFromJson.city, hotelFromJson.country, hotelFromJson.descriptive);

       }; // end for

    // end::query-access-json[]

} // end function




// tag::query-syntax-props[]
CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error: &error];

CBLQuery *listQuery;

CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

CBLQuerySelectResult *type = [CBLQuerySelectResult property:@"type"];

CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

CBLQuerySelectResult *city = [CBLQuerySelectResult property:@"city"];

*listQuery = [CBLQueryBuilder select:@[id, type, name, city]
             from:[CBLQueryDataSource database:db]] // <.>

// end::query-syntax-props[]

// tag::query-access-props[]
    NSMutableArray* matches = [[NSMutableArray alloc] init]; // save to native array

    CBLQueryResultSet* resultset = [listQuery execute:&error];

    for (CBLQueryResult *result in resultset.allResults) { // all results

        [matches addObject: [result toDictionary]];

        NSLog(@"id = %@", [result stringForKey:@"id"]);
        NSLog(@"name = %@", [result stringForKey:@"name"]);
        NSLog(@"type = %@", [result stringForKey:@"type"]);
        NSLog(@"city = %@", [result stringForKey:@"city"]);

    } // end for

// end::query-access-props[]



// tag::query-syntax-count-only[]
CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error: &error];

CBLQuerySelectResult *count =
  [CBLQuerySelectResult expression:[CBLQueryFunction count:   [CBLQueryExpression all]]];

*listQuery = [CBLQueryBuilder select:@[count]
             from:[CBLQueryDataSource database:db]] // <.>

// end::query-syntax-count-only[]

// tag::query-access-count-only[]
CBLDictionary *match;

CBLMutableArray* matches = [[CBLMutableArray alloc] init];

CBLQueryResultSet* resultset = [listQuery execute:&error];

for (CBLQueryResult *result in resultset) {

  *match = [result toDictionary];

  *thisCount = [match intForKey:@"mycount"] // <.>

} // end for

// end::query-access-count-only[]


// tag::query-syntax-id[]
CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error: &error];

CBLQuery *listQuery;

CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

*listQuery = [CBLQueryBuilder select:@[id]
             from:[CBLQueryDataSource database:db]]

// end::query-syntax-id[]

// tag::query-access-id[]

CBLDictionary *match;

CBLMutableArray* matches = [[CBLMutableArray alloc] init];

CBLQueryResultSet* resultset = [listQuery execute:&error];

for (CBLQueryResult *result in resultset) {

  *match = [result toDictionary];

  *thisDocsId = [match stringForKey:@"id"] // <.>

  // Now you can get the document using its ID
  // for example using
  CBLMutableDocument* thisDoc =
    [thisDB documentWithID: thisDocsId]

} // end for

// end::query-access-id[]


// tag::query-syntax-pagination[]
int thisOffset = 0;
int thisLimit = 20;
CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error: &error];

CBLQuery* listQuery =
            [CBLQueryBuilder
                select: @[[CBLQuerySelectResult all]]
                from: [CBLQueryDataSource database: db]
                limit: [CBLQueryLimit
                            limit: [CBLQueryExpression integer: thisLimit]
                            offset: [CBLQueryExpression integer: thisOffset]]
            ];

// end::query-syntax-pagination[]

- (void) docsonly_QuerySyntaxN1QL() {
    /* Documentation Only query-syntax-n1ql
        Declared elsewhere: CBLDatabase* argDb
    */
    NSError *error;

    CBLDatabase *db == argDB;

    // tag::query-syntax-n1ql[]
    NSString *n1qlstr = "SELECT * FROM _ WHERE type = \"hotel\""; // <.>

    CBLQuery* thisQuery = [db createQuery: n1qlstr];

    CBLQueryResultSet* resultset =  [thisQuery execute:&error];

    // end::query-syntax-n1ql[]
}

- (void) docsonly_QuerySyntaxN1QLParams() {
    /* Documentation Only query-syntax-n1ql-params
        Declared elsewhere: CBLDatabase* argDB
    */

    NSError *error;

    CBLDatabase *db = argDB;

    // tag::query-syntax-n1ql-params[]
    NSString *n1qlstr = "SELECT * FROM _ WHERE type = $type"; // <.>

    CBLQuery* thisQuery = [db createQuery: n1qlstr];

    CBLQueryParameters* n1qlparams = [[CBLQueryParameters alloc] init];
    [params setString: @"hotel" forName: @"type"]; // <.>

    thisQuery.parameters = n1qlparams;

    CBLQueryResultSet* resultset =  [thisQuery execute:&error];

    // end::query-syntax-n1ql-params[]
}

// PEER-to-PEER


// tag::listener-simple[]
CBLURLEndpointListenerConfiguration* thisConfig;
  thisConfig =
    [[CBLURLEndpointListenerConfiguration alloc]
      initWithDatabase: database]; // <.>

thisConfig.authenticator =
  [[CBLListenerPasswordAuthenticator alloc]
    initWithBlock: ^BOOL(NSString * validUser, NSString * validPassword) {
      if ([self isValidCredentials: validUser password:validPassword]) {
          return  YES;
      }
      return NO;
  }]; // <.>

CBLURLEndpointListener* thisListener = nil;
thisListener =
  [[CBLURLEndpointListener alloc] initWithConfig: thisConfig]; // <.>

BOOL success = [thisListener startWithError: &error];
if (!success) {
    NSLog(@"Cannot start the listener: %@", error);
} // <.>

// end::listener-simple[]

// tag::replicator-simple[]
NSURL *url =
  [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
CBLURLEndpoint *theListenerURL =
  [[CBLURLEndpoint alloc] initWithURL:url]; // <.>

CBLReplicatorConfiguration *thisConfig
  = [[CBLReplicatorConfiguration alloc]
      initWithDatabase:thisDB target:theListenerURL]; // <.>

thisConfig.acceptOnlySelfSignedServerCertificate = YES; // <.>

thisConfig.authenticator =
  [[CBLBasicAuthenticator alloc]
    initWithUsername:@"valid.user"
      password:@"valid.password.string"]; // <.>


CBLReplicator *_thisReplicator;
_thisReplicator = [[CBLReplicator alloc] initWithConfig:thisConfig]; // <.>

[_thisReplicator start]; // <.>

// end::replicator-simple[]

//
// Stuff I adapted
//


import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class cMyPassListener {
  // tag::listener-initialize[]
  // tag::listener-config-db[]
  // Initialize the listener config <.>
  CBLURLEndpointListenerConfiguration* thisConfig;
  thisConfig =
    [[CBLURLEndpointListenerConfiguration alloc]
      initWithDatabase: database];

    // end::listener-config-db[]
    // tag::listener-config-port[]
    thisConfig.port =  55990; // <.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    NSString *thisURL = @"10.1.1.10";
    thisConfig.networkInterface = thisURL; // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    thisConfig.enableDeltaSync = true; // <.>

    // end::listener-config-delta-sync[]
    // Configure server security
    // tag::listener-config-tls-enable[]
    thisConfig.disableTLS  = false; // <.>

    // end::listener-config-tls-enable[]

    // tag::listener-config-tls-id-anon[]
    // Use an anonymous self-signed cert
    thisConfig.tlsIdentity = nil; // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-client-auth-pwd[]
    // Configure Client Security using an Authenticator
    // For example, Basic Authentication <.>
    thisConfig.authenticator =
      [[CBLListenerPasswordAuthenticator alloc]
        initWithBlock: ^BOOL(NSString * validUser, NSString * validPassword) {
          if ([self isValidCredentials: validUser password:validPassword]) {
              return  YES;
          }
          return NO;
      }];

    // end::listener-config-client-auth-pwd[]
    // tag::listener-start[]
    // tag::listener-init[]
    // Initialize the listener <.>
    CBLURLEndpointListener* thisListener = nil;
    thisListener =
      [[CBLURLEndpointListener alloc] initWithConfig: thisConfig];

    // end::listener-init[]
    // start the listener <.>
    BOOL success = [thisListener startWithError: &error];
    if (!success) {
        NSLog(@"Cannot start the listener: %@", error);
    }

    // end::listener-start[]
// end::listener-initialize[]
  } // end of class

// tag::listener-stop[]
    [thisListener stop];

// end::listener-stop[]

  }
}


// Additional Snippets

// tag::listener-get-network-interfaces[]
// . . .  code snippet to be provided

// end::listener-get-network-interfaces[]

// tag::listener-get-url-list[]
NSError* error = nil;
CBLURLEndpointListenerConfiguration* config =
  [[CBLURLEndpointListenerConfiguration alloc] initWithDatabase: self.otherDB];
CBLURLEndpointListener* listener =
  [[CBLURLEndpointListener alloc] initWithConfig: config];

[listener startWithError: &error];

NSLog(@"%@", listener.urls);

// end::listener-get-url-list[]

// tag::listener-local-db[]
// . . . preceding application logic . . .
fileprivate  var _allowlistedCommonNames:[[String:String]] = []
fileprivate var _thisListener:URLEndpointListener?
fileprivate var thisDB:Database?
// Include websockets listener initializer code
// func fMyPassListener() {
CBLDatabase *thisDB = self.db;
// end::listener-local-db[]

// tag::listener-config-tls-full[]
  // Configure server authentication
  // tag::listener-config-tls-disable[]
  thisConfig.disableTLS  = true; // <.>

  // end::listener-config-tls-disable[]

  // EXAMPLE 6
  // tag::listener-config-tls-id-full[]
  // tag::listener-config-tls-id-caCert[]
  // Use CA Cert
  // Create a TLSIdentity from a key-pair and
  // certificate in secure storage
    NSURL *certURL =
      [[NSBundle mainBundle] URLForResource: @"cert" withExtension: @"p12"]; // <.>

    NSData *data =
      [[NSData alloc] initWithContentsOfURL: certURL];
    CBLTLSIdentity* thisIdentity =
      [CBLTLSIdentity importIdentityWithData: data
        password: @"123"
        label: @"couchbase-docs-cert"
        error: &error]; // <.>

    config.tlsIdentity = thisIdentity; // <.>

  // end::listener-config-tls-id-caCert[]
  // tag::listener-config-tls-id-SelfSigned[]
  // Use a self-signed certificate
  NSDictionary* attrs =
    @{ kCBLCertAttrCommonName: @"Couchbase Inc" }; // <.>

  thisIdentity =
    [CBLTLSIdentity createIdentityForServer: YES /* isServer */
        attributes: attrs
        expiration: [NSDate dateWithTimeIntervalSinceNow: 86400]
              label: @" couchbase-docs-cert"
              error: &error]; // <.>

  // end::listener-config-tls-id-SelfSigned[]
      // tag::listener-config-tls-id-set[]
  // set the TLS Identity
  thisConfig.tlsIdentity = thisIdentity; // <.>

  // end::listener-config-tls-id-set[]
  // end::listener-config-tls-id-full[]
// end::listener-config-tls-full[]

// EXAMPLE 8
// tag::listener-config-client-auth-root[]
// Configure the client authenticator
NSURL *certURL =
  [[NSBundle mainBundle]
    URLForResource: @"cert" withExtension: @"p12"]; // <.>
NSData *data =
  [[NSData alloc]
    initWithContentsOfURL: certURL];
SecCertificateRef rootCertRef =
  SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

thisConfig.authenticator =
  [[CBLListenerCertificateAuthenticator alloc]
    initWithRootCerts: @[(id)CFBridgingRelease(rootCertRef)]];  // <.> <.>

// end::listener-config-client-auth-root[]
// tag::listener-config-client-auth-lambda[]
// Authenticate self-signed cert
// using application logic
CBLListenerCertificateAuthenticator* thisListenerAuth =
  [[CBLListenerCertificateAuthenticator alloc]
    initWithBlock: ^BOOL(NSArray *certs) {
      SecCertificateRef cert =
        (__bridge SecCertificateRef)(certs[0]); // <.>
      CFStringRef cnRef;
      OSStatus status = SecCertificateCopyCommonName(cert, &cnRef);
      if (status == errSecSuccess) {
          NSString* cn = (NSString*)CFBridgingRelease(cnRef);
          if ([self._allowlistedCommonNames containsObject: cn])
              return YES;
      }
      return NO;
  }];  // <.>

thisConfig.authenticator = thisListenerAuth; // <.>

// end::listener-config-client-auth-lambda[]







// tag::xlistener-config-tls-disable[]
thisConfig.disableTLS  = true

// end::xlistener-config-tls-disable[]

// tag::listener-config-tls-id-nil[]
thisConfig.tlsIdentity = nil

// end::listener-config-tls-id-nil[]


// tag::old-listener-config-delta-sync[]
thisConfig.enableDeltaSync = true

// end::old-listener-config-delta-sync[]


// tag::listener-status-check[]
NSUInteger totalConnections = thisListener.status.connectionCount;
NSUInteger activeConnections = thisListener.status.activeConnectionCount;

// end::listener-status-check[]


// tag::old-listener-config-client-auth-root[]
  // cert is a pre-populated object of type:SecCertificate representing a certificate
  let rootCertData = SecCertificateCopyData(cert) as Data
  let rootCert = SecCertificateCreateWithData(kCFAllocatorDefault, rootCertData as CFData)!
  // Listener:
  thisConfig.authenticator = ListenerCertificateAuthenticator.init (rootCerts: [rootCert])

// end::old-listener-config-client-auth-root[]
/

// tag::listener-config-client-auth-self-signed[]
thisConfig.authenticator = ListenerCertificateAuthenticator.init {
  (cert) -> Bool in
    var cert:SecCertificate
    var certCommonName:CFString?
    let status=SecCertificateCopyCommonName(cert, &certCommonName)
    if (self._allowlistedCommonNames.contains(["name": certCommonName! as String])) {
        return true
    }
    return false
}

// end::listener-config-client-auth-self-signed[]

// tag::p2p-ws-api-urlendpointlistener[]
public class URLEndpointListener {
    // Properties // <1>
    public let config: URLEndpointListenerConfiguration
    public let port UInt16?
    public let tlsIdentity: TLSIdentity?
    public let urls: Array<URL>?
    public let status: ConnectionStatus?
    // Constructors <2>
    public init(config: URLEndpointListenerConfiguration)
    // Methods <3>
    public func start() throws
    public func stop()
}

// end::p2p-ws-api-urlendpointlistener[]


// tag::p2p-ws-api-urlendpointlistener-constructor[]
let config = URLEndpointListenerConfiguration.init(database: self.oDB)
thisConfig.port = tls ? wssPort : wsPort
thisConfig.disableTLS = !tls
thisConfig.authenticator = auth
self.listener = URLEndpointListener.init(config: config) // <1>

// end::p2p-ws-api-urlendpointlistener-constructor[]


// Active Peer Connection Snippets

//
//  my Other Bits.swift
//  doco-sync
//
//  Created by Ian Bridge on 19/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

class myActPeerClass {

  func fMyActPeer() {
    // let validUser = "syncthisUser"
    // let validPassword = "sync9455"
    // let cert:SecCertificate?
    // let passivePeerEndpoint = "10.1.1.12:8920"
    // let passivePeerPort = "8920"
    // let passiveDbName = "userdb"
    // var actDb:Database?
    // var thisReplicator:Replicator?
    // var replicatorListener:ListenerToken?

    CBLReplicator *_thisReplicator;

    CBLListenerToken *_thisListenerToken;

    CBLDatabase *database
      = [[CBLDatabase alloc] initWithName:@"thisDB" error:&error];
        if (!database) {
          NSLog(@"Cannot open the database: %@", error);
        };

    // tag::p2p-act-rep-func[]
    // tag::p2p-act-rep-initialize[]
    // Set listener DB endpoint
    NSURL *url =
      [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *thisListener =
      [[CBLURLEndpoint alloc] initWithURL:url]; // <.>

    CBLReplicatorConfiguration *thisConfig =
      [[CBLReplicatorConfiguration alloc]
        initWithDatabase:thisDB target:thisListener]; // <.>

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config[]
    // tag::p2p-act-rep-config-type[]
    thisConfig.replicatorType = kCBLReplicatorTypePush;

    // end::p2p-act-rep-config-type[]
    // tag::autopurge-override[]
    // set auto-purge behavior (here we override default)
    thisConfig.enableAutoPurge = NO; // <.>

    // end::autopurge-override[]
    // tag::p2p-act-rep-config-cont[]
    thisConfig.continuous = YES;

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Authentication
    // Here - expect and accept self-signed certs
    thisConfig.acceptOnlySelfSignedServerCertificate = YES; // <.>

    // end::p2p-act-rep-config-self-cert[]
    // Configure Client Authentication
    // tag::p2p-act-rep-auth[]
    // Here set client to use basic authentication
    // Providing username and password credentials
    // If prompted for them by server
    thisConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"Our Username" password:@"Our Password"]; // <.>

    // end::p2p-act-rep-auth[]
    // end::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-conflict[]
    /* Optionally set custom conflict resolver call back */
    thisConfig.conflictResolver = [[LocalWinConflictResolver alloc] // <.>

    // end::p2p-act-rep-config-conflict[]    //
    // end::p2p-act-rep-config[]
    // tag::p2p-act-rep-start-full[]
    // Apply configuration settings to the replicator
    _thisReplicator = [[CBLReplicator alloc] initWithConfig:thisConfig]; // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-add-change-listener-label[]
    // Optionally add a change listener <.>
    // end::p2p-act-rep-add-change-listener-label[]
    // Retain token for use in deletion
    id<CBLListenerToken> thisListenerToken
      = [thisReplicator addChangeListener:^(CBLReplicatorChange *thisChange) {
    // tag::p2p-act-rep-status[]
          if (thisChange.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
            } else {
            NSLog(@"Status: %d", thisChange.status.activity);
            };
    // end::p2p-act-rep-status[]
        }];
// end::p2p-act-rep-add-change-listener[]
// tag::p2p-act-rep-start[]
    // Run the replicator using the config settings
    [thisReplicator start]; // <.>

// end::p2p-act-rep-start[]
// end::p2p-act-rep-start-full[]
// end::p2p-act-rep-func[]
    }

    func mystopfunc() {
// tag::p2p-act-rep-stop[]
    // Remove the change listener
    [thisReplicator removeChangeListenerWithToken: thisListenerToken];

    // Stop the replicator
    [thisReplicator stop];
// end::p2p-act-rep-stop[]
}

// Additional Snippets from above
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA Certs
    thisConfig.acceptOnlySelfSignedServerCertificate = NO; // <.>

    // end::p2p-act-rep-config-cacert[]


    // tag::p2p-act-rep-config-pinnedcert[]
    // Return the remote pinned cert (the listener's cert)
    thisConfig.pinnedServerCertificate = thisCert; // Get listener cert if pinned

    // end::p2p-act-rep-config-pinnedcert[]







// tag::p2p-tlsid-manage-func[]
//
//  cMyGetCert.swift
//  doco-sync
//
//  Created by Ian Bridge on 20/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

import Foundation
import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity


class cMyGetCert1{

    let kListenerCertLabel = "doco-sync-server"
    let kListenerCertKeyP12File = "listener-cert-pkey"
    let kListenerPinnedCertFile = "listener-pinned-cert"
    let kListenerCertKeyExportPassword = "couchbase"
    //var importedItems : NSArray
    let thisData : CFData?
    var items : CFArray?

    func fMyGetCert() ->TLSIdentity? {
        var kcStatus = errSecSuccess // Zero
        let thisLabel : String? = "doco-sync-server"

        //var thisData : CFData?
        // tag::p2p-tlsid-tlsidentity-with-label[]
        // tag::p2p-tlsid-check-keychain[]
        // Check if Id exists in keychain and if so, use it
        CBLTLSIdentity* identity =
          [CBLTLSIdentity identityWithLabel: @"doco-sync-server" error: &error]; // <.>

        // end::p2p-tlsid-check-keychain[]
        thisConfig.authenticator =
          [[CBLClientCertificateAuthenticator alloc] initWithIdentity: identity]; // <.>

        // end::p2p-tlsid-tlsidentity-with-label[]


// tag::p2p-tlsid-check-bundled[]
// CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

        // Check for a resource bundle with required label to generate identity from
        // return nil identify if not found
        guard let pathToCert = Bundle.main.path(forResource: "doco-sync-server", ofType: "p12"),
                let thisData = NSData(contentsOfFile: pathToCert)
            else
                {return nil}
// end::p2p-tlsid-check-bundled[]

// tag::p2p-tlsid-import-from-bundled[]
        // Use SecPKCS12Import to import the contents (identities and certificates)
        // of the required resource bundle (PKCS #12 formatted blob).
        //
        // Set passphrase using kSecImportExportPassphrase.
        // This passphrase should correspond to what was specified when .p12 file was created
        kcStatus = SecPKCS12Import(thisData as CFData, [String(kSecImportExportPassphrase): "couchbase"] as CFDictionary, &items)
            if kcStatus != errSecSuccess {
             print("failed to import data from provided with error :\(kcStatus) ")
             return nil
            }
        let importedItems = items! as NSArray
        let thisItem = importedItems[0] as! [String: Any]

        // Get SecIdentityRef representing the item's id
        let thisSecId = thisItem[String(kSecImportItemIdentity)]  as! SecIdentity

        // Get Id's Private Key, return nil id if fails
        var thisPrivateKey : SecKey?
        kcStatus = SecIdentityCopyPrivateKey(thisSecId, &thisPrivateKey)
            if kcStatus != errSecSuccess {
                print("failed to import private key from provided with error :\(kcStatus) ")
                return nil
            }

        // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
        let thisCertChain = thisItem[String(kSecImportItemCertChain)] as? [SecCertificate]

        // Return nil Id if errors in key or cert chain at this stage
        guard let pKey = thisPrivateKey, let pubCerts = thisCertChain else {
            return nil
        }
// end::p2p-tlsid-import-from-bundled[]

// tag::p2p-tlsid-store-in-keychain[]
// STORE THE IDENTITY AND ITS CERT CHAIN IN THE KEYCHAIN

        // Store Private Key in Keychain
        let params: [String : Any] = [
            String(kSecClass):          kSecClassKey,
            String(kSecAttrKeyType):    kSecAttrKeyTypeRSA,
            String(kSecAttrKeyClass):   kSecAttrKeyClassPrivate,
            String(kSecValueRef):       pKey
        ]
        kcStatus = SecItemAdd(params as CFDictionary, nil)
            if kcStatus != errSecSuccess {
                print("Unable to store private key")
                return nil
            }
       // Store all Certs for Id in Keychain:
       var i = 0;
       for cert in thisCertChain! {
            let params: [String : Any] = [
                String(kSecClass):      kSecClassCertificate,
                String(kSecValueRef):   cert,
                String(kSecAttrLabel):  "doco-sync-server"
                ]
            kcStatus = SecItemAdd(params as CFDictionary, nil)
                if kcStatus != errSecSuccess {
                    print("Unable to store certs")
                    return nil
                }
            i=i+1
        }
// end::p2p-tlsid-store-in-keychain[]

// tag::p2p-tlsid-return-id-from-keychain[]
// RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
do {
    return try TLSIdentity.identity(withIdentity: thisSecId, certs: [pubCerts[0]])
} catch {
    print("Error while loading self signed cert : \(error)")
    return nil
}
// end::p2p-tlsid-return-id-from-keychain[]
    } // fMyGetCert
} // cMyGetCert


// tag::p2p-tlsid-delete-id-from-keychain[]

[CBLTLSIdentity deleteIdentityWithLabel:thisSecId error: &error];

// end::p2p-tlsid-delete-id-from-keychain[]



// end::p2p-tlsid-manage-func[]



// tag::p2p-act-rep-config-cacert-pinned-func[]
func fMyCaCertPinned() {
  // do {
  let tgtUrl = URL(string: "wss://10.1.1.12:8092/actDb")!
  let targetEndpoint = URLEndpoint(url: tgtUrl)
  let actDb:Database?
  let config = ReplicatorConfiguration(database: actDb!, target: targetEndpoint)
  // tag::p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL =
      [[NSBundle mainBundle] URLForResource: @"cert" withExtension: @"cer"];
    NSData *data =
      [[NSData alloc] initWithContentsOfURL: certURL];
    SecCertificateRef certificate =
      SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    NSURL *url =
      [NSURL URLWithString:@"ws://localhost:4984/db"];

    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];

    CBLReplicatorConfiguration *thisConfig =
      [[CBLReplicatorConfiguration alloc] initWithDatabase:database
                                          target:target];
    thisConfig.pinnedServerCertificate =
      (SecCertificateRef)CFAutorelease(certificate);

    thisConfig.acceptOnlySelfSignedServerCertificate=false;

  // end::p2p-act-rep-config-cacert-pinned[]
  // end::p2p-act-rep-config-cacert-pinned-func[]
}



// For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
@interface MyClass : NSObject
@property (nonatomic) CBLDatabase *database;
@property (nonatomic) CBLReplicator *replicator; // <1>
@end

@implementation MyClass
@synthesize database=_database;
@synthesize replicator=_replicator;

- (void) startReplication {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"]; // <2>
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL: url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database
                                                                                       target:target];
    config.replicatorType = kCBLReplicatorTypePull;
    _replicator = [[CBLReplicator alloc] initWithConfig:config];
    [_replicator start];
}
@end

// end::sgw-repl-pull[]

// tag::sgw-repl-pull-callouts[]
<1> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<2> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.


// end::sgw-repl-pull-callouts[]

// tag::sgw-act-rep-initialize[]
// Set listener DB endpoint
NSURL *url = [NSURL URLWithString:@"ws://10.0.2.2.com:55990/travel-sample"];
CBLURLEndpoint *thisListener = [[CBLURLEndpoint alloc] initWithURL:url];

CBLReplicatorConfiguration *thisConfig
  = [[CBLReplicatorConfiguration alloc]
      initWithDatabase:thisDB target:thisListener]; // <.>

// end::sgw-act-rep-initialize[]
// END -- snippets --



// FOR JSON API Methods

// tag::tojson-array[]
NSString* thisJSONstring = @"[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\","
    "\"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},"
    "{\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\","
    "\"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},"
    "{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\","
    "\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\","
    "\"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]";

    NSError* error = nil;
    CBLMutableArray* myArray = [[CBLMutableArray alloc] initWithJSON: thisJSONstring error: &error];

    for (NSUInteger i = 0 ; i < myArray.count; i++) {
        NSLog(@"%lu %@", i+1, [[myArray dictionaryAtIndex: i] stringForKey: @"name"]);

        NSString* docID = [[myArray dictionaryAtIndex: i] stringForKey: @"ID"];

        CBLMutableDocument* newdoc = [[CBLMutableDocument alloc] initWithID: docID data: [[myArray dictionaryAtIndex: i] toDictionary]];

        [db saveDocument: newdoc error: &error];
    }

    CBLDocument* extendedDoc = [newdb documentWithID: @"1002"];
    NSArray* features = [[extendedDoc arrayForKey: @"features"] toArray];
    for (NSUInteger i = 0; i < features.count; i++) {
        NSLog(@"%@", features[i]);
    }

    NSLog( @"%@", [[extendedDoc arrayForKey: @"features"] toJSON]);

// end::tojson-array[]

// Example 2. Using Blobs
// tag::tojson-blob[]

    // Get a document
    CBLMutableDocument* thisDoc = [[db documentWithID: @"1000"] toMutable];

    // Get the image and add as a blob to the document
    NSString* contentType = @"";
    UIImage* ourImage = [UIImage imageNamed: @"couchbaseimage.png"];
    NSData* imageData = UIImageJPEGRepresentation(ourImage, 1);
    CBLBlob* thisBlob = [[CBLBlob alloc] initWithContentType: contentType data: imageData];
    [thisDoc setBlob: thisBlob forKey: @"avatar"];

    NSString* theBlobAsJSONstringFails = [[thisDoc blobForKey: @"avatar"] toJSON];

    // Save blob as part of doc or alternatively as a blob

    NSError* error = nil;
    [db saveDocument: thisDoc error: &error];
    [db saveBlob: thisBlob error: &error]; // <.>

    // Retrieve saved blob as a JSON, reconstitue and check still blob

    CBLDocument* sameDoc = [db documentWithID: @"1000"];
    CBLBlob* sameBlob = [sameDoc blobForKey: @"avatar"];
    NSString* theBlobAsJSONstring = [sameBlob toJSON];
    NSDictionary* dict = sameDoc.toDictionary;
    for (id key in dict) {
        NSLog(@"Data -- {%@) = {%@}", key, [dict valueForKey: key]);
    }

    if ([CBLBlob isBlob: sameBlob.properties]) {
        NSLog(@"%@", theBlobAsJSONstring);
    }

// end::tojson-blob[]

// Example 6. Dictionaries as JSON strings
// tag::tojson-dictionary[]
    NSString* aJSONstring = @"{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\","
    "\"city\":\"Balmain\",\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}";

    NSError* error = nil;
    CBLMutableDictionary* myDict = [[CBLMutableDictionary alloc] initWithJSON: aJSONstring error: &error];
    NSLog(@"%@", myDict);

    NSString* name = [myDict stringForKey: @"name"];
    NSLog(@"Details for: %@", name);

    for (NSString* key in myDict) {
        NSLog(@"%@ %@", key, [myDict valueForKey: key]);
    }

// end:tojson-dictionary[]

// Example 7. Documents as JSON strings
// tag::tojson-document[]
    NSError* error = nil;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"hotel" error: &error];
    CBLDatabase* dbnew = [[CBLDatabase alloc] initWithName: @"newhotels" error: &error];

    CBLQuery* listQuery = [CBLQueryBuilder select: @[[CBLQuerySelectResult expression: [CBLQueryMeta id] as: @"metaId"]]
                                             from: [CBLQueryDataSource database: db]];


    CBLQueryResultSet* rs = [listQuery execute: &error];
    for (CBLQueryResult* r in rs.allObjects) {
        NSString* thisId = [r stringForKey: @"metaId"];
        NSString* thisJSONstring = [[db documentWithID: thisId] toJSON];

        NSLog(@"JSON String = %@", thisJSONstring);

        NSError* docError = nil;
        CBLMutableDocument* hotelFromJSON = [[CBLMutableDocument alloc] initWithID: thisId json: thisJSONstring error: &docError];

        [dbnew saveDocument: hotelFromJSON error: &error];
        CBLDocument* newhotel = [dbnew documentWithID: thisId];
        NSArray* keys = newhotel.keys;
        for (NSString* key in keys) {
            NSLog(@"%@ %@", key, [newhotel valueForKey: key]);
        }
    }

// end::tojson-document[]
