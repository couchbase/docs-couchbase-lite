package com.example.docsnippet;
import com.couchbase.lite.*;

public class Item {

        public String Id;
        public String Type;
        public String Name;
        public String City;
        public String Country;
        public String Description;
        public String Text;


        public MutableDocument ToMutableDocument()
        {
                MutableDocument thisMutDoc = new MutableDocument();
                Item thisItem = this;
                thisMutDoc.setString("id",this.Id);
                thisMutDoc.setString("Type", this.Type);
                thisMutDoc.setString("Name", this.Name);
                thisMutDoc.setString("City", this.City);
                thisMutDoc.setString("Country", this.Country);
                thisMutDoc.setString("Description", this.Description);
                thisMutDoc.setString("Text", this.Text);

                return thisMutDoc;
        }

        public Item FromMutableDocument(MutableDocument argDoc)
        {
                Item thisItem = new Item();
                thisItem.Id = argDoc.getString("id");
                thisItem.Type = argDoc.getString("Type");
                thisItem.Name = argDoc.getString("Name");
                thisItem.City = argDoc.getString("City");
                thisItem.Country = argDoc.getString("Country");
                thisItem.Description = argDoc.getString("Description");
                thisItem.Text = argDoc.getString("Text");

                return thisItem;

        }

    }
