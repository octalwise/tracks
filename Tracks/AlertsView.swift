import Foundation
import SwiftUI

// alerts view
struct AlertsView: View {
    let alerts: [Alert]

    var body: some View {
        Grid {
            ForEach(
                Array(self.alerts.enumerated()),
                id: \.1.self
            ) { index, alert in
                if index > 0 {
                    Divider()
                }

                GridRow {
                    HStack {
                        // trimmed header
                        DisclosureGroup(alert.header) {
                            HStack {
                                // expanded description
                                VStack {
                                    Text(alert.header)

                                    if alert.description != nil {
                                        Text(alert.description!)
                                    }
                                }
                                .lineLimit(nil)

                                Spacer()
                            }
                        }
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    }.gridColumnAlignment(.leading)
                }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
            }
        }.padding(EdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0))
    }
}
