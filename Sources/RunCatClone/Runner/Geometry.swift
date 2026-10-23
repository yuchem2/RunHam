import CoreGraphics

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}

extension CGPoint {
    /// 수직 아래 기준 angle(도) 방향으로 length 만큼 이동. 양수 각도는 +x(앞)쪽.
    func moved(angle: CGFloat, length: CGFloat) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(x: x + sin(radians) * length, y: y - cos(radians) * length)
    }
}
