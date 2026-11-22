import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppLock.self) private var lock
    @AppStorage(AppLock.storageKey) private var lockEnabled = false
    @Query private var recurring: [RecurringItem]

    @State private var notificationsAllowed = false

    private var iCloudAvailable: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: lockBinding) {
                        Label("Lock with \(AppLock.biometryName)", systemImage: AppLock.biometrySymbol)
                    }
                    .disabled(!AppLock.canAuthenticate)
                } header: {
                    Text("Security")
                } footer: {
                    Text(AppLock.canAuthenticate
                         ? LocalizedStringKey("The app asks for authentication every time it's opened.")
                         : LocalizedStringKey("Set up a passcode on your iPhone to use this option."))
                }

                Section {
                    if notificationsAllowed {
                        Label("Bill reminders are on", systemImage: "bell.badge.fill")
                    } else {
                        Button {
                            Task {
                                notificationsAllowed = await BillReminders.requestAuthorization()
                                if notificationsAllowed { BillReminders.rescheduleAll(recurring) }
                            }
                        } label: {
                            Label("Turn on bill reminders", systemImage: "bell.fill")
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("If you denied notifications before, turn them on in the iPhone Settings app.")
                }

                Section {
                    if iCloudAvailable {
                        Label("Syncing with iCloud", systemImage: "checkmark.icloud.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("iCloud is off", systemImage: "xmark.icloud.fill")
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("iCloud")
                } footer: {
                    Text(iCloudAvailable
                         ? LocalizedStringKey("Your data is kept private in your iCloud account and syncs between your devices.")
                         : LocalizedStringKey("Sign in to iCloud in the iPhone Settings app to back up and sync your data. Meanwhile, everything is saved on this iPhone."))
                }

                Section {
                    LabeledContent("Currency", value: Currency.code)
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Language and currency follow your iPhone settings.")
                }
            }
            .navigationTitle("Settings")
            .task {
                notificationsAllowed = await BillReminders.isAuthorized()
                if notificationsAllowed { BillReminders.rescheduleAll(recurring) }
            }
        }
    }

    /// Asks for Face ID before turning the lock on or off.
    private var lockBinding: Binding<Bool> {
        Binding(
            get: { lockEnabled },
            set: { newValue in
                Task {
                    if await lock.authenticate(reason: String(localized: "Confirm to change the app lock")) {
                        lockEnabled = newValue
                    }
                }
            }
        )
    }
}
