// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'dart:collection';

import 'package:tuple/tuple.dart';

class ThumbnailManager {
  static HashMap<int, Tuple3<List<String>, List<String>, List<String>>> _ids =
      HashMap<int, Tuple3<List<String>, List<String>, List<String>>>();

  static bool isExists(int id) {
    return _ids.containsKey(id);
  }

  static void insert(
      int id, Tuple3<List<String>, List<String>, List<String>> url) {
    _ids[id] = url;
  }

  static Tuple3<List<String>, List<String>, List<String>> get(int id) {
    return _ids[id];
  }

  static void clear() {
    _ids.clear();
  }
}
