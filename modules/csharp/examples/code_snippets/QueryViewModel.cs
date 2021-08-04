using System;
using System.Linq;
using System.Collections.Generic;
using cblQueryEgAppProj.Models;
using Couchbase.Lite;
using Couchbase.Lite.DI;
using Couchbase.Lite.Query;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using cblQueryEgAppProj.Services;
using System.IO;
using Couchbase.Lite.DI;
using System.Collections;

namespace cblQueryEgAppProj.ViewModels
{
    public class QueryViewModel : BaseViewModel
    {
        public QueryViewModel()
        {
        }

        public static void testQuerySyntaxAll()
        {
            // For Documentation
           
            
            var dbName = "travel-sample";
            var this_Db = new Database(dbName);

            string thisDocsId;
            string thisDocsName;
            string thisDocsType;
            string thisDocsCity;
            Dictionary<string, object> hotel = new Dictionary<string, object>();
            Dictionary<string, object> hotels = new Dictionary<string, object>();

            // tag::query-syntax-all[]
            var query = QueryBuilder
                  .Select(SelectResult.All())
                  .From(DataSource.Database(this_Db)); // <.>
            // end::query-syntax-all[]

            // tag::query-access-all[]
            var results = query.Execute().AllResults();

            if (results?.Count > 0)
            {
                foreach (var result in results)
                {
                    // get the result into our dictionary object
                    var thisDocsProps = result.GetDictionary(dbName); // <.>

                    if (thisDocsProps != null)
                    {
                        thisDocsId = thisDocsProps.GetString("id"); // <.>
                        thisDocsName = thisDocsProps.GetString("name");
                        thisDocsCity = thisDocsProps.GetString("city");
                        thisDocsType = thisDocsProps.GetString("type");
                        hotel = thisDocsProps.ToDictionary();
                        // Store this hotel in a list of hotels
                        hotels.Add(
                            hotel["Id"].ToString(),
                            hotel);
                    }

                }
            }
            // end::query-access-all[]

            // tag::query-access-json[]

            foreach (var result in query.Execute().AsEnumerable())
            {

                // get the result into a JSON String
                string thisDocsJSONString = result.GetDictionary(dbName).ToJSON();// <.>

                // deserialize the string to a json objetc
                var thisDocsJSONObject = (JObject)JsonConvert.DeserializeObject(thisDocsJSONString);

                // use the json object's properties
                if (thisDocsJSONObject != null)
                {
                    thisDocsId = thisDocsJSONObject["id"].ToString(); // <.>
                    thisDocsName = thisDocsJSONObject["name"].ToString();
                    thisDocsCity = thisDocsJSONObject["city"].ToString();
                    thisDocsType = thisDocsJSONObject["type"].ToString();

                    //Get the JSON string back to a C# object
                    Hotel this_hotel = JsonConvert.DeserializeObject<Hotel>(thisDocsJSONString);

                    // Store this hotel object in a list of hotels
                    hotels.Add(
                        this_hotel.Id.ToString(),
                        this_hotel);


                }

            } // end foreaach result
            // end::query-access-json[]
        }


        private static void testQuerySyntaxProps()
        {
            // For Documentation
            var dbName = "travel-sample";
            var this_Db = new Database(dbName);

            string thisDocsName;
            string thisDocsType;
            string thisDocsCity;
            Dictionary<string, object> hotel = new Dictionary<string, object>();
            Dictionary<string, object> hotels = new Dictionary<string, object>();
            //List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

            // tag::query-syntax-props[]
            var query = QueryBuilder.Select(
                    SelectResult.Property("type"),
                    SelectResult.Property("name"),
                    SelectResult.Property("city")).From(DataSource.Database(this_Db));
            // end::query-syntax-props[]

            // tag::query-access-props[]
            var results = query.Execute().AllResults();
            foreach (var result in results)

            {

                // get the returned array of k-v pairs into a dictionary
                Dictionary<string, object> hotelChanges = result.ToDictionary();

                // If this hotel exists then apply updates
                if (hotels.ContainsKey(hotel["Id"].ToString()))
                {

                    hotel.Equals(hotels[hotel["Id"].ToString()]);

                    hotels.Remove(hotel["Id"].ToString());

                    hotel["name"] = hotelChanges["name"];
                    hotel["city"] = hotelChanges["name"];
                    hotel["type"] = hotelChanges["type"];

                    hotels.Add(
                        hotel["Id"].ToString(),
                        hotel);
                }
                else { /* handle exception */ }

                // use the properties of the returned array of k-v pairs directly
                thisDocsType = result.GetString("type");
                thisDocsName = result.GetString("name");
                thisDocsCity = result.GetString("city");

            }

            // end::query-access-props[]
        }


        private static void testQuerySyntaxCount()
        {
            // For Documentation
            var dbName = "travel-sample";
            var this_Db = new Database(dbName);

            Dictionary<string, object> hotel = new Dictionary<string, object>();
            List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

            // tag::query-syntax-count-only[]
            var query =
              QueryBuilder
                .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount")) // <.>
                .From(DataSource.Database(this_Db));

            // end::query-syntax-count-only[]


            // tag::query-access-count-only[]
            var results = query.Execute().AllResults();
            foreach (var result in results)
            {
                var numberOfDocs = result.GetInt("mycount"); // <.>
                // end::query-access-count-only[]
            }
        }


        private static void testQueryForID()
        {

            // For Documentation
            var dbName = "travel-sample";
            var this_Db = new Database(dbName);

            Dictionary<string, object> hotel = new Dictionary<string, object>();
            List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();


            // tag::query-syntax-id[]
            var query = QueryBuilder
                    .Select(SelectResult.Expression(Meta.ID).As("this_ID")) // <.>
                    .From(DataSource.Database(this_Db));

            // end::query-syntax-id[]


            // tag::query-access-id[]
            var results = query.Execute().AllResults();
            foreach (var result in results)
            {

                var thisDocsID = result.GetString("this_ID"); // <.>
                var doc = this_Db.GetDocument(thisDocsID);
            }
            //end::query-access-id[]
        }


        private static void testQueryPagination()
        {
            // For Documentation
            var dbName = "travel-sample";
            var this_Db = new Database(dbName);
            Dictionary<string, object> hotel = new Dictionary<string, object>();
            List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();


            //tag::query-pagination[]

            var thisLimit = 20;
            var thisOffset = 0;

            var countQuery =
                QueryBuilder
                   .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount")) // <.>
                   .From(DataSource.Database(this_Db));

            var numberOfDocs =
                countQuery.Execute().AllResults().ElementAt(0).GetInt("mycount"); // <.>

            if (numberOfDocs < thisLimit)
            {
                thisLimit = numberOfDocs;
            }

            while (thisOffset < numberOfDocs)
            {
                var listQuery =
                    QueryBuilder
                        .Select(SelectResult.All())
                        .From(DataSource.Database(this_Db))
                        .Limit(Expression.Int(thisLimit), Expression.Int(thisOffset)); // <.>

                foreach (var result in listQuery.Execute().AllResults())
                {
                    // Display and or process query results batch

                }

                thisOffset = thisOffset + thisLimit;

            } // end while

            //end::query-pagination[]

        } // testQueryPagination



        public static List<Result> testN1QLQueryString (Database argDB)
        {
            // For Documentation
            //Database this_Db = argDB;
            var dbName = "travel-sample";
            Database this_Db;
            var username = "ian";
            IQuery thisQuery;

            DatabaseConfiguration dbCfg = new DatabaseConfiguration();
            dbCfg.Directory =
                Path.Combine(Service.GetInstance<IDefaultDirectoryResolver>().DefaultDirectory(), username);

            Database thisDb = new Database(dbName, dbCfg);

            thisQuery = thisDb.CreateQuery("SELECT META().id FROM  _default WHERE type = 'hotel'");
            
            return thisQuery.Execute().AllResults(); 


            //Dictionary<string, object> hotel = new Dictionary<string, object>();
            //List<Dictionary<string, object>> hotels = new List<Dictionary<string, object>>();

            //// tag::query-syntax-count-only[]
            //var query =
            //  QueryBuilder
            //    .Select(SelectResult.Expression(Function.Count(Expression.All())).As("mycount")) // <.>
            //    .From(DataSource.Database(this_Db));

            //// end::query-syntax-count-only[]


            //// tag::query-access-count-only[]
            //var myresults = query.Execute().AllResults();
            //foreach (var myresult in myresults)
            //{
            //    var numberOfDocs = myresult.GetInt("mycount"); // <.>
            //    // end::query-access-count-only[]
            //}
        }




    } // public class
} // namespace

 