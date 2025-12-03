# build-and-install-script Development Rules

## Project Overview

**build-and-install-script** is a **usage/application** project that consumes bash-tools to provide build and install functionality. This project focuses on application-specific functionality and leverages bash-tools utilities rather than reimplementing them.

## Coding Style & Conventions

### Function Naming

- Use `namespace.function()` pattern (e.g., `bai.run`, `ssl.setup`, `system.setup`)
- Namespace should match the module/file name
- Function names should be descriptive and use camelCase

**Examples:**
```bash
bai.run()
ssl.setup()
system.setup()
```

### Function Documentation

All public functions **MUST** have documentation blocks using this format:

```bash
## @function: namespace.function(param1, param2?)
##
## @description: Clear description of what the function does
##
## @param: $1 - Parameter description
## @param: $2 - Optional parameter description (use ? to indicate optional)
##
## @return: Description of return value or void
##
## @example: namespace.function "arg1" "arg2"
##
## @note: Important implementation details (if needed)
##
## @dependencies: List required modules (if any)
```

**Required fields:**
- `@function` - Function signature
- `@description` - What the function does
- `@param` - Each parameter (use `?` for optional)
- `@return` - Return value description or "void"

**Optional fields:**
- `@example` - Usage example (recommended for complex functions)
- `@note` - Important implementation details
- `@dependencies` - Required modules

### Error Handling

- Use `error.throw(message, code)` for fatal errors that should stop execution
- Use `log.warning()` for recoverable issues
- Validate inputs at function boundaries
- Provide clear error messages with context

**Example:**
```bash
if [[ ! -f "$file" ]]; then
  error.throw "File not found: $file" 1
fi
```

### Logging

Use appropriate log levels (provided by bash-tools):

- `log.verbose()` - Very detailed debugging information
- `log.debug()` - Debug information for development
- `log.info()` - General informational messages
- `log.warning()` - Warning messages for recoverable issues
- `log.error()` - Error messages (use `error.throw()` for fatal errors)

### Variable Naming

- Use descriptive names
- Prefer local variables: `local var_name="$1"`
- Use UPPER_CASE for constants/globals only
- Avoid global namespace pollution

### Shebang

All executable scripts **MUST** start with `#!/bin/bash`

## File Structure

### Source Organization

```
build-and-install-script/
├── src/
│   ├── main/              # Source code
│   │   ├── module-name/
│   │   │   ├── bundle.module-name.sh
│   │   │   ├── cli.sh
│   │   │   └── module.sh
│   │   └── ...
│   └── test/              # Test files
│       └── module-name/
│           └── module.test.sh
├── dist/                 # Generated bundles
├── VERSION               # Semantic version
└── release.sh           # Release script
```

### Module Structure

Each module should be self-contained in its own directory:

- `bundle.*.sh` - Bundle entrypoint (if needed)
- `cli.sh` - CLI interface (if needed)
- `module.sh` - Main module code

## Import/Source Patterns

### Loading bash-tools

In bundle files, **always** load bash-tools from GitHub releases:

```bash
source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f
```

This loads the `lib.tools` bundle which provides:
- `log.*` - Logging functions
- `error.*` - Error handling
- `folder.*` - File system operations
- `string.*` - String utilities
- `array.*` - Array utilities
- And more...

### Import Pattern

After loading bash-tools, use `import` for local modules:

```bash
import "./backup.sh"
import "./build-and-install.sh"
import "./cli.sh"
```

### Source Pattern

For absolute paths or when import is not available:

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../core/importer.sh"
```

### Import Order

1. First: Load bash-tools bundle (if in bundle file)
2. Then: Import local dependencies
3. Last: Import the module's own dependencies

### Avoid

- Circular dependencies
- **Reimplementing functionality available in bash-tools**
- Hardcoded absolute paths
- Direct source of bash-tools files (use bundle loader)

## Testing Requirements

### Test File Structure

- Test files: `*.test.sh` in `src/test/`
- Test files should mirror `src/main/` structure
- Example: `src/main/generate-ssl-certificate/ssl.sh` → `src/test/generate-ssl-certificate/ssl.test.sh`

### Test Function Naming

- Test functions: Named `test_*` (e.g., `test_ssl_setup_success`)
- Use descriptive names that explain what is being tested

### Test Framework

Use `expect` framework for assertions (provided by bash-tools):

```bash
expect "$result" to.equal "expected"
expect "$result" to.contain "substring"
expect "$result" to.be.empty
expect "$result" to.have.length 5
expect.run "command" to.fail.with 1 "error message"
```

### Lifecycle Hooks

Use when needed:

- `before()` - Setup before all tests
- `before_each()` - Setup before each test
- `after_each()` - Cleanup after each test
- `after()` - Cleanup after all tests

### Test Requirements

- All public functions should have test coverage
- Tests must pass before any release
- Use bash-tools testing framework

## Bundling Process

### Bundle Entrypoints

- Any `bundle.*.sh` file in `src/main/` is a bundle entrypoint
- Bundle name is derived from filename: `bundle.bai.sh` → `bai`

### Bundle Structure

Bundles should:

1. Load bash-tools via `source <(curl ...)`
2. Import local dependencies via `import`
3. Define the main entry function
4. Call the entry function with `"$@"` to pass arguments

**Example:**
```bash
#!/bin/bash

source <(curl -fsSL https://github.com/nu-art/bash-tools/releases/latest/download/bundle.loader.sh) -b lib.tools -f

import "./backup.sh"
import "./build-and-install.sh"
import "./cli.sh"

bai.run "$@"
```

### Bundler Behavior

- Automatically resolves `import` and `source` statements recursively
- Generated bundles go to `dist/bundle.*.sh`
- Bundles include version metadata and generation timestamp
- Strips import/source statements and reorders for dependency correctness

### Bundle Usage

Bundles are distributed via GitHub releases and can be loaded:

```bash
source <(curl -fsSL https://github.com/nu-art/build-and-install-script/releases/latest/download/bundle.bai.sh)
```

## Release Process

Follow this exact sequence:

1. **Run tests**: `release.run_tests`
2. **Bundle artifacts**: `release.bundle`
3. **Bump version**: `release.bump_version <type>` (patch/minor/major)
4. **Commit version bump**: `release.commit_version_bump`
5. **Tag version**: `release.tag_current_version`
6. **Publish to GitHub**: `release.publish_github`

Execute via: `bash release.sh`

## Version Management

### Semantic Versioning

- Format: `MAJOR.MINOR.PATCH` (e.g., `0.1.26`)
- **Patch**: Bug fixes (backward compatible)
- **Minor**: New features (backward compatible)
- **Major**: Breaking changes

### Version File

- Stored in `VERSION` file at project root
- Single line with version number only
- Updated automatically during release process

## Documentation Standards

### Function Documentation

All public functions **MUST** include:

- `## @function:` - Function signature
- `## @description:` - What the function does
- `## @param:` - Each parameter (use `?` for optional)
- `## @return:` - Return value description or "void"
- `## @example:` - Usage example (for complex functions)
- `## @note:` - Important implementation details (if needed)
- `## @dependencies:` - Required modules (if any)

### Code Comments

- Comment complex logic, but prefer self-documenting code
- Use `#` for inline comments
- Use `##` for documentation blocks

## Code Quality

### Best Practices

- Use `set -e` in scripts that should fail on errors
- Prefer early returns over deep nesting
- Use local variables to avoid global namespace pollution
- Validate function inputs
- Handle edge cases explicitly

### Code Organization

- Group related functions together
- Keep functions focused and single-purpose
- Avoid deep nesting (max 3-4 levels)
- Use helper functions for complex logic

## Project-Specific Guidelines

### Usage/Application Focus

- **Depends on bash-tools** (loaded from GitHub releases)
- Focus on application-specific functionality
- **Use bash-tools utilities rather than reimplementing**
- Keep bundle size reasonable
- Leverage existing bash-tools modules (logger, error, folder, etc.)

### Module Design

- One module per file/directory
- Clear separation of concerns
- Minimal dependencies between modules
- Reuse bash-tools utilities whenever possible

### bash-tools Integration

- Always load bash-tools via bundle loader in bundle files
- Use bash-tools utilities: `log.*`, `error.*`, `folder.*`, `string.*`, `array.*`, etc.
- **Don't duplicate functionality that exists in bash-tools**
- Keep dependencies on bash-tools version flexible (use latest)

## Common Patterns

### Path Resolution

```bash
local REPO_ROOT
REPO_ROOT="$(folder.repo_root)"
```

### Function with Optional Parameters

```bash
function.name() {
  local required="$1"
  local optional="${2:-default_value}"
  # function body
}
```

### Using bash-tools Utilities

```bash
# Logging
log.info "Processing..."
log.debug "Debug info"
log.warning "Warning message"
error.throw "Fatal error" 1

# File operations
folder.create "$dir"
folder.delete "$dir"

# String operations
string.contains "$text" "substring"
string.replace "old" "new" "$text"

# Array operations
array.contains "$item" "${array[@]}"
array.map fromArray toArray mapperFn
```

### Error Handling Pattern

```bash
if [[ ! -f "$file" ]]; then
  error.throw "File not found: $file" 1
fi
```

### CLI Argument Parsing

```bash
REMAINING_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --option)
      # handle option
      shift
      ;;
    *)
      # collect remaining args
      REMAINING_ARGS+=("$1")
      shift
      ;;
  esac
done

# Process remaining args
process_args "${REMAINING_ARGS[@]}"
```

