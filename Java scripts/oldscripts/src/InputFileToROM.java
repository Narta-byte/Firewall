import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.math.BigInteger;
import java.util.Scanner;

public class InputFileToROM {
    public static void main(String[] args) {

        try {
            Scanner reader = new Scanner(new File(
                    "C:/Users/Mig/Desktop/Hardware projekt/Firewall/Java scripts/oldscripts/input_file.txt"));
            FileWriter writer = new FileWriter(new File("output_file.txt"));
            String str = "";
            boolean first = true;
            int i = 1;
            int nmbOfLines = 0;
            Scanner reader2 = new Scanner(new File(
                    "C:/Users/Mig/Desktop/Hardware projekt/Firewall/Java scripts/oldscripts/output_file.txt"));
            while (reader2.hasNext()) {
                reader2.next();
                reader2.next();
                reader2.next();
                nmbOfLines++;
            }
            while (reader.hasNext()) {
                // String data = reader.next();

                str = new BigInteger(reader.next(), 16).toString(2);
                System.out.println(str);

                while (8 != str.length()) {
                    str = "0" + str;
                }
                // System.out.println(str+reader.next()); //byte then bit
                if (first) {
                    writer.write("type ROM_type is array (0 to " + (nmbOfLines - 1)
                            + ") of std_logic_vector(8 downto 0);" + "\n\n");
                    writer.write(
                            "constant ROM : ROM_type := (" + 0 + " => \"" + str + "" + reader.next() + "\"," + "\n");
                    first = false;
                } else if (i == (nmbOfLines - 1)) {
                    writer.write("                            " + i + " => \"" + str + reader.next() + "\");\n");
                } else {
                    writer.write("                            " + i + " => \"" + str + reader.next() + "\",\n");
                    i++;
                }

                // System.out.println(data);
            }

            writer.close();
            reader.close();

        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException f) {
            f.printStackTrace();
        }
    }

}