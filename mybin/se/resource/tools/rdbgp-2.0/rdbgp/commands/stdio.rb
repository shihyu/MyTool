require 'rdbgp/helper.rb'

module Debugger
  class DBGP_Stdout < Command # :nodoc:
    self.cmd_name = :stdout
    include Helpers

    def execute(processor, cmdArgs)
      processor.do_stdout(cmdArgs)
    end
  end
  class DBGP_Stderr < Command # :nodoc:
    self.cmd_name = :stderr
    include Helpers

    def execute(processor, cmdArgs)
      processor.do_stderr(cmdArgs)
    end
  end
end
