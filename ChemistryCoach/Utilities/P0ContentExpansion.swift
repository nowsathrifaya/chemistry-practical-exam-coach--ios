import Foundation

struct PracticalReferenceItem: Identifiable, Codable, Hashable {
    let id: String; let title: String; let details: String
}

struct CalculationPracticeItem: Identifiable, Codable, Hashable {
    let id: String; let topic: String; let question: String; let answer: String; let steps: [String]
}

enum PracticalReferenceLibrary {
    static let items: [PracticalReferenceItem] = [
        .init(id:"solubility", title:"Solubility rules", details:"All nitrates and Group 1/ammonium salts are soluble. Most chlorides are soluble except silver and lead. Most sulfates are soluble except barium, lead and calcium (sparingly). Most carbonates and hydroxides are insoluble except Group 1 and ammonium; calcium hydroxide is sparingly soluble."),
        .init(id:"flame", title:"Flame tests", details:"Li⁺ red; Na⁺ yellow; K⁺ lilac; Ca²⁺ orange-red; Ba²⁺ apple green; Cu²⁺ blue-green."),
        .init(id:"gases", title:"Gas tests", details:"H₂: lighted splint gives a squeaky pop. O₂: glowing splint relights. CO₂: limewater turns milky. NH₃: damp red litmus turns blue. Cl₂: damp litmus is bleached. SO₂: acidified potassium manganate(VII) is decolourised."),
        .init(id:"indicators", title:"Indicators", details:"Methyl orange: red to yellow, approximately pH 3–4. Phenolphthalein: colourless to pink, approximately pH 8–10. Universal indicator: full pH colour range."),
        .init(id:"formulae", title:"Formula sheet", details:"n = m/Mr; c = n/V in dm³; q = mcΔT; percentage yield = actual/theoretical × 100%; percentage purity = pure mass/sample mass × 100%; 1 dm³ = 1000 cm³."),
        .init(id:"reactivity", title:"Reactivity series", details:"K, Na, Ca, Mg, Al, C, Zn, Fe, H, Cu, Ag, Au. Metals above hydrogen generally react with dilute acids to produce hydrogen; more reactive metals displace less reactive metals from compounds."),
        .init(id:"ions", title:"Common ions", details:"Na⁺, K⁺, NH₄⁺, Ag⁺, Ca²⁺, Mg²⁺, Ba²⁺, Cu²⁺, Fe²⁺, Fe³⁺, Zn²⁺, Al³⁺, Cl⁻, Br⁻, I⁻, OH⁻, NO₃⁻, CO₃²⁻, SO₄²⁻, PO₄³⁻."),
        .init(id:"titration", title:"Titration procedure", details:"Rinse the burette with titrant, fill and remove the funnel, record the initial reading, pipette a measured aliquot into a conical flask, add indicator, titrate while swirling, record the final reading, calculate final minus initial, and repeat until concordant titres are obtained."),
        .init(id:"salt", title:"Salt preparation", details:"For acid plus soluble alkali, use titration to find exact volumes, repeat without indicator, mix, evaporate some water, crystallise, filter and dry. For an insoluble base, add excess base to warm acid, filter, concentrate, crystallise, filter and dry."),
        .init(id:"electrolysis", title:"Electrolysis", details:"At the cathode, reduction occurs. At the anode, oxidation occurs. Aqueous CuSO₄ with inert electrodes gives copper at the cathode and oxygen at the anode. Concentrated aqueous NaCl gives hydrogen at the cathode and chlorine at the anode."),
        .init(id:"water", title:"Water of crystallisation", details:"Heat a known mass of hydrated salt to constant mass. Mass lost is water. Convert anhydrous salt and water masses to moles, divide both by the smaller amount, and obtain the simplest whole-number ratio."),
        .init(id:"graph", title:"Graph checklist", details:"Put the independent variable on the x-axis, dependent variable on the y-axis, include units, use most of the grid, choose sensible equal intervals, plot accurately, draw a smooth best-fit line, identify anomalies, and interpolate only within the data range unless extrapolation is requested.")
    ]
}

enum CalculationPracticeLibrary {
    static let items: [CalculationPracticeItem] = [
        .init(id:"titration1", topic:"Titration", question:"25.0 cm³ of 0.100 mol/dm³ NaOH reacts with 24.60 cm³ of HCl in a 1:1 ratio. Find the HCl concentration.", answer:"0.102 mol/dm³", steps:["Convert 24.60 cm³ to 0.02460 dm³.","Moles NaOH = 0.100 × 0.0250 = 0.00250 mol.","Moles HCl = 0.00250 mol.","c = n/V = 0.00250/0.02460 = 0.102 mol/dm³."]),
        .init(id:"gas1", topic:"Gas volume", question:"A reaction produces 480 cm³ of gas. Calculate the amount in moles at room conditions using 24 000 cm³/mol.", answer:"0.0200 mol", steps:["Use n = volume/24 000.","n = 480/24 000 = 0.0200 mol."]),
        .init(id:"energy1", topic:"Energy", question:"50.0 g of water rises by 6.5 °C. Calculate q using c = 4.18 J/g°C.", answer:"1.36 kJ", steps:["Use q = mcΔT.","q = 50.0 × 4.18 × 6.5 = 1358.5 J.","Convert to kJ: 1.36 kJ."]),
        .init(id:"yield1", topic:"Percentage yield", question:"The theoretical yield is 12.0 g and the actual yield is 9.0 g. Calculate percentage yield.", answer:"75.0%", steps:["Use actual/theoretical × 100%.","9.0/12.0 × 100% = 75.0%."]),
        .init(id:"purity1", topic:"Percentage purity", question:"A 5.00 g sample contains 4.25 g of pure compound. Calculate percentage purity.", answer:"85.0%", steps:["Use pure mass/sample mass × 100%.","4.25/5.00 × 100% = 85.0%."]),
        .init(id:"water1", topic:"Water of crystallisation", question:"A hydrated salt loses 1.80 g water and leaves 2.50 g anhydrous salt. If Mr of water is 18.0 and Mr of salt is 160, find x in salt·xH₂O.", answer:"x ≈ 6", steps:["Moles water = 1.80/18.0 = 0.100 mol.","Moles salt = 2.50/160 = 0.015625 mol.","Ratio water:salt = 0.100:0.015625 ≈ 6.4:1; experimental values should be checked and rounded only after considering uncertainty."])
    ]
}

// The 180 auto-generated template questions have been replaced with
// 100 real exam-style questions in ExpandedAceQuestions.swift.
// AceQuestionBank.realExpanded is the new source of truth for the full bank.
// The PracticalReferenceLibrary and CalculationPracticeLibrary are now
// connected to views (CompleteReferenceView and CalculationPracticeView).
