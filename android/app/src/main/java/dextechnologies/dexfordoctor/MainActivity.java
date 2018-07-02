package dextechnologies.dexfordoctor;


import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.MediaRecorder;
import android.os.AsyncTask;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;
import android.util.Log;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.io.File;
import java.io.IOException;
import java.sql.Timestamp;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

public class MainActivity extends FlutterActivity {

  //CHANNEL
  private static final String CHANNEL = "dex.channels/dfRedButtonState";

  //INSTANCE OF RECORDER
  private MediaRecorder mRecorder;

  //FILE
  String mFileName = null;

  int stateOfMRecorder=0; //0 stop, 1Record, 2Paused

  NotificationManager notificationManager;

  //FIRE BASE STORAGE
//  FirebaseStorage storage = FirebaseStorage.getInstance();
//  private StorageReference mStorage;

  //PAUSE WHEN IN CALL
  BroadcastReceiver phonestatereceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      Bundle extras = intent.getExtras();
      if (extras != null) {
        String state = extras.getString(TelephonyManager.EXTRA_STATE);
        if (state.equals(TelephonyManager.EXTRA_STATE_RINGING)) {
          //pause here
          if (stateOfMRecorder==1){
            mRecorder.pause();
            stateOfMRecorder=2;
          }
        }
        else if (state.equals(TelephonyManager.EXTRA_STATE_OFFHOOK)) {
          //pause here
          if (stateOfMRecorder==1){
            mRecorder.pause();
            stateOfMRecorder=2;
            }
        }
        else if (state.equals(TelephonyManager.EXTRA_STATE_IDLE)) {
          //play here
          if (stateOfMRecorder==2){
            mRecorder.resume();
            }
        }
      }
    }
  };

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    GeneratedPluginRegistrant.registerWith(this);



    //CHANNEL CODE STARTS HERE
    new MethodChannel(getFlutterView(),CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall methodCall,final MethodChannel.Result result) {
                if(methodCall.method.equals("stateReply")){

                  int redButtonState = methodCall.argument("redButtonState");
                  String time = methodCall.argument("time");
//                  mFileName += "/"+time+".3gp";

                  //FLUTTER HOT RELOAD AND RESTART DOES NOT WORK FOR MAIN ACTIVITY CODE


                  //WHEN TRUE IS RECEIVED FROM FLUTTER CHANNEL THEN RECORDING IS STOPPED
                  //VICE VERSA FOR FALSE

                  if(redButtonState==0){
                    stopRecording();
                    result.success(mFileName);

                    unregisterReceiver(phonestatereceiver);

                  }else if(redButtonState==1){


                    startRecording();
                    result.success("Recording On ");


                    IntentFilter filter = new IntentFilter();
                    filter.addAction(android.telephony.TelephonyManager.ACTION_PHONE_STATE_CHANGED);
                    registerReceiver(phonestatereceiver,filter);

                  }else if(redButtonState==2){
                    mRecorder.pause();
                  }else{
                    mRecorder.resume();
                  }


                } else  {
                  result.notImplemented();
                }

              }
            }
    );
    //CHANNEL CODE ENDS HERE

  }



  //RECORDING METHODS
  private void startRecording() {

    //FILE PATH KEEPING THESE ANYWHERE ELSE IS PAIN
    mFileName = Environment.getExternalStorageDirectory().getAbsolutePath();

    //create /DeX subdirectory
    File folderCreationFile= new File(Environment.getExternalStorageDirectory().getAbsolutePath()+"/DeX");
    if(!folderCreationFile.exists()){
      folderCreationFile.mkdir();
    }


    mFileName += "/DeX/DeX_"+System.currentTimeMillis()+".m4a";

    mRecorder = new MediaRecorder();
    mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
    mRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
    mRecorder.setOutputFile(mFileName);
    mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.HE_AAC);
    mRecorder.setAudioSamplingRate(48000);
    mRecorder.setAudioEncodingBitRate(384000);

    try {
      mRecorder.prepare();
    } catch (IOException e) {
      Log.e("Record_Log", "prepare() failed");
    }

    mRecorder.start();
    stateOfMRecorder=1;

  }

  private void stopRecording() {
    mRecorder.stop();
    mRecorder.release();
    mRecorder = null;
    stateOfMRecorder=0;
  }


}
