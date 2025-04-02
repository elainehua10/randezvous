import 'package:flutter/material.dart';

class BeaconMapMarker extends StatelessWidget {
  final String? title;

  const BeaconMapMarker({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Optional title pill
        if (title != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              title!,
              style: TextStyle(
                color: Colors.amber[800],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

        if (title != null) const SizedBox(height: 8),

        // Beacon marker
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle with shadow
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber[50],
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),

            // Middle circle - amber color
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber[400],
              ),
            ),

            // Inner circle - white
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),

            // Beacon icon
            Icon(Icons.location_on, color: Colors.amber[800], size: 26),
          ],
        ),

        // Triangle pointer
        Transform.translate(
          offset: Offset(0, -5),
          child: ClipPath(
            clipper: TriangleClipper(),
            child: Container(
              width: 20,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.amber[400],
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clipper for the pointer triangle
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
