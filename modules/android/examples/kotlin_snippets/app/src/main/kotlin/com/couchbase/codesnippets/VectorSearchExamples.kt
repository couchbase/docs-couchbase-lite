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
@file:Suppress("unused", "UNUSED_VARIABLE")

package com.couchbase.codesnippets

import android.text.TextUtils
import com.couchbase.codesnippets.utils.Logger
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.MutableArray
import com.couchbase.lite.MutableDictionary
import com.couchbase.lite.Parameters
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.VectorEncoding
import com.couchbase.lite.VectorIndexConfiguration

class VectorSearchExamples {
    fun createDefaultVSConfig() {
        // tag::vs-create-default-config[]
        // create the configuration for a vector index named "vector"
        // with 300 dimensions and 20 centroids
        val config = VectorIndexConfiguration("vector", 300L, 20L)
        // end::vs-create-default-config[]
    }

    fun createCustomVSConfig() {
        // tag::vs-create-custom-config[]
        // create the configuration for a vector index named "vector"
        // with 300 dimensions, 20 centroids, max training size 200, min training size 100
        // no vector encoding and using COSINE distance measurement
        val config = VectorIndexConfiguration("vector", 300L, 20L)
            .setEncoding(VectorEncoding.none())
            .setMetric(VectorIndexConfiguration.DistanceMetric.COSINE)
            .setMinTrainingSize(100L)
            .setMaxTrainingSize(200L)
        // end::vs-create-custom-config[]
    }

    @Throws(CouchbaseLiteException::class)
    fun createVectorIndex(db: Database) {
        // tag::vs-create-index[]
        // create a vector index named "words_index"
        // in the collection "_default.words"
        db.getCollection("words")!!.createIndex("word_index", VectorIndexConfiguration("vector", 300L, 20L))
        // end::vs-create-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun createPredictiveIndex(db: Database) {
        // tag::vs-create-predictive-index[]
        // create a vector index with a simple predictive model
        val collection = db.getCollection("words")!!
        Database.prediction.registerModel("WordEmbedding") {
            val word: String? = it.getString("word")
            if (TextUtils.isEmpty(word)) {
                Logger.log("Input word is empty")
                return@registerModel null
            }
            try {
                db.createQuery(
                    "SELECT vector"
                            + " FROM ${collection}"
                            + " WHERE word = '${word}'"
                ).execute().use { rs ->
                    val results = rs.allResults()
                    if (results.isEmpty()) {
                        return@registerModel null
                    }

                    results[0].getArray(0)?.let { result ->
                        val dict = MutableDictionary()
                        dict.setValue("vector", result.toList())
                        return@registerModel dict
                    }

                    Logger.log("Prediction result is not an array")
                }
            } catch (e: CouchbaseLiteException) {
                Logger.log("Prediction query failed", e)
            }
            return@registerModel null
        }

        collection.createIndex(
            "words_pred_index",
            VectorIndexConfiguration("prediction(WordEmbedding, {'word': word}).vector", 300L, 8L)
        )
        // end::vs-create-predictive- index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVD(db: Database, hugeListOfFloats: List<Any?>?) {
        // tag::vs-use-vector-match[]
        // tag::vs-apvd-order-by[]
        // use APPROX_VECTOR_DISTANCE in a query
        db.getCollection("words")!!.createIndex("word_index", VectorIndexConfiguration("vector", 300L, 8L))

        val query = db.createQuery(
            "SELECT meta().id, word"
                    + " FROM _default.words"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(vector, \$vectorParam)"
                    + " LIMIT 300"
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((hugeListOfFloats)!!))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-order-by[]
        // end::vs-use-vector-match[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVDWithWhere(db: Database, hugeListOfFloats: List<Any?>?) {
        // tag::vs-apvd-where[]
        // use APPROX_VECTOR_DISTANCE with a WHERE clause, in a query
        db.getCollection("words")!!.createIndex("word_index", VectorIndexConfiguration("vector", 300L, 8L))

        val query = db.createQuery(
            "SELECT meta().id, word"
                    + " FROM _default.words"
                    + " WHERE catid = 'cat1'"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(vector, \$vectorParam)"
                    + " LIMIT 300"
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((hugeListOfFloats)!!))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-where[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVDWithPrediction(db: Database, model: PredictiveModel?, hugeListOfFloats: List<Any?>?) {
        // tag::vs-apvd-prediction[]
        // use APPROX_VECTOR_DISTANCE with a predictive model
        Database.prediction.registerModel("WordEmbedding", (model)!!)

        db.getCollection("words")!!.createIndex(
            "words_pred_index",
            VectorIndexConfiguration("prediction(WordEmbedding, {'word': word}).vector", 300L, 8L)
        )

        val query = db.createQuery(
            "SELECT meta().id, word"
                    + " FROM _default.words"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(prediction(WordEmbedding, {'word': word}).vector, \$dinner)"
                    + " LIMIT 300"
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((hugeListOfFloats)!!))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-prediction[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useNumProbes(db: Database) {
        // tag::vs-numprobes-config[]
        // explicitly set numProbes
        val col = db.getCollection("words")!!

        // Like this:
        var idxConfig = VectorIndexConfiguration("vector", 300L, 8L)
        idxConfig.numProbes = 5

        // Or like this:
        idxConfig = VectorIndexConfiguration("vector", 300L, 8L).setNumProbes(5)

        col.createIndex("words_index", idxConfig)

        // end::vs-numprobes-config[]
    }

}
