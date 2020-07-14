// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'dart:io';

import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/dialogs.dart';
import 'package:violet/locale.dart';
import 'package:violet/pages/settings/tag_selector.dart';
import 'package:violet/pages/settings/version_page.dart';
import 'package:violet/pages/test/test_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:violet/settings.dart';
import 'package:violet/database/user/user.dart';
import 'package:violet/update_sync.dart';
import 'package:violet/pages/database_download/database_download_page.dart';
import 'package:violet/widgets/toast.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin<SettingsPage> {
  FlareControls _flareController = FlareControls();
  bool _themeSwitch = false;
  FlutterToast flutterToast;

  @override
  void initState() {
    super.initState();
    _themeSwitch = Settings.themeWhat;
    flutterToast = FlutterToast(context);
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: <Widget>[
                _buildGroup(Translations.of(context).trans('theme')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: ShaderMask(
                        shaderCallback: (bounds) => RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.0,
                          colors: [Colors.black, Colors.white],
                          tileMode: TileMode.clamp,
                        ).createShader(bounds),
                        child:
                            Icon(MdiIcons.themeLightDark, color: Colors.white),
                      ),
                      title: Text(Translations.of(context).trans('darkmode')),
                      trailing: SizedBox(
                        width: 50,
                        height: 50,
                        child: FlareActor(
                          'assets/flare/switch_daytime.flr',
                          animation: _themeSwitch ? "night_idle" : "day_idle",
                          controller: _flareController,
                          snapToEnd: true,
                        ),
                      ),
                    ),
                    onTap: () async {
                      if (!_themeSwitch)
                        _flareController.play('switch_night');
                      else
                        _flareController.play('switch_day');
                      _themeSwitch = !_themeSwitch;
                      Settings.setThemeWhat(_themeSwitch);
                      DynamicTheme.of(context).setBrightness(
                          Theme.of(context).brightness == Brightness.dark
                              ? Brightness.light
                              : Brightness.dark);
                      setState(() {});
                    },
                  ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: ShaderMask(
                        shaderCallback: (bounds) => RadialGradient(
                          center: Alignment.bottomLeft,
                          radius: 1.2,
                          colors: [Colors.orange, Colors.pink],
                          tileMode: TileMode.clamp,
                        ).createShader(bounds),
                        child:
                            Icon(MdiIcons.formatColorFill, color: Colors.white),
                      ),
                      title:
                          Text(Translations.of(context).trans('colorsetting')),
                      trailing: Icon(
                          // Icons.message,
                          Icons.keyboard_arrow_right),
                    ),
                    onTap: () {
                      // showDialog(
                      //   context: context,
                      //   builder: (BuildContext context) {
                      //     return AlertDialog(
                      //       titlePadding: const EdgeInsets.all(0.0),
                      //       contentPadding: const EdgeInsets.all(0.0),
                      //       content: SingleChildScrollView(
                      //         child: ColorPicker(
                      //           pickerColor: Settings.majorColor,
                      //           onColorChanged: (color) async {
                      //             await Settings.setMajorColor(color);
                      //             setState(() {});
                      //           },
                      //           colorPickerWidth: 300.0,
                      //           pickerAreaHeightPercent: 0.7,
                      //           enableAlpha: true,
                      //           displayThumbColor: true,
                      //           showLabel: true,
                      //           paletteType: PaletteType.hsv,
                      //           pickerAreaBorderRadius: const BorderRadius.only(
                      //             topLeft: const Radius.circular(2.0),
                      //             topRight: const Radius.circular(2.0),
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // );
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                Translations.of(context).trans('selectcolor')),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: Settings.majorColor,
                                onColorChanged: (color) async {
                                  await Settings.setMajorColor(color);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      );
                      // showDialog(
                      //   context: context,
                      //   builder: (BuildContext context) {
                      //     return AlertDialog(
                      //       titlePadding: const EdgeInsets.all(0.0),
                      //       contentPadding: const EdgeInsets.all(0.0),
                      //       content: SingleChildScrollView(
                      //         child: MaterialPicker(
                      //           pickerColor: Settings.majorColor,
                      //           onColorChanged: (color) async {
                      //             await Settings.setMajorColor(color);
                      //             setState(() {});
                      //           },
                      //           enableLabel: true,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // );
                    },
                  ),
                ]),
                _buildGroup(Translations.of(context).trans('search')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.tagHeartOutline,
                        color: Settings.majorColor,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Translations.of(context).trans('defaulttag')),
                          Text(
                            Translations.of(context).trans('currenttag') +
                                Settings.includeTags,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      final vv = await showDialog(
                        context: context,
                        child: TagSelectorDialog(what: 'include'),
                      );

                      if (vv.item1 == 1) {
                        Settings.setIncludeTags(vv.item2);
                        setState(() {});
                      }
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      MdiIcons.tagOff,
                      color: Settings.majorColor,
                    ),
                    title: Text(Translations.of(context).trans('excludetag')),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () async {
                      final vv = await showDialog(
                        context: context,
                        child: TagSelectorDialog(what: 'exclude'),
                      );

                      if (vv.item1 == 1) {
                        Settings.setExcludeTags(vv.item2);
                        setState(() {});
                      }
                    },
                  ),
                  // _buildDivider(),
                  // InkWell(
                  //   child: ListTile(
                  //     leading: Icon(
                  //       MdiIcons.blur,
                  //       color: Settings.majorColor,
                  //     ),
                  //     title: Text(Translations.of(context).trans('blurredtag')),
                  //     trailing: Icon(Icons.keyboard_arrow_right),
                  //   ),
                  //   onTap: () async {
                  //     final vv = await showDialog(
                  //       context: context,
                  //       child: TagSelectorDialog(what: 'blurred'),
                  //     );

                  //     if (vv.item1 == 1) {
                  //       Settings.setBlurredTags(vv.item2);
                  //       setState(() {});
                  //     }
                  //   },
                  // ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.tooltipEdit,
                        color: Settings.majorColor,
                      ),
                      title: Text(Translations.of(context).trans('tagrebuild')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      if (await Dialogs.yesnoDialog(
                          context,
                          Translations.of(context).trans('tagrebuildmsg'),
                          Translations.of(context).trans('tagrebuild'))) {
                        await Dialogs.okDialog(context, 'TODO: Implementation');
                      }
                    },
                  ),
                  // _buildDivider(),
                  // ListTile(
                  //   leading: Icon(
                  //     MdiIcons.imageMultipleOutline,
                  //     color: Settings.majorColor,
                  //   ),
                  //   title: Text(Translations.of(context).trans('howtoshowsearchresult')),
                  //   trailing: Icon(
                  //       // Icons.message,
                  //       Icons.keyboard_arrow_right),
                  //   onTap: () {},
                  // ),
                ]),
                _buildGroup(Translations.of(context).trans('system')),
                _buildItems([
                  // ListTile(
                  //   leading: Icon(Icons.folder_open, color: Settings.majorColor),
                  //   title: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(Translations.of(context).trans('savedir')),
                  //       Text(Translations.of(context).trans('curdir') + ": /android/Pictures"),
                  //     ],
                  //   ),
                  //   trailing: Icon(Icons.keyboard_arrow_right),
                  //   onTap: () {},
                  // ),
                  // _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(Icons.receipt, color: Settings.majorColor),
                      title: Text(Translations.of(context).trans('logrecord')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(Icons.language, color: Settings.majorColor),
                    title: Text(Translations.of(context).trans('language')),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Theme(
                            data: Theme.of(context)
                                .copyWith(primaryColor: Colors.pink),
                            child: CountryPickerDialog(
                                titlePadding:
                                    EdgeInsets.symmetric(vertical: 16),
                                // searchCursorColor: Colors.pinkAccent,
                                // searchInputDecoration:
                                //     InputDecoration(hintText: 'Search...'),
                                // isSearchable: true,
                                title: Text('Select Language'),
                                onValuePicked: (Country country) async {
                                  final dict = {
                                    'KR': 'ko',
                                    'US': 'en',
                                    'JP': 'ja',
                                    'CN': 'zh',
                                    'RU': 'ru'
                                  };
                                  await Translations.of(context)
                                      .load(dict[country.isoCode]);
                                  await Settings.setLanguage(
                                      dict[country.isoCode]);
                                  setState(() {});
                                },
                                itemFilter: (c) => [].contains(c.isoCode),
                                priorityList: [
                                  CountryPickerUtils.getCountryByIsoCode('US'),
                                  CountryPickerUtils.getCountryByIsoCode('KR'),
                                  CountryPickerUtils.getCountryByIsoCode('JP'),
                                  // CountryPickerUtils.getCountryByIsoCode('CN'),
                                  // CountryPickerUtils.getCountryByIsoCode('RU'),
                                ],
                                itemBuilder: (Country country) {
                                  final dict = {
                                    'KR': '한국어',
                                    'US': 'English',
                                    'JP': '日本語',
                                    'CN': '中文',
                                    'RU': 'Русский'
                                  };
                                  return Container(
                                    child: Row(
                                      children: <Widget>[
                                        CountryPickerUtils.getDefaultFlagImage(
                                            country),
                                        SizedBox(
                                          width: 8.0,
                                          height: 30,
                                        ),
                                        Text("${dict[country.isoCode]}"),
                                      ],
                                    ),
                                  );
                                })),
                      );
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading:
                        Icon(Icons.info_outline, color: Settings.majorColor),
                    title: Text(Translations.of(context).trans('info')),
                    trailing: Icon(Icons.keyboard_arrow_right),
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (_, __, ___) {
                            return VersionViewPage();
                          },
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
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(Icons.developer_mode, color: Colors.orange),
                      title: Text(Translations.of(context).trans('devtool')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => TestPage(),
                        ),
                      );
                    },
                  ),
                ]),
                _buildGroup(Translations.of(context).trans('database')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(MdiIcons.swapHorizontal,
                          color: Settings.majorColor),
                      title: Text(Translations.of(context).trans('switching')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(MdiIcons.databaseSync,
                          color: Settings.majorColor),
                      title: Text(Translations.of(context).trans('syncmanual')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      var latestDB = UpdateSyncManager
                          .rawlangDB[Settings.databaseType].item1;
                      var lastDB = (await SharedPreferences.getInstance())
                          .getString('databasesync');

                      if (lastDB != null &&
                          latestDB.difference(DateTime.parse(lastDB)).inHours <
                              1) {
                        flutterToast.showToast(
                          child: ToastWrapper(
                            isCheck: true,
                            msg: '데이터베이스가 이미 최신상태입니다.',
                          ),
                          gravity: ToastGravity.BOTTOM,
                          toastDuration: Duration(seconds: 4),
                        );
                        return;
                      }

                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => DataBaseDownloadPage(
                                dbType: Settings.databaseType,
                                isExistsDataBase: false,
                              )));
                    },
                  ),
                ]),
                _buildGroup(Translations.of(context).trans('network')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(MdiIcons.vpn, color: Settings.majorColor),
                      title: Text('VPN'),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0)),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.router,
                        color: Settings.majorColor,
                      ),
                      title:
                          Text(Translations.of(context).trans('routing_rule')),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () {},
                  ),
                ]),
                _buildGroup(Translations.of(context).trans('bookmark')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading:
                          Icon(MdiIcons.import, color: Settings.majorColor),
                      title: Text('북마크 가져오기'),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      if (!await Permission.storage.isGranted) {
                        if (await Permission.storage.request() ==
                            PermissionStatus.denied) {
                          flutterToast.showToast(
                            child: ToastWrapper(
                              isCheck: false,
                              msg: "권한이 없어서 실행할 수 없습니다.",
                            ),
                            gravity: ToastGravity.BOTTOM,
                            toastDuration: Duration(seconds: 4),
                          );
                          return;
                        }
                      }

                      File file;
                      file = await FilePicker.getFile(
                        type: FileType.any,
                      );

                      if (file == null) {
                        flutterToast.showToast(
                          child: ToastWrapper(
                            isCheck: false,
                            msg: "선택된 데이터베이스가 없습니다.",
                          ),
                          gravity: ToastGravity.BOTTOM,
                          toastDuration: Duration(seconds: 4),
                        );

                        return;
                      }

                      var db = await getApplicationDocumentsDirectory();
                      var extfile = File(file.path);
                      await extfile.copy('${db.path}/user.db');

                      await Bookmark.getInstance();

                      flutterToast.showToast(
                        child: ToastWrapper(
                          isCheck: true,
                          msg: "북마크를 가져왔습니다!",
                        ),
                        gravity: ToastGravity.BOTTOM,
                        toastDuration: Duration(seconds: 4),
                      );
                    },
                  ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0)),
                    ),
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.export,
                        color: Settings.majorColor,
                      ),
                      title: Text('북마크 내보내기'),
                      trailing: Icon(Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      if (!await Permission.storage.isGranted) {
                        if (await Permission.storage.request() ==
                            PermissionStatus.denied) {
                          flutterToast.showToast(
                            child: ToastWrapper(
                              isCheck: false,
                              msg: "권한이 없어서 실행할 수 없습니다.",
                            ),
                            gravity: ToastGravity.BOTTOM,
                            toastDuration: Duration(seconds: 4),
                          );

                          return;
                        }
                      }

                      var db = await getApplicationDocumentsDirectory();
                      var dbfile = File('${db.path}/user.db');
                      var ext = await getExternalStorageDirectory();
                      var extpath = '${ext.path}/bookmark.db';
                      var extfile = await dbfile.copy(extpath);

                      flutterToast.showToast(
                        child: ToastWrapper(
                          isCheck: true,
                          msg: "북마크를 내보냈습니다!",
                        ),
                        gravity: ToastGravity.BOTTOM,
                        toastDuration: Duration(seconds: 4),
                      );
                    },
                  ),
                ]),
                // _buildGroup(Translations.of(context).trans('viewer')),
                // _buildItems([
                //   ListTile(
                //     leading: Icon(Icons.view_array, color: Settings.majorColor),
                //     title: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Text(Translations.of(context).trans('viewertype')),
                //         Text(Translations.of(context).trans('currenttype') + ": " + Translations.of(context).trans('scrollview')),
                //       ],
                //     ),
                //     trailing: Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                //   _buildDivider(),
                //   ListTile(
                //     leading: Icon(
                //       Icons.blur_linear,
                //       color: Settings.majorColor,
                //     ),
                //     title: Text(Translations.of(context).trans('imgquality')),
                //     trailing: Icon(
                //         // Icons.message,
                //         Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                // ]),
                // _buildGroup(Translations.of(context).trans('downloader')),
                // _buildItems([
                //   ListTile(
                //     leading: ShaderMask(
                //       shaderCallback: (bounds) => RadialGradient(
                //         center: Alignment.bottomLeft,
                //         radius: 1.3,
                //         colors: [Colors.yellow, Colors.red, Colors.purple],
                //         tileMode: TileMode.clamp,
                //       ).createShader(bounds),
                //       child: Icon(MdiIcons.instagram, color: Colors.white),
                //     ),
                //     title: Text(Translations.of(context).trans('instagram')),
                //     trailing: Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                //   _buildDivider(),
                //   ListTile(
                //     leading: Icon(MdiIcons.twitter, color: Colors.blue),
                //     title: Text(Translations.of(context).trans('twitter')),
                //     trailing: Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                //   _buildDivider(),
                //   ListTile(
                //     leading: Image.asset('assets/icons/pixiv.ico', width: 25),
                //     title: Text(Translations.of(context).trans('pixiv')),
                //     trailing: Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                // ]),
                // _buildGroup(Translations.of(context).trans('cache')),
                // _buildItems([
                //   ListTile(
                //     leading: Icon(Icons.lock_outline, color: Settings.majorColor),
                //     title: Text("Enable Locking"),
                //     trailing: AbsorbPointer(
                //       child: Switch(
                //         value: true,
                //         onChanged: (value) {
                //           //setState(() {
                //           //  isSwitched = value;
                //           //  print(isSwitched);
                //           //});
                //         },
                //         activeTrackColor: Settings.majorColor,
                //         activeColor: Settings.majorAccentColor,
                //       ),
                //     ),
                //     //Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                // ]),
                // _buildGroup('잠금'),
                // _buildItems([
                //   ListTile(
                //     leading: Icon(Icons.lock_outline, color: Settings.majorColor),
                //     title: Text("잠금 기능 켜기"),
                //     trailing: AbsorbPointer(
                //       child: Switch(
                //         value: true,
                //         onChanged: (value) {
                //           //setState(() {
                //           //  isSwitched = value;
                //           //  print(isSwitched);
                //           //});
                //         },
                //         activeTrackColor: Settings.majorColor,
                //         activeColor: Settings.majorAccentColor,
                //       ),
                //     ),
                //     //Icon(Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                //   _buildDivider(),
                //   ListTile(
                //     leading: Icon(
                //       Icons.security,
                //       color: Settings.majorColor,
                //     ),
                //     title: Text("보호 설정"), // blurring
                //     trailing: Icon(
                //         // Icons.message,
                //         Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                // ]),
                // _buildGroup('네트워크'),
                // _buildItems([
                //   ListTile(
                //     leading: Icon(
                //       Icons.router,
                //       color: Settings.majorColor,
                //     ),
                //     title: Text("라우팅 규칙"),
                //     trailing: Icon(
                //         // Icons.message,
                //         Icons.keyboard_arrow_right),
                //     onTap: () {},
                //   ),
                // ]),

                // _buildGroup(Translations.of(context).trans('network')),
                // _buildItems([
                //   InkWell(
                //     customBorder: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10.0),
                //     ),
                //     child: ListTile(
                //       // borderRadius: BorderRadius.circular(10.0),
                //       leading: Icon(
                //         Icons.router,
                //         color: Settings.majorColor,
                //       ),
                //       title:
                //           Text(Translations.of(context).trans('routing_rule')),
                //       trailing: Icon(
                //           // Icons.message,
                //           Icons.keyboard_arrow_right),
                //     ),
                //     onTap: () {},
                //   ),
                // ]),
                _buildGroup(Translations.of(context).trans('update')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      // borderRadius: BorderRadius.circular(10.0),
                      leading: Icon(
                        Icons.update,
                        color: Settings.majorColor,
                      ),
                      title:
                          Text(Translations.of(context).trans('checkupdate')),
                      trailing: Icon(
                          // Icons.message,
                          Icons.keyboard_arrow_right),
                    ),
                    onTap: () async {
                      await UpdateSyncManager.checkUpdateSync();

                      if (UpdateSyncManager.updateRequire) {
                        flutterToast.showToast(
                          child: ToastWrapper(
                            isCheck: true,
                            msg: "새로운 업데이트가 있습니다.",
                          ),
                          gravity: ToastGravity.BOTTOM,
                          toastDuration: Duration(seconds: 4),
                        );
                      } else {
                        flutterToast.showToast(
                          child: ToastWrapper(
                            isCheck: true,
                            msg: "최신 버전입니다!",
                          ),
                          gravity: ToastGravity.BOTTOM,
                          toastDuration: Duration(seconds: 4),
                        );
                      }
                    },
                  ),
                ]),
                _buildGroup(Translations.of(context).trans('etc')),
                _buildItems([
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.0),
                            topRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.discord,
                        color: Color(0xFF7189da),
                      ),
                      title: Text(Translations.of(context).trans('discord')),
                      trailing: Icon(Icons.open_in_new),
                    ),
                    onTap: () async {
                      const url = 'https://discord.gg/K8qny6E';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      MdiIcons.github,
                      color: Colors.black,
                    ),
                    title: Text(
                        "Github " + Translations.of(context).trans('project')),
                    trailing: Icon(Icons.open_in_new),
                    onTap: () async {
                      const url = 'https://github.com/project-violet/';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      MdiIcons.gmail,
                      color: Colors.redAccent,
                    ),
                    title: Text(Translations.of(context).trans('contact')),
                    trailing: Icon(
                        // Icons.email,
                        Icons.keyboard_arrow_right),
                    onTap: () async {
                      const url =
                          'mailto:violet.dev.master@gmail.com?subject=[App Issue] &body=';
                      if (await canLaunch(url)) {
                        await launch(url);
                      }
                    },
                  ),
                  _buildDivider(),
                  ListTile(
                    leading: Icon(
                      MdiIcons.heart,
                      color: Colors.orange,
                    ),
                    title: Text(Translations.of(context).trans('donate')),
                    trailing: Icon(
                        // Icons.email,
                        Icons.open_in_new),
                    onTap: () async {
                      // const url = 'https://www.patreon.com/projectviolet';
                      // if (await canLaunch(url)) {
                      //   await launch(url);
                      // }
                    },
                  ),
                  // _buildDivider(),
                  // ListTile(
                  //   leading: Icon(
                  //     MdiIcons.script,
                  //     color: Settings.majorColor,
                  //   ),
                  //   title: Text(Translations.of(context).trans('termsofuse')),
                  //   trailing: Icon(
                  //       // Icons.email,
                  //       Icons.keyboard_arrow_right),
                  //   onTap: () async {

                  //   },
                  // ),
                  // _buildDivider(),
                  // ListTile(
                  //   leading: Icon(
                  //     Icons.open_in_new,
                  //     color: Settings.majorColor,
                  //   ),
                  //   title: Text(Translations.of(context).trans('externallink')),
                  //   trailing: Icon(
                  //       // Icons.email,
                  //       Icons.keyboard_arrow_right),
                  //   onTap: () {},
                  // ),
                  _buildDivider(),
                  InkWell(
                    customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                            bottomRight: Radius.circular(10.0))),
                    child: ListTile(
                      leading: Icon(
                        MdiIcons.library,
                        color: Settings.majorColor,
                      ),
                      title: Text(Translations.of(context).trans('license')),
                      trailing: Icon(
                          // Icons.email,
                          Icons.keyboard_arrow_right),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => LicensePage(
                            applicationName: 'Project Violet\n',
                            applicationIcon: Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
                Container(
                  margin: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        // Card(
                        //   elevation: 5,
                        //   shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(10.0),
                        //   ),
                        //   child:
                        InkWell(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 100,
                            height: 100,
                          ),
                          //onTap: () {},
                        ),
                        // ),
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                        ),
                        Text(
                          'Project Violet',
                          style: TextStyle(
                            color: Settings.themeWhat
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 16.0,
                            fontFamily: "Calibre-Semibold",
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Copyright (C) 2020 by dc-koromo',
                          style: TextStyle(
                            color: Settings.themeWhat
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 12.0,
                            fontFamily: "Calibre-Semibold",
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      width: double.infinity,
      height: 1.0,
      color: Settings.themeWhat ? Colors.grey.shade600 : Colors.grey.shade400,
    );
  }

  Padding _buildGroup(String name) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(name,
              style: TextStyle(
                color: Settings.themeWhat ? Colors.white : Colors.black87,
                fontSize: 24.0,
                fontFamily: "Calibre-Semibold",
                letterSpacing: 1.0,
              )),
        ],
      ),
    );
  }

  Container _buildItems(List<Widget> items) {
    return Container(
      transform: Matrix4.translationValues(0, -2, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Card(
          elevation: 4.0,
          margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(children: items),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
