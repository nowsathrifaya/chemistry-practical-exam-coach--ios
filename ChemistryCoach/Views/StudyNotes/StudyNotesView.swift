
import SwiftUI

enum StudyNoteCategory: String, CaseIterable, Identifiable {
    case experimental, particulate, bonding, calculations, acidBase, qualitative, redox, periodic, energetics, rate, organic, airQuality, examSkills
    var id:String{rawValue}
    var label:String{
        switch self{
        case .experimental:return "Experimental Chemistry"
        case .particulate:return "Particulate Nature of Matter"
        case .bonding:return "Chemical Bonding & Structure"
        case .calculations:return "Chemical Calculations"
        case .acidBase:return "Acid–Base Chemistry"
        case .qualitative:return "Qualitative Analysis"
        case .redox:return "Redox Chemistry"
        case .periodic:return "Patterns in the Periodic Table"
        case .energetics:return "Chemical Energetics"
        case .rate:return "Rate of Reactions"
        case .organic:return "Organic Chemistry"
        case .airQuality:return "Maintaining Air Quality"
        case .examSkills:return "Paper 3 Exam Skills"
        }
    }
    var emoji:String{
        switch self{
        case .experimental:return "🧪"; case .particulate:return "⚛️"; case .bonding:return "🔗"; case .calculations:return "🧮"; case .acidBase:return "🧫"; case .qualitative:return "🔬"; case .redox:return "🔋"; case .periodic:return "🧩"; case .energetics:return "🔥"; case .rate:return "⏱️"; case .organic:return "🧬"; case .airQuality:return "🌍"; case .examSkills:return "🎯"
        }
    }
}
struct StudyNote:Identifiable{
    let id:String; let category:StudyNoteCategory; let title:String; let rule:String; let examples:String; let doNotDo:String; let tip:String
}
enum StudyNotesBank {
    static let all:[StudyNote]=[
        n("exp1",.experimental,"Choosing apparatus","Use an apparatus whose precision matches the measurement required. Burettes and pipettes are preferred for accurate titration volumes.","Burette: read to 0.05 cm³. Volumetric pipette: fixed 25.0 cm³ aliquot. Measuring cylinder: less precise.","Do not choose a measuring cylinder when a pipette is needed for an accurate fixed volume.","Always justify apparatus choice by precision and purpose."),
        n("exp2",.experimental,"Separation methods","Choose the method from physical properties: solubility, boiling point, particle size, sublimation or immiscibility.","Filtration separates an insoluble solid from a liquid; fractional distillation separates miscible liquids with different boiling points.","Do not say filtration separates dissolved salt from water.","Name the property that makes the method work."),
        n("part1",.particulate,"Particle model","Solids have closely packed particles vibrating about fixed positions; liquids have particles that can move past one another; gases have widely spaced particles moving randomly.","Heating increases average kinetic energy and usually increases particle separation.","Do not describe particles themselves as expanding.","Explain macroscopic changes using particle arrangement and motion."),
        n("bond1",.bonding,"Structure determines properties","Ionic, covalent molecular, giant covalent and metallic structures have different bonding and particle arrangements, producing different properties.","Graphite conducts because it has delocalised electrons; diamond is hard because of its giant covalent network.","Do not assume every covalent substance has the same properties.","Link property → structure → bonding."),
        n("calc1",.calculations,"Mole calculations","Use n = m/Mr and c = n/V, with V in dm³ for concentration.","25.0 cm³ = 0.0250 dm³. Always write the balanced equation before using mole ratios.","Do not use cm³ directly in c = n/V.","Track units at every step."),
        n("acid1",.acidBase,"Strong vs weak acids","Strong acids ionise extensively in water; weak acids ionise only partially. Strength is not the same as concentration.","A concentrated weak acid can contain more acid per unit volume than a dilute strong acid.","Do not equate strong with concentrated.","Separate strength (ionisation) from concentration (amount per volume)."),
        n("qual1",.qualitative,"Qualitative analysis","Observations must be precise: colour change, precipitate colour, solubility in excess reagent and gas tests.","Carbonate + dilute acid → effervescence; CO₂ turns limewater milky. Chloride + acidified AgNO₃ → white precipitate.","Do not write only 'reaction occurs'.","Record what you actually see before interpreting it."),
        n("redox1",.redox,"OIL RIG","Oxidation is loss of electrons; reduction is gain of electrons. Oxidation occurs at the anode; reduction occurs at the cathode.","Cu²⁺ + 2e⁻ → Cu is reduction at a cathode.","Do not swap anode/cathode or oxidation/reduction.","Remember: Red Cat = Reduction at Cathode."),
        n("period1",.periodic,"Group trends","Down Group 1, reactivity increases because the outer electron is farther from and more shielded from the nucleus. Down Group 17, reactivity decreases.","Noble gases are unreactive because their outer electron arrangement is stable.","Do not say reactivity trends are caused only by atomic mass.","Explain the trend using electron arrangement."),
        n("energy1",.energetics,"Energy profile","Exothermic reactions release energy and have products at lower energy than reactants; endothermic reactions absorb energy and have products at higher energy.","A catalyst lowers activation energy but does not change the overall energy change.","Do not confuse activation energy with overall energy change.","Label axes and activation energy clearly."),
        n("rate1",.rate,"What affects rate?","Higher temperature, higher concentration, greater surface area and suitable catalysts can increase reaction rate.","A steep tangent on a volume-time graph represents a faster rate.","Do not claim a catalyst increases the energy change.","Explain rate using successful collision frequency/energy."),
        n("org1",.organic,"Organic reactions","Alkanes are saturated; alkenes contain C=C and undergo addition reactions. Alcohols, carboxylic acids and esters have characteristic reactions.","Bromine water is decolourised by an alkene under the syllabus test conditions.","Do not call all hydrocarbons alkenes.","Look for the functional group."),
        n("air1",.airQuality,"Air pollutants","Combustion can produce CO₂, CO, particulates and nitrogen oxides; sulfur compounds can produce sulfur dioxide. Pollutants have different sources and effects.","CO is toxic because it reduces oxygen transport by haemoglobin; SO₂ contributes to acid deposition.","Do not treat all air pollutants as greenhouse gases.","Separate source, pollutant, effect and control measure."),
        n("skills1",.examSkills,"Titration concordance","SEAB practical guidance expects burette readings to 0.05 cm³ and, for a good end-point, two titres within 0.20 cm³.","24.10 and 24.15 cm³ are concordant; 24.55 cm³ is not concordant with them.","Do not average an obviously discordant titre automatically.","Identify concordant titres before calculating a mean."),
        n("skills2",.examSkills,"Paper 3 planning","A good plan identifies variables, apparatus, procedure, data processing and risks/precautions.","For rate experiments, specify how rate will be measured and which variables remain constant.","Do not write 'repeat and be accurate' as the whole plan.","Write enough detail that another student could reproduce the experiment.")
    ]
    static func forCategory(_ c:StudyNoteCategory)->[StudyNote]{all.filter{$0.category==c}}
    private static func n(_ id:String,_ c:StudyNoteCategory,_ t:String,_ r:String,_ e:String,_ d:String,_ tip:String)->StudyNote{StudyNote(id:id,category:c,title:t,rule:r,examples:e,doNotDo:d,tip:tip)}
}
struct StudyNotesListView:View{
    let curriculum:Curriculum
    @EnvironmentObject private var purchases: PurchaseManager
    var body:some View{
        List{
            if let resumed = LastStudiedNoteStore.resolve() {
                Section("Continue reading") {
                    NavigationLink {
                        StudyNoteCategoryDetailView(category: resumed.category, resumeAtIndex: resumed.pageIndex)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(resumed.note.title).font(.headline)
                                Text(resumed.category.label).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            Section("Study notes") {
                ForEach(StudyNoteCategory.allCases){c in NavigationLink{StudyNoteCategoryDetailView(category:c)} label: {HStack{Text(c.emoji).font(.title2);VStack(alignment:.leading){Text(c.label).font(.headline);Text("\(StudyNotesBank.forCategory(c).count) notes").font(.caption).foregroundStyle(.secondary)}}.padding(.vertical,4)}}
            }
            Section("6092 revision materials") {
                NavigationLink { RevisionMaterialsView() } label: {
                    Label("Full revision material pack", systemImage: "books.vertical.fill")
                }
                NavigationLink { premiumDestination(purchases: purchases) { CompleteReferenceView() } } label: {
                    Label("Practical reference tables", systemImage: "text.book.closed.fill")
                }
            }
        }
        .navigationTitle("Learn")
    }
}
struct StudyNoteCategoryDetailView:View{
    let category:StudyNoteCategory
    var resumeAtIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    private var notes: [StudyNote] { StudyNotesBank.forCategory(category) }
    var body:some View{
        Group {
            if notes.isEmpty {
                ContentUnavailableView("No notes here yet", systemImage: "book")
            } else {
                PagedReaderView(
                    pageCount: notes.count,
                    initialIndex: min(max(resumeAtIndex, 0), notes.count - 1),
                    pageLabel: { "Note \($0 + 1) of \(notes.count)" },
                    page: { i in StudyNoteCardPage(note: notes[i]) },
                    onFinished: { dismiss() },
                    finishedLabel: "Done",
                    onPageChanged: { LastStudiedNoteStore.record(category: category, pageIndex: $0) }
                )
                .onAppear { LastStudiedNoteStore.record(category: category, pageIndex: min(max(resumeAtIndex, 0), notes.count - 1)) }
            }
        }
        .navigationTitle(category.label).navigationBarTitleDisplayMode(.inline)
    }
}
private struct StudyNoteCardPage: View {
    let note: StudyNote
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(note.title).font(.title2.bold())
            Text(note.rule).font(.title3).fixedSize(horizontal: false, vertical: true)
            NoteBlock(label:"Examples",text:note.examples,tint:.blue)
            NoteBlock(label:"Avoid",text:note.doNotDo,tint:.red)
            NoteBlock(label:"Exam tip",text:note.tip,tint:.teal)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
private struct NoteBlock:View{let label:String;let text:String;let tint:Color;var body:some View{VStack(alignment:.leading,spacing:3){Text(label).font(.caption.bold()).foregroundStyle(tint);Text(text).font(.footnote)}}}
