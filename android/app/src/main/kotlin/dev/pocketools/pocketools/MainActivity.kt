package dev.pocketools.pocketools

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val MOTION_CHANNEL = "pocketools/motion_sensor"
        private const val MOTION_EVENTS_CHANNEL = "pocketools/motion_sensor/events"
    }

    private var motionManager: SensorManager? = null
    private var motionListener: SensorEventListener? = null
    private var motionSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MOTION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(startMotionSensor())
                    "stop" -> {
                        stopMotionSensor()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MOTION_EVENTS_CHANNEL,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                motionSink = events
            }

            override fun onCancel(arguments: Any?) {
                motionSink = null
            }
        })
    }

    override fun onDestroy() {
        stopMotionSensor()
        super.onDestroy()
    }

    private fun startMotionSensor(): Boolean {
        val manager = getSystemService(SENSOR_SERVICE) as? SensorManager ?: return false
        val sensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: return false
        val listener = motionListener ?: object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    motionSink?.success(
                        mapOf(
                            "x" to event.values[0].toDouble(),
                            "y" to event.values[1].toDouble(),
                            "z" to event.values[2].toDouble(),
                        ),
                    )
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
            }.also { motionListener = it }
        motionManager = manager
        return manager.registerListener(
            listener,
            sensor,
            SensorManager.SENSOR_DELAY_GAME,
        )
    }

    private fun stopMotionSensor() {
        val manager = motionManager
        val listener = motionListener
        if (manager != null && listener != null) {
            manager.unregisterListener(listener)
        }
        motionManager = null
    }
}
