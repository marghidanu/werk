require "log"
require "yaml"
require "json"
require "uuid"
require "dotenv"
require "option_parser"
require "tallboy"
require "colorize"
require "digest/md5"
require "wait_group"

require "../src/craph"
require "../src/docr"
require "../src/tools"
require "../src/vault"

require "./werk/error"
require "./werk/config/*"
require "./werk/config/jobs/*"
require "./werk/utils/*"
require "./werk/context"
require "./werk/schedulers/*"
require "./werk/executors/*"
require "./werk/pipeline"
require "mcp"
require "./werk/mcp/state"
require "./werk/mcp/tools/*"
require "./werk/commands/*"
require "./werk/application"

module Werk
  VERSION = {{ env("APP_VERSION") || "0.0.0" }}
end
