#include <cbl/CouchbaseLite.h>

#include <time.h>
#ifdef _MSC_VER
#include <direct.h>
#else
#include <unistd.h>
#endif

static CBLDatabase* kDatabase;
static CBLReplicator* kReplicator;
static CBLListenerToken* kListenerToken;
static bool kNeedsExtraDocs;

static void getting_started_change_listener(void* context, CBLReplicator* repl, const CBLReplicatorStatus* status) {
    if(status->error.code != 0) {
        printf("Error %d / %d", status->error.domain, status->error.code);
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
        fprintf(stderr, "Error opening database (%d / %d)", err.domain, err.code);
        FLSliceResult msg = CBLError_Message(&err);
        fprintf(stderr, "%.*s", (int)msg.size, (const char *)msg.buf);
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
    printf("Document ID :: %.*s", (int)retrievedID.size, (const char *)retrievedID.buf);
    printf("Learning %.*s", (int)retrievedLanguage.size, (const char *)retrievedLanguage.buf);

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
    //         printf("Error %d / %d", status->error.domain, status->error.code);
    //     }
    // }

    CBLListenerToken* token = CBLReplicator_AddChangeListener(replicator, getting_started_change_listener, NULL);
    CBLReplicator_Start(replicator, false);

    // Later, stop and release the replicator
    // end::getting-started[]

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

static void test_save_with_conflict_handler() {
    CBLDatabase* database = kDatabase;

    // tag::update-document-with-conflict-handler[]
    // NOTE: No error handling, for brevity (see getting started)

    CBLError err;
    CBLDocument* mutableDocument = CBLDatabase_GetMutableDocument(database, FLSTR("xyz"), &err);
    FLDict properties = CBLDocument_MutableProperties(mutableDocument);

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

    // tag::replication-reset-checkpoint[]
    // replicator is a CBLReplicator* instance
    CBLReplicator_Start(replicator, true);
    // end::replication-reset-checkpoint[]

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
        printf("Saved user document %s", buffer);
    }

    CBLDatabase_EndTransaction(db, true, &err);
    // end::batch[]
}

static void document_listener(void* context, const CBLDatabase* db, FLString id) {
    CBLError err;
    const CBLDocument* doc = CBLDatabase_GetDocument(db, id, &err);
    FLDict properties = CBLDocument_Properties(doc);
    FLString verified_account = FLValue_AsString(FLDict_Get(properties, FLSTR("verified_account")));
    printf("Status :: %.*s", (int)verified_account.size, (const char *)verified_account.buf);
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
        printf("Status :: %.*s", (int)verified_account.size, (const char *)verified_account.buf);
        CBLDocument_Release(doc);
    }
    */

    CBLListenerToken* token = CBLDatabase_AddDocumentChangeListener(db, FLSTR("user.john"),
        document_listener, NULL);
    // end::document-listener[]
}

int main(int argc, char** argv) {
    return 0;
}


// tag::query-index[]
// placeholder
// tag::query-index[]

// tag::fts-index[]
// placeholder
// tag::fts-index[]