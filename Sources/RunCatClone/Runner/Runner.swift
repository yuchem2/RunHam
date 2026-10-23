import CoreGraphics

/// 메뉴바에서 반복 재생할 프레임 묶음. 프레임은 높이 36px(@2x) 알파 마스크 이미지다.
struct Runner: @unchecked Sendable {
    static let pixelHeight = 36
    static let scale: CGFloat = 2

    let id: String
    /// 표시 이름의 현지화 키(runner.cat 등). 언어를 바꾸면 이름도 바뀐다.
    let nameKey: String
    let frames: [CGImage]
    /// 도트 러너는 확대·축소할 때 nearest 로, 벡터 러너는 부드럽게 보간한다.
    let isPixelArt: Bool
    /// 설정 창 미리보기처럼 크게 보여 줄 때 쓰는 프레임. 벡터 러너는 고해상도로 따로 그린다.
    let previewFrames: [CGImage]

    /// 속도 1 에서 초당 프레임 수. 원본 규칙은 2 이고, 프레임이 많은 러너는 한 주기(보폭) 시간이
    /// 원본과 같아지도록 올린다(예: 7프레임 → 2.8).
    let baseFrameRate: Double

    init(
        id: String,
        nameKey: String,
        frames: [CGImage],
        isPixelArt: Bool,
        previewFrames: [CGImage]? = nil,
        baseFrameRate: Double = 2
    ) {
        self.id = id
        self.baseFrameRate = baseFrameRate
        self.nameKey = nameKey
        self.frames = frames
        self.isPixelArt = isPixelArt
        self.previewFrames = previewFrames ?? frames
    }

    var name: String { L(nameKey) }

    var pointSize: CGSize {
        guard let first = frames.first else { return .zero }
        return CGSize(width: CGFloat(first.width) / Self.scale, height: CGFloat(first.height) / Self.scale)
    }

    /// 속도 1 에서 한 주기 시간. 원본(초당 2프레임)은 `frameCount / 2`.
    var cycleDuration: Double { Double(frames.count) / baseFrameRate }
}

extension Runner {
    static let builtIns: [Runner] = [SleekCatSprite.makeRunner(), ChubbyCatSprite.makeRunner(), PixelCatSprite.makeRunner()]

    static func builtIn(id: String) -> Runner {
        builtIns.first { $0.id == id } ?? builtIns[0]
    }
}

/// 투명 배경에 불투명 실루엣을 그리는 프레임 렌더러.
enum SpriteRenderer {
    static func render(width: Int, height: Int = Runner.pixelHeight, draw: (CGContext) -> Void) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        draw(context)
        return context.makeImage()!
    }
}
