# Contributing to ZoneBar

Thanks for your interest in contributing to ZoneBar.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/kkz6/ZoneBar.git
   cd ZoneBar
   ```

2. Open in Xcode:
   ```bash
   open ZoneBar.xcodeproj
   ```

3. Build and run with **Cmd+R**.

### Requirements
- macOS 14.0+ (Sonoma)
- Xcode 15.0+
- Swift 5.9+

## Project Conventions

### Code Style
- Follow standard Swift naming conventions (camelCase for properties/methods, PascalCase for types)
- Use SwiftUI idioms (`@Published`, `@AppStorage`, `@StateObject`)
- Keep views small and focused -- extract subviews when a view exceeds ~100 lines
- Use SF Symbols for icons

### File Organization
- **Models/** -- Data types and business logic
- **Views/** -- SwiftUI views
- **Services/** -- Stateful managers and system integrations
- **Resources/** -- Bundled data files

### Commits
- Write clear, concise commit messages
- Use imperative mood ("Add feature" not "Added feature")
- Reference issue numbers where applicable

## How to Contribute

### Reporting Bugs
- Open an issue with steps to reproduce
- Include macOS version and ZoneBar version
- Attach screenshots if relevant

### Suggesting Features
- Check the [roadmap](docs/ROADMAP.md) first to see if it's already planned
- Open an issue describing the feature and its use case

### Submitting Changes
1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Ensure the project builds without warnings
5. Open a pull request with a clear description of your changes

## Architecture Notes

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for an overview of the codebase architecture, state management patterns, and key design decisions.
