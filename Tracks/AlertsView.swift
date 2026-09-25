import Foundation
import SwiftUI

struct AlertsView: View {
    let alerts: [Alert]

    var body: some View {
        VStack {
            ForEach(
                Array(alerts.enumerated()),
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
        .animation(.easeInOut(duration: 0.3), value: alerts)
    }
}

struct AlertItem: View {
    let alert: Alert

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .padding(.trailing, 3)

            VStack {
                HStack {
                    // header
                    Text(alert.header)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }

                if alert.description != nil && !alert.description!.isEmpty {
                    HStack {
                        // description
                        Text(alert.description!)
                            .multilineTextAlignment(.leading)

                            Spacer()
                    }
                }
            }
        }.padding([.top, .bottom], 5)
    }
}
