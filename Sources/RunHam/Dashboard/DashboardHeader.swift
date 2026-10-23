import Observation
import SwiftUI

/// 대시보드 맨 위 줄(앱 이름 + 햄버거 버튼)과, 햄버거를 누르면 그 아래로 펼쳐지는 옵션 목록.
/// 마우스를 메뉴 아래까지 내리지 않아도 되고, 항목은 `items` 에 더하기만 하면 늘어난다.
@MainActor
@Observable
final class DashboardHeaderModel {
    struct Item: Identifiable {
        var id: String { titleKey }
        var symbol: String
        var titleKey: String
        /// 오른쪽에 흐리게 보여 줄 단축키(⌘, 등)
        var shortcut: String?
        /// 위에 구분선을 긋는다(종료처럼 성격이 다른 항목)
        var startsGroup = false
        var action: () -> Void
    }

    var isExpanded = false
    @ObservationIgnored var items: [Item] = []
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
            Button {
                withAnimation(.snappy(duration: 0.15)) { model.isExpanded.toggle() }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 26, height: 22)
                    .background(RoundedRectangle(cornerRadius: 6).fill(model.isExpanded ? Color.primary.opacity(0.12) : .clear))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L("menu.more"))
        }
        .frame(height: 24)
    }
}

/// 햄버거 아래로 펼쳐지는 옵션 목록. 대시보드 카드 위에 겹쳐 뜬다.
struct DashboardOptionsPanel: View {
    var model: DashboardHeaderModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.items) { item in
                if item.startsGroup {
                    Divider().padding(.vertical, 4).padding(.horizontal, 6)
                }
                OptionRow(item: item)
            }
        }
        .padding(5)
        .frame(width: 200)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.primary.opacity(0.12)))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
    }
}

/// 메뉴 항목처럼 마우스를 올리면 강조색으로 칠해지는 한 줄
private struct OptionRow: View {
    var item: DashboardHeaderModel.Item
    @State private var isHovered = false

    var body: some View {
        Button(action: item.action) {
            HStack(spacing: 8) {
                Image(systemName: item.symbol)
                    .frame(width: 18)
                Text(L(item.titleKey))
                Spacer()
                if let shortcut = item.shortcut {
                    Text(shortcut)
                        .foregroundStyle(isHovered ? Color.white.opacity(0.8) : Color.secondary)
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(isHovered ? Color.white : Color.primary)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 5).fill(isHovered ? Color.accentColor : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
