package com.irs.itap

import android.os.Bundle
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  private val CHANNEL = "com.irs.itap/requireLocation"
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method == "requireLocation") {
        result.success(VERSION.SDK_INT >= VERSION_CODES.O)
      } else {
        result.notImplemented()
      }
    }
  }
}
