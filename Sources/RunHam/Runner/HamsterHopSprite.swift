import CoreGraphics

/// RunHam 의 기본 러너: 깡총깡총 뛰는 햄스터. 22×18pt, 8프레임.
///
/// 돌고래 러너처럼 실루엣이 프레임을 꽉 채우고 몸 모양 변화로 움직임을 보여 준다.
/// 웅크림 → 박차기 → 상승 → 정점 → 하강 → 착지 → 뒷발 모으기 → 웅크림.
enum HamsterHopSprite {
    static let canvas = CGSize(width: 22, height: 18)
    static let scale: CGFloat = 2
    static let previewScale: CGFloat = 6

    static func makeRunner() -> Runner {
        Runner(
            id: "hamster",
            nameKey: "runner.hamster",
            frames: poses.indices.map { render(frame: $0, scale: scale) },
            isPixelArt: false,
            previewFrames: poses.indices.map { render(frame: $0, scale: previewScale) },
            // 8프레임 한 번 뛰기가 속도 1 에서 2초
            baseFrameRate: 4
        )
    }

    static let poses: [HamsterSilhouette.Pose] = [
        .init(pitch: 0, stretch: 0.92, lift: 0, front: 10, hind: 0, hindReach: 0.6),
        .init(pitch: 22, stretch: 1.08, lift: 1.6, front: 50, hind: -45, hindReach: 1.3),
        .init(pitch: 14, stretch: 1.12, lift: 2.2, front: 70, hind: -60, hindReach: 1.2),
        .init(pitch: 0, stretch: 1.1, lift: 2.8, front: 40, hind: -30, hindReach: 1.0),
        .init(pitch: -14, stretch: 1.08, lift: 2.0, front: 15, hind: -50, hindReach: 1.1),
        .init(pitch: -18, stretch: 1.15, lift: 0.6, front: -5, hind: -70, hindReach: 1.3),
        .init(pitch: -4, stretch: 0.98, lift: 0.3, front: -25, hind: 35, hindReach: 0.8),
        .init(pitch: 4, stretch: 0.94, lift: 0.1, front: 0, hind: 15, hindReach: 0.7),
    ]

    /// 8자세를 모두 겹친 영역(몸통 중심 기준, x -9.1…11.4, y -6.3…10.8)이 위아래 0.4pt 만 남기고
    /// 높이 18pt 를 채우도록 옮기고 키운다. 자세를 바꾸면 다시 재서 고친다.
    static let fitScale: CGFloat = 1.0118
    static let fitOrigin = CGPoint(x: 0.4 + 9.125 * fitScale, y: 0.4 + 6.25 * fitScale)

    static func render(frame: Int, scale: CGFloat) -> CGImage {
        SpriteRenderer.render(width: Int(canvas.width * scale), height: Int(canvas.height * scale)) { context in
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: fitOrigin.x, y: fitOrigin.y)
            context.scaleBy(x: fitScale, y: fitScale)
            HamsterSilhouette.draw(poses[frame], in: context)
        }
    }
}
