import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Scanner;

public class WiresharkToInput {
    public static void main(String[] args){
        try {
            Scanner reader = new Scanner(new File("Data.txt"));
            FileWriter writer = new FileWriter(new File("new_input_file.txt"));
            String str = "";
            while (reader.hasNextLine()) {
                str = "";
                if (reader.next().equals("0000")) {


                    for (int i = 0; i < 14; i++) {
                        str = str + reader.next() + " 0\n";
                    }
                    str = str + reader.next() +" 1\n";
                    str = str + reader.next() +" 0\n";
                    // remove junk
                    for (int i = 0; i < 15; i++) {
                        reader.next();
                    }
                    writer.write(str);
                    System.out.println(str);
                } else {

                    for (int i = 0; i < 16; i++) {
                        str = str + reader.next() + " 0\n";
                    }
                    // remove junk
                    for (int i = 0; i < 16; i++) {
                        reader.next();
                    }
                    writer.write(str);
                    System.out.println(str);
                }




                //remove first four numbers
                //System.out.println(reader.next());

                //read the next 15 bytes to get to the ip header
                //for (int i = 1; i <= 15 ; i++) {
                  //  str = str + reader.next() + " 0\n";
                    //System.out.println(str);
                //}


            }

            writer.close();
            reader.close();

        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch ( IOException f) {
            f.printStackTrace();
        }
    }


}
