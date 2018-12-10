package com.algorin.playfantasy;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.algorin.playfantasy.services.MyHelperClass;

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
import com.razorpay.PaymentResultListener;


public class MainActivity extends FlutterActivity implements PaymentResultListener {
  private static final String BRANCH_IO_CHANNEL="com.algorin.pf.branch";
  private static final String RAZORPAY_IO_CHANNEL="com.algorin.pf.razorpay";
  MyHelperClass myHeperClass;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    initFlutterChannels();
  }

  @Override
  public void onStart() {
    super.onStart();
    final Intent intent = getIntent();
    try{
      Branch.getInstance().initSession(new Branch.BranchReferralInitListener() {
        @Override
        public void onInitFinished(JSONObject referringParams, BranchError error) {
          if (error == null) {
            Log.i("BRANCH SDK", referringParams.toString());
          } else {
            Log.i("BRANCH SDK", error.getMessage());
          }
        }
      },intent.getData(), this);
    }
    catch(Exception e){
    }
  }

  @Override
  public void onNewIntent(Intent intent) {
    this.setIntent(intent);
  }


  protected  void initFlutterChannels(){
    new MethodChannel(getFlutterView(),BRANCH_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if(methodCall.method.equals("_getBranchRefCode")){
          String pfRefCode=getRefCodeUsingBranch();
          result.success(pfRefCode);
        }
        if(methodCall.method.equals("_getInstallReferringLink")){
          String installReferring_link= getInstallReferringLink();
          result.success(installReferring_link);
        }
      }
    });
    new MethodChannel(getFlutterView(),RAZORPAY_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if (methodCall.method.equals("_openRazorpayNative")) {
            Map<String,Object> arguments=methodCall.arguments();
          startPayment(arguments);
          String razocode="testrazo";
          result.success(razocode);

        } else {
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
    String installAndroid_link="";

    try {
      installReferring_link = (String) installParams.get("~referring_link");
      branchQueryParms.put("installReferring_link", installReferring_link);
      System.out.println("installReferring_link"+installReferring_link);
    } catch (Exception e) {
      System.out.println(e);
    }
    try {
      installAndroid_link=(String) installParams.get("$android_url");
      branchQueryParms.put("installAndroid_link", installAndroid_link);
      System.out.println("installAndroid_link"+installAndroid_link);
    } catch (Exception e) {
      System.out.println(e);
    }
    return branchQueryParms;
  }

  public String getInstallReferringLink(){
      String installReferring_link = "";
      JSONObject installParams = Branch.getInstance().getFirstReferringParams();
      try {
          installReferring_link = (String) installParams.get("~referring_link");

          System.out.println("installReferring_link"+installReferring_link);
      } catch (Exception e) {
          System.out.println(e);
      }

      return installReferring_link;
  }

  public void startPayment( Map<String,Object> arguments) {
        /*
          You need to pass current activity in order to let Razorpay create CheckoutActivity
         */
    final Activity activity = this;

    final Checkout co = new Checkout();

    try {
      JSONObject options = new JSONObject();
      options.put("name", "PlayFantasy");
      options.put("description", "Add Cash");
      //You can omit the image option to fetch the image from dashboard
      options.put("image", "https://s3.amazonaws.com/rzp-mobile/images/rzp.png");
      options.put("currency", "INR");
      options.put("amount", (String)arguments.get("amount"));

      JSONObject preFill = new JSONObject();
      preFill.put("email", (String)arguments.get("email"));
      preFill.put("contact", (String)arguments.get("phone"));

      options.put("prefill", preFill);

      co.open(activity, options);
    } catch (Exception e) {
      Toast.makeText(activity, "Error in payment: " + e.getMessage(), Toast.LENGTH_SHORT)
              .show();
      e.printStackTrace();
    }
  }


  @SuppressWarnings("unused")
  @Override
  public void onPaymentSuccess(String razorpayPaymentID) {
    try {


      onRazorPayPaymentSuccess();
    } catch (Exception e) {

    }
  }


  @SuppressWarnings("unused")
  @Override
  public void onPaymentError(int code, String response) {
    try {
      onRazorPayPaymentFail();
    } catch (Exception e) {

    }
  }



  public void onRazorPayPaymentFail(){
    new MethodChannel(getFlutterView(),RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentFail", "", new MethodChannel.Result() {
      @Override
      public void success(Object o) {

      }
      @Override
      public void error(String s, String s1, Object o) {}

      @Override
      public void notImplemented() {}
    });
  }

  public void onRazorPayPaymentSuccess(){
    new MethodChannel(getFlutterView(),RAZORPAY_IO_CHANNEL).invokeMethod("onRazorPayPaymentSuccess", "", new MethodChannel.Result() {
      @Override
      public void success(Object o) {

      }
      @Override
      public void error(String s, String s1, Object o) {}

      @Override
      public void notImplemented() {}
    });
  }




}
