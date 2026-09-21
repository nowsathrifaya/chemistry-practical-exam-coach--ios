import Foundation

enum CurriculumSkill: String, CaseIterable, Identifiable, Hashable { case safety, apparatus, measurement, observation, recording, graphing, calculation, planning, evaluation, qualitativeAnalysis
 var id: String { rawValue }
}
struct CurriculumTopic: Identifiable, Hashable { let id: String; let title: String; let skills: [CurriculumSkill]; let notes: String }
struct OLevelPracticalCurriculum {
 static let topics: [CurriculumTopic] = [
  .init(id:"fundamentals",title:"Practical fundamentals",skills:[.safety,.apparatus,.measurement,.recording],notes:"Safety, apparatus choice, units, decimal places, significant figures, accurate scale and meniscus readings, observations versus inferences."),
  .init(id:"titration",title:"Titration",skills:[.apparatus,.measurement,.recording,.calculation],notes:"Rinsing, pipetting, indicator choice, rough and accurate titres, concordance, mean titre and concentration calculations."),
  .init(id:"rates",title:"Rate of reaction",skills:[.planning,.measurement,.graphing,.evaluation],notes:"Independent, dependent and controlled variables; gas volume or mass loss; repeat readings; rate, gradients and fair tests."),
  .init(id:"separation",title:"Separation and purification",skills:[.apparatus,.planning,.observation],notes:"Filtration, evaporation, crystallisation, distillation and chromatography; choosing a method from physical properties."),
  .init(id:"qualitative",title:"Qualitative analysis",skills:[.observation,.recording,.qualitativeAnalysis],notes:"Cation, anion and gas tests; record colour, precipitate, solubility, effervescence and confirmatory tests."),
  .init(id:"electrolysis",title:"Electrolysis",skills:[.observation,.calculation,.evaluation],notes:"Electrolytes, electrodes, ion discharge, products, observations and half-equations."),
  .init(id:"energetics",title:"Energetics",skills:[.measurement,.calculation,.evaluation],notes:"Temperature change, q = mcΔT, energy per mole, heat loss and improvements."),
  .init(id:"salts",title:"Preparation of salts",skills:[.planning,.apparatus,.observation],notes:"Acid plus excess insoluble base, filtration, concentration, crystallisation, washing and drying."),
  .init(id:"gas",title:"Gas collection and tests",skills:[.apparatus,.observation,.measurement],notes:"Gas syringe and displacement methods; hydrogen, oxygen, carbon dioxide, ammonia and chlorine tests."),
  .init(id:"data",title:"Data analysis and investigation planning",skills:[.graphing,.calculation,.planning,.evaluation],notes:"Tables, units, anomalies, line of best fit, gradient, conclusions, reliability, accuracy, validity and improvements.")
 ]
}
