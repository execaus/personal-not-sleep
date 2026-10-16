import AppKit
import PersonalNotSleepCore
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        model.$reason.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateIcon() }
        }.store(in: &subscriptions)
        updateIcon()
    }

    private var subscriptions = Set<AnyCancellable>()

    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        let active = model.reason != .inactive
        button.image = NSImage(systemSymbolName: active ? "sun.max.fill" : "moon.zzz",
                               accessibilityDescription: model.stateText)
        button.toolTip = model.stateText
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        model.refresh()
        updateIcon()
        menu.removeAllItems()
        let status = NSMenuItem(title: model.stateText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())
        let manual = NSMenuItem(title: "Включить до выключения", action: #selector(startManual), keyEquivalent: "")
        manual.target = self
        menu.addItem(manual)
        let timer = NSMenuItem(title: "Включить на…", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for minutes in [15, 30, 60, 120] {
            let label = minutes < 60 ? "\(minutes) минут" : "\(minutes / 60) \(minutes == 60 ? "час" : "часа")"
            let item = NSMenuItem(title: label, action: #selector(startPreset(_:)), keyEquivalent: "")
            item.tag = minutes
            item.target = self
            submenu.addItem(item)
        }
        submenu.addItem(.separator())
        let custom = NSMenuItem(title: "Своя длительность…", action: #selector(openSettings), keyEquivalent: "")
        custom.target = self
        submenu.addItem(custom)
        menu.setSubmenu(submenu, for: timer)
        menu.addItem(timer)
        let stop = NSMenuItem(title: "Выключить", action: #selector(stop), keyEquivalent: "")
        stop.target = self
        stop.isEnabled = model.reason != .inactive
        menu.addItem(stop)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: "Расписание и настройки…", action: #selector(openSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        let quit = NSMenuItem(title: "Выход", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func startManual() { model.startManual(); updateIcon() }
    @objc private func startPreset(_ sender: NSMenuItem) { model.startTimer(minutes: sender.tag); updateIcon() }
    @objc private func stop() { model.stop(); updateIcon() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable],
                                  backing: .buffered, defer: false)
            window.title = "Personal Not Sleep"
            window.contentView = NSHostingView(rootView: SettingsView(model: model))
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

import Combine

@MainActor
private struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var customMinutes = "45"
    private let days: [(Int, String)] = [(2, "Пн"), (3, "Вт"), (4, "Ср"), (5, "Чт"),
                                         (6, "Пт"), (7, "Сб"), (1, "Вс")]

    var body: some View {
        Form {
            Section("Состояние") {
                Label(model.stateText, systemImage: model.reason == .inactive ? "moon.zzz" : "sun.max.fill")
                    .font(.headline)
                if let error = model.error { Text(error).foregroundStyle(.red) }
                HStack {
                    Button("Включить вручную") { model.startManual() }
                    Button("Выключить") { model.stop() }.disabled(model.reason == .inactive)
                }
            }
            Section("Таймер") {
                HStack {
                    TextField("Минуты", text: $customMinutes).frame(width: 90)
                    Button("Включить на указанное время") {
                        model.startTimer(minutes: Int(customMinutes) ?? 0)
                    }
                }
                Text("От 1 минуты до 7 дней. Пресеты 15, 30, 60 и 120 минут доступны в меню.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Повторяющееся расписание") {
                ForEach($model.rules) { $rule in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle("Активно", isOn: $rule.isEnabled)
                            Spacer()
                            Button("Удалить", role: .destructive) {
                                model.rules.removeAll { $0.id == rule.id }
                            }
                        }
                        HStack {
                            ForEach(days, id: \.0) { weekday, title in
                                Toggle(title, isOn: Binding(
                                    get: { rule.weekdays.contains(weekday) },
                                    set: { selected in
                                        if selected { rule.weekdays.insert(weekday) }
                                        else { rule.weekdays.remove(weekday) }
                                    }
                                )).toggleStyle(.button)
                            }
                        }
                        HStack {
                            Text("С")
                            timePicker(minute: $rule.startMinute)
                            Text("до")
                            timePicker(minute: $rule.endMinute)
                        }
                        if rule.startMinute == rule.endMinute || rule.weekdays.isEmpty {
                            Text("Выберите день и разные часы начала и конца.")
                                .font(.caption).foregroundStyle(.orange)
                        } else if rule.endMinute < rule.startMinute {
                            Text("Окончание — на следующий день.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                Button("Добавить интервал") {
                    model.rules.append(ScheduleRule(weekdays: [2, 3, 4, 5, 6],
                                                    startMinute: 9 * 60, endMinute: 18 * 60))
                }
            }
            Section("Запуск") {
                Toggle("Запускать при входе в macOS", isOn: $model.launchAtLogin)
                Text("Для работы расписания после перезагрузки войдите в свою учётную запись.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("Утилита предотвращает только простойный сон Mac и дисплея. Блокировка экрана, закрытая крышка и системные политики действуют как обычно.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(minWidth: 550, minHeight: 440)
    }

    private func timePicker(minute: Binding<Int>) -> some View {
        let date = Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: minute.wrappedValue / 60,
                                      minute: minute.wrappedValue % 60, second: 0, of: Date()) ?? Date()
            },
            set: { value in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
                minute.wrappedValue = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
        return DatePicker("", selection: date, displayedComponents: .hourAndMinute)
            .labelsHidden().frame(width: 95)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
