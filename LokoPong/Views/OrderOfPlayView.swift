import SwiftUI

/**
 * OrderOfPlayView
 *
 * Displays the order of play for the tournament.
 * Shows scheduled matches with times and courts.
 */
struct OrderOfPlayView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "clock")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Order of Play")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Match schedules will be available once the tournament draw is finalized")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                
                Spacer()
            }
            .navigationTitle("Order of Play")
        }
    }
}

#Preview {
    OrderOfPlayView()
} 