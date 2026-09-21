
import SwiftUI

struct ApparatusPracticeView: View {
    let apparatusType: ApparatusType
    let curriculum: Curriculum
    let repository: AttemptRepository
    var onSaved: (() -> Void)?
    @State private var question: ApparatusQuestion
    @State private var input = ""
    @State private var result: ApparatusMarkResult?
    @FocusState private var focused: Bool

    init(apparatusType: ApparatusType, curriculum: Curriculum, repository: AttemptRepository, onSaved: (() -> Void)? = nil) {
        self.apparatusType=apparatusType; self.curriculum=curriculum; self.repository=repository; self.onSaved=onSaved
        _question=State(initialValue: ApparatusTrainer().question(type:apparatusType,seed:Int.random(in:0...Int(Int32.max)),curriculum:curriculum))
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                VStack(alignment:.leading,spacing:6) {
                    Text(apparatusType.label).font(.title2.bold())
                    Text("Instrument reading practice").foregroundStyle(.secondary)
                }
                InstrumentCard(state: question.visualState, type: apparatusType)
                Text(question.prompt).font(.headline)
                TextField("Your reading",text:$input).keyboardType(.decimalPad).textFieldStyle(.roundedBorder).focused($focused)
                if let result {
                    VStack(alignment:.leading,spacing:8) {
                        Label(result.correct ? "Correct" : "Review this reading",systemImage:result.correct ? "checkmark.circle.fill":"xmark.circle.fill")
                            .font(.headline).foregroundStyle(result.correct ? .green:.red)
                        ForEach(result.feedback,id:\.self){Text($0).font(.footnote)}
                        Divider()
                        Text("Exam trap").font(.caption.bold())
                        Text(result.examTrap).font(.footnote)
                    }.padding(16).background(Color(.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:16))
                }
                Button(result == nil ? "Check reading" : "New reading") {
                    if result == nil {
                        focused=false
                        let v=Double(input.replacingOccurrences(of:",",with:"."))
                        let r=ApparatusTrainer().mark(question:question,studentReading:v)
                        result=r
                        SoundManager.shared.play(r.correct ? .success : .error)
                        repository.save(curriculum:curriculum,mode:AttemptMode.apparatusPractice,target:apparatusType.label,score:r.score,maxScore:100,feedback:r.feedback); onSaved?()
                    } else {
                        SoundManager.shared.play(.tap)
                        question=ApparatusTrainer().question(type:apparatusType,seed:Int.random(in:0...Int(Int32.max)),curriculum:curriculum); input=""; result=nil
                    }
                }.buttonStyle(.borderedProminent).frame(maxWidth:.infinity)
            }.padding(20)
        }.background(Color(.systemGroupedBackground)).navigationTitle("Reading Practice").navigationBarTitleDisplayMode(.inline)
    }
}

private struct InstrumentCard: View {
    let state: ApparatusVisualState; let type: ApparatusType
    var body: some View { ChemistryInstrumentView(state: state, type: type) }
}
