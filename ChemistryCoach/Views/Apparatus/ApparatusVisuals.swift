import SwiftUI

struct ChemistryInstrumentView: View {
    let state: ApparatusVisualState
    let type: ApparatusType
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                drawBackground(&context, size: size)
                switch state {
                case .burette(let reading): drawBurette(&context, size: size, reading: reading)
                case .balance(let mass): drawBalance(&context, size: size, reading: mass)
                case .thermometer(let temp): drawThermometer(&context, size: size, reading: temp)
                case .measuringCylinder(let volume): drawCylinder(&context, size: size, reading: volume)
                case .gasSyringe(let volume): drawSyringe(&context, size: size, reading: volume)
                case .stopwatch(let seconds): drawStopwatch(&context, size: size, reading: seconds)
                case .pipette: drawPipette(&context, size: size)
                case .generic: break
                }
            }.accessibilityLabel("Interactive \(type.label) showing a reading")
        }
        .padding(12)
    }

    private func drawBackground(_ c: inout GraphicsContext, size: CGSize) { c.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 16), with: .color(Color(.systemBackground))) }
    private func drawBurette(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let x=size.width*0.45, top=25.0, bottom=size.height-40, h=bottom-top
        c.fill(Path(CGRect(x:x-8,y:top,width:16,height:h)), with:.color(.cyan.opacity(0.12))); c.stroke(Path(CGRect(x:x-8,y:top,width:16,height:h)), with:.color(.blue), lineWidth:1)
        for i in 0...10 { let y=top+h*CGFloat(i)/10; var p=Path(); p.move(to:CGPoint(x:x+10,y:y)); p.addLine(to:CGPoint(x:x+32,y:y)); c.stroke(p,with:.color(.primary),lineWidth:1); c.draw(Text("\(i*5)").font(.caption2),at:CGPoint(x:x+48,y:y)) }
        c.fill(Path(ellipseIn:CGRect(x:x-18,y:top+h*CGFloat(reading/50)-5,width:36,height:10)),with:.color(.blue.opacity(0.35)))
        c.draw(Text(String(format:"Meniscus %.2f cm³",reading)).font(.headline),at:CGPoint(x:size.width/2,y:size.height-18))
    }
    private func drawBalance(_ c: inout GraphicsContext, size: CGSize, reading: Double) {
        let r=CGRect(x:size.width*0.18,y:size.height*0.28,width:size.width*0.64,height:size.height*0.42); c.fill(Path(roundedRect:r,cornerRadius:18),with:.color(.gray.opacity(0.18))); c.stroke(Path(roundedRect:r,cornerRadius:18),with:.color(.gray),lineWidth:2); c.fill(Path(CGRect(x:r.midX-65,y:r.midY-22,width:130,height:44)),with:.color(.black.opacity(0.88))); c.draw(Text(String(format:"%.1f g",reading)).font(.title3.monospacedDigit().bold()).foregroundStyle(.green),at:CGPoint(x:r.midX,y:r.midY)); c.draw(Text("Electronic balance").font(.headline),at:CGPoint(x:size.width/2,y:size.height-22))
    }
    private func drawThermometer(_ c: inout GraphicsContext, size: CGSize, reading: Double) { let x=size.width/2; c.fill(Path(roundedRect:CGRect(x:x-10,y:35,width:20,height:size.height-75),cornerRadius:10),with:.color(.white)); c.stroke(Path(roundedRect:CGRect(x:x-10,y:35,width:20,height:size.height-75),cornerRadius:10),with:.color(.gray),lineWidth:1); c.fill(Path(ellipseIn:CGRect(x:x-18,y:size.height-55,width:36,height:36)),with:.color(.red)); let fraction=max(0,min(1,(reading-0)/(100))); c.fill(Path(CGRect(x:x-4,y:45+(size.height-95)*(1-fraction),width:8,height:(size.height-95)*fraction)),with:.color(.red)); c.draw(Text(String(format:"%.1f °C",reading)).font(.headline),at:CGPoint(x:size.width/2,y:size.height-18)) }
    private func drawCylinder(_ c: inout GraphicsContext, size: CGSize, reading: Double) { let r=CGRect(x:size.width*0.38,y:25,width:size.width*0.24,height:size.height-65); c.stroke(Path(roundedRect:r,cornerRadius:10),with:.color(.blue),lineWidth:2); for i in 0...10 { let y=r.minY+r.height*CGFloat(i)/10; var p=Path(); p.move(to:CGPoint(x:r.minX-20,y:y)); p.addLine(to:CGPoint(x:r.minX-4,y:y)); c.stroke(p,with:.color(.primary),lineWidth:1) }; c.fill(Path(roundedRect:CGRect(x:r.minX+2,y:r.maxY-r.height*CGFloat(min(reading,100)/100),width:r.width-4,height:r.height*CGFloat(min(reading,100)/100)),cornerRadius:8),with:.color(.blue.opacity(0.22))); c.draw(Text("\(Int(reading)) cm³").font(.headline),at:CGPoint(x:size.width/2,y:size.height-18)) }
    private func drawSyringe(_ c: inout GraphicsContext, size: CGSize, reading: Double) { let r=CGRect(x:size.width*0.18,y:size.height*0.42,width:size.width*0.64,height:60); c.stroke(Path(roundedRect:r,cornerRadius:10),with:.color(.gray),lineWidth:2); let frac=min(max(reading/100,0),1); c.fill(Path(CGRect(x:r.minX+6,y:r.minY+6,width:(r.width-12)*frac,height:r.height-12)),with:.color(.blue.opacity(0.18))); c.draw(Text("Gas volume  \(Int(reading)) cm³").font(.headline),at:CGPoint(x:size.width/2,y:size.height-28)) }
    private func drawStopwatch(_ c: inout GraphicsContext, size: CGSize, reading: Double) { let d=min(size.width,size.height)*0.55; let r=CGRect(x:(size.width-d)/2,y:25,width:d,height:d); c.stroke(Path(ellipseIn:r),with:.color(.primary),lineWidth:3); c.draw(Text(String(format:"%.1f s",reading)).font(.title2.monospacedDigit().bold()),at:CGPoint(x:r.midX,y:r.midY)); c.draw(Text("Stopwatch").font(.headline),at:CGPoint(x:size.width/2,y:size.height-20)) }
    private func drawPipette(_ c: inout GraphicsContext, size: CGSize) { var p=Path(); p.move(to:CGPoint(x:size.width*0.45,y:35)); p.addLine(to:CGPoint(x:size.width*0.55,y:35)); p.addLine(to:CGPoint(x:size.width*0.62,y:size.height-40)); p.addLine(to:CGPoint(x:size.width*0.38,y:size.height-40)); p.closeSubpath(); c.stroke(p,with:.color(.blue),lineWidth:2); c.draw(Text("25.0 cm³ volumetric pipette").font(.headline),at:CGPoint(x:size.width/2,y:size.height-18)) }
}
