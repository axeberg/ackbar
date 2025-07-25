# Release Process

## Automated Release

Releases are automatically created when the VERSION file is updated on the main branch.

### Steps:

1. Create a new branch for your changes
2. Update the VERSION file with the new version number (e.g., `0.2.0`)
3. Commit and push your changes
4. Create a PR and merge to main
5. The GitHub Actions workflow will automatically create a release

### Manual Release

You can also trigger a release manually:

1. Go to Actions → Release workflow
2. Click "Run workflow"
3. Enter the version number
4. Click "Run workflow"

## Version Numbering

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features
- PATCH: Bug fixes