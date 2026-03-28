import 'package:rfw_gen/src/rfw_icons.dart';
import 'package:test/test.dart';

void main() {
  group('RfwIcon', () {
    /// All icon names that have a static const defined in RfwIcon.
    /// This list must stay in sync with the class.
    final allIconNames = <String>[
      // Navigation
      'home', 'menu', 'arrowBack', 'arrowForward', 'arrowUpward',
      'arrowDownward', 'close', 'chevronLeft', 'chevronRight',
      'expandMore', 'expandLess', 'moreVert', 'moreHoriz',
      'arrowBackIos', 'arrowForwardIos',
      'firstPage', 'lastPage', 'navigateBefore', 'navigateNext',
      'subdirectoryArrowLeft', 'fullscreen', 'fullscreenExit',

      // Action
      'search', 'settings', 'delete', 'add', 'remove', 'edit', 'check',
      'refresh', 'done', 'save', 'copy', 'filterList', 'sort', 'clear',
      'download', 'upload', 'openInNew', 'checkCircle',
      'checkCircleOutline', 'doneAll', 'power', 'print', 'undo', 'redo',
      'zoomIn', 'zoomOut', 'login', 'logout',

      // Content
      'favorite', 'favoriteBorder', 'share', 'send', 'star', 'starBorder',
      'bookmark', 'bookmarkBorder', 'link', 'flag', 'addCircle',
      'addCircleOutline', 'removeCircle', 'removeCircleOutline',
      'contentCopy', 'contentPaste', 'contentCut', 'selectAll',

      // Communication
      'email', 'phone', 'chat', 'notifications', 'notificationsNone',
      'message', 'comment', 'forum', 'call', 'contactPhone', 'contactMail',
      'chatBubble', 'chatBubbleOutline', 'notificationsActive',
      'notificationsOff',

      // Social
      'person', 'personAdd', 'personOutline', 'group', 'groupAdd',
      'people', 'thumbUp', 'thumbDown', 'thumbUpOffAlt',
      'thumbDownOffAlt', 'public',

      // Media
      'image', 'camera', 'playArrow', 'pause', 'volumeUp', 'volumeOff',
      'stop', 'skipNext', 'skipPrevious', 'fastForward', 'fastRewind',
      'replay', 'volumeDown', 'volumeMute', 'mic', 'micOff', 'videocam',
      'videocamOff', 'photoCamera', 'movie', 'musicNote',

      // Device
      'batteryFull', 'wifi', 'bluetooth', 'gpsFixed', 'screenRotation',
      'brightness', 'flashOn', 'flashOff',

      // File
      'folder', 'folderOpen', 'fileCopy', 'createNewFolder', 'cloud',
      'cloudUpload', 'cloudDownload', 'cloudDone', 'attachment',
      'insertDriveFile', 'description',

      // Status / Alert
      'info', 'infoOutline', 'warning', 'warningAmber', 'error',
      'errorOutline', 'help', 'helpOutline', 'visibility', 'visibilityOff',
      'lock', 'lockOpen', 'reportProblem', 'block', 'doNotDisturb',

      // Maps / Places
      'place', 'map', 'myLocation', 'locationOn', 'locationOff',
      'directions', 'navigation',

      // Fitness & Health
      'fitnessCenter', 'timer', 'directionsRun', 'localFireDepartment',
      'schedule', 'trendingUp', 'emojiEvents', 'selfImprovement',
      'monitorHeart',

      // Toggle
      'toggleOn', 'toggleOff', 'checkBox', 'checkBoxOutlineBlank',
      'radioButtonChecked', 'radioButtonUnchecked',
      'indeterminateCheckBox', 'starHalf',
    ];

    test('lookup() returns non-null for every defined icon name', () {
      for (final name in allIconNames) {
        expect(
          RfwIcon.lookup(name),
          isNotNull,
          reason: 'RfwIcon.lookup("$name") should not be null',
        );
      }
    });

    test('previously missing icons are present in lookup', () {
      // These were missing from _codepoints map
      expect(RfwIcon.lookup('arrowBackIos'), isNotNull);
      expect(RfwIcon.lookup('arrowForwardIos'), isNotNull);
      expect(RfwIcon.lookup('subdirectoryArrowLeft'), isNotNull);
      expect(RfwIcon.lookup('power'), isNotNull);
    });

    test('known duplicate pairs have distinct codepoints', () {
      // arrowBackIos vs arrowForward
      expect(RfwIcon.arrowBackIos, isNot(equals(RfwIcon.arrowForward)),
          reason: 'arrowBackIos should differ from arrowForward');

      // arrowForwardIos vs arrowForward
      expect(RfwIcon.arrowForwardIos, isNot(equals(RfwIcon.arrowForward)),
          reason: 'arrowForwardIos should differ from arrowForward');

      // arrowBackIos vs arrowForwardIos
      expect(RfwIcon.arrowBackIos, isNot(equals(RfwIcon.arrowForwardIos)),
          reason: 'arrowBackIos should differ from arrowForwardIos');

      // stop vs starBorder
      expect(RfwIcon.stop, isNot(equals(RfwIcon.starBorder)),
          reason: 'stop should differ from starBorder');

      // locationOff vs image
      expect(RfwIcon.locationOff, isNot(equals(RfwIcon.image)),
          reason: 'locationOff should differ from image');

      // fileCopy vs flashOn
      expect(RfwIcon.fileCopy, isNot(equals(RfwIcon.flashOn)),
          reason: 'fileCopy should differ from flashOn');

      // chatBubbleOutline vs chevronLeft
      expect(RfwIcon.chatBubbleOutline, isNot(equals(RfwIcon.chevronLeft)),
          reason: 'chatBubbleOutline should differ from chevronLeft');
    });

    test('no unintentional duplicate codepoints in lookup map', () {
      // Intentional aliases: copy and contentCopy both map to 0xe190
      const intentionalAliases = {
        'copy',
        'contentCopy',
      };

      final codepointToNames = <int, List<String>>{};

      for (final name in allIconNames) {
        final codepoint = RfwIcon.lookup(name);
        if (codepoint == null) continue;
        codepointToNames.putIfAbsent(codepoint, () => []).add(name);
      }

      for (final entry in codepointToNames.entries) {
        if (entry.value.length > 1) {
          // Check if ALL names in this group are intentional aliases
          final isIntentional =
              entry.value.every((n) => intentionalAliases.contains(n));
          expect(
            isIntentional,
            isTrue,
            reason:
                'Codepoint 0x${entry.key.toRadixString(16)} is shared by '
                '${entry.value} — only $intentionalAliases may share a codepoint',
          );
        }
      }
    });

    test('typo subjectoryArrowLeft does not exist', () {
      // The old typo should be gone
      expect(RfwIcon.lookup('subjectoryArrowLeft'), isNull,
          reason: 'Typo "subjectoryArrowLeft" should not be in lookup');
    });
  });
}
