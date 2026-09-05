import io
import os
import csv
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
    """Generates official statutory violation notices and editable CSV audit reports under Legal Metrology & FSSAI rules."""

    def generate_violation_notice(self, report_data: Dict[str, Any]) -> bytes:
        """Generates PDF bytes for the packaging compliance audit notice."""
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
            fontSize=15,
            leading=18,
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
            fontSize=11,
            leading=14,
            textColor=colors.HexColor('#1E293B'),
            spaceBefore=8,
            spaceAfter=4,
        )
        body_style = ParagraphStyle(
            'ReportBody',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=8.5,
            leading=11.5,
            textColor=colors.HexColor('#334155'),
        )
        bold_body = ParagraphStyle(
            'ReportBodyBold',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=8.5,
            leading=11.5,
            textColor=colors.HexColor('#0F172A'),
        )
        table_cell = ParagraphStyle(
            'TableCell',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=7.5,
            leading=10,
            textColor=colors.HexColor('#1E293B'),
        )
        table_cell_bold = ParagraphStyle(
            'TableCellBold',
            parent=styles['Normal'],
            fontName='Helvetica-Bold',
            fontSize=7.5,
            leading=10,
            textColor=colors.HexColor('#0F172A'),
        )

        elements = []

        # 1. Header Banner
        elements.append(Paragraph("LEGAL METROLOGY & FOOD SAFETY COMPLIANCE ENFORCEMENT AUDIT", title_style))
        elements.append(Spacer(1, 3))
        elements.append(Paragraph("FORMAL STATUTORY NOTICE OF PACKAGING NON-COMPLIANCE & VIOLATIONS", subtitle_style))
        elements.append(Paragraph("<font size=7.5 color='#64748B'>Issued pursuant to Legal Metrology Act 2009 (Sec 18/36), Legal Metrology (Packaged Commodities) Rules 2011 (Rule 6, 7-9), & FSSAI Act 2006 (Sec 23/24)</font>", ParagraphStyle('sub', alignment=1, spaceAfter=6)))
        elements.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor('#0F172A'), spaceAfter=8))

        # 2. Product Meta & Truth Score Card Table
        product_name = report_data.get("product_name", "Packaged Product")
        brand_name = report_data.get("brand_name", "Unknown Brand")
        barcode = report_data.get("barcode") or "N/A (Visual Scan)"
        truth_score = report_data.get("truth_score", 0)
        verdict = report_data.get("verdict", "Violates Standards")
        now_str = datetime.utcnow().strftime("%d %B %Y, %H:%M UTC")

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
                Paragraph(f"<b>Compliance Truth Score:</b> <font color='{score_color}' size=11><b>{truth_score} / 100</b></font>", body_style),
                Paragraph(f"<b>Statutory Verdict:</b> <font color='{score_color}'><b>{verdict.upper()}</b></font>", body_style),
            ]
        ]
        t_meta = Table(meta_data, colWidths=[270, 270])
        t_meta.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#F8FAFC')),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
            ('PADDING', (0, 0), (-1, -1), 5),
        ]))
        elements.append(t_meta)
        elements.append(Spacer(1, 8))

        # 3. LMPC Rule 6 Mandatory Declarations Checklist Table
        elements.append(Paragraph("1. Legal Metrology (Packaged Commodities) Rule 6 Mandatory Declarations", section_style))
        mandatory = report_data.get("mandatory_declarations")
        if mandatory and hasattr(mandatory, "items"):
            decl_items = mandatory.items
        elif isinstance(mandatory, dict) and "items" in mandatory:
            decl_items = mandatory["items"]
        else:
            decl_items = []

        if decl_items:
            m_data = [[
                Paragraph("<b>Rule Clause</b>", table_cell_bold),
                Paragraph("<b>Mandatory Declaration Item</b>", table_cell_bold),
                Paragraph("<b>Status</b>", table_cell_bold),
                Paragraph("<b>Declared Text / Legal Defect</b>", table_cell_bold),
            ]]
            for item in decl_items:
                if hasattr(item, "is_compliant"):
                    c_ok = item.is_compliant and item.is_present
                    clause = getattr(item, "rule_clause", "")
                    title = getattr(item, "title", "")
                    defect = getattr(item, "legal_defect", None)
                    ext = getattr(item, "extracted_text", "") or "Declared on PDP"
                else:
                    c_ok = item.get("is_compliant", True) and item.get("is_present", True)
                    clause = item.get("rule_clause", "")
                    title = item.get("title", "")
                    defect = item.get("legal_defect")
                    ext = item.get("extracted_text") or "Declared on PDP"

                status_badge = "<font color='#16A34A'><b>PASSED</b></font>" if c_ok else "<font color='#DC2626'><b>DEFECTIVE</b></font>"
                desc = defect if not c_ok else ext

                m_data.append([
                    Paragraph(f"<b>{clause}</b>", table_cell),
                    Paragraph(title, table_cell),
                    Paragraph(status_badge, table_cell),
                    Paragraph(f"{desc}", table_cell),
                ])
            t_m = Table(m_data, colWidths=[80, 170, 70, 220])
            t_m.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E2E8F0')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(t_m)
        else:
            elements.append(Paragraph("<i>Standard LMPC declarations audited and verified on package.</i>", body_style))

        elements.append(Spacer(1, 8))

        # 4. Font Size & Readability Analysis Box (LMPC Rule 7 & Schedule-II)
        font_audit = report_data.get("font_readability")
        if font_audit:
            elements.append(Paragraph("2. Font Size & Readability Analysis (LMPC Rule 7 & Schedule-II)", section_style))
            if hasattr(font_audit, "min_required_font_height_mm"):
                req_h = getattr(font_audit, "min_required_font_height_mm", 2.0)
                det_h = getattr(font_audit, "detected_font_height_mm", 2.5)
                f_ok = getattr(font_audit, "is_font_compliant", True)
                pdp_a = getattr(font_audit, "pdp_area_sq_cm", 140.0)
                bracket = getattr(font_audit, "net_quantity_bracket", "50g to 200g")
                remarks = getattr(font_audit, "remarks", "")
            else:
                req_h = font_audit.get("min_required_font_height_mm", 2.0)
                det_h = font_audit.get("detected_font_height_mm", 2.5)
                f_ok = font_audit.get("is_font_compliant", True)
                pdp_a = font_audit.get("pdp_area_sq_cm", 140.0)
                bracket = font_audit.get("net_quantity_bracket", "50g to 200g")
                remarks = font_audit.get("remarks", "")

            f_color = "#16A34A" if f_ok else "#DC2626"
            f_status = "COMPLIANT" if f_ok else "NON-COMPLIANT"

            f_table_data = [
                [
                    Paragraph(f"<b>Principal Display Panel (PDP) Area:</b> ~{pdp_a} cm²", table_cell),
                    Paragraph(f"<b>Package Size Bracket:</b> {bracket}", table_cell),
                ],
                [
                    Paragraph(f"<b>Statutory Min. Numeral Height:</b> {req_h} mm", table_cell),
                    Paragraph(f"<b>Detected Font Height:</b> {det_h} mm (<font color='{f_color}'><b>{f_status}</b></font>)", table_cell),
                ],
                [
                    Paragraph(f"<b>Readability Finding:</b> {remarks}", table_cell),
                    Paragraph("<b>Legal Reference:</b> LMPC Rule 7 & Schedule-II Tables", table_cell),
                ]
            ]
            t_f = Table(f_table_data, colWidths=[270, 270])
            t_f.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#F8FAFC')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(t_f)
            elements.append(Spacer(1, 8))

        # 5. Section: Front Marketing Claim vs. Reality Audit
        elements.append(Paragraph("3. Marketing Claims vs. Empirical Back-Panel Audit", section_style))
        comparisons = report_data.get("claim_comparisons", [])
        if comparisons:
            comp_table_data = [[
                Paragraph("<b>Front Marketing Claim</b>", table_cell_bold),
                Paragraph("<b>Back Panel Audit Finding & Empirical Reality</b>", table_cell_bold),
                Paragraph("<b>Status</b>", table_cell_bold),
            ]]
            for c in comparisons:
                c_dict = c if isinstance(c, dict) else (c.model_dump() if hasattr(c, "model_dump") else c.dict())
                status_text = c_dict.get("status", "violation").upper()
                c_color = "#DC2626" if status_text == "VIOLATION" else ("#D97706" if status_text == "MISLEADING" else "#16A34A")
                comp_table_data.append([
                    Paragraph(f"\"{c_dict.get('front_claim', '')}\"", table_cell),
                    Paragraph(f"{c_dict.get('reality_finding', '')}<br/><font color='#64748B'><i>{c_dict.get('explanation', '')}</i></font>", table_cell),
                    Paragraph(f"<font color='{c_color}'><b>{status_text}</b></font>", table_cell_bold),
                ])
            t_comp = Table(comp_table_data, colWidths=[150, 320, 70])
            t_comp.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E2E8F0')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#CBD5E1')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#E2E8F0')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(t_comp)
        else:
            elements.append(Paragraph("<i>No deceptive marketing claims detected on the evaluated package.</i>", body_style))

        elements.append(Spacer(1, 8))

        # 6. Section: Specific Statutory Regulatory Violations
        elements.append(Paragraph("4. Statutory Violations & Non-Compliance Dockets", section_style))
        violations = report_data.get("violations", [])
        if violations:
            viol_table_data = [[
                Paragraph("<b>Rule Code</b>", table_cell_bold),
                Paragraph("<b>Statutory Reference</b>", table_cell_bold),
                Paragraph("<b>Severity</b>", table_cell_bold),
                Paragraph("<b>Audit Finding & Legal Defect</b>", table_cell_bold),
            ]]
            for v in violations:
                v_dict = v if isinstance(v, dict) else (v.model_dump() if hasattr(v, "model_dump") else v.dict())
                sev = v_dict.get("severity", "Medium")
                s_color = "#DC2626" if sev == "Critical" else ("#EA580C" if sev == "High" else "#D97706")
                viol_table_data.append([
                    Paragraph(f"<b>{v_dict.get('rule_code', '')}</b>", table_cell_bold),
                    Paragraph(v_dict.get('regulation_reference', ''), table_cell),
                    Paragraph(f"<font color='{s_color}'><b>{sev.upper()}</b></font>", table_cell_bold),
                    Paragraph(f"<b>{v_dict.get('title', '')}</b><br/>{v_dict.get('audit_finding', '')}", table_cell),
                ])
            t_viol = Table(viol_table_data, colWidths=[110, 130, 60, 240])
            t_viol.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#FEE2E2')),
                ('BOX', (0, 0), (-1, -1), 1, colors.HexColor('#FCA5A5')),
                ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#FECACA')),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('PADDING', (0, 0), (-1, -1), 4),
            ]))
            elements.append(t_viol)
        else:
            elements.append(Paragraph("<i>Zero statutory violations identified against Legal Metrology and FSSAI thresholds.</i>", body_style))

        elements.append(Spacer(1, 8))

        # 7. Formal Enforcement Grievance Submission Block
        legal_block = [
            Paragraph("<b>5. STATUTORY DECLARATION & ENFORCEMENT ACTION</b>", section_style),
            Paragraph(
                "This report constitutes empirical documentary evidence under "
                "<b>Section 18 & 36 of the Legal Metrology Act, 2009</b>, "
                "<b>The Legal Metrology (Packaged Commodities) Rules, 2011 (Rules 6, 7-9)</b>, "
                "<b>Section 23 & 24 of the Food Safety and Standards Act, 2006</b>, and the "
                "<b>Consumer Protection Act, 2019</b>. "
                "The audited package contains non-compliances rendering the manufacturer/packer liable for statutory notice and enforcement rectification.",
                body_style
            ),
            Spacer(1, 4),
            Paragraph(f"<b>Inspecting Authority / Advocate:</b> {report_data.get('complainant_name', 'Authorized Legal Metrology Officer / Consumer Advocate')}", bold_body),
            Paragraph("<b>Target Statutory Authority:</b> Department of Consumer Affairs (DoCA) / Legal Metrology Enforcement Directorate / CCPA", body_style),
            Spacer(1, 8),
            Paragraph("<b>Verification Signature & Digital Stamp:</b>", body_style),
            Paragraph("_____________________________________________ <br/><font size=7 color='#64748B'>Certified via LabelTruth Automated Compliance Verification System</font>", body_style)
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

    def generate_csv_report(self, report_data: Dict[str, Any]) -> str:
        """Generates an editable CSV compliance inspection report string."""
        output = io.StringIO()
        writer = csv.writer(output)

        # 1. Header Information
        writer.writerow(["LABELTRUTH COMPLIANCE INSPECTION REPORT", ""])
        writer.writerow(["Report Date", datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")])
        writer.writerow(["Product Name", report_data.get("product_name", "N/A")])
        writer.writerow(["Brand / Manufacturer", report_data.get("brand_name", "N/A")])
        writer.writerow(["Barcode / SKU", report_data.get("barcode", "N/A")])
        writer.writerow(["Compliance Truth Score (0-100)", report_data.get("truth_score", 0)])
        writer.writerow(["Compliance Verdict", report_data.get("verdict", "N/A")])
        writer.writerow([])

        # 2. LMPC Rule 6 Mandatory Declarations
        writer.writerow(["SECTION 1: LMPC RULE 6 MANDATORY DECLARATIONS", "", "", ""])
        writer.writerow(["Rule Clause", "Declaration Item", "Status", "Details / Legal Defect"])
        
        mandatory = report_data.get("mandatory_declarations")
        if mandatory and hasattr(mandatory, "items"):
            decl_items = mandatory.items
        elif isinstance(mandatory, dict) and "items" in mandatory:
            decl_items = mandatory["items"]
        else:
            decl_items = []

        for item in decl_items:
            if hasattr(item, "is_compliant"):
                c_ok = item.is_compliant and item.is_present
                clause = getattr(item, "rule_clause", "")
                title = getattr(item, "title", "")
                defect = getattr(item, "legal_defect", "") or getattr(item, "extracted_text", "Declared")
            else:
                c_ok = item.get("is_compliant", True) and item.get("is_present", True)
                clause = item.get("rule_clause", "")
                title = item.get("title", "")
                defect = item.get("legal_defect") or item.get("extracted_text", "Declared")
            writer.writerow([clause, title, "PASSED" if c_ok else "DEFECTIVE", defect])
        writer.writerow([])

        # 3. Marketing Claim Comparisons
        writer.writerow(["SECTION 2: MARKETING CLAIM COMPARISONS", "", "", ""])
        writer.writerow(["Front Marketing Claim", "Back Panel Reality", "Status", "Explanation"])
        for c in report_data.get("claim_comparisons", []):
            c_dict = c if isinstance(c, dict) else (c.model_dump() if hasattr(c, "model_dump") else c.dict())
            writer.writerow([
                c_dict.get("front_claim", ""),
                c_dict.get("reality_finding", ""),
                c_dict.get("status", "").upper(),
                c_dict.get("explanation", "")
            ])
        writer.writerow([])

        # 4. Violations
        writer.writerow(["SECTION 3: STATUTORY VIOLATIONS", "", "", ""])
        writer.writerow(["Rule Code", "Regulation Reference", "Severity", "Finding"])
        for v in report_data.get("violations", []):
            v_dict = v if isinstance(v, dict) else (v.model_dump() if hasattr(v, "model_dump") else v.dict())
            writer.writerow([
                v_dict.get("rule_code", ""),
                v_dict.get("regulation_reference", ""),
                v_dict.get("severity", "").upper(),
                v_dict.get("audit_finding", "")
            ])

        return output.getvalue()

pdf_service = PDFReportService()
