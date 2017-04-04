package org.acme.database;

import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;


public class Database {

    private Cursor cursor;

    // Based on "Classic Books" list from
    // https://www.abebooks.com/books/features/50-classic-books.shtml
    // All page numbers are estimates.
    private Object[][] rows = new Object[3][4];

    public Database(String url) {
        rows[0][0] = 0;
        rows[0][1] = "Lord of the Flies";
        rows[0][2] = 1954;
        rows[0][3] = 250;
        rows[1][0] = 1;
        rows[1][1] = "Lorna Doone";
        rows[1][2] = 1869;
        rows[1][3] = 200;
        rows[2][0] = 2;
        rows[2][1] = "Daphne de Maurier";
        rows[2][2] = 1936;
        rows[2][3] = 330;
        cursor = new Cursor();
        cursor.addRows(Arrays.asList(rows));
    }

    public Cursor cursor() {
        return this.cursor;
    }

}
