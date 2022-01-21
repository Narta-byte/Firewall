import java.io.*;
import java.util.*;

public class keysToROM {

    public static void main(String[] args) {

        try {

            Scanner reader = new Scanner(new File("keys_to_be_programmed_2.txt"));
            FileWriter writer = new FileWriter(new File("output_keys.txt"));
            String str = "";
            boolean first = true;
            int i = 1;

            int nmbOfLines = 0;
            Scanner reader2 = new Scanner(new File("keys_to_be_programmed_2.txt"));

            while (reader2.hasNext()) {
                reader2.next();
                nmbOfLines++;
            }
            System.out.println(nmbOfLines);

            while (reader.hasNext()) {
                str = reader.next();
                // System.out.println(str);

                while (96 != str.length()) {
                    str = "0" + str;
                }

                if (first) {
                    writer.write("type ROM_type is array (0 to " + (nmbOfLines - 1)
                            + ") of std_logic_vector(95 downto 0);" + "\n\n");

                    writer.write(
                            "constant ROM : ROM_type := (\n   " + 0 + " => \"" + str + "\"," + "\n");

                    // System.out.print(i);
                    first = false;
                } else if (i == (nmbOfLines - 1)) {

                    writer.write("   " + i + " => \"" + str + "\");\n");

                } else {

                    writer.write("   " + i + " => \"" + str + "\",\n");
                    i++;
                }

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
