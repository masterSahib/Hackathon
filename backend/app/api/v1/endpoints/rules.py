from typing import List
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()

class ComplianceRuleInfo(BaseModel):
    code: str
    name: str
    regulation_reference: str
    severity: str
    description: str
    penalty_points: int

@router.get("/", response_model=List[ComplianceRuleInfo])
async def list_active_rules():
    """Lists all statutory food packaging regulations and detection rules enforced by LabelTruth."""
    return [
        ComplianceRuleInfo(
            code="RULE_A_ZERO_SUGAR_DECEPTION",
            name="Zero Sugar & No Added Sugar Deception",
            regulation_reference="FSSAI Claims Reg. 2018 Sec 5(2) & Legal Metrology Act 2009 Sec 18",
            severity="Critical",
            description="Audits if products claiming 'No Added Sugar' conceal high glycemic index fillers (maltodextrin, invert syrups, liquid glucose).",
            penalty_points=30
        ),
        ComplianceRuleInfo(
            code="RULE_B_GRAIN_HIERARCHY_DECEPTION",
            name="Whole Wheat / Atta Hierarchy Inversion",
            regulation_reference="FSSAI Labelling Reg. 2020 Sec 23 & Legal Metrology (Packaged Commodities) Rules 2011 Rule 6(1)(b)",
            severity="Critical",
            description="Audits if packaging claiming '100% Whole Wheat' or 'Made with Atta' lists Refined Flour (Maida) as the predominant #1 ingredient in violation of generic commodity declaration rules.",
            penalty_points=25
        ),
        ComplianceRuleInfo(
            code="RULE_C_INSUFFICIENT_PROTEIN_CLAIM",
            name="Insufficient Protein Content Threshold",
            regulation_reference="FSSAI Schedule-I Nutritional Claims Thresholds & Codex Alimentarius",
            severity="Medium",
            description="Requires at least 12% energy from protein for 'Source of Protein' and 20% energy for 'High Protein' claims.",
            penalty_points=15
        ),
        ComplianceRuleInfo(
            code="RULE_D_PALM_OIL_MASKING",
            name="Palm Oil Disguise / Generic Vegetable Oil Audit",
            regulation_reference="FSSAI Section 2.2.2.5 & Legal Metrology (Packaged Commodities) Rules 2011",
            severity="High",
            description="Flags products concealing high-palmitic palm oil or generic 'Edible Vegetable Oil' without mandatory vegetable fat source declaration.",
            penalty_points=20
        ),
        ComplianceRuleInfo(
            code="RULE_E_CHEMICAL_ADDITIVES",
            name="Harmful Synthetic Dyes, Preservatives & Sweeteners",
            regulation_reference="FSSAI Food Additives INS Standards & Consumer Protection Act 2019",
            severity="High",
            description="Audits toxic synthetic azo dyes (INS 102/110/129), Caramel Color IV (INS 150d), flavour enhancers (INS 627/631), and intense sweeteners (INS 950/951/955).",
            penalty_points=10
        ),
        ComplianceRuleInfo(
            code="RULE_F_HFSS_SODIUM_AND_FAT_HAZARDS",
            name="HFSS Sodium, Salt & Saturated Fat Threshold Caps",
            regulation_reference="FSSAI Labelling & Display Regulations 2020 (HFSS Standards) & ICMR-NIN Dietary Guidelines",
            severity="High",
            description="Enforces Indian statutory caps on high sodium (>400mg/100g) and saturated fat (>6g/100g) in packaged snacks.",
            penalty_points=15
        ),
        ComplianceRuleInfo(
            code="RULE_G_LMPC_MANDATORY_DECLARATIONS",
            name="Legal Metrology Mandatory Declarations & Unit Sale Pricing",
            regulation_reference="Legal Metrology Act, 2009 & Legal Metrology (Packaged Commodities) Rules, 2011 (Rule 6)",
            severity="Medium",
            description="Verifies mandatory declaration of generic product identity, Net Quantity, Unit Sale Price (USP), and Consumer Care details on principal display panels.",
            penalty_points=10
        )
    ]
