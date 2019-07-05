import UIKit
import Flutter
import Razorpay
import UserNotifications
import Branch
import WebEngage
import FirebaseInstanceID
import FirebaseMessaging
import Firebase
import CoreLocation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,RazorpayPaymentCompletionProtocolWithData,CLLocationManagerDelegate {
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
    private var UTILS_CHANNEL:FlutterMethodChannel!;
    private var razorpay_result: FlutterResult!
    private var location_permission_result: FlutterResult!
    private var device_info_result: FlutterResult!
    private var bBranchLodead:Bool = false;
    private var app_launchOptions: [UIApplicationLaunchOptionsKey: Any]?;
    //var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var weUser: WEGUser!
    var weAnalytics: WEGAnalytics!
    let locationManager = CLLocationManager()
    
    
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
        
        UTILS_CHANNEL = FlutterMethodChannel(name: "com.algorin.pf.utils",binaryMessenger: controller)
        /* Init Services*/
        initPushNotifications(application);
        initFlutterChannels();
        initWebengage(application,didFinishLaunchingWithOptions:launchOptions);
        initBranchPlugin(didFinishLaunchingWithOptions:launchOptions);
        enableLocationServices();
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
                    let argue = call.arguments as? [String : Any];
                     var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webEngageEventSigniup(signupData:argue!);
                    }
                    result(channelResult);
                }
                if(call.method=="webEngageEventLogin"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webEngageEventLogin(loginData:argue!);
                    }
                    result(channelResult);
                }
                if(call.method=="webEngageTransactionFailed"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webEngageTransactionFailed(data:argue!);
                    }
                    result(channelResult);
                }
                if(call.method=="webEngageTransactionSuccess"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webEngageTransactionSuccess(data:argue!);
                    }
                    result(channelResult);
                }
                if(call.method == "webengageTrackUser"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        if(argue != nil ){
                     channelResult = self!.webengageTrackUser(data:argue!);
                        }
                    }
                    result(channelResult)
                }
                else if (call.method == "webengageCustomAttributeTrackUser"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webengageCustomAttributeTrackUser(data:argue!);
                    }
                    result(channelResult);
                }
                else if (call.method == "webengageTrackEvent"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.webengageTrackEvent(data:argue!);
                    }
                    result(channelResult);
                }
                else if(call.method == "trackEventsWithAttributes"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.trackEventsWithAttributes(data:argue!);
                    }
                    result(channelResult);
                }
                else if(call.method == "webengageAddScreenData"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    result(channelResult);
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
                if(call.method == "shareViaFacebook"){
                    SocialShare.shareText(viewController:self?.controller,msg:call.arguments as! String);
                    result("Social Share");
                }
                if(call.method == "shareViaGmail"){
                    SocialShare.shareText(viewController:self?.controller,msg:call.arguments as! String);
                    result("Social Share");
                }
                else{
                    result(FlutterMethodNotImplemented)
                }
            })
        })
        
        UTILS_CHANNEL.setMethodCallHandler({
            (call: FlutterMethodCall, result:  FlutterResult) -> Void in
            self.UTILS_CHANNEL.setMethodCallHandler({
                [weak self] (call: FlutterMethodCall, result:@escaping FlutterResult) -> Void in
                if(call.method == "onUserInfoRefreshed"){
                    let argue = call.arguments as? [String : Any];
                    var  channelResult:String="";
                    if(argue != nil){
                        channelResult = self!.onUserInfoRefreshed(data:argue!);
                    }
                    result(channelResult);
                }
                if(call.method == "getLocationLongLat"){
                    self?.location_permission_result=result;
                    self?.getLocationLongLat();
                }
            })
        })
    }
    
    func getLocationLongLat(){
        locationManager.delegate = self
        var currentLocation: CLLocation!
        var response = [String : String]()
        response["bAccessGiven"] = "false";
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            currentLocation = locationManager.location;
            response["bAccessGiven"] = "true";
            response["longitude"] = String(currentLocation.coordinate.longitude);
            response["latitude"] = String(currentLocation.coordinate.latitude);
        }else{
           response["bAccessGiven"] = "false"; 
        }
        location_permission_result(response);
    }
    func enableLocationServices() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break
        case .restricted, .denied:
            break
        case .authorizedWhenInUse:
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            break
        case .authorizedAlways:
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            break
        }
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
        razorpay.open(options)
    }
    
    
    
    
    public func onPaymentError(_ code: Int32, description str: String,andData response: [AnyHashable : Any]?){
        /* Function Usecase : Call on Razorpay Payment Failed*/
        razorpay_result(FlutterError(code: "0",
                                     message: str,
                                     details: nil))
    }
    
    //andData response: [AnyHashable : Any]?
    public func onPaymentSuccess(_ payment_id: String,andData response: [AnyHashable : Any]?){
        print("<<<<<<<<<<< Payment Success >>>>>>>>>>>>>>>>>>>>>>>>>>>");
        /* Function Usecase : Call on Razorpay Payment success*/
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
        razorpay_result(response);
    }
    
    private func onUserInfoRefreshed(data:[String:Any])-> String{
        if(data["first_name"] != nil){
            let value:String = data["first_name"] as! String;
            weUser.setFirstName(value);
        }
        if(data["lastName"] != nil){
            let value:String = data["lastName"] as! String;
            weUser.setLastName(value);
        }
        if(data["login_name"] != nil){
            let value:String = data["login_name"] as! String;
            weUser.setAttribute("userName", withStringValue:value);
            
        }
        if(data["channelId"] != nil){
            let value:String = data["channelId"] as! String;
            weUser.setAttribute("channelId", withStringValue:value);
            
        }
        if(data["withdrawable"] != nil){
            var valueinD:Double = data["withdrawable"] as! Double;
            valueinD = Double(round(100*valueinD)/100);
            var valueinS:String = String(format: "%.0f", valueinD);
            let value = valueinD;
            weUser.setAttribute("withdrawable", withStringValue:String(value));
        }
        if(data["depositBucket"] != nil){
            var valueinD:Double = data["depositBucket"] as! Double;
            valueinD = Double(round(100*valueinD)/100);
            var valueinS:String = String(format: "%.0f", valueinD);
            let value = valueinD;
            weUser.setAttribute("depositBucket", withStringValue:String(value));
        }
        if(data["nonWithdrawable"] != nil){
            var valueinD:Double = data["nonWithdrawable"] as! Double;
            valueinD = Double(round(100*valueinD)/100);
            var valueinS:String = String(format: "%.0f", valueinD);
            let value = valueinD;
            weUser.setAttribute("nonWithdrawable", withStringValue:String(value));
        }
        if(data["nonPlayableBucket"] != nil){
            var valueinD:Double = data["nonPlayableBucket"] as! Double;
            valueinD = Double(round(100*valueinD)/100);
            var valueinS:String = String(format: "%.0f", valueinD);
            let value = valueinD;
            weUser.setAttribute("nonPlayableBucket", withStringValue:String(value));
        }
        if(data["pan_verification"] != nil){
            let value:String = data["pan_verification"] as! String;
            if(value=="DOC_NOT_SUBMITTED"){
                weUser.setAttribute("idProofStatus", withValue:0);
            }else if(value=="DOC_SUBMITTED"){
                 weUser.setAttribute("idProofStatus", withValue:1);
            }else if(value=="UNDER_REVIEW"){
                 weUser.setAttribute("idProofStatus", withValue:2);
            }else if(value=="DOC_REJECTED"){
                 weUser.setAttribute("idProofStatus", withValue:3);
            }else if(value=="VERIFIED") {
                 weUser.setAttribute("idProofStatus", withValue:4);
            }
            
        }
        if(data["mobile_verification"] != nil){
            let value:Bool = data["mobile_verification"] as! Bool;
            if(value){
                weUser.setAttribute("mobileVerified", withValue:true);
            }else{
                weUser.setAttribute("mobileVerified", withValue:false);
            }
        }
        if(data["address_verification"] != nil){
            let value:String = data["address_verification"] as! String;
            if(value=="DOC_NOT_SUBMITTED"){
                weUser.setAttribute("addressProofStatus", withValue:0);
            }else if(value=="DOC_SUBMITTED"){
                weUser.setAttribute("addressProofStatus", withValue:1);
            }else if(value=="UNDER_REVIEW"){
                weUser.setAttribute("addressProofStatus", withValue:2);
            }else if(value=="DOC_REJECTED"){
                weUser.setAttribute("addressProofStatus", withValue:3);
            }else if(value=="VERIFIED") {
                weUser.setAttribute("addressProofStatus", withValue:4);
            }
        }
        if(data["email_verification"] != nil){
            let value:Bool = data["email_verification"] as! Bool;
            if(value){
                 weUser.setAttribute("emailVerified", withValue:true);
            }else{
                 weUser.setAttribute("emailVerified", withValue:false);
            }
           
        }
        if(data["dob"] != nil){
            let value:String = data["dob"] as! String;
            weUser.setBirthDateString(value);
        }
        if(data["state"] != nil){
            let value:String = data["state"] as! String;
            weUser.setAttribute("State", withStringValue:value);
        }
        if(data["user_balance_webengage"] != nil){
            var valueinD:Double = data["user_balance_webengage"] as! Double;
            valueinD = Double(round(100*valueinD)/100);
            var valueinS:String = String(format: "%.0f", valueinD);
            let value = valueinD;
            weUser.setAttribute("balance", withStringValue:String(value));
        }
        return "Data is used";
    }
    
    private func  webengageTrackUser(data:[String:Any])-> String{
        /* Function Usecase : to track Web Engage User */
        var  trackType = "";
        var  value = "";
        if(data["trackingType"] != nil){
            trackType = data["trackingType"] as! String;
        }
        if(data["value"] != nil){
           value = data["value"] as! String;
        }
        switch trackType{
        case "login":
            weUser.login(value);
            return "Login Track added";
        case "logout":
            weUser.logout();
            return "Logout To Tracking event done";
        case "setEmail":
            weUser.setHashedEmail(value);
            return "Email track   added";
        case "setBirthDate":
            weUser.setBirthDateString(value);
            return "Birth Day track added";
        case "setPhoneNumber":
            weUser.setHashedPhone(value);
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
    
    private func  webengageCustomAttributeTrackUser(data:[String:Any]) -> String{
        /* Function Usecase : to track Web Engage User with custom attributes */
        var  trackType = "";
        var  value = "";
        if(data["trackType"] != nil){
            trackType = data["trackType"] as! String;
        }
        if(data["value"] != nil){
            value = data["value"] as! String;
        }
        weUser.setAttribute(trackType, withStringValue:value);
        return "User " + trackType + "tracking added";
    }
    
    private func webengageTrackEvent(data:[String:Any])-> String{
        /* Function Usecase : Track webengage Event without any Attributes*/
        var  eventName = "";
        if(data["eventName"] != nil){
            eventName = data["eventName"] as! String;
        }
        weAnalytics.trackEvent(withName:eventName)
        return "Event "+eventName+"" + "added";
    }
    
    
    private func trackEventsWithAttributes(data:[String:Any])-> String{
        /* Function Usecase : Track webengage Event with  Attributes*/
        var eventName = "";
        if(data["eventName"] != nil){
            eventName = data["eventName"] as! String;
        }
        var addedAttributes:[String:Any] = [:];
        if(data["data"] != nil){
            addedAttributes = data["data"] as! [String:Any];
        }
        weAnalytics.trackEvent(withName: eventName, andValue:addedAttributes)
        return "Event "+eventName+"" + "added";
    }
    
    private func webEngageEventSigniup(signupData:[String:Any])->String {
        var email = "";
        var phone = "";
        var addedAttributes:[String:Any] = [:];
        if(signupData["email"] != nil){
            email = signupData["email"] as! String;
        }
        if(signupData["phone"] != nil){
            phone = signupData["phone"] as! String;
        }
        if(signupData["data"] != nil){
            addedAttributes = signupData["data"] as! [String:Any];
        }
        weAnalytics.trackEvent(withName: "COMPLETE_REGISTRATION", andValue:addedAttributes);
        if(email.count>3){
             weUser.setHashedEmail(email);
        }
        if(phone.count>3){
            weUser.setHashedPhone(phone);
        }
        return "Web Engage Signup Event added";
    }
    
    private func webEngageEventLogin(loginData:[String:Any])->String{
        var email = "";
        var phone = "";
        var first_name = "";
        var last_name = "";
        var addedAttributes:[String:Any] = [:];
        if(loginData["email"] != nil){
            email = loginData["email"] as! String;
        }
        if(loginData["phone"] != nil){
            phone = loginData["phone"] as! String;
        }
        if(loginData["data"] != nil){
            addedAttributes = loginData["data"] as! [String:Any];
        }
        if(loginData["first_name"] != nil){
            first_name = loginData["first_name"] as! String;
        }
        if(loginData["last_name"] != nil){
           last_name = loginData["last_name"]! as! String ;
        }
        weAnalytics.trackEvent(withName: "COMPLETE_LOGIN", andValue:addedAttributes);
        if(email.count>3){
            weUser.setHashedEmail(email);
        }
        if(phone.count>3){
            weUser.setHashedPhone(phone);
        }
        if(loginData["first_name"] != nil){
             weUser.setFirstName(first_name);
        }
        if(loginData["last_name"] != nil){
             weUser.setLastName(last_name);
        }
         return "Web engage Login  Event added";
    }
    
    private func webEngageTransactionFailed(data:[String:Any])-> String{
        var isfirstDepositor:Bool = false;
        var eventName = "FIRST_DEPOSIT_FAILED";
        var addedAttributes:[String:Any] = [:];
        if(data["firstDepositor"] != nil){
            isfirstDepositor = data["firstDepositor"] as? Bool ?? false;
            if(!isfirstDepositor){
                eventName = "REPEAT_DEPOSIT_FAILED";
            }
        }
        if(data["data"] != nil){
            addedAttributes = data["data"] as! [String:Any];
        }
        weAnalytics.trackEvent(withName: eventName, andValue:addedAttributes);
        return "Web engage Transaction Failed  Event added";
    }
    
    private func webEngageTransactionSuccess(data:[String:Any])-> String{
        var isfirstDepositor:Bool = false;
        var eventName = "DEPOSIT_SUCCESS";
        var addedAttributes:[String:Any] = [:];
        if(data["data"] != nil){
            addedAttributes = data["data"] as! [String:Any];
        }
        weAnalytics.trackEvent(withName: eventName, andValue:addedAttributes);
        return "Web engage Transaction Success  Event added";
    }
    
    private func branchLifecycleEventSigniup(registrationID:String,transactionID:String,description:String,data: NSDictionary){
        let event = BranchEvent.standardEvent(.completeRegistration)
        event.transactionID = transactionID;
        event.eventDescription = description;
        event.customData["registrationID"] = registrationID;
        let obj = data as NSDictionary
        for (key, value) in obj {
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
    }
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
          
        }
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
        completionHandler()
    }
}


extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        Messaging.messaging().subscribe(toTopic: "news") { error in
           
        }
        
        Messaging.messaging().subscribe(toTopic: "ios_news") { error in
           
        }
        
    }
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
}

