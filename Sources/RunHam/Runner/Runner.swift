import CoreGraphics

/// 메뉴바에서 반복 재생할 프레임 묶음. 프레임은 높이 36px(@2x) 이미지다.
/// 템플릿 러너는 알파만 마스크로 써서 메뉴바 글자색으로 칠하고, 색상 러너는 이미지를 그대로 보여 준다.
struct Runner: @unchecked Sendable {
    static let pixelHeight = 36
    static let scale: CGFloat = 2

    let id: String
    /// 표시 이름의 현지화 키(runner.cat 등). 언어를 바꾸면 이름도 바뀐다.
    let nameKey: String
    /// 커스텀 러너는 사용자가 정한 이름을 그대로 쓴다.
    let customName: String?
    /// false 면 메뉴바 글자색으로 칠하지 않고 이미지 색을 그대로 보여 준다(커스텀 러너의 "컬러").
    let isTemplate: Bool
    let frames: [CGImage]
    /// 도트 러너는 확대·축소할 때 nearest 로, 벡터 러너는 부드럽게 보간한다.
    let isPixelArt: Bool
    /// 설정 창 미리보기처럼 크게 보여 줄 때 쓰는 프레임. 벡터 러너는 고해상도로 따로 그린다.
    let previewFrames: [CGImage]

    /// 속도 1 에서 초당 프레임 수. 기본은 2 이고, 러너마다 한 주기(한 번 뛰기·헤엄치기)가
    /// 자연스러운 길이가 되도록 정한다.
    let baseFrameRate: Double

    init(
        id: String,
        nameKey: String,
        frames: [CGImage],
        isPixelArt: Bool,
        previewFrames: [CGImage]? = nil,
        baseFrameRate: Double = 2,
        customName: String? = nil,
        isTemplate: Bool = true
    ) {
        self.id = id
        self.customName = customName
        self.isTemplate = isTemplate
        self.baseFrameRate = baseFrameRate
        self.nameKey = nameKey
        self.frames = frames
        self.isPixelArt = isPixelArt
        self.previewFrames = previewFrames ?? frames
    }

    var name: String { customName ?? L(nameKey) }

    var isCustom: Bool { customName != nil }

    var pointSize: CGSize {
        // 커스텀 러너는 프레임마다 폭이 다를 수 있어 가장 넓은 프레임에 맞춘다.
        guard let width = frames.map(\.width).max(), let height = frames.map(\.height).max() else { return .zero }
        return CGSize(width: CGFloat(width) / Self.scale, height: CGFloat(height) / Self.scale)
    }

    /// 속도 1 에서 한 주기 시간
    var cycleDuration: Double { Double(frames.count) / baseFrameRate }
}

extension Runner {
    static let builtIns: [Runner] = [
        HamsterHopSprite.makeRunner(), HamsterBallSprite.makeRunner(), HamsterSnackSprite.makeRunner(),
        RollingHamsterSprite.makeRunner(), CheekyHamsterSprite.makeRunner(),
        CatSprite.makeRunner(), ChickSprite.makeRunner(), PenguinSprite.makeRunner(),
        WhaleSprite.makeRunner(), SharkSprite.makeRunner(),
    ]

    static func builtIn(id: String) -> Runner {
        builtIns.first { $0.id == id } ?? builtIns[0]
    }

    /// 기본 러너와 커스텀 러너를 함께 찾는다. 없으면(지운 커스텀 러너 등) 기본 햄스터.
    @MainActor
    static func resolve(id: String, custom: CustomRunnerStore) -> Runner {
        custom.runner(id: id) ?? builtIn(id: id)
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
