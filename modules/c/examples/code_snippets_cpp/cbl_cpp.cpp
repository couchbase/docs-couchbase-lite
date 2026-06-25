// Compilable source for the C++ code snippets shown on the Couchbase Lite C SDK
// documentation site. This mirrors code_snippets/main.cpp but uses the C++ API
// (the header-only `cbl++` wrapper, namespace `cbl`) instead of the C API.
//
// The docs pull regions out of this file via AsciiDoc tagged-region markers
// (paired "tag" / "end" line comments, exactly as in main.cpp), so the published
// C++ examples are guaranteed to compile against the real API. The docs reference
// these regions by name from example$code_snippets_cpp/cbl_cpp.cpp.
// Each region is the cbl++ equivalent of the same-named region in main.cpp, so
// the C and C++ doc tabs sit side by side. Where the C snippet uses // <.>
// callouts, the C++ snippet keeps them at the matching lines so the shared
// numbered descriptions line up. Snippets are ported incrementally.

#include <cbl++/CouchbaseLite.hh>
#include <iostream>
#include <optional>

// Page=build and run
// url=https://docs-staging.couchbase.com/couchbase-lite/current/c/gs-build.html
static void getting_started() {
    // tag::getting-started[]
    //  Purpose-- provide an overview of available CRUD and sync functionality
    //
    // The C++ API reports failures by throwing cbl::Error. For brevity this
    // try/catch is shown only here and is omitted in the other doc snippets.
    try {
        // Get the database (and create it if it doesn't exist)
        cbl::Database database("mydb");

        // All CRUD operations must be carried out via a collection. C++ objects
        // are ref-counted, so there is no explicit release/close to remember.
        cbl::Collection collection = database.getDefaultCollection();

        // Create a new document (i.e. a record) in the database. Passing nullptr
        // gives it an auto-generated ID. 'Mutable' means its properties can change.
        cbl::MutableDocument mutableDoc(nullptr);
        mutableDoc["version"] = 3.0f;

        // Save it to the database
        collection.saveDocument(mutableDoc);

        // Keep the auto-generated ID so we can fetch the document again
        std::string id = mutableDoc.id();

        // Update a document
        mutableDoc = collection.getMutableDocument(id);
        mutableDoc["language"] = "C++";
        collection.saveDocument(mutableDoc);

        // Read it back (a cbl::Document, unlike cbl::MutableDocument, is read-only)
        cbl::Document docAgain = collection.getDocument(id);
        std::cout << "Document ID :: " << docAgain.id() << std::endl;
        std::cout << "Learning " << docAgain["language"].asstring() << std::endl;

        // tag::query-syntax-n1ql[]
        // Create a query to fetch documents of type SDK
        cbl::Query query(database, kCBLN1QLLanguage,
                         "SELECT * FROM _ WHERE type = \"SDK\"");
        cbl::ResultSet result = query.execute();
        // end::query-syntax-n1ql[]

        // Create a replicator to push and pull changes to and from the cloud
        cbl::ReplicatorConfiguration config(
            { cbl::CollectionConfiguration(collection) },
            cbl::Endpoint::urlEndpoint("ws://localhost:4984/getting-started-db"));
        config.authenticator = cbl::Authenticator::basicAuthenticator("john", "pass");

        cbl::Replicator replicator(config);

        // Listen for replicator status changes
        auto token = replicator.addChangeListener(
            [](cbl::Replicator r, const CBLReplicatorStatus& status) {
                if (status.error.code != 0) {
                    std::cerr << "Error " << status.error.domain
                              << " / " << status.error.code << std::endl;
                }
            });

        replicator.start();

        // Later, stop the replicator. Ref-counted objects free themselves once
        // the last reference goes away (here, when this scope ends).
        replicator.stop();
    } catch (const cbl::Error& e) {
        // Error handling. For brevity, this is truncated here and omitted in the
        // other doc code snippets.
        std::cerr << "Error: " << e.what() << std::endl;
    }
    // end::getting-started[]
}

static void new_database() {
    // tag::new-database[]
    // NOTE: No error handling, for brevity (see getting started)
    cbl::Database db("my-database");
    // end::new-database[]
}

static void close_database() {
    cbl::Database db("my-database");
    // tag::close-database[]
    // NOTE: No error handling, for brevity (see getting started)
    db.close();
    // end::close-database[]
}

static void database_fullsync() {
    cbl::DatabaseConfiguration config{};
    // tag::database-fullsync[]
    // this enables full sync
    config.fullSync = true;
    // end::database-fullsync[]
}

#ifdef COUCHBASE_ENTERPRISE
static void database_encryption() {
    // tag::database-encryption[]
    // NOTE: No error handling, for brevity (see getting started)

    cbl::DatabaseConfiguration config{};

    // Derive an AES-256 key from a password and set it on the configuration
    config.encryptionKey = cbl::EncryptionKey("password");

    cbl::Database db("seekrit", config);

    // Change the encryption key (or add encryption if the DB is unencrypted)
    cbl::EncryptionKey betterKey("betterpassw0rd");
    db.changeEncryptionKey(&betterKey);

    // Remove encryption
    db.changeEncryptionKey(nullptr);
    // end::database-encryption[]
}
#endif

static void prebuilt_database() {
    // tag::prebuilt-database[]
    // Note: Getting the path to a database is platform-specific.  For desktop (including RPi)
    // this can be a simple filesystem path.  For iOS you need to get the path from the
    // main bundle.  For Android you need to extract it from your assets to a temporary directory
    // and then pass that path.

    // NOTE: No error handling, for brevity (see getting started)

    const char* path = "/path/to/travel-sample.cblite2";
    if (!cbl::Database::exists("travel-sample.cblite2")) {
        cbl::Database::copyDatabase(path, "travel-sample");
    }
    // end::prebuilt-database[]
}

static void query_access_all() {
    cbl::Database database("mydb");
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT * FROM _");
    // tag::query-access-all[]
    cbl::ResultSet results = query.execute();
    for (cbl::Result result : results) {
        fleece::Dict dict = result["_"].asDict();

        std::cout << "ID :: "   << dict["id"].asstring()   << std::endl;
        std::cout << "Type :: " << dict["type"].asstring() << std::endl;
        std::cout << "Name :: " << dict["name"].asstring() << std::endl;
        std::cout << "City :: " << dict["city"].asstring() << std::endl;
    }
    // All results are available from the above query
    // end::query-access-all[]
}

static void query_access_id() {
    cbl::Database database("mydb");
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT meta().id AS id FROM _");
    // tag::query-access-id[]
    // NOTE: No error handling, for brevity (see getting started)
    cbl::ResultSet results = query.execute();
    for (cbl::Result result : results) {
        std::cout << "Document ID :: " << result["id"].asstring() << std::endl;
    }
    // end::query-access-id[]
}

static void query_access_props() {
    cbl::Database database("mydb");
    // tag::query-access-props[]
    // NOTE: No error handling, for brevity (see getting started)
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT type, name, city FROM _");

    cbl::ResultSet results = query.execute();
    for (cbl::Result result : results) {
        std::cout << "Type :: " << result["type"].asstring() << std::endl;
        std::cout << "Name :: " << result["name"].asstring() << std::endl;
        std::cout << "City :: " << result["city"].asstring() << std::endl;
    }
    // end::query-access-props[]
}

static void query_access_json() {
    cbl::Database database("mydb");
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT * FROM _");
    // tag::query-access-json[]
    cbl::ResultSet results = query.execute();
    for (cbl::Result result : results) {
        std::cout << "JSON Result :: " << result.toJSON().asString() << std::endl;
    }
    // end::query-access-json[]
}

static void query_syntax_n1ql_params() {
    cbl::Database database("mydb");
    // tag::query-syntax-n1ql-params[]
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT * FROM _ WHERE type = $type");

    fleece::MutableDict params = fleece::MutableDict::newDict();
    params["type"] = "hotel";
    query.setParameters(params);

    cbl::ResultSet result = query.execute();
    // ... process results as required
    // end::query-syntax-n1ql-params[]
}

static void live_query() {
    cbl::Database database("mydb");
    // tag::live-query[]
    // NOTE: No error handling, for brevity (see getting started)
    cbl::Query query(database, kCBLN1QLLanguage, "SELECT * FROM _"); // <.>

    // The listener is invoked with the current results whenever they change
    auto token = query.addChangeListener([](cbl::Query::Change change) { // <.>
        for (cbl::Result result : change.results()) {
            // Update UI
        }
    });
    // end::live-query[]
}

static void stop_live_query() {
    cbl::Query::ChangeListener token{};
    // tag::stop-live-query[]
    token.remove(); // The token received from addChangeListener
    // end::stop-live-query[]
}

static void fts_index() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::fts-index[]
    cbl::FullTextIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.expressions = "name";
    config.ignoreAccents = false;

    collection.createFullTextIndex("nameFTSIndex", config);
    // end::fts-index[]
}

static void fts_query() {
    cbl::Database database("mydb");
    // tag::fts-query[]
    cbl::Query query(database, kCBLN1QLLanguage,
        "SELECT meta().id FROM _ WHERE MATCH(nameFTSIndex, \"'buy'\")");

    cbl::ResultSet results = query.execute();
    for (cbl::Result result : results) {
        std::cout << "Document id :: " << result[0].asstring() << std::endl;
    }
    // end::fts-query[]
}

static void query_index() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::query-index[]
    // For value types, this is optional but provides performance enhancements
    // NOTE: No error handling, for brevity (see getting started)
    // Syntax for the expressions is the same as taking from a N1QL SELECT
    // i.e. SELECT (type, name) FROM _;
    // tag::scopes-manage-index-collection[]
    cbl::ValueIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.expressions = "type, name";

    collection.createValueIndex("TypeNameIndex", config);
    // end::scopes-manage-index-collection[]
    // end::query-index[]
}

static void partial_value_index() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::partial-value-index[]
    cbl::ValueIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.expressions = "city";
    config.where = "type = \"hotel\"";

    collection.createValueIndex("HotelCityIndex", config);
    // end::partial-value-index[]
}

static void partial_full_text_index() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::partial-full-text-index[]
    cbl::FullTextIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.expressions = "description";
    config.where = "type = \"hotel\"";

    collection.createFullTextIndex("HotelDescIndex", config);
    // end::partial-full-text-index[]
}

static void array_index_config() {
    // tag::array-index-config[]
    cbl::ArrayIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.path = "contacts";
    // end::array-index-config[]
}

static void array_index_single() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::array-index-single[]
    cbl::ArrayIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.path = "likes";

    collection.createArrayIndex("myindex", config);
    // end::array-index-single[]
}

static void array_index_nested() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::array-index-nested[]
    cbl::ArrayIndexConfiguration config{};
    config.expressionLanguage = kCBLN1QLLanguage;
    config.path = "contacts[].phones";
    config.expressions = "type";

    collection.createArrayIndex("myindex", config);
    // end::array-index-nested[]
}

static void scopes_manage_create_collection() {
    cbl::Database db("mydb");
    // tag::scopes-manage-create-collection[]
    db.createCollection("collA", "scopeA");
    // end::scopes-manage-create-collection[]
}

static void scopes_manage_drop_collection() {
    cbl::Database db("mydb");
    // tag::scopes-manage-drop-collection[]
    db.deleteCollection("collA", "scopeA");
    // end::scopes-manage-drop-collection[]
}

static void scopes_manage_list() {
    cbl::Database db("mydb");
    // tag::scopes-manage-list[]
    // Get Scope names
    fleece::MutableArray scopes = db.getScopeNames();
    // Get Collection names of a specific Scope named scopeA
    fleece::MutableArray collections = db.getCollectionNames("scopeA");
    // Get default Collection
    cbl::Collection collection = db.getDefaultCollection();
    // Get specific Collection named collA of a specific Scope named scopeA
    cbl::Collection collA = db.getCollection("collA", "scopeA");
    // Get the Scope name of a Collection
    std::string scopeName = collA.scopeName();
    // end::scopes-manage-list[]
}

// tag::local-win-conflict-resolver[]
static cbl::ConflictResolver localWinConflictResolver =
    [](std::string_view documentID, const cbl::Document localDoc, const cbl::Document remoteDoc) {
        return localDoc;
    };
// end::local-win-conflict-resolver[]

// tag::remote-win-conflict-resolver[]
static cbl::ConflictResolver remoteWinConflictResolver =
    [](std::string_view documentID, const cbl::Document localDoc, const cbl::Document remoteDoc) {
        return remoteDoc;
    };
// end::remote-win-conflict-resolver[]

// tag::merge-conflict-resolver[]
static cbl::ConflictResolver mergeConflictResolver =
    [](std::string_view documentID, const cbl::Document localDoc, const cbl::Document remoteDoc) {
        // Start from the local properties, then add any keys that exist only remotely
        fleece::MutableDict mergedProps = localDoc.properties().mutableCopy();
        for (fleece::Dict::iterator i(remoteDoc.properties()); i; ++i) {
            if (!mergedProps.get(i.keyString())) {
                mergedProps.set(i.keyString(), i.value());
            }
        }

        cbl::MutableDocument mergeDocument(documentID);
        mergeDocument.setProperties(mergedProps);
        return mergeDocument;
    };
// end::merge-conflict-resolver[]

static void replication_conflict_resolver() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::replication-conflict-resolver[]
    // NOTE: No error handling, for brevity (see getting started)
    cbl::Endpoint target = cbl::Endpoint::urlEndpoint("ws://localhost:4984/mydatabase");

    cbl::CollectionConfiguration collectionConfig(collection);
    collectionConfig.conflictResolver = localWinConflictResolver;

    cbl::ReplicatorConfiguration replConfig({ collectionConfig }, target);

    cbl::Replicator replicator(replConfig);
    replicator.start();
    // end::replication-conflict-resolver[]
}

static void update_document_with_conflict_handler() {
    cbl::Database database("mydb");
    // tag::update-document-with-conflict-handler[]
    cbl::Collection collection = database.getDefaultCollection();
    cbl::MutableDocument mutableDoc = collection.getMutableDocument("xyz");
    mutableDoc["name"] = "apples";

    bool saved = collection.saveDocument(mutableDoc,
        [](cbl::MutableDocument documentBeingSaved, cbl::Document conflictingDocument) {
            // Merge the conflicting document's properties into the one being saved
            fleece::Dict currentProps = conflictingDocument.properties();
            fleece::MutableDict newProps = documentBeingSaved.properties();
            for (fleece::Dict::iterator i(currentProps); i; ++i) {
                if (!newProps.get(i.keyString())) {
                    newProps.set(i.keyString(), i.value());
                }
            }
            return true;
        });
    // end::update-document-with-conflict-handler[]
}

static void new_console_logging() {
    // tag::new-console-logging[]
    cbl::ConsoleLogSink logSink{};
    logSink.level = kCBLLogVerbose;
    logSink.domains = kCBLLogDomainMaskAll;
    cbl::LogSinks::setConsole(logSink);
    // end::new-console-logging[]
}

static void new_file_logging() {
    // tag::new-file-logging[]
    cbl::FileLogSink logSink{};
    logSink.level = kCBLLogVerbose;
    logSink.directory = "/tmp/logs";
    logSink.maxKeptFiles = 12;
    logSink.maxSize = 1048576;
    logSink.usePlaintext = false;
    cbl::LogSinks::setFile(logSink);
    // end::new-file-logging[]
}

// tag::custom-logging[]
static void custom_log_callback(CBLLogDomain domain, CBLLogLevel level, FLString message) {
    // handle the message, for example piping it to a third party framework
}
// end::custom-logging[]

// tag::new-custom-logging[]
static void custom_log_sink_callback(CBLLogDomain domain, CBLLogLevel level, FLString message) {
    // handle the message, for example piping it to a third party framework.
}
// end::new-custom-logging[]

static void set_new_custom_logging() {
    // tag::set-new-custom-logging[]
    cbl::CustomLogSink logSink{};
    logSink.level = kCBLLogVerbose;
    logSink.callback = custom_log_sink_callback;
    cbl::LogSinks::setCustom(logSink);
    // end::set-new-custom-logging[]
}

static void sgw_act_rep_initialize() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::sgw-act-rep-initialize[]
    // Initialize the configuration object and set db target
    cbl::Endpoint target = cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"); // <.>

    cbl::CollectionConfiguration collectionConfig(collection);
    cbl::ReplicatorConfiguration replConfig({ collectionConfig }, target); // <.>
    // end::sgw-act-rep-initialize[]
}

static void p2p_act_rep_config_cont() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration replConfig({ cbl::CollectionConfiguration(collection) },
                                            cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    // tag::p2p-act-rep-config-cont[]
    // Set replication direction and mode
    replConfig.replicatorType = kCBLReplicatorTypePull; // <.>
    replConfig.continuous = true;
    // end::p2p-act-rep-config-cont[]
}

static void p2p_act_rep_config_type() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration replConfig({ cbl::CollectionConfiguration(collection) },
                                            cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    // tag::p2p-act-rep-config-type[]
    replConfig.replicatorType = kCBLReplicatorTypePull;
    // end::p2p-act-rep-config-type[]
}

static void p2p_act_rep_config_pinnedcert() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration replConfig({ cbl::CollectionConfiguration(collection) },
                                            cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    std::string certData;
    // tag::p2p-act-rep-config-pinnedcert[]
    // Use the pinned certificate from the listener (the listener's cert)
    replConfig.pinnedServerCertificate = certData; // Get listener cert if pinned
    // end::p2p-act-rep-config-pinnedcert[]
}

static void p2p_act_rep_start_full() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration replConfig({ cbl::CollectionConfiguration(collection) },
                                            cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    // tag::p2p-act-rep-start-full[]
    cbl::Replicator replicator(replConfig); // <.>
    // end::p2p-act-rep-start-full[]
    // tag::p2p-act-rep-start-full[]
    replicator.start(); // <.>
    // end::p2p-act-rep-start-full[]
}

static void p2p_act_rep_add_change_listener() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::Replicator replicator(cbl::ReplicatorConfiguration(
        { cbl::CollectionConfiguration(collection) },
        cbl::Endpoint::urlEndpoint("ws://localhost:4984/db")));
    // tag::p2p-act-rep-add-change-listener[]
    // Purpose -- illustrate addition of a Replicator change listener
    auto token = replicator.addChangeListener(
        [](cbl::Replicator r, const CBLReplicatorStatus& status) {
            if (status.error.code != 0) {
                std::cerr << "Error " << status.error.domain
                          << " / " << status.error.code << std::endl;
            }
        }); // <.>
    // end::p2p-act-rep-add-change-listener[]
}

static void p2p_act_rep_status(cbl::Replicator replicator) {
    // tag::p2p-act-rep-status[]
    // Purpose -- illustrate use of Replicator::status()
    CBLReplicatorStatus thisState = replicator.status();
    if (thisState.activity == kCBLReplicatorStopped) {
        if (thisState.error.code == 0) {
            replicator.start();
        } else {
            std::cerr << "Replicator stopped -- code " << thisState.error.code << std::endl;
            // ... handle error ...
        }
    }
    // end::p2p-act-rep-status[]
}

static void p2p_act_rep_stop(cbl::Replicator replicator) {
    // tag::p2p-act-rep-stop[]
    // Purpose -- show how to stop a replication
    if (replicator.status().activity != kCBLReplicatorStopped) {
        replicator.stop();
    }
    // end::p2p-act-rep-stop[]
}

static void replication_pendingdocuments(cbl::Replicator replicator, cbl::Collection collection) {
    // tag::replication-pendingdocuments[]
    fleece::Dict thisPendingIdList = replicator.pendingDocumentIDs(collection); // <.>
    if (!thisPendingIdList.empty()) {
        for (fleece::Dict::iterator item(thisPendingIdList); item; ++item) {
            std::string pendingId = item.keyString().asString();
            if (replicator.isDocumentPending(pendingId, collection)) { // <.>
                // ... process the still pending docid as required <.>
            } else {
                // Doc Id no longer pending -- already pushed
                printf("Document already pushed");
            }
        }
    } else {
        printf("No Pending Id Docs to process");
    }
    // end::replication-pendingdocuments[]
}

static void p2p_act_rep_config_cacert() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration config({ cbl::CollectionConfiguration(collection) },
                                        cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    // tag::p2p-act-rep-config-cacert[]
    // Configure Server Security -- only accept CA Certs
    config.acceptOnlySelfSignedServerCertificate = false;
    // end::p2p-act-rep-config-cacert[]
}

static void replication_retry_config() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    cbl::ReplicatorConfiguration replConfig({ cbl::CollectionConfiguration(collection) },
                                            cbl::Endpoint::urlEndpoint("ws://localhost:4984/db"));
    // tag::replication-retry-config[]
    // Configure replication retries
    // tag::replication-set-heartbeat[]
    replConfig.heartbeat = 120; // <.>
    // end::replication-set-heartbeat[]

    // tag::replication-set-maxattempts[]
    replConfig.maxAttempts = 20; // <.>
    // end::replication-set-maxattempts[]

    // tag::replication-set-maxattemptwaittime[]
    replConfig.maxAttemptWaitTime = 600; // <.>
    // end::replication-set-maxattemptwaittime[]
    // end::replication-retry-config[]
}

static void replicator_simple() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::replicator-simple[]
    // Set up the collection for replication:
    cbl::CollectionConfiguration collectionConfig(collection);

    // Create a URL endpoint to the listener:
    cbl::Endpoint endpoint =
        cbl::Endpoint::urlEndpoint("wss://<listener-ip-address>:<listener-port>/<database-name>");

    // Initialize the replicator config with the collection and endpoint:
    cbl::ReplicatorConfiguration replConfig({ collectionConfig }, endpoint);

    // tag::p2p-act-rep-config-self-cert[]
    // Accept self-signed certificates, for testing purposes only:
    replConfig.acceptOnlySelfSignedServerCertificate = true;
    // end::p2p-act-rep-config-self-cert[]

    // Set up a basic authenticator with a username and password:
    replConfig.authenticator = cbl::Authenticator::basicAuthenticator("username", "password");

    // Create a replicator:
    cbl::Replicator replicator(replConfig);

    // Start the replicator:
    replicator.start();
    // end::replicator-simple[]
}

#ifdef COUCHBASE_ENTERPRISE
// tag::replicator_property_encryption[]
// tag::replicator_property_encryptor_decryptor_sample[]
// Purpose: Declare property-level encryptor/decryptor callback functions

// A simple symmetric XOR cipher shared by the encryptor and decryptor.
static fleece::alloc_slice my_cipher_function(fleece::slice input) {
    fleece::alloc_slice result(input.size);
    for (size_t i = 0; i < input.size; ++i) {
        ((uint8_t*)result.buf)[i] = ((const uint8_t*)input.buf)[i] ^ 'K';
    }
    return result;
}

static cbl::PropertyEncryptor property_encryptor =
    [](fleece::slice scope, fleece::slice collection, fleece::slice documentID,
       fleece::Dict properties, fleece::slice keyPath, fleece::slice input) -> cbl::EncryptionResult {
        return { my_cipher_function(input), "MyEnc" };
    };

static cbl::PropertyDecryptor property_decryptor =
    [](fleece::slice scope, fleece::slice collection, fleece::slice documentID,
       fleece::Dict properties, fleece::slice keyPath, fleece::slice input,
       std::optional<std::string_view> algorithm, std::optional<std::string_view> keyID) -> cbl::DecryptionResult {
        return { my_cipher_function(input) };
    };
// end::replicator_property_encryptor_decryptor_sample[]
// end::replicator_property_encryption[]

static void replicator_property_encryption() {
    cbl::Database database("mydb");
    cbl::Collection collection = database.getDefaultCollection();
    // tag::replicator_property_encryption[]
    // Purpose: Show how to declare en(de)cryptors in the replicator config
    cbl::Endpoint target = cbl::Endpoint::urlEndpoint("ws://localhost:4984/db");

    cbl::CollectionConfiguration collectionConfig(collection);

    cbl::ReplicatorConfiguration replConfig({ collectionConfig }, target);
    replConfig.documentPropertyEncryptor = property_encryptor; // <.>
    replConfig.documentPropertyDecryptor = property_decryptor; // <.>

    cbl::Replicator replicator(replConfig);
    replicator.start();
    // end::replicator_property_encryption[]
}
#endif

// The snippets in this file exist only to be compile-checked and pulled into the
// docs via tagged regions; the project is never run, so main() is empty.
int main(int argc, char** argv) {
    return 0;
}
