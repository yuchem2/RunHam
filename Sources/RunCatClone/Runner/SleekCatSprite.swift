import CoreGraphics
import Foundation

/// 옆모습으로 그린 날렵한 고양이 러너(기본). 28×18pt 캔버스를 안티앨리어싱해 렌더링한다.
///
/// 몸통·목·머리는 곡선 하나로 이은 실루엣이고, 다리는 위(어깨·허벅지)가 굵고 아래로 갈수록 가늘어지는
/// 마디로 그린다. 프레임은 ChubbyCatSprite 와 같은 방식으로 뼈대 자세 값으로 정의한다.
/// 좌표는 포인트 단위, 원점은 왼쪽 아래(지면), 고양이는 오른쪽(+x)을 본다.
enum SleekCatSprite {
    static let canvas = CGSize(width: 28, height: 18)
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6

    static func makeRunner() -> Runner {
        Runner(
            id: "cat",
            nameKey: "runner.cat",
            frames: gallop.map { render($0, scale: scale) },
            isPixelArt: false,
            previewFrames: gallop.map { render($0, scale: previewScale) }
        )
    }

    // MARK: - 자세

    /// 각도는 수직 아래 기준(도), 양수면 앞(+x). lower 는 무릎 아래의 절대 각도.
    struct Limb {
        var upper: CGFloat
        var lower: CGFloat
    }

    struct Pose {
        var bob: CGFloat
        /// 양수면 머리가 올라간다
        var tilt: CGFloat
        /// 꼬리를 세운 정도(0 낮게 ~ 1 높이 말아 올림)
        var tail: CGFloat
        var frontNear: Limb
        var frontFar: Limb
        var hindNear: Limb
        var hindFar: Limb
    }

    static let gallop: [Pose] = [
        // 쭉 뻗기
        Pose(bob: 0.6, tilt: 0, tail: 0.4,
             frontNear: Limb(upper: 40, lower: 60), frontFar: Limb(upper: 30, lower: 48),
             hindNear: Limb(upper: -34, lower: -58), hindFar: Limb(upper: -22, lower: -44)),
        // 앞발 착지
        Pose(bob: 0.1, tilt: -2.5, tail: 0.7,
             frontNear: Limb(upper: 12, lower: 2), frontFar: Limb(upper: 30, lower: 45),
             hindNear: Limb(upper: -15, lower: -35), hindFar: Limb(upper: -35, lower: -65)),
        // 모으기
        Pose(bob: 0.6, tilt: 0, tail: 0.9,
             frontNear: Limb(upper: -18, lower: -50), frontFar: Limb(upper: -8, lower: -35),
             hindNear: Limb(upper: 30, lower: -15), hindFar: Limb(upper: 18, lower: -25)),
        // 뒷발 착지
        Pose(bob: 0.2, tilt: 2.5, tail: 0.7,
             frontNear: Limb(upper: 25, lower: 70), frontFar: Limb(upper: 12, lower: 45),
             hindNear: Limb(upper: 8, lower: -12), hindFar: Limb(upper: -10, lower: -25)),
        // 박차기
        Pose(bob: 0.5, tilt: 1.5, tail: 0.5,
             frontNear: Limb(upper: 34, lower: 40), frontFar: Limb(upper: 24, lower: 30),
             hindNear: Limb(upper: -26, lower: -50), hindFar: Limb(upper: -12, lower: -34)),
    ]

    // MARK: - 비율

    static let pivot = CGPoint(x: 14.0, y: 9.4)
    static let shoulder = (near: CGPoint(x: 17.6, y: 8.6), far: CGPoint(x: 16.6, y: 8.8))
    static let hip = (near: CGPoint(x: 8.6, y: 9.0), far: CGPoint(x: 9.8, y: 9.2))
    /// 앞다리: 위팔 / 아래팔 길이와 굵기(위 → 아래)
    static let front = (upper: CGFloat(3.4), lower: CGFloat(3.8), widths: (CGFloat(2.6), CGFloat(1.6), CGFloat(1.3)))
    /// 뒷다리: 허벅지가 굵고 정강이는 가늘다
    static let hind = (upper: CGFloat(3.2), lower: CGFloat(4.4), widths: (CGFloat(3.4), CGFloat(1.7), CGFloat(1.3)))
    static let farLegAlpha: CGFloat = 0.5
    /// 귀 끝·발끝이 들썩임과 기울기까지 캔버스 안에 들어오도록 살짝 줄인다.
    static let fit = CGAffineTransform(translationX: 1.0, y: 0.1).scaledBy(x: 0.95, y: 0.95)

    // MARK: - 그리기

    static func render(_ pose: Pose, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            context.concatenate(fit)
            draw(pose, in: context)
        }
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let lift = CGAffineTransform(translationX: 0, y: pose.bob)
        let center = pivot.applying(lift)
        let place = lift.concatenating(
            CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: pose.tilt * .pi / 180)
                .translatedBy(x: -center.x, y: -center.y)
        )

        context.setAlpha(farLegAlpha)
        drawLeg(from: shoulder.far.applying(place), pose.frontFar, lengths: (front.upper, front.lower), widths: front.widths, in: context)
        drawLeg(from: hip.far.applying(place), pose.hindFar, lengths: (hind.upper, hind.lower), widths: hind.widths, in: context)
        context.setAlpha(1)

        context.saveGState()
        context.concatenate(place)
        drawTail(raise: pose.tail, in: context)
        context.addPath(silhouette)
        context.fillPath()
        drawEars(in: context)
        context.restoreGState()

        drawLeg(from: shoulder.near.applying(place), pose.frontNear, lengths: (front.upper, front.lower), widths: front.widths, in: context)
        drawLeg(from: hip.near.applying(place), pose.hindNear, lengths: (hind.upper, hind.lower), widths: hind.widths, in: context)
    }

    /// 엉덩이 → 등 → 목 → 머리 → 코 → 턱 → 가슴 → 배 → 엉덩이로 이어지는 한 덩어리 실루엣
    // CGPath 는 Sendable 이 아니라 전역 상수로 둘 수 없다. 프레임은 시작할 때 한 번만 그리므로 매번 만들어도 된다.
    static var silhouette: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 6.6, y: 11.0))
        // 등: 둥글게 솟은 등선
        path.addCurve(to: CGPoint(x: 16.0, y: 11.8), control1: CGPoint(x: 9.6, y: 12.4), control2: CGPoint(x: 13.2, y: 12.2))
        // 목: 어깨에서 뒤통수로
        path.addCurve(to: CGPoint(x: 18.8, y: 13.6), control1: CGPoint(x: 17.2, y: 11.9), control2: CGPoint(x: 18.0, y: 12.9))
        // 둥근 정수리
        path.addCurve(to: CGPoint(x: 21.6, y: 14.6), control1: CGPoint(x: 19.4, y: 14.5), control2: CGPoint(x: 20.4, y: 14.8))
        // 이마 → 짧은 코
        path.addCurve(to: CGPoint(x: 24.4, y: 12.2), control1: CGPoint(x: 23.2, y: 14.3), control2: CGPoint(x: 24.3, y: 13.3))
        // 코 → 턱
        path.addCurve(to: CGPoint(x: 23.0, y: 10.9), control1: CGPoint(x: 24.5, y: 11.5), control2: CGPoint(x: 23.8, y: 11.0))
        // 턱 → 목 아래
        path.addCurve(to: CGPoint(x: 20.4, y: 10.4), control1: CGPoint(x: 22.2, y: 10.7), control2: CGPoint(x: 21.2, y: 10.9))
        // 가슴: 깊게 내려온다
        path.addCurve(to: CGPoint(x: 18.6, y: 6.4), control1: CGPoint(x: 19.6, y: 9.4), control2: CGPoint(x: 19.8, y: 7.0))
        // 배: 뒷다리 쪽으로 올라붙는다
        path.addCurve(to: CGPoint(x: 11.2, y: 6.6), control1: CGPoint(x: 16.4, y: 5.6), control2: CGPoint(x: 13.4, y: 6.0))
        path.addCurve(to: CGPoint(x: 7.8, y: 7.4), control1: CGPoint(x: 9.8, y: 6.9), control2: CGPoint(x: 8.6, y: 7.0))
        // 둥근 엉덩이
        path.addCurve(to: CGPoint(x: 6.6, y: 11.0), control1: CGPoint(x: 5.4, y: 7.8), control2: CGPoint(x: 5.0, y: 10.0))
        path.closeSubpath()
        return path
    }

    /// 뾰족한 두 귀(뒤쪽 귀가 조금 낮다)
    private static func drawEars(in context: CGContext) {
        context.move(to: CGPoint(x: 18.8, y: 13.8))
        context.addQuadCurve(to: CGPoint(x: 19.4, y: 17.1), control: CGPoint(x: 18.7, y: 15.9))
        context.addQuadCurve(to: CGPoint(x: 21.2, y: 14.6), control: CGPoint(x: 20.5, y: 15.8))
        context.closePath()
        context.fillPath()
        context.move(to: CGPoint(x: 20.4, y: 14.6))
        context.addQuadCurve(to: CGPoint(x: 21.7, y: 17.6), control: CGPoint(x: 20.6, y: 16.6))
        context.addQuadCurve(to: CGPoint(x: 23.3, y: 14.2), control: CGPoint(x: 22.8, y: 16.0))
        context.closePath()
        context.fillPath()
    }

    /// 엉덩이에서 올라가 끝이 말리는 긴 꼬리. raise 가 클수록 높이 세우고 많이 만다.
    private static func drawTail(raise: CGFloat, in context: CGContext) {
        let root = CGPoint(x: 6.6, y: 10.6)
        let tip = CGPoint(x: 2.4 + raise * 1.4, y: 13.4 + raise * 2.4)
        let curl = CGPoint(x: tip.x + 1.6 + raise * 0.6, y: tip.y + 0.4 + raise * 0.4)
        context.setLineWidth(1.5)
        context.move(to: root)
        context.addCurve(
            to: tip,
            control1: CGPoint(x: 3.8, y: 10.4 + raise * 0.6),
            control2: CGPoint(x: 1.6, y: 11.4 + raise * 1.4)
        )
        context.addQuadCurve(to: curl, control: CGPoint(x: tip.x + 0.2, y: tip.y + 1.4))
        context.strokePath()
    }

    /// 위는 굵고 아래로 갈수록 가늘어지는 두 마디 다리 + 작은 발
    private static func drawLeg(
        from top: CGPoint,
        _ limb: Limb,
        lengths: (CGFloat, CGFloat),
        widths: (CGFloat, CGFloat, CGFloat),
        in context: CGContext
    ) {
        let joint = top.moved(angle: limb.upper, length: lengths.0)
        let paw = joint.moved(angle: limb.lower, length: lengths.1)
        fillTapered(from: top, to: joint, startWidth: widths.0, endWidth: widths.1, in: context)
        fillTapered(from: joint, to: paw, startWidth: widths.1, endWidth: widths.2, in: context)
        // 발은 진행 방향으로 살짝 길쭉하게
        context.fillEllipse(in: CGRect(center: CGPoint(x: paw.x + 0.3, y: paw.y), size: CGSize(width: 1.7, height: 1.1)))
    }

    /// 두 점 사이를 굵기가 변하는 둥근 막대로 채운다.
    private static func fillTapered(from start: CGPoint, to end: CGPoint, startWidth: CGFloat, endWidth: CGFloat, in context: CGContext) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(hypot(dx, dy), 0.001)
        let normal = CGPoint(x: -dy / length, y: dx / length)
        context.move(to: CGPoint(x: start.x + normal.x * startWidth / 2, y: start.y + normal.y * startWidth / 2))
        context.addLine(to: CGPoint(x: end.x + normal.x * endWidth / 2, y: end.y + normal.y * endWidth / 2))
        context.addLine(to: CGPoint(x: end.x - normal.x * endWidth / 2, y: end.y - normal.y * endWidth / 2))
        context.addLine(to: CGPoint(x: start.x - normal.x * startWidth / 2, y: start.y - normal.y * startWidth / 2))
        context.closePath()
        context.fillPath()
        context.fillEllipse(in: CGRect(center: start, size: CGSize(width: startWidth, height: startWidth)))
        context.fillEllipse(in: CGRect(center: end, size: CGSize(width: endWidth, height: endWidth)))
    }
}
