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
@file:Suppress("UNUSED_VARIABLE", "unused")

package com.couchbase.codesnippets

import androidx.lifecycle.LiveData
import androidx.lifecycle.asLiveData
import com.couchbase.lite.Collection
import com.couchbase.lite.DocumentChange
import com.couchbase.lite.Query
import com.couchbase.lite.Replicator
import com.couchbase.lite.ReplicatorActivityLevel
import com.couchbase.lite.Result
import com.couchbase.lite.collectionChangeFlow
import com.couchbase.lite.documentChangeFlow
import com.couchbase.lite.queryChangeFlow
import com.couchbase.lite.replicatorChangesFlow
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull


class FlowExamples {

    fun replChangeFlowExample(repl: Replicator): LiveData<ReplicatorActivityLevel> {
        // tag::flow-as-replicator-change-listener[]
        return repl.replicatorChangesFlow()
            .map { it.status.activityLevel }
            .asLiveData()
    }

    fun replChangeFlowExample(collection: Collection): LiveData<MutableList<String>> {
        // end::flow-as-replicator-change-listener[]
        // tag::flow-as-database-change-listener[]
        return collection.collectionChangeFlow(null)
            .map { it.documentIDs }
            .asLiveData()
    }

    fun docChangeFlowExample(collection: Collection, owner: String): LiveData<DocumentChange?> {
        // end::flow-as-database-change-listener[]
        // tag::flow-as-document-change-listener[]
        return collection.documentChangeFlow("1001")
            .mapNotNull { change ->
                change.takeUnless {
                    collection.getDocument(it.documentID)?.getString("owner").equals(owner)
                }
            }
            .asLiveData()
    }

    // end::flow-as-document-change-listener[]
    // tag::flow-as-query-change-listener[]
    @ExperimentalCoroutinesApi
    fun watchQuery(query: Query): LiveData<List<Result>> {
        return query.queryChangeFlow()
            .mapNotNull { change ->
                val err = change.error
                if (err != null) {
                    throw err
                }
                change.results?.allResults()
            }
            .asLiveData()
        // end::flow-as-query-change-listener[]
    }
}
