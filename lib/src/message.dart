class Message {
  final String? channel;
  final Object? message;

  Message({
    required this.channel,
    required this.message,
  });

  @override
  String toString() {
    return 'channel: $channel, message: $message';
  }
}
