import org.acme.database.QueryResult;
import org.acme.database.Book;
import org.acme.database.Booklist;
import org.acme.database.Database;
import org.acme.database.ConnectionException;

import java.util.ArrayList;
import java.util.List;


public class BookListing {

    private boolean DEBUG = true;

    public Booklist getBookListing(String genre, int maxBooks) {

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

                    List records = queryResult.getRecords();

                    for (int i = 0; i < Math.min(records.size(), maxBooks); ++i) {

                        Book book = (Book)records.get(i);
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
                            System.out.println("Fetched book: " + title + " (" + genre + ")");
                        }

                        rowNumber++;

                        if (queryResult.isDone() || rowNumber >= maxBooks) {
                            finished = true;
                        } else {
                            queryResult = database.queryMore(queryResult.getQueryLocator());
                        }

                    }
                 }
            } else {
                System.out.println("No results found in the database");
            }

        } catch (ConnectionException exception) {
            exception.printStackTrace();
        }

        booklist.titles = titles;
        return booklist;

    }

    public boolean isBestseller(int id) {
        return id == 2;
    }

    public static void main(String[] args) {
        new BookListing().getBookListing("romance", 3);
    }

}
