module Docr
  class Error < Exception
    getter status_code : Int32?

    def initialize(message : String, @status_code : Int32? = nil)
      super(message)
    end
  end
end
