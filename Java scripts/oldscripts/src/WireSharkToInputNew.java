import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Scanner;
// C:/Users/Asger/3-ugers/Firewall/Java scripts/oldscripts/Data.txt
public class WireSharkToInputNew {
    public static void main(String[] args) {
        try {
//            Scanner reader = new Scanner(new File("Data.txt"));
            //Scanner reader = new Scanner(new File("C:/Users/Asger/3-ugers/Firewall/Java scripts/oldscripts/Data.txt"));
            
            Scanner reader = new Scanner(new File("C:/Users/Mig/Desktop/Hardware projekt/Firewall/Java scripts/oldscripts/Data.txt"));
//            FileWriter writer = new FileWriter(new File("new_input_file.txt"));
            //FileWriter writer = new FileWriter(new File("C:/Users/Asger/3-ugers/Firewall/Java scripts/oldscripts/src/new_input_file.txt"));
            FileWriter writer = new FileWriter(new File("C:/Users/Mig/Desktop/Hardware projekt/Firewall/Java scripts/oldscripts/input_file.txt"));
            String str = "";
            String line = "";
            while (reader.hasNextLine()) {
                str = "";
                if (reader.next().equals("0000")) {
                    line = reader.nextLine();
                    //System.out.println(line);
                    line = line.substring(2,line.length()-19);
                    System.out.println(line);

                    for (int i = 0; i < 14; i++) {
                        str = str + line.substring(0,3)+"0 0\n";
                        line = line.substring(3,line.length());
                    }

                    str = str + line.substring(0,3)+"0 1\n";
                    //line = line.substring(3,line.length());

                    System.out.println(line);
                    System.out.println(str);
                    str = str + line.substring(0,3)+"1 0\n";
                    line = line.substring(3,line.length());
                    str = str + line+" 0 0\n";
                    
                    writer.write(str);
                    System.out.println(str);
                } else {
                    line = reader.nextLine();
                    line = line.substring(2,line.length()-19);
                    //ystem.out.println(line);
                   // System.out.println(line.length());
                    if (line.length() == 47) {
                        for (int i = 0; i < 15; i++) {
                            str = str + line.substring(0,3)+"0 0\n";
                            line = line.substring(3,line.length());
                        }
                        str = str + line+" 0 0\n";
                        writer.write(str);
                        System.out.println(str);

                    } else {


                        while (line.length() !=4) {

                            if (!(line.substring(0,3).equals("   "))) {
                                str = str + line.substring(0,3)+"0 0\n";
                                //System.out.println(str);
                                line = line.substring(3,line.length());
                            } else {
                                break;
                            }
                        }
                        writer.write(str);
                        System.out.println(str);
                    }
                }
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
