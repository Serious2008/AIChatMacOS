//
//  GrowingTextView.swift
//  AIChatMacOS
//
//  Created by Sergey Markov on 11.08.2025.
//

import SwiftUI
import AppKit

// MARK: - GrowingTextView (final with appearance + color fixes)
struct GrowingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    var maxHeight: CGFloat = 140

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        scroll.appearance = NSApp.effectiveAppearance

        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 4
        textView.delegate = context.coordinator

        // --- Appearance & colors (dark/light safe) ---
        let isDark = (scroll.appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
        textView.appearance = scroll.appearance
        textView.backgroundColor = isDark ? NSColor.controlBackgroundColor : NSColor.textBackgroundColor
        textView.textColor = isDark ? NSColor.white : NSColor.textColor
        textView.insertionPointColor = isDark ? NSColor.white : NSColor.textColor
        textView.typingAttributes[.foregroundColor] = isDark ? NSColor.white : NSColor.textColor
        textView.selectedTextAttributes = [.backgroundColor: NSColor.selectedTextBackgroundColor]

        scroll.documentView = textView
        context.coordinator.textView = textView
        textView.string = text
        recalcHeight(textView)
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        nsView.appearance = NSApp.effectiveAppearance
        let isDark = (nsView.appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)

        if textView.string != text {
            textView.string = text
        }

        textView.font = font
        textView.appearance = nsView.appearance
        textView.drawsBackground = true
        textView.backgroundColor = isDark ? NSColor.controlBackgroundColor : NSColor.textBackgroundColor
        textView.textColor = isDark ? NSColor.white : NSColor.textColor
        textView.insertionPointColor = isDark ? NSColor.white : NSColor.textColor
        textView.typingAttributes[.foregroundColor] = isDark ? NSColor.white : NSColor.textColor
        textView.selectedTextAttributes = [.backgroundColor: NSColor.selectedTextBackgroundColor]

        // Recolor existing content to ensure visibility in dark mode
        let len = (textView.string as NSString).length
        if len > 0 {
            textView.textStorage?.addAttribute(.foregroundColor,
                                               value: (isDark ? NSColor.white : NSColor.textColor),
                                               range: NSRange(location: 0, length: len))
        }

        recalcHeight(textView)
        nsView.hasVerticalScroller = calculatedHeight >= maxHeight - 1
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: GrowingTextView
        weak var textView: NSTextView?
        init(_ parent: GrowingTextView) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            parent.text = tv.string
            parent.recalcHeight(tv)
        }
    }

    private func recalcHeight(_ textView: NSTextView) {
        guard let tc = textView.textContainer, let lm = textView.layoutManager else { return }
        lm.ensureLayout(for: tc)
        let used = lm.usedRect(for: tc).size.height
        let insets = textView.textContainerInset
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let target = max(lineHeight + insets.height * 2,
                         min(maxHeight, ceil(used + insets.height * 2 + 2)))
        if abs(calculatedHeight - target) > 0.5 {
            DispatchQueue.main.async { calculatedHeight = target }
        }
    }
}
