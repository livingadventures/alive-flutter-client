import 'package:alive/alive.dart';
import 'package:flutter/material.dart';

late Client client;

void main() {
  client = Client(url: 'ws://localhost:4000/');
  client.connect();
  client.subscribe('test');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Alive example app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: StreamBuilder(
            stream: client.on('test'),
            builder: (BuildContext context, AsyncSnapshot<Message> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Channel: ${snapshot.data!.channel ?? 'Broadcast message (null)'}',
                    ),
                    Text(
                      'Message: ${snapshot.data!.message!.toString()}',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ],
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}
