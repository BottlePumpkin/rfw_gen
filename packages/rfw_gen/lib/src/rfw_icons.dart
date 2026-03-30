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
  static const int moreVert = 0xe3e1;
  static const int moreHoriz = 0xe3df;
  static const int arrowBackIos = 0xe5e7;
  static const int arrowForwardIos = 0xe5e8;
  static const int firstPage = 0xe268;
  static const int lastPage = 0xe39b;
  static const int navigateBefore = 0xe41b;
  static const int navigateNext = 0xe41c;
  static const int subdirectoryArrowLeft = 0xe5e0;
  static const int fullscreen = 0xe28a;
  static const int fullscreenExit = 0xe28b;

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
  static const int sort = 0xe5f4;
  static const int clear = 0xe162;
  static const int download = 0xe1d8;
  static const int upload = 0xe629;
  static const int openInNew = 0xe461;
  static const int checkCircle = 0xe157;
  static const int checkCircleOutline = 0xe158;
  static const int doneAll = 0xe1e1;
  static const int power = 0xe4a4;
  static const int print = 0xe4a5;
  static const int undo = 0xe62d;
  static const int redo = 0xe512;
  static const int zoomIn = 0xe65a;
  static const int zoomOut = 0xe65b;
  static const int login = 0xe3b3;
  static const int logout = 0xe3b4;

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
  static const int addCircle = 0xe048;
  static const int addCircleOutline = 0xe049;
  static const int removeCircle = 0xe4f8;
  static const int removeCircleOutline = 0xe4f9;
  static const int contentCopy = 0xe190;
  static const int contentPaste = 0xe192;
  static const int contentCut = 0xe191;
  static const int selectAll = 0xe570;

  // --- Communication ---
  static const int email = 0xe22a;
  static const int phone = 0xe4a2;
  static const int chat = 0xe15b;
  static const int notifications = 0xe42f;
  static const int notificationsNone = 0xe431;
  static const int message = 0xe3e0;
  static const int comment = 0xe18a;
  static const int forum = 0xe283;
  static const int call = 0xe13a;
  static const int contactPhone = 0xe18e;
  static const int contactMail = 0xe18d;
  static const int chatBubble = 0xe15c;
  static const int chatBubbleOutline = 0xe0ca;
  static const int notificationsActive = 0xe42e;
  static const int notificationsOff = 0xe430;

  // --- Social ---
  static const int person = 0xe491;
  static const int personAdd = 0xe494;
  static const int personOutline = 0xe498;
  static const int group = 0xe2f3;
  static const int groupAdd = 0xe2f4;
  static const int people = 0xe48b;
  static const int thumbUp = 0xe62a;
  static const int thumbDown = 0xe628;
  static const int thumbUpOffAlt = 0xe62b;
  static const int thumbDownOffAlt = 0xe816;
  static const int publicIcon = 0xe4a7; // 'public' is reserved

  // --- Media ---
  static const int image = 0xe3a4;
  static const int camera = 0xe3b0;
  static const int playArrow = 0xe4a3;
  static const int pause = 0xe49b;
  static const int volumeUp = 0xe64d;
  static const int volumeOff = 0xe64f;
  static const int stop = 0xe614;
  static const int skipNext = 0xe5ad;
  static const int skipPrevious = 0xe5ae;
  static const int fastForward = 0xe258;
  static const int fastRewind = 0xe259;
  static const int replay = 0xe51a;
  static const int volumeDown = 0xe64e;
  static const int volumeMute = 0xe650;
  static const int mic = 0xe3e4;
  static const int micOff = 0xe3e5;
  static const int videocam = 0xe63c;
  static const int videocamOff = 0xe63d;
  static const int photoCamera = 0xe4a0;
  static const int movie = 0xe3e2;
  static const int musicNote = 0xe3e3;

  // --- Device ---
  static const int batteryFull = 0xe109;
  static const int wifi = 0xe653;
  static const int bluetooth = 0xe12a;
  static const int gpsFixed = 0xe2f5;
  static const int screenRotation = 0xe568;
  static const int brightness = 0xe134;
  static const int flashOn = 0xe265;
  static const int flashOff = 0xe266;

  // --- File ---
  static const int folder = 0xe27b;
  static const int folderOpen = 0xe27c;
  static const int fileCopy = 0xe173;
  static const int createNewFolder = 0xe19b;
  static const int cloud = 0xe16b;
  static const int cloudUpload = 0xe16d;
  static const int cloudDownload = 0xe16c;
  static const int cloudDone = 0xe16e;
  static const int attachment = 0xe0a0;
  static const int insertDriveFile = 0xe363;
  static const int description = 0xe1b7;

  // --- Status / Alert ---
  static const int info = 0xe35b;
  static const int infoOutline = 0xe35c;
  static const int warning = 0xe648;
  static const int warningAmber = 0xe649;
  static const int error = 0xe237;
  static const int errorOutline = 0xe238;
  static const int help = 0xe302;
  static const int helpOutline = 0xe303;
  static const int visibility = 0xe63e;
  static const int visibilityOff = 0xe63f;
  static const int lock = 0xe3b6;
  static const int lockOpen = 0xe3b7;
  static const int reportProblem = 0xe517;
  static const int block = 0xe128;
  static const int doNotDisturb = 0xe1da;

  // --- Maps / Places ---
  static const int place = 0xe49f;
  static const int map = 0xe3c6;
  static const int myLocation = 0xe41a;
  static const int locationOn = 0xe3a3;
  static const int locationOff = 0xe3a5;
  static const int directions = 0xe1c4;
  static const int navigation = 0xe41d;

  // --- Fitness & Health ---
  static const int fitnessCenter = 0xe28d;
  static const int timer = 0xe662;
  static const int directionsRun = 0xe1dc;
  static const int localFireDepartment = 0xe392;
  static const int schedule = 0xe556;
  static const int trendingUp = 0xe67f;
  static const int emojiEvents = 0xe22c;
  static const int selfImprovement = 0xe56f;
  static const int monitorHeart = 0xf053d;

  // --- Toggle ---
  static const int toggleOn = 0xe620;
  static const int toggleOff = 0xe621;
  static const int checkBox = 0xe155;
  static const int checkBoxOutlineBlank = 0xe159;
  static const int radioButtonChecked = 0xe4a8;
  static const int radioButtonUnchecked = 0xe4a9;
  static const int indeterminateCheckBox = 0xe35e;
  static const int starHalf = 0xe5fb;

  /// Lookup map for ExpressionConverter.
  static const Map<String, int> _codepoints = {
    // Navigation
    'home': home, 'menu': menu, 'arrowBack': arrowBack,
    'arrowForward': arrowForward, 'arrowUpward': arrowUpward,
    'arrowDownward': arrowDownward, 'close': close,
    'chevronLeft': chevronLeft, 'chevronRight': chevronRight,
    'expandMore': expandMore, 'expandLess': expandLess,
    'moreVert': moreVert, 'moreHoriz': moreHoriz,
    'firstPage': firstPage, 'lastPage': lastPage,
    'navigateBefore': navigateBefore, 'navigateNext': navigateNext,
    'arrowBackIos': arrowBackIos, 'arrowForwardIos': arrowForwardIos,
    'subdirectoryArrowLeft': subdirectoryArrowLeft,
    'fullscreen': fullscreen, 'fullscreenExit': fullscreenExit,

    // Action
    'search': search, 'settings': settings, 'delete': delete,
    'add': add, 'remove': remove, 'edit': edit, 'check': check,
    'refresh': refresh, 'done': done, 'save': save, 'copy': copy,
    'filterList': filterList, 'sort': sort, 'clear': clear,
    'download': download, 'upload': upload, 'openInNew': openInNew,
    'checkCircle': checkCircle, 'checkCircleOutline': checkCircleOutline,
    'doneAll': doneAll, 'power': power, 'print': print, 'undo': undo,
    'redo': redo,
    'zoomIn': zoomIn, 'zoomOut': zoomOut, 'login': login, 'logout': logout,

    // Content
    'favorite': favorite, 'favoriteBorder': favoriteBorder,
    'share': share, 'send': send, 'star': star, 'starBorder': starBorder,
    'bookmark': bookmark, 'bookmarkBorder': bookmarkBorder,
    'link': link, 'flag': flag, 'addCircle': addCircle,
    'addCircleOutline': addCircleOutline, 'removeCircle': removeCircle,
    'removeCircleOutline': removeCircleOutline,
    'contentCopy': contentCopy, 'contentPaste': contentPaste,
    'contentCut': contentCut, 'selectAll': selectAll,

    // Communication
    'email': email, 'phone': phone, 'chat': chat,
    'notifications': notifications, 'notificationsNone': notificationsNone,
    'message': message, 'comment': comment, 'forum': forum,
    'call': call, 'contactPhone': contactPhone, 'contactMail': contactMail,
    'chatBubble': chatBubble, 'chatBubbleOutline': chatBubbleOutline,
    'notificationsActive': notificationsActive,
    'notificationsOff': notificationsOff,

    // Social
    'person': person, 'personAdd': personAdd, 'personOutline': personOutline,
    'group': group, 'groupAdd': groupAdd, 'people': people,
    'thumbUp': thumbUp, 'thumbDown': thumbDown,
    'thumbUpOffAlt': thumbUpOffAlt, 'thumbDownOffAlt': thumbDownOffAlt,
    'public': publicIcon,

    // Media
    'image': image, 'camera': camera, 'playArrow': playArrow,
    'pause': pause, 'volumeUp': volumeUp, 'volumeOff': volumeOff,
    'stop': stop, 'skipNext': skipNext, 'skipPrevious': skipPrevious,
    'fastForward': fastForward, 'fastRewind': fastRewind,
    'replay': replay, 'volumeDown': volumeDown, 'volumeMute': volumeMute,
    'mic': mic, 'micOff': micOff, 'videocam': videocam,
    'videocamOff': videocamOff, 'photoCamera': photoCamera,
    'movie': movie, 'musicNote': musicNote,

    // Device
    'batteryFull': batteryFull, 'wifi': wifi, 'bluetooth': bluetooth,
    'gpsFixed': gpsFixed, 'screenRotation': screenRotation,
    'brightness': brightness, 'flashOn': flashOn, 'flashOff': flashOff,

    // File
    'folder': folder, 'folderOpen': folderOpen, 'fileCopy': fileCopy,
    'createNewFolder': createNewFolder, 'cloud': cloud,
    'cloudUpload': cloudUpload, 'cloudDownload': cloudDownload,
    'cloudDone': cloudDone, 'attachment': attachment,
    'insertDriveFile': insertDriveFile, 'description': description,

    // Status / Alert
    'info': info, 'infoOutline': infoOutline, 'warning': warning,
    'warningAmber': warningAmber, 'error': error, 'errorOutline': errorOutline,
    'help': help, 'helpOutline': helpOutline, 'visibility': visibility,
    'visibilityOff': visibilityOff, 'lock': lock, 'lockOpen': lockOpen,
    'reportProblem': reportProblem, 'block': block,
    'doNotDisturb': doNotDisturb,

    // Maps / Places
    'place': place, 'map': map, 'myLocation': myLocation,
    'locationOn': locationOn, 'locationOff': locationOff,
    'directions': directions, 'navigation': navigation,

    // Fitness & Health
    'fitnessCenter': fitnessCenter, 'timer': timer,
    'directionsRun': directionsRun,
    'localFireDepartment': localFireDepartment, 'schedule': schedule,
    'trendingUp': trendingUp, 'emojiEvents': emojiEvents,
    'selfImprovement': selfImprovement, 'monitorHeart': monitorHeart,

    // Toggle
    'toggleOn': toggleOn, 'toggleOff': toggleOff,
    'checkBox': checkBox, 'checkBoxOutlineBlank': checkBoxOutlineBlank,
    'radioButtonChecked': radioButtonChecked,
    'radioButtonUnchecked': radioButtonUnchecked,
    'indeterminateCheckBox': indeterminateCheckBox, 'starHalf': starHalf,
  };

  /// Returns the codepoint for the given icon [name], or null if unknown.
  static int? lookup(String name) => _codepoints[name];
}
