#pragma once
#include <cbl/CouchbaseLite.h>
#include <fleece/Fleece.h>
#include <stdexcept>
#include <vector>

class Color {
public:
    static std::vector<float> getVector(std::string color) {
        return {};
    }
};

class TransientError : public std::exception { };

class VectorSearch {
public:

    void enableVectorSearchExtension()
    {
        // tag::vs-setup-packaging[]
        CBL_SetExtensionPath(FLStr("/path/to/extension_dir"));
        // end::vs-setup-packaging[]
    }

    void createDefaultVectorIndexConfig() {
        // tag::vs-create-default-config[]
        // Create a vector index configuration for indexing 3-dimensional vectors embedded
        // in the documents' key named "vector" using 2 centroids.
        CBLVectorIndexConfiguration config{};
        config.expressionLanguage = kCBLN1QLLanguage;
        config.expression = FLStr("vector");
        config.dimensions = 3;
        config.centroids = 2;
        // end::vs-create-default-config[]
    }

    void createCustomVectorIndexConfig() {
        // tag::vs-create-custom-config[]
        // Create a vector index configuration for indexing 3-dimensional vectors embedded
        // in the documents' key named "vector" using 2 centroids. The config is customized
        // to use Cosise distance metric, no vector encoding, min training size 100 and
        // max training size 200.
        CBLVectorIndexConfiguration config{};
        config.expressionLanguage = kCBLN1QLLanguage;
        config.expression = FLStr("vector");
        config.dimensions = 3;
        config.centroids = 2;
        // Note: Calls CBLVectorEncoding_Free(config.encoding) after creating the index.
        config.encoding = CBLVectorEncoding_CreateNone();
        config.minTrainingSize = 100;
        config.maxTrainingSize = 200;
        // end::vs-create-custom-config[]
    }

    void createVectorIndex() {
        CBLDatabase* database = getDatabase();

        // tag::vs-create-index[]
        CBLVectorIndexConfiguration config {};
        config.expressionLanguage = kCBLN1QLLanguage;
        config.expression = FLStr("vector");
        config.dimensions = 3;
        config.centroids = 2;
        config.encoding = CBLVectorEncoding_CreateNone();

        CBLError err {};
        CBLCollection* collection = CBLDatabase_Collection(database, FLStr("colors"), FLStr("_default"), &err);
        if (collection == nullptr) { throw std::domain_error("No Collection Found"); }

        bool result = CBLCollection_CreateVectorIndex(collection, FLStr("colors_index"), config, &err);
        if (!result) { throw std::domain_error("Create Index Error"); }

        CBLVectorEncoding_Free(config.encoding);
        CBLCollection_Release(collection);
        // end::vs-create-index[]
    }

    void createVectorIndexWithPredictiveModel() {
        CBLDatabase* database = getDatabase();

        // tag::vs-predictive-model[]
        auto callback = [](void* context, FLDict input) -> FLSliceResult {
            // Set color input string
            FLString color = FLValue_AsString(FLDict_Get(input, FLStr("colorInput")));

            // Call MLModel to embedding:
            auto colorString = std::string(static_cast<const char *>(color.buf), color.size);
            std::vector<float> colorVector = Color::getVector(colorString);

            // Construct output as Fleece Dictionary Encoded:
            FLMutableArray vectorArray = FLMutableArray_New();
            for (float val : colorVector) {
                FLMutableArray_AppendFloat(vectorArray, val);
            }

            FLEncoder enc = FLEncoder_New();
            FLEncoder_BeginDict(enc, 1);
            FLEncoder_WriteKey(enc, FLStr("vector_output"));
            FLEncoder_WriteValue(enc, (FLValue)vectorArray);
            FLEncoder_EndDict(enc);
            FLMutableArray_Release(vectorArray);
            return FLEncoder_Finish(enc, nullptr);
        };

        CBLPredictiveModel model {};
        model.prediction = callback;
        // tag::end-predictive-model[]

        // tag::vs-create-predictive-index[]
        // Register the predictive model named "ColorModel".
        CBL_RegisterPredictiveModel(FLStr("ColorModel"), model);

        // Create a vector index configuration with an expression using the prediction
        // function to get the vectors from the registered predictive model.
        CBLVectorIndexConfiguration config {};
        config.expressionLanguage = kCBLN1QLLanguage;
        config.expression = FLStr("predict(ColorModel, {\"colorInput\": color})");
        config.dimensions = 3;
        config.centroids = 2;
        config.encoding = CBLVectorEncoding_CreateNone();

        CBLError err {};
        CBLCollection* collection = CBLDatabase_Collection(database, FLStr("colors"), FLStr("_default"), &err);
        if (collection == nullptr) { throw std::domain_error("No Collection Found"); }

        bool result = CBLCollection_CreateVectorIndex(collection, FLStr("colors_index"), config, &err);
        if (!result) { throw std::domain_error("Create Index Error"); }

        CBLVectorEncoding_Free(config.encoding);
        CBLCollection_Release(collection);
        // end::vs-create-predictive-index[]
    }

    void createLazyIndex() {
        // tag::vs-lazy-index-config[]
        // Creating a lazy vector index using the document's 'color' key.
        // The value of this key will be used to compute a vector when updating the index.
        CBLVectorIndexConfiguration config{};
        config.expressionLanguage = kCBLN1QLLanguage;
        config.expression = FLStr("color");
        config.dimensions = 3;
        config.centroids = 2;
        config.isLazy = true;
        // end::vs-lazy-index-config[]
    }

    void updateLazyIndex() {
        CBLDatabase* database = getDatabase();
        CBLCollection* collection = CBLDatabase_Collection(database, FLStr("colors"), FLStr("_default"), nullptr);

        // tag::vs-create-lazy-index-embedding[]
        CBLError err {};
        CBLQueryIndex* index = CBLCollection_GetIndex(collection, FLStr("color_index"), &err);
        if (!index) { throw std::domain_error("Index Not Found"); }

        while (true) {
            // Start an update on it (in this case, limit to 50 entries at a time)
            CBLIndexUpdater* updater = CBLQueryIndex_BeginUpdate(index, 50, &err);
            if (!updater) {
                if (err.code != 0) { throw std::domain_error("Error Begin Update"); }
                // If updater is NULL and no error, that means there are no more entries to process
                break;
            }

            for (size_t i = 0; i < CBLIndexUpdater_Count(updater); i++) {
                // The value type will depend on the expression you have set in your index.
                // In this example, it is a string property.
                FLString value = FLValue_AsString(CBLIndexUpdater_Value(updater, i));
                std::string colorString = std::string((char*)value.buf, value.size);

                std::vector<float> vector;
                try {
                    // Call a MLModel to get a vector.
                    vector = Color::getVector(colorString);
                } catch (const TransientError& e) {
                    // Bad connection? Corrupted over the wire? Something bad happened
                    // and the vector cannot be generated at the moment. So skip
                    // this entry. The next time CBLQueryIndex_BeginUpdate is called,
                    // it will be considered again.
                    CBLIndexUpdater_SkipVector(updater, i);
                } catch (...) {
                    // An unexpected error happened.
                    CBLIndexUpdater_Release(updater);
                    throw std::domain_error("Error Getting a Vector");
                }

                bool success;
                if (!vector.empty()) {
                    // The size of the vector must match the number of dimensions set in the index.
                    // Otherwise, an error will be returned.
                    success = CBLIndexUpdater_SetVector(updater, i, vector.data(),vector.size(),  &err);
                } else {
                    // No vector applicable. Calling SetVector with NULL will
                    // cause the underlying document to NOT be indexed
                    success = CBLIndexUpdater_SetVector(updater, i, nullptr, 0, &err);
                }
                if (!success) {
                    CBLIndexUpdater_Release(updater);
                    throw std::domain_error("Error Setting a Vector");
                }
            }

            // This writes the vectors to the index. You MUST have either set or
            // skipped all the values inside the updater or this call will return an error.
            if (!CBLIndexUpdater_Finish(updater, &err)) {
                CBLIndexUpdater_Release(updater);
                throw std::domain_error("Error Finish Updating");
            }

            CBLIndexUpdater_Release(updater);
        }

        CBLQueryIndex_Release(index);

        // end::vs-create-lazy-index-embedding[]
    }

    void queryUsingVectorMatch() {
        CBLDatabase* database = getDatabase();

        // tag::vs-use-vector-match[]
        // Create a query to search similar colors by using the vector_match()
        // function in the vector index named "colors_index".
        CBLError err{};
        const char* sql = "SELECT id, color FROM _default.colors WHERE vector_match(colors_index, $vector, 8)";
        CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
                                                  FLStr(sql),
                                                  nullptr, &err);

        // Get a vector, an array of float numbers, for the input color code (e.g. FF000AA).
        // Normally, you will get the vector from your ML model.
        std::vector colorVector = Color::getVector("FF00AA");

        // Set the vector array to the parameter "$vector"
        auto colorArray = FLMutableArray_New();
        for (auto val : colorVector) {
            FLMutableArray_AppendFloat(colorArray, val);
        }

        auto params = FLMutableDict_New();
        FLMutableDict_SetArray(params, FLSTR("vector"), colorArray);
        CBLQuery_SetParameters(query, params);

        FLMutableArray_Release(colorArray);
        FLMutableDict_Release(params);

        // Execute the query:
        auto results = CBLQuery_Execute(query, &err);
        if (!results) {
            throw std::domain_error("Invalid Query");
        }

        while(CBLResultSet_Next(results)) {
            // Process results
        }
        // end::vs-use-vector-match[]
    }

    void queryUsingVectorDistance() {
        CBLDatabase* database = getDatabase();

        // tag::vs-use-vector-distance[]
        // Create a query to get vector distances using the vector_distance() function.
        CBLError err{};
        const char* sql = "SELECT id, color, vector_distance(colors_index) FROM _default.colors WHERE vector_match(colors_index, $vector, 8)";
        CBLQuery* query = CBLDatabase_CreateQuery(database, kCBLN1QLLanguage,
                                                  FLStr(sql),
                                                  nullptr, &err);

        // Get a vector, an array of float numbers, for the input color code (e.g. FF000AA).
        // Normally, you will get the vector from your ML model.
        std::vector colorVector = Color::getVector("FF00AA");

        // Set the vector array to the parameter "$vector"
        auto colorArray = FLMutableArray_New();
        for (auto val : colorVector) {
            FLMutableArray_AppendFloat(colorArray, val);
        }

        auto params = FLMutableDict_New();
        FLMutableDict_SetArray(params, FLSTR("vector"), colorArray);
        CBLQuery_SetParameters(query, params);

        FLMutableArray_Release(colorArray);
        FLMutableDict_Release(params);

        // Execute the query:
        auto results = CBLQuery_Execute(query, &err);
        if (!results) {
            throw std::domain_error("Invalid Query");
        }

        while(CBLResultSet_Next(results)) {
            // Process results
        }
        // end::vs-use-vector-distance[]
    }

private:
    CBLDatabase* db {};

    CBLDatabase* getDatabase() {
        if (!db) {
            db = CBLDatabase_Open(FLStr("my-database"), nullptr, nullptr);
        }
        return db;
    }
};

