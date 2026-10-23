import CoreGraphics
import Foundation

/// RunHam 의 기본 러너: 원판형 쳇바퀴 안에서 쭉 뻗어 달리는 햄스터. 24×18pt 캔버스, 6프레임.
///
/// 넓은 바퀴 띠에 뚫은 발판 줄이 시계 방향으로 돌고, 바퀴 위 양옆에 흔들림 선이 깜빡여 제자리에서도 빠르게 도는 느낌을 준다.
/// 햄스터는 몸은 옆으로 달리고 얼굴은 해바라기씨 먹는 햄스터와 같은 정면 얼굴(짙은 모자, 하얀 얼굴, 구슬 눈, ω 입)로
/// 이쪽을 돌아본다. 아랫배는 하얗다.
/// 좌표는 포인트 단위, 원점은 왼쪽 아래, 햄스터는 오른쪽을 본다.
enum HamsterWheelSprite {
    static let canvas = CGSize(width: 24, height: 18)
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6
    static let frameCount = 6

    static func makeRunner() -> Runner {
        let frames = Array(0..<frameCount)
        return Runner(
            id: "hamster",
            nameKey: "runner.hamster",
            frames: frames.map { render(frame: $0, scale: scale) },
            isPixelArt: false,
            previewFrames: frames.map { render(frame: $0, scale: previewScale) },
            // 6프레임 한 바퀴가 속도 1 에서 2초
            baseFrameRate: 3
        )
    }

    // MARK: - 쳇바퀴

    static let wheelCenter = CGPoint(x: 12, y: 9.6)
    static let outerRadius: CGFloat = 8.3
    static let bandWidth: CGFloat = 2.3
    static let treadCount = 16
    /// 발판 줄 간격(22.5°)의 1/3 씩 돌려 6프레임이면 정확히 두 칸 → 끊김 없이 이어진다
    static var treadStep: CGFloat { 360 / CGFloat(treadCount) / 3 }

    // MARK: - 햄스터 자세

    struct Pose {
        var center: CGPoint
        var tilt: CGFloat
        /// 1 보다 크면 길게 늘어나고 납작해진다(쭉 뻗기), 작으면 웅크린다(모으기)
        var stretch: CGFloat
        /// 앞발·뒷발의 앞뒤 위치
        var front: CGFloat
        var hind: CGFloat
    }

    static func pose(frame: Int) -> Pose {
        let phase = CGFloat(frame) / CGFloat(frameCount) * 2 * .pi
        return Pose(
            // 발이 바퀴 띠(안쪽 바닥 y = 3.6)를 파고들지 않을 높이
            center: CGPoint(x: 11.8, y: 7.0 + abs(sin(phase)) * 0.5),
            tilt: sin(phase) * 3,
            stretch: 1 + cos(phase) * 0.08,
            // 뻗을 때 앞발은 앞으로·뒷발은 뒤로, 모을 때 배 밑으로
            front: cos(phase) * 1.4,
            hind: -cos(phase) * 1.4
        )
    }

    // MARK: - 그리기

    static func render(frame: Int, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            draw(frame: frame, in: context)
        }
    }

    static func draw(frame: Int, in context: CGContext) {
        context.setLineCap(.round)
        context.setLineJoin(.round)
        drawStand(in: context)
        drawWheel(rotation: -treadStep * CGFloat(frame), in: context)
        drawMotionMarks(frame: frame, in: context)

        let hamster = pose(frame: frame)
        // 바퀴 띠와 붙어 보이지 않게 햄스터 둘레를 비우고 그린다
        context.setBlendMode(.clear)
        drawHamster(hamster, outline: 0.6, in: context)
        context.setBlendMode(.normal)
        drawHamster(hamster, outline: 0, in: context)
    }

    /// 바퀴 양옆 기둥과 아래 가로대로 된 받침 틀
    private static func drawStand(in context: CGContext) {
        context.setLineWidth(1.2)
        context.move(to: CGPoint(x: 3.2, y: 10.2))
        context.addLine(to: CGPoint(x: 1.4, y: 0.7))
        context.addLine(to: CGPoint(x: 22.6, y: 0.7))
        context.addLine(to: CGPoint(x: 20.8, y: 10.2))
        context.strokePath()
    }

    /// 넓은 바퀴 띠 + 띠에 뚫은 발판 줄
    private static func drawWheel(rotation: CGFloat, in context: CGContext) {
        let c = wheelCenter
        let middle = outerRadius - bandWidth / 2
        context.setLineWidth(bandWidth)
        context.addEllipse(in: CGRect(center: c, size: CGSize(width: middle * 2, height: middle * 2)))
        context.strokePath()

        context.setBlendMode(.clear)
        context.setLineWidth(0.5)
        for index in 0..<treadCount {
            let angle = (rotation + CGFloat(index) * 360 / CGFloat(treadCount)) * .pi / 180
            let inner = outerRadius - bandWidth + 0.45
            let outer = outerRadius - 0.45
            context.move(to: CGPoint(x: c.x + cos(angle) * inner, y: c.y + sin(angle) * inner))
            context.addLine(to: CGPoint(x: c.x + cos(angle) * outer, y: c.y + sin(angle) * outer))
        }
        context.strokePath()
        context.setBlendMode(.normal)
    }

    /// 바퀴 위 양옆의 흔들림 선. 프레임마다 길이를 바꿔 깜빡이게 한다.
    private static func drawMotionMarks(frame: Int, in context: CGContext) {
        context.setLineWidth(0.7)
        let long = frame % 2 == 0
        for (angle, side) in [(CGFloat(140), CGFloat(1)), (CGFloat(40), CGFloat(-1))] {
            for offset in [CGFloat(-7), 7] {
                let radians = (angle + offset * side) * .pi / 180
                let start = outerRadius + 0.9
                let end = start + (long ? 1.5 : 0.9)
                context.move(to: CGPoint(x: wheelCenter.x + cos(radians) * start, y: wheelCenter.y + sin(radians) * start))
                context.addLine(to: CGPoint(x: wheelCenter.x + cos(radians) * end, y: wheelCenter.y + sin(radians) * end))
            }
        }
        context.strokePath()
    }

    static let headScale: CGFloat = 0.6

    /// outline > 0 이면 그만큼 둘레를 키운 실루엣만 그린다(비우기용).
    /// 몸은 옆으로 달리고, 머리는 먹는 햄스터와 같은 정면 얼굴로 이쪽을 돌아본다.
    private static func drawHamster(_ pose: Pose, outline: CGFloat, in context: CGContext) {
        let c = pose.center
        // 머리가 큰 2등신: 짧고 통통한 몸 앞쪽에 머리가 겹친다
        let bodyCenter = CGPoint(x: c.x - 1.4, y: c.y - 0.2)
        let bodySize = CGSize(width: 7.2 * pose.stretch + outline * 2, height: 5.4 / pose.stretch + outline * 2)
        let head = CGPoint(x: c.x + 2.2, y: c.y + 1.5 + pose.tilt * 0.06)
        let feet = [
            CGPoint(x: c.x + 1.8 + pose.front, y: c.y - 2.7 + max(0, pose.front) * 0.3),
            CGPoint(x: c.x - 3.6 + pose.hind, y: c.y - 2.7 + max(0, pose.hind) * 0.3),
        ]

        // 짧은 꼬리, 발, 옆으로 누운 몸
        context.fillEllipse(in: CGRect(center: CGPoint(x: bodyCenter.x - 3.7 * pose.stretch, y: c.y + 0.4), size: CGSize(width: 1.2 + outline * 2, height: 1.0 + outline * 2)))
        for foot in feet {
            context.fillEllipse(in: CGRect(center: foot, size: CGSize(width: 1.9 + outline * 2, height: 1.3 + outline * 2)))
        }
        context.fillEllipse(in: CGRect(center: bodyCenter, size: bodySize))

        guard outline == 0 else {
            HamsterShape.fillFrontHeadSilhouette(at: head, scale: headScale, inflate: outline, in: context)
            return
        }
        // 하얀 아랫배(구멍)와 테두리
        context.saveGState()
        context.addEllipse(in: CGRect(center: bodyCenter, size: bodySize))
        context.clip()
        context.setBlendMode(.clear)
        context.fillEllipse(in: CGRect(center: CGPoint(x: bodyCenter.x + 0.2, y: c.y - 2.3), size: CGSize(width: 4.8, height: 2.0)))
        context.restoreGState()
        context.setLineWidth(0.8)
        context.strokeEllipse(in: CGRect(center: bodyCenter, size: CGSize(width: bodySize.width - 0.8, height: bodySize.height - 0.8)))

        HamsterShape.drawFrontHead(at: head, scale: headScale, mouthOpen: abs(pose.tilt) / 3, in: context)
    }
}
