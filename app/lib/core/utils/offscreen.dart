import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draws a widget off screen and returns PNG bytes. Used for PDF pages so Flutter's own text engine
/// shapes Hindi and Gujarati correctly (the pdf package cannot join Indic letters). No images inside:
/// the tree must lay out and paint in one pass.
Future<List<int>> renderWidgetToPng(Widget widget, {required Size size, double pixelRatio = 2}) async {
  final repaint = RenderRepaintBoundary();
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.center, child: repaint),
    configuration: ViewConfiguration(logicalConstraints: BoxConstraints.tight(size), devicePixelRatio: pixelRatio),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaint,
    child: MediaQuery(
      data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
      child: Directionality(textDirection: TextDirection.ltr, child: widget),
    ),
  ).attachToRenderTree(buildOwner);
  buildOwner.buildScope(root);
  buildOwner.finalizeTree();
  pipeline.flushLayout();
  pipeline.flushCompositingBits();
  pipeline.flushPaint();
  final image = await repaint.toImage(pixelRatio: pixelRatio);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
