import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("시나리오", systemImage: "bubble.left.and.right.fill")
            }

            NavigationStack {
                MyPhrasesView()
            }
            .tabItem {
                Label("내 표현", systemImage: "text.book.closed.fill")
            }

            NavigationStack {
                KeyboardManageView()
            }
            .tabItem {
                Label("키보드", systemImage: "keyboard.fill")
            }
        }
    }
}
