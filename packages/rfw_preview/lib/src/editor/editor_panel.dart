import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor_theme.dart';
import 'rfw_editor_controller.dart';

/// A [TextEditingController] that applies rfwtxt syntax highlighting
/// by building a [TextSpan] tree with colored segments.
class RfwtxtEditingController extends TextEditingController {
  RfwtxtEditingController({super.text});

  /// Whether to use dark theme colors.
  bool isDark = true;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = _highlight(text, isDark);
    return TextSpan(style: style, children: spans);
  }

  static List<TextSpan> _highlight(String source, bool isDark) {
    final spans = <TextSpan>[];
    final length = source.length;
    var i = 0;

    Color kw, wn, str, num, cmt, prop, plain;
    if (isDark) {
      kw = SyntaxColors.keyword;
      wn = SyntaxColors.widgetName;
      str = SyntaxColors.string;
      num = SyntaxColors.number;
      cmt = SyntaxColors.comment;
      prop = SyntaxColors.property;
      plain = SyntaxColors.plain;
    } else {
      kw = SyntaxColors.lightKeyword;
      wn = SyntaxColors.lightWidgetName;
      str = SyntaxColors.lightString;
      num = SyntaxColors.lightNumber;
      cmt = SyntaxColors.lightComment;
      prop = SyntaxColors.lightProperty;
      plain = SyntaxColors.lightPlain;
    }

    void addSpan(String text, Color color) {
      spans.add(TextSpan(text: text, style: TextStyle(color: color)));
    }

    while (i < length) {
      // Line comment
      if (i + 1 < length && source[i] == '/' && source[i + 1] == '/') {
        final end = source.indexOf('\n', i);
        final commentEnd = end == -1 ? length : end;
        addSpan(source.substring(i, commentEnd), cmt);
        i = commentEnd;
        continue;
      }

      // Block comment
      if (i + 1 < length && source[i] == '/' && source[i + 1] == '*') {
        final end = source.indexOf('*/', i + 2);
        final commentEnd = end == -1 ? length : end + 2;
        addSpan(source.substring(i, commentEnd), cmt);
        i = commentEnd;
        continue;
      }

      // String literal
      if (source[i] == '"') {
        final start = i;
        i++;
        while (i < length && source[i] != '"') {
          if (source[i] == '\\') i++; // skip escaped
          i++;
        }
        if (i < length) i++; // closing quote
        addSpan(source.substring(start, i), str);
        continue;
      }

      // Numbers (including hex)
      if (_isDigit(source[i]) ||
          (source[i] == '0' && i + 1 < length && source[i + 1] == 'x')) {
        final start = i;
        if (source[i] == '0' && i + 1 < length && source[i + 1] == 'x') {
          i += 2;
          while (i < length && _isHexDigit(source[i])) {
            i++;
          }
        } else {
          while (i < length && (_isDigit(source[i]) || source[i] == '.')) {
            i++;
          }
        }
        addSpan(source.substring(start, i), num);
        continue;
      }

      // Identifiers and keywords
      if (_isAlpha(source[i]) || source[i] == '_') {
        final start = i;
        while (i < length && (_isAlphaNumeric(source[i]) || source[i] == '.')) {
          i++;
        }
        final word = source.substring(start, i);
        if (_keywords.contains(word)) {
          addSpan(word, kw);
        } else if (_isWidgetName(word)) {
          addSpan(word, wn);
        } else if (i < length && source[i] == ':') {
          // property name followed by colon
          addSpan(word, prop);
        } else {
          addSpan(word, plain);
        }
        continue;
      }

      // Everything else
      addSpan(source[i], plain);
      i++;
    }

    return spans;
  }

  static const _keywords = {
    'import',
    'widget',
    'true',
    'false',
    'set',
    'event',
    'switch',
    'default',
    'state',
    'data',
    'args',
  };

  static bool _isWidgetName(String word) {
    if (word.isEmpty) return false;
    // Starts with uppercase and contains only alpha chars (no dots)
    return word[0] == word[0].toUpperCase() &&
        word[0] != word[0].toLowerCase() &&
        !word.contains('.');
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isHexDigit(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 70) ||
        (code >= 97 && code <= 102);
  }

  static bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  static bool _isAlphaNumeric(String c) =>
      _isAlpha(c) || _isDigit(c) || c == '_';
}

/// The code editor panel with line numbers, syntax highlighting,
/// cursor position display, and error reporting.
class EditorPanel extends StatefulWidget {
  const EditorPanel({
    super.key,
    required this.controller,
  });

  /// The editor controller managing all state.
  final RfwEditorController controller;

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  late final RfwtxtEditingController _textController;
  late final ScrollController _editorScroll;
  late final ScrollController _lineNumberScroll;
  Timer? _debounce;
  int _cursorLine = 1;
  int _cursorCol = 1;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _textController = RfwtxtEditingController(text: widget.controller.rfwtxt);
    _textController.isDark = widget.controller.isDarkTheme;
    _editorScroll = ScrollController();
    _lineNumberScroll = ScrollController();
    _editorScroll.addListener(_syncLineScroll);
    _textController.addListener(_onTextChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _editorScroll.removeListener(_syncLineScroll);
    _textController.removeListener(_onTextChanged);
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _editorScroll.dispose();
    _lineNumberScroll.dispose();
    super.dispose();
  }

  void _syncLineScroll() {
    if (_syncing) return;
    _syncing = true;
    if (_lineNumberScroll.hasClients) {
      _lineNumberScroll.jumpTo(_editorScroll.offset);
    }
    _syncing = false;
  }

  void _onControllerChanged() {
    _textController.isDark = widget.controller.isDarkTheme;
    // If the controller's rfwtxt changed externally (e.g., snippet load),
    // update the text controller.
    if (_textController.text != widget.controller.rfwtxt) {
      _textController.text = widget.controller.rfwtxt;
    }
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    _updateCursorPosition();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.controller.rfwtxt = _textController.text;
    });
  }

  void _updateCursorPosition() {
    final offset = _textController.selection.baseOffset;
    if (offset < 0) return;
    final text = _textController.text;
    final before = text.substring(0, offset.clamp(0, text.length));
    final lines = before.split('\n');
    if (mounted) {
      setState(() {
        _cursorLine = lines.length;
        _cursorCol = lines.last.length + 1;
      });
    }
  }

  void _onManualRender() {
    _debounce?.cancel();
    widget.controller.rfwtxt = _textController.text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkTheme;
    final bgColor = isDark ? EditorColors.darkBg : EditorColors.cardBg;
    final gutterColor =
        isDark ? EditorColors.darkSurface : EditorColors.sectionBg;
    final lineNumColor =
        isDark ? EditorColors.szsGray50 : EditorColors.szsGray50;
    final errorColor = EditorColors.szsRed50;

    final lineCount = '\n'.allMatches(_textController.text).length + 1;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Editor area with line numbers
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number gutter
                Container(
                  width: 48,
                  color: gutterColor,
                  child: ListView.builder(
                    controller: _lineNumberScroll,
                    itemCount: lineCount,
                    itemExtent: 20.0, // matches line height
                    padding: const EdgeInsets.only(top: 12),
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, i) {
                      final lineNum = i + 1;
                      final isError = widget.controller.errorLine == lineNum;
                      return SizedBox(
                        height: 20,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '$lineNum',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.0,
                                color: isError ? errorColor : lineNumColor,
                                fontWeight: isError
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Code editor
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      // Cmd+Enter manual render
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          HardwareKeyboard.instance.isMetaPressed) {
                        _onManualRender();
                      }
                    },
                    child: TextField(
                      controller: _textController,
                      scrollController: _editorScroll,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 20.0 / 13.0, // 20px line height
                        color: isDark
                            ? SyntaxColors.plain
                            : SyntaxColors.lightPlain,
                      ),
                      cursorColor: EditorColors.szsBlue55,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        isCollapsed: true,
                      ),
                      onTap: _updateCursorPosition,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status bar
          Container(
            height: 28,
            color: gutterColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Ln $_cursorLine, Col $_cursorCol',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: isDark
                        ? EditorColors.szsGray50
                        : EditorColors.szsGray70,
                  ),
                ),
                const Spacer(),
                if (widget.controller.error != null) ...[
                  Icon(Icons.error_outline, size: 14, color: errorColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.controller.errorLine != null
                          ? 'Line ${widget.controller.errorLine}: ${widget.controller.error}'
                          : widget.controller.error!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: errorColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
