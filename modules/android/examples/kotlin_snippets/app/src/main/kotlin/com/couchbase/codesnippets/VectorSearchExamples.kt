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

import com.couchbase.lite.Blob
import com.couchbase.lite.Collection
import com.couchbase.lite.CouchbaseLiteException
import com.couchbase.lite.Database
import com.couchbase.lite.MutableArray
import com.couchbase.lite.Parameters
import com.couchbase.lite.PredictiveModel
import com.couchbase.lite.VectorEncoding
import com.couchbase.lite.VectorIndexConfiguration
import com.couchbase.lite.VectorIndexConfigurationFactory
import com.couchbase.lite.newConfig


fun interface ColorModel {
    fun getEmbedding(color: Blob?): List<Float?>?
}

class VectorSearchExamples {
    fun createDefaultVSConfig() {
        // tag::vs-create-default-config[]
        // create the configuration for a vector index named "vector"
        // with 3 dimensions and 100 centroids
        val config = VectorIndexConfigurationFactory.newConfig("vector", 3L, 100L)
        // end::vs-create-default-config[]
    }

    fun createCustomVSConfig() {
        // tag::vs-create-custom-config[]
        // create the configuration for a vector index named "vector"
        // with 3 dimensions, 100 centroids, no encoding, using cosine distance
        // with a max training size 5000 and amin training size 2500
        // no vector encoding and using COSINE distance measurement
        val config = VectorIndexConfigurationFactory.newConfig(
            "vector",
            3L,
            100L,
            encoding = VectorEncoding.none(),
            metric = VectorIndexConfiguration.DistanceMetric.COSINE,
            numProbes = 8L,
            minTrainingSize = 2500L,
            maxTrainingSize = 5000L
        )
        // end::vs-create-custom-config[]
    }

    @Throws(CouchbaseLiteException::class)
    fun createVectorIndex(db: Database) {
        // tag::vs-create-index[]
        // create a vector index named "colors_index"
        // in the collection "_default.colors"
        db.getCollection("colors")?.createIndex(
            "colors_index",
            VectorIndexConfigurationFactory.newConfig("vector", 3L, 100L)
        ) ?: throw IllegalStateException("No such collection: colors")
        // end::vs-create-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun setNumProbes(col: Collection) {
        // tag::vs-numprobes-config[]
        // explicitly set numProbes
        col.createIndex(
            "colors_index",
            VectorIndexConfigurationFactory.newConfig("vector", 3L, 100L, numProbes = 5L)
        )
        // end::vs-numprobes-config[]
    }

    @Throws(CouchbaseLiteException::class)
    fun createPredictiveIndex(db: Database, colorModel: PredictiveModel) {
        // tag::vs-create-predictive-index[]
        // create a vector index with a simple predictive model
        Database.prediction.registerModel("ColorModel", colorModel)

        db.getCollection("colors")?.createIndex(
            "colors_pred_index",
            VectorIndexConfigurationFactory.newConfig(
                "prediction(ColorModel, {'colorInput': color}).vector",
                3L, 100L
            )
        ) ?: throw IllegalStateException("No such collection: colors")
        // end::vs-create-predictive-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useVectorIndex(db: Database, colorVector: List<Any>) {
        // tag::vs-use-vector-index[]
        db.getCollection("colors")?.createIndex(
            "colors_index",
            VectorIndexConfigurationFactory.newConfig("vector", 3L, 100L)
        ) ?: throw IllegalStateException("No such collection: colors")

        // get the APPROX_VECTOR_DISTANCE to the parameter vector for each color in the collection
        val query = db.createQuery(
            "SELECT meta().id, color, APPROX_VECTOR_DISTANCE(vector, \$vectorParam)"
                    + " FROM _default.colors"
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end:vs-use-vector-index[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVD(db: Database, colorVector: List<Any>) {
        // tag::vs-use-vector-match[]
        // tag::vs-apvd-order-by[]
        // use APPROX_VECTOR_DISTANCE in a query ORDER BY clause
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(vector, \$vectorParam)"
                    + " LIMIT 8")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-order-by[]
        // end::vs-use-vector-match[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVDWithWhere(db: Database, colorVector: List<Any>) {
        // tag::vs-apvd-where[]
        // use APPROX_VECTOR_DISTANCE in a query WHERE clause
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " WHERE APPROX_VECTOR_DISTANCE(vector, \$vectorParam) < 0.5")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-where[]
    }

    @Throws(CouchbaseLiteException::class)
    fun useAVDWithPrediction(db: Database, colorModel: PredictiveModel, colorVector: List<Any>) {
        // tag::vs-apvd-prediction[]
        // use APPROX_VECTOR_DISTANCE with a predictive model
        Database.prediction.registerModel("ColorModel", (colorModel))

        db.getCollection("colors")?.createIndex(
            "colors_pred_index",
            VectorIndexConfigurationFactory.newConfig(
                "prediction(ColorModel, {'colorInput': color}).vector",
                3L, 100L
            )
        ) ?: throw IllegalStateException("No such collection: colors")

        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " ORDER BY APPROX_VECTOR_DISTANCE("
                    + "    prediction(ColorModel, {'colorInput': color}).vector,"
                    + "    \$vectorParam)"
                    + " LIMIT 300")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-apvd-prediction[]
    }

    @Throws(CouchbaseLiteException::class)
    fun hybridOrderBy(db: Database, colorVector: List<Any>) {
        // tag::vs-hybrid-order-by[]
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " WHERE saturation > 0.5"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(vector, \$vector)"
                    + " LIMIT 8")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-hybrid-order-by[]
    }

    @Throws(CouchbaseLiteException::class)
    fun hybridWhere(db: Database, colorVector: List<Any>) {
        // tag::vs-hybrid-where[]
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " WHERE saturation > 0.5"
                    + "     AND APPROX_VECTOR_DISTANCE(vector, \$vector) < .05")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-hybrid-where[]
    }

    @Throws(CouchbaseLiteException::class)
    fun hybridPrediction(db: Database, colorVector: List<Any>) {
        // tag::vs-hybrid-prediction[]
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " WHERE saturation > 0.5"
                    + " ORDER BY APPROX_VECTOR_DISTANCE("
                    + "    prediction(ColorModel, {'colorInput': color}).vector,"
                    + "    \$vectorParam)"
                    + " LIMIT 8")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-hybrid-prediction[]
    }

    // ??? vs-hybrid-vmatch[]

    @Throws(CouchbaseLiteException::class)
    fun hybridFullText(db: Database, colorVector: List<Any>) {
        // tag::vs-hybrid-ftmatch[]
        // Create a hybrid vector search query with full-text's match() that
        // uses the the full-text index named "color_desc_index".
        val query = db.createQuery(
            ("SELECT meta().id, color"
                    + " FROM _default.colors"
                    + " WHERE MATCH(color_desc_index, \$text)"
                    + " ORDER BY APPROX_VECTOR_DISTANCE(vector, \$vector)"
                    + " LIMIT 8")
        )
        val params = Parameters()
        params.setArray("vectorParam", MutableArray((colorVector)))
        query.parameters = params

        query.execute().use { rs ->
            // process results
        }
        // end::vs-hybrid-ftmatch[]
    }

    @Throws(CouchbaseLiteException::class)
    fun lazyIndexConfig(db: Database) {
        // tag::vs-lazy-index-config[]
        db.getCollection("colors")?.createIndex(
            "colors_index",
            VectorIndexConfigurationFactory.newConfig("color", 3L, 100L, lazy = true)
        ) ?: throw IllegalStateException("No such collection: colors")
        // end::vs-lazy-index-config[]
    }

    @Throws(Exception::class)
    fun lazyIndexEmbed(col: Collection, colorModel: ColorModel) {
        // tag::vs-create-lazy-index-embedding[]
        while (true) {
            col.getIndex("colors_index")?.beginUpdate(10)?.use { updater ->
                for (i in 0 until updater.count()) {
                    val embedding: List<Float?>? = colorModel.getEmbedding(updater.getBlob(i))
                    if (embedding != null) {
                        updater.setVector(embedding, i)
                    } else {
                        // Bad connection? Corrupted over the wire? Something bad happened
                        // and the vector cannot be generated at the moment: skip it.
                        // The next time beginUpdate() is called, we'll try it again.
                        updater.skipVector(i)
                    }
                }
                // This writes the vectors to the index. You MUST either have set or skipped each
                // of the the vectors in the updater or this call will throw an exception.
                updater.finish()
            }
            // loop until there are no more vectors to update
                ?: break
        }
        // tag::vs-create-lazy-index-embedding[]
    }
}
