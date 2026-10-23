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

/// 볼 빵빵 햄스터: 먹이를 볼에 채워 넣어 볼주머니가 점점 부풀었다가 꺼진다. 22×18pt, 8프레임.
enum CheekyHamsterSprite {
    /// 볼주머니 크기(0 = 홀쭉, 2.6 = 빵빵)
    static let cheekCurve: [CGFloat] = [0, 0.5, 1.0, 1.5, 2.0, 2.6, 2.6, 0.6]

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "hamster-cheeks", nameKey: "runner.hamsterCheeks", width: 22, frameCount: cheekCurve.count, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let cheek = cheekCurve[frame]
        let isFull = cheek >= 2.6

        // 깔고 앉은 엉덩이·뒷발·꼬리·몸통, 가슴 앞에 모은 앞발
        DrawnRunner.fill(CGPoint(x: 2.2, y: 2.4), CGSize(width: 1.8, height: 1.3), in: context)
        DrawnRunner.fill(CGPoint(x: 6.4, y: 3.4), CGSize(width: 7.0, height: 5.6), in: context)
        DrawnRunner.fill(CGPoint(x: 10.2, y: 0.9), CGSize(width: 4.4, height: 1.7), in: context)
        DrawnRunner.fill(CGPoint(x: 8.4, y: 5.6), CGSize(width: 11.6, height: 10.4), rotated: -11, in: context)
        DrawnRunner.fill(CGPoint(x: 13.8, y: 4.4), CGSize(width: 2.4, height: 1.8), in: context)

        // 머리. 꽉 차면 눈을 감고 만족한 얼굴
        context.saveGState()
        context.translateBy(x: 11.6, y: 11.0)
        context.scaleBy(x: 1.08, y: 1.08)
        context.rotate(by: -6 * .pi / 180)
        HamsterSilhouette.drawHead(eyesClosed: isFull, in: context)
        if cheek > 0 {
            // 머리 앞아래로 부푸는 볼주머니. 흰 테두리로 몸·얼굴과 떨어뜨려 커지는 게 보이게 한다
            let pouch = CGRect(center: CGPoint(x: 1.4 + cheek * 0.55, y: -3.0 - cheek * 0.65), size: CGSize(width: 3.4 + cheek * 1.8, height: 2.8 + cheek * 1.5))
            context.saveGState()
            context.setBlendMode(.clear)
            context.fillEllipse(in: pouch.insetBy(dx: -0.6, dy: -0.6))
            context.restoreGState()
            context.fillEllipse(in: pouch)
        }
        context.restoreGState()
    }
}
