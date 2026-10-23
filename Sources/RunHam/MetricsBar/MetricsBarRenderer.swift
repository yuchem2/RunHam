import AppKit

/// 메트릭스 바에 그릴 항목 하나.
struct MetricsBarItem: Equatable, Sendable {
    enum Content: Equatable, Sendable {
        /// 한 줄 값. 폭은 `reference` 기준으로 고정해 숫자가 바뀌어도 흔들리지 않게 한다.
        case value(String, reference: String)
        /// 위아래 두 줄 작은 글씨(네트워크 ↑/↓)
        case dual(top: String, bottom: String)
        /// 길이가 정해지지 않은 사용자 값(Custom Metrics). 최대 폭에서 잘린다.
        case freeform(String)
        case iconOnly
    }

    var symbol: String
    var content: Content
}

/// 메트릭스 바 전체를 한 장의 템플릿 이미지로 그린다.
///
/// 상태바에 뷰를 올리지 않고 이미지 한 장만 넘기므로 메뉴바 색 대응과 다른 화면용 복제본(replicant)을
/// 시스템이 알아서 처리한다. 항목 크기(아이콘 22pt, 간격 4pt, 값 폭, 사용자 값 최대 80pt)는
/// RunCat Neo 의 MetricsBarView / IndicatorKind (Copyright 2026 Kyome22, Apache License 2.0) 를 참고했다.
enum MetricsBarRenderer {
    static let height: CGFloat = 18
    static let iconSize = CGSize(width: 22, height: 16)
    static let spacing: CGFloat = 4
    static let freeformMaxWidth: CGFloat = 80

    // NSFont 는 Sendable 이 아니라 전역 상수로 둘 수 없어 계산 속성으로 둔다(캐시되는 시스템 폰트라 비용은 작다).
    static var valueFont: NSFont { .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular) }
    static var smallFont: NSFont { .monospacedSystemFont(ofSize: 7.5, weight: .medium) }
    static var symbolConfiguration: NSImage.SymbolConfiguration { .init(pointSize: 12, weight: .medium) }

    static func textWidth(_ text: String, font: NSFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    static func contentWidth(_ content: MetricsBarItem.Content) -> CGFloat {
        switch content {
        case let .value(_, reference):
            textWidth(reference, font: valueFont)
        case let .dual(top, bottom):
            // 단위가 바뀌어도 폭이 흔들리지 않게 가장 긴 형태 기준.
            max(textWidth("↑999.9KB/s", font: smallFont), textWidth(top, font: smallFont), textWidth(bottom, font: smallFont))
        case let .freeform(text):
            min(textWidth(text, font: valueFont) + 4, freeformMaxWidth)
        case .iconOnly:
            0
        }
    }

    static func width(of items: [MetricsBarItem]) -> CGFloat {
        guard !items.isEmpty else { return SleepingHamsterSprite.pointSize.width }
        let widths = items.map { iconSize.width + contentWidth($0.content) }
        return ceil(widths.reduce(0, +) + spacing * CGFloat(widths.count - 1))
    }

    /// 비어 있으면 자는 고양이를 그린다(원본과 같은 빈 상태).
    static func image(for items: [MetricsBarItem]) -> NSImage {
        guard !items.isEmpty else {
            let image = NSImage(cgImage: SleepingHamsterSprite.image, size: SleepingHamsterSprite.pointSize)
            image.isTemplate = true
            return image
        }
        let size = CGSize(width: width(of: items), height: height)
        // drawingHandler 이미지는 그려질 때마다(복제본 포함) 다시 그리므로 1x·2x 비트맵으로 한 번만 래스터화한다.
        let image = NSImage(size: size)
        for scale in [1, 2] {
            guard let rep = rasterize(items, size: size, scale: scale) else { continue }
            image.addRepresentation(rep)
        }
        image.isTemplate = true
        return image
    }

    private static func rasterize(_ items: [MetricsBarItem], size: CGSize, scale: Int) -> NSBitmapImageRep? {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width) * scale,
            pixelsHigh: Int(size.height) * scale,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        // 컨텍스트를 만들기 전에 포인트 크기를 정해야 2x 비트맵에 배율이 적용된다.
        rep.size = size
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        // 위에서 아래로 배치하도록 뒤집는다.
        context.cgContext.translateBy(x: 0, y: size.height)
        context.cgContext.scaleBy(x: 1, y: -1)
        let flipped = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
        NSGraphicsContext.current = flipped

        var x: CGFloat = 0
        for item in items {
            drawSymbol(item.symbol, in: CGRect(x: x, y: (height - iconSize.height) / 2, width: iconSize.width, height: iconSize.height))
            x += iconSize.width
            let width = contentWidth(item.content)
            drawContent(item.content, in: CGRect(x: x, y: 0, width: width, height: height))
            x += width + spacing
        }
        return rep
    }

    private static func drawSymbol(_ name: String, in rect: CGRect) {
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(symbolConfiguration) else { return }
        let size = symbol.size
        let scale = min(rect.width / size.width, rect.height / size.height, 1)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        symbol.draw(in: CGRect(
            x: rect.midX - fitted.width / 2,
            y: rect.midY - fitted.height / 2,
            width: fitted.width,
            height: fitted.height
        ))
    }

    private static func drawContent(_ content: MetricsBarItem.Content, in rect: CGRect) {
        switch content {
        case let .value(text, _), let .freeform(text):
            draw(text, font: valueFont, in: rect)
        case let .dual(top, bottom):
            let half = rect.height / 2
            draw(top, font: smallFont, in: CGRect(x: rect.minX, y: rect.minY + 1, width: rect.width, height: half))
            draw(bottom, font: smallFont, in: CGRect(x: rect.minX, y: rect.minY + half - 1, width: rect.width, height: half))
        case .iconOnly:
            break
        }
    }

    private static func draw(_ text: String, font: NSFont, in rect: CGRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black, .paragraphStyle: paragraph]
        let lineHeight = ceil(font.ascender - font.descender)
        let origin = CGPoint(x: rect.minX, y: rect.minY + (rect.height - lineHeight) / 2)
        (text as NSString).draw(in: CGRect(origin: origin, size: CGSize(width: rect.width, height: lineHeight)), withAttributes: attributes)
    }
}
