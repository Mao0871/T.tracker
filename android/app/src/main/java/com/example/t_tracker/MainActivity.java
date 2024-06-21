package com.example.t_tracker;

import android.os.Build;
import android.os.Bundle;
import android.Manifest;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.gps/record";
    private File currentFile;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("recordLocation")) {
                                double latitude = call.argument("latitude");
                                double longitude = call.argument("longitude");
                                String timestamp = call.argument("timestamp");

                                boolean isRecorded = recordLocation(latitude, longitude, timestamp);
                                if (isRecorded) {
                                    result.success("Location recorded");
                                } else {
                                    result.error("UNAVAILABLE", "Recording failed", null);
                                }
                            } else if (call.method.equals("saveFile")) {
                                String endTime = call.argument("endTime");
                                boolean isSaved = saveFile(endTime);
                                if (isSaved) {
                                    result.success("File saved");
                                } else {
                                    result.error("UNAVAILABLE", "File save failed", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }//这个方法虽然没有被调用过，但是他是java和flutter之间的桥梁

    private boolean recordLocation(double latitude, double longitude, String timestamp) {
        try {
            if (currentFile == null) {
                currentFile = new File(getExternalFilesDir(null), "temp_locations.json");
            }
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("latitude", latitude);
            jsonObject.put("longitude", longitude);
            jsonObject.put("timestamp", timestamp);

            FileWriter writer = new FileWriter(currentFile, true);
            writer.write(jsonObject.toString() + "\n");
            writer.close();
            return true;
        } catch (IOException | JSONException e) {
            e.printStackTrace();
            return false;
        }
    }

    private boolean saveFile(String endTime) {
        try {
            if (currentFile == null) {
                return false;
            }
            File newFile = new File(getExternalFilesDir(null), endTime + ".json");
            return currentFile.renameTo(newFile);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        } finally {
            currentFile = null;
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(new String[]{
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
            }, 1);
        }
    }//获取权限
}
