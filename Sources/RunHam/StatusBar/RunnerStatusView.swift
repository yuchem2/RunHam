import AppKit

/// 상태바 버튼 위에 얹는 뷰. 러너 레이어와 (선택적으로) CPU 퍼센트 텍스트를 배치한다.
///
/// macOS 26 의 상태바는 다른 화면용 복제본(replicant)을 만들려고 버튼을 스냅샷하면서 외형을 바꾸는데,
/// 그 안에 NSTextField 같은 컨트롤이 있으면 외형 변경마다 다시 그려져 스냅샷이 끝없이 반복된다(CPU 40%+).
/// 그래서 서브뷰 없이 CALayer 만으로 그린다.
@MainActor
final class RunnerStatusView: NSView {
    private static let padding: CGFloat = 2
    private static let textGap: CGFloat = 3
    /// 기본 러너는 18pt 캔버스로 그려 두지만 메뉴바에선 작아 보여서 이 높이로 키운다.
    /// 커스텀 러너는 사용자가 넣은 PNG 높이(18pt) 그대로 둔다.
    private static let builtInHeight: CGFloat = 22
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)

    private let runnerLayer = RunnerLayer()
    private let textLayer = CATextLayer()
    private var runnerSize: CGSize = .zero

    var showsCPU = false {
        didSet {
            guard showsCPU != oldValue else { return }
            withoutActions { textLayer.isHidden = !showsCPU }
            needsLayout = true
        }
    }

    var cpuText: String = "" {
        didSet {
            guard cpuText != oldValue else { return }
            withoutActions { textLayer.string = cpuText }
        }
    }

    /// 상태 아이템 폭. 텍스트 폭은 "100.0%" 기준으로 고정해 숫자가 바뀌어도 흔들리지 않게 한다.
    var preferredWidth: CGFloat {
        var width = Self.padding * 2 + runnerSize.width
        if showsCPU {
            width += Self.textGap + Self.textSize.width
        }
        return width
    }

    private static var textSize: CGSize {
        let size = ("100.0%" as NSString).size(withAttributes: [.font: font])
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(runnerLayer)

        textLayer.font = Self.font
        textLayer.fontSize = Self.font.pointSize
        textLayer.alignmentMode = .left
        textLayer.isHidden = true
        layer?.addSublayer(textLayer)
        updateTint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRunner(_ runner: Runner, flipped: Bool) {
        let speed = runnerLayer.runnerSpeed
        let zoom = runner.isCustom ? 1 : Self.builtInHeight / max(runner.pointSize.height, 1)
        runnerSize = CGSize(width: runner.pointSize.width * zoom, height: runner.pointSize.height * zoom)
        // zoom 이 1보다 크면 고해상도 미리보기 프레임을 줄여 그려서 키워도 흐려지지 않는다.
        runnerLayer.setRunner(runner, flipped: flipped, zoom: zoom)
        runnerLayer.setRunnerSpeed(speed)
        needsLayout = true
    }

    func setSpeed(_ speed: Float) {
        runnerLayer.setRunnerSpeed(speed)
    }

    // 클릭은 아래의 상태바 버튼이 받도록 통과시킨다.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        let runnerFrame = CGRect(
            x: Self.padding,
            y: ((bounds.height - runnerSize.height) / 2).rounded(),
            width: runnerSize.width,
            height: runnerSize.height
        )
        let textSize = Self.textSize
        let textFrame = CGRect(
            x: Self.padding + runnerSize.width + Self.textGap,
            y: ((bounds.height - textSize.height) / 2).rounded(),
            width: textSize.width,
            height: textSize.height
        )
        withoutActions {
            if runnerLayer.frame != runnerFrame { runnerLayer.frame = runnerFrame }
            if textLayer.frame != textFrame { textLayer.frame = textFrame }
        }
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        let scale = window?.backingScaleFactor ?? 2
        withoutActions { textLayer.contentsScale = scale }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateTint()
    }

    private func updateTint() {
        var color: CGColor?
        effectiveAppearance.performAsCurrentDrawingAppearance {
            color = NSColor.labelColor.cgColor
        }
        guard let color, runnerLayer.tintColor != color else { return }
        runnerLayer.tintColor = color
        withoutActions { textLayer.foregroundColor = color }
    }

    private func withoutActions(_ body: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        body()
        CATransaction.commit()
    }
}
