// CBL Version 3.0.0 BETA
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

//  BEGIN lower-level function declarations

//  DOCS NOTE --
//  These functions are referred to in subsequent code samples.
//  Their tags will ensure they are shown alongide the usage examples.
//  Functions used in more than one place may hve multiple tags.

// tag::p2p-act-rep-func[]
// tag::p2p-act-rep-add-change-listener[]
// Purpose -- illustrate a simple change listener
static void simpleChangeListener(
                void* context,
                CBLReplicator* repl,
                const CBLReplicatorStatus* status) {
     if(status->error.code != 0) {
         printf("Error %d / %d\n",
                status->error.domain,
                status->error.code);
     }
 }

// end::p2p-act-rep-add-change-listener[]

// tag::local-win-conflict-resolver[]
// Purpose -- illustrate a simple conflict resolver function
static const CBLDocument* simpleConflictResolver_localWins(
        void* context, FLString documentID,
        const CBLDocument* localDocument,
        const CBLDocument* remoteDocument) {
        return localDocument;
    }

// end::local-win-conflict-resolver[]
// end::p2p-act-rep-func[]



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
                                              const CBLReplicatedDocument *documents) {

    if(isPush) {
        printf("We pushed %d documents",numDocuments);
    }
}

// END lower-level function declarations


// DOCS NOTE
// Page=Data Sync >> Configuration Summary
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#configuration-summary

static void docs_act_replication() {
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

    // tag::p2p-act-rep-func[]
    // Purpose -- Show configuration , initialization and running of a replicator

    // NOTE: No error handling, for brevity (see getting started)
    // Note: Android emulator needs to use 10.0.2.2 for localhost (10.0.3.2 for GenyMotion)

    CBLError err;
    FLString url = FLSTR("ws://localhost:4984/db");
    CBLEndpoint* target = CBLEndpoint_CreateWithURL(url, &err); // <.>

    CBLReplicatorConfiguration config;
    memset(&config, 0, sizeof(CBLReplicatorConfiguration));
    config.database = db;
    config.endpoint = target; // <.>

    // tag::p2p-act-rep-config-cont[]
    // Set replication direction and mode
    config.replicatorType = kCBLReplicatorTypePull; // <.>
    config.continuous = true;
    // end::p2p-act-rep-config-cont[]

    // Optionally, set auto-purge behavior (here we override default)
    config.disableAutoPurge = true; // <.>

    // Optionally, configure Client Authentication
    // Here we are using to Basic Authentication,
    // Providing username and password credentials
    CBLAuthenticator* basicAuth =
        CBLAuth_CreatePassword(FLSTR("username"), FLSTR("passwd")); // <.>
    config.authenticator = basicAuth;

    // Optionally, configure how we handle conflicts
    config.conflictResolver = simpleConflictResolver_localWins; // <.>

    // Initialize replicator with created config
    CBLReplicator* replicator =
        CBLReplicator_Create(&config, &err); // <.>

    CBLEndpoint_Free(target);

    // Optionally, add change listener
    CBLListenerToken* token =
            CBLReplicator_AddChangeListener(replicator,
                                            simpleChangeListener,
                                            NULL); // <.>

    // Start replication
    CBLReplicator_Start(replicator, false); // <.>
    // end::p2p-act-rep-func[]

    kReplicator = replicator;
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
static void docs_act_replication_config_section_snippets() {
    CBLDatabase* db = kDatabase;
    bool docs_example_resetRequired = false;
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

    CBLReplicatorConfiguration config;
    memset(&config, 0, sizeof(CBLReplicatorConfiguration));
    config.database = db;
    config.endpoint = target; // <.>

    // end::sgw-act-rep-initialize[]

    //    tag::p2p-act-rep-config-type[]
    config.replicatorType = kCBLReplicatorTypePull;
    //    end::p2p-act-rep-config-type[]
    //    tag::p2p-act-rep-config-cont[]
    config.continuous = true;
    //    end::p2p-act-rep-config-cont[]


    // tag::replication-retry-config[]
    // Configure replication retries
    // tag::replication-set-heartbeat[]
    config.heartbeat = 120; //  <.>
    // end::replication-set-heartbeat[]
    // tag::replication-set-maxattempts[]
    config.maxAttempts = 20; //  <.>
    // end::replication-set-maxattempts[]
    // tag::replication-set-maxattemptwaittime[]
    config.maxAttemptWaitTime = 600; //  <.>
    // end::replication-set-maxattemptwaittime[]

    // end::replication-retry-config[]

    // tag::basic-authentication[]
    // Configure Client Authentication to Basic Authentication
    // Providing username and password credentials
    if(docs_example_ShowBasicAuth) {
        CBLAuthenticator* basicAuth =
            CBLAuth_CreatePassword(FLSTR("username"),
                                   FLSTR("passwd"));
        config.authenticator = basicAuth; // <.>
    }
    // end::basic-authentication[]

    // tag::session-authentication[]
    if(docs_example_ShowSessionAuth) {
        CBLAuthenticator* sessionAuth =
            CBLAuth_CreateSession(FLSTR("904ac010862f37c8dd99015a33ab5a3565fd8447"),
                                  FLSTR("optionalCookieName"));
        config.authenticator = sessionAuth; // <.>
    }

    // end::session-authentication[]

    // tag::replication-custom-header[]

    // Optionally, add custom headers
    FLMutableDict customHdrs = FLMutableDict_New();
    FLMutableDict_SetString(customHdrs,
                            FLSTR("customHeaderName"),
                            FLSTR("customHeaderValue"));

    config.headers = customHdrs;

    // end::replication-custom-header[]

    // FILTERS

    // tag::replication-push-filter[]
    // tag::replication-pull-filter[]
    // Purpose - Illustrate use of push and-or pull filter functions

    config.pushFilter = simpleReplicationFilter;

    config.pullFilter = simpleReplicationFilter;

    // end::replication-pull-filter[]
    // end::replication-push-filter[]


    //  Auto-purge over-ride
    // tag::autopurge-override[]
    config.disableAutoPurge = true; // <.>

    // end::autopurge-override[]
    // tag::[]

    // Initialize replicator with created config
    CBLReplicator* replicator =
        CBLReplicator_Create(&config, &err); // <.>

    // end::[]

    CBLEndpoint_Free(target);

    // Add optional change listener
    CBLListenerToken* token =
        CBLReplicator_AddChangeListener(replicator,
                                        docs_example_simpleChangeListener,
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

    CBLReplicator* thisRepl =
        CBLReplicator_Create(&argConfig, &err); // <.>

    // end::p2p-act-rep-start-full[]
    if(!docs_example_resetRequired) {
    // tag::p2p-act-rep-start-full[]

      CBLReplicator_Start(thisRepl,false); // <.>

    // end::p2p-act-rep-start-full[]
    } else {
    // tag::replication-reset-checkpoint[]
      CBLReplicator_Start(thisRepl, true); // <.>

    // end::replication-reset-checkpoint[]
    }

    return thisRepl;

}

// END replication.html >> initialize section

// PAGE=Data Sync >> Monitor
// URL=https://docs.couchbase.com/couchbase-lite/current/c/replication.html#lbl-repl-mon
// BEGIN replication.html >> Monitor section
//
static void docs_act_replication_Monitor(
                                       void* context,
                                       CBLReplicator* argRepl) {

    CBLError err;

    CBLReplicator* thisRepl = argRepl;

    // tag::p2p-act-rep-add-change-listener[]
    // Purpose -- illustrate addition of a Replicator change listener
    CBLListenerToken* token_ReplChangeListener =
            CBLReplicator_AddChangeListener(thisRepl,
                                            simpleChangeListener,
                                            NULL);

    // end::p2p-act-rep-add-change-listener[]
    // tag::add-document-replication-listener[]
    // Purpose -- illustrate addition of a Document Replicator  listener
    CBLListenerToken* token_ReplDocListener =
            CBLReplicator_AddDocumentReplicationListener(
                                                        thisRepl,
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

    CBLReplicatorStatus thisState = CBLReplicator_Status(thisRepl);

    if(thisState.activity==kCBLReplicatorStopped) {
        if(thisState.error.code==0) {
            CBLReplicator_Start(thisRepl,false);
        } else {
            printf("Replicator stopped -- code %d", thisState.error.code);
            // ... handle error ...
        }
    }

    // end::p2p-act-rep-status[]


    // tag::replication-pendingdocuments[]

    FLDict thisPendingIdList =
        CBLReplicator_PendingDocumentIDs(thisRepl, &err); // <.>

    if(!FLDict_IsEmpty(thisPendingIdList)) {
        FLDictIterator item;
        FLDictIterator_Begin(thisPendingIdList, &item);
        FLValue itemValue;
        FLString pendingId;

        while(NULL != (FLDictIterator_GetValue(&item))) {
            pendingId = FLValue_AsString(itemValue);

            if(CBLReplicator_IsDocumentPending(thisRepl,
                                               pendingId,
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





//CBLReplicator_PendingDocumentIDs(<#CBLReplicator * _Nonnull#>, <#CBLError * _Nullable outError#>)

