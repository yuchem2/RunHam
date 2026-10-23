import Observation
import ServiceManagement

/// `SMAppService.mainApp` 등록 상태를 설정 창 토글에 연결한다.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled
    private(set) var errorMessage: String?

    func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
