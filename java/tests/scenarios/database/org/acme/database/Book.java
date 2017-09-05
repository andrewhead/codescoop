package org.acme.database;

  
public class Book {
    
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
