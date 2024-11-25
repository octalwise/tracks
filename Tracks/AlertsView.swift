import Foundation
import SwiftUI

// alerts view
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
            }
        }
        .padding(.top, 10)
        .padding([.bottom, .leading, .trailing], 15)
    }
}

// alert item
struct AlertItem: View {
    // alert
    let alert: Alert

    @State var expanded = false

    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.none) {
                    // toggle expanded alert
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
                        .offset(y: 2)

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
