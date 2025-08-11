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
        scroll.contentView.drawsBackground = false
        scroll.wantsLayer = true
        scroll.layer?.backgroundColor = NSColor.clear.cgColor

        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.wantsLayer = true
        textView.font = font
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 4
        textView.textContainer?.lineBreakMode = .byWordWrapping
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator

        // --- Appearance & colors (dark/light safe) ---
        textView.appearance = scroll.appearance
        let resolvedBg = NSColor.textBackgroundColor
        let resolvedFg = NSColor.textColor
        textView.usesAdaptiveColorMappingForDarkAppearance = false
        textView.backgroundColor = resolvedBg
        textView.layer?.backgroundColor = resolvedBg.cgColor
        textView.textColor = resolvedFg
        textView.insertionPointColor = resolvedFg
        textView.typingAttributes = [
            .foregroundColor: resolvedFg,
            .font: font
        ]
        textView.selectedTextAttributes = [.backgroundColor: NSColor.selectedTextBackgroundColor]

        // Ensure initial sizing so the container has a real width
        let initialWidth = scroll.contentSize.width > 0 ? scroll.contentSize.width : 100
        textView.textContainer?.containerSize = NSSize(width: initialWidth, height: .greatestFiniteMagnitude)
        textView.setFrameSize(NSSize(width: initialWidth, height: 1))
        scroll.documentView = textView
        context.coordinator.textView = textView
        textView.string = text
        recalcHeight(textView)
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        nsView.appearance = nsView.effectiveAppearance
        nsView.contentView.drawsBackground = false
        // Keep document sizing in sync so glyphs actually layout
        nsView.layoutSubtreeIfNeeded()
        if let docView = nsView.documentView as? NSTextView {
            docView.textContainer?.containerSize = NSSize(width: nsView.contentSize.width, height: .greatestFiniteMagnitude)
            var size = docView.frame.size
            size.width = nsView.contentSize.width
            docView.setFrameSize(size)
        }

        if textView.string != text {
            // Preserve selection while updating string
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange.location <= text.count ? selectedRange : NSRange(location: text.count, length: 0))
        }

        textView.font = font
        textView.appearance = nsView.appearance
        textView.drawsBackground = true
        let resolvedBg = NSColor.textBackgroundColor
        let resolvedFg = NSColor.textColor
        textView.usesAdaptiveColorMappingForDarkAppearance = false
        textView.backgroundColor = resolvedBg
        textView.layer?.backgroundColor = resolvedBg.cgColor
        textView.textColor = resolvedFg
        textView.insertionPointColor = resolvedFg
        textView.typingAttributes = [
            .foregroundColor: resolvedFg,
            .font: font
        ]
        textView.selectedTextAttributes = [.backgroundColor: NSColor.selectedTextBackgroundColor]

        // Recolor existing content to ensure visibility
        let len = (textView.string as NSString).length
        if len > 0, let storage = textView.textStorage {
            storage.beginEditing()
            storage.setAttributes([
                .foregroundColor: resolvedFg,
                .font: font
            ], range: NSRange(location: 0, length: len))
            storage.endEditing()
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
