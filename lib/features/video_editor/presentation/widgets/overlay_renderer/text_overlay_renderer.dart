import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RenderedOverlayResult {
  final File file;
  final int width;
  final int height;

  const RenderedOverlayResult({
    required this.file,
    required this.width,
    required this.height,
  });
}

class TextOverlayRenderer {
  static Future<RenderedOverlayResult> renderTextToPng({
    required String text,
    required double fontSize,
    required Color color,
    required double maxWidth,
    required double maxHeight,
    required String outputPath,
    double scale = 1.0,
    double opacity = 1.0,
  }) async {
    // 1. Calculate resolution scale factor based on 1080p reference width
    final double scaleFactor = maxWidth / 1080.0;
    
    // Scale font size by target output DPI and item-specific scale
    final double scaledFontSize = fontSize * scaleFactor * scale;

    // Apply opacity factor to color values
    final Color textColor = color.withOpacity(color.opacity * opacity);
    final Color bgColor = Colors.black.withOpacity(0.45 * opacity);
    final Color borderColor = Colors.white.withOpacity(0.24 * opacity);

    final double padHorizontal = 10.0 * scaleFactor * scale;
    final double padVertical = 6.0 * scaleFactor * scale;
    final double borderRadiusVal = 8.0 * scaleFactor * scale;
    final double borderWidthVal = 1.5 * scaleFactor * scale;
    final double shadowOffset = 1.0 * scaleFactor * scale;
    final double shadowBlur = 2.0 * scaleFactor * scale;

    // 2. Build text paragraph
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: scaledFontSize,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );

    builder.pushStyle(ui.TextStyle(
      color: textColor,
      shadows: [
        ui.Shadow(
          color: const Color(0xD7000000).withOpacity(0.84 * opacity),
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: shadowBlur,
        )
      ],
    ));
    builder.addText(text);
    builder.pop();

    final ui.Paragraph paragraph = builder.build();
    // Layout paragraph restricting it to maxWidth minus margins
    final double maxLayoutWidth = maxWidth - (20.0 * scaleFactor * scale * 2);
    paragraph.layout(ui.ParagraphConstraints(width: maxLayoutWidth));

    final double textWidth = paragraph.minIntrinsicWidth.clamp(20.0 * scaleFactor * scale, maxLayoutWidth);
    paragraph.layout(ui.ParagraphConstraints(width: textWidth));

    // Calculate container bounds including padding
    final double rectWidth = textWidth + (padHorizontal * 2.0);
    final double rectHeight = paragraph.height + (padVertical * 2.0);

    // 3. Paint to Canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, rectWidth, rectHeight),
      Radius.circular(borderRadiusVal),
    );

    // Draw container background
    final Paint bgPaint = Paint()
      ..color = bgColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Draw container border
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidthVal;
    canvas.drawRRect(rrect, borderPaint);

    // Draw paragraph centered in the padded bounds
    canvas.drawParagraph(paragraph, Offset(padHorizontal, padVertical));

    // 4. Compile picture and save as PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(rectWidth.toInt(), rectHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to serialize text overlay to PNG');
    }

    final File file = File(outputPath);
    await file.writeAsBytes(byteData.buffer.asUint8List());
    
    return RenderedOverlayResult(
      file: file,
      width: rectWidth.toInt(),
      height: rectHeight.toInt(),
    );
  }
}
