package com.example.iheart

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iheart/dispositivo")
            .setMethodCallHandler { llamada, resultado ->
                when (llamada.method) {
                    "nivelBateria" -> {
                        val gestor = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                        resultado.success(gestor.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY))
                    }
                    "nombreDispositivo" -> {
                        val nombre = Settings.Global.getString(contentResolver, "device_name")
                        resultado.success(if (nombre.isNullOrBlank()) Build.MODEL else nombre)
                    }
                    else -> resultado.notImplemented()
                }
            }
    }
}
