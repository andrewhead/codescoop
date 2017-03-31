package org.acme.database;

import java.util.ArrayList;
import java.util.List;


public class Database {

    private boolean mQueryDone = false;
    private int QUERY_RESULT_SIZE = 2;

    // Based on "Classic Books" list from
    // https://www.abebooks.com/books/features/50-classic-books.shtml
    // All page numbers are estimates.
    private Row[] records = {
        new Book(1, "Lord of the Flies", 1954, 250),
        new Book(2, "Lorna Doone", 1869, 200),
        new Book(3, "Daphne de Maurier", 1936, 330)
    };

    private List getRowList(int start, int length) {
        if (start + length > records.length) {
            length = 1;
        }
        ArrayList rowList = new ArrayList();
        for (int i = 0; i < length; i++) {
            rowList.add(records[start + i]);
        }
        return rowList;
    }

    private boolean hasMore(int start, int length) {
        return (start + length) < records.length;
    }

    public QueryResult query(String query) throws ConnectionException {
        return new QueryResult(
            getRowList(0, QUERY_RESULT_SIZE),
            hasMore(0, QUERY_RESULT_SIZE)
        );
    }

    public QueryResult queryMore(int queryLocator) {
        return new QueryResult(
            getRowList(queryLocator, QUERY_RESULT_SIZE),
            hasMore(queryLocator, QUERY_RESULT_SIZE)
        );
    }

}
