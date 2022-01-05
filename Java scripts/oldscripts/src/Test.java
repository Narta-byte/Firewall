public class Test {
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
        // take the last 16 bits
        int last_16 = sum_dec & 0xffff;
        // complement the number
        int complement = last_16 ^ 0xffff;
        // convert the number to hexadecimal
        String hex_complement = Integer.toHexString(complement);
        // return the last 16 bits
        return hex_complement.substring(hex_complement.length() - 4);
    }
}
