# Plan: Edit Profile (name/phone) — Backend PATCH + Bottom Sheet + Refresh

## Bối cảnh
Profile screen hiện read-only (chỉ avatar đổi được). `AuthUser` immutable, được home_screen giữ trong `widget.auth.user` → sau edit cần trả object mới về Home. Backend `/api/users/me` chưa có PATCH.

Quyết định: **bottom sheet edit** + **refresh toàn user về Home** (cũng fix bug avatar hiện tại).

## Phạm vi

### A — Backend

#### A1. `backend/src/modules/users/user.service.ts`
1. **Thêm `phone` vào `getCurrentUser` select** (hiện thiếu): thêm `phone: true` vào select + `phone: user.phone` vào return.
2. **Thêm hàm `updateMyProfile(userId, input)`**:
   - `findUnique` → 404 nếu thiếu (dùng `Object.assign(new Error(...), { statusCode: 404 })` — pattern users module).
   - Validate: nếu `fullName` provided → trim, kiểm tra rỗng + ≤ 100 ký tự (DB VarChar(100)), sai → throw với `statusCode: 400`. Nếu `phone` provided → trim, kiểm tra ≤ 30 ký tự (DB VarChar(30)), sai → throw 400. (Email KHÔNG cho edit.)
   - `prisma.users.update` với spread điều kiện (`...(input.fullName !== undefined && { full_name: ... })`, `...(input.phone !== undefined && { phone: ... })`), luôn set `updated_at: new Date()`, `select` trả snake_case gồm `{ id, full_name, email, avatar_url, phone, role, status }`.
   - Return object snake_case.

```ts
type UpdateProfileInput = { fullName?: string; phone?: string };

export async function updateMyProfile(userId: string, input: UpdateProfileInput) {
  const current = await prisma.users.findUnique({
    where: { id: userId },
    select: { id: true },
  });

  if (!current) {
    const error = Object.assign(new Error("User not found."), {
      statusCode: 404,
    });
    throw error;
  }

  const data: { full_name?: string; phone?: string; updated_at: Date } = {
    updated_at: new Date(),
  };

  if (input.fullName !== undefined) {
    const trimmed = input.fullName.trim();
    if (trimmed.length === 0 || trimmed.length > 100) {
      const error = Object.assign(
        new Error("Full name must be 1–100 characters."),
        { statusCode: 400 },
      );
      throw error;
    }
    data.full_name = trimmed;
  }

  if (input.phone !== undefined) {
    const trimmed = input.phone.trim();
    if (trimmed.length > 30) {
      const error = Object.assign(
        new Error("Phone must be 30 characters or fewer."),
        { statusCode: 400 },
      );
      throw error;
    }
    data.phone = trimmed.length === 0 ? null : trimmed; // empty string -> null
  }

  const updated = await prisma.users.update({
    where: { id: userId },
    data,
    select: {
      id: true,
      full_name: true,
      email: true,
      avatar_url: true,
      phone: true,
      role: true,
      status: true,
    },
  });

  return updated;
}
```

#### A2. `backend/src/modules/users/user.controller.ts`
Thêm `updateMyProfile` handler (validate type ở controller, theo pattern admin):
```ts
// PATCH /api/users/me
// Cập nhật full_name / phone của user hiện tại.
export const updateMyProfile = asyncHandler(async (req: Request, res: Response) => {
  const { fullName, phone } = req.body ?? {};

  if (fullName !== undefined && typeof fullName !== "string") {
    res.status(400).json({ message: "fullName must be a string." });
    return;
  }

  if (phone !== undefined && typeof phone !== "string") {
    res.status(400).json({ message: "phone must be a string." });
    return;
  }

  const user = await updateMyProfileService(req.user!.id, { fullName, phone });
  res.status(200).json({ message: "Profile updated successfully", data: { user } });
});
```
> Import `updateMyProfile as updateMyProfileService` từ service (tránh trùng tên controller). Bọc `{ user }` trong `data` để khớp `getMe`.

#### A3. `backend/src/modules/users/user.routes.ts`
Thêm route PATCH `/me`:
```ts
import { getMe, updateMyProfile, uploadMyAvatar } from "./user.controller";
...
userRoutes.get("/me", getMe);
userRoutes.patch("/me", updateMyProfile);   // ← thêm
userRoutes.post("/me/avatar", avatarUpload.single("avatar"), uploadMyAvatar);
```

#### A4. Build
`cd backend && npm run build`.

### B — Mobile

#### B1. `mobile/lib/features/auth/data/auth_api.dart` — thêm field `phone`
`AuthUser` hiện thiếu `phone`. Thêm field + fromJson mapping:
```dart
class AuthUser {
  AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.phone,        // ← thêm
    required this.role,
    required this.status,
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? phone;          // ← thêm
  final String role;
  final String status;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,   // ← thêm
      role: json['role'] as String,
      status: json['status'] as String,
    );
  }
}
```
> AuthUser immutable → sau edit phải tạo object mới (đã có sẵn từ /me response).

#### B2. `mobile/lib/features/profile/data/profile_api.dart` — thêm `updateProfile`
```dart
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_api.dart';   // ← import mới cho AuthUser

class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  Future<String> uploadAvatar({ ... }) async { ... }   // giữ nguyên

  /// PATCH /api/users/me — cập nhật full_name/phone, trả user mới.
  Future<AuthUser> updateProfile({String? fullName, String? phone}) async {
    final response = Map<String, dynamic>.from(
      await _client.put('/api/users/me', {   // ApiClient có put()
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
      }) as Map,
    );
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return AuthUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }
}
```
> Dùng `put` vì ApiClient không có `patch` (xem api_client.dart: có get/post/put/delete). Backend route là PATCH, nhưng `http.put` tới route PATCH sẽ không match. **Cần xử lý** — xem note cuối.

#### B3. `mobile/lib/features/profile/presentation/profile_screen.dart` — refactor sang state + bottom sheet + return result
Thay đổi lớn:
1. **Chuyển `widget.user.*` sang state-held**: thêm `late AuthUser _user` trong initState = `widget.user`. Dùng `_user.fullName`/`_user.phone` trong build thay vì `widget.user.*`. (Avatar đã có `_avatarUrl` state.)
2. **Thêm edit capability**: tile "Full name" và thêm tile "Phone" mới → bấm mở `_EditProfileSheet`. `_ProfileInfoTile` thêm optional `onTap` + trailing chevron khi editable.
3. **Thêm tile Phone** vào card Account (hiện thiếu).
4. **`_openEditName()` / `_openEditPhone()`**: showModalBottomSheet trả `AuthUser?` mới → setState `_user = updated` + cũng propagate về Home.
5. **Trả user mới về Home**: chuyển `ProfileScreen` thành trả `AuthUser?` qua `Navigator.pop(result)`. Mọi lần update (name/phone/avatar) đều `Navigator.pop(context, _user)` để Home nhận user mới.

#### B4. `mobile/lib/features/home/presentation/home_screen.dart` — nhận user mới từ Profile
Sửa `_openProfile()` (hiện chỉ `Navigator.push`):
```dart
IconButton(
  tooltip: 'Profile',
  icon: const Icon(Icons.account_circle_outlined),
  onPressed: () async {
    final updatedUser = await Navigator.of(context).push<AuthUser>(
      MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.auth.user)),
    );
    if (updatedUser != null && mounted) {
      setState(() {
        widget.auth = AuthResult(user: updatedUser, accessToken: widget.auth.accessToken);
      });
    }
  },
),
```
> `widget.auth` cần mutable — hiện `HomeScreen({required this.auth})` final field. Vì `setState` không đổi field final, cần đổi: hoặc dùng `late AuthResult auth` non-final, hoặc giữ state object riêng. Giải pháp đơn giản: đổi `final AuthResult auth` → `AuthResult auth` (non-final field, mutable) trong HomeScreen. Hoặc tạo biến state riêng `_currentUser`. Tôi sẽ dùng biến state riêng `_currentUser` trong `_HomeScreenState` để sạch hơn.

## Logic propagate user mới (fix cả bug avatar)
- Khi login/splash → Home giữ `widget.auth.user` (AuthUser A).
- Mở Profile (A) → edit name → `_user = B` → `Navigator.pop(B)`.
- Home nhận B → setState `_currentUser = B`. AppBar/Profile lần sau dùng B.
- Avatar cũng qua cùng cơ chế (hiện avatar không pop về Home → bug; sửa luôn).

## Note về PATCH vs PUT
ApiClient chỉ có `get/post/put/delete` (không patch). 2 lựa chọn:
1. **Thêm method `patch` vào ApiClient** (sạch, đúng语义) — copy pattern `put`.
2. **Đổi backend route PATCH → PUT** (nhẹ nhưng lệch REST convention).

Tôi khuyến nghị **lựa chọn 1** (thêm patch vào ApiClient) vì codebase dùng PUT cho practice-goals (`PUT /:id`), và REST chuẩn cho partial update là PATCH.

## Ngoài phạm vi (KHÔNG làm)
- Không cho edit email/role/status (email đổi phức tạp — unique constraint + verification; role/status là admin-only).
- Không thêm đổi password (cần verify old password + hashing — scope riêng).
- Không refactor AuthResult/AuthUser thành state management lib.

## Kiểm tra
- Backend: `npm run build`.
- Mobile: `flutter analyze` + test edit name/phone → về Home → mở lại Profile thấy data mới.

## Thứ tự thực hiện
1. Backend service (phone trong getCurrentUser + updateMyProfile).
2. Backend controller + route + build.
3. Mobile ApiClient thêm patch method.
4. Mobile auth_api thêm field phone.
5. Mobile profile_api thêm updateProfile.
6. Mobile profile_screen refactor + bottom sheet + pop result.
7. Mobile home_screen nhận user mới.