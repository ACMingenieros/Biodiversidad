package com.example.biodiversidad

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var eventSink: EventChannel.EventSink? = null

    private val rotationMatrix = FloatArray(9)
    private val remappedMatrix = FloatArray(9)
    private val orientationAngles = FloatArray(3)
    private val gravityReading = FloatArray(3)
    private val magnetometerReading = FloatArray(3)
    private val linearAccel = FloatArray(3)
    private var hasGravity = false
    private var hasMagnetometer = false
    private var lastEmitTimestampMs = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "biodiversidad.unsm/ar_sensors"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startWatchingSensors()
            }

            override fun onCancel(arguments: Any?) {
                stopWatchingSensors()
                eventSink = null
            }
        })
    }

    private fun startWatchingSensors() {
        val manager = sensorManager ?: return
        val rotationSensor = manager.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
            ?: manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

        if (rotationSensor != null) {
            manager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_GAME)
        } else {
            manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
                manager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
            manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)?.let {
                manager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
        }

        manager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)?.let {
            manager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    private fun stopWatchingSensors() {
        sensorManager?.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val sink = eventSink ?: return
        val sensorEvent = event ?: return

        when (sensorEvent.sensor.type) {
            Sensor.TYPE_LINEAR_ACCELERATION -> {
                val alpha = 0.25f
                linearAccel[0] += alpha * (sensorEvent.values[0] - linearAccel[0])
                linearAccel[1] += alpha * (sensorEvent.values[1] - linearAccel[1])
                linearAccel[2] += alpha * (sensorEvent.values[2] - linearAccel[2])
                return
            }

            Sensor.TYPE_GAME_ROTATION_VECTOR,
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotationMatrix, sensorEvent.values)
                SensorManager.remapCoordinateSystem(
                    rotationMatrix,
                    SensorManager.AXIS_X,
                    SensorManager.AXIS_Z,
                    remappedMatrix
                )
                SensorManager.getOrientation(remappedMatrix, orientationAngles)
            }

            Sensor.TYPE_ACCELEROMETER -> {
                System.arraycopy(sensorEvent.values, 0, gravityReading, 0, 3)
                hasGravity = true
                if (!updateFallbackOrientation()) return
            }

            Sensor.TYPE_MAGNETIC_FIELD -> {
                System.arraycopy(sensorEvent.values, 0, magnetometerReading, 0, 3)
                hasMagnetometer = true
                if (!updateFallbackOrientation()) return
            }

            else -> return
        }

        val nowMs = System.currentTimeMillis()
        if (nowMs - lastEmitTimestampMs < 20L) return
        lastEmitTimestampMs = nowMs

        val yawRad = orientationAngles[0].toDouble()
        val pitchRad = orientationAngles[1].toDouble()
        val rollRad = orientationAngles[2].toDouble()

        sink.success(
            doubleArrayOf(
                pitchRad,
                yawRad,
                rollRad,
                linearAccel[0].toDouble(),
                linearAccel[1].toDouble(),
                linearAccel[2].toDouble()
            )
        )
    }

    private fun updateFallbackOrientation(): Boolean {
        if (!hasGravity) return false
        if (hasMagnetometer) {
            if (!SensorManager.getRotationMatrix(
                    rotationMatrix,
                    null,
                    gravityReading,
                    magnetometerReading
                )
            ) {
                return false
            }
            SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_X,
                SensorManager.AXIS_Z,
                remappedMatrix
            )
            SensorManager.getOrientation(remappedMatrix, orientationAngles)
            return true
        }
        return false
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onDestroy() {
        stopWatchingSensors()
        super.onDestroy()
    }
}
