package com.example.voicehub

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.RandomAccessFile
import kotlin.concurrent.thread
import kotlin.math.max

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.voicehub/native_pcm_audio"
    }

    // Cấu hình âm thanh thực PCM 16-bit, 44100 Hz, Mono
    private val sampleRate = 44100
    private val channelConfigRecord = AudioFormat.CHANNEL_IN_MONO
    private val channelConfigPlay = AudioFormat.CHANNEL_OUT_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT

    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null

    @Volatile
    private var isRecording = false

    @Volatile
    private var isPlaying = false

    @Volatile
    private var isPassthroughActive = false

    private var recordingThread: Thread? = null
    private var playbackThread: Thread? = null
    private var passthroughThread: Thread? = null

    private var currentRecordingFilePath: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!granted) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.RECORD_AUDIO),
                            1001
                        )
                    }
                    result.success(granted)
                }
                "startPassthrough" -> {
                    val success = startAudioPassthrough()
                    result.success(success)
                }
                "stopPassthrough" -> {
                    stopAudioPassthrough()
                    result.success(true)
                }
                "isPassthroughActive" -> {
                    result.success(isPassthroughActive)
                }
                "startRecording" -> {
                    val fileName = call.argument<String>("filePath") ?: "rec_${java.lang.System.currentTimeMillis()}.wav"
                    val fullPath = if (fileName.contains("/")) fileName else "${filesDir.absolutePath}/$fileName"
                    currentRecordingFilePath = fullPath
                    val success = startPcmRecording(fullPath)
                    result.success(if (success) fullPath else "")
                }
                "stopRecording" -> {
                    val savedPath = stopPcmRecording()
                    result.success(savedPath)
                }
                "startPlayback" -> {
                    val pathArg = call.argument<String>("filePath") ?: currentRecordingFilePath
                    val success = startPcmPlayback(pathArg)
                    result.success(success)
                }
                "stopPlayback" -> {
                    stopPcmPlayback()
                    result.success(true)
                }
                "isRecording" -> {
                    result.success(isRecording)
                }
                "isPlaying" -> {
                    result.success(isPlaying)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * 🎧 CHẾ ĐỘ AUDIO PASSTHROUGH / REAL-TIME MONITORING
     * Thu âm thực từ micro và phát thẳng ra loa/tai nghe theo thời gian thực
     */
    private fun startAudioPassthrough(): Boolean {
        if (isPassthroughActive) return false

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        val minRecordBufSize = AudioRecord.getMinBufferSize(sampleRate, channelConfigRecord, audioFormat)
        val minPlayBufSize = AudioTrack.getMinBufferSize(sampleRate, channelConfigPlay, audioFormat)

        if (minRecordBufSize <= 0 || minPlayBufSize <= 0) return false

        val bufferSize = max(minRecordBufSize, minPlayBufSize)

        val audioSource = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            MediaRecorder.AudioSource.UNPROCESSED
        } else {
            MediaRecorder.AudioSource.MIC
        }

        try {
            audioRecord = AudioRecord(
                audioSource,
                sampleRate,
                channelConfigRecord,
                audioFormat,
                bufferSize * 2
            )
        } catch (e: Exception) {
            try {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    channelConfigRecord,
                    audioFormat,
                    bufferSize * 2
                )
            } catch (ex: Exception) {
                return false
            }
        }

        audioTrack = AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate,
            channelConfigPlay,
            audioFormat,
            bufferSize * 2,
            AudioTrack.MODE_STREAM
        )

        val recObj = audioRecord ?: return false
        val trackObj = audioTrack ?: return false

        if (recObj.state != AudioRecord.STATE_INITIALIZED || trackObj.state != AudioTrack.STATE_INITIALIZED) {
            return false
        }

        isPassthroughActive = true
        recObj.startRecording()
        trackObj.play()

        passthroughThread = thread(start = true) {
            val buffer = ByteArray(bufferSize)
            while (isPassthroughActive) {
                val bytesRead = recObj.read(buffer, 0, buffer.size)
                if (bytesRead > 0) {
                    trackObj.write(buffer, 0, bytesRead)
                }
            }
        }

        return true
    }

    private fun stopAudioPassthrough() {
        isPassthroughActive = false
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        passthroughThread = null
    }

    /**
     * 🎙 GHI ÂM ÂM THANH THỰC (PCM 16-BIT 44100Hz UNPROCESSED) VÀO FILE .WAV
     */
    private fun startPcmRecording(filePath: String): Boolean {
        if (isRecording) return false

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfigRecord, audioFormat)
        if (minBufferSize <= 0) return false

        val audioSource = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            MediaRecorder.AudioSource.UNPROCESSED
        } else {
            MediaRecorder.AudioSource.MIC
        }

        try {
            audioRecord = AudioRecord(
                audioSource,
                sampleRate,
                channelConfigRecord,
                audioFormat,
                minBufferSize * 2
            )
        } catch (e: Exception) {
            try {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    channelConfigRecord,
                    audioFormat,
                    minBufferSize * 2
                )
            } catch (ex: Exception) {
                return false
            }
        }

        val recordObj = audioRecord ?: return false
        if (recordObj.state != AudioRecord.STATE_INITIALIZED) {
            return false
        }

        isRecording = true
        recordObj.startRecording()

        recordingThread = thread(start = true) {
            val wavFile = File(filePath)
            if (wavFile.exists()) wavFile.delete()

            var outStream: FileOutputStream? = null
            try {
                outStream = FileOutputStream(wavFile)
                outStream.write(ByteArray(44)) // Ghi 44 bytes header rỗng

                val buffer = ByteArray(minBufferSize)
                var totalAudioLen: Long = 0

                while (isRecording) {
                    val bytesRead = recordObj.read(buffer, 0, buffer.size)
                    if (bytesRead > 0) {
                        outStream.write(buffer, 0, bytesRead)
                        totalAudioLen += bytesRead
                    }
                }

                outStream.close()
                outStream = null

                // Ghi chuẩn WAV header 44 bytes vào đầu file
                writeWavHeader(wavFile, totalAudioLen, sampleRate, 1, 16)
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                outStream?.close()
            }
        }

        return true
    }

    private fun stopPcmRecording(): String {
        if (!isRecording) return currentRecordingFilePath

        isRecording = false
        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            e.printStackTrace()
        }

        recordingThread?.join(1000)
        recordingThread = null

        return currentRecordingFilePath
    }

    /**
     * 🔊 PHÁT LẠI ÂM THANH GIỌNG THỰC BẰNG AUDIOTRACK
     */
    private fun startPcmPlayback(filePath: String): Boolean {
        var targetFile = File(filePath)

        // Hỗ trợ tìm kiếm file nếu nhận đường dẫn tương đối
        if (!targetFile.exists()) {
            targetFile = File(filesDir, filePath)
        }
        if (!targetFile.exists() && currentRecordingFilePath.isNotEmpty()) {
            targetFile = File(currentRecordingFilePath)
        }

        if (!targetFile.exists() || isPlaying) return false

        val minBufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfigPlay, audioFormat)
        if (minBufferSize <= 0) return false

        try {
            audioTrack = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                channelConfigPlay,
                audioFormat,
                minBufferSize * 2,
                AudioTrack.MODE_STREAM
            )
        } catch (e: Exception) {
            return false
        }

        val trackObj = audioTrack ?: return false
        if (trackObj.state != AudioTrack.STATE_INITIALIZED) return false

        isPlaying = true
        trackObj.play()

        playbackThread = thread(start = true) {
            var inStream: FileInputStream? = null
            try {
                inStream = FileInputStream(targetFile)
                if (targetFile.length() > 44) {
                    inStream.skip(44) // Bỏ qua 44 bytes header WAV
                }

                val buffer = ByteArray(minBufferSize)
                var bytesRead = inStream.read(buffer)

                while (isPlaying && bytesRead != -1) {
                    trackObj.write(buffer, 0, bytesRead)
                    bytesRead = inStream.read(buffer)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                inStream?.close()
                stopPcmPlayback()
            }
        }

        return true
    }

    private fun stopPcmPlayback() {
        isPlaying = false
        try {
            audioTrack?.stop()
            audioTrack?.release()
            audioTrack = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
        playbackThread = null
    }

    private fun writeWavHeader(file: File, totalAudioLen: Long, sampleRate: Int, channels: Int, bitsPerSample: Int) {
        val totalDataLen = totalAudioLen + 36
        val byteRate = sampleRate * channels * bitsPerSample / 8

        val header = ByteArray(44)
        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        header[4] = (totalDataLen and 0xff).toByte()
        header[5] = (totalDataLen shr 8 and 0xff).toByte()
        header[6] = (totalDataLen shr 16 and 0xff).toByte()
        header[7] = (totalDataLen shr 24 and 0xff).toByte()
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        header[16] = 16
        header[17] = 0
        header[18] = 0
        header[19] = 0
        header[20] = 1
        header[21] = 0
        header[22] = channels.toByte()
        header[23] = 0
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = (sampleRate shr 8 and 0xff).toByte()
        header[26] = (sampleRate shr 16 and 0xff).toByte()
        header[27] = (sampleRate shr 24 and 0xff).toByte()
        header[28] = (byteRate and 0xff).toByte()
        header[29] = (byteRate shr 8 and 0xff).toByte()
        header[30] = (byteRate shr 16 and 0xff).toByte()
        header[31] = (byteRate shr 24 and 0xff).toByte()
        header[32] = (channels * bitsPerSample / 8).toByte()
        header[33] = 0
        header[34] = bitsPerSample.toByte()
        header[35] = 0
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        header[40] = (totalAudioLen and 0xff).toByte()
        header[41] = (totalAudioLen shr 8 and 0xff).toByte()
        header[42] = (totalAudioLen shr 16 and 0xff).toByte()
        header[43] = (totalAudioLen shr 24 and 0xff).toByte()

        val raf = RandomAccessFile(file, "rw")
        raf.seek(0)
        raf.write(header)
        raf.close()
    }

    override fun onDestroy() {
        stopAudioPassthrough()
        stopPcmRecording()
        stopPcmPlayback()
        super.onDestroy()
    }
}
