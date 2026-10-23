import AppKit
import SwiftUI

/// 설정 창 미리보기 무대. 메뉴바와 같은 RunnerLayer(Core Animation)로 러너를 돌리고,
/// 바닥 점선도 CA 애니메이션으로 흘려 보낸다. SwiftUI 타임라인으로 매 프레임 다시 그리면
/// 설정 화면 전체가 매번 다시 배치돼 CPU 를 10% 넘게 써서 이렇게 바꿨다.
struct RunnerStageView: NSViewRepresentable {
    var runner: Runner
    var speed: Double
    var flipped: Bool

    func makeNSView(context: Context) -> RunnerStageNSView {
        RunnerStageNSView()
    }

    func updateNSView(_ view: RunnerStageNSView, context: Context) {
        view.configure(runner: runner, flipped: flipped)
        view.setSpeed(Float(speed))
    }
}

final class RunnerStageNSView: NSView {
    static let zoom: CGFloat = 3
    static let groundSpacing: CGFloat = 12
    static let groundInset: CGFloat = 14
    /// 속도 1 에서 바닥이 흐르는 속도(pt/s)
    static let groundSpeed: CGFloat = 18

    private let runnerLayer = RunnerLayer()
    private let groundTrack = CALayer()
    private let dots = CAReplicatorLayer()
    private let dot = CALayer()
    private var configured: (id: String, flipped: Bool, isTemplate: Bool)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
        dot.frame = CGRect(x: 0, y: 0, width: 3, height: 3)
        dots.addSublayer(dot)
        dots.instanceTransform = CATransform3DMakeTranslation(Self.groundSpacing, 0, 0)
        groundTrack.addSublayer(dots)
        layer?.addSublayer(groundTrack)
        layer?.addSublayer(runnerLayer)
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(runner: Runner, flipped: Bool) {
        guard configured?.id != runner.id || configured?.flipped != flipped || configured?.isTemplate != runner.isTemplate else { return }
        configured = (runner.id, flipped, runner.isTemplate)
        runnerLayer.setRunner(runner, flipped: flipped, zoom: Self.zoom)
        restartGround(flipped: flipped)
        needsLayout = true
    }

    func setSpeed(_ speed: Float) {
        runnerLayer.setRunnerSpeed(speed)
        groundTrack.setAnimationSpeed(speed)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        let size = runnerLayer.bounds.size
        runnerLayer.frame = CGRect(
            x: ((bounds.width - size.width) / 2).rounded(),
            y: Self.groundInset,
            width: size.width,
            height: size.height
        )
        dots.instanceCount = Int(bounds.width / Self.groundSpacing) + 3
        groundTrack.frame = CGRect(x: -Self.groundSpacing, y: Self.groundInset - 3, width: bounds.width + Self.groundSpacing * 2, height: 3)
        dots.frame = groundTrack.bounds
    }

    /// 점선 한 칸만큼 반복해서 옮겨 끊김 없이 흐르는 것처럼 보이게 한다. 러너 방향의 반대로 흐른다.
    private func restartGround(flipped: Bool) {
        groundTrack.removeAllAnimations()
        let animation = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
        animation.fromValue = 0
        animation.toValue = (flipped ? 1 : -1) * Self.groundSpacing
        animation.duration = CFTimeInterval(Self.groundSpacing / Self.groundSpeed)
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        groundTrack.add(animation, forKey: "ground")
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            runnerLayer.tintColor = NSColor.labelColor.cgColor
            dot.backgroundColor = NSColor.tertiaryLabelColor.cgColor
        }
    }
}
