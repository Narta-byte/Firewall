import java.util.*;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;

public class generatekeys {
    public static void main(String[] args) {

        try {
            FileWriter writer = new FileWriter(new File("C:/Users/Asger/3-ugers/Firewall/data_keys.txt"));
        
            String str = "0";
            String fil = "";
            for (int i=1; i <= 96; i++) // Length of header is 96
                str = str + 0;
    
            //Random rand = new Random(); //instance of random class
            String tal = "";
            String cutoff = "";
            for (int k = 0; k <= 513; k++) { // How many keys u want?
                //int int_random = rand.nextInt(k);
                tal = Integer.toBinaryString(k+k);
                cutoff = str.substring(tal.length());
                System.out.println(cutoff + tal);
                //fil = cutoff + tal;
                //writer.write(fil);
    
            }
            writer.close();
        } catch (Exception e) {
            //TODO: handle exception
        }
        
    }

}