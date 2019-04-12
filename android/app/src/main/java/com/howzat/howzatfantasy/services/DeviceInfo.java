package com.howzat.howzatfantasy.services;
        import java.io.BufferedInputStream;
        import java.io.ByteArrayOutputStream;
        import java.io.FileInputStream;
        import java.net.InetAddress;
        import java.net.NetworkInterface;
        import java.util.ArrayList;
        import java.util.Collections;
        import java.util.HashMap;
        import java.util.List;
        import java.util.Map;
        import java.util.regex.Pattern;
        import android.accounts.Account;
        import android.accounts.AccountManager;
        import android.annotation.SuppressLint;
        import android.app.Activity;
        import android.content.Context;
        import android.content.pm.PackageInfo;
        import android.net.ConnectivityManager;
        import android.net.NetworkInfo;
        import android.net.wifi.WifiManager;
        import android.os.Build;
        import android.provider.Settings.Secure;
        import android.telephony.TelephonyManager;
        import android.util.Patterns;
        import android.content.pm.PackageManager;
        import java.math.BigInteger;
public class DeviceInfo {
    private static final String cipherString = "00000000000000000000";
    private static int			present_deviceType		= 0;
    public static Map<String, String> getDeviceInfoMap(Activity current_activity) {
        PackageManager packageManager = current_activity.getPackageManager();
        Map<String, String> deviceInfoMap = new HashMap<String, String>();
        TelephonyManager telManager = (TelephonyManager) current_activity.getSystemService(Context.TELEPHONY_SERVICE);
        deviceInfoMap.put("device_IPv4", getIPAddress(true));
        deviceInfoMap.put("android_version", Build.VERSION.RELEASE);
        deviceInfoMap.put("network_Operator", telManager.getNetworkOperatorName());
        deviceInfoMap.put("manufacturer", Build.MANUFACTURER);
        deviceInfoMap.put("android_Id", Secure.getString(current_activity.getContentResolver(), Secure.ANDROID_ID));
        deviceInfoMap.put("device_ID", getAndroidDeviceId(current_activity));
        deviceInfoMap.put("model", Build.MODEL);
        try{
            PackageInfo info = packageManager.getPackageInfo(current_activity.getPackageName(), PackageManager.GET_ACTIVITIES);
            deviceInfoMap.put("packageName", info.packageName);
            deviceInfoMap.put("versionName", info.versionName);
            deviceInfoMap.put("baseRevisionCode", String.valueOf(info.baseRevisionCode));
            deviceInfoMap.put("firstInstallTime", String.valueOf(info.firstInstallTime));
            deviceInfoMap.put("lastUpdateTime", String.valueOf(info.lastUpdateTime));
        }
        catch(PackageManager.NameNotFoundException e){
            deviceInfoMap.put("packageName", "");
            deviceInfoMap.put("versionName", "");
            deviceInfoMap.put("baseRevisionCode", "");
            deviceInfoMap.put("firstInstallTime", "");
            deviceInfoMap.put("lastUpdateTime", "");
        }
        return deviceInfoMap;
    }


    @SuppressLint("MissingPermission")
    public static String getConnectionType(Activity activity) {
        String connectionType = "No_Connection";
        ConnectivityManager connManager = (ConnectivityManager) activity.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = connManager.getActiveNetworkInfo();
        if (netInfo != null && netInfo.isConnected()) {
            if (netInfo.getType() == ConnectivityManager.TYPE_WIFI)
                connectionType = "WiFi";
            else {
                switch (netInfo.getSubtype()) {
                    case TelephonyManager.NETWORK_TYPE_GPRS:
                    case TelephonyManager.NETWORK_TYPE_EDGE:
                    case TelephonyManager.NETWORK_TYPE_CDMA:
                    case TelephonyManager.NETWORK_TYPE_1xRTT:
                    case TelephonyManager.NETWORK_TYPE_IDEN:
                        connectionType = "2G";
                        break;
                    case TelephonyManager.NETWORK_TYPE_UMTS:
                    case TelephonyManager.NETWORK_TYPE_EVDO_0:
                    case TelephonyManager.NETWORK_TYPE_EVDO_A:
                    case TelephonyManager.NETWORK_TYPE_HSDPA:
                    case TelephonyManager.NETWORK_TYPE_HSUPA:
                    case TelephonyManager.NETWORK_TYPE_HSPA:
                    case TelephonyManager.NETWORK_TYPE_EVDO_B:
                    case TelephonyManager.NETWORK_TYPE_EHRPD:
                    case TelephonyManager.NETWORK_TYPE_HSPAP:
                        connectionType = "3G";
                        break;
                    case TelephonyManager.NETWORK_TYPE_LTE:
                        connectionType = "4G";
                        break;
                    default:
                        connectionType = "?";
                        break;
                }
            }
        }
        return connectionType;
    }

    @SuppressLint("MissingPermission")

    public static List<String> getGoogleEmailList(Activity activity) {
        Account[] google_accounts = AccountManager.get(activity).getAccountsByType("com.google");
        List<String> googleEmailsList = new ArrayList<>();
        Pattern emailPattern = Patterns.EMAIL_ADDRESS;
        int total_no_Accounts = google_accounts.length;
        for (int j = 0; j < total_no_Accounts; j++) {
            String emailId = google_accounts[j].name;
            if (emailPattern.matcher(emailId).matches() && !googleEmailsList.contains(emailId))
                googleEmailsList.add(emailId);
        }
        return googleEmailsList;
    }

    private static String  getAndroidDeviceId(Activity current_activity){
        String androidDeviceID = null;
        WifiManager wifiManager = (WifiManager) current_activity.getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (androidDeviceID == null || androidDeviceID == "") {
            androidDeviceID = Secure.getString(current_activity.getContentResolver(), Secure.ANDROID_ID);
            androidDeviceID = fetchPaddedAndroidID(androidDeviceID);
        }
        if (androidDeviceID == null || androidDeviceID == "") {
            androidDeviceID = wifiManager.getConnectionInfo().getMacAddress();
            androidDeviceID = fetchPaddedMAC(androidDeviceID);
        }
        return androidDeviceID;
    }


    public static String fetchPaddedMAC(String MAC) {
        if(MAC == null || MAC.isEmpty())
            return null;
        int count = 12;
        int index = 0;
        BigInteger toNumeric = BigInteger.ZERO;
        while (count > 0 && index < MAC.length()) {
            char c = MAC.charAt(index++);
            if (c >= '0' && c <= '9') {
                toNumeric = toNumeric.multiply(BigInteger.valueOf(16)).add(BigInteger.valueOf(c - '0'));
                count--;
            } else if (c >= 'A' && c <= 'F') {
                toNumeric = toNumeric.multiply(BigInteger.valueOf(16)).add(BigInteger.valueOf(c - 'A' + 10));
                count--;
            } else if (c >= 'a' && c <= 'f') {
                toNumeric = toNumeric.multiply(BigInteger.valueOf(16)).add(BigInteger.valueOf(c - 'a' + 10));
                count--;
            } else {
                continue;
            }
        }
        return paddedStr(toNumeric.toString());
    }

    public static String fetchPaddedAndroidID(String AndroidID) {
        if(AndroidID == null || AndroidID.isEmpty())
            return null;
        BigInteger toNumeric = new BigInteger(AndroidID, 16);
        return paddedStr(toNumeric.toString());
    }

    private static String paddedStr(String s) {
        return cipherString.substring(s.length()) + s;
    }




    public static String bytesToHex(byte[] bytes) {
        //Convert byte array to hex string
        StringBuilder sbuf = new StringBuilder();
        for(int idx=0; idx < bytes.length; idx++) {
            int intVal = bytes[idx] & 0xff;
            if (intVal < 0x10) sbuf.append("0");
            sbuf.append(Integer.toHexString(intVal).toUpperCase());
        }
        return sbuf.toString();
    }

    public static byte[] getUTF8Bytes(String str) {
        try { return str.getBytes("UTF-8"); } catch (Exception ex) { return null; }
    }


    public static String loadFileAsString(String filename) throws java.io.IOException {
        /*Load UTF8withBOM or any ansi text file. */
        final int BUFLEN=1024;
        BufferedInputStream is = new BufferedInputStream(new FileInputStream(filename), BUFLEN);
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream(BUFLEN);
            byte[] bytes = new byte[BUFLEN];
            boolean isUTF8=false;
            int read,count=0;
            while((read=is.read(bytes)) != -1) {
                if (count==0 && bytes[0]==(byte)0xEF && bytes[1]==(byte)0xBB && bytes[2]==(byte)0xBF ) {
                    isUTF8=true;
                    baos.write(bytes, 3, read-3); // drop UTF8 bom marker
                } else {
                    baos.write(bytes, 0, read);
                }
                count+=read;
            }
            return isUTF8 ? new String(baos.toByteArray(), "UTF-8") : new String(baos.toByteArray());
        } finally {
            try{ is.close(); } catch(Exception ignored){}
        }
    }


    public static String getMACAddress(String interfaceName) {
        try {
            List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface intf : interfaces) {
                if (interfaceName != null) {
                    if (!intf.getName().equalsIgnoreCase(interfaceName)) continue;
                }
                byte[] mac = intf.getHardwareAddress();
                if (mac==null) return "";
                StringBuilder buf = new StringBuilder();
                for (byte aMac : mac) buf.append(String.format("%02X:",aMac));
                if (buf.length()>0) buf.deleteCharAt(buf.length()-1);
                return buf.toString();
            }
        } catch (Exception ignored) { } // for now eat exceptions
        return "";
        /*try {
            // this is so Linux hack
            return loadFileAsString("/sys/class/net/" +interfaceName + "/address").toUpperCase().trim();
        } catch (IOException ex) {
            return null;
        }*/
    }


    public static String getIPAddress(boolean useIPv4) {
        try {
            List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface intf : interfaces) {
                List<InetAddress> addrs = Collections.list(intf.getInetAddresses());
                for (InetAddress addr : addrs) {
                    if (!addr.isLoopbackAddress()) {
                        String sAddr = addr.getHostAddress();
                        //boolean isIPv4 = InetAddressUtils.isIPv4Address(sAddr);
                        boolean isIPv4 = sAddr.indexOf(':')<0;

                        if (useIPv4) {
                            if (isIPv4)
                                return sAddr;
                        } else {
                            if (!isIPv4) {
                                int delim = sAddr.indexOf('%'); // drop ip6 zone suffix
                                return delim<0 ? sAddr.toUpperCase() : sAddr.substring(0, delim).toUpperCase();
                            }
                        }
                    }
                }
            }
        } catch (Exception ignored) { } // for now eat exceptions
        return "";
    }

}
