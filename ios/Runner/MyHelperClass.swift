
import Foundation

class MyHelperClass{
    static func getQueryStringParameter(url: String, param: String) -> String? {
        var result:String = "";
        guard let url = URLComponents(string: url) else {
            return "" }
        result=url.queryItems?.first(where: { $0.name == param })?.value ?? "";
        return result;
    }
    
    static func isValidUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                return UIApplication.shared.canOpenURL(url)
            }
        }
        return false
    }
    
    
}
