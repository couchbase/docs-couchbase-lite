//
// VectorSearch.cs
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

using Couchbase.Lite;
using Couchbase.Lite.Enterprise.Query;
using Couchbase.Lite.Extensions;
using Couchbase.Lite.Query;

namespace api_walkthrough
{
    class Color
    {
        public static float[] GetVector(string color)
        {
            return new float[] { 0.0f, 0.0f, 0.0f };
        }

        public string Name { get; set; }
    }

    public class VectorSearch
    {
        public VectorSearch() { }

        private static Task<float[]> GenerateEmbedding(string input)
        {
            return Task.FromResult(Enumerable.Empty<float>().ToArray());
        }

        private static void EnableVectorSearchExtension()
        {
            // tag::vs-setup-packaging[]
            Extension.Enable(new VectorSearchExtension());
            // end::vs-setup-packaging[]
        }

        private void CreateDefaultVectorIndexConfig()
        {
            // tag::vs-create-default-config[]
            // Create a vector index configuration for indexing 3 dimensional vectors embedded
            // in the documents' key named "vector" using 2 centroids.
            var config = new VectorIndexConfiguration("color", 3, 100);
            // end::vs-create-default-config[]
        }
        private void CreateCustomVectorIndexConfig()
        {
            // tag::vs-create-custom-config[]
            // Create a vector index configuration for indexing 3 dimensional vectors embedded
            // in the documents' key named "vector" using 2 centroids. The config is customized
            // to use Cosise distance metric, no vector encoding, min training size 100 and
            // max training size 200.
            var config = new VectorIndexConfiguration("color", 3, 100)
            {
                DistanceMetric = DistanceMetric.Cosine,
                Encoding = VectorEncoding.None(),
                MinTrainingSize = 2500,
                MaxTrainingSize = 5000
            };
            // end::vs-create-custom-config[]
        }

        private void CreateLazyIndex()
        {
            // tag::vs-lazy-index-config[]
            // Creating a lazy vector index is the same as creating a normal one, except
            // with the IsLazy property set to true
            var config = new VectorIndexConfiguration("vector", 3, 2)
            {
                IsLazy = true
            };
            // end::vs-lazy-index-config[]
        }

        private async Task UpdateLazyIndex()
        {
            var database = new Database("my-database");
            var collection = database.GetDefaultCollection();

            // tag::vs-create-lazy-index-embedding[]
            // Retrieve the index you wish to update
            var index = collection.GetIndex("index-name");

            // Start an update on it (in this case, limit to 50 entries at a time)
            var updater = index.BeginUpdate(50);

            // If updater is null, that means there are no more entries to process
            while (updater != null) {
                using (updater) {
                    // Otherwise, the updater will contain a list of data that needs embeddings generated
                    int i = 0;
                    foreach (var entry in updater) {
                        // The type of entry will depend on what you have set as your index.
                        // In this example, we will assume it was set to a string property.
                        // Let's also assume that if an embedding is not applicable, this
                        // pseudo function returns null
                        try {
                            var embedding = await GenerateEmbedding((string)entry);
                            if (embedding == null) {
                                // No embedding applicable.  Calling SetVector will null will
                                // cause the underlying document to NOT be indexed
                                updater.SetVector(i, null);
                            } else {
                                // Yes this if/else is unneeded, and only to demonstrate the
                                // effect of setting null in SetVector
                                updater.SetVector(i, embedding);
                            }
                        } catch (Exception) {
                            // Bad connection?  Corrupted over the wire?  Something bad happened
                            // and the embedding cannot be generated at the moment.  So skip
                            // this entry.  The next time BeginUpdate is called, it will be considered again
                            updater.SkipVector(i);
                        }
                    }

                    // This writes the vectors to the index.  Disposing it without calling this
                    // will throw out the results without saving.  You MUST have either set or
                    // skipped all the entries inside of the updater or this call will throw an exception.
                    updater.Finish();
                }

                // Ready for the next batch!
                updater = index.BeginUpdate(50);
            }
            // end::vs-create-lazy-index-embedding[]
        }

        private void CreateVectorIndex()
        {
            
            var database = new Database("my-database");
  
            // tag::vs-create-index[]
            // Create a vector index configuration for indexing 3 dimensional vectors embedded
            // in the documents' key named "vector" using 2 centroids.
            var config = new VectorIndexConfiguration("color", 3, 100);

            // Create a vector index named "color_index" using the configuration
            var collection = database.GetCollection("colors");
            collection.CreateIndex("colors_index", config);
            // end::vs-create-index[]
        }

        // tag::vs-predictive-model[]
        public sealed class ColorModel : IPredictiveModel
        {
            public DictionaryObject Predict(DictionaryObject input)
            {
                // Get the input color code 
                var inputColor = input.GetString("colorInput");
                if (inputColor == null)
                {
                    return null;
                }

                // Get a vector, an array of float numbers, for the input color code.
                // Normally, you will get the vector from your ML model.
                float[] vector;
                try
                {
                    vector = Color.GetVector(inputColor);
                }
                catch (Exception)
                {
                    return null;
                }

                // Create an output dictionary by setting the vector result to
                // the dictionary key named "vector".
                var retVal = new MutableDictionaryObject();
                retVal.SetValue("vector", vector);
                return retVal;
            }
        }
        // tag::end-predictive-model[]

        private void CreatePredictiveIndex()
        {
            var database = new Database("my-database");

            // tag::vs-create-predictive-index[]
            // Register the predictive model named "ColorModel".
            Database.Prediction.RegisterModel("ColorModel", new ColorModel());

            // Create a vector index configuration with an expression using the prediction
            // function to get the vectors from the registered predictive model.
            var expression = "prediction(ColorModel, {\"colorInput\": color}).vector";
            var config = new VectorIndexConfiguration(expression, 3, 100);

            // Create a vector index from the configuration
            var collection = database.GetCollection("colors");
            collection.CreateIndex("colors_index", config);
            // end::vs-create-predictive-index[]
        }

        private void QueryUsingVectorMatch()
        {
            var database = new Database("my-database");

            string inputColor = "FF00AA";

            // tag::vs-use-vector-match[]
            // Create a query to search similar colors by using the vector_match()
            // function in the vector index named "colors_index".
            var sql = "SELECT id, color " +
                      "FROM _default.colors " +
                      "ORDER BY approx_vector_distance(vector, $vector) " +
                      "LIMIT 8";
            var query = database.CreateQuery(sql);

            // Get a vector, an array of float numbers, for the input color code.
            // Normally, you will get the vector from your ML model.
            var vector = Color.GetVector(inputColor);

            // Set the vector array to the parameter "$vector"
            var queryParams = new Parameters();
            queryParams.SetValue("vector", vector);
            query.Parameters = queryParams;

            // Execute the query
            var results = query.Execute();
            foreach (var r in results)
            {
                // process results
            }
            // end::vs-use-vector-match[]
        }

        private void QueryUsingVectorDistance()
        {
           
            var database = new Database("my-database");

            // tag::vs-use-vector-distance[]
            // Create a query to get vector distances using the vector_distance() function.
            var sql = "SELECT id, color, approx_vector_distance(vector, $vector) " +
                      "FROM _default.colors " +
                      "LIMIT 8";
            var query = database.CreateQuery(sql);

            // Get a vector, an array of float numbers, for the input color code
            // e.g. FF000AA. Mostly, the vector will be generated from a ML Model.
            var vector = Color.GetVector("FFOOAA");

            // Set the vector array to the parameter "$vector"
            var queryParams = new Parameters();
            queryParams.SetValue("vector", vector);
            query.Parameters = queryParams;

            // Execute the query
            var results = query.Execute();
            foreach (var r in results)
            {
                // process results
            }
            // end::vs-use-vector-distance[]
        }
    }
}

