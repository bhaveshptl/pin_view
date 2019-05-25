package com.howzat.howzatfantasy;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.howzat.howzatfantasy.services.DeviceInfo;
import com.howzat.howzatfantasy.services.MyHelperClass;

import org.json.JSONException;
import org.json.JSONObject;

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
import io.branch.referral.util.CurrencyType;
import io.branch.referral.util.ProductCategory;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.razorpay.Checkout;
import com.razorpay.PaymentData;
import com.razorpay.PaymentResultWithDataListener;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.support.annotation.NonNull;

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


public class MainActivity extends FlutterActivity implements PaymentResultWithDataListener {
    private static final String BRANCH_IO_CHANNEL = "com.algorin.pf.branch";
    private static final String RAZORPAY_IO_CHANNEL = "com.algorin.pf.razorpay";
    private static final String PF_FCM_CHANNEL = "com.algorin.pf.fcm";
    MyHelperClass myHeperClass;
    String firebaseToken = "";
    String installReferring_link = "";
    JSONObject installParams;
    String refCodeFromBranch = "";
    String googleAdId = "";

    Function callback;
    boolean bBranchLodead = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initPushNotifications();
        fetchAdvertisingID(this);
        GeneratedPluginRegistrant.registerWith(this);
        initFlutterChannels();
    }

    @Override
    public void onStart() {
        super.onStart();
        initBranchPlugin();


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
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                }
            }, intent.getData(), this);
        } catch (Exception e) {
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            Log.i("BRANCH SDK", e.getMessage());
            initBranchSession(null);
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
        }
    }

    private void getBranchData(MethodChannel.Result result) {
        final Intent intent = getIntent();
        try {
            Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
                @Override
                public void onInitFinished(JSONObject referringParams, BranchError error) {
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                    JSONObject object;
                    if (error == null) {
                        object = initBranchSession(referringParams);
                        Log.i("BRANCH SDK", referringParams.toString());
                    } else {
                        object = initBranchSession(referringParams);
                        Log.i("BRANCH SDK", error.getMessage());
                    }
                    result.success(object.toString());
                    Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
                }
            }, intent.getData(), this);
        } catch (Exception e) {
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            Log.i("BRANCH SDK", e.getMessage());
            JSONObject object = initBranchSession(null);
            result.success(object.toString());
            Log.i("BRANCH SDK", "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
        }
    }


    private JSONObject initBranchSession(JSONObject referringParams) {
        Log.i("BRANCH SDK", ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        JSONObject object = new JSONObject();

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
            JSONObject installParams = Branch.getInstance().getFirstReferringParams();
            installReferring_link1 = (String) installParams.get("~referring_link");
            Log.i("BRANCH SDK link1", installReferring_link1);
            refCodeFromBranchTrail1 = myHeperClass.getQueryParmValueFromUrl(installReferring_link1, "refCode");
        } catch (Exception e) {
        }

        try {
            JSONObject sessionParams = Branch.getInstance().getLatestReferringParams();
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
        try {
            object.put("installReferring_link", installReferring_link);
            object.put("refCodeFromBranch", refCodeFromBranch);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Log.i("BRANCH SDK", ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        return object;
    }

    @Override
    public void onNewIntent(Intent intent) {
        this.setIntent(intent);
    }

    protected void initFlutterChannels() {
        new MethodChannel(getFlutterView(), BRANCH_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("_getBranchRefCode")) {
                    String pfRefCode = (String) getRefCodeUsingBranch();

                    result.success(pfRefCode);
                }
                if (methodCall.method.equals("_initBranchIoPlugin")) {
                    if (bBranchLodead) {
                        JSONObject object = new JSONObject();
                        String pfRefCode = (String) getRefCodeUsingBranch();
                        String installReferring_link = (String) getInstallReferringLink();
                        try {
                            object.put("installReferring_link", installReferring_link);
                            object.put("refCodeFromBranch", pfRefCode);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
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
                    String channelResult=branchLifecycleEventSigniup(arguments);
                    result.success(channelResult);
                }
                if (methodCall.method.equals("branchEventInitPurchase")) {
                    Map<String, Object> arguments = methodCall.arguments();
                    String channelResult=branchEventInitPurchase(arguments);
                    result.success(channelResult);
                }
                if (methodCall.method.equals("branchEventTransactionFailed")) {
                    Map<String, Object> arguments = methodCall.arguments();
                    String channelResult=branchEventTransactionFailed(arguments);
                    result.success(channelResult);
                }
                if (methodCall.method.equals("branchEventTransactionSuccess")) {
                    Map<String, Object> arguments = methodCall.arguments();
                    String channelResult=branchEventTransactionSuccess(arguments);
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
        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
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
    }

    /*Bracnch Io related code*/
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

        buo.setContentMetadata(
                new ContentMetadata()
                        .addCustomMetadata("custom_metadata_key1", "custom_metadata_val1")
                        .addCustomMetadata("custom_metadata_key1", "custom_metadata_val1")

                        .setContentSchema(BranchContentSchema.COMMERCE_PRODUCT))
                .addKeyWord("keyword1")
                .addKeyWord("keyword2");
    }

    private String branchLifecycleEventSigniup(Map<String, Object> arguments) {
        BranchEvent be = new BranchEvent(BRANCH_STANDARD_EVENT.COMPLETE_REGISTRATION)
                .setTransactionID(""+arguments.get("transactionID"))
                .setDescription("HOWZAT SIGN UP");
        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {

            be.addCustomDataProperty((String) entry.getKey(), ""+entry.getValue());
        }
        be.logEvent(MainActivity.this);
        return "Sign Up Track event added";

    }


    private String branchEventTransactionFailed(Map<String, Object> arguments) {

        boolean isfirstDepositor=false;
        String eventName="FIRST_DEPOSIT_FAILED";
        isfirstDepositor= Boolean.parseBoolean(""+arguments.get("firstDepositor"));
        if(!isfirstDepositor){
            eventName ="REPEAT_DEPOSIT_FAILED";
        }

        BranchEvent be = new BranchEvent(eventName)
                .setTransactionID(""+arguments.get("txnId"))
                .setDescription(("HOWZAT DEPOSIT FAILED"));
        be.addCustomDataProperty("txnTime", ""+ arguments.get("txnTime"));
        be.addCustomDataProperty("txnDate", ""+ arguments.get("txnDate"));
        be.addCustomDataProperty("appPage",  ""+arguments.get("appPage"));

        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {
            be.addCustomDataProperty(entry.getKey(), ""+entry.getValue());
        }
        be.logEvent(MainActivity.this);

        return " Add Cash Failed Event added";

    }

    private String branchEventTransactionSuccess(Map<String, Object> arguments) {
        boolean isfirstDepositor=false;
        String eventName="FIRST_DEPOSIT_SUCCESS";
        isfirstDepositor=Boolean.parseBoolean(""+arguments.get("firstDepositor"));
        if(!isfirstDepositor){
            eventName ="REPEAT_DEPOSIT_SUCCESS";
        }


        BranchEvent be = new BranchEvent(eventName)
                .setTransactionID(""+arguments.get("txnId"))
                .setDescription("HOWZAT DEPOSIT FAILED");
        be.addCustomDataProperty("txnTime", ""+ arguments.get("txnTime"));
        be.addCustomDataProperty("txnDate", ""+ arguments.get("txnDate"));
        be.addCustomDataProperty("appPage", ""+ arguments.get("appPage"));

        HashMap<String, Object> data = new HashMap();
        data = (HashMap) arguments.get("data");

        for (Map.Entry<String, Object> entry : data.entrySet()) {

            be.addCustomDataProperty(entry.getKey(), ""+entry.getValue());
        }

        be.logEvent(MainActivity.this);

        return " Add Cash Success Event added";

    }

    private String branchEventInitPurchase(Map<String, Object> arguments) {
        new BranchEvent(BRANCH_STANDARD_EVENT.INITIATE_PURCHASE)
                .setTransactionID((String) arguments.get("transactionID"))
                .setDescription((String) arguments.get("description"))
                .addCustomDataProperty("registrationID", "12345")
                .logEvent(MainActivity.this);

        return "";
    }

    public void startPayment(Map<String, Object> arguments) {
        /*
          You need to pass current activity in order to let Razorpay create CheckoutActivity
         */
        final Activity activity = this;

        final Checkout co = new Checkout();

        try {
            JSONObject options = new JSONObject();
            options.put("name", (String) arguments.get("name"));
            options.put("description", "Add Cash");
            //You can omit the image option to fetch the image from dashboard
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
            Toast.makeText(activity, "Error in payment: " + e.getMessage(), Toast.LENGTH_SHORT)
                    .show();
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

        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentFail", object.toString(), new MethodChannel.Result() {
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

        new MethodChannel(getFlutterView(), RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentSuccess", object.toString(), new MethodChannel.Result() {
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

    /*Firebase Push notification*/
    public void initPushNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Create channel to show notifications.
            String channelId = "fcm_default_channel";
            String channelName = "News";
            NotificationManager notificationManager =
                    getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(new NotificationChannel(channelId,
                    channelName, NotificationManager.IMPORTANCE_LOW));
        }

        if (getIntent().getExtras() != null) {
            for (String key : getIntent().getExtras().keySet()) {
                Object value = getIntent().getExtras().get(key);
                //  Log.d(TAG, "Key: " + key + " Value: " + value);
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


}
