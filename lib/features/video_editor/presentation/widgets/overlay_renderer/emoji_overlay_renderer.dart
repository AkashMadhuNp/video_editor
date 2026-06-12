import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class EmojiOverlayRenderer {
  static Future<File> renderEmojiToPng({
    required String emoji,
    required double size,
    required String outputPath,
  }) async {
    final double canvasSize = size * 1.5; // Padding for emoji overflow bounds
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: size,
        fontFamily: Platform.isIOS ? 'Apple Color Emoji' : 'Noto Color Emoji',
      ),
    );

    builder.addText(emoji);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: canvasSize));

    final double x = (canvasSize - paragraph.width) / 2;
    final double y = (canvasSize - paragraph.height) / 2;
    canvas.drawParagraph(paragraph, ui.Offset(x, y));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to serialize emoji canvas to PNG byte data');
    }

    final File file = File(outputPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }
}
