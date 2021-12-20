// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(SharedComponentLibrary)
import SharedComponentLibrary
#else
import ComponentLibrary
#endif
import SwiftUI
import ToolKit

public struct Task: Codable, Hashable {

    public struct Row: Codable, Hashable {
        var title: String
        var value: String
    }

    public struct Label: Codable, Hashable {
        var text: String
    }

    public struct Section: Codable, Hashable {

        public struct Plain: Codable, Hashable {
            var header: String
            var expandable: Bool?
            var tasks: [Task]
        }

        var plain: Plain?
    }

    public struct Spacer: Codable, Hashable {
        var length: Length?
    }

    public struct Group: Codable, Hashable {
        var tasks: [Task]
    }

    var section: Section?
    var label: Label?
    var media: Media?
    var row: Row?
    var spacer: Spacer?
    var divider: Bool?
    var group: Group?
    var style: Style?
}

public struct Style: Codable, Hashable {

    public struct Text: Codable, Hashable {
        var typography: Typography?
    }

    public struct Padding: Codable, Hashable {
        var top: Length?
        var leading: Length?
        var bottom: Length?
        var trailing: Length?
    }

    var text: Text?
    var padding: Padding?
    var foreground: Texture?
    var background: Texture?
}

public struct TaskView: View {

    public let task: Task
    private let lineage: [Task]
    private let bundle: Bundle

    @State private var padding: EdgeInsets = .zero

    public init(_ task: Task) {
        self.init(task, lineage: [])
    }

    public init(_ task: Task, lineage: [Task] = [], in bundle: Bundle = .main) {
        self.task = task
        self.lineage = lineage
        self.bundle = bundle
    }

    public var body: some View {
        Group {
            if let section = task.section?.plain {
                SectionView(section, lineage: lineage + [task], in: bundle)
            } else if let group = task.group {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(group.tasks, id: \.self) {
                        TaskView($0, lineage: lineage + [task])
                    }
                }
            } else if let media = task.media {
                MediaView(media, in: bundle)
                    .padding(padding)
            } else if let row = task.row {
                HStack {
                    RichText(row.title)
                        .typography(.body1)
                    Spacer()
                    RichText(row.value)
                        .typography(.body2)
                }
                .frame(minHeight: layout.minHeight)
                .padding(padding)
            } else if let label = task.label {
                RichText(label.text)
                    .padding([.top, .bottom], layout.verticalTextPadding)
                    .padding(padding)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let spacer = task.spacer {
                SpacerView(spacer: spacer)
            } else if let divider = task.divider, divider {
                Divider()
            }
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    padding = lineage.padding(in: geometry)
                        + (task.style?.padding?.edgeInsets(in: geometry) ?? .zero)
                }
            }
        )
        .typography(task.style?.text?.typography)
        .backgroundTexture(task.style?.background)
        .foregroundTexture(task.style?.foreground)
    }
}

extension TaskView {

    struct SectionView: View {

        let lineage: [Task]
        let section: Task.Section.Plain

        var isExpandable: Bool { section.expandable ?? false }
        var isShowingContent: Bool { !isExpandable || isExpanded }

        @State private var padding: EdgeInsets = .zero
        @State private var isExpanded = true
        private let bundle: Bundle

        init(_ section: Task.Section.Plain, lineage: [Task], in bundle: Bundle = .main) {
            self.lineage = lineage
            self.section = section
            self.bundle = bundle
        }

        var body: some View {
            VStack(alignment: .leading) {
                Divider()
                    .foregroundColor(.dividerLineLight)
                Section(
                    header: Button(
                        action: {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        },
                        label: {
                            HStack {
                                RichText(section.header)
                                    .typography(.paragraph2)
                                    .foregroundColor(.textTitle)
                                if isExpandable {
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.footnote.bold())
                                        .rotationEffect(.radians(isExpanded ? .pi : .pi * 2))
                                        .foregroundColor(isExpanded ? .blue : .gray)
                                }
                            }
                            .padding([.leading], padding.leading)
                            .padding([.trailing], padding.trailing)
                        }
                    )
                    .frame(minHeight: layout.minHeight)
                ) {
                    Group {
                        if isShowingContent {
                            Divider()
                                .foregroundColor(.dividerLineLight)
                            ForEach(section.tasks, id: \.self) { task in
                                TaskView(task, lineage: lineage, in: bundle)
                                if section.tasks.last != task {
                                    Divider()
                                        .foregroundColor(.dividerLineLight)
                                }
                            }
                        }
                    }
                    .opacity(isShowingContent ? 1 : 0)
                    Divider()
                        .foregroundColor(.dividerLineLight)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            padding = lineage.padding(in: geometry)
                        }
                    }
                )
            }
            .textCase(nil)
        }
    }

    struct SpacerView: View {

        let spacer: Task.Spacer
        @State private var length: CGFloat = .zero

        var body: some View {
            if let _length = spacer.length {
                Spacer()
                    .frame(width: length, height: length)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                length = _length.in(geometry)
                            }
                        }
                    )
            } else {
                Spacer()
            }
        }
    }
}

private var layout = (
    minHeight: 50.cg,
    verticalTextPadding: 10.cg
)

extension Task {

    public static var none: Task { .init() }

    public static func label(_ text: String) -> Task {
        Task(label: .init(text: text))
    }

    public func typography(_ typography: Typography) -> Task {
        with(self, at: \.style, default: .init()) { style in
            style.text = .init(typography: typography)
        }
    }

    public func padding(
        _ edges: Edge.Set = [.leading, .trailing],
        _ length: Length? = 6.5.vmin
    ) -> Task {
        with(self, at: \.style, default: .init()) { style in
            style.padding = .init(length, edges: edges)
        }
    }

    public func foreground(
        _ color: Color
    ) -> Task {
        with(self, at: \.style, default: .init()) { style in
            style.foreground = color.texture
        }
    }

    public static func media(_ media: Media) -> Task {
        Task(media: media)
    }

    public static func spacer(_ length: Length? = nil) -> Task {
        Task(spacer: .init(length: length))
    }

    public static func divider() -> Task {
        Task(divider: true, style: .init(foreground: Color.dividerLineLight.texture))
    }

    public static func group(_ tasks: Task...) -> Task {
        Task(group: .init(tasks: tasks))
    }

    public static func group(_ tasks: [Task]) -> Task {
        Task(group: .init(tasks: tasks))
    }

    public static func section(
        header: String,
        expandable: Bool = false,
        task tasks: Task...
    ) -> Task {
        section(
            header: header,
            expandable: expandable,
            tasks: tasks
        )
    }

    public static func section(
        header: String,
        expandable: Bool = false,
        tasks: [Task]
    ) -> Task {
        Task(
            section: .init(
                plain: .init(
                    header: header,
                    expandable: expandable,
                    tasks: tasks
                )
            )
        )
    }

    public static func row(_ title: String, value: String) -> Task {
        .init(row: .init(title: title, value: value))
    }
}

extension Collection where Element == Task {

    fileprivate func padding(in geometry: GeometryProxy) -> EdgeInsets {
        reduce(.zero) { sum, next in
            sum + (next.style?.padding?.edgeInsets(in: geometry) ?? .zero)
        }
    }
}

extension Style.Padding {

    fileprivate init(_ length: Length?, edges: Edge.Set) {
        guard let length = length else { return }
        if edges.contains(.top) {
            top = length
        }
        if edges.contains(.leading) {
            leading = length
        }
        if edges.contains(.bottom) {
            bottom = length
        }
        if edges.contains(.trailing) {
            trailing = length
        }
    }

    fileprivate func edgeInsets(in geometry: GeometryProxy) -> EdgeInsets {
        var insets = EdgeInsets()
        insets.top ?= top?.in(geometry)
        insets.leading ?= leading?.in(geometry)
        insets.bottom ?= bottom?.in(geometry)
        insets.trailing ?= trailing?.in(geometry)
        return insets
    }
}

#if DEBUG
struct TaskView_Previews: PreviewProvider {

    static var previews: some View {
        VStack {
            NavigationView {
                ScrollView {
                    TaskView(
                        Task.group(
                            payment(),
                            Task.spacer(4.vmin),
                            safeconnect()
                        )
                        .padding()
                    )
                }
            }
        }
    }
}
#endif
