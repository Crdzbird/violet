// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'package:violet/database/database.dart';

class QueryResult {
  Map<String, dynamic> result;
  QueryResult({this.result});

  int id() => result['Id'];
  title() => result['Title'];
  ehash() => result['EHash'];
  type() => result['Type'];
  artists() => result['Artists'];
  characters() => result['Characters'];
  groups() => result['Groups'];
  language() => result['Language'];
  series() => result['Series'];
  tags() => result['Tags'];
  uploader() => result['Uploader'];
  published() => result['Published'];
  files() => result['Files'];
  classname() => result['Class'];

  DateTime getDateTime() {
    if (published() == null || published() == 0) return null;

    const epochTicks = 621355968000000000;
    const ticksPerMillisecond = 10000;

    var ticksSinceEpoch = (published() as int) - epochTicks;
    var ms = ticksSinceEpoch ~/ ticksPerMillisecond;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}

class QueryManager {
  String queryString;
  List<QueryResult> results;
  bool isPagination;
  int curPage;
  int itemsPerPage = 500;

  static Future<QueryManager> query(String rawQuery) async {
    QueryManager qm = new QueryManager();
    qm.queryString = rawQuery;
    qm.results = (await (await DataBaseManager.getInstance()).query(rawQuery))
        .map((e) => QueryResult(result: e))
        .toList();
    return qm;
  }

  static QueryManager queryPagination(String rawQuery) {
    QueryManager qm = new QueryManager();
    qm.isPagination = true;
    qm.curPage = 0;
    qm.queryString = rawQuery;
    return qm;
  }

  Future<List<QueryResult>> next() async {
    curPage += 1;
    return (await (await DataBaseManager.getInstance()).query(
            "$queryString ORDER BY Id DESC LIMIT $itemsPerPage OFFSET ${itemsPerPage * (curPage - 1)}"))
        .map((e) => QueryResult(result: e))
        .toList();
  }
}
