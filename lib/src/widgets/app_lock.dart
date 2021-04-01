import 'dart:async';

import 'package:flutter/material.dart';

/// A widget which handles app lifecycle events for showing and hiding a lock screen.
/// This should wrap around a `MyApp` widget (or equivalent).
///
/// [lockScreen] is a [Widget] which should be a screen for handling login logic and
/// calling `AppLock.of(context).didUnlock();` upon a successful login.
///
/// [builder] is a [Function] taking an [Object] as its argument and should return a
/// [Widget]. The [Object] argument is provided by the [lockScreen] calling
/// `AppLock.of(context).didUnlock();` with an argument. [Object] can then be injected
/// in to your `MyApp` widget (or equivalent).
///
/// [enabled] determines wether or not the [lockScreen] should be shown on app launch
/// and subsequent app pauses. This can be changed later on using `AppLock.of(context).enable();`,
/// `AppLock.of(context).disable();` or the convenience method `AppLock.of(context).setEnabled(enabled);`
/// using a bool argument.
///
/// [backgroundLockLatency] determines how much time is allowed to pass when
/// the app is in the background state before the [lockScreen] widget should be
/// shown upon returning. It defaults to instantly.
class AppLock extends StatefulWidget {
  final Widget Function(Object) builder;
  final Widget lockScreen;
  final bool enabled;
  final Duration backgroundLockLatency;
  final Duration inactivityLockLatency;
  final ThemeData theme;

  const AppLock({
    Key key,
    @required this.builder,
    @required this.lockScreen,
    this.enabled = true,
    this.backgroundLockLatency = const Duration(seconds: 0),
    this.inactivityLockLatency,
    this.theme,
  }) : super(key: key);

  static _AppLockState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppLockState>();

  @override
  _AppLockState createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  bool _didUnlockForAppLaunch;
  bool _isLocked;
  bool _enabled;

  Timer _backgroundLockLatencyTimer;
  Timer _inactivityLockLatencyTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    this._didUnlockForAppLaunch = !this.widget.enabled;
    this._isLocked = false;
    this._enabled = this.widget.enabled;

    this._setupInactivityTimer();
  }

  @override
  void didUpdateWidget(covariant AppLock oldWidget) {
    super.didUpdateWidget(oldWidget);

    this._setupInactivityTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!this._enabled) {
      return;
    }

    if (state == AppLifecycleState.paused &&
        (!this._isLocked && this._didUnlockForAppLaunch)) {
      this._backgroundLockLatencyTimer = Timer(
          this.widget.backgroundLockLatency, this._showLockScreenFromTimer);
    }

    if (state == AppLifecycleState.resumed) {
      this._backgroundLockLatencyTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    this._backgroundLockLatencyTimer?.cancel();
    this._inactivityLockLatencyTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: this.widget.enabled ? this._lockScreen : this._unlocked(null),
      navigatorKey: this._navigatorKey,
      routes: {
        '/lock-screen': (context) => this._lockScreen,
        '/unlocked': (context) =>
            this._unlocked(ModalRoute.of(context).settings.arguments),
      },
      theme: this.widget.theme,
    );
  }

  Widget _unlocked([Object args]) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (rawKeyEvent) => this._setupInactivityTimer(),
      child: Listener(
        onPointerCancel: (_) => this._setupInactivityTimer(),
        onPointerDown: (_) => this._setupInactivityTimer(),
        onPointerHover: (_) => this._setupInactivityTimer(),
        onPointerMove: (_) => this._setupInactivityTimer(),
        onPointerSignal: (_) => this._setupInactivityTimer(),
        onPointerUp: (_) => this._setupInactivityTimer(),
        child: this.widget.builder(args),
      ),
    );
  }

  Widget get _lockScreen {
    return WillPopScope(
      child: this.widget.lockScreen,
      onWillPop: () => Future.value(false),
    );
  }

  bool get _isShowingLockScreen =>
      this._isLocked || !this._didUnlockForAppLaunch;

  /// Causes `AppLock` to either pop the [lockScreen] if the app is already running
  /// or instantiates widget returned from the [builder] method if the app is cold
  /// launched.
  ///
  /// [args] is an optional argument which will get passed to the [builder] method
  /// when built. Use this when you want to inject objects created from the
  /// [lockScreen] in to the rest of your app so you can better guarantee that some
  /// objects, services or databases are already instantiated before using them.
  void didUnlock([Object args]) {
    if (this._didUnlockForAppLaunch) {
      this._didUnlockOnAppPaused();
    } else {
      this._didUnlockOnAppLaunch(args);
    }

    this._setupInactivityTimer();
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses if
  /// [enabled] is true of makes sure it isn't shown on subsequent app pauses if
  /// [enabled] is false.
  void setEnabled(bool enabled) {
    setState(() {
      this._enabled = enabled;
    });

    this._setupInactivityTimer();
  }

  /// Makes sure that [AppLock] shows the [lockScreen] on subsequent app pauses.
  ///
  /// This is a convenience method for calling [setEnabled] with true.
  void enable() {
    this.setEnabled(true);
  }

  /// Makes sure that [AppLock] doesn't show the [lockScreen] on subsequent app pauses.
  ///
  /// This is a convenience method for calling [setEnabled] with false.
  void disable() {
    this.setEnabled(false);
  }

  /// Manually show the [lockScreen].
  Future<void> showLockScreen() {
    this._isLocked = true;
    return this._navigatorKey.currentState.pushNamed('/lock-screen');
  }

  void _didUnlockOnAppLaunch(Object args) {
    this._didUnlockForAppLaunch = true;
    this
        ._navigatorKey
        .currentState
        .pushReplacementNamed('/unlocked', arguments: args);
  }

  void _didUnlockOnAppPaused() {
    this._isLocked = false;
    this._navigatorKey.currentState.pop();
  }

  void _setupInactivityTimer() {
    this._inactivityLockLatencyTimer?.cancel();

    if (this._enabled &&
        this.widget.inactivityLockLatency != null &&
        !this._isShowingLockScreen) {
      this._inactivityLockLatencyTimer = Timer(
          this.widget.inactivityLockLatency, this._showLockScreenFromTimer);
    }
  }

  void _showLockScreenFromTimer() {
    if (!this._isShowingLockScreen) this.showLockScreen();
  }
}
