import 'package:flutter/material.dart';

enum Alliance { blue, red }

class FieldHeatmapWidget extends StatefulWidget {
  final String blueAllianceImagePath;
  final String redAllianceImagePath;
  final Alliance alliance;
  final ValueChanged<int>? onPointsChanged;
  final VoidCallback? onClear;

  const FieldHeatmapWidget({
    Key? key,
    required this.blueAllianceImagePath,
    required this.redAllianceImagePath,
    required this.alliance,
    this.onPointsChanged,
    this.onClear,
  }) : super(key: key);

  @override
  State<FieldHeatmapWidget> createState() => FieldHeatmapWidgetState();
}

class FieldHeatmapWidgetState extends State<FieldHeatmapWidget> {
  // A list of "strokes", where each stroke is a list of points
  List<List<Offset>> _strokes = [];

  String get _currentImagePath =>
      widget.alliance == Alliance.blue ? widget.blueAllianceImagePath : widget.redAllianceImagePath;

  Color get _allianceColor => widget.alliance == Alliance.blue ? Colors.blue : Colors.red;

  void clearHeatmap() {
    setState(() => _strokes.clear());
    widget.onClear?.call();
    widget.onPointsChanged?.call(0);
  }

  void undoLast() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
      widget.onPointsChanged?.call(_strokes.length);
    }
  }

  @override
  void didUpdateWidget(FieldHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alliance != widget.alliance) {
      _strokes.clear();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _buildFieldCanvas(), // This points to the logic below
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildFieldCanvas() {
    return AspectRatio(
      aspectRatio: 1.8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Capture the single tap immediately
            onTapDown: (details) {
              setState(() {
                _strokes.add([details.localPosition]);
              });
              widget.onPointsChanged?.call(_strokes.length);
            },
            onPanStart: (details) {
              setState(() {
                _strokes.add([details.localPosition]);
              });
            },
            onPanUpdate: (details) {
              // BOUNDARY CHECK: Only add points if they are inside the image area
              if (details.localPosition.dx >= 0 &&
                  details.localPosition.dx <= constraints.maxWidth &&
                  details.localPosition.dy >= 0 &&
                  details.localPosition.dy <= constraints.maxHeight) {
                setState(() {
                  if (_strokes.isNotEmpty) {
                    _strokes.last.add(details.localPosition);
                  }
                });
              }
            },
            onPanEnd: (_) => widget.onPointsChanged?.call(_strokes.length),
            child: ClipRect( // Prevents drawing from "bleeding" over other UI
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _currentImagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: WhiteboardPainter(
                          strokes: _strokes,
                          strokeColor: _allianceColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: undoLast,
            icon: const Icon(Icons.undo, color: Colors.white),
            tooltip: 'Undo',
          ),
          ElevatedButton.icon(
            onPressed: clearHeatmap,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
          Text(
            "Strokes: ${_strokes.length}",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  WhiteboardPainter({required this.strokes, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 13.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      if (stroke.length == 1) {
        // If it's just a single tap, draw a small dot
        canvas.drawCircle(stroke.first, 9.0, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke; // Reset for lines
      } else {
        // Draw a continuous line
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) => true;
}