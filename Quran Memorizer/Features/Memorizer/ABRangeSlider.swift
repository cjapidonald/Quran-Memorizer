import SwiftUI

struct ABRangeSlider: View {
    @Binding var start: TimeInterval
    @Binding var end: TimeInterval
    var duration: TimeInterval
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var activeHandle: Handle? = nil

    private enum Handle { case start, end }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H: CGFloat = 28
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 6).offset(y: (H-6)/2)
                Capsule().fill(Color.accentColor.opacity(0.35))
                    .frame(width: segmentWidth(W), height: 6)
                    .offset(x: xFor(start, in: W), y: (H-6)/2)

                handleView
                    .position(x: xFor(start, in: W), y: H/2)
                    .highPriorityGesture(drag(for: .start, width: W))

                handleView
                    .position(x: xFor(end, in: W), y: H/2)
                    .highPriorityGesture(drag(for: .end, width: W))
            }
            .frame(height: H)
        }
        .frame(height: 28)
    }

    private var handleView: some View {
        Circle().fill(.thinMaterial)
            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 0.8))
            .frame(width: 22, height: 22)
            .shadow(radius: 0.5, y: 0.5)
    }

    private func drag(for handle: Handle, width W: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                if activeHandle == nil { activeHandle = handle; onEditingChanged(true) }
                let ratio = max(0, min(1, v.location.x / max(1, W)))
                let t = ratio * duration
                switch handle {
                case .start:
                    start = min(max(0, t), end - 1)
                case .end:
                    end = max(min(duration, t), start + 1)
                }
            }
            .onEnded { _ in
                activeHandle = nil
                onEditingChanged(false)
            }
    }

    private func xFor(_ time: TimeInterval, in W: CGFloat) -> CGFloat {
        CGFloat(time / max(1, duration)) * W
    }

    private func segmentWidth(_ W: CGFloat) -> CGFloat {
        (CGFloat(end - start) / max(1, duration)) * W
    }
}
