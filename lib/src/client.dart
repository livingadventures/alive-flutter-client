import 'dart:convert';

import 'package:alive/src/message.dart';
import 'package:web_socket_channel/io.dart';

class Client {
  final String url;
  final String? apiKey;
  late String _connectionUrl;
  late IOWebSocketChannel socketChannel;
  Client({
    required this.url,
    this.apiKey,
  }) {
    if (url.isEmpty) {
      throw Exception('Invalid URL');
    }
    try {
      _connectionUrl = apiKey == null ? url : '$url?apiKey=$apiKey';
      Uri uri = Uri.parse(_connectionUrl);
      if (!['ws', 'wss'].contains(uri.scheme)) {
        throw Exception('Invalid URL');
      }
    } catch (exception) {
      if (exception is FormatException) {
        throw Exception('Invalid URL');
      }
    }
  }

  void connect() {
    try {
      socketChannel = IOWebSocketChannel.connect(Uri.parse(_connectionUrl));
    } catch (exception) {
      throw Exception('Connection error');
    }
  }

  void subscribe(String channel) {
    socketChannel.sink.add(
      jsonEncode(
        {
          'event': 'subscribe',
          'channel': channel,
        },
      ),
    );
  }

  void publish(String channel, Object data) {}

  Stream<Message> _onMessage() async* {
    await for (final message in socketChannel.stream) {
      Map<String, dynamic> data = jsonDecode(message);
      yield Message(
        channel: data['channel'],
        message: data['message'],
      );
    }
  }

  Stream<Message> on([String? channel]) async* {
    await for (final message in _onMessage()) {
      if (message.channel == channel) {
        yield message;
      }
    }
  }
}
