package dextechnologies.dexfordoctor;


import android.annotation.SuppressLint;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.MediaRecorder;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.telephony.TelephonyManager;
import android.util.Log;

import com.coremedia.iso.boxes.Container;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.googlecode.mp4parser.authoring.Movie;
import com.googlecode.mp4parser.authoring.Track;
import com.googlecode.mp4parser.authoring.builder.DefaultMp4Builder;
import com.googlecode.mp4parser.authoring.container.mp4.MovieCreator;
import com.googlecode.mp4parser.authoring.tracks.AppendTrack;


public class MainActivity extends FlutterActivity {

  //CHANNEL
  private static final String CHANNEL = "dex.channels/dfRedButtonState";

  //INSTANCE OF RECORDER
  private MediaRecorder mRecorder;

  //FILE
  String mFileName = null;

  int stateOfMRecorder=0; //0 stop, 1Record, 2Paused

  NotificationManager notificationManager;

  //contains source files for pause function (android sdk < 24)
  List<String> sourceFiles = new ArrayList<>();

//  String sourceFiles[];

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
            pauseRecording();
            stateOfMRecorder=2;
          }
        }
        else if (state.equals(TelephonyManager.EXTRA_STATE_OFFHOOK)) {
          //pause here
          if (stateOfMRecorder==1){
            pauseRecording();
            stateOfMRecorder=2;
            }
        }
        else if (state.equals(TelephonyManager.EXTRA_STATE_IDLE)) {
          //play here
          if (stateOfMRecorder==2){
            resumeRecording();
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
              @SuppressLint("StaticFieldLeak")
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

//                    new AsyncTask<>() {
//                      @Override
//                      protected Object doInBackground(Object... objects) {
//                        stopRecording();
//                        return null;
//                      }
//
//                      @Override
//                      protected void onPostExecute(Object o) {
//                        result.success(mFileName);
//                      }
//                    }.execute();

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
                    pauseRecording();
                  }else{
                    resumeRecording();
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

//  int recorderStoppedState =0;

  private void stopRecording() {

//    if(recorderStoppedState !=1) {
      mRecorder.stop();
      mRecorder.release();
      mRecorder = null;
        stateOfMRecorder = 0;

//    }

      sourceFiles.add(mFileName);
      String[] sourceFilesArray = sourceFiles.toArray(new String[0]);


      if (Build.VERSION.SDK_INT < 24 && sourceFilesArray.length>1) {


        mFileName = Environment.getExternalStorageDirectory().getAbsolutePath();
        mFileName += "/DeX/DeX_" + System.currentTimeMillis() + ".m4a";
//        mergeMediaFiles(true, sourceFilesArray, mFileName);

        MyTaskParams params = new MyTaskParams(sourceFilesArray,mFileName);
        new mergeAudioFiles().execute(params);
      }

      sourceFiles.clear(); //clear all recording fragments

  }


  //FOR SDK < 24 PAUSE() IS NOT SUPPORTED
  private void pauseRecording() {
    if(Build.VERSION.SDK_INT < 24){
      mRecorder.stop();
      mRecorder.release();
      mRecorder = null;
      stateOfMRecorder=0;
      sourceFiles.add(mFileName);

//      recorderStoppedState =1;
    }
    else{
      mRecorder.pause();
    }
  }
  private void resumeRecording() {
    if(Build.VERSION.SDK_INT < 24){
      startRecording();
//      recorderStoppedState=0;
    }
    else{
      mRecorder.resume();
    }
  }

  //this dude combines sourcefiles
//  public static boolean mergeMediaFiles(boolean isAudio, String sourceFiles[], String targetFile) {
//    try {
//      String mediaKey = isAudio ? "soun" : "vide";
//      List<Movie> listMovies = new ArrayList<>();
//      for (String filename : sourceFiles) {
//        listMovies.add(MovieCreator.build(filename));
//      }
//      List<Track> listTracks = new LinkedList<>();
//      for (Movie movie : listMovies) {
//        for (Track track : movie.getTracks()) {
//          if (track.getHandler().equals(mediaKey)) {
//            listTracks.add(track);
//          }
//        }
//      }
//      Movie outputMovie = new Movie();
//      if (!listTracks.isEmpty()) {
//        outputMovie.addTrack(new AppendTrack(listTracks.toArray(new Track[listTracks.size()])));
//      }
//      Container container = new DefaultMp4Builder().build(outputMovie);
//      FileChannel fileChannel = new RandomAccessFile(String.format(targetFile), "rw").getChannel();
//      container.writeContainer(fileChannel);
//      fileChannel.close();
//      return true;
//    }
//    catch (IOException e) {
//      Log.e("tag", "Error merging media files. exception: "+e.getMessage());
//      return false;
//    }
//  }


  private static class MyTaskParams {
    String sourceFiles[];
    String targetFile;

    MyTaskParams(String sourceFiles[], String targetFile) {
      this.sourceFiles = sourceFiles;
      this.targetFile = targetFile;
    }
  }

  public static class mergeAudioFiles extends AsyncTask<MyTaskParams,Void,String>{

    @Override
    protected String doInBackground(MyTaskParams... params) {

      String sourceFiles[]=params[0].sourceFiles;
      String targetFile=params[0].targetFile;

      try {
        String mediaKey = "soun";
        List<Movie> listMovies = new ArrayList<>();
        for (String filename : sourceFiles) {
          listMovies.add(MovieCreator.build(filename));
        }
        List<Track> listTracks = new LinkedList<>();
        for (Movie movie : listMovies) {
          for (Track track : movie.getTracks()) {
            if (track.getHandler().equals(mediaKey)) {
              listTracks.add(track);
            }
          }
        }
        Movie outputMovie = new Movie();
        if (!listTracks.isEmpty()) {
          outputMovie.addTrack(new AppendTrack(listTracks.toArray(new Track[listTracks.size()])));
        }
        Container container = new DefaultMp4Builder().build(outputMovie);
        FileChannel fileChannel = new RandomAccessFile(String.format(targetFile), "rw").getChannel();
        container.writeContainer(fileChannel);
        fileChannel.close();
        return null;
      }
      catch (IOException e) {
        Log.e("tag", "Error merging media files. exception: "+e.getMessage());
        return null;
      }
    }
  }


}
