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
            regulation_reference="FSSAI Claims & Advertisements Regulations 2018, Section 5(2)",
            severity="Critical",
            description="Audits if products claiming 'No Added Sugar' conceal high glycemic index fillers (maltodextrin, invert syrups, fruit concentrates).",
            penalty_points=30
        ),
        ComplianceRuleInfo(
            code="RULE_B_GRAIN_HIERARCHY_DECEPTION",
            name="Whole Wheat / Atta Hierarchy Inversion",
            regulation_reference="FSSAI Labelling and Display Regulations 2020, Section 23 & Reg 5(1)",
            severity="Critical",
            description="Audits if packaging claiming '100% Whole Wheat' or 'Made with Atta' lists Refined Flour (Maida) as the predominant #1 ingredient.",
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
            regulation_reference="FSSAI Section 2.2.2.5 (Specific Declaration of Vegetable Fat)",
            severity="High",
            description="Flags products concealing high-palmitic palm oil or generic 'Edible Vegetable Oil' without mandatory source declaration.",
            penalty_points=20
        ),
        ComplianceRuleInfo(
            code="RULE_E_CHEMICAL_ADDITIVES",
            name="Harmful Synthetic Dyes, Preservatives & Sweeteners",
            regulation_reference="FSSAI Food Products Standards and Food Additives Regulations (INS Standards)",
            severity="High",
            description="Audits toxic synthetic azo dyes (INS 102/110/129), Caramel Color IV (INS 150d), MSG (INS 621), and intense sweeteners (INS 950/951/955).",
            penalty_points=10
        ),
        ComplianceRuleInfo(
            code="RULE_F_TRANS_FAT_LIMIT",
            name="Industrial Trans Fat Safety Limit (<2%)",
            regulation_reference="FSSAI Trans Fatty Acid Limits Regulation",
            severity="Critical",
            description="Strictly flags partially hydrogenated fats and vanaspati in packaged consumer items.",
            penalty_points=25
        )
    ]
