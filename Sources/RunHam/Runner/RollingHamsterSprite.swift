import CoreGraphics

/// 데굴데굴 햄스터: 몸을 동그랗게 말고 앞으로 구른다. 24×18pt, 8프레임(한 바퀴).
enum RollingHamsterSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "hamster-roll", nameKey: "runner.hamsterRoll", width: 24, frameCount: frameCount, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount)
        // 구를 때마다 바닥에서 살짝 통통 튄다
        let center = CGPoint(x: 15.0, y: 8.4 + abs(sin(phase * 2 * .pi * 2)) * 0.5)

        // 뒤로 날리는 속도선
        for (index, y) in [CGFloat(12.0), 8.4, 4.8].enumerated() {
            let length: CGFloat = (index + frame) % 2 == 0 ? 3.4 : 2.0
            DrawnRunner.stroke([CGPoint(x: 5.4 - length, y: y), CGPoint(x: 5.4, y: y)], width: 1.2, in: context)
        }

        // 오른쪽으로 구르므로 시계 방향(각도 감소)으로 돈다
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -phase * 2 * .pi)
        let radius: CGFloat = 7.4
        func around(_ degrees: CGFloat, _ distance: CGFloat) -> CGPoint {
            let a = degrees * .pi / 180
            return CGPoint(x: cos(a) * distance, y: sin(a) * distance)
        }
        DrawnRunner.fill(.zero, CGSize(width: radius * 2, height: radius * 2), in: context)
        DrawnRunner.fill(around(112, radius - 0.6), CGSize(width: 3.6, height: 3.6), in: context)    // 둥근 귀
        DrawnRunner.fill(around(88, radius - 0.6), CGSize(width: 3.0, height: 3.0), in: context)     // 먼 쪽 귀
        DrawnRunner.fill(around(34, radius + 0.1), CGSize(width: 2.4, height: 2.2), in: context)     // 코
        // 동그랗게 만 몸: 머리와 몸이 맞닿은 곳을 흰 곡선으로
        context.saveGState()
        context.setBlendMode(.clear)
        context.setLineWidth(0.7)
        context.setLineCap(.round)
        context.addArc(center: CGPoint(x: 1.2, y: -1.0), radius: 4.0, startAngle: -0.3, endAngle: -2.2, clockwise: true)
        context.strokePath()
        context.restoreGState()
        DrawnRunner.eye(around(66, 4.8), in: context)
        context.restoreGState()
    }
}
