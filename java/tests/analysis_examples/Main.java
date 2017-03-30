import java.util.ArrayList;
import java.util.List;
import java.lang.Math;


public class Main {

    private Database database;
    private static final boolean DEBUG = true;

    public Main() {
    }

    private class Database {

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

    private class QueryResult {

        private final int BATCH_SIZE = 2;
        private int mBatchPointer = 0;
        private List mRows;
        private boolean mIsDone;

        public QueryResult(List rows, boolean pIsDone) {
            this.mRows = rows;
            this.mIsDone = pIsDone;
        }

        public int getSize() {
            return this.mRows.size();
        }

        public Row[] getRecords() {
            return (Row[]) this.mRows.toArray(new Row[this.mRows.size()]);
        }

        public boolean isDone() {
            return this.mIsDone;
        }

        public int getQueryLocator() {
            return this.mBatchPointer;
        }

    }

    private class ConnectionException extends Exception {
        public static final long serialVersionUID = -1;
    }

    private class Row {}

    private class Book extends Row {

        private int id;
        private String title;
        private int year;
        private int numPages;

        public Book (int pId, String pTitle, int pYear, int pNumPages) {
            this.id = pId;
            this.title = pTitle;
            this.year = pYear;
            this.numPages = pNumPages;
        }

        public int getId() { return id; }
        public String getTitle() { return title; }
        public int getYear() { return year; }
        public int getNumPages() { return numPages; }

    }

    private class Booklist extends ArrayList {

        public boolean hasBestseller;
        public static final long serialVersionUID = -1;
        public List titles = new ArrayList();

    }

    public boolean isBestseller(int id) {
        return id == 2;
    }

    public Booklist getBooklist(String genre, int max_books) {

        Database database = new Database();
        Booklist booklist = new Booklist();
        List titles = new ArrayList();

        try {

            String query = "SELECT id, title, year, num_pages FROM table WHERE title LIKE '%" + genre + "%'";
            QueryResult queryResult = database.query(query);
            boolean finished = false;

            if (queryResult.getSize() > 0) {

                int rowNumber = 0;
                while (!finished) {

                    Row[] records = queryResult.getRecords();

                    for (int i = 0; i < Math.min(records.length, max_books); ++i) {

                        Book book = (Book)records[i];
                        int id = book.getId();
                        String title = book.getTitle();
                        int year = book.getYear();
                        int num_pages = book.getNumPages();

                        if (title != null) {
                            titles.add(title);
                        }
                        if (id != -1) {
                            boolean bestseller = isBestseller(id);
                            if (bestseller) {
                                booklist.hasBestseller = bestseller;
                            }
                        }

                        if (DEBUG) {
                            System.out.println("Fetched book: " + title +
                                " (" + genre + ")");
                        }

                        rowNumber++;

                        if (queryResult.isDone() || rowNumber >= max_books) {
                            finished = true;
                        } else {
                            queryResult = database.queryMore(queryResult.getQueryLocator());
                        }

                    }
                 }
            } else {
                System.out.println("Hello world!");
            }

        } catch (ConnectionException exception) {
            exception.printStackTrace();
        }

        booklist.titles = titles;
        return booklist;

    }

    public static void main(String[] args) {
        new Main().getBooklist("romance", 3);
    }

}
