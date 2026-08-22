import 'package:flutter_tts/flutter_tts.dart';
import '../models/scan_result.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    try {
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((_) {
        _isSpeaking = false;
      });
    } catch (_) {}
  }

  Future<void> speakAuditSummary(ScanResult result) async {
    try {
      if (_isSpeaking) {
        await stop();
        return;
      }

      final buffer = StringBuffer();
      buffer.write("LabelTruth Compliance Audit for ${result.productName}. ");
      buffer.write("The product received a Truth Score of ${result.truthScore} out of 100, ");
      buffer.write("with a verdict of: ${result.verdict}. ");

      if (result.violations.isNotEmpty) {
        buffer.write("We detected ${result.violations.length} statutory violations under FSSAI regulations. ");
        for (var v in result.violations.take(2)) {
          buffer.write("${v.title}. ${v.auditFinding}. ");
        }
      } else {
        buffer.write("No major statutory labeling violations were found. ");
      }

      if (result.dietaryWarnings.isNotEmpty) {
        buffer.write("Dietary warning: ${result.dietaryWarnings.first}. ");
      }

      if (result.healthierAlternatives.isNotEmpty) {
        buffer.write("A recommended healthier alternative is ${result.healthierAlternatives.first.name} by ${result.healthierAlternatives.first.brand}.");
      }

      _isSpeaking = true;
      await _flutterTts.speak(buffer.toString());
    } catch (_) {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }
}

final ttsService = TtsService();
