// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SearchBarSliver implements SliverPersistentHeaderDelegate {
  SearchBarSliver({this.minExtent, @required this.maxExtent, this.searchBar});
  final double minExtent;
  final double maxExtent;

  Widget searchBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedOpacity(
          child: searchBar,
          opacity: 1.0 - max(0.0, shrinkOffset - 20) / (maxExtent - 20),
          duration: Duration(milliseconds: 100),
        )
      ],
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration => null;

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration => null;
}
