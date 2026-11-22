import SwiftUI

struct LockView: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                Text("Na Palma is locked")
                    .font(.title2.bold())
                Text("Your financial data is protected.")
                    .foregroundStyle(.secondary)
                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label("Unlock", systemImage: AppLock.biometrySymbol)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
        .task { await lock.unlock() }
    }
}
