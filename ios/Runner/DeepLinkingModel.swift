

import UIKit


class DeepLinkingModel {
    
    
    var activateDeepLinkingNavigation:Bool=false;
    var dl_page_route:String = "";
    var dl_leagueId: String = "";
    var dl_ac_promocode: String = "";
    var dl_ac_promoamount:String = "";
    var dl_sp_pageLocation:String = "";
    var dl_sp_pageTitle:String = "";
    var dl_sport_type:String = "";
    var dl_unique_id:String = "";
    
    init ?(dl_page_route: String, dl_leagueId: String, dl_ac_promocode:String ,dl_ac_promoamount:String,dl_sp_pageLocation:String,dl_sp_pageTitle:String,
           dl_sport_type:String,dl_unique_id:String ) {
        
        guard !dl_page_route.isEmpty else {
            return nil
        }
        
        
        
            self.dl_page_route=dl_page_route;
            self.activateDeepLinkingNavigation=true;
            
            if dl_leagueId.isEmpty   {
                self.dl_leagueId = "";
            }else{
                self.dl_leagueId = dl_leagueId
            }
            if dl_ac_promocode.isEmpty   {
                self.dl_leagueId = "";
            }else{
                self.dl_leagueId = dl_ac_promocode
            }
        }
    
    
}
