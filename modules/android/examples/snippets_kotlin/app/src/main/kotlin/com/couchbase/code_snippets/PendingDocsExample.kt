//
// Copyright (c) 2021 Couchbase, Inc All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package com.couchbase.code_snippets

import android.util.Log
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorStatus


private const val TAG = "PENDING"

@Suppress("unused")
class PendingDocsExample(private var replicator: Replicator) {
    //
    // tag::replication-pendingdocuments[]
    //
    private fun onStatusChanged(pendingDocs: Set<String>, status: ReplicatorStatus) {
        // ... sample onStatusChanged function
        //
        Log.i(TAG, "Replicator activity level is ${status.activityLevel}")

        // iterate and report-on previously
        // retrieved pending docids 'list'
        val itr = pendingDocs.iterator()
        while (itr.hasNext()) {
            val docId = itr.next()

            // tag::replication-push-isdocumentpending[]
            if (!replicator.isDocumentPending(docId)) { // <.>
                continue
            }

            // end::replication-push-isdocumentpending[]
            Log.i(TAG, "Doc ID $docId has been pushed")
        }
    } // end::replication-pendingdocuments[]
}
