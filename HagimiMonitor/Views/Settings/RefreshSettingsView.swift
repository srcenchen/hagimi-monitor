import SwiftUI

/// 设置「刷新频率」:一个全局档位统一控制所有后台监控模块的采样间隔,
/// 取代此前只作用于系统功耗的单项设置。
struct RefreshSettingsView: View {
    @ObservedObject var settings: MonitorSettings

    var body: some View {
        SettingsPage {
            SettingsGroup(String(localized: "settings.refresh-interval.group")) {
                SettingsRow(
                    title: String(localized: "settings.refresh-interval"),
                    subtitle: String(localized: "settings.refresh-interval.subtitle")
                ) {
                    Picker(String(localized: "settings.refresh-interval"), selection: $settings.globalRefreshInterval) {
                        ForEach(GlobalRefreshInterval.allCases) { interval in
                            Text(interval.title).tag(interval)
                        }
                    }
                    .labelsHidden()
                    .compatibleTabPickerStyle()
                    .frame(width: 300)
                }
            }
        }
    }
}
