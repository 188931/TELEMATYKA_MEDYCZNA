import SwiftUI

enum AccessibleTheme {
    static let minimumTapSize: CGFloat = 44
    static let requiredHint = "Pola oznaczone gwiazdką są wymagane."
    static let loadingAnnouncement = "Trwa ładowanie, proszę czekać."
}

// MARK: - Form label

struct AccessibleFormLabel: ViewModifier {
    let label: String
    let isRequired: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(isRequired ? "\(label), wymagane" : label)
    }
}

// MARK: - Tap target (WCAG 2.5.8 / Apple HIG 44pt)

struct MinimumTapTarget: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minWidth: AccessibleTheme.minimumTapSize, minHeight: AccessibleTheme.minimumTapSize)
    }
}

// MARK: - Headings (WCAG 1.3.1, 2.4.6)

struct AccessibleHeading: ViewModifier {
    func body(content: Content) -> some View {
        content.accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Decorative images (WCAG 1.1.1)

struct AccessibleDecorativeImage: ViewModifier {
    func body(content: Content) -> some View {
        content.accessibilityHidden(true)
    }
}

// MARK: - Status with icon + text — not color alone (WCAG 1.4.1)

struct AccessibleStatusBadge: View {
    let text: String
    let systemImage: String
    let isPositive: Bool

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(isPositive ? .primary : .secondary)
        .accessibilityLabel("Status: \(text)")
    }
}

// MARK: - Warning / alert text (WCAG 1.4.1)

struct AccessibleWarningText: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Ostrzeżenie: \(text)")
    }
}

// MARK: - Loading overlay (WCAG 4.1.3)

struct AccessibleLoadingOverlay: ViewModifier {
    let isLoading: Bool
    let label: String

    func body(content: Content) -> some View {
        content.overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView(label)
                        .padding(20)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(label)
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }
}

// MARK: - Grouped card for VoiceOver (WCAG 1.3.1)

struct AccessibleGroupedCard: ViewModifier {
    let label: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
}

// MARK: - Toolbar icon buttons

struct AccessibleToolbarAction: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .minimumTapTarget()
    }
}

// MARK: - Reduce motion helper (WCAG 2.3.3)

enum AccessibleAnimation {
    static func scroll(proxy: ScrollViewProxy, to id: some Hashable, reduceMotion: Bool) {
        if reduceMotion {
            proxy.scrollTo(id, anchor: .center)
        } else {
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
        }
    }
}

// MARK: - View extensions

extension View {
    func accessibleFormLabel(_ label: String, required: Bool = false) -> some View {
        modifier(AccessibleFormLabel(label: label, isRequired: required))
    }

    func minimumTapTarget() -> some View {
        modifier(MinimumTapTarget())
    }

    func accessibleHeading() -> some View {
        modifier(AccessibleHeading())
    }

    func accessibleDecorativeImage() -> some View {
        modifier(AccessibleDecorativeImage())
    }

    func accessibleLoading(_ isLoading: Bool, label: String = "Ładowanie") -> some View {
        modifier(AccessibleLoadingOverlay(isLoading: isLoading, label: label))
    }

    func accessibleGroupedCard(_ label: String) -> some View {
        modifier(AccessibleGroupedCard(label: label))
    }

    func accessibleToolbarAction(_ label: String, hint: String? = nil) -> some View {
        modifier(AccessibleToolbarAction(label: label, hint: hint))
    }
}
