import 'package:flutter/material.dart';
import 'package:flutter_openwrt_assistant/router.dart';


showErrorSnackBar(String content) {
  final context = navigatorKey.currentContext!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        content,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
    ),
  );
}

showSnackBar(String content) {
  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
    SnackBar(content: Text(content), behavior: SnackBarBehavior.floating),
  );
}
