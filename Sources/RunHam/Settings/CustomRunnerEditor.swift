import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

/// 커스텀 러너 편집 시트의 상태: 이름, 색상 방식, 프레임과 그 순서.
/// 새로 만들 때와 이미 있는 러너를 고칠 때 같이 쓴다.
@MainActor
@Observable
final class CustomRunnerDraft: Identifiable {
    struct Frame: Identifiable, Equatable {
        let id = UUID()
        let image: CGImage
    }

    let id = UUID()
    /// nil 이면 새 러너, 있으면 그 러너를 고친다
    let editingID: String?
    var name: String
    var isTemplate: Bool
    var frames: [Frame]
    var selection: Frame.ID?
    var errorMessage: String?

    init(editingID: String? = nil, name: String = "", isTemplate: Bool = true, images: [CGImage] = []) {
        self.editingID = editingID
        self.name = name
        self.isTemplate = isTemplate
        self.frames = images.map { Frame(image: $0) }
    }

    var canSave: Bool { !frames.isEmpty }

    /// PNG 파일·폴더를 끝에 덧붙인다. 폴더는 파일 이름 순서로 읽고, 조건에 맞지 않는 파일이 있으면 그 이름을 알린다.
    func append(_ urls: [URL]) {
        var files: [URL] = []
        for url in urls {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                files += (try? CustomRunnerImporter.frameURLs(in: url)) ?? []
                if name.isEmpty { name = CustomRunnerImporter.suggestedName(for: url) }
            } else if url.pathExtension.lowercased() == "png" {
                files.append(url)
            }
        }
        files.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        do {
            for file in files {
                guard frames.count < CustomRunnerImporter.maxFrames else { throw CustomRunnerError.tooManyFrames }
                frames.append(Frame(image: try CustomRunnerImporter.loadFrames(from: [file])[0]))
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSelected() {
        guard let index = frames.firstIndex(where: { $0.id == selection }) else { return }
        frames.remove(at: index)
        selection = frames.isEmpty ? nil : frames[min(index, frames.count - 1)].id
    }

    /// 선택한 프레임을 앞(-1)이나 뒤(+1)로 한 칸 옮긴다
    func moveSelected(by offset: Int) {
        guard let index = frames.firstIndex(where: { $0.id == selection }) else { return }
        let target = index + offset
        guard frames.indices.contains(target) else { return }
        frames.swapAt(index, target)
    }

    /// 끌어 놓은 프레임을 놓은 자리로 옮긴다
    func move(_ id: Frame.ID, to target: Frame.ID) {
        guard id != target,
              let from = frames.firstIndex(where: { $0.id == id }),
              let to = frames.firstIndex(where: { $0.id == target }) else { return }
        frames.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
    }

    func reverse() {
        frames.reverse()
    }
}

/// 커스텀 러너 추가·편집 시트: 이름, 색상, 프레임 순서(끌어서 옮기기, ◀ ▶ 버튼, 뒤집기), 미리보기.
struct CustomRunnerEditorView: View {
    @Bindable var draft: CustomRunnerDraft
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L(draft.editingID == nil ? "customRunner.editor.addTitle" : "customRunner.editor.editTitle"))
                .font(.headline)

            Form {
                TextField(L("customRunner.editor.name"), text: $draft.name, prompt: Text(L("customRunner.defaultName")))
                Picker(L("customRunner.editor.color"), selection: $draft.isTemplate) {
                    Text(L("customRunner.editor.color.template")).tag(true)
                    Text(L("customRunner.editor.color.original")).tag(false)
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.columns)

            VStack(alignment: .leading, spacing: 6) {
                Text(L("customRunner.editor.frames")).font(.subheadline.weight(.medium))
                FrameGrid(draft: draft)
                Text(L("customRunner.requirements"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let message = draft.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L("customRunner.editor.preview")).font(.subheadline.weight(.medium))
                DraftPreview(draft: draft)
            }

            HStack {
                Spacer()
                Button(L("common.cancel"), role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(L(draft.editingID == nil ? "common.add" : "common.save"), action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!draft.canSave)
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}

/// 프레임 격자. 칸을 눌러 고르고, 끌어서 다른 칸에 놓으면 그 자리로 옮긴다. PNG·폴더를 끌어 놓으면 덧붙인다.
private struct FrameGrid: View {
    @Bindable var draft: CustomRunnerDraft
    private let columns = Array(repeating: GridItem(.fixed(62), spacing: 6), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if draft.frames.isEmpty {
                    Text(L("customRunner.editor.empty"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                } else {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(draft.frames.enumerated()), id: \.element.id) { index, frame in
                            FrameCell(index: index, frame: frame, isTemplate: draft.isTemplate, isSelected: draft.selection == frame.id)
                                .onTapGesture { draft.selection = frame.id }
                                .draggable(frame.id.uuidString) {
                                    FrameCell(index: index, frame: frame, isTemplate: draft.isTemplate, isSelected: true)
                                }
                                .dropDestination(for: String.self) { items, _ in
                                    guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                                    withAnimation(.snappy(duration: 0.2)) { draft.move(id, to: frame.id) }
                                    draft.selection = id
                                    return true
                                }
                        }
                    }
                    .padding(6)
                }
            }
            .frame(height: 160)
            .background(Color(nsColor: .controlBackgroundColor))
            .dropDestination(for: URL.self) { urls, _ in
                draft.append(urls)
                return true
            }

            Divider()
            HStack(spacing: 2) {
                ToolbarButton(symbol: "plus", help: L("customRunner.editor.addFrames"), action: chooseFiles)
                ToolbarButton(symbol: "minus", help: L("customRunner.editor.removeFrame"), action: draft.removeSelected)
                    .disabled(draft.selection == nil)
                Divider().frame(height: 14).padding(.horizontal, 4)
                ToolbarButton(symbol: "chevron.left", help: L("customRunner.editor.moveEarlier")) { draft.moveSelected(by: -1) }
                    .disabled(draft.selection == nil)
                ToolbarButton(symbol: "chevron.right", help: L("customRunner.editor.moveLater")) { draft.moveSelected(by: 1) }
                    .disabled(draft.selection == nil)
                ToolbarButton(symbol: "arrow.left.arrow.right", help: L("customRunner.editor.reverse"), action: draft.reverse)
                    .disabled(draft.frames.count < 2)
                Spacer()
                Text(L("customRunner.editor.count", draft.frames.count, CustomRunnerImporter.maxFrames))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 6)
            }
            .padding(4)
        }
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.message = L("customRunner.choose")
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.png, .folder]
        guard panel.runModal() == .OK else { return }
        draft.append(panel.urls)
    }
}

private struct ToolbarButton: View {
    var symbol: String
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).frame(width: 22, height: 18)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}

private struct FrameCell: View {
    var index: Int
    var frame: CustomRunnerDraft.Frame
    var isTemplate: Bool
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(decorative: frame.image, scale: Runner.scale)
                .renderingMode(isTemplate ? .template : .original)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .foregroundStyle(.primary)
                .frame(width: 54, height: 30)
            Text("\(index + 1)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .padding(.horizontal, 5)
                .background(Capsule().fill(isSelected ? Color.accentColor : Color.clear))
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: isSelected ? 2 : 1))
        .contentShape(Rectangle())
    }
}

/// 지금 순서대로 재생해 보는 작은 미리보기. 시트가 열려 있을 때만 돈다.
private struct DraftPreview: View {
    var draft: CustomRunnerDraft

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let frames = draft.frames
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlBackgroundColor))
                if !frames.isEmpty {
                    let index = Int(context.date.timeIntervalSinceReferenceDate / 0.25) % frames.count
                    Image(decorative: frames[index].image, scale: 1)
                        .renderingMode(draft.isTemplate ? .template : .original)
                        .interpolation(.high)
                        .foregroundStyle(.primary)
                }
            }
            .frame(height: 52)
        }
    }
}
