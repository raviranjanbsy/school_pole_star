package com.example.school_management;

import android.os.Bundle;
import androidx.core.splashscreen.SplashScreen;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    // Handle the splash screen transition.
    SplashScreen.installSplashScreen(this);

    super.onCreate(savedInstanceState);
  }
}
