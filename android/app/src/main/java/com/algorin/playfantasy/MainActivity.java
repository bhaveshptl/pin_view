package com.algorin.playfantasy;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import com.algorin.playfantasy.services.MyHelperClass;

import org.json.JSONObject;

import io.branch.referral.Branch;
import io.branch.referral.BranchError;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  private static final String BRANCH_IO_CHANNEL="com.algorin.pf.branch";
  MyHelperClass myHeperClass;
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    new MethodChannel(getFlutterView(),BRANCH_IO_CHANNEL).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        if(methodCall.method.equals("_getBranchRefCode")){
          String pfRefCode=getRefCodeUsingBranch();
          result.success(pfRefCode);
        }
      }
    });
  }

  @Override
  public void onNewIntent(Intent intent) {
    this.setIntent(intent);
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

}
