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
import com.couchbase.lite.*
import org.json.JSONException
import org.json.JSONObject


const val JSON = """[{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
        \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
        {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
        \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
        {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
        \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
        \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]"""


class KtJSONExamples {
    private val TAG = "SNIPPETS"

    fun jsonArrayExample(db: Database) {
        // tag::tojson-array[]
        // github tag=tojson-array
        val mArray = MutableArray(JSON) // <.>
        for (i in 0 until mArray.count()) {
            mArray.getDictionary(i)?.apply {
                Log.i(TAG, getString("name") ?: "unknown")
                db.save(MutableDocument(getString("id"), toMap()))
            } // <.>
        }

        db.getDocument("1002")?.getArray("features")?.apply {
            for (feature in toList()) {
                Log.i(TAG, "$feature")
            } // <.>
            Log.i(TAG, toJSON())
        } // <.>
        // end::tojson-array[]
    }

    fun jsonBlobExample(db: Database) {
        // tag::tojson-blob[]
        // github tag=tojson-blob
        val thisBlob = db.getDocument("thisdoc-id")!!.toMap()
        if (!Blob.isBlob(thisBlob)) {
          return
        }
        val blobType = thisBlob["content_type"].toString()
        val blobLength = thisBlob["length"] as Number?
        // end::tojson-blob[]
    }

    fun jsonDictionaryExample() {
        // tag::tojson-dictionary[]
        // github tag=tojson-dictionary
        val mDict = MutableDictionary(JSON) // <.>
        Log.i(TAG, "$mDict")
        Log.i(TAG, "Details for: ${mDict.getString("name")}")
        for (key in mDict.keys) {
          Log.i(TAG, key + " => " + mDict.getValue(key))
        }
        // end::tojson-dictionary[]
    }

    @Throws(CouchbaseLiteException::class)
    fun jsonDocumentExample(srcDb: Database, dstDb: Database) {
        QueryBuilder
            .select(SelectResult.expression(Meta.id).`as`("metaId"))
            .from(DataSource.database(srcDb))
            .execute()
            .forEach {
                it.getString("metaId")?.let { thisId ->
                    srcDb.getDocument(thisId)?.toJSON()?.let { json -> // <.>
                        Log.i(TAG, "JSON String = $json")
                        val hotelFromJSON = MutableDocument(thisId, json) // <.>
                        dstDb.save(hotelFromJSON)
                        dstDb.getDocument(thisId)?.toMap()?.forEach { e ->
                            Log.i(TAG, "$e.key => $e.value")
                        } // <.>
                    }
                }
            }
    }

    @Throws(CouchbaseLiteException::class, JSONException::class)
    fun jsonQueryExample(query: Query) {
        query.execute().forEach {

            // Use a Json Object to populate Native object
            JSONObject(it.toJSON()).apply {
                val (description, country, city, name, type, id) = Hotel(
                    id = getString("id"),
                    type = getString("type"),
                    name = getString("name"),
                    city = getString("city"),
                    country = "Ghana, West Africa",
                    description = "this hotel"
                )
            }
        }
    }
}