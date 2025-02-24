// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the MIT License.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PatchModel {
  DateTime dateTime;
  String version;
  bool isMajor;
  bool isMinor;
  String detail;
  List<String> contents;

  PatchModel({
    this.dateTime,
    this.version,
    this.isMajor = false,
    this.isMinor = false,
    this.contents,
  });
}

final patches = [
  PatchModel(
    dateTime: DateTime(2021, 9, 24),
    version: '1.16.1 Patch Update <== Latest',
    contents: [
      'optimize critical ui processes-2',
      'replace sync info url',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 9, 22),
    version: '1.16 Minor Update',
    contents: [
      'optimize critical ui processes',
      'add hisoki.me router',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 9, 19),
    version: '1.15 Minor Update',
    contents: [
      'apply flutter 2.5',
      'add dialog search (beta)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 9, 8),
    version: '1.14.1 Patch Update',
    contents: [
      'change some uis',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 8, 21),
    version: '1.14 Minor Update',
    isMinor: true,
    contents: [
      'add hitomi image route script',
      'add exhentai comment search page',
      'add exhentai comment count sorting',
      'add progress indicator to horizontal view',
      'lock appbar to bottom is true on ios',
      'fix to bottom padding',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 8, 11),
    version: '1.13.2 Patch Update <== Latest',
    contents: [
      'fix hitomi routing error',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 8, 5),
    version: '1.13.1 Patch Update',
    contents: [
      'fix random search bug',
      'add recent user record page',
      'code refactoring for violet 2.0 project',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 8, 1),
    version: '1.13 Minor Update',
    isMinor: true,
    contents: [
      'add artist comment',
      'add some test chunk of articles collection',
      'code refactoring for violet 2.0 project',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 7, 10),
    version: '1.12 Minor Update',
    isMinor: true,
    contents: [
      'add height estimation login',
      'code refactoring for violet 2.0 project',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 6, 27),
    version: '1.11 Minor Update',
    isMinor: true,
    contents: [
      'code refactoring for flutter 2.0',
      'ehance tag translation(korean)',
      'add viewer report routine',
      'add sort by population to filter page',
      'fix to consistent random search',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 6, 20),
    version: '1.10.2 Patch Update',
    contents: [
      'add related tag viewer',
      'fix article info paddings error',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 6, 18),
    version: '1.10.1 Patch Update',
    contents: [
      'fix hitomi get image list method',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 6, 16),
    version: '1.10 Minor Update',
    isMinor: true,
    contents: [
      'add korean search',
      'ehance viewer',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 6, 8),
    version: '1.9.2 Patch',
    contents: [
      'fix hitomi image rule',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 20),
    version: '1.9.1 Patch',
    contents: [
      'add bookmark and info button to viewer-page',
      'add move to appbar to bottom option',
      'enhace viewer-page tab button',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 19),
    version: '1.9 Minor Update',
    isMinor: true,
    contents: [
      'add view tabs',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 19),
    version: '1.8.8 Patch (HotFix)',
    contents: [
      'add tag long press to add exclude tag',
      'fix excluded tag not working issue (bug in which the sql syntax does not recognize null)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 19),
    version: '1.8.7 Patch',
    contents: [
      'fix bug in which the visible area images are pushed down due to the top postloaded image in the vertical scroll viewer',
      'fix bug in which the page was not displayed properly when the viewer page was inactive, and the time of the inactive state was added to violet-server view_close api',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 18),
    version: '1.8.6 Patch',
    contents: [
      'add viewer timer',
      'redesign info page (faq, manual, etc...)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 17),
    version: '1.8.5 Patch',
    contents: [
      'add series to artists collection (series finder)',
      'add double tap zoom on viewer',
      'add importing bookmark from hiyobi',
      'fix record view request too much database connection',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 15),
    version: '1.8.4 Patch (HotFix)',
    contents: [
      'fix bug that seriesCharacter inner loop use mismatched list during tag rebuilding',
      'fix an issue where the actual images storage path and the path recorded in the DB did not match',
      'fix an error where the innerstorage option is initialized every time the app is started.'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 14),
    version: '1.8.3 Patch',
    contents: [
      'add series article viewer',
      'add tag-rebuild function',
      'add database-rebuild function',
      'add database-opt function',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 14),
    version: '1.8.2 Patch',
    contents: [
      'add search log',
      'add search filter to search filter page',
      'enhance log view'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 12),
    version: '1.8.1 Patch',
    contents: [
      'Code update for flutter-2.0',
      'optimize viewer memory usage',
      'fix download path invalid over android 30',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 5, 11),
    version: '1.8 Minor Update',
    isMinor: true,
    contents: [
      'Code update for flutter-2.0',
      'add \'random\' lookup chip',
      'add article when eh url clicked',
      'add read page indicator',
      'add download to inner storage option',
      'add filter on bookmark group page',
      'add artists article collections',
      'add writing comment function',
      'add log-record page',
      'add community tab (move to settings page) with login, signup functions',
      'remove illegal characters from a file name',
      'fix space character added when first lookup',
      'fix bug that randomly moves when moving works/artists between bookmark lists',
      'fix bug that the order is reversed when moving a group',
      'fix an error where more than 1000 bookmarks were not displayed',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 3, 1),
    version: '1.7.8 Patch',
    contents: [
      'update crashlytics plugin version',
      'upload user bookmark database'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2021, 2, 12),
    version: '1.7.7 Patch',
    contents: ['?'],
  ),
  PatchModel(
    dateTime: DateTime(2021, 2, 12),
    version: '1.7.6 Patch',
    contents: [
      'fix bookmark state not changed',
      'searching random with conditions'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 26),
    version: '1.7.5 Patch',
    contents: [
      'apply anti-aliasing to horizontal view (upscale filter quality)',
      'change selected bookmark style',
      'fix exhentai login error',
      'fix intact bug artist bookmark'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 25),
    version: '1.7.4 Patch (HotFix)',
    contents: [
      'fix hiyobi routing error',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 21),
    version: '1.7.3 Patch',
    contents: [
      'fix critical error related with app',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 21),
    version: '1.7.2 Patch (E)',
    contents: [
      'fix hitomi subdomain error',
      'fix e/ex-hentai comment parsing error',
      'enhance startup time',
      'enhance viewer gallery view',
      'change default download directory (Violet => .violet)',
      '(This patch was released earlier than scheduled due to critical errors.)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 17),
    version: '1.7.1 Patch (HotFix)',
    contents: [
      'fix database downloading error when first start',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 17),
    version: '1.7 Minor Update',
    isMinor: true,
    contents: [
      'add volume key viewer controller',
      'add artist/group/uploader/series/character bookmark',
      'fix hentai downloader viewer',
      'fix autosync encoding error',
      'modify viewer gesture detection strategy',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 16),
    version: '1.6.4 Patch (Rollback)',
    contents: [
      'rollback 1.6.3 viewer patch',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 16),
    version: '1.6.3 Patch',
    contents: [
      'add auto sync functions',
      'add volume key viewer controller',
      'fix hentai downloader',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 8),
    version: '1.6.2 Patch (HotFix)',
    contents: [
      'fix viewer menu is not shown',
      'fix image height is too loose in scroll viewer',
      'fix new main page is not shown in drawer mode',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 6),
    version: '1.6.1 Patch (HotFix)',
    contents: [
      'fix downloader error',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 5),
    version: '1.6 Minor Update',
    isMinor: true,
    contents: [
      'enhance viewer, article info page',
      'enhance tag filter, auto complete list',
      'redesign main page',
      'add database switcher',
      'add faq page',
      'add throttle manager for exhentai.org host',
      'fix loading screen is displayed while zooming thumbnails',
      'fix toast bottom padding',
      'remove search page grid animation (for performance)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 2),
    version: '1.5.1 Patch',
    contents: [
      'enhance e/ex-hentai image loading',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 10, 0),
    version: '1.5 Minor Update',
    isMinor: true,
    contents: [
      'enhance horizontal viewer',
      'add function to import bookmark from e/ex-hentai account',
      'add precaching in horizontal viewer',
      'add id search on web searching',
      'add function to keep search text',
      'fix bookmark not showing when article is not in database',
      'fix default filter is not working on real-time best',
      'remove search bar long press page',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 26),
    version: '1.4.1 Patch (HotFix)',
    contents: [
      'fix e/exhentai parsing error (images are doubled)',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 25),
    version: '1.4 Minor Update',
    isMinor: true,
    contents: [
      'add Drawer Theme',
      'add option to disable fullscreen',
      'add option to disable overlay buttons',
      'show page number in vetical viewer',
      'keep bookmark group align',
      'Robust Multiple Image Hosting Network Connection',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 23),
    version: '1.3.3~1.3.4 Patch',
    contents: [
      'fix Memory Leak in Large Scale Images (8MB>)',
      'fix loading indicator not showing on reader',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 21),
    version: '1.3.1 Patch',
    contents: [
      'fix Memory Leak on Viewer',
      'fix App crash when load too much images',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 21),
    version: '1.3 Minor Update',
    isMinor: true,
    contents: [
      'implements Character, Series Info Page',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 21),
    version: '1.2 Minor Update',
    isMinor: true,
    contents: [
      'add Vertical Viewer Padding option',
      'add Viewer for downloaded item',
      'add Search Routing Option, Viewer Routing Option',
      'separate hitomi.la database and download logic',
      'fix VPN Crashed when violet app load',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 09, 12),
    version: '1.0 Major Update',
    isMajor: true,
    contents: [
      '''My goal for version 1.0.0 was to improve the viewer completely. Now that I have achieved my goal, I am releasing this version.\n
There are still features to be improved, such as web search, but I will improve this in a minor version.\n
Thank you so much for using the beta version until now.'''
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 08, 15),
    version: '0.9.2 Patch',
    contents: [
      'fix cannot select bookmark item',
      'add search on web experimentally',
      'Android 29+ Supports (exec, saf)'
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 08, 09),
    version: '0.9.1 Patch',
    contents: [
      'fix hitomi subdomain',
      'fix crash when open download page twice',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 08, 02),
    version: '0.9 Minor Update',
    isMinor: true,
    contents: [
      'Code refactoring and stabilization, view-model separation',
      'EHentai login function added',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 31),
    version: '0.8.4 Patch',
    contents: [
      'Bookmark group reordering',
      'Donwload item management',
      'Fix reader memory leak',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 26),
    version: '0.8.3 Patch',
    contents: [
      'Improved the speed of the downloader.',
      'Now use network resources to the maximum to download.',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 24),
    version: '0.8.2 Patch',
    contents: [
      'Fix Instagram downloader',
      'Fix Bookmark group page refresh when items move and delete',
      'Add hitomi.la downloader',
      'Add Italiano and Simplified chinese(中文-简化字) translation (thank you alles, basinnn)',
      'Some ui changes',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 22),
    version: '0.8.1 Patch',
    contents: [
      'Improved and stabilized downloader',
      'Add Instagram downloader (with Video)',
      'https://www.instagram.com/ravi.me/?hl=ko',
      'Currently, only 1000 items are allowed.',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 21),
    version: '0.8 Minor Update',
    isMinor: true,
    contents: [
      'Add Pixiv Downloader',
      'To use this feature, you must first login on Settings.',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 13),
    version: '0.7 Minor Update',
    isMinor: true,
    contents: [
      'Fix viewer memory leak',
      'Improve viewer flexibly',
      'Comment function is temporarily suspended according to exhentai policy.',
      'Infinite Loading: Infinite query function is added. You can infinitely scroll.',
      'Left to Right Reading: Check Settings->Viewer->Read Right To Left toggle switch',
      'I removed some unnecessary animations to improve performance.',
      'Fixed 3 problems related to the viewer.',
      'I hope this will fix the viewer error.',
      'Added one-click database synchronization function',
      'Update checking',
      'Manual database synchronization',
      'Bookmark export, import',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 07, 06),
    version: '0.6 Alpha',
    isMinor: true,
    contents: [
      '검색결과 필터 구현',
      '뷰어 스크롤할 때 이미지 씹히는 버그 수정',
      '뷰어 스크롤 기능 추가',
      '애니메이션 및 그림자, 투명도, 블러 등 배터리 영향줄 수 있는 기능들 중 불필요한 것들 삭제 또는 최적화',
    ],
  ),
  PatchModel(
    dateTime: DateTime(2020, 06, 25),
    version: '0.4 Alpha',
    isMinor: true,
    contents: [
      '작품창 작가/그룹/업로더 창 추가',
      'or 키워드 괄호, -(제외할 태그) 사용가능',
      '사용자 태그 적용',
      "기본 제외 태그 목록 'female:rape','male:rape','female:loli','male:shota','female:ryona','male:ryona','female:scat','male:scat','female:snuff','male:snuff','female:insect','female:insect_girl''male:insect','male:insect_boy','female:gore','male:gore','female:gag','male:gag','female:bondage','male:bondage','female:enema','male:enema','female:bdsm','male:bdsm','female:monster','male:monster','female:netorare','male:netorare'",
      '기본 포함 태그 (검색어)',
      '(lang:korean or lang:n/a)',
      '디테일 뷰 구현',
      'n/a 검색 태깅 인덱싱',
      '언어/테마/컬러 설정',
    ],
  ),
];

class PatchNotePage extends StatefulWidget {
  @override
  _PatchNotePageState createState() => _PatchNotePageState();
}

class _PatchNotePageState extends State<PatchNotePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
            top: statusBarHeight + 16, bottom: mediaQuery.padding.bottom),
        child: Column(
          children: [
            Text(
              'Patch Note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 16,
            ),
            Expanded(
              child: ListView.separated(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(8),
                // addAutomaticKeepAlives: false,
                itemBuilder: (c, i) {
                  var ii = patches[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: i == 0
                            ? Colors.greenAccent.withOpacity(0.8)
                            : ii.isMajor
                                ? Colors.lightBlueAccent.withOpacity(0.8)
                                : ii.isMinor
                                    ? Colors.orange.withOpacity(0.8)
                                    : Colors.redAccent.withOpacity(0.8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(ii.isMajor
                                ? MdiIcons.chevronTripleUp
                                : ii.isMinor
                                    ? MdiIcons.chevronDoubleUp
                                    : MdiIcons.trendingUp),
                            SizedBox(
                              width: 12.0,
                            ),
                            Text(
                              ii.version,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${ii.dateTime.year}.${ii.dateTime.month}.${ii.dateTime.day}'),
                              ),
                            ),
                            // ii.detail != null
                            //     ? Expanded(
                            //         child: Align(
                            //           alignment: Alignment.centerRight,
                            //           child: SizedBox(
                            //             height: 18.0,
                            //             width: 18.0,
                            //             child: IconButton(
                            //               padding: EdgeInsets.zero,
                            //               icon: Icon(
                            //                 Icons.keyboard_arrow_right,
                            //                 size: 24,
                            //               ),
                            //               onPressed: () async {
                            //                 await showOkDialog(
                            //                     context, ii.detail, 'Detail');
                            //               },
                            //             ),
                            //           ),
                            //         ),
                            //       )
                            //     : Container(),
                          ],
                        ),
                        Container(height: 4),
                        Text('* ' + ii.contents.join('\n* ')),
                      ],
                    ),
                  );
                },
                itemCount: patches.length,
                separatorBuilder: (context, index) {
                  // return Divider(
                  //   height: 2,
                  // );

                  return Container(
                    height: 8,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // ),
    );
  }
}
