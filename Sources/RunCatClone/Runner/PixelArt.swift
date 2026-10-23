import CoreGraphics

/// 도트 스프라이트. 문자열 한 줄이 한 행이고, 문자 하나가 한 픽셀이다.
///
/// - `#` 불투명, `+` 반투명(볼터치·귀 안쪽 같은 명암), `o` 구멍(아래에 그려진 것까지 지움, 눈 등)
/// - `.` 과 공백은 투명이며 아래 픽셀을 건드리지 않는다.
struct PixelSprite: Sendable {
    let rows: [String]

    init(_ rows: [String]) {
        self.rows = rows
    }

    var width: Int { rows.map(\.count).max() ?? 0 }
    var height: Int { rows.count }

    /// 좌우 반전본. 다리 방향을 반대로 쓸 때 사용한다.
    var mirrored: PixelSprite {
        PixelSprite(rows.map { String($0.padding(toLength: width, withPad: ".", startingAt: 0).reversed()) })
    }
}

/// 픽셀 단위로 스프라이트를 합성한 뒤 정수배 nearest-neighbor 로 키워 CGImage 를 만든다.
/// 1 아트 픽셀 = 1pt = @2x 에서 2×2 디바이스 픽셀이라 메뉴바에서 번지지 않고 또렷하다.
struct PixelCanvas {
    static let solid = 1.0
    static let shade = 0.45

    let width: Int
    let height: Int
    private(set) var alpha: [Double]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        alpha = Array(repeating: 0, count: width * height)
    }

    subscript(x: Int, y: Int) -> Double {
        get { alpha[y * width + x] }
        set {
            guard (0..<width).contains(x), (0..<height).contains(y) else { return }
            alpha[y * width + x] = newValue
        }
    }

    /// (x, y) 는 스프라이트 왼쪽 위 모서리. 캔버스 밖은 잘린다.
    mutating func stamp(_ sprite: PixelSprite, x: Int, y: Int) {
        for (row, line) in sprite.rows.enumerated() {
            for (column, character) in line.enumerated() {
                let px = x + column
                let py = y + row
                guard (0..<width).contains(px), (0..<height).contains(py) else { continue }
                switch character {
                case "#": self[px, py] = Self.solid
                case "+": self[px, py] = Self.shade
                case "o": self[px, py] = 0
                default: break
                }
            }
        }
    }

    func makeImage(scale: Int) -> CGImage {
        SpriteRenderer.render(width: width * scale, height: height * scale) { context in
            context.setShouldAntialias(false)
            for y in 0..<height {
                for x in 0..<width where self[x, y] > 0 {
                    context.setFillColor(CGColor(gray: 0, alpha: self[x, y]))
                    // CGContext 는 원점이 왼쪽 아래라 행을 뒤집는다.
                    context.fill(CGRect(x: x * scale, y: (height - 1 - y) * scale, width: scale, height: scale))
                }
            }
        }
    }
}
