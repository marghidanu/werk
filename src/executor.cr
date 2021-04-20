require "uuid"

module Werk
  abstract class Executor
    abstract def run(job : Werk::Model::Job, session_id : UUID, name : String, context : String) : {Int32, String}
  end
end
