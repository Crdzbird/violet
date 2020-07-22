// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Translations {
  Translations(this.locale);

  final Locale locale;

  // Latest instance
  static Translations instance;

  static Translations of(BuildContext context) {
    return Localizations.of<Translations>(context, Translations);
  }

  Map<String, String> _sentences;

  Future<bool> load([String code]) async {
    if (code == null) {
      code = locale.languageCode;
      if (!code.contains('_')) {
        if (locale.scriptCode != null && locale.scriptCode != '')
          code += '_' + this.locale.scriptCode;
      }
      instance = this;
    }

    String data = await rootBundle.loadString('assets/locale/$code.json');
    Map<String, dynamic> _result = json.decode(data);

    this._sentences = new Map();
    _result.forEach((String key, dynamic value) {
      this._sentences[key] = value.toString();
    });

    return true;
  }

  String trans(String key) {
    return this._sentences[key];
  }
}

class TranslationsDelegate extends LocalizationsDelegate<Translations> {
  const TranslationsDelegate();

  @override
  bool isSupported(Locale locale) {
    var lc = ['ko', 'en', 'ja', 'zh', 'it'].contains(locale.languageCode);
    var sc = ['Hans', 'Hant'].contains(locale.scriptCode);
    if (locale.languageCode == 'zh') {
      return sc;
    }
    return lc || sc;
  }

  @override
  Future<Translations> load(Locale locale) async {
    Translations localizations = new Translations(locale);
    await localizations.load();

    print("Load ${locale.languageCode}");

    return localizations;
  }

  @override
  bool shouldReload(TranslationsDelegate old) => false;
}
