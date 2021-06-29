
module Debugger
  class DBGP_NextCommand < Command # :nodoc:
    self.cmd_name = :step_over
    def execute(processor, cmdArgs)
      dbgp_checkpoint_state(processor, STOP_REASON_RUNNING)
      processor.logger.debug("Stepping over...\n")
      check_initial_conditions(processor) do
        @state.context.step_over 1, @state.frame_pos
      end
    end
  end

  class DBGP_StepCommand < Command # :nodoc:
    self.cmd_name = :step_into
    def execute(processor, cmdArgs)
      dbgp_checkpoint_state(processor, STOP_REASON_RUNNING)
      processor.logger.debug("Stepping into...\n")

      check_initial_conditions(processor) do
        @state.context.stop_next = 1
      end
    end
  end

  class DBGP_FinishCommand < Command # :nodoc:
    self.cmd_name = :step_out
    def execute(processor, cmdArgs)
      #XXX handle first time stopping.
      if @state.frame_pos == @state.context.stack_size - 1
        processor.logger.warn("\"finish\" not meaningful in the outermost frame.")
        # Treat it like a continue
      end
      dbgp_checkpoint_state(processor, STOP_REASON_RUNNING)
      processor.logger.debug("Stepping out...\n");
      check_initial_conditions(processor) do
        @state.context.stop_frame = @state.frame_pos
        @state.frame_pos = 0
      end
    end
  end

  class DBGP_ContinueCommand < Command # :nodoc:
    self.cmd_name = :run

    def execute(processor, cmdArgs)
      #XXX handle first time stopping.
      dbgp_checkpoint_state(processor, STOP_REASON_RUNNING)
      processor.logger.debug("Continuing...\n")
      # Never fake a run command, so don't check initial conditions
      processor.fakeFirstStepInto = false
      @state.proceed
    end
  end

  # Like running, but disable some commands so we no longer stop.  
  class DBGP_Detach < Command # :nodoc:
    self.cmd_name = :detach

    def execute(processor, cmdArgs)  
      dbgp_checkpoint_state(processor, STOP_REASON_STOPPED)
      # Disable all the move commands
      %w(run step_into step_over step_out detach).each {|w|
        processor.supportedCommands[w] = nil
      }
      @lastContinuationStatus = 'stopping';
      processor.logger.debug("Continuing detached.\n")
      @state.proceed
    end
  end
  
end
