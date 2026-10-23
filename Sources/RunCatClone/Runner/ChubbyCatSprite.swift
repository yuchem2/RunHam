import CoreGraphics
import Foundation

/// 곡선(벡터)으로 그리는 통통한 고양이 러너(정면 얼굴, 2등신). 28×18pt 캔버스를 @2x 로 안티앨리어싱해 렌더링한다.
///
/// 프레임은 이미지로 그리지 않고 뼈대 자세(다리 관절 각도, 몸 들썩임, 기울기, 꼬리)로 정의해서
/// 자세 값만 바꿔 동작을 다듬을 수 있다. 좌표는 포인트 단위, 원점은 왼쪽 아래(지면), 고양이는 오른쪽(+x)을 본다.
enum ChubbyCatSprite {
    static let canvas = CGSize(width: 28, height: 18)
    static let scale: CGFloat = 2

    /// 미리보기(3배 확대)를 Retina 에서 또렷하게 보이게 하는 배율
    static let previewScale: CGFloat = 6

    static func makeRunner() -> Runner {
        Runner(
            id: "chubby-cat",
            nameKey: "runner.chubbyCat",
            frames: gallop.map { render($0, scale: scale) },
            isPixelArt: false,
            previewFrames: gallop.map { render($0, scale: previewScale) }
        )
    }

    // MARK: - 자세

    /// 다리 하나. 각도는 수직 아래 기준(도), 양수면 진행 방향(앞)으로 뻗는다. lower 는 무릎 아래의 절대 각도.
    struct Limb {
        var upper: CGFloat
        var lower: CGFloat
    }

    enum Tail {
        case up, mid, down
    }

    struct Pose {
        /// 몸 전체를 위로 띄우는 정도(pt)
        var bob: CGFloat
        /// 몸통 기울기(도), 양수면 머리가 올라간다
        var tilt: CGFloat
        var tail: Tail
        var frontNear: Limb
        var frontFar: Limb
        var hindNear: Limb
        var hindFar: Limb
    }

    /// 5프레임 갤럽(속도 1 에서 초당 2프레임 규칙은 그대로)
    static let gallop: [Pose] = [
        // 쭉 뻗기
        Pose(bob: 0.4, tilt: 0, tail: .mid,
             frontNear: Limb(upper: 55, lower: 75), frontFar: Limb(upper: 40, lower: 60),
             hindNear: Limb(upper: -50, lower: -70), hindFar: Limb(upper: -38, lower: -55)),
        // 앞발 착지
        Pose(bob: 0, tilt: -3, tail: .up,
             frontNear: Limb(upper: 8, lower: -5), frontFar: Limb(upper: 28, lower: 50),
             hindNear: Limb(upper: -25, lower: 10), hindFar: Limb(upper: -45, lower: -60)),
        // 모으기: 실제 갤럽처럼 다리를 배 밑에서 교차시키면 덩어리로 보여서, 네 발을 모아 통통 튀는 자세로 둔다
        Pose(bob: 1.1, tilt: 0, tail: .up,
             frontNear: Limb(upper: -6, lower: 6), frontFar: Limb(upper: 4, lower: 14),
             hindNear: Limb(upper: 14, lower: 2), hindFar: Limb(upper: 4, lower: -8)),
        // 뒷발 착지
        Pose(bob: 0.2, tilt: 3, tail: .mid,
             frontNear: Limb(upper: 30, lower: 85), frontFar: Limb(upper: 20, lower: 60),
             hindNear: Limb(upper: 5, lower: -5), hindFar: Limb(upper: -15, lower: 10)),
        // 박차기
        Pose(bob: 0.5, tilt: 2, tail: .down,
             frontNear: Limb(upper: 45, lower: 40), frontFar: Limb(upper: 35, lower: 30),
             hindNear: Limb(upper: -35, lower: -55), hindFar: Limb(upper: -20, lower: -30)),
    ]

    // MARK: - 비율

    static let bodyCenter = CGPoint(x: 12.6, y: 7.6)
    static let bodySize = CGSize(width: 13.5, height: 7.2)
    static let headCenter = CGPoint(x: 21.0, y: 10.4)
    static let headSize = CGSize(width: 10.2, height: 8.8)
    static let frontShoulder = (near: CGPoint(x: 16.6, y: 6.0), far: CGPoint(x: 15.2, y: 6.2))
    static let hindHip = (near: CGPoint(x: 8.6, y: 6.0), far: CGPoint(x: 10.0, y: 6.2))
    static let upperLength: CGFloat = 3.1
    static let lowerLength: CGFloat = 2.8
    static let legWidth: CGFloat = 2.3
    static let farLegAlpha: CGFloat = 0.5
    /// 들썩임·뻗은 다리까지 캔버스 안에 들어오도록 전체를 살짝 줄여 띄운다.
    static let fit = CGAffineTransform(translationX: 1.2, y: 0.9).scaledBy(x: 0.9, y: 0.9)

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

        // 기울기는 몸통 중심을 축으로 머리·꼬리·다리 뿌리까지 함께 돌린다.
        let lift = CGAffineTransform(translationX: 0, y: pose.bob)
        let pivot = bodyCenter.applying(lift)
        let tilt = CGAffineTransform(translationX: pivot.x, y: pivot.y)
            .rotated(by: pose.tilt * .pi / 180)
            .translatedBy(x: -pivot.x, y: -pivot.y)
        let place = lift.concatenating(tilt)

        // 먼 쪽 다리 → 꼬리 → 몸통 → 가까운 쪽 다리 → 머리 → 구멍(눈·코)
        // 먼 쪽 다리는 겹친 곳이 진해지지 않도록 불투명하게 그린 뒤 한꺼번에 흐리게 한다.
        context.setAlpha(farLegAlpha)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setAlpha(1)
        drawLeg(from: frontShoulder.far.applying(place), pose.frontFar, in: context)
        drawLeg(from: hindHip.far.applying(place), pose.hindFar, in: context)
        context.endTransparencyLayer()
        context.setAlpha(1)

        drawTail(pose.tail, transform: place, in: context)

        context.saveGState()
        context.concatenate(place)
        // 겹치는 도형을 한 경로로 칠하면 감는 방향에 따라 겹친 부분이 비므로 도형마다 따로 칠한다.
        context.fillEllipse(in: CGRect(center: bodyCenter, size: bodySize))
        // 가슴: 몸통과 머리를 부드럽게 잇는다
        context.fillEllipse(in: CGRect(center: CGPoint(x: 16.8, y: 8.6), size: CGSize(width: 6.4, height: 6.4)))
        context.restoreGState()

        drawLeg(from: frontShoulder.near.applying(place), pose.frontNear, in: context)
        drawLeg(from: hindHip.near.applying(place), pose.hindNear, in: context)

        context.saveGState()
        context.concatenate(place)
        drawHead(in: context)
        context.restoreGState()
    }

    private static func drawLeg(from hip: CGPoint, _ limb: Limb, in context: CGContext) {
        let knee = hip.moved(angle: limb.upper, length: upperLength)
        let paw = knee.moved(angle: limb.lower, length: lowerLength)
        context.setLineWidth(legWidth)
        context.move(to: hip)
        context.addLine(to: knee)
        context.addLine(to: paw)
        context.strokePath()
        // 둥근 발
        context.addEllipse(in: CGRect(center: paw, size: CGSize(width: legWidth + 0.5, height: legWidth + 0.3)))
        context.fillPath()
    }

    private static func drawTail(_ tail: Tail, transform: CGAffineTransform, in context: CGContext) {
        let root = CGPoint(x: 6.6, y: 9.0)
        let (c1, c2, tip): (CGPoint, CGPoint, CGPoint) = switch tail {
        case .up: (CGPoint(x: 3.6, y: 9.4), CGPoint(x: 1.2, y: 12.6), CGPoint(x: 2.6, y: 15.8))
        case .mid: (CGPoint(x: 3.6, y: 9.6), CGPoint(x: 0.9, y: 11.4), CGPoint(x: 1.3, y: 13.9))
        case .down: (CGPoint(x: 3.6, y: 9.0), CGPoint(x: 1.6, y: 9.6), CGPoint(x: 0.9, y: 11.6))
        }
        context.saveGState()
        context.concatenate(transform)
        context.setLineWidth(2.0)
        context.move(to: root)
        context.addCurve(to: tip, control1: c1, control2: c2)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawHead(in context: CGContext) {
        // 얼굴
        context.fillEllipse(in: CGRect(center: headCenter, size: headSize))
        drawEars(in: context)

        // 눈·코는 구멍으로 뚫어 메뉴바 배경이 비치게 한다
        context.setBlendMode(.clear)
        context.addEllipse(in: CGRect(center: CGPoint(x: 19.4, y: 10.9), size: CGSize(width: 1.2, height: 1.7)))
        context.addEllipse(in: CGRect(center: CGPoint(x: 22.6, y: 10.9), size: CGSize(width: 1.2, height: 1.7)))
        context.addEllipse(in: CGRect(center: CGPoint(x: 21.0, y: 9.2), size: CGSize(width: 0.9, height: 0.6)))
        context.fillPath()
        context.setBlendMode(.normal)
    }

    /// 귀(둥근 삼각형). `headCenter` 기준 좌표라 자는 고양이도 옮겨서 같이 쓴다.
    static func drawEars(in context: CGContext) {
        context.move(to: CGPoint(x: 17.2, y: 12.6))
        context.addQuadCurve(to: CGPoint(x: 17.8, y: 17.0), control: CGPoint(x: 16.7, y: 15.6))
        context.addQuadCurve(to: CGPoint(x: 20.6, y: 14.5), control: CGPoint(x: 19.0, y: 16.3))
        context.closePath()
        context.move(to: CGPoint(x: 21.4, y: 14.5))
        context.addQuadCurve(to: CGPoint(x: 24.4, y: 16.8), control: CGPoint(x: 23.4, y: 16.4))
        context.addQuadCurve(to: CGPoint(x: 24.9, y: 12.4), control: CGPoint(x: 25.2, y: 15.0))
        context.closePath()
        context.fillPath()
    }
}
