#include <cbl/CouchbaseLite.h>

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
static CBLReplicator* kReplicator;

static void getting_started_change_listener(void* context, CBLReplicator* repl, const CBLReplicatorStatus* status) {
    if(status->error.code != 0) {
        printf("Error %d / %d\n", status->error.domain, status->error.code);
    }
}

static void getting_started() {
    // tag::getting-started[]
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

    // The lack of 'const' indicates this document is mutable
    // Create a new document (i.e. a record) in the database
    CBLDocument* mutableDoc = CBLDocument_Create();
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetFloat(properties, FLSTR("version"), 3.0f);

    // Save it to the database
    if(!CBLDatabase_SaveDocument(database, mutableDoc, &err)) {
        // Failed to save, do error handling as above
        return;
    }

    // Since we will release the document, make a copy of the ID since it
    // is an internal pointer.  Whenever we create or get an FLSliceResult
    // or FLStringResult we will need to free it later too!
    FLStringResult id = FLSlice_Copy(CBLDocument_ID(mutableDoc));
    CBLDocument_Release(mutableDoc);

    // Update a document
    mutableDoc = CBLDatabase_GetMutableDocument(database, FLSliceResult_AsSlice(id), &err);
    if(!mutableDoc) {
        // Failed to retrieve, do error handling as above.  NOTE: error code 0 simply means
        // the document does not exist.
        return;
    }

    properties = CBLDocument_MutableProperties(mutableDoc);
    FLMutableDict_SetString(properties, FLSTR("language"), FLSTR("C"));
    if(!CBLDatabase_SaveDocument(database, mutableDoc, &err)) {
        // Failed to save, do error handling as above
        return;
    }

    // Note const here, means readonly
    const CBLDocument* docAgain = CBLDatabase_GetDocument(database, FLSliceResult_AsSlice(id), &err);
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
    FLSliceResult_Release(id);

    // tag::query-syntax-n1ql-params[]
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
    // end::query-syntax-n1ql-params[]

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

    CBLListener_Remove(token);
    kReplicator = replicator;
}

// tag::local-win-conflict-resolver[]
static const CBLDocument* local_win_conflict_resolver(void* context, FLString documentID,
    const CBLDocument* localDocument, const CBLDocument* remoteDocument) {
    return localDocument;
}
// end::local-win-conflict-resolver[]

static void test_replicator_conflict_resolve() {
    CBLDatabase* database = kDatabase;

    // tag::replication-conflict-resolver[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(FLSTR("ws://localhost:4984/mydatabase"), &err);

    CBLReplicatorConfiguration replConfig;
    memset(&replConfig, 0, sizeof(replConfig));
    replConfig.database = database;
    replConfig.endpoint = target;
    replConfig.conflictResolver = local_win_conflict_resolver;

    CBLReplicator* replicator = CBLReplicator_Create(&replConfig, &err);
    CBLEndpoint_Free(target);
    CBLReplicator_Start(replicator, false);

    // end::replication-conflict-resolver[]
}

static bool custom_conflict_handler(void* context, CBLDocument* documentBeingSaved,
    const CBLDocument* conflictingDocument) {
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
    CBLDatabase* database = kDatabase;

    // tag::update-document-with-conflict-handler[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDocument* mutableDocument = CBLDatabase_GetMutableDocument(database, FLSTR("xyz"), &err);
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDocument);
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
    CBLDatabase_SaveDocumentWithConflictHandler(database, mutableDocument, custom_conflict_handler, NULL, &err);

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

    CBLReplicator_Release(replicator);
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
    CBLDatabase* db = kDatabase;

    // tag::initializer[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLDocument* newTask = CBLDocument_CreateWithID(FLSTR("xyz"));
    FLMutableDict properties = CBLDocument_MutableProperties(newTask);
    FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("task"));
    FLMutableDict_SetString(properties, FLSTR("owner"), FLSTR("todo"));

    // Storing time in millisecond, bluntly
    FLMutableDict_SetUInt(properties, FLSTR("createdAt"), time(NULL) * 1000);

    CBLError err;
    CBLDatabase_SaveDocument(db, newTask, &err);
    CBLDocument_Release(newTask);
    // end::initializer[]
}

static void update_document() {
    CBLDatabase* db = kDatabase;

    // tag::update-document[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDocument* mutableDocument = CBLDatabase_GetMutableDocument(db, FLSTR("xyz"), &err);
    FLMutableDict properties = CBLDocument_MutableProperties(mutableDocument);
    FLMutableDict_SetString(properties, FLSTR("name"), FLSTR("apples"));
    CBLDatabase_SaveDocument(db, mutableDocument, &err);
    CBLDocument_Release(mutableDocument);
    // end::update-document[]
}

// Note use_typed_accessors not applicable

static void do_batch_operation() {
    CBLDatabase* db = kDatabase;

    // tag::batch[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDatabase_BeginTransaction(db, &err);
    char buffer[7];
    for(int i = 0; i < 10; i++) {
        CBLDocument* doc = CBLDocument_Create();
        FLMutableDict properties = CBLDocument_MutableProperties(doc);
        FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("user"));
        sprintf(buffer, "user %d", i);
        FLMutableDict_SetString(properties, FLSTR("name"), FLStr(buffer));
        FLMutableDict_SetBool(properties, FLSTR("admin"), false);
        CBLDatabase_SaveDocument(db, doc, &err);
        CBLDocument_Release(doc);
        printf("Saved user document %s\n", buffer);
    }

    CBLDatabase_EndTransaction(db, true, &err);
    // end::batch[]
}

static void document_listener(void* context, const CBLDatabase* db, FLString id) {
    CBLError err;
    const CBLDocument* doc = CBLDatabase_GetDocument(db, id, &err);
    FLDict properties = CBLDocument_Properties(doc);
    FLString verified_account = FLValue_AsString(FLDict_Get(properties, FLSTR("verified_account")));
    printf("Status :: %.*s\n", (int)verified_account.size, (const char *)verified_account.buf);
    CBLDocument_Release(doc);
}

static void database_change_listener() {
    CBLDatabase* db = kDatabase;

    // tag::document-listener[]
    /*
    static void document_listener(void* context, const CBLDatabase* db, FLString id) {
        CBLError err;
        const CBLDocument* doc = CBLDatabase_GetDocument(db, id, &err);
        FLDict properties = CBLDocument_Properties(doc);
        FLString verified_account = FLValue_AsString(FLDict_Get(properties, FLSTR("verified_account")));
        printf("Status :: %.*s\n", (int)verified_account.size, (const char *)verified_account.buf);
        CBLDocument_Release(doc);
    }
    */

    CBLListenerToken* token = CBLDatabase_AddDocumentChangeListener(db, FLSTR("user.john"),
        document_listener, NULL);
    // end::document-listener[]

    CBLListener_Remove(token);
}

static void document_expiration() {
    CBLDatabase* db = kDatabase;

    // tag::document-expiration[]
    // Purge the document one day from now

    // Overly simplistic for example purposes
    // NOTE: API takes milliseconds
    // NOTE: No error handling, for brevity (see getting started)
    time_t ttl = time(NULL) + 24 * 60 * 60;
    ttl *= 1000;

    CBLError err;
    CBLDatabase_SetDocumentExpiration(db, FLSTR("doc123"), ttl, &err);

    // Reset expiration
    CBLDatabase_SetDocumentExpiration(db, FLSTR("doc1"), 0, &err);

    // Query documents that will be expired in less than five minutes
    time_t fiveMinutesFromNow = time(NULL) + 5 * 60;
    fiveMinutesFromNow *= 1000;
    FLMutableDict parameters = FLMutableDict_New();
    FLMutableDict_SetInt(parameters, FLSTR("five_minutes"), fiveMinutesFromNow);

    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id FROM _ WHERE meta().expiration < $five_minutes"), NULL, &err);
    CBLQuery_SetParameters(query, parameters);
    FLMutableDict_Release(parameters);
    // end::document-expiration[]
}

static void use_blob() {
    CBLDatabase* db = kDatabase;

    CBLDocument* newTask = CBLDocument_Create();

    // tag::blob[]
    // Note: Reading the data is implementation dependent, as with prebuilt databases
    // NOTE: No error handling, for brevity (see getting started)

    uint8_t buffer[128000];
    FILE* avatar_file = fopen("avatar.jpg", "rb");
    size_t read = fread(buffer, 1, 128000, avatar_file);

    FLSliceResult avatar = FLSliceResult_CreateWith(buffer, read);
    CBLBlob* blob = CBLBlob_CreateWithData(FLSTR("image/jpeg"), FLSliceResult_AsSlice(avatar));
    FLSliceResult_Release(avatar);

    // TODO: Create shortcut blob method
    CBLError err;
    FLMutableDict properties = CBLDocument_MutableProperties(newTask);
    FLSlot_SetBlob(FLMutableDict_Set(properties, FLSTR("avatar")), blob);
    CBLDatabase_SaveDocument(db, newTask, &err);
    // end::blob[]

    CBLDocument_Release(newTask);
    CBLBlob_Release(blob);
}

static void create_index() {
    CBLDatabase* db = kDatabase;

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
    CBLDatabase_CreateValueIndex(db, FLSTR("TypeNameIndex"), config, &err);
    // end::query-index[]
}

static void select_meta() {
    CBLDatabase* db = kDatabase;

    // tag::query-select-meta[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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

static void query_change_listener(void* context, CBLQuery* query, CBLListenerToken* token) {
    CBLError err;
    CBLResultSet* results = CBLQuery_CopyCurrentResults(query, token, &err);
    while(CBLResultSet_Next(results)) {
        // Update UI
    }
}

static void select_all() {
    CBLDatabase* db = kDatabase;

    // tag::query-select-all[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _"), NULL, &err);

    // All results will be available from the above query
    CBLQuery_Release(query);
    // end::query-select-all[]

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

    query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT * FROM _"), NULL, &err);
    CBLListenerToken* token = CBLQuery_AddChangeListener(query, query_change_listener, NULL);
    // end::live-query[]

    // tag::stop-live-query[]
    CBLListener_Remove(token); // The token received from AddChangeListener
    CBLQuery_Release(query);
    // end::stop-live-query[]
}

static void select_where() {
    CBLDatabase* db = kDatabase;

    // tag::query-where[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-collection-operator-contains[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id, name, public_likes FROM _ WHERE type = \"hotel\" "
              "AND ARRAY_CONTAINS(public_likes, \"Armani Langworth\""), NULL, &err);

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
    CBLDatabase* db = kDatabase;

    // tag::query-collection-operator-in[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-like-operator[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-like-operator-wildcard-match[]
    // NOTE: No error handling, for brevity (see getting started)

     CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-like-operator-wildcard-character-match[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-regex-operator[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-join[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-groupby[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
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
    CBLDatabase* db = kDatabase;

    // tag::query-orderby[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage, 
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
    CBLDatabase* db = kDatabase;

    {
    // tag::query-explain-all[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage, 
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
    CBLDatabase* db = kDatabase;
    
    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage,
        FLSTR("SELECT meta().id as id, name, city, type FROM _ LIMIT 10"),
        NULL, &err);

    // tag::query-access-json[]
    // NOTE: No error handling, for brevity (see getting started)
    
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
    CBLDatabase* db = kDatabase;

    const char* tasks[] = { "buy groceries", "play chess", "book travels", "buy museum tickets" };
    char idBuffer[7];
    for(int i = 0; i < 4; i++) {
        const char* task = tasks[i];
        sprintf(idBuffer, "extra%d", i);
        const CBLDocument* doc = CBLDatabase_GetDocument(db, FLStr(idBuffer), NULL);
        if(doc) {
            CBLDocument_Release(doc);
            continue;
        }

        CBLDocument* mutableDoc = CBLDocument_CreateWithID(FLStr(idBuffer));
        FLMutableDict properties = CBLDocument_MutableProperties(mutableDoc);
        FLMutableDict_SetString(properties, FLSTR("type"), FLSTR("task"));
        FLMutableDict_SetString(properties, FLSTR("task"), FLStr(task));
        CBLDatabase_SaveDocument(db, mutableDoc, NULL);
        CBLDocument_Release(mutableDoc);
    }

    // tag::fts-index[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLFullTextIndexConfiguration config = {
        kCBLN1QLLanguage,
        FLSTR("name"),
        false
    };

    CBLDatabase_CreateFullTextIndex(db, FLSTR("nameFTSIndex"), config, &err);
    // end::fts-index[]
}

static void full_text_search() {
    CBLDatabase* db = kDatabase;

    // tag::fts-query[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLQuery* query = CBLDatabase_CreateQuery(db, kCBLN1QLLanguage, 
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
    CBLDatabase* db = kDatabase;

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
    CBLReplicatorConfiguration config;
    memset(&config, 0, sizeof(CBLReplicatorConfiguration));
    config.database = db;
    config.endpoint = target;
    config.replicatorType = kCBLReplicatorTypePull;

    CBLReplicator* replicator = CBLReplicator_Create(&config, &err);
    CBLEndpoint_Free(target);
    CBLReplicator_Start(replicator, false);
    // end::replication[]

    kReplicator = replicator;
}

// Console logging domain methods not applicable to C

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
    CBLDatabase* db = kDatabase;

    // tag::basic-authentication[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/mydatabase");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err);
    CBLAuthenticator* basicAuth = CBLAuth_CreatePassword(FLSTR("john"), FLSTR("pass"));

    CBLReplicatorConfiguration config;
    memset(&config, 0, sizeof(CBLReplicatorConfiguration));
    config.database = db;
    config.endpoint = target;
    config.authenticator = basicAuth;

    CBLReplicator* replicator = CBLReplicator_Create(&config, &err);
    CBLEndpoint_Free(target);
    CBLAuth_Free(basicAuth);

    CBLReplicator_Start(replicator, false);
    // end::basic-authentication[]
}

int main(int argc, char** argv) {
    create_new_database();
    create_document();
    update_document();
    do_batch_operation();
    use_blob();
    select_meta();

    load_prebuilt();
    create_index();
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

    CBLReplicator_Stop(kReplicator);
    while(CBLReplicator_Status(kReplicator).activity != kCBLReplicatorStopped) {
        printf("Waiting for replicator to stop...");
        usleep(200000);
    }

    CBLDatabase_Close(kDatabase, NULL);

    return 0;
}


// tag::console-logging-db[]
// Placeholder for code to increase level of console logging for kCBLLogDomainDatabase domain
// end::console-logging-db[]

// tag::console-logging[]
// Placeholder for code to increase level of console logging for all domains
// end::console-logging[]

// tag::date-getter[]
// Placeholder for Date accessors.
// end::date-getter[]
