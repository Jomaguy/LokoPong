//
//  EntryListView.swift
//  LokoPong
//
//  Created by Jonathan Mahrt Guyou on 4/23/25.
//

import SwiftUI

/**
 * EntryListView
 *
 * A view that displays the tournament entry list.
 * Currently shows a placeholder "Coming Soon" message.
 */
struct EntryListView: View {
    var body: some View {
        VStack {
            Spacer()
            
            Text("Coming Soon")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    EntryListView()
} 