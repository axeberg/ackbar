# Contributing to Ackbar

## Commit Message Guidelines

We follow a combination of jj-vcs style topics with Chris Beams' commit message principles.

### Format

```
<topic>: <imperative mood summary, max 50 chars>

<explanation of why the change was made, wrapped at 72 chars>
<what problem it solves or what it improves>

- Additional details if needed
- Implementation notes
```

### Guidelines

1. Start with a topic followed by a colon (e.g., `ui:`, `window:`, `build:`)
2. Use imperative mood in the subject line ("Add feature" not "Added feature")
3. Limit the subject line to 50 characters
4. Capitalize the subject line
5. Do not end the subject line with a period
6. Separate subject from body with a blank line
7. Wrap the body at 72 characters
8. Use the body to explain what and why vs. how

### Common Topics

- `ui`: User interface changes
- `window`: Window management and behavior
- `build`: Build system and scripts
- `shortcuts`: Keyboard shortcuts
- `config`: Configuration changes
- `docs`: Documentation updates
- `deps`: Dependency updates

### Examples

```
ui: Add menu bar with popup window

Previously users had to manually open the app window.
Now they can access it directly from the menu bar,
improving workflow efficiency.
```

```
window: Fix position persistence using autosaveName

Window position was reset on each launch because the
frameAutosaveName wasn't properly configured. This ensures
the OS remembers window placement between sessions.
```

```
build: Update scripts for current functionality

The previous justfile commands were outdated. Updated to
match the current project structure and removed references
to non-existent files.
```

## Code Style

- Follow existing Swift conventions in the codebase
- Use SwiftUI idioms where appropriate
- Keep code simple and readable

## Testing

Run the build before committing:
```bash
just build
```