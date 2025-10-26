import 'package:flutter/material.dart';
import 'dart:async';

/// 打字机效果文本组件
/// 逐行逐字显示文本内容，产生打字机效果
class TypewriterTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay; // 每个字符的延迟时间
  final Duration lineDelay; // 每行之间的延迟时间

  const TypewriterTextWidget({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 10),
    this.lineDelay = const Duration(milliseconds: 100),
  });

  @override
  State<TypewriterTextWidget> createState() => _TypewriterTextWidgetState();
}

class _TypewriterTextWidgetState extends State<TypewriterTextWidget> {
  String _displayedText = '';
  late List<String> _lines;
  int _currentLineIndex = 0;
  int _currentCharIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lines = widget.text.split('\n');
    _startAnimation();
  }

  @override
  void didUpdateWidget(TypewriterTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = '';
      _currentLineIndex = 0;
      _currentCharIndex = 0;
      _lines = widget.text.split('\n');
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer?.cancel();

    // 如果第一行有内容，先显示第一行
    if (_lines.isNotEmpty && _lines.first.isNotEmpty) {
      _animateNextChar();
    }
  }

  void _animateNextChar() {
    if (_currentLineIndex >= _lines.length) {
      // 所有行都已显示完
      return;
    }

    final currentLine = _lines[_currentLineIndex];

    if (_currentCharIndex < currentLine.length) {
      // 继续显示当前行的字符
      setState(() {
        _displayedText += currentLine[_currentCharIndex];
        _currentCharIndex++;
      });

      _timer = Timer(widget.charDelay, () {
        if (mounted) {
          _animateNextChar();
        }
      });
    } else {
      // 当前行显示完，准备显示下一行
      _currentLineIndex++;
      _currentCharIndex = 0;

      if (_currentLineIndex < _lines.length) {
        // 添加换行符并显示下一行
        _timer = Timer(widget.lineDelay, () {
          if (mounted) {
            setState(() {
              _displayedText += '\n';
            });
            _animateNextChar();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
  }
}
