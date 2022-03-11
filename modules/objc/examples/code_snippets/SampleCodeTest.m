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


#pragma mark - !!!Note
/**
 Note for Consistency across the code snippets:

 1. We will keep the '*' with instance after the space.
    `NSDictionary *dict = [NSDictionary dictionary];`

 2. For making more space in single line, we will avoid space after the ':' in function call.
    `[myMLModel predictImage:imageData];`

 3. Will only keep `self.database` when using database, query and replicator related code snippet.
    Except when creating a new database sample.

 4. Will only keep `self.otherDB` when using listener-db

 5. While using replicator/listener, we will use as ivar `self.replicator` and `self.listener` resp.
 */

#pragma mark -

// tag::predictive-model[]
// `myMLModel` is a fake implementation
// this would be the implementation of the ml model you have chosen
@interface myMLModel :NSObject

+ (NSDictionary*)predictImage:(NSData*)data;

@end

@interface ImageClassifierModel :NSObject <CBLPredictiveModel>

- (nullable CBLDictionary*) predict:(CBLDictionary*)input;

@end

@implementation ImageClassifierModel

- (nullable CBLDictionary*) predict:(CBLDictionary*)input; {
    CBLBlob *blob = [input blobForKey:@"photo"];

    NSData *imageData = blob.content;
    // `myMLModel` is a fake implementation
    // this would be the implementation of the ml model you have chosen
    NSDictionary *modelOutput = [myMLModel predictImage:imageData];

    CBLMutableDictionary *output = [[CBLMutableDictionary alloc] initWithData:modelOutput];
    return output; // <1>
}

@end
// end::predictive-model[]

// to avoid link error
@implementation myMLModel
+ (NSDictionary*)predictImage:(NSData*)data { return [NSDictionary dictionary]; }
@end

// tag::custom-logging[]
@interface LogTestLogger :NSObject<CBLLogger>

// set the log level
@property (nonatomic) CBLLogLevel level;

@end

@implementation LogTestLogger

@synthesize level=_level;

- (void) logWithLevel:(CBLLogLevel)level domain:(CBLLogDomain)domain message:(NSString*)message {
    // handle the message, for example piping it to
    // a third party framework
}

@end

// end::custom-logging[]

// tag::local-win-conflict-resolver[]
@interface LocalWinConflictResolver :NSObject<CBLConflictResolver>
@end

@implementation LocalWinConflictResolver
- (CBLDocument*) resolve:(CBLConflict*)conflict {
    return conflict.localDocument;
}

@end
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
@interface RemoteWinConflictResolver:NSObject<CBLConflictResolver>
@end

@implementation RemoteWinConflictResolver
- (CBLDocument*) resolve:(CBLConflict*)conflict {
    return conflict.remoteDocument;
}

@end
// end::remote-win-conflict-resolver[]


// tag::merge-conflict-resolver[]
@interface MergeConflictResolver:NSObject<CBLConflictResolver>
@end

@implementation MergeConflictResolver
- (CBLDocument*) resolve:(CBLConflict*)conflict {
    NSDictionary *localDict = conflict.localDocument.toDictionary;
    NSDictionary *remoteDict = conflict.remoteDocument.toDictionary;

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:localDict];
    [result addEntriesFromDictionary:remoteDict];

    return [[CBLMutableDocument alloc] initWithID:conflict.documentID
                                             data:result];
}

@end
// end::merge-conflict-resolver[]

@interface Hotel :NSObject
@property (nonatomic) NSString *id;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *city;
@property (nonatomic) NSString *country;
@property (nonatomic) NSString *descriptive;
@end

@implementation Hotel
@synthesize id, name, city, country, descriptive;
@end

@interface SampleCodeTest :NSObject
@property(nonatomic) CBLDatabase *database;
@property(nonatomic) CBLDatabase *otherDB;
@property(nonatomic) CBLURLEndpointListener *listener;
@property(nonatomic) CBLReplicator *replicator;
@end

@implementation SampleCodeTest

#pragma mark - Database

- (void) dontTestNewDatabase {
    // tag::new-database[]
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"my-database" error:&error];
    if (!database) {
        NSLog(@"Cannot open the database:%@", error);
    }
    self.database = database;
    // end::new-database[]

    // tag::close-database[]
    if (![self.database close:&error])
        NSLog(@"Error closing db:%@", error);

    // end::close-database[]
}

- (void) dontTestLogging {
    // tag::logging[]

    // Replicator / Verbose
    CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    CBLDatabase.log.console.domains = kCBLLogDomainReplicator;

    // Query /  Verbose
    CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    CBLDatabase.log.console.domains = kCBLLogDomainQuery;
    // end::logging[]
}

#if COUCHBASE_ENTERPRISE
- (void) dontTestDatabaseEncryption {
    // tag::database-encryption[]
    CBLDatabaseConfiguration *config = [[CBLDatabaseConfiguration alloc] init];
    config.encryptionKey = [[CBLEncryptionKey alloc] initWithPassword:@"secretpassword"];

    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"my-database" config:config error:&error];
    if (!self.database) {
        NSLog(@"Cannot open the database:%@", error);
    }
    // end::database-encryption[]
}
#endif

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
    NSString *tempFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cbllog"];
    CBLLogFileConfiguration *config = [[CBLLogFileConfiguration alloc] initWithDirectory:tempFolder]; // <.>
    config.maxRotateCount = 2; // <.>
    config.maxSize = 1024; // <.>
    config.usePlainText = YES; // <.>
    [CBLDatabase.log.file setConfig:config];
    [CBLDatabase.log.file setLevel:kCBLLogLevelInfo]; // <.>
    // end::file-logging[]
}

- (void) dontTestEnableCustomLogging {
    // tag::set-custom-logging[]
    LogTestLogger *logger = [[LogTestLogger alloc] init];
    logger.level = kCBLLogLevelWarning;
    [CBLDatabase.log setCustom:logger];

    // end::set-custom-logging[]
}

- (void) dontTestLoadingPrebuilt {
    // tag::prebuilt-database[]
    // Note:Getting the path to a database is platform-specific.
    // For iOS you need to get the path from the main bundle.
    if (![CBLDatabase databaseExists:@"travel-sample" inDirectory:nil]) {
        NSError *error;
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"travel-sample" ofType:@"cblite2"];
        if (![CBLDatabase copyFromPath:path toDatabase:@"travel-sample" withConfig:nil error:&error]) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Could not load pre-built database:%@", error];
        }
    }
    // end::prebuilt-database[]
}

#pragma mark - Document

- (void) dontTestInitializer {
    NSError *error;

    // tag::initializer[]
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] init];
    [newTask setString:@"task" forKey:@"task"];
    [newTask setString:@"todo" forKey:@"owner"];
    [newTask setString:@"task" forKey:@"createdAt"];
    [self.database saveDocument:newTask error:&error];
    // end::initializer[]
}

- (void) dontTestMutability {
    NSError *error;

    // tag::update-document[]
    CBLDocument *document = [self.database documentWithID:@"xyz"];
    CBLMutableDocument *mutableDocument = [document toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];
    [self.database saveDocument:mutableDocument error:&error];
    // end::update-document[]
}

- (void) dontTestTypedAcessors {
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] init];

    // tag::date-getter[]
    [newTask setValue:[NSDate date] forKey:@"createdAt"];
    NSDate *date = [newTask dateForKey:@"createdAt"];
    // end::date-getter[]

    NSLog(@"Date:%@", date);
}



- (void) dontTestDataTypeUsage {
    // tag::datatype_usage[]
    // tag::datatype_usage_createdb[]
    // Get the database (and create it if it doesn’t exist).

    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"hoteldb" error:&error];

    // end::datatype_usage_createdb[]
    // tag::datatype_usage_createdoc[]
    // Create your new document
    // The lack of 'const' indicates this document is mutable
    CBLMutableDocument *mutableDoc = [[CBLMutableDocument alloc] init];


    // end::datatype_usage_createdoc[]
    // tag::datatype_usage_mutdict[]
    // Create and populate mutable dictionary
    // Create a new mutable dictionary and populate some keys/values
    CBLMutableDictionary *address = [[CBLMutableDictionary alloc] init];
    [address setString:@"1 Main st" forKey:@"street"];
    [address setString:@"San Francisco" forKey:@"city"];
    [address setString:@"CA" forKey:@"state"];
    [address setString:@"USA" forKey:@"country"];
    [address setString:@"90210" forKey:@"code"];

    // end::datatype_usage_mutdict[]
    // tag::datatype_usage_mutarray[]
    // Create and populate mutable array
    CBLMutableArray *phones = [[CBLMutableArray alloc] init];
    [phones addString:@"650-000-0000"];
    [phones addString:@"650-000-0001"];

    // end::datatype_usage_mutarray[]
    // tag::datatype_usage_populate[]
    // Initialize and populate the document

    // Add document type to document properties <.>
    [mutableDoc setString:@"hotel" forKey:@"type"];

    // Add hotel name string to document properties <.>
    [mutableDoc setString:@"Hotel Java Mo" forKey:@"name"];

    // Add float to document properties <.>
    [mutableDoc setFloat:121.75 forKey:@"room_rate"];

    // Add dictionary to document's properties <.>
    [mutableDoc setDictionary:address forKey:@"address"];

    // Add array to document's properties <.>
    [mutableDoc setArray:phones forKey:@"phones"];

    // end::datatype_usage_populate[]
    // tag::datatype_usage_persist[]
    // Save the document changes <.>
    [self.database saveDocument:mutableDoc error:&error];

    // end::datatype_usage_persist[]
    // tag::datatype_usage_closedb[]
    // Close the database <.>
    if (![self.database close:&error])
        NSLog(@"Error closing db:%@", error);

    // end::datatype_usage_closedb[]

    // end::datatype_usage[]

}


- (void) dontTestDataTypeDictionary {
    // tag::datatype_dictionary[]
    CBLDocument *document = [self.database documentWithID:@"doc1"];

    // Getting a dictionary value from the document
    CBLDictionary *dict = [document dictionaryForKey:@"address"];

    // Access a value from the dictionary
    NSString *street = [dict stringForKey:@"street"];
    NSLog(@"Street:: %@", street);

    // Iterate dictionary
    for (NSString *key in dict) {
        id value = [dict valueForKey:key];
        NSLog(@"Value:: %@", value);
    }

    // Create a mutable copy
    CBLMutableDictionary *mutableDict = [dict toMutable];
    [mutableDict setString:@"1 Great sts" forKey:@"street"];
    // end::datatype_dictionary[]
}

- (void) dontTestDataTypeMutableDictionary {
    // tag::datatype_mutable_dictionary[]

    // Create a new mutable dictionary and populate some keys/values
    CBLMutableDictionary *dict = [[CBLMutableDictionary alloc] init];
    [dict setString:@"1 Main st" forKey:@"street"];
    [dict setString:@"San Francisco" forKey:@"city"];

    // Set the dictionary to a document and save the document
    CBLMutableDocument *document = [[CBLMutableDocument alloc] init];
    [document setDictionary:dict forKey:@"address"];
    NSError *error;
    [self.database saveDocument:document error:&error];
    // end::datatype_mutable_dictionary[]
}

- (void) dontTestDataTypeArray {
    // tag::datatype_array[]
    CBLDocument *document = [self.database documentWithID:@"doc1"];

    // Getting an array value from the document
    CBLArray *array = [document arrayForKey:@"phones"];

    // Get element count
    NSUInteger count = array.count;
    NSLog(@"Count:: %lu", (unsigned long)count);

    // Access an array element by index
    if (count > 0) {
        id value = [array valueAtIndex:0];
        NSLog(@"Value:: %@", value);
    }

    // Iterate the array
    for (id value in array) {
        NSLog(@"Value:: %@", value);
    }

    // Create a mutable copy
    CBLMutableArray *mutableArray = [array toMutable];
    [mutableArray addString:@"650-000-0002"];
    // end::datatype_array[]
}

- (void) dontTestDataTypeMutableArray {
    // tag::datatype_mutable_array[]
    // Create a new mutable array and populate data into the array
    CBLMutableArray *array = [[CBLMutableArray alloc] init];
    [array addString:@"650-000-0000"];
    [array addString:@"650-000-0001"];

    // Set the array to a document and save the document
    CBLMutableDocument *document = [[CBLMutableDocument alloc] init];
    [document setArray:array forKey:@"address"];
    NSError *error;
    [self.database saveDocument:document error:&error];
    // end::datatype_mutable_array[]
}

- (void) dontTestBatchOperations {
    NSError *error;

    // tag::batch[]
    [self.database inBatch:&error usingBlock:^{
        for (int i = 0; i < 10; i++) {
            CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
            [doc setValue:@"user" forKey:@"type"];
            [doc setValue:[NSString stringWithFormat:@"user %d", i] forKey:@"name"];
            [doc setBoolean:NO forKey:@"admin"];

            NSError *err = nil;
            [self.database saveDocument:doc error:&err];
        }
    }];
    // end::batch[]
}

- (void) dontTestChangeListener {
    __block SampleCodeTest *wSelf = self;
    // tag::document-listener[]
    [self.database addDocumentChangeListenerWithID:@"user.john" listener:^(CBLDocumentChange  *change) {
        CBLDocument *document = [wSelf.database documentWithID:change.documentID];
        NSLog(@"Status ::%@)", [document stringForKey:@"verified_account"]);
    }];
    // end::document-listener[]
}

- (void) dontTestDocumentExpiration {
    NSError *error;

    // tag::document-expiration[]
    // Purge the document one day from now
    NSDate *ttl = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay
                                                           value:1
                                                          toDate:[NSDate date]
                                                         options:0];
    [self.database setDocumentExpirationWithID:@"doc123" expiration:ttl error:&error];

    // Reset expiration
    [self.database setDocumentExpirationWithID:@"doc1" expiration:nil error:&error];

    // Query documents that will be expired in less than five minutes
    NSTimeInterval fiveMinutesFromNow = [[NSDate dateWithTimeIntervalSinceNow:60 * 5] timeIntervalSince1970];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[[CBLQueryMeta expiration]
                                                lessThan:[CBLQueryExpression double:fiveMinutesFromNow]]];
    // end::document-expiration[]
    NSLog(@"%@", query);
}

- (void) dontTestBlob {
#if TARGET_OS_IPHONE
    NSError *error;
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] initWithID:@"task1"];

    // tag::blob[]
    UIImage *appleImage = [UIImage imageNamed:@"avatar.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(appleImage, 1.0);  // <.>

    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:imageData];  // <.>
    [newTask setBlob:blob forKey:@"avatar"]; // <.>
    [self.database saveDocument:newTask error:&error];

    CBLDocument *savedTask = [self.database documentWithID:@"task1"];
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

    // tag::query-index[]

    CBLValueIndexConfiguration* config =
                [[CBLValueIndexConfiguration alloc]
                    initWithExpression: @[@"type", @"name"]];

    [self.database createIndexWithConfig: config name: @"TypeNameIndex" error: &error];


    // end::query-index[]
}

- (void) dontTestIndexing_Querybuilder {
    NSError *error;

        // tag::query-index_Querybuilder[]
    CBLValueIndexItem *type = [CBLValueIndexItem property:@"type"];
    CBLValueIndexItem *name = [CBLValueIndexItem property:@"name"];
    CBLIndex *index = [CBLIndexBuilder valueIndexWithItems:@[type, name]];
    [self.database createIndex:index withName:@"TypeNameIndex" error:&error];
        // end::query-index_Querybuilder[]
}



- (void) dontTestSelect {
    NSError *error;
    // tag::query-select-meta[]
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuery *query = [CBLQueryBuilder select:@[name]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression value:@"user"]] andExpression:
                                               [[CBLQueryExpression property:@"admin"] equalTo:[CBLQueryExpression boolean:NO]]]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"user name ::%@", [result stringAtIndex:0]);
    }
    // end::query-select-meta[]
}

- (void) dontTestSelectProps {
    NSError *error;
    // tag::query-select-props[]
    CBLQuerySelectResult *metaId = [CBLQuerySelectResult expression: CBLQueryMeta.id as:@"id"];
    CBLQuerySelectResult *type = [CBLQuerySelectResult property:@"type"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuery *query = [CBLQueryBuilder select:@[metaId, type, name]
                                         from:[CBLQueryDataSource database:self.database]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"document id :: %@", [result stringForKey:@"id"]);
        NSLog(@"document name :: %@", [result stringForKey:@"name"]);
    }
    // end::query-select-props[]
}

- (void) dontTestSelectAll {
    // tag::query-select-all[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:self.database]];
    // end::query-select-all[]

    NSLog(@"%@", query);
}

- (void) dontTestLiveQuery {
    // tag::live-query[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:self.database]]; // <.>

    // Adds a query change listener.
    // Changes will be posted on the main queue.
    id<CBLListenerToken> token = [query addChangeListener:^(CBLQueryChange  *change) { // <.>
        for (CBLQueryResultSet *results in [change results]) {
            NSLog(@"%@", results);
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
    // tag::query-where[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:[CBLQueryLimit limit:[CBLQueryExpression integer:10]]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        CBLDictionary *dict = [result valueForKey:@"travel-sample"];
        NSLog(@"document name ::%@", [dict stringForKey:@"name"]);
    }
    // end::query-where[]

    NSLog(@"%@", query);
}

- (void) dontTestQueryDeletedDocuments {
    // tag::query-deleted-documents[]
    // Query documents that have been deleted
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult expression:CBLQueryMeta.id]]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:CBLQueryMeta.isDeleted];
    // end::query-deleted-documents[]
    NSLog(@"%@", query);
}

- (void) dontTestCollectionOperatorContains {
    NSError *error;

    // tag::query-collection-operator-contains[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuerySelectResult *likes = [CBLQuerySelectResult property:@"public_likes"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]];
    CBLQueryExpression *contains = [CBLQueryArrayFunction contains:[CBLQueryExpression property:@"public_likes"]
                                                             value:[CBLQueryExpression string:@"Armani Langworth"]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, name, likes]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:contains]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"public_likes ::%@", [[result arrayForKey:@"public_likes"] toArray]);
    }
    // end::query-collection-operator-contains[]
}

- (void) dontTestCollectionOperatorIn {
    // tag::query-collection-operator-in[]
    NSArray *values = @[[CBLQueryExpression property:@"first"],
                       [CBLQueryExpression property:@"last"],
                       [CBLQueryExpression property:@"username"]];

    [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource database:self.database]
                      where:[[CBLQueryExpression string:@"Armani"] in:values]];
    // end::query-collection-operator-in[]
}

- (void) dontTestLikeOperator {
    NSError *error;
    // tag::query-like-operator[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryFunction lower:[CBLQueryExpression property:@"name"]] like:[CBLQueryExpression string:@"royal engineers museum"]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:like]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"name property ::%@", [result stringForKey:@"name"]);
    }
    // end::query-like-operator[]
}

- (void) dontTestWildCardMatch {
    // tag::query-like-operator-wildcard-match[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryFunction lower:[CBLQueryExpression property:@"name"]] like:[CBLQueryExpression string:@"eng%e%"]];

    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:like]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-like-operator-wildcard-match[]

    NSLog(@"%@", query);
}

- (void) dontTestWildCardCharacterMatch {
    // tag::query-like-operator-wildcard-character-match[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *like = [[CBLQueryExpression property:@"name"] like:[CBLQueryExpression string:@"eng____r"]];

    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, country, name]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:like]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-like-operator-wildcard-character-match[]

    NSLog(@"%@", query);
}

- (void) dontTestRegexMatch {
    // tag::query-regex-operator[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *regex = [[CBLQueryExpression property:@"name"] regex:[CBLQueryExpression string:@"\\bEng.*e\\b"]];

    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, name]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:regex]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-regex-operator[]

    NSLog(@"%@", query);
}

- (void) dontTestJoin {
    // tag::query-join[]
    CBLQuerySelectResult *name = [CBLQuerySelectResult
                                  expression:[CBLQueryExpression property:@"name" from:@"airline"]];
    CBLQuerySelectResult *callsign = [CBLQuerySelectResult
                                      expression:[CBLQueryExpression property:@"callsign" from:@"airline"]];
    CBLQuerySelectResult *dest = [CBLQuerySelectResult
                                  expression:[CBLQueryExpression property:@"destinationairport" from:@"route"]];
    CBLQuerySelectResult *stops = [CBLQuerySelectResult
                                   expression:[CBLQueryExpression property:@"stops" from:@"route"]];
    CBLQuerySelectResult *airline = [CBLQuerySelectResult
                                     expression:[CBLQueryExpression property:@"airline" from:@"route"]];

    CBLQueryJoin *join = [CBLQueryJoin join:[CBLQueryDataSource database:self.database
                                                                      as:@"route"]
                                         on:[[CBLQueryMeta idFrom:@"airline"]
                                             equalTo:[CBLQueryExpression property:@"airlineid"
                                                                             from:@"route"]]];

    CBLQueryExpression *typeRoute = [[CBLQueryExpression property:@"type" from:@"route"]
                                     equalTo:[CBLQueryExpression string:@"route"]];
    CBLQueryExpression *typeAirline = [[CBLQueryExpression property:@"type" from:@"airline"]
                                       equalTo:[CBLQueryExpression string:@"airline"]];
    CBLQueryExpression *sourceRIX = [[CBLQueryExpression property:@"sourceairport" from:@"route"]
                                     equalTo:[CBLQueryExpression string:@"RIX"]];

    CBLQuery *query = [CBLQueryBuilder select:@[name, callsign, dest, stops, airline]
                                         from:[CBLQueryDataSource database:self.database as:@"airline"]
                                         join:@[join]
                                        where:[[typeRoute andExpression:typeAirline] andExpression:sourceRIX]];
    // end::query-join[]

    NSLog(@"%@", query);
}

- (void) dontTestGroupBy {
    // tag::query-groupby[]
    CBLQuerySelectResult *count = [CBLQuerySelectResult expression:[CBLQueryFunction count:[CBLQueryExpression all]]];
    CBLQuerySelectResult *country = [CBLQuerySelectResult property:@"country"];
    CBLQuerySelectResult *tz = [CBLQuerySelectResult property:@"tz"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"airport"]];
    CBLQueryExpression *geoAlt = [[CBLQueryExpression property:@"geo.alt"] greaterThanOrEqualTo:[CBLQueryExpression integer:300]];

    CBLQuery *query = [CBLQueryBuilder select:@[count, country, tz]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[type andExpression:geoAlt]
                                      groupBy:@[[CBLQueryExpression property:@"country"],
                                                [CBLQueryExpression property:@"tz"]]];
    // end::query-groupby[]

    NSLog(@"%@", query);
}

- (void) dontTestOrderBy {
    // tag::query-orderby[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *title = [CBLQuerySelectResult property:@"title"];

    CBLQuery *query = [CBLQueryBuilder select:@[id, title]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]]
                                      orderBy:@[[[CBLQueryOrdering property:@"title"] descending]]];
    // end::query-orderby[]

    NSLog(@"%@", query);
}


- (void) dontTestExplainAll {
    NSError *error;
    // tag::query-explain-all[]
    CBLQuery *query =
        [CBLQueryBuilder
            select:@[[CBLQuerySelectResult all]]
            from:[CBLQueryDataSource database:self.database]
            where:[[CBLQueryExpression property:@"type"]
                   equalTo:[CBLQueryExpression string:@"university"]]
//            groupBy:@[[CBLQueryExpression property:@"country"]] // <.>
                          orderBy:@[[[CBLQueryOrdering property:@"title"] descending]] // <.>
       ];

    NSLog(@"%@", [query explain:&error]); // <.>

      // end::query-explain-all[]
}
- (void) dontTestExplainLike {
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
            from:[CBLQueryDataSource database:self.database]
            where:[type andExpression:name]
        ];
      NSLog(@"%@", [query explain:&error]); // <.>

      // end::query-explain-like[]

}
- (void) dontTestExplainNoPfx {
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
            from:[CBLQueryDataSource database:self.database]
            where:[type andExpression:name]
        ];

    NSLog(@"%@", [query explain:&error]);

    // end::query-explain-nopfx[]
}

- (void) dontTestExplainFunction {
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
                from:[CBLQueryDataSource database:self.database]
                where:[type andExpression:name]];

    NSLog(@"%@", [query explain:&error]);

    // end::query-explain-function[]
}

- (void) dontTestExplainNoFunction {
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
            from:[CBLQueryDataSource database:self.database]
            where:[type andExpression:name]
        ];

    NSLog(@"%@", [query explain:&error]);

      // end::query-explain-nofunction[]

}



- (void) dontTestCreateFullTextIndex {
    NSError *error;

    // tag::fts-index[]
    // Insert documents
    NSArray *overviews = @[@"buy groceries", @"play chess", @"book travels", @"buy museum tickets"];
    for (NSString *overview in overviews) {
        CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
        [doc setString:@"task" forKey:@"type"];
        [doc setString:overview forKey:@"overview"];
        [self.database saveDocument:doc error:&error];
    }

    // Create index
    CBLFullTextIndexConfiguration* config =
        [[CBLFullTextIndexConfiguration alloc]
            initWithExpression: @[@"overview"]
            ignoreAccents: NO language: nil];

    [self.database createIndexWithConfig: config
            name: @"overviewFTSIndex" error: &error];

    // end::fts-index[]
}

- (void) dontTestFullTextSearch {
    NSError *error;

    // tag::fts-query[]
    NSString *ftsQueryString =
    @"SELECT META().id FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)";

    CBLQueryResultSet *resultSet = [ftsQuery execute:&error];
    NSArray* results  = [resultSet allResults];
    for (CBLQueryResult *result in results) {
        NSLog(@"document id %@", [result stringAtIndex:0]);
    }
    // end::fts-query[]
}




- (void) dontTestCreateFullTextIndex_Querybuilder {
    NSError *error;

    // tag::fts-index_Querybuilder[]
    // Insert documents
    NSArray *tasks = @[@"buy groceries", @"play chess", @"book travels", @"buy museum tickets"];
    for (NSString *task in tasks) {
        CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
        [doc setString:@"task" forKey:@"type"];
        [doc setString:task forKey:@"name"];
        [self.database saveDocument:doc error:&error];
    }

    // Create index
    CBLFullTextIndex *index = [CBLIndexBuilder fullTextIndexWithItems:@[[CBLFullTextIndexItem property:@"name"]]];
    index.ignoreAccents = NO;
    [self.database createIndex:index withName:@"nameFTSIndex" error:&error];
    // end::fts-index_Querybuilder[]
}

- (void) dontTestFullTextSearch_Querybuilder {
    NSError *error;

    // tag::fts-query_Querybuilder[]
    CBLQueryExpression *where = [CBLQueryFullTextFunction matchWithIndexName:@"nameFTSIndex"
                                                                       query:@"'buy'"];
    CBLQuery *query =
      [CBLQueryBuilder
        select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
        from:[CBLQueryDataSource database:self.database]
        where:where];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"document id %@", [result stringAtIndex:0]);
    }
    // end::fts-query_Querybuilder[]
}









#pragma mark - Replication

/* The `tag::replication[]` example is inlined in objc.adoc */

- (void) dontTestEnableReplicatorLogging {
    // tag::replication-logging[]
    // Replicator
    CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    CBLDatabase.log.console.domains = kCBLLogDomainReplicator;

    // Network
    CBLDatabase.log.console.level = kCBLLogLevelVerbose;
    CBLDatabase.log.console.domains = kCBLLogDomainNetwork;
    // end::replication-logging[]
}

- (void) dontTestReplicationBasicAuthentication {
    // tag::basic-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::basic-authentication[]
}

- (void) dontTestReplicationSessionAuthentication {
    // tag::session-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    config.authenticator = [[CBLSessionAuthenticator alloc] initWithSessionID:@"904ac010862f37c8dd99015a33ab5a3565fd8447"];

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::session-authentication[]
}

- (void) dontTestReplicatorStatus {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::replication-status[]
    [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
        }
    }];
    // end::replication-status[]
}


//  BEGIN PendingDocuments IB -- 11/Feb/21 --
- (void) testReplicationPendingDocs {
    // tag::replication-pendingdocuments[]

    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                       target:target];

    config.replicatorType = kCBLReplicatorTypePush;

    // tag::replication-push-pendingdocumentids[]
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // Get list of pending doc IDs
    NSError *err = nil;
    NSSet *pendingDocIds = [self.replicator pendingDocumentIDs:&err]; // <.>

    // end::replication-push-pendingdocumentids[]

    if ([pendingDocIds count] > 0) {

        NSLog(@"There are %lu documents pending", (unsigned long)[pendingDocIds count]);

        [self.replicator addChangeListener:^(CBLReplicatorChange *change) {

            NSLog(@"Replicator activity level is %u", change.status.activity);
            // iterate and report-on the pending doc IDs  in 'mydocids'
            for (NSString *docID in pendingDocIds) {

                // tag::replication-push-isdocumentpending[]
                NSError *err = nil;
                if (![change.replicator isDocumentPending:docID error:&err]) { // <.>
                    NSLog(@"Doc ID %@ now pushed", docID);
                }
                // end::replication-push-isdocumentpending[]
            }

        }];
        [self.replicator start];

    };

    // end::replication-pendingdocuments[]
}
//  END PendingDocuments IB -- 11/Feb/21 --


- (void) dontTestReplicatorDocumentEvent {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::add-document-replication-listener[]
    id token = [self.replicator addDocumentReplicationListener:^(CBLDocumentReplication  *replication) {
        NSLog(@"Replication type ::%@", replication.isPush ? @"Push" :@"Pull");
        for (CBLReplicatedDocument *document in replication.documents) {
            if (document.error == nil) {
                NSLog(@"Doc ID ::%@", document.id);
                if ((document.flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
                    NSLog(@"Successfully replicated a deleted document");
                }
            } else {
                // There was an error
            }
        }
    }];

    [self.replicator start];
    // end::add-document-replication-listener[]

    // tag::remove-document-replication-listener[]
    [self.replicator removeChangeListenerWithToken:token];
    // end::remove-document-replication-listener[]
}

// tag::sgw-act-rep-network-interface[]
- (void) dontTestCustomReplicationNetworkInterface {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *endpoint = [[CBLURLEndpoint alloc] initWithURL:url];

        // tag::replication-custom-header[]
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:endpoint];
    config.networkInterface = @"en0";
        // end::replication-custom-header[]
}

// end::sgw-act-rep-network-interface[]

- (void) dontTestCustomReplicationHeader {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *endpoint = [[CBLURLEndpoint alloc] initWithURL:url];

    // tag::replication-custom-header[]
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:endpoint];
    config.headers = @{@"CustomHeaderName" :@"Value"};
    // end::replication-custom-header[]
}

- (void) dontTestHandlingReplicationError {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::replication-error-handling[]
    [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code:%ld", change.status.error.code);
        }
    }];
    // end::replication-error-handling[]
}

- (void) dontTestReplicationResetCheckpoint {
    BOOL restCheckpoint = NO;
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // tag::replication-reset-checkpoint[]
    if (restCheckpoint)
        [self.replicator startWithReset:restCheckpoint]; // <.>

    // end::replication-reset-checkpoint[]
}

- (void) dontTestReplicationPushFilter {
    // tag::replication-push-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    config.pushFilter = ^BOOL(CBLDocument *document, CBLDocumentFlags flags) { // <1>
        if ([[document stringForKey:@"type"] isEqualToString:@"draft"]) {
            return false;
        }
        return true;
    };

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::replication-push-filter[]
}

- (void) dontTestReplicationPullFilter {

    // tag::replication-pull-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    config.pullFilter = ^BOOL(CBLDocument *document, CBLDocumentFlags flags) { // <1>
        if ((flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
            return false;
        }
        return true;
    };

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::replication-pull-filter[]
}

//  Added 2/Feb/21 - Ian Bridge
- (void) dontTestCustomRetryConfig {
    // tag::replication-retry-config[]
    id target = [[CBLURLEndpoint alloc] initWithURL:[NSURL URLWithString:@"ws://foo.cbl.com/db"]];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                       target:target];
    config.replicatorType = kCBLReplicatorTypePush;
    config.continuous = YES;
    //  other config as required . . .

    // tag::replication-heartbeat[]
    config.heartbeat = 150; // <.>

    // end::replication-heartbeat[]
    // tag::replication-maxattempts[]
    config.maxAttempts = 20; // <.>

    // end::replication-maxattempts[]
    // tag::replication-maxattemptwaittime[]
    config.maxAttemptWaitTime = 600; // <.>

    // end::replication-maxattemptwaittime[]
    //  other config as required . . .
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // end::replication-retry-config[]
}


#ifdef COUCHBASE_ENTERPRISE
- (void) dontTestDatabaseReplica {
    /* EE feature:code below might throw a compilation error
     if it's compiled against CBL Swift Community. */
    // tag::database-replica[]
    CBLDatabaseEndpoint *targetDatabase = [[CBLDatabaseEndpoint alloc] initWithDatabase:self.otherDB];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:targetDatabase];
    config.replicatorType = kCBLReplicatorTypePush;

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::database-replica[]
}
#endif

- (void) dontTestCertificatePinning {
    // Active - Example 4
    // tag::certificate-pinning[]
    // tag::p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                       target:target];
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);

    // end::p2p-act-rep-config-cacert-pinned[]
    // end::certificate-pinning[]
    NSLog(@"%@", config);
}

- (NSData*) dataFromResource:(NSString*)file ofType:(NSString*)type {
    return [NSData data];
}

- (void) dontTestGettingStarted {
    // tag::getting-started[]
    // Get the database (and create it if it doesn’t exist).
    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // Create a new document (i.e. a record) in the database.
    CBLMutableDocument *mutableDoc = [[CBLMutableDocument alloc] init];
    [mutableDoc setFloat:2.0 forKey:@"version"];
    [mutableDoc setString:@"SDK" forKey:@"type"];

    // Save it to the database.
    [self.database saveDocument:mutableDoc error:&error];

    // Update a document.
    CBLMutableDocument *mutableDoc2 = [[self.database documentWithID:mutableDoc.id] toMutable];
    [mutableDoc2 setString:@"Swift" forKey:@"language"];
    [self.database saveDocument:mutableDoc2 error:&error];

    CBLDocument *document = [self.database documentWithID:mutableDoc2.id];
    // Log the document ID (generated by the database)
    // and properties
    NSLog(@"Document ID ::%@", document.id);
    NSLog(@"Learning %@", [document stringForKey:@"language"]);

    // Create a query to fetch documents of type SDK.
    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"SDK"]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                          from:[CBLQueryDataSource database:self.database]
                                         where:type];

    // Run the query
    CBLQueryResultSet *results = [query execute:&error];
    NSLog(@"Number of rows ::%lu", (unsigned long)[[results allResults] count]);

    // Create replicators to push and pull changes to and from the cloud.
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
    CBLURLEndpoint *targetEndpoint = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                           target:targetEndpoint];
    config.replicatorType = kCBLReplicatorTypePushAndPull;

    // Add authentication.
    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

    // Create replicator (make sure to add an ivar)
    self.replicator = [[CBLReplicator alloc] initWithConfig:config];

    // Listen to replicator change events.
    [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code:%ld", change.status.error.code);
        }
    }];

    // Start replication
    [self.replicator start];
    // end::getting-started[]
}

- (void) dontTestPredictiveModel {
    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::register-model[]
    ImageClassifierModel *model = [[ImageClassifierModel alloc] init];
    [[CBLDatabase prediction] registerModel:model withName:@"ImageClassifier"];
    // end::register-model[]

    // tag::predictive-query-value-index[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction *prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input];

    CBLValueIndex *index = [CBLIndexBuilder valueIndexWithItems:@[[CBLValueIndexItem expression:[prediction property:@"label"]]]];
    [self.database createIndex:index withName:@"value-index-image-classifier" error:&error];
    // end::predictive-query-value-index[]

    // tag::unregister-model[]
    [[CBLDatabase prediction] unregisterModelWithName:@"ImageClassifier"];
    // end::unregister-model[]
}

- (void) dontTestPredictiveIndex {
    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::predictive-query-predictive-index[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];

    CBLPredictiveIndex *index = [CBLIndexBuilder predictiveIndexWithModel:@"ImageClassifier" input:input properties:nil];
    [self.database createIndex:index withName:@"predictive-index-image-classifier" error:&error];
    // end::predictive-query-predictive-index[]
}

- (void) dontTestPredictiveQuery {
    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::predictive-query[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction *prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input]; // <1>

    CBLQueryExpression *condition = [[[prediction property:@"label"] equalTo:[CBLQueryExpression string:@"car"]]
                                     andExpression:[[prediction property:@"probablity"] greaterThanOrEqualTo:[CBLQueryExpression double:0.8]]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:condition];

    // Run the query.
    CBLQueryResultSet *results = [query execute:&error];
    NSLog(@"Number of rows ::%lu", (unsigned long)[[results allResults] count]);
    // end::predictive-query[]
}

- (void) dontTestCoreMLPredictiveModel {
    NSError *error;

    // tag::coreml-predictive-model[]
    // Load MLModel from `ImageClassifier.mlmodel`
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ImageClassifier" withExtension:@"mlmodel"];
    NSURL *compiledModelURL = [MLModel compileModelAtURL:modelURL error:&error];
    MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&error];
    CBLCoreMLPredictiveModel *predictiveModel = [[CBLCoreMLPredictiveModel alloc] initWithMLModel:model];

    // Register model
    [[CBLDatabase prediction] registerModel:predictiveModel withName:@"ImageClassifier"];
    // end::coreml-predictive-model[]
}

- (void) dontTestReplicatorConflictResolver {
    NSError *error;
    self.database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

    // tag::replication-conflict-resolver[]
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database target:target];
    config.conflictResolver = [[LocalWinConflictResolver alloc] init];

    self.replicator = [[CBLReplicator alloc] initWithConfig:config];
    [self.replicator start];
    // end::replication-conflict-resolver[]
}

- (void) dontTestSaveWithConflictHandler {
    NSError *error;

    // tag::update-document-with-conflict-handler[]
    CBLDocument *document = [self.database documentWithID:@"xyz"];
    CBLMutableDocument *mutableDocument = [document toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];

    [self.database saveDocument:mutableDocument
           conflictHandler:^BOOL(CBLMutableDocument *new, CBLDocument *current) {
               NSDictionary *currentDict = current.toDictionary;
               NSDictionary *newDict = new.toDictionary;

               NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:currentDict];
               [result addEntriesFromDictionary:newDict];
               [new setData:result];
               return YES;
           }
                     error:&error];
    // end::update-document-with-conflict-handler[]
}

#pragma mark - URLListener

- (BOOL) isValidCredentials:(NSString*)u password:(NSString*)p { return YES; } // helper
- (BOOL) isValidCertificates:(NSArray*)certs { return YES; } // helper

- (void) dontTestInitListener {
    // tag::init-urllistener[]
    CBLURLEndpointListenerConfiguration *config;
    config = [[CBLURLEndpointListenerConfiguration alloc] initWithDatabase:self.database];
    config.tlsIdentity = nil; // Use with anonymous self signed cert
    config.authenticator = [[CBLListenerPasswordAuthenticator alloc]
                            initWithBlock:^BOOL( NSString *username, NSString *password) {
        return [self isValidCredentials:username password:password];
    }];

    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:config];
    // end::init-urllistener[]
}

- (void) dontTestListenerStart {
    NSError *error = nil;

    // tag::start-urllistener[]
    BOOL success = [self.listener startWithError:&error];
    if (!success) {
        NSLog(@"Cannot start the listener:%@", error);
    }
    // end::start-urllistener[]
}

- (void) dontTestListenerStop {
    // tag::stop-urllistener[]
    [self.listener stop];
    // end::stop-urllistener[]
}

- (void) dontTestCreateSelfSignedCert {
    NSError *error = nil;
    CBLTLSIdentity *identity = nil;
    // <site-rooot>/objc/advance/objc-p2psync-websocket-using-passive.html
    // Example-6
    // tag::create-self-signed-cert[]
    // tag::listener-config-tls-id-SelfSigned[]

    NSDictionary *attrs = @{ kCBLCertAttrCommonName:@"Couchbase Inc" };
    identity =
      [CBLTLSIdentity createIdentityForServer:YES /* isServer */
        attributes:attrs
        expiration:[NSDate dateWithTimeIntervalSinceNow:86400]
        label:@"Server-Cert-Label"
        error:&error];
    // end::listener-config-tls-id-SelfSigned[]
    // end::create-self-signed-cert[]
}

- (void) dontTestListenerCertificateAuthenticatorRootCert {
    CBLURLEndpointListenerConfiguration *config;

    // Example 8-tab1
    // tag::listener-certificate-authenticator-root-urllistener[]
    // tag::listener-config-client-auth-root[]

    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef rootCertRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    config.authenticator = [[CBLListenerCertificateAuthenticator alloc]
                            initWithRootCerts:@[(id)CFBridgingRelease(rootCertRef)]];
    // end::listener-config-client-auth-root[]
    // end::listener-certificate-authenticator-root-urllistener[]
}

- (void) dontTestListenerCertificateAuthenticatorCallback {
    CBLURLEndpointListenerConfiguration *config;
    // Example 8-tab2
    // tag::listener-certificate-authenticator-callback-urllistener[]
    // tag::listener-config-client-auth-lambda[]

    CBLListenerCertificateAuthenticator *listenerAuth =
    [[CBLListenerCertificateAuthenticator alloc] initWithBlock:^BOOL(NSArray *certs) {
        return [self isValidCertificates:certs];
    }];

    config.authenticator = listenerAuth;
    // end::listener-config-client-auth-lambda[]
    // end::listener-certificate-authenticator-callback-urllistener[]
}

# pragma mark - QUERY RESULT SET HANDLING EXAMPLES

- (void) dontTestQuerySyntaxJson {
    // tag::query-syntax-all[]
    NSError *error;

    CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error:&error];

    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                             from:[CBLQueryDataSource database:db]]; // <.>

    // end::query-syntax-all[]


    // tag::query-access-all[]
    CBLQueryResultSet *results = [query execute:&error];

    for (CBLQueryResult *result in results) {

        NSDictionary *data = [result valueAtIndex:0];

        // Use dictionary values
        NSLog(@"id = %@", [data valueForKey:@"id"]);
        NSLog(@"name = %@", [data valueForKey:@"name"]);
        NSLog(@"type = %@", [data valueForKey:@"type"]);
        NSLog(@"city = %@", [data valueForKey:@"city"]);

    } // end for

    // end::query-access-all[]

    // tag::query-access-json[]
    CBLQueryResultSet *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {

        // Get result as a JSON string
        NSString *json = [result toJSON]; // <.>

        // Get an native Obj-C object from the Json String
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&error]; // <.>

        // Log generated Json and Native objects
        // For demo/example purposes
        NSLog(@"Json String %@", json);
        NSLog(@"Native Object %@", dict);

    }; // end for

    // end::query-access-json[]

} // end function

- (void) dontTestQuerySyntaxAndAccessProps {
    NSError *error = nil;

    // tag::query-syntax-props[]
    CBLDatabase *db = [[CBLDatabase alloc] initWithName:@"hotels" error:&error];

    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

    CBLQuerySelectResult *type = [CBLQuerySelectResult property:@"type"];

    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQuerySelectResult *city = [CBLQuerySelectResult property:@"city"];

    CBLQuery *query = [CBLQueryBuilder select:@[id, type, name, city]
                                         from:[CBLQueryDataSource database:db]]; // <.>
    // end::query-syntax-props[]

    // tag::query-access-props[]

    CBLQueryResultSet *results = [query execute:&error];

    for (CBLQueryResult *result in results) { // all results
        NSLog(@"id = %@", [result stringForKey:@"id"]);
        NSLog(@"name = %@", [result stringForKey:@"name"]);
        NSLog(@"type = %@", [result stringForKey:@"type"]);
        NSLog(@"city = %@", [result stringForKey:@"city"]);

    }

    // end::query-access-props[]
}

- (void) dontTestQuerySyntaxCount {
    NSError *error = nil;
    NSInteger count = 0;
    // tag::query-syntax-count-only[]
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"hotels" error:&error];

    CBLQueryExpression *countExpression = [CBLQueryFunction count:[CBLQueryExpression all]];
    CBLQuerySelectResult *selectResult = [CBLQuerySelectResult expression:countExpression
                                                                       as:@"myCount"];

    CBLQuery *query = [CBLQueryBuilder select:@[selectResult]
                                         from:[CBLQueryDataSource database:database]]; // <.>

    // tag::query-access-count-only[]
    CBLQueryResultSet *results = [query execute:&error];

    for (CBLQueryResult *result in results) {
        count = [result integerForKey:@"myCount"]; // <.>

    } // end for

    // end::query-access-count-only[]

    // end::query-syntax-count-only[]
    NSLog(@"print to avoid warning %@ %ld", query, count);
}

- (void) dontTestQuerySyntaxID {
    NSError *error = nil;

    // tag::query-syntax-id[]
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"hotels" error:&error];

    CBLQuerySelectResult *selectResult = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

    CBLQuery *query = [CBLQueryBuilder select:@[selectResult]
                                         from:[CBLQueryDataSource database:database]];

    // end::query-syntax-id[]
    NSLog(@"print to avoid warning %@", query);
}

- (void) dontTestQueryAccessID {
    CBLQuery *query;
    NSError *error = nil;
    // tag::query-access-id[]

    CBLQueryResultSet *results = [query execute:&error];
    CBLDocument *doc = nil;
    NSString *docId = nil;
    for (CBLQueryResult *result in results) {
        docId = [result stringForKey:@"id"]; // <.>

        // Now you can get the document using its ID
        // for example using
        doc = [self.database documentWithID:docId];

    }

    // end::query-access-id[]
    NSLog(@"doc.id = %@", doc.id);
}

- (void) dontTestQuerySyntaxPagination {
    // tag::query-syntax-pagination[]
    int offset = 0;
    int limit = 20;

    CBLQueryLimit *queryLimit = [CBLQueryLimit limit:[CBLQueryExpression integer:limit]
                                              offset:[CBLQueryExpression integer:offset]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource database:self.database]
                                        where:nil
                                      groupBy:nil
                                       having:nil
                                      orderBy:nil
                                        limit:queryLimit];
    // end::query-syntax-pagination[]
    NSLog(@"print to avoid warning %@", query);
}

- (void) dontTestDocsOnly_QuerySyntaxN1QL {
    // Documentation Only query-syntax-n1ql
    NSError *error;

    // tag::query-syntax-n1ql[]
    NSString *queryString = @"SELECT * FROM _ WHERE type = \"hotel\""; // <.>

    CBLQuery *query = [self.database createQuery:queryString];

    CBLQueryResultSet *results = [query execute:&error];

    // end::query-syntax-n1ql[]
    NSLog(@"resultset.count = %lu", (unsigned long)results.allResults.count);
}

- (void) dontTestDocsOnly_QuerySyntaxN1QLParams {
    // Documentation Only query-syntax-n1ql-params
    NSError *error;

    // tag::query-syntax-n1ql-params[]
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM _ WHERE type = $type"]; // <.>

    CBLQuery *query = [self.database createQuery:queryString];

    CBLQueryParameters *params = [[CBLQueryParameters alloc] init];
    [params setString:@"hotel" forName:@"type"]; // <.>
    query.parameters = params;

    CBLQueryResultSet *results =  [query execute:&error];

    // end::query-syntax-n1ql-params[]
    NSLog(@"resultset.count = %lu", (unsigned long)results.allResults.count);
}

#pragma mark - PEER-to-PEER

- (void) dontTestListenerSimple {
    NSError *error = nil;

    // tag::listener-simple[]
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithDatabase:self.database]; // <.>

    config.authenticator = [[CBLListenerPasswordAuthenticator alloc]
                                initWithBlock:^BOOL(NSString  *validUser, NSString  *validPassword) {
        return [self isValidCredentials:validUser password:validPassword];
    }]; // <.>

    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:config]; // <.>

    BOOL success = [self.listener startWithError:&error];
    if (!success) {
        NSLog(@"Cannot start the listener:%@", error);
    } // <.>

    // end::listener-simple[]
}

- (void) dontTestReplicatorSimple {
    // tag::replicator-simple[]
    NSURL *url = [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *endpoint = [[CBLURLEndpoint alloc] initWithURL:url]; // <.>

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                       target:endpoint]; // <.>

    config.acceptOnlySelfSignedServerCertificate = YES; // <.> //FIXME: Remove this from doc!

    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"valid.user"
                                                                  password:@"valid.password.string"]; // <.>


    self.replicator = [[CBLReplicator alloc] initWithConfig:config]; // <.>

    [self.replicator start]; // <.>

    // end::replicator-simple[]
}

- (void) dontTestP2PURLEndpointListener {
    // tag::p2p-ws-api-urlendpointlistener[]
    // FIXME: can we use the docsn site to show the interface of the Listener class?
    // https://docs.couchbase.com/mobile/2.8.0/couchbase-lite-objc/Classes/CBLURLEndpointListener.html
    // end::p2p-ws-api-urlendpointlistener[]
}

- (void) dontTestURLEndpointListenerConstructor {
    NSUInteger wssPort = 4985;
    NSUInteger wsPort = 4984;
    BOOL isTLS = NO;
    CBLListenerPasswordAuthenticator *auth = [[CBLListenerPasswordAuthenticator alloc]
                                              initWithBlock:^BOOL(NSString *username, NSString *password) {
        return YES;
    }];

    // tag::p2p-ws-api-urlendpointlistener-constructor[]
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc] initWithDatabase:self.otherDB];
    config.port = isTLS ? wssPort :wsPort;
    config.disableTLS = !isTLS;
    config.authenticator = auth;

    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:config]; // <1>
    // end::p2p-ws-api-urlendpointlistener-constructor[]
}

- (void) dontTestMyActivePeer {
    NSError *error = nil;
    self.database = [[CBLDatabase alloc] initWithName:@"database" error:&error];
    if (!self.database) {
        NSLog(@"Cannot open the database:%@", error);
    };

    // tag::p2p-act-rep-func[]
    // tag::p2p-act-rep-initialize[]
    // Set listener DB endpoint
    NSURL *url = [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *endpoint = [[CBLURLEndpoint alloc] initWithURL:url]; // <.>

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc]
                                          initWithDatabase:self.database target:endpoint]; // <.>

    // end::p2p-act-rep-initialize[]
    // tag::p2p-act-rep-config[]
    // tag::p2p-act-rep-config-type[]
    config.replicatorType = kCBLReplicatorTypePush;

    // end::p2p-act-rep-config-type[]
    // tag::autopurge-override[]
    // set auto-purge behavior (here we override default)
    config.enableAutoPurge = NO; // <.>

    // end::autopurge-override[]
    // tag::p2p-act-rep-config-cont[]
    config.continuous = YES;

    // end::p2p-act-rep-config-cont[]
    // tag::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Authentication
    // Here - expect and accept self-signed certs
    config.acceptOnlySelfSignedServerCertificate = YES; // <.>

    // end::p2p-act-rep-config-self-cert[]
    // Configure Client Authentication
    // tag::p2p-act-rep-auth[]
    // Here set client to use basic authentication
    // Providing username and password credentials
    // If prompted for them by server
    config.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"Our Username" password:@"Our Password"]; // <.>

    // end::p2p-act-rep-auth[]
    // end::p2p-act-rep-config-tls-full[]
    // tag::p2p-act-rep-config-conflict[]
    /* Optionally set custom conflict resolver call back */
    config.conflictResolver = [[LocalWinConflictResolver alloc] init]; // <.>

    // end::p2p-act-rep-config-conflict[]    //
    // end::p2p-act-rep-config[]
    // tag::p2p-act-rep-start-full[]
    // Apply configuration settings to the replicator
    self.replicator = [[CBLReplicator alloc] initWithConfig:config]; // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-add-change-listener-label[]
    // Optionally add a change listener <.>
    // end::p2p-act-rep-add-change-listener-label[]
    // Retain token for use in deletion
    id<CBLListenerToken> listenerToken = [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        // tag::p2p-act-rep-status[]
        if (change.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
        } else {
            NSLog(@"Status:%d", change.status.activity);
        };
        // end::p2p-act-rep-status[]
    }];
    // end::p2p-act-rep-add-change-listener[]
    // tag::p2p-act-rep-start[]
    // Run the replicator using the config settings
    [self.replicator start]; // <.>

    // end::p2p-act-rep-start[]
    // end::p2p-act-rep-start-full[]
    // end::p2p-act-rep-func[]

    NSLog(@"print to avoid warning %@", listenerToken);
}

- (void) dontTestReplicatorStop {
    id<CBLListenerToken> listenerToken;

    // tag::p2p-act-rep-stop[]
    // Remove the change listener
    [self.replicator removeChangeListenerWithToken:listenerToken];

    // Stop the replicator
    [self.replicator stop];
    // end::p2p-act-rep-stop[]

}

// Additional Snippets from above

- (void) dontTestReplicatorConfigCerts {
    CBLReplicatorConfiguration *config;
    SecCertificateRef cert;
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA Certs
    config.acceptOnlySelfSignedServerCertificate = NO; // <.>

    // end::p2p-act-rep-config-cacert[]


    // tag::p2p-act-rep-config-pinnedcert[]
    // Return the remote pinned cert (the listener's cert)
    config.pinnedServerCertificate = cert; // Get listener cert if pinned

    // end::p2p-act-rep-config-pinnedcert[]

}

// tag::p2p-act-rep-config-cacert-pinned-func[]
- (void) dontTestCACertPinned {
    // tag::p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:self.database
                                                                                       target:target];
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);

    config.acceptOnlySelfSignedServerCertificate=false;

  // end::p2p-act-rep-config-cacert-pinned[]

}
// end::p2p-act-rep-config-cacert-pinned-func[]

#pragma mark - Listener

- (void) dontTestListener {
    NSError *error = nil;

    // tag::listener-initialize[]
    // tag::listener-config-db[]
    // Initialize the listener config <.>
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithDatabase:self.database];

    // end::listener-config-db[]
    // tag::listener-config-port[]
    config.port =  55990; // <.>

    // end::listener-config-port[]
    // tag::listener-config-netw-iface[]
    config.networkInterface = @"10.1.1.10"; // <.>

    // end::listener-config-netw-iface[]
    // tag::listener-config-delta-sync[]
    config.enableDeltaSync = true; // <.>

    // end::listener-config-delta-sync[]
    // Configure server security
    // tag::listener-config-tls-enable[]
    config.disableTLS  = false; // <.>

    // end::listener-config-tls-enable[]

    // tag::listener-config-tls-id-anon[]
    // Use an anonymous self-signed cert
    config.tlsIdentity = nil; // <.>

    // end::listener-config-tls-id-anon[]
    // tag::listener-config-client-auth-pwd[]
    // Configure Client Security using an Authenticator
    // For example, Basic Authentication <.>
    config.authenticator = [[CBLListenerPasswordAuthenticator alloc]
                            initWithBlock:^BOOL(NSString *username, NSString *password) {
        return [self isValidCredentials:username password:password];
    }];

    // end::listener-config-client-auth-pwd[]
    // tag::listener-start[]
    // tag::listener-init[]
    // Initialize the listener <.>
    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:config];

    // end::listener-init[]
    // start the listener <.>
    BOOL success = [self.listener startWithError:&error];
    if (!success) {
        NSLog(@"Cannot start the listener:%@", error);
    }

    // end::listener-start[]
    // end::listener-initialize[]

    // tag::listener-stop[]
    [self.listener stop];

    // end::listener-stop[]
}

- (void) dontTestListenerGetNetworkInterfaces {
    // tag::listener-get-network-interfaces[]
    // . . .  code snippet to be provided

    // end::listener-get-network-interfaces[]
}

- (void) dontTestListenerGetURLList {
    NSError *error = nil;
    // tag::listener-get-url-list[]
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithDatabase:self.otherDB];
    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:config];

    [self.listener startWithError:&error];

    NSLog(@"%@", self.listener.urls);

    // end::listener-get-url-list[]
}

- (void) dontTestlistenerConfigClientAuth {
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithDatabase:self.database];
    // EXAMPLE 8
    // tag::listener-config-client-auth-root[]
    // Configure the client authenticator
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"p12"]; // <.>
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef rootCertRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    config.authenticator = [[CBLListenerCertificateAuthenticator alloc]
                            initWithRootCerts:@[(id)CFBridgingRelease(rootCertRef)]];  // <.> <.>

    // end::listener-config-client-auth-root[]
}

- (void) dontTestListenerLocalDB {
    NSError *error = nil;
    SecCertificateRef cert;
    // tag::listener-local-db[]
    // . . . preceding application logic . . .
    // FIXME: anything??
    // Include websockets listener initializer code
    // end::listener-local-db[]

    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithDatabase:self.otherDB];
    // tag::listener-config-tls-full[]
    // Configure server authentication
    // tag::listener-config-tls-disable[]
    config.disableTLS  = true; // <.>

    // end::listener-config-tls-disable[]

    // EXAMPLE 6
    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-caCert[]
    // Use CA Cert
    // Create a TLSIdentity from a key-pair and
    // certificate in secure storage
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"p12"]; // <.>

    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    CBLTLSIdentity *tlsIdentity = [CBLTLSIdentity importIdentityWithData:data
                                                                password:@"123"
                                                                   label:@"couchbase-docs-cert"
                                                                   error:&error]; // <.>

    config.tlsIdentity = tlsIdentity; // <.>

    // end::listener-config-tls-id-caCert[]
    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    NSDictionary *attrs = @{ kCBLCertAttrCommonName:@"Couchbase Inc" }; // <.>

    tlsIdentity = [CBLTLSIdentity createIdentityForServer:YES /* isServer */
                                               attributes:attrs
                                               expiration:[NSDate dateWithTimeIntervalSinceNow:86400]
                                                    label:@"couchbase-docs-cert"
                                                    error:&error]; // <.>

    // end::listener-config-tls-id-SelfSigned[]
    // tag::listener-config-tls-id-set[]
    // set the TLS Identity
    config.tlsIdentity = tlsIdentity; // <.>

    // end::listener-config-tls-id-set[]
    // end::listener-config-tls-id-full[]
    // end::listener-config-tls-full[]


    // tag::listener-config-client-auth-lambda[]
    // Authenticate self-signed cert
    // using application logic
    CBLListenerCertificateAuthenticator *authenticator = [[CBLListenerCertificateAuthenticator alloc]
                                                          initWithBlock:^BOOL(NSArray *certs) {
        return [self isValidCertificates:certs];
    }];  // <.>

    config.authenticator = authenticator; // <.>

    // end::listener-config-client-auth-lambda[]


    // tag::xlistener-config-tls-disable[]
    config.disableTLS  = YES;

    // end::xlistener-config-tls-disable[]

    // tag::listener-config-tls-id-nil[]
    config.tlsIdentity = nil;

    // end::listener-config-tls-id-nil[]


    // tag::old-listener-config-delta-sync[]
    config.enableDeltaSync = YES;

    // end::old-listener-config-delta-sync[]


    // tag::listener-status-check[]
    NSUInteger totalConnections = self.listener.status.connectionCount;
    NSUInteger activeConnections = self.listener.status.activeConnectionCount;

    // end::listener-status-check[]
    NSLog(@"Connection status = %lu/%lu", activeConnections,totalConnections);


    // tag::old-listener-config-client-auth-root[]
    // cert is a pre-populated object of type:SecCertificate representing a certificate
    CFDataRef rootCertData = SecCertificateCopyData(cert);
    CFAutorelease(rootCertData);
    SecCertificateRef rootCert = SecCertificateCreateWithData(NULL, rootCertData);

    // Listener:
    config.authenticator = [[CBLListenerCertificateAuthenticator alloc]
                            initWithRootCerts:@[(id)CFBridgingRelease(rootCert)]];

    // end::old-listener-config-client-auth-root[]

    // tag::listener-config-client-auth-self-signed[]
    config.authenticator = [[CBLListenerCertificateAuthenticator alloc] initWithBlock:^BOOL(NSArray *certs) {
        return [self isValidCertificates:certs];
    }];

    // end::listener-config-client-auth-self-signed[]
}

#pragma mark - JSON API

- (void) dontTestToJSONBlob {
    // Example 2. Using Blobs
    // tag::tojson-blob[]

    CBLDocument *doc = [self.database documentWithID:@"doc-1000"];
    CBLBlob *blob = [doc blobForKey:@"avatar"];
    NSString *json = [blob toJSON];
    NSLog(@"json string is %@", json);

    // end::tojson-blob[]
}

- (void) dontTestDictionaryAsJSON {
    NSError *error = nil;
    // Example 6. Dictionaries as JSON strings
    // tag::tojson-dictionary[]
    NSString *aJSONstring = @"{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\","
    "\"city\":\"Balmain\",\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}";


    CBLMutableDictionary *myDict = [[CBLMutableDictionary alloc] initWithJSON:aJSONstring
                                                                        error:&error];

    NSString *name = [myDict stringForKey:@"name"];

    for (NSString *key in myDict) {
        NSLog(@"%@ %@", key, [myDict valueForKey:key]);
    }

    // end::tojson-dictionary[]
    NSLog(@"%@", name);
}

- (void) dontTestToJSONDocument {
    // Example 7. Documents as JSON strings
    // tag::tojson-document[]

    CBLDocument *doc = [self.database documentWithID:@"doc-1000"];
    NSString *json = [doc toJSON];
    NSLog(@"json %@", json);

    // end::tojson-document[]
}

- (void) dontTestJSONAsArray {
    NSError *error = nil;
    // tag::tojson-array[]
    NSString *json = @"[\"1000\",\"1001\",\"1002\",\"1003\"]";

    CBLMutableArray *myArray = [[CBLMutableArray alloc] initWithJSON:json error:&error];

    for (NSString *item in myArray) {
        NSLog(@"%@", item);
    }

    // end::tojson-array[]
}

#pragma mark - SGW
- (void) dontTestSGWActiveReplicatorInitialize {
    // tag::sgw-act-rep-initialize[]
    // Set listener DB endpoint
    NSURL *url = [NSURL URLWithString:@"ws://10.0.2.2.com:55990/travel-sample"];
    CBLURLEndpoint *listener = [[CBLURLEndpoint alloc] initWithURL:url];

    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc]
                                          initWithDatabase:self.database target:listener]; // <.>

    // end::sgw-act-rep-initialize[]
    // END -- snippets --
    NSLog(@"print to aviod warning %@", config.description);
}

@end

#pragma mark -

// Singleton Pattern
// <doc>
@interface DataManager :NSObject

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
            NSLog(@"Cannot open the database:%@", error);
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
@interface ActivePeer:NSObject <CBLMessageEndpointDelegate>

@end

@interface ActivePeerConnection:NSObject <CBLMessageEndpointConnection>
- (void)disconnect;
- (void)receive:(NSData*)data;
@end

@implementation ActivePeer

- (instancetype) init {
    self = [super init];
    if (self) {
        NSError *error = nil;
        // tag::message-endpoint[]
        CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"dbname" error:&error];

        // The delegate must implement the `CBLMessageEndpointDelegate` protocol.
        NSString *id = @"";
        CBLMessageEndpoint *endpoint = [[CBLMessageEndpoint alloc] initWithUID:@"UID:123"
                                                                        target:id
                                                                  protocolType:kCBLProtocolTypeMessageStream
                                                                      delegate:self];
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc]
                                              initWithDatabase:database target:endpoint];

        // Create the replicator object.
        CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:config];
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
- (void)open:(nonnull id<CBLReplicatorConnection>)connection completion:(nonnull void (^)(BOOL, CBLMessagingError  *_Nullable))completion {
    _replicatorConnection = connection;
    completion(YES, nil);
}
// end::active-peer-open[]

// tag::active-peer-send[]
/* implementation of CBLMessageEndpointConnection */
- (void)send:(nonnull CBLMessage *)message completion:(nonnull void (^)(BOOL, CBLMessagingError  *_Nullable))completion {
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
@interface PassivePeerConnection:NSObject <CBLMessageEndpointConnection>
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
    NSError *error = nil;
    // tag::listener[]
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"mydb" error:&error];

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
    [_messageEndpointListener accept:connection];
    // end::advertizer-accept[]
}

- (void)disconnect {
    // tag::passive-replicator-close[]
    [_replicatorConnection close:nil];
    // end::passive-replicator-close[]
}

// tag::passive-peer-open[]
/* implementation of CBLMessageEndpointConnection */
- (void)open:(nonnull id<CBLReplicatorConnection>)connection completion:(nonnull void (^)(BOOL, CBLMessagingError *_Nullable))completion {
    _replicatorConnection = connection;
    completion(YES, nil);
}
// end::passive-peer-open[]

// tag::passive-peer-send[]
/* implementation of CBLMessageEndpointConnection */
- (void)send:(nonnull CBLMessage *)message completion:(nonnull void (^)(BOOL, CBLMessagingError *_Nullable))completion {
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

#pragma mark - TLS Manage Functions

// tag::p2p-tlsid-manage-func[]
//
//  cMyGetCert.swift
//  doco-sync
//
//  Created by Ian Bridge on 20/06/2020.
//  Copyright © 2020 Couchbase Inc. All rights reserved.
//

// tag::p2p-tlsid-manage-func[]
@interface MyGetCert1 :NSObject

- (CBLTLSIdentity*) fMyGetCert;

@end

@implementation MyGetCert1

- (CBLTLSIdentity*) fMyGetCert {
    NSError *error = nil;
    CBLReplicatorConfiguration *config; // FIXME: Are we sure? this is Replicator config?
    // tag::p2p-tlsid-tlsidentity-with-label[]
    // tag::p2p-tlsid-check-keychain[]
    // Check if Id exists in keychain and if so, use it
    CBLTLSIdentity *identity = [CBLTLSIdentity identityWithLabel:@"doco-sync-server" error:&error]; // <.>

    // end::p2p-tlsid-check-keychain[]
    config.authenticator = [[CBLClientCertificateAuthenticator alloc] initWithIdentity:identity]; // <.>

    // end::p2p-tlsid-tlsidentity-with-label[]

    // tag::p2p-tlsid-check-bundled[]
    // CREATE IDENTITY FROM BUNDLED RESOURCE IF FOUND

    // Check for a resource bundle with required label to generate identity from
    // return nil identify if not found
    NSString *path = [[NSBundle mainBundle] pathForResource:@"doco-sync-server" ofType:@"p12"];
    NSData *data = [NSData dataWithContentsOfFile:path
                                              options:0
                                                error:&error];
    if (!data)
        return nil;

    // end::p2p-tlsid-check-bundled[]

    // tag::p2p-tlsid-import-from-bundled[]
    // Use SecPKCS12Import to import the contents (identities and certificates)
    // of the required resource bundle (PKCS #12 formatted blob).
    //
    // Set passphrase using kSecImportExportPassphrase.
    // This passphrase should correspond to what was specified when .p12 file was created
    CFArrayRef result = NULL;
    NSDictionary *options = @{ (id)kSecImportExportPassphrase:@"couchbase" };
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)data, (__bridge CFDictionaryRef)options, &result);
    if (status != errSecSuccess) {
        NSLog(@"Failed to import data from provided with error :%d ", (int)status);
        return nil;
    }

    NSArray *importedItems = (NSArray*)CFBridgingRelease(result);
    NSDictionary *item = importedItems[0];

    // Get SecIdentityRef representing the item's id
    SecIdentityRef identityRef = (__bridge SecIdentityRef) item[(id)kSecImportItemIdentity];

    // Get Id's Private Key, return nil id if fails
    SecKeyRef privateKey;
    status = SecIdentityCopyPrivateKey(identityRef, &privateKey);
    if (status != errSecSuccess) {
        NSLog(@"Failed to import private key from provided with error :%d ", (int)status);
        return nil;
    }
    CFAutorelease(privateKey);

    // Get all relevant certs [SecCertificate] from the ID's cert chain using kSecImportItemCertChain
    NSArray *certChain = item[(id)kSecImportItemCertChain];

    // Return nil Id if errors in key or cert chain at this stage
    if (!certChain || !privateKey)
        return nil;

    // end::p2p-tlsid-import-from-bundled[]

    // tag::p2p-tlsid-store-in-keychain[]
    // FIXME: Use the same tag as tag: [create-self-signed-cert]
    // end::p2p-tlsid-store-in-keychain[]

    // tag::p2p-tlsid-return-id-from-keychain[]
    // RETURN A TLSIDENTITY FROM THE KEYCHAIN FOR USE IN CONFIGURING TLS COMMUNICATION
    return [CBLTLSIdentity identityWithIdentity:identityRef
                                          certs:@[certChain[1]]
                                          error:&error];
    // end::p2p-tlsid-return-id-from-keychain[]
}

- (void) dontTestDeleteTLSIdentityFromKeychain {
    NSError *error;
    // tag::p2p-tlsid-delete-id-from-keychain[]

    [CBLTLSIdentity deleteIdentityWithLabel:@"doco-sync-server-1" error:&error];

    // end::p2p-tlsid-delete-id-from-keychain[]
}

@end
// end::p2p-tlsid-manage-func[]

#pragma mark - For replications

// BEGIN -- snippets --
//    Purpose -- code samples for use in replication topic

// tag::sgw-repl-pull[]
@interface MyClass :NSObject
@property (nonatomic) CBLDatabase *database;
@property (nonatomic) CBLReplicator *replicator; // <1>
@end

@implementation MyClass
@synthesize database=_database;
@synthesize replicator=_replicator;

- (void) startReplication {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"]; // <2>
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc] initWithDatabase:_database
                                                                                       target:target];
    config.replicatorType = kCBLReplicatorTypePull;
    _replicator = [[CBLReplicator alloc] initWithConfig:config];
    [_replicator start];
}
@end

// end::sgw-repl-pull[]

/*
// tag::sgw-repl-pull-callouts[]
<1> A replication is an asynchronous operation.
To keep a reference to the `replicator` object, you can set it as an instance property.
<2> The URL scheme for remote database URLs has changed in Couchbase Lite 2.0.
You should now use `ws:`, or `wss:` for SSL/TLS connections.


// end::sgw-repl-pull-callouts[]
 */
