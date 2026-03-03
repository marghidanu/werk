module Werk
  class Variables
    delegate :[], :[]=, :each, :has_key?, :empty?, :size, :merge!, to: @data

    @data : Hash(String, String)

    def initialize(@data = Hash(String, String).new)
    end

    def initialize(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      @data = Hash(String, String).new(ctx, node)
    end

    # Parse CLI -e flags: ["KEY=value", ...] into Variables.
    def self.parse(raw : Array(String)) : self
      vars = new
      raw.each do |item|
        if match = item.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/)
          vars[match[1]] = match[2]
        end
      end
      vars
    end

    # Merge with another Variables or Hash, returning a new instance.
    def merge(other : Variables | Hash(String, String)) : Variables
      data = other.is_a?(Variables) ? other.to_h : other
      Variables.new(@data.merge(data))
    end

    # Convert to plain Hash for external boundaries (Template, Vault, Process).
    def to_h : Hash(String, String)
      @data
    end
  end
end
