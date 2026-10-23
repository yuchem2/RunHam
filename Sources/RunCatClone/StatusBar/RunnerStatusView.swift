import AppKit

/// 상태바 버튼 위에 얹는 뷰. 러너 레이어와 (선택적으로) CPU 퍼센트 라벨을 배치한다.
@MainActor
final class RunnerStatusView: NSView {
    private static let padding: CGFloat = 4
    private static let labelGap: CGFloat = 3

    private let runnerLayer = RunnerLayer()
    private let label = NSTextField(labelWithString: "")
    private var runnerSize: CGSize = .zero

    var showsCPU = false {
        didSet {
            label.isHidden = !showsCPU
            needsLayout = true
        }
    }

    var cpuText: String = "" {
        didSet { label.stringValue = cpuText }
    }

    /// 상태 아이템 폭. 라벨 폭은 "100.0%" 기준으로 고정해 숫자가 바뀌어도 흔들리지 않게 한다.
    var preferredWidth: CGFloat {
        var width = Self.padding * 2 + runnerSize.width
        if showsCPU {
            width += Self.labelGap + ceil(("100.0%" as NSString).size(withAttributes: [.font: label.font!]).width)
        }
        return width
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(runnerLayer)
        label.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        label.textColor = .labelColor
        label.isHidden = true
        addSubview(label)
        updateTint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRunner(_ runner: Runner, flipped: Bool) {
        let speed = runnerLayer.runnerSpeed
        runnerSize = runner.pointSize
        runnerLayer.setRunner(runner, flipped: flipped)
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
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        runnerLayer.frame = CGRect(
            x: Self.padding,
            y: ((bounds.height - runnerSize.height) / 2).rounded(),
            width: runnerSize.width,
            height: runnerSize.height
        )
        CATransaction.commit()

        label.sizeToFit()
        label.frame.origin = CGPoint(
            x: Self.padding + runnerSize.width + Self.labelGap,
            y: ((bounds.height - label.frame.height) / 2).rounded()
        )
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateTint()
    }

    private func updateTint() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            runnerLayer.tintColor = NSColor.labelColor.cgColor
        }
    }
}
