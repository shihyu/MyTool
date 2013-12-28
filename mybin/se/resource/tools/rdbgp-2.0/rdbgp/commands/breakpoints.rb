
require 'rdbgp/helper.rb'
require 'rdbgp/DB/constants.rb'
require 'rdbgp/DB/breakpoint_table.rb'

module Debugger
  
  class DBGP_BreakpointSet < Command # :nodoc:
    self.cmd_name = :breakpoint_set
    
    include Helpers
    include DBGP::Constants

    def initialize(*args)
      super(*args)
      @@ko_breakpoints = nil
    end
    
    def execute(processor, cmdArgs)
      # Common stuff here
      bWorkingFileURI, bFunctionName, bLine, bIsTemporary, bState, bType,
        bHitValue, bHitConditionOperator = cmdArgs.pickArgs('f:m:n+:r+:s:t:h:o:')

      reason = nil
      if (bType.nil?)
        raise DBGP_Exception.new(DBP_E_InvalidOption, "No breaktype specified")
      end
      bType = bType.to_sym
      if !{:line => nil, :call => nil, :conditional => nil}.has_key?(bType)
        reason = "#{bType} breakpoints aren't supported"
        raise DBGP_Exception.new(DBP_E_BreakpointTypeNotSupported, reason)
      end

      # Big simplification for start -- files and lines only
      # Either set filename+lineno or class+methodName (both as strings)
      source = pos = nil
      if bWorkingFileURI
        raise DBGP_Exception.new(DBP_E_BreakpointTypeNotSupported,
                                 "can't set a breakpoint at both a file and function name") if bFunctionName
        bWorkingFileURI = bWorkingFileURI.sub(%r{^dbgp:///file:/}, 'file:/')
        # ruby-debug doesn't handle paths well, so here things don't
        # work great when multiple files end with the same base.
        #XXX Fix this.
        source = File.basename(uriToFile(bWorkingFileURI))
        pos = bLine
      elsif (!bFunctionName)
        raise DBGP_Exception.new(DBP_E_BreakpointTypeNotSupported,
                                 "neither file nor method name specified for a new breakpoint")
      elsif (mo = /^(.*):(.*)/.match(bFunctionName))
          klass = debug_silent_eval(mo[1])
          if klass && !klass.kind_of?(Module)
            raise DBGP_Exception.new(DBP_E_ParseError,
                                     "only module classes are breakable, not class @{mo[1]}")
          end
          source = klass ? klass.name : ""
          pos = mo[2]
      else
        source = ""
        pos = bFunctionName.intern.id2name
      end

      bState = bState.to_sym
      bState = :temporary if bIsTemporary != 0 && bState == :enabled
      ko_bkptID = processor.ko_breakpoints.get_new_breakpoint(bState, bType)
      ko_bp = processor.ko_breakpoints.lookup(ko_bkptID)

      ko_bp.addHitInfo((bHitValue.to_i rescue 0), bHitConditionOperator)
      ko_bp.bOriginalURI = bWorkingFileURI if bWorkingFileURI
      ko_bp.bLine = bLine if bLine
      ko_bp.bFunctionName = bFunctionName if bFunctionName

      expr = cmdArgs.getDataArgs()
      # Warning: ruby-debug evals empty strings as false, but nil as true
      expr2 = decodeData(expr, "base64")
      expr3 = get_ruby_debugger_expn(expr2, ko_bkptID, processor.ko_breakpoints.object_id)
      
      ko_bp.bExpression = expr2 if expr.size > 0

      # Make this available to the callback
      # This one fails
      # @@ko_breakpoints = processor.ko_breakpoints unless @@ko_breakpoints
      # processor.logger.debug("bp_set: @@ko_breakpoints = #{@@ko_breakpoints}")

      b = Debugger.add_breakpoint(source, pos, expr3)
      ko_bp.rubyDebugID = b.id
      processor.logger.debug("Set breakpoint %d at %s:%s (%s)\n" % [b.id, source, pos.to_s, b.expr])
      attrs = {:state => bState, :id => ko_bkptID}
      processor.complete_response_print(attrs)
    end
    
    def self.verify_bp(id, bktp_table_id)
      # $stderr.puts("In the callback, id=#{id}")
      ko_breakpoints = ObjectSpace._id2ref(bktp_table_id)
      # $stderr.puts("self.verify_bp: @@ko_breakpoints = #{@@ko_breakpoints}\n")
      res = ko_breakpoints.meets_static_conditions?(id)
      # $stderr.puts("meets_static_conditions?(#{id}) ==> #{res}")
      return res
    end
  end

  class DBGP_BreakpointGet < Command # :nodoc:
    self.cmd_name = :breakpoint_get
    include Helpers
    
    def execute(processor, cmdArgs)
      ko_bkptID = cmdArgs.getArg('-d').to_i
      ko_bp = processor.ko_breakpoints.lookup(ko_bkptID)
      if !ko_bp
        raise DBGP_Exception.new(DBP_E_NoSuchBreakpoint, "Can't find breakpoint #{ko_bkptID}")
      end
      processor.complete_response_print(nil, ko_bp.print(processor.settings['data_encoding'][0]))
    end
  end

  class DBGP_BreakpointList < Command # :nodoc:
    self.cmd_name = :breakpoint_list
    include Helpers

    def execute(processor, cmdArgs)
      dlist = processor.ko_breakpoints.list.map{|ko_bp| ko_bp.print(processor.settings['data_encoding'][0])}
      processor.complete_response_print(nil, dlist.join("\n"))
    end
  end

  class DBGP_BreakpointRemove < Command # :nodoc:
    self.cmd_name = :breakpoint_remove
    include Helpers

    def execute(processor, cmdArgs)
      ko_bkptID = cmdArgs.getArg('-d').to_i
      ko_bp = processor.ko_breakpoints.remove(ko_bkptID)
      if !ko_bp
        raise DBGP_Exception.new(DBP_E_NoSuchBreakpoint, "Can't find breakpoint #{bkptID}")
      end
      bkptID = ko_bp.rubyDebugID
      if !bkptID || bkptID < 0
        raise DBGP_Exception.new(DBP_E_NoSuchBreakpoint, "Can't find ruby-debug breakpoint #{bkptID}")
      end
      Debugger.remove_breakpoint(bkptID)
      processor.complete_response_print(nil)
    end
  end

  class DBGP_BreakpointUpdate < Command # :nodoc:
    self.cmd_name = :breakpoint_update
    include Helpers

    def execute(processor, cmdArgs)
      ko_bkptID, bState, bLine, bHitValue, bHitConditionOperator = cmdArgs.pickArgs('d+:s:n+:h:o:')
      bState = bState.nil? ? :enabled : bState.to_sym
      ko_bp = processor.ko_breakpoints.lookup(ko_bkptID)
      if !ko_bp
        raise DBGP_Exception.new(DBP_E_NoSuchBreakpoint, "Can't find breakpoint #{bkptID}")
      end
      
      bkptID = ko_bp.rubyDebugID

      #XXX Implement all changes:
      # state, hit, and expression (calls for a new inner bkpt)

      if ko_bp.bState != bState
        # This one's easy
        ko_bp.bState = bState
      end

      bHitValue = bHitValue.to_i rescue 0
      bHitInfo = ko_bp.bHitInfo
      if bHitValue != 0 || bHitConditionOperator
        made_change = false
        if bHitValue != 0 && bHitValue != bHitInfo.hit_value
          bHitInfo.hit_value = bHitValue
          made_change = true
        end
        if bHitConditionOperator && bHitConditionOperator != bHitInfo.eval_func_str
          bHitInfo.eval_func_str = bHitConditionOperator
          made_change = true
        end
        if made_change
          bHitInfo.hit_count = 0
        end
      elsif bHitInfo.hit_value > 0
        # Turn it off
        bHitInfo.hit_value = 0
      end

      rd_bp = Debugger.breakpoints.find {|b| b.id == bkptID}
      raise DBGP_Exception.new(DBP_E_NoSuchBreakpoint, "Can't find breakpoint #{bkptID}") unless rd_bp

      expr = cmdArgs.getDataArgs()
      expr2 = decodeData(expr, "base64")
      new_expr = get_ruby_debugger_expn(expr2, ko_bkptID, processor.ko_breakpoints.object_id)

      # Changes in the line# or expression call for a new
      # underlying ruby_debug breakpoint, because it doesn't
      # have any writable properties

      create_new_breakpoint = new_expr != rd_bp.expr
      if create_new_breakpoint
        new_line = bLine > 0 ? bLine : rd_bp.pos
      elsif bLine != 0 && bLine != rd_bp.pos
        create_new_breakpoint = true
        ko_bp.bLine = new_line = bLine
      end

      if create_new_breakpoint
        source = rd_bp.source
        Debugger.remove_breakpoint(rd_bp.id)
        processor.logger.debug("Setting breakpoint.expr = #{new_expr}")
        b = Debugger.add_breakpoint(source, new_line, new_expr)
        ko_bp.bExpression = expr2 if expr.size > 0
        processor.logger.debug("Setting ko.expr = #{expr2}")
        ko_bp.rubyDebugID = b.id
      end
      attrs = {:state => bState, :id => ko_bkptID}
      processor.complete_response_print(nil, ko_bp.print(processor.settings['data_encoding'][0]))
    end
  end
end
