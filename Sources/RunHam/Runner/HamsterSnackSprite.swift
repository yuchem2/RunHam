import CoreGraphics

/// 해바라기씨를 앞발로 들고 오물오물 먹는 햄스터(옆모습, 22×18pt, 6프레임). CPU 가 높을수록 빨리 오물거린다.
///
/// 기본 러너와 같은 검은 실루엣·하얀 눈 머리를 쓰고, 엉덩이를 깔고 똑바로 앉는다.
/// 씹을 때마다 씨가 입으로 올라가고, 머리가 까딱이며, 볼주머니가 부풀고, 눈을 꼭 감는다.
/// 씨는 둘레만 하얗게 비워 실루엣 안에서도 보이고, 씹을 때마다 부스러기가 앞으로 떨어진다.
enum HamsterSnackSprite {
    static let canvas = CGSize(width: 22, height: 18)
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

    /// 0 ~ 1. 씨를 입에 대고 꼭꼭 씹는 정도. 한 바퀴에 두 번 오물거린다.
    static let chewCurve: [CGFloat] = [0, 0.5, 1, 0.1, 0.5, 1]

    static func render(frame: Int, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            draw(chew: chewCurve[frame % chewCurve.count], in: context)
            drawCrumbs(frame: frame, in: context)
        }
    }

    static func draw(chew: CGFloat, in context: CGContext) {
        let bob = chew * 0.6
        let seedLift = chew * 1.2

        // 깔고 앉은 엉덩이와 납작한 뒷발, 짧은 꼬리, 통통한 몸
        HamsterSilhouette.fill(CGPoint(x: 2.2, y: 2.4), CGSize(width: 1.8, height: 1.3), in: context)
        HamsterSilhouette.fill(CGPoint(x: 6.4, y: 3.4), CGSize(width: 7.0, height: 5.6), in: context)
        HamsterSilhouette.fill(CGPoint(x: 10.2, y: 0.9), CGSize(width: 4.4, height: 1.7), in: context)
        context.saveGState()
        context.translateBy(x: 8.4, y: 5.6)
        context.rotate(by: -0.2)
        HamsterSilhouette.fill(.zero, CGSize(width: 11.6, height: 10.4), in: context)
        context.restoreGState()

        // 큰 머리: 씹을 때 살짝 숙이며 까딱인다
        context.saveGState()
        context.translateBy(x: 11.6, y: 10.9 - bob)
        context.scaleBy(x: 1.12, y: 1.12)
        context.rotate(by: (-8 - chew * 6) * .pi / 180)
        HamsterSilhouette.drawHead(cheek: chew, eyesClosed: chew > 0.9, in: context)
        context.restoreGState()

        // 주둥이 아래로 든 해바라기씨와 그 아래를 감싼 두 앞발
        let seed = CGPoint(x: 17.2, y: 6.2 + seedLift)
        drawSeed(at: seed, tilt: -4 - chew * 8, in: context)
        HamsterSilhouette.fill(CGPoint(x: seed.x - 1.4, y: seed.y - 1.6), CGSize(width: 2.4, height: 1.8), in: context)
        HamsterSilhouette.fill(CGPoint(x: seed.x + 0.8, y: seed.y - 2.0), CGSize(width: 2.0, height: 1.6), in: context)
    }

    /// 씨 아래에서 떨어지는 부스러기 세 개(두 프레임씩 엇갈려 떨어진다)와 바닥에 쌓인 부스러기
    static func drawCrumbs(frame: Int, in context: CGContext) {
        let drift: [CGFloat] = [0.2, -0.9, 1.0]
        for (index, dx) in drift.enumerated() {
            let fall = CGFloat((frame + index * 2) % frameCount) / CGFloat(frameCount)
            let center = CGPoint(x: 17.6 + dx + fall * 0.8, y: 3.4 - fall * 2.6)
            let size: CGFloat = index == 1 ? 0.9 : 1.1
            HamsterSilhouette.fill(center, CGSize(width: size, height: size), in: context)
        }
        HamsterSilhouette.fill(CGPoint(x: 18.4, y: 0.5), CGSize(width: 1.4, height: 0.9), in: context)
        HamsterSilhouette.fill(CGPoint(x: 20.2, y: 0.45), CGSize(width: 1.0, height: 0.8), in: context)
    }

    /// 끝이 뾰족한 물방울 모양 씨: 둘레만 비워 몸·얼굴과 떨어뜨린다
    private static func drawSeed(at center: CGPoint, tilt: CGFloat, in context: CGContext) {
        context.saveGState()
        defer { context.restoreGState() }
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: tilt * .pi / 180)
        context.scaleBy(x: 1.15, y: 1.15)
        let seed = CGMutablePath()
        seed.move(to: CGPoint(x: 0, y: 2.3))
        seed.addCurve(to: CGPoint(x: 0, y: -2.0), control1: CGPoint(x: 1.9, y: 1.0), control2: CGPoint(x: 1.6, y: -2.0))
        seed.addCurve(to: CGPoint(x: 0, y: 2.3), control1: CGPoint(x: -1.6, y: -2.0), control2: CGPoint(x: -1.9, y: 1.0))

        context.setBlendMode(.clear)
        context.setLineWidth(0.8)
        context.addPath(seed)
        context.strokePath()
        context.setBlendMode(.normal)
        context.addPath(seed)
        context.fillPath()
    }
}
