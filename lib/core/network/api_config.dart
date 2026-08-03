class ApiConfig {
  // baseUrl depends on the environment.
  // 10.0.2.2 is the special alias to your host loopback interface (localhost) from the Android emulator.
  // If you are using a physical device, replace this with your machine's Wi-Fi IPv4 address (e.g. 192.168.1.X:8000).
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // API Endpoints
  static const String requestPasswordReset = '$baseUrl/usuarios/password-reset/request/';
  static const String confirmPasswordReset = '$baseUrl/usuarios/password-reset/confirm/';
  static const String registerParent = '$baseUrl/usuarios/parent-registration/';
  static const String registerStudent = '$baseUrl/usuarios/student-registration/';
}
