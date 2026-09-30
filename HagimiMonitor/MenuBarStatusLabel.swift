import AppKit
import SwiftUI

struct MenuBarStatusLabel: View {
    @ObservedObject var store: MonitorStore
    let darkMode: Bool

    var body: some View {
        switch store.settings.menuBarDisplayMode {
        case .ring:
            Image(nsImage: MenuBarComputeRingIcon.image(
                load: store.loadAnimator.displayedComputeLoad,
                darkMode: darkMode,
                loadLevel: store.haloRingLoadLevel
            ))
            .resizable()
            .frame(width: 18, height: 18)
            .help("HagimiMonitor")
        case .metrics:
            MenuBarMetricLabel(
                items: store.menuBarMetricItems,
                layoutStyle: store.settings.menuBarMetricLayoutStyle
            )
            .help("HagimiMonitor")
        }
    }
}

struct MenuBarMetricLabel: View {
    enum Style {
        case menuBar
        case preview
    }

    let items: [MenuBarMetricItem]
    var style: Style = .menuBar
    var layoutStyle: MenuBarMetricLayoutStyle = .icon

    var body: some View {
        switch layoutStyle {
        case .icon, .text:
            horizontalBody
        case .compact:
            compactBody
        }
    }

    /// 横排(icon/text):总宽由 `MenuBarMetricWidthEngine` 按各指标的最大预留一次性算死,
    /// 与任何实时数值无关--左右边缘与邻居图标的距离恒定不动;每格区域按「常用宽度」
    /// 划定,常用范围内的位数变化被区域内空白吸收,位置纹丝不动,富余均摊为格间间距。
    /// 字体与菜单栏观感同族(SF Rounded,引擎同源 NSFont 桥接),尾部单位小一号弱化。
    private var horizontalBody: some View {
        let layout = MenuBarMetricWidthEngine.horizontalLayout(for: items, layout: layoutStyle)
        return HStack(spacing: layout.gap) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                horizontalCell(for: item, flushTrailing: index == items.count - 1)
            }
        }
        .font(Font(MenuBarMetricWidthEngine.horizontalValueFont))
        .lineLimit(1)
        .allowsTightening(false)
        .fixedSize()
    }

    /// 紧凑(compact):列宽仍按最大可能值预留，格与格之间的间距不变。
    /// 最左列丢掉外侧半格空白、最右列丢掉外侧半格空白，边距只留系统那一圈。
    private var compactBody: some View {
        HStack(spacing: interCellSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                compactCell(for: item, edge: compactEdge(at: index))
            }
        }
        .lineLimit(1)
        .allowsTightening(false)
        .fixedSize()
    }

    private enum CompactEdge {
        case only, leading, trailing, middle
    }

    private func compactEdge(at index: Int) -> CompactEdge {
        if items.count <= 1 { return .only }
        if index == 0 { return .leading }
        if index == items.count - 1 { return .trailing }
        return .middle
    }

    /// 横排单格:按「常用宽度」划定最小区域,前缀(SF 图标 / CPU / ↑↓ 等)+ 数值紧贴成对。
    /// 常用范围内的位数变化只伸缩区域内空白,不推动任何相邻内容;
    /// 冲出常用宽度时该格临时变宽、轻微收缩格间距(引擎侧计算)。
    private func horizontalCell(for item: MenuBarMetricItem, flushTrailing: Bool) -> some View {
        let natural = MenuBarMetricWidthEngine.naturalPairWidth(for: item, layout: layoutStyle)
        let common = MenuBarMetricWidthEngine.commonPairWidth(for: item.kind, layout: layoutStyle)
        // 末格不再把「常用宽度」里用不到的空白留在整组最右侧。
        let minWidth = flushTrailing ? natural : max(natural, common)
        return HStack(spacing: symbolSpacing) {
            leading(for: item.kind)
            valueText(for: item)
        }
        .frame(minWidth: minWidth, alignment: .leading)
    }

    /// 数值:数字部分主字号,尾部单位字形小一号、基线对齐弱化(iStat 式层次)。
    /// 拆分口径与引擎的 measuredValueWidth 一一对应,测量/渲染同源。
    @ViewBuilder
    private func valueText(for item: MenuBarMetricItem) -> some View {
        let parts = MenuBarMetricWidthEngine.splitValueUnit(numericValue(for: item))
        if parts.unit.isEmpty {
            Text(parts.digits)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(parts.digits)
                Text(parts.unit)
                    .font(Font(MenuBarMetricWidthEngine.unitFont))
            }
        }
    }

    /// 前缀视图:图标模式用 SF Symbol,文字模式用 CPU/GPU… 或网络的 ↑↓。
    /// 仅由横排分支调用,紧凑模式走独立的 `compactCell`、不经过这里。
    @ViewBuilder
    private func leading(for kind: MenuBarMetricKind) -> some View {
        switch layoutStyle {
        case .icon:
            // icon 字号比文本小 2pt,让数字视觉上比 icon 略大一圈(贴近 iStat Menus
            // "数字突出、icon 作标识" 的视觉权重);父级 .font 不继承到此。
            Image(systemName: kind.symbol)
                .font(.system(size: Self.iconFontSize, weight: .medium))
        default:
            Text(Self.textPrefix(for: kind))
        }
    }

    /// 紧凑模式:文字标签(小)在上、数值(大)在下的双层排布,专为窄屏机型省空间设计。
    /// 标签与数值都居中对齐,且始终按 `compactCellWidth` 定宽(含末位指标),
    /// 避免数值位数变化(如 8% -> 18%)时上下两行、乃至整个图标宽度跟着跳动。
    private func compactCell(for item: MenuBarMetricItem, edge: CompactEdge) -> some View {
        let full = compactCellWidth(for: item.kind)
        let slack = compactSideSlack(for: item)
        let (width, alignment): (CGFloat, Alignment) = switch edge {
        case .only:
            (max(full - slack * 2, 1), .center)
        case .leading:
            (max(full - slack, 1), .leading)
        case .trailing:
            (max(full - slack, 1), .trailing)
        case .middle:
            (full, .center)
        }
        return VStack(alignment: .center, spacing: -1) {
            Text(Self.textPrefix(for: item.kind))
                .font(compactLabelFont)
            Text(numericValue(for: item))
                .font(compactValueFont)
        }
        .frame(width: width, alignment: alignment)
    }

    /// 纯数值:trim/剥箭头逻辑同源在布局引擎,横排与紧凑共用。
    private func numericValue(for item: MenuBarMetricItem) -> String {
        MenuBarMetricWidthEngine.displayValue(for: item)
    }

    /// 文字前缀(横排文字模式/紧凑模式共用),同源在布局引擎。
    private static func textPrefix(for kind: MenuBarMetricKind) -> String {
        MenuBarMetricWidthEngine.textPrefix(for: kind)
    }

    /// 各指标为紧凑定宽框预留的「最宽可能值」--紧凑列宽以此为测量样本。
    /// 输入与实例状态无关,故为 static。
    private static func reservedNumericValue(for kind: MenuBarMetricKind) -> String {
        switch kind {
        case .cpuUsage, .gpuUsage, .memoryUsage, .memoryPressure, .batteryLevel:
            "100%"
        case .networkDownload, .networkUpload:
            "888M"
        case .cpuTemperature:
            "888°"
        case .storageFree:
            "888G"
        case .systemPower, .gpuPower:
            "888W"
        case .memoryBandwidth:
            "888G"
        case .displayRefreshRate:
            "120Hz"
        case .displayPower:
            "99.9W"
        case .fanSpeed:
            "9999"
        }
    }

    /// 居中列里，文字两侧各有一半用不到的预留宽。最外侧的那一半就是多出来的边距。
    private func compactSideSlack(for item: MenuBarMetricItem) -> CGFloat {
        let content = compactContentWidth(for: item)
        return max(0, (compactCellWidth(for: item.kind) - content) / 2)
    }

    private func compactContentWidth(for item: MenuBarMetricItem) -> CGFloat {
        let labelWidth = (Self.textPrefix(for: item.kind) as NSString)
            .size(withAttributes: [.font: Self.compactLabelMeasuringFont]).width
        let valueWidth = (numericValue(for: item) as NSString)
            .size(withAttributes: [.font: Self.compactValueMeasuringFont]).width
        return ceil(max(labelWidth, valueWidth))
    }

    /// 双层列宽:取「标签」与「数值最大可能宽度」两者中较宽的一个,
    /// 保证上下两行都不会因为对方更宽而在切换时左右跳动。
    /// +2 兜底:测量与渲染的亚像素取整差异会让实测宽度卡在边界,
    /// 差零点几 pt 时数值被截断成「9…」,预留余量兜底。
    private func compactCellWidth(for kind: MenuBarMetricKind) -> CGFloat {
        Self.compactCellWidths[kind]!
    }

    private var compactLabelFont: Font {
        .system(size: Self.compactLabelFontSize, weight: .semibold, design: .rounded)
    }

    private var compactValueFont: Font {
        .system(size: Self.compactValueFontSize, weight: .bold, design: .rounded).monospacedDigit()
    }

    // MARK: - 静态缓存(消除每渲染周期重建 NSFont + 重复测量固定字符串的热点)

    /// 测量用 NSFont 按固定字号/字重/是否等宽数字各复用一个实例。字号在进程内恒定,
    /// 故用 static let 一次性构造,避免每次 body 都新建字体。
    private static let compactLabelMeasuringFont: NSFont =
        MenuBarMetricWidthEngine.roundedMeasuringFont(size: compactLabelFontSize, weight: .semibold, monospacedDigit: false)
    private static let compactValueMeasuringFont: NSFont =
        MenuBarMetricWidthEngine.roundedMeasuringFont(size: compactValueFontSize, weight: .bold, monospacedDigit: true)

    /// 各指标的列宽:取「标签宽度」与「数值最大宽度」中较宽者,一次性测得并复用。
    private static let compactCellWidths: [MenuBarMetricKind: CGFloat] = {
        var cache: [MenuBarMetricKind: CGFloat] = [:]
        for kind in MenuBarMetricKind.allCases {
            let labelWidth = (MenuBarMetricWidthEngine.textPrefix(for: kind) as NSString)
                .size(withAttributes: [.font: compactLabelMeasuringFont]).width
            let valueWidth = (reservedNumericValue(for: kind) as NSString)
                .size(withAttributes: [.font: compactValueMeasuringFont]).width
            cache[kind] = ceil(max(labelWidth, valueWidth)) + 2
        }
        return cache
    }()

    /// icon 字号,同源在布局引擎(icon 测量与渲染必须一致)。
    private static var iconFontSize: CGFloat { MenuBarMetricWidthEngine.iconFontSize }

    /// 上层标签字号:比数值小一档,弱化标签、突出数值。
    private static var compactLabelFontSize: CGFloat { 7 }

    /// 下层数值字号:菜单栏 22pt 高度预算内,双层叠加后仍留有余量。
    private static var compactValueFontSize: CGFloat { 10 }

    /// 前缀与数值之间的间距,同源在布局引擎。
    private var symbolSpacing: CGFloat { MenuBarMetricWidthEngine.symbolSpacing }

    /// 紧凑模式指标之间的间距。
    private var interCellSpacing: CGFloat { 2 }
}
