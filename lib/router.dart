import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/database/table/device_table.dart';
import 'package:flutter_openwrt_assistant/page/device/device_main_page.dart';
import 'package:flutter_openwrt_assistant/page/home/device_add_page.dart';
import 'package:flutter_openwrt_assistant/page/home/home_page.dart';
import 'package:flutter_openwrt_assistant/page/setting/setting_page.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_edit_page.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_page.dart';
import 'package:flutter_openwrt_assistant/page/three_cat/three_cat_rule.dart';
import 'package:flutter_openwrt_assistant/page/wol/wol_page.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/device_add', builder: (context, state) => DeviceAddPage()),
    GoRoute(
      path: '/device_modify/:deviceId',
      builder: (context, state) {
        var deviceId = state.pathParameters['deviceId'] as String;
        return DeviceAddPage(deviceId: int.parse(deviceId));
      },
    ),
    GoRoute(
      path: '/device/:deviceId',
      builder: (context, state) {
        var deviceId = state.pathParameters['deviceId'] as String;
        return DeviceMainPage(deviceId: int.parse(deviceId));
      },
    ),
    GoRoute(path: '/setting', builder: (context, state) => SettingPage()),
    GoRoute(
      path: '/wol',
      builder: (context, state) => WolPage(device: state.extra as Device),
    ),
    GoRoute(
      path: '/3cat',
      builder: (context, state) => ThreeCatPage(device: state.extra as Device),
    ),
    GoRoute(
      path: '/3cat_edit',
      builder: (context, state) {
        final extra = state.extra as ({Device device, ThreeCatRule? rule});
        return ThreeCatEditPage(device: extra.device, rule: extra.rule);
      },
    ),
  ],
);

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
