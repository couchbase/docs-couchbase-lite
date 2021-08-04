//
//  JsonApiMethods.swift
//  sampleQueryResults
//
//  Created by Ian Bridge on 28/05/2021.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity

//import CoreML


class JsonApi {

    // tag::usingjsonapi[]
    var db = try! Database(name: "hotel")

    func usingJsonApi () throws {
//         seedHotel()
        struct hotelStruct : Codable {
            var id: String
            var type: String
            var name: String
            var city: String
            var country: String
            var description: String
        }



        var x = try Query().dontTestQueryProps()
        print(x)
        // Get a document
        let thisDoc = db.document(withID: "1000")

        // Get document data as JSON String
        let thisDocAsJsonString = thisDoc?.toJSON()

        // Get Json Object from the Json String
        var myJsonObj = thisDocAsJsonString?.toJSONObj()
        print(myJsonObj)
        print( (myJsonObj as! [String:Any])["name"] )
        print( (myJsonObj as! [String:Any])["city"] )

        let jsonData = thisDocAsJsonString?.data(using: .utf8)!

        // Get Json Object as Native Object (anhotel)
        var thehotels:[hotelStruct] = []
        var anhotel:hotelStruct =
            try! JSONDecoder().decode(hotelStruct.self, from: jsonData!)

        print(anhotel.name)
        thehotels.append(anhotel)

        // Update the retrieved Object
        anhotel.name = "A Copy of " + anhotel.name
        anhotel.id = "2001"

        // Convert the updated object to json string
        let newJsonData = try! JSONEncoder().encode(anhotel)
        let newJsonString = String(data: newJsonData, encoding: .utf8)!

        // tag::tojson-document[]

        // Create a new document using the updated JSON String

        let hotel:MutableDocument = MutableDocument.init(id: anhotel.id)

        try! hotel.setJSON(newJsonString)

        // end::tojson-document[]

        try! db.saveDocument(hotel)

        print(db.document(withID: anhotel.id)?.toDictionary())


//        var b:Blob = Blob(contentType: "", contentStream: "")

    }


    public func JsonApiBlob() throws {


    //         seedHotel()
        struct hotelStruct : Codable {
            var id: String
            var type: String
            var name: String
            var city: String
            var country: String
            var description: String
        }
        // tag::tojson-blob[]

        // Get a document
        let thisDoc = db.document(withID: "1000")?.toMutable() // <.>


        // Get the image and add as a blob to the document
        let contentType = "";
        let ourImage = UIImage(named: "couchbaseimage.png")!
        let imageData = ourImage.jpegData(compressionQuality: 1)! // <.>
        thisDoc?.setBlob( Blob(contentType: contentType, data: imageData), forKey: "avatar") //<.>

//        let theBlobAsJSONstringFails = thisDoc?.blob(forKey: "avatar")!.toJSON(); // <.>

        // Save blob as part of doc or alternatively as a blob

        try! db.saveDocument(thisDoc!);
        try! db.saveBlob(blob: Blob(contentType: contentType, data: imageData)); //<.>;

        // Retrieve saved blob as a JSON, reconstitue and check still blob
        let sameDoc = db.document(withID: "1000")?.toMutable()
        let theBlobAsJSONstring = sameDoc?.blob(forKey: "avatar")!.toJSON(); // <.>
        let reconstitutedBlob = MutableDictionaryObject().setDictionary(try MutableDictionaryObject().setJSON(theBlobAsJSONstring!), forKey: "blobCOPY")
        for (key, value) in sameDoc!.toDictionary() {
             print( "Data -- {0) = {1}", key, value);
        }

        if(Blob.isBlob(properties: reconstitutedBlob.dictionary(forKey: "blobCOPY")!.toDictionary())) // <.>
        {
            print(theBlobAsJSONstring);
        }

        // end::tojson-blob[]


    }




    func seedHotel() {

        print(db.document(withID: "2001")?.dictionary(forKey: "2001"))

      try! db.delete()

        db = try! Database(name: "hotel")

        let key = ["id","name","type","city", "country","description"]
        let val = [
                    ["1000","Hotel Ted","hotel","Paris", "France","Very good and central"],
                    ["1001","Hotel Fred","hotel","London", "England","Very good and central"],
                    ["1002","Hotel Du Ville","hotel","Casablanca", "Morocco","Very good and central"],
                    ["1003","Hotel Ouzo","hotel","Athens", "Greece","Very good and central"]
                ]
        let maxrecs=val.count-1
        for i in 0 ... maxrecs {

            let hotel:MutableDocument = MutableDocument.init(id: val[i][0])

            for x in 0 ... key.count-1 {
                hotel.setString(val[i][x], forKey: key[x])
            }

            try! db.saveDocument(hotel)
            print(hotel.id)


//            let hotel:md = MutableDocument.init(id: "J1000", json: <#T##String#>)




        }

    }




    func dontTestJSONdocument() {
        // tag::query-get-all[]
        let db = try! Database(name: "hotel")
        let dbnew = try! Database(name: "newhotels")
        var hotels = [String:Any]()

        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"))
            .from(DataSource.database(db))


        for row in try! listQuery.execute() {
        // end::query-get-all[]

        // tag::tojson-document[]
            var thisId = row.string(forKey: "metaId")! as String

            var thisJSONstring = try! db.document(withID: thisId)!.toJSON() // <.>

            print("JSON String = ", thisJSONstring as! String)

            let hotelFromJSON:MutableDocument = // <.>
                    try! MutableDocument(id: thisId as? String, json: thisJSONstring)

            try! dbnew.saveDocument(hotelFromJSON)

            let newhotel = dbnew.document(withID: thisId)

            let keys = newhotel!.keys
            for key in keys { // <.>
                print(key, newhotel!.value(forKey: key) as! String)
            }

            // end::tojson-document[]

        /*
        // tag::tojson-document-output[]
             JSON String =  {"description":"Very good and central","id":"1000","country":"France","name":"Hotel Ted","type":"hotel","city":"Paris"}
             type hotel
             id 1000
             country France
             city Paris
             description Very good and central
             name Hotel Ted
        // end::tojson-document-output[]
         */
        } // end  query for loop


        // tag::tojson-array[]

        var thisJSONstring = """
            [{\"id\":\"1000\",\"type\":\"hotel\",\"name\":\"Hotel Ted\",\"city\":\"Paris\",
            \"country\":\"France\",\"description\":\"Undefined description for Hotel Ted\"},
            {\"id\":\"1001\",\"type\":\"hotel\",\"name\":\"Hotel Fred\",\"city\":\"London\",
            \"country\":\"England\",\"description\":\"Undefined description for Hotel Fred\"},
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\",
            \"features\":[\"Cable TV\",\"Toaster\",\"Microwave\"]}]
            """
        let myArray:MutableArrayObject =
            try! MutableArrayObject.init(json: thisJSONstring) // <.>

        for i in 0...myArray.count-1 {

            print(i+1, myArray.dictionary(at: i)!.string(forKey: "name")!)

            var docid = myArray.dictionary(at: i)!.string(forKey: "id")

            var newdoc:MutableDocument = // <.>
                try! MutableDocument(id: docid,
                         data: (myArray.dictionary(at: i)?.toDictionary())! )

            try! dbnew.saveDocument(newdoc)

        }

        let extendedDoc = dbnew.document(withID: "1002")
        let features =
            extendedDoc!.array(forKey: "features")?.toArray() // <.>
        for i in 0...features!.count-1 {
            print(features![i])
        }

        print( extendedDoc!.array(
                forKey: "features")?.toJSON() as! String) // <.>

        // end::tojson-array[]


        // tag::tojson-dictionary[]

        var aJSONstring = """
            {\"id\":\"1002\",\"type\":\"hotel\",\"name\":\"Hotel Ned\",\"city\":\"Balmain\",
            \"country\":\"Australia\",\"description\":\"Undefined description for Hotel Ned\"}
            """

        let myDict:MutableDictionaryObject =
            try! MutableDictionaryObject(json: aJSONstring) // <.>
        print(myDict)

        let name = myDict.string(forKey: "name")
        print("Details for: ", name!)

        for key in myDict {

            print(key, myDict.value(forKey: key) as! String)

        }

        try! dontTestTypedAcessors()

        // end::tojson-dictionary[]

        /*
        // tag::tojson-dictionary-output[]

         Details for:  Hotel Ned
         description Undefined description for Hotel Ned
         id 1002
         name Hotel Ned
         country Australia
         type hotel
         city Balmain

         // end::tojson-dictionary-output[]
        */


//    } // end func testjson

//        } // end query loop


    } // end jsonapi func

    func dontTestTypedAcessors() throws {
//        let db = try! Database(name: "hotel")
//        db.

        var newTask:Document = try! db.document(withID: "1001")! // <.>

//        let newTask = Document()

//        // tag::date-getter[]
//        newTask.setValue(Date(), forKey: "createdAt")
//        let date = newTask.date(forKey: "createdAt")
//        // end::date-getter[]

        // tag::to-dictionary[]
        print(newTask.toDictionary()) // returns a Dictionary<String, Any>
        // end::to-dictionary[]

        // tag::to-json[]
        print(newTask.toJSON()) // returns a JSON
        // end::to-json[]

//        print("\(date!)")

    }


}

    extension String {

        func toJSONObj() -> Any {

            let d1 = self.data(using: .utf8)

            return try! JSONSerialization.jsonObject(
                with: d1!, options:[])
        }
    }
//
//





 // end class



