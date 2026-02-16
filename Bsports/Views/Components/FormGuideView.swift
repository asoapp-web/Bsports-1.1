import SwiftUI

struct FormGuideView: View {
    let form: String?
    
    private var formLetters: [(String, Color)] {
        guard let form = form, !form.isEmpty else { return [] }
        let cleaned = form.replacingOccurrences(of: " ", with: "").uppercased()
        let letters: [String]
        if cleaned.contains(",") {
            letters = cleaned.split(separator: ",").map(String.init)
        } else {
            letters = cleaned.map { String($0) }
        }
        return letters.prefix(5).map { ($0, colorForLetter($0)) }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(formLetters.enumerated()), id: \.offset) { _, item in
                Text(item.0)
                    .font(.montserrat(.bold, size: 10))
                    .foregroundColor(.white)
                    .frame(width: 14, height: 14)
                    .background(item.1)
                    .cornerRadius(3)
            }
        }
    }
    
    private func colorForLetter(_ letter: String) -> Color {
        switch letter.uppercased() {
        case "W": return .fanSuccess
        case "D": return .fanWarning
        case "L": return .fanError
        default: return .fanGrayText
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        FormGuideView(form: "W,W,D,L,W")
        FormGuideView(form: "L,L,L,L,L")
        FormGuideView(form: nil)
    }
    .padding()
    .background(Color.fanBackground)
}
