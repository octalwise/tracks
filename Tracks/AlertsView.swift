import Foundation
import SwiftUI

struct AlertsView: View {
    let alerts: [Alert]

    var body: some View {
        VStack {
            ForEach(
                Array(self.alerts.enumerated()),
                id: \.1.self
            ) { index, alert in
                if index > 0 {
                    Divider()
                }

                AlertItem(alert: alert)
                    .padding([.leading, .trailing], 20)
                    .transition(.opacity)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 15)
        .animation(.easeInOut(duration: 0.3), value: self.alerts)
    }
}

struct AlertItem: View {
    let alert: Alert

    @State var expanded = false

    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.none) {
                    expanded = !expanded
                }
            }) {
                // header
                Text(self.alert.header)
                    .lineLimit(expanded ? nil : 1)
                    .multilineTextAlignment(.leading)

                Spacer()

                VStack {
                    Image(systemName:  "chevron.right")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .animation(.linear(duration: 0.25), value: expanded)
                        .offset(y: 4)

                    Spacer()
                }
            }

            if self.alert.description != nil && !self.alert.description!.isEmpty && expanded {
                // description
                HStack {
                    Text(self.alert.description!)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
            }
        }.padding([.top, .bottom], 5)
    }
}
