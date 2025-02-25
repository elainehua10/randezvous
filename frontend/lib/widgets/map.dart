import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  LatLng userPos = LatLng(40.428246, -86.914391);
  LatLng prevUserPos = LatLng(
    40.428246,
    -86.914391,
  ); // Keep track of previous position
  StreamSubscription<Position>? positionStream;
  AnimationController? _animationController;
  Animation<double>? _latAnimation;
  Animation<double>? _lngAnimation;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _moveToUser();

    // Create an animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000), // Adjust duration as needed
    );

    // Set up update timer to redraw marker position during animation
    _updateTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (_latAnimation != null && _lngAnimation != null) {
        setState(() {
          userPos = LatLng(_latAnimation!.value, _lngAnimation!.value);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _updateTimer?.cancel();
    positionStream?.cancel();
    super.dispose();
  }

  void _moveToUser() async {
    final GoogleMapController controller = await _controller.future;
    userPos = await _getUserLocation() ?? LatLng(40.428246, -86.914391);
    prevUserPos = userPos; // Initialize previous position

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: userPos, zoom: 15)),
    );

    positionStream = Geolocator.getPositionStream().listen((
      Position? position,
    ) {
      if (position == null) {
        return;
      }

      // Store the previous position
      prevUserPos = userPos;

      // Create new target position
      LatLng newPos = LatLng(position.latitude, position.longitude);

      // Create animations for smooth transition
      _createPositionAnimation(prevUserPos, newPos);

      // Start the animation
      _animationController!.forward(from: 0.0);

      // Also update the camera to follow the user smoothly
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPos, zoom: 15),
        ),
      );
    });
  }

  void _createPositionAnimation(LatLng startPos, LatLng endPos) {
    // Create animations for latitude and longitude
    _latAnimation = Tween<double>(
      begin: startPos.latitude,
      end: endPos.latitude,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut, // Use a smoother curve
      ),
    );

    _lngAnimation = Tween<double>(
      begin: startPos.longitude,
      end: endPos.longitude,
    ).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
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
        // Enable this to make camera follow user automatically
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: const Text('To the lake!'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
