package com.example.docsnippet;
import android.app.Application.*;
import android.content.Context;
import android.content.Context.*;
import java.lang.Object;
import java.util.*;
import com.couchbase.lite.*;

public class Datastore {


//{
//  return = initialize_DB(dbName);
//}
//
private static boolean is_Connected;
private static boolean is_Initialized;
private static String dbName;
private static Database db;

static {
    init();
}



    public Database getDB() {

        return db;

    }

    public boolean addItem(Item arg_item) throws CouchbaseLiteException {
        boolean thisResult = false;

        if (is_Connected)
        {
            try {
                db.save(arg_item.ToMutableDocument());
                } catch (CouchbaseLiteException egg) {
                    System.out.println("Exception saving item " + arg_item.toString());
                    egg.printStackTrace();
                }
            thisResult = true;
        }
        else
        {
            System.out.println("DB NOT CONNECTED");
        }

        return thisResult;
    }


    public Item getItem(String arg_id) {

        if (is_Connected) {
            return new Item().FromMutableDocument(db.getDocument(arg_id).toMutable());
        } else {
            return null;
        }
    }


    public List<Item> getItems() {

        if (is_Connected) {

            List<Item> thisItemList = new ArrayList<Item>();

            MutableDocument thisDoc = new MutableDocument();

            Query query = QueryBuilder
                    .select(SelectResult.expression(Meta.id).as("this_id"))
                    .from(DataSource.database(db));

            try {
                List<Result> results = query.execute().allResults();

                if (results.size() > 0) {
                    for (Result result : results) {

                        String thisId = result.getString("this_id");

                        MutableDocument thisDocX = new MutableDocument();
                        thisDocX = db.getDocument(thisId).toMutable();
                        Item thisItem = new Item().FromMutableDocument(thisDocX);
                        thisItemList.add(thisItem);

//                        thisItemList.add(new Item().FromMutableDocument(db.getDocument(result.getString("this_id")).toMutable()));

                        }
                    } else {seedDB();}

                } catch(CouchbaseLiteException egg){
                    egg.printStackTrace();
                }

                return thisItemList;

            } else{
                return null;
            }
        }




    private static Database initialize_DB( String dbName) {
        boolean thisResult = false;
//        Context context = null;

//        if (is_Initialized == false) {
//            CouchbaseLite.init();
//            is_Initialized = true;
//
//        }

        db = null;
        try {
            db = new Database(dbName);
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

        return db;
    }

    public void forceSeedDB() throws CouchbaseLiteException {

        db.delete();
        initialize_DB(dbName);
        try {
            seedDB();
        } catch (CouchbaseLiteException e) {
            e.printStackTrace();
        }

    }

    public static void init() {
        is_Connected=false;
        is_Initialized=false;
        dbName="hotels";
        db = initialize_DB(dbName);
        is_Connected = (db != null);
    }

    private void seedDB() throws CouchbaseLiteException {

        MutableDocument thisMutDoc = new MutableDocument();
        thisMutDoc.setString("id", "1001");
        thisMutDoc.setString("Type", "hotel");
        thisMutDoc.setString("Name", "Hotel Fred");
        thisMutDoc.setString("City", "London");
        thisMutDoc.setString("Country", "England");
        thisMutDoc.setString("Description", "Seed hotel document description");
        thisMutDoc.setString("Text", "Seed hotel document text");

        addItem(new Item().FromMutableDocument(thisMutDoc));

        Item thisItem = new Item();

    }

}
