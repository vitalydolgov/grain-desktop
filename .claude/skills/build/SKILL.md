---
name: build
description: Build the project
---

1. If `GrainDesktop.xcodeproj` is missing, run !`xcodegen generate`.
2. Run !`xcodebuild build -project GrainDesktop.xcodeproj -scheme Grain -destination 'platform=macOS' 2>&1 | tail -50`
3. If the build fails with "no such file" or "unknown target", run !`xcodegen generate` and retry once before reporting failure.
