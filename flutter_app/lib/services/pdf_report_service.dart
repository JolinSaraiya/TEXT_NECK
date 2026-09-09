import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../posture/neck_angle_calculator.dart';
import 'posture_history_manager.dart';

/// Clinical PDF Report Service
/// Generates and exports formatted medical posture assessment reports.
class PdfReportService {
  PdfReportService._();
  static final PdfReportService instance = PdfReportService._();

  /// Generates and opens the print/export dialog for the clinical posture report.
  Future<void> exportPostureReport({
    required double angle,
    required RiskLevel riskLevel,
    String? patientName,
    List<PostureSessionResult>? history,
  }) async {
    final pdf = pw.Document();

    final sessions = history ?? PostureHistoryManager().history;
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // Color mapping for PDF
    PdfColor riskColor;
    String riskCategory;
    switch (riskLevel) {
      case RiskLevel.good:
        riskColor = PdfColors.green700;
        riskCategory = "Optimal Alignment (Low Risk)";
        break;
      case RiskLevel.warning:
        riskColor = PdfColors.amber700;
        riskCategory = "Mild Forward Head Posture (Moderate Risk)";
        break;
      case RiskLevel.critical:
        riskColor = PdfColors.red700;
        riskCategory = "Severe Text Neck Syndrome (Critical Risk)";
        break;
    }

    // Cervical load estimate based on Kapandji spine biomechanics
    String cervicalLoad;
    if (angle >= 48.0) {
      cervicalLoad = "~10 - 12 lbs (Normal physiological weight of human head)";
    } else if (angle >= 43.0) {
      cervicalLoad = "~27 - 35 lbs (2.5x increase in cervical spine tension)";
    } else {
      cervicalLoad = "~45 - 60 lbs (Up to 5x compressive stress on C5-C7 vertebrae)";
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(dateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildPatientInfo(patientName ?? "Patient / User", dateStr),
          pw.SizedBox(height: 20),
          _buildScoreCard(angle, riskLevel, riskColor, riskCategory, cervicalLoad),
          pw.SizedBox(height: 24),
          _buildClinicalReferenceTable(),
          pw.SizedBox(height: 24),
          _buildHistoryTable(sessions),
          pw.SizedBox(height: 24),
          _buildPrescribedExercises(riskLevel),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: "TextNeck_Clinical_Report_${now.millisecondsSinceEpoch}.pdf",
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildHeader(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "TEXT NECK AI CLINICAL ASSESSMENT",
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                "AI Biomechanical Posture & Craniovertebral Angle (CVA) Evaluation",
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            "Report Date: $dateStr",
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Medical Disclaimer: Diagnostic aid for ergonomic tracking. Consult a licensed physical therapist for clinical pathology.",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            "Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPatientInfo(String name, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("Subject / User: $name", style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text("Evaluation Method: Computer Vision CVA Analysis", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
      ),
    );
  }

  pw.Widget _buildScoreCard(
    double angle,
    RiskLevel riskLevel,
    PdfColor riskColor,
    String riskCategory,
    String cervicalLoad,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: riskColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "CRANIOVERTEBRAL ANGLE (CVA)",
                style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: riskColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  riskLevel.label.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "${angle.toStringAsFixed(1)}°",
                style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: riskColor),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Text(
                  riskCategory,
                  style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            "Estimated Cervical Load: $cervicalLoad",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClinicalReferenceTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Clinical Reference Standards", style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell("Angle Range", isHeader: true),
                _tableCell("Clinical Classification", isHeader: true),
                _tableCell("Biomechanical Implication", isHeader: true),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell("> 48.0°"),
                _tableCell("Good / Normal Alignment"),
                _tableCell("Cervical spine curvature maintains normal lordosis. Head weight evenly distributed."),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell("43.0° - 48.0°"),
                _tableCell("Mild Forward Head Posture"),
                _tableCell("Suboccipital extensor muscles under early strain. Upper thoracic rounding initiated."),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell("< 43.0°"),
                _tableCell("Severe Text Neck / FHP"),
                _tableCell("Heavy compressive disc stress on C5-C7. High correlation with chronic cervicogenic headaches."),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildHistoryTable(List<PostureSessionResult> sessions) {
    final recent = sessions.take(5).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Recent Session Telemetry (${recent.length} recorded)", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (recent.isEmpty)
          pw.Text("No previous sessions recorded.", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell("Timestamp", isHeader: true),
                  _tableCell("CVA Angle", isHeader: true),
                  _tableCell("Risk Tier", isHeader: true),
                  _tableCell("Frames Evaluated", isHeader: true),
                ],
              ),
              ...recent.map((s) {
                final date = "${s.timestamp.month}/${s.timestamp.day} ${s.timestamp.hour}:${s.timestamp.minute.toString().padLeft(2, '0')}";
                return pw.TableRow(
                  children: [
                    _tableCell(date),
                    _tableCell("${s.angle.toStringAsFixed(1)}°"),
                    _tableCell(s.riskLevel.label),
                    _tableCell("${s.frameCount} frames"),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildPrescribedExercises(RiskLevel riskLevel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Prescribed Ergonomic Exercises & Stretches", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        _exerciseRow("Chin Tucks (Deep Cervical Flexor Retraining)", "Gently pull head straight back creating a double chin. Hold 5 sec, 10 reps. Strengthens deep neck flexors."),
        _exerciseRow("Upper Trapezius & Levator Scapulae Stretch", "Tilt ear towards opposite shoulder; use hand for gentle overpressure. Hold 20 sec per side."),
        _exerciseRow("Doorway Pec & Chest Opening Stretch", "Place forearms against doorframe and step forward until chest stretches. Counteracts forward-slumped shoulders."),
      ],
    );
  }

  pw.Widget _exerciseRow(String name, String desc) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 6,
            height: 6,
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            decoration: const pw.BoxDecoration(color: PdfColors.blue700, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(desc, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
