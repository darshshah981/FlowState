# Builder Note

## What This Project Is

FlowState is a local macOS dictation app built around `whisper.cpp` with a menu bar interface, a bottom-screen HUD, configurable shortcuts, and direct text insertion into the focused app.

The goal was not to build a general transcription tool. The goal was to build something that feels fast enough and lightweight enough for everyday dictation on macOS, while staying local and private.

That distinction ended up shaping almost every product and engineering decision in the app.

## How The Build Evolved

### 1. Start with a local Whisper shell, then remove the wrong defaults

The initial architecture used local Whisper transcription with a relatively heavy default model and slower decode settings. That was workable from a technical standpoint, but it was not the right product tradeoff for dictation.

The first big realization was that a dictation product is not optimized the same way as batch transcription:

- lower latency matters more than squeezing out marginal accuracy
- short utterances behave differently than long recordings
- users feel delays after key release much more than they feel small transcript differences

That pushed the app toward:

- `base.en` as the main default
- `greedy` decoding as the main default
- live preview as optional, not always on
- aggressive simplification of the “default” path

The lesson here was simple:

> For dictation, a slightly less accurate model that responds immediately often feels better than a nominally stronger model with slow finalization.

### 2. Treat the audio/transcription system like a pipeline, not one model call

Another early lesson was that “transcription quality” is not just the model.

The pipeline matters:

- how audio is captured
- whether silence is trimmed
- whether quiet speech is normalized
- whether context is preserved
- whether preview and final transcription compete for the same engine

This project moved from “record, then transcribe” toward a more layered pipeline:

- audio cleanup before inference
- separate live preview behavior from final transcription
- vocabulary hints and post-processing
- heuristics for deciding when a preview can stand in for a heavier final pass

That changed the feel of the app more than just swapping Whisper model sizes.

The main lesson:

> Accuracy complaints are often pipeline complaints in disguise.

### 3. Build the UX around interaction mode, not around implementation details

The app originally behaved like a technical shell around local Whisper. Over time it moved closer to a real dictation product by centering the interaction modes:

- `Hold To Talk`
- `Press To Start/Stop`

That sounds obvious in retrospect, but it mattered because it changed how the app should be organized:

- shortcuts are product behavior, not just settings
- the HUD has to reflect the active mode
- stop/cancel controls only make sense in toggle mode
- the app has to understand which trigger started the current session

Once both modes existed, the system could no longer treat “a dictation session” as generic. It had to track session origin and behavior.

The lesson:

> Interaction mode is part of core state, not just a UI preference.

### 4. Hotkeys became one of the hardest parts

The hotkey system turned out to be much more complex than it looked initially.

At first, the app used a single preset-style global shortcut. That was easy to implement, but too limiting.

Then it evolved to:

- separate shortcuts for both modes
- user-recorded shortcuts instead of preset menus
- support for modifier-only shortcuts like `Control + Option`
- support for longer shortcuts like `Control + Option + Space`

That surfaced a deeper problem: global shortcut systems behave very differently depending on whether a shortcut includes a concrete key or only modifiers.

Specific lessons from this part:

- Carbon hotkeys work well for standard key combinations, but not for modifier-only shortcuts.
- Modifier-only shortcuts require a different event-monitoring strategy.
- Once prefix-overlapping shortcuts exist, precedence matters.
- Recording shortcuts and listening for live shortcuts cannot happen in the same way at the same time.

This led to several key design choices:

- pause live hotkey handling while recording a new shortcut
- support modifier-only shortcuts through event monitoring
- delay modifier-only activation slightly so longer combos can win
- cap `Hold To Talk` at 2 keys and require `Press To Start/Stop` to use at least 3 keys

That last rule was not just a UX choice. It was an architecture simplification.

The lesson:

> Shortcut design is part UX, part systems programming, and part input-policy design.

### 5. The HUD mattered more than expected

The first HUD versions worked functionally but did not feel like a polished product.

Over time the HUD was pushed toward a more intentional design:

- a small bottom-center pill
- translucent styling
- waveform-only by default
- subtitle panel separated above the pill
- stop/cancel controls only when the mode requires them

A key lesson from the HUD work was that “less UI” often feels better for dictation:

- users do not want a giant panel while speaking
- they do want confidence that the app is listening
- they only want text when live subtitles are explicitly helpful

That led to the split:

- pill for listening state and controls
- subtitle panel only when live subtitle mode is enabled

Another important technical detail:

- smoothing the waveform display improved perceived quality even though it did not change transcription at all

The lesson:

> Perceived responsiveness is partly transcription speed and partly motion quality.

### 6. The menu bar window needed to stop looking like a debug console

A lot of internal controls were useful during development:

- warm backend
- preview insert
- direct backend details

But as the product solidified, those controls became confusing.

The menu bar app should answer a few simple questions:

- Is FlowState ready?
- What shortcuts are active?
- Are permissions okay?
- Where do I change behavior?

That drove cleanup:

- removing development-only actions
- keeping the main window focused on state, shortcuts, and basic status
- moving more detailed configuration into Settings

The lesson:

> Internal tooling should not leak into the product surface unless it is truly user-facing.

### 7. Permissions on macOS were a product concern, not just an implementation concern

This app needs high-trust permissions:

- Microphone
- Accessibility
- Input Monitoring

Those permissions shaped the build and distribution story more than expected.

One hard-earned lesson was that development builds behave differently than shipped apps. Rebuilding and replacing a locally signed app caused macOS to treat permissions as unstable enough that they sometimes had to be removed and re-added.

That led to a clearer mental model:

- development path and shipping path are not the same
- permission behavior depends on bundle identity, path, and signing stability
- local rebuilds can make TCC feel unreliable even when the app logic is fine

The lesson:

> Shipping a high-trust Mac app is partly a code problem and partly a platform-identity problem.

### 8. Packaging and sharing forced a shift from “project” to “product”

Once the app felt good enough to share, new concerns appeared immediately:

- GitHub repository hygiene
- vendored dependency structure
- `.gitignore`
- release artifacts
- public vs private repo
- eventual DMG/signing/notarization questions

Even creating the GitHub repo surfaced a real engineering issue: the vendored `whisper.spm` dependency originally existed as an embedded git repository, which would have made clones incomplete if pushed as-is. That had to be normalized into ordinary tracked source for the repo to be self-contained.

The lesson:

> What feels acceptable in a local workspace often breaks down the moment you try to share it.

## What Ended Up Working Well

These were some of the strongest decisions in the project:

- Choosing `base.en + greedy` as the practical default
- Treating live preview and final transcription as different concerns
- Making the HUD smaller and quieter instead of richer and louder
- Supporting both hold and toggle modes
- Allowing custom shortcuts rather than locking into predefined combos
- Adding structure to shortcut rules instead of trying to support every edge case forever

## What Was More Difficult Than Expected

- Reliable shortcut behavior across modifier-only and key-based combinations
- Handling overlapping shortcuts without making the app feel laggy
- Keeping permissions stable during local development
- Preventing the UI from drifting into “power-user tool” territory
- Balancing speed and accuracy without making the configuration matrix overwhelming

## What I Learned

### Product Lessons

- Local AI products live or die on interaction latency, not just raw model quality.
- Giving users fewer, better choices often beats exposing every tunable parameter.
- A dictation tool should feel invisible when idle and obvious when active.
- The right constraints make the product feel more reliable, not less flexible.

### Engineering Lessons

- Input systems get complicated quickly when global shortcuts, modifier-only detection, and live text insertion all interact.
- For desktop apps, state transitions matter as much as the underlying service layer.
- Event timing, animation smoothing, and UI placement can noticeably change perceived performance.
- Distribution concerns should be thought about earlier when the app depends on privileged permissions.

### Personal Builder Lessons

- “Try it and feel it” was more valuable than theorizing about the best model or the best shortcut architecture.
- A lot of the right decisions only became obvious after using the app repeatedly.
- Shipping pressure is useful because it reveals which parts are real product requirements and which parts are just interesting engineering ideas.

## If I Were Continuing From Here

The next likely steps would be:

1. Clean up the menu/settings UX further so the app feels less diagnostic.
2. Add a proper README and release notes for the public repository.
3. Stabilize packaging, signing, and distribution for non-developer users.
4. Consider whether the preview/final transcription policy should become simpler and more opinionated.
5. Benchmark newer runtime options only if they improve the product experience, not just the spec sheet.

## Final Takeaway

This app was not really built by “adding Whisper to a menu bar app.”

It was built by repeatedly reducing friction in a loop:

- make capture easier
- make feedback quieter and clearer
- make latency feel shorter
- make controls more intentional
- make the state machine match real user behavior

That is what turned it from a local speech experiment into something that actually feels usable.
