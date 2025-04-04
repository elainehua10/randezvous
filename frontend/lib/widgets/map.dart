import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/auth.dart'; // Assuming Auth class is here
import 'package:frontend/models/user.dart';
import 'package:frontend/util.dart';
import 'package:frontend/widgets/beacon_marker.dart';
import 'package:frontend/widgets/map_style.dart';
import 'package:frontend/widgets/user_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MapWidget extends StatefulWidget {
  final String? activeGroupId; // Pass the selected group ID

  const MapWidget({super.key, this.activeGroupId});

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LatLng userPos = const LatLng(40.428246, -86.914391);
  StreamSubscription<Position>? positionStream;
  WebSocketChannel? _channel;
  Set<Marker> _markers = {};
  Map<String, User> _userLocations = {}; // Track user locations
  bool _showBeaconReachedModal = false;
  String _beaconMessage = "";
  bool _showConfirmationMessage = false; // Confirmation message state

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
    _moveToUser();
  }

  void _closeBeaconModal() {
    setState(() {
      _showBeaconReachedModal = false;
      _beaconMessage = "";
      _showConfirmationMessage = true; // Show confirmation message
    });

    // Hide confirmation message after a few seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showConfirmationMessage = false; // Hide it after 2 seconds
        });
      }
    });
  }

  Widget _buildConfirmationMessage() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showConfirmationMessage ? 40 : -100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Text(
            'Congrats! Points have been rewarded!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeGroupId != oldWidget.activeGroupId) {
      setState(() {
        _markers = {}; // Reset markers
        _userLocations = {}; // Reset user locations
      });
      _updateWebSocketGroup();
    }
  }

  void _connectToWebSocket() async {
    final token = await Auth.getAccessToken();
    if (token == null) return;

    _channel = WebSocketChannel.connect(
      Uri.parse(
        // 'ws://localhost:5001/locations',
        Platform.isAndroid
            ? "ws://10.0.2.2:5001/locations"
            : 'ws://localhost:5001/locations',
      ), // Replace with your server URL
    );

    _channel!.stream.listen(
      (message) {
        if (message == "You've reached the beacon!") {
          setState(() {
            _beaconMessage = "You've reached the beacon!";
            _showBeaconReachedModal = true;
          });
          return;
        }
        final data = jsonDecode(message) as Map<String, dynamic>;

        // Otherwise process as a location update
        final location = User.fromJson(data);
        setState(() {
          _userLocations[location.id] = location;
          _updateMarkers();
        });
      },
      onError: (error) => print("WebSocket error: $error"),
      onDone: () => print("WebSocket closed"),
    );
  }

  void _updateWebSocketGroup() {
    _sendLocation(userPos.latitude, userPos.longitude);
  }

  void _sendLocation(double latitude, double longitude) async {
    if (_channel == null) return;
    final token = await Auth.getAccessToken();
    if (token == null) return;

    final message = {
      "authToken": token,
      "longitude": longitude,
      "latitude": latitude,
      "activeGroupId": widget.activeGroupId ?? -1,
    };

    _channel!.sink.add(jsonEncode(message));
  }

  void _moveToUser() async {
    final GoogleMapController controller = await _controller.future;
    final pos = await _getUserLocation() ?? const LatLng(40.428246, -86.914391);
    setState(() => userPos = pos);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: userPos, zoom: 15)),
    );

    positionStream = Geolocator.getPositionStream().listen((
      Position? position,
    ) {
      if (position == null || !mounted) return;
      setState(() {
        userPos = LatLng(position.latitude, position.longitude);
        _sendLocation(position.latitude, position.longitude);
      });
      _updateMarkers();
    });
  }

  Future<LatLng?> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
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

  void _updateMarkers() async {
    final markers =
        _userLocations.values.map((user) async {
          final bitmap = await _createMarkerIcon(
            user.avatarUrl,
            user.username,
            user.id,
          );
          return Marker(
            markerId: MarkerId(user.id),
            position:
                user.latitude != null && user.longitude != null
                    ? LatLng(user.latitude!, user.longitude!)
                    : LatLng(0, 0),
            icon: bitmap,
            infoWindow: InfoWindow(title: user.username),
          );
        }).toList();

    final resolvedMarkers = await Future.wait(markers);
    if (mounted) {
      setState(() => _markers = resolvedMarkers.toSet());
    }
  }

  Future<BitmapDescriptor> _createMarkerIcon(
    String? profilePicture,
    String username,
    String userId,
  ) async {
    if (userId == "BEACON") {
      return BeaconMapMarker(title: "BEACON").toBitmapDescriptor();
    }
    // For simplicity, use a default icon; implement profile picture rendering if needed
    return CustomMapMarker(
      avatarUrl: profilePicture,
      username: username,
    ).toBitmapDescriptor();
    // To use profile pictures, you'd need to download the image and convert it to BitmapDescriptor
  }

  Widget _buildBeaconReachedModal() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showBeaconReachedModal ? 40 : -200,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber[800]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.celebration, color: Colors.amber[800], size: 28),
                  Text(
                    'Beacon Reached!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.amber[800]),
                    onPressed: _closeBeaconModal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Message Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Text(
                  _beaconMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _closeBeaconModal,
                child: const Text("I'm Here!"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        _buildBeaconReachedModal(),
        _buildConfirmationMessage(),
      ],
    );
  }

  @override
  void dispose() {
    print("DISPOSE");
    _controller.future.then((controller) {
      controller.dispose();
    });
    positionStream?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
