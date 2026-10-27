# ProGuard / R8 rules cho WakeUp+
#
# Bản build release chạy R8 shrink + obfuscate. Những quy tắc dưới đây giữ lại
# những thứ R8 không thể tự suy luận là đang dùng.

# --- Play Core (Deferred Components) ----------------------------------------
# Flutter khai báo `FlutterPlayStoreSplitApplication` và
# `PlayStoreDeferredComponentManager`, chúng tham chiếu lớp của Play Core.
# App này KHÔNG dùng deferred components nên các lớp đó không tồn tại.
#
# Nếu không khai báo `-dontwarn`, R8 dừng build với lỗi:
#   "Missing classes detected while running R8"
#
# Đây là cấu hình chuẩn, mọi project Flutter bật R8 đều cần.
-dontwarn com.google.android.play.core.**

# --- Âm thanh báo thức -------------------------------------------------------
# LƯU Ý: hiện KHÔNG còn rule nào cho res/raw, và điều đó là CỐ Ý.
#
# `AlarmService.resolveSoundResourceId()` liệt kê tường minh bằng `R.raw.xxx`
# thay vì `resources.getIdentifier()` — nên tham chiếu là TĨNH và R8 nhìn thấy.
# Đã kiểm chứng trên APK release: 12/12 file còn nguyên trong resources.arsc.
#
# Nếu sau này ai đó đổi lại sang getIdentifier(), `shrinkResources` sẽ XOÁ SẠCH
# file âm thanh và chuông sẽ rơi về âm mặc định của hệ thống — mà không có lỗi nào
# báo ra. Khi đó phải thêm lại rule giữ resource, ví dụ tạo `res/raw/keep.xml`:
#     <?xml version="1.0" encoding="utf-8"?>
#     <resources xmlns:tools="http://schemas.android.com/tools"
#                tools:keep="@raw/alarm_*" />

# --- Flutter / plugin --------------------------------------------------------
# Đây là các quy tắc chuẩn mà Flutter khuyến nghị.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# --- Firebase / Crashlytics -------------------------------------------------
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*

# --- Supabase ----------------------------------------------------------------
-keep class io.supabase.** { *; }

# --- MethodChannel -----------------------------------------------------------
# MethodChannel xử lý bằng tên chuỗi nên không cần giữ, nhưng class MainActivity
# được gọi từ native nên phải giữ lại.
-keep class com.wakeup.app.MainActivity { *; }
-keep class com.wakeup.app.AlarmService { *; }
-keep class com.wakeup.app.AlarmReceiver { *; }
-keep class com.wakeup.app.AlarmTriggerReceiver { *; }
-keep class com.wakeup.app.AlarmWidgetProvider { *; }