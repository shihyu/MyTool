
require 'rdbgp/DB/constants.rb'
require 'rdbgp/helper.rb'
module Debugger
  
  class DBGP_StopCommand < Command # :nodoc:
    self.cmd_name = :stop
    include DBGP::Constants
    include Helpers

    def execute(processor, cmdArgs)
      dbgp_checkpoint_state(processor, STOP_REASON_STOPPING)
      processor.broadcast_complete_response({:status => :stopping,
                                              :reason => :ok})
      Debugger.save_history if Debugger.respond_to? :save_history
      processor.logger.close()
      processor.restore_stdio()
      begin
        processor.interface.close()
      rescue Exception => ex
        $stderr.puts(get_exception_msg(ex))
      end
        
      exit! # exit -> exit!: No graceful way to stop threads...
    end
  end
    
  class DBGP_BreakCommand < Command # :nodoc:
    self.cmd_name = :break
    include DBGP::Constants

    def execute(processor, cmdArgs)
      dbgp_checkpoint_state(processor, STOP_REASON_STOPPING)
      processor.complete_response_print({:status => :break,
                                         :reason => :ok})
    end
  end
end
