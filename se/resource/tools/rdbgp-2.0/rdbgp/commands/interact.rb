
require 'rdbgp/helper.rb'
require 'rdbgp/DB/constants.rb'

module Debugger
  class DBGP_Interact < Command # :nodoc:
    self.cmd_name = :interact
     include Helpers
     include DBGP::Constants

    def initialize(*args)
      super(*args)
      @@prompts = [">", "*"]
      @@stop_collecting_cmd_re = Regexp.new('\\t*\\*[\\r\\n]*$')
    end

    def execute(processor, cmdArgs)
      do_abort, i_mode = cmdArgs.pickArgs('a:m+:')
      decodedData = decodeData(cmdArgs.getDataArgs(), "base64")
      logger = processor.logger
      processor.stopReason = STOP_REASON_INTERACT
      processor.ibState = IB_STATE_START if processor.ibState == IB_STATE_NONE
      if i_mode == 0
        processor.ibState = IB_STATE_NONE
        processor.stopReason = processor.startedAsInteractiveShell ? STOP_REASON_STOPPED : STOP_REASON_BREAK
        processor.do_ishell_status({:more => 0, :prompt => ""})
        @state.proceed if processor.startedAsInteractiveShell
        return
      end
      moreValue = 0
      processor.stopReason = STOP_REASON_INTERACT
      if !do_abort && decodedData.length > 0
        if processor.ibState == IB_STATE_START
          processor.ibBuffer = decodedData
        else
          processor.ibBuffer += "\n#{decodedData}"
          case processor.ibBuffer
          when /<<(\w+).+^\1$/sm
            logger.debug("Found bareword here-doc ending for [#{processor.ibBuffer}]")
            processor.ibBuffer += "\n"
          when /<<([\"\'])((?:\.|.)*?)\1.*^\2$/sm
            logger.debug("Found quoted-target here-doc ending for [#{processor.ibBuffer}]")
            processor.ibBuffer += "\n"
          when /<< .*\n$/s
            logger.debug("Found empty-line here-doc ending for [#{processor.ibBuffer}]")
            processor.ibBuffer += "\n"
          end
          logger.debug("Have -- 1 ** [#{processor.ibBuffer}]")
        end
        processor.ibBuffer.gsub!(/^\s+$/, '') # Remove all white-space
        processor.doContinue = false
        if processor.ibBuffer.length > 0
          if processor.ibBuffer =~ /^(.*?[^\\](?:\\\\)*)\\$/m
            # Make sure the final \\ isn't an escaped
            # \\ at the end of a string.
            processor.ibBuffer = $1
            logger.debug("found it, now: #{processor.ibBuffer}")
            processor.doContinue = true
          else
            #XXX: Capture stdout side effects
            begin
              logger.debug("Have -- 3 ** [#{processor.ibBuffer}]");
              res = eval(processor.ibBuffer, Debugger.current_context.frame_binding(0))
              logger.debug("After eval, res is a #{res.class}")
              processor.doContinue = false
              mainError = nil
            rescue SyntaxError
              mainError = $! && $!.to_s
              res = nil
              logger.debug("Syntax Error: #{mainError}")
              # Don't complain about syntax errors at the end of the line
              if mainError =~ /^(.*)\n(\s*)\^\s*$/ && $2.size < $1.size
                # This doesn't handle tabs correctly, but we can't
                # get the tab size from the IDE.
                processor.doContinue = false
              elsif mainError =~ /:\d+:\s*syntax error.*\n.*:\d+:\s*syntax error/m
                # Two syntax errors: print them and bail out
                logger.debug("Found two syntax errors in |#{mainError}|")
                processor.doContinue = false
              elsif mainError =~ /:(\d+):\s*syntax error.*/ && $1.to_i < processor.ibBuffer.split(/\n/).size
                logger.debug("Got a syntax error at line %d of %d", $1.to_i, processor.ibBuffer.split(/\n/).size)
                processor.doContinue = false
              elsif decodedData =~ @@stop_collecting_cmd_re
                processor.doContinue = false
                mainError = nil
              else
                processor.doContinue = true
                res = '*resetting command buffer*'
              end
            rescue ScriptError
              mainError = $! && $!.to_s
              res = nil
              logger.debug("Script Error: #{mainError}")
              processor.doContinue = false
            rescue Exception
              mainError = $! && $!.to_s
              if mainError == 'exit'
                Kernel.exit!(0)
              end
              res = nil
              logger.debug("general Exception: #{mainError}")
              processor.doContinue = false
            end
          end
          if processor.doContinue
            processor.ibState = IB_STATE_PENDING
            moreValue = 1
          else
            processor.ibState = IB_STATE_START
            if mainError
              # Make sure we print one last \n
              $stderr.print((mainError + "\n").sub(/\n+$/, "\n"))
            elsif res.nil?
              logger.debug('res is nil')
            elsif res.class == String
              logger.debug("res is a string = #{res}")
              res2 = res[-1] == ?\n ? res : res + "\n"
              $stdout.print(res2)
            else
              logger.debug("res is a #{res.class}")
              s = res.inspect
              if s && s.size > 0
                res2 = s[-1] == ?\n ? s : s + "\n"
                $stdout.print(res2)
              end
            end
          end
        else
          logger.debug("interact: decodedData not defined\n")
          if !i_mode || processor.ibState == IB_STATE_START
            logger.debug("State start")
          else
            moreValue = 1
          end
        end
      end
      processor.do_ishell_status({:more => moreValue,
                                  :prompt => @@prompts[moreValue]})
    end
  end
end
