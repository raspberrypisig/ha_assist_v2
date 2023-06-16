import 'package:flutter/material.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:go_router/go_router.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class HAInstances extends StatefulWidget {
  const HAInstances({super.key});

  @override
  State<HAInstances> createState() => _HAInstancesState();
}

class _HAInstancesState extends State<HAInstances> {
  late BonsoirDiscovery _mdnsService;
  //This is the type of service we're looking for :
  //final String _type = '_services._dns-sd._udp';
  final String _type = '_home-assistant._tcp';
  bool _ismdnsServiceReady = false;

  @override
  void initState() {
    super.initState();
    print("Init state");
    _mdnsService = BonsoirDiscovery(type: _type);
    _mdnsService.ready.whenComplete(() {
      _mdnsService.eventStream?.listen((event) {
        //print("something interesting happened");
        //print(event.type);
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          print('Service found : ${event.service?.toJson()}');
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceLost) {
          print('Service lost : ${event.service?.toJson()}');
        }
      });
      print("about to start mdns service");
      _mdnsService.start();
      print("started mdns service");
      setState(() {
        _ismdnsServiceReady = true;
      });
      print("set state mdns service ready");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  _mdnsService.stop();
                  context.goNamed('home');
                },
                child: const Text("Back")),
            ElevatedButton(
                onPressed: () async {
                  print("mdns button pressed");
                  if (!_mdnsService.isReady) {
                    await _mdnsService.ready;
                    //setState(() {
                    //  _ismdnsServiceReady = true;
                    //});
                    /*
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
                    */
                    //await _mdnsService.start();
                  }
                },
                child: const Text("Refresh MDNS List")),
            StreamBuilder(
                stream: _mdnsService.eventStream,
                builder: (context, snapshot) {
                  print("Something happening");
                  print(snapshot.hasData);
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
          ]),
    );
  }
}
