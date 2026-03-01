module Werk
  class Context
    getter session_id : UUID
    getter target : String
    getter name : String
    getter directory : String
    getter variables : Werk::Variables
    getter stage_id : Int32
    getter batch_id : Int32

    def initialize(
      @session_id,
      @target,
      @name,
      @directory,
      @variables,
      @stage_id,
      @batch_id,
    )
    end
  end
end
