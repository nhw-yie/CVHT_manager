import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final String? initials;
  final double radius;
  final Color? borderColor;

  const AvatarWidget({Key? key, this.imageUrl, this.assetPath, this.initials, this.radius = 24, this.borderColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      inner = CircleAvatar(radius: radius, backgroundImage: NetworkImage(imageUrl!));
    } else if (assetPath != null && assetPath!.isNotEmpty) {
      inner = CircleAvatar(radius: radius, backgroundImage: AssetImage(assetPath!));
    } else {
      inner = CircleAvatar(radius: radius, child: Text(initials ?? '', style: TextStyle(fontSize: radius / 2)));
    }

    if (borderColor != null) {
      return CircleAvatar(radius: radius + 2, backgroundColor: borderColor, child: ClipOval(child: inner));
    }
    return inner;
  }
}
