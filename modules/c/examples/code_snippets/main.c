#include <cbl/CouchbaseLite.h>
#include <fleece/FLExpert.h>
#include <time.h>
#include <inttypes.h>
#ifdef _MSC_VER
#include <direct.h>
#include <Shlwapi.h>

void usleep(unsigned int us) {
    Sleep(us / 1000);
}
#else
#include <unistd.h>
#endif

static CBLDatabase* kDatabase;

// Helper for stop replicator in the code snippet
static void stop_replicator(CBLReplicator* replicator) {
    CBLReplicator_Stop(replicator);
    while(CBLReplicator_Status(replicator).activity != kCBLReplicatorStopped) {
        printf("Waiting for replicator to stop...");
        usleep(200000);
    }
    CBLReplicator_Release(replicator);
}

//  BEGIN lower-level function declarations

//  DOCS NOTE --
//  These functions are referred to in subsequent code samples.
//  Their tags will ensure they are shown alongide the usage examples.
//  Functions used in more than one place may hve multiple tags.

// tag::p2p-act-rep-func[]
// tag::p2p-act-rep-add-change-listener[]
// tag::replication-error-handling[]
// Purpose -- illustrate a simple change listener
static void simpleChangeListener(void* context,
                                 CBLReplicator* repl,
                                 const CBLReplicatorStatus* status)
{
     if(status->error.code != 0) {
         printf("Error %d / %d\n",
                status->error.domain,
                status->error.code);
     }
}
// end::replication-error-handling[]
// end::p2p-act-rep-add-change-listener[]
// end::p2p-act-rep-func[]

static const CBLDocument* simpleConflictResolver_localWins(
                                void* context, FLString documentID,
                                const CBLDocument* localDocument,
                                const CBLDocument* remoteDocument)
{
    return localDocument;
}

// tag::replication-push-filter[]
// tag::replication-pull-filter[]
// Purpose -- illustrate a simple replication filter function
static bool simpleReplicationFilter(void* context,
                                    CBLDocument* argDoc,
                                    CBLDocumentFlags argFlags)
{
    bool result = (argFlags == kCBLDocumentFlagsDeleted);
    return result;
}

// end::replication-push-filter[]
// end::replication-pull-filter[]

// tag::SimpleReplicationDocumentListener[]
// Purpose -- Illustrate a simple replication document listener
static void SimpleReplicationDocumentListener(
                                  void *context,
                                  CBLReplicator *replicator,
                                  bool isPush,
                                  unsigned numDocuments,
                                  const CBLReplicatedDocument *documents)
{
    if(isPush) {
        printf("We pushed %d documents",numDocuments);
    }
}

// END lower-level function declarations


static void getting_started_change_listener(void* context,
                                            CBLReplicator* repl,
                                            const CBLReplicatorStatus* status)
{
    if(status->error.code != 0) {
        printf("Error %d / %d\n", status->error.domain, status->error.code);
    }
}

// Page=build and run
// url=https://docs-staging.couchbase.com/couchbase-lite/current/c/gs-build.html
static void getting_started() {
    // tag::getting-started[]
    //  Purpose-- provide an overview of available crud  and sync functionality
    //
    // Get the database (and create it if it doesn't exist)
    CBLError err;
    CBLDatabase* database = CBLDatabase_Open(FLSTR("mydb"), NULL, &err);
    if(!database) {
        // Error handling.  For brevity, this is truncated in the rest of the snippet
        // and omitted in other doc code snippets
        fprintf(stderr, "Error opening database (%d / %d)\n", err.domain, err.code);
        FLSliceResult msg = CBLError_Message(&err);
        fprintf(stderr, "%.*s\n", (int)msg.size, (const char *)msg.buf);
        FLSliceResult_Release(msg);
        return;
    }

    // All CRUD operations must be carried out via a collection (for backwards compatibility
    // the old CBLDatabase_ API will automatically use the default collection).  This is a quick
    // API to explicitly get the default collection.
    CBLCollection* collection = CBLDatabase_DefaultCollection(database, &err);

    // The lack of 'const' indicates this document is mutable
    // Create a new document (i.e. a record) in the database
    CBLDocument* mutableDoc = CBLDocument_Create();
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetFloat(properties, FLSTR("version"), 3.0f);

    // Save it to the database
    if(!CBLCollection_SaveDocument(collection, mutableDoc, &err)) {
        // Failed to save, do error handling as above
        return;
    }

    // Since we will release the document, make a copy of the ID since it
    // is an internal pointer.  Whenever we create or get an FLSliceResult
    // or FLStringResult we will need to free it later too!
    FLString id = CBLDocument_ID(mutableDoc);
    CBLDocument_Release(mutableDoc);

    // Update a document
    mutableDoc = CBLCollection_GetMutableDocument(collection, id, &err);
    if(!mutableDoc) {
        // Failed to retrieve, do error handling as above.  NOTE: error code 0 simply means
        // the document does not exist.
        return;
    }

    properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetString(properties, FLSTR("language"), FLSTR("C"));
    if(!CBLCollection_SaveDocument(collection, mutableDoc, &err)) {
        // Failed to save, do error handling as above
        return;
    }

    // Note const here, means readonly
    const CBLDocument* docAgain = CBLCollection_GetDocument(collection, id, &err);
    if(!docAgain) {
        // Failed to retrieve, do error handling as above.  NOTE: error code 0 simply means
        // the document does not exist.
        return;
    }

    // No copy this time, so no release later (notice it is not FLStringResult this time)
    FLString retrievedID = CBLDocument_ID(docAgain);
    FLDict retrievedProperties = CBLDocument_Properties(docAgain);
    FLString retrievedLanguage = FLValue_AsString(FLDict_Get(retrievedProperties, FLSTR("language")));
    printf("Document ID :: %.*s\n", (int)retrievedID.size, (const char *)retrievedID.buf);
    printf("Learning %.*s\n", (int)retrievedLanguage.size, (const char *)retrievedLanguage.buf);

    CBLDocument_Release(mutableDoc);
    CBLDocument_Release(docAgain);

    // tag::query-syntax-n1ql[]
    // Create a query to fetch documents of type SDK
    int errorPos;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage, FLSTR("SELECT * FROM _ WHERE type = \"SDK\""), &errorPos, &err);
    if(!query) {
        // Failed to create query, do error handling as above
        // Note that errorPos will contain the position in the N1QL string
        // that the parse failed, if applicable
        return;
    }

    CBLResultSet* result = CBLQuery_Execute(query, &err);
    if(!result) {
        // Failed to run query, do error handling as above
        return;
    }
    // end::query-syntax-n1ql[]

    // TODO: Result set count?
    CBLResultSet_Release(result);
    CBLQuery_Release(query);

    // Create replicator to push and pull changes to and from the cloud
    CBLEndpoint* targetEndpoint = CBLEndpoint_CreateWithURL(FLSTR("ws://localhost:4984/getting-started-db"), &err);
    if(!targetEndpoint) {
        // Failed to create endpoint, do error handling as above
        return;
    }

    CBLReplicatorConfiguration replConfig;
    CBLAuthenticator* basicAuth = CBLAuth_CreatePassword(FLSTR("john"), FLSTR("pass"));
    memset(&replConfig, 0, sizeof(replConfig));
    replConfig.database = database;
    replConfig.endpoint = targetEndpoint;
    replConfig.authenticator = basicAuth;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLAuth_Free(basicAuth);
    CBLEndpoint_Free(targetEndpoint);
    if(!replicator) {
        // Failed to create replicator, do error handling as above
        return;
    }

    // Assume a function like the simple following
    //
    // static void getting_started_change_listener(void* context, CBLReplicator* repl, const CBLReplicatorStatus* status) {
    //     if(status->error.code != 0) {
    //         printf("Error %d / %d\n", status->error.domain, status->error.code);
    //     }
    // }

    CBLListenerToken* token = CBLReplicator_AddChangeListener(replicator, getting_started_change_listener, NULL);

    CBLReplicator_Start(replicator, false);

    // Later, stop and release the replicator
    // end::getting-started[]

    // When finished release resources ... eg
    CBLListener_Remove(token);

    stop_replicator(replicator);
}


// tag::local-win-conflict-resolver[]
static const CBLDocument* local_win_conflict_resolver(void* context,
                                                      FLString documentID,
                                                      const CBLDocument* localDocument,
                                                      const CBLDocument* remoteDocument)
{
    return localDocument;
}
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
static const CBLDocument* remote_win_conflict_resolver(void* context,
                                                       FLString documentID,
                                                       const CBLDocument* localDocument,
                                                       const CBLDocument* remoteDocument)
{
    return remoteDocument;
}
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
static const CBLDocument* merge_conflict_resolver(void* context,
                                                  FLString documentID,
                                                  const CBLDocument* localDocument,
                                                  const CBLDocument* remoteDocument)
{
    FLDict localProps = CBLDocument_Properties(localDocument);
    FLDict remoteProps = CBLDocument_Properties(remoteDocument);
    FLMutableDict mergeProps = FLDict_MutableCopy(localProps, kFLDefaultCopy);

    FLDictIterator d;
    FLDictIterator_Begin(localProps, &d);
    FLValue value;
    while((value = FLDictIterator_GetValue(&d))) {
        FLString key = FLDictIterator_GetKeyString(&d);
        if(FLDict_Get(mergeProps, key)) {
            continue;
        }

        FLMutableDict_SetValue(mergeProps, key, value);
        FLDictIterator_Next(&d);
    }

    CBLDocument* mergeDocument = CBLDocument_CreateWithID(documentID);
    CBLDocument_SetProperties(mergeDocument, mergeProps);
    FLMutableDict_Release(mergeProps);

    return mergeDocument;
}
// end::merge-conflict-resolver[]

static void test_replicator_conflict_resolve() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(database, NULL);

    // tag::replication-conflict-resolver[]
    // NOTE: No error handling, for brevity (see getting started)
    CBLError err;
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(FLSTR("ws://localhost:4984/mydatabase"), &err);

    
    CBLReplicationCollection collectionConfig;
    memset(&collection, 0, sizeof(collectionConfig));
    collectionConfig.collection = collection;
    collectionConfig.conflictResolver = local_win_conflict_resolver;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(replConfig));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);
    CBLReplicator_Start(replicator, false);

    // end::replication-conflict-resolver[]

    stop_replicator(replicator);
}

static bool custom_conflict_handler(void* context,
                                    CBLDocument* documentBeingSaved,
                                    const CBLDocument* conflictingDocument)
{
    FLDict currentProps = CBLDocument_Properties(conflictingDocument);
    FLDict updatedProps = CBLDocument_Properties(documentBeingSaved);
    FLMutableDict newProps = FLDict_MutableCopy(updatedProps, kFLDefaultCopy);

    FLDictIterator d;
    FLDictIterator_Begin(currentProps, &d);
    FLValue currentValue;
    while((currentValue = FLDictIterator_GetValue(&d))) {
        FLString currentKey = FLDictIterator_GetKeyString(&d);
        if(FLDict_Get(newProps, currentKey)) {
            continue;
        }

        FLMutableDict_SetValue(newProps, currentKey, currentValue);
        FLDictIterator_Next(&d);
    }

    return true;
}

static void test_save_with_conflict_handler() {
    // tag::update-document-with-conflict-handler[]
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(database, NULL);
    CBLError err;
    
    CBLDocument* mutableDoc = CBLCollection_GetMutableDocument(collection, FLSTR("xyz"), &err);
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetString(properties, FLSTR("name"), FLSTR("apples"));

    /*
    static bool custom_conflict_handler(void* context, CBLDocument* documentBeingSaved,
        const CBLDocument* conflictingDocument) {
        FLDict currentProps = CBLDocument_Properties(conflictingDocument);
        FLDict updatedProps = CBLDocument_Properties(documentBeingSaved);
        FLMutableDict newProps = FLDict_MutableCopy(updatedProps, kFLDefaultCopy);

        FLDictIterator d;
        FLDictIterator_Begin(currentProps, &d);
        FLSlice currentKey = FLDictIterator_GetKeyString(&d);
        for(; currentKey.buf; currentKey = FLDictIterator_GetKeyString(&d)) {
            if(FLDict_Get(newProps, currentKey)) {
                continue;
            }

            FLValue currentValue = FLDictIterator_GetValue(&d);
            FLMutableDict_SetValue(newProps, currentKey, currentValue);
        }

        return true;
    }
    */
    CBLCollection_SaveDocumentWithConflictHandler(collection, mutableDoc, custom_conflict_handler, NULL, &err);

    // end::update-document-with-conflict-handler[]
}

static void use_encryption() {
    #ifdef COUCHBASE_ENTERPRISE

    // tag::database-encryption[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLDatabaseConfiguration config = CBLDatabaseConfiguration_Default();

    // This returns a boolean, so check it in production code
    CBLEncryptionKey_FromPassword(&config.encryptionKey, FLSTR("password"));

    CBLError err;
    CBLDatabase* db = CBLDatabase_Open(FLSTR("seekrit"), &config, &err);

    // Change the encryption key (or add encryption if the DB is unencrypted)
    CBLEncryptionKey betterKey;
    CBLEncryptionKey_FromPassword(&betterKey, FLSTR("betterpassw0rd"));
    CBLDatabase_ChangeEncryptionKey(db, &betterKey, &err);

    // Remove encryption
    CBLDatabase_ChangeEncryptionKey(db, NULL, &err);
    // end::database-encryption[]

    #endif
}

static void reset_replicator_checkpoint() {
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(FLSTR("ws://localhost:4984/db"), NULL);
    CBLReplicatorConfiguration config;
    memset(&config, 0, sizeof(CBLReplicatorConfiguration));
    config.database = kDatabase;
    config.endpoint = target;
    CBLReplicator* replicator = CBLReplicator_Create(&config, NULL);
    CBLEndpoint_Free(target);

    // tag::replication-reset-checkpoint-full[]
    // replicator is a CBLReplicator* instance
    CBLReplicator_Start(replicator, true); // <.>

    // end::replication-reset-checkpoint-full[]

    stop_replicator(replicator);
}

static void read_1x_attachment() {
    CBLDocument* document = CBLDocument_Create();

    // tag::1x-attachment[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    FLDict properties = CBLDocument_Properties(document);
    FLDict attachments = FLValue_AsDict(FLDict_Get(properties, FLSTR("_attachments")));
    const CBLBlob* avatar = FLDict_GetBlob(FLValue_AsDict(FLDict_Get(attachments, FLSTR("avatar"))));
    FLSliceResult content = CBLBlob_Content(avatar, &err);

    FLSliceResult_Release(content);
    // end::1x-attachment[]

    CBLDocument_Release(document);
}

static void create_new_database() {
    // tag::new-database[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDatabase* db = CBLDatabase_Open(FLSTR("my-database"), NULL, &err);
    // end::new-database[]

    kDatabase = db;
}

static void close_database() {
    CBLDatabase* db = kDatabase;
    // tag::close-database[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDatabase_Close(db, &err);
    // end::close-database[]
}

static void create_collection() {
    CBLDatabase *db = kDatabase;
    // tag::scopes-manage-create-collection[]

    CBLError err;
    CBLDatabase_CreateCollection(db, FLSTR("collA"), FLSTR("scopeA"), &err);
    //end::scopes-manage-create-collection[]
}

// tag::scopes-manage-index-collection[]
// We need to add a code sample to index a collection
// end::scopes-manage-index-collection[]

static void delete_collection(){
    CBLDatabase *db = kDatabase;
    // tag::scopes-manage-drop-collection[]

    CBLError err;
    CBLDatabase_DeleteCollection(db, FLSTR("collA"), FLSTR("scopeA"), &err);
    // end::scopes-manage-drop-collection[]
}

static void list_scopes_and_collections(){
    CBLDatabase *db = kDatabase;
    // tag::scopes-manage-list[]

    CBLError err;
    
    // Get Scopes
    FLMutableArray scopes = CBLDatabase_ScopeNames(db, &err);
    // Get default Scope
    CBLScope *scope = CBLDatabase_DefaultScope(db, &err);
    // Get specific Scope named scopeA
    CBLScope *scopeA = CBLDatabase_Scope(db, FLSTR("scopeA"), &err);
    // Get Collections of a specific Scope named scopeA
    FLMutableArray collections = CBLDatabase_CollectionNames(db, FLSTR("scopeA"), &err);
    // Get default Collection
    CBLCollection *collection = CBLDatabase_DefaultCollection(db, &err);
    // Get specific Collection named collA of a specific Scope named scopeA
    CBLCollection *collA = CBLDatabase_Collection(db, FLSTR("collA"), FLSTR("scopeA"), &err);
    // end::scopes-manage-list[]
}

static void change_logging() {
    // tag::logging[]
    // For output to stdout
    CBLLog_SetConsoleLevel(kCBLLogVerbose);

    // For output to custom logging
    CBLLog_SetCallbackLevel(kCBLLogVerbose);
    // end::logging[]
}

static void load_prebuilt() {
    CBL_DeleteDatabase(FLSTR("travel-sample.cblite2"), kFLSliceNull, NULL);

    // tag::prebuilt-database[]
    // Note: Getting the path to a database is platform-specific.  For desktop (including RPi)
    // this can be a simple filesystem path.  For iOS you need to get the path from the
    // main bundle.  For Android you need to extract it from your assets to a temporary directory
    // and then pass that path.

    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    const char* path = "/path/to/travel-sample.cblite2";
    if(!CBL_DatabaseExists(FLSTR("travel-sample.cblite2"), kFLSliceNull)) {
        CBL_CopyDatabase(FLStr(path), FLSTR("travel-sample"), NULL, &err);
    }
    // end::prebuilt-database[]

    CBLDatabase_Close(kDatabase, NULL);
    CBLDatabase_Release(kDatabase);
    kDatabase = CBLDatabase_Open(FLSTR("travel-sample"), NULL, NULL);
}

static void query_deleted_document() {
    CBLDatabase* db = kDatabase;

    // tag::query-deleted-documents[]
    // Query documents that have been deleted
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id FROM _ WHERE meta().deleted"), NULL, &err);
    // end::query-deleted-documents[]

    CBLQuery_Release(query);
}

static void create_document() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::initializer[]

    CBLDocument* doc = CBLDocument_CreateWithID(FLSTR("xyz"));
    FLMutableDict properties = CBLDocument_MutableProperties(doc);
    FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("task"));
    FLMutableDict_SetString(properties, FLSTR("owner"), FLSTR("todo"));

    // Storing time in millisecond, bluntly
    FLMutableDict_SetUInt(properties, FLSTR("createdAt"), time(NULL) * 1000);

    CBLError err;
    CBLCollection_SaveDocument(collection, doc, &err);
    CBLDocument_Release(doc);
    // end::initializer[]
}

static void update_document() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::update-document[]

    CBLError err;
    CBLDocument* mutableDoc = CBLCollection_GetMutableDocument(collection, FLSTR("xyz"), &err);
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetString(properties, FLSTR("name"), FLSTR("apples"));
    CBLCollection_SaveDocument(collection, mutableDoc, &err);
    CBLDocument_Release(mutableDoc);
    // end::update-document[]
}

// Note use_typed_accessors not applicable

static void do_batch_operation() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::batch[]

    CBLError err;
    CBLDatabase_BeginTransaction(database, &err);
    char buffer[7];
    for(int i = 0; i < 10; i++) {
        CBLDocument* doc = CBLDocument_Create();
        FLMutableDict properties = CBLDocument_MutableProperties(doc);
        FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("user"));
        sprintf(buffer, "user %d", i);
        FLMutableDict_SetString(properties, FLSTR("name"), FLStr(buffer));
        FLMutableDict_SetBool(properties, FLSTR("admin"), false);
        CBLCollection_SaveDocument(collection, doc, &err);
        CBLDocument_Release(doc);
        printf("Saved user document %s\n", buffer);
    }

    CBLDatabase_EndTransaction(database, true, &err);
    // end::batch[]
}

static void document_listener(void* context, const CBLDocumentChange* change) {
    CBLError err;
    const CBLDocument* doc = CBLCollection_GetDocument(change->collection, change->docID, &err);
    FLDict properties = CBLDocument_Properties(doc);
    FLString verified_account = FLValue_AsString(FLDict_Get(properties, FLSTR("verified_account")));
    printf("Status :: %.*s\n", (int)verified_account.size, (const char *)verified_account.buf);
    CBLDocument_Release(doc);
}

static void database_change_listener() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::document-listener[]
    /*
    static void document_listener(void* context, const CBLDocumentChange* change) {
    CBLError err;
        const CBLDocument* doc = CBLCollection_GetDocument(change->collection, change->docID, &err);
        FLDict properties = CBLDocument_Properties(doc);
        FLString verified_account = FLValue_AsString(FLDict_Get(properties, FLSTR("verified_account")));
        printf("Status :: %.*s\n", (int)verified_account.size, (const char *)verified_account.buf);
        CBLDocument_Release(doc);
    }
    */
    CBLListenerToken* token = CBLCollection_AddDocumentChangeListener(collection, FLSTR("user.john"),
        document_listener, NULL);
    // end::document-listener[]

    CBLListener_Remove(token);
}

static void document_expiration() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::document-expiration[]
    // Purge the document one day from now

    // Overly simplistic for example purposes
    // NOTE: API takes milliseconds
    time_t ttl = time(NULL) + 24 * 60 * 60;
    ttl *= 1000;

    CBLError err;
    CBLCollection_SetDocumentExpiration(collection, FLSTR("doc123"), ttl, &err);

    // Reset expiration
    CBLCollection_SetDocumentExpiration(collection, FLSTR("doc1"), 0, &err);

    // Query documents that will be expired in less than five minutes
    time_t fiveMinutesFromNow = time(NULL) + 5 * 60;
    fiveMinutesFromNow *= 1000;
    FLMutableDict parameters = FLMutableDict_New();
    FLMutableDict_SetInt(parameters, FLSTR("five_minutes"), fiveMinutesFromNow);

    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id FROM _ WHERE meta().expiration < $five_minutes"), NULL, &err);
    CBLQuery_SetParameters(query, parameters);
    FLMutableDict_Release(parameters);
    // end::document-expiration[]
}

static void use_blob() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    CBLDocument* newTask = CBLDocument_Create();

    // tag::blob[]
    // Note: Reading the data is implementation dependent, as with prebuilt databases
    // NOTE: No error handling, for brevity (see getting started)

    uint8_t buffer[128000];
    FILE* avatar_file = fopen("avatar.jpg", "rb");
    size_t read = fread(buffer, 1, 128000, avatar_file); // <.>

    FLSliceResult avatar = FLSliceResult_CreateWith(buffer, read);
    CBLBlob* blob = CBLBlob_CreateWithData(FLSTR("image/jpeg"), FLSliceResult_AsSlice(avatar)); // <.>
    FLSliceResult_Release(avatar);

    // TODO: Create shortcut blob method
    CBLError err;
    FLMutableDict properties = CBLDocument_MutableProperties(newTask);
    FLSlot_SetBlob(FLMutableDict_Set(properties, FLSTR("avatar")), blob);
    CBLCollection_SaveDocument(collection, newTask, &err); // <.>

    // end::blob[]



    CBLDocument_Release(newTask);
    CBLBlob_Release(blob);
}

static void doc_json() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::tojson-document[]
    FLString json = FLSTR("{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",\"country\":\"Australia\"}");

    // Create a document and set the JSON data to the document
    CBLError err;
    CBLDocument* newDoc = CBLDocument_CreateWithID(FLSTR("hotel_1002"));
    CBLDocument_SetJSON(newDoc, json, &err);

    // Save the document to the database
    CBLCollection_SaveDocument(collection, newDoc, &err);

    // Release created doc after using it
    CBLDocument_Release(newDoc);

    // Get the document from the database
    const CBLDocument* doc = CBLCollection_GetDocument(collection, FLSTR("hotel_1002"), &err);

    // Get document body as JSON
    FLSliceResult docJson = CBLDocument_CreateJSON(doc);
    printf("Document in JSON :: %.*s\n", (int)docJson.size, (const char *)docJson.buf);

    // Release JSON data after using it
    FLSliceResult_Release(docJson);

    // Release doc read from the database after using it
    CBLDocument_Release(doc);
    // end::tojson-document[]
}

static void dict_json() {
    // tag::tojson-dictionary[]
    FLString json = FLSTR("{\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",\"country\":\"Australia\"}");

    // Create a dictionary from the JSON string
    FLError err;
    FLSliceResult jsonData1 = FLData_ConvertJSON(json, &err);
    FLDict hotel = FLValue_AsDict(FLValue_FromData(FLSliceResult_AsSlice(jsonData1), kFLTrusted));

    // Iterate through the dictionary
    FLDictIterator iter;
    FLDictIterator_Begin(hotel, &iter);
    FLValue value;
    while (NULL != (value = FLDictIterator_GetValue(&iter))) {
        FLString key = FLDictIterator_GetKeyString(&iter);
        FLString strValue = FLValue_AsString(value);
        printf("%.*s :: %.*s\n", (int)key.size, (const char*)key.buf, (int)strValue.size, (const char*)strValue.buf);
        FLDictIterator_Next(&iter);
    }

    // Convert the dictionary to JSON
    FLSliceResult jsonData2 = FLValue_ToJSON((FLValue)hotel);
    printf("Hotel in JSON :: %.*s\n", (int)jsonData2.size, (const char *)jsonData2.buf);

    // Release JSON data after finish using it
    FLSliceResult_Release(jsonData1);
    FLSliceResult_Release(jsonData2);
    // end::tojson-dictionary[]
}

static void array_json() {
    // tag::tojson-array[]
    FLString json = FLSTR("[\"Hotel Ned\", \"Hotel Ted\"]");

    // Create an array from the JSON string
    FLError err;
    FLSliceResult jsonData1 = FLData_ConvertJSON(json, &err);
    FLArray hotels = FLValue_AsArray(FLValue_FromData(FLSliceResult_AsSlice(jsonData1), kFLTrusted));

    // Iterate through the array
    FLArrayIterator iter;
    FLArrayIterator_Begin(hotels, &iter);
    FLValue value;
    while (NULL != (value = FLArrayIterator_GetValue(&iter))) {
        FLString hotel = FLValue_AsString(value);
        printf("Hotel :: %.*s\n", (int)hotel.size, (const char *)hotel.buf);
        FLArrayIterator_Next(&iter);
    }

    // Convert the array to JSON
    FLSliceResult jsonData2 = FLValue_ToJSON((FLValue)hotels);
    printf("Hotels in JSON :: %.*s\n", (int)jsonData2.size, (const char *)jsonData2.buf);

    // Release JSON data after finish using it
    FLSliceResult_Release(jsonData1);
    FLSliceResult_Release(jsonData2);
    // end::tojson-array[]
}

static void blob_json() {
    // tag::tojson-blob[]
    const char *content = "This is the content of blob 1.";
    const size_t bufferSize = strlen(content);
    char buffer[bufferSize];
    FLSliceResult contentSlice = FLSliceResult_CreateWith(content, bufferSize);

    CBLBlob* blob = CBLBlob_CreateWithData(FLSTR("text/plain"), FLSliceResult_AsSlice(contentSlice));
    FLSliceResult_Release(contentSlice);
    // Blob to json
    FLStringResult json = CBLBlob_CreateJSON(blob);
    CBLBlob_Release(blob);
    // end::tojson-blob[]
}

static void datatype_dictionary()
{
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::datatype_dictionary[]
    CBLError err;
    const CBLDocument *doc = CBLCollection_GetDocument(collection, FLSTR("doc1"), &err);
    FLDict properties = CBLDocument_Properties(doc);

    // Getting a dictionary from the document's properties
    FLValue dictValue = FLDict_Get(properties, FLSTR("address"));
    FLDict dict = FLValue_AsDict(dictValue);

    // Access a value with a key from the dictionary
    FLValue streetVal = FLDict_Get(dict, FLSTR("street"));
    FLString street = FLValue_AsString(streetVal);

    // Iterate dictionary
    FLDictIterator iter;
    FLDictIterator_Begin(dict, &iter);
    FLValue value;
    while (NULL != (value = FLDictIterator_GetValue(&iter))) {
        FLString key = FLDictIterator_GetKeyString(&iter);
        FLString strValue = FLValue_AsString(value);
        printf("Key :: %.*s\n", (int)key.size, (const char *)key.buf);
        printf("Value :: %.*s\n", (int)strValue.size, (const char *)strValue.buf);
        // ...
        FLDictIterator_Next(&iter);
    }

    // Create a mutable copy.
    // kFLDefaultCopy is shallow which means the nested dictionaries and arrays will be
    // referenced but not copied. Use kFLDeepCopyImmutables for the deep copy.
    FLMutableDict mutableDict = FLDict_MutableCopy(dict, kFLDefaultCopy);

    // Release when finish using it
    FLMutableDict_Release(mutableDict);
    // end::datatype_dictionary[]
}

static void datatype_mutable_dictionary()
{
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::datatype_mutable_dictionary[]
    // tag::datatype_mutable_dictionary-create[]
    // Create a new mutable dictionary and populate some keys/values
    FLMutableDict dict = FLMutableDict_New();
    FLMutableDict_SetString(dict, FLSTR("street"), FLSTR("1 Main st."));
    FLMutableDict_SetString(dict, FLSTR("city"), FLSTR("San Francisco"));
    // end::datatype_mutable_dictionary-create[]

    // tag::datatype_mutable_dictionary-add-to-doc[]
    // Set the dictionary to document's properties and save the document
    CBLDocument *doc = CBLDocument_Create();
    FLMutableDict properties = CBLDocument_MutableProperties(doc);
    FLMutableDict_SetDict(properties, FLSTR("address"), dict);
    // end::datatype_mutable_dictionary-add-to-doc[]
    CBLError err;
    CBLCollection_SaveDocument(collection, doc, &err);
    CBLDocument_Release(doc);

    // Release when finish using it
    FLMutableDict_Release(dict);
    // end::datatype_mutable_dictionary[]
}

static void datatype_array()
{
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::datatype_array[]
    CBLError err;
    const CBLDocument *doc = CBLCollection_GetDocument(collection, FLSTR("doc1"), &err);
    FLDict properties = CBLDocument_Properties(doc);

    // Getting a phones array from the document's properties
    FLValue arrayValue = FLDict_Get(properties, FLSTR("phones"));
    FLArray array = FLValue_AsArray(arrayValue);

    // Get element count
    int count = FLArray_Count(array);
    printf("Count :: %d\n", count);

    // Access an array element by index
    if (!FLArray_IsEmpty(array)) {
        FLValue phoneVal = FLArray_Get(array, 0);
        FLString phone = FLValue_AsString(phoneVal);
        printf("Value :: %.*s\n", (int)phone.size, (const char *)phone.buf);
    }

    // Iterate array
    FLArrayIterator iter;
    FLArrayIterator_Begin(array, &iter);
    FLValue val;
    while (NULL != (val = FLArrayIterator_GetValue(&iter)))
    {
        FLString str = FLValue_AsString(val);
        printf("Value :: %.*s\n", (int)str.size, (const char *)str.buf);
        FLArrayIterator_Next(&iter);
    }
    // end::datatype_array[]

    // Create a mutable copy.
    // kFLDefaultCopy is shallow which means the nested dictionaries and arrays will be
    // referenced but not copied. Use kFLDeepCopyImmutables for the deep copy.
    FLMutableArray mutableArray = FLArray_MutableCopy(array, kFLDefaultCopy);

    // Release when finish using it
    FLMutableArray_Release(mutableArray);
}

static void datatype_mutable_array()
{
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::datatype_mutable_array[]
    // tag::datatype_mutable_array-create[]
    // Create a new mutable array and populate data into the array
    FLMutableArray phones = FLMutableArray_New();
    FLMutableArray_AppendString(phones, FLSTR("650-000-0000"));
    FLMutableArray_AppendString(phones, FLSTR("650-000-0001"));
    // end::datatype_mutable_array-create[]

    // tag::datatype_mutable_array-add-to-doc[]
    // Set the array to document's properties and save the document
    CBLDocument *doc = CBLDocument_Create();
    FLMutableDict properties = CBLDocument_MutableProperties(doc);
    FLMutableDict_SetArray(properties, FLSTR("phones"), phones);
    // end::datatype_mutable_array-add-to-doc[]
    CBLError err;
    CBLCollection_SaveDocument(collection, doc, &err);
    CBLDocument_Release(doc);

    // Release the created dictionary
    FLMutableArray_Release(phones);
    // end::datatype_mutable_array[]
}


static void datatype_usage() {

    // tag::datatype_usage[]
    // tag::datatype_usage_createdb[]
    // Open or create DB if it doesn't exist
    CBLError err;
    CBLDatabase* database = CBLDatabase_Open(FLSTR("mydb"), NULL, &err);
    
    if(!database) {
        return;
    }

    // Get default collections
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // end::datatype_usage_createdb[]
    // tag::datatype_usage_createdoc[]
    // Create your new document
    // The lack of 'const' indicates this document is mutable
    CBLDocument* mutableDoc = CBLDocument_Create();
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);

    // end::datatype_usage_createdoc[]
    // tag::datatype_usage_mutdict[]
    // Create and populate mutable dictionary
    FLMutableDict address = FLMutableDict_New();
    FLMutableDict_SetString(address, FLSTR("street"), FLSTR("1 Main st."));
    FLMutableDict_SetString(address, FLSTR("city"), FLSTR("San Francisco"));
    FLMutableDict_SetString(address, FLSTR("state"), FLSTR("CA"));
    FLMutableDict_SetString(address, FLSTR("country"), FLSTR("USA"));
    FLMutableDict_SetString(address, FLSTR("code"), FLSTR("90210"));

    // end::datatype_usage_mutdict[]
    // tag::datatype_usage_mutarray[]
    // Create and populate mutable array
    FLMutableArray phones = FLMutableArray_New();
    FLMutableArray_AppendString(phones, FLSTR("650-000-0000"));
    FLMutableArray_AppendString(phones, FLSTR("650-000-0001"));

    // end::datatype_usage_mutarray[]
    // tag::datatype_usage_populate[]
    // Initialize and populate the document

        // Add document type and hotel name as string
    FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("hotel"));
    FLMutableDict_SetString(properties, FLSTR("hotel"), FLSTR(""));

    // Add average room rate (float)
    FLMutableDict_SetFloat(properties, FLSTR("room_rate"), 121.75f);

    // Add address (dictionary)
    FLMutableDict_SetDict(properties, FLSTR("address"), address);

        // Add phone numbers(array)
    FLMutableDict_SetArray(properties, FLSTR("phones"), phones);

    // end::datatype_usage_populate[]
    {
    // tag::datatype_usage_persist[]
    CBLError err;
    CBLCollection_SaveDocument(collection, mutableDoc, &err);
    // end::datatype_usage_persist[]
    }

    {
    // tag::datatype_usage_closedb[]
    CBLError err;
    CBLDatabase_Close(database, &err);
    // end::datatype_usage_closedb[]
    }

    // tag::datatype_usage_release[]
    CBLDatabase_Release(database);
    CBLDocument_Release(mutableDoc);
    FLMutableDict_Release(address);
    FLMutableArray_Release(phones);
    // end::datatype_usage_release[]

    // end::datatype_usage[]

} // end datatype_usage()


static void create_index() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::query-index[]
    // For value types, this is optional but provides performance enhancements
    // NOTE: No error handling, for brevity (see getting started)

    // Syntax for second argument is the same as taking from a N1QL SELECT
    // i.e. SELECT (type, name) FROM _;
    CBLValueIndexConfiguration config = {
        kCBLN1QLLanguage,
        FLSTR("type, name")
    };

    CBLError err;
    CBLCollection_CreateValueIndex(collection, FLSTR("TypeNameIndex"), config, &err);
    // end::query-index[]
}

static void select_meta() {
    CBLDatabase* database = kDatabase;

    // tag::query-select-meta[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, type, name FROM _"), NULL, &err);
    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString id = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("id")));
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Document ID :: %.*s\n", (int)id.size, (const char *)id.buf);
        printf("Document Name :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-select-meta[]
}

static void select_id() {
    CBLDatabase* database = kDatabase;

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id FROM _"), NULL, &err);

    // tag::query-access-id[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString id = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("id")));
        printf("Document ID :: %.*s\n", (int)id.size, (const char *)id.buf);
    }
    // end::query-access-id[]

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
}

static void query_change_listener(void* context, CBLQuery* query, CBLListenerToken* token) {
    CBLError err;
    CBLResultSet* results = CBLQuery_CopyCurrentResults(query, token, &err);
    while(CBLResultSet_Next(results)) {
        // Update UI
    }
}

static void select_all() {
    CBLDatabase* database = kDatabase;

    {
    // tag::query-select-all[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _"), NULL, &err);

    // All results will be available from the above query
    CBLQuery_Release(query);
    // end::query-select-all[]
    }

    {
    // tag::live-query[]
    /*
    static void query_change_listener(void* context, CBLQuery* query, CBLListenerToken* token) {
        CBLError err;
        CBLResultSet* results = CBLQuery_CopyCurrentResults(query, token, &err);
        while(CBLResultSet_Next(results)) {
            // Update UI
        }
    }
    */

    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _"), NULL, &err); // <.>

    CBLListenerToken* token = CBLQuery_AddChangeListener(query, query_change_listener, NULL); // <.>
    // end::live-query[]
    }

    {
    CBLListenerToken* token;
    CBLQuery* query;
    // tag::stop-live-query[]
    CBLListener_Remove(token); // The token received from AddChangeListener
    CBLQuery_Release(query);
    // end::stop-live-query[]
    }
}

static void select_and_access_all() {
    CBLDatabase* database = kDatabase;

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _"), NULL, &err);

    // tag::query-access-all[]
    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLDict dict = FLValue_AsDict(CBLResultSet_ValueForKey(results, FLSTR("_")));

        FLString id = FLValue_AsString(FLDict_Get(dict, FLSTR("id")));
        FLString type = FLValue_AsString(FLDict_Get(dict, FLSTR("type")));
        FLString name = FLValue_AsString(FLDict_Get(dict, FLSTR("name")));
        FLString city = FLValue_AsString(FLDict_Get(dict, FLSTR("city")));

        printf("ID :: %.*s\n", (int)id.size, (const char *)id.buf);
        printf("Type :: %.*s\n", (int)type.size, (const char *)type.buf);
        printf("Name :: %.*s\n", (int)name.size, (const char *)name.buf);
        printf("City :: %.*s\n", (int)city.size, (const char *)city.buf);
    }

    // All results will be available from the above query
    CBLResultSet_Release(results);
    // end::query-access-all[]

    CBLQuery_Release(query);
}

static void select_props() {
    CBLDatabase* database = kDatabase;

    // tag::query-access-props[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT type, name, city FROM _"), NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString type = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("type")));
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        FLString city = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("city")));

        printf("Type :: %.*s\n", (int)type.size, (const char *)type.buf);
        printf("Name :: %.*s\n", (int)name.size, (const char *)name.buf);
        printf("City :: %.*s\n", (int)city.size, (const char *)city.buf);
    }
    // end::query-access-props[]

    // All results will be available from the above query
    CBLResultSet_Release(results);
    CBLQuery_Release(query);
}

static void select_where() {
    CBLDatabase* database = kDatabase;

    // tag::query-where[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _ WHERE type = \"hotel\" LIMIT 10"), NULL, &err);
    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLDict dict = FLValue_AsDict(CBLResultSet_ValueForKey(results, FLSTR("_")));
        FLString name = FLValue_AsString(FLDict_Get(dict, FLSTR("name")));
        printf("Document Name :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-where[]
}

static void use_collection_contains() {
    CBLDatabase* database = kDatabase;

    // tag::query-collection-operator-contains[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name, public_likes FROM _ WHERE type = \"hotel\" "
              "AND ARRAY_CONTAINS(public_likes, \"Armani Langworth\")"), NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLArray publicLikes = FLValue_AsArray(CBLResultSet_ValueForKey(results, FLSTR("public_likes")));
        FLStringResult json = FLValue_ToJSON((FLValue)publicLikes);
        printf("Public Likes :: %.*s\n", (int)json.size, (const char *)json.buf);
        FLSliceResult_Release(json);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-collection-operator-contains[]
}

static void use_collection_in() {
    CBLDatabase* database = kDatabase;

    // tag::query-collection-operator-in[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _ WHERE \"Armani\" IN (first, last, username)"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLDict body = FLValue_AsDict(CBLResultSet_ValueAtIndex(results, 0));
        FLStringResult json = FLValue_ToJSON((FLValue)body);
        printf("In results :: %.*s\n", (int)json.size, (const char *)json.buf);
        FLSliceResult_Release(json);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-collection-operator-in[]
}

static void select_like() {
    CBLDatabase* database = kDatabase;

    // tag::query-like-operator[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name FROM _ WHERE type = \"landmark\" "
              "AND lower(name) LIKE \"Royal Engineers Museum\" LIMIT 10"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Name Property :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-like-operator[]
}

static void select_wildcard_like() {
    CBLDatabase* database = kDatabase;

    // tag::query-like-operator-wildcard-match[]
    // NOTE: No error handling, for brevity (see getting started)

     CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name FROM _ WHERE type = \"landmark\" "
              "AND lower(name) LIKE \"Eng%e%\" LIMIT 10"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Name Property :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-like-operator-wildcard-match[]
}

static void select_wildcard_character_like() {
    CBLDatabase* database = kDatabase;

    // tag::query-like-operator-wildcard-character-match[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name FROM _ WHERE type = \"landmark\" "
              "AND lower(name) LIKE \"Royal Eng____rs Museum\" LIMIT 10"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Name Property :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-like-operator-wildcard-character-match[]
}

static void select_regex() {
    CBLDatabase* database = kDatabase;

    // tag::query-regex-operator[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name FROM _ WHERE type = \"landmark\" "
              "AND regexp_like(name, \"\\bEng.*e\\b\") LIMIT 10"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Name Property :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-regex-operator[]
}

static void select_join() {
    CBLDatabase* database = kDatabase;

    // tag::query-join[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT airline.name, airline.callsign, route.destinationairport, route.stops, route.airline "
              "FROM _ AS airline INNER JOIN _ AS route ON meta(airline).id = route.airlineid "
              "WHERE route.type = \"route\" AND airline.type = \"airline\" AND route.sourceairport = \"RIX\""),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString name = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("name")));
        printf("Name Property :: %.*s\n", (int)name.size, (const char *)name.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-join[]
}

static void group_by() {
    CBLDatabase* database = kDatabase;

    // tag::query-groupby[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT count(*), country, tz FROM _ WHERE type = \"airport\" AND geo.alt >= 300 "
              "GROUP BY country, tz"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        int64_t count = FLValue_AsInt(CBLResultSet_ValueForKey(results, FLSTR("$1")));
        FLString tz = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("tz")));
        FLString country = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("country")));
        printf("There are %" PRIi64 " airports in the %.*s timezone located in %.*s and above 300 ft\n",
            count, (int)tz.size, (const char *)tz.buf, (int)country.size, (const char *)country.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-groupby[]
}

static void order_by() {
    CBLDatabase* database = kDatabase;

    // tag::query-orderby[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, title FROM _ WHERE type = \"hotel\" ORDER BY title ASC LIMIT 10"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString title = FLValue_AsString(CBLResultSet_ValueForKey(results, FLSTR("title")));
        printf("Title :: %.*s\n", (int)title.size, (const char *)title.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::query-orderby[]
}

static void test_explain_statement() {
    CBLDatabase* database = kDatabase;

    {
    // tag::query-explain-all[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _ WHERE type = \"hotel\" GROUP BY country ORDER BY title ASC LIMIT 10"),
        NULL, &err);

    FLSliceResult explanation = CBLQuery_Explain(query);
    printf("%.*s", (int)explanation.size, (const char *)explanation.buf);
    FLSliceResult_Release(explanation);
    // end::query-explain-all[]
    }

    // DOCS NOTE: Others omitted for now
}

static void query_result_json() {
    CBLDatabase* database = kDatabase;

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id as id, name, city, type FROM _ LIMIT 10"),
        NULL, &err);

    // tag::query-access-json[]
    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLDict result = CBLResultSet_ResultDict(results);
        FLStringResult json = FLValue_ToJSON((FLValue)result);
        printf("JSON Result :: %.*s\n", (int)json.size, (const char *)json.buf);
        FLSliceResult_Release(json);
    }
    CBLResultSet_Release(results);

    // end::query-access-json[]

    CBLQuery_Release(query);
}

static void create_full_text_index() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    const char* tasks[] = { "buy groceries", "play chess", "book travels", "buy museum tickets" };
    char idBuffer[7];
    for(int i = 0; i < 4; i++) {
        const char* task = tasks[i];
        sprintf(idBuffer, "extra%d", i);
        const CBLDocument* doc = CBLCollection_GetDocument(collection, FLStr(idBuffer), NULL);
        if(doc) {
            CBLDocument_Release(doc);
            continue;
        }

        CBLDocument* mutableDoc = CBLDocument_CreateWithID(FLStr(idBuffer));
        FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
        FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("task"));
        FLMutableDict_SetString(properties, FLSTR("task"), FLStr(task));
        CBLCollection_SaveDocument(collection, mutableDoc, NULL);
        CBLDocument_Release(mutableDoc);
    }

    // tag::fts-index[]

    CBLError err;
    CBLFullTextIndexConfiguration config = {
        kCBLN1QLLanguage,
        FLSTR("name"),
        false
    };

    CBLCollection_CreateFullTextIndex(collection, FLSTR("nameFTSIndex"), config, &err);
    // end::fts-index[]
}

static void full_text_search() {
    CBLDatabase* database = kDatabase;

    // tag::fts-query[]

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id FROM _ WHERE MATCH(nameFTSIndex, \"'buy'\")"),
        NULL, &err);

    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        FLString id = FLValue_AsString(CBLResultSet_ValueAtIndex(results, 0));
        printf("Document id :: %.*s\n", (int)id.size, (const char *)id.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::fts-query[]
}

static void start_replication() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    /*
    * This requires Sync Gateway running with the following config, or equivalent:
    *
    * {
    *     "log":["*"],
    *     "databases": {
    *         "db": {
    *             "server":"walrus:",
    *             "users": {
    *                 "GUEST": {"disabled": false, "admin_channels": ["*"] }
    *             }
    *         }
    *     }
    * }
    */

    // tag::replication[]
    // NOTE: No error handling, for brevity (see getting started)
    // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err);

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target;
    replConfig.replicatorType = kCBLReplicatorTypePull;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);
    CBLReplicator_Start(replicator, false);
    // end::replication[]

    stop_replicator(replicator);
}

// Console logging domain methods are not applicable to C

static void file_logging() {
    // tag::file-logging[]
    // NOTE: No error handling, for brevity (see getting started)
    // NOTE: You will need to use a platform appropriate method for finding
    // a temporary directory

    FLString tempFolder = FLSTR("/tmp/cbllog");

    CBLLogFileConfiguration config; // Don't bother zeroing, since we set all properties
    config.level = kCBLLogInfo;
    config.directory = tempFolder;
    config.maxRotateCount = 5;
    config.maxSize = 10240;
    config.usePlaintext = false;

    CBLError err;
    CBLLog_SetFileConfig(config, &err);
    // end::file-logging[]
}

// tag::custom-logging[]
static void custom_log_callback(CBLLogDomain domain, CBLLogLevel level, FLString message) {
    // handle the message, for example piping it to
    // a third party framework
}
// end::custom-logging[]

static void enable_custom_logging() {
    // tag::set-custom-logging[]
    CBLLog_SetCallback(custom_log_callback);
    // end::set-custom-logging[]
}

static void enable_basic_auth() {
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::basic-authentication-full[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/mydatabase");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err);
    CBLAuthenticator* basicAuth = CBLAuth_CreatePassword(FLSTR("john"), FLSTR("pass"));

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target;
    replConfig.authenticator = basicAuth;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);
    CBLAuth_Free(basicAuth);

    CBLReplicator_Start(replicator, false);
    // end::basic-authentication-full[]

    stop_replicator(replicator);
}

static void docsonly_N1QL_Params(CBLDatabase* argDb)
{
    CBLDatabase* database = argDb;

    // tag::query-syntax-n1ql-params[]
    int errorPos;

    CBLError err;

    FLString n1qlstr = FLSTR("SELECT * FROM _ WHERE type = $type");

    FLMutableDict n1qlparams = FLMutableDict_New();
    FLMutableDict_SetString(n1qlparams, FLSTR("type"), FLSTR("hotel"));

    CBLQuery* query = CBLDatabase_CreateQuery(database,
                          kCBLN1QLLanguage,
                          n1qlstr,
                          &errorPos,
                          &err);

    CBLQuery_SetParameters(query, n1qlparams);

    if(!query) {
        /* Do appropriate error handling ...
            Note that (where applicable) errorPos contains the position
            in the N1QL string that the parse failed
        */
        FLMutableDict_Release(n1qlparams);
        CBLQuery_Release(query);
        return;
    }

    CBLResultSet* result = CBLQuery_Execute(query, &err);
    if(!result) {
        // Failed to run query, do error handling ...
        return;
    }

    // Release query when finished with
    FLMutableDict_Release(n1qlparams);
    CBLQuery_Release(query);

    // ... process results as required

    // Release result set then finished with
    CBLResultSet_Release(result);

    // end::query-syntax-n1ql-params[]
}

// DOCS NOTE
// Page=Data Sync >> Configuration Summary
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#configuration-summary
static void docs_act_replication(CBLDatabase* argDb)
{
    CBLDatabase* database = argDb;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    /*
    * This requires Sync Gateway running with the following config, or equivalent:
    *
    * {
    *     "log":["*"],
    *     "databases": {
    *         "db": {
    *             "server":"walrus:",
    *             "users": {
    *                 "GUEST": {"disabled": false, "admin_channels": ["*"] }
    *             }
    *         }
    *     }
    * }
    */

    // tag::p2p-act-rep-func[]
    // Purpose -- Show configuration , initialization and running of a replicator

    // NOTE: No error handling, for brevity (see getting started)
    // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err); // <.>

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target; // <.>

    // tag::p2p-act-rep-config-cont[]
    // Set replication direction and mode
    replConfig.replicatorType = kCBLReplicatorTypePull; // <.>
    replConfig.continuous = true;

    // end::p2p-act-rep-config-cont[]

    // Optionally, set auto-purge behavior (here we override default)
    replConfig.disableAutoPurge = true; // <.>

    // Optionally, configure Client Authentication
    // Here we are using to Basic Authentication,
    // Providing username and password credentials
    CBLAuthenticator* basicAuth =
        CBLAuth_CreatePassword(FLSTR("username"),
                               FLSTR("passwd")); // <.>
    replConfig.authenticator = basicAuth;

    // Optionally, configure how we handle conflicts (note that this is set
    // per collection, and not on the overall replicator)
    collectionConfig.conflictResolver = simpleConflictResolver_localWins; // <.>

    // Initialize replicator with created config
    CBLReplicator* replicator =
        CBLReplicator_Create(&replConfig, &err); // <.>

    CBLEndpoint_Free(target);

    // Optionally, add change listener
    CBLListenerToken* token =
            CBLReplicator_AddChangeListener(replicator,
                                            simpleChangeListener,
                                            NULL); // <.>

    // Start replication
    CBLReplicator_Start(replicator, false); // <.>

    // end::p2p-act-rep-func[]

    //    ... other processing as required

    // When finished release resources e.g.
    CBLAuth_Free(basicAuth);
    stop_replicator(replicator);
}
// END configuration summary snippets


// DOCS NOTE:
// Page=Data Sync >> Configuration
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#configuration-summary
// This function is not pulled into docs en-bloc
// it is a slightly more in-depth than the configurationsummary above
// and the snippets within it are used individually or in sets
// to illustrate specific points as required
//
static void docs_act_replication_config_section_snippets()
{
    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);
    bool docs_example_ShowBasicAuth = false;
    bool docs_example_ShowSessionAuth = false;

    /*
    * This requires Sync Gateway running with the following config, or equivalent:
    *
    * {
    *     "log":["*"],
    *     "databases": {
    *         "db": {
    *             "server":"walrus:",
    *             "users": {
    *                 "GUEST": {"disabled": false, "admin_channels": ["*"] }
    *             }
    *         }
    *     }
    * }
    */
    // tag::p2p-act-rep-func-full[]
    // NOTE: No error handling, for brevity (see getting started)
    // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)

    // tag::sgw-act-rep-initialize[]
    // Initialize the configuration object and set db target
    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target =
        CBLEndpoint_CreateWithURL(url, &err); // <.>

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target; // <.>

    // end::sgw-act-rep-initialize[]

    //    tag::p2p-act-rep-config-type[]
    replConfig.replicatorType = kCBLReplicatorTypePull;

    //    end::p2p-act-rep-config-type[]
    //    tag::p2p-act-rep-config-cont[]
    replConfig.continuous = true;

    //    end::p2p-act-rep-config-cont[]
    // tag::replication-retry-config[]
    // Configure replication retries
    // tag::replication-set-heartbeat[]
    replConfig.heartbeat = 120; //  <.>

    // end::replication-set-heartbeat[]
    // tag::replication-set-maxattempts[]
    replConfig.maxAttempts = 20; //  <.>

    // end::replication-set-maxattempts[]
    // tag::replication-set-maxattemptwaittime[]
    replConfig.maxAttemptWaitTime = 600; //  <.>

    // end::replication-set-maxattemptwaittime[]
    // end::replication-retry-config[]
    // tag::basic-authentication[]
    // Configure Client Authentication to Basic Authentication
    // Providing username and password credentials
    if(docs_example_ShowBasicAuth) {
        CBLAuthenticator* basicAuth =
            CBLAuth_CreatePassword(FLSTR("username"),
                                   FLSTR("passwd"));
        replConfig.authenticator = basicAuth; // <.>
    }
    // end::basic-authentication[]

    // tag::session-authentication[]
    if(docs_example_ShowSessionAuth) {
        CBLAuthenticator* sessionAuth =
            CBLAuth_CreateSession(FLSTR("904ac010862f37c8dd99015a33ab5a3565fd8447"),
                                  FLSTR("optionalCookieName"));
        replConfig.authenticator = sessionAuth; // <.>
    }

    // end::session-authentication[]

    // tag::replication-custom-header[]
    // Optionally, add custom headers
    FLMutableDict customHdrs = FLMutableDict_New();
    FLMutableDict_SetString(customHdrs,
                            FLSTR("customHeaderName"),
                            FLSTR("customHeaderValue"));

    replConfig.headers = customHdrs;

    // tag::certificate-pinning[]
    char cert_buf[10000];
    FILE* cert_file = fopen("cert.pem", "r");
    size_t read = fread(cert_buf, 1, sizeof(cert_buf), cert_file);
    replConfig.pinnedServerCertificate = (FLSlice){cert_buf, read};
    // end::certificate-pinning[]

    // end::replication-custom-header[]
    // FILTERS
    // tag::replication-push-filter[]
    // tag::replication-pull-filter[]
    // Purpose - Illustrate use of push and-or pull filter functions

    // NOTE: Push and pull filters are set per collection
    collectionConfig.pushFilter = simpleReplicationFilter;

    collectionConfig.pullFilter = simpleReplicationFilter;

    // end::replication-pull-filter[]
    // end::replication-push-filter[]

    //  Auto-purge over-ride
    // tag::autopurge-override[]
    replConfig.disableAutoPurge = true; // <.>

    // end::autopurge-override[]
    // Initialize replicator with created config
    CBLReplicator* replicator =
        CBLReplicator_Create(&replConfig, &err); // <.>

    CBLEndpoint_Free(target);

    // Add optional change listener
    CBLListenerToken* token_ReplChangeListener =
        CBLReplicator_AddChangeListener(replicator,
                                        simpleChangeListener,
                                        NULL); // <.>
}
// END replication.html >> configure section


// PAGE=Data Sync >> Initialize section
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#lbl-init-repl
static CBLReplicator* docs_act_replication_Intialize(
                        void* context,
                        CBLReplicatorConfiguration argConfig,
                        bool argResetRequired)
{
    CBLError err;
    bool docs_example_resetRequired = argResetRequired;
    // tag::p2p-act-rep-start-full[]
    CBLReplicator* replicator =
    CBLReplicator_Create(&argConfig, &err); // <.>

    // end::p2p-act-rep-start-full[]
    if(!docs_example_resetRequired) {
    // tag::p2p-act-rep-start-full[]
      CBLReplicator_Start(replicator, false); // <.>

    // end::p2p-act-rep-start-full[]
    } else {
    // tag::replication-reset-checkpoint[]
      CBLReplicator_Start(replicator, true); // <.>

    // end::replication-reset-checkpoint[]
    }
    return replicator;
}
// END replication.html >> initialize section

// PAGE=Data Sync >> Monitor section
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#lbl-repl-mon
static void docs_act_replication_Monitor(
                                       void* context,
                                       CBLReplicator* argRepl) {
    CBLError err;
    CBLReplicator* replicator = argRepl;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);
    // tag::p2p-act-rep-add-change-listener[]
    // Purpose -- illustrate addition of a Replicator change listener
    CBLListenerToken* token_ReplChangeListener =
            CBLReplicator_AddChangeListener(replicator,
                                            simpleChangeListener,
                                            NULL);

    // end::p2p-act-rep-add-change-listener[]
    // tag::add-document-replication-listener[]
    // Purpose -- illustrate addition of a Document Replicator  listener
    CBLListenerToken* token_ReplDocListener =
            CBLReplicator_AddDocumentReplicationListener(
                                                        replicator,
                                                        SimpleReplicationDocumentListener,
                                                        context);

    // end::add-document-replication-listener[]
    // tag::remove-document-replication-listener[]
    // Purpose -- illustrate removal of a listener
    CBLListener_Remove(token_ReplDocListener);
    CBLListener_Remove(token_ReplChangeListener);

    // end::remove-document-replication-listener[]

    // tag::p2p-act-rep-status[]
    // Purpose -- illustrate use of CBLReplicator_Status()
    CBLReplicatorStatus thisState = CBLReplicator_Status(replicator);
    if(thisState.activity==kCBLReplicatorStopped) {
        if(thisState.error.code==0) {
            CBLReplicator_Start(replicator,false);
        } else {
            printf("Replicator stopped -- code %d", thisState.error.code);
            // ... handle error ...
            CBLReplicator_Release(replicator);
        }
    }

    // end::p2p-act-rep-status[]
    // tag::replication-pendingdocuments[]
    FLDict thisPendingIdList =
        CBLReplicator_PendingDocumentIDs2(replicator, collection, &err); // <.>
    if(!FLDict_IsEmpty(thisPendingIdList)) {
        FLDictIterator item;
        FLDictIterator_Begin(thisPendingIdList, &item);
        FLValue itemValue;
        FLString pendingId;
        while(NULL != (itemValue = FLDictIterator_GetValue(&item))) {
            pendingId = FLValue_AsString(itemValue);
            if(CBLReplicator_IsDocumentPending2(replicator,
                                               pendingId,
                                               collection,
                                               &err)) {
                // ... process the still pending docid as required <.>
            } else {
                // Doc Id no longer pending
                if(err.code==0) {
                    // No fail so must have already been pushed
                    printf("Document already pushed");
                } else {
                    // Error detected so handle it
                    printf("Error code %d checking for pendingId", err.code);
                    break;
                }
            }
            FLDictIterator_Next(&item);
        }
        FLDictIterator_End(&item);
        FLValue_Release(itemValue);
    } else {
        printf("No Pending Id Docs to process");
    }
    FLDict_Release(thisPendingIdList);

    // end::replication-pendingdocuments[]
}
// END replication.html >> Monitor section

// BEGIN replication.html >> Stop section
// PAGE=Data Sync >> Stop
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#lbl-repl-stop
static void docs_act_replication_Stop(
                                       void* context,
                                       CBLReplicator* argRepl) {
    // tag::p2p-act-rep-stop[]
    // Purpose -- show how to stop a replication
    if(CBLReplicator_Status(argRepl).activity!=kCBLReplicatorStopped) {
        CBLReplicator_Stop(argRepl);
    }

    // end::p2p-act-rep-stop[]
}
// END replication.html >> Stop section

static void replication_error_handling() {
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);
    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err);

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);



    stop_replicator(replicator);
}

static void create_encryptable() {
    #ifdef COUCHBASE_ENTERPRISE

    // tag::encryptable[]
    // NOTE: No error handling, for brevity (see getting started)

    // Create with premitive type
    CBLEncryptable* encNull = CBLEncryptable_CreateWithNull();
    CBLEncryptable* encBool = CBLEncryptable_CreateWithBool(true);
    CBLEncryptable* encInt = CBLEncryptable_CreateWithInt(256);
    CBLEncryptable* encUInt = CBLEncryptable_CreateWithUInt(1024);
    CBLEncryptable* encFloat = CBLEncryptable_CreateWithFloat(1.2);
    CBLEncryptable* encDouble = CBLEncryptable_CreateWithDouble(100.50);
    CBLEncryptable* encString = CBLEncryptable_CreateWithString(FLSTR("foo"));

    // Create with dictionary
    FLMutableDict dict = FLMutableDict_New();
    FLSlot_SetString(FLMutableDict_Set(dict, FLSTR("greeting")), FLSTR("hello"));
    CBLEncryptable* encDict = CBLEncryptable_CreateWithDict(dict);

    // Create with array
    FLMutableArray array = FLMutableArray_New();
    FLSlot_SetString(FLMutableArray_Append(array), FLSTR("item1"));
    CBLEncryptable* encArray = CBLEncryptable_CreateWithArray(array);

    // Create with FLValue
    FLMutableDict dict2 = FLMutableDict_New();
    FLSlot_SetString(FLMutableDict_Set(dict2, FLSTR("greeting")), FLSTR("hello"));
    CBLEncryptable* encValue = CBLEncryptable_CreateWithValue((FLValue)dict2);
    // end::encryptable[]

    // Release after using it
    CBLEncryptable_Release(encNull);
    CBLEncryptable_Release(encBool);
    CBLEncryptable_Release(encInt);
    CBLEncryptable_Release(encBool);
    CBLEncryptable_Release(encUInt);
    CBLEncryptable_Release(encFloat);
    CBLEncryptable_Release(encDouble);
    CBLEncryptable_Release(encString);
    CBLEncryptable_Release(encDict);
    CBLEncryptable_Release(encArray);
    CBLEncryptable_Release(encValue);

    FLMutableDict_Release(dict);
    FLMutableDict_Release(dict2);
    FLMutableArray_Release(array);

    #endif
}

static void release_encryptable() {
    #ifdef COUCHBASE_ENTERPRISE

    CBLEncryptable* encValue = CBLEncryptable_CreateWithString(FLSTR("foo"));
    // tag::release_encryptable[]
    // Release the encryptable value after finish using it
    CBLEncryptable_Release(encValue);
    // end::release_encryptable[]

    #endif
}

static void use_encryptable() {
    #ifdef COUCHBASE_ENTERPRISE

    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::use_encryptable[]
    // NOTE: No error handling, for brevity (see getting started)
    CBLDocument* doc = CBLDocument_CreateWithID(FLSTR("doc1"));

    // Set encryptable:
    FLMutableDict props = CBLDocument_MutableProperties(doc);
    CBLEncryptable* encryptable = CBLEncryptable_CreateWithString(FLSTR("My secret"));
    FLSlot_SetEncryptableValue(FLMutableDict_Set(props, FLSTR("secret")), encryptable);

    CBLError error;
    CBLCollection_SaveDocument(collection, doc, &error);

    // Release
    CBLDocument_Release(doc);
    CBLEncryptable_Release(encryptable);
    // end::release_encryptable[]

    #endif
}

static void query_encryptable() {
    #ifdef COUCHBASE_ENTERPRISE

    CBLDatabase* database = kDatabase;

    // tag::use_encryptable[]
    // NOTE: No error handling, for brevity (see getting started)
    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
        FLSTR("SELECT secret, secret.value as secretValue FROM _ WHERE type = \"profile\""), NULL, &err);
    CBLResultSet* results = CBLQuery_Execute(query, &err);
    while(CBLResultSet_Next(results)) {
        // Get secret as CBLEncryptable value
        FLValue value = CBLResultSet_ValueForKey(results, FLSTR("secret"));
        const CBLEncryptable* encValue = FLValue_GetEncryptableValue(value);
        FLString secretStr = FLValue_AsString(CBLEncryptable_Value(encValue));
        printf("Secret :: %.*s\n", (int)secretStr.size, (const char *)secretStr.buf);

        // Get secret value directly
        value = CBLResultSet_ValueForKey(results, FLSTR("secretValue"));
        secretStr = FLValue_AsString(value);
        printf("Secret :: %.*s\n", (int)secretStr.size, (const char *)secretStr.buf);
    }

    CBLResultSet_Release(results);
    CBLQuery_Release(query);
    // end::release_encryptable[]

    #endif
}

#ifdef COUCHBASE_ENTERPRISE

// tag::replicator_property_encryption[]
// tag::replicator_property_encryptor_decryptor_sample[]
// Purpose: Declare property-level encryptor callback functions
static FLSliceResult my_cipher_function(FLSlice input) {
    FLSliceResult result = FLSliceResult_New(input.size);
    for(int i = 0; i < input.size; ++i) {
        ((uint8_t*)(result.buf))[i] = ((uint8_t*)input.buf)[i] ^ 'K';}
    return result;
}


static FLSliceResult property_encryptor(void* context, FLString docID, FLDict props, FLString path,
                                        FLSlice input, FLStringResult* algorithm, FLStringResult* keyID, CBLError* error) {
    *algorithm = FLSlice_Copy(FLSTR("MyEnc"));
    return my_cipher_function(input);
}


static FLSliceResult property_decryptor(void* context, FLString documentID, FLDict properties, FLString keyPath,
                                        FLSlice input, FLString algorithm, FLString keyID, CBLError* error) {
    return my_cipher_function(input);
}

// end::replicator_property_encryptor_decryptor_sample[]
// end::replicator_property_encryption[]

#endif

// PAGE=Field Level Encryption
// URL=https://docs.couchbase.com/couchbase-lite/current/c/field-level-encryption.html
//
static void replicator_property_encryption() {
    #ifdef COUCHBASE_ENTERPRISE

    CBLDatabase* database = kDatabase;
    CBLCollection* collection = CBLDatabase_DefaultCollection(kDatabase, NULL);

    // tag::replicator_property_encryption[]
    // Purpose: Show how to declare en(de)cryptors in replicator config
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err);

    CBLReplicationCollection collectionConfig;
    memset(&collectionConfig, 0, sizeof(CBLReplicationCollection));
    collectionConfig.collection = collection;

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(CBLReplicatorConfiguration));
    replConfig.collectionCount = 1;
    replConfig.collections = &collectionConfig;
    replConfig.endpoint = target;
    replConfig.propertyEncryptor = property_encryptor; // <.>
    replConfig.propertyDecryptor = property_decryptor; // <.>

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);

    CBLReplicator_Start(replicator, false);
    // end::replicator_property_encryption[]

    stop_replicator(replicator);

    #endif
}

int main(int argc, char** argv) {
    create_new_database();
    create_document();
    update_document();
    do_batch_operation();
    // Disable use_blob() as no avatar.jpg to load and crash
    // use_blob();
    doc_json();
    dict_json();
    array_json();
    load_prebuilt();
    create_index();
    select_all();
    select_and_access_all();
    select_props();
    select_meta();
    select_id();
    select_where();
    use_collection_contains();
    select_like();
    select_wildcard_like();
    select_wildcard_character_like();
    select_regex();
    select_join();
    group_by();
    order_by();
    query_result_json();

    create_full_text_index();
    full_text_search();
    start_replication();
    replicator_property_encryption();

    CBLDatabase_Close(kDatabase, NULL);

    return 0;
}
