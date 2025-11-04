import SwiftUI

struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            configuration.isOn ? Color.accentColor : .secondary,
                            lineWidth: 1.5
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(configuration.isOn ? Color.accentColor : Color.clear)
                        )
                        .frame(width: 18, height: 18)

                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
