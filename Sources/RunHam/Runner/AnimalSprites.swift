import CoreGraphics

/// 병아리: 머리와 몸이 하나로 이어진 동글동글한 덩어리에 작은 부리·꽁지·가는 다리.
/// 통통 뛰며 종종걸음으로 간다. 20×18pt, 6프레임.
enum ChickSprite {
    static let frameCount = 6

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "chick", nameKey: "runner.chick", width: 20, frameCount: frameCount, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        let hop = abs(sin(phase))
        // 땅에 닿을 때 살짝 납작해진다
        let squash = 1 - (1 - hop) * 0.06
        let lift = 1.8 + hop * 1.4

        // 가는 다리와 세 갈래 발: 번갈아 앞으로
        for (index, x) in [CGFloat(8.6), 11.0].enumerated() {
            let step = sin(phase + CGFloat(index) * .pi) * 1.0
            let foot = CGPoint(x: x + step, y: 0.6 + max(0, step) * 0.5)
            DrawnRunner.stroke([CGPoint(x: x, y: lift + 1.2), foot], width: 0.8, in: context)
            DrawnRunner.stroke([CGPoint(x: foot.x - 0.6, y: foot.y), CGPoint(x: foot.x + 1.4, y: foot.y)], width: 0.8, in: context)
        }

        context.saveGState()
        context.translateBy(x: 10, y: lift)
        context.scaleBy(x: 1 / squash, y: squash)
        // 몸통과 머리가 이어진 하나의 둥근 덩어리(아래가 더 통통한 달걀형)
        DrawnRunner.fill(CGPoint(x: -0.4, y: 5.6), CGSize(width: 14.6, height: 11.4), in: context)
        DrawnRunner.fill(CGPoint(x: 1.6, y: 9.2), CGSize(width: 10.8, height: 10.2), in: context)
        // 뒤로 살짝 솟은 꽁지
        DrawnRunner.polygon([CGPoint(x: -6.6, y: 7.0), CGPoint(x: -8.8, y: 9.6), CGPoint(x: -6.0, y: 9.4)], in: context)
        // 작은 세모 부리
        DrawnRunner.polygon([CGPoint(x: 6.6, y: 11.6), CGPoint(x: 9.0, y: 10.6), CGPoint(x: 6.6, y: 9.6)], in: context)
        // 뒤쪽 옆구리에 쏙 나온 작은 날개가 파닥인다
        DrawnRunner.fill(CGPoint(x: -6.4, y: 4.6), CGSize(width: 4.2, height: 2.4), rotated: 30 + sin(phase * 2) * 22, in: context)
        DrawnRunner.eye(CGPoint(x: 3.6, y: 10.6), size: CGSize(width: 1.7, height: 1.8), in: context)
        context.restoreGState()
    }
}

/// 펭귄: 정면을 보고 뒤뚱뒤뚱. 둥근 몸에 하얀 얼굴·배(하트 모양), 그 안에 까만 눈·부리,
/// 양옆으로 벌린 날개와 납작한 발. 18×18pt, 8프레임.
enum PenguinSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "penguin", nameKey: "runner.penguin", width: 18, frameCount: frameCount, baseFrameRate: 4, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        let rock = sin(phase)

        // 번갈아 들리는 발
        DrawnRunner.fill(CGPoint(x: 6.4, y: 0.8 + max(0, rock) * 0.8), CGSize(width: 3.6, height: 1.5), in: context)
        DrawnRunner.fill(CGPoint(x: 11.6, y: 0.8 + max(0, -rock) * 0.8), CGSize(width: 3.6, height: 1.5), in: context)

        // 발을 디딘 쪽을 축으로 몸을 좌우로 기울인다
        context.saveGState()
        context.translateBy(x: 9, y: 1.4)
        context.rotate(by: -rock * 8 * .pi / 180)
        // 양옆 날개: 걸음마다 파닥
        for side: CGFloat in [-1, 1] {
            let flap: CGFloat = 18 + (side * rock > 0 ? 14 : 0)
            DrawnRunner.fill(CGPoint(x: side * 6.0, y: 6.4), CGSize(width: 2.4, height: 6.2), rotated: side * flap, in: context)
        }
        // 둥근 몸
        DrawnRunner.fill(CGPoint(x: 0, y: 7.6), CGSize(width: 12.6, height: 15.0), in: context)
        // 하얀 얼굴과 배: 두 눈 주위 동그라미 + 배 타원이 이어진 하트 모양
        context.saveGState()
        context.setBlendMode(.clear)
        DrawnRunner.fill(CGPoint(x: -2.0, y: 10.2), CGSize(width: 5.2, height: 5.0), in: context)
        DrawnRunner.fill(CGPoint(x: 2.0, y: 10.2), CGSize(width: 5.2, height: 5.0), in: context)
        DrawnRunner.fill(CGPoint(x: 0, y: 5.4), CGSize(width: 9.6, height: 8.6), in: context)
        context.restoreGState()
        // 까만 눈과 작은 부리
        DrawnRunner.fill(CGPoint(x: -2.0, y: 10.6), CGSize(width: 1.6, height: 1.8), in: context)
        DrawnRunner.fill(CGPoint(x: 2.0, y: 10.6), CGSize(width: 1.6, height: 1.8), in: context)
        DrawnRunner.polygon([CGPoint(x: -1.1, y: 9.2), CGPoint(x: 1.1, y: 9.2), CGPoint(x: 0, y: 7.6)], in: context)
        context.restoreGState()
    }
}

/// 고래(인형): 통통한 몸에서 꼬리까지 한 덩어리로 이어진 뜨개 인형 같은 고래. 위로 휘어 올라간 꼬리 끝에 Y 자 지느러미,
/// 배 아래 앞지느러미, 하얀 눈. 몸은 모양이 변하지 않은 채 코사인 물결을 타고, 꼬리만 한 박자 늦게 휜다. 26×18pt, 8프레임.
enum WhaleSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        // 한 번 헤엄치는 데 속도 1 에서 2.5초
        DrawnRunner.make(
            id: "whale", nameKey: "runner.whale", width: 26, frameCount: frameCount, baseFrameRate: 8 / 2.5,
            smoothing: 0.85,
            details: details,
            draw: draw
        )
    }

    private static func phase(_ frame: Int) -> CGFloat {
        DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
    }

    /// 몸 전체를 하나로: 코사인 물결을 따라 오르내리고, 오를 때 머리를 들고 내려갈 때 숙인다
    private static func place(_ frame: Int, in context: CGContext) {
        let p = phase(frame)
        context.translateBy(x: 14.4, y: 8.6 + cos(p) * 1.0)
        context.rotate(by: -sin(p) * 9 * .pi / 180)
        context.scaleBy(x: 0.8, y: 0.8)
    }

    /// 꼬리 위치 t(0 몸 쪽 … 1 끝)의 중심. 꼬리는 몸보다 한 박자 늦게, 끝으로 갈수록 크게 휜다
    private static func tail(_ t: CGFloat, _ frame: Int) -> CGPoint {
        let flex = sin(phase(frame) - 1.3) * 2.0
        return CGPoint(x: -4.0 - t * 5.6, y: 0.4 + t * t * 5.0 + t * t * flex)
    }

    static func draw(frame: Int, in context: CGContext) {
        place(frame, in: context)
        // 통통한 몸과 빵빵한 아랫배, 앞지느러미: 모양이 매 프레임 같아 배 윤곽이 흔들리지 않는다
        DrawnRunner.fill(CGPoint(x: 1.6, y: 0.6), CGSize(width: 15.4, height: 12.6), in: context)
        DrawnRunner.fill(CGPoint(x: 1.2, y: -2.2), CGSize(width: 15.6, height: 8.4), in: context)
        flipper(in: context)
        // 몸에서 꼬리 끝까지 점점 작아지는 동그라미를 촘촘히 이어, 다듬으면 끊김 없이 가늘어지는 꼬리가 된다
        for index in 0...20 {
            let t = CGFloat(index) / 20, size = 9.0 - t * 6.6
            DrawnRunner.fill(tail(t, frame), CGSize(width: size, height: size * 0.95), in: context)
        }
    }

    /// 배 아래 앞지느러미: 뒤쪽 아래를 향해 쏙 나온다
    private static func flipper(in context: CGContext) {
        DrawnRunner.fill(CGPoint(x: 0.8, y: -6.9), CGSize(width: 5.4, height: 2.2), rotated: 30, in: context)
    }

    /// 다듬기에 뭉개지지 않게 몸을 다듬은 뒤에 또렷하게 그리는 부분: 꼬리지느러미, 앞지느러미, 눈
    static func details(frame: Int, in context: CGContext) {
        place(frame, in: context)
        // 꼬리 끝에서 같은 크기의 잎사귀 두 장이 꼬리 방향을 기준으로 Y 자로 벌어진다
        let tip = tail(1, frame), before = tail(0.85, frame)
        let direction = atan2(tip.y - before.y, tip.x - before.x)
        for side: CGFloat in [-1, 1] {
            let angle = direction + side * 0.8
            let center = CGPoint(x: tip.x + cos(angle) * 2.0, y: tip.y + sin(angle) * 2.0)
            DrawnRunner.fill(center, CGSize(width: 4.4, height: 2.0), rotated: angle * 180 / .pi, in: context)
        }
        flipper(in: context)
        DrawnRunner.eye(CGPoint(x: 5.4, y: 1.4), size: CGSize(width: 1.6, height: 1.8), in: context)
    }
}

/// 물속 동물의 몸: 꼬리에서 머리까지 이어진 등뼈 곡선을 따라 두께를 입혀, 몸 전체가 물결치듯 휘는 실루엣을 만든다.
enum SwimmerBody {
    struct Spine {
        /// 꼬리 끝(t=0)과 코끝(t=1)의 x
        var tailX: CGFloat
        var noseX: CGFloat
        var baseY: CGFloat
        /// 꼬리 쪽이 크게 흔들리는 물결 폭
        var wave: CGFloat
        var phase: CGFloat
        /// 꼬리 쪽이 위로 휘어 올라가는 정도
        var curl: CGFloat = 0
        /// 0 이 아니면 몸 전체가 코사인 물결을 타고 넘는다: 머리가 먼저 오르내리고 꼬리가 그 길을 뒤따른다.
        /// 값은 몸 길이에 걸친 위상 차(라디안)
        var travel: CGFloat = 0

        func point(_ t: CGFloat) -> CGPoint {
            let x = tailX + (noseX - tailX) * t
            if travel != 0 {
                return CGPoint(x: x, y: baseY + wave * cos(phase - (1 - t) * travel) + curl * pow(1 - t, 2.2))
            }
            return CGPoint(x: x, y: baseY + wave * pow(1 - t, 1.6) * sin(phase - t * 2.4) + curl * pow(1 - t, 2.2))
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

/// 상어(백상아리): 머리를 살짝 든 굵은 몸, 뾰족한 코, 하얀 눈, 덥석덥석 벌렸다 닫는 입,
/// 큰 삼각 등지느러미와 길게 뻗은 가슴지느러미, 위아래로 펼친 초승달 꼬리. 몸 전체가 코사인 물결을 타듯 헤엄친다. 34×18pt, 8프레임.
enum SharkSprite {
    static let frameCount = 8

    static func makeRunner() -> Runner {
        DrawnRunner.make(id: "shark", nameKey: "runner.shark", width: 34, frameCount: frameCount, baseFrameRate: 3, draw: draw)
    }

    static func draw(frame: Int, in context: CGContext) {
        let phase = DrawnRunner.phase(frame, of: frameCount) * 2 * .pi
        // 몸 전체가 코사인 물결을 타고 넘는다: 머리가 먼저 오르내리고 꼬리가 그 길을 뒤따른다
        context.translateBy(x: 17, y: 9)
        context.scaleBy(x: 0.86, y: 0.86)
        context.translateBy(x: -17, y: -9)
        let spine = SwimmerBody.Spine(tailX: 6.4, noseX: 32.8, baseY: 8.9, wave: 1.1, phase: phase, curl: -1.0, travel: 2.6)
        SwimmerBody.fill(spine, thickness: { t in
            t < 0.6 ? 1.5 + 8.1 * pow(sin(.pi / 2 * t / 0.6), 1.2) : 9.6 * (1 - pow((t - 0.6) / 0.4, 1.8))
        }, in: context)
        // 위아래로 펼친 초승달 꼬리(위 갈래가 조금 더 길다)
        SwimmerBody.fin(spine, at: 0, [CGPoint(x: 1.2, y: 0.8), CGPoint(x: -1.6, y: 7.0), CGPoint(x: -0.8, y: 0), CGPoint(x: -1.6, y: -5.6), CGPoint(x: 1.2, y: -0.8)], in: context)
        // 큰 삼각 등지느러미, 꼬리 쪽 작은 지느러미 두 개
        SwimmerBody.fin(spine, at: 0.55, [CGPoint(x: -3.2, y: 3.8), CGPoint(x: -0.4, y: 9.2), CGPoint(x: 2.4, y: 4.0)], in: context)
        SwimmerBody.fin(spine, at: 0.16, [CGPoint(x: -1.0, y: 0.8), CGPoint(x: -0.2, y: 2.4), CGPoint(x: 0.8, y: 0.8)], in: context)
        SwimmerBody.fin(spine, at: 0.2, [CGPoint(x: -1.0, y: -0.8), CGPoint(x: -0.6, y: -2.6), CGPoint(x: 0.8, y: -0.8)], in: context)
        // 아래로 길게 뻗은 가슴지느러미
        SwimmerBody.fin(spine, at: 0.66, [CGPoint(x: 1.4, y: -3.6), CGPoint(x: -2.8, y: -7.4 + sin(phase) * 0.6), CGPoint(x: -1.4, y: -3.2)], in: context)

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
