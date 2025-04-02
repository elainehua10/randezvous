import 'package:flutter/material.dart';

class CustomMapMarker extends StatelessWidget {
  final String? avatarUrl;
  final String username;

  const CustomMapMarker({Key? key, this.avatarUrl, required this.username})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            username,
            style: TextStyle(
              color: Colors.amber[800],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Avatar with bottom pointer
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Avatar container
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber[50],
                backgroundImage: _getBackgroundImage(),
                child:
                    _shouldShowIcon()
                        ? Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.amber[800],
                        )
                        : null,
              ),
            ),
            // Pointer for map marker
            Positioned(
              bottom: -8,
              child: ClipPath(
                clipper: TriangleClipper(),
                child: Container(width: 16, height: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to determine background image
  ImageProvider<Object>? _getBackgroundImage() {
    if (avatarUrl != null && avatarUrl != "pfp" && avatarUrl!.isNotEmpty) {
      return NetworkImage(avatarUrl!);
    }
    return null;
  }

  // Helper method to determine whether to show icon
  bool _shouldShowIcon() {
    return avatarUrl == null || avatarUrl == "pfp" || avatarUrl!.isEmpty;
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
