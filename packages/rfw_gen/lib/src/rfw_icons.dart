/// Pre-mapped Material icon codepoints for use with rfw_gen.
///
/// Since `Icons.home` codepoints are Flutter SDK runtime constants
/// inaccessible at build-time via package:analyzer, this class provides
/// const codepoints for commonly used icons.
///
/// Usage in @RfwWidget functions:
/// ```dart
/// Icon(icon: RfwIcon.home, size: 24)
/// ```
class RfwIcon {
  RfwIcon._();

  // --- Navigation ---
  static const int home = 0xe318;
  static const int menu = 0xe3dc;
  static const int arrowBack = 0xe092;
  static const int arrowForward = 0xe093;
  static const int arrowUpward = 0xe094;
  static const int arrowDownward = 0xe091;
  static const int close = 0xe16a;
  static const int chevronLeft = 0xe15d;
  static const int chevronRight = 0xe15e;
  static const int expandMore = 0xe233;
  static const int expandLess = 0xe232;

  // --- Action ---
  static const int search = 0xe567;
  static const int settings = 0xe57f;
  static const int delete = 0xe1b9;
  static const int add = 0xe047;
  static const int remove = 0xe4f7;
  static const int edit = 0xe22b;
  static const int check = 0xe156;
  static const int refresh = 0xe514;
  static const int done = 0xe1e0;
  static const int save = 0xe55c;
  static const int copy = 0xe190;
  static const int filterList = 0xe26c;

  // --- Content ---
  static const int favorite = 0xe25b;
  static const int favoriteBorder = 0xe25c;
  static const int share = 0xe580;
  static const int send = 0xe571;
  static const int star = 0xe5f9;
  static const int starBorder = 0xe5fa;
  static const int bookmark = 0xe12e;
  static const int bookmarkBorder = 0xe12f;
  static const int link = 0xe3a0;
  static const int flag = 0xe269;

  // --- Communication ---
  static const int email = 0xe22a;
  static const int phone = 0xe4a2;
  static const int chat = 0xe15b;
  static const int notifications = 0xe42f;
  static const int notificationsNone = 0xe431;
  static const int message = 0xe3e0;

  // --- Media ---
  static const int image = 0xe3a4;
  static const int camera = 0xe3b0;
  static const int playArrow = 0xe4a3;
  static const int pause = 0xe49b;
  static const int volumeUp = 0xe64d;
  static const int volumeOff = 0xe64f;

  // --- Status ---
  static const int info = 0xe35b;
  static const int warning = 0xe648;
  static const int error = 0xe237;
  static const int help = 0xe302;
  static const int visibility = 0xe63e;
  static const int visibilityOff = 0xe63f;
  static const int lock = 0xe3b6;
  static const int lockOpen = 0xe3b7;

  /// Lookup map for ExpressionConverter.
  static const Map<String, int> _codepoints = {
    'home': home, 'menu': menu, 'arrowBack': arrowBack,
    'arrowForward': arrowForward, 'arrowUpward': arrowUpward,
    'arrowDownward': arrowDownward, 'close': close,
    'chevronLeft': chevronLeft, 'chevronRight': chevronRight,
    'expandMore': expandMore, 'expandLess': expandLess,
    'search': search, 'settings': settings, 'delete': delete,
    'add': add, 'remove': remove, 'edit': edit, 'check': check,
    'refresh': refresh, 'done': done, 'save': save, 'copy': copy,
    'filterList': filterList, 'favorite': favorite,
    'favoriteBorder': favoriteBorder, 'share': share, 'send': send,
    'star': star, 'starBorder': starBorder, 'bookmark': bookmark,
    'bookmarkBorder': bookmarkBorder, 'link': link, 'flag': flag,
    'email': email, 'phone': phone, 'chat': chat,
    'notifications': notifications, 'notificationsNone': notificationsNone,
    'message': message, 'image': image, 'camera': camera,
    'playArrow': playArrow, 'pause': pause, 'volumeUp': volumeUp,
    'volumeOff': volumeOff, 'info': info, 'warning': warning,
    'error': error, 'help': help, 'visibility': visibility,
    'visibilityOff': visibilityOff, 'lock': lock, 'lockOpen': lockOpen,
  };

  /// Returns the codepoint for the given icon [name], or null if unknown.
  static int? lookup(String name) => _codepoints[name];
}
