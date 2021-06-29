
require 'rdbgp/helper.rb'
require 'rdbgp/DB/constants.rb'

module Debugger
  class DBGP_ContextNames < Command # :nodoc:
    self.cmd_name = :context_names
    include Helpers
    include DBGP::Constants

    def execute(processor, cmdArgs)
      propInfo = processor.propInfo
      inner_XML_EncodedText = propInfo.contextPropertyNames.map {|name|
        attrs = {
          :name => xmlAttrEncode(name),
          :id => propInfo.contextProperties[name]
        }
        '<context ' + hashToAttrValues(attrs) + " />"
      }.join("\n")
      processor.complete_response_print(nil, inner_XML_EncodedText)
    end
  end
  
  class DBGP_ContextGet < Command # :nodoc:
    self.cmd_name = :context_get
    include Helpers

    def execute(processor, cmdArgs)
      settings = processor.settings
      saved_max_depth = settings['max_depth'][0]
      begin
        return do_context_get(processor, cmdArgs, settings)
      ensure
        settings['max_depth'][0] = saved_max_depth
      end
    end

    def do_context_get(processor, cmdArgs, settings)
      stackDepth = cmdArgs.getArg('-d', :default => '0').to_i
      context_id = cmdArgs.getArg('-c', :default => '0').to_i
      sc = @state.context
      propInfo = processor.propInfo
      stackDepth = get_adjusted_stack_depth(processor, stackDepth)
      the_binding = sc.frame_binding(stackDepth)
      sorted = false
      vars = {}
      namesAndValues = nil
      case context_id
      when LocalVars
        names = nil
        vars = sc.frame_locals(stackDepth)
        _self = sc.frame_self(stackDepth)
        if _self.to_s != "main" && !vars.has_key?('self')
          vars['self'] = _self
        end
        namesAndValues = vars.sort
      when InstanceVars
        self_obj = sc.frame_self(stackDepth)
        inames = self_obj.instance_variables.sort
        cnames = self_obj.class.class_variables.sort
        names = processor.propInfo.get_sorted_object_varnames(inames, cnames, settings['sort_ignore_at_signs'][0] == 1).collect {|name, status| name}
          sorted = true
      when PunctuationVariables
        names = global_variables.delete_if {|x|
          x =~ /^\$[_a-zA-Z]/
        }
      when GlobalVars
        # User-space globals
        names = global_variables.delete_if {|x|
          x =~ /^\$[^_a-z]/ ||
            x == "$ldebug"
        }
      when BuiltinGlobals
        # Ruby-space globals
        names = global_variables.delete_if {|x|
          x =~ /^\$[^A-Z]/
        }
      end
      if names
        processor.logger.debug("names: " + names.join(", "))
      else
        processor.logger.debug("names: " + namesAndValues.map{|x|x[0]}.join(", "))
      end
      if !namesAndValues
        namesAndValues = []
        names.sort! unless sorted
        names.each {|name|
          val = eval(name, the_binding)
          #XXX Use debug_log_eval
          #val = debug_log_eval(name, the_binding)
          if !val.nil? && (val.to_s.length > 0 ||
                           val.instance_variables.length > 0)
            namesAndValues << [name, val]
          end
        }
      end
      inner_XML_EncodedText =
        processor.propInfo.emitContextProperties(namesAndValues,
                                       settings['max_data'][0])
      attrs = {
        :context_id => context_id
      }
      processor.complete_response_print(attrs, inner_XML_EncodedText)
    end
    private :do_context_get

  end
  
  class DBGP_PropertyGet < Command # :nodoc:
    self.cmd_name = :property_get
    include Helpers

    def execute(processor, cmdArgs)
      key_address, context_id, stackDepth, propertyKey, maxDataSize, property_long_name, \
      pageIndex, data_type = cmdArgs.pickArgs('a:c+:d+:k:m+:n:p+:t:')
      raise DBGP_Exception.new(DBP_E_InvalidOption, "No long name supplied") if property_long_name.nil?
      settings = processor.settings
      maxDataSize = settings['max_data'][0] if maxDataSize.nil? or maxDataSize == 0
      @logger = processor.logger
      stackDepth = get_adjusted_stack_depth(processor, stackDepth)
      sc = @state.context
      the_binding = sc.frame_binding(stackDepth)
      val = debug_log_eval_check_address(property_long_name, the_binding, key_address)
      inner_XML_EncodedText =\
         processor.propInfo.emitProperty(property_long_name,
                                         val,
                                         pageIndex,
                                         settings['max_children'][0],
                                         maxDataSize,
                                         (settings['sort_ignore_at_signs'][0] == 1))
      processor.complete_response_print(nil, inner_XML_EncodedText)
    end

  end
    
  class DBGP_PropertyValue < Command # :nodoc:
    # This command is used to get the text for a property,
    # and doesn't follow the max_data limits.
    self.cmd_name = :property_value
    include Helpers

    def execute(processor, cmdArgs)
      context_id, stackDepth, property_long_name, = cmdArgs.pickArgs('c+:d+:n:')
      raise DBGP_Exception.new(DBP_E_InvalidOption, "No long name supplied") if property_long_name.nil?
      settings = processor.settings
      maxDataSize = 0
      stackDepth = get_adjusted_stack_depth(processor, stackDepth)
      @logger = processor.logger
      sc = @state.context
      the_binding = sc.frame_binding(stackDepth)
      val = debug_log_eval(property_long_name, the_binding)
      @logger.debug("property_value( #{property_long_name}) ==> #{val}")
      attrs, inner_XML_EncodedText =\
          processor.propInfo.emitPropertyValue(context_id,
                                               property_long_name,
                                               val)
      processor.complete_response_print(attrs, inner_XML_EncodedText)
    end
  end
    
  class DBGP_PropertySet < Command # :nodoc:
    self.cmd_name = :property_set
    include Helpers

    def execute(processor, cmdArgs)
      key_address, context_id, stackDepth, property_long_name, \
      data_type = cmdArgs.pickArgs('a:c+:d+:n:t:')
      raise DBGP_Exception.new(DBP_E_InvalidOption, "No long name supplied") if property_long_name.nil?
      settings = processor.settings
      new_val = decodeData(cmdArgs.getDataArgs(), "base64")
      if data_type == "string" && new_val !~ /^\s*\d+\s*$/
        new_val = '"' + new_val.gsub('"', '\\"') + '"'
      end
      
      # Context doesn't matter here.
      @logger = processor.logger
      stackDepth = get_adjusted_stack_depth(processor, stackDepth)
      sc = @state.context
      the_binding = sc.frame_binding(stackDepth)
      #processor.complete_response_print(nil, "About to set #{property_long_name} to #{new_val}")
      #return
      begin
        debug_log_set(property_long_name, new_val, the_binding, key_address)
        attrs = {:success => 1}
        processor.complete_response_print(attrs)
      rescue => ex
        @logger.debug("general exception #{ex.class.name} #{ex.message}")
        raise DBGP_Exception.new(DBP_E_CantSetProperty, ex);
      end
    end
  end # ContextSet class

  class DBGP_StackDepth < Command # :nodoc:
    self.cmd_name = :stack_depth

    def execute(processor, cmdArgs)
      # Hide the eval frames from Komodo
      sc = @state.context
      if sc
        depth = @sc.stack_size
        depth = (0...sc.stack_size).reject {|pos|
          sc.frame_file(pos) == "(eval)" || (pos == 0 && sc.frame_file(pos)[-3 .. -1] == '/-e')}.size
      else
        depth = 0
      end
      processor.complete_response_print({:depth => depth})
    end
  end

  
  class DBGP_StackGet < Command # :nodoc:
    self.cmd_name = :stack_get
    include Helpers

    def execute(processor, cmdArgs)
      stackDepth = cmdArgs.getArg('-d', :default => '0')
      @logger = processor.logger
      begin
        stackDepth = stackDepth.to_i
        raise "Negative stack_depth" if stackDepth < 0
      rescue => ex
        @logger.debug("general exception #{ex.class.name} #{ex.message}")
        raise DBGP_Exception.new(DBP_E_StackDepthInvalid,
                                 "Invalid stack depth arg of '#{stackDepth}' : #{msg}")
        return
      end

      # First get the full stack, and then truncate it somehow
      levels = ["  "]
      sc = @state.context
      if sc
        (0...sc.stack_size).each do |pos|
          raw_filename = sc.frame_file(pos)
          next if raw_filename == "(eval)"
          next if (pos == 0 && raw_filename == '-e')
          attrs = {
            :level => pos,
            :type => "file",  # later: do we do eval?
            :lineno => sc.frame_line(pos),
            :where => sc.frame_id(pos) || "",
            :filename => processor.fileToURI(raw_filename)
          }
          finfo = '<stack ' + hashToAttrValues(attrs) + ' />'
          levels << finfo
        end
      end
      inner_XML_EncodedText = levels.join("\n  ")
      processor.complete_response_print(nil, inner_XML_EncodedText)
    end
  end

end
