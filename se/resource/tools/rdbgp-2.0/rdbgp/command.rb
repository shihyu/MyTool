# Swiped from the original command.rb, but with less going on

module Debugger
  class Command # :nodoc:
    class << self
      attr_accessor :cmd_name
      def commands
        @commands ||= []
      end

      def inherited(klass)
        commands << klass
        @cmd_name = klass.cmd_name
      end

      def load_dbgp_commands
        dir = File.dirname(__FILE__)
        dir.gsub!(/\\/, '/') if RUBY_PLATFORM["-mswin"] # Allow for 64-bit, i686
        Dir[File.join(dir, 'commands', '*.rb')].each do |file|
          require file
        end
      end
    end
    
    def initialize(state)
      @state = state
    end

    def handles(cmd_name)
      self.class.cmd_name.to_s == cmd_name
    end

    # XXX -- hbinding, get_binding from command.rb?
    
    protected
    def dbgp_checkpoint_state(processor, reason)
      processor.checkpoint_state(reason, self.class.cmd_name)
    end

    def check_initial_conditions(processor)
      if processor.fakeFirstStepInto
        processor.logger.debug("Ignoring first #{self.class.cmd_name}")
        processor.fakeFirstStepInto = false
        processor.complete_response_print({:status => :break,
                                           :reason => :ok})
      else
        yield if block_given?
        @state.proceed
      end
    end

    # Stack-access helpers
    def get_adjusted_stack_depth(processor, proposed_stack_depth)
      sc = @state.context
      final_stack_depth = proposed_stack_depth
      num_real_levels_found = 0
      (0...sc.stack_size).each do |pos|
        if sc.frame_file(pos) == "(eval)"
          final_stack_depth += 1
        else
          num_real_levels_found += 1
          if num_real_levels_found > proposed_stack_depth
            break
          end
        end
      end
      processor.logger.debug("get_adjusted_stack_depth: adjusting #{proposed_stack_depth} => #{final_stack_depth}")
      return final_stack_depth
    end

    ################
    # Breakpoint helpers
    ################

    def get_ruby_debugger_expn(expr, ko_bkptID, ko_breakpoints_id)
      expns = ["Debugger::DBGP_BreakpointSet.verify_bp(#{ko_bkptID}, #{ko_breakpoints_id})"]
      if expr && expr.size > 0
        expns << expr
      end
      return expns.join(" && ")
    end

  end
  Command.load_dbgp_commands
end
