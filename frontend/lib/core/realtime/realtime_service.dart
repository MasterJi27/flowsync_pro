import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

class RealtimeEvent {
  const RealtimeEvent(this.name, this.payload);

  final String name;
  final dynamic payload;
}

class RealtimeService {
  io.Socket? _socket;
  final _events = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _events.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (AppConfig.isSupabaseEdgeBackend) {
      _events.add(const RealtimeEvent('socket:disabled', null));
      return;
    }

    disconnect();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect(
        (_) => _events.add(const RealtimeEvent('socket:connected', null)),
      )
      ..onDisconnect(
        (_) => _events.add(const RealtimeEvent('socket:disconnected', null)),
      )
      ..onAny((event, payload) => _events.add(RealtimeEvent(event, payload)))
      ..connect();
  }

  void joinShipment(String shipmentId) {
    _socket?.emit('shipment:join', shipmentId);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _events.close();
  }
}
