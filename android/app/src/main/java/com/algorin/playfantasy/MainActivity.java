package com.algorin.playfantasy;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.algorin.playfantasy.services.MyHelperClass;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;
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
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.util.Log;

import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;



public class MainActivity extends FlutterActivity implements PaymentResultWithDataListener {
    private static final String BRANCH_IO_CHANNEL = "com.algorin.pf.branch";
    private static final String RAZORPAY_IO_CHANNEL = "com.algorin.pf.razorpay";
    private static final String PF_FCM_CHANNEL = "com.algorin.pf.fcm";
    MyHelperClass myHeperClass;
    String firebaseToken="";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);
        initFlutterChannels();
        initPushNotifications();
    }

    @Override
    public void onStart() {
        super.onStart();
        final Intent intent = getIntent();
        try {
            Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
                @Override
                public void onInitFinished(JSONObject referringParams, BranchError error) {
                    if (error == null) {
                        Log.i("BRANCH SDK", referringParams.toString());
                    } else {
                        Log.i("BRANCH SDK", error.getMessage());
                    }
                }
            }, intent.getData(), this);
        } catch (Exception e) {
        }
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
                    String pfRefCode = getRefCodeUsingBranch();
                    result.success(pfRefCode);
                }
                if (methodCall.method.equals("_getInstallReferringLink")) {
                    String installReferring_link = getInstallReferringLink();
                    result.success(installReferring_link);
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
    public String getRefCodeUsingBranch() {
        String refCodeFromBranch = "";
        String refCodeFromBranchTrail1 = "";
        String refCodeFromBranchTrail2 = "";
        try {
            myHeperClass = new MyHelperClass();
            JSONObject installParams = Branch.getInstance().getFirstReferringParams();
            String installReferring_link = (String) installParams.get("~referring_link");
            refCodeFromBranchTrail1 = myHeperClass.getQueryParmValueFromUrl(installReferring_link, "pfRefCode");
            System.out.println(refCodeFromBranch);

            JSONObject sessionParams = Branch.getInstance().getLatestReferringParams();
            String installReferring_link2 = (String) sessionParams.get("~referring_link");
            refCodeFromBranchTrail2 = myHeperClass.getQueryParmValueFromUrl(installReferring_link2, "pfRefCode");

        } catch (Exception e) {

        }
        if (refCodeFromBranchTrail1 != null && refCodeFromBranchTrail1.length() > 2) {
            refCodeFromBranch = refCodeFromBranchTrail1;
        } else {
            refCodeFromBranch = refCodeFromBranchTrail2;
        }
        return refCodeFromBranch;
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
            System.out.println("installReferring_link" + installReferring_link);
        } catch (Exception e) {
            System.out.println(e);
        }
        try {
            installAndroid_link = (String) installParams.get("$android_url");
            branchQueryParms.put("installAndroid_link", installAndroid_link);
            System.out.println("installAndroid_link" + installAndroid_link);
        } catch (Exception e) {
            System.out.println(e);
        }
        return branchQueryParms;
    }

    public String getInstallReferringLink() {
        String installReferring_link = "";
        JSONObject installParams = Branch.getInstance().getFirstReferringParams();
        try {
            installReferring_link = (String) installParams.get("~referring_link");

            System.out.println("installReferring_link" + installReferring_link);
        } catch (Exception e) {
            System.out.println(e);
        }

        return installReferring_link;
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
                        System.out.println(token);
                        System.out.println(token);

                    }
                });
    }

    private String getFireBaseToken(){
        return firebaseToken;
    }

    private void subscribeToFirebaseTopic(String topicName){
        try{
            FirebaseMessaging.getInstance().subscribeToTopic(topicName);
        }catch(Exception e) {

        }

    }

}
