import SwiftUI
import FirebaseFirestore

/**
 * TournamentDrawView
 *
 * The main tournament bracket view that displays all rounds and matches.
 * Provides horizontal scrolling navigation between tournament rounds with
 * gesture-based interactions and animations.
 *
 * Features:
 * - Horizontal scrolling between tournament rounds
 * - Gesture-based navigation
 * - Match detail modal presentation
 * - Automatic scrolling to top when changing rounds
 * - Responsive layout based on screen size
 */

struct TournamentDrawView: View {
    // Layout and data properties
    private let columnWidth: CGFloat = UIScreen.main.bounds.width * 0.9
    let brackets: [Bracket] // Tournament rounds data
    @State private var presentingMatchDetails: MatchData? // Selected match for detail view
    
    // Gesture and navigation state
    @State private var dragOffsetX: CGFloat = 0 // Current drag gesture offset
    @State private var focusedColumnIndex: Int = 0 // Currently focused round
    @State private var scrollOffset: CGFloat = 0 // Precise scroll position
    
    // Calculate horizontal scroll offset based on focused column and drag
    private var offsetX: CGFloat {
        let screenCenter = (UIScreen.main.bounds.width - columnWidth) / 2
        return scrollOffset + dragOffsetX + screenCenter
    }
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView(.vertical, showsIndicators: false) {
                // Round selector at top of view
                SelectedColumnIndicator(columnNames: brackets.map({ bracket in bracket.name }),
                                      focusedColumnIndex: $focusedColumnIndex)
                    .id("scroll-to-top-anchor")
                
                // Horizontally scrollable bracket view
                ScrollView(.horizontal, showsIndicators: false) {
                    columns
                        .offset(x: offsetX)
                }
                .frame(width: UIScreen.main.bounds.size.width)
                .scrollDisabled(true)
                .gesture(DragGesture(minimumDistance: 12, coordinateSpace: .global)
                    .onChanged(updateCurrentOffsetX)
                    .onEnded(handleDragEnded)
                )
            }
            
            // Match details modal presentation
            .sheet(item: $presentingMatchDetails, onDismiss: { presentingMatchDetails = nil }) { details in
                MatchDetailsView(matchData: details)
                    .padding(.horizontal)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            // Scroll to top when changing rounds
            .onChange(of: focusedColumnIndex) { _ in
                withAnimation {
                    scrollViewProxy.scrollTo("scroll-to-top-anchor")
                }
            }
            // Update scroll offset when focusedColumnIndex changes
            .onChange(of: focusedColumnIndex) { newValue in
                updateScrollOffset(newValue)
            }
            .onAppear {
                // Set initial scroll offset
                updateScrollOffset(focusedColumnIndex)
            }
        }
    }
    
    // Layout for all tournament rounds
    private var columns: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<brackets.count, id: \.self) { columnIndex in
                BracketColumnView(bracket: brackets[columnIndex],
                                columnIndex: columnIndex,
                                focusedColumnIndex: focusedColumnIndex,
                                lastColumnIndex: numberOfColumns - 1,
                                didTapCell: { matchData in presentingMatchDetails = matchData }
                )
                .frame(width: columnWidth)
            }
        }
        .frame(width: CGFloat(numberOfColumns) * columnWidth)
    }
    
    // Total number of tournament rounds
    private var numberOfColumns: Int {
        brackets.count
    }
    
    // Update scroll offset based on focused column index
    private func updateScrollOffset(_ columnIndex: Int) {
        withAnimation(.easeInOut) {
            scrollOffset = -CGFloat(columnIndex) * columnWidth
        }
    }
    
    // Update drag gesture offset
    private func updateCurrentOffsetX(_ dragGestureValue: DragGesture.Value) {
        dragOffsetX = dragGestureValue.translation.width
    }
    
    // Handle end of drag gesture
    private func handleDragEnded(_ gestureValue: DragGesture.Value) {
        let isScrollingRight = gestureValue.translation.width < 0
        let didScrollEnough = abs(gestureValue.translation.width) > columnWidth * 0.3
        let isFirstColumn = focusedColumnIndex == 0
        let isLastColumn = focusedColumnIndex == numberOfColumns - 1
        
        withAnimation(.easeInOut) {
            if didScrollEnough {
                if isScrollingRight && !isLastColumn {
                    focusedColumnIndex += 1
                } else if !isScrollingRight && !isFirstColumn {
                    focusedColumnIndex -= 1
                }
            }
            // Always reset drag offset when gesture ends
            dragOffsetX = 0
        }
    }
    
    // Navigation helpers
    private func moveToLeft() {
        if focusedColumnIndex > 0 {
            focusedColumnIndex -= 1
        }
    }
    
    private func moveToRight() {
        if focusedColumnIndex < numberOfColumns - 1 {
            focusedColumnIndex += 1
        }
    }
}

// Sample data for development and preview
let sampleBrackets: [Bracket] = [
    Bracket(name: "Eights", matches: [
        MatchData(team1: "Team 1", team2: "Team 2", team1Score: 3, team2Score: 0),
        MatchData(team1: "Team 3", team2: "Team 4", team1Score: 1, team2Score: 2),
        MatchData(team1: "Team 5", team2: "Team 6", team1Score: 2, team2Score: 0),
        MatchData(team1: "Team 7", team2: "Team 8", team1Score: 0, team2Score: 3),
        MatchData(team1: "Team 9", team2: "Team 10", team1Score: 1, team2Score: 2),
        MatchData(team1: "Team 11", team2: "Team 12", team1Score: 3, team2Score: 1),
        MatchData(team1: "Team 13", team2: "Team 14", team1Score: 2, team2Score: 0),
        MatchData(team1: "Team 15", team2: "Team 16", team1Score: 1, team2Score: 2)
    ]),
    Bracket(name: "Quarter Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 4", team1Score: 3, team2Score: 0),
        MatchData(team1: "Team 5", team2: "Team 8", team1Score: 1, team2Score: 2),
        MatchData(team1: "Team 10", team2: "Team 11", team1Score: 2, team2Score: 0),
        MatchData(team1: "Team 13", team2: "Team 16", team1Score: 0, team2Score: 3),
    ]),
    Bracket(name: "Semi Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 8", team1Score: 3, team2Score: 0),
        MatchData(team1: "Team 10", team2: "Team 16", team1Score: 1, team2Score: 2),
    ]),
    Bracket(name: "Grand Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 16", team1Score: 1, team2Score: 2)
    ])
]

// Preview provider for SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    @State static private var brackets: [Bracket] = sampleBrackets
    
    static var previews: some View {
        TournamentDrawView(brackets: brackets)
    }
}
