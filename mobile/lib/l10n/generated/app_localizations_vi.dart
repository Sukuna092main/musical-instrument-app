// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Music Practice Tracker';

  @override
  String get practiceDashboard => 'Tổng quan luyện tập';

  @override
  String hi(String name) {
    return 'Chào, $name';
  }

  @override
  String get readyForToday => 'Sẵn sàng tập hôm nay chưa?';

  @override
  String get today => 'Hôm nay';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get streak => 'Chuỗi ngày';

  @override
  String get allTime => 'Tất cả';

  @override
  String sessions(int count) {
    return '$count buổi';
  }

  @override
  String completedSessions(int count) {
    return '$count buổi đã hoàn thành';
  }

  @override
  String daysRemaining(int count) {
    return 'Còn $count ngày';
  }

  @override
  String bestDays(int count) {
    return 'Tốt nhất $count ngày';
  }

  @override
  String get practiceTimer => 'Hẹn giờ tập';

  @override
  String get practiceTimerSubtitle =>
      'Bắt đầu buổi tập có ghi chú và tâm trạng';

  @override
  String get practiceHistory => 'Lịch sử luyện tập';

  @override
  String get practiceHistorySubtitle =>
      'Xem lại các buổi tập, ghi chú và tâm trạng';

  @override
  String get goals => 'Mục tiêu';

  @override
  String get goalsSubtitle => 'Theo dõi phút/ngày, ngày/tuần và chuỗi ngày';

  @override
  String get learn => 'Học';

  @override
  String get learnSubtitle => 'Xem bài học, hợp âm và gam';

  @override
  String get myInstruments => 'Nhạc cụ của tôi';

  @override
  String get myInstrumentsSubtitle => 'Quản lý nhạc cụ bạn đang luyện tập';

  @override
  String get practiceInProgress => 'Đang luyện tập';

  @override
  String get noActivePractice => 'Chưa có buổi tập nào';

  @override
  String get startWhenReady => 'Bắt đầu hẹn giờ khi bạn sẵn sàng';

  @override
  String get logOut => 'Đăng xuất';

  @override
  String get logOutQuestion => 'Đăng xuất?';

  @override
  String get logOutConfirm => 'Bạn sẽ cần đăng nhập lại để tiếp tục.';

  @override
  String get cancel => 'Hủy';

  @override
  String get support => 'Hỗ trợ';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String couldNotLoad(String what) {
    return 'Không tải được $what';
  }

  @override
  String get retry => 'Tải lại';

  @override
  String get account => 'Tài khoản';

  @override
  String get fullName => 'Họ và tên';

  @override
  String get phone => 'Điện thoại';

  @override
  String get phoneNotSet => 'Chưa đặt';

  @override
  String get email => 'Email';

  @override
  String get accountType => 'Loại tài khoản';

  @override
  String get subscription => 'Đăng ký';

  @override
  String get vipMembership => 'Thành viên VIP';

  @override
  String get viewPlans => 'Xem các gói và trạng thái đăng ký';

  @override
  String get editFullName => 'Sửa họ và tên';

  @override
  String get editPhone => 'Sửa điện thoại';

  @override
  String get phoneNumberLabel => 'Số điện thoại';

  @override
  String get save => 'Lưu';

  @override
  String get nameUpdated => 'Đã cập nhật tên.';

  @override
  String get phoneUpdated => 'Đã cập nhật điện thoại.';

  @override
  String get profilePhotoUpdated => 'Đã cập nhật ảnh hồ sơ.';

  @override
  String get onlyJpgPngWebp => 'Chỉ hỗ trợ ảnh JPG, PNG và WEBP.';

  @override
  String get changeProfilePhoto => 'Đổi ảnh hồ sơ';

  @override
  String get buildYourSkills => 'Xây dựng kỹ năng';

  @override
  String get lessonsSubtitle => 'Chọn bài học và tiếp tục tiến độ của bạn.';

  @override
  String get chords => 'Hợp âm';

  @override
  String get scales => 'Gam';

  @override
  String get all => 'Tất cả';

  @override
  String get noLessonsAvailable => 'Chưa có bài học nào';

  @override
  String get couldNotLoadLessons => 'Không tải được bài học';

  @override
  String get completed => 'Đã hoàn thành';

  @override
  String get inProgress => 'Đang học';

  @override
  String get vipLesson => 'Bài học VIP';

  @override
  String get beginner => 'Sơ cấp';

  @override
  String get intermediate => 'Trung cấp';

  @override
  String get advanced => 'Cao cấp';

  @override
  String get refreshLessons => 'Tải lại bài học';

  @override
  String get filterByInstrument => 'Lọc theo nhạc cụ';

  @override
  String get noMoreSessions => 'Không còn buổi nào';

  @override
  String get noCompletedSessionsYet => 'Chưa có buổi hoàn thành nào';

  @override
  String get finishPracticeToSee => 'Hoàn thành một buổi tập để xem tại đây.';

  @override
  String get couldNotLoadHistory => 'Không tải được lịch sử';

  @override
  String get moodGreat => 'Tuyệt';

  @override
  String get moodGood => 'Tốt';

  @override
  String get moodOkay => 'Tạm được';

  @override
  String get moodBad => 'Tệ';

  @override
  String get howCanWeHelp => 'Chúng tôi có thể giúp gì?';

  @override
  String get chatSubtitle =>
      'Hỏi về luyện tập, mục tiêu, bài học, VIP hoặc thanh toán.';

  @override
  String get typeMessage => 'Nhập tin nhắn…';

  @override
  String get couldNotLoadMessages => 'Không tải được tin nhắn';

  @override
  String get settings => 'Cài đặt';

  @override
  String get appearance => 'Hiển thị';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get darkModeSubtitle => 'Dùng giao diện tối cho ứng dụng';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get about => 'Giới thiệu';

  @override
  String get version => 'Phiên bản';

  @override
  String get instrument => 'Nhạc cụ';

  @override
  String get readyToPractice => 'Sẵn sàng tập chưa?';

  @override
  String get chooseInstrumentHint =>
      'Chọn nhạc cụ và bắt đầu buổi tập của bạn.';

  @override
  String get noInstrumentYet => 'Bạn chưa thêm nhạc cụ nào vào hồ sơ.';

  @override
  String get addInstrument => 'Thêm nhạc cụ';

  @override
  String get startPractice => 'Bắt đầu tập';

  @override
  String get starting => 'Đang bắt đầu...';

  @override
  String get practiceNotes => 'Ghi chú tập luyện';

  @override
  String get notesHint => 'Hôm nay bạn đã tập những gì?';

  @override
  String get howDidItFeel => 'Cảm thấy thế nào?';

  @override
  String get sessionInProgress => 'Buổi tập đang diễn ra';

  @override
  String get endAndSave => 'Kết thúc và lưu buổi tập';

  @override
  String get saving => 'Đang lưu...';

  @override
  String get practice => 'Luyện tập';

  @override
  String get askAbout =>
      'Hỏi về luyện tập, mục tiêu, bài học, VIP hoặc thanh toán.';

  @override
  String get cancelSession => 'Hủy buổi tập';

  @override
  String get cancelSessionQuestion => 'Hủy buổi tập này?';

  @override
  String get cancelSessionDescription =>
      'Buổi tập này sẽ bị hủy và không được tính vào tiến độ.';

  @override
  String get cancelling => 'Đang hủy...';

  @override
  String get learningProgress => 'Tiến độ học';

  @override
  String totalLessons(int count) {
    return '$count bài học';
  }

  @override
  String inProgressLessons(int count) {
    return '$count đang học';
  }

  @override
  String completedLessons(int count) {
    return '$count đã hoàn thành';
  }

  @override
  String get noLearningProgress => 'Chưa có tiến độ học';

  @override
  String get noInProgressLessons => 'Không có bài học đang học';

  @override
  String get noCompletedLessons => 'Chưa có bài học hoàn thành';

  @override
  String get startLessonToTrackProgress =>
      'Bắt đầu một bài học để theo dõi tiến độ tại đây.';

  @override
  String completedOn(String date) {
    return 'Hoàn thành ngày $date';
  }
}
