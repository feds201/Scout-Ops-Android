import 'dart:ui' as ui;

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

enum Alliance { blue, red }

class MultiPointSelector extends StatefulWidget {
  final String blueAllianceImagePath;
  final String redAllianceImagePath;
  final Alliance alliance;
  final List<List<Offset>>? initialStrokes;
  final void Function(List<List<Offset>> strokes)? onStrokesChanged;
  final void Function(bool isLocked)? onLockStateChanged;

  const MultiPointSelector({
    Key? key,
    required this.blueAllianceImagePath,
    required this.redAllianceImagePath,
    required this.alliance,
    this.initialStrokes,
    this.onStrokesChanged,
    this.onLockStateChanged,
  }) : super(key: key);

  @override
  State<MultiPointSelector> createState() => MultiPointSelectorState();
}

class MultiPointSelectorState extends State<MultiPointSelector> {
  List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialStrokes != null) {
      _strokes = List.from(widget.initialStrokes!);
    }
  }

  String get _currentImagePath => widget.alliance == Alliance.blue
      ? widget.blueAllianceImagePath
      : widget.redAllianceImagePath;

  Color get _allianceColor =>
      widget.alliance == Alliance.blue ? Colors.blue : Colors.red;

  @override
  void didUpdateWidget(covariant MultiPointSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alliance != widget.alliance) {
      setState(() {
        _strokes.clear();
        _currentStroke = null;
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _notifyChanged();
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _notifyChanged();
      });
    }
  }

  void _notifyChanged() {
    widget.onStrokesChanged?.call(_strokes);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Container(
                width: screenWidth,
                decoration: BoxDecoration(
                  color: islightmode()
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(255, 34, 34, 34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    color: const Color(0xBF254EEA),
                    child: GestureDetector(
                      onPanStart: _isLocked
                          ? null
                          : (details) {
                              setState(() {
                                _currentStroke = [details.localPosition];
                                _strokes.add(_currentStroke!);
                              });
                            },
                      onPanUpdate: _isLocked
                          ? null
                          : (details) {
                              setState(() {
                                _currentStroke?.add(details.localPosition);
                              });
                            },
                      onPanEnd: _isLocked
                          ? null
                          : (details) {
                              _currentStroke = null;
                              _notifyChanged();
                            },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              _currentImagePath,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _StrokesPainter(
                                  strokes: _strokes,
                                  color: _allianceColor,
                                ),
                              ),
                            ),
                            if (_isLocked)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.black.withOpacity(0.5),
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLocked = !_isLocked;
                      });
                      widget.onLockStateChanged?.call(_isLocked);
                    },
                    icon:
                        Icon(_isLocked ? Icons.lock_outline : Icons.lock_open),
                    label: Text(_isLocked ? "Unlock" : "Lock"),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          islightmode() ? Colors.black : Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _Undoable ? _undo : null,
                        icon: const Icon(Icons.undo),
                        label: const Text("Undo"),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              islightmode() ? Colors.black : Colors.white,
                          disabledForegroundColor: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _Clearable ? _clear : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Clear"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          disabledForegroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _Undoable => _strokes.isNotEmpty;

  bool get _Clearable => _strokes.isNotEmpty;
}

class _StrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;

  _StrokesPainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // If you wanted to scale points, you'd do it here or in the data layer.
    // Here we assume raw offsets relative to the widget size.
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
      } else {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.color != color;
  }
}
