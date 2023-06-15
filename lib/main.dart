import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:bonsoir/bonsoir.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late SpeechToText _speech;
  late bool _isListening = false;
  late BonsoirDiscovery _mdnsService;
  String _text = 'Press the button and start speaking...';
  // This is the type of service we're looking for :
  //final String _type = '_services._dns-sd._udp';
  final String _type = '_home-assistant._tcp';
  bool _ismdnsServiceReady = false;

  @override
  void initState() {
    super.initState();
    _speech = SpeechToText();
    _isListening = true;
    _mdnsService = BonsoirDiscovery(type: _type);
  }

  void mdnsReady() async {
    await _mdnsService.ready;
  }

  void startListening() {}

  void stopListening() {}

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () async {
                  if (!_mdnsService.isReady) {
                    await _mdnsService.ready;
                    setState(() {
                      _ismdnsServiceReady = true;
                    });

                    _mdnsService.eventStream?.listen((event) {
                      //print("something interesting happened");
                      //print(event.type);
                      if (event.type ==
                          BonsoirDiscoveryEventType.discoveryServiceResolved) {
                        print('Service found : ${event.service?.toJson()}');
                      } else if (event.type ==
                          BonsoirDiscoveryEventType.discoveryServiceLost) {
                        print('Service lost : ${event.service?.toJson()}');
                      }
                    });
                    await _mdnsService.start();
                  }
                },
                child: const Text("Refresh MDNS List")),
            Text(
              _text,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            StreamBuilder(
                stream: _mdnsService.eventStream,
                builder: (context, snapshot) {
                  if (_ismdnsServiceReady) {
                    if (snapshot.hasData) {
                      var boo = snapshot.data;
                      if (boo?.isServiceResolved == null) {
                      } else {
                        var name = boo?.service?.name ?? 'no name';
                        var port = boo?.service?.port ?? 'no port';
                        var attributes = boo?.service?.attributes;

                        var ipaddress =
                            attributes?["base_url"] ?? 'no ip address';
                        var uri = Uri.parse(ipaddress);
                        var ip = uri.host;
                        return Text(
                            'N: $name P: $port IP: $ipaddress onlyip: $ip');
                      }
                    } else {
                      return const Text("ready, but no data");
                    }
                  }
                  return const Text("no data");
                })
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        tooltip: 'Increment',
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => print(status),
        onError: (errorNotification) => print(errorNotification),
      );
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }
}
