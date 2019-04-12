package com.howzat.howzatfantasy.services;

import io.branch.referral.Branch;
import io.flutter.app.FlutterApplication;

public class BranchClass  extends FlutterApplication {
    /*BranchClass extends FlutterApplication.To remove the Branch function from this project replace  android:name=".services.BranchClass" to io.flutter.app.FlutterApplication*/
    @Override
    public void onCreate() {
        super.onCreate();
        // Branch logging for debugging
        Branch.enableLogging();
        // Branch object initialization
        Branch.getAutoInstance(this);
    }

}