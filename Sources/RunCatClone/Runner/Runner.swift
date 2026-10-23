import CoreGraphics

/// 메뉴바에서 반복 재생할 프레임 묶음. 프레임은 높이 36px(@2x) 알파 마스크 이미지다.
struct Runner: @unchecked Sendable {
    static let pixelHeight = 36
    static let scale: CGFloat = 2

    let id: String
    let name: String
    let frames: [CGImage]

    var pointSize: CGSize {
        guard let first = frames.first else { return .zero }
        return CGSize(width: CGFloat(first.width) / Self.scale, height: CGFloat(first.height) / Self.scale)
    }

    /// 속도 1 에서 초당 2프레임 (`duration = frameCount / 2`).
    var cycleDuration: Double { Double(frames.count) / 2 }
}

extension Runner {
    static let builtIns: [Runner] = [CatSprite.makeRunner()]

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
