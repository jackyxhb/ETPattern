# GitHub Copilot Instructions – English Chunk Flashcard iOS App
# Target: Swift + SwiftUI, iOS 16+, Xcode 15+
# Goal: A beautiful, native iOS app that imports your 12-group CSV files and lets users learn 300 English patterns with auto-TTS audio.

## Core Requirements (must be implemented exactly)
1. The app must import CSV files in this exact format (separator: ;;):
   Front;;Back;;Tags
   (Back contains 5 examples separated by <br>)

2. Each imported CSV becomes a CardSet (deck) named after the file or group.
3. One Card =
   - front: the pattern (e.g. "I think...")
   - back: 5 examples with <br> line breaks (HTML displayed as multi-line text)

4. Card display
   - Full-screen card with big, centred text
   - Tap anywhere → flip animation (180° rotation)
   - Front = bold pattern
   - Back = pattern at the top (smaller) + 5 examples below (nice line spacing)

5. Automatic TTS Audio
   - Every time a side becomes visible → speak its text aloud
   - Use AVSpeechSynthesizer (en-US or en-GB voice, natural rate 0.48–0.52)
   - One speaker instance only (stop previous utterance before new one)
   - Optional: let user choose American / British voice in Settings

6. Learning flow
   - "Play" button → starts spaced-repetition session (simple Leitner or basic daily review is enough)
   - Swipe right = "Easy/Know it" → longer interval
   - Swipe left or "Again" button = see again soon
   - Progress circle + cards today counter

7. CardSet management
   - List of decks (Group 1–12 + any imported CSV)
   - Long-press → Rename / Delete / Re-import
   - Built-in 12 groups already included as bundled CSV assets

## Project Structure (create exactly these files)