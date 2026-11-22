import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            EntriesView()
                .tabItem { Label("Transactions", systemImage: "list.bullet.rectangle.fill") }
            ChartsView()
                .tabItem { Label("Charts", systemImage: "chart.pie.fill") }
            PlanningView()
                .tabItem { Label("Planning", systemImage: "target") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task { RecurrenceEngine.run(in: context) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { RecurrenceEngine.run(in: context) }
        }
    }
}
