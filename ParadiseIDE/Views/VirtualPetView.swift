import SwiftUI

struct VirtualPetView: View {
    @EnvironmentObject var vm: EditorViewModel
    var t: ParadiseTheme { vm.theme }

    @State private var bounceOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 2) {
            Button {
                vm.petTapped()
            } label: {
                Text(t.petEmoji)
                    .font(.system(size: 22))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(t.surface.opacity(0.6))
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.15), t.surfaceBorder],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                            .shadow(color: t.accent.opacity(0.2), radius: 8)
                    )
                    .offset(y: bounceOffset)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
            .buttonStyle(.plain)

            if !vm.petMood.message.isEmpty {
                Text(vm.petMood.message)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(t.accent)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 72)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .onChange(of: vm.petMood) { mood in
            withAnimation(nil) {
                bounceOffset = 0
                rotation = 0
                scale = 1.0
            }
            guard !vm.performanceMode else { return }
            animateForMood(mood)
        }
        .onAppear { animateForMood(.idle) }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: vm.petMood.message)
    }

    private func animateForMood(_ mood: PetMood) {
        switch mood {
        case .idle:
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                bounceOffset = -6
            }
        case .typing:
            withAnimation(.easeInOut(duration: 0.25).repeatForever(autoreverses: true)) {
                rotation = 8
            }
        case .ai:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).repeatCount(4, autoreverses: true)) {
                bounceOffset = -12
                scale = 1.1
            }
        case .error:
            withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                rotation = 12
                scale = 1.15
            }
        case .happy:
            withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
