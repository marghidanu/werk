module Werk::Model
  class JobResult
    getter name : String
    getter exit_code : Int32
    getter output : String
    getter duration : Time::Span

    def initialize(@name, @exit_code, @output, @duration)
    end
  end
end
