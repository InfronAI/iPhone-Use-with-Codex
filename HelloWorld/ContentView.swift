import SpriteKit
import SwiftUI
import UIKit

private let electric = Color(red: 0.32, green: 0.95, blue: 1)
private let muted = Color(red: 0.49, green: 0.61, blue: 0.73)

struct ContentView: View {
    @StateObject private var session = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            SpriteView(scene: session.scene, preferredFramesPerSecond: 60,
                       options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .accessibilityLabel("战斗区域，拖动手指移动战机，自动射击")
            if session.hud.phase == .playing || session.hud.phase == .paused { flightOverlay }
            switch session.hud.phase {
            case .ready: launchScreen
            case .paused: pauseScreen
            case .gameOver: resultsScreen
            case .playing: EmptyView()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.pause() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.willDeactivateNotification)) { _ in
            session.pause()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            session.pause()
        }
        .onDisappear { session.pause() }
    }

    private var launchScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Label("星际飞行中队", systemImage: "airplane")
                    .font(.system(size: 11, weight: .semibold)).tracking(2)
                Spacer()
                Text("ARCADE / 01").font(.system(size: 10, design: .monospaced))
            }
            .foregroundStyle(muted)
            .padding(.top, 14)
            Spacer(minLength: 20)
            VStack(spacing: 12) {
                Text("N E O N   S T R I K E")
                    .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(electric)
                Text("雷电")
                    .font(.system(size: 80, weight: .black, design: .rounded)).tracking(10)
                    .foregroundStyle(.white).shadow(color: electric.opacity(0.5), radius: 28)
                HStack(spacing: 12) {
                    Rectangle().fill(electric.opacity(0.45)).frame(width: 25, height: 1)
                    Text("星 空 突 袭").font(.system(size: 14, weight: .medium))
                    Rectangle().fill(electric.opacity(0.45)).frame(width: 25, height: 1)
                }.foregroundStyle(muted)
            }
            Spacer(minLength: 20)
            VStack(spacing: 20) {
                HStack(spacing: 0) {
                    instruction("hand.draw", title: "拖动战机", detail: "单指操控")
                    instruction("scope", title: "自动开火", detail: "专注闪避")
                    instruction("bolt.shield", title: "能量炸弹", detail: "危机清屏")
                }
                .padding(.vertical, 17)
                .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.08)))
                actionButton("出击", subtitle: "START MISSION", symbol: "arrow.up", id: "startGame") { session.start() }
                HStack(spacing: 8) {
                    Image(systemName: "laurel.leading")
                    Text("最高纪录  " + formattedScore(session.hud.best))
                    Image(systemName: "laurel.trailing")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(muted)
            }
            .padding(.bottom, 105)
        }
        .padding(.horizontal, 28)
    }

    private var flightOverlay: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCORE").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(electric)
                    Text(formattedScore(session.hud.score))
                        .font(.system(size: 27, weight: .semibold, design: .monospaced))
                        .contentTransition(.numericText())
                }
                .accessibilityElement(children: .combine).allowsHitTesting(false)
                Spacer()
                VStack(alignment: .trailing, spacing: 5) {
                    Text("SECTOR " + String(format: "%02d", session.hud.stage))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(muted)
                    HStack(spacing: 5) {
                        ForEach(0..<3) { index in
                            Image(systemName: index < session.hud.lives ? "shield.fill" : "shield")
                                .foregroundStyle(index < session.hud.lives ? electric : muted.opacity(0.4))
                        }
                    }
                    .font(.system(size: 12))
                    .accessibilityLabel("剩余护盾 \(session.hud.lives)")
                }
                .allowsHitTesting(false)
                Button { session.pause() } label: {
                    Image(systemName: "pause.fill").font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 13))
                }
                .accessibilityLabel("暂停").accessibilityIdentifier("pauseGame").padding(.leading, 9)
            }
            if session.hud.bossMaximum > 0 {
                VStack(spacing: 5) {
                    HStack {
                        Text("敌方旗舰").font(.system(size: 10, weight: .semibold))
                        Spacer()
                        Text("BOSS").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2)
                    }.foregroundStyle(Color(red: 1, green: 0.38, blue: 0.5))
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.12))
                            Capsule().fill(Color(red: 1, green: 0.38, blue: 0.5))
                                .frame(width: geometry.size.width * CGFloat(session.hud.bossHealth) / CGFloat(max(1, session.hud.bossMaximum)))
                        }
                    }.frame(height: 4)
                }.allowsHitTesting(false)
            }
            Spacer()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("WEAPON / 火力").font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(muted)
                    HStack(spacing: 5) {
                        ForEach(1...3, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(level <= session.hud.weapon ? electric : electric.opacity(0.12))
                                .frame(width: 20, height: 5)
                        }
                    }
                }
                .accessibilityLabel("火力等级 \(session.hud.weapon)").allowsHitTesting(false)
                Spacer()
                Button { session.bomb() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill").font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("清屏炸弹").font(.system(size: 12, weight: .bold))
                            Text("BOMB ×\(session.hud.bombs)").font(.system(size: 9, weight: .semibold, design: .monospaced))
                        }
                    }
                    .foregroundStyle(session.hud.bombs > 0 ? electric : muted)
                    .padding(.horizontal, 17).frame(height: 54)
                    .background(Color(red: 0.04, green: 0.13, blue: 0.18), in: Capsule())
                    .overlay(Capsule().strokeBorder(electric.opacity(session.hud.bombs > 0 ? 0.5 : 0.1)))
                }
                .disabled(session.hud.bombs == 0 || session.hud.phase != .playing)
                .accessibilityLabel("使用清屏炸弹，剩余 \(session.hud.bombs) 枚")
                .accessibilityIdentifier("useBomb")
            }
        }
        .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 16)
    }

    private var pauseScreen: some View {
        modal {
            Image(systemName: "pause.circle").font(.system(size: 44, weight: .ultraLight)).foregroundStyle(electric)
            Text("任务暂停").font(.system(size: 30, weight: .bold))
            Text("深呼吸，准备再次出击。").font(.system(size: 14)).foregroundStyle(muted)
            actionButton("继续飞行", subtitle: "RESUME", symbol: "play.fill", id: "resumeGame") { session.resume() }
                .padding(.top, 12)
            Button { session.hapticsEnabled.toggle() } label: {
                Label(session.hapticsEnabled ? "触感反馈：开" : "触感反馈：关",
                      systemImage: session.hapticsEnabled ? "waveform" : "waveform.slash")
                    .font(.system(size: 13)).foregroundStyle(muted).frame(height: 44)
            }
            Button("重新开始") { session.start() }
                .font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                .frame(minHeight: 44).accessibilityIdentifier("restartGame")
        }
    }

    private var resultsScreen: some View {
        modal {
            Text("MISSION COMPLETE").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(electric)
            Text("任务结束").font(.system(size: 34, weight: .bold))
            VStack(spacing: 5) {
                Text(formattedScore(session.hud.score))
                    .font(.system(size: 45, weight: .light, design: .monospaced)).minimumScaleFactor(0.6).lineLimit(1)
                Text("本次得分").font(.system(size: 12)).foregroundStyle(muted)
            }.padding(.vertical, 14)
            HStack {
                resultMetric("抵达区域", value: String(format: "%02d", session.hud.stage))
                Spacer()
                resultMetric("最高纪录", value: formattedScore(session.hud.best))
            }
            .padding(18).background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
            actionButton("再次出击", subtitle: "TRY AGAIN", symbol: "arrow.clockwise", id: "playAgain") { session.start() }
                .padding(.top, 10)
            Text("拾取 P 升级火力 · + 恢复护盾 · B 补充炸弹")
                .font(.system(size: 10)).foregroundStyle(muted).multilineTextAlignment(.center)
        }
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color(red: 0.02, green: 0.04, blue: 0.08).opacity(0.88).ignoresSafeArea()
            VStack(spacing: 18, content: content)
                .padding(26).frame(maxWidth: 350)
                .background(Color(red: 0.035, green: 0.065, blue: 0.11), in: RoundedRectangle(cornerRadius: 26))
                .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(electric.opacity(0.2)))
                .padding(24)
        }
    }

    private func instruction(_ symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 21, weight: .light)).foregroundStyle(electric)
            Text(title).font(.system(size: 11, weight: .semibold))
            Text(detail).font(.system(size: 9)).foregroundStyle(muted)
        }.frame(maxWidth: .infinity)
    }

    private func resultMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 11)).foregroundStyle(muted)
            Text(value).font(.system(size: 18, weight: .semibold, design: .monospaced))
        }
    }

    private func actionButton(_ title: String, subtitle: String, symbol: String, id: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 19, weight: .bold))
                    Text(subtitle).font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(2)
                }
                Spacer()
                Image(systemName: symbol).font(.system(size: 22, weight: .semibold))
            }
            .foregroundStyle(Color(red: 0.02, green: 0.1, blue: 0.14))
            .padding(.horizontal, 22).frame(height: 68)
            .background(electric, in: RoundedRectangle(cornerRadius: 17))
            .shadow(color: electric.opacity(0.15), radius: 20, y: 6)
        }.buttonStyle(.plain).accessibilityIdentifier(id)
    }

    private func formattedScore(_ score: Int) -> String { String(format: "%06d", score) }
}
