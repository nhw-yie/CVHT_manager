import 'package:flutter/material.dart';

enum LoadingMode { circular, linear, skeleton }

class LoadingIndicator extends StatelessWidget {
  final LoadingMode mode;
  final double? height;

  const LoadingIndicator({Key? key, this.mode = LoadingMode.circular, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case LoadingMode.linear:
        return LinearProgressIndicator(minHeight: height ?? 4);
      case LoadingMode.skeleton:
        return _Skeleton(height: height ?? 12);
      case LoadingMode.circular:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _Skeleton extends StatelessWidget {
  final double height;

  const _Skeleton({Key? key, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
    );
  }
}
