public class InsertBetterNameHere {
    public static void main (String[] args) {
        String[] xs1 = {"4500","0073","0000","4000","4011","c0a8","0001","c0a8","00c7"};
        //correct checksum : 4db4
        String[] xs2 = {"4500","0028","45bc","4000","8006","0ad1","f56b","1f0d","4816"};
        String[] xs3 = {"4512","0028","45bc","4000","8006","0ad1","f56b","1f0d","4816"};
        System.out.println("Testcase 1 :"+ip_checksum(xs1));
        System.out.println("Testcase 2 :"+ip_checksum(xs2));
        System.out.println("Testcase 3 :"+ip_checksum(xs3));

        String[] xs4 = {"4500","0073","0000","4000","4011","b861","c0a8","0001","c0a8","00c7"};
        String[] xs5 = {"4500","0028","45bc","4000","8006","4db4","0ad1","f56b","1f0d","4816"};
        String[] xs6 = {"4512","0028","45bc","4000","8006","4db4","0ad1","f56b","1f0d","4816"};

        System.out.println("Testcase 4 :"+ipVerify(xs4));
        System.out.println("Testcase 5 :"+ipVerify(xs5));
        System.out.println("Testcase 6 this should be false :"+ipVerify(xs6));
    }

    public static String ip_checksum(String[] hex_list) {
        // convert hexadecimal numbers to decimal numbers
        int[] dec_list = new int[hex_list.length];
        for (int i = 0; i < hex_list.length; i++) {
            dec_list[i] = Integer.parseInt(hex_list[i], 16);
        }
        // sum all numbers
        int sum_dec = 0;
        for (int i = 0; i < dec_list.length; i++) {
            sum_dec += dec_list[i];
        }
        System.out.println("sum of xs :"+Integer.toHexString(sum_dec));
        int carry = Integer.parseInt(Integer.toHexString(sum_dec).charAt(0)+"",16);
        // take the last 16 bits
        int last_16 = (sum_dec+carry) & 0xffff;
        // complement the number
        int complement = last_16 ^ 0xffff;
        // convert the number to hexadecimal
        String hex_complement = Integer.toHexString(complement);
        // return the last 16 bits
        return hex_complement.substring(hex_complement.length() -4);
    }
    public static boolean ipVerify(String[] hexList) {
        int sum = 0;
        for (int i = 0; i < hexList.length; i++) {
            sum = sum + Integer.parseInt(hexList[i], 16);
            System.out.println(Integer.toHexString(sum));
        }
        System.out.println(sum);
        int carry = Integer.parseInt(Integer.toHexString(sum).charAt(0)+"",16);
        int last_16 = (sum+carry) & 0xffff;
        //System.out.println("sum of something : "+Integer.toHexString(last_16));
        return 0xffff == last_16;
    }
}
