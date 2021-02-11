# werk

Dead simple task runner. Now with support for Docker.

## Build status

[![CI Status](https://github.com/marghidanu/werk/workflows/CI/badge.svg)](https://github.com/marghidanu/werk/actions)

## Installation

You can follow the installation guide available [here](https://github.com/marghidanu/werk/wiki/Installation).

## Documentation

For more information on how to get started, please check the [wiki](https://github.com/marghidanu/werk/wiki/Guide).

## Features

- [x] Automatic determination of the execution plan
- [x] Parallel jobs execution
- [x] Shell executor
- [x] Docker executor
- [x] Real-time output support for parallel jobs
- [x] Simple configuration DSL based on YAML
- [x] Execution report
- [ ] Web UI for browsing the execution reports (?)
- [ ] Enable logging

## Example

Create a **werk.yml** with the following content:

```yaml
version: "1"

description: "Manage Werk with Werk"

jobs:
  main:
    description: "Build application"
    executor: local
    commands:
      - shards build
    needs:
      - lint
      - test

  lint:
    description: "Lint code"
    executor: docker
    image: veelenga/ameba
    commands:
      - ameba
    can_fail: true

  test:
    description: "Test code"
    executor: local
    commands:
      - crystal spec

  docs:
    description: Generate API documentation
    executor: local
    commands:
      - crystal docs
      - open docs/index.html
    silent: true
```

after that, you can run

```
werk run
```

 You can also start individual jobs by specifying a target like this:

```
werk run lint
```

Here's another example; in this case, I'm building Werk using itself.

[![asciicast](https://asciinema.org/a/ssMl6y1R2RcaDgfTHj5uJejzH.svg)](https://asciinema.org/a/ssMl6y1R2RcaDgfTHj5uJejzH)

## Contributing

1. Fork it (<https://github.com/marghidanu/werk/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Tudor Marghidanu](https://github.com/marghidanu) - creator and maintainer
