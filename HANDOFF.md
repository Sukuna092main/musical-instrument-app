# HANDOFF — Settings Screen Task (Dark Mode + i18n)

> **Bất kỳ AI coding nào đọc file này là biết tiếp tục task Settings đang dở.**
> Cập nhật lần cuối: session hiện tại.

## 🎯 Task đang làm

Thêm **Settings screen** vào Flutter app với 2 khả năng:
1. **Dark mode toggle** (chế độ tối).
2. **Ngôn ngữ vi/en** toàn app.

Quyết định: dark mode "phân tầng" (5 screen chính migrate, screen phụ giữ light), i18n theo `flutter_localizations` + `gen-l10n`, entry Settings từ **ProfileScreen**.

---

## ✅ ĐÃ XONG (đừng làm lại)

### Phần A — Infrastructure (TẤT CẢ file đã tạo/sửa)
- `mobile/pubspec.yaml` — đã thêm `flutter_localizations`, `intl`, bật `generate: true`.
- `mobile/l10n.yaml` — config gen-l10n (output-dir: `lib/l10n/generated`).
- `mobile/lib/l10n/app_en.arb` — tất cả keys (file template).
- `mobile/lib/l10n/app_vi.arb` — bản dịch tiếng Việt.
- `mobile/lib/l10n/generated/app_localizations*.dart` — **đã generate** (chạy `flutter gen-l10n` để regen nếu sửa ARB).
- `mobile/lib/core/theme/app_colors.dart` — `AppColors.accent` (#1F7A5A), `accentDark` (#163B32), `accentSurface` (#E8EFE7), `gold` (#FFD700), `goldText` (#B7791F), `error` (#B42318), `errorSurface`, `lockBg`, `offWhite` (#F7F7F2).
- `mobile/lib/core/theme/app_theme.dart` — `AppTheme.light` / `AppTheme.dark` (ColorScheme.fromSeed seedColor=accent).
- `mobile/lib/core/settings/app_settings.dart` — `class AppSettings extends ChangeNotifier` giữ `themeMode` + `locale`, persist SharedPreferences (keys `themeMode`, `locale`).
- `mobile/lib/core/settings/app_settings_scope.dart` — `AppSettingsScope` (InheritedNotifier). Truy cập: `AppSettingsScope.of(context)`.
- `mobile/lib/core/l10n/l10n_ext.dart` — extension `context.l10n`.

### Phần A8-A9 — Wire root
- `mobile/lib/main.dart` — load `AppSettings` trước runApp, truyền vào `MusicPracticeApp(settings:)`.
- `mobile/lib/app.dart` — `MusicPracticeApp` đã thành StatefulWidget, listen settings, có `theme`/`darkTheme`/`themeMode`/`locale`/`supportedLocales`/`localizationsDelegates`, wrap `home` bằng `AppSettingsScope`.

### Phần B — Settings screen + Profile (đã migrate luôn)
- `mobile/lib/features/settings/presentation/settings_screen.dart` — TẠO. UI: SwitchListTile dark mode + RadioListTile English/Tiếng Việt + About version. Đọc `AppSettingsScope.of(context)`.
- `mobile/lib/features/profile/presentation/profile_screen.dart` — MIGRATE dark mode + i18n + thêm tile "Settings" ở cuối (Card mới).

### Phần C (đã migrate)
- `mobile/lib/features/home/presentation/home_screen.dart` — ✅ migrate xong.
- `mobile/lib/features/practice/presentation/practice_history_screen.dart` — ✅ migrate xong.
- `mobile/lib/features/lessons/presentation/lesson_screen.dart` — ✅ migrate xong.

---

## 🚧 ĐANG DỞ — AI tiếp theo làm tiếp từ đây

### Phần C còn lại (2 file cần migrate dark mode + i18n)
1. **`mobile/lib/features/practice/presentation/practice_timer_screen.dart`** — chưa migrate. Vẫn dùng `Color(0xFFF7F7F2)`, `Color(0xFF1F7A5A)`, `Color(0xFF163B32)`, hardcoded English.
2. **`mobile/lib/features/chat/presentation/chat_screen.dart`** — chưa migrate. Có `_isVi` flag + helper `t(en, vi)` cục bộ — cần bỏ, thay bằng `context.l10n`.

### Quy ước migrate (áp dụng cho cả 2 file còn lại)
- `Color(0xFFF7F7F2)` (scaffold bg) → **xóa**, để Scaffold dùng default (đã set trong `AppTheme`).
- `Color(0xFF1F7A5A)` → `AppColors.accent`.
- `Color(0xFF163B32)` → `AppColors.accentDark`.
- `Color(0xFFE8EFE7)` → `AppColors.accentSurface`.
- `Color(0xFFB42318)` → `AppColors.error`.
- `Color(0xFFFFF4DE)` → `AppColors.lockBg`.
- `Color(0xFFB7791F)` → `AppColors.goldText`.
- `Color(0xFFFFD700)` → `AppColors.gold`.
- `Colors.white` (Card bg) → **xóa**, để Card dùng default.
- `Colors.black54` / `Colors.black45` (hint) → `Theme.of(context).hintColor`.
- Hardcoded English `'Text'` → `context.l10n.<key>` (xem ARB keys có sẵn; nếu thiếu thì thêm vào cả `app_en.arb` + `app_vi.arb` rồi `flutter gen-l10n`).
- Import: thêm `import '../../../core/l10n/l10n_ext.dart';` và `import '../../../core/theme/app_colors.dart';`.

### Verify cuối cùng
```bash
cd mobile
flutter gen-l10n        # regen nếu có sửa ARB
flutter pub get         # đảm bảo deps OK
flutter analyze         # 0 error
```
Test trên emulator: Settings → toggle dark mode → 5 screen chính đổi nền tối. Toggle ngôn ngữ → labels đổi vi/en.

---

## ❌ KHÔNG migrate (giữ nguyên English + light, làm task sau)
`auth`, `splash`, `goals`, `lesson_detail`, `chords`, `scales`, `instruments`, `vip`, `instruments_api` (data layer không cần i18n).

---

## 🔑 Key concept cho AI tiếp theo
- **State propagation**: `AppSettings extends ChangeNotifier`. Khi user toggle trong SettingsScreen → `setThemeMode()`/`setLocale()` → `notifyListeners()` → `MusicPracticeApp` (StatefulWidget, đã `addListener`) rebuild → toàn app đổi. **Không cần truyền state qua routes.**
- **Truy cập settings**: `final settings = AppSettingsScope.of(context);` ở bất kỳ đâu dưới `AppSettingsScope` (đã wrap ở `app.dart`).
- **Lấy string**: `context.l10n.<key>` (extension trong `l10n_ext.dart`).
- **ARB có placeholder**: ví dụ `hi(name)` dùng `l10n.hi('John')` → "Hi, John" / "Chào, John". Xem `app_en.arb` cho cú pháp `@key.placeholders`.

---

## 📋 Convention codebase (từ AGENTS.md)
- Flutter mobile, Node/Express/TS backend.
- Pattern API: `XxxApi(this._client)` + model `fromJson` (parse snake_case từ Prisma → camelCase Dart).
- Bảng màu: xanh lá `#1F7A5A`, xanh đậm `#163B32`, nền `#F7F7F2`.
- Error: `error.toString().replaceFirst('Exception: ', '')`.
- Không tự ý refactor module không liên quan.

## 📝 Tasks đã hoàn thành trước Settings (cùng session)
Chat screen, Instruments screen (full CRUD), mount `/api/chords`, auth guard (GET /me + splash), VIP lock bấm được, audio player (chords/scales), edit profile (name/phone + refresh về Home).
