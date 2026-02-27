import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../storage/auth_storage.dart';
import 'api_constants.dart';

class ReverbService {
  static final ReverbService _instance = ReverbService._internal();
  factory ReverbService() => _instance;
  ReverbService._internal();

  IOWebSocketChannel? _rawChannel;
  final http.Client _httpClient = http.Client();
  bool _isInitializing = false;
  String? _currentSocketId;
  String? _currentToken;
  String? _subscribedChannel;
  Timer? _pingTimer;

  // Event callbacks
  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  final ValueNotifier<ChannelState> ticketsChannelState =
      ValueNotifier<ChannelState>(ChannelState.unsubscribed);

  Future<void> initialize() async {
    if (_isInitializing) return;
    if (_rawChannel != null && _currentSocketId != null) return;

    _isInitializing = true;

    try {
      final token = await AuthStorage.getToken();
      final userDataStr = await AuthStorage.getUserData();

      if (token == null || userDataStr == null) {
        _isInitializing = false;
        return;
      }

      _currentToken = token;
      final userData = jsonDecode(userDataStr);
      final driverId = userData['id'];
      final primaryChannelName = 'private-driver.$driverId.tickets';
      final connectionCompleter = Completer<void>();

      final wssUrl =
          'wss://${AppConfig.reverbHost}:${AppConfig.reverbPort}/app/${AppConfig.reverbAppKey}';

      _rawChannel = IOWebSocketChannel.connect(Uri.parse(wssUrl));

      _rawChannel!.stream.listen(
        (message) =>
            _handleRawMessage(message, primaryChannelName, connectionCompleter),
        onError: (e) {
          print('Reverb: ❌ Socket error: $e');
          ticketsChannelState.value = ChannelState.unsubscribed;
          if (!connectionCompleter.isCompleted)
            connectionCompleter.completeError(e);
        },
        onDone: () {
          print('Reverb: 🔌 Socket closed. Will reconnect on next app resume.');
          ticketsChannelState.value = ChannelState.unsubscribed;
          _currentSocketId = null;
          _rawChannel = null;
          _stopPing();
        },
      );

      // Wait for connection
      await connectionCompleter.future.timeout(const Duration(seconds: 20));

      // Small delay to allow other startup API calls to finish (me, vehicles, etc.)
      await Future.delayed(const Duration(seconds: 1));

      // Subscribe to tickets channel
      if (_currentSocketId != null) {
        await _subscribeToChannel(primaryChannelName);
      }

      // Subscribe to public channels via separate handler
      _subscribePublic('driver-locations');
      _subscribePublic('vehicle-locations');

      // Keep-alive ping every 25 seconds
      _startPing();

      _isInitializing = false;
    } catch (e) {
      print('Reverb: ❌ Init error: $e');
      _isInitializing = false;
    }
  }

  void _handleRawMessage(
    String message,
    String channelName,
    Completer<void> completer,
  ) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final event = json['event'] as String?;
      final channel = json['channel'] as String?;

      switch (event) {
        case 'pusher:connection_established':
          final data = jsonDecode(json['data'] as String);
          _currentSocketId = data['socket_id'] as String;
          print('Reverb: 🌐 Connected. ID: $_currentSocketId');
          if (!completer.isCompleted) completer.complete();
          break;

        case 'pusher_internal:subscription_succeeded':
          if (channel == channelName) {
            print('Reverb: 🎯 Subscribed to $channel');
            ticketsChannelState.value = ChannelState.subscribed;
            _subscribedChannel = channel;
          }
          break;

        case 'pusher:error':
          final data = json['data'];
          print('Reverb: 🚨 Server error: $data');
          break;

        case 'pusher:pong':
          // Keep-alive acknowledged
          break;

        default:
          // Log ALL unknown events so we can see the exact name from the backend
          if (event != null) {
            print(
              'Reverb: 📨 INCOMING EVENT -> "$event" on channel "$channel"',
            );
          }
          // Dispatch to registered listeners
          if (event != null && channel != null) {
            final listeners = _eventListeners[event];
            if (listeners != null) {
              final rawData = json['data'];
              dynamic parsedData = rawData;
              if (rawData is String) {
                try {
                  parsedData = jsonDecode(rawData);
                } catch (_) {}
              }
              for (final cb in listeners) {
                cb(parsedData);
              }
            }
          }
      }
    } catch (e) {
      // Ignore parse errors for non-JSON messages
    }
  }

  Future<void> _subscribeToChannel(
    String channelName, {
    int attempt = 1,
  }) async {
    const maxAttempts = 3;
    try {
      ticketsChannelState.value = ChannelState.subscribing;
      print(
        'Reverb: 🔐 Auth attempt $attempt/$maxAttempts for $channelName...',
      );

      final response = await _httpClient
          .post(
            Uri.parse(AppConfig.driverBroadcastingAuthUrl),
            headers: {
              'Authorization': 'Bearer $_currentToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'channel_name': channelName,
              'socket_id': _currentSocketId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final auth = data['auth'] as String;
        print('Reverb: ✅ Auth OK! Subscribing...');

        _rawChannel!.sink.add(
          jsonEncode({
            'event': 'pusher:subscribe',
            'data': {
              'channel': channelName,
              'auth': auth,
              if (data['channel_data'] != null)
                'channel_data': data['channel_data'].toString(),
            },
          }),
        );
      } else {
        print('Reverb: ❌ Auth failed (${response.statusCode})');
        ticketsChannelState.value = ChannelState.unsubscribed;
      }
    } catch (e) {
      print('Reverb: ❌ Auth attempt $attempt failed: $e');
      if (attempt < 3 && _rawChannel != null) {
        print('Reverb: ⏳ Retrying in 3 seconds...');
        await Future.delayed(const Duration(seconds: 3));
        await _subscribeToChannel(channelName, attempt: attempt + 1);
      } else {
        print('Reverb: ❌ All auth attempts failed.');
        ticketsChannelState.value = ChannelState.unsubscribed;
      }
    }
  }

  void _subscribePublic(String channelName) {
    _rawChannel?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName},
      }),
    );
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _rawChannel?.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ---- Public API ----

  void bindTicketOffered(Function(dynamic) callback) =>
      _addEventListener('ticket.offered', callback);

  void bindTicketUpdated(Function(dynamic) callback) =>
      _addEventListener('ticket.status_changed', callback);

  void bindTicketStatusChanged(Function(dynamic) callback) =>
      _addEventListener('ticket.status_changed', callback);

  void bindTicketCancelled(Function(dynamic) callback) =>
      _addEventListener('ticket.cancelled', callback);

  void bindLocationUpdated(Function(dynamic) callback) =>
      _addEventListener('location.updated', callback);

  void bindVehicleDroppedOff(Function(dynamic) callback) =>
      _addEventListener('vehicle.dropped_off', callback);

  void _addEventListener(String event, Function(dynamic) callback) {
    _eventListeners.putIfAbsent(event, () => []).add(callback);
  }

  /// Sends the driver's real-time GPS position to the backend via HTTP POST.
  ///
  /// The backend at POST /api/driver/location/update:
  ///   1. Updates the driver's `latitude`, `longitude`, and `last_location_updated_at`
  ///      in the database — this is what makes the customer app's freshness check pass.
  ///   2. Broadcasts `driver.location.updated` on the correct customer private channel
  ///      (`private-customer.{customerId}.driver-location`) so the customer map
  ///      updates in real time.
  ///
  /// We also fire a low-latency WebSocket client event on the public
  /// `driver-locations` channel so other drivers on the same home map can
  /// see each other move (the previous functionality).
  Future<void> sendLocationUpdate(double latitude, double longitude) async {
    // 1. HTTP POST → updates DB + triggers correct backend broadcast
    try {
      final token = _currentToken ?? await AuthStorage.getToken();
      if (token != null) {
        final response = await _httpClient
            .post(
              Uri.parse(ApiConstants.updateLocation),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'latitude': latitude,
                'longitude': longitude,
                'timestamp': DateTime.now().toUtc().toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          print(
            '📍 [ReverbService] Location updated via API ✅ '
            '(lat=$latitude, lng=$longitude)',
          );
        } else {
          print(
            '⚠️ [ReverbService] Location API returned ${response.statusCode}: '
            '${response.body}',
          );
        }
      }
    } catch (e) {
      print('⚠️ [ReverbService] Location HTTP update failed: $e');
    }

    // 2. WebSocket client event on the public driver-locations channel
    //    (peer visibility on the driver home map — best effort).
    //    Note: _subscribedChannel is the private tickets channel; we intentionally
    //    broadcast to the public 'driver-locations' channel here instead.
    if (_rawChannel != null) {
      try {
        print(
          '🔌 [ReverbService] Sending WS location event '
          '(tickets channel: $_subscribedChannel)',
        );
        _rawChannel!.sink.add(
          jsonEncode({
            'event': 'client-driver-location',
            'channel': 'driver-locations',
            'data': {'latitude': latitude, 'longitude': longitude},
          }),
        );
      } catch (_) {}
    }
  }

  void disconnect() {
    _stopPing();
    _rawChannel?.sink.close();
    _rawChannel = null;
    _currentSocketId = null;
    _subscribedChannel = null;
    _eventListeners.clear();
    ticketsChannelState.value = ChannelState.unsubscribed;
  }
}
