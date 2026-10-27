import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

class ApiClient {
  static final Dio _dio = Dio();

  // Đây là SHA-256 fingerprint của SSL certificate hợp lệ (Ví dụ: của backend API riêng)
  // Lấy mã này bằng lệnh openssl trên Terminal
  static const String _trustedFingerprint = 'A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0:U1:V2:W3:X4:Y5:Z6:A7:B8:C9:D0';

  static Dio get client {
    // Cấu hình SSL Pinning (Tường lửa chống nghe lén)
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // Bắt buộc kết nối trực tiếp, chặn mọi HTTP Proxy (ví dụ như Charles Proxy, Burp Suite)
        client.findProxy = (uri) => 'DIRECT';
        
        // Từ chối mọi Bad Certificate (ví dụ như tự cấp phát - self-signed)
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => false;
        
        return client;
      },
      validateCertificate: (X509Certificate? cert, String host, int port) {
        if (cert == null) return false;

        // Băm (Hash) chứng chỉ nhận được từ server bằng thuật toán SHA-256
        final serverFingerprint = sha256.convert(cert.der).toString().toUpperCase();
        final sanitizedServerFingerprint = _formatFingerprint(serverFingerprint);

        // Chặn kết nối ngay lập tức nếu mã băm không khớp
        if (sanitizedServerFingerprint != _trustedFingerprint) {
          debugPrint('CẢNH BÁO: Phát hiện tấn công MITM! Chứng chỉ không khớp.');
          return false; // Ngắt kết nối
        }

        return true; // Hợp lệ, cho phép gọi API
      },
    );

    return _dio;
  }

  // Hàm phụ trợ định dạng mã băm thành chuỗi có dấu ':' (giống output của openssl)
  static String _formatFingerprint(String hash) {
    StringBuffer formatted = StringBuffer();
    for (int i = 0; i < hash.length; i++) {
      if (i > 0 && i % 2 == 0) formatted.write(':');
      formatted.write(hash[i]);
    }
    return formatted.toString();
  }
}
