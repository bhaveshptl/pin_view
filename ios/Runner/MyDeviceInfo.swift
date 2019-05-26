
import Foundation;
import CoreTelephony;
import AdSupport;

class MyDeviceInfo{
    
    static func postRequest() -> [String:String] {
        return ["someData" : "someData"]
    }
    
    static func getVersionCode() ->String {
        var versionCode:String = "";
        if(Bundle.main.infoDictionary != nil){
            if(Bundle.main.infoDictionary!["CFBundleVersion"] != nil){
                versionCode = Bundle.main.infoDictionary!["CFBundleVersion"]!as! String;
            }
        }
        return versionCode;
    }
    
    static func getVersionName() ->String {
        
        var versionName:String = "";
        if(Bundle.main.infoDictionary != nil){
            if(Bundle.main.infoDictionary!["CFBundleShortVersionString"] != nil){
                versionName = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!as! String;
            }
        }
        return versionName;
    }
    
    static func getUID() ->String {
        if (UIDevice.current.identifierForVendor?.uuidString) != nil {
            return (UIDevice.current.identifierForVendor?.uuidString)!;
        }
        else {
            return "";
        }
    }
    
    static func getModel() ->String {
        return machineName();
    }
    
    static func getSerial() ->String {
        return "";
    }
    
    static func getManufacturer() ->String {
        return "";
    }
    
    static func getOSVersion() ->String {
        return UIDevice.current.systemVersion;
    }
    
    static func getNetworkOperator() ->String {
        let networkInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo();
        guard let carrier: CTCarrier = networkInfo.subscriberCellularProvider else {
            /*No carrier info available*/
            return ""
        }
        if carrier.carrierName != nil {
            return carrier.carrierName!;
        }
        else {
            return "";
        }
        
    }
    
    static func getPackageName() ->String {
        if(Bundle.main.bundleIdentifier != nil){
              return Bundle.main.bundleIdentifier!;
        }
        else{
            return ""
        }
    }
    
    static func getDeviceIPAddress() ->String {
        var ipAddress:String = "";
        if let addr = getWiFiAddress() {
            ipAddress=addr
        }
        
        return ipAddress ;
    }
    
    static func getNetworkType() ->String {
        return getConnectionType();
    }
    
    static func machineName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    static func getConnectionType() ->String{
        var tecnologyType:String;
        let networkInfo = CTTelephonyNetworkInfo()
        let networkString = networkInfo.currentRadioAccessTechnology
        tecnologyType="";
        if networkString == CTRadioAccessTechnologyLTE{
            // LTE (4G)
            tecnologyType="4G"
        }else if networkString == CTRadioAccessTechnologyWCDMA{
            
            tecnologyType="3G"
        }else if networkString == CTRadioAccessTechnologyEdge{
            tecnologyType="2G"
        }
        return tecnologyType;
    }
    
    static func getWiFiAddress() -> String? {
        var address : String?
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            
            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
    
    
    static func identifierForAdvertising() -> String? {
        guard ASIdentifierManager.shared().isAdvertisingTrackingEnabled else {
            return ""}
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString;
    }
    
    
    
}
