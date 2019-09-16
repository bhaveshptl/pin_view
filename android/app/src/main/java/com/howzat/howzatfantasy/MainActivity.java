package com.howzat.howzatfantasy;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.widget.Toast;
import android.content.Context;

import com.google.gson.Gson;
import com.google.gson.JsonIOException;
import com.google.gson.JsonObject;
import com.howzat.howzatfantasy.services.BranchClass;
import com.howzat.howzatfantasy.services.DeviceInfo;
import com.howzat.howzatfantasy.services.MyHelperClass;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.branch.indexing.BranchUniversalObject;
import io.branch.referral.Branch;
import io.branch.referral.BranchError;
import io.branch.referral.util.BRANCH_STANDARD_EVENT;
import io.branch.referral.util.BranchContentSchema;
import io.branch.referral.util.BranchEvent;
import io.branch.referral.util.ContentMetadata;
import io.flutter.app.FlutterActivity;
import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.razorpay.Checkout;
import com.razorpay.PaymentData;
import com.razorpay.PaymentResultWithDataListener;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import androidx.annotation.NonNull;

import com.google.android.gms.ads.identifier.AdvertisingIdClient;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesNotAvailableException;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.GooglePlayServicesRepairableException;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;
import com.google.firebase.messaging.FirebaseMessaging;

import java.io.IOException;
import java.util.function.Function;
import com.webengage.sdk.android.WebEngageConfig;
import com.webengage.sdk.android.WebEngageActivityLifeCycleCallbacks;
import com.webengage.sdk.android.WebEngage;

import com.webengage.sdk.android.Analytics;
import com.webengage.sdk.android.User;
import com.webengage.sdk.android.actions.render.InAppNotificationData;
import com.webengage.sdk.android.actions.render.PushNotificationData;
import com.webengage.sdk.android.utils.Gender;
import com.paynimo.android.payment.PaymentActivity;
import com.paynimo.android.payment.PaymentModesActivity;
import com.paynimo.android.payment.util.Constant;
import com.webengage.sdk.android.callbacks.InAppNotificationCallbacks;
import com.webengage.sdk.android.callbacks.PushNotificationCallbacks;

public class MainActivity extends FlutterActivity implements PaymentResultWithDataListener ,PushNotificationCallbacks, InAppNotificationCallbacks{
    private static final String BRANCH_IO_CHANNEL = "com.algorin.pf.branch";
    private static final String RAZORPAY_IO_CHANNEL = "com.algorin.pf.razorpay";
    private static final String PF_FCM_CHANNEL = "com.algorin.pf.fcm";
    private static final String BROWSER_LAUNCH_CHANNEL = "com.algorin.pf.browser";
    private static final String WEBENGAGE_CHANNEL = "com.algorin.pf.webengage";
    private static final String UTILS_CHANNEL = "com.algorin.pf.utils";
    private static final String SOCIAL_SHARE_CHANNEL="com.algorin.pf.socialshare";
    private static final String TECH_PROCESS_CHANNEL="com.algorin.pf.techprocess";
    public static Context applicationContext;
    private MethodChannel.Result deepLinkingDataObjectResult;


    MyHelperClass myHeperClass;
    String firebaseToken = "";
    String installReferring_link = "";
    JSONObject installParams;
    String refCodeFromBranch = "";
    String googleAdId = "";
    private Analytics weAnalytics;
    private User weUser;
    Function callback;
    boolean bBranchLodead = false;
    private String indusosPostResult;
    private boolean bActivateIndiusOSAttribution=false;
    Map<String, Object> deepLinkingDataObject;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        applicationContext=getApplicationContext();
        deepLinkingDataObject = new HashMap();
        deepLinkingDataObject.put("activateDeepLinkingNavigation",false);
        initPushNotifications();
        fetchAdvertisingID(this);
        GeneratedPluginRegistrant.registerWith(this);
        initFlutterChannels();
        initWebEngage();

    }

    @Override
    public void onStart() {
        super.onStart();

        if(bActivateIndiusOSAttribution){
            initIndusOSBranchAttribution();
            /*For indus OS branch attribution call the async call first and then init the branch plugin*/
        }else{
            initBranchPlugin();
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    public PushNotificationData onPushNotificationReceived(Context context, PushNotificationData notificationData) {
        return notificationData;
    }

    @Override
    public void onPushNotificationShown(Context context, PushNotificationData notificationData) {
    }

    @Override
    public boolean onPushNotificationClicked(Context context, PushNotificationData notificationData) {
        // try {
        //     Gson gson = new Gson();
        //     String customData = gson.toJson(notificationData.getCustomData());
        //     JSONObject cusTomeDataJson = new JSONObject(customData);
        //     String enableDeepLinking = cusTomeDataJson.getJSONObject("mMap").getString("enableDeepLinking");
        //     String disableDeepLinking_android = cusTomeDataJson.getJSONObject("mMap").getString("disableDeepLinking_android");
        //     String dLR_page = cusTomeDataJson.getJSONObject("mMap").getString("dLR_page");
        //     String dLR_matchID = cusTomeDataJson.getJSONObject("mMap").getString("dLR_matchID");
        // } catch (JSONException e) {
        //     System.out.println(e);
        // }
        return false;
    }

    @Override
    public boolean onPushNotificationActionClicked(Context context, PushNotificationData notificationData, String buttonID) {
        return false;
    }

    @Override
    public void onPushNotificationDismissed(Context context, PushNotificationData notificationData) {
    }

    @Override
    public InAppNotificationData onInAppNotificationPrepared(Context context, InAppNotificationData notificationData) {
        return notificationData;
    }

    @Override
    public void onInAppNotificationShown(Context context, InAppNotificationData notificationData) {

    }

    @Override
    public void onInAppNotificationDismissed(Context context, InAppNotificationData notificationData) {

    }

    @Override
    public boolean onInAppNotificationClicked(Context context, InAppNotificationData notificationData, String actionId) {
        return false;
    }

    private void initIndusOSBranchAttribution(){
        if (!getSharedPreferences("branch", 0).getBoolean("branchTrackUrlHit", false)) {
            IndusOSAttribution runner = new IndusOSAttribution();
            runner.execute();
        }else {
            initBranchPlugin();
        }
    }


    private void initWebEngage() {
        WebEngageConfig webEngageConfig = new WebEngageConfig.Builder().setWebEngageKey("~47b65866")
                .setDebugMode(true)
                .setPushSmallIcon(R.drawable.notification_icon_small)
                .setPushAccentColor(Color.parseColor("#d32518"))
                .build();
        this.getApplication()
                .registerActivityLifecycleCallbacks(new WebEngageActivityLifeCycleCallbacks(this, webEngageConfig));
        FlutterApplication flutterApplication = new FlutterApplication();
        BranchClass branchClass =new BranchClass();
        flutterApplication.registerActivityLifecycleCallbacks(new WebEngageActivityLifeCycleCallbacks(flutterApplication, webEngageConfig));
        branchClass.registerActivityLifecycleCallbacks(new WebEngageActivityLifeCycleCallbacks(branchClass, webEngageConfig));
        weAnalytics = WebEngage.get().analytics();
        weUser = WebEngage.get().user();

    }

    private void initBranchPlugin() {
        final Intent intent = getIntent();
        try {
            Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
                @Override
                public void onInitFinished(JSONObject referringParams, BranchError error) {
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                    bBranchLodead = true;

                    if (error == null) {
                        initBranchSession(referringParams);
                        Log.i("BRANCH SDK", referringParams.toString());

                    } else {
                        initBranchSession(referringParams);
                        Log.i("BRANCH SDK", error.getMessage());
                    }
                }
            }, intent.getData(), this);
        } catch (Exception e) {
            initBranchSession(null);
        }
    }

    private void getBranchData(MethodChannel.Result result) {
        final Intent intent = getIntent();
        try {
            Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
                @Override
                public void onInitFinished(JSONObject referringParams, BranchError error) {
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                    Map<String, String> object;
                    if (error == null) {
                        object = initBranchSession(referringParams);
                        Log.i("BRANCH SDK", referringParams.toString());
                    } else {
                        object = initBranchSession(referringParams);
                        Log.i("BRANCH SDK", error.getMessage());
                    }
                    result.success(object);
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                }
            }, intent.getData(), this);
        } catch (Exception e) {
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            Log.i("BRANCH SDK", e.getMessage());

            Map<String, String> object = initBranchSession(null);
            result.success(object);
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
        }
    }

    private Map<String, String> initBranchSession(JSONObject referringParams) {
        JSONObject installParams = Branch.getInstance().getFirstReferringParams();
        JSONObject sessionParams = Branch.getInstance().getLatestReferringParams();
        setDeepLinkingBranchData(referringParams);
        setDeepLinkingBranchData(sessionParams);
        Map<String, String> object = new HashMap();
        String refCodeFromBranchTrail0 = "";
        String refCodeFromBranchTrail1 = "";
        String refCodeFromBranchTrail2 = "";
        String installReferring_link0 = "";
        String installReferring_link1 = "";
        String installReferring_link2 = "";
        try {
            myHeperClass = new MyHelperClass();

            if (referringParams != null) {
                installReferring_link0 = (String) referringParams.get("~referring_link");
                Log.i("BRANCH SDK link1", installReferring_link0);
                refCodeFromBranchTrail0 = myHeperClass.getQueryParmValueFromUrl(installReferring_link0, "refCode");
            }
        } catch (Exception e) {
        }

        try {
            installReferring_link1 = (String) installParams.get("~referring_link");
            Log.i("BRANCH SDK link1", installReferring_link1);
            refCodeFromBranchTrail1 = myHeperClass.getQueryParmValueFromUrl(installReferring_link1, "refCode");
        } catch (Exception e) {
        }

        try {
            installReferring_link2 = (String) sessionParams.get("~referring_link");
            Log.i("BRANCH SDK link1", installReferring_link2);
            refCodeFromBranchTrail2 = myHeperClass.getQueryParmValueFromUrl(installReferring_link2, "refCode");
        } catch (Exception e) {
        }

        if (refCodeFromBranchTrail0 != null && refCodeFromBranchTrail0.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail0;
        } else if (refCodeFromBranchTrail1 != null && refCodeFromBranchTrail1.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail1;
        } else {
            refCodeFromBranch = refCodeFromBranchTrail2;
        }

        if (installReferring_link0 != null && installReferring_link0 != "") {
            installReferring_link = installReferring_link0;
            Log.i("BRANCH SDK link0", installReferring_link0);
        } else if (installReferring_link1 != null && installReferring_link1 != "") {
            installReferring_link = installReferring_link1;
            Log.i("BRANCH SDK link1", installReferring_link1);
        } else if (installReferring_link2 != null && installReferring_link2 != "") {
            installReferring_link = installReferring_link2;
            Log.i("BRANCH SDK link2", installReferring_link2);
        }

        object.put("installReferring_link", installReferring_link);
        object.put("refCodeFromBranch", refCodeFromBranch);
        Log.i("BRANCH SDK", ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        return object;
    }

    @Override
    public void onNewIntent(Intent intent) {
        this.setIntent(intent);
    }


    private void setDeepLinkingBranchData(JSONObject referringParams ) {
        String dl_page_route = referringParams.optString("dl_page_route", "");
        String dl_leagueId = referringParams.optString("dl_leagueId", "");
        String dl_ac_promocode = referringParams.optString("dl_ac_promocode", "");
        String dl_ac_promoamount = referringParams.optString("dl_ac_promoamount", "");
        String dl_sp_pageLocation = referringParams.optString("dl_sp_pageLocation", "");
        String dl_sp_pageTitle = referringParams.optString("dl_sp_pageTitle", "");
        String dl_sport_type = referringParams.optString("dl_sport_type", "0");

        if (dl_page_route.length() > 2) {
            deepLinkingDataObject.put("activateDeepLinkingNavigation", true);
            deepLinkingDataObject.put("dl_page_route", dl_page_route);
            deepLinkingDataObject.put("dl_leagueId", dl_leagueId);
            deepLinkingDataObject.put("dl_ac_promocode", dl_ac_promocode);
            deepLinkingDataObject.put("dl_ac_promoamount", dl_ac_promoamount);
            deepLinkingDataObject.put("dl_sp_pageLocation", dl_sp_pageLocation);
            deepLinkingDataObject.put("dl_sp_pageTitle", dl_sp_pageTitle);
            deepLinkingDataObject.put("dl_sport_type", dl_sport_type);
        }
    }


    private void  deepLinkingRoutingHandler(){
        deepLinkingDataObjectResult.success(deepLinkingDataObject);
    }

    protected void initFlutterChannels() {
        new MethodChannel(getFlutterView(), BRANCH_IO_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method.equals("_getBranchRefCode")) {
                            String pfRefCode = (String) getRefCodeUsingBranch();
                            result.success(pfRefCode);
                        }
                        if (methodCall.method.equals("_initBranchIoPlugin")) {
                            if (bBranchLodead) {
                                Map<String, String> object = new HashMap();
                                String pfRefCode = (String) getRefCodeUsingBranch();
                                String installReferring_link = (String) getInstallReferringLink();
                                object.put("installReferring_link", installReferring_link);
                                object.put("refCodeFromBranch", pfRefCode);

                                result.success(object.toString());
                            } else {
                                getBranchData(result);
                            }

                        }
                        if (methodCall.method.equals("_getInstallReferringLink")) {
                            String installReferring_link = (String) getInstallReferringLink();
                            result.success(installReferring_link);
                        }
                        if (methodCall.method.equals("_getInstallReferringLink")) {
                            String installReferring_link = (String) getInstallReferringLink();
                            result.success(installReferring_link);
                        }
                        if (methodCall.method.equals("trackAndSetBranchUserIdentity")) {
                            String userId = methodCall.arguments();
                            trackAndSetBranchUserIdentity(userId);
                            result.success("Branch Io user Identity added ");
                        }
                        if (methodCall.method.equals("branchUserLogout")) {
                            branchUserLogout();
                            result.success("Branch Io user Logout done");
                        }

                        if (methodCall.method.equals("setBranchUniversalObject")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            setBranchUniversalObject(arguments);
                            result.success("Branch Io Universal Object added");
                        }
                        if (methodCall.method.equals("branchLifecycleEventSigniup")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = branchLifecycleEventSigniup(arguments);
                            result.success(channelResult);
                        }
                        if (methodCall.method.equals("branchEventInitPurchase")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = branchEventInitPurchase(arguments);
                            result.success(channelResult);
                        }
                        if (methodCall.method.equals("branchEventTransactionFailed")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = branchEventTransactionFailed(arguments);
                            result.success(channelResult);
                        }
                        if (methodCall.method.equals("branchEventTransactionSuccess")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = branchEventTransactionSuccess(arguments);
                            result.success(channelResult);
                        }

                        if (methodCall.method.equals("_getGoogleAddId")) {
                            String googleAddId = (String) getGoogleAddId();
                            result.success(googleAddId);
                        }
                        if (methodCall.method.equals("_getAndroidDeviceInfo")) {
                            Map<String, Object> deviceInfo = getDeviceInfo();
                            result.success(deviceInfo);
                        }
                    }
                });
        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method.equals("_openRazorpayNative")) {
                            Map<String, Object> arguments = methodCall.arguments();
                           startPayment(arguments);
                            String razocode = "testrazo";
                            result.success(razocode);

                        } else {
                            result.notImplemented();
                        }

                    }
                });

        new MethodChannel(getFlutterView(), TECH_PROCESS_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method.equals("_openTechProcessNative")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            initTechProcessPayment(arguments);
                            String razocode = "testrazo";
                            result.success(razocode);

                        } else {
                            result.notImplemented();
                        }
                        }});

        new MethodChannel(getFlutterView(), PF_FCM_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("_getFirebaseToken")) {
                    String firebaseToken = getFireBaseToken();
                    result.success(firebaseToken);
                } else if (methodCall.method.equals("_subscribeToFirebaseTopic")) {
                    String fcmTopic = methodCall.arguments();
                    subscribeToFirebaseTopic(fcmTopic);
                    result.success("Subscribed to PF fcm topic" + fcmTopic);
                } else {
                    result.notImplemented();
                }

            }
        });

        new MethodChannel(getFlutterView(), BROWSER_LAUNCH_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method.equals("launchInBrowser")) {
                            String linkUrl = methodCall.arguments();
                            Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(linkUrl));
                            startActivity(browserIntent);
                        } else {
                            result.notImplemented();
                        }
                    }
                });
        new MethodChannel(getFlutterView(), WEBENGAGE_CHANNEL)
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {

                        if (methodCall.method.equals("webEngageEventSigniup")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webEngageEventSigniup(arguments);
                            result.success(channelResult);
                        }

                        if (methodCall.method.equals("webEngageEventLogin")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webEngageEventLogin(arguments);
                            result.success(channelResult);
                        }

                        if (methodCall.method.equals("webEngageTransactionFailed")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webEngageTransactionFailed(arguments);
                            result.success(channelResult);
                        }
                        if (methodCall.method.equals("webEngageTransactionSuccess")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webEngageTransactionSuccess(arguments);
                            result.success(channelResult);
                        } else if (methodCall.method.equals("webengageTrackUser")) {
                            Map<String, String> arguments = methodCall.arguments();
                            String channelResult = webengageTrackUser(arguments);
                            result.success(channelResult);
                        } else if (methodCall.method.equals("webengageCustomAttributeTrackUser")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webengageCustomAttributeTrackUser(arguments);
                            result.success(channelResult);
                        } else if (methodCall.method.equals("webengageTrackEvent")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webengageTrackEvent(arguments);
                            result.success(channelResult);
                        } else if (methodCall.method.equals("trackEventsWithAttributes")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = trackEventsWithAttributes(arguments);
                            result.success(channelResult);
                        } else if (methodCall.method.equals("webengageAddScreenData")) {
                            Map<String, Object> arguments = methodCall.arguments();
                            String channelResult = webengageAddScreenData(arguments);
                            result.success(channelResult);
                        } else {
                            result.notImplemented();
                        }

                    }
                });

        new MethodChannel(getFlutterView(), UTILS_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("deleteInternalStorageFile")) {
                    AsyncTask.execute(new Runnable() {
                        @Override
                        public void run() {
                            String filename = methodCall.arguments();
                            try {
                                deleteIfFileExist(filename);
                            } catch (Exception e) {
                            }
                            try {
                                File internalFileDirectory = new File(
                                        Environment.getExternalStorageDirectory().getPath());
                                deleteFileRecursive(internalFileDirectory, filename);
                            } catch (Exception e) {
                                System.out.print(e);
                            }
                        }
                    });
                } else if ( methodCall.method.equals("onUserInfoRefreshed")) {
                    Map<String, Object> arguments = methodCall.arguments();
                    onUserInfoRefreshed(arguments);
                } else if (methodCall.method.equals("_deepLinkingRoutingHandler")) {
                    deepLinkingDataObjectResult =result;
                    deepLinkingRoutingHandler();

                } else {
                    result.notImplemented();
                }
            }
        });

        new MethodChannel(getFlutterView(), SOCIAL_SHARE_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("initSocialShareChannel")) {
                    result.success("Social Share init success");
                }
                else if(methodCall.method.equals("shareText")) {
                    String message = methodCall.arguments();
                    inviteFriend(message);
                    result.success("Social Share init success");
                }
                else if(methodCall.method.equals("shareViaFacebook")) {
                    String message = methodCall.arguments();
                    inviteFriendViaFacebook(message);
                    result.success("Social Share init success");
                }else if(methodCall.method.equals("shareViaWhatsApp")) {
                    String message = methodCall.arguments();
                    inviteFriendViaWhatsapp(message);
                    result.success("Social Share init success");
                }
                else if(methodCall.method.equals("shareViaGmail")) {
                    String message = methodCall.arguments();
                    inviteFriendViaGmail(message);
                    result.success("Social Share init success");
                }
                else  {
                    result.success("Social Share init success");
                }
            }
        });



    }


    private String onUserInfoRefreshed(Map<String, Object> arguments){
       
        if(arguments.get("first_name") != null && ((String) arguments.get("first_name")).length()>0){
            weUser.setFirstName((String)arguments.get("first_name"));
            weUser.setAttribute("first_name", (String)arguments.get("first_name"));
        }
        if(arguments.get("email") != null && ((String) arguments.get("email")).length()>0){
            weUser.setHashedEmail((String)arguments.get("email"));

        }
        if(arguments.get("mobile") != null && ((String) arguments.get("mobile")).length()>0){
            weUser.setHashedPhoneNumber((String)arguments.get("mobile"));

        }
        if(arguments.get("lastName") != null && ((String) arguments.get("lastName")).length()>0){
            weUser.setLastName((String)arguments.get("lastName"));
            weUser.setAttribute("last_name", (String)arguments.get("lastName"));
        }
        if(arguments.get("login_name") != null && ((String) arguments.get("login_name")).length()>0){
            weUser.setAttribute("userName", (String)arguments.get("login_name"));
        }
        if(arguments.get("channelId") != null && ((String) arguments.get("channelId")).length()>0){
            weUser.setAttribute("channelId", (String)arguments.get("channelId"));
        }
        if(arguments.get("withdrawable") != null && (arguments.get("withdrawable")).toString().length()>0){
            double withdrawable =new Double(arguments.get("withdrawable").toString());
            weUser.setAttribute("withdrawable",Math.round(withdrawable * 100.0) / 100.0 );
        }
        if(arguments.get("depositBucket") != null && (arguments.get("depositBucket")).toString().length()>0){
            double depositBucket = new Double(arguments.get("depositBucket").toString());
            weUser.setAttribute("depositBucket",  Math.round(depositBucket * 100.0) / 100.0 );
        }
        if(arguments.get("nonWithdrawable") != null && (arguments.get("nonWithdrawable")).toString().length()>0){
            double nonWithdrawable = new Double(arguments.get("nonWithdrawable").toString());
            weUser.setAttribute("nonWithdrawable", Math.round(nonWithdrawable * 100.0) / 100.0  );
        }
        if(arguments.get("nonPlayableBucket") != null && (arguments.get("nonPlayableBucket")).toString().length()>0){
            double nonPlayableBucket= new Double(arguments.get("nonPlayableBucket").toString());
            weUser.setAttribute("nonPlayableBucket", Math.round(nonPlayableBucket * 100.0) / 100.0);
        }
        if(arguments.get("pan_verification") != null && ((String) arguments.get("pan_verification")).length()>0){
            if(arguments.get("pan_verification").toString().equals("DOC_NOT_SUBMITTED")){
                weUser.setAttribute("idProofStatus", 0);
            }
            else if(arguments.get("pan_verification").toString().equals("DOC_SUBMITTED")){
                weUser.setAttribute("idProofStatus", 1);
            }
            else if(arguments.get("pan_verification").toString().equals("UNDER_REVIEW")){
                weUser.setAttribute("idProofStatus", 2);
            }
            else if(arguments.get("pan_verification").toString().equals("DOC_REJECTED")){
                weUser.setAttribute("idProofStatus", 3);

            }else if(arguments.get("pan_verification").toString().equals("VERIFIED")){
                weUser.setAttribute("idProofStatus", 4);
            }
        }
        if(arguments.get("mobile_verification") != null){
            weUser.setAttribute("mobileVerified", (boolean)arguments.get("mobile_verification"));
        }
        if(arguments.get("address_verification") != null && ((String) arguments.get("address_verification")).length()>0){
            if(arguments.get("address_verification").toString().equals("DOC_NOT_SUBMITTED")){
                weUser.setAttribute("addressProofStatus", 0);
            }
            else if(arguments.get("address_verification").toString().equals("DOC_SUBMITTED")){
                weUser.setAttribute("addressProofStatus", 1);
            }
            else if(arguments.get("address_verification").toString().equals("UNDER_REVIEW")){
                weUser.setAttribute("addressProofStatus", 2);
            }
            else if(arguments.get("address_verification").toString().equals("DOC_REJECTED")){
                weUser.setAttribute("addressProofStatus", 3);
            }else if(arguments.get("address_verification").toString().equals("VERIFIED")){
                weUser.setAttribute("addressProofStatus", 4);
            }
        }
        if(arguments.get("email_verification") != null){
            weUser.setAttribute("emailVerified", (boolean)arguments.get("email_verification"));
        }
        if(arguments.get("dob") != null&& ((String) arguments.get("dob")).length()>0){
            weUser.setBirthDate((String)arguments.get("dob"));
        }
        if(arguments.get("state") != null&& ((String) arguments.get("state")).length()>0){
            weUser.setAttribute("State", (String) arguments.get("state"));
        }
        if(arguments.get("user_balance_webengage") != null){
            double user_balance_webengage = new Double(arguments.get("user_balance_webengage").toString());
            weUser.setAttribute("balance",Math.round(user_balance_webengage * 100.0) / 100.0 );
        }
        if(arguments.get("accountStatus") != null){
            weUser.setAttribute("accountStatus",arguments.get("accountStatus").toString() );
        }
        
        return "Refreshed user Date is used";

    }

    /**************** Web Engage Stuff ***************/
    private String webengageTrackUser(Map<String, String> arguments) {
        String trackType = arguments.get("trackingType");
        switch (trackType) {
        case "login":
            weUser.login(arguments.get("value"));
            return "Login Track added";
        case "logout":
            weUser.logout();
            return "Logout To Tracking event done";
        case "setEmail":
            weUser.setHashedEmail(arguments.get("value"));
            return "Email track   added";
        case "setBirthDate":
            weUser.setBirthDate(arguments.get("value"));
            return "Birth Day track added";
        case "setPhoneNumber":
            weUser.setHashedPhoneNumber(arguments.get("value"));
            return "Phone Number track added";
        case "setFirstName":
            weUser.setFirstName(arguments.get("value"));
            return "Login Track added";
        case "setGender":
            String gendel = arguments.get("value");
            if (gendel == "male") {
                weUser.setGender(Gender.MALE);
            } else if (gendel == "female") {
                weUser.setGender(Gender.FEMALE);
            } else {
                weUser.setGender(Gender.OTHER);
            }
            return "User Gender  added";
        case "setLastName":
            weUser.setLastName(arguments.get("value"));
            return "Last Name  Track added";
        default:
            return "No Such tracking type found ";
        }
    }

    private String webengageCustomAttributeTrackUser(Map<String, Object> arguments) {
        String trackType = (String) arguments.get("trackingType");
        String value = (String) arguments.get("value");
        weUser.setAttribute(trackType, value);
        return "User " + trackType + " tracking added";
    }

    private String webengageTrackEvent(Map<String, Object> arguments) {
        /* Track Event without any Attributes */
        System.out.print((String) arguments.get("eventName"));
        String eventName = "" + (String) arguments.get("eventName");
        boolean priority = true;
        weAnalytics.track(eventName, new Analytics.Options().setHighReportingPriority(priority));
        return "Event " + eventName + "" + " added";
    }

    private String trackEventsWithAttributes(Map<String, Object> arguments) {
        /* Track Event with Attributes */
        String eventName = (String) arguments.get("eventName");
        boolean priority = true;
        Map<String, Object> addedAttributes = new HashMap<>();
        addedAttributes = (Map) arguments.get("data");
        weAnalytics.track(eventName, addedAttributes, new Analytics.Options().setHighReportingPriority(priority));
        return "Event " + eventName + "" + "added";
    }

    private String webengageAddScreenData(Map<String, Object> arguments) {
        System.out.println(arguments);
        System.out.println(arguments);

        String screenName = (String) arguments.get("screenName");
        Map<String, Object> addedAttributes = new HashMap<>();
        addedAttributes = (Map) arguments.get("data");
        weAnalytics.screenNavigated(screenName, addedAttributes);
        return "Screen Data added for the screen " + screenName;
    }

    private String webEngageEventSigniup(Map<String, Object> arguments) {

        Map<String, Object> addCustomDataProperty = new HashMap<>();
        HashMap<String, Object> data = new HashMap();
        String email = (String) arguments.get("email");
        String phone = (String) arguments.get("phone");

        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            addCustomDataProperty.put(entry.getKey(), "" + entry.getValue());
        }

        weAnalytics.track("COMPLETE_REGISTRATION", addCustomDataProperty);

        if (email != null && email.length() > 3) {
            weUser.setHashedEmail(email);
            System.out.println(email);
        }

        if (phone != null && phone.length() > 3) {
            weUser.setHashedPhoneNumber(phone);

        }

        System.out.print((String) arguments.get("chosenloginTypeByUser"));
        weUser.setAttribute("loginType", (String) arguments.get("chosenloginTypeByUser"));

        return "Web engage Sign Up Track event added";

    }

    private String webEngageEventLogin(Map<String, Object> arguments) {
        Map<String, Object> addCustomDataProperty = new HashMap<>();
        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");
        String email = (String) arguments.get("email");
        String phone = (String) arguments.get("phone");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            addCustomDataProperty.put(entry.getKey(), "" + entry.getValue());
        }
        weAnalytics.track("COMPLETE_LOGIN", addCustomDataProperty);

        weUser.setAttribute("loginType", "" + (String) arguments.get("loginType"));

        System.out.print(phone);

        if (email != null && email.length() > 3) {
            weUser.setHashedEmail(email);
            System.out.println(email);
        }
        if (phone != null && phone.length() > 3) {
            weUser.setHashedPhoneNumber(phone);
        }
        if (data.get("first_name") != null) {
            weUser.setFirstName((String) data.get("first_name"));
        }
        if (data.get("last_name") != null) {
            weUser.setLastName((String) data.get("last_name"));
        }
        weUser.setAttribute("loginType", (String) arguments.get("chosenloginTypeByUser"));
        return "Web engage Login Track event added";

    }

    private String webEngageTransactionFailed(Map<String, Object> arguments) {

        boolean isfirstDepositor = false;
        String eventName = "FIRST_DEPOSIT_FAILED";
        isfirstDepositor = Boolean.parseBoolean("" + arguments.get("firstDepositor"));
        if (!isfirstDepositor) {
            eventName = "REPEAT_DEPOSIT_FAILED";
        }

        Map<String, Object> addCustomDataProperty = new HashMap<>();
        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            addCustomDataProperty.put(entry.getKey(), "" + entry.getValue());
        }

        weAnalytics.track(eventName, addCustomDataProperty);
        return " Add Cash Failed Event added";

    }

    private String webEngageTransactionSuccess(Map<String, Object> arguments) {
        boolean isfirstDepositor = false;
        String eventName = "DEPOSIT_SUCCESS";
        isfirstDepositor = Boolean.parseBoolean("" + arguments.get("firstDepositor"));
        if (!isfirstDepositor) {
            eventName = "DEPOSIT_SUCCESS";
        }
        Map<String, Object> addCustomDataProperty = new HashMap<>();
        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            addCustomDataProperty.put(entry.getKey(), "" + entry.getValue());
        }
        weAnalytics.track(eventName, addCustomDataProperty);
        return " Add Cash Success Event added";

    }

    /* Bracnch Io related code */
    public String getRefCodeUsingBranch() {
        return refCodeFromBranch;
    }

    private Map<String, String> getBranchQueryParms() {
        myHeperClass = new MyHelperClass();
        Map<String, String> branchQueryParms = new HashMap<String, String>();
        JSONObject installParams = Branch.getInstance().getFirstReferringParams();
        String installReferring_link = "";
        String installAndroid_link = "";

        try {
            installReferring_link = (String) installParams.get("~referring_link");
            branchQueryParms.put("installReferring_link", installReferring_link);

        } catch (Exception e) {

        }
        try {
            installAndroid_link = (String) installParams.get("$android_url");
            branchQueryParms.put("installAndroid_link", installAndroid_link);
        } catch (Exception e) {

        }
        return branchQueryParms;
    }

    public String getInstallReferringLink() {
        Log.i("BRANCH SDK link2", installReferring_link);
        return installReferring_link;
    }

    private void trackAndSetBranchUserIdentity(String userId) {
        Branch.getInstance().setIdentity(userId);
    }

    private void branchUserLogout() {
        Branch.getInstance().logout();
    }

    private void setBranchUniversalObject(Map<String, Object> arguments) {
        BranchUniversalObject buo = new BranchUniversalObject()
                .setCanonicalIdentifier((String) arguments.get("canonicalIdentifier"))
                .setTitle((String) arguments.get("title"))
                .setContentDescription((String) arguments.get("contentDescription"))
                .setContentImageUrl((String) arguments.get("contentImageUrl"));

        buo.setContentIndexingMode(BranchUniversalObject.CONTENT_INDEX_MODE.PUBLIC);
        buo.setLocalIndexMode(BranchUniversalObject.CONTENT_INDEX_MODE.PUBLIC);

        buo.setContentMetadata(new ContentMetadata().addCustomMetadata("custom_metadata_key1", "custom_metadata_val1")
                .addCustomMetadata("custom_metadata_key1", "custom_metadata_val1")

                .setContentSchema(BranchContentSchema.COMMERCE_PRODUCT)).addKeyWord("keyword1").addKeyWord("keyword2");
    }

    private String branchLifecycleEventSigniup(Map<String, Object> arguments) {
        BranchEvent be = new BranchEvent(BRANCH_STANDARD_EVENT.COMPLETE_REGISTRATION)
                .setTransactionID("" + arguments.get("transactionID")).setDescription("HOWZAT SIGN UP");
        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {

            be.addCustomDataProperty((String) entry.getKey(), "" + entry.getValue());
        }
        be.logEvent(MainActivity.this);
        return "Sign Up Track event added";

    }

    private String branchEventTransactionFailed(Map<String, Object> arguments) {

        boolean isfirstDepositor = false;
        String eventName = "FIRST_DEPOSIT_FAILED";
        isfirstDepositor = Boolean.parseBoolean("" + arguments.get("firstDepositor"));
        if (!isfirstDepositor) {
            eventName = "REPEAT_DEPOSIT_FAILED";
        }

        BranchEvent be = new BranchEvent(eventName).setTransactionID("" + arguments.get("txnId"))
                .setDescription(("HOWZAT DEPOSIT FAILED"));
        be.addCustomDataProperty("txnTime", "" + arguments.get("txnTime"));
        be.addCustomDataProperty("txnDate", "" + arguments.get("txnDate"));
        be.addCustomDataProperty("appPage", "" + arguments.get("appPage"));

        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            be.addCustomDataProperty(entry.getKey(), "" + entry.getValue());
        }
        be.logEvent(MainActivity.this);

        return " Add Cash Failed Event added";

    }

    private String branchEventTransactionSuccess(Map<String, Object> arguments) {
        boolean isfirstDepositor = false;
        String eventName = "FIRST_DEPOSIT_SUCCESS";
        isfirstDepositor = Boolean.parseBoolean("" + arguments.get("firstDepositor"));
        if (!isfirstDepositor) {
            eventName = "REPEAT_DEPOSIT_SUCCESS";
        }

        BranchEvent be = new BranchEvent(eventName).setTransactionID("" + arguments.get("txnId"))
                .setDescription("HOWZAT DEPOSIT FAILED");
        be.addCustomDataProperty("txnTime", "" + arguments.get("txnTime"));
        be.addCustomDataProperty("txnDate", "" + arguments.get("txnDate"));
        be.addCustomDataProperty("appPage", "" + arguments.get("appPage"));

        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {

            be.addCustomDataProperty(entry.getKey(), "" + entry.getValue());
        }

        be.logEvent(MainActivity.this);

        return " Add Cash Success Event added";

    }

    private String branchEventInitPurchase(Map<String, Object> arguments) {
        new BranchEvent(BRANCH_STANDARD_EVENT.INITIATE_PURCHASE)
                .setTransactionID((String) arguments.get("transactionID"))
                .setDescription((String) arguments.get("description")).addCustomDataProperty("registrationID", "12345")
                .logEvent(MainActivity.this);

        return "";
    }

    public void startPayment(Map<String, Object> arguments) {
        /*
         * You need to pass current activity in order to let Razorpay create
         * CheckoutActivity
         */
        final Activity activity = this;

        final Checkout co = new Checkout();

        try {
            JSONObject options = new JSONObject();
            options.put("name", (String) arguments.get("name"));
            options.put("description", "Add Cash");
            // You can omit the image option to fetch the image from dashboard
            options.put("image", (String) arguments.get("image"));
            options.put("currency", "INR");
            options.put("amount", (String) arguments.get("amount"));
            options.put("order_id", (String) arguments.get("orderId"));

            JSONObject preFill = new JSONObject();
            preFill.put("email", (String) arguments.get("email"));
            preFill.put("contact", (String) arguments.get("phone"));
            preFill.put("method", (String) arguments.get("method"));

            options.put("prefill", preFill);

            Log.d("options", options.toString());

            co.open(activity, options);
        } catch (Exception e) {
            Toast.makeText(activity, "Error in payment: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            e.printStackTrace();
        }
    }

    @SuppressWarnings("unused")
    @Override
    public void onPaymentSuccess(String razorpayPaymentID, PaymentData data) {
        try {
            onRazorPayPaymentSuccess(razorpayPaymentID, data);
        } catch (Exception e) {
        }
    }

    @SuppressWarnings("unused")
    @Override
    public void onPaymentError(int code, String response, PaymentData data) {
        try {
            Log.d("optionss", data.getData().toString());
            Log.d("optionss", response);
            onRazorPayPaymentFail(response, data);
        } catch (Exception e) {

        }
    }

    public void onRazorPayPaymentFail(String response, PaymentData data) {
        JSONObject object = new JSONObject();
        try {
            object.put("paymentId", data.getPaymentId());
            object.put("signature", data.getSignature());
            object.put("orderId", data.getOrderId());
            object.put("status", "failed");
        } catch (JSONException e) {

        }

        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentFail",
                object.toString(), new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                    }

                    @Override
                    public void notImplemented() {
                    }
                });
    }

    public void onRazorPayPaymentSuccess(String razorpayPaymentID, PaymentData data) {
        JSONObject object = new JSONObject();
        try {
            object.put("paymentId", data.getPaymentId());
            object.put("signature", data.getSignature());
            object.put("orderId", data.getOrderId());
            object.put("status", "paid");
        } catch (JSONException e) {

        }

        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentSuccess",
                object.toString(), new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                    }

                    @Override
                    public void notImplemented() {
                    }
                });
    }


    public void onTechProcessPaymentFail(Map<String, Object> arguments) {
        JSONObject object = new JSONObject();
        try {
            object.put("errorCode", (String)arguments.get("errorCode"));
            object.put("errorMessage",(String) arguments.get("errorMessage"));
            object.put("status", "failed");
        } catch (JSONException e) {

        }

        new MethodChannel(getFlutterView(), TECH_PROCESS_CHANNEL).invokeMethod("onTechProcessPaymentFail",
                object.toString(), new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {                       
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                    }

                    @Override
                    public void notImplemented() {
                    }
                });
    }

    public void onTechProcessPaymentSuccess(JSONObject  data) {
        new MethodChannel(getFlutterView(), TECH_PROCESS_CHANNEL).invokeMethod("onTechProcessPaymentSuccess",
                data.toString(), new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                        Log.d("TECHPROCESS",  "Success" );
                    }
                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("TECHPROCESS",  "Success" );
                    }
                    @Override
                    public void notImplemented() {
                        Log.d("TECHPROCESS",  "Success" );
                    }
                });
    }

    private void initTechProcessPayment(Map<String, Object> arguments){

        String email= (String) arguments.get("email");
        String phone = (String) arguments.get("phone");
        String amount_in_rupees= (String) arguments.get("amount");
        String date= (String) arguments.get("date");
        String orderId= (String) arguments.get("orderId");
        String paymentMethod=(String) arguments.get("method");
        String userId=(String) arguments.get("userId");
        String extra_public_key =(String) arguments.get("extra_public_key");
        boolean cardDataCapturingRequired =(boolean) arguments.get("cardDataCapturingRequired");
        /*Prepare a checkout object*/
        com.paynimo.android.payment.model.Checkout checkout = new com.paynimo.android.payment.model.Checkout();
        checkout.setMerchantIdentifier("T456537");
        checkout.setTransactionIdentifier(orderId);
        checkout.setTransactionReference (orderId);
        checkout.setTransactionType (PaymentActivity.TRANSACTION_TYPE_SALE);
        checkout.setTransactionSubType (PaymentActivity.TRANSACTION_SUBTYPE_DEBIT);
        checkout.setTransactionCurrency ("INR");
        checkout.setTransactionAmount (amount_in_rupees);
        checkout.setTransactionDateTime (date);
        /*User Info*/
        checkout.setConsumerIdentifier (userId);
        checkout.setConsumerEmailID (email);
        checkout.setConsumerMobileNumber (phone);
        checkout.setConsumerAccountNo (userId);

        checkout.addCartItem("FIRST",amount_in_rupees,"0.0", "0.0", "", "", "","");

        /**************** Auth Intent ****************/
        Intent authIntent = new Intent(this, PaymentModesActivity.class);
        authIntent.putExtra(PaymentActivity.EXTRA_PUBLIC_KEY, extra_public_key);

        if(paymentMethod.equals("netbanking")){
            authIntent.putExtra(PaymentActivity.EXTRA_REQUESTED_PAYMENT_MODE, PaymentActivity.PAYMENT_METHOD_NETBANKING);
        }else if(paymentMethod.equals("card")){
            
            if(cardDataCapturingRequired){
                String cardNo=(String) arguments.get("tp_cardNumber");
                String expiryMonth=(String) arguments.get("tp_expireMonth");
                String expiryYear=(String) arguments.get("tp_expireYear");
                String cvv=(String) arguments.get("tp_cvv");
                String nameOnCard=(String) arguments.get("tp_nameOnTheCard");
                /*Data Capturing Page at Merchant End For - New Card*/
                checkout.setPaymentInstrumentIdentifier(cardNo);
                checkout.setPaymentInstrumentExpiryMonth(expiryMonth);
                checkout.setPaymentInstrumentExpiryYear(expiryYear);
                checkout.setPaymentInstrumentVerificationCode(cvv);
                checkout.setPaymentInstrumentHolderName(nameOnCard);
                checkout.setTransactionIsRegistration("Y");
                checkout.setTransactionMerchantInitiated("Y");
                authIntent.putExtra(PaymentActivity.EXTRA_REQUESTED_PAYMENT_MODE, PaymentActivity.PAYMENT_METHOD_CARDS);
            }else{
                String cvv=(String) arguments.get("tp_cvv");
                String tp_instrumentToken=(String) arguments.get("tp_instrumentToken");
                checkout.setTransactionMerchantInitiated("N");
                checkout.setPaymentMethodToken("00000");
                checkout.setPaymentInstrumentToken(tp_instrumentToken);
                checkout.setPaymentInstrumentVerificationCode(cvv);
                authIntent.putExtra(PaymentActivity.EXTRA_REQUESTED_PAYMENT_MODE,
                        PaymentActivity.PAYMENT_METHOD_CARDS);
            }
        }
        else{
            authIntent.putExtra(PaymentActivity.EXTRA_REQUESTED_PAYMENT_MODE,
                    PaymentActivity.PAYMENT_METHOD_DEFAULT);
        }
        
        /*Now call the payment activity*/
        authIntent.putExtra(Constant.ARGUMENT_DATA_CHECKOUT, checkout);
        try{
            startActivityForResult(authIntent, PaymentActivity.REQUEST_CODE);
        }catch(Exception e){
            System.out.println(e.toString());
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PaymentActivity.REQUEST_CODE) {
            Log.d("TECHPROCESS", "Result Code :" +PaymentActivity.REQUEST_CODE );
            if (resultCode == PaymentActivity.RESULT_OK) {
                // PAyment  was successful
                Log.d("TECHPROCESS", "Result Code :" + RESULT_OK);
                if (data != null) {
                    Log.d("TECHPROCESS", "Data is not null");
                    try {
                        com.paynimo.android.payment.model.Checkout checkout_res = (com.paynimo.android.payment.model.Checkout) data.getSerializableExtra(Constant.ARGUMENT_DATA_CHECKOUT);
                        String transactionType = checkout_res.getMerchantRequestPayload().getTransaction().getType();
                        String transactionSubType = checkout_res.getMerchantRequestPayload().getTransaction().getSubType();

                        if (transactionType != null && transactionType.equalsIgnoreCase(PaymentActivity.TRANSACTION_TYPE_PREAUTH)
                                && transactionSubType != null && transactionSubType
                                .equalsIgnoreCase(PaymentActivity.TRANSACTION_SUBTYPE_RESERVE)){
                            Log.d("TECHPROCESS", "Transaction sub type is reserve");
                            // Transaction Completed and Got SUCCESS
                            if (checkout_res.getMerchantResponsePayload()
                                    .getPaymentMethod().getPaymentTransaction()
                                    .getStatusCode().equalsIgnoreCase(PaymentActivity.TRANSACTION_STATUS_PREAUTH_RESERVE_SUCCESS)) {

                                Log.d("TECHPROCESS", "Transaction Status Preauth");


                                if (checkout_res.getMerchantResponsePayload()
                                        .getPaymentMethod().getPaymentTransaction().getInstruction().getStatusCode().equalsIgnoreCase("")) {

                                    Log.d("TECHPROCESS", "Transaction sub type is reserve");

                                }

                            }

                            else {
                                /* some error from bank side*/
                                Log.d("TECHPROCESS", "Some error");

                                Log.d("Checkout Response Obj", checkout_res.getMerchantResponsePayload().toString());

                            }

                        } else {
                            /* Transaction Completed and Got SUCCESS*/
                            Log.d("TECHPROCESS", "Transaction sub type is reserve");
                            if (checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getStatusCode().equalsIgnoreCase(PaymentActivity.TRANSACTION_STATUS_SALES_DEBIT_SUCCESS)) {
                                Log.d("TECHPROCESS", "Transaction sub type is reserve");
                                if (checkout_res.getMerchantResponsePayload().
                                        getPaymentMethod().getPaymentTransaction().
                                        getInstruction().getId() != null && checkout_res.getMerchantResponsePayload().
                                        getPaymentMethod().getPaymentTransaction().
                                        getInstruction().getId().isEmpty()) {
                                    Log.v("TRANSACTION SI STATUS=>",
                                            checkout_res.getMerchantResponsePayload().toString());
                                    Log.v("TRANSACTION SI STATUS=>",
                                            checkout_res.getMerchantResponsePayload().toString());



                                } else if (checkout_res.getMerchantResponsePayload().
                                        getPaymentMethod().getPaymentTransaction().
                                        getInstruction().getId() != null && !checkout_res.getMerchantResponsePayload().
                                        getPaymentMethod().getPaymentTransaction().
                                        getInstruction().getId().isEmpty()) {

                                    Log.d("TECHPROCESS", "Transaction sub type is reserve");
                                }
                            }
                            else if (checkout_res
                                    .getMerchantResponsePayload().getPaymentMethod()			.getPaymentTransaction().getStatusCode().equalsIgnoreCase(
                                            PaymentActivity.TRANSACTION_STATUS_DIGITAL_MANDATE_SUCCESS
                                    )) {
                                Log.d("TECHPROCESS", "Transaction sub type is reserve");

                                if (checkout_res.getMerchantResponsePayload().
                                        getPaymentMethod().getPaymentTransaction().
                                        getInstruction().getId() != null
                                        && !checkout_res
                                        .getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getInstruction().getId().isEmpty()) {
                                    Log.d("TECHPROCESS", "Transaction sub type is reserve");

                                } else {

                                    Log.d("TECHPROCESS", "Transaction sub type is reserve");



                                }
                            }
                            else {

                                Log.d("TECHPROCESS", "Transaction sub type is reserve");

                            }
                            Log.d("TECHPROCESS", "Transaction sub type is reserve");

                        }

                        String statusCode=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getStatusCode();
                        String statusMessage =checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getStatusMessage();
                        String errorMessage = checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getErrorMessage();
                        String amount =checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getAmount();
                        String dateTime = checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getDateTime();
                        String merchantTransactionIdentifier=checkout_res.getMerchantResponsePayload().getMerchantTransactionIdentifier();
                        String identifier = checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getIdentifier() ;
                        String bankSelectionCode=checkout_res.getMerchantResponsePayload().getPaymentMethod().getBankSelectionCode();
                        String bankReferenceIdentifier=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getBankReferenceIdentifier();
                        String refundIdentifier=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getRefundIdentifier();
                        String balanceAmount= checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getBalanceAmount();
                        String instrumentAliasName=checkout_res.getMerchantResponsePayload().getPaymentMethod().getInstrumentAliasName();
                        String  instrumentToken=checkout_res.getMerchantResponsePayload().getPaymentMethod().getInstrumentToken();
                        String  SIMandateId=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getInstruction().getId();
                        String SIMandateStatus=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getInstruction().getStatusCode();
                        String  SIMandateErrorCode=checkout_res.getMerchantResponsePayload().getPaymentMethod().getPaymentTransaction().getInstruction().getErrorcode();
                        Log.d("TECHPROCESS", statusCode);
                        if(statusCode.equals("0300")){
                            Gson gson = new Gson();
                            String jsonString = gson.toJson(checkout_res.getMerchantResponsePayload());
                            try {
                                JSONObject request = new JSONObject(jsonString);
                                request.put("amount",amount);
                                request.put("orderId",merchantTransactionIdentifier);
                                request.put("status",1);
                                request.put("instrumentAliasName",instrumentAliasName);
                                request.put("instrumentToken",instrumentToken);
                                onTechProcessPaymentSuccess(request);

                            } catch (JSONException e) {
                                // TODO Auto-generated catch block
                                e.printStackTrace();
                            }
                        }else{

                            Map<String, Object> errorArguments =new HashMap();
                            errorArguments.put("errorCode",statusCode);
                            errorArguments.put("errorMessage","");
                            onTechProcessPaymentFail(errorArguments);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();                   
                    }

                }
            }
            else if (resultCode == PaymentActivity.RESULT_ERROR) {

                Log.d("Exception", "Error");
                if (data.hasExtra(PaymentActivity.RETURN_ERROR_CODE) &&
                        data.hasExtra(PaymentActivity.RETURN_ERROR_DESCRIPTION)) {

                    String error_code = (String) data
                            .getStringExtra(PaymentActivity.RETURN_ERROR_CODE);
                    Log.d("Exception", error_code);
                    String error_desc = (String) data
                            .getStringExtra(PaymentActivity.RETURN_ERROR_DESCRIPTION);

                    Map<String, Object> errorArguments =new HashMap();
                    errorArguments.put("errorCode","");
                    if(error_code.equals("ERROR_PAYNIMO_023")){
                        errorArguments.put("errorMessage","Enter valid card details");
                    }
                    else{
                        errorArguments.put("errorMessage"," ");
                    }
                    onTechProcessPaymentFail(errorArguments);

                }
            }
            else if (resultCode == PaymentActivity.RESULT_CANCELED) {

                Log.d("Exception", "Cancled");

                Map<String, Object> errorArguments =new HashMap();
                errorArguments.put("errorCode","");
                errorArguments.put("errorMessage","Payment cancled by user");
                onTechProcessPaymentFail(errorArguments);
                onTechProcessPaymentFail(errorArguments);

            }
        }
    }

    

    /* Firebase Push notification */
    public void initPushNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create channel to show notifications.
            String channelId = "fcm_default_channel";
            String channelName = "News";
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(
                    new NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW));
        }

        /*Handling deep linking Data*/
        Intent intent = getIntent();
        if (intent != null && intent.getExtras() != null) {
            Bundle extras = intent.getExtras();
            try{
                if (getIntent().getExtras() != null && getIntent().getExtras().containsKey("enableDeepLinking")) {
                    String enableDeepLinking= extras.getString("enableDeepLinking");

                    if(enableDeepLinking.equals("true")){
                        if(extras.containsKey("dl_page_route")){
                            String dl_page_route = extras.getString("dl_page_route");
                            if(dl_page_route.length()>2){
                                deepLinkingDataObject.put("activateDeepLinkingNavigation", true);
                                deepLinkingDataObject.put("dl_page_route", (String) extras.get("dl_page_route"));

                                if(extras.containsKey("dl_leagueId")){
                                    deepLinkingDataObject.put("dl_leagueId", (String) extras.get("dl_leagueId"));
                                }else{
                                    deepLinkingDataObject.put("dl_leagueId", "");
                                }
                                if(extras.containsKey("dl_ac_promocode")){
                                    deepLinkingDataObject.put("dl_ac_promocode", (String) extras.get("dl_ac_promocode"));
                                }else{
                                    deepLinkingDataObject.put("dl_ac_promocode", " ");
                                }
                                if(extras.containsKey("dl_ac_promoamount")){
                                    deepLinkingDataObject.put("dl_ac_promoamount", (String) extras.get("dl_ac_promoamount"));
                                }else{
                                    deepLinkingDataObject.put("dl_ac_promoamount", " ");
                                }

                                if(extras.containsKey("dl_sp_pageLocation")){
                                    deepLinkingDataObject.put("dl_sp_pageLocation", (String) extras.get("dl_ac_promoamount"));
                                }else{
                                    deepLinkingDataObject.put("dl_sp_pageLocation", " ");
                                }
                                if(extras.containsKey("dl_sp_pageTitle")){
                                    deepLinkingDataObject.put("dl_sp_pageTitle", (String) extras.get("dl_ac_promoamount"));
                                }else{
                                    deepLinkingDataObject.put("dl_sp_pageTitle", " ");
                                }

                                if(extras.containsKey("dl_sport_type")){
                                    deepLinkingDataObject.put("dl_sport_type", (String) extras.get("dl_sport_type"));
                                }else{
                                    deepLinkingDataObject.put("dl_sport_type", "0");
                                }
                                
                            }

                        }
                    }
                }
            } catch(Exception e){

            }
        }

        if (getIntent().getExtras() != null) {
            for (String key : getIntent().getExtras().keySet()) {
                Object value = getIntent().getExtras().get(key);
                // Log.d(TAG, "Key: " + key + " Value: " + value);
            }
        }

        String fmChannelName = "news";
        FirebaseMessaging.getInstance().subscribeToTopic(fmChannelName)
                .addOnCompleteListener(new OnCompleteListener<Void>() {
                    @Override
                    public void onComplete(@NonNull Task<Void> task) {
                        if (!task.isSuccessful()) {

                        }
                    }
                });
        FirebaseInstanceId.getInstance().getInstanceId()
                .addOnCompleteListener(new OnCompleteListener<InstanceIdResult>() {
                    @Override
                    public void onComplete(@NonNull Task<InstanceIdResult> task) {
                        if (!task.isSuccessful()) {
                            return;
                        }
                        String token = task.getResult().getToken();
                        firebaseToken = token;
                    }
                });
    }

    private String getFireBaseToken() {
        FirebaseInstanceId.getInstance().getInstanceId()
                .addOnCompleteListener(new OnCompleteListener<InstanceIdResult>() {
                    @Override
                    public void onComplete(@NonNull Task<InstanceIdResult> task) {
                        if (!task.isSuccessful()) {
                            return;
                        }
                        String token = task.getResult().getToken();
                        firebaseToken = token;
                        WebEngage.get().setRegistrationID(token);
                    }
                });
        return firebaseToken;
    }

    private void subscribeToFirebaseTopic(String topicName) {
        try {
            FirebaseMessaging.getInstance().subscribeToTopic(topicName);
        } catch (Exception e) {

        }

    }

    private void fetchAdvertisingID(final Activity current_activity) {
        GoogleApiAvailability googleAPI = GoogleApiAvailability.getInstance();
        if (googleAPI.isGooglePlayServicesAvailable(current_activity) == ConnectionResult.SUCCESS) {
            new Thread(new Runnable() {
                public void run() {
                    AdvertisingIdClient.Info adInfo = null;
                    try {
                        adInfo = AdvertisingIdClient.getAdvertisingIdInfo(current_activity);
                    } catch (IOException e) {
                        return;

                    } catch (GooglePlayServicesNotAvailableException e) {
                        return;

                    } catch (GooglePlayServicesRepairableException e) {
                        return;
                    }
                    String AdId = adInfo.getId();
                    setTheGoogleId(AdId);
                    boolean userOptOutAdTracking = adInfo.isLimitAdTrackingEnabled();

                    if (userOptOutAdTracking) {
                    } else {
                    }
                }
            }).start();
        } else {
        }
    }

    private void setTheGoogleId(String AdId) {
        googleAdId = AdId;
    }

    private String getGoogleAddId() {
        fetchAdvertisingID(this);
        return googleAdId;
    }

    void deleteFileRecursive(File fileOrDirectory, String fileName) {
        try {
            if (fileOrDirectory.isDirectory()) {
                if (fileOrDirectory.exists()) {
                    System.out.print(fileOrDirectory);
                    for (File child : fileOrDirectory.listFiles()) {
                        System.out.print(child);
                        deleteFileRecursive(child, fileName);

                    }
                }
            }

        } catch (Exception e) {
            System.out.print(e);
        }

        System.out.print(fileOrDirectory);

        try {
            if (fileOrDirectory.isFile()) {
                if (fileOrDirectory.getName().endsWith(fileName)) {
                    Boolean deleted = fileOrDirectory.delete();
                    System.out.print(deleted);
                }
            }

        } catch (Exception e) {

        }
    }

    public boolean deleteIfFileExist(String fname) {
        boolean deleted = false;
        try {
            File applictionFile = new File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS) + "/" + fname);

            if (applictionFile != null && applictionFile.exists()) {
                deleted = applictionFile.delete();
                System.out.print(deleted);
            }

        } catch (Exception e) {

        }
        return deleted;
    }


    private void  inviteFriend(String message){
        String shareMessage= message;
        try {
            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType("text/plain");
            shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage);
            startActivity(Intent.createChooser(shareIntent, "Share to"));
        } catch(Exception e) {
            //e.toString();
        }
    }

    private void  inviteFriendViaWhatsapp(String message){
        Intent whatsappIntent = new Intent(Intent.ACTION_SEND);
        whatsappIntent.setType("text/plain");
        whatsappIntent.setPackage("com.whatsapp");
        whatsappIntent.putExtra(Intent.EXTRA_TEXT, message);
        try {
            startActivity(whatsappIntent);
        } catch (android.content.ActivityNotFoundException ex) {
            inviteFriend(message);
        }
    }

    private void  inviteFriendViaFacebook(String message){
        Intent whatsappIntent = new Intent(Intent.ACTION_SEND);
        whatsappIntent.setType("text/plain");
        whatsappIntent.setPackage("com.facebook.katana");
        whatsappIntent.putExtra(Intent.EXTRA_TEXT, message);
        try {
            startActivity(whatsappIntent);
        } catch (android.content.ActivityNotFoundException ex) {
            inviteFriend(message);
        }
    }

    private void inviteFriendViaGmail(String message){
        String shareMessage= message;
        try {
            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType("text/plain");
            shareIntent.setPackage("com.google.android.gm");
            shareIntent.putExtra(Intent.EXTRA_TEXT, shareMessage);
            startActivity(Intent.createChooser(shareIntent, "Share to"));
        } catch(Exception e) {
            inviteFriend(message);
        }
    }

    private Map<String, Object> getDeviceInfo() {
        Map<String, Object> params = new HashMap<>();
        Map<String, String> emailList = new HashMap();
        final DeviceInfo deviceData = new DeviceInfo();
        final Map<String, String> deviceInfoList = deviceData.getDeviceInfoMap(this);
        try {
            params.put("versionCode", BuildConfig.VERSION_CODE);
            params.put("versionName", BuildConfig.VERSION_NAME);
            params.put("uid", deviceInfoList.get("device_ID"));
            params.put("model", deviceInfoList.get("model"));
            params.put("serial", deviceInfoList.get("android_Id"));
            params.put("manufacturer", deviceInfoList.get("manufacturer"));
            params.put("version", deviceInfoList.get("android_version"));
            params.put("network_operator", deviceInfoList.get("network_Operator"));
            params.put("packageName", deviceInfoList.get("packageName"));
            params.put("versionName", deviceInfoList.get("versionName"));
            params.put("baseRevisionCode", deviceInfoList.get("baseRevisionCode"));
            params.put("firstInstallTime", deviceInfoList.get("firstInstallTime"));
            params.put("lastUpdateTime", deviceInfoList.get("lastUpdateTime"));
            params.put("device_ip_", deviceInfoList.get("device_IPv4"));
            params.put("network_type", deviceData.getConnectionType(this));
            params.put("googleAdId", getGoogleAddId());
            List email = deviceData.getGoogleEmailList(this);
            int emailIndex = 1;
            for (Object s : email) {
                emailList.put("googleEmail" + emailIndex, s.toString());
                emailIndex++;
            }
            params.put("googleEmailList", emailList);
        } catch (Exception e) {

        }
        return params;
    }


    private class IndusOSAttribution extends AsyncTask<Void, Void, String> {
        String branch_tracking_url_indusos="https://11zy.app.link/howzat_indus?%243p=a_indus_os&%24aaid={aaid}";
        @Override
        protected String doInBackground(Void... params) {
            String retVal = "false";
            String advertId = null;
            try {
                advertId = AdvertisingIdClient.getAdvertisingIdInfo(applicationContext).getId();

            } catch (IOException |GooglePlayServicesNotAvailableException |GooglePlayServicesRepairableException e) {}
            String BRANCH_TRACK_URL = branch_tracking_url_indusos;

            String track_url = BRANCH_TRACK_URL.replace("{aaid}",advertId) + "&%24s2s=true";
            HttpURLConnection urlConnection = null;
            try {
                URL url = new URL(track_url);
                urlConnection = (HttpURLConnection) url.openConnection();
                BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
                StringBuilder result = new StringBuilder();
                String line ;
                while ((line = bufferedReader.readLine()) != null) {
                    result.append('\n').append(line);
                }
                String response = result.toString();
                bufferedReader.close();
                JSONObject object = new JSONObject(response);
                if(object.getBoolean("success")){
                    retVal = "true";
                };
            } catch (Exception e) {}
            finally {
                urlConnection.disconnect();
            }
            return retVal;
        }
        @Override
        protected void onPostExecute(String response) {
            if("true".equalsIgnoreCase(response)){
                indusosPostResult=response;
                SharedPreferences sharedPreferences = getSharedPreferences("branch", 0);
                sharedPreferences.edit().putBoolean("branchTrackUrlHit", true).apply();
                initBranchPlugin();
            }
        }
    }


}
