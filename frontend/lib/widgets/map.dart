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
  double _currentPoints = 10.0; // Default to max points
  DateTime? _beaconStartTime;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
    _moveToUser();
  }

  double _calculatePoints(int timeTakenInSeconds) {
    const double maxPoints = 10.0; // Maximum points
    const double minPoints = 2.0; // Minimum points
    const double decayRate = 0.005; // Adjust this to control the decay rate

    // Calculate points using exponential decay
    double points = maxPoints * (1 / (1 + decayRate * timeTakenInSeconds));

    // Clamp points between minPoints and maxPoints
    return points.clamp(minPoints, maxPoints);
  }

  void _closeBeaconModal() {
    if (_beaconStartTime == null) return;

    final timeTakenInSeconds =
        DateTime.now().difference(_beaconStartTime!).inSeconds;
    final points = _calculatePoints(timeTakenInSeconds);

    print("Time taken in seconds: $timeTakenInSeconds");
    print("Calculated points: $points");

    setState(() {
      _currentPoints = points;
      _showBeaconReachedModal = false;
      _beaconMessage = "";
      _showConfirmationMessage = true; // Show confirmation message
    });

    // Hide confirmation message after a few seconds
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfirmationMessage = false; // Hide it after 2 seconds
        });
      }
    });
  }

  Widget _buildConfirmationMessage(double points) {
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
            'Congrats! ${points.toStringAsFixed(1)} Points have been rewarded!',
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

    print("Connecting to WebSocket at ${Util.BACKEND_URL}/locations");

    _channel = WebSocketChannel.connect(
      Uri.parse(
        // 'ws://localhost:5001/locations',
        // Platform.isAndroid
        //     ? "ws://10.0.2.2:5001/locations"
        //     : 'ws://localhost:5001/locations',
        "ws://${Util.HOST_NAME}/locations",
      ), // Replace with your server URL
    );

    _channel!.stream.listen(
      (message) {
        if (message == "You've reached the beacon!") {
          setState(() {
            _beaconMessage = "You've reached the beacon!";
            _showBeaconReachedModal = true;
            _beaconStartTime = DateTime.now(); // Record the start time
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
            onTap:
                user.id == "BEACON"
                    ? () => _showBeaconOptions(context, user.id)
                    : null,
          );
        }).toList();

    final resolvedMarkers = await Future.wait(markers);
    if (mounted) {
      setState(() => _markers = resolvedMarkers.toSet());
    }
  }

  void _showBeaconOptions(BuildContext context, String beaconId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Report Beacon Location",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _showReportConfirmation(context, beaconId); // Trigger report
              },
              icon: Icon(Icons.report, size: 20),
              label: Text("Report"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReportConfirmation(BuildContext context, String beaconId) {
    final List<String> reportReasons = [
      "Dangerous location",
      "Inaccessible location",
      "Other",
    ];

    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        String selectedReason = reportReasons[0];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Report Beacon"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reportReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedReason = value;
                            });
                          }
                        },
                      );
                    }).toList(),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: "Additional details (optional)",
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    Navigator.pop(context);

                    print("Reporting ${beaconId}");
                    print("Reason: $selectedReason");
                    print("Details: ${descriptionController.text}");

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Report submitted. Thank you.")),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
                    onPressed: () => _closeBeaconModal(),
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
                onPressed: () => _closeBeaconModal(),
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
        _buildConfirmationMessage(_currentPoints),
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
