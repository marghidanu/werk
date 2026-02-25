# Werk

Local CI pipeline runner with parallel execution and Docker support.

[![CI Status](https://github.com/marghidanu/werk/workflows/CI/badge.svg)](https://github.com/marghidanu/werk/actions)

## Features

- Declarative pipelines in a single YAML file
- Automatic parallelism based on the dependency graph
- Local and Docker executors
- Built-in vault for encrypting secrets in dotenv files
- Execution reports with per-job timing and status
- MCP server for AI assistant integration (experimental)

## Quick start

Install via Homebrew:

```
brew tap marghidanu/werk
brew install werk
```

Create a `werk.yml`:

```yaml
version: "1.0"

jobs:
  main:
    executor: local
    needs:
      - lint
      - test
    commands:
      - echo "Build complete!"

  lint:
    executor: local
    commands:
      - echo "Linting..."

  test:
    executor: local
    commands:
      - echo "Running tests..."
```

Run it:

```
werk run
```

Inspect the execution plan:

```
werk plan
```

Get a detailed report:

```
werk run -r
```

## Documentation

- [Installation](https://github.com/marghidanu/werk/wiki/Installation)
- [Getting started](https://github.com/marghidanu/werk/wiki/Guide)
- [Philosophy](https://github.com/marghidanu/werk/wiki/Philosophy)
- [Internals](https://github.com/marghidanu/werk/wiki/Internals)
- [MCP Server](https://github.com/marghidanu/werk/wiki/MCP)
- [FAQ](https://github.com/marghidanu/werk/wiki/FAQ)

## License

MIT
