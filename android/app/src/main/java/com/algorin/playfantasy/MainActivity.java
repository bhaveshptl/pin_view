package com.algorin.playfantasy;

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


public class MainActivity extends FlutterActivity {
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
//          val intent = Intent(this, NativeViewActivity::class.java)
//          startActivity(intent);
//          result.success(true);
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









}
