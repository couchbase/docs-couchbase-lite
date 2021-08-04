using System;
using System.Linq;
using System.Collections.Generic;
using cblQueryEgAppProj.Models;
using cblQueryEgAppProj.ViewModels;
using Couchbase.Lite;
using Couchbase.Lite.DI;
using Couchbase.Lite.Query;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using cblQueryEgAppProj.Services;
using System.IO;
using Couchbase.Lite.DI;
using System.Collections;
using System.Web;
using System.Collections.ObjectModel;
using Xamarin.Forms;

namespace cblQueryEgAppProj.ViewModels
{
    public class JsonApiMethodz : BaseViewModel
    {

        private Item _selectedItem;

        public ObservableCollection<Item> Items { get; }
        public Command LoadItemsCommand { get; }
        public Command AddItemCommand { get; }
        private Database this_Db;
        public JsonApiMethodz()
        {

            this_Db = DataStore.getDbHandle();
            //JsonApiDocument();
            //JsonApiArray();
            JsonApiDictionary();
        }

        public void JsonApiDocument()
        {

            // tag::toJson-document[]
            Database this_DB = new Database("travel-sample");
            Database newDb = new Database("ournewdb");

            // Get a document
            var thisDoc = this_Db.GetDocument("hotel_10025");

            // Get document data as JSON String
            var thisDocAsJsonString = thisDoc?.ToJSON(); // <.>

            // Get Json Object from the Json String
            JObject myJsonObj = JObject.Parse(thisDocAsJsonString);

            // Get Native Object (anhotel) from JSON String
            List<Hotel> thehotels = new List<Hotel>();

            Hotel anhotel = new Hotel();
            anhotel = JsonConvert.DeserializeObject<Hotel>(thisDocAsJsonString);
            thehotels.Add(anhotel);

            // Update the retrieved native object
            anhotel.Name = "A Copy of " + anhotel.Name;
            anhotel.Id = "2001";

            // Convert the updated object back to a JSON string
            var newJsonString = JsonConvert.SerializeObject(anhotel);

            // Update new document with JSOn String
            MutableDocument newhotel =
                new MutableDocument(anhotel.Id, newJsonString); // <.>

            foreach (string key in newhotel.ToDictionary().Keys)
            {
                System.Console.WriteLine("Data -- {0} = {1}",
                    key, newhotel.GetValue(key));
            }

            newDb.Save(newhotel);

            var thatDoc = newDb.GetDocument("2001").ToJSON(); // <.>
            System.Console.Write(thatDoc);

            // end::toJson-document[]


        //    // tag::toJson-document-output[]
        //    JSON String = { "description":"Very good and central","id":"1000","country":"France","name":"Hotel Ted","type":"hotel","city":"Paris"}
        //             type = hotel
        //             id = 1000
        //             country = France
        //             city = Paris
        //             description = Very good and central
        //             name = Hotel Ted
        //        // end::toJson-document-output[]
        //         */

        } // End JSONAPIDocument


    public void JsonApiArray()
        {
            // Init for docs
            //var this_Db = DataStore.getDbHandle();
            var ourdbname = "ournewdb";

            if (Database.Exists(ourdbname, "/"))
            {
                Database.Delete(ourdbname, "/");
            }

        // tag::toJson-array[]

            Database dbNew = new Database(ourdbname);

            // JSON String -- an Array (3 elements. including embedded arrays)
            var thisJSONstring = "[{'id':'1000','type':'hotel','name':'Hotel Ted','city':'Paris','country':'France','description':'Undefined description for Hotel Ted'},{'id':'1001','type':'hotel','name':'Hotel Fred','city':'London','country':'England','description':'Undefined description for Hotel Fred'},                        {'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}]".Replace("'", "\"");

            // Get JSON Array from JSON String
            JArray myJsonObj = JArray.Parse(thisJSONstring);

            // Create mutable array using JSON String Array
            var myArray = new MutableArrayObject();
            myArray.SetJSON(thisJSONstring);  // <.>


            // Create a new documenty for each array element
            for (int i = 0; i < myArray.Count; i++)
            {
                var dict = myArray.GetDictionary(i);
                var docid = myArray[i].Dictionary.GetString("id");
                var newdoc = new MutableDocument(docid, dict.ToDictionary()); // <.>
                dbNew.Save(newdoc);
            }

            // Get one of the created docs and iterate through one of the embedded arrays
            var extendedDoc = dbNew.GetDocument("1002");
            var features = extendedDoc.GetArray("features");
            // <.>
            foreach (string feature in features) {
                System.Console.Write(feature); // <.>
                //process array item as required
            }

            var featuresJSON = extendedDoc.GetArray("features").ToJSON(); // <.>

            // end::toJson-array[]
        }


        public void JsonApiDictionary()
        {

            var ourdbname = "ournewdb";

            if (Database.Exists(ourdbname, "/"))
            {
                Database.Delete(ourdbname, "/");
            }
            Database dbNew = new Database(ourdbname);

            // tag::toJson-dictionary[]

            // Get dictionary from JSONstring
            var aJSONstring = "{'id':'1002','type':'hotel','name':'Hotel Ned','city':'Balmain','country':'Australia','description':'Undefined description for Hotel Ned','features':['Cable TV','Toaster','Microwave']}".Replace("'", "\"");
            var myDict = new MutableDictionaryObject(json: aJSONstring); // <.>

            // use dictionary to get name value
            var name = myDict.GetString("name");


            // Iterate through keys
            foreach (string key in myDict.Keys)
            {
                System.Console.WriteLine("Data -- {0} = {1}", key, myDict.GetValue(key).ToString());

            }
            // end::toJson-dictionary[]

            /*
            // tag::toJson-dictionary-output[]

                mono-stdout: Data -- id = 1002
                mono-stdout: Data -- type = hotel
                mono-stdout: Data -- name = Hotel Ned
                mono-stdout: Data -- city = Balmain
                mono-stdout: Data -- country = Australia
                mono-stdout: Data -- description = Undefined description for Hotel Ned
                mono-stdout: Data -- features = Couchbase.Lite.MutableArrayObject

            // end::toJson-dictionary-output[]
            */
        } /* end of func */



    }
    // end class
}


