//
// Copyright (c) 2024 Couchbase, Inc All rights reserved.
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
@file:Suppress("UNUSED_VARIABLE", "unused", "DEPRECATION")

package com.couchbase.codesnippets

import com.couchbase.lite.ArrayIndexConfiguration
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.IndexConfiguration

class ArrayIndexExamples {
    fun arrayIndexConfig() {
        // tag::array-index-config[]
        val config: IndexConfiguration = ArrayIndexConfiguration("contacts", "type")
        // end::array-index-config[]
    }

    @Throws(CouchbaseLiteException::class)
    fun arrayIndexSingle(collection: Collection) {
        // tag::array-index-single[]
        collection.createIndex("myindex", ArrayIndexConfiguration("likes"))
        // end::array-index-single[]
    }

    @Throws(CouchbaseLiteException::class)
    fun arrayIndexNested(collection: Collection) {
        // tag::array-index-nested[]
        collection.createIndex(
            "myindex",
            ArrayIndexConfiguration("contacts[].phones", "type")
        )
        // end::array-index-nested[]
    }
}