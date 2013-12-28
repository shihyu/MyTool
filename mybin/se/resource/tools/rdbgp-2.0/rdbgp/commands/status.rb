module Debugger
  class DBGP_Status < Command # :nodoc:
    self.cmd_name = :status
    def execute(processor, cmdArgs)
      processor.do_status()
    end
  end
end
