module Werk::Executor
  abstract class Base
    abstract def run(name : String, job : Werk::Model::Job, context : String)
  end
end
