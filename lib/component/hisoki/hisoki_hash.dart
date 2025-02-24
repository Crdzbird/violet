// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

class HisokiHash {
  static Map<String, String> hash;

  static Future<void> init() async {
    String data;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      var file = File('/home/ubuntu/violet/assets/hisoki.json');
      data = await file.readAsString();
    } else {
      data = await rootBundle.loadString('assets/hisoki.json');
    }

    Map<String, dynamic> _hashs = json.decode(data);
    hash = Map<String, String>();
    hash.addEntries(
        _hashs.entries.map((e) => MapEntry(e.key, e.value as String)).toList());
  }

  static String getHash(String id) {
    return hash[id];
  }
}
