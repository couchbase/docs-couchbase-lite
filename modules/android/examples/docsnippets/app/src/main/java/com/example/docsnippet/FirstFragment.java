package com.example.docsnippet;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.View.OnClickListener;
import android.widget.Button;
import androidx.fragment.app.Fragment;
import androidx.navigation.fragment.FragmentKt;

import java.util.ArrayList;
import java.util.HashMap;

import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import java.util.List;
import com.couchbase.lite.*;

//@Metadata(
//        mv = {1, 1, 16},
//        bv = {1, 0, 3},
//        k = 1,
//        d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0005¢\u0006\u0002\u0010\u0002J&\u0010\u0003\u001a\u0004\u0018\u00010\u00042\u0006\u0010\u0005\u001a\u00020\u00062\b\u0010\u0007\u001a\u0004\u0018\u00010\b2\b\u0010\t\u001a\u0004\u0018\u00010\nH\u0016J\u001a\u0010\u000b\u001a\u00020\f2\u0006\u0010\r\u001a\u00020\u00042\b\u0010\t\u001a\u0004\u0018\u00010\nH\u0016¨\u0006\u000e"},
//        d2 = {"Lcom/example/docsnippet/FirstFragment;", "Landroidx/fragment/app/Fragment;", "()V", "onCreateView", "Landroid/view/View;", "inflater", "Landroid/view/LayoutInflater;", "container", "Landroid/view/ViewGroup;", "savedInstanceState", "Landroid/os/Bundle;", "onViewCreated", "", "view", "app_debug"}
//)
public final class FirstFragment extends Fragment {
        private HashMap _$_findViewCache;

        public List<Item> ItemList = new ArrayList<Item>();

        @Nullable
        public View onCreateView(@NotNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
                Intrinsics.checkParameterIsNotNull(inflater, "inflater");

                Datastore ds = new Datastore();
//                try {
//                        ds.forceSeedDB();
//                } catch (CouchbaseLiteException e) {
//                        e.printStackTrace();
//                }
                TestQueries tq = new TestQueries();

                ItemList = ds.getItems();

                System.out.println(ItemList.toString());

                try {
//                        tq.testQuerySyntaxAll();
//                        tq.testQuerySyntaxProps();
//                        tq.testQuerySyntaxCount();
                        tq.testQuerySyntaxProps();
                        tq.testQueryPagination();

                } catch (CouchbaseLiteException e) {
                        e.printStackTrace();
                }

                return inflater.inflate(1300034, container, false);
        }

        public void onViewCreated(@NotNull View view, @Nullable Bundle savedInstanceState) {
                Intrinsics.checkParameterIsNotNull(view, "view");
                super.onViewCreated(view, savedInstanceState);
                ((Button)view.findViewById(1000220)).setOnClickListener((OnClickListener)(new OnClickListener() {
                        public final void onClick(View it) {
                                FragmentKt.findNavController(FirstFragment.this).navigate(1000292);
                        }
                }));
        }

        public View _$_findCachedViewById(int var1) {
                if (this._$_findViewCache == null) {
                        this._$_findViewCache = new HashMap();
                }

                View var2 = (View)this._$_findViewCache.get(var1);
                if (var2 == null) {
                        View var10000 = this.getView();
                        if (var10000 == null) {
                                return null;
                        }

                        var2 = var10000.findViewById(var1);
                        this._$_findViewCache.put(var1, var2);
                }

                return var2;
        }

        public void _$_clearFindViewByIdCache() {
                if (this._$_findViewCache != null) {
                        this._$_findViewCache.clear();
                }

        }

        // $FF: synthetic method
        public void onDestroyView() {
                super.onDestroyView();
                this._$_clearFindViewByIdCache();
        }
}
