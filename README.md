# werk

Dead simple task runner.

## Features

- [x] Automatic determination of the execution plan
- [x] Parallel jobs execution
- [x] Shell executor
- [ ] Docker executor
- [ ] SSH executor (WIP)
- [x] Real-time output support for parallel jobs
- [x] Simple configuration DSL based on YAML
- [ ] Save execution report
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
```

after that you can run

```
werk run
```

to trigger the entire build flow. You can also trigger individual jobs by specifing a target like this:

```
werk run lint
```

## Contributing

1. Fork it (<https://github.com/marghidanu/werk/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Tudor Marghidanu](https://github.com/marghidanu) - creator and maintainer
