import SwiftUI

struct SeedEditorView: View {
  @Binding var seed: UInt64?
  @State private var input: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        Text("Seed")
        ZStack(alignment: .leading) {
          TextField("", text: $input)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .overlay(alignment: .trailing) {
              if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                  seed = nil
                  input = ""
                } label: {
                  Image(systemName: "x.circle.fill")
                    .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
              }
            }
          if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("nil")
              .font(.callout.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(
                Capsule()
                  .fill(Color.secondary.opacity(0.15))
              )
              .frame(maxWidth: .infinity)
              .foregroundStyle(.secondary)
              .padding(.leading, 6)
          }
        }
        .frame(maxWidth: .infinity)
      }
      HStack(spacing: 20) {
        Spacer()
        Button("Random Seed") {
          let value = UInt64.random(in: UInt64.min...UInt64.max)
          seed = value
          input = String(value)
        }
        Spacer()
      }
    }
    .onAppear {
      if let seed { input = String(seed) } else { input = "" }
    }
    .onChange(of: input) { _, newValue in
      let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        seed = nil
      } else if let value = UInt64(trimmed) {
        seed = value
      }
    }
  }
}

#Preview {
  @Previewable @State var seed1: UInt64? = nil
  @Previewable @State var seed2: UInt64? = 1234567890

  VStack(alignment: .leading) {
    SeedEditorView(seed: $seed1)
    SeedEditorView(seed: $seed2)
  }
  .padding()
}
