# CVHT Manager - Project Documentation

## 📋 Tổng quan dự án
**CVHT Manager** là ứng dụng Flutter quản lý Cố vấn học tập (CVHT), hỗ trợ giao tiếp giữa sinh viên và giảng viên, quản lý hoạt động, điểm rèn luyện, và thông báo.

---

## 🏗️ Cấu trúc thư mục

```
lib/
├── app_router.dart              # Định tuyến ứng dụng (GoRouter)
├── main.dart                    # Entry point
├── constants/                   # Các hằng số
│   └── app_colors.dart         # Màu sắc ứng dụng
├── theme/                       # Cấu hình theme
│   └── app_theme.dart          # Material 3 theme
├── models/                      # Data models
│   ├── models.dart             # Barrel export file
│   ├── user.dart               # User model
│   ├── student.dart            # Student model
│   ├── advisor.dart            # Advisor model
│   ├── notification_model.dart # Notification models
│   ├── activity.dart           # Activity model
│   ├── activity_role.dart      # Activity role model
│   ├── activity_registration.dart
│   ├── class_model.dart        # Class model
│   ├── semester.dart           # Semester model
│   ├── course.dart             # Course model
│   └── ... (các models khác)
├── providers/                   # State management (Provider)
│   ├── auth_provider.dart      # Quản lý authentication
│   ├── notification_provider_student.dart
│   ├── notifications_provider.dart (advisor)
│   ├── activities_provider.dart
│   ├── advisor_activities_provider.dart
│   ├── registrations_provider.dart
│   ├── student_provider.dart
│   ├── class_provider.dart
│   └── advisor_provider.dart
├── services/                    # API và services
│   └── api_service.dart        # Dio-based API client
├── screens/                     # Các màn hình UI
│   ├── login_screen.dart
│   ├── main_scaffold.dart      # Bottom navigation wrapper
│   ├── student_screens/        # Màn hình cho sinh viên
│   │   ├── home_screens/
│   │   ├── notification_screens/
│   │   ├── activity_screens/
│   │   └── student_profile_screen.dart
│   ├── advisor_screens/        # Màn hình cho giảng viên
│   │   ├── advisor_home_screen.dart
│   │   ├── notification_screens/
│   │   ├── activity_screens/
│   │   ├── students_manager_screens/
│   │   └── profile_screens/
│   └── ... (các screens khác)
├── widgets/                     # Reusable widgets
│   ├── widgets.dart            # Barrel export
│   ├── custom_app_bar.dart
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── custom_card.dart
│   ├── empty_state.dart
│   ├── loading_indicator.dart
│   ├── error_widget.dart
│   ├── badge_icon.dart
│   ├── status_badge.dart
│   └── avatar_widget.dart
└── utils/                       # Utilities
    └── error_handler.dart      # Error handling helpers
```

---

## 🎨 Màu sắc & Theme

### App Colors (`lib/constants/app_colors.dart`)
Tất cả màu sắc được định nghĩa tập trung:

```dart
class AppColors {
  static const Color primary = Color(0xFF1976D2);    // #1976D2 - Blue
  static const Color secondary = Color(0xFFFF6F00);  // #FF6F00 - Orange
  static const Color success = Color(0xFF4CAF50);    // #4CAF50 - Green
  static const Color warning = Color(0xFFFFC107);    // #FFC107 - Amber
  static const Color error = Color(0xFFF44336);      // #F44336 - Red
  static const Color background = Color(0xFFF5F5F5); // #F5F5F5 - Light Gray
  static const Color surface = Color(0xFFFFFFFF);    // #FFFFFF - White
}
```

### Theme Configuration (`lib/theme/app_theme.dart`)
- **Material 3** theme
- Font family: `Roboto`
- Border radius: `8.0` (base)
- Spacing constants: `xs(4), sm(8), md(16), lg(24), xl(32)`

**Sử dụng:**
```dart
Theme.of(context).colorScheme.primary
AppColors.primary
AppRadius.base
AppSpacing.md
```

---

## 🔌 API Service

### ApiService (`lib/services/api_service.dart`)
**Singleton** Dio-based API client với các tính năng:

#### Khởi tạo:
```dart
void main() {
  ApiService.init(); // hoặc ApiService.init(tokenStorage: CustomStorage())
  runApp(MyApp());
}
```

#### Token Management:
- Tự động thêm `Authorization: Bearer <token>` vào headers
- **Token refresh** tự động khi gặp lỗi 401
- Queue các request đang chờ trong lúc refresh
- Support `TokenStorage` interface (SecureTokenStorage/SharedPrefTokenStorage)

#### Base URL:
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **Desktop/Web**: `http://127.0.0.1:8000/api`

#### Endpoints chính:

**Authentication:**
```dart
login(email, password, role)
logout()
me()
refresh()
```

**Notifications:**
```dart
getNotifications({page, perPage, params})
getNotificationById(id)
createNotification(payload)
updateNotification(id, payload)
deleteNotification(id)
markNotificationRead(id)
respondToNotification(id, payload)
getNotificationResponses(notificationId)
getNotificationStatistics()
```

**Activities:**
```dart
getActivities({query})
getActivityById(id)
createActivity(payload)
updateActivity(id, payload)
deleteActivity(id)
registerActivity(payload)
myRegistrations()
cancelRegistration(payload)
assignStudentsToActivity(activityId, assignments)
getAvailableStudents(activityId, {filters...})
```

**Students & Classes:**
```dart
getStudents({page, perPage, q, classId})
getStudentById(id)
createStudent(payload)
updateStudent(id, payload)
deleteStudent(id)
getClasses({page, perPage, params})
getClassDetail(classId)
getStudentsByClass(classId)
createClass(payload)
updateClass(classId, payload)
deleteClass(classId)
```

**Messages:**
```dart
getMessages({query})
sendMessage(payload)
markMessageRead(id)
```

---

## 🔄 State Management (Provider)

### AuthProvider (`lib/providers/auth_provider.dart`)
Quản lý authentication state:

**Properties:**
- `User? currentUser`
- `String? token`
- `bool isAuthenticated`
- `bool isLoading`
- `Stream<bool> authStateChanges`

**Methods:**
```dart
login(email, password, role)
logout()
checkAuthStatus()
refreshToken()
```

### NotificationsProvider (Student)
(`lib/providers/notification_provider_student.dart`)

**Cho sinh viên:**
```dart
fetchAll()                    // Lấy tất cả thông báo
fetchUnread()                 // Lấy thông báo chưa đọc
fetchDetail(id)               // Chi tiết thông báo
markAsRead(notification)      // Đánh dấu đã đọc
markAllAsRead()              // Đánh dấu tất cả đã đọc
```

**Properties:**
- `List<NotificationModel> allNotifications`
- `List<NotificationModel> unreadNotifications`
- `int unreadCount`
- `NotificationModel? selectedNotification`

### AdvisorNotificationsProvider
(`lib/providers/notifications_provider.dart`)

**Cho giảng viên:**
```dart
fetchNotifications()          // Lấy thông báo đã tạo
fetchDetail(id)               // Chi tiết
fetchResponses(id)            // Lấy phản hồi từ sinh viên
createNotification(...)       // Tạo mới
updateNotification(...)       // Cập nhật
deleteNotification(id)        // Xóa
replyToResponse(...)          // Phản hồi sinh viên
fetchStatistics()             // Thống kê
setTypeFilter(type)           // Lọc theo loại
```

**Properties:**
- `List<NotificationModel> notifications`
- `List<StudentResponseInfo> responses`
- `NotificationStatistics? statistics`
- `String typeFilter` (all/general/academic/activity/urgent)

### ActivitiesProvider
Quản lý hoạt động cho sinh viên:
```dart
fetchActivities({q, date, minPoints, status})
register(payload)
cancelRegistration(payload)
```

### AdvisorActivitiesProvider
Quản lý hoạt động cho giảng viên (CRUD):
```dart
fetchActivities({page, perPage})
fetchDetail(activityId)
createActivity(payload, {assignByAdvisor, assignments})
updateActivity(activityId, payload)
deleteActivity(activityId)
```

### StudentProvider
Quản lý danh sách sinh viên:
```dart
fetchStudents({page, perPage, search, classId, status, reset})
fetchStudentDetail(id)
createStudent(payload)
updateStudent(id, payload)
deleteStudent(id)
```

### ClassProvider
Quản lý lớp học:
```dart
fetchClasses({page, perPage, reset})
fetchClassDetail(classId)
fetchStudentsByClass(classId)
createClass(payload)
updateClass(classId, payload)
deleteClass(classId)
```

---

## 🛣️ Routing (GoRouter)

### App Router (`lib/app_router.dart`)

**Cấu trúc:**
- Sử dụng **GoRouter** (Router 2.0)
- Auth guard: redirect đến `/login` nếu chưa đăng nhập
- Role-based routing: `/student/*` và `/advisor/*`

**Student Routes:**
```
/student/home                  # Trang chủ sinh viên
/student/notifications         # Danh sách thông báo
/student/notifications/:id     # Chi tiết thông báo
/student/activities            # Danh sách hoạt động
/student/activities/:id        # Chi tiết hoạt động
/student/my-registrations      # Hoạt động đã đăng ký
/student/points                # Quản lý điểm
/student/chat/:advisorId       # Chat với CVHT
/student/profile               # Hồ sơ sinh viên
```

**Advisor Routes:**
```
/advisor/home                  # Dashboard giảng viên
/advisor/notifications         # Danh sách thông báo
/advisor/notifications/create  # Tạo thông báo mới
/advisor/notifications/:id     # Chi tiết thông báo
/advisor/notifications/edit/:id # Sửa thông báo
/advisor/students              # Quản lý sinh viên
/advisor/students/:id          # Chi tiết sinh viên
/advisor/activities/manage     # Quản lý hoạt động
/advisor/activities/manage/create # Tạo hoạt động
/advisor/activities/manage/edit/:id # Sửa hoạt động
/advisor/profile               # Hồ sơ giảng viên
```

**Navigation:**
```dart
context.go('/student/home')
context.push('/student/notifications/:id')
```

---

## 🧩 Reusable Widgets

### Custom Widgets (`lib/widgets/`)

**CustomAppBar:**
```dart
CustomAppBar(
  title: 'Title',
  actions: [...],
  gradient: LinearGradient(...),
)
```

**CustomButton:**
```dart
CustomButton(
  onPressed: () {},
  child: Text('Submit'),
  isLoading: true,
  style: CustomButtonStyle.primary, // primary/secondary/outlined
)
```

**CustomTextField:**
```dart
CustomTextField(
  label: 'Email',
  controller: controller,
  isPassword: true,
  validator: (v) => v?.isEmpty ? 'Required' : null,
)
```

**CustomCard:**
```dart
CustomCard(
  padding: EdgeInsets.all(16),
  onTap: () {},
  child: Text('Content'),
)
```

**EmptyState:**
```dart
EmptyState(
  icon: Icons.inbox,
  message: 'No data',
  actionLabel: 'Reload',
  onAction: () {},
)
```

**LoadingIndicator:**
```dart
LoadingIndicator(mode: LoadingMode.circular) // circular/linear/skeleton
```

**ErrorDisplay:**
```dart
ErrorDisplay(
  message: 'Error occurred',
  onRetry: () {},
)
```

**StatusBadge:**
```dart
StatusBadge(label: 'Đủ điều kiện') // Tự động chọn màu
```

**BadgeIcon:**
```dart
BadgeIcon(icon: Icons.notifications, count: 5)
```

**AvatarWidget:**
```dart
AvatarWidget(
  imageUrl: 'https://...',
  initials: 'AB',
  radius: 32,
)
```

---

## 📱 Screens Overview

### Main Scaffold (`lib/screens/main_scaffold.dart`)
Bottom navigation wrapper với **PageStorage** để giữ scroll state.

**Features:**
- Tab navigation với badge (unread count)
- Tự động switch giữa student/advisor tabs
- PageStorageBucket để preserve state

### Student Screens

**Home:** Tổng quan, quick links, thông báo mới nhất  
**Notifications:** Danh sách thông báo (All/Unread tabs)  
**Activities:** Danh sách hoạt động (Upcoming/Registered/History)  
**My Registrations:** Hoạt động đã đăng ký, cancel requests  
**Points:** Điểm rèn luyện, CTXH, khiếu nại  
**Profile:** Hồ sơ, thống kê học tập  

### Advisor Screens

**Home:** Dashboard, thống kê tổng quan  
**Notifications:** Quản lý thông báo (CRUD), xem phản hồi  
**Students Management:** Danh sách sinh viên, filter, sort  
**Activities Management:** Quản lý hoạt động (CRUD)  
**Student Detail:** Chi tiết sinh viên, ghi chú theo dõi  
**Profile:** Hồ sơ giảng viên  

---

## ⚠️ Error Handling

### ErrorHandler (`lib/utils/error_handler.dart`)

**ApiException:**
```dart
class ApiException {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors; // validation errors
}
```

**Usage:**
```dart
try {
  await api.login(...);
} catch (e) {
  ErrorHandler.showSnack(context, e);
  // hoặc
  ErrorHandler.showDialogFor(context, e);
}
```

**Helpers:**
- `mapToMessage(error)` - Map lỗi sang tiếng Việt
- `AsyncValueWidget` - Widget wrapper cho Future/Stream
- `RetryWrapper` - Error display với retry button

---

## 🔐 Authentication Flow

1. **Login** → `AuthProvider.login()` → Save tokens → Navigate to home
2. **Token in Header** → `ApiService` interceptor tự động thêm
3. **401 Error** → Auto refresh token → Retry request
4. **Refresh Failed** → Logout → Navigate to login
5. **Logout** → Clear tokens → Navigate to login

---

## 📦 Models

### Barrel Export (`lib/models/models.dart`)
Import tất cả models:
```dart
import 'package:app/models/models.dart';
```

### Key Models:
- **User:** Base user model (id, userCode, fullName, email, role)
- **Student:** Student-specific data
- **Advisor:** Advisor-specific data
- **NotificationModel:** Notification với relations (advisor, classes, attachments, responses)
- **Activity:** Activity với roles
- **ActivityRole:** Vai trò trong hoạt động (points, slots)
- **ActivityRegistration:** Đăng ký hoạt động
- **ClassModel:** Lớp học
- **Semester:** Học kỳ
- **Course & CourseGrade:** Môn học và điểm

**Common patterns:**
```dart
Model.fromJson(json)
model.toJson()
model.copyWith(...)
```

---

## 🎯 Best Practices

### 1. Provider Usage:
```dart
// In build method
final provider = context.watch<AuthProvider>();

// In callbacks
final provider = context.read<AuthProvider>();

// Outside build
Provider.of<AuthProvider>(context, listen: false)
```

### 2. Navigation:
```dart
context.go('/path')      // Replace
context.push('/path')    // Stack
context.pop()            // Back
```

### 3. API Calls:
```dart
try {
  final resp = await ApiService.instance.getNotifications();
  // Handle success
} on ApiException catch (e) {
  ErrorHandler.showSnack(context, e);
}
```

### 4. Form Validation:
```dart
final _formKey = GlobalKey<FormState>();

TextFormField(
  validator: (v) => v?.isEmpty ?? true ? 'Bắt buộc' : null,
)

if (_formKey.currentState!.validate()) {
  // Submit
}
```

---

## 🚀 Getting Started

### 1. Dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  go_router: ^13.0.0
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.0.0
  file_picker: ^6.0.0
  url_launcher: ^6.0.0
  intl: ^0.18.0
  fl_chart: ^0.66.0
```

### 2. Run:
```bash
flutter pub get
flutter run
```

### 3. API Configuration:
Edit `ApiService._baseUrl` nếu cần thay đổi backend URL.

---

## 📝 Notes

- **Material 3** design system
- **Provider** cho state management
- **GoRouter** cho routing (declarative)
- **Dio** với auto token refresh
- **SharedPreferences** cho token persistence
- Dark mode: chưa implement (có thể extend `AppTheme.dark()`)
- Localization: chưa có (hardcoded Vietnamese)

---

## 🐛 Common Issues

**1. Token refresh loop:**
→ Check `_isRequestToRefresh()` trong `ApiService`

**2. Navigation không hoạt động:**
→ Kiểm tra auth state trong `app_router.dart`

**3. Provider not found:**
→ Đảm bảo wrap với `MultiProvider` trong `main.dart`

**4. CORS trên web:**
→ Backend cần enable CORS headers

**5. Android emulator không kết nối được API:**
→ Sử dụng `10.0.2.2` thay vì `localhost`

---

## 📞 Contact & Support

**Issues:** Report tại GitHub repository  
**Documentation:** File này + code comments

---

**Last Updated:** 2025-01-19  
**Version:** 1.0.0  
**Flutter SDK:** >=3.0.0