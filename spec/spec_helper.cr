require "spec"
require "yaml"
require "json"
require "uuid"
require "log"
require "dotenv"
require "colorize"
require "digest/md5"

require "../src/craph"
require "../src/docr"
require "../src/gitleaks"
require "../src/vault"

require "../src/werk/config/*"
require "../src/werk/config/jobs/*"
require "../src/werk/utils/*"
require "../src/werk/context"
require "../src/werk/schedulers/*"
require "../src/werk/executors/*"
require "../src/werk/pipeline"

Werk::Utils::PrefixIO.enabled = false
