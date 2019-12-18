class DeepLinkingData {
  String dl_page_route;
  String dl_leagueId;
  String dl_ac_promocode;
  String dl_ac_promoamount;
  String dl_sp_pageLocation;
  String dl_sp_pageTitle;
  String dl_sport_type;
  String dl_unique_id;
  
  DeepLinkingData(
      {this.dl_page_route = " ",
      this.dl_leagueId = "0",
      this.dl_ac_promocode = " ",
      this.dl_ac_promoamount = " ",
      this.dl_sp_pageLocation = " ",
      this.dl_sp_pageTitle = " ",
      this.dl_sport_type = " ",
      this.dl_unique_id = " "});

  factory DeepLinkingData.fromJson(Map<dynamic, dynamic> json) {
    return DeepLinkingData(
        dl_page_route: (json["dl_page_route"]),
        dl_leagueId: (json["dl_leagueId"]),
        dl_ac_promocode: (json["dl_ac_promocode"]),
        dl_sp_pageLocation: (json["dl_sp_pageLocation"]),
        dl_sp_pageTitle: (json["dl_sp_pageTitle"]),
        dl_sport_type: (json["dl_sport_type"]),
        dl_unique_id: (json["dl_unique_id"]),
        dl_ac_promoamount: (json["dl_ac_promoamount"]));
  }
}
