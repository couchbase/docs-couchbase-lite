
//
//  QueryResultSets.swift
//  sampleQueryResults
//
//  Created by Ian Bridge on 28/05/2021.
//

import Foundation
import CouchbaseLiteSwift
import MultipeerConnectivity
//import CoreML


class QueryResultSets {

    static var thisHotel = Hotel()

    let dbName = "hotel"
    //    let dbName = "hotel"
    var db = try! Database(name: "hotel")
    var hotels = [String:Any]()
    var thisDocsProperties = [String:Any]()
    var jsonbit = [String:Any]()

    func dontTestQueryAll() throws {

//        seedHotel()

// QUERY RESULT SET HANDLING EXAMPLES
// tag::query-syntax-all[]
        let db = try! Database(name: "hotel")
        var hotels = [String:Any]()
        var hotel:Hotel = Hotel.init()

        let listQuery = QueryBuilder.select(SelectResult.all())
            .from(DataSource.database( db))

// end::query-syntax-all[]

// tag::query-access-all[]

        do {

            for row in try! listQuery.execute() {

                let thisDocsProps =
                    row.dictionary(at: 0)?.toDictionary() // <.>

                let docid = thisDocsProps!["id"] as! String

                let name = thisDocsProps!["name"] as! String

                let type = thisDocsProps!["type"] as! String

                let city = thisDocsProps!["city"] as! String

                let hotel = row.dictionary(at: 0)?.toDictionary()  //<.>

                let hotelId = hotel!["id"] as! String

                hotels[hotelId] = hotel

            } // end for

        } //end do-block

    // end::query-access-all[]

    // tag::query-access-json[]

        do {

            for (_, row) in
                try! listQuery.execute().allResults().enumerated() {

                let jsonString = row.dictionary(forKey: "_doc")!.toJSON()

                let thisJsonObj =
                        try! JSONSerialization.jsonObject(
                                with: jsonString.data(using: .utf8)! , options:[])
                                    as? [String: Any]

                let docid = thisJsonObj!["id"] as! String

                let name = thisJsonObj!["name"] as! String

                let type = thisJsonObj!["type"] as! String

                let city = thisJsonObj!["city"] as! String

                print("the JSON Object's propertiess are: ", docid,name,type,city)

            } // end for

    // end::query-access-json[]
        } catch let err {
            print(err.localizedDescription)

        } // end do


    } // end func dontTestQueryAll


//
    func dontTestQueryProps () throws {
        // tag::query-syntax-props[]
        let db = try! Database(name: "hotel")
        var hotels = [String:Any]()
        var hotel:Hotel = Hotel.init()

        let listQuery = QueryBuilder
            .select(SelectResult.expression(Meta.id).as("metaId"),
                    SelectResult.expression(Expression.property("id")),
                    SelectResult.expression(Expression.property("name")),
                    SelectResult.expression(Expression.property("city")),
                    SelectResult.expression(Expression.property("type")))
                    .from(DataSource.database(db))

        // end::query-syntax-props[]

        // tag::query-access-props[]
        for (_, result) in try! listQuery.execute().enumerated() {


            let thisDoc = result.toDictionary() as? [String:Any]  // <.>
                // Store dictionary data in hotel object and save in array
            hotel.id = thisDoc!["id"] as! String
            hotel.name = thisDoc!["name"] as! String
            hotel.city = thisDoc!["city"] as! String
            hotel.type = thisDoc!["type"] as! String
            hotels[hotel.id] = hotel

            // Use result content directly
            let docid = result.string(forKey: "metaId")
            let hotelId = result.string(forKey: "id")
            let name = result.string(forKey: "name")
            let city = result.string(forKey: "city")
            let type = result.string(forKey: "type")

            // ... process document properties as required
            print("Result properties are: ", docid, hotelId,name, city, type)
          } // end for
// end::query-access-props[]
    }

//
    func dontTestQueryCount () throws {

    // tag::query-syntax-count-only[]
        let db = try! Database(name: "hotel")
        do {
            let listQuery = QueryBuilder
                .select(SelectResult.expression(Function.count(Expression.all())).as("mycount"))
                .from (DataSource.database(db)).groupBy(Expression.property("type"))

                // end::query-syntax-count-only[]


            // tag::query-access-count-only[]

            for result in try! listQuery.execute() {
                let dict = result.toDictionary() as? [String: Int]
                let thiscount = dict!["mycount"]! // <.>
                print("There are ", thiscount, " rows")
            } // end for

        } // end do

    } // end function

// end::query-access-count-only[]

//
    func dontTestQueryId () throws {

        // tag::query-syntax-id[]
        let db = try! Database(name: "hotel")
        let listQuery = QueryBuilder.select(SelectResult.expression(Meta.id).as("metaId"))
                    .from(DataSource.database(db))

        // end::query-syntax-id[]


        // tag::query-access-id[]
        for (_, result) in try! listQuery.execute().enumerated() {

            print(result.toDictionary())
            print("Document Id is -- ", result["metaId"].string!)

            let thisDocsId = result["metaId"].string! // <.>

            // Now you can get the document using the ID
            var thisDoc = db.document(withID: thisDocsId)!.toDictionary()

            let hotelId = thisDoc["id"] as! String

            let name = thisDoc["name"] as! String

            let city = thisDoc["city"] as! String

            let type = thisDoc["type"] as! String

            // ... process document properties as required
            print("Result properties are: ", hotelId,name, city, type)


        } // end for

// end::query-access-id[]
    } // end function dontTestQueryId

//
    func query_pagination () throws {

        //tag::query-syntax-pagination[]
        let thisOffset = 0;
        let thisLimit = 20;
        //
        let listQuery = QueryBuilder
                .select(SelectResult.all())
                .from(DataSource.database(db))
                .limit(Expression.int(thisLimit),
                  offset: Expression.int(thisOffset))

        // end::query-syntax-pagination[]

    } // end function
//
//


    func seedHotel () {

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

            let hotel:MutableDocument = MutableDocument()

            for x in 0 ... key.count-1 {
                hotel.setString(val[i][x], forKey: key[x])
            }

            try! db.saveDocument(hotel)


        }

    }
//
//

} // end class
