package com.example.bananachock

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        prepareEdgeToEdgeWindow()
    }

    override fun onResume() {
        super.onResume()
        prepareEdgeToEdgeWindow()
    }

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.bananachock/timer").setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimer" -> {
                    requestNotifications()
                    val i = Intent(this, TimerForegroundService::class.java).apply {
                        action = TimerForegroundService.START
                        for (key in listOf("mode", "task")) putExtra(key, call.argument<String>(key) ?: "")
                        for (key in listOf("value", "work", "break")) putExtra(key, call.argument<Int>(key) ?: 0)
                        putExtra("isBreak", call.argument<Boolean>("isBreak") ?: false)
                    }
                    ContextCompat.startForegroundService(this, i); result.success(null)
                }
                "pauseTimer", "stopTimer" -> {
                    if (call.method == "pauseTimer") TimerForegroundService.pause(this) else TimerForegroundService.stop(this)
                    result.success(null)
                }
                "getTimerState" -> result.success(TimerForegroundService.snapshot(this, call.argument<Boolean>("consume") ?: false))
                "setImmersive" -> { applyImmersiveMode(call.argument<Boolean>("enabled") ?: false); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareEdgeToEdgeWindow() {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= 28) window.attributes = window.attributes.apply {
            layoutInDisplayCutoutMode = if (Build.VERSION.SDK_INT >= 30)
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            else WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    private fun applyImmersiveMode(enabled: Boolean) {
        prepareEdgeToEdgeWindow()
        WindowInsetsControllerCompat(window, window.decorView).apply {
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            if (enabled) hide(WindowInsetsCompat.Type.systemBars()) else show(WindowInsetsCompat.Type.systemBars())
        }
    }

    private fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 115)
    }
}
