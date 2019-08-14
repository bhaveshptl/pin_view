class Event {
  double appVersion;
  int clientTimestamp;
  final int id;
  final String name;
  final String network;
  String source;
  String journey;
  int userId;
  final int v1;
  final int v2;
  final int v3;
  final int v4;
  final int v5;
  final int v6;
  final int v7;
  final String s1;
  final String s2;
  final String s3;
  final String s4;
  final String s5;

  Event({
    this.appVersion = 0,
    this.clientTimestamp = 0,
    this.id = 0,
    this.name = "",
    this.network = "",
    this.source = "",
    this.journey = "",
    this.userId = 0,
    this.v1 = 0,
    this.v2 = 0,
    this.v3 = 0,
    this.v4 = 0,
    this.v5 = 0,
    this.v6 = 0,
    this.v7 = 0,
    this.s1 = "",
    this.s2 = "",
    this.s3 = "",
    this.s4 = "",
    this.s5 = "",
  });

  Map<String, dynamic> toJson() => {
        "appVersion": appVersion,
        "clientTimestamp": clientTimestamp,
        "id": id,
        "name": name,
        "network": network,
        "source": source,
        "userId": userId,
        "journey": journey,
        "v1": v1,
        "v2": v2,
        "v3": v3,
        "v4": v4,
        "v5": v5,
        "v6": v6,
        "v7": v7,
        "s1": s1,
        "s2": s2,
        "s3": s3,
        "s4": s4,
        "s5": s5,
      };
}

class Visit {
  final double appVersion;
  final int channelId;
  int clientTimestamp;
  final int creativeId;
  final String deviceId;
  final String domain;
  final String googleAddId;
  final int id;
  final String manufacturer;
  final String model;
  final String networkOp;
  final String networkType;
  final String osName;
  final String osVersion;
  final int partnerId;
  final int productId;
  final String providerId;
  final String refCode;
  final String refURL;
  final String serial;
  final String sessionId;
  final int uid;
  int userId;
  String utmCampaign;
  String utmContent;
  String utmMedium;
  String utmSource;
  String utmTerm;
  Visit({
    this.appVersion = 0,
    this.channelId = 0,
    this.clientTimestamp = 0,
    this.creativeId = 0,
    this.deviceId = "",
    this.domain = "",
    this.googleAddId = "",
    this.id = 0,
    this.manufacturer = "",
    this.model = "",
    this.networkOp = "",
    this.networkType = "",
    this.osName = "",
    this.osVersion = "",
    this.partnerId = 0,
    this.productId = 0,
    this.providerId = "",
    this.refCode = "",
    this.refURL = "",
    this.serial = "",
    this.sessionId = "",
    this.uid = 0,
    this.userId = 0,
    this.utmCampaign = "",
    this.utmContent = "",
    this.utmMedium = "",
    this.utmSource = "",
    this.utmTerm = "",
  });

  Map<String, dynamic> toJson() => {
        "appVersion": appVersion,
        "channelId": channelId,
        "clientTimestamp": clientTimestamp,
        "creativeId": creativeId,
        "deviceId": deviceId,
        "domain": domain,
        "googleAddId": googleAddId,
        "id": id,
        "manufacturer": manufacturer,
        "model": model,
        "networkOp": networkOp,
        "networkType": networkType,
        "osName": osName,
        "osVersion": osVersion,
        "partnerId": partnerId,
        "productId": productId,
        "providerId": providerId,
        "refCode": refCode,
        "refURL": refURL,
        "serial": serial,
        "sessionId": sessionId,
        "uid": uid,
        "userId": userId,
        "utmCampaign": utmCampaign,
        "utmContent": utmContent,
        "utmMedium": utmMedium,
        "utmSource": utmSource,
        "utmTerm": utmTerm,
      };
}
