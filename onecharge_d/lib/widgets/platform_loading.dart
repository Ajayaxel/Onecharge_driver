import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PlatformLoading extends StatelessWidget {
  final Color? color;
  final double radius;

  const PlatformLoading({super.key, this.color, this.radius = 15});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(color: color, radius: radius);
    }
    return CircularProgressIndicator(
      color: color ?? Colors.black,
      strokeWidth: 3,
    );
  }
}
