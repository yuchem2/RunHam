import CoreGraphics
import Foundation

/// 해바라기씨를 앞발로 들고 오물오물 먹는 햄스터(정면, 20×18pt, 6프레임). CPU 가 높을수록 빨리 오물거린다.
///
/// 투톤: 머리 위(모자처럼)와 몸 테두리는 짙고, 얼굴 아래쪽부터 배까지는 하얗다(구멍).
/// 하얀 얼굴 위에 짙은 구슬 눈·코·ω 입을 그리고, 하얀 배 앞에 흰 줄무늬가 있는 큰 씨를 두 앞발로 든다.
enum HamsterSnackSprite {
    static let canvas = CGSize(width: 20, height: 18)
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6
    static let frameCount = 6

    static func makeRunner() -> Runner {
        let frames = Array(0..<frameCount)
        return Runner(
            id: "hamster-snack",
            nameKey: "runner.hamsterSnack",
            frames: frames.map { render(frame: $0, scale: scale) },
            isPixelArt: false,
            previewFrames: frames.map { render(frame: $0, scale: previewScale) },
            // 6프레임에 두 번 오물거리고, 속도 1 에서 한 바퀴 1.5초
            baseFrameRate: 4
        )
    }

    struct Pose {
        /// 0 ~ 1. 볼이 부풀고 씨가 입으로 올라가는 정도
        var chew: CGFloat
        var earTwitch: CGFloat
    }

    static func pose(frame: Int) -> Pose {
        let phase = CGFloat(frame) / CGFloat(frameCount) * 2 * .pi
        // 한 바퀴에 두 번 오물오물
        return Pose(chew: (1 - cos(phase * 2)) / 2, earTwitch: frame == 4 ? 1 : 0)
    }

    static func render(frame: Int, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            draw(pose(frame: frame), in: context)
        }
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        context.setLineCap(.round)
        context.setLineJoin(.round)
        let x: CGFloat = 10
        let puff = 1 + pose.chew * 0.05
        let lift = pose.chew * 0.45

        // 짙은 바탕: 달걀형 몸과 머리, 귀
        context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 7.2), size: CGSize(width: 13.4 * puff, height: 14.0)))
        context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 11.4), size: CGSize(width: 12.6 * puff, height: 9.8)))
        HamsterShape.drawEar(at: CGPoint(x: x - 4.7, y: 14.8 + pose.earTwitch * 0.4), radius: 1.5, in: context)
        HamsterShape.drawEar(at: CGPoint(x: x + 4.7, y: 14.8), radius: 1.5, in: context)

        // 하얀 얼굴 아래쪽 + 배(구멍). 테두리와 머리 위는 짙게 남는다.
        context.setBlendMode(.clear)
        context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 10.5), size: CGSize(width: 10.0 * puff, height: 6.0)))
        context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 5.6), size: CGSize(width: 10.0, height: 9.6)))
        context.setBlendMode(.normal)

        // 하얀 얼굴 위의 짙은 구슬 눈(반짝이는 점), 코, ω 입
        for side: CGFloat in [-1, 1] {
            let eye = CGPoint(x: x + side * 2.7, y: 11.9)
            context.fillEllipse(in: CGRect(center: eye, size: CGSize(width: 1.8, height: 1.9)))
            context.setBlendMode(.clear)
            context.fillEllipse(in: CGRect(center: CGPoint(x: eye.x + 0.35, y: eye.y + 0.4), size: CGSize(width: 0.6, height: 0.6)))
            context.setBlendMode(.normal)
        }
        context.fillEllipse(in: CGRect(center: CGPoint(x: x, y: 10.6), size: CGSize(width: 1.1, height: 0.75)))
        context.setLineWidth(0.5)
        for side: CGFloat in [-1, 1] {
            // 씹을 때 입이 살짝 커진다
            context.addArc(center: CGPoint(x: x + side * 0.6, y: 10.1), radius: 0.6 + pose.chew * 0.12, startAngle: .pi * 1.1, endAngle: .pi * 1.9, clockwise: false)
            context.strokePath()
        }

        // 큰 해바라기씨(흰 줄무늬)와 씨를 잡은 작은 앞발
        let seed = CGPoint(x: x, y: 5.9 + lift)
        drawSeed(at: seed, tilt: (pose.chew - 0.5) * 8, in: context)
        context.setLineWidth(0.6)
        for side: CGFloat in [-1, 1] {
            let paw = CGPoint(x: x + side * 1.9, y: seed.y + 0.3)
            // 몸 옆에서 앞발로 이어지는 팔
            context.move(to: CGPoint(x: x + side * 4.9, y: 8.0))
            context.addQuadCurve(to: paw, control: CGPoint(x: x + side * 3.6, y: seed.y - 0.6))
            context.strokePath()
            context.fillEllipse(in: CGRect(center: paw, size: CGSize(width: 1.7, height: 1.6)))
        }

        // 작은 발
        for side: CGFloat in [-1, 1] {
            context.fillEllipse(in: CGRect(center: CGPoint(x: x + side * 3.0, y: 1.0), size: CGSize(width: 2.6, height: 1.6)))
        }
    }

    /// 아래가 둥글고 위가 뾰족한 씨. 흰 줄무늬는 구멍으로 뚫는다.
    private static func drawSeed(at center: CGPoint, tilt: CGFloat, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: tilt * .pi / 180)

        let width: CGFloat = 3.2
        let height: CGFloat = 5.6
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: height / 2))
        path.addCurve(to: CGPoint(x: 0, y: -height / 2), control1: CGPoint(x: width * 0.72, y: height * 0.2), control2: CGPoint(x: width * 0.62, y: -height / 2))
        path.addCurve(to: CGPoint(x: 0, y: height / 2), control1: CGPoint(x: -width * 0.62, y: -height / 2), control2: CGPoint(x: -width * 0.72, y: height * 0.2))
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()

        context.setBlendMode(.clear)
        context.setLineWidth(0.4)
        for offset: CGFloat in [-0.75, 0.75] {
            context.move(to: CGPoint(x: offset * 0.35, y: height / 2 - 0.9))
            context.addQuadCurve(to: CGPoint(x: offset * 0.6, y: -height / 2 + 0.7), control: CGPoint(x: offset * 1.3, y: 0))
        }
        context.strokePath()
        context.setBlendMode(.normal)
    }
}
