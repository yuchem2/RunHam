import QuartzCore

/// 배경색을 프레임 실루엣으로 마스킹해 메뉴바 글자색으로 러너를 그린다.
/// 색상 러너(isTemplate == false)는 마스크 없이 프레임 이미지를 그대로 보여 준다.
/// 프레임은 `CAKeyframeAnimation(contents)` 로 돌리고,
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

    private var isTemplate = true
    private var storedTint: CGColor?

    var tintColor: CGColor? {
        get { storedTint }
        set {
            storedTint = newValue
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            backgroundColor = isTemplate ? newValue : nil
            CATransaction.commit()
        }
    }

    /// zoom 이 1보다 크면(설정 창 미리보기) 고해상도 미리보기 프레임을 그 배율로 보여 준다.
    func setRunner(_ runner: Runner, flipped: Bool, zoom: CGFloat = 1) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        isTemplate = runner.isTemplate
        if runner.isTemplate {
            spriteLayer.removeFromSuperlayer()
            mask = spriteLayer
            backgroundColor = storedTint
        } else {
            mask = nil
            if spriteLayer.superlayer !== self { addSublayer(spriteLayer) }
            backgroundColor = nil
        }

        let frames = zoom > 1 ? runner.previewFrames : runner.frames
        let size = CGSize(width: runner.pointSize.width * zoom, height: runner.pointSize.height * zoom)
        bounds = CGRect(origin: .zero, size: size)
        spriteLayer.removeAllAnimations()
        spriteLayer.frame = bounds
        spriteLayer.contentsScale = CGFloat(frames.first?.width ?? 1) / max(size.width, 1)
        spriteLayer.contents = frames.first
        // 1x 외장 모니터 등에서 축소될 때: 도트는 픽셀을 지키고, 벡터는 부드럽게 줄인다.
        let filter: CALayerContentsFilter = runner.isPixelArt ? .nearest : .trilinear
        spriteLayer.magnificationFilter = filter
        spriteLayer.minificationFilter = filter
        spriteLayer.setAffineTransform(flipped ? CGAffineTransform(scaleX: -1, y: 1) : .identity)

        guard frames.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.calculationMode = .discrete
        animation.duration = runner.cycleDuration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        spriteLayer.add(animation, forKey: Self.animationKey)
    }

    var runnerSpeed: Float { spriteLayer.speed }

    func setRunnerSpeed(_ speed: Float) {
        spriteLayer.setAnimationSpeed(speed)
    }
}

extension CALayer {
    /// 걸려 있는 애니메이션을 다시 만들지 않고 위상을 유지한 채 속도만 바꾼다.
    func setAnimationSpeed(_ speed: Float) {
        guard self.speed != speed else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        let now = CACurrentMediaTime()
        timeOffset = convertTime(now, from: nil)
        beginTime = now
        self.speed = speed
    }
}
