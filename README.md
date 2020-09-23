# werk

Dead simple task runner.

## Build status

[![CI Status](https://github.com/marghidanu/werk/workflows/CI/badge.svg)](https://github.com/marghidanu/werk/actions)

## Installation

You can follow the installation guide available [here](https://github.com/marghidanu/werk/wiki/Installation).

## Documentation

For more information on how to get started, please check the [wiki](https://github.com/marghidanu/werk/wiki/Usage).

## Features

- [x] Automatic determination of the execution plan
- [x] Parallel jobs execution
- [x] Shell executor
- [ ] Docker executor
- [ ] SSH executor (WIP)
- [x] Real-time output support for parallel jobs
- [x] Simple configuration DSL based on YAML
- [x] Execution report (Partial support)
- [ ] Web UI for browsing the execution reports

## Example

Create a **werk.yml** with the following content:

```yaml
version: "1"

description: "Manage Werk with Werk"

jobs:
  main:
    description: "Build application"
    commands:
      - shards build
    needs:
      - lint
      - test

  lint:
    description: "Lint code"
    commands:
      - ameba
    can_fail: true

  test:
    description: "Test code"
    commands:
      - crystal spec

  docs:
    description: Generate API documentation
    commands:
      - crystal docs
      - open docs/index.html
    silent: true
```

after that, you can run

```
werk run
```

to trigger the entire build flow. You can also start individual jobs by specifying a target like this:

```
werk run lint
```

Here's another example; in this case, I'm building Werk using itself.

[![asciicast](https://asciinema.org/a/Qtd1BoU5vvgK4rOl1R113QKBA.svg)](https://asciinema.org/a/Qtd1BoU5vvgK4rOl1R113QKBA)

## Contributing

1. Fork it (<https://github.com/marghidanu/werk/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Tudor Marghidanu](https://github.com/marghidanu) - creator and maintainer
