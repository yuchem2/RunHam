import CoreGraphics
import Foundation

/// 옆모습으로 그린 날렵한 고양이 러너(기본). 28×18pt 캔버스를 안티앨리어싱해 렌더링한다.
///
/// 실제 갤럽처럼 몸이 늘어났다 말리도록 몸을 엉덩이(골반)와 가슴(어깨) 두 덩어리로 나누고,
/// 둘을 등·배 곡선으로 잇는다. 프레임마다 두 덩어리의 위치·기울기와 등 굽힘, 다리 관절 각도,
/// 꼬리 각도를 바꿔 자세를 만든다. 좌표는 포인트 단위, 원점은 왼쪽 아래(지면), 고양이는 오른쪽(+x)을 본다.
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
            previewFrames: gallop.map { render($0, scale: previewScale) },
            // 7프레임이어도 한 보폭이 원본(5프레임 ÷ 초당 2프레임 = 2.5초)과 같게
            baseFrameRate: Double(gallop.count) / 2.5
        )
    }

    // MARK: - 자세

    /// 앞다리: 위팔·아래팔 각도(수직 아래 기준, 도, 양수면 앞)
    struct Front {
        var upper: CGFloat
        var lower: CGFloat
    }

    /// 뒷다리: 허벅지·정강이·발등 각도. 정강이와 발등 사이가 뒤로 꺾이는 발목(hock)이다.
    struct Hind {
        var thigh: CGFloat
        var shank: CGFloat
        var foot: CGFloat
    }

    struct Pose {
        /// 골반(뒷다리가 붙는 곳) 위치와 기울기. 양수면 엉덩이 쪽이 내려간다(반시계).
        var hip: CGPoint
        var pelvis: CGFloat
        /// 어깨(앞다리가 붙는 곳) 위치와 기울기. 양수면 머리 쪽이 올라간다.
        var shoulder: CGPoint
        var chest: CGFloat
        /// 등이 위로 굽는 정도(pt). 모을 때 크고 뻗을 때 0 근처.
        var arch: CGFloat
        /// 가슴 기울기에 더해 머리를 숙이는 각도(음수면 숙임)
        var neck: CGFloat
        /// 꼬리 각도(도, 0 = 수평으로 뒤, 양수면 위)와 물결 크기
        var tail: CGFloat
        var tailWave: CGFloat
        var frontNear: Front
        var frontFar: Front
        var hindNear: Hind
        var hindFar: Hind
    }

    /// 7프레임 로터리 갤럽: 뻗기 → 앞발 착지 → 앞발 지지 → 모으기 → 뒷발 착지 → 박차기 → 날아오르기
    static let gallop: [Pose] = [
        // 1 쭉 뻗은 공중 자세: 몸이 길고 평평, 앞다리는 앞으로, 뒷다리는 뒤로
        Pose(hip: CGPoint(x: 8.0, y: 9.4), pelvis: -4, shoulder: CGPoint(x: 17.0, y: 9.4), chest: 4,
             arch: -0.2, neck: -4, tail: 10, tailWave: 0.5,
             frontNear: Front(upper: 62, lower: 80), frontFar: Front(upper: 36, lower: 52),
             hindNear: Hind(thigh: -48, shank: -70, foot: -85), hindFar: Hind(thigh: -26, shank: -46, foot: -60)),
        // 2 앞발 착지: 앞다리 하나가 앞쪽 바닥을 짚고, 뒷다리는 앞으로 끌려온다
        Pose(hip: CGPoint(x: 8.4, y: 9.0), pelvis: 0, shoulder: CGPoint(x: 16.8, y: 8.6), chest: -2,
             arch: 0.1, neck: -8, tail: 6, tailWave: 0.8,
             frontNear: Front(upper: 22, lower: 10), frontFar: Front(upper: 50, lower: 70),
             hindNear: Hind(thigh: -10, shank: -40, foot: -60), hindFar: Hind(thigh: -28, shank: -55, foot: -75)),
        // 3 앞발 지지: 앞다리가 몸 밑을 지나고 등이 말리기 시작, 뒷다리는 앞으로 접혀 온다
        Pose(hip: CGPoint(x: 9.2, y: 9.2), pelvis: 10, shoulder: CGPoint(x: 16.4, y: 8.4), chest: -5,
             arch: 0.7, neck: -10, tail: 2, tailWave: 1.0,
             frontNear: Front(upper: -10, lower: -12), frontFar: Front(upper: 12, lower: 4),
             hindNear: Hind(thigh: 22, shank: -25, foot: 10), hindFar: Hind(thigh: 10, shank: -35, foot: 0)),
        // 4 모으기: 등을 둥글게 말고 뒷다리를 배 밑 깊숙이, 머리를 숙인다
        Pose(hip: CGPoint(x: 10.6, y: 9.8), pelvis: 25, shoulder: CGPoint(x: 16.0, y: 8.8), chest: -10,
             arch: 1.6, neck: -12, tail: -4, tailWave: 1.2,
             frontNear: Front(upper: -45, lower: -70), frontFar: Front(upper: -30, lower: -50),
             hindNear: Hind(thigh: 45, shank: 0, foot: 40), hindFar: Hind(thigh: 32, shank: -10, foot: 30)),
        // 5 뒷발 착지: 뒷다리가 몸 밑을 짚고 앞다리는 접혀 올라온다
        Pose(hip: CGPoint(x: 10.0, y: 9.4), pelvis: 18, shoulder: CGPoint(x: 16.6, y: 9.6), chest: 0,
             arch: 1.2, neck: -8, tail: 0, tailWave: 1.0,
             frontNear: Front(upper: -20, lower: -75), frontFar: Front(upper: -5, lower: -60),
             hindNear: Hind(thigh: 22, shank: -12, foot: 15), hindFar: Hind(thigh: -8, shank: -32, foot: -18)),
        // 6 박차기: 뒷다리로 밀며 등을 펴고 앞다리를 앞으로 내민다
        Pose(hip: CGPoint(x: 9.0, y: 9.6), pelvis: 6, shoulder: CGPoint(x: 17.0, y: 10.0), chest: 6,
             arch: 0.4, neck: -4, tail: 6, tailWave: 0.8,
             frontNear: Front(upper: 40, lower: 75), frontFar: Front(upper: 14, lower: 36),
             hindNear: Hind(thigh: -20, shank: -40, foot: -30), hindFar: Hind(thigh: 12, shank: -18, foot: 4)),
        // 7 날아오르기: 몸이 다시 길어지며 공중으로
        Pose(hip: CGPoint(x: 8.4, y: 9.8), pelvis: 0, shoulder: CGPoint(x: 17.2, y: 10.0), chest: 5,
             arch: 0, neck: -4, tail: 9, tailWave: 0.6,
             frontNear: Front(upper: 55, lower: 70), frontFar: Front(upper: 30, lower: 45),
             hindNear: Hind(thigh: -38, shank: -60, foot: -72), hindFar: Hind(thigh: -18, shank: -38, foot: -52)),
    ]

    // MARK: - 비율

    static let front = (upper: CGFloat(2.9), lower: CGFloat(2.8), widths: (CGFloat(2.5), CGFloat(1.5), CGFloat(1.2)))
    static let hind = (thigh: CGFloat(3.0), shank: CGFloat(2.4), foot: CGFloat(1.7),
                       widths: (CGFloat(3.8), CGFloat(1.8), CGFloat(1.3), CGFloat(1.1)))
    static let farLegAlpha: CGFloat = 0.5
    static let fit = CGAffineTransform(translationX: 0.6, y: 0.0).scaledBy(x: 0.96, y: 0.96)

    // MARK: - 그리기

    static func render(_ pose: Pose, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            context.concatenate(fit)
            draw(pose, in: context)
        }
    }

    /// 덩어리(골반·가슴·머리) 기준 좌표를 화면 좌표로
    private struct Frame {
        var origin: CGPoint
        var angle: CGFloat

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let radians = angle * .pi / 180
            return CGPoint(x: origin.x + x * cos(radians) - y * sin(radians), y: origin.y + x * sin(radians) + y * cos(radians))
        }

        func fillEllipse(center x: CGFloat, _ y: CGFloat, size: CGSize, in context: CGContext) {
            context.saveGState()
            let center = point(x, y)
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: angle * .pi / 180)
            context.fillEllipse(in: CGRect(center: .zero, size: size))
            context.restoreGState()
        }
    }

    static func draw(_ pose: Pose, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let pelvis = Frame(origin: pose.hip, angle: pose.pelvis)
        let chest = Frame(origin: pose.shoulder, angle: pose.chest)

        // 먼 쪽 다리는 마디가 겹친 곳이 진해지지 않도록 불투명하게 그린 뒤 한꺼번에 흐리게 한다.
        context.setAlpha(farLegAlpha)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setAlpha(1)
        drawFront(from: chest.point(-0.2, -1.2), pose.frontFar, in: context)
        drawHind(from: pelvis.point(0.6, -0.4), pose.hindFar, in: context)
        context.endTransparencyLayer()
        context.setAlpha(1)

        drawTail(from: pelvis.point(-2.6, 1.4), angle: pose.tail, wave: pose.tailWave, in: context)

        // 몸통: 엉덩이와 가슴 덩어리 + 둘을 잇는 등·배
        pelvis.fillEllipse(center: -0.7, 0.5, size: CGSize(width: 5.8, height: 5.2), in: context)
        chest.fillEllipse(center: 0.4, 0.2, size: CGSize(width: 6.0, height: 6.4), in: context)
        let backStart = pelvis.point(-0.4, 2.8)
        let backEnd = chest.point(-0.6, 3.2)
        let bellyStart = chest.point(0.4, -2.9)
        let bellyEnd = pelvis.point(1.0, -2.0)
        context.move(to: backStart)
        context.addQuadCurve(to: backEnd, control: CGPoint(x: (backStart.x + backEnd.x) / 2, y: (backStart.y + backEnd.y) / 2 + 0.3 + pose.arch))
        context.addLine(to: bellyStart)
        // 배는 뒷다리 쪽으로 올라붙고, 등을 말면 같이 올라간다
        context.addQuadCurve(to: bellyEnd, control: CGPoint(x: (bellyStart.x + bellyEnd.x) / 2, y: (bellyStart.y + bellyEnd.y) / 2 + 0.5 + pose.arch * 0.6))
        context.closePath()
        context.fillPath()

        drawFront(from: chest.point(0.6, -1.4), pose.frontNear, in: context)
        drawHind(from: pelvis.point(0.2, -0.6), pose.hindNear, in: context)

        // 목과 머리
        let neckBase = chest.point(1.2, 1.6)
        let head = Frame(origin: chest.point(3.0, 2.9), angle: pose.chest + pose.neck)
        fillTapered(from: neckBase, to: head.point(0.2, 0.2), startWidth: 3.8, endWidth: 3.0, in: context)
        // 목덜미: 등선에서 뒤통수까지 곡선으로 메워 어깨가 혹처럼 튀어나오지 않게 한다
        let nape = head.point(-1.2, 1.4)
        context.move(to: backEnd)
        context.addQuadCurve(to: nape, control: chest.point(1.2, 3.8))
        context.addLine(to: head.point(0.4, -1.2))
        context.addLine(to: chest.point(1.4, 0.0))
        context.closePath()
        context.fillPath()
        drawHead(head, in: context)
    }

    /// 옆모습 머리: 둥근 두개골 + 짧은 주둥이 + 뒤로 살짝 젖힌 두 귀 + 작은 눈 구멍
    private static func drawHead(_ head: Frame, in context: CGContext) {
        head.fillEllipse(center: 0.8, 0.5, size: CGSize(width: 5.0, height: 4.4), in: context)
        // 주둥이는 머리와 크게 겹쳐 따로 튀어나와 보이지 않게
        head.fillEllipse(center: 2.5, -0.1, size: CGSize(width: 2.6, height: 2.2), in: context)
        // 밑변이 넓고 달릴 때처럼 뒤로 살짝 젖힌 귀 두 개(뒤쪽 귀가 조금 작다)
        let ears: [(base: CGPoint, tip: CGPoint, end: CGPoint)] = [
            (CGPoint(x: -1.3, y: 1.4), CGPoint(x: -1.2, y: 3.7), CGPoint(x: 0.4, y: 2.4)),
            (CGPoint(x: 0.0, y: 2.4), CGPoint(x: 0.5, y: 4.2), CGPoint(x: 2.0, y: 2.0)),
        ]
        for ear in ears {
            context.move(to: head.point(ear.base.x, ear.base.y))
            context.addLine(to: head.point(ear.tip.x, ear.tip.y))
            context.addLine(to: head.point(ear.end.x, ear.end.y))
            context.closePath()
            context.fillPath()
        }
        context.setBlendMode(.clear)
        context.saveGState()
        let eye = head.point(2.1, 0.9)
        context.translateBy(x: eye.x, y: eye.y)
        context.rotate(by: (head.angle - 10) * .pi / 180)
        context.fillEllipse(in: CGRect(center: .zero, size: CGSize(width: 0.8, height: 0.5)))
        context.restoreGState()
        context.setBlendMode(.normal)
    }

    private static func drawFront(from top: CGPoint, _ leg: Front, in context: CGContext) {
        let elbow = top.moved(angle: leg.upper, length: front.upper)
        let paw = elbow.moved(angle: leg.lower, length: front.lower)
        fillTapered(from: top, to: elbow, startWidth: front.widths.0, endWidth: front.widths.1, in: context)
        fillTapered(from: elbow, to: paw, startWidth: front.widths.1, endWidth: front.widths.2, in: context)
        drawPaw(at: paw, in: context)
    }

    private static func drawHind(from top: CGPoint, _ leg: Hind, in context: CGContext) {
        let knee = top.moved(angle: leg.thigh, length: hind.thigh)
        let hock = knee.moved(angle: leg.shank, length: hind.shank)
        let paw = hock.moved(angle: leg.foot, length: hind.foot)
        fillTapered(from: top, to: knee, startWidth: hind.widths.0, endWidth: hind.widths.1, in: context)
        fillTapered(from: knee, to: hock, startWidth: hind.widths.1, endWidth: hind.widths.2, in: context)
        fillTapered(from: hock, to: paw, startWidth: hind.widths.2, endWidth: hind.widths.3, in: context)
        drawPaw(at: paw, in: context)
    }

    private static func drawPaw(at paw: CGPoint, in context: CGContext) {
        context.fillEllipse(in: CGRect(center: CGPoint(x: paw.x + 0.3, y: paw.y), size: CGSize(width: 1.6, height: 1.0)))
    }

    /// 뒤로 흐르는 긴 꼬리. 굵기를 뿌리에서 끝으로 줄이고 물결을 준다.
    private static func drawTail(from root: CGPoint, angle: CGFloat, wave: CGFloat, in context: CGContext) {
        let radians = (180 - angle) * .pi / 180
        let direction = CGPoint(x: cos(radians), y: sin(radians))
        let normal = CGPoint(x: -direction.y, y: direction.x)
        func along(_ distance: CGFloat, _ offset: CGFloat) -> CGPoint {
            CGPoint(x: root.x + direction.x * distance + normal.x * offset, y: root.y + direction.y * distance + normal.y * offset)
        }
        let samples = 12
        let length: CGFloat = 6.4
        var previous = root
        for index in 1...samples {
            let t = CGFloat(index) / CGFloat(samples)
            // 끝으로 갈수록 살짝 들리는 S자 물결
            let point = along(length * t, sin(t * .pi * 1.4) * wave - t * t * 0.6)
            let width = 1.6 - 0.7 * t
            fillTapered(from: previous, to: point, startWidth: width + 0.06, endWidth: width, in: context)
            previous = point
        }
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
