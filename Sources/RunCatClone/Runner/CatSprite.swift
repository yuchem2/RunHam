import CoreGraphics

/// 도트로 그린 고양이 러너 (28×18pt 캔버스, @2x 56×36px, 5프레임 갤럽).
/// 원본 에셋을 쓰지 않고 머리·몸통·꼬리·다리 부품을 프레임마다 다시 배치해 만든다.
enum CatSprite {
    static let canvasWidth = 28
    static let canvasHeight = 18
    static let pixelScale = 2

    static func makeRunner() -> Runner {
        Runner(id: "cat", nameKey: "runner.cat", frames: frames.map { render($0).makeImage(scale: pixelScale) })
    }

    // MARK: - 부품

    /// 머리 11×9. 정면을 보는 큰 얼굴이 몸통 앞쪽 위에 얹혀 2등신 느낌을 낸다.
    static let head = PixelSprite([
        ".#.......#.",
        ".##.....##.",
        ".#+#####+#.",
        "###########",
        "###o###o###",
        "###o###o###",
        "#+###+###+#",
        ".#########.",
        "..#######..",
    ])

    /// 몸통 10×5. 짧고 둥글게 해서 머리가 큰 2등신 비율을 만든다.
    static let body = PixelSprite([
        "..######..",
        ".########.",
        "##########",
        "##########",
        ".########.",
    ])

    enum Tail {
        case up, mid, down

        var sprite: PixelSprite {
            switch self {
            case .up:
                PixelSprite([
                    "##...",
                    "##...",
                    ".##..",
                    "..##.",
                    "...##",
                ])
            case .mid:
                PixelSprite([
                    "##....",
                    ".###..",
                    "...###",
                ])
            case .down:
                PixelSprite([
                    "....##",
                    "..###.",
                    "###...",
                ])
            }
        }

        /// 꼬리 오른쪽 끝이 몸통 왼쪽 위에 닿도록 몸통 기준 상대 위치로 둔다.
        var offset: (x: Int, y: Int) {
            switch self {
            case .up: (-4, -3)
            case .mid: (-5, -1)
            case .down: (-5, 1)
            }
        }
    }

    // MARK: - 프레임

    /// 다리는 프레임마다 몸통 아래 3행짜리 띠로 직접 그린다(짧은 다리가 더 귀엽다).
    /// 가까운 쪽 다리는 `#`, 먼 쪽 다리는 `+`(반투명)로 칠해 다리가 뭉치지 않고 앞뒤가 읽히게 한다.
    struct Pose {
        var lift: Int
        var tail: Tail
        var legs: PixelSprite
    }

    static let frames: [Pose] = [
        // 쭉 뻗기: 앞다리는 앞으로, 뒷다리는 뒤로
        Pose(lift: 0, tail: .mid, legs: PixelSprite([
            "..##++....++##..",
            ".##++......++##.",
            "##++........++##",
        ])),
        // 앞발 착지, 뒷다리 앞으로 끌어오기
        Pose(lift: 0, tail: .up, legs: PixelSprite([
            "..##++....++##..",
            "..##.++...++##..",
            ".##...++..++##..",
        ])),
        // 모으기: 네 다리를 배 밑으로 접고 몸이 떠오른다
        Pose(lift: 1, tail: .up, legs: PixelSprite([
            "...##+..+##.....",
            "....##..##......",
        ])),
        // 뒷발 착지, 앞다리 뻗을 준비
        Pose(lift: 0, tail: .mid, legs: PixelSprite([
            "...##++...++##..",
            "...##++....++##.",
            "...##++.....++##",
        ])),
        // 박차기: 뒷다리로 밀며 앞다리를 내민다
        Pose(lift: 0, tail: .down, legs: PixelSprite([
            "..##++...++##...",
            ".##++....++.##..",
            "##++.....++..##.",
        ])),
    ]

    static let bodyOrigin = (x: 8, y: 10)
    static let headOrigin = (x: 15, y: 3)
    /// 다리 띠의 왼쪽 끝 x
    static let legsX = 5

    static func render(_ pose: Pose) -> PixelCanvas {
        var canvas = PixelCanvas(width: canvasWidth, height: canvasHeight)
        let dy = -pose.lift
        let bodyY = bodyOrigin.y + dy

        canvas.stamp(pose.legs, x: legsX, y: bodyY + body.height)
        canvas.stamp(body, x: bodyOrigin.x, y: bodyY)
        canvas.stamp(pose.tail.sprite, x: bodyOrigin.x + pose.tail.offset.x, y: bodyY + pose.tail.offset.y)
        canvas.stamp(head, x: headOrigin.x, y: headOrigin.y + dy)
        return canvas
    }
}
