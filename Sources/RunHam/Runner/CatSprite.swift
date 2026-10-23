import CoreGraphics

/// 고양이: 햄스터와 같은 검은 실루엣에 하얀 눈 하나. 뾰족한 귀와 긴 꼬리로 갤럽한다. 28×18pt, 8프레임.
/// 몸을 모았다가(웅크림) 앞발을 쭉 뻗어 날아오르고, 앞발부터 착지해 다시 모은다.
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

    static let poses: [Pose] = [
        Pose(pitch: 0, stretch: 0.92, lift: 0.3, front: -28, hind: 34, tail: 0.6),
        Pose(pitch: 8, stretch: 0.98, lift: 0.7, front: 6, hind: 14, tail: 0.3),
        Pose(pitch: 12, stretch: 1.08, lift: 1.4, front: 40, hind: -20, tail: 0),
        Pose(pitch: 3, stretch: 1.16, lift: 2.0, front: 62, hind: -52, tail: -0.3),
        Pose(pitch: -5, stretch: 1.14, lift: 1.7, front: 42, hind: -48, tail: -0.1),
        Pose(pitch: -10, stretch: 1.06, lift: 0.9, front: 8, hind: -26, tail: 0.3),
        Pose(pitch: -5, stretch: 0.98, lift: 0.4, front: -14, hind: 4, tail: 0.6),
        Pose(pitch: -1, stretch: 0.93, lift: 0.3, front: -26, hind: 26, tail: 0.7),
    ]

    static func makeRunner() -> Runner {
        // 8프레임 한 보폭이 속도 1 에서 2.5초
        DrawnRunner.make(id: "cat", nameKey: "runner.cat", width: 28, frameCount: poses.count, baseFrameRate: 3.2) { frame, context in
            // 뛰어오를 때 귀·꼬리가 잘리지 않게 조금 줄여 가운데 둔다
            context.translateBy(x: 14.8, y: 6.4)
            context.scaleBy(x: 0.9, y: 0.9)
            draw(poses[frame], in: context)
        }
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        let s = pose.stretch
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: 0, y: pose.lift)
        context.rotate(by: pose.pitch * .pi / 180)

        // 먼 쪽 다리(몸 뒤에 살짝 보인다)
        leg(from: CGPoint(x: 5.0 * s, y: -1.8), angle: pose.front + 16, length: 4.4, in: context)
        leg(from: CGPoint(x: -4.6 * s, y: -1.6), angle: pose.hind - 14, length: 4.2, in: context)

        // 긴 꼬리: 엉덩이에서 위로 휘어 올라간다
        let root = CGPoint(x: -6.6 * s, y: 1.0)
        context.saveGState()
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        context.move(to: root)
        context.addQuadCurve(to: CGPoint(x: root.x - 6.0, y: root.y + 2.4 + pose.tail * 3.2), control: CGPoint(x: root.x - 4.4, y: root.y - 1.6))
        context.strokePath()
        context.restoreGState()

        DrawnRunner.fill(.zero, CGSize(width: 14 * s, height: 7.2 / s.squareRoot()), in: context)          // 몸통
        DrawnRunner.fill(CGPoint(x: 4.4 * s, y: 0.4), CGSize(width: 6.6, height: 7.0), in: context)        // 가슴
        DrawnRunner.fill(CGPoint(x: -4.6 * s, y: 0.2), CGSize(width: 6.2, height: 6.8), in: context)       // 엉덩이

        leg(from: CGPoint(x: 4.4 * s, y: -2.2), angle: pose.front, length: 4.6, in: context)
        leg(from: CGPoint(x: -4.2 * s, y: -2.0), angle: pose.hind, length: 4.4, in: context)

        // 머리: 몸보다 덜 기울어 앞을 본다
        context.translateBy(x: 8.6 * s, y: 3.0)
        context.rotate(by: -pose.pitch * 0.5 * .pi / 180)
        DrawnRunner.polygon([CGPoint(x: -3.2, y: 1.6), CGPoint(x: -2.4, y: 5.6), CGPoint(x: -0.2, y: 2.8)], in: context)   // 먼 쪽 귀
        DrawnRunner.polygon([CGPoint(x: -0.6, y: 2.6), CGPoint(x: 1.2, y: 6.2), CGPoint(x: 2.8, y: 2.0)], in: context)    // 가까운 귀
        DrawnRunner.fill(.zero, CGSize(width: 7.2, height: 6.4), in: context)                                             // 둥근 머리
        DrawnRunner.fill(CGPoint(x: 3.0, y: -1.0), CGSize(width: 3.2, height: 2.8), in: context)                          // 주둥이
        DrawnRunner.eye(CGPoint(x: 1.5, y: 0.6), size: CGSize(width: 1.3, height: 1.5), in: context)
    }

    /// 가늘고 긴 다리와 작은 발
    private static func leg(from hip: CGPoint, angle: CGFloat, length: CGFloat, in context: CGContext) {
        let end = hip.moved(angle: angle, length: length)
        DrawnRunner.stroke([hip, end], width: 1.6, in: context)
        DrawnRunner.fill(CGPoint(x: end.x + 0.5, y: end.y), CGSize(width: 2.2, height: 1.2), in: context)
    }
}
