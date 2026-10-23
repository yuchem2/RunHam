import CoreGraphics

/// 고양이: 날렵한 몸과 큰 뾰족 귀, 가는 다리, 뒤로 길게 흐르는 꼬리로 갤럽한다. 하얀 눈 하나. 30×18pt, 10프레임.
/// 몸을 모았다가(웅크림) 앞발을 쭉 뻗어 날아오르고, 앞발부터 착지해 다시 모은다.
/// 열쇠 자세 5개 사이를 이어 10프레임으로 부드럽게 움직이고, 도형 이음매는 다듬어 한 덩어리로 보이게 한다.
enum CatSprite {
    struct Pose {
        var pitch: CGFloat
        var stretch: CGFloat
        var lift: CGFloat
        /// 앞다리·뒷다리 각도(도). 0 은 수직 아래, + 는 앞쪽.
        var front: CGFloat
        var hind: CGFloat
        /// 꼬리 끝 높이(-1 아래 … 1 위)
        var tail: CGFloat
    }

    /// 회전 갤럽: 공중에서 쭉 뻗음 → 앞발 착지 → 네 발을 몸 아래로 모음 → 뒷발로 박참 → 다시 뻗으며 날아오름
    static let keyPoses: [Pose] = [
        Pose(pitch: 0, stretch: 1.2, lift: 1.8, front: 54, hind: -58, tail: 0.1),
        Pose(pitch: -7, stretch: 1.1, lift: 0.8, front: 28, hind: -58, tail: 0.3),
        Pose(pitch: -4, stretch: 0.9, lift: 0.3, front: -18, hind: 30, tail: 0.9),
        Pose(pitch: 8, stretch: 0.94, lift: 0.4, front: -8, hind: 12, tail: 0.6),
        Pose(pitch: 6, stretch: 1.1, lift: 1.3, front: 38, hind: -30, tail: 0.2),
    ]

    static let frameCount = 10

    /// 열쇠 자세 사이를 이은 frame 번째 자세
    static func pose(_ frame: Int) -> Pose {
        let position = CGFloat(frame) / CGFloat(frameCount) * CGFloat(keyPoses.count)
        let a = keyPoses[Int(position) % keyPoses.count], b = keyPoses[(Int(position) + 1) % keyPoses.count]
        let t = position - floor(position)
        func mix(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * t }
        return Pose(pitch: mix(a.pitch, b.pitch), stretch: mix(a.stretch, b.stretch), lift: mix(a.lift, b.lift),
                    front: mix(a.front, b.front), hind: mix(a.hind, b.hind), tail: mix(a.tail, b.tail))
    }

    static func makeRunner() -> Runner {
        // 한 보폭이 속도 1 에서 2.5초(RunCat 처럼 빠른 다리)
        DrawnRunner.make(
            id: "cat", nameKey: "runner.cat", width: 30, frameCount: frameCount, baseFrameRate: Double(frameCount) / 2.5,
            smoothing: 0.7,
            details: { frame, context in
                place(in: context)
                context.concatenate(headTransform(pose(frame)))
                DrawnRunner.eye(CGPoint(x: 1.6, y: 0.4), size: CGSize(width: 1.6, height: 1.8), in: context)
            },
            draw: { frame, context in
                place(in: context)
                draw(pose(frame), in: context)
            }
        )
    }

    /// 뛰어오를 때 귀·꼬리가 잘리지 않게 조금 줄여 가운데 둔다
    private static func place(in context: CGContext) {
        context.translateBy(x: 15.6, y: 6.8)
        context.scaleBy(x: 0.86, y: 0.86)
    }

    private static func bodyTransform(_ pose: Pose) -> CGAffineTransform {
        CGAffineTransform(translationX: 0, y: pose.lift).rotated(by: pose.pitch * .pi / 180)
    }

    /// 머리는 몸보다 덜 기울어 앞을 본다
    private static func headTransform(_ pose: Pose) -> CGAffineTransform {
        CGAffineTransform(translationX: 8.6 * pose.stretch, y: 3.6).rotated(by: -pose.pitch * 0.5 * .pi / 180).concatenating(bodyTransform(pose))
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        let s = pose.stretch
        context.saveGState()
        defer { context.restoreGState() }
        context.concatenate(bodyTransform(pose))

        // 먼 쪽 다리(몸 뒤에 살짝 보인다)
        leg(from: CGPoint(x: 5.0 * s, y: -1.2), angle: pose.front + 18, length: 4.6, in: context)
        leg(from: CGPoint(x: -4.6 * s, y: -1.2), angle: pose.hind - 18, length: 4.4, in: context)

        // 뒤로 길게 흐르는 꼬리: 엉덩이에서 굵게 시작해 끝으로 갈수록 가늘어진다. 몸을 모으면 위로 치켜든다
        let root = CGPoint(x: -5.6 * s, y: 1.2)
        DrawnRunner.taper(
            from: root,
            control1: CGPoint(x: root.x - 3.0, y: root.y + 1.2 + pose.tail * 0.6),
            control2: CGPoint(x: root.x - 6.4, y: root.y - 0.6 + pose.tail * 3.6),
            to: CGPoint(x: root.x - 9.4 + pose.tail * 2.4, y: root.y + 1.2 + pose.tail * 4.6),
            startWidth: 2.6, endWidth: 1.1, in: context
        )

        DrawnRunner.fill(.zero, CGSize(width: 14.4 * s, height: 4.8 / s.squareRoot()), in: context)        // 날렵한 몸통
        DrawnRunner.fill(CGPoint(x: -4.8 * s, y: 0.3), CGSize(width: 5.0, height: 5.2), in: context)       // 엉덩이
        DrawnRunner.fill(CGPoint(x: 4.4 * s, y: 0.4), CGSize(width: 5.2, height: 5.0), in: context)        // 가슴

        leg(from: CGPoint(x: 4.4 * s, y: -1.4), angle: pose.front, length: 5.0, in: context)
        leg(from: CGPoint(x: -4.4 * s, y: -1.4), angle: pose.hind, length: 4.8, in: context)

        // 앞으로 내민 목과 작은 머리, 크고 뾰족한 두 귀
        DrawnRunner.fill(CGPoint(x: 6.6 * s, y: 2.2), CGSize(width: 3.6, height: 4.4), rotated: -30, in: context)  // 목
        context.translateBy(x: 8.6 * s, y: 3.6)
        context.rotate(by: -pose.pitch * 0.5 * .pi / 180)
        DrawnRunner.polygon([CGPoint(x: -3.2, y: 1.2), CGPoint(x: -2.6, y: 6.6), CGPoint(x: -0.2, y: 2.8)], in: context)   // 뒤쪽 귀
        DrawnRunner.polygon([CGPoint(x: 0.4, y: 2.8), CGPoint(x: 2.4, y: 6.8), CGPoint(x: 3.4, y: 1.0)], in: context)     // 앞쪽 귀
        DrawnRunner.fill(.zero, CGSize(width: 7.6, height: 6.6), in: context)                                             // 머리
        DrawnRunner.fill(CGPoint(x: 3.0, y: -1.2), CGSize(width: 3.0, height: 2.6), in: context)                          // 주둥이
    }

    /// 몸에서 굵게 나와 발목으로 가늘어지는 다리와 작은 발
    private static func leg(from hip: CGPoint, angle: CGFloat, length: CGFloat, in context: CGContext) {
        let end = hip.moved(angle: angle, length: length)
        DrawnRunner.taper(from: hip, to: end, startWidth: 3.0, endWidth: 1.4, in: context)
        DrawnRunner.fill(CGPoint(x: end.x + 0.3, y: end.y), CGSize(width: 2.0, height: 1.4), in: context)
    }
}
