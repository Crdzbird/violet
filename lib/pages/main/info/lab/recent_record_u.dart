// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/query.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/log/log.dart';
import 'package:violet/model/article_list_item.dart';
import 'package:violet/pages/artist_info/artist_info_page.dart';
import 'package:violet/pages/main/info/lab/recent_user_record.dart';
import 'package:violet/pages/segment/card_panel.dart';
import 'package:violet/server/community/anon.dart';
import 'package:violet/server/violet.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/article_item/article_list_item_widget.dart';

class LabRecentRecordsU extends StatefulWidget {
  @override
  _LabRecentRecordsUState createState() => _LabRecentRecordsUState();
}

class _LabRecentRecordsUState extends State<LabRecentRecordsU> {
  List<Tuple3<QueryResult, int, String>> records =
      <Tuple3<QueryResult, int, String>>[];
  int latestId = 0;
  int limit = 10;
  Timer timer;
  ScrollController _controller = ScrollController();
  bool isTop = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        if (_controller.position.pixels == 0) {
          isTop = false;
        } else {
          isTop = true;
        }
      } else
        isTop = false;
    });

    Future.delayed(Duration(milliseconds: 100)).then(updateRercord).then(
        (value) => Future.delayed(Duration(milliseconds: 100)).then((value) =>
            _controller.animateTo(_controller.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn)));
    timer = Timer.periodic(Duration(seconds: 1), updateRercord);
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> updateRercord(dummy) async {
    try {
      var trecords = await VioletServer.recordU(latestId, 10, limit);
      if (trecords is int || trecords == null || trecords.length == 0) return;

      var xrecords = trecords as List<Tuple4<int, int, int, String>>;

      latestId = max(latestId,
          xrecords.reduce((x, y) => x.item1 > y.item1 ? x : y).item1 + 1);

      var queryRaw = HitomiManager.translate2query(Settings.includeTags +
              ' ' +
              Settings.excludeTags
                  .where((e) => e.trim() != '')
                  .map((e) => '-$e')
                  .join(' ')) +
          ' AND ';

      queryRaw += '(' + xrecords.map((e) => 'Id=${e.item2}').join(' OR ') + ')';
      var query = await QueryManager.query(queryRaw);

      if (query.results.length == 0) return;

      var qr = Map<String, QueryResult>();
      query.results.forEach((element) {
        qr[element.id().toString()] = element;
      });

      var result = <Tuple3<QueryResult, int, String>>[];
      xrecords.forEach((element) {
        if (qr[element.item2.toString()] == null) {
          return;
        }
        result.add(Tuple3<QueryResult, int, String>(
            qr[element.item2.toString()], element.item3, element.item4));
      });

      records.insertAll(0, result);

      if (isTop) {
        setState(() {});
        Future.delayed(Duration(milliseconds: 50)).then((x) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
          );
        });
      } else
        setState(() {});
    } catch (e, st) {
      Logger.error(
          '[lab-recent_record] E: ' + e.toString() + '\n' + st.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    var xrecords = records.where((x) => x.item2 > limit).toList();
    var windowWidth = MediaQuery.of(context).size.width;
    return CardPanel.build(
      context,
      enableBackgroundColor: true,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(0),
              controller: _controller,
              physics: BouncingScrollPhysics(),
              itemCount: xrecords.length,
              reverse: true,
              itemBuilder: (BuildContext ctxt, int index) {
                return Align(
                  key: Key('records' +
                      index.toString() +
                      '/' +
                      xrecords[xrecords.length - index - 1]
                          .item1
                          .id()
                          .toString()),
                  alignment: Alignment.center,
                  child: Provider<ArticleListItem>.value(
                    value: ArticleListItem.fromArticleListItem(
                      queryResult: xrecords[xrecords.length - index - 1].item1,
                      showDetail: true,
                      addBottomPadding: true,
                      width: (windowWidth - 4.0),
                      thumbnailTag: Uuid().v4(),
                      seconds: xrecords[xrecords.length - index - 1].item2,
                      doubleTapCallback: () => _doubleTapCallback(
                          xrecords[xrecords.length - index - 1].item3),
                    ),
                    child: ArticleListItemVerySimpleWidget(),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Container(width: 16),
              Text('Limit: $limit${Translations.instance.trans('second')}'),
              Expanded(
                child: ListTile(
                  dense: true,
                  title: Align(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: Color(0xffd0d2d3),
                        trackHeight: 3,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        value: limit.toDouble(),
                        max: 180,
                        min: 0,
                        divisions: (180 - 0),
                        inactiveColor: Settings.majorColor.withOpacity(0.7),
                        activeColor: Settings.majorColor,
                        onChangeEnd: (value) async {
                          limit = value.toInt();
                        },
                        onChanged: (value) {
                          setState(() {
                            limit = value.toInt();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _doubleTapCallback(String userAppId) {
    _navigate(LabUserRecentRecords(userAppId));
  }

  _navigate(Widget page) {
    if (!Platform.isIOS) {
      Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        pageBuilder: (_, __, ___) => page,
      ));
    } else {
      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => page));
    }
  }
}
