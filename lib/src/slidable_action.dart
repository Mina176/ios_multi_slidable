import 'package:flutter/material.dart';

class SlidableAction {
  final Widget child;
  final Color color;
  final VoidCallback onTap;

  const SlidableAction({
    required this.child,
    required this.color,
    required this.onTap,
  });
}
