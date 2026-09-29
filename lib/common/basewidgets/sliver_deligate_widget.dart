import 'package:flutter/material.dart';

class SliverDelegateWidget extends SliverPersistentHeaderDelegate {
  Widget child;
  double containerHeight;
  SliverDelegateWidget({required this.child, required this.containerHeight});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => containerHeight;

  @override
  double get minExtent => containerHeight;

  @override
  bool shouldRebuild(SliverDelegateWidget oldDelegate) {
    return oldDelegate.maxExtent != containerHeight || oldDelegate.minExtent != containerHeight || child != oldDelegate.child;
  }
}