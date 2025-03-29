import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/widgets/map_style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  LatLng userPos = LatLng(40.428246, -86.914391);
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    _moveToUser();
  }

  void _moveToUser() async {
    final GoogleMapController controller = await _controller.future;
    userPos = await _getUserLocation() ?? LatLng(40.428246, -86.914391);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: userPos, zoom: 15)),
    );

    positionStream = Geolocator.getPositionStream().listen((
      Position? position,
    ) {
      if (position == null) {
        return;
      }
      // print(
      //   '${position.latitude.toString()}, ${position.longitude.toString()}',
      // );
      setState(() {
        userPos = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<LatLng?> _getUserLocation() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(37.43296265331129, -122.08832357078792),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        // style: MyMapStyle.mapStyles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: const Text('To the lake!'),
      //   icon: const Icon(Icons.directions_boat),
      // ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
