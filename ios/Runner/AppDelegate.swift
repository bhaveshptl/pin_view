import UIKit
import Flutter
import Razorpay
import UserNotifications
import Branch
import WebEngage
import FirebaseInstanceID
import FirebaseMessaging
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,RazorpayPaymentCompletionProtocolWithData {
    private var controller : FlutterViewController!;
    private var razorpay: Razorpay!
    private var razorpayProdKey:String="rzp_live_jpaEKwXwl8iWX6";
    private var firebaseToken:String="";
    private var installReferring_link:String="";
    private var refCodeFromBranch="";
    private var eventSink: FlutterEventSink?
    private var razorpay_arguments:NSDictionary!
    private var RAZORPAY_IO_CHANNEL:FlutterMethodChannel!;
    private var BRANCH_IO_CHANNEL:FlutterMethodChannel!;
    private var PF_FCM_CHANNEL:FlutterMethodChannel!;
    private var WEBENGAGE_CHANNEL:FlutterMethodChannel!;
    private var SOCIAL_SHARE_CHANNEL:FlutterMethodChannel!;
    private var BROWSER_LAUNCH_CHANNEL:FlutterMethodChannel!;
    private var razorpay_result: FlutterResult!
    private var device_info_result: FlutterResult!
    private var bBranchLodead:Bool = false;
    private var app_launchOptions: [UIApplicationLaunchOptionsKey: Any]?;
    //var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var weUser: WEGUser!
    var weAnalytics: WEGAnalytics!
    
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        /* Flutter Channel Init*/
        controller = window?.rootViewController as? FlutterViewController;
        RAZORPAY_IO_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.razorpay",binaryMessenger: controller)
        BRANCH_IO_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.branch",binaryMessenger: controller)
        PF_FCM_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.fcm",binaryMessenger: controller)
        WEBENGAGE_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.webengage",binaryMessenger: controller)
        SOCIAL_SHARE_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.socialshare",binaryMessenger: controller)
        BROWSER_LAUNCH_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.browser",binaryMessenger: controller)
        /* Init Services*/
        initPushNotifications(application);
        initFlutterChannels();
        initWebengage(application,didFinishLaunchingWithOptions:launchOptions);
        initBranchPlugin(didFinishLaunchingWithOptions:launchOptions);
        
        /* Flutter App Init*/
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func initPushNotifications(_ application: UIApplication){
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    private func  getFireBaseToken()-> String{
        var token:String = "";
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print(error);
            } else if let result = result {
                token=result.token;
            }
        }
        return token;
        
    }
    
    private func subscribeToFirebaseTopic(topicName:String)->String {
        Messaging.messaging().subscribe(toTopic: topicName) { error in
            
        }
        return "Subscribed to the firebase topic"+topicName;
        
    }
    
    private func initWebengage(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?){
        WebEngage.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions);
        weUser = WebEngage.sharedInstance().user;
        weAnalytics = WebEngage.sharedInstance().analytics;
    }
    
    private func initBranchPlugin(didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?){
        Branch.setUseTestBranchKey(false);
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            self.bBranchLodead = true;
            if let error = error {
                print(error);
            } else if let params = params {
                self.initBranchSession(branchResultData:params as? [String: AnyObject]);
            }
        }
    }
    
    private func getBranchData(result: FlutterResult){
        var object = [String : String]();
        if (app_launchOptions != nil){
            Branch.getInstance().initSession(launchOptions: app_launchOptions) { (params, error) in
                if let error = error {
                    print(error);
                } else if let params = params {
                    object=self.initBranchSession(branchResultData:params as? [String: AnyObject]);
                }
                
            }
        }
        result(object);
    }
    
    
    private func initBranchSession(branchResultData branchData:[String: AnyObject]?)->[String:String]{
        print("<<<<<<<<<<<Branch>>>>>>>>>>>>");
        var object = [String : String]();
        var refCodeFromBranchTrail0:String = "";
        var refCodeFromBranchTrail1:String = "";
        var refCodeFromBranchTrail2:String = "";
        var installReferring_link0:String = "";
        var installReferring_link1:String = "";
        var installReferring_link2:String = "";
        let installParams = Branch.getInstance().getFirstReferringParams();
        let sessionParams = Branch.getInstance().getLatestReferringParams();
        
        if branchData != nil {
            print(branchData!);
            if(branchData!["+clicked_branch_link"] != nil){
                if(branchData!["+clicked_branch_link"]! as? Int == 1){
                    installReferring_link0=branchData!["~referring_link"]! as? String ?? "";
                    if branchData!["refCode"] as? String  != nil {
                        refCodeFromBranchTrail0=branchData!["refCode"]! as? String ?? "";
                    }
                    else{
                        refCodeFromBranchTrail0=MyHelperClass.getQueryStringParameter(url: installReferring_link2, param: "refCode") ?? "";
                    }
                }
            }
        }
        
        if installParams != nil {
            print(installParams!);
            if(installParams!["+clicked_branch_link"] != nil){
                if(installParams!["+clicked_branch_link"]! as? Int == 1){
                    installReferring_link1=installParams!["~referring_link"]! as? String ?? "";
                    if installParams!["refCode"] as? String  != nil {
                        refCodeFromBranchTrail1=installParams!["refCode"]! as? String ?? "";
                    }
                    else{
                        refCodeFromBranchTrail1=MyHelperClass.getQueryStringParameter(url: installReferring_link2, param: "refCode") ?? "";
                    }
                }
            }
        }
        
        if sessionParams != nil {
            print(sessionParams!);
            if(sessionParams!["+clicked_branch_link"] != nil){
                if(sessionParams!["+clicked_branch_link"]! as? Int == 1){
                    installReferring_link2=sessionParams!["~referring_link"]! as? String ?? "";
                    if sessionParams!["refCode"] as? String  != nil {
                        refCodeFromBranchTrail2=sessionParams!["refCode"]! as? String ?? "";
                    }
                    else{
                        refCodeFromBranchTrail2=MyHelperClass.getQueryStringParameter(url: installReferring_link2, param: "refCode") ?? "";
                    }
                }
            }
        }
        
        if (installReferring_link0 != "") {
            installReferring_link = installReferring_link0;
            
        } else if (installReferring_link1 != "") {
            installReferring_link = installReferring_link1;
            
        } else if (installReferring_link2 != "") {
            installReferring_link = installReferring_link2;
        }
        
        if (refCodeFromBranchTrail0.count > 2) {
            refCodeFromBranch = refCodeFromBranchTrail0;
        } else if (refCodeFromBranchTrail1.count > 2) {
            refCodeFromBranch = refCodeFromBranchTrail1;
        } else {
            refCodeFromBranch = refCodeFromBranchTrail2;
        }
        object["installReferring_link"] = installReferring_link;
        object["refCodeFromBranch"] = refCodeFromBranch;
        return object;
    }
    
    private func initFlutterChannels(){
        
        RAZORPAY_IO_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.RAZORPAY_IO_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "initRazorpayNativePlugin"){
                    result("Razorpay Init done");
                }
                else if(call.method == "_openRazorpayNative"){
                    self?.razorpay_result=result;
                    let razorpayInitArgue = call.arguments as? [String: AnyObject] ;
                    if(razorpayInitArgue != nil){
                        let product_name = razorpayInitArgue!["name"] as? String ;
                        let prefill_email = razorpayInitArgue!["email"] as? String;
                        let prefill_phone = razorpayInitArgue!["phone"] as? String;
                        let product_amount = razorpayInitArgue!["amount"] as? String;
                        let product_orderId = razorpayInitArgue!["orderId"] as? String;
                        let product_method = razorpayInitArgue!["method"] as? String;
                        let product_image = razorpayInitArgue!["image"] as? String;
                        self?.showPaymentForm(name: product_name!, email:prefill_email!, phone:prefill_phone!, amount:product_amount!,orderId:product_orderId!, method:product_method!,image:product_image!);
                    }
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        });
        
        BROWSER_LAUNCH_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.BROWSER_LAUNCH_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "launchInBrowser"){
                    let weburl=call.arguments as? String;
                    guard let url = URL(string: weburl!) else {
                        result(FlutterMethodNotImplemented)
                        return //be safe
                    }
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                    result("Broser Opened");
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
                
            })
        });
        
        WEBENGAGE_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.WEBENGAGE_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                
                if(call.method=="webEngageEventSigniup"){
                    let  channelResult:String=""
                    result(channelResult);
                }
                if(call.method=="webEngageEventLogin"){
                    let  channelResult:String=""
                    result(channelResult);
                }
                if(call.method=="webEngageTransactionFailed"){
                    let  channelResult:String=""
                    result(channelResult);
                }
                if(call.method=="webEngageTransactionSuccess"){
                    let  channelResult:String=""
                    result(channelResult);
                }
                if(call.method == "webengageTrackUser"){
                    let argue = call.arguments as? NSDictionary;
                    let  channelResult:String="";
                    if(argue != nil){
                        let trackType = argue!["trackType"] as? String;
                        let value = argue!["value"] as? String;
                        if(trackType != nil ){
                            if(value != nil){
                             self?.webengageTrackUser(trackType:trackType!,value:value!);
                            }
                        }
                    }
                    result(channelResult)
                }
                else if (call.method == "webengageCustomAttributeTrackUser"){
                    let  channelResult:String=""
                    result(channelResult)
                }
                else if (call.method == "webengageTrackEvent"){
                    let  channelResult:String=""
                    result(channelResult)
                }
                else if(call.method == "trackEventsWithAttributes"){
                    let  channelResult:String=""
                    result(channelResult)
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        })
        
        BRANCH_IO_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.BRANCH_IO_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "_getBranchRefCode"){
                    let  channelResult:String=self!.refCodeFromBranch;
                    result(channelResult)
                }
                else if(call.method == "_initBranchIoPlugin"){
                    let  channelResult:String=""
                    if (self!.bBranchLodead) {
                        var object = [String : String]();
                        object["installReferring_link"] = self!.installReferring_link;
                        object["refCodeFromBranch"] = self!.refCodeFromBranch;
                        result(object);
                    } else {
                        self!.getBranchData(result:result);
                    }
                    result(channelResult)
                }
                else if(call.method == "_getInstallReferringLink"){
                    let  channelResult:String=self!.installReferring_link;
                    
                    result(channelResult)
                }
                    
                else if(call.method == "trackAndSetBranchUserIdentity"){
                    let  channelResult:String="";
                    Branch.getInstance().setIdentity(call.arguments as? String)
                    result(channelResult);
                }
                else if(call.method == "branchLifecycleEventSigniup"){
                    let  channelResult:String="";
                    let argue = call.arguments as? NSDictionary;
                    let data = argue!["data"]! as? [String: Any];
                    
                    let event = BranchEvent.standardEvent(.completeRegistration)
                    event.transactionID = argue!["transactionID"] as? String;
                    event.eventDescription = argue!["description"] as? String;
                    event.customData["registrationID"] = argue!["registrationID"] as? String;
                    event.customData["login_name"] = data!["login_name"]!;
                    event.customData["channelId"] =  data!["channelId"]!;
                    
                    for (key , value) in data! {
                        //event.customData[key+""] = value;
                    }
                    event.logEvent();
                    result(channelResult);
                }
                else if(call.method == "branchEventTransactionFailed"){
                    let  channelResult:String="";
                    let argue = call.arguments as? NSDictionary;
                    let data = argue!["data"]! as? NSDictionary;
                    var  isfirstDepositor:Bool=false;
                    var eventName:String="FIRST_DEPOSIT_FAILED";
                    isfirstDepositor = argue!["firstDepositor"] as? Bool ?? false;
                    if(!isfirstDepositor){
                        eventName = "REPEAT_DEPOSIT_FAILED";
                    }
                    let event = BranchEvent.customEvent(withName:eventName)
                    for (key, value) in data! {
                        event.customData[key] = value;
                    }
                    event.logEvent();
                    print("<<<<<<<<<<<<<<<<B>>>>>>>>>>>>>");
                    print(event);
                    result(channelResult)
                }
                else if(call.method == "branchEventTransactionSuccess"){
                    let  channelResult:String="";
                    let argue = call.arguments as? NSDictionary;
                    let data = argue!["data"]! as? NSDictionary;
                    var  isfirstDepositor:Bool=false;
                    var eventName:String="FIRST_DEPOSIT_SUCCESS";
                    isfirstDepositor = argue!["firstDepositor"] as? Bool ?? false;
                    if(!isfirstDepositor){
                        eventName = "REPEAT_DEPOSIT_SUCCESS";
                    }
                    let event = BranchEvent.customEvent(withName:eventName)
                    for (key, value) in data! {
                        event.customData[key] = value;
                    }
                    event.logEvent();
                    
                    result(channelResult)
                }
                else if(call.method == "_getGoogleAddId"){
                    var  channelResult:String="";
                    channelResult=MyDeviceInfo.identifierForAdvertising();
                    result(channelResult)
                }
                else if(call.method == "_getAndroidDeviceInfo"){
                    self?.device_info_result=result;
                    self?.getDeviceInfo(deviceinfoResult: result);
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        })
        
        PF_FCM_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.PF_FCM_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "_getFirebaseToken"){
                    var  channelResult:String="";
                    if(self!.firebaseToken.count>4){
                        channelResult=self!.firebaseToken;
                    }
                    else{
                        channelResult=self!.getFireBaseToken();
                    }
                    result(channelResult)
                }
                else if(call.method == "_subscribeToFirebaseTopic"){
                    let topic=call.arguments as? String;
                    var  channelResult:String = "";
                    if(topic != nil){
                        channelResult=self!.subscribeToFirebaseTopic(topicName:topic!);
                    }
                    result(channelResult)
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        })
        
        
        SOCIAL_SHARE_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.SOCIAL_SHARE_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "initSocialShareChannel"){
                    result("Social Share");
                }
                if(call.method == "shareViaWhatsApp"){
                    let isWhatsAppOpened:Bool = SocialShare.shareViaWhatsApp(msg:call.arguments as! String);
                    if(isWhatsAppOpened){
                        result("Social Share");
                    }
                    else{
                        result(FlutterError(code: "0",message: "Failed to open WhatsApp",
                                            details: nil));
                    }
                    
                }
                if(call.method == "shareText"){
                    SocialShare.shareText(viewController:self?.controller,msg:call.arguments as! String);
                    result("Social Share");
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        })
    }
    
    
    internal func showPaymentForm(name: String, email:String, phone:String, amount:String,orderId:String, method:String,image:String){
        /* Function Usecase : Open  Razorpay Payment Window*/
        razorpay = Razorpay.initWithKey(razorpayProdKey, andDelegateWithData: self);
        let options: [String:Any] = [
            "amount" :amount ,
            "description": "Add Cash",
            "image": image,
            "name": name,
            "currency":"INR",
            "order_id":orderId,
            "prefill": [
                "contact": phone,
                "email": email,
                "method":method
            ],
            "theme": [
                "color": "#d32518"
            ]
        ]
        print(options);
        razorpay.open(options)
    }
    
    
    
    
    public func onPaymentError(_ code: Int32, description str: String,andData response: [AnyHashable : Any]?){
        /* Function Usecase : Call on Razorpay Payment Failed*/
        print("<<<<<<<<<<< Payment Failed >>>>>>>>>>>>>>>>>>>>>>>>>>>");
        // RAZORPAY_IO_CHANNEL.invokeMethod("onRazorPayPaymentFail", arguments: str);
        print(str);
        razorpay_result(FlutterError(code: "0",
                                     message: str,
                                     details: nil))
    }
    
    //andData response: [AnyHashable : Any]?
    public func onPaymentSuccess(_ payment_id: String,andData response: [AnyHashable : Any]?){
        print("<<<<<<<<<<< Payment Success >>>>>>>>>>>>>>>>>>>>>>>>>>>");
        /* Function Usecase : Call on Razorpay Payment success*/
        print(payment_id);
        print(response!);
        var dict : Dictionary = Dictionary<AnyHashable,Any>();
        if(response != nil){
            dict=response!;
        }
        let razorpay_signature : String = dict["razorpay_signature"] as? String ?? "";
        let razorpay_order_id : String = dict["razorpay_order_id"] as? String ?? "";
        var response = [String : String]()
        response["paymentId"] = payment_id
        response["signature"] = razorpay_signature;
        response["orderId"] = razorpay_order_id;
        response["status"] = "paid";
        print(response);
        razorpay_result(response);
        
    }
    
    private func  webengageTrackUser(trackType:String,value:String)-> String{
        /* Function Usecase : to track Web Engage User */
        switch trackType{
        case "login":
            weUser.login(value);
            return "Login Track added";
        case "logout":
            weUser.logout();
            return "Logout To Tracking event done";
        case "setEmail":
            weUser.setEmail(value);
            return "Email track   added";
        case "setBirthDate":
            weUser.setBirthDateString(value);
            return "Birth Day track added";
        case "setPhoneNumber":
            weUser.setPhone(value);
            return "Phone Number track added";
        case "setFirstName":
            weUser.setFirstName(value);
            return "Login Track added";
        case "setGender":
            let gendel:String=value;
            if(gendel=="male"){
                weUser.setGender(gendel);
            }
            else if (gendel=="female"){
                weUser.setGender(gendel);
            }
            else{
                weUser.setGender(gendel);
            }
            return "User Gender  added";
        case "setLastName":
            weUser.setLastName(value);
            return "Last Name  Track added";
        default:
            return "No Such tracking type found ";
        }
    }
    
    private func  webengageCustomAttributeTrackUser(trackType:String,value:String) -> String{
        /* Function Usecase : to track Web Engage User with custom attributes */
        weUser.setAttribute(trackType, withStringValue:value);
        return "User " + trackType + "tracking added";
    }
    
    private func webengageTrackEvent(eventName:String,priority:Bool)-> String{
        /* Function Usecase : Track webengage Event without any Attributes*/
        weAnalytics.trackEvent(withName:eventName)
        return "Event "+eventName+"" + "added";
    }
    
    
    private func trackEventsWithAttributes(eventName:String,priority:Bool)-> String{
        /* Function Usecase : Track webengage Event with  Attributes*/
        let orderPlacedAttributes : [String:Any] = [
            "Amount": 808.48,
            "Product 1 SKU Code": "UHUH799",
        ]
        weAnalytics.trackEvent(withName: eventName, andValue: orderPlacedAttributes)
        return "Event "+eventName+"" + "added";
    }
    
    
    
    
    
    private func branchLifecycleEventSigniup(registrationID:String,transactionID:String,description:String,data: NSDictionary){
        let event = BranchEvent.standardEvent(.completeRegistration)
        event.transactionID = transactionID;
        event.eventDescription = description;
        event.customData["registrationID"] = registrationID;
        let obj = data as NSDictionary
        for (key, value) in obj {
            print(key);
            print(value);
            event.customData[key] = value;
        }
        event.logEvent();
    }
    
    
    private func getDeviceInfo(deviceinfoResult: FlutterResult){
        let deviceInfoDict: NSDictionary = [
            "versionCode":MyDeviceInfo.getVersionCode(),
            "versionName":MyDeviceInfo.getVersionName(),
            "uid":MyDeviceInfo.getUID(),
            "model":MyDeviceInfo.getModel(),
            "serial":"",
            "manufacturer":"Apple",
            "version":MyDeviceInfo.getOSVersion(),
            "network_operator":MyDeviceInfo.getNetworkOperator(),
            "packageName":MyDeviceInfo.getPackageName(),
            "baseRevisionCode":"",
            "firstInstallTime":"",
            "lastUpdateTime":"",
            "device_ip_":MyDeviceInfo.getDeviceIPAddress(),
            "network_type":MyDeviceInfo.getNetworkType(),
            "googleaddid":MyDeviceInfo.identifierForAdvertising()
        ]
        device_info_result(deviceInfoDict)
    }
    
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
    }
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        completionHandler(UIBackgroundFetchResult.newData);
        Branch.getInstance().handlePushNotification(userInfo)
    }
    
    
    
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        InstanceID.instanceID().instanceID(handler: { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                self.firebaseToken=result.token;
            }
        })
    }
    
    
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Branch.getInstance().application(app, open: url, options: options)
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        Branch.getInstance().continue(userActivity)
        return true
    }
}


@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        completionHandler()
    }
}


extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        Messaging.messaging().subscribe(toTopic: "news") { error in
            print("Subscribed to news topic")
        }
        
        Messaging.messaging().subscribe(toTopic: "ios_news") { error in
            print("Subscribed to ios_news topic")
        }
        
    }
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
}

