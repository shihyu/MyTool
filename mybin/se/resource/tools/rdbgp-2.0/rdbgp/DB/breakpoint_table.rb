# breakpoint_table
# Store other info here:
# state (enable|disable|temporary)
# hit-count
# hit-condition
# ruby-debug ID

require 'rdbgp/helper.rb'

module Debugger
  module DBGP
    class BreakpointHitInfo
      include Helpers
      @@hitConditions = {
        # hit_count is the varying value the debugger maintains
        # hit_value is the thing the user specifies, stating when to break
        # a hit_value of 0 means don't test
        # This is needed because the IDE doesn't resend the hit-condition
        # on re-enable after the hit test has been temporarily disabled
        
        '>=' => Proc.new {|hit_count, hit_value| hit_count >= hit_value },
        '==' => Proc.new {|hit_count, hit_value| hit_count == hit_value },
        '%'  => Proc.new {|hit_count, hit_value| hit_count % hit_value == 0},
        nil  => Proc.new {|hit_count, hit_value| true},
      }

      attr_accessor :hit_count, :hit_value
      attr_reader   :eval_func_str

      def initialize(hit_value, eval_func_str)
        @hit_count = 0
        @hit_value = hit_value
        # Throw an exception if no match
        self.eval_func_str = eval_func_str
      end

      def eval_func_str=(val)
        @eval_func_str = val
        @xml_encoded_eval_func_str = val && xmlAttrEncode(val)
        @eval_func = @@hitConditions.fetch(val)
      end

      def inc_and_test
        return true if @hit_value == 0
        @hit_count += 1
        if @eval_func
          res = @eval_func.call(@hit_count, @hit_value)
          return res
        else
          return true
        end
      end

      def clear
        @hit_count = @hit_value = 0
        @eval_func = null
      end

      def add_attributes(lvs)
        if @hit_value && @hit_value != 0
          lvs['hit_count'] = @hit_count
          lvs['hit_value'] = @hit_value
          lvs['hit_condition'] = xmlAttrEncode(@eval_func_str)
        end
      end
    end
    
    class BreakpointInfo
      include Helpers

      # Info on a breakpoint -- used to be an array, but this is better
      attr_accessor :bOriginalURI, :bLine, :bState, :bType
      attr_accessor :bFunctionName, :bExpression, :bException, :bHitInfo
      attr_accessor :rubyDebugID
      def initialize(bState, bType, koID)
        @koID = koID
        @bState = bState
        @bType = bType
        @bOriginalURI = nil
        @bLine = nil
        @bFunctionName = nil
        @bExpression = nil
        @bException = nil
        @bHitInfo = nil
        @rubyDebugID = -1
      end

      def addHitInfo(hitValue, hitConditionString)
        @bHitInfo = BreakpointHitInfo.new(hitValue, hitConditionString)
      end

      def do_hit?
        if @bState == :disabled
          return false
        elsif @bState == :temporary
          @bState = :disabled
        end

        # Now check for hit-counts
        if @bHitInfo
          return @bHitInfo.inc_and_test
        end
        return true
      end

      def print(data_encoding)
        attrs = {
          :state => @bState == :temporary ? :enabled : @bState,
          :type => @bType
        }
        attrs[:filename] = @bOriginalURI if @bOriginalURI
        #bug 83208: should be lineno=..., not line=...
        # Keep the old behavior for non-Komodo clients using this engine.
        attrs[:line] = attrs[:lineno] = @bLine if @bLine
        attrs[:temporary] = @bState == :temporary ? 1 : 0
        attrs[:exception] = @bException if @bException
        attrs[:function] = @bFunctionName if @bFunctionName
        @bHitInfo.add_attributes(attrs) if @bHitInfo
        
        tag1 = "<breakpoint " + hashToAttrValues(attrs)
        if @bExpression
          tag2 = ">" + cdata(encodeData(@bExpression, data_encoding)) + "</breakpoint>"
        else
          tag2 = " />"
        end
        return tag1 + tag2
      end

    end
    
    class Breakpoints
      attr_reader :bkptInfoTable
      def initialize()
        @@next_bkpt_id = 1
        @bkptInfoTable = {}
      end

      # We'll map Komodo ID#s to ruby-debug ID #s
      # No need to go the other way.
      def get_new_breakpoint(bState, bType)
        id = @@next_bkpt_id
        @@next_bkpt_id += 1
        @bkptInfoTable[id] = BreakpointInfo.new(bState, bType, id)
        return id
      end

      def list
        return @bkptInfoTable.values
      end
      
      def lookup(id)
        return @bkptInfoTable[id]
      end
      
      def remove(id)
        # Use the value we return
        return @bkptInfoTable.delete(id)
      end
      
      def meets_static_conditions?(id)
        bkpt_info = lookup(id)
        
        # First look to see if we're enabled
        # Temporary breakpoints are enabled once.
        if !bkpt_info
          return false
        else
          res = bkpt_info.do_hit?
          return res
        end
      end
    end
    
  end
end
