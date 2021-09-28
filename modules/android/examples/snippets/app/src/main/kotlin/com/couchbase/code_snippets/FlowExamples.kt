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

import androidx.lifecycle.LiveData
import androidx.lifecycle.asLiveData
import com.couchbase.lite.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.map


class FlowExamples(argDb: Database,
                   argRepl: Replicator,
                   argQuery: Query,
                   argDocOwner: String) {

    // tag::flow-as-replicator-change-listener[]
    val replState: LiveData<ReplicatorActivityLevel> = argRepl.replicatorChangesFlow()
        .map { it.status.activityLevel }
        .asLiveData()

    // end::flow-as-replicator-change-listener[]
    // tag::flow-as-database-change-listener[]
    val dbChanges: LiveData<MutableList<String>> = argDb.databaseChangeFlow()
        .map { it.documentIDs }
        .asLiveData()

    // end::flow-as-database-change-listener[]
    // tag::flow-as-document-change-listener[]
    val docChanges: LiveData<DocumentChange?> = argDb.documentChangeFlow("1001")
        .map {
            it.takeUnless {
                it.database.getDocument(it.documentID)?.getString("owner").equals(argDocOwner)
            }
        }
        .asLiveData()

    // end::flow-as-document-change-listener[]
    // tag::flow-as-query-change-listener[]
    var liveQuery: LiveData<List<Any>?>? = null

    @ExperimentalCoroutinesApi
    fun watchQuery(query: Query): LiveData<List<Any>?> {
        val queryFlow = query.queryChangeFlow()
            .map {
                val err = it.error
                if (err != null) {
                    throw err
                }
                it.results?.allResults()?.flatMap { it.toList() }
            }
            .asLiveData()
        liveQuery = queryFlow
        return queryFlow
    }
    // end::flow-as-query-change-listener[]
}
