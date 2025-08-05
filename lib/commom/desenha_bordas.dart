import 'package:flutter/material.dart';

class BordaColoridaPainter extends CustomPainter {
  final String bordaesq;
  final String bordadir;
  final String bordafre;
  final String bordatra;

  BordaColoridaPainter({
    required this.bordaesq,
    required this.bordadir,
    required this.bordafre,
    required this.bordatra,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Borda esquerda
    borderPaint.color = bordaesq == '1' ? Colors.red : Colors.black;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), borderPaint);

    // Borda superior
    borderPaint.color = bordafre == '1' ? Colors.red : Colors.black;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), borderPaint);

    // Borda direita
    borderPaint.color = bordadir == '1' ? Colors.red : Colors.black;
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      borderPaint,
    );

    // Borda inferior
    borderPaint.color = bordatra == '1' ? Colors.red : Colors.black;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      borderPaint,
    );

    // Adicione drawLine ou outras formas para as outras bordas, se necessário
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
