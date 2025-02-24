// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';
import 'package:violet/component/hentai.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/database/user/record.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/log/log.dart';
import 'package:violet/model/article_info.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/pages/article_info/article_info_page.dart';
import 'package:violet/pages/viewer/others/lifecycle_event_handler.dart';
import 'package:violet/pages/viewer/others/photo_view_gallery.dart';
import 'package:violet/pages/viewer/others/preload_page_view.dart';
import 'package:violet/pages/viewer/tab_panel.dart';
import 'package:violet/pages/viewer/v_cached_network_image.dart';
import 'package:violet/pages/viewer/view_record_panel.dart';
import 'package:violet/pages/viewer/viewer_gallery.dart';
import 'package:violet/pages/viewer/viewer_page_provider.dart';
import 'package:violet/pages/viewer/viewer_report.dart';
import 'package:violet/pages/viewer/viewer_setting_panel.dart';
import 'package:violet/server/violet.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';
import 'package:violet/widgets/article_item/image_provider_manager.dart';
import 'package:violet/widgets/toast.dart';

const volumeKeyChannel = const EventChannel('xyz.project.violet/volume');

class ViewerPage extends StatefulWidget {
  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage>
    with SingleTickerProviderStateMixin {
  ViewerPageProvider _pageInfo;
  Timer _clearTimer;
  int _prevPage = 1;
  double _opacity = 0.0;
  bool _disableBottom = true;
  PreloadPageController _pageController = PreloadPageController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool _sliderOnChange = false;
  TapDownDetails _doubleTapDetails;
  TransformationController _transformationController =
      TransformationController();
  bool scrollListEnable = true;
  int _mpPoints = 0;
  AnimationController _animationController;
  Animation<Matrix4> _animation;
  Timer _nextPageTimer;
  LifecycleEventHandler _lifecycleEventHandler;
  DateTime _inactivateTime;
  int currentPage = 0;
  DateTime _startsTime;
  int _inactivateSeconds = 0;
  bool isBookmarked = false;
  ViewerReport _report;
  List<int> _decisecondPerPages;
  bool _isStaring = true;
  List<bool> _isImageLoaded;
  bool _isSessionOutdated = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 100))
        .then((value) => _checkLatestRead());

    Future.delayed(Duration(milliseconds: 100)).then((value) async =>
        isBookmarked =
            await (await Bookmark.getInstance()).isBookmark(_pageInfo.id));

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..addListener(() {
        _transformationController.value = _animation.value;
      });

    itemPositionsListener.itemPositions.addListener(() {
      if (_sliderOnChange) return;

      var v = itemPositionsListener.itemPositions.value.toList();
      var selected;

      v.sort((x, y) => x.itemLeadingEdge.compareTo(y.itemLeadingEdge));

      for (var e in v) {
        if (e.itemLeadingEdge <= 0.125) {
          selected = e.index;
        } else {
          break;
        }
      }

      _getLatestHeight();

      if (selected != null && _prevPage != selected + 1) {
        setState(() {
          _prevPage = selected + 1;
          currentPage = _prevPage;
        });
      }
    });

    _lifecycleEventHandler = LifecycleEventHandler(
      inactiveCallBack: () async {
        _inactivateTime = DateTime.now();
        _isStaring = false;
        await (await User.getInstance())
            .updateUserLog(_pageInfo.id, currentPage);
      },
      resumeCallBack: () async {
        _inactivateSeconds +=
            DateTime.now().difference(_inactivateTime).inSeconds;
        _isStaring = true;
        setState(() {
          _mpPoints = 0;
        });
      },
    );

    WidgetsBinding.instance.addObserver(_lifecycleEventHandler);

    _startsTime = DateTime.now();

    startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageInfo == null) {
      _pageInfo = Provider.of<ViewerPageProvider>(context);
      _report = ViewerReport(
        id: _pageInfo.id,
        pages: _pageInfo.uris.length,
        startsTime: DateTime.now(),
      );
      _decisecondPerPages = List.filled(_pageInfo.uris.length, 0);

      _isImageLoaded = List.filled(_pageInfo.uris.length, false);

      Timer.periodic(
        Duration(milliseconds: 100),
        pageReadTimerCallback,
      );
    }
    volumeKeyChannel.receiveBroadcastStream().listen((event) {
      if (event as String == 'down') {
        _rightButtonEvent();
      } else if (event as String == 'up') {
        _leftButtonEvent();
      }
    });
  }

  @override
  void dispose() {
    if (_clearTimer != null) _clearTimer.cancel();
    if (_nextPageTimer != null) _nextPageTimer.cancel();
    PaintingBinding.instance.imageCache.clear();
    if (_pageInfo.useWeb)
      _pageInfo.uris.forEach((element) async {
        await CachedNetworkImageProvider(element).evict();
      });
    SystemChrome.setEnabledSystemUIOverlays([
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ]);
    imageCache.clearLiveImages();
    imageCache.clear();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleEventHandler);
    super.dispose();
  }

  Future<void> _savePageRead() async {
    await (await User.getInstance()).updateUserLog(_pageInfo.id, currentPage);
    if (Settings.useVioletServer) {
      _report.endsTime = DateTime.now();
      _report.validSeconds =
          DateTime.now().difference(_startsTime).inSeconds - _inactivateSeconds;
      _report.lastPage = currentPage;
      _report.msPerPages = _decisecondPerPages;

      VioletServer.viewClose(
              _pageInfo.id,
              DateTime.now().difference(_startsTime).inSeconds -
                  _inactivateSeconds)
          .then((value) {
        VioletServer.viewReport(_report);
      });
    }
  }

  Future<void> pageReadTimerCallback(timer) async {
    if (_isStaring) {
      var _page = _prevPage - 1 < 0
          ? 0
          : _prevPage - 1 >= _pageInfo.uris.length
              ? _pageInfo.uris.length - 1
              : _prevPage - 1;

      if (_isImageLoaded[_page]) _decisecondPerPages[_page] += 1;
    }
  }

  void startTimer() {
    if (_nextPageTimer != null) {
      _nextPageTimer.cancel();
      _nextPageTimer = null;
    }
    if (Settings.enableTimer) {
      _nextPageTimer = Timer.periodic(
        Duration(milliseconds: (Settings.timerTick * 1000).toInt()),
        nextPageTimerCallback,
      );
    }
  }

  void stopTimer() {
    if (_nextPageTimer != null) {
      _nextPageTimer.cancel();
      _nextPageTimer = null;
    }
  }

  Future<void> nextPageTimerCallback(timer) async {
    var next = _prevPage + 1;
    if (next < 1 || next > _pageInfo.uris.length) return;
    if (!Settings.isHorizontal) {
      if (!Settings.animation) {
        itemScrollController.jumpTo(index: next - 1, alignment: 0.12);
      } else {
        _sliderOnChange = true;
        await itemScrollController.scrollTo(
          index: next - 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
        Future.delayed(Duration(milliseconds: 300)).then((value) {
          _sliderOnChange = false;
        });
      }
    } else {
      if (!Settings.animation) {
        _pageController.jumpToPage(next - 1);
      } else {
        _pageController.animateToPage(
          next - 1,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
    currentPage = next;
    setState(() {
      _prevPage = next;
    });
  }

  void _checkLatestRead([bool moveAnywhere = false]) {
    User.getInstance().then((value) => value.getUserLog().then((value) async {
          var x = value.where((e) => e.articleId() == _pageInfo.id.toString());
          if (x.length < 2) return;
          var e = x.elementAt(1);
          if (e.lastPage() == null) return;
          if (e.lastPage() > 1 &&
              DateTime.parse(e.datetimeStart())
                      .difference(DateTime.now())
                      .inDays <
                  7) {
            if (moveAnywhere ||
                await showYesNoDialog(
                    context,
                    Translations.of(context)
                        .trans('recordmessage')
                        .replaceAll('%s', e.lastPage().toString()),
                    Translations.of(context).trans('record'))) {
              if (!Settings.isHorizontal) {
                itemScrollController.jumpTo(
                    index: e.lastPage() - 1, alignment: 0.12);
              } else {
                _pageController.jumpToPage(e.lastPage() - 1);
              }
            }
          }
        }));
  }

  @override
  Widget build(BuildContext context) {
    ImageCache _imageCache = PaintingBinding.instance.imageCache;
    final mediaQuery = MediaQuery.of(context);
    if (_imageCache.currentSizeBytes >= (1024 + 256) << 20) {
      _imageCache.clear();
      _imageCache.clearLiveImages();
    }

    return WillPopScope(
      onWillPop: () async {
        _isSessionOutdated = true;
        if (!_pageInfo.useFileSystem) await _savePageRead();
        return Future(() => true);
      },
      child: () {
        if (Settings.disableFullScreen) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: Padding(
              padding: mediaQuery.padding + mediaQuery.viewInsets,
              child:
                  Settings.isHorizontal ? _bodyHorizontal() : _bodyVertical(),
            ),
          );
        } else {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
            sized: false,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              body: Padding(
                padding: Platform.isIOS && _disableBottom
                    ? EdgeInsets.only(top: Variables.statusBarHeight)
                    : EdgeInsets.zero,
                child:
                    Settings.isHorizontal ? _bodyHorizontal() : _bodyVertical(),
              ),
            ),
          );
        }
      }(),
    );
  }

  _appBar() {
    final statusBarHeight =
        Settings.disableFullScreen ? MediaQuery.of(context).padding.top : 0;
    final height = MediaQuery.of(context).size.height;
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(milliseconds: 300),
      child: Stack(
        children: [
          !Settings.disableFullScreen
              ? Padding(
                  padding: EdgeInsets.only(top: statusBarHeight.toDouble()),
                  child: Container(
                    height: Variables.statusBarHeight,
                    color: Colors.black,
                  ),
                )
              : Container(),
          Container(
            padding: !Settings.moveToAppBarToBottom
                ? EdgeInsets.only(
                    top: !Settings.disableFullScreen
                        ? Variables.statusBarHeight
                        : 0.0)
                : EdgeInsets.only(
                    top: height -
                        Variables.bottomBarHeight -
                        (48) -
                        statusBarHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: Settings.moveToAppBarToBottom
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Material(
                  color: Colors.black.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _appBarBack(),
                      Expanded(
                        child: Row(
                          children: [
                            _appBarBookmark(),
                            _appBarInfo(),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _appBarTab(),
                          _appBarHistory(),
                          _appBarTimer(),
                          _appBarGallery(),
                          _appBarSettings(),
                        ],
                      ),
                    ],
                  ),
                ),
                !Settings.disableFullScreen && Settings.moveToAppBarToBottom
                    ? Container(
                        height: Variables.bottomBarHeight,
                        color: Colors.black,
                      )
                    : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _appBarBack() {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      color: Colors.white,
      onPressed: () async {
        _isSessionOutdated = true;
        if (!_pageInfo.useFileSystem) await _savePageRead();
        Navigator.pop(context, currentPage);
        return Future(() => false);
      },
    );
  }

  _appBarBookmark() {
    return IconButton(
      icon: Icon(isBookmarked ? MdiIcons.heart : MdiIcons.heartOutline),
      color: Colors.white,
      onPressed: () async {
        isBookmarked =
            await (await Bookmark.getInstance()).isBookmark(_pageInfo.id);

        if (isBookmarked) {
          if (!await showYesNoDialog(context, '북마크를 삭제할까요?', '북마크')) return;
        }

        FlutterToast(context).showToast(
          child: ToastWrapper(
            icon: isBookmarked ? Icons.delete_forever : Icons.check,
            color: isBookmarked
                ? Colors.redAccent.withOpacity(0.8)
                : Colors.greenAccent.withOpacity(0.8),
            ignoreDrawer: true,
            reverse: true,
            msg:
                '${_pageInfo.id}${Translations.of(context).trans(!isBookmarked ? 'addtobookmark' : 'removetobookmark')}',
          ),
          gravity: ToastGravity.TOP,
          toastDuration: Duration(seconds: 4),
        );

        isBookmarked = !isBookmarked;
        if (isBookmarked)
          await (await Bookmark.getInstance()).bookmark(_pageInfo.id);
        else
          await (await Bookmark.getInstance()).unbookmark(_pageInfo.id);

        setState(() {});
      },
    );
  }

  _appBarInfo() {
    return IconButton(
      icon: Icon(MdiIcons.information),
      color: Colors.white,
      onPressed: () async {
        final height = MediaQuery.of(context).size.height;

        final search = await HentaiManager.idSearch(_pageInfo.id.toString());
        if (search.item1.length != 1) return;

        final qr = search.item1[0];

        var prov = ProviderManager.get(_pageInfo.id);
        var thumbnail = await prov.getThumbnailUrl();
        var headers = await prov.getHeader(0);
        ProviderManager.insert(qr.id(), prov);

        var isBookmarked =
            await (await Bookmark.getInstance()).isBookmark(qr.id());

        _isStaring = false;
        stopTimer();

        var cache;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) {
            return DraggableScrollableSheet(
              initialChildSize: 400 / height,
              minChildSize: 400 / height,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                if (cache == null) {
                  cache = Provider<ArticleInfo>.value(
                    child: ArticleInfoPage(
                      key: ObjectKey('asdfasdf'),
                    ),
                    value: ArticleInfo.fromArticleInfo(
                      queryResult: qr,
                      thumbnail: thumbnail,
                      headers: headers,
                      heroKey: 'zxcvzxcvzxcv',
                      isBookmarked: isBookmarked,
                      controller: controller,
                      lockRead: true,
                    ),
                  );
                }
                return cache;
              },
            );
          },
        ).then((value) {
          _isStaring = true;
          startTimer();
        });
      },
    );
  }

  _appBarTab() {
    return IconButton(
      icon: Icon(MdiIcons.tab),
      color: Colors.white,
      onPressed: () async {
        stopTimer();
        _isStaring = false;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: false,
          builder: (context) => TabPanel(
            articleId: _pageInfo.id,
            usableTabList: _pageInfo.usableTabList,
          ),
        ).then((value) async {
          if (value == null) return;

          await _savePageRead();

          await (await User.getInstance()).insertUserLog(value.id(), 0);

          _inactivateSeconds = 0;
          _startsTime = DateTime.now();

          if (!Settings.isHorizontal) {
            itemScrollController.jumpTo(index: 0, alignment: 0.12);
          } else {
            _pageController.jumpToPage(0);
          }
          currentPage = 0;
          setState(() {
            _prevPage = 0;
          });

          _pageInfo = ViewerPageProvider(
            uris: List<String>.filled(
                ProviderManager.get(value.id()).length(), null),
            useProvider: true,
            provider: ProviderManager.get(value.id()),
            headers: await ProviderManager.get(value.id()).getHeader(0),
            id: value.id(),
            title: value.title(),
            usableTabList: _pageInfo.usableTabList,
          );

          _report = ViewerReport(
            id: _pageInfo.id,
            pages: _pageInfo.uris.length,
            startsTime: DateTime.now(),
          );
          _decisecondPerPages = List.filled(_pageInfo.uris.length, 0);
          _isImageLoaded = List.filled(_pageInfo.uris.length, false);

          _headerCache =
              List<Map<String, String>>.filled(_pageInfo.uris.length, null);
          _urlCache = List<String>.filled(_pageInfo.uris.length, null);
          _height = List<double>.filled(_pageInfo.uris.length, 0);
          _keys = List<GlobalKey>.generate(
              _pageInfo.uris.length, (index) => GlobalKey());
          _estimatedImageHeight = List<double>.filled(_pageInfo.uris.length, 0);
          _loadingEstimaed = List<bool>.filled(_pageInfo.uris.length, false);
          _latestIndex = 0;
          _latestAlign = 0;
          _onScroll = false;

          setState(() {});

          Future.delayed(Duration(milliseconds: 300))
              .then((value) => _checkLatestRead(true));
        });
        startTimer();
        _isStaring = true;
      },
    );
  }

  _appBarHistory() {
    return IconButton(
      icon: Icon(MdiIcons.history),
      color: Colors.white,
      onPressed: () async {
        stopTimer();
        _isStaring = false;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: false,
          builder: (context) => ViewRecordPanel(
            articleId: _pageInfo.id,
          ),
        ).then((value) {
          if (value != null) {
            if (!Settings.isHorizontal) {
              itemScrollController.jumpTo(index: value, alignment: 0.12);
            } else {
              _pageController.jumpToPage(value - 1);
            }
            currentPage = value;
            setState(() {
              _prevPage = value;
            });
          }
        });
        startTimer();
        _isStaring = true;
      },
    );
  }

  _appBarTimer() {
    return IconButton(
      icon: Icon(Settings.enableTimer ? MdiIcons.timer : MdiIcons.timerOff),
      color: Colors.white,
      onPressed: () async {
        setState(() {
          Settings.setEnableTimer(!Settings.enableTimer);
        });
        startTimer();
      },
    );
  }

  _appBarGallery() {
    return IconButton(
      icon: Icon(MdiIcons.folderImage),
      color: Colors.white,
      onPressed: () async {
        stopTimer();
        _isStaring = false;
        if (!Platform.isIOS) {
          Navigator.of(context)
              .push(
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 500),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = Offset(0.0, 1.0);
                var end = Offset.zero;
                var curve = Curves.ease;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              pageBuilder: (_, __, ___) => Provider<ViewerPageProvider>.value(
                value: _pageInfo,
                child: ViewerGallery(
                  viewedPage: _prevPage,
                ),
              ),
            ),
          )
              .then(
            (value) {
              if (value != null) {
                if (!Settings.isHorizontal) {
                  itemScrollController.jumpTo(index: value, alignment: 0.12);
                } else {
                  _pageController.jumpToPage(value - 1);
                }
                currentPage = value;
                setState(() {
                  _prevPage = value;
                });
              }
            },
          );
        } else {
          Navigator.of(context)
              .push(
            CupertinoPageRoute(
              builder: (_) => Provider<ViewerPageProvider>.value(
                value: _pageInfo,
                child: ViewerGallery(),
              ),
            ),
          )
              .then(
            (value) {
              if (value != null) {
                if (!Settings.isHorizontal) {
                  itemScrollController.jumpTo(
                      index: _prevPage - 1, alignment: 0.12);
                } else {
                  _pageController.jumpToPage(value - 1);
                }
                currentPage = value;
                setState(() {
                  _prevPage = value;
                });
              }
            },
          );
        }
        startTimer();
        _isStaring = true;
      },
    );
  }

  _appBarSettings() {
    return IconButton(
      icon: Icon(Icons.settings),
      color: Colors.white,
      onPressed: () async {
        stopTimer();
        _isStaring = false;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: false,
          builder: (context) => ViewerSettingPanel(
            viewerStyleChangeEvent: () {
              if (Settings.isHorizontal) {
                _pageController =
                    PreloadPageController(initialPage: _prevPage - 1);
              } else {
                var npage = _prevPage;
                _sliderOnChange = true;
                Future.delayed(Duration(milliseconds: 180)).then((value) {
                  itemScrollController.jumpTo(
                      index: npage - 1, alignment: 0.12);
                  _sliderOnChange = false;
                });
              }
              setState(() {});
            },
            setStateCallback: () {
              setState(() {});
            },
          ),
        );
        startTimer();
        _isStaring = true;
        return;
      },
    );
  }

  // _appBarPageInfo() {
  //   return Expanded(
  //     child: Text(
  //       _pageInfo.id.toString(),
  //       maxLines: 1,
  //       overflow: TextOverflow.ellipsis,
  //       style: TextStyle(
  //         color: Colors.white,
  //         fontSize: 19,
  //       ),
  //       onTap: () async {
  //         stopTimer();
  //         await showModalBottomSheet(
  //           context: context,
  //           isScrollControlled: false,
  //           builder: (context) => ViewRecordPanel(
  //             articleId: _pageInfo.id,
  //           ),
  //         ).then((value) {
  //           if (value != null) {
  //             if (!Settings.isHorizontal) {
  //               itemScrollController.jumpTo(index: value, alignment: 0.12);
  //             } else {
  //               _pageController.jumpToPage(value - 1);
  //             }
  //             currentPage = value;
  //             setState(() {
  //               _prevPage = value;
  //             });
  //           }
  //         });
  //         startTimer();
  //       },
  //     ),
  //   );
  // }

  _bodyVertical() {
    final height = MediaQuery.of(context).size.height;

    return Stack(
      children: <Widget>[
        // PhotoView.customChild(
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          child: Container(
            color: const Color(0xff444444),
            child: NotificationListener(
              child: ScrollablePositionedList.builder(
                physics: scrollListEnable
                    ? AlwaysScrollableScrollPhysics()
                    : NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _pageInfo.uris.length,
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionsListener,
                minCacheExtent: height * 3.0,
                itemBuilder: (context, index) {
                  Widget image;
                  if (!Settings.padding) {
                    if (_pageInfo.useWeb)
                      image = _networkImageItem(index);
                    else if (_pageInfo.useFileSystem)
                      image = _storageImageItem(index);
                    else if (_pageInfo.useProvider)
                      image = _providerImageItem(index);
                  } else {
                    if (_pageInfo.useWeb)
                      image = Padding(
                        child: _networkImageItem(index),
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                      );
                    else if (_pageInfo.useFileSystem)
                      image = Padding(
                        child: _storageImageItem(index),
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                      );
                    else if (_pageInfo.useProvider)
                      image = Padding(
                        child: _providerImageItem(index),
                        padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                      );
                  }

                  if (image == null) throw Exception('Dead Reaching');

                  return Listener(
                    onPointerDown: (event) {
                      _mpPoints++;
                      if (_mpPoints >= 2) {
                        if (scrollListEnable) {
                          setState(() {
                            scrollListEnable = false;
                          });
                        }
                      }
                    },
                    onPointerUp: (event) {
                      _mpPoints--;
                      if (_mpPoints < 1) {
                        setState(() {
                          scrollListEnable = true;
                        });
                      }
                    },
                    child: image,
                  );
                },
              ),
              onNotification: (t) {
                if (t is ScrollStartNotification) {
                  _onScroll = true;
                } else if (t is ScrollEndNotification) {
                  _onScroll = false;
                }
                return false;
              },
            ),
          ),
        ),
        _verticalPageLabel(),
        _touchArea(),
        !_disableBottom &&
                (!Settings.moveToAppBarToBottom || Settings.showSlider)
            ? _bottomAppBar()
            : Container(),
        !_disableBottom ? _appBar() : Container(),
      ],
    );
  }

  _bodyHorizontal() {
    return Stack(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: VPhotoViewGallery.builder(
            scrollPhysics: const AlwaysScrollableScrollPhysics(),
            builder: _buildItem,
            itemCount: _pageInfo.uris.length,
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
            pageController: _pageController,
            onPageChanged: (page) async {
              currentPage = page.toInt() + 1;
              setState(() {
                _prevPage = page.toInt() + 1;
              });
              await _precache(page.toInt() - 1);
              await _precache(page.toInt() + 1);
            },
            scrollDirection:
                Settings.scrollVertical ? Axis.vertical : Axis.horizontal,
            reverse: Settings.rightToLeft,
            loadingBuilder: (context, imageChunkEvent) {
              return Center(
                child: SizedBox(
                  child: CircularProgressIndicator(
                      value: imageChunkEvent == null
                          ? 0
                          : imageChunkEvent.cumulativeBytesLoaded /
                              imageChunkEvent.expectedTotalBytes.toDouble()),
                  width: 30,
                  height: 30,
                ),
              );
            },
          ),
        ),
        _verticalPageLabel(),
        _touchAreaMiddle(),
        !Settings.disableOverlayButton ? _touchAreaLeft() : Container(),
        !Settings.disableOverlayButton ? _touchAreaRight() : Container(),
        !_disableBottom &&
                (!Settings.moveToAppBarToBottom || Settings.showSlider)
            ? _bottomAppBar()
            : Container(),
        !_disableBottom ? _appBar() : Container(),
      ],
    );
  }

  _precache(int index) async {
    if (_pageInfo.useWeb) {
      if (index < 0 || _pageInfo.uris.length <= index) return;
      await precacheImage(
        CachedNetworkImageProvider(
          _pageInfo.uris[index],
          headers: _pageInfo.headers,
        ),
        context,
      );
    } else if (_pageInfo.useProvider) {
      if (index < 0 || _pageInfo.provider.length() <= index) return;
      if (_headerCache == null) {
        _headerCache =
            List<Map<String, String>>.filled(_pageInfo.uris.length, null);
        _urlCache = List<String>.filled(_pageInfo.uris.length, null);
      }
      if (_height == null) {
        _height = List<double>.filled(_pageInfo.uris.length, 0);
        _keys = List<GlobalKey>.generate(
            _pageInfo.uris.length, (index) => GlobalKey());
      }

      if (_headerCache[index] == null) {
        var header = await _pageInfo.provider.getHeader(index);
        _headerCache[index] = header;
      }

      if (_urlCache[index] == null) {
        var url = await _pageInfo.provider.getImageUrl(index);
        _urlCache[index] = url;
      }

      await precacheImage(
        CachedNetworkImageProvider(
          _urlCache[index],
          headers: _headerCache[index],
        ),
        context,
      );
    }
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index) {
    if (_pageInfo.useWeb)
      return PhotoViewGalleryPageOptions(
        imageProvider: CachedNetworkImageProvider(
          _pageInfo.uris[index],
          headers: _pageInfo.headers,
        ),
        filterQuality: FilterQuality.medium,
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.contained * 5.0,
      );
    else if (_pageInfo.useFileSystem) {
      return PhotoViewGalleryPageOptions(
        imageProvider: FileImage(File(_pageInfo.uris[index])),
        filterQuality: FilterQuality.medium,
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.contained * 5.0,
      );
    } else if (_pageInfo.useProvider) {
      return PhotoViewGalleryPageOptions.customChild(
        child: FutureBuilder(
          future: Future.sync(() async {
            if (_headerCache == null) {
              _headerCache =
                  List<Map<String, String>>.filled(_pageInfo.uris.length, null);
              _urlCache = List<String>.filled(_pageInfo.uris.length, null);
            }
            if (_height == null) {
              _height = List<double>.filled(_pageInfo.uris.length, 0);
              _keys = List<GlobalKey>.generate(
                  _pageInfo.uris.length, (index) => GlobalKey());
            }

            if (_headerCache[index] == null) {
              var header = await _pageInfo.provider.getHeader(index);
              _headerCache[index] = header;
            }

            if (_urlCache[index] == null) {
              var url = await _pageInfo.provider.getImageUrl(index);
              _urlCache[index] = url;
            }

            return Tuple2<Map<String, String>, String>(
                _headerCache[index], _urlCache[index]);
          }),
          builder: (context, snapshot) {
            if (_urlCache[index] != null && _headerCache[index] != null) {
              return PhotoView(
                imageProvider: CachedNetworkImageProvider(
                  _urlCache[index],
                  headers: _headerCache[index],
                ),
                filterQuality: FilterQuality.medium,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.contained * 5.0,
                gestureDetectorBehavior: HitTestBehavior.opaque,
              );
            }

            return SizedBox(
              height: 300,
              child: Center(
                child: SizedBox(
                  child: CircularProgressIndicator(),
                  width: 30,
                  height: 30,
                ),
              ),
            );
          },
        ),
        initialScale: PhotoViewComputedScale.contained,
        minScale: PhotoViewComputedScale.contained * 1.0,
        maxScale: PhotoViewComputedScale.contained * 5.0,
      );
    }
    throw Exception('Dead Reaching');
  }

  Timer _doubleTapCheckTimer;
  bool isPressed = false;
  bool isDoubleTap = false;
  bool isSingleTap = false;
  _touchArea() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Container(
      color: null,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // onDoubleTapDown: (TapDownDetails details) {
        //   _doubleTapDetails = details;
        // },
        // onDoubleTap: _handleDoubleTap,
        onTap: _handleTap,
        onTapDown: (TapDownDetails details) {
          _doubleTapDetails = details;

          isPressed = true;
          if (_doubleTapCheckTimer != null && _doubleTapCheckTimer.isActive) {
            isDoubleTap = true;
            _doubleTapCheckTimer.cancel();
          } else {
            _doubleTapCheckTimer = Timer(
                const Duration(milliseconds: 200), _doubleTapTimerElapsed);
          }
        },
        onTapCancel: () {
          isPressed = isSingleTap = isDoubleTap = false;
          if (_doubleTapCheckTimer != null && _doubleTapCheckTimer.isActive) {
            _doubleTapCheckTimer.cancel();
          }
        },
      ),
    );
  }

  void _doubleTapTimerElapsed() {
    if (isPressed) {
      isSingleTap = true;
    } else {
      _touchEvent();
    }
  }

  void _handleTap() {
    isPressed = false;
    if (isSingleTap) {
      isSingleTap = false;
      _touchEvent();
    }
    if (isDoubleTap) {
      isDoubleTap = false;
      _doubleTapEvent();
    }
  }

  void _touchEvent() {
    final width = MediaQuery.of(context).size.width;
    if (_doubleTapDetails.localPosition.dx < width / 3) {
      if (!Settings.disableOverlayButton) _leftButtonEvent();
    } else if (width / 3 * 2 < _doubleTapDetails.localPosition.dx) {
      if (!Settings.disableOverlayButton) _rightButtonEvent();
    } else {
      _middleButtonEvent();
    }
  }

  void _doubleTapEvent() {
    Matrix4 _endMatrix;
    Offset _position = _doubleTapDetails.localPosition;

    if (_transformationController.value != Matrix4.identity()) {
      _endMatrix = Matrix4.identity();
    } else {
      _endMatrix = Matrix4.identity()
        ..translate(-_position.dx * 1, -_position.dy * 1)
        ..scale(2.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: _endMatrix,
    ).animate(
      CurveTween(curve: Curves.easeOut).animate(_animationController),
    );
    _animationController.forward(from: 0);
  }

  bool _overlayOpend = false;
  _touchAreaMiddle() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.center,
      child: Container(
        color: null,
        width: width / 3,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _middleButtonEvent,
        ),
      ),
    );
  }

  _middleButtonEvent() async {
    if (!_overlayOpend) {
      if (!Settings.isHorizontal) _prevPage = currentPage;
      // setState(() {});
      setState(() {
        _opacity = 1.0;
        _disableBottom = false;
      });
      if (!Settings.disableFullScreen) {
        SystemChrome.setEnabledSystemUIOverlays(
            [SystemUiOverlay.bottom, SystemUiOverlay.top]);
      }
    } else {
      setState(() {
        _opacity = 0.0;
      });
      if (!Settings.disableFullScreen) {
        SystemChrome.setEnabledSystemUIOverlays([]);
      }
      Future.delayed(Duration(milliseconds: 300)).then((value) {
        setState(() {
          _disableBottom = true;
        });
      });
    }
    _overlayOpend = !_overlayOpend;
  }

  _touchAreaLeft() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        color: null,
        width: width / 3,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _leftButtonEvent,
        ),
      ),
    );
  }

  _leftButtonEvent() async {
    var next = Settings.rightToLeft ^ Settings.isHorizontal
        ? _prevPage - 1
        : _prevPage + 1;
    if (next < 1 || next > _pageInfo.uris.length) return;
    if (!Settings.isHorizontal) {
      if (!Settings.animation) {
        itemScrollController.jumpTo(index: next - 1, alignment: 0.12);
      } else {
        _sliderOnChange = true;
        await itemScrollController.scrollTo(
          index: next - 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
        Future.delayed(Duration(milliseconds: 300)).then((value) {
          _sliderOnChange = false;
        });
      }
    } else {
      if (!Settings.animation) {
        _pageController.jumpToPage(next - 1);
      } else {
        _pageController.animateToPage(
          next - 1,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
    currentPage = next;
    setState(() {
      _prevPage = next;
    });
  }

  _touchAreaRight() {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        color: null,
        width: width / 3,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _rightButtonEvent,
        ),
      ),
    );
  }

  _rightButtonEvent() async {
    var next = Settings.rightToLeft ^ Settings.isHorizontal
        ? _prevPage + 1
        : _prevPage - 1;
    if (next < 1 || next > _pageInfo.uris.length) return;
    if (!Settings.isHorizontal) {
      if (!Settings.animation) {
        itemScrollController.jumpTo(index: next - 1, alignment: 0.12);
      } else {
        _sliderOnChange = true;
        await itemScrollController.scrollTo(
          index: next - 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.12,
        );
        Future.delayed(Duration(milliseconds: 300)).then((value) {
          _sliderOnChange = false;
        });
      }
    } else {
      if (!Settings.animation) {
        _pageController.jumpToPage(next - 1);
      } else {
        _pageController.animateToPage(
          next - 1,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
    currentPage = next;
    setState(() {
      _prevPage = next;
    });
  }

  List<double> _height;
  List<GlobalKey> _keys;
  _networkImageItem(index) {
    final width =
        MediaQuery.of(context).size.width - (Settings.padding ? 8 : 0);
    if (_height == null) {
      _height = List<double>.filled(_pageInfo.uris.length, 0);
      _keys = List<GlobalKey>.generate(
          _pageInfo.uris.length, (index) => GlobalKey());
    }
    return FutureBuilder(
      // to avoid loading all images when fast scrolling
      future: Future.delayed(Duration(milliseconds: 300)).then((value) => 1),
      builder: (context, snapshot) {
        // To prevent the scroll from being chewed,
        // it is necessary to put an empty box for the invisible part.
        if (!snapshot.hasData && _height[index] == 0) {
          return SizedBox(
            height: 300,
            child: Center(
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 30,
                height: 30,
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(
              minHeight: _height[index] != 0 ? _height[index] : 300),
          child: VCachedNetworkImage(
            key: _keys[index],
            imageUrl: _pageInfo.uris[index],
            httpHeaders: _pageInfo.headers,
            fit: BoxFit.cover,
            fadeInDuration: Duration(microseconds: 500),
            fadeInCurve: Curves.easeIn,
            imageBuilder: (context, imageProvider, child) {
              if (_height[index] == 0 || _height[index] == 300) {
                try {
                  final RenderBox renderBoxRed =
                      _keys[index].currentContext.findRenderObject();
                  final sizeRender = renderBoxRed.size;
                  if (sizeRender.height != 300)
                    _height[index] = width / sizeRender.aspectRatio;
                  _isImageLoaded[index] = true;
                } catch (e) {}
              }
              return child;
            },
            progressIndicatorBuilder: (context, string, progress) {
              return SizedBox(
                height: 300,
                child: Center(
                  child: SizedBox(
                    child: CircularProgressIndicator(value: progress.progress),
                    width: 30,
                    height: 30,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  _storageImageItem(index) {
    final width = MediaQuery.of(context).size.width;
    if (_height == null) {
      _height = List<double>.filled(_pageInfo.uris.length, 0);
    }
    if (_height[index] == 0) {
      return FutureBuilder(
        // to avoid loading all images when fast scrolling
        future: Future.delayed(Duration(milliseconds: 300)).then((value) async {
          return await _calculateImageDimension(_pageInfo.uris[index]);
        }),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _height[index] = width / snapshot.data.aspectRatio;
            return Container(
              height: _height[index],
              child: Image(
                image: FileImage(File(_pageInfo.uris[index])),
                fit: BoxFit.cover,
              ),
            );
          }

          return SizedBox(
            height: _height[index] != 0 ? _height[index] : 300,
            child: Center(
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 30,
                height: 30,
              ),
            ),
          );
        },
      );
    } else {
      // Prevent flicking when no animate jump page
      return Container(
        height: _height[index],
        child: Image(
          image: FileImage(File(_pageInfo.uris[index])),
          fit: BoxFit.cover,
        ),
      );
    }
  }

  Future<Size> _calculateImageDimension(String uri) async {
    Completer<Size> completer = Completer();
    Image image = Image.file(File(uri));
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          var myImage = image.image;
          Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
          if (!completer.isCompleted) completer.complete(size);
        },
      ),
    );
    return completer.future;
  }

  /*
  Future<Size> _calculateNetworkImageDimension(String uri) async {
    Completer<Size> completer = Completer();
    Image image = Image(
        image: OptimizedCacheImageProvider(uri, headers: _pageInfo.headers));
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          var myImage = image.image;
          Size size = Size(myImage.width.toDouble(), myImage.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }
   */

  List<Map<String, String>> _headerCache;
  List<String> _urlCache;
  List<double> _estimatedImageHeight;
  List<bool> _loadingEstimaed;
  int _latestIndex = 0;
  double _latestAlign = 0;
  bool _onScroll = false;
  _providerImageItem(index) {
    if (_headerCache == null) {
      _headerCache =
          List<Map<String, String>>.filled(_pageInfo.uris.length, null);
      _urlCache = List<String>.filled(_pageInfo.uris.length, null);
    }

    final width = MediaQuery.of(context).size.width;
    if (_height == null) {
      _height = List<double>.filled(_pageInfo.uris.length, 0);
      _keys = List<GlobalKey>.generate(
          _pageInfo.uris.length, (index) => GlobalKey());
    }

    if (_estimatedImageHeight == null) {
      _estimatedImageHeight = List<double>.filled(_pageInfo.uris.length, 0);
      _loadingEstimaed = List<bool>.filled(_pageInfo.uris.length, false);
    }

    if (_loadingEstimaed[index] == false) {
      _loadingEstimaed[index] = true;
      Future.delayed(Duration(milliseconds: 1)).then((value) async {
        if (_isSessionOutdated) return;
        final _h =
            await _pageInfo.provider.getEstimatedImageHeight(index, width);
        if (_h > 0) {
          setState(() {
            _estimatedImageHeight[index] = _h;
          });
        }
      });
    }

    return FutureBuilder(
      // to avoid loading all images when fast scrolling
      future: Future.delayed(Duration(milliseconds: 300)).then((value) => 1),
      builder: (context, snapshot) {
        // To prevent the scroll from being chewed,
        // it is necessary to put an empty box for the invisible part.
        if (!snapshot.hasData && _height[index] == 0) {
          return SizedBox(
            height: _estimatedImageHeight[index] != 0
                ? _estimatedImageHeight[index]
                : 300,
            child: Center(
              child: SizedBox(
                child: CircularProgressIndicator(),
                width: 30,
                height: 30,
              ),
            ),
          );
        }

        return FutureBuilder(
          future: Future.delayed(Duration(milliseconds: 1)).then((value) async {
            if (_headerCache[index] == null) {
              var header = await _pageInfo.provider.getHeader(index);
              _headerCache[index] = header;
            }

            if (_urlCache[index] == null) {
              var url = await _pageInfo.provider.getImageUrl(index);
              _urlCache[index] = url;
            }

            return 1;
          }),
          builder: (context, snapshot) {
            if (!snapshot.hasData &&
                (_urlCache[index] == null || _headerCache[index] == null)) {
              return SizedBox(
                height: _estimatedImageHeight[index] != 0
                    ? _estimatedImageHeight[index]
                    : 300,
                child: Center(
                  child: SizedBox(
                    child: CircularProgressIndicator(),
                    width: 30,
                    height: 30,
                  ),
                ),
              );
            }
            return Container(
              // height: _height[index] != 0 ? _height[index] : null,
              constraints: _height[index] != 0
                  ? BoxConstraints(minHeight: _height[index])
                  : _estimatedImageHeight[index] != 0
                      ? BoxConstraints(minHeight: _estimatedImageHeight[index])
                      : null,
              child: VCachedNetworkImage(
                key: _keys[index],
                imageUrl: _urlCache[index],
                httpHeaders: _headerCache[index],
                fit: BoxFit.cover,
                fadeInDuration: Duration(microseconds: 500),
                fadeInCurve: Curves.easeIn,
                imageBuilder: (context, imageProvider, child) {
                  if (_height[index] == 0 || _height[index] == 300) {
                    Future.delayed(Duration(milliseconds: 50)).then((value) {
                      try {
                        final RenderBox renderBoxRed =
                            _keys[index].currentContext.findRenderObject();
                        final sizeRender = renderBoxRed.size;
                        if (sizeRender.height != 300) {
                          _height[index] = width / sizeRender.aspectRatio;
                        }

                        _isImageLoaded[index] = true;

                        if (_latestIndex >= index && !_onScroll)
                          _patchHeightForDynamicLoadedImage();
                      } catch (e) {}
                    });
                  }
                  return child;
                },
                progressIndicatorBuilder: (context, string, progress) {
                  return SizedBox(
                    height: _estimatedImageHeight[index] != 0
                        ? _estimatedImageHeight[index]
                        : 300,
                    child: Center(
                      child: SizedBox(
                        child:
                            CircularProgressIndicator(value: progress.progress),
                        width: 30,
                        height: 30,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  _getLatestHeight() {
    var v = itemPositionsListener.itemPositions.value.toList();
    var selected;
    var selectede;

    v.sort((x, y) => y.itemLeadingEdge.compareTo(x.itemLeadingEdge));

    for (var e in v) {
      if (e.itemLeadingEdge >= 0.0) {
        selected = e.index;
        selectede = e;
      } else {
        break;
      }
    }

    _latestIndex = selected;
    _latestAlign = selectede.itemLeadingEdge;
  }

  _patchHeightForDynamicLoadedImage() {
    if (_sliderOnChange) return;
    itemScrollController.jumpTo(index: _latestIndex, alignment: _latestAlign);
  }

  _bottomAppBar() {
    final statusBarHeight =
        Settings.disableFullScreen ? MediaQuery.of(context).padding.top : 0;
    final height = MediaQuery.of(context).size.height;
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(milliseconds: 300),
      child: Stack(
        children: [
          !Settings.disableFullScreen && !Settings.moveToAppBarToBottom
              ? Padding(
                  padding: EdgeInsets.only(top: statusBarHeight.toDouble()),
                  child: Container(
                    height: Variables.statusBarHeight,
                    color: Colors.black,
                  ),
                )
              : Container(),
          Padding(
            padding: EdgeInsets.only(
                top: height -
                    Variables.bottomBarHeight -
                    (48) -
                    statusBarHeight -
                    (Settings.moveToAppBarToBottom ? 48 : 0)),
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Colors.black.withOpacity(0.8),
              height: Variables.bottomBarHeight +
                  (!Settings.moveToAppBarToBottom ? 48 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_prevPage',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16.0)),
                      Container(
                        width: 200,
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.blue,
                            inactiveTrackColor: Color(0xffd0d2d3),
                            trackHeight: 3,
                            thumbShape:
                                RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            // thumbShape: SliderThumbShape(),
                          ),
                          child: Slider(
                            value: _prevPage.toDouble() > 0
                                ? _prevPage <= _pageInfo.uris.length
                                    ? _prevPage.toDouble()
                                    : _pageInfo.uris.length.toDouble()
                                : 1,
                            max: _pageInfo.uris.length.toDouble(),
                            min: 1,
                            label: _prevPage.toString(),
                            divisions: _pageInfo.uris.length,
                            inactiveColor: Settings.majorColor.withOpacity(0.7),
                            activeColor: Settings.majorColor,
                            onChangeStart: (value) {
                              _sliderOnChange = true;
                            },
                            onChangeEnd: (value) {
                              _sliderOnChange = false;
                            },
                            onChanged: (value) {
                              if (!Settings.isHorizontal) {
                                itemScrollController.jumpTo(
                                    index: value.toInt() - 1, alignment: 0.12);
                              } else {
                                _pageController.jumpToPage(value.toInt() - 1);
                              }
                              currentPage = value.toInt();
                              setState(() {
                                _prevPage = value.toInt();
                              });
                            },
                          ),
                        ),
                      ),
                      Text('${_pageInfo.uris.length}',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 15.0)),
                    ],
                  ),
                  !Settings.disableFullScreen && !Settings.moveToAppBarToBottom
                      ? Container(
                          height: Variables.bottomBarHeight,
                          color: Colors.black,
                        )
                      : Container(
                          height: Settings.moveToAppBarToBottom
                              ? Variables.bottomBarHeight
                              : 0,
                          color: Colors.transparent,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _verticalPageLabel() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.all(8),
      child: Stack(
        children: [
          Text(
            '$_prevPage/${_pageInfo.uris.length}',
            style: TextStyle(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          Text(
            '$_prevPage/${_pageInfo.uris.length}',
            style: TextStyle(
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
