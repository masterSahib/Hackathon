import io
import os
import base64
from datetime import datetime
from typing import Dict, Any, List
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    HRFlowable,
    KeepTogether,
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch

class PDFReportService:
    """Generates official, print-ready statutory violation notices for FSSAI / Consumer Forum complaints."""

    def generate_violation_notice(self, report_data: Dict[str, Any]) -> bytes:
        """Generates PDF bytes for the food packaging compliance audit notice."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36,
        )

        styles = getSampleStyleSheet()
        
        # Custom styles
        title_style = ParagraphStyle(
            'HeaderTitle',
            parent=styles['Heading1'],
            fontName='Helvetica-Bold',
            fontSize=16,
            leading=20,
            textColor=colors.HexColor('#0F172A'),
            alignment=1,
        )
        subtitle_style = ParagraphStyle(
            'HeaderSubtitle',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=10,
            leading=13,
            textColor=colors.HexColor('#DC2626'),
            alignment=1,
        )
        section_style = ParagraphStyle(
            'SectionHeader',
            parent=styles['Heading2'],
            fontName='Helvetica-Bold',
            fontSize=12,
            leading=15,
            textColor=colors.HexColor('#1E293B'),
            spaceBefore=10,
            spaceAfter=4,
        )
        body_style = ParagraphStyle(
            'ReportBody',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=9,
            leading=12,
            textColor=colors.HexColor('#334155'),
        )
        bold_body = ParagraphStyle(
            'ReportBodyBold',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=9,
            leading=12,
            textColor=colors.HexColor('#0F172A'),
        )
        table_cell = ParagraphStyle(
            'TableCell',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=8,
            leading=11,
            textColor=colors.HexColor('#1E293B'),
        )
        table_cell_bold = ParagraphStyle(
            'TableCellBold',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=8,
            leading=11,
            textColor=colors.HexColor('#0F172A'),
        )

        elements = []

        # 1. Header Banner
        elements.append(Paragraph("NATIONAL FOOD SAFETY & CONSUMER COMPLIANCE AUDIT", title_style))
        elements.append(Spacer(1, 4))
        elements.append(Paragraph("FORMAL STATUTORY NOTICE OF MISLEADING PACKAGING & REGULATORY VIOLATIONS", subtitle_style))
        elements.append(Paragraph("<font size=8 color='#64748B'>Issued pursuant to FSSAI Act 2006 (Sec 23/24), Legal Metrology Act 2009 (Sec 18 / LMPC Rules 2011), & Consumer Protection Act 2019</font>", ParagraphStyle('sub', alignment=1, spaceAfter=8)))
        elements.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#0F172A'), spaceAfter=10))

        # 2. Product Meta & Truth Score Card Table
        product_name = report_data.get("product_name", "Packaged Product")
        brand_name = report_data.get("brand_name", "Unknown Brand")
        barcode = report_data.get("barcode") or "N/A (Visual Scan)"
        truth_score = report_data.get("truth_score", 0)
        verdict = report_data.get("verdict", "Violates Standards")
        now_str = datetime.utcnow().strftime("%d %B %Y, %H:%M UTC")

        # Color choice based on score
        score_color = "#16A34A" if truth_score >= 80 else ("#D97706" if truth_score >= 50 else "#DC2626")

        meta_data = [
            [
                Paragraph(f"<b>Product:</b> {product_name}", body_style),
                Paragraph(f"<b>Brand / Manufacturer:</b> {brand_name}", body_style),
            ],
            [
                Paragraph(f"<b>Barcode / SKU:</b> {barcode}", body_style),
                Paragraph(f"<b>Audit Timestamp:</b> {now_str}", body_style),
            ],
            [
                Paragraph(f"<b>Truth Score:</b> <font color='{score_color}' size=12><b>{truth_score} / 100</b></font>", body_style),
                Paragraph(f"<b>Compliance Verdict:</b> <font color='{score_color}'><b>{verdict.upper()}</b></font>", body_style),
            ]
        ]
        t_meta = Table(meta_data, colWidths=[270, 270])
        t_meta.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#F8FAFC')),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
            ('PADDING', (0, 0), (-1, -1), 6),
        ]))
        elements.append(t_meta)
        elements.append(Spacer(1, 10))

        # 3. Section: Claim vs. Reality Audit
        elements.append(Paragraph("1. Front-of-Pack Marketing Claims vs. Back Panel Reality", section_style))
        comparisons = report_data.get("claim_comparisons", [])
        
        if comparisons:
            comp_table_data = [[
                Paragraph("<b>Front Marketing Claim</b>", table_cell_bold),
                Paragraph("<b>Lab & Ingredient Audit Finding</b>", table_cell_bold),
                Paragraph("<b>Status</b>", table_cell_bold),
            ]]
            for c in comparisons:
                status_text = c.get("status", "violation").upper()
                c_color = "#DC2626" if status_text == "VIOLATION" else ("#D97706" if status_text == "MISLEADING" else "#16A34A")
                comp_table_data.append([
                    Paragraph(f"\"{c.get('front_claim', '')}\"", table_cell),
                    Paragraph(f"{c.get('reality_finding', '')}<br/><font color='#64748B'><i>{c.get('explanation', '')}</i></font>", table_cell),
                    Paragraph(f"<font color='{c_color}'><b>{status_text}</b></font>", table_cell_bold),
                ])
            t_comp = Table(comp_table_data, colWidths=[160, 310, 70])
            t_comp.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E2E8F0')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 5),
            ]))
            elements.append(t_comp)
        else:
            elements.append(Paragraph("<i>No deceptive marketing claims detected on the evaluated package.</i>", body_style))

        elements.append(Spacer(1, 10))

        # 4. Section: Specific Statutory Regulatory Violations
        elements.append(Paragraph("2. Statutory Non-Compliance & Regulatory Violations", section_style))
        violations = report_data.get("violations", [])
        if violations:
            viol_table_data = [[
                Paragraph("<b>Regulation Code</b>", table_cell_bold),
                Paragraph("<b>Statutory Reference</b>", table_cell_bold),
                Paragraph("<b>Severity</b>", table_cell_bold),
                Paragraph("<b>Audit Finding & Legal Defect</b>", table_cell_bold),
            ]]
            for v in violations:
                sev = v.get("severity", "Medium")
                s_color = "#DC2626" if sev == "Critical" else ("#EA580C" if sev == "High" else "#D97706")
                viol_table_data.append([
                    Paragraph(f"<b>{v.get('rule_code', '')}</b>", table_cell_bold),
                    Paragraph(v.get('regulation_reference', ''), table_cell),
                    Paragraph(f"<font color='{s_color}'><b>{sev.upper()}</b></font>", table_cell_bold),
                    Paragraph(f"<b>{v.get('title', '')}</b><br/>{v.get('audit_finding', '')}", table_cell),
                ])
            t_viol = Table(viol_table_data, colWidths=[120, 140, 60, 220])
            t_viol.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FEE2E2')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#FCA5A5')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#FECACA')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 5),
            ]))
            elements.append(t_viol)
        else:
            elements.append(Paragraph("<i>Zero statutory violations identified against standard FSSAI thresholds.</i>", body_style))

        elements.append(Spacer(1, 10))

        # 5. Section: Harmful Chemical Additives & Hidden Substances
        additives = report_data.get("suspicious_additives", [])
        if additives:
            elements.append(Paragraph("3. High-Risk Additives, E-Numbers & Chemical Agents", section_style))
            add_data = [[
                Paragraph("<b>Additive / Code</b>", table_cell_bold),
                Paragraph("<b>Classification</b>", table_cell_bold),
                Paragraph("<b>Health & Regulatory Concern</b>", table_cell_bold),
            ]]
            for a in additives:
                add_data.append([
                    Paragraph(f"<b>{a.get('name', '')}</b> ({a.get('code') or 'E-Additive'})", table_cell),
                    Paragraph(a.get('category', 'Additive'), table_cell),
                    Paragraph(a.get('concern', ''), table_cell),
                ])
            t_add = Table(add_data, colWidths=[160, 130, 250])
            t_add.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FEF3C7')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#FDE68A')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#FDE68A')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(t_add)
            elements.append(Spacer(1, 10))

        # 6. Formal Consumer Forum / Regulatory Grievance Filing Block
        legal_block = [
            Paragraph("<b>4. STATUTORY DECLARATION & FORMAL GRIEVANCE SUBMISSION</b>", section_style),
            Paragraph(
                "This audit report constitutes empirical documentary evidence of statutory non-compliance under "
                "<b>Section 23 & 24 of the Food Safety and Standards Act, 2006</b>, "
                "<b>The Legal Metrology (Packaged Commodities) Rules, 2011 (Rule 6)</b>, and the "
                "<b>Consumer Protection Act, 2019</b>. "
                "The audited packaging contains deceptive claims and misleading representations intended to mislead reasonable consumers regarding true ingredient composition and nutritional thresholds.",
                body_style
            ),
            Spacer(1, 6),
            Paragraph(f"<b>Complainant / Auditor:</b> {report_data.get('complainant_name', 'Authorized Consumer Advocate')}", bold_body),
            Paragraph("<b>Target Statutory Authorities:</b> Central Consumer Protection Authority (CCPA) / Department of Consumer Affairs (National Consumer Helpline) / FSSAI FOSCOS Enforcement Directorate", body_style),
            Spacer(1, 10),
            Paragraph("<b>Verification Signature / Digital Timestamp:</b>", body_style),
            Paragraph("_____________________________________________ <br/><font size=7 color='#64748B'>Certified via LabelTruth AI Cryptographic Verification Engine</font>", body_style)
        ]
        elements.append(KeepTogether(legal_block))

        # Build PDF
        doc.build(elements)
        pdf_bytes = buffer.getvalue()
        buffer.close()
        return pdf_bytes

    def generate_base64_pdf(self, report_data: Dict[str, Any]) -> str:
        """Generates PDF and returns as base64 string."""
        pdf_bytes = self.generate_violation_notice(report_data)
        return base64.b64encode(pdf_bytes).decode("utf-8")

pdf_service = PDFReportService()
