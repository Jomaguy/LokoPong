//
//  SelectedColumnIndicator.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

/**
 * SelectedColumnIndicator
 *
 * A horizontal scrolling navigation component that indicates and controls
 * which tournament round (column) is currently in focus.
 *
 * Features:
 * - Horizontal scrollable list of tournament rounds
 * - Visual indication of selected round
 * - Automatic scrolling to selected round
 * - Interactive round selection
 */

import SwiftUICore
import SwiftUI

struct SelectedColumnIndicator: View {
    // Array of round names to display
    let columnNames: [String]
    
    // Binding to track which column is currently focused
    @Binding var focusedColumnIndex: Int
    
    var body: some View {
        // ScrollViewReader enables programmatic scrolling
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                scrollViewContent
            }
            
            // Automatically scroll when focused column changes
            .onChange(of: focusedColumnIndex) { newIndex in 
                // Non-animated scrolling to prevent animation conflicts
                scrollProxy.scrollTo(newIndex, anchor: .center)
            }
        }
    }

    // Horizontal layout of round indicators
    var scrollViewContent: some View {
        HStack(spacing: 24) {
            // Create an indicator button for each round
            ForEach(0..<columnNames.count, id: \.self) { columnIndex in
                indicator(for: columnIndex)
            }
        }
        .padding(24)
    }
    
    // Individual round indicator button
    private func indicator(for columnIndex: Int) -> some View {
        Button(action: { didTapColumnIndicator(at: columnIndex) }) {
            Text(columnNames[columnIndex].uppercased())
                .font(.system(size: 24))
                .bold()
                .foregroundColor(columnIndex == focusedColumnIndex ? .black : .gray)
                .id(columnIndex)  // ID needed for ScrollViewReader
        }
    }
    
    // Handle round selection
    private func didTapColumnIndicator(at index: Int) {
        // Use parent view's animation instead of local animation
        focusedColumnIndex = index
    }
}

// Preview provider for SwiftUI canvas
struct SelectedColumnIndicator_Previews: PreviewProvider {
    @State private static var focusedColumnIndex = 0
    
    static var previews: some View {
        SelectedColumnIndicator(columnNames: ["Eights", "Quarterfinals", "Semifinals", "Finals"], focusedColumnIndex: $focusedColumnIndex)
    }
}
