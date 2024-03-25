import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

main() {
  runApp(const QiblahApp());
}

class QiblahApp extends StatefulWidget {
  const QiblahApp({Key? key}) : super(key: key);

  @override
  State<QiblahApp> createState() => _QiblahAppState();
}

class _QiblahAppState extends State<QiblahApp> {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();

  final locationStream = StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => locationStream.stream;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    locationStream.close();
    FlutterQiblah().dispose();

    super.dispose();
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();

    if (locationStatus.enabled &&
        (locationStatus.status == LocationPermission.denied ||
            locationStatus.status == LocationPermission.deniedForever)) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      locationStream.sink.add(s);
    } else {
      locationStream.sink.add(locationStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: FutureBuilder(
              future: _deviceSupport,
              builder: (context, AsyncSnapshot<bool?> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error.toString()}");
                }

                return StreamBuilder(
                    stream: stream,
                    builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      if (!snapshot.data!.enabled) {
                        return const Text("Lokatsiyaga ruxsat berilmagan");
                      }

                      switch (snapshot.data!.status) {
                        case LocationPermission.always:
                        case LocationPermission.whileInUse:
                          return StreamBuilder(
                              stream: FlutterQiblah.qiblahStream,
                              builder: (context,
                                  AsyncSnapshot<QiblahDirection> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                final qiblahDirection = snapshot.data;

                                const pi = 3.14;

                                return Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                    maxHeight: 300,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.rotate(
                                          angle: ((qiblahDirection?.direction ??
                                                  0) *
                                              (pi / 180) *
                                              -1),
                                          child: SvgPicture.asset(
                                              "assets/compass.svg")),
                                      Transform.rotate(
                                          angle:
                                              ((qiblahDirection?.qiblah ?? 0) *
                                                  (pi / 180) *
                                                  -1),
                                          child: SvgPicture.asset(
                                              "assets/needle.svg")),
                                    ],
                                  ),
                                );
                              });
                        case LocationPermission.denied:
                          return const Text("Manzilga ruxsat o'chirilgan");
                        case LocationPermission.deniedForever:
                          return const Text(
                              "Manzilga ruxsat butunlayga o'chirilgan");
                        default:
                          return const SizedBox();
                      }
                    });
              }),
        ),
      ),
    );
  }
}
