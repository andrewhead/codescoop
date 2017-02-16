public class Example {

  public static void main(String[] args) {

    int i = 1;          // Def: i
    int j = i + 1;      // Def: j, Use: i

    i =  j + 1;          // Def: i, Use: j

    System.out.println(j + i);  // Use: i, j

  }

}
