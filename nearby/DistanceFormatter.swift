import Foundation

class DistanceFormatter: ObservableObject {
    @Published var useImperial = false
    
    func format(_ meters: Double) -> String {
        if useImperial {
            let feet = meters * 3.28084
            if feet >= 5280 {
                let miles = feet / 5280
                return String(format: "%.1f mi", miles)
            } else {
                return "\(Int(feet)) ft"
            }
        } else {
            if meters >= 1000 {
                let kilometers = meters / 1000
                return String(format: "%.1f km", kilometers)
            } else {
                return "\(Int(meters)) m"
            }
        }
    }
    
    func toggle() {
        useImperial.toggle()
    }
}
