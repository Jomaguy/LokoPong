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
 * - Only displays approved teams in the tournament (approved by admin)
 * - Future rounds display TBD until winners are determined
 */

struct TournamentDrawView: View {
    // Layout and data properties
    private let columnWidth: CGFloat = UIScreen.main.bounds.width * 0.9
    @ObservedObject var viewModel: TournamentDrawViewModel
    
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
                VStack(spacing: 20) {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if errorMessage.contains("No approved teams") {
                        Text("Teams must be approved by an administrator before they can participate in the tournament.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Image(systemName: "person.2.badge.gearshape")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
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
                    
                    // Coordinate all changes related to column changing in one place
                    .onChange(of: focusedColumnIndex) { newValue in
                        // Use easeInOut animation instead of spring for more stable timing
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                                lastColumnIndex: numberOfColumns - 1)
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
        
        // Apply changes with easeInOut animation
        withAnimation(.easeInOut(duration: 0.3)) {
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

// MatchView - Displays a single match with TBD support
struct MatchView: View {
    let match: MatchData
    let isFirstRound: Bool
    let isTBD: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Team 1
            teamRow(name: match.team1, players: match.team1Players, score: match.team1Score)
            
            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3))
            
            // Team 2
            teamRow(name: match.team2, players: match.team2Players, score: match.team2Score)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .opacity(isTBD ? 0.5 : 1.0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .opacity(isTBD ? 0.7 : 1.0)
    }
    
    private func teamRow(name: String, players: [String], score: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: name == "TBD" ? .regular : .bold))
                    .foregroundColor(name == "TBD" ? .gray : .primary)
                
                if !players.isEmpty && name != "TBD" {
                    Text(players.joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Show score only for non-TBD matches
            if !isTBD {
                Text("\(score)")
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
}

// Preview provider for SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Create minimal sample data for preview
        let previewBrackets: [Bracket] = [
            Bracket(name: "Eights", matches: [
                MatchData(team1: "Team 1", team2: "Team 2",
                         team1Players: ["Player 1A"], team2Players: ["Player 2A"],
                         uniqueId: "match1"),
                MatchData(team1: "Team 3", team2: "Team 4",
                         team1Players: ["Player 3A"], team2Players: ["Player 4A"],
                         uniqueId: "match2")
            ]),
            Bracket(name: "Semi Finals", matches: [
                MatchData(team1: "Team 1", team2: "Team 4",
                         team1Players: ["Player 1A"], team2Players: ["Player 4A"],
                         uniqueId: "match3")
            ])
        ]
        
        return TournamentDrawView(viewModel: TournamentDrawViewModel(brackets: previewBrackets))
    }
}
