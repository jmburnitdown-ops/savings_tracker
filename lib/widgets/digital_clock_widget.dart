import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalClockWidget extends StatefulWidget {
  final Color textColor;
  final double fontSize;
  
  const DigitalClockWidget({super.key, this.textColor = Colors.redAccent, this.fontSize = 14});

  @override
  State<DigitalClockWidget> createState() => _DigitalClockWidgetState();
}

class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  late Timer _timer;
  String _formattedDateTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final String formatted = DateFormat('MMMM d, yyyy • h:mm:ss a').format(DateTime.now());
    if (mounted) setState(() => _formattedDateTime = formatted);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_formattedDateTime, style: TextStyle(color: widget.textColor, fontSize: widget.fontSize, fontWeight: FontWeight.w500));
  }
}