
import Foundation
import UIKit;



class SocialShare{
    
    static func shareViaWhatsApp(msg:String){
        let msg = msg
        let urlWhats = "whatsapp://send?text=\(msg)";
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                
                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                     //UIApplication.shared.openURL(whatsappURL as URL)
                    UIApplication.shared.open(whatsappURL as URL)
                    
                } else {
                    // Cannot open whatsapp
                }
            }
        }
    }
    
    static func shareText(viewController: UIViewController!,msg:String){
        let text = msg
        // set up activity view controller
        let textToShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = viewController.view // so that iPads won't crash
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop]
        // present the view controller
        viewController.present(activityViewController, animated: true, completion: nil)
        
    }
    
}
