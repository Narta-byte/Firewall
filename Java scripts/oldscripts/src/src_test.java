public class src_test {
    public static void main(String[] args)  {
        System.out.println("hello bitch");

        int[] data = {1,1};
        int[] generator = {1,1,1,1,0,1,0,0,1};
        
        System.out.println(crc(data,generator));
    }

    public static int crc(int[] data, int[] generator) {
        int crc = 0;
        for (int i = 0; i < data.length; i++) {
            crc = crc ^ data[i];
            for (int j = 1; j < generator.length; j++) {
                if (crc == 1) {
                    crc = crc ^ generator[j];
                }
                crc = crc >>> 1;
            }
        }
        return crc;
    }

}