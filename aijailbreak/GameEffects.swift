//
//  GameEffects.swift
//  aijailbreak
//
//  Created by user20 on 2025/9/19.
//

import SwiftUI

// 成功動畫效果
struct SuccessEffectView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 背景光暈
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .scaleEffect(scale)
                .opacity(opacity)
            
            // 中心圖標
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                rotation = 360
            }
            
            // 自動消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    scale = 1.2
                }
            }
        }
    }
}

// 粒子爆炸效果
struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .orange, .red, .pink, .purple, .blue, .green]
        
        for _ in 0..<20 {
            let particle = Particle(
                id: UUID(),
                position: CGPoint(x: 200, y: 200), // 中心點
                velocity: CGPoint(
                    x: Double.random(in: -100...100),
                    y: Double.random(in: -100...100)
                ),
                color: colors.randomElement() ?? .yellow,
                size: Double.random(in: 4...12),
                opacity: 1.0,
                scale: 1.0
            )
            particles.append(particle)
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x
                particles[i].position.y += particles[i].velocity.y
                particles[i].opacity = 0
                particles[i].scale = 0.1
            }
        }
        
        // 清理粒子
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles.removeAll()
        }
    }
}

struct Particle {
    let id: UUID
    var position: CGPoint
    let velocity: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
}

// 打字機效果
struct TypewriterText: View {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
    }
    
    private func startTyping() {
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// 進度條動畫
struct AnimatedProgressBar: View {
    let progress: Double
    let total: Double
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * (animatedProgress / total), height: 8)
                    .cornerRadius(4)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animatedProgress)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}

// 脈衝動畫修飾器
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseEffect() -> some View {
        modifier(PulseEffect())
    }
}

// 搖擺動畫（錯誤時使用）
struct ShakeEffect: ViewModifier {
    @State private var shakeOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onAppear {
                withAnimation(.linear(duration: 0.1).repeatCount(6, autoreverses: true)) {
                    shakeOffset = 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    shakeOffset = 0
                }
            }
    }
}

extension View {
    func shakeEffect() -> some View {
        modifier(ShakeEffect())
    }
}