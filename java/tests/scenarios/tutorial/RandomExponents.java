import java.util.Random;


public class RandomExponents {

    public static void main(String[] args) {

        double result;
        int NUM_EXPONENTS = 10;
        int MAX_BASE = 5;
        int MAX_POW = 2;
        Random randomGenerator = new Random();

        for (int i = 0; i < NUM_EXPONENTS; i++) {
            int base = randomGenerator.nextInt(MAX_BASE + 1);
            int pow = randomGenerator.nextInt(MAX_POW + 1);
            result = Math.pow(base, pow);
            System.out.println(result);
        }

    }

}
