import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:alive/src/message.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Client {
  final String url;
  final String? apiKey;

  late String _connectionUrl;
  late IOWebSocketChannel socketChannel;

  final StreamController<String> _dataController = StreamController();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController();

  bool _connected = false;

  bool get connected => _connected;

  int _retryTimeout = 0;
  final double _retryIncrease = 1.65;

  final List<String> _subscribedChannels = [];

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

  Future<void> connect({bool closeOnError = true}) async {
    // TODO: retry strategy
    if (!_connected) {
      try {
        log('Connecting to $_connectionUrl');
        socketChannel = IOWebSocketChannel.connect(Uri.parse(_connectionUrl));
        socketChannel.stream.listen((message) {
          if (!_connected) {
            _connected = true;
            log('Connected to $_connectionUrl');
            if (_retryTimeout != 0) {
              _retryTimeout = 0;
            }
            if (_subscribedChannels.isNotEmpty) {
              _subscribeAll(_subscribedChannels);
            }
          }
          _dataController.add(message);
        }, onDone: () async {
          log('onDone on Connect function');
          if (socketChannel.closeCode != null) {
            log(socketChannel.closeCode.toString());
          }
          await _reconnect(closeOnError);
        }, onError: (Object exception, StackTrace? stackTrace) {
          if (exception is! WebSocketChannelException &&
              socketChannel.closeCode == null) {
            log('onError on Connect function');
            log(exception.toString());
            throw exception;
          }
        });
      } catch (exception) {
        log(exception.hashCode.toString());
        log(exception.toString());
        if (closeOnError) {
          throw Exception('Connection error');
        } else {
          await _reconnect(closeOnError);
        }
      }
    }
  }

  void disconnect() {
    if (_connected) {
      log('Disconnecting');
      _connected = false;
      _dataController.close();
      socketChannel.sink.close();
      log('Disconnected');
    }
  }

  Future<void> _reconnect(bool closeOnError) async {
    _connected = false;
    if (_retryTimeout == 0) {
      _retryTimeout = 400;
    } else {
      int rounded = (_retryTimeout * _retryIncrease).round();
      int difference = 100 - (rounded % 100);
      _retryTimeout = rounded + difference;
    }
    log('Waiting $_retryTimeout to reconnect');
    await Future.delayed(Duration(milliseconds: _retryTimeout), () async {
      await connect(closeOnError: closeOnError);
    });
  }

  void _send(Map<String, dynamic> data) {
    socketChannel.sink.add(jsonEncode(data));
  }

  void _subscribe(String channel) {
    log('Subscribing to $channel');
    _send(
      {
        'event': 'subscribe',
        'channel': channel,
      },
    );
    log('Subscribed to $channel');
  }

  void _subscribeAll(List<String> channels) {
    for (String channel in channels) {
      _subscribe(channel);
    }
  }

  void _unsubscribe(String channel) {
    log('Unsubscribing to $channel');
    _send(
      {
        'event': 'unsubscribe',
        'channel': channel,
      },
    );
    log('Unsubscribed to $channel');
  }

  void subscribe(String channel) {
    if (_connected) {
      _subscribe(channel);
    }
    _subscribedChannels.add(channel);
  }

  void subscribeAll(List<String> channels) {
    for (String channel in channels) {
      subscribe(channel);
    }
  }

  void unsubscribe(String channel) {
    if (_connected) {
      _unsubscribe(channel);
    }
    _subscribedChannels.remove(channel);
  }

  void unsubscribeAll(List<String> channels) {
    for (String channel in channels) {
      unsubscribe(channel);
    }
  }

  void publish(String channel, Object data) {}

  Stream<Map<String, dynamic>> _onData() {
    _dataController.stream.listen((message) {
      _messageController.add(jsonDecode(message));
    }, onError: (Object exception, StackTrace? stackTrace) {
      log(exception.toString());
    }, onDone: () {
      log('Connection closed');
    });
    return _messageController.stream;
  }

  Stream<Message> on({
    String? channel,
    Function(Object, StackTrace?)? onError,
  }) async* {
    try {
      await for (final data in _onData()) {
        Message message = Message(
          channel: data['channel'],
          message: data['message'],
        );
        if (message.channel == channel) {
          yield message;
        }
      }
    } catch (exception) {
      if (onError != null) {
        onError(exception, StackTrace.current);
      }
    }
  }

  Future<Message?> first({String? channel}) async {
    await for (final data in _onData()) {
      Message message = Message(
        channel: data['channel'],
        message: data['message'],
      );
      if (message.channel == channel) {
        return message;
      }
    }
    return null;
  }
}
