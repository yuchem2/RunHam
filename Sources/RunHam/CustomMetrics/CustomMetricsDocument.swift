import Foundation

/// RunCat Neo 의 Custom Metrics JSON 스키마(docs/CustomMetricsSchema.md)와 호환되는 문서.
/// 같은 JSON 파일을 RunCat Neo 와 이 앱에서 함께 쓸 수 있다.
struct CustomMetricsDocument: Decodable, Equatable, Sendable {
    static let defaultSymbol = "chart.bar.horizontal.page.fill"

    var title: String
    var symbol: String?
    /// 원본의 메트릭스 바(메뉴바 상시 표시)용 값. 이 앱은 아직 메트릭스 바가 없어 읽기만 한다.
    var metricsBarValue: String?
    var metrics: [Metric]
    var lastUpdatedDate: Date

    struct Metric: Decodable, Equatable, Sendable {
        var title: String
        var formattedValue: String
        /// 0...1 로 잘라 둔다. 있으면 진행 막대를 그린다.
        var normalizedValue: Double?

        init(title: String, formattedValue: String, normalizedValue: Double? = nil) {
            self.title = title
            self.formattedValue = formattedValue
            self.normalizedValue = normalizedValue.map { min(max($0, 0), 1) }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                title: try container.decode(String.self, forKey: .title),
                formattedValue: try container.decode(String.self, forKey: .formattedValue),
                normalizedValue: try container.decodeIfPresent(Double.self, forKey: .normalizedValue)
            )
        }

        private enum CodingKeys: String, CodingKey {
            case title, formattedValue, normalizedValue
        }
    }

    var resolvedSymbol: String { symbol ?? Self.defaultSymbol }

    static func decode(_ data: Data) throws -> CustomMetricsDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            for options: ISO8601DateFormatter.Options in [[.withInternetDateTime, .withFractionalSeconds], [.withInternetDateTime]] {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = options
                if let date = formatter.date(from: text) { return date }
            }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Not an ISO 8601 date: \(text)"))
        }
        return try decoder.decode(CustomMetricsDocument.self, from: data)
    }
}

enum CustomMetricsError: LocalizedError, Equatable {
    case unreadable
    case invalidFormat
    case alreadyAdded

    // 원본의 안내 문구를 따른다.
    var errorDescription: String? {
        switch self {
        case .unreadable: L("error.unreadable")
        case .invalidFormat: L("error.invalidFormat")
        case .alreadyAdded: L("error.alreadyAdded")
        }
    }
}
