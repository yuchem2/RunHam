import CoreGraphics

/// 햄스터 러너들이 같이 쓰는 모양. 좌표는 포인트 단위, 원점은 몸 중심, 옆모습은 오른쪽을 본다.
///
/// 레퍼런스에서 본 햄스터다운 특징: 목이 없이 머리와 몸이 이어진 식빵(물방울) 모양,
/// 둥글게 솟은 등에서 내려와 짧고 뭉툭한 코끝, 등 앞쪽 위의 작은 동그란 귀, 반짝이는 까만 구슬 눈,
/// 코끝의 수염, 배 밑으로 살짝 보이는 짧은 발, 거의 안 보이는 꼬리.
enum HamsterShape {
    /// 옆모습 몸 전체(머리 포함) 실루엣. 폭 약 11.6, 높이 약 6.9.
    static var sideBody: CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4.6, y: -2.4))
        // 둥근 엉덩이
        path.addCurve(to: CGPoint(x: -5.6, y: 0.8), control1: CGPoint(x: -5.9, y: -2.1), control2: CGPoint(x: -6.1, y: -0.6))
        // 둥글게 솟은 등(머리까지 이어진다)
        path.addCurve(to: CGPoint(x: 0.0, y: 4.2), control1: CGPoint(x: -5.0, y: 3.6), control2: CGPoint(x: -2.6, y: 4.4))
        // 이마에서 코로 내려오는 둥근 경사
        path.addCurve(to: CGPoint(x: 5.0, y: 0.8), control1: CGPoint(x: 2.8, y: 4.0), control2: CGPoint(x: 4.8, y: 2.6))
        // 짧고 뭉툭한 코끝
        path.addCurve(to: CGPoint(x: 4.8, y: -0.6), control1: CGPoint(x: 5.6, y: 0.4), control2: CGPoint(x: 5.5, y: -0.4))
        // 통통한 볼과 턱
        path.addCurve(to: CGPoint(x: 2.2, y: -2.3), control1: CGPoint(x: 4.4, y: -1.6), control2: CGPoint(x: 3.4, y: -2.3))
        // 납작한 배
        path.addCurve(to: CGPoint(x: -4.6, y: -2.4), control1: CGPoint(x: 0.2, y: -2.7), control2: CGPoint(x: -2.8, y: -2.7))
        path.closeSubpath()
        return path
    }

    /// 머리에 반쯤 묻힌 작은 귀(위로 솟으면 생쥐처럼 보인다)
    static let sideEar = (center: CGPoint(x: 1.4, y: 3.6), radius: CGFloat(1.15))
    static let sideEye = CGPoint(x: 2.8, y: 1.6)

    /// 까만 구슬 눈: 작은 구멍을 뚫고 눈동자를 살짝 비껴 채워 반짝임(초승달 모양 빛)을 남긴다.
    static func drawBeadyEye(at center: CGPoint, radius: CGFloat, in context: CGContext) {
        context.setBlendMode(.clear)
        context.fillEllipse(in: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        context.setBlendMode(.normal)
        let pupil = radius * 0.78
        context.fillEllipse(in: CGRect(center: CGPoint(x: center.x + radius * 0.12, y: center.y - radius * 0.14), size: CGSize(width: pupil * 2, height: pupil * 2)))
    }

    /// 귀 안쪽을 뚫어 동그란 귀가 또렷하게 보이게 한다.
    static func drawEar(at center: CGPoint, radius: CGFloat, in context: CGContext) {
        context.fillEllipse(in: CGRect(center: center, size: CGSize(width: radius * 2, height: radius * 2)))
        context.setBlendMode(.clear)
        let inner = radius * 0.45
        context.fillEllipse(in: CGRect(center: CGPoint(x: center.x + radius * 0.1, y: center.y + radius * 0.05), size: CGSize(width: inner * 2, height: inner * 2)))
        context.setBlendMode(.normal)
    }

    /// 옆모습 코끝 수염 두 가닥
    static func drawWhiskers(in context: CGContext) {
        context.setLineWidth(0.45)
        context.move(to: CGPoint(x: 5.2, y: -0.1))
        context.addLine(to: CGPoint(x: 7.2, y: 0.5))
        context.move(to: CGPoint(x: 5.2, y: -0.4))
        context.addLine(to: CGPoint(x: 7.1, y: -0.8))
        context.strokePath()
    }

    // MARK: - 정면 얼굴 (해바라기씨 먹는 햄스터와 같은 생김새)

    /// 정면 머리 실루엣(짙은 모자 + 귀). 둘레 비우기용으로도 쓴다. scale 1 이 먹는 햄스터 크기.
    static func fillFrontHeadSilhouette(at center: CGPoint, scale: CGFloat, inflate: CGFloat = 0, earTwitch: CGFloat = 0, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scale, y: scale)
        let grow = inflate / scale
        context.fillEllipse(in: CGRect(center: .zero, size: CGSize(width: 12.6 + grow * 2, height: 9.8 + grow * 2)))
        for (side, twitch) in [(CGFloat(-1), earTwitch), (1, 0)] {
            let radius = 1.5 + grow
            context.fillEllipse(in: CGRect(center: CGPoint(x: side * 4.7, y: 3.4 + twitch * 0.4), size: CGSize(width: radius * 2, height: radius * 2)))
        }
    }

    /// 짙은 모자 머리 + 귀(안쪽 구멍) + 하얀 얼굴 + 짙은 구슬 눈(반짝임)·코·ω 입.
    /// eyesClosed 면 눈 대신 감은 눈(‿)을 그린다.
    static func drawFrontHead(
        at center: CGPoint,
        scale: CGFloat,
        eyesClosed: Bool = false,
        mouthOpen: CGFloat = 0,
        earTwitch: CGFloat = 0,
        in context: CGContext
    ) {
        fillFrontHeadSilhouette(at: center, scale: scale, earTwitch: earTwitch, in: context)
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scale, y: scale)

        // 귀 안쪽
        context.setBlendMode(.clear)
        for (side, twitch) in [(CGFloat(-1), earTwitch), (1, 0)] {
            context.fillEllipse(in: CGRect(center: CGPoint(x: side * 4.7 + 0.15, y: 3.45 + twitch * 0.4), size: CGSize(width: 1.35, height: 1.35)))
        }
        // 하얀 얼굴
        context.fillEllipse(in: CGRect(center: CGPoint(x: 0, y: -0.9), size: CGSize(width: 10.0, height: 6.0)))
        context.setBlendMode(.normal)

        for side: CGFloat in [-1, 1] {
            let eye = CGPoint(x: side * 2.7, y: 0.5)
            if eyesClosed {
                context.setLineWidth(0.7)
                context.addArc(center: CGPoint(x: eye.x, y: eye.y + 0.4), radius: 1.0, startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
                context.strokePath()
            } else {
                context.fillEllipse(in: CGRect(center: eye, size: CGSize(width: 1.8, height: 1.9)))
                context.setBlendMode(.clear)
                context.fillEllipse(in: CGRect(center: CGPoint(x: eye.x + 0.35, y: eye.y + 0.4), size: CGSize(width: 0.6, height: 0.6)))
                context.setBlendMode(.normal)
            }
        }
        context.fillEllipse(in: CGRect(center: CGPoint(x: 0, y: -0.8), size: CGSize(width: 1.1, height: 0.75)))
        context.setLineWidth(0.5)
        for side: CGFloat in [-1, 1] {
            context.addArc(center: CGPoint(x: side * 0.6, y: -1.3), radius: 0.6 + mouthOpen * 0.12, startAngle: .pi * 1.1, endAngle: .pi * 1.9, clockwise: false)
            context.strokePath()
        }
    }
}
