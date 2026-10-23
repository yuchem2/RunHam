import Observation
import SwiftUI

/// 대시보드 맨 위 줄: 왼쪽은 앱 이름, 오른쪽은 햄버거 버튼.
/// 햄버거를 누르면 그 자리에 설정·활성 상태 보기·종료 아이콘이 펼쳐져, 마우스를 메뉴 아래까지 내리지 않아도 된다.
@MainActor
@Observable
final class DashboardHeaderModel {
    var isExpanded = false
    @ObservationIgnored var onSettings: () -> Void = {}
    @ObservationIgnored var onActivityMonitor: () -> Void = {}
    @ObservationIgnored var onQuit: () -> Void = {}
}

struct DashboardHeader: View {
    var model: DashboardHeaderModel

    var body: some View {
        HStack(spacing: 6) {
            Image(decorative: HamsterSymbol.image, scale: 1)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 18, height: 14)
                .foregroundStyle(.secondary)
            Text(L("app.name"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if model.isExpanded {
                HStack(spacing: 2) {
                    HeaderButton(symbol: "gearshape", title: L("menu.settings"), action: model.onSettings)
                    HeaderButton(symbol: "waveform.path.ecg.rectangle", title: L("menu.activityMonitor"), action: model.onActivityMonitor)
                    HeaderButton(symbol: "power", title: L("menu.quit"), action: model.onQuit)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            HeaderButton(symbol: model.isExpanded ? "xmark" : "line.3.horizontal", title: L("menu.more")) {
                withAnimation(.snappy(duration: 0.18)) { model.isExpanded.toggle() }
            }
        }
        .frame(height: 24)
    }
}

/// 둥근 배경이 깔리는 아이콘 버튼. 메뉴 안에서는 도움말 풍선이 잘 뜨지 않아 마우스를 올리면 배경으로 알려 준다.
private struct HeaderButton: View {
    var symbol: String
    var title: String
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 26, height: 22)
                .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.primary.opacity(0.1) : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .help(title)
        .accessibilityLabel(title)
        .onHover { isHovered = $0 }
    }
}
