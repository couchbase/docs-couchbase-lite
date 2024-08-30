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

import java.io.IOException;
import java.util.List;

import com.couchbase.lite.Blob;
import com.couchbase.lite.Collection;
import com.couchbase.lite.CouchbaseLite;
import com.couchbase.lite.CouchbaseLiteException;
import com.couchbase.lite.Database;
import com.couchbase.lite.IndexUpdater;
import com.couchbase.lite.MutableArray;
import com.couchbase.lite.Parameters;
import com.couchbase.lite.PredictiveModel;
import com.couchbase.lite.Query;
import com.couchbase.lite.ResultSet;
import com.couchbase.lite.VectorEncoding;
import com.couchbase.lite.VectorIndexConfiguration;


@SuppressWarnings("unused")
class VectorSearchExamples {
    @FunctionalInterface
    public interface ColorModel {
        List<Float> getEmbedding(Blob color) throws IOException;
    }

    public void enableVS() {
        // tag::vs-setup-packaging[]
        try { CouchbaseLite.enableVectorSearch(); }
        catch (CouchbaseLiteException e) {
            throw new IllegalStateException("Could not enable vector search", e);
        }
        // end::vs-setup-packaging[]
    }

    public void createDefaultVSConfig() {
        // tag::vs-create-default-config[]
        // create the configuration for a vector index named "vector"
        // with 3 dimensions and 100 centroids
        VectorIndexConfiguration config = new VectorIndexConfiguration("vector", 3L, 100L);
        // end::vs-create-default-config[]
    }

    public void createCustomVSConfig() {
        // tag::vs-create-custom-config[]
        // create the configuration for a vector index named "vector"
        // with 3 dimensions, 100 centroids, no encoding, using cosine distance
        // with a max training size 5000 and amin training size 2500
        // no vector encoding and using COSINE distance measurement
        VectorIndexConfiguration config = new VectorIndexConfiguration("vector", 3L, 100L)
            .setEncoding(VectorEncoding.none())
            .setMetric(VectorIndexConfiguration.DistanceMetric.COSINE)
            .setNumProbes(8L)
            .setMinTrainingSize(2500L)
            .setMaxTrainingSize(5000L);
        // end::vs-create-custom-config[]
    }

    public void createVectorIndex(Database db) throws CouchbaseLiteException {
        // tag::vs-create-index[]
        // create a vector index named "colors_index"
        // in the collection "_default.colors"
        db.getCollection("colors").createIndex(
            "colors_index",
            new VectorIndexConfiguration("vector", 3L, 100L));
        // end::vs-create-index[]
    }

    public void setNumProbes(Collection col) throws CouchbaseLiteException {
        // tag::vs-numprobes-config[]
        // explicitly set numProbes
        col.createIndex(
            "colors_index",
            new VectorIndexConfiguration("vector", 3L, 100L)
                .setNumProbes(5));
        // end::vs-numprobes-config[]
    }

    public void createPredictiveIndex(Database db, PredictiveModel colorModel) throws CouchbaseLiteException {
        // tag::vs-create-predictive-index[]
        // create a vector index with a simple predictive model
        Database.prediction.registerModel("ColorModel", colorModel);

        db.getCollection("colors").createIndex(
            "colors_pred_index",
            new VectorIndexConfiguration(
                "prediction(ColorModel, {'colorInput': color}).vector",
                3L, 100L));
        // end::vs-create-predictive-index[]
    }

    public void useVectorIndex(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-use-vector-index[]
        db.getCollection("colors").createIndex(
            "colors_index",
            new VectorIndexConfiguration("vector", 3L, 100L));

        // get the APPROX_VECTOR_DISTANCE to the parameter vector for each color in the collection
        Query query = db.createQuery(
            "SELECT meta().id, color, APPROX_VECTOR_DISTANCE(vector, $vectorParam)"
                + " FROM _default.colors");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end:vs-use-vector-index[]
    }

    public void useAVD(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-use-vector-match[]
        // tag::vs-apvd-order-by[]
        // use APPROX_VECTOR_DISTANCE in a query ORDER BY clause
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " ORDER BY APPROX_VECTOR_DISTANCE(vector, $vectorParam)"
                + " LIMIT 8");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-apvd-order-by[]
        // end::vs-use-vector-match[]
    }

    public void useAVDWithWhere(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-apvd-where[]
        // use APPROX_VECTOR_DISTANCE in a query WHERE clause
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " WHERE APPROX_VECTOR_DISTANCE(vector, $vectorParam) < 0.5");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-apvd-where[]
    }

    public void useAVDWithPrediction(Database db, PredictiveModel colorModel, List<Object> colorVector)
        throws CouchbaseLiteException {
        // tag::vs-apvd-prediction[]
        // use APPROX_VECTOR_DISTANCE with a predictive model
        Database.prediction.registerModel("ColorModel", colorModel);

        db.getCollection("colors").createIndex(
            "colors_pred_index",
            new VectorIndexConfiguration(
                "prediction(ColorModel, {'colorInput': color}).vector",
                3L, 100L));

        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " ORDER BY APPROX_VECTOR_DISTANCE("
                + "    prediction(ColorModel, {'colorInput': color}).vector,"
                + "    $vectorParam)"
                + " LIMIT 300");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-apvd-prediction[]
    }

    public void hybridOrderBy(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-hybrid-order-by[]
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " WHERE saturation > 0.5"
                + " ORDER BY APPROX_VECTOR_DISTANCE(vector, $vector)"
                + " LIMIT 8");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-hybrid-order-by[]
    }

    public void hybridWhere(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-hybrid-where[]
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " WHERE saturation > 0.5"
                + "     AND APPROX_VECTOR_DISTANCE(vector, $vector) < .05");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-hybrid-where[]
    }

    public void hybridPrediction(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-hybrid-prediction[]
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " WHERE saturation > 0.5"
                + " ORDER BY APPROX_VECTOR_DISTANCE("
                + "    prediction(ColorModel, {'colorInput': color}).vector,"
                + "    $vectorParam)"
                + " LIMIT 8");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-hybrid-prediction[]
    }

//    ??? vs-hybrid-vmatch[]

    public void hybridFullText(Database db, List<Object> colorVector) throws CouchbaseLiteException {
        // tag::vs-hybrid-ftmatch[]
        // Create a hybrid vector search query with full-text's match() that
        // uses the the full-text index named "color_desc_index".
        Query query = db.createQuery(
            "SELECT meta().id, color"
                + " FROM _default.colors"
                + " WHERE MATCH(color_desc_index, $text)"
                + " ORDER BY APPROX_VECTOR_DISTANCE(vector, $vector)"
                + " LIMIT 8");
        Parameters params = new Parameters();
        params.setArray("vectorParam", new MutableArray(colorVector));
        query.setParameters(params);

        try (ResultSet rs = query.execute()) {
            // process results
        }
        // end::vs-hybrid-ftmatch[]
    }

    public void lazyIndexConfig(Database db) throws CouchbaseLiteException {
        // tag::vs-lazy-index-config[]
        db.getCollection("colors").createIndex(
            "colors_index",
            new VectorIndexConfiguration("color", 3L, 100L)
                .setLazy(true));
        // end::vs-lazy-index-config[]
    }

    public void lazyIndexEmbed(Collection col, ColorModel colorModel) throws CouchbaseLiteException {
        // tag::vs-create-lazy-index-embedding[]
        while (true) {
            try (IndexUpdater updater = col.getIndex("colors_index").beginUpdate(10)) {
                if (updater == null) { break; }
                for (int i = 0; i < updater.count(); i++) {
                    try {
                        // get the color swatch from the updater and send it to the remote model
                        List<Float> embedding = colorModel.getEmbedding(updater.getBlob(i));
                        updater.setVector(embedding, i);
                    }
                    catch (IOException e) {
                        // Bad connection? Corrupted over the wire? Something bad happened
                        // and the vector cannot be generated at the moment: skip it.
                        // The next time beginUpdate() is called, we'll try it again.
                        updater.skipVector(i);
                    }
                }
                // This writes the vectors to the index. You MUST either have set or skipped each
                // of the the vectors in the updater or this call will throw an exception.
                updater.finish();
            }
        }
        // tag::vs-create-lazy-index-embedding[]
    }
}
