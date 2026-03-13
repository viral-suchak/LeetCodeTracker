// ContentView.swift
// LeetCodeTracker

import SwiftUI

struct ContentView: View {
    @State private var username: String = ""
    @State private var isLoading = false
    @State private var stats: LeetCodeUserStats?
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    var body: some View {
        if let stats {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ProfileView(
                        stats: stats,
                        onRefresh: { await loadStats(for: stats.username) }
                    )
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

                NavigationStack {
                    SubmissionsView(stats: stats)
                }
                .tabItem { Label("Submissions", systemImage: "list.clipboard.fill") }
                .tag(1)

                NavigationStack {
                    SettingsView(
                        username: stats.username,
                        onChangeUser: {
                            self.stats = nil
                            SharedDataManager.shared.savedUsername = nil
                        },
                        onRefresh: { await loadStats(for: stats.username) }
                    )
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
            }
            .accentColor(.orange)
        } else {
            landingView
        }
    }

    // MARK: - Landing / Username Entry

    private var landingView: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(Color.orange)
                    }

                    Text("LeetCode Tracker")
                        .font(.system(size: 30, weight: .bold))

                    Text("Enter your public username\nto view your progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("LeetCode Username", systemImage: "person.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            TextField("e.g. neal_wu", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.go)
                                .onSubmit { Task { await loadStats(for: username) } }

                            if !username.isEmpty {
                                Button {
                                    username = ""
                                    errorMessage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(errorMessage != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    }

                    if let errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(errorMessage)
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await loadStats(for: username) }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            }
                            Text(isLoading ? "Loading…" : "View Profile")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(username.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
                .padding(.horizontal, 28)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption2)
                    Text("No sign-in required")
                        .font(.caption)
                }
                .foregroundStyle(.tertiary)
                .padding(.bottom, 32)
            }
        }
        .task {
            if let saved = SharedDataManager.shared.savedUsername, !saved.isEmpty {
                username = saved
                await loadStats(for: saved)
            }
        }
    }

    // MARK: - Data loading

    private func loadStats(for name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await LeetCodeService.shared.fetchUserStats(username: trimmed)
            stats = fetched
            SharedDataManager.shared.savedUsername = trimmed
            SharedDataManager.shared.saveWidgetData(from: fetched)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Submissions tab

struct SubmissionsView: View {
    let stats: LeetCodeUserStats

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    submissionStatCard(count: stats.totalActiveDays, label: "Active Days", color: .purple)
                    submissionStatCard(count: stats.dailySubmissions.reduce(0, +), label: "Last 365 Days", color: .green)
                }

                CardContainer(title: "Recent Activity") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Submission history is available on leetcode.com")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Link("Open LeetCode Profile", destination: URL(string: "https://leetcode.com/\(stats.username)")!)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Submissions")
        .navigationBarTitleDisplayMode(.large)
    }

    private func submissionStatCard(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Settings tab

struct SettingsView: View {
    let username: String
    let onChangeUser: () -> Void
    let onRefresh: () async -> Void

    @State private var isRefreshing = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(username)
                            .font(.headline)
                        Text("Signed in as")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Data") {
                Button {
                    Task {
                        isRefreshing = true
                        await onRefresh()
                        isRefreshing = false
                    }
                } label: {
                    HStack {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                        Spacer()
                        if isRefreshing {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                }
                .disabled(isRefreshing)
            }

            Section("Account") {
                Button(role: .destructive) {
                    onChangeUser()
                } label: {
                    Label("Change Username", systemImage: "person.badge.minus")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    ContentView()
}
