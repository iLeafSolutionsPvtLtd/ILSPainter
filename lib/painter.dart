library painter;

import 'dart:convert';

import 'package:flutter/widgets.dart' hide Image;
import 'package:json_annotation/json_annotation.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:typed_data';

part 'painter.g.dart';

class Painter extends StatefulWidget {
  final PainterController painterController;

  Painter(PainterController painterController)
      : this.painterController = painterController,
        super(key: new ValueKey<PainterController>(painterController));

  @override
  _PainterState createState() => new _PainterState();
}

class _PainterState extends State<Painter> {
  bool _eraseMode = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _finished = false;
    _eraseMode = false;
    widget.painterController._widgetFinish = _finish;
  }

  Size _finish() {
    setState(() {
      _finished = true;
    });
    return context.size!;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = new CustomPaint(
      willChange: true,
      painter: new _PainterPainter(widget.painterController._pathHistory,
          repaint: widget.painterController),
    );
    child = new ClipRect(child: child);
    if (!_finished) {
      child = new GestureDetector(
        child: child,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
      );
    }
    return new Container(
      child: child,
      width: double.infinity,
      height: double.infinity,
    );
  }

  void _onPanStart(DragStartDetails start) {
    Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(start.globalPosition);
    widget.painterController._pathHistory?.add(pos);
    widget.painterController._notifyListeners();
  }

  void _onPanUpdate(DragUpdateDetails update) {
    Offset pos = (context.findRenderObject() as RenderBox)
        .globalToLocal(update.globalPosition);
    try {
      widget.painterController._pathHistory!
          .updateCurrent(pos, widget.painterController.compressionLevel!);
    } catch (_) {}

    widget.painterController._notifyListeners();
  }

  void _onPanEnd(DragEndDetails end) {
    try {
      widget.painterController._pathHistory!._filterBlankHistory();
      widget.painterController._pathHistory!.endCurrent();
    } catch (_) {}

    widget.painterController._notifyListeners();
    widget.painterController._onDrawStepListener?.call();
    widget.painterController._onHistoryUpdatedListener?.call();
  }
}

class _PainterPainter extends CustomPainter {
  final _PathHistory? _path;

  _PainterPainter(this._path, {required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    _path?.draw(canvas, size);
  }

  @override
  bool shouldRepaint(_PainterPainter oldDelegate) {
    return true;
  }
}

@JsonSerializable()
class Point {
  double x;
  double y;

  Point(this.x, this.y);

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
  Map<String, dynamic> toJson() => _$PointToJson(this);
}

@JsonSerializable()
class PathHistoryEntry {
  double pathDx;
  double pathDy;

  List<Point> lineToList = [];

  int paintA;
  int paintR;
  int paintG;
  int paintB;
  int paintBlendMode;
  double paintThickness;

  PathHistoryEntry(this.pathDx, this.pathDy, this.paintA, this.paintR,
      this.paintG, this.paintB, this.paintBlendMode, this.paintThickness);

  factory PathHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$PathHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$PathHistoryEntryToJson(this);

  Paint extractPaint() {
    Paint paint = new Paint();
    paint.color = Color.fromARGB(paintA, paintR, paintG, paintB);
    paint.blendMode = BlendMode.values[paintBlendMode];
    paint.strokeWidth = paintThickness;
    paint.style = PaintingStyle.stroke;

    return paint;
  }

  Path extractPath() {
    Path path = new Path();
    path.moveTo(pathDx, pathDy);

    for (var point in lineToList) {
      path.lineTo(point.x, point.y);
    }
    return path;
  }

  MapEntry<Path, Paint> convertToPathHistoryFormat() {
    return MapEntry(extractPath(), extractPaint());
  }
}

class _PathHistory {
  List<PathHistoryEntry> redoPath = [];
  List<PathHistoryEntry>? _paths;
  Paint? currentPaint;
  Paint? _backgroundPaint;
  bool? _inDrag;
  Function? _onDrawStepListener;

  int historySize() {
    return _paths!.length;
  }

  void _filterBlankHistory() {
    List<PathHistoryEntry> result = [];
    for (var path in _paths!) {
      if (path.lineToList.isNotEmpty) {
        Point initialPoint = path.lineToList.first;
        for (var point in path.lineToList) {
          if (point.x != initialPoint.x || point.y != initialPoint.y) {
            result.add(path);
            break;
          }
        }
      } else {
        continue;
      }
    }
    _paths = result;
  }

  _PathHistory(List<PathHistoryEntry>? paths) {
    if (paths != null) {
      _paths = paths;
    } else {
      _paths = <PathHistoryEntry>[];
    }
    _inDrag = false;
    _backgroundPaint = new Paint();
  }

  void setOnDrawStepListener(Function onDrawListener) {
    _onDrawStepListener = onDrawListener;
  }

  void setBackgroundColor(Color backgroundColor) {
    _backgroundPaint!.color = backgroundColor;
  }

  void undo() {
    if (!_inDrag!) {
      if (_paths!.isNotEmpty) {
        redoPath.add(_paths!.last);
        _paths?.removeLast();
      }
    }
  }

  void redo() {
    _paths!.add(redoPath.last);
    redoPath.removeLast();
  }

  void clear() {
    if (!_inDrag!) {
      _paths!.clear();
    }
  }

  void add(Offset startPoint) {
    if (!_inDrag!) {
      _inDrag = true;
      Path path = new Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      PathHistoryEntry pathHistoryEntry = new PathHistoryEntry(
          startPoint.dx,
          startPoint.dy,
          currentPaint!.color.alpha,
          currentPaint!.color.red,
          currentPaint!.color.green,
          currentPaint!.color.blue,
          currentPaint!.blendMode.index,
          currentPaint!.strokeWidth);
      _paths?.add(pathHistoryEntry);
    }
  }

  void updateCurrent(Offset nextPoint, int compressionLevel) {
    if (_inDrag!) {
      if (_paths!.last.lineToList.isNotEmpty) {
        Offset prevOffset = Offset(
            _paths!.last.lineToList.last.x, _paths!.last.lineToList.last.y);
        if ((prevOffset - nextPoint).distance >
            _paths!.last.paintThickness / compressionLevel) {
          Path path = _paths!.last.extractPath();
          path.lineTo(nextPoint.dx, nextPoint.dy);
          _paths!.last.lineToList.add(Point(nextPoint.dx, nextPoint.dy));
        }
      } else {
        Path path = _paths!.last.extractPath();
        path.lineTo(nextPoint.dx, nextPoint.dy);
        _paths!.last.lineToList.add(Point(nextPoint.dx, nextPoint.dy));
      }
    }
  }

  void endCurrent() {
    _inDrag = false;
  }

  void draw(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(new Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        _backgroundPaint!);
    for (PathHistoryEntry path in _paths!) {
      MapEntry<Path, Paint> oldModel = path.convertToPathHistoryFormat();
      canvas.drawPath(oldModel.key, oldModel.value);
    }
    canvas.restore();
  }
}

typedef PictureDetails PictureCallback();

class PictureDetails {
  final Picture picture;
  final int width;
  final int height;

  const PictureDetails(this.picture, this.width, this.height);

  Future<Image> toImage() {
    return picture.toImage(width, height);
  }

  Future<Uint8List> toPNG() async {
    final image = await toImage();
    return (await image.toByteData(format: ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
}

class PainterController extends ChangeNotifier {
  Color _drawColor = new Color.fromARGB(255, 0, 0, 0);
  Color _backgroundColor = new Color.fromARGB(255, 255, 255, 255);
  bool _eraseMode = false;
  int? compressionLevel = 4;

  double _thickness = 1.0;
  PictureDetails? _cached;
  _PathHistory? _pathHistory;
  ValueGetter<Size>? _widgetFinish;
  Function? _onDrawStepListener;
  Function? _onHistoryUpdatedListener;

  PainterController({String? history, this.compressionLevel}) {
    if (history != null) _setHistory(history);
  }

  String get history {
    return _serializeHistory();
  }

  void _setHistory(String history) {
    _pathHistory = new _PathHistory(_derializeHistory(history));
  }

  String _serializeHistory() {
    return jsonEncode(_pathHistory?._paths);
  }

  List<PathHistoryEntry>? _derializeHistory(String serializedHistory) {
    if (serializedHistory != '') {
      return (jsonDecode(serializedHistory) as List)
          .map((entry) => PathHistoryEntry.fromJson(entry))
          .toList();
    } else {
      return null;
    }
  }

  void setOnDrawStepListener(Function onDrawStepListener) {
    this._onDrawStepListener = onDrawStepListener;
  }

  void setOnHistoryUpdatedListener(Function onHistoryUpdatedListener) {
    this._onHistoryUpdatedListener = onHistoryUpdatedListener;
  }

  bool hasHistory() {
    return _pathHistory?.historySize() != 0;
  }

  // setter for erase mode.
  // Note: Works only for transparent background
  bool get eraseMode => _eraseMode;
  set eraseMode(bool enabled) {
    _eraseMode = enabled;
    _updatePaint();
  }

  Color get drawColor => _drawColor;
  set drawColor(Color color) {
    _drawColor = color;
    _updatePaint();
  }

  Color get backgroundColor => _backgroundColor;
  set backgroundColor(Color color) {
    _backgroundColor = color;
    _updatePaint();
  }

  double get thickness => _thickness;
  set thickness(double t) {
    _thickness = t;
    _updatePaint();
  }

  void _updatePaint() {
    Paint paint = new Paint();
    if (_eraseMode) {
      paint.color = Color.fromARGB(0, 255, 0, 0);
      paint.blendMode = BlendMode.clear;
    } else {
      paint.color = drawColor;
    }
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = thickness;
    _pathHistory?.currentPaint = paint;
    _pathHistory?.setBackgroundColor(backgroundColor);
    notifyListeners();
  }

  void undo() {
    if (!isFinished()) {
      _pathHistory!.undo();
      notifyListeners();
    }
  }

  void redo() {
    if (!isFinished()) {
      _pathHistory!.redo();
      notifyListeners();
    }
  }

  void _notifyListeners() {
    notifyListeners();
  }

  void clear() {
    if (!isFinished()) {
      _pathHistory!.clear();
      notifyListeners();
    }
  }

  PictureDetails? finish() {
    if (!isFinished()) {
      _cached = _render(_widgetFinish!());
    }
    return _cached;
  }

  PictureDetails _render(Size size) {
    PictureRecorder recorder = new PictureRecorder();
    Canvas canvas = new Canvas(recorder);
    _pathHistory!.draw(canvas, size);
    return new PictureDetails(
        recorder.endRecording(), size.width.floor(), size.height.floor());
  }

  bool isFinished() {
    return _cached != null;
  }
}
