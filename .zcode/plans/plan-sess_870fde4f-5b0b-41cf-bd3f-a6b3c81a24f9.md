# Plan: Settings Screen (Dark Mode + Ngôn ngữ vi/en toàn app)

## Quyết định thiết kế
- **State**: `ChangeNotifier` (zero new dep, có sẵn trong `flutter/foundation.dart`).
- **Dark mode**: migrate 5 screen chính sang `Theme.of(context)` tokens; screen phụ giữ light (fallback).
- **i18n**: `flutter_localizations` + `intl` + gen-l10n với `.arb` files. Migrate cùng 5 screen chính; screen phụ giữ English.
- **Entry**: tile "Settings" trong ProfileScreen → push `SettingsScreen`.
- **Persistence**: SharedPreferences (keys `themeMode`, `locale`).

## Phần A — Infrastructure (core)

### A1. `mobile/pubspec.yaml` — thêm deps + generate flag
```yaml
dependencies:
  ...
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  uses-material-design: true
  generate: true          # ← bật gen-l10n
```

### A2. TẠO `mobile/l10n.yaml`
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
output-dir: lib/l10n/generated
```

### A3. TẠO 2 file ARB
- `mobile/lib/l10n/app_en.arb` — template (tất cả key).
- `mobile/lib/l10n/app_vi.arb` — bản dịch tiếng Việt.

Keys ban đầu (extract từ 5 screen chính + settings): `appName`, `practiceDashboard`, `hi`, `readyForToday`, `today`, `thisWeek`, `streak`, `allTime`, `practiceTimer`, `practiceHistory`, `goals`, `learn`, `myInstruments`, `logOut`, `logOutQuestion`, `logOutConfirm`, `cancel`, `support`, `profile`, `account`, `fullName`, `phone`, `email`, `accountType`, `subscription`, `vipMembership`, `viewPlans`, `save`, `settings`, `appearance`, `darkMode`, `language`, `english`, `vietnamese`, `about`, `version`, ... (extract đầy đủ khi implement).

### A4. TẠO `mobile/lib/core/theme/app_colors.dart` — brand colors hằng số
Brand colors KHÔNG đổi giữa light/dark (xanh lá, vàng, đỏ lỗi). Screens dùng `Theme.of(context).colorScheme.*` cho surface, nhưng brand color dùng hằng:
```dart
class AppColors {
  static const accent = Color(0xFF1F7A5A);        // primary green
  static const accentDark = Color(0xFF163B32);    // dark green card/badge
  static const gold = Color(0xFFFFD700);
  static const goldText = Color(0xFFB7791F);
  static const error = Color(0xFFB42318);
  static const lockBg = Color(0xFFFFF4DE);
  static const offWhite = Color(0xFFF7F7F2);      // fallback cho screen chưa migrate
}
```

### A5. TẠO `mobile/lib/core/theme/app_theme.dart` — ThemeData builders
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.offWhite,
    cardTheme: const CardThemeData(color: Colors.white),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
  );
}
```

### A6. TẠO `mobile/lib/core/settings/app_settings.dart` — ChangeNotifier
```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isDarkPreferred => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey);
    if (themeName == 'dark') _themeMode = ThemeMode.dark;
    else if (themeName == 'light') _themeMode = ThemeMode.light;
    else _themeMode = ThemeMode.system;

    final lang = prefs.getString(_localeKey);
    if (lang == 'vi') _locale = const Locale('vi');
    else _locale = const Locale('en');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
```

### A7. TẠO `mobile/lib/core/l10n/l10n_ext.dart` — extension tiện lợi
```dart
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

### A8. SỬA `mobile/lib/main.dart` — load settings trước runApp
```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/settings/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();
  runApp(MusicPracticeApp(settings: settings));
}
```

### A9. SỬA `mobile/lib/app.dart` — convert sang StatefulWidget + locale/themeMode
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/l10n_ext.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'l10n/generated/app_localizations.dart';

class MusicPracticeApp extends StatefulWidget {
  const MusicPracticeApp({super.key, required this.settings});
  final AppSettings settings;

  @override
  State<MusicPracticeApp> createState() => _MusicPracticeAppState();
}

class _MusicPracticeAppState extends State<MusicPracticeApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return MaterialApp(
      title: 'Music Practice Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
```

## Phần B — Settings Screen

### B1. TẠO `mobile/lib/features/settings/presentation/settings_screen.dart`
`StatefulWidget`, dùng `InheritedWidget` hoặc nhận `AppSettings` qua constructor. Cách đơn giản: truyền `widget.settings` từ ProfileScreen.

Layout:
- AppBar "Settings".
- Section "Appearance": `SwitchListTile` "Dark mode" (đọc/gọi `settings.setThemeMode`).
- Section "Language": `RadioListTile`/`SegmentedButton` 2 lựa chọn English / Tiếng Việt.
- Section "About": ListTile "Version" → `0.1.0` (đọc từ pubspec qua `package_info_plus` hoặc hardcode cho MVP — hardcode để tránh thêm dep).

Mỗi toggle/setLocale gọi thẳng `widget.settings.setXxx()` → `notifyListeners()` → MaterialApp rebuild → toàn app đổi.

### B2. SỬA `mobile/lib/features/profile/presentation/profile_screen.dart` — thêm tile Settings
Trong card "Subscription" (hoặc tạo card "Preferences" mới), thêm ListTile:
```dart
ListTile(
  leading: const Icon(Icons.settings_outlined, color: AppColors.accent),
  title: Text(context.l10n.settings),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.push(SettingsScreen(settings: ...)),
),
```
> Vấn đề: ProfileScreen hiện không nhận `AppSettings`. Giải pháp: dùng `Finder` qua `context.findAncestorStateOfType` HOẶC dùng InheritedWidget. **Cách sạch nhất cho codebase này**: thêm InheritedWidget `AppSettingsScope` bọc MaterialApp, screens đọc qua `AppSettingsScope.of(context)`. Thêm file `lib/core/settings/app_settings_scope.dart`.

**Quyết định**: Tạo `AppSettingsScope` (InheritedNotifier) để mọi screen truy cập `AppSettings` mà không phải truyền qua 20 route. This is the cleanest given the imperative navigation model.

### B3. TẠO `mobile/lib/core/settings/app_settings_scope.dart` — InheritedNotifier
```dart
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()!.notifier!;
  }
}
```
Wrap trong app.dart: `home: AppSettingsScope(settings: settings, child: SplashScreen())`. Screens truy cập: `final settings = AppSettingsScope.of(context);`.

## Phần C — Migrate 5 screen chính (dark mode + i18n)

Với mỗi screen, thay:
- `Color(0xFFF7F7F2)` → `Theme.of(context).scaffoldBackgroundColor`
- `Colors.white` (Card bg) → `Theme.of(context).cardTheme.color` hoặc `colorScheme.surface`
- Hardcoded strings → `context.l10n.keyName`
- Brand colors (`0xFF1F7A5A`, `0xFF163B32`, gold...) → `AppColors.accent`/`AppColors.accentDark` (không đổi giữa mode)

### Files migrate:
1. `mobile/lib/features/home/presentation/home_screen.dart`
2. `mobile/lib/features/profile/presentation/profile_screen.dart`
3. `mobile/lib/features/practice/presentation/practice_timer_screen.dart`
4. `mobile/lib/features/practice/presentation/practice_history_screen.dart`
5. `mobile/lib/features/lessons/presentation/lesson_screen.dart`
6. `mobile/lib/features/chat/presentation/chat_screen.dart` (bỏ `_isVi` flag + `t()` helper, thay bằng `context.l10n`)

> **Không migrate (giữ nguyên English + light fallback)**: auth, splash, goals, lesson_detail, chords, scales, instruments, vip. Sau này bổ sung dần.

## Phần D — Strings extraction (chi tiết cho app_en.arb)
Sẽ extract đầy đủ khi implement. Ví dụ cấu trúc:
```json
{
  "@@locale": "en",
  "appName": "Music Practice Tracker",
  "@appName": {"description": "App name"},
  "practiceDashboard": "Practice Dashboard",
  "hi": "Hi, {name}",
  "@hi": {"placeholders": {"name": {"type": "String"}}},
  "today": "Today",
  "thisWeek": "This week",
  ...
}
```

## Ngoài phạm vi (KHÔNG làm trong task này)
- Không migrate 8 screen phụ (auth/splash/goals/chords/scales/instruments/vip/lesson_detail) — để task sau.
- Không thêm package_info_plus (version hardcode).
- Không thêm theme seed color picker (chỉ toggle dark mode).
- Không thêm notification reminders (scope khác).
- Không refator navigation sang GoRouter.

## Verify
- `cd mobile && flutter pub get` (sinh AppLocalizations).
- `cd mobile && flutter analyze` — 0 error.
- Test: Settings → toggle dark mode → Home/Profile/Practice/Lessons/Chat đổi nền tối. Toggle ngôn ngữ → labels đổi vi/en.

## Thứ tự thực hiện
1. **Infra**: pubspec + l10n.yaml + 2 ARB + app_colors + app_theme + app_settings + app_settings_scope + l10n_ext.
2. **Wire**: main.dart + app.dart (StatefulWidget + locale/themeMode).
3. **Settings screen** + tile trong Profile.
4. **Migrate 5 screen** (dark mode tokens + strings → context.l10n).
5. **flutter pub get + analyze + test**.

## Ước lượng
Đây là task lớn nhất session. ~15 file touch (6 mới + 9 sửa). Token cost cao nhưng đã có plan rõ ràng để execute tuần tự.