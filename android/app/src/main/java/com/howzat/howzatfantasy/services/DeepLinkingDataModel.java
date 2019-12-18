package com.howzat.howzatfantasy.services;

import java.util.HashMap;
import java.util.Map;

public class DeepLinkingDataModel {

    boolean activateDeepLinkingNavigation=false;
    String dl_page_route = " ";
    String dl_leagueId = " ";
    String dl_ac_promocode = " ";
    String dl_ac_promoamount = " ";
    String dl_sp_pageLocation = " ";
    String dl_sp_pageTitle = " ";
    String dl_sport_type = " ";
    String dl_unique_id = " ";

    public void setActivateDeepLinkingNavigation(boolean value){
        this.activateDeepLinkingNavigation=value;
    }

    public void setDlPageRoute(String name) {
        this.dl_page_route = name;
    }

    public void setDlLeagueId(String name) {
        this.dl_leagueId = name;
    }

    public void setDlAcPromocode(String name) {
        this.dl_ac_promocode = name;
    }

    public void setDlSpPageLocation(String name) {
        this.dl_sp_pageLocation = name;
    }

    public void setDlSpPageTitle(String name) {
        this.dl_sp_pageTitle = name;
    }

    public void setDlSportType(String name) {
        this.dl_sport_type = name;
    }

    public void setDlUnique_id(String name) {
        this.dl_unique_id = name;
    }


    public void setDlAcPromoamount(String name) {
        this.dl_ac_promoamount = name;
    }

    public boolean getActivateDeepLinkingNavigation(){
        return this.activateDeepLinkingNavigation;
    }

    public String getDlPageRoute( ) {
        return  this.dl_page_route;
    }

    public String getDlLeagueId( ) {
        return this.dl_leagueId ;
    }

    public String getDlAcPromocode( ) {
        return this.dl_ac_promocode ;
    }

    public String getDlSpPageLocation( ) {
        return this.dl_sp_pageLocation ;
    }

    public String getDlSpPageTitle( ) {
        return this.dl_sp_pageTitle ;
    }

    public String getDlSportType( ) {
        return this.dl_sport_type  ;
    }

    public String getDlUnique_id( ) {
        return this.dl_unique_id  ;
    }


    public String getDlAcPromoamount( ) {
        return  this.dl_ac_promoamount ;
    }


    public HashMap getDeepLinkingDataMap(){
        HashMap<String, Object> deepLinkingDataObject =new HashMap<>();
        deepLinkingDataObject.put("activateDeepLinkingNavigation", activateDeepLinkingNavigation);
        deepLinkingDataObject.put("dl_page_route", dl_page_route);
        deepLinkingDataObject.put("dl_leagueId", dl_leagueId);
        deepLinkingDataObject.put("dl_ac_promocode", dl_ac_promocode);
        deepLinkingDataObject.put("dl_ac_promoamount", dl_ac_promoamount);
        deepLinkingDataObject.put("dl_sp_pageLocation", dl_sp_pageLocation);
        deepLinkingDataObject.put("dl_sp_pageTitle", dl_sp_pageTitle);
        deepLinkingDataObject.put("dl_sport_type", dl_sport_type);
        deepLinkingDataObject.put("dl_unique_id", dl_unique_id);
        return deepLinkingDataObject;
    }

}


