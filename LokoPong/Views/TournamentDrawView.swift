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
    @ObservedObject var viewModel: TournamentDrawViewModel
    @State private var presentingMatchDetails: MatchData? // Selected match for detail view
    
    // Gesture and navigation state
    @State private var dragOffsetX: CGFloat = 0 // Current drag gesture offset
    @State private var focusedColumnIndex: Int = 0 // Currently focused round
    @State private var scrollOffset: CGFloat = 0 // Precise scroll position
    @State private var scrollVelocity: CGFloat = 0
    
    // Initialize with a viewModel
    init(viewModel: TournamentDrawViewModel) {
        self.viewModel = viewModel
    }
    
    // For backward compatibility with existing code/previews
    init() {
        self.viewModel = TournamentDrawViewModel()
    }
    
    // Calculate horizontal scroll offset based on focused column and drag
    private var offsetX: CGFloat {
        let screenCenter = (UIScreen.main.bounds.width - columnWidth) / 2
        return scrollOffset + dragOffsetX + screenCenter
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading tournament data...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                ScrollViewReader { scrollViewProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        // Round selector at top of view
                        SelectedColumnIndicator(columnNames: viewModel.brackets.map({ bracket in bracket.name }),
                                                focusedColumnIndex: $focusedColumnIndex)
                        .id("scroll-to-top-anchor")
                        
                        // Horizontally scrollable bracket view
                        ScrollView(.horizontal, showsIndicators: false) {
                            columns
                                .offset(x: offsetX)
                        }
                        .frame(width: UIScreen.main.bounds.size.width)
                        .scrollDisabled(true)
                        .gesture(DragGesture(minimumDistance: 5, coordinateSpace: .global)
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
                    
                    // Coordinate all changes related to column changing in one place
                    .onChange(of: focusedColumnIndex) { newValue in
                        // Perform all related updates in a single animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            // 1. Update scroll offset
                            scrollOffset = -CGFloat(newValue) * columnWidth
                            
                            // 2. Scroll to top
                            scrollViewProxy.scrollTo("scroll-to-top-anchor", anchor: .top)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadTournamentData()
        }
    }
    
    // Layout for all tournament rounds
    private var columns: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<viewModel.brackets.count, id: \.self) { columnIndex in
                BracketColumnView(bracket: viewModel.brackets[columnIndex],
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
        viewModel.brackets.count
    }
    
    // Update drag gesture offset
    private func updateCurrentOffsetX(_ dragGestureValue: DragGesture.Value) {
        let newOffset = dragGestureValue.translation.width
        scrollVelocity = newOffset - dragOffsetX
        dragOffsetX = newOffset
    }
    
    // Handle end of drag gesture
    private func handleDragEnded(_ gestureValue: DragGesture.Value) {
        let velocityX = gestureValue.predictedEndLocation.x - gestureValue.location.x
        let isScrollingRight = gestureValue.translation.width < 0
        
        // Consider both distance and velocity for more natural feel
        let didScrollEnough = abs(gestureValue.translation.width) > columnWidth * 0.2 || 
                            abs(velocityX) > 10
        
        let isFirstColumn = focusedColumnIndex == 0
        let isLastColumn = focusedColumnIndex == numberOfColumns - 1
        
        // Determine new column index first
        var newColumnIndex = focusedColumnIndex
        if didScrollEnough {
            if isScrollingRight && !isLastColumn {
                newColumnIndex += 1
            } else if !isScrollingRight && !isFirstColumn {
                newColumnIndex -= 1
            }
        }
        
        // Apply changes in a single animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Reset drag offset
            dragOffsetX = 0
            
            // Update column index if needed
            if newColumnIndex != focusedColumnIndex {
                focusedColumnIndex = newColumnIndex
            }
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
        MatchData(team1: "Team 1", team2: "Team 2",
                 team1Players: ["Player 1A", "Player 1B"], 
                 team2Players: ["Player 2A", "Player 2B"]),
        MatchData(team1: "Team 3", team2: "Team 4",
                 team1Players: ["Player 3A", "Player 3B"], 
                 team2Players: ["Player 4A", "Player 4B"]),
        MatchData(team1: "Team 5", team2: "Team 6",
                 team1Players: ["Player 5A", "Player 5B"], 
                 team2Players: ["Player 6A", "Player 6B"]),
        MatchData(team1: "Team 7", team2: "Team 8",
                 team1Players: ["Player 7A", "Player 7B"], 
                 team2Players: ["Player 8A", "Player 8B"]),
        MatchData(team1: "Team 9", team2: "Team 10",
                 team1Players: ["Player 9A", "Player 9B"], 
                 team2Players: ["Player 10A", "Player 10B"]),
        MatchData(team1: "Team 11", team2: "Team 12",
                 team1Players: ["Player 11A", "Player 11B"], 
                 team2Players: ["Player 12A", "Player 12B"]),
        MatchData(team1: "Team 13", team2: "Team 14",
                 team1Players: ["Player 13A", "Player 13B"], 
                 team2Players: ["Player 14A", "Player 14B"]),
        MatchData(team1: "Team 15", team2: "Team 16",
                 team1Players: ["Player 15A", "Player 15B"], 
                 team2Players: ["Player 16A", "Player 16B"])
    ]),
    Bracket(name: "Quarter Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 4",
                 team1Players: ["Player 1A", "Player 1B"], 
                 team2Players: ["Player 4A", "Player 4B"]),
        MatchData(team1: "Team 5", team2: "Team 8",
                 team1Players: ["Player 5A", "Player 5B"], 
                 team2Players: ["Player 8A", "Player 8B"]),
        MatchData(team1: "Team 10", team2: "Team 11",
                 team1Players: ["Player 10A", "Player 10B"], 
                 team2Players: ["Player 11A", "Player 11B"]),
        MatchData(team1: "Team 13", team2: "Team 16",
                 team1Players: ["Player 13A", "Player 13B"], 
                 team2Players: ["Player 16A", "Player 16B"]),
    ]),
    Bracket(name: "Semi Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 8",
                 team1Players: ["Player 1A", "Player 1B"], 
                 team2Players: ["Player 8A", "Player 8B"]),
        MatchData(team1: "Team 10", team2: "Team 16",
                 team1Players: ["Player 10A", "Player 10B"], 
                 team2Players: ["Player 16A", "Player 16B"]),
    ]),
    Bracket(name: "Grand Finals", matches: [
        MatchData(team1: "Team 1", team2: "Team 16",
                 team1Players: ["Player 1A", "Player 1B"], 
                 team2Players: ["Player 16A", "Player 16B"])
    ])
]

// Preview provider for SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    @State static private var brackets: [Bracket] = sampleBrackets
    
    static var previews: some View {
        TournamentDrawView(viewModel: TournamentDrawViewModel(brackets: brackets))
    }
}
