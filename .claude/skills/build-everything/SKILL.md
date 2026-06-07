---
name: build-everything
description: Build Desktop, Watch, and Phone targets for the project concurrently.
when_to_use: whenever the user wants to "build all targets", "build everything", or "build the project".
---

Build all three app targets concurrently.

Run all three commands in a single response as simultaneous (concurrent) Bash tool calls:

1. !`xcodebuild build -project GrainApp.xcodeproj -scheme Desktop -destination 'platform=macOS'`
2. !`xcodebuild build -project GrainApp.xcodeproj -scheme Watch -destination 'generic/platform=watchOS Simulator'`
3. !`xcodebuild build -project GrainApp.xcodeproj -scheme Phone -destination 'generic/platform=iOS Simulator'`
