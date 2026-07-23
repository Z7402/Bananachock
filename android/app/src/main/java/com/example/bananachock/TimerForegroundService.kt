package com.example.bananachock

import android.app.*
import android.content.*
import android.os.*
import androidx.core.app.NotificationCompat
import kotlin.math.max

class TimerForegroundService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val prefs by lazy { getSharedPreferences(PREFS, MODE_PRIVATE) }
    private val ticker = object : Runnable {
        override fun run() {
            if (!prefs.getBoolean("running", false)) { removeForeground(); stopSelf(); return }
            syncClock(); startForeground(ID, notification()); handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate() { super.onCreate(); createChannel() }
    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            START -> saveStart(intent)
            PAUSE -> { syncClock(); prefs.edit().putBoolean("running", false).apply() }
            STOP -> prefs.edit().clear().apply()
        }
        handler.removeCallbacks(ticker)
        if (!prefs.getBoolean("running", false)) { removeForeground(); stopSelf(); return START_NOT_STICKY }
        syncClock(); startForeground(ID, notification()); handler.post(ticker); return START_STICKY
    }

    private fun saveStart(i: Intent) = prefs.edit()
        .putBoolean("running", true).putString("mode", i.getStringExtra("mode") ?: "pomodoro")
        .putInt("value", max(0, i.getIntExtra("value", 0))).putInt("work", i.getIntExtra("work", 1500))
        .putInt("break", i.getIntExtra("break", 300)).putBoolean("isBreak", i.getBooleanExtra("isBreak", false))
        .putString("task", i.getStringExtra("task") ?: "").putLong("anchor", System.currentTimeMillis()).apply()

    private fun syncClock() {
        if (!prefs.getBoolean("running", false)) return
        val now = System.currentTimeMillis(); val elapsed = max(0, ((now - prefs.getLong("anchor", now)) / 1000).toInt())
        if (elapsed == 0) return
        val mode = prefs.getString("mode", "pomodoro")!!; var value = prefs.getInt("value", 0)
        var isBreak = prefs.getBoolean("isBreak", false); var running = true; var pending = prefs.getInt("pending", 0)
        if (mode == "stopwatch") value += elapsed else {
            var left = elapsed
            while (left > 0 && running) {
                if (value <= 0) value = 1
                if (value > left) { value -= left; left = 0 } else {
                    left -= value
                    if (!isBreak) { pending++; isBreak = true; value = prefs.getInt("break", 300) }
                    else { isBreak = false; value = prefs.getInt("work", 1500); running = false }
                }
            }
        }
        prefs.edit().putInt("value", max(0, value)).putBoolean("isBreak", isBreak)
            .putBoolean("running", running).putInt("pending", pending).putLong("anchor", now).apply()
    }

    private fun notification(): Notification {
        val mode = prefs.getString("mode", "pomodoro"); val value = prefs.getInt("value", 0)
        val isBreak = prefs.getBoolean("isBreak", false); val task = prefs.getString("task", "").orEmpty()
        val title = if (mode == "stopwatch") (task.ifEmpty { "正向计时中" }) else if (isBreak) "休息计时中" else task.ifEmpty { "专注计时中" }
        val label = if (mode == "stopwatch") "已计时" else if (isBreak) "休息剩余" else "专注剩余"
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pending = PendingIntent.getActivity(this, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL).setSmallIcon(R.mipmap.ic_launcher).setContentTitle(title)
            .setContentText("$label %02d:%02d".format(value / 60, value % 60)).setContentIntent(pending)
            .setOngoing(true).setOnlyAlertOnce(true).setSilent(true).setCategory(NotificationCompat.CATEGORY_STOPWATCH).build()
    }

    private fun createChannel() { if (Build.VERSION.SDK_INT >= 26) getSystemService(NotificationManager::class.java)
        .createNotificationChannel(NotificationChannel(CHANNEL, "后台计时", NotificationManager.IMPORTANCE_LOW).apply { setSound(null, null) }) }
    private fun removeForeground() { if (Build.VERSION.SDK_INT >= 24) stopForeground(STOP_FOREGROUND_REMOVE) else @Suppress("DEPRECATION") stopForeground(true) }
    override fun onDestroy() { handler.removeCallbacks(ticker); super.onDestroy() }

    companion object {
        const val START = "bananachock.timer.START"; const val PAUSE = "bananachock.timer.PAUSE"; const val STOP = "bananachock.timer.STOP"
        private const val PREFS = "bananachock_timer_service"; private const val CHANNEL = "bananachock_timer"; private const val ID = 115
        fun pause(context: Context) { context.getSharedPreferences(PREFS, MODE_PRIVATE).edit().putBoolean("running", false).apply(); context.stopService(Intent(context, TimerForegroundService::class.java)) }
        fun stop(context: Context) { context.getSharedPreferences(PREFS, MODE_PRIVATE).edit().clear().apply(); context.stopService(Intent(context, TimerForegroundService::class.java)) }
        fun snapshot(context: Context, consume: Boolean): Map<String, Any?> {
            val p = context.getSharedPreferences(PREFS, MODE_PRIVATE)
            val result = mapOf("active" to p.contains("mode"), "running" to p.getBoolean("running", false), "mode" to p.getString("mode", "pomodoro"),
                "value" to p.getInt("value", 0), "work" to p.getInt("work", 1500), "break" to p.getInt("break", 300),
                "isBreak" to p.getBoolean("isBreak", false), "task" to p.getString("task", ""), "pending" to p.getInt("pending", 0))
            if (consume) p.edit().putInt("pending", 0).apply(); return result
        }
    }
}
