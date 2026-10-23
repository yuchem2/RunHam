import Foundation

/// 파일 하나를 DispatchSource 로 감시한다(폴링 없음).
///
/// - 연속 쓰기는 잠깐 모았다가 한 번만 알린다.
/// - 원자적 쓰기(임시 파일 → rename)나 삭제로 감시 중인 inode 가 사라지면 경로를 다시 연다.
/// - 파일이 없으면 5초마다 다시 시도한다.
@MainActor
final class FileWatcher {
    static let coalesceDelay: Duration = .milliseconds(150)
    static let retryDelay: Duration = .seconds(5)

    private let path: String
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: Task<Void, Never>?
    private var retry: Task<Void, Never>?

    init(path: String, onChange: @escaping () -> Void) {
        self.path = path
        self.onChange = onChange
    }

    func start() {
        stopSource()
        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else {
            scheduleRetry()
            return
        }
        retry?.cancel()
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.handleEvent() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
    }

    func stop() {
        stopSource()
        pending?.cancel()
        retry?.cancel()
    }

    private func handleEvent() {
        guard let source else { return }
        if !source.data.isDisjoint(with: [.delete, .rename]) {
            // 새 파일이 제자리에 놓일 시간을 조금 준 뒤 경로를 다시 연다.
            stopSource()
            pending?.cancel()
            pending = Task { [weak self] in
                try? await Task.sleep(for: Self.coalesceDelay)
                guard !Task.isCancelled else { return }
                self?.start()
                self?.onChange()
            }
            return
        }
        pending?.cancel()
        pending = Task { [weak self] in
            try? await Task.sleep(for: Self.coalesceDelay)
            guard !Task.isCancelled else { return }
            self?.onChange()
        }
    }

    private func scheduleRetry() {
        retry?.cancel()
        retry = Task { [weak self] in
            try? await Task.sleep(for: Self.retryDelay)
            guard !Task.isCancelled else { return }
            self?.start()
            self?.onChange()
        }
    }

    private func stopSource() {
        source?.cancel()
        source = nil
    }
}
