# Adhan audio

`adhan_placeholder.wav` is a **synthesized placeholder chime** (3 notes),
NOT a real Adhan recitation. It exists so prayer notifications have a
distinct, gentle tone out of the box.

## Replacing with a real Adhan

1. Obtain a **licensed** Adhan recording (reciter permission / royalty-free
   license). Never bundle a recording you do not have rights to.
2. Convert to WAV (16-bit PCM mono, ≤ 30 s recommended for notifications):
   `ffmpeg -i adhan.mp3 -ac 1 -ar 22050 adhan.wav`
3. Overwrite BOTH copies:
   - `assets/audio/adhan_placeholder.wav` (Flutter asset, informational)
   - `android/app/src/main/res/raw/adhan_placeholder.wav`
     (this is what Android actually plays — referenced as
     `RawResourceAndroidNotificationSound('adhan_placeholder')` in
     `lib/core/services/notifications/local_notification_service.dart`)
4. For iOS: add the file to the Runner target and set the sound name in
   the Darwin notification details (currently defaults to system sound).
