## 2.0.0 - 28th July 2021

Migrated to null-safety!

There are now also integration tests in the example project which can be run using `flutter test integration_test/integration_tests.dart`.

## 1.5.0 - 1st April 2021

Added the ability to override the `theme` property of the `MaterialApp` which `AppLock` uses internally.

```dart
runApp(AppLock(
  ...
  theme: ThemeData(
    textTheme: TextTheme(
      headline1: TextStyle(fontSize: 32),
    ),
  ),
));
```

`debugShowCheckedModeBanner` has also been set to false.

## 1.4.0+1 - 4th Oct 2020

Minor updates to docs.

## 1.4.0 - 4th Oct 2020

New functionality to specify a period of time between the app going into the background state and when the lock screen should be shown.

```dart
runApp(AppLock(
  ...,
  backgroundLockLatency: const Duration(seconds: 30),
));
```

This allows the app to go into the background state for the specified duration without causing the lock screen to be shown.

## 1.3.1 - 16th May 2020

`showLockScreen` is now a `Future`.

```dart
await AppLock.of(context).showLockScreen();

print('Did unlock!');
```

## 1.3.0 - 16th May 2020

New functionality to show the lock screen on-demand.

```dart
AppLock.of(context).showLockScreen();
```

## 1.2.0+1 - 21st Feb 2020

Update to description.

## 1.2.0 - 21st Dec 2019

New functionality to enable or disable the `lockScreen` at launch and on-demand.

```dart
runApp(AppLock(
  builder: ...,
  lockScreen: ...,
  enabled: false,
));
```

```dart
AppLock.of(context).enable();
AppLock.of(context).disable();
```

## 1.1.0+2 - 21st Dec 2019

- Removing deprecating `child` method in preference for the `builder` method.
- Updating Flutter version constraints

## 1.1.0+1 - 15th Dec 2019

Deprecating `child` method in preference for the `builder` method - simply a name change.

## 1.1.0 - 15th Dec 2019

**Breaking change**

An argument can now be passed in to the `AppLock` method `didUnlock` and is accessible through the builder method, `child` - this should be considered a **breaking change** as the builder method, `child` requires a parameter even if null is passed in to `didUnlock`.

## 1.0.0 - 15th Dec 2019

Initial release

Use `AppLock` to provide lock screen functionality to you Flutter apps.
