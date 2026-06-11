---
name: build-everything
description: Build Desktop, Watch, and Phone targets for the project concurrently.
when_to_use: whenever the user wants to "build all targets", "build everything", or "build the project".
---

Build all three app targets concurrently and report a clear pass/fail for each.

Run these as three separate background Bash tool calls (`run_in_background: true`) in the same response, each filtered to just the result. Each uses its own `-derivedDataPath` so the parallel builds don't collide on a shared build database:

```sh
xcodebuild build -project GrainApp.xcodeproj -scheme Desktop -destination 'platform=macOS' -derivedDataPath /tmp/dd-desktop 2>&1 | grep -E 'error:|BUILD SUCCEEDED|BUILD FAILED'
```
```sh
xcodebuild build -project GrainApp.xcodeproj -scheme Watch -destination 'generic/platform=watchOS Simulator' -derivedDataPath /tmp/dd-watch 2>&1 | grep -E 'error:|BUILD SUCCEEDED|BUILD FAILED'
```
```sh
xcodebuild build -project GrainApp.xcodeproj -scheme Phone -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/dd-phone 2>&1 | grep -E 'error:|BUILD SUCCEEDED|BUILD FAILED'
```

Judge each target by whether `** BUILD SUCCEEDED **` or `** BUILD FAILED **` appears — not by the pipeline exit code, which `grep` masks. Report the `error:` lines for any failure, and summarize all three once they finish.
