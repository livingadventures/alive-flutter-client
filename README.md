[![Pub version](https://img.shields.io/pub/v/alive?color=blue)](https://pub.dev/packages/alive) [![Sponsors](https://img.shields.io/badge/sponsor-buy%20me%20a%20coffee-yellow)](https://www.buymeacoffee.com/jonorozcoc) ![Contributors](https://img.shields.io/github/contributors/livingadventures/alive-flutter-client?color=blue) [![Discord](https://img.shields.io/discord/937492655854735360)](https://discord.gg/ZXrJ6zW5)

Alive is a library inspired by [Socket.IO](https://socket.io/) for enabling "real"-time communication on multiple platforms. The current implementation works on Dart/Flutter

> Help me reach more people! Increasing alive community will make the package more stable with your feedback ❤

![Like the project](docs\images\likes.png)

## Features

Current features:

- [x] Message broadcasting
- [x] Message channels

On road-map:

- [ ] Private channels
- [ ] Authentication

## Getting started

Before using the library, be sure you already have a server instance running

## Usage

Connect to server and listen to broadcast messages

```dart
import 'package:alive/alive.dart';
import 'package:flutter/material.dart';

late Client client;

void main() {
  client = Client(url: 'ws://localhost:4000/');
  client.connect();
  client.on().listen((message) => print(message.data));
  runApp(const MyApp());
}
```

Connect to server and listen to specific channel

```dart
import 'package:alive/alive.dart';
import 'package:flutter/material.dart';

late Client client;

void main() {
  client = Client(url: 'ws://localhost:4000/');
  client.connect();
  client.subscribe('test');
  client.on('test').listen((message) => print(message.data));
  runApp(const MyApp());
}
```

## Additional information

No additional information

<!-- TODO: Add additional information -->
