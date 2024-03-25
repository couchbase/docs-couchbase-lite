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
package com.couchbase.codesnippets;

import java.util.List;

import com.couchbase.codesnippets.utils.Logger;
import com.couchbase.codesnippets.utils.Utils;
import com.couchbase.lite.Array;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.MutableDictionary;
import com.couchbase.lite.Parameters;
import com.couchbase.lite.Query;
import com.couchbase.lite.Result;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.VectorEncoding;
import com.couchbase.lite.VectorIndexConfiguration;


@SuppressWarnings("unused")
class VectorSearchExamples {
    public void createDefaultVSConfig() {
        // tag::vs-create-default-config[]
        // create the configuration for a vector indes named "vector"
        // with 300 dimensions and 20 centroids
        VectorIndexConfiguration config = new VectorIndexConfiguration("vector", 300L, 20L);
        // end:::vs-create-default-config[]
    }

    public void createCustomVSConfig() {
        // tag::vs-create-custom-config[]
        // create the configuration for a vector indes named "vector"
        // with 300 dimensions, 20 centroids, max training size 200, min training size 100
        // no vector encoding and using COSINE distance measurement
        VectorIndexConfiguration config = new VectorIndexConfiguration("vector", 300L, 20L)
            .setEncoding(VectorEncoding.none())
            .setMetric(VectorIndexConfiguration.DistanceMetric.COSINE)
            .setMinTrainingSize(100L)
            .setMaxTrainingSize(200L);
        // end:::vs-create-custom-config[]
    }

    public void createVectorIndex(Database db) throws CouchbaseLiteException {
        // tag::vs-create-index[]
        // create a vector index named "words_index"
        // in the collection "_default.words"
        db.getCollection("words").createIndex("word_index", new VectorIndexConfiguration("vector", 300L, 20L));
        // end:::vs-create-index[]
    }

    public void createPredictiveIndex(Database db) throws CouchbaseLiteException {
        // tag::vs-create-predictive-index[]
        // create a vector index with a simple predictive model
        final Collection collection = db.getCollection("words");
        Database.prediction.registerModel(
            "WordEmbedding",
            input -> {
                String word = input.getString("word");
                if (Utils.isEmpty(word)) {
                    Logger.log("Input word is empty");
                    return null;
                }
                try (ResultSet rs = db.createQuery(
                        "SELECT vector"
                            + " FROM " + collection.getFullName()
                            + " WHERE word = '" + word + " '")
                    .execute()) {
                    List<Result> results = rs.allResults();
                    if (results.isEmpty()) { return null; }

                    Array result = results.get(0).getArray(0);
                    if (result != null) {
                        MutableDictionary dict = new MutableDictionary();
                        dict.setValue("vector", result.toList());
                        return dict;
                   }

                    Logger.log("Unexpected result: " + result);
                }
                catch (CouchbaseLiteException e) {
                    Logger.log("Prediction query failed", e);
                }
                return null;
            });

        collection.createIndex(
            "words_pred_index",
            new VectorIndexConfiguration("prediction(WordEmbedding, {'word': word}).vector", 300L, 8L));
        // end:::vs-create-predictive- index[]
    }

    public void useVectorMatch(Database db, List<Object> hugeListOfFloats) throws CouchbaseLiteException {
        // tag::vs-use-vector-match[]
        // use the vector_match function in a query
        db.getCollection("words").createIndex("word_index", new VectorIndexConfiguration("vector", 300L, 8L));

        Query query = db.createQuery(
            "SELECT meta().id, word"
                + " FROM _default.words"
                + " WHERE vector_match(words_index, $vectorParam, 20)");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(hugeListOfFloats));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end:::vs-use-vector-match[]
    }


    public void useVectorDistance(Database db, List<Object> hugeListOfFloats) throws CouchbaseLiteException {
        // tag::vs-use-vector-distance[]
        // use the vector_distance function in a query
        db.getCollection("words").createIndex("word_index", new VectorIndexConfiguration("vector", 300L, 8L));

        Query query = db.createQuery(
            "SELECT meta().id, word,vector_distance(words_index)"
                + " FROM _default.words"
                + " WHERE vector_match(words_index, $dinner, 20)");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(hugeListOfFloats));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end:::vs-use-vector-distance[]
    }
}
