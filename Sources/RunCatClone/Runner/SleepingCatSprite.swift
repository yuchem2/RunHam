import CoreGraphics

/// 메트릭스 바에 아무 항목도 켜지 않았을 때 보여 줄 도트 자는 고양이(28×18pt, 1프레임).
/// 러너와 같은 방식으로 부품(식빵 자세 몸통, 감은 눈 머리, 꼬리, Z)을 찍어 만든다.
enum SleepingCatSprite {
    static let pointSize = CGSize(width: 28, height: 18)

    /// 식빵 자세 몸통 15×6
    static let body = PixelSprite([
        "...#########...",
        ".#############.",
        "###############",
        "###############",
        "###############",
        ".#############.",
    ])

    /// 머리 9×8. 눈은 가로로 긴 구멍(감은 눈), 볼은 반투명.
    static let head = PixelSprite([
        ".#.....#.",
        ".##...##.",
        "#+#####+#",
        "#########",
        "#oo###oo#",
        "#########",
        "#+#####+#",
        ".#######.",
    ])

    /// 몸 앞쪽으로 말아 둔 꼬리
    static let tail = PixelSprite([
        "##.........",
        "###########",
    ])

    static let bigZ = PixelSprite([
        "####",
        "..#.",
        ".#..",
        "####",
    ])

    static let smallZ = PixelSprite([
        "###",
        ".#.",
        "###",
    ])

    static let image: CGImage = {
        var canvas = PixelCanvas(width: Int(pointSize.width), height: Int(pointSize.height))
        canvas.stamp(body, x: 2, y: 12)
        canvas.stamp(tail, x: 1, y: 16)
        canvas.stamp(head, x: 14, y: 9)
        canvas.stamp(smallZ, x: 20, y: 4)
        canvas.stamp(bigZ, x: 23, y: 0)
        return canvas.makeImage(scale: Int(Runner.scale))
    }()
}
