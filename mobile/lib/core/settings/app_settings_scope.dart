import 'package:flutter/widgets.dart';

import 'app_settings.dart';

/// Exposes [AppSettings] to the whole widget tree.
/// Wrap it around MaterialApp's `home` (or the root). Any descendant can then
/// access settings via `AppSettingsScope.of(context)` and will rebuild when
/// the notifier fires (theme/locale change).
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in widget tree');
    return scope!.notifier!;
  }
}
