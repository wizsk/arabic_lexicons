import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class MsgSv {
  static const MethodChannel _channel = MethodChannel('app/toast');
  static const _defDuration = Duration(seconds: 4);

  static final GlobalKey<ScaffoldMessengerState> snackMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// on android tries to show toast msg and else-where snakmsg
  static Future<void> showToast(
    String message, {
    final bool shortDuration = true,
    final Duration snackDuration = _defDuration,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('showToast', {
          'message': message,
          'short': shortDuration,
        });
      } on PlatformException {
        showSnackbarMsg(message, duration: snackDuration);
      }
    } else {
      showSnackbarMsg(message, duration: snackDuration);
    }
  }

  static void showSnackbarMsg(
    String message, {
    final Duration duration = _defDuration,
    final SnackBarAction? action,
    final bool? showCloseIcon,
  }) => showSnackbar(
    Text(message),
    duration: duration,
    action: action,
    showCloseIcon: showCloseIcon,
  );

  static Timer? _snackMsgTimmer;
  static VoidCallback? _snackMsgClearAction;

  static void showSnackbar(
    Widget message, {
    final Duration duration = _defDuration,
    final SnackBarAction? action,
    final bool? showCloseIcon,
  }) {
    _snackMsgTimmer?.cancel();
    _snackMsgTimmer = null;

    final messenger = snackMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();

    final ac = action == null
        ? null
        : SnackBarAction(
            key: action.key,
            label: action.label,
            onPressed: () {
              _snackMsgTimmer?.cancel();
              action.onPressed();
            },
            disabledTextColor: action.disabledTextColor,
            disabledBackgroundColor: action.disabledBackgroundColor,
            backgroundColor: action.backgroundColor,
            textColor: action.textColor,
          );

    final f = messenger?.showSnackBar(
      SnackBar(
        content: message,
        duration: duration,
        action: ac,
        showCloseIcon: showCloseIcon,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (f != null && action != null) {
      void c() {
        try {
          f.close();
        } catch (_) {}
        _snackMsgTimmer = null;
        _snackMsgClearAction = null;
      }

      _snackMsgClearAction = c;
      _snackMsgTimmer = Timer(duration, c);
    }
  }

  static void clearSnackActions() {
    _snackMsgTimmer?.cancel();
    _snackMsgClearAction?.call();
  }
}
