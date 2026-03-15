# LeetCode Tracker

An iOS app to track your LeetCode progress using the public GraphQL API — no account or sign-in required.

## Features

- **Profile overview** — real name, avatar, rank, country, GitHub, LinkedIn
- **Multi-color arc gauge** — Easy / Medium / Hard solved vs total, styled to match LeetCode's own UI
- **Activity heatmap** — rolling 26-week "Current" view or full Jan–Dec view for any year, with a year picker that auto-hides years with no data
- **Badges** — displays earned badges with icons loaded from LeetCode CDN
- **Language stats** — problems solved per programming language
- **Recent AC submissions** — last 15 accepted submissions with relative timestamps
- **Home screen widgets**
  - Stats widget (small + medium): solved count, streak, difficulty breakdown with progress bars
  - Heatmap widget (medium + large): submission heatmap; medium shows rolling 26 weeks, large shows the full calendar year
- **No sign-in required** — uses LeetCode's public GraphQL API only

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9 |
| UI | SwiftUI (iOS 16+) |
| Widgets | WidgetKit |
| Data sharing | App Groups / shared `UserDefaults` |
| Networking | `URLSession` async/await |
| API | LeetCode public GraphQL (`https://leetcode.com/graphql`) |
| Image loading | `AsyncImage` (badge icons), `URLSession` (avatar) |
| Date handling | `Calendar`, `RelativeDateTimeFormatter` |

## Architecture

```
LeetCodeTracker (main app)
├── ContentView.swift           Landing / username entry + TabView shell
├── ProfileView.swift           Full profile UI (gauge, heatmap, badges, languages, recent AC)
├── LeetCodeService.swift       GraphQL API layer — 5 parallel async queries
├── Models.swift                App-level models + GraphQL decoding types
└── SharedDataManager.swift     Writes WidgetData to App Group UserDefaults

LeetCodeWidget (extension)
├── LeetCodeWidget.swift        Stats widget (small/medium)
├── LeetCodeHeatmapWidget.swift Heatmap widget (medium/large)
├── WidgetShared.swift          Shared WidgetData model + UserDefaults loader
└── LeetCodeWidgetBundle.swift  Widget bundle entry point
```

### API Queries

Up to 5 parallel GraphQL queries fire on each profile load:

| Query | Required | Data fetched |
|-------|----------|-------------|
| `getUserProfile` | Yes | Username, avatar, rank, submit stats, question counts |
| `userCalendar` | Yes | Streak, active days, 365-day submission calendar |
| `getExtendedProfile` | No (silent fail) | Country, social links, longest streak, badges, languages |
| `userProblemsSolvedBeats` | No (silent fail) | Beats % per difficulty |
| `recentAcSubmissions` | No (silent fail) | Last 15 accepted submissions |

Optional queries silently fail — the app loads successfully even if they return errors.

## Requirements

- Xcode 15+
- iOS 16+
- An Apple Developer account (free tier works) with App Groups capability

## Setup

1. Clone the repo
2. Open `LeetCodeTracker.xcodeproj` in Xcode
3. In **Signing & Capabilities**, enable **App Groups** on both the `LeetCodeTracker` and `LeetCodeWidget` targets using the group ID `group.com.viralsuchak.leetcodetracker`
4. Update the bundle identifier prefix to match your Apple ID
5. Build and run on a device or simulator
