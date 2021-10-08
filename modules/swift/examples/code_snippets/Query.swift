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


class Query {

    var this_hotel:Hotel = Hotel()

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
            var results = try! listQuery.execute()
            for row in  results {

//                let jsonString = row.toJSON() // <.>
//                print( "SELECT props = {0}", jsonString)
                let jsonString = row.dictionary(at: 0)!.toJSON() // <.>
                print( "SELECT ALL = {0}", jsonString)
//                this_hotel.id = "fred"
                
//                let payload: Data = try JSONEncoder().encode(this_hotel)
                
               
                let thisJsonObj:Dictionary =
                    try! (JSONSerialization.jsonObject(
                            with: jsonString.data(using: .utf8)! , options: .allowFragments)
                            as? [String: Any])! // <.>
                
                // Use Json Object to populate Native object <.>
                
//                let that_hotel = try! JSONSerialization. .jsonObject(thisJsonObj)
                   
                
                let this_hotel:Hotel = (try JSONDecoder().decode(Hotel.self, from: jsonString.data(using: .utf8)!))

                
                this_hotel.id = thisJsonObj["id"] as! String

                this_hotel.name = thisJsonObj["name"] as! String

                this_hotel.type = thisJsonObj["type"] as! String

                this_hotel.city = thisJsonObj["city"] as! String

                hotels[this_hotel.id] = this_hotel
    
                
            } // end for

        } catch let err {
            print(err.localizedDescription)

        } // end do


    } // end func dontTestQueryAll

    // end::query-access-json[]


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
                // Store dictionary data in hotel object and save in arry
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
    }// end func

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
                
                // Alternatively
                print ( result["mycount"] )
            
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

            let hotel:MutableDocument = MutableDocument(id: val[0][i])

            for x in 0 ... key.count-1 {
                hotel.setString(val[i][x], forKey: key[x])
            }

            try! db.saveDocument(hotel)


        }

    }

//
// N1QL QUERY EXAMPLES
//

    func dontTestQueryN1QL() throws {


    // tag::query-syntax-n1ql[]
        let db = try! Database(name: "hotel")
        
        let listQuery =  db.createQuery("SELECT META().id AS thisId FROM \(db.name) WHERE type = 'hotel'") // <.>
        
        let results: ResultSet = try listQuery.execute()

    // end::query-syntax-n1ql[]
        
        if (results.allResults().count>0) {
            try! dontTestProcessResults(results: results)
        }
        
    } // dontTestQueryN1QL
  
    
    func dontTestQueryN1QLparams() throws {
        
    // tag::query-syntax-n1ql-params[]
        let db = try! Database(name: "hotel")
                
        let listQuery =
            db.createQuery("SELECT META().id AS thisId FROM _ WHERE type = $type") // <.>
        
        listQuery.parameters =
            Parameters().setString("hotel", forName: "type") // <.>
        
        let results: ResultSet = try listQuery.execute()
        
    // end::query-syntax-n1ql-params[]

        if (results.allResults().count>0) {
            try! dontTestProcessResults(results: results)
        }
                
    } // dontTestQueryN1QLparams()


    func dontTestProcessResults(results: ResultSet) throws {
        // tag::query-access-n1ql[]
        // tag::query-process-results[]
       
        do {

            for row in results {

                print(row["thisId"].string!)
               
                let thisDocsId = row["thisId"].string!
                
                // Now you can get the document using the ID
                var thisDoc = db.document(withID: thisDocsId)!.toDictionary()

                let hotelId = thisDoc["id"] as! String

                let name = thisDoc["name"] as! String

                let city = thisDoc["city"] as! String

                let type = thisDoc["type"] as! String

                // ... process document properties as required
                print("Result properties are: ", hotelId,name, city, type)

            } // end for
            // end::query-access-n1ql[]
            // end::query-process-results[]

        } //end do-block
    
    } // end dontTestProcessResults
    
} // end class


