package com.howzat.howzatfantasy.services;

import android.graphics.Color;

import com.howzat.howzatfantasy.MainActivity;
import com.howzat.howzatfantasy.R;
import com.webengage.sdk.android.WebEngage;
import com.webengage.sdk.android.WebEngageActivityLifeCycleCallbacks;
import com.webengage.sdk.android.WebEngageConfig;

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
        initWebEngage();
    }

    private void initWebEngage() {
        WebEngageConfig config = new WebEngageConfig.Builder()
                .setWebEngageKey(MyConstants.WEBENGAGE_REGKEY)
                .setPushSmallIcon(R.drawable.notification_icon_small)
                .setPushAccentColor(Color.parseColor("#d32518"))
                .build();
        registerActivityLifecycleCallbacks(new WebEngageActivityLifeCycleCallbacks(this, config));
        FlutterApplication flutterApplication = new FlutterApplication();
        registerActivityLifecycleCallbacks(new WebEngageActivityLifeCycleCallbacks(flutterApplication, config));
        WebEngage.registerPushNotificationCallback(new MainActivity());

    }

}