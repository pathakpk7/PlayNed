# Contributing to PlayNed

Thank you for your interest in contributing to **PlayNed**!

## Code Guidelines

1. **Deterministic Game Engines**: All game rules, moves, and board logic must reside in pure deterministic engines under `backend/app/games/` and follow the `BaseGameEngine` abstract base class.
2. **Platform Agnosticism**: Platform infrastructure (rooms, codes, WebSocket real-time events, user sessions) must remain decoupled from specific game rules.
3. **Responsive UI**: All frontend widgets and game screens must support both mobile/touch and desktop form factors with no horizontal layout overflow.
4. **Preserve Existing Games**: Any changes to the platform must never break existing games like Hangman Reimagined.

## Testing Requirements

Before submitting code:
- Run backend tests:
  ```bash
  python -m pytest backend/tests
  ```
- Run Flutter frontend tests:
  ```bash
  flutter test
  ```
- Ensure all tests pass with 0 errors.
