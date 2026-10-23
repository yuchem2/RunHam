import QuartzCore

/// 배경색을 프레임 실루엣으로 마스킹해 메뉴바 글자색으로 러너를 그린다.
/// 원본 `RunnerLayer` 처럼 프레임은 `CAKeyframeAnimation(contents)` 로 돌리고,
/// 속도는 애니메이션을 다시 만들지 않고 레이어 시간계(speed/timeOffset/beginTime)만 바꾼다.
final class RunnerLayer: CALayer {
    private static let animationKey = "runner.frames"
    private let spriteLayer = CALayer()

    override init() {
        super.init()
        spriteLayer.contentsGravity = .resizeAspect
        mask = spriteLayer
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var tintColor: CGColor? {
        get { backgroundColor }
        set {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundColor = newValue
            CATransaction.commit()
        }
    }

    func setRunner(_ runner: Runner, flipped: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let size = runner.pointSize
        bounds = CGRect(origin: .zero, size: size)
        spriteLayer.removeAllAnimations()
        spriteLayer.frame = bounds
        spriteLayer.contentsScale = Runner.scale
        spriteLayer.contents = runner.frames.first
        spriteLayer.setAffineTransform(flipped ? CGAffineTransform(scaleX: -1, y: 1) : .identity)

        guard runner.frames.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = runner.frames
        animation.calculationMode = .discrete
        animation.duration = runner.cycleDuration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        spriteLayer.add(animation, forKey: Self.animationKey)
    }

    var runnerSpeed: Float { spriteLayer.speed }

    func setRunnerSpeed(_ speed: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let now = CACurrentMediaTime()
        spriteLayer.timeOffset = spriteLayer.convertTime(now, from: nil)
        spriteLayer.beginTime = now
        spriteLayer.speed = speed
    }
}
