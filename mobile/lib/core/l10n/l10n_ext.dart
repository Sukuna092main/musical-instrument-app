import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Convenience accessor: `context.l10n` instead of `AppLocalizations.of(context)!`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
