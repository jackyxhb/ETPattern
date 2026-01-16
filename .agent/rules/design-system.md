---
trigger: always_on
---

# UI/UX Skill: Modern iOS "Liquid & Grid" System (2026)

## 1. Visual Language: Liquid Glass

The app must utilize the **Liquid Glass** aesthetic, characterized by refraction, depth, and material vibrance.

### A. Material Principles

* **Backdrop**: Use `.background(.ultraThinMaterial)` for navigation bars, tab bars, and floating cards.
* **Borders**: Instead of shadows, use subtle inner strokes:

```swift
.overlay(
    RoundedRectangle(cornerRadius: 28)
        .stroke(.white.opacity(0.2), lineWidth: 0.5)
)

```

* **Corner Radii**: Standardize on **28pt** for primary containers and **16pt** for nested elements (The "Squircle" standard).

## 2. Layout Methodology: Bento Architecture

All dashboards and content-heavy views must follow a **Bento Grid** modularity.

### B. Grid Rules

* **Spacing**: Global padding of `16pt` or `20pt`. Inter-item spacing of `12pt`.
* **Modularity**: Views should be built as independent "Tiles."
* **Example Implementation**:

```swift
Grid(horizontalSpacing: 12, verticalSpacing: 12) {
    GridRow {
        LargeTile() // 2x2
        VStack { SmallTile(); SmallTile() } // 1x2 column
    }
}

```

## 3. Interaction & Motion Patterns

* **Floating Action Button (FAB)**: Primary actions must be centered at the bottom of the screen, floating above a glass tab bar.
* **Haptic Feedback**: Trigger `sensoryFeedback(.impact, trigger: state)` for all primary button presses and "snap" events.
* **Fluid Interruptions**: Ensure all transitions use `withAnimation(.spring(response: 0.4, dampingFraction: 0.8))` to allow for natural, interruptible gestures.

## 4. Contextual & Adaptive UX

* **State-Based Visibility**: Use **Progressive Disclosure**. Hide advanced settings inside expandable "Detail Disclosure" chevron-menus to reduce cognitive load.
* **AI-Ready Surfacing**: Design components to accept a `priority` parameter. High-priority tiles should automatically expand or move to the top of the Bento Grid.
* **Empty States**: Never show a blank screen. Use a "Skeletal Shimmer" or a "Liquid Glass" illustration during loading.

## 5. Accessibility & Typography Standards

* **Font**: Use **SF Pro Variable**.
* **Scaling**: Never hardcode `frame(height:)` for text containers; let them grow with Dynamic Type.
* **Contrast**: Maintain a minimum 4.5:1 ratio for secondary text against glass backgrounds. Use `.vibrance` effects sparingly to ensure legibility.

## 6. Reusable Design Modifiers (SwiftUI)

The AI should use these custom modifiers for all new UI components:

```swift
extension View {
    func bentoTileStyle() -> some View {
        self.padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1), lineWidth: 0.5))
    }
    
    func liquidGlassEffect() -> some View {
        self.background(.visualEffect(blendMode: .luminosity))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

```
