package com.howzat.howzatfantasy.services;



import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import android.util.Log;

import com.howzat.howzatfantasy.MainActivity;
import com.howzat.howzatfantasy.R;
import com.firebase.jobdispatcher.FirebaseJobDispatcher;
import com.firebase.jobdispatcher.GooglePlayDriver;
import com.firebase.jobdispatcher.Job;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.webengage.sdk.android.WebEngage;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.List;
import java.util.Map;



public class MyFirebaseMessagingService extends FirebaseMessagingService {


    private static final String TAG = "MyFirebaseMsgService";
    Bitmap imageUriBitmap, pictureUrlBitmap, pictureBigBitmap;


    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {

        Log.d(TAG, "From: " + remoteMessage.getFrom());
      

        Map<String, String> webengagedata = remoteMessage.getData();
        if(webengagedata != null) {
            if(webengagedata.containsKey("source") && "webengage".equals(webengagedata.get("source"))) {
                WebEngage.get().receive(webengagedata);
            }
        }

        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());

            if (true) {
                scheduleJob();
            } else {
                handleNow();
            }

        }

        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
        }

        Boolean isAppOnForeground = false;
        if (!isAppOnForeground) {
            if(webengagedata.containsKey("source") && "webengage".equals(webengagedata.get("source"))) {
                //WebEngage.get().receive(webengagedata);
            }else{
                try{
                    Map<String, String> pushData = remoteMessage.getData();
                    if (pushData.containsKey("title")&&pushData.containsKey("body")&&pushData.containsKey("image")&&pushData.containsKey("picture")){
                        sendNotification(remoteMessage);
                    }
                }catch(Exception e){
                }
            }
        }
        else{

        }

    }

    @Override
    public void onNewToken(String token) {
        Log.d(TAG, "Refreshed token: " + token);
        sendRegistrationToServer(token);
        WebEngage.get().setRegistrationID(token);
    }

    private void scheduleJob() {
//        FirebaseJobDispatcher dispatcher = new FirebaseJobDispatcher(new GooglePlayDriver(this));
//        Job myJob = dispatcher.newJobBuilder()
//                .setService(MyJobService.class)
//                .setTag("my-job-tag")
//                .build();
//        dispatcher.schedule(myJob);

    }


    private void handleNow() {
        Log.d(TAG, "Short lived task is done.");
    }


    private void sendRegistrationToServer(String token) {

    }


    private void sendNotification(RemoteMessage remoteMessage) {
        try {
            Map<String, String> receivedMap = remoteMessage.getData();
            String title = receivedMap.get("title");
            String body = receivedMap.get("body");
            String imageUri = receivedMap.get("image");
            String pictureUrl = receivedMap.get("picture");
            imageUriBitmap = getBitmapfromUrl(imageUri);
            pictureUrlBitmap = getBitmapfromUrl(pictureUrl);

            //Bitmap pictureBigBitmap = BitmapFactory.decodeResource(getResources(), ic_launcher_round);

          Intent intent = new Intent(MainActivity.applicationContext, MainActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent pendingIntent = PendingIntent.getActivity(MainActivity.applicationContext, 0 /* Request code */, intent,
                    PendingIntent.FLAG_ONE_SHOT);
            String channelId = "fcm_default_channel";
            Uri defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);


            NotificationManagerCompat notificationManager = NotificationManagerCompat.from(MainActivity.applicationContext);

           NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(MainActivity.applicationContext, channelId);
            NotificationCompat.BigPictureStyle bigPictureStyle = new NotificationCompat.BigPictureStyle();
            bigPictureStyle.bigPicture(pictureUrlBitmap);
            bigPictureStyle.setBigContentTitle(body);
            notificationBuilder
                    .setSmallIcon(R.drawable.notification_icon_small)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setAutoCancel(true)
                    .setLargeIcon(imageUriBitmap)
                    .setDefaults(Notification.DEFAULT_VIBRATE | Notification.FLAG_SHOW_LIGHTS | Notification.DEFAULT_SOUND )
                    .setSound(defaultSoundUri)
                    .setStyle(bigPictureStyle)
                    .setColor(Color.parseColor("#d32518"))
                    .setContentIntent(pendingIntent);

            /* Since android Oreo notification channel is needed*/
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(channelId,
                        "PlayFantasy",
                        NotificationManager.IMPORTANCE_DEFAULT);

            }

            notificationManager.notify(0 /* ID of notification */, notificationBuilder.build());

        } catch (Exception e) {
             System.out.print(e.toString());
        }

    }


    public Bitmap getBitmapfromUrl(String imageUrl) {
        try {
            URL url = new URL(imageUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoInput(true);
            connection.connect();
            InputStream input = connection.getInputStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);
            return bitmap;

        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return null;

        }
    }

    private boolean isAppOnForeground(Context context, String appPackageName) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningAppProcessInfo> appProcesses = activityManager.getRunningAppProcesses();
        if (appProcesses == null) {
            return false;
        }
        final String packageName = appPackageName;
        for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND && appProcess.processName.equals(packageName)) {

                return true;
            }
        }
        return false;
    }

    private String getApplicationName(Context context, String data, int flag) {

        final PackageManager pckManager = context.getPackageManager();
        ApplicationInfo applicationInformation;
        try {
            applicationInformation = pckManager.getApplicationInfo(data, flag);
        } catch (PackageManager.NameNotFoundException e) {
            applicationInformation = null;
        }
        final String applicationName = (String) (applicationInformation != null ? pckManager.getApplicationLabel(applicationInformation) : "(unknown)");
        return applicationName;

    }


}