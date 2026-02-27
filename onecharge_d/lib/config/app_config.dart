/// 1Charge Driver app: Main app = app.onecharge.io, Reverb = separate service.
class AppConfig {
  // ----- Main app (API, auth, channel auth) -----
  static const String baseUrl = 'https://app.onecharge.io/api';

  /// Private channel auth (ticket offers) – must be main app, not Reverb.
  static const String driverBroadcastingAuthUrl =
      'https://app.onecharge.io/api/driver/broadcasting/auth';
  // ----- Reverb (WebSocket only) -----
  static const String reverbHost = 'one-charge-1-charge.up.railway.app';
  static const int reverbPort = 443;
  static const String reverbAppKey = '5csvb4sew88zqnmcxuqg';
  static const bool reverbUseTls = true;
}
