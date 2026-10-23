import CoreGraphics

/// 병아리: 큰 머리, 동그란 몸, 짧은 날개를 파닥이며 가는 다리로 종종 뛴다. 20×18pt, 6프레임.
enum ChickSprite {
    static let frameCount = 6

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "chick", nameKey: "runner.chick", width: 20, frameCount: frameCount, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        let bounce = abs(sin(phase)) * 1.0
        let hip = CGPoint(x: 9.0, y: 3.6 + bounce)

        // 가는 다리 두 개가 엇갈려 앞뒤로
        for offset in [CGFloat(0), .pi] {
            let swing = cos(phase + offset)
            let foot = CGPoint(x: hip.x + swing * 2.4, y: 0.7 + max(0, -sin(phase + offset)) * 1.4)
            DrawnRunner.stroke([CGPoint(x: hip.x + swing * 0.6, y: hip.y), foot], width: 0.9, in: context)
            DrawnRunner.stroke([foot, CGPoint(x: foot.x + 1.4, y: foot.y)], width: 0.9, in: context)
        }

        context.saveGState()
        context.translateBy(x: 0, y: bounce)
        DrawnRunner.fill(CGPoint(x: 8.6, y: 7.4), CGSize(width: 11.4, height: 9.6), in: context)          // 몸
        DrawnRunner.fill(CGPoint(x: 12.6, y: 11.4), CGSize(width: 8.6, height: 8.0), in: context)         // 큰 머리
        DrawnRunner.polygon([CGPoint(x: 3.6, y: 9.0), CGPoint(x: 0.8, y: 11.2), CGPoint(x: 3.2, y: 7.0)], in: context)  // 꽁지
        DrawnRunner.polygon([CGPoint(x: 16.4, y: 12.4), CGPoint(x: 19.4, y: 11.2), CGPoint(x: 16.4, y: 10.0)], in: context)  // 부리
        DrawnRunner.stroke([CGPoint(x: 12.0, y: 15.0), CGPoint(x: 11.5, y: 16.2)], width: 0.9, in: context)  // 정수리 솜털
        DrawnRunner.stroke([CGPoint(x: 12.8, y: 15.2), CGPoint(x: 13.3, y: 16.2)], width: 0.9, in: context)
        DrawnRunner.eye(CGPoint(x: 14.0, y: 12.4), size: CGSize(width: 1.5, height: 1.6), in: context)
        // 날개: 몸 뒤쪽 위로 파닥인다
        DrawnRunner.fill(CGPoint(x: 5.8, y: 9.4 + sin(phase * 2) * 0.6), CGSize(width: 5.6, height: 2.6), rotated: 24 + sin(phase * 2) * 26, in: context)
        context.restoreGState()
    }
}

/// 펭귄: 똑바로 서서 몸을 좌우로 기울이며 뒤뚱뒤뚱 걷는다. 18×18pt, 8프레임.
enum PenguinSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "penguin", nameKey: "runner.penguin", width: 18, frameCount: frameCount, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        let tilt = sin(phase) * 9
        let lift = abs(sin(phase)) * 0.4

        // 번갈아 들리는 납작한 발
        DrawnRunner.fill(CGPoint(x: 7.2, y: 0.8 + max(0, sin(phase)) * 0.9), CGSize(width: 3.8, height: 1.4), in: context)
        DrawnRunner.fill(CGPoint(x: 10.6, y: 0.8 + max(0, -sin(phase)) * 0.9), CGSize(width: 3.8, height: 1.4), in: context)

        // 발을 축으로 몸 전체를 기울인다
        context.saveGState()
        context.translateBy(x: 9, y: 1.4 + lift)
        context.rotate(by: tilt * .pi / 180)
        context.translateBy(x: -9, y: -1.4)
        DrawnRunner.fill(CGPoint(x: 8.8, y: 7.6), CGSize(width: 10.4, height: 13.0), in: context)          // 몸
        DrawnRunner.fill(CGPoint(x: 9.8, y: 13.2), CGSize(width: 7.6, height: 6.8), in: context)          // 머리
        DrawnRunner.polygon([CGPoint(x: 13.0, y: 14.0), CGPoint(x: 16.4, y: 13.0), CGPoint(x: 13.0, y: 12.0)], in: context)  // 부리
        // 날개: 몸 뒤로 퍼덕
        DrawnRunner.fill(CGPoint(x: 3.8, y: 8.2), CGSize(width: 2.6, height: 7.2), rotated: 22 + sin(phase * 2) * 14, in: context)
        DrawnRunner.eye(CGPoint(x: 11.4, y: 14.2), in: context)
        context.restoreGState()
    }
}

/// 물속 동물의 몸: 꼬리에서 머리까지 이어진 등뼈 곡선을 따라 두께를 입혀, 몸 전체가 물결치듯 휘는 실루엣을 만든다.
/// 돌고래 러너처럼 세부(입·아가미 등) 없이 그림자 같은 윤곽만 쓴다.
enum SwimmerBody {
    struct Spine {
        /// 꼬리 끝(t=0)과 코끝(t=1)의 x
        var tailX: CGFloat
        var noseX: CGFloat
        var baseY: CGFloat
        /// 꼬리 쪽이 크게 흔들리는 물결 폭
        var wave: CGFloat
        var phase: CGFloat
        /// 꼬리 쪽이 위로 휘어 올라가는 정도(고래)
        var curl: CGFloat = 0

        func point(_ t: CGFloat) -> CGPoint {
            CGPoint(
                x: tailX + (noseX - tailX) * t,
                y: baseY + wave * pow(1 - t, 1.6) * sin(phase - t * 2.4) + curl * pow(1 - t, 2.2)
            )
        }

        /// t 위치에서 몸이 기운 각도(라디안)
        func slope(_ t: CGFloat) -> CGFloat {
            let a = point(max(0, t - 0.02)), b = point(min(1, t + 0.02))
            return atan2(b.y - a.y, b.x - a.x)
        }
    }

    /// thickness(t) 는 그 위치의 몸 두께(pt)
    static func fill(_ spine: Spine, thickness: (CGFloat) -> CGFloat, in context: CGContext) {
        let steps = 40
        var top: [CGPoint] = [], bottom: [CGPoint] = []
        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let center = spine.point(t), normal = spine.slope(t) + .pi / 2, half = thickness(t) / 2
            top.append(CGPoint(x: center.x + cos(normal) * half, y: center.y + sin(normal) * half))
            bottom.append(CGPoint(x: center.x - cos(normal) * half, y: center.y - sin(normal) * half))
        }
        DrawnRunner.polygon(top + bottom.reversed(), in: context)
    }

    /// 몸의 t 위치에 붙은 지느러미: 몸 기울기를 따라 돌린 다각형(로컬 좌표, x 는 몸 방향)
    static func fin(_ spine: Spine, at t: CGFloat, _ points: [CGPoint], in context: CGContext) {
        let origin = spine.point(t), angle = spine.slope(t)
        DrawnRunner.polygon(points.map { p in
            CGPoint(x: origin.x + p.x * cos(angle) - p.y * sin(angle), y: origin.y + p.x * sin(angle) + p.y * cos(angle))
        }, in: context)
    }
}

/// 고래: 크고 동그란 머리, 꼬리로 갈수록 가늘어지며 위로 휘어 올라간 몸, 위로 펼친 꼬리지느러미.
/// 꼬리를 위아래로 저으며 천천히 떠간다. 30×18pt, 8프레임.
enum WhaleSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        // 한 번 헤엄치는 데 속도 1 에서 3초: 큰 몸이 느긋하게 움직인다
        DrawnRunner.make(id: "whale", nameKey: "runner.whale", width: 30, frameCount: frameCount, baseFrameRate: 8 / 3, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        let flap = sin(phase)
        let spine = SwimmerBody.Spine(tailX: 6.2, noseX: 28.8, baseY: 7.0 + cos(phase) * 0.3, wave: 0.6, phase: phase, curl: 5.0 + flap * 1.3)
        // 꼬리자루는 가늘고, 머리 쪽은 메뉴바 높이를 거의 채울 만큼 동그랗게 크다
        SwimmerBody.fill(spine, thickness: { t in
            t < 0.62 ? 1.8 + 12.4 * pow(sin(.pi / 2 * t / 0.62), 1.9) : 14.2 * sqrt(max(0.16, 1 - pow((t - 0.62) / 0.42, 2)))
        }, in: context)
        DrawnRunner.fill(spine.point(0.9), CGSize(width: 6.6, height: 10.4), in: context)
        // 위로 펼친 꼬리지느러미(Y)
        let tail = spine.point(0)
        for (angle, side) in [(CGFloat(128), CGFloat(-1)), (56, 1)] {
            let a = (angle + flap * 10) * .pi / 180
            DrawnRunner.fill(CGPoint(x: tail.x + cos(a) * 2.2, y: tail.y + sin(a) * 2.2), CGSize(width: 4.6, height: 2.1), rotated: angle + flap * 10 + side * 6, in: context)
        }
        DrawnRunner.eye(CGPoint(x: spine.point(0.84).x + 1.6, y: spine.point(0.84).y + 1.4), size: CGSize(width: 1.5, height: 1.6), in: context)
    }
}

/// 상어(백상아리): 머리를 살짝 든 굵은 몸, 뾰족한 코, 하얀 눈, 덥석덥석 벌렸다 닫는 입,
/// 큰 삼각 등지느러미와 길게 뻗은 가슴지느러미, 위아래로 펼친 초승달 꼬리. 34×18pt, 8프레임.
enum SharkSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "shark", nameKey: "runner.shark", width: 34, frameCount: frameCount, baseFrameRate: 3, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        // 꼬리 쪽이 조금 낮아 머리를 든 자세
        let spine = SwimmerBody.Spine(tailX: 6.4, noseX: 32.8, baseY: 8.4, wave: 1.6, phase: phase, curl: -2.2)
        SwimmerBody.fill(spine, thickness: { t in
            t < 0.6 ? 1.5 + 8.1 * pow(sin(.pi / 2 * t / 0.6), 1.2) : 9.6 * (1 - pow((t - 0.6) / 0.4, 1.8))
        }, in: context)
        // 위아래로 펼친 초승달 꼬리(위 갈래가 조금 더 길다)
        SwimmerBody.fin(spine, at: 0, [CGPoint(x: 1.2, y: 0.8), CGPoint(x: -1.6, y: 7.0), CGPoint(x: -0.8, y: 0), CGPoint(x: -1.6, y: -5.6), CGPoint(x: 1.2, y: -0.8)], in: context)
        // 큰 삼각 등지느러미, 꼬리 쪽 작은 지느러미 두 개
        SwimmerBody.fin(spine, at: 0.55, [CGPoint(x: -3.2, y: 3.8), CGPoint(x: -0.4, y: 10.0), CGPoint(x: 2.4, y: 4.0)], in: context)
        SwimmerBody.fin(spine, at: 0.16, [CGPoint(x: -1.0, y: 0.8), CGPoint(x: -0.2, y: 2.4), CGPoint(x: 0.8, y: 0.8)], in: context)
        SwimmerBody.fin(spine, at: 0.2, [CGPoint(x: -1.0, y: -0.8), CGPoint(x: -0.6, y: -2.6), CGPoint(x: 0.8, y: -0.8)], in: context)
        // 아래로 길게 뻗은 가슴지느러미
        SwimmerBody.fin(spine, at: 0.66, [CGPoint(x: 1.4, y: -3.6), CGPoint(x: -3.0, y: -9.0 + sin(phase) * 0.6), CGPoint(x: -1.4, y: -3.2)], in: context)

        // 하얀 눈과 덥석 벌리는 입(코 아래를 쐐기 모양으로 비운다)
        let head = spine.point(0.8), angle = spine.slope(0.8)
        func local(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: head.x + x * cos(angle) - y * sin(angle), y: head.y + x * sin(angle) + y * cos(angle))
        }
        let open: CGFloat = [0.2, 0.9, 1.6, 0.9, 0.2, 0.5, 1.1, 0.5][frame]
        context.saveGState()
        context.setBlendMode(.clear)
        // 입: 머리 아래쪽에서 앞으로 벌어지는 쐐기(코끝은 남긴다)
        DrawnRunner.polygon([local(-0.6, -1.8), local(6.4, -0.9 + open * 0.3), local(6.4, -2.0 - open * 1.1)], in: context)
        context.restoreGState()
        DrawnRunner.eye(local(0.8, 1.2), size: CGSize(width: 1.5, height: 1.5), in: context)
    }
}
