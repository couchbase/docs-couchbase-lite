//
//  SampleCodeTest.m
//  code-snippets
//
//  Copyright © 2025 couchbase. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>
#import <CoreML/CoreML.h>
#import <ifaddrs.h>
#import <net/if.h>


#pragma mark - !!!Note
/**
 Note for Consistency across the code snippets:

 1. We will keep the '*' with instance after the space.
    `NSDictionary *dict = [NSDictionary dictionary];`

 2. For making more space in single line, we will avoid space after the ':' in function call.
    `[myMLModel predictImage:imageData];`

 3. Will only use `self.database` and `self.otherDB`. Except when creating a new database sample.

 4. Will only keep `self.collection` and `self.otherCollection` when using default collections for the two databases.

 5. While using replicator/listener, we will use as ivar `self.replicator` and `self.listener` resp.
 */

#pragma mark -- PredictiveModel Class

// tag::predictive-model[]
/**
 `myMLModel` is a fake implementation.
 This would be the implementation of the ml model you have chosen.
 */
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
+ (NSDictionary*) predictImage: (NSData*)data { return [NSDictionary dictionary]; }
@end

#pragma mark -- Custom Logging Class

// tag::new-custom-logging[]
@interface TestLogSink :NSObject<CBLLogSinkProtocol>

@end

@implementation TestLogSink

- (void) writeLogWithLevel:(CBLLogLevel)level domain:(CBLLogDomain)domain message:(NSString*)message {
    // handle the message, for example piping it to
    // a third party framework
}

@end
// end::new-custom-logging[]

#pragma mark -- Conflict Resolver Helpers

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

#pragma mark -- Query Hotel

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

#pragma mark -- !!!Snippets

@interface SampleCodeTest :NSObject
@property(nonatomic) CBLDatabase *database;
@property(nonatomic) CBLCollection *collection;
@property(nonatomic) CBLDatabase *otherDB;
@property(nonatomic) CBLCollection *otherCollection;
@property(nonatomic) CBLURLEndpointListener *listener;
@property(nonatomic) CBLReplicator *replicator;
@end

@implementation SampleCodeTest

#pragma mark -- Identify available network interfaces

- (void) dontTestListenerGetNetworkInterfaces {
    // tag::listener-get-network-interfaces[]
    struct ifaddrs *ifaddrs;
    getifaddrs(&ifaddrs);
    for (struct ifaddrs *ifa = ifaddrs; ifa != NULL; ifa = ifa->ifa_next) {
        NSLog(@"%@", [NSString stringWithUTF8String: ifa->ifa_name]);
        // do something with this `ifa`
    }
    
    freeifaddrs(ifaddrs);
    // end::listener-get-network-interfaces[]
}

#pragma mark -- Troubleshooting Page - Logging

- (void) dontTestLoggingApi {
    //tag::console-logging-db[]
    CBLLogSinks.console = [[CBLConsoleLogSink alloc] initWithLevel:kCBLLogLevelVerbose domains:kCBLLogDomainDatabase];
    //end::console-logging-db[]
    
    // tag::new-console-logging[]
    CBLLogSinks.console = [[CBLConsoleLogSink alloc] initWithLevel:kCBLLogLevelVerbose domains:kCBLLogDomainAll];
    // end::new-console-logging[]
    
    // tag::new-file-logging[]
    NSString* tempFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:  @"cbllog"];
    CBLLogSinks.file = [[CBLFileLogSink alloc] initWithLevel:kCBLLogLevelVerbose
                                                   directory:tempFolder
                                                usePlaintext:false
                                                maxKeptFiles:12
                                                 maxFileSize:524288];
    // end::new-file-logging[]
    
    // tag::set-new-custom-logging[]
    TestLogSink* sink = [[TestLogSink alloc] init];
    CBLLogSinks.custom = [[CBLCustomLogSink alloc] initWithLevel:kCBLLogLevelWarning logSink:sink];
    // end::set-new-custom-logging[]
}

#pragma mark -- Database

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

- (void) dontTestDatabaseFullSync {
    CBLDatabaseConfiguration* config = [[CBLDatabaseConfiguration alloc] init];
    // tag::database-fullsync[]
    config.fullSync = true;
    // end::database-fullsync[]
}

- (void) dontTestManageCollection {
    NSError* error = nil;
    
    // tag::scopes-manage-create-collection[]
    CBLCollection* collection = [self.database createCollectionWithName:@"myCollectionName"
                                                                  scope:@"myScopeName"
                                                                  error:&error];
    // end::scopes-manage-create-collection[]
    
    // tag::scopes-manage-index-collection[]
    CBLFullTextIndexConfiguration* config = [[CBLFullTextIndexConfiguration alloc]
                                             initWithExpression: @[@"overview"]
                                             ignoreAccents: NO
                                             language: nil];

    [collection createIndexWithName: @"overviewFTSIndex" config:config error: &error];
    // end::scopes-manage-index-collection[]
    
    // tag::scopes-manage-list[]
    NSArray* scopes = [self.database scopes: &error];
    NSArray* collections = [self.database collections:@"myScopeName" error:&error];
    NSLog(@"I have %d scopes and %d collections", (int)scopes.count, (int)collections.count);
    // end::scopes-manage-list[]
    
    // tag::scopes-manage-drop-collection[]
    BOOL success = [self.database deleteCollectionWithName:@"myCollectionName"
                                                     scope:@"myScopeName"
                                                     error:&error];
    if (!success) {
        NSLog(@"Failed to delete the collection %@", error);
    }
    // end::scopes-manage-drop-collection[]
}

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

- (void) dontTestLoadingPrebuilt {
    // tag::prebuilt-database[]
    // Note: Getting the path to a database is platform-specific.
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

#pragma mark -- Document page

- (void) dontTestInitializer {
    NSError *error;
    // tag::initializer[]
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
    [doc setString:@"task" forKey:@"task"];
    [doc setString:@"todo" forKey:@"owner"];
    [doc setDate:[NSDate now] forKey:@"createdAt"];
    [self.collection saveDocument:doc error:&error];
    // end::initializer[]
}

- (void) dontTestMutability {
    NSError *error;
    // tag::update-document[]
    CBLDocument *doc = [self.collection documentWithID:@"xyz" error:&error];
    CBLMutableDocument *mutableDocument = [doc toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];
    [self.collection saveDocument:mutableDocument error:&error];
    // end::update-document[]
}

- (void) dontTestTypedAcessors {
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];

    // tag::date-getter[]
    [doc setValue:[NSDate date] forKey:@"createdAt"];
    NSDate *date = [doc dateForKey:@"createdAt"];
    // end::date-getter[]

    NSLog(@"Date:%@", date);
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
            [self.collection saveDocument:doc error:&err];
        }
    }];
    // end::batch[]
}

- (void) dontTestChangeListener {
    // tag::document-listener[]
    __block CBLCollection *wCollection = self.collection;
    [self.collection addDocumentChangeListenerWithID:@"user.john" listener:^(CBLDocumentChange  *change) {
        NSError *error;
        CBLDocument *doc = [wCollection documentWithID:change.documentID error:&error];
        NSLog(@"Status ::%@)", [doc stringForKey:@"verified_account"]);
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
    [self.collection setDocumentExpirationWithID:@"doc123" expiration:ttl error:&error];

    // Reset expiration
    [self.collection setDocumentExpirationWithID:@"doc1" expiration:nil error:&error];

    // Query documents that will be expired in less than five minutes
    NSTimeInterval fiveMinutesFromNow = [[NSDate dateWithTimeIntervalSinceNow:60 * 5] timeIntervalSince1970];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
                                         from:[CBLQueryDataSource collection:self.collection]
                                        where:[[CBLQueryMeta expiration]
                                                lessThan:[CBLQueryExpression double:fiveMinutesFromNow]]];
    // end::document-expiration[]
    NSLog(@"%@", query);
}

- (void) dontTestDataTypeUsage {
    // tag::datatype_usage[]
    // tag::datatype_usage_createdb[]
    // Get the database (and create it if it doesn’t exist).
    NSError *error;
    CBLDatabase *database = [[CBLDatabase alloc] initWithName:@"hoteldb" error:&error];
    CBLCollection *collection = [database defaultCollection:&error];
    // end::datatype_usage_createdb[]
    
    // tag::datatype_usage_createdoc[]
    // Create your new document
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
    // Add document type and hotel name as string
    [mutableDoc setString:@"hotel" forKey:@"type"];
    [mutableDoc setString:@"Hotel Java Mo" forKey:@"name"];

    // Add average room rate (float)
    [mutableDoc setFloat:121.75 forKey:@"room_rate"];

    // Add address (dictionary)
    [mutableDoc setDictionary:address forKey:@"address"];

    // Add phone numbers(array)
    [mutableDoc setArray:phones forKey:@"phones"];
    // end::datatype_usage_populate[]
    
    // tag::datatype_usage_persist[]
    [collection saveDocument:mutableDoc error:&error];
    // end::datatype_usage_persist[]
    
    // tag::datatype_usage_closedb[]
    if (![self.database close:&error])
        NSLog(@"Error closing db:%@", error);
    // end::datatype_usage_closedb[]
    // end::datatype_usage[]
}

- (void) dontTestDataTypeDictionary {
    NSError *error;
    // tag::datatype_dictionary[]
    CBLDocument *doc = [self.collection documentWithID:@"doc1" error:&error];

    // Getting a dictionary value from the document
    CBLDictionary *dict = [doc dictionaryForKey:@"address"];

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
    // end::datatype_dictionary[]
    
    NSLog(@"%@", mutableDict);
}

- (void) dontTestDataTypeMutableDictionary {
    // tag::datatype_mutable_dictionary[]

    // Create a new mutable dictionary and populate some keys/values
    CBLMutableDictionary *dict = [[CBLMutableDictionary alloc] init];
    [dict setString:@"1 Main st" forKey:@"street"];
    [dict setString:@"San Francisco" forKey:@"city"];

    // Set the dictionary to a document and save the document
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
    [doc setDictionary:dict forKey:@"address"];
    NSError *error;
    [self.collection saveDocument:doc error:&error];
    // end::datatype_mutable_dictionary[]
}

- (void) dontTestDataTypeArray {
    // tag::datatype_array[]
    NSError *error;
    CBLDocument *doc = [self.collection documentWithID:@"doc1" error:&error];

    // Getting an array value from the document
    CBLArray *array = [doc arrayForKey:@"phones"];

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
    // end::datatype_array[]
    
    NSLog(@"%@", mutableArray);
}

- (void) dontTestDataTypeMutableArray {
    // tag::datatype_mutable_array[]
    // Create a new mutable array and populate data into the array
    CBLMutableArray *array = [[CBLMutableArray alloc] init];
    [array addString:@"650-000-0000"];
    [array addString:@"650-000-0001"];

    // Set the array to a document and save the document
    CBLMutableDocument *doc = [[CBLMutableDocument alloc] init];
    [doc setArray:array forKey:@"address"];
    NSError *error;
    [self.collection saveDocument:doc error:&error];
    // end::datatype_mutable_array[]
}

#if TARGET_OS_IPHONE
- (void) dontTestBlob {
    NSError *error;
    CBLMutableDocument *newTask = [[CBLMutableDocument alloc] initWithID:@"task1"];

    // tag::blob[]
    UIImage *appleImage = [UIImage imageNamed:@"avatar.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(appleImage, 1.0);  // <.>

    CBLBlob *blob = [[CBLBlob alloc] initWithContentType:@"image/jpeg" data:imageData];  // <.>
    [newTask setBlob:blob forKey:@"avatar"]; // <.>
    [self.collection saveDocument:newTask error:&error];

    CBLDocument *savedTask = [self.collection documentWithID:@"task1" error:&error];
    CBLBlob *taskBlob = [savedTask blobForKey:@"avatar"];
    UIImage *taskImage = [UIImage imageWithData:taskBlob.content];
    // end::blob[]

    NSLog(@"%@", taskImage);
}
#endif

#pragma mark -- Query

- (void) dontTestIndexing {
    NSError *error;

    // tag::query-index[]
    CBLValueIndexConfiguration* config = [[CBLValueIndexConfiguration alloc]
                                          initWithExpression:@[@"type", @"name"]];

    [self.collection createIndexWithName:@"TypeNameIndex" config:config error:&error];
    // end::query-index[]
    
    // tag::query-index_Querybuilder[]
    CBLValueIndexItem *type = [CBLValueIndexItem property:@"type"];
    CBLValueIndexItem *name = [CBLValueIndexItem property:@"name"];
    CBLIndex *index = [CBLIndexBuilder valueIndexWithItems:@[type, name]];
    [self.collection createIndex:index name:@"TypeNameIndex" error:&error];
    // end::query-index_Querybuilder[]
}

- (void) dontTestPartialValueIndex {
    NSError* error;
    // tag::partial-value-index[]
    CBLValueIndexConfiguration* config = [[CBLValueIndexConfiguration alloc]
                                          initWithExpression:@[@"city"] where:@"type = \"hotel\""];

    [self.collection createIndexWithName:@"HotelCityIndex" config:config error:&error];
    // end::partial-value-index[]
}

- (void) dontTestPartialFullTextIndex {
    NSError* error;
    // tag::partial-full-text-index[]
    CBLFullTextIndexConfiguration* config = [[CBLFullTextIndexConfiguration alloc]
                                             initWithExpression:@[@"description"]
                                             where:@"type = \"hotel\""
                                             ignoreAccents:NO
                                             language:nil];

    [self.collection createIndexWithName:@"HotelDescIndex" config:config error:&error];
    // end::partial-full-text-index[]
}

- (void) dontTestSelectProps {
    NSError *error;
    // tag::query-select-props[]
    CBLQuerySelectResult *metaId = [CBLQuerySelectResult expression: CBLQueryMeta.id as:@"id"];
    CBLQuerySelectResult *type = [CBLQuerySelectResult property:@"type"];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];
    CBLQuery *query = [CBLQueryBuilder select:@[metaId, type, name]
                                         from:[CBLQueryDataSource collection:self.collection]];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"document id :: %@", [result stringForKey:@"id"]);
        NSLog(@"document name :: %@", [result stringForKey:@"name"]);
    }
    // end::query-select-props[]
}

- (void) dontTestSelectAll {
    CBLQuery *query;
    // tag::query-select-all[]
    query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                               from:[CBLQueryDataSource collection:self.collection]];
    // end::query-select-all[]

    // tag::live-query[]
    query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                               from:[CBLQueryDataSource collection:self.collection]]; // <.>

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
    [token remove]; // <.>
    // end::stop-live-query[]
}

- (void) dontTestWhere {
    NSError *error;
    // tag::query-where[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
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
                       from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
                                        where:[type andExpression:like]
                                      groupBy:nil having:nil orderBy:nil
                                        limit:limit];
    // end::query-like-operator-wildcard-character-match[]

    NSLog(@"%@", query);
}

- (void) dontTestRegexMatch {
    CBLCollection *collection = [self.database defaultCollection:nil];
    // tag::query-regex-operator[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];
    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQueryExpression *type = [[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"landmark"]];
    CBLQueryExpression *regex = [[CBLQueryExpression property:@"name"] regex:[CBLQueryExpression string:@"\\bEng.*e\\b"]];

    CBLQueryLimit *limit = [CBLQueryLimit limit:[CBLQueryExpression integer:10]];

    CBLQuery *query = [CBLQueryBuilder select:@[id, name]
                                         from:[CBLQueryDataSource collection:collection]
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

    CBLQueryJoin *join = [CBLQueryJoin join:[CBLQueryDataSource collection:self.collection
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
                                         from:[CBLQueryDataSource collection:self.collection as:@"airline"]
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
                                         from:[CBLQueryDataSource collection:self.collection]
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
                                         from:[CBLQueryDataSource collection:self.collection]
                                        where:[[CBLQueryExpression property:@"type"] equalTo:[CBLQueryExpression string:@"hotel"]]
                                      orderBy:@[[[CBLQueryOrdering property:@"title"] descending]]];
    // end::query-orderby[]

    NSLog(@"%@", query);
}


- (void) dontTestExplainAll {
    NSError *error;
    
    // tag::query-explain-all[]
    CBLQuery *query = [CBLQueryBuilder
                       select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource collection:self.collection]
                       where:[[CBLQueryExpression property:@"type"]
                              equalTo:[CBLQueryExpression string:@"university"]]
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
            like:[CBLQueryExpression string:@"%hotel%"]]; // <.>
    CBLQueryExpression *name =
        [[CBLQueryExpression property:@"name"]
            like:[CBLQueryExpression string:@"%royal%"]];

    CBLQuery *query = [CBLQueryBuilder
                       select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource collection:self.collection]
                       where:[type andExpression:name]
    ];
      NSLog(@"%@", [query explain:&error]);
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

    CBLQuery *query = [CBLQueryBuilder
                       select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource collection:self.collection]
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

    CBLQuery *query = [CBLQueryBuilder
                       select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource collection:self.collection]
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

    CBLQuery *query = [CBLQueryBuilder
                       select:@[[CBLQuerySelectResult all]]
                       from:[CBLQueryDataSource collection:self.collection]
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
        [self.collection saveDocument:doc error:&error];
    }

    // Create index with N1QL
    CBLFullTextIndexConfiguration* config = [[CBLFullTextIndexConfiguration alloc]
                                             initWithExpression: @[@"overview"]
                                             ignoreAccents: NO
                                             language: nil];

    [self.collection createIndexWithName:@"overviewFTSIndex" config:config error: &error];
    // end::fts-index[]
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
        [self.collection saveDocument:doc error:&error];
    }

    // Create index with IndexBuilder
    CBLFullTextIndex *index = [CBLIndexBuilder fullTextIndexWithItems:@[[CBLFullTextIndexItem property:@"name"]]];
    index.ignoreAccents = NO;
    [self.collection createIndex:index name:@"nameFTSIndex" error:&error];
    // end::fts-index_Querybuilder[]
}

- (void) dontTestFullTextSearch {
    NSError *error;

    // tag::fts-query[]
    NSString *ftsQueryString =
    @"SELECT META().id FROM _ WHERE MATCH(overviewFTSIndex, 'Michigan') ORDER BY RANK(overviewFTSIndex)";
    CBLQuery *ftsQuery = [self.database createQuery:ftsQueryString error:&error];

    CBLQueryResultSet *resultSet = [ftsQuery execute:&error];
    NSArray* results  = [resultSet allResults];
    for (CBLQueryResult *result in results) {
        NSLog(@"document id %@", [result stringAtIndex:0]);
    }
    // end::fts-query[]
}

- (void) dontTestFullTextSearch_Querybuilder {
    NSError *error;
    // tag::fts-query_Querybuilder[]
    id exp = [CBLQueryExpression fullTextIndex:@"nameFTSIndex"];
    CBLQueryExpression *where = [CBLQueryFullTextFunction matchWithIndex:exp query:@"'buy'"];
    
    CBLQuery *query =
      [CBLQueryBuilder
        select:@[[CBLQuerySelectResult expression:[CBLQueryMeta id]]]
        from:[CBLQueryDataSource collection:self.collection]
        where:where];

    NSEnumerator *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {
        NSLog(@"document id %@", [result stringAtIndex:0]);
    }
    // end::fts-query_Querybuilder[]
}

- (void) dontTestPredictiveModel {
    NSError *error;
    // tag::register-model[]
    ImageClassifierModel *model = [[ImageClassifierModel alloc] init];
    [[CBLDatabase prediction] registerModel:model withName:@"ImageClassifier"];
    // end::register-model[]

    // tag::predictive-query-value-index[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction *prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input];

    CBLValueIndex *index = [CBLIndexBuilder valueIndexWithItems:@[[CBLValueIndexItem expression:[prediction property:@"label"]]]];
    [self.collection createIndex: index name:@"value-index-image-classifier" error:&error];
    // end::predictive-query-value-index[]

    // tag::unregister-model[]
    [[CBLDatabase prediction] unregisterModelWithName:@"ImageClassifier"];
    // end::unregister-model[]
}

- (void) dontTestPredictiveIndex {
    NSError *error;

    // tag::predictive-query-predictive-index[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];

    CBLPredictiveIndex *index = [CBLIndexBuilder predictiveIndexWithModel:@"ImageClassifier" input:input properties:nil];
    [self.collection createIndex:index name:@"predictive-index-image-classifier" error:&error];
    // end::predictive-query-predictive-index[]
}

- (void) dontTestPredictiveQuery {
    NSError *error;

    // tag::predictive-query[]
    CBLQueryExpression *input = [CBLQueryExpression dictionary:@{@"photo":[CBLQueryExpression property:@"photo"]}];
    CBLQueryPredictionFunction *prediction = [CBLQueryFunction predictionUsingModel:@"ImageClassifier" input:input]; // <1>

    CBLQueryExpression *condition = [[[prediction property:@"label"] equalTo:[CBLQueryExpression string:@"car"]]
                                     andExpression:[[prediction property:@"probablity"] greaterThanOrEqualTo:[CBLQueryExpression double:0.8]]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource collection:self.collection]
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

- (void) dontTestQuerySyntaxJson {
    NSError *error;
    
    // tag::query-syntax-all[]
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                             from:[CBLQueryDataSource collection:self.collection]]; // <.>
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

    }
    // end::query-access-all[]

    // tag::query-access-json[]
    CBLQueryResultSet *rs = [query execute:&error];
    for (CBLQueryResult *result in rs) {

        // Get result as a JSON string
        NSString *json = [result toJSON];

        // Get an native Obj-C object from the Json String
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&error];

        // Log generated Json and Native objects
        // For demo/example purposes
        NSLog(@"Json String %@", json);
        NSLog(@"Native Object %@", dict);
    };
    // end::query-access-json[]
}

- (void) dontTestQuerySyntaxAndAccessProps {
    NSError *error = nil;
    
    // tag::query-syntax-props[]
    CBLQuerySelectResult *id = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

    CBLQuerySelectResult *type = [CBLQuerySelectResult property:@"type"];

    CBLQuerySelectResult *name = [CBLQuerySelectResult property:@"name"];

    CBLQuerySelectResult *city = [CBLQuerySelectResult property:@"city"];

    CBLQuery *query = [CBLQueryBuilder select:@[id, type, name, city]
                                         from:[CBLQueryDataSource collection:self.collection]]; // <.>
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
    NSError* error;
    // tag::query-syntax-count-only[]
    NSInteger count = 0;
    CBLQueryExpression *countExpression = [CBLQueryFunction count:[CBLQueryExpression all]];
    CBLQuerySelectResult *selectResult = [CBLQuerySelectResult expression:countExpression
                                                                       as:@"myCount"];

    CBLQuery *query = [CBLQueryBuilder select:@[selectResult]
                                         from:[CBLQueryDataSource collection:self.collection]]; // <.>
    // end::query-syntax-count-only[]
    
    // tag::query-access-count-only[]
    CBLQueryResultSet *results = [query execute:&error];

    for (CBLQueryResult *result in results) {
        count = [result integerForKey:@"myCount"]; // <.>
    }
    // end::query-access-count-only[]
    
    NSLog(@"print to avoid warning %@ %ld", query, count);
}

- (void) dontTestQuerySyntaxID {
    NSError *error;
    
    // tag::query-syntax-id[]
    CBLQuerySelectResult *selectResult = [CBLQuerySelectResult expression:[CBLQueryMeta id]];

    CBLQuery *query = [CBLQueryBuilder select:@[selectResult]
                                         from:[CBLQueryDataSource collection:self.collection]];
    // end::query-syntax-id[]
    
    // tag::query-access-id[]
    CBLQueryResultSet *results = [query execute:&error];
    CBLDocument *doc = nil;
    NSString *docId = nil;
    for (CBLQueryResult *result in results) {
        docId = [result stringForKey:@"id"]; // <.>

        // Now you can get the document using its ID
        // for example using
        doc = [self.collection documentWithID:docId error:&error];
        NSLog(@"doc.id = %@", doc.id);
    }
    // end::query-access-id[]
    
    NSLog(@"print to avoid warning %@", query);
}

- (void) dontTestQuerySyntaxPagination {
    // tag::query-syntax-pagination[]
    int offset = 0;
    int limit = 20;

    CBLQueryLimit *queryLimit = [CBLQueryLimit limit:[CBLQueryExpression integer:limit]
                                              offset:[CBLQueryExpression integer:offset]];
    CBLQuery *query = [CBLQueryBuilder select:@[[CBLQuerySelectResult all]]
                                         from:[CBLQueryDataSource collection:self.collection]
                                        where:nil
                                      groupBy:nil
                                       having:nil
                                      orderBy:nil
                                        limit:queryLimit];
    // end::query-syntax-pagination[]
    
    NSLog(@"print to avoid warning %@", query);
}

- (void) dontTestDocsOnly_QuerySyntaxN1QL {
    NSError *error;

    // tag::query-syntax-n1ql[]
    NSString *queryString = @"SELECT * FROM _ WHERE type = \"hotel\""; // <.>

    CBLQuery *query = [self.database createQuery:queryString error: &error];

    CBLQueryResultSet *results = [query execute:&error];
    // end::query-syntax-n1ql[]
    
    NSLog(@"resultset.count = %lu", (unsigned long)results.allResults.count);
}

- (void) dontTestDocsOnly_QuerySyntaxN1QLParams {
    NSError *error;

    // tag::query-syntax-n1ql-params[]
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM _ WHERE type = $type"]; // <.>

    CBLQuery *query = [self.database createQuery:queryString error: &error];

    CBLQueryParameters *params = [[CBLQueryParameters alloc] init];
    [params setString:@"hotel" forName:@"type"]; // <.>
    query.parameters = params;

    CBLQueryResultSet *results =  [query execute:&error];
    // end::query-syntax-n1ql-params[]
    
    NSLog(@"resultset.count = %lu", (unsigned long)results.allResults.count);
}

#pragma mark -- JSON

- (void) donTestToDictionary {
    // tag::to-dictionary[]
    CBLDocument *doc = [self.collection documentWithID:@"xyz" error:nil];
    NSLog(@"%@", [doc toDictionary]);
    // end::to-dictionary[]
}

- (void) donTestToJSON {
    // tag::to-json[]
    CBLDocument *doc = [self.collection documentWithID:@"xyz" error:nil];
    NSLog(@"%@", [doc toJSON]);
    // end::to-json[]
}

- (void) dontTestJSONAsArray {
    NSError *error = nil;
    // tag::tojson-array[]
    NSString *json = @"[\"1000\",\"1001\",\"1002\",\"1003\"]";
    CBLMutableArray *array = [[CBLMutableArray alloc] initWithJSON:json error:&error];
    for (NSString *item in array) {
        NSLog(@"%@", item);
    }
    // end::tojson-array[]
}

- (void) dontTestDictionaryAsJSON {
    NSError *error = nil;
    // tag::tojson-dictionary[]
    NSString *json = @"{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\","
    "\"city\":\"Balmain\",\"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}";
    
    
    CBLMutableDictionary *dict = [[CBLMutableDictionary alloc] initWithJSON:json
                                                                      error:&error];
    
    NSString *name = [dict stringForKey:@"name"];
    
    for (NSString *key in dict) {
        NSLog(@"%@ %@", key, [dict valueForKey:key]);
    }
    // end::tojson-dictionary[]
    
    NSLog(@"%@", name);
}

- (void) dontTestToJSONDocument {
    NSError *error;
    // tag::tojson-document[]
    CBLDocument *doc = [self.collection documentWithID:@"doc-1000" error:&error];
    NSString *json = [doc toJSON];
    NSLog(@"json %@", json);
    // end::tojson-document[]
}

- (void) dontTestToJSONBlob {
    NSError *error;
    // tag::tojson-blob[]
    CBLDocument *doc = [self.collection documentWithID:@"doc-1000" error:&error];
    CBLBlob *blob = [doc blobForKey:@"avatar"];
    NSString *json = [blob toJSON];
    NSLog(@"%@", json);
    // end::tojson-blob[]
}

#pragma mark -- Replication

- (void) dontTestEnableReplicatorLogging {
    // tag::replication-logging[]
    // Replicator
    CBLLogSinks.console = [[CBLConsoleLogSink alloc] initWithLevel:kCBLLogLevelVerbose domains:kCBLLogDomainReplicator];

    // Network
    CBLLogSinks.console = [[CBLConsoleLogSink alloc] initWithLevel:kCBLLogLevelVerbose domains:kCBLLogDomainNetwork];
    // end::replication-logging[]
}

- (void) dontTestReplicatorSimple {
    // tag::replicator-simple[]
    NSURL *url = [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url]; // <.>

    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target]; // <.>

    replConfig.acceptOnlySelfSignedServerCertificate = true; // <.>
    
    replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"valid.user"
                                                                  password:@"valid.password.string"]; // <.>


    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig]; // <.>

    [self.replicator start]; // <.>
    // end::replicator-simple[]
}

#pragma mark -- Data Sync page - Remote Sync Gateway

- (void) dontTestRemoteSyncGatewayync {
    // tag::sgw-rep-func[]
    // tag::sgw-act-rep-configure-target[]
    // tag::sgw-rep-target[]
    NSURL *url = [NSURL URLWithString:@"ws://10.0.2.2.com:55990/travel-sample"]; // <.>
    CBLURLEndpoint *listener = [[CBLURLEndpoint alloc] initWithURL:url];
    // end::sgw-rep-target[]
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *config = [[CBLReplicatorConfiguration alloc]
                                          initWithCollections:@[collectionConfig]
                                          target:listener]; // <.>
    // end::sgw-act-rep-configure-target[]
    
    // tag::sgw-rep-network-interface[]
    config.networkInterface = @"en0";
    // end::sgw-rep-network-interface[]
    
    // tag::sgw-act-rep-config-type[]
    config.replicatorType = kCBLReplicatorTypePushAndPull;
    // end::sgw-act-rep-config-type[]
    
    // tag::sgw-act-rep-config-cont[]
    // Configure Sync Mode
    config.continuous = true;
    // end::sgw-act-rep-config-cont[]
    
    // tag::replication-retry-config[]
    config.heartbeat = 150; // <.>
    config.maxAttempts = 20; // <.>
    config.maxAttemptWaitTime = 600; // <.>
    // end::replication-retry-config[]
    
    // tag::sgw-rep-config-cacert[]
    // Only accept CA Certs
    config.acceptOnlySelfSignedServerCertificate = false; // <.>
    // end::sgw-rep-config-cacert[]
    
    // tag::sgw-rep-config-self-cert[]
    // Only accept self-signed certs
    config.acceptOnlySelfSignedServerCertificate = true; // <.>
    // end::sgw-rep-config-self-cert[]
    
    // tag::sgw-rep-config-cacert-pinned[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    
    config.acceptOnlySelfSignedServerCertificate=false;
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);
    // end::sgw-rep-config-cacert-pinned[]
    
    // tag::sgw-config-autopurge[]
    // Default is YES
    config.enableAutoPurge = NO; // <.>
    // end::sgw-config-autopurge[]
    
    // tag::sgw-start-repl[]
    /** Apply configuration settings */
    self.replicator = [[CBLReplicator alloc] initWithConfig:config]; // <.>
    /** Run the repliator with the applied config settings */
    [self.replicator start]; // <.>
    // end::sgw-start-repl[]
    // end::sgw-rep-func[]
    
    NSLog(@"print to aviod warning %@", config.description);
}

- (void) dontTestReplicationBasicAuthentication {
    // tag::basic-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];
    
    replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"john" password:@"pass"];

    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::basic-authentication[]
}

- (void) dontTestReplicationSessionAuthentication {
    // tag::session-authentication[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];
    
    replConfig.authenticator = [[CBLSessionAuthenticator alloc] initWithSessionID:@"904ac010862f37c8dd99015a33ab5a3565fd8447"];

    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::session-authentication[]
}

- (void) dontTestReplicatorStatus {
    // tag::replication-status[]
    [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
        }
    }];
    // end::replication-status[]
}

- (void) testReplicationPendingDocs {
    CBLCollection *wCollection = self.collection;
    // tag::replication-pendingdocuments[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];
    
    replConfig.replicatorType = kCBLReplicatorTypePush;
    // tag::replication-push-pendingdocumentids[]
    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];

    /** Get list of pending doc IDs */
    NSError *err = nil;
    NSSet *pendingDocIds = [self.replicator pendingDocumentIDsForCollection:self.collection error:&err]; // <.>
    // end::replication-push-pendingdocumentids[]

    if ([pendingDocIds count] > 0) {

        NSLog(@"There are %lu documents pending", (unsigned long)[pendingDocIds count]);

        [self.replicator addChangeListener:^(CBLReplicatorChange *change) {

            NSLog(@"Replicator activity level is %u", change.status.activity);
            /** Iterate and report-on the pending doc IDs  in 'mydocids' */
            for (NSString *docID in pendingDocIds) {

                // tag::replication-push-isdocumentpending[]
                NSError *err = nil;
                if (![change.replicator isDocumentPending:docID collection:wCollection error:&err]) { // <.>
                    NSLog(@"Doc ID %@ now pushed", docID);
                }
                // end::replication-push-isdocumentpending[]
            }
        }];
        
        [self.replicator start];
    };
    // end::replication-pendingdocuments[]
}

- (void) dontTestCustomReplicationHeader {
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    
    // tag::replication-custom-header[]
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];
    replConfig.headers = @{@"CustomHeaderName" :@"Value"};
    // end::replication-custom-header[]
}

- (void) dontTestReplicationPushFilter {
    // tag::replication-push-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    collectionConfig.pushFilter = ^BOOL(CBLDocument *doc, CBLDocumentFlags flags) { // <1>
        if ([[doc stringForKey:@"type"] isEqualToString:@"draft"]) {
            return false;
        }
        return true;
    };
    
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];

    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::replication-push-filter[]
}

- (void) dontTestReplicationPullFilter {
    // tag::replication-pull-filter[]
    NSURL *url = [NSURL URLWithString:@"ws://localhost:4984/db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    collectionConfig.pullFilter = ^BOOL(CBLDocument *doc, CBLDocumentFlags flags) { // <1>
        if ((flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
            return false;
        }
        return true;
    };
    
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];

    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::replication-pull-filter[]
}

- (void) dontTestReplicationResetCheckpoint {
    BOOL resetCheckpoint = NO;
    // tag::replication-reset-checkpoint[]
    if (resetCheckpoint)
        [self.replicator startWithReset:YES]; // <.>
    // end::replication-reset-checkpoint[]
}

- (void) dontTestReplicatorDocumentEvent {
    // tag::add-document-replication-listener[]
    id token = [self.replicator addDocumentReplicationListener:^(CBLDocumentReplication  *replication) {
        NSLog(@"Replication type ::%@", replication.isPush ? @"Push" :@"Pull");
        for (CBLReplicatedDocument *doc in replication.documents) {
            if (doc.error == nil) {
                NSLog(@"Doc ID ::%@", doc.id);
                if ((doc.flags & kCBLDocumentFlagsDeleted) == kCBLDocumentFlagsDeleted) {
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
    [token remove];
    // end::remove-document-replication-listener[]
}

- (void) dontTestHandlingReplicationError {
    // tag::replication-error-handling[]
    [self.replicator addChangeListener:^(CBLReplicatorChange *change) {
        if (change.status.error) {
            NSLog(@"Error code:%ld", change.status.error.code);
        }
    }];
    // end::replication-error-handling[]
}

- (void) dontTestCertificatePinning {
    CBLReplicatorConfiguration* config = self.replicator.config;
    // tag::certificate-pinning[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
    
    config.acceptOnlySelfSignedServerCertificate=false;
    config.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);
    // end::certificate-pinning[]
}

- (void) dontTestDatabaseReplica {
    /* EE feature:code below might throw a compilation error
     if it's compiled against CBL Swift Community. */
    // tag::database-replica[]
    CBLDatabaseEndpoint *targetDatabase = [[CBLDatabaseEndpoint alloc] initWithDatabase:self.otherDB];
    
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:targetDatabase];
    replConfig.replicatorType = kCBLReplicatorTypePush;
    
    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::database-replica[]
}

#pragma mark -- Data Sync page - Pasive Peer

- (BOOL) isValidCredentials:(NSString*)u password:(NSString*)p { return YES; }
- (BOOL) isValidCertificates:(NSArray*)certs { return YES; }

- (void) dontTestListenerSimple {
    NSError *error = nil;

    // tag::listener-simple[]
    CBLURLEndpointListenerConfiguration *endpointConfig = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithCollections:[NSArray arrayWithObject:self.collection]]; // <.>

    endpointConfig.authenticator = [[CBLListenerPasswordAuthenticator alloc]
                                initWithBlock:^BOOL(NSString  *validUser, NSString  *validPassword) {
        return [self isValidCredentials:validUser password:validPassword];
    }]; // <.>

    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:endpointConfig]; // <.>

    BOOL success = [self.listener startWithError:&error];
    if (!success) {
        NSLog(@"Cannot start the listener:%@", error);
    } // <.>
    // end::listener-simple[]
}

- (void) dontTestListener {
    NSError *error = nil;

    // tag::listener-initialize[]
    // tag::listener-config-db[]
    // Initialize the listener config <.>
    CBLURLEndpointListenerConfiguration *endpointConfig = [[CBLURLEndpointListenerConfiguration alloc]
                                                           initWithCollections:[NSArray arrayWithObject:self.collection]];
    // end::listener-config-db[]
    
    // tag::listener-config-port[]
    endpointConfig.port =  55990; // <.>
    // end::listener-config-port[]
    
    // tag::listener-config-netw-iface[]
    endpointConfig.networkInterface = @"10.1.1.10"; // <.>
    // end::listener-config-netw-iface[]
    
    // tag::listener-config-delta-sync[]
    endpointConfig.enableDeltaSync = true; // <.>
    // end::listener-config-delta-sync[]
    
    // Configure server security
    // tag::listener-config-tls-enable[]
    endpointConfig.disableTLS  = false; // <.>
    // end::listener-config-tls-enable[]

    // tag::listener-config-tls-id-anon[]
    // Use an anonymous self-signed cert
    endpointConfig.tlsIdentity = nil; // <.>
    // end::listener-config-tls-id-anon[]
    
    // tag::listener-config-client-auth-pwd[]
    // Configure Client Security using an Authenticator
    // For example, Basic Authentication <.>
    endpointConfig.authenticator = [[CBLListenerPasswordAuthenticator alloc]
                            initWithBlock:^BOOL(NSString *username, NSString *password) {
        return [self isValidCredentials:username password:password];
    }];
    // end::listener-config-client-auth-pwd[]
    
    // tag::listener-start[]
    // tag::listener-init[]
    // Initialize the listener <.>
    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:endpointConfig];
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

- (void) dontTestListenerLocalDB {
    NSError *error = nil;
    CBLURLEndpointListenerConfiguration *endpointConfig = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithCollections:[NSArray arrayWithObject:self.collection]];

    // tag::listener-config-tls-id-full[]
    // tag::listener-config-tls-id-caCert[]
    /**
     Use CA Cert.
     Create a TLSIdentity from a key-pair and certificate in secure storage
     */
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"p12"]; // <.>

    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    CBLTLSIdentity *tlsIdentity = [CBLTLSIdentity importIdentityWithData:data
                                                                password:@"123"
                                                                   label:@"couchbase-docs-cert"
                                                                   error:&error]; // <.>

    endpointConfig.tlsIdentity = tlsIdentity; // <.>
    // end::listener-config-tls-id-caCert[]
    
    // tag::listener-config-tls-id-SelfSigned[]
    // Use a self-signed certificate
    NSDictionary *attrs = @{ kCBLCertAttrCommonName:@"Couchbase Inc" }; // <.>

    tlsIdentity = [CBLTLSIdentity createIdentityForKeyUsages:kCBLKeyUsagesServerAuth
                                                  attributes:attrs
                                                  expiration:[NSDate dateWithTimeIntervalSinceNow:86400] label:@"couchbase-docs-cert"
                                                       error:&error];// <.>
    // end::listener-config-tls-id-SelfSigned[]
    
    // tag::listener-config-tls-id-set[]
    // Set the TLS Identity
    endpointConfig.tlsIdentity = tlsIdentity; // <.>
    // end::listener-config-tls-id-set[]
    // end::listener-config-tls-id-full[]
}

- (void) dontTestlistenerConfigClientAuth {
    CBLURLEndpointListenerConfiguration *config = [[CBLURLEndpointListenerConfiguration alloc]
                                                   initWithCollections:[NSArray arrayWithObject:self.collection]];
    // tag::listener-config-client-auth-root[]
    // Configure the client authenticator
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"p12"]; // <.>
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef rootCertRef = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    config.authenticator = [[CBLListenerCertificateAuthenticator alloc]
                            initWithRootCerts:@[(id)CFBridgingRelease(rootCertRef)]];  // <.> <.>
    // end::listener-config-client-auth-root[]
    
    // tag::listener-config-client-auth-lambda[]
    // Authenticate self-signed cert
    // using application logic
    CBLListenerCertificateAuthenticator *authenticator = [[CBLListenerCertificateAuthenticator alloc]
                                                          initWithBlock:^BOOL(NSArray *certs) {
        return [self isValidCertificates:certs];
    }];  // <.>

    config.authenticator = authenticator; // <.> <.>
    // end::listener-config-client-auth-lambda[]
}

- (void) dontTestDeleteTLSIdentityFromKeychain {
    NSError *error;
    // tag::p2p-tlsid-delete-id-from-keychain[]
    [CBLTLSIdentity deleteIdentityWithLabel:@"alias" error:&error];
    // end::p2p-tlsid-delete-id-from-keychain[]
}

- (void) dontTestListenerStatus {
    // tag::listener-status-check[]
    NSUInteger totalConnections = self.listener.status.connectionCount;
    NSUInteger activeConnections = self.listener.status.activeConnectionCount;
    // end::listener-status-check[]
    
    NSLog(@"%lu", (unsigned long)totalConnections);
    NSLog(@"%lu", (unsigned long)activeConnections);
}

#pragma mark -- Data Sync Page - Active Peer

- (void) dontTestMyActivePeer {
    // tag::p2p-act-rep-func[]
    // tag::p2p-act-rep-target[]
    // Set listener DB endpoint
    NSURL *url = [NSURL URLWithString:@"ws://listener.com:55990/otherDB"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    
    // tag::p2p-act-rep-config-conflict[]
    /**
     Optionally set custom conflict resolver callback.
     NOTE: This is set per collection, not on the replicator.
     */
    collectionConfig.conflictResolver = [[LocalWinConflictResolver alloc] init]; // <.>
    // end::p2p-act-rep-config-conflict[]
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];
    // end::p2p-act-rep-target[]
    
    // tag::p2p-act-rep-config-type[]
    replConfig.replicatorType = kCBLReplicatorTypePush;
    // end::p2p-act-rep-config-type[]
    
    // tag::p2p-act-rep-config-cont[]
    replConfig.continuous = YES;
    // end::p2p-act-rep-config-cont[]
    
    // tag::autopurge-override[]
    /** Default is YES */
    replConfig.enableAutoPurge = NO;
    // end::autopurge-override[]
    
    // tag::p2p-act-rep-config-cacert[]
    // Only accept CA Certs
    replConfig.acceptOnlySelfSignedServerCertificate = NO; // <.>
    // end::p2p-act-rep-config-cacert[]
    
    // tag::p2p-act-rep-config-self-cert[]
    // Configure Server Authentication
    // Here - expect and accept self-signed certs
    replConfig.acceptOnlySelfSignedServerCertificate = YES; // <.>
    // end::p2p-act-rep-config-self-cert[]
    
    // tag::p2p-act-rep-config-cacert-pinned[]
    NSURL *certURL = [[NSBundle mainBundle] URLForResource:@"cert" withExtension:@"cer"];
    NSData *data = [[NSData alloc] initWithContentsOfURL:certURL];
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);

    replConfig.pinnedServerCertificate = (SecCertificateRef)CFAutorelease(certificate);
    replConfig.acceptOnlySelfSignedServerCertificate=false;
    // end::p2p-act-rep-config-cacert-pinned[]
    
    // tag::p2p-act-rep-auth[]
    // Here set client to use basic authentication
    // Providing username and password credentials
    // If prompted for them by server
    replConfig.authenticator = [[CBLBasicAuthenticator alloc] initWithUsername:@"Our Username" password:@"Our Password"]; // <.>
    // end::p2p-act-rep-auth[]
    
    // tag::p2p-act-rep-start-full[]
    // Apply configuration settings to the replicator
    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig]; // <.>

    // tag::p2p-act-rep-add-change-listener[]
    // Retain token for use in deletion
    id<CBLListenerToken> listenerToken = [self.replicator addChangeListener:^(CBLReplicatorChange *change) { // <.>
        // tag::p2p-act-rep-status[]
        if (change.status.activity == kCBLReplicatorStopped) {
            NSLog(@"Replication stopped");
        } else {
            NSLog(@"Status:%d", change.status.activity);
        };
        // end::p2p-act-rep-status[]
    }];
    // end::p2p-act-rep-add-change-listener[]

    // Run the replicator using the config settings
    [self.replicator start]; // <.>
    // end::p2p-act-rep-start-full[]
    // end::p2p-act-rep-func[]
    
    // tag::p2p-act-rep-stop[]
    // Remove the change listener
    [listenerToken remove];

    // Stop the replicator
    [self.replicator stop];
    // end::p2p-act-rep-stop[]

    NSLog(@"print to avoid warning %@", listenerToken);
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
    CBLURLEndpointListenerConfiguration *endpointConfig = [[CBLURLEndpointListenerConfiguration alloc] initWithCollections:@[self.collection]];
    endpointConfig.port = isTLS ? wssPort :wsPort;
    endpointConfig.disableTLS = !isTLS;
    endpointConfig.authenticator = auth;

    self.listener = [[CBLURLEndpointListener alloc] initWithConfig:endpointConfig]; // <1>
    // end::p2p-ws-api-urlendpointlistener-constructor[]
}

- (void) dontTestTLSIdentity {
    NSError *error = nil;
    CBLReplicatorConfiguration *config;
    // tag::p2p-tlsid-tlsidentity-with-label[]
    /** Get identity from keychain */
    CBLTLSIdentity *identity = [CBLTLSIdentity identityWithLabel:@"alias" error:&error]; // <.>
    config.authenticator = [[CBLClientCertificateAuthenticator alloc] initWithIdentity:identity]; // <.>
    // end::p2p-tlsid-tlsidentity-with-label[]
}

#pragma mark -- Handling Data Conflicts page

- (void) dontTestReplicatorConflictResolver {
    // tag::replication-conflict-resolver[]
    NSURL *url = [[NSURL alloc] initWithString:@"ws://localhost:4984/getting-started-db"];
    CBLURLEndpoint *target = [[CBLURLEndpoint alloc] initWithURL:url];
    CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc] initWithCollection:self.collection];
    collectionConfig.conflictResolver = [[LocalWinConflictResolver alloc] init];
    
    CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc] initWithCollections:@[collectionConfig] target:target];

    self.replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
    [self.replicator start];
    // end::replication-conflict-resolver[]
}

- (void) dontTestSaveWithConflictHandler {
    NSError *error;

    // tag::update-document-with-conflict-handler[]
    CBLDocument *doc = [self.collection documentWithID:@"xyz" error:&error];
    CBLMutableDocument *mutableDocument = [doc toMutable];
    [mutableDocument setString:@"apples" forKey:@"name"];

    [self.collection saveDocument:mutableDocument
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

@end

#pragma mark -- Data Sync page - Integrate Custom Listener

/**
 -----------------------------------------------------------
 ACTIVE SIDE
 -----------------------------------------------------------
 */

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
        CBLCollection *collection = [database defaultCollection:&error];

        // The delegate must implement the `CBLMessageEndpointDelegate` protocol.
        NSString *id = @"";
        CBLMessageEndpoint *endpoint = [[CBLMessageEndpoint alloc] initWithUID:@"UID:123"
                                                                        target:id
                                                                  protocolType:kCBLProtocolTypeMessageStream
                                                                      delegate:self];
        // end::message-endpoint[]

        // tag::message-endpoint-replicator[]
        CBLCollectionConfiguration *collectionConfig = [[CBLCollectionConfiguration alloc]
                                                        initWithCollection:collection];
        CBLReplicatorConfiguration *replConfig = [[CBLReplicatorConfiguration alloc]
                                                  initWithCollections:@[collectionConfig]
                                                  target:endpoint];
        
        // Create the replicator object.
        CBLReplicator *replicator = [[CBLReplicator alloc] initWithConfig:replConfig];
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

/**
 -----------------------------------------------------------
 PASIVE SIDE
 -----------------------------------------------------------
 */
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
    [[CBLMessageEndpointListenerConfiguration alloc] initWithCollections:[NSArray arrayWithObject:[database defaultCollection:&error]]
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
