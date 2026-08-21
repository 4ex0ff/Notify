import 'package:flutter/material.dart';

enum InlineEditTrigger {
  singleTap, // Одиночный клик
  doubleTap, // Двойной клик
  longPress, // Долгое нажатие
  manual, // Только извне (например, по кнопке из контекстного меню)
}

class InlineEditText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final InlineEditTrigger trigger;
  final ValueChanged<String> onSubmitted;
  final bool enabled;

  const InlineEditText({
    super.key,
    required this.text,
    required this.onSubmitted,
    this.trigger = InlineEditTrigger.doubleTap,
    this.style,
    this.enabled = true,
  });

  @override
  State<InlineEditText> createState() => InlineEditTextState();
}

class InlineEditTextState extends State<InlineEditText> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant InlineEditText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isEditing) {
      _controller.text = widget.text;
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submit();
    }
  }

  void _submit() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);

    final trimmed = _controller.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.text) {
      widget.onSubmitted(trimmed);
    } else {
      _controller.text = widget.text;
    }
  }

  void startEditing() {
    if (!widget.enabled) return;
    setState(() => _isEditing = true);
    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: widget.style,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      );
    }

    return MouseRegion(
      child: GestureDetector(
        onTap: widget.trigger == InlineEditTrigger.singleTap
            ? startEditing
            : null,
        onDoubleTap: widget.trigger == InlineEditTrigger.doubleTap
            ? startEditing
            : null,
        onLongPress: widget.trigger == InlineEditTrigger.longPress
            ? startEditing
            : null,
        child: Text(
          widget.text,
          style: widget.style,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
