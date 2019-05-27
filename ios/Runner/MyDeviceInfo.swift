
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
        let modelName = UIDevice.modelName;
        print("<<<<<<<<<<<,Model Name>>>>>>>>>");
        return modelName;
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

public extension UIDevice {
    
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad Mini 5"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
    
}

