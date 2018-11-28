package com.algorin.playfantasy;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import org.json.JSONObject;

import io.branch.referral.Branch;
import io.branch.referral.BranchError;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
  }

  @Override
  public void onNewIntent(Intent intent) {
    this.setIntent(intent);
  }
  @Override
  public void onStart() {
    super.onStart();
    final Intent intent = getIntent();
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
    if (Intent.ACTION_VIEW.equals(intent.getAction()) && intent.getData() != null) {
      Toast.makeText(this, intent.getData().toString(),Toast.LENGTH_LONG);
      Log.w("Message",intent.getData().toString());
      Log.w("Message",intent.getData().toString());

    }
    Toast.makeText(this, "Null", Toast.LENGTH_LONG);
    // latest
    JSONObject sessionParams = Branch.getInstance().getLatestReferringParams();

// first
    JSONObject installParams = Branch.getInstance().getFirstReferringParams();
    JSONObject installParams2 = Branch.getInstance().getFirstReferringParams();
    JSONObject installParams3 = Branch.getInstance().getFirstReferringParams();
    JSONObject installParams4 = Branch.getInstance().getFirstReferringParams();
    JSONObject installParams6 = Branch.getInstance().getFirstReferringParams();
  }

}
