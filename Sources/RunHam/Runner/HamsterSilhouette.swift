import CoreGraphics

/// RunHam 햄스터들이 함께 쓰는 옆모습 실루엣: 검은 몸에 하얀 눈 하나만 뚫는다.
///
/// 좌표는 포인트, 원점은 몸통 중심, x 는 앞쪽(오른쪽), y 는 위쪽.
/// 몸통·허벅지·머리·볼·귀를 겹친 타원으로 만들고, 다리는 끝이 둥근 짧은 막대 + 발 타원이다.
enum HamsterSilhouette {
    struct Pose {
        /// 몸 기울기(도). +는 머리가 위로 들린다.
        var pitch: CGFloat = 0
        /// 몸 길이 배율. 늘어나면 그만큼 납작해진다.
        var stretch: CGFloat = 1
        /// 바닥에서 뜬 높이
        var lift: CGFloat = 0
        /// 앞다리·뒷다리 각도(도). 0 은 수직 아래, + 는 앞쪽.
        var front: CGFloat = 0
        var hind: CGFloat = 0
        /// 뒷다리 길이 배율(웅크리면 짧고 박차면 길다)
        var hindReach: CGFloat = 1
        /// 머리를 몸과 따로 더 숙이거나(-) 드는(+) 각도
        var headTilt: CGFloat = 0
        /// 0 ~ 1. 볼주머니가 부푸는 정도
        var cheek: CGFloat = 0
        var showsLegs = true
        var eyesClosed = false
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineCap(.round)
        let s = pose.stretch
        context.concatenate(bodyTransform(pose))

        if pose.showsLegs {
            // 먼 쪽 앞다리는 몸 뒤에 가려진다
            leg(from: CGPoint(x: 4.0 * s, y: -2.0), angle: pose.front + 18, length: 2.8, width: 1.5, foot: CGSize(width: 1.7, height: 1.1), in: context)
        }
        fill(CGPoint(x: -6.1 * s, y: 1.0), CGSize(width: 1.8, height: 1.3), in: context)   // 짧은 꼬리
        fill(.zero, CGSize(width: 12 * s, height: 9.4 / s.squareRoot()), in: context)       // 몸통
        let thigh = CGPoint(x: -3.3 * s, y: -1.0)
        fill(thigh, CGSize(width: 5.4, height: 5.8), in: context)                           // 통통한 허벅지
        if pose.showsLegs {
            leg(from: CGPoint(x: thigh.x, y: thigh.y - 1.6), angle: pose.hind, length: 2.6 * pose.hindReach, width: 1.8, foot: CGSize(width: 3.0, height: 1.2), in: context)
            leg(from: CGPoint(x: 3.4 * s, y: -2.2), angle: pose.front, length: 3.0, width: 1.7, foot: CGSize(width: 1.9, height: 1.2), in: context)
        }

        context.concatenate(headTransform(pose).concatenating(bodyTransform(pose).inverted()))
        drawHead(cheek: pose.cheek, eyesClosed: pose.eyesClosed, in: context)
    }

    private static func bodyTransform(_ pose: Pose) -> CGAffineTransform {
        CGAffineTransform(translationX: 0, y: pose.lift).rotated(by: pose.pitch * .pi / 180)
    }

    /// 머리 중심 좌표계. 머리는 몸보다 덜 기울어 시선이 앞을 향한다.
    private static func headTransform(_ pose: Pose) -> CGAffineTransform {
        bodyTransform(pose)
            .translatedBy(x: 5.4 * pose.stretch, y: 1.4)
            .rotated(by: (-pose.pitch * 0.5 + pose.headTilt) * .pi / 180)
    }

    /// 머리 좌표계에서 눈 위치
    static let eye = CGPoint(x: 1.9, y: 0.8)

    /// 실루엣 좌표계(몸통 중심)에서 눈 위치. 아이콘처럼 눈을 따로 칠할 때 쓴다.
    static func eyeCenter(_ pose: Pose) -> CGPoint {
        eye.applying(headTransform(pose))
    }

    /// 머리 중심 기준. 다른 자세(앉아서 먹기 등)에서도 머리만 따로 쓴다.
    static func drawHead(cheek: CGFloat = 0, eyesClosed: Bool = false, in context: CGContext) {
        fill(CGPoint(x: 1.1, y: 4.0), CGSize(width: 1.9, height: 2.0), in: context)        // 먼 쪽 귀(작고 뒤에)
        fill(CGPoint(x: -1.5, y: 4.5), CGSize(width: 2.6, height: 2.7), in: context)       // 가까운 귀
        fill(.zero, CGSize(width: 8.6, height: 7.8), in: context)                           // 머리
        fill(CGPoint(x: 1.6, y: -2.2 - cheek * 0.4), CGSize(width: 4.6 + cheek * 1.6, height: 3.6 + cheek * 1.4), in: context)  // 볼주머니
        fill(CGPoint(x: 3.3, y: -0.9), CGSize(width: 3.2, height: 3.0), in: context)       // 동글한 주둥이
        fill(CGPoint(x: 4.8, y: -0.5), CGSize(width: 1.0, height: 1.0), in: context)       // 코끝

        context.saveGState()
        context.setBlendMode(.clear)
        if eyesClosed {
            // 감은 눈: 아래로 휜 짧은 흰 선
            context.setLineWidth(0.7)
            context.setLineCap(.round)
            context.addArc(center: CGPoint(x: 1.9, y: 1.5), radius: 1.0, startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
            context.strokePath()
        } else {
            fill(eye, CGSize(width: 1.35, height: 1.45), in: context)
        }
        context.restoreGState()
    }

    static func fill(_ center: CGPoint, _ size: CGSize, in context: CGContext) {
        context.fillEllipse(in: CGRect(center: center, size: size))
    }

    private static func leg(from hip: CGPoint, angle: CGFloat, length: CGFloat, width: CGFloat, foot: CGSize, in context: CGContext) {
        let end = hip.moved(angle: angle, length: length)
        context.setLineWidth(width)
        context.move(to: hip)
        context.addLine(to: end)
        context.strokePath()
        // 발끝이 앞을 향하도록 조금 앞으로 내민다
        let toe = CGPoint(x: 0, y: 0).moved(angle: angle, length: 0.3)
        fill(CGPoint(x: end.x + toe.x + 0.4, y: end.y), foot, in: context)
    }
}
