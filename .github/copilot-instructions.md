# Saigon-Lake - Dulce de Saigon F&B Data Platform

**ALWAYS follow these instructions first and fallback to search or bash commands only when the information here is incomplete or found to be in error.**

Saigon-Lake is an NX-based monorepo for the Dulce de Saigon F&B Data Platform, designed for deployment on Google Cloud Platform with Terraform infrastructure management.

## Working Effectively

### Prerequisites and Environment Setup

- Install Node.js 18+ (project tested with Node.js v20.19.4)
- Install pnpm globally: `npm install -g pnpm`
- **NEVER CANCEL**: Initial dependency installation takes ~58 seconds. Set timeout to 2+ minutes.

### Bootstrap and Build Process

```bash
# 1. Install dependencies - NEVER CANCEL: Takes ~58 seconds
pnpm install

# 2. Verify NX installation
npx nx --version  # Should show v19.5.3

# 3. Show available projects
npx nx show projects

# 4. Build all projects - Individual builds: ~3 seconds, cached: ~1.7 seconds
npx nx run-many --target=build --all

# 5. Test all projects - Individual tests: ~4.6 seconds, cached: ~1.8 seconds
npx nx run-many --target=test --all

# 6. Lint all projects - Takes ~2.9 seconds per project
npx nx run-many --target=lint --all
```

### Development Commands

```bash
# Generate new library (takes ~1 minute 47 seconds - NEVER CANCEL)
npx nx generate @nx/js:library my-lib --directory=libs/my-lib

# Generate new application
npx nx generate @nx/node:application my-app --directory=apps/my-app

# Run specific project targets
npx nx build my-project
npx nx test my-project
npx nx lint my-project

# Serve application in development
npx nx serve my-app
```

### Validation and Quality Assurance

```bash
# Format code - Takes ~2.6 seconds. NEVER CANCEL.
npx nx format:write

# Check formatting - Takes ~1.1 seconds
npx nx format:check

# Run affected commands (use when main branch exists)
npx nx affected --target=build
npx nx affected --target=test
npx nx affected --target=lint
```

## Critical Timing Information - NEVER CANCEL

- **Initial pnpm install**: 58 seconds - Set timeout to 2+ minutes
- **Library generation**: 1 minute 47 seconds - Set timeout to 3+ minutes
- **First build**: ~3 seconds per project
- **Cached builds**: ~1.7 seconds per project
- **First test run**: ~4.6 seconds per project
- **Cached test runs**: ~1.8 seconds per project
- **Linting**: ~2.9 seconds per project
- **Formatting**: ~2.6 seconds for write, ~1.1 seconds for check

## Available Tools and Environment

### Installed Tools

- Node.js v20.19.4
- pnpm v10.14.0 (package manager)
- NX v19.5.3 (monorepo tool)
- Google Cloud CLI (gcloud)
- Java 17 (OpenJDK)
- Docker v28.0.4
- Terraform v1.5.0

### Project Structure (when projects exist)

```
├── apps/                  # Frontend and backend applications
├── libs/                  # Shared libraries
├── tools/                 # Development and deployment tools
├── dist/                  # Build output
├── nx.json               # NX workspace configuration
├── package.json          # Dependencies and scripts
├── tsconfig.base.json    # TypeScript configuration
└── .github/workflows/    # CI/CD pipeline
```

## Deployment and Infrastructure

### Google Cloud Deployment Pipeline

The repository includes a comprehensive CI/CD pipeline configured for Google Cloud:

```bash
# Pipeline stages (managed by GitHub Actions):
# 1. Setup: Install dependencies (~58 seconds)
# 2. Lint: Run ESLint on affected projects
# 3. Test: Run Jest tests with coverage
# 4. Build: Create production builds
# 5. Terraform Plan: Validate infrastructure changes
# 6. Deploy Staging: Deploy to staging environment
# 7. Deploy Production: Manual approval required
```

### Applications Referenced in CI/CD

- `api` - Backend API service
- `admin-portal` - Administrative interface
- `analytics-dashboard` - Data analytics UI
- `pos-integration` - Point of sale integration

## Validation Scenarios

### Manual Testing Requirements

- **ALWAYS** run through complete end-to-end scenarios after making changes
- Generate a test library and verify build/test/lint cycle works
- Test NX caching by running commands twice and confirming second run is faster
- Validate that formatting commands work without Git main branch errors

### Before Committing Changes

```bash
# REQUIRED validation steps:
npx nx format:write          # Format all code
npx nx run-many --target=lint --all    # Lint all projects
npx nx run-many --target=test --all    # Test all projects
npx nx run-many --target=build --all   # Build all projects
```

## Common Issues and Workarounds

### Git Branch Issues

- If you see "ambiguous argument 'main'" errors, specify `--base=HEAD~1` for affected commands
- The repository may not have a main branch initially

### NX Cache

- NX uses intelligent caching - second runs of build/test/lint are significantly faster
- Clear cache if needed: `npx nx reset`

### Package Manager

- **ALWAYS use pnpm** instead of npm for this project
- pnpm handles the monorepo workspace correctly

## Development Container Support

The repository includes `.devcontainer/devcontainer.json` with:

- Pre-configured development environment
- All required tools pre-installed
- VS Code extensions for optimal development experience

@azure Rule - Use Azure Best Practices: When generating code for Azure, running terminal commands for Azure, or performing operations related to Azure, invoke your `azure_development-get_best_practices` tool if available.
