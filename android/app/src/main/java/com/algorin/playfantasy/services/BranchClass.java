package com.algorin.playfantasy.services;

import android.app.Application;
import io.branch.referral.Branch;
import io.flutter.app.FlutterApplication;

public class BranchClass  extends FlutterApplication {




    @Override
    public void onCreate() {
        super.onCreate();

        // Branch logging for debugging
        Branch.enableLogging();

        // Branch object initialization
        Branch.getAutoInstance(this);
    }

}