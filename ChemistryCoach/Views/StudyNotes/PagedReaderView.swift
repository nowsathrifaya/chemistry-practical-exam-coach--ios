//
//  PagedReaderView.swift
//  ChemistryCoach
//
//  A "book-like" paged reader: one focused, comfortably-sized page of
//  content at a time — swipeable, with a progress bar and Back/Next
//  buttons pinned at the bottom. Used by Study Notes so a student moves
//  through content one digestible chunk at a time instead of one long,
//  small-font scroll.
//

import SwiftUI

struct PagedReaderView<Page: View>: View {
    let pageCount: Int
    var initialIndex: Int = 0
    /// Short label shown above the progress bar, e.g. "Note 2 of 6" or
    /// "Vernier Caliper — 1 of 9".
    let pageLabel: (Int) -> String
    @ViewBuilder let page: (Int) -> Page
    /// Called when the button on the last page is tapped — typically pops
    /// back to the list this pager was opened from. `nil` just disables
    /// the button on the last page (nothing further to do).
    var onFinished: (() -> Void)? = nil
    var finishedLabel: String = "Done"
    /// Fires whenever the visible page changes (swipe or Back/Next) — used
    /// by Study Notes to remember where a student left off.
    var onPageChanged: ((Int) -> Void)? = nil

    @State private var index: Int

    init(
        pageCount: Int,
        initialIndex: Int = 0,
        pageLabel: @escaping (Int) -> String,
        @ViewBuilder page: @escaping (Int) -> Page,
        onFinished: (() -> Void)? = nil,
        finishedLabel: String = "Done",
        onPageChanged: ((Int) -> Void)? = nil
    ) {
        self.pageCount = pageCount
        self.initialIndex = initialIndex
        self.pageLabel = pageLabel
        self.page = page
        self.onFinished = onFinished
        self.finishedLabel = finishedLabel
        self.onPageChanged = onPageChanged
        _index = State(initialValue: min(max(initialIndex, 0), max(pageCount - 1, 0)))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if pageCount == 0 {
                Spacer()
            } else {
                TabView(selection: $index) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        ScrollView {
                            page(i)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            footer
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: index) { _, newValue in onPageChanged?(newValue) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pageCount == 0 ? "" : pageLabel(index))
                    .font(.headline)
                Spacer()
                if let remaining = estimatedMinutesRemaining {
                    Text(remaining <= 1 ? "~1 min left" : "~\(remaining) min left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 5)
                    Capsule().fill(Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    /// Rough reading-time estimate for the remaining pages — ~25 seconds
    /// per page, which is a reasonable pace for these short note/technique
    /// pages. Nil once there's nothing left, so the label just disappears
    /// on the last page rather than showing "0 min left."
    private var estimatedMinutesRemaining: Int? {
        let remainingPages = pageCount - (index + 1)
        guard remainingPages > 0 else { return nil }
        return max(1, Int((Double(remainingPages) * 25.0 / 60.0).rounded(.up)))
    }

    private var progress: CGFloat {
        guard pageCount > 0 else { return 0 }
        return CGFloat(index + 1) / CGFloat(pageCount)
    }

    private var isFirstPage: Bool { index == 0 }
    private var isLastPage: Bool { index >= pageCount - 1 }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { index = max(0, index - 1) }
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .opacity(isFirstPage ? 0 : 1)
            .disabled(isFirstPage)

            Button {
                if isLastPage {
                    onFinished?()
                } else {
                    withAnimation { index += 1 }
                }
            } label: {
                Label(isLastPage ? finishedLabel : "Next", systemImage: isLastPage ? "checkmark" : "chevron.right")
                    .labelStyle(.trailingIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .opacity(isLastPage && onFinished == nil ? 0.4 : 1)
            .disabled(isLastPage && onFinished == nil)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

/// Puts the icon after the title (e.g. "Next ›") rather than before it,
/// which reads more naturally for a forward-navigation button.
private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

private extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

extension Array {
    /// Splits the array into consecutive chunks of at most `size` elements
    /// each — used to spread a long bullet list across several reader
    /// pages instead of one dense page.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
