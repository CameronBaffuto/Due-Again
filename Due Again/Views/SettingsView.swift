import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultReminderHour") private var defaultReminderHour = 9
    @AppStorage("defaultReminderMinute") private var defaultReminderMinute = 0
    @AppStorage("showArchivedInAll") private var showArchivedInAll = true

    @State private var reminderDate = Date()

    var body: some View {
        Form {
            Section("Notification Defaults") {
                DatePicker("Default time", selection: $reminderDate, displayedComponents: [.hourAndMinute])
                    .onAppear {
                        reminderDate = Calendar.current.date(from: DateComponents(hour: defaultReminderHour, minute: defaultReminderMinute)) ?? Date()
                    }
                    .onChange(of: reminderDate) { _, newValue in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        defaultReminderHour = components.hour ?? 9
                        defaultReminderMinute = components.minute ?? 0
                    }

                Text("Permission is requested only when a cadence has reminders enabled.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Preferences") {
                Toggle("Show archived in All", isOn: $showArchivedInAll)
            }

            Section("Data") {
                LabeledContent("Storage", value: "On this iPhone")
                LabeledContent("Sync", value: "Off")
                LabeledContent("Export", value: "Later")
            }
        }
        .navigationTitle("Settings")
    }
}
