import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class AppStrings {
  final bool _isEn;

  AppStrings._(this._isEn);

  static AppStrings of(BuildContext context, {bool listen = true}) {
    final provider = Provider.of<LocaleProvider>(context, listen: listen);
    return AppStrings._(provider.isEnglish);
  }

  static AppStrings ofLocale(String locale) {
    return AppStrings._(locale == 'en');
  }

  // --- Navigation ---
  String get home => _isEn ? 'Home' : 'Trang chủ';
  String get courses => _isEn ? 'Courses' : 'Khóa học';
  String get aiChatbot => _isEn ? 'AI Assistant' : 'Trợ lý ảo';
  String get me => _isEn ? 'Me' : 'Cá nhân';

  // --- Auth Screen ---
  String get signIn => _isEn ? 'Sign in' : 'Đăng nhập';
  String get signUp => _isEn ? 'Sign up' : 'Đăng ký';
  String get welcomeBack => _isEn ? 'Welcome back' : 'Chào mừng trở lại';
  String get createAccount => _isEn ? 'Create an account here' : 'Tạo tài khoản mới';
  String get username => _isEn ? 'Username' : 'Tên người dùng';
  String get emailAddress => _isEn ? 'Email address' : 'Địa chỉ email';
  String get password => _isEn ? 'Password' : 'Mật khẩu';
  String get forgotPassword => _isEn ? 'Forgot Password?' : 'Quên mật khẩu?';
  String get termsOfUse => _isEn ? 'By signing up you agree with our Terms of Use' : 'Bằng việc đăng ký, bạn đồng ý với Điều khoản sử dụng';
  String get newMember => _isEn ? 'New member? ' : 'Chưa có tài khoản? ';
  String get alreadyMember => _isEn ? 'Already a member? ' : 'Đã có tài khoản? ';
  String get signInSuccess => _isEn ? 'Sign in successful!' : 'Đăng nhập thành công!';
  String get signUpSuccess => _isEn ? 'Sign up successful!' : 'Đăng ký thành công!';

  // --- Reset Password ---
  String get resetPassword => _isEn ? 'Reset Password' : 'Đặt lại mật khẩu';
  String get resetPasswordDesc => _isEn
      ? 'Enter your email address and we will send you a link to reset your password.'
      : 'Nhập địa chỉ email và chúng tôi sẽ gửi cho bạn liên kết đặt lại mật khẩu.';
  String get cancel => _isEn ? 'Cancel' : 'Hủy';
  String get sendLink => _isEn ? 'Send Link' : 'Gửi liên kết';
  String get pleaseEnterEmail => _isEn ? 'Please enter an email!' : 'Vui lòng nhập email!';
  String get checkYourEmail => _isEn ? 'Check your email' : 'Kiểm tra email';
  String checkYourEmailDesc(String email) => _isEn
      ? 'We have sent password recover instructions to your email.\n\n$email\n\nPlease check your inbox and spam folder.'
      : 'Chúng tôi đã gửi hướng dẫn khôi phục mật khẩu đến email.\n\n$email\n\nVui lòng kiểm tra hộp thư đến và thư rác.';
  String get ok => _isEn ? 'OK' : 'OK';
  String get oopsError => _isEn ? 'Oops! Error' : 'Lỗi!';
  String get tryAgain => _isEn ? 'Try Again' : 'Thử lại';

  // --- Home Screen ---
  String get search => _isEn ? 'Search' : 'Tìm kiếm';
  String noWordFound(String query) => _isEn ? "No word found: '$query'" : "Không tìm thấy từ: '$query'";
  String get goodMorning => _isEn ? 'Good morning' : 'Chào buổi sáng';
  String get goodAfternoon => _isEn ? 'Good afternoon' : 'Chào buổi chiều';
  String get goodEvening => _isEn ? 'Good evening' : 'Chào buổi tối';
  String get readyToLearn => _isEn ? 'Ready to learn?' : 'Sẵn sàng học chưa?';
  String get letsReview => _isEn ? "Let's review some words" : 'Cùng ôn tập từ vựng nhé';
  String get wordOfTheDay => _isEn ? 'Word of the Day' : 'Từ vựng của ngày';
  String get dailyChallenge => _isEn ? 'Daily Challenge' : 'Thử thách hàng ngày';
  String get continueLearning => _isEn ? 'Continue Learning' : 'Tiếp tục học';
  String get recentWords => _isEn ? 'Recent Words' : 'Từ vựng gần đây';
  String get streak => _isEn ? 'Streak' : 'Chuỗi';
  String get coins => _isEn ? 'Coins' : 'Xu';

  // --- Flashcard ---
  String get tapToSeeExamples => _isEn ? 'Tap to see examples' : 'Chạm để xem ví dụ';
  String get tapToSeeDefinition => _isEn ? 'Tap to see definition' : 'Chạm để xem định nghĩa';
  String get definition => _isEn ? 'Definition' : 'Định nghĩa';
  String get examples => _isEn ? 'Examples:' : 'Ví dụ:';
  String get noDefinition => _isEn ? 'No definition' : 'Chưa có định nghĩa';
  String get noExamples => _isEn ? 'No examples available' : 'Chưa có ví dụ cho từ này';
  String get noAudio => _isEn ? 'No audio available for this word!' : 'Không có âm thanh cho từ này!';

  // --- Courses Screen ---
  String get chooseTopicToLearn => _isEn ? 'Choose a topic to start learning' : 'Chọn chủ đề để bắt đầu học';
  String lessons(int count) => '$count ${_isEn ? 'lessons' : 'bài học'}';
  String words(int count) => '$count ${_isEn ? 'words' : 'từ'}';
  String get lessonsLabel => _isEn ? 'Lessons' : 'Bài học';
  String get wordsLabel => _isEn ? 'Words' : 'Từ vựng';

  // --- Lesson Detail ---
  String get next => _isEn ? 'Next' : 'Tiếp';
  String get complete => _isEn ? 'Complete' : 'Hoàn thành';
  String get finish => _isEn ? 'Finish' : 'Hoàn tất';
  String get wellDone => _isEn ? 'Well done!' : 'Tuyệt vời!';
  String lessonCompleted(String title, int wordCount) => _isEn
      ? 'You have completed $title.\n$wordCount words reviewed!'
      : 'Bạn đã hoàn thành $title.\n$wordCount từ đã ôn tập!';
  String get noWordsFound => _isEn ? 'No words found' : 'Không tìm thấy từ nào';
  String lessonWithTitle(String title) {
    // Remove "Lesson " or "Bài học " prefix from title if it exists in the DB string
    String cleanTitle = title.replaceAll(RegExp(r'^(Lesson|Bài học)\s*', caseSensitive: false), '');
    return _isEn ? 'Lesson $cleanTitle' : 'Bài học $cleanTitle';
  }
  String topicWithTitle(String title) {
    final Map<String, String> topicMap = {
      'giáo dục': 'Education',
      'education': 'Education',
      'sức khỏe': 'Health',
      'health': 'Health',
      'y tế': 'Health',
      'medical': 'Health',
      'sức khỏe & y tế': 'Health',
      'sức khỏe & y tế ': 'Health',
      'du lịch': 'Travel',
      'travel': 'Travel',
      'công nghệ': 'IT',
      'it': 'IT',
      'ẩm thực': 'Food',
      'food': 'Food',
      'kinh doanh': 'Business',
      'business': 'Business',
      'nghề nghiệp': 'Career',
      'career': 'Career',
      'gia đình': 'Family',
      'family': 'Family',
      'thể thao': 'Sports',
      'sports': 'Sports',
    };

    String key = title.toLowerCase().trim();
    
    // Kiểm tra khớp hoàn toàn hoặc chứa từ khóa
    String? foundKey;
    for (var entry in topicMap.keys) {
      if (key == entry || key.contains(entry)) {
        foundKey = entry;
        break;
      }
    }

    if (foundKey != null) {
      return _isEn ? topicMap[foundKey]! : (foundKey == title.toLowerCase() ? title : foundKey);
    }

    return title;
  }

  // --- Profile Screen ---
  String get editProfile => _isEn ? 'Edit Profile' : 'Chỉnh sửa hồ sơ';
  String get settings => _isEn ? 'Settings' : 'Cài đặt';
  String get termsOfService => _isEn ? 'Terms of Service' : 'Điều khoản dịch vụ';
  String get privacyPolicy => _isEn ? 'Privacy policy' : 'Chính sách bảo mật';
  String get logOut => _isEn ? 'Log Out' : 'Đăng xuất';
  String get defaultUser => _isEn ? 'User' : 'Người dùng';
  String get noEmail => _isEn ? 'No email set' : 'Chưa cập nhật email';

  // --- Edit Profile Screen ---
  String get profile => _isEn ? 'Profile' : 'Hồ sơ';
  String get changeUsername => _isEn ? 'Change Username' : 'Đổi tên người dùng';
  String get changePassword => _isEn ? 'Change Password' : 'Đổi mật khẩu';
  String get newUsername => _isEn ? 'New username' : 'Tên mới';
  String get currentPassword => _isEn ? 'Current password' : 'Mật khẩu hiện tại';
  String get newPassword => _isEn ? 'New password' : 'Mật khẩu mới';
  String get confirmPassword => _isEn ? 'Confirm password' : 'Xác nhận mật khẩu';
  String get save => _isEn ? 'Save' : 'Lưu';
  String get pleaseEnterUsername => _isEn ? 'Please enter a username' : 'Vui lòng nhập tên người dùng';
  String get sameUsername => _isEn ? 'New name is the same as current!' : 'Tên mới trùng với tên hiện tại!';
  String get pleaseEnterPassword => _isEn ? 'Please enter your password' : 'Vui lòng nhập mật khẩu xác nhận';
  String get usernameChanged => _isEn ? 'Username changed successfully!' : 'Đổi tên thành công!';
  String get forgotPasswordDesc => _isEn
      ? 'We will send a password reset link to the following email address:'
      : 'Chúng tôi sẽ gửi một liên kết đặt lại mật khẩu đến địa chỉ email sau:';
  String get emailNotFound => _isEn ? 'Error: User email not found.' : 'Lỗi: Không tìm thấy email người dùng.';
  String get resetLinkSent => _isEn
      ? 'Password reset link sent! Please check your email and sign in again.'
      : 'Link đặt lại mật khẩu đã được gửi! Vui lòng kiểm tra email và đăng nhập lại.';
  String get pleaseFillAllFields => _isEn ? 'Please fill in all fields' : 'Vui lòng điền đủ thông tin';
  String get passwordsDoNotMatch => _isEn ? 'New passwords do not match!' : 'Mật khẩu mới không khớp!';
  String get passwordChanged => _isEn
      ? 'Password changed successfully! Please sign in again.'
      : 'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.';

  // --- Settings Screen ---
  String get language => _isEn ? 'Language' : 'Ngôn ngữ';
  String get notification => _isEn ? 'Notification' : 'Thông báo';
  String get darkMode => _isEn ? 'Dark Mode' : 'Chế độ tối';
  String get selectLanguage => _isEn ? 'Select Language' : 'Chọn ngôn ngữ';
  String get english => _isEn ? 'English' : 'English';
  String get vietnamese => _isEn ? 'Vietnamese' : 'Tiếng Việt';

  // --- AI Chatbot ---
  String get aiAssistant => _isEn ? 'AI Assistant' : 'Trợ lý AI';
  String get chatbotGreeting => _isEn
      ? 'Hello! I am your English assistant. What would you like to learn today?'
      : 'Xin chào! Tôi là trợ lý tiếng Anh của bạn. Bạn muốn học gì hôm nay?';
  String get chatbotFallback => _isEn ? "I don't understand..." : 'Tôi không hiểu ý bạn...';
  String connectionError(String e) => _isEn ? 'Connection error: $e' : 'Lỗi kết nối: $e';
  String get aiOverloaded => _isEn
      ? 'AI system is overloaded. Please wait a moment and try again!'
      : 'Hệ thống AI đang quá tải. Bạn vui lòng đợi một lát rồi thử lại nhé!';
  String get tooManyRequests => _isEn
      ? 'Too many requests. Please wait a moment!'
      : 'Bạn đã gửi quá nhiều yêu cầu. Vui lòng đợi một chút nhé!';
  String get clearChatHistory => _isEn ? 'Clear chat history' : 'Xóa lịch sử chat';
  String get clearChatConfirm => _isEn ? 'Clear chat history?' : 'Xóa lịch sử chat?';
  String get clearChatDesc => _isEn
      ? 'All old messages will be permanently deleted. Are you sure you want to proceed?'
      : 'Tất cả tin nhắn cũ sẽ biến mất vĩnh viễn. Bạn có chắc chắn muốn thực hiện hành động này không?';
  String get delete => _isEn ? 'Delete' : 'Xóa';

  // --- Auth Services (error messages) ---
  String get passwordChangedSuccess => _isEn ? 'Password changed successfully!' : 'Thành công: Đã đổi mật khẩu mới!';
  String get notLoggedIn => _isEn ? 'Error: You are not logged in.' : 'Lỗi: Bạn chưa đăng nhập.';
  String get requiresReLogin => _isEn
      ? 'Security: Please sign out and sign in again before changing password.'
      : 'Bảo mật: Bạn cần đăng xuất và đăng nhập lại trước khi đổi mật khẩu.';
  String get accountNotFound => _isEn ? 'Error: Account not found.' : 'Lỗi: Không tìm thấy tài khoản.';
  String get sessionInvalid => _isEn ? 'Error: Session is invalid.' : 'Lỗi: Phiên đăng nhập không hợp lệ.';
  String get incorrectPassword => _isEn ? 'Current password is incorrect!' : 'Mật khẩu hiện tại không chính xác!';
  String get authError => _isEn ? 'Authentication error' : 'Lỗi xác thực';
  String get unknownError => _isEn ? 'Unknown error' : 'Lỗi không xác định';
}