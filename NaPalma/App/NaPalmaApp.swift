import SwiftUI
import SwiftData

@main
struct NaPalmaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLock.storageKey) private var lockEnabled = false
    @State private var lock = AppLock(locked: UserDefaults.standard.bool(forKey: AppLock.storageKey))

    private let container = Persistence.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .overlay {
                    if lock.isLocked {
                        LockView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: lock.isLocked)
                .environment(lock)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if lockEnabled { lock.isLocked = true }
            case .active:
                if lock.isLocked { Task { await lock.unlock() } }
            default:
                break
            }
        }
    }
}
