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

import io.branch.referral.Branch;
import io.branch.referral.BranchError;
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
import io.flutter.plugin.common.MethodChannel.Result;
import java.io.IOException;



public class MainActivity extends FlutterActivity implements PaymentResultWithDataListener {
    private static final String BRANCH_IO_CHANNEL = "com.algorin.pf.branch";
    private static final String RAZORPAY_IO_CHANNEL = "com.algorin.pf.razorpay";
    private static final String PF_FCM_CHANNEL = "com.algorin.pf.fcm";
    private Result branchIoResult;
    private HashMap<String, String> branchIoResultData;
    private MyHelperClass myHeperClass;
    private String firebaseToken="";
    private String installReferring_link = "";
    private JSONObject installParams;
    private JSONObject sessionParams;
    private JSONObject referringParams;
    private String refCodeFromBranch = "";
    private String googleAdId="";

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
    }




    protected void initFlutterChannels() {
        new MethodChannel(getFlutterView(), BRANCH_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                if (methodCall.method.equals("_initBranchIoPlugin")) {
                    branchIoResult=result;
                    initBranchPlugin();
                }
                if(methodCall.method.equals("_getGoogleAddId")){
                    String googleAddId = (String)getGoogleAddId();
                    result.success(googleAddId);
                }
                if(methodCall.method.equals("_getAndroidDeviceInfo")){
                    String deviceInfo = (String)getDeviceInfo();
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
                }
                else if(methodCall.method.equals("_subscribeToFirebaseTopic")){
                    String fcmTopic = methodCall.arguments();
                    subscribeToFirebaseTopic(fcmTopic);
                    result.success("Subscribed to PF fcm topic"+fcmTopic);
                }
                else {
                    result.notImplemented();
                }

            }
        });

    }


    /*Bracnch Io related code*/
    private void initBranchPlugin(){
        final Intent intent = getIntent();
        branchIoResultData = new HashMap<>();
        try {
            Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
                @Override
                public void onInitFinished(JSONObject _referringParams, BranchError error) {
                    if (error == null) {
                        Log.i("BRANCH SDK", _referringParams.toString());

                        referringParams=_referringParams;
                        initBranchSession();
                    } else {
                        Log.i("BRANCH SDK", error.getMessage());
                        branchIoResult.error("UNAVAILABLE", error.getMessage(), null);

                    }
                }
            }, intent.getData(), this);
        } catch (Exception e) {
            branchIoResult.error("UNAVAILABLE", "Failed to Init Branch", null);
        }
    }


    private void initBranchSession(){
        installParams = Branch.getInstance().getFirstReferringParams();
        sessionParams = Branch.getInstance().getLatestReferringParams();
        myHeperClass = new MyHelperClass();
        String installReferring_link_Trail1 ="";
        String installReferring_link_Trail2 ="";
        String installReferring_link_Trail3 ="";
        try {
            installReferring_link_Trail1 = (String) referringParams.get("~referring_link");

        } catch (Exception e) {
        }
        try {
            installReferring_link_Trail2 = (String) installParams.get("~referring_link");
        } catch (Exception e) {
        }
        try {
            installReferring_link_Trail3 = (String) sessionParams.get("~referring_link");

        } catch (Exception e) {
        }

        if (installReferring_link_Trail1 != null && installReferring_link_Trail1.length() > 2) {
            installReferring_link = installReferring_link_Trail1;
            branchIoResultData.put("installReferring_link", installReferring_link);
        } else if  (installReferring_link_Trail2 != null && installReferring_link_Trail2.length() > 2) {
            installReferring_link = installReferring_link_Trail2;
            branchIoResultData.put("installReferring_link", installReferring_link);
        }
        else if(installReferring_link_Trail3 != null && installReferring_link_Trail3.length() > 2){
            installReferring_link = installReferring_link_Trail3;
            branchIoResultData.put("installReferring_link", installReferring_link);
        }
        else{
            installReferring_link="";
            branchIoResultData.put("installReferring_link", installReferring_link);
        }
        //RefCode
        String refCodeFromBranchTrail1 = "";
        String refCodeFromBranchTrail2 = "";
        String refCodeFromBranchTrail3 = "";
        try {
            refCodeFromBranchTrail1 = myHeperClass.getQueryParmValueFromUrl(installReferring_link_Trail1, "refCode");

        } catch (Exception e) {
        }
        try {
            refCodeFromBranchTrail2 = myHeperClass.getQueryParmValueFromUrl(installReferring_link_Trail2, "refCode");

        } catch (Exception e) {
        }
        try {
            refCodeFromBranchTrail3 = myHeperClass.getQueryParmValueFromUrl(installReferring_link_Trail3, "refCode");

        } catch (Exception e) {
        }

        if (refCodeFromBranchTrail1 != null && refCodeFromBranchTrail1.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail1;
            branchIoResultData.put("refCodeFromBranch", refCodeFromBranch);

        } else if  (refCodeFromBranchTrail2 != null && refCodeFromBranchTrail2.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail2;
            branchIoResultData.put("refCodeFromBranch", refCodeFromBranch);
        }
        else if(refCodeFromBranchTrail3 != null && refCodeFromBranchTrail3.length() > 2){
            refCodeFromBranch = refCodeFromBranchTrail3;
            branchIoResultData.put("refCodeFromBranch", refCodeFromBranch);
        }
        else{
            refCodeFromBranch="";
            branchIoResultData.put("refCodeFromBranch", refCodeFromBranch);
        }

        branchIoResultData.put("refCodeFromBranch", refCodeFromBranch);
        branchIoResultData.put("installReferring_link", installReferring_link);
        branchIoResult.success(branchIoResultData);

    }

    @Override
    public void onNewIntent(Intent intent) {
        this.setIntent(intent);
    }

    public void getRefCodeUsingBranch() {
        String refCodeFromBranchTrail1 = "";
        String refCodeFromBranchTrail2 = "";
        try {
            myHeperClass = new MyHelperClass();
            JSONObject installParams = Branch.getInstance().getFirstReferringParams();
            String installReferring_link = (String) installParams.get("~referring_link");
            refCodeFromBranchTrail1 = myHeperClass.getQueryParmValueFromUrl(installReferring_link, "refCode");

            JSONObject sessionParams = Branch.getInstance().getLatestReferringParams();
            String installReferring_link2 = (String) sessionParams.get("~referring_link");
            refCodeFromBranchTrail2 = myHeperClass.getQueryParmValueFromUrl(installReferring_link2, "refCode");

        } catch (Exception e) {

        }
        if (refCodeFromBranchTrail1 != null && refCodeFromBranchTrail1.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail1;

        } else {
            refCodeFromBranch = refCodeFromBranchTrail2;

        }


    }


    public Map<String, String> getBranchQueryParms() {
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

    public void getInstallReferringLink() {
       installParams = Branch.getInstance().getFirstReferringParams();
        try {
            installReferring_link = (String) installParams.get("~referring_link");
        } catch (Exception e) {
        }

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

        String fmChannelName="news";
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
                        firebaseToken=token;
                    }
                });
    }

    private String getFireBaseToken(){
        FirebaseInstanceId.getInstance().getInstanceId()
                .addOnCompleteListener(new OnCompleteListener<InstanceIdResult>() {
                    @Override
                    public void onComplete(@NonNull Task<InstanceIdResult> task) {
                        if (!task.isSuccessful()) {
                            return;
                        }
                        String token = task.getResult().getToken();
                        firebaseToken=token;

                    }
                });
        return firebaseToken;
    }

    private void subscribeToFirebaseTopic(String topicName){
        try{
            FirebaseMessaging.getInstance().subscribeToTopic(topicName);
        }catch(Exception e) {

        }

    }

    private   void fetchAdvertisingID(final Activity current_activity) {
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

    private   void setTheGoogleId(String AdId) {
        googleAdId = AdId;
    }

    private String getGoogleAddId(){
        fetchAdvertisingID(this);
        return googleAdId;
    }


    private String  getDeviceInfo(){
        JSONObject params = new JSONObject();
        JSONObject emailList = new JSONObject();
        final DeviceInfo deviceData = new DeviceInfo();
        final Map<String, String> deviceInfoList = deviceData.getDeviceInfoMap(this);
        try{
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
        }catch(Exception e){

        }
       return params.toString();
    }



}
