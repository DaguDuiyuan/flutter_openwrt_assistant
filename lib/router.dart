import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/page/device/device_main_page.dart';
import 'package:flutter_openwrt_assistant/page/home/device_add_page.dart';
import 'package:flutter_openwrt_assistant/page/home/home_page.dart';
import 'package:flutter_openwrt_assistant/page/setting/setting_page.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(navigatorKey: navigatorKey, routes: [
  GoRoute(
    path: '/',
    builder: (context, state) => const HomePage(),
  ),
  GoRoute(
    path: '/device_add',
    builder: (context, state) => DeviceAddPage(),
  ),
  GoRoute(
    path: '/device_modify/:deviceId',
    builder: (context, state) {
      var deviceId = state.pathParameters['deviceId'] as String;
      return DeviceAddPage(deviceId: int.parse(deviceId),);
    },
  ),
  GoRoute(
    path: '/device/:deviceId',
    builder: (context, state) {
      var deviceId =state.pathParameters['deviceId'] as String;
      return DeviceMainPage(
        deviceId: int.parse(deviceId),
      );
    },
  ),
  GoRoute(
    path: '/setting',
    builder: (context, state) => SettingPage(),
  ),
]);

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
