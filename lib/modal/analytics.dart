class Event {
  final int appVersion;
  final int clientTimestamp;
  final int id;
  final String name;
  final String network;
  final String source;
  final int userId;
  final int value1;
  final int value2;
  final int value3;
  final int value4;
  final int value5;
  final int value6;

  Event({
    this.appVersion = 0,
    this.clientTimestamp = 0,
    this.id = 0,
    this.name = "",
    this.network = "",
    this.source = "",
    this.userId = 0,
    this.value1 = 0,
    this.value2 = 0,
    this.value3 = 0,
    this.value4 = 0,
    this.value5 = 0,
    this.value6 = 0,
  });

  Map<String, dynamic> toJson() => {
        "appVersion": appVersion,
        "clientTimestamp": clientTimestamp,
        "id": id,
        "name": name,
        "network": network,
        "source": source,
        "userId": userId,
        "value1": value1,
        "value2": value2,
        "value3": value3,
        "value4": value4,
        "value5": value5,
        "value6": value6,
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
  final int userId;
  final String utmCampaign;
  final String utmContent;
  final String utmMedium;
  final String utmSource;
  final String utmTerm;
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
