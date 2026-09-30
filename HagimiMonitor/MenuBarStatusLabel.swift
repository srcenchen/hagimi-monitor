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
            ForEach(items) { item in
                horizontalCell(for: item)
            }
        }
        .font(Font(MenuBarMetricWidthEngine.horizontalValueFont))
        .lineLimit(1)
        .allowsTightening(false)
        .fixedSize()
        .frame(width: layout.totalWidth, alignment: .leading)
    }

    /// 紧凑(compact):各指标双层列宽恒定,整体宽度天然稳定,字体同为 rounded。
    private var compactBody: some View {
        HStack(spacing: interCellSpacing) {
            ForEach(items) { item in
                compactCell(for: item)
            }
        }
        .lineLimit(1)
        .allowsTightening(false)
        .fixedSize()
    }

    /// 横排单格:按「常用宽度」划定最小区域,前缀(SF 图标 / CPU / ↑↓ 等)+ 数值紧贴成对。
    /// 常用范围内的位数变化只伸缩区域内空白,不推动任何相邻内容;
    /// 冲出常用宽度时该格临时变宽、轻微收缩格间距(引擎侧计算)。
    private func horizontalCell(for item: MenuBarMetricItem) -> some View {
        HStack(spacing: symbolSpacing) {
            leading(for: item.kind)
            valueText(for: item)
        }
        .frame(minWidth: MenuBarMetricWidthEngine.commonPairWidth(for: item.kind, layout: layoutStyle), alignment: .leading)
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

    /// 紧凑模式:文字标签(小)在上、数值(大)在下。列宽取标签与当前数值中较宽的一边,
    /// 不再为「100%」「888W」预留整列空白。位数跨档(9%→10%)时状态项会跟着收放。
    private func compactCell(for item: MenuBarMetricItem) -> some View {
        VStack(alignment: .center, spacing: -1) {
            Text(Self.textPrefix(for: item.kind))
                .font(compactLabelFont)
            Text(numericValue(for: item))
                .font(compactValueFont)
        }
        .frame(width: compactCellWidth(for: item))
    }

    /// 纯数值:trim/剥箭头逻辑同源在布局引擎,横排与紧凑共用。
    private func numericValue(for item: MenuBarMetricItem) -> String {
        MenuBarMetricWidthEngine.displayValue(for: item)
    }

    /// 文字前缀(横排文字模式/紧凑模式共用),同源在布局引擎。
    private static func textPrefix(for kind: MenuBarMetricKind) -> String {
        MenuBarMetricWidthEngine.textPrefix(for: kind)
    }

    /// 列宽贴着当前标签和数值。+1 只防测量和渲染差零点几 pt 时把末尾裁掉。
    private func compactCellWidth(for item: MenuBarMetricItem) -> CGFloat {
        let labelWidth = (Self.textPrefix(for: item.kind) as NSString)
            .size(withAttributes: [.font: Self.compactLabelMeasuringFont]).width
        let valueWidth = (numericValue(for: item) as NSString)
            .size(withAttributes: [.font: Self.compactValueMeasuringFont]).width
        return ceil(max(labelWidth, valueWidth)) + 1
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

    /// icon 字号,同源在布局引擎(icon 测量与渲染必须一致)。
    private static var iconFontSize: CGFloat { MenuBarMetricWidthEngine.iconFontSize }

    /// 上层标签字号:比数值小一档,弱化标签、突出数值。
    private static var compactLabelFontSize: CGFloat { 7 }

    /// 下层数值字号:菜单栏 22pt 高度预算内,双层叠加后仍留有余量。
    private static var compactValueFontSize: CGFloat { 10 }

    /// 前缀与数值之间的间距,同源在布局引擎。
    private var symbolSpacing: CGFloat { MenuBarMetricWidthEngine.symbolSpacing }

    /// 紧凑模式指标之间的间距。
    private var interCellSpacing: CGFloat { 1 }
}
