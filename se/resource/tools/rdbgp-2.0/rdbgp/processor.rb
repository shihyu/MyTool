#
# ruby debugger II

require 'rdbgp/helper.rb'
require 'rdbgp/interface'
require 'rdbgp/command'

require 'rdbgp/DB/constants'
require 'rdbgp/DB/settings'
require 'rdbgp/DB/properties'
require 'rdbgp/DB/redirect'
require 'rdbgp/DB/breakpoint_table'

include Debugger::DBGP::Constants

module Debugger
  class CommandArgs < Array
    def initialize(cmdLine)
      splitCommandLine(cmdLine)
    end
    
    def cmdName
      self[0]
    end
  
    def getArg(option, opts={})
      (0 .. self.size - 1).each {|i|
        if self[i] == option
          return opts['keep'] ? self[i + 1] : self.slice!(i, 2)[1]
        end
      }
      return opts[:default] if opts.has_key?(:default)
      raise "Can't find option #{option} in #{self.join(" ")}"
    end
  
    def getDataArgs()
      return "" if self.size == 0
      self.shift() if self[0] == '--'
      return self.join("")
    end
  
    # Template consists of a <letter>+?:
    # If there's a "+", convert the value to a number
    def pickArgs(template)
      retvals = []
      template.split(/:/).each {|typ|
        let, isplus = "-" + typ[0, 1], typ[1] == ?+
        val = self.getArg(let, :default => nil)
        val = (val.to_i rescue 0) if isplus
        retvals << val
      }
      return retvals
    end
    
    def to_s
      "[#{self.join(" ")}]"
    end
    
    private
    def splitCommandLine(cmd)
      # args = []
      self.clear()
      while cmd.length > 0
        if cmd =~ /^\s+(.*)$/ then
          cmd = $1
        elsif cmd[0] == ?' then
          cmd =~ /^\'((?:\\.|[^\'\\]+)*)('?)(.*)$/
          cmd = $3
          self << $1.gsub(/\\(.)/, '\1')
        elsif cmd[0] == ?" then
          cmd =~ /^\"((?:\\.|[^\"\\]+)*)("?)(.*)$/
          cmd = $3
          self << $1.gsub(/\\(.)/, '\1')
        elsif cmd =~ /^['"]/ then
          cmd =~ /^(.)((?:\\.|[^\1\\]+)*)(\1?)(.*)$/
          cmd = $3
          self << $1.gsub(/\\(.)/, '\1')
        elsif cmd =~ /^([^'"\s]+)\s*(.*)$/ then
          cmd = $2
          self << $1.gsub(/\\(.)/, '\1')
        else
          raise "Can't deal with string <<#{cmd}>>"
        end
      end
      #@args = args
    end
  end

  class ContextContainer # :nodoc:
    include Helpers
    
    attr_reader :context   # The Debugger::Context object
    attr_reader :interface
    attr_accessor   :transactionID, :lastTranID, :stopReason
    attr_accessor   :lastContinuationCommand, :lastContinuationStatus
    attr_accessor   :cmd_name
    attr_accessor   :fakeFirstStepInto
    
    def initialize(host, port, context, logger)
      @interface = DBGP_Interface.new(host, port, context, logger)
      @context = context
      @stopReason = STOP_REASON_STARTING
      @lastContinuationCommand = nil
      @lastContinuationStatus = 'break'
      @lastTranID = 0  # The transactionID that started

      @fakeFirstStepInto = false
    end

    def checkpoint_state(reason, cmd_name)
      @lastContinuationCommand = cmd_name
      @lastContinuationStatus = 'break'
      @lastTranID = @transactionID
      @stopReason = reason
    end

    def shutdown
      @interface.shutdown
    end
  end
  
  class DBGP_CommandProcessor # :nodoc:
    include Helpers
    
    @@stopReasons = %w(starting stopping stopped running break interactive)

    attr_accessor :interface, :logger
    attr_reader   :display
    
    attr_accessor   :supportedCommands, :supportedFeatures, :settings
    attr_accessor   :stdout, :stderr, :propInfo

    attr_accessor   :ko_breakpoints
    attr_accessor   :ibState, :ibBuffer, :startedAsInteractiveShell, :doContinue
    def initialize(host, port, is_interactive_shell, logger, isLocalDebugger=true)
      @logger = logger
      @host = host
      @port = port
      @isLocalDebugger = isLocalDebugger
      
      @display = []
      @mutex = Mutex.new
      @last_cmd = nil
      @actions = []

      #XXX Support interactive shells
      @startedAsInteractiveShell = is_interactive_shell
      
      main_settings = DBGP::Settings.new
      @supportedCommands, @supportedFeatures, @settings = main_settings.get
      
      @orig_stdout = @stdout = $stdout
      @orig_stderr = @stderr = $stderr
      
      @propInfo = DBGP::Properties.new()
      @propInfo.default_encoding = 'base64'

      @initial_dir = Dir.getwd
      @ko_breakpoints = DBGP::Breakpoints.new

      # Interactive variables
      @ibState = IB_STATE_NONE
      @ibBuffer = ''
      
      @contexts = {}  # ThreadNum => Debugger::Context object
      # We can't connect to Komodo yet because we don't have
      # a debugger context we can associate with the connection,
      # and it's too messy to unlink the first one, but create
      # all others together.

      @threadID = nil

      @filter_rubygems = true
      @rubygem_file = %r{\br?ubygems\.rb$}
    end
    
    def self.protect(mname)
      alias_method "__#{mname}", mname
      module_eval %{
        def #{mname}(*args)
          begin
            @mutex.lock
            __#{mname}(*args)
          rescue IOError, Errno::EPIPE
            @interface = nil
          rescue Exception => ex
            @logger.debug("dbgp internal error in #{mname}: #\{ex\}\n") rescue nil
            @logger.debug(ex.backtrace.map{|l| "\t#\{l\}"}.join("\n")) rescue nil
          ensure
            @mutex.unlock
          end
        end
      }
    end
    
    def at_tracing(context, file, line)
      @logger.debug("**** at_tracing ****: (#{file}:#{line}")
    end
    protect :at_tracing

    def at_breakpoint(context, breakpoint)
      n = Debugger.breakpoints.index(breakpoint) + 1
      @filter_rubygems = false
      @logger.debug("Breakpoint %d at %s:%s\n" % [ n, breakpoint.source, breakpoint.pos])
    end
    protect :at_breakpoint

    def at_catchpoint(context, excpt)
      msg = []
      msg << "Catchpoint at %s:%d: `%s' (%s)\n" % [context.frame_file(0), context.frame_line(0), excpt, excpt.class]
      fs = context.stack_size
      tb = caller(0)[-fs..-1]
      if tb
        for i in tb
          msg << "\tfrom #{i}"
        end
      end
      @logger.debug(msg.join("\n"))
    end
    protect :at_catchpoint
    
    # Got it -- only process commands when we're at a line
    def at_line(context, file, line)
      if !@filter_rubygems
        @logger.debug(">>>> at_line thread #{context.thnum} (#{Thread.current})")
      end
      if file == "(eval)"
        context.stop_next = 1
        return
      elsif context.frame_self(0).instance_of?(Debugger::DBGP::RedirectStdOutput)
#        (@orig_stderr || $stderr).puts("**** In redirect, try later")
        context.stop_next = 1
        return
      elsif file["/rdbgp/loader.rb"] && Debugger.line_at(file, line)["Debugger."]
        return
      elsif @filter_rubygems
        # Don't stop if we're in rubygems.rb, ubygems.rb, or one of
        # the files it loads...
        if in_rubygems_context(context, file)
          #@logger.debug("  in_rubygems_context: ignore #{file}")
          context.stop_next = 1
          return
        else
          @filter_rubygems = false
        end
      end

      # Do we need an interface?
      thnum = context.thnum
      if !@contexts.has_key?(thnum)
        #$stderr.puts("$$$$ new thread, we currently know about #{@contexts.length} different contexts") #QQQ
        begin
          @context_container = @contexts[thnum] = ContextContainer.new(@host, @port, context, @logger)
        rescue Errno::EBADF => ex
          w = (@orig_stderr || $stderr)
          w.write("Can't connect to host #{@host}:#{@port}: #{ex}\n" +
                    "...\n" +
                    ex.backtrace[8 .. -1].map{|l| "\t#{l}"}.join("\n") + "\n")
          return
        rescue Exception => ex
          w = (@orig_stderr || $stderr)
          w.write("Error at at_line: #{ex}\n" +
                    ex.backtrace.map{|l| "\t#{l}"}.join("\n") + "\n")
          return
        end
        if @contexts.length > 1
          @context_container.fakeFirstStepInto = true
        elsif @isLocalDebugger
          @context_container.fakeFirstStepInto = true
        end
        
        if @startedAsInteractiveShell
          @context_container.stopReason = STOP_REASON_INTERACT
        end
      else
        @context_container = @contexts[thnum]
      end

      @logger.debug("at_line: %s:%d: %s" % [file, line, Debugger.line_at(file, line)])
      if @context_container.lastContinuationCommand.nil?
        if @startedAsInteractiveShell
          @context_container.stopReason = STOP_REASON_INTERACT
          emitBanner() if Thread.current == Thread.main
        else
          @context_container.stopReason = STOP_REASON_BREAK;
        end
        send_init_packet(file)
      else
        printWithLength(stop_reason_packet())
      end
      process_commands(file, line)
      @logger.debug("<<<< at_line thread #{context.thnum}")
    end
    protect :at_line

    def in_rubygems_context(context, file)
      (0 ... context.stack_size).each do |pos|
        if @rubygem_file.match(context.frame_file(pos))
          return true
        end
      end
      return false
    end
    private :in_rubygems_context
    
    def stop_reason_packet()
      return sprintf(%Q(%s\n<response %s command="%s" status="%s" reason="ok" transaction_id="%s"/>),
                     xmlHeader(),
                     namespaceAttr(),
                     @context_container.lastContinuationCommand,
                     @context_container.lastContinuationStatus,
                     @context_container.lastTranID)
    end

    def checkpoint_state(reason, cmd_name)
      @context_container.checkpoint_state(reason, cmd_name)
    end

    def fakeFirstStepInto()
      @context_container.fakeFirstStepInto
    end

    def fakeFirstStepInto=(val)
      @context_container.fakeFirstStepInto = val
    end
    
    def getStopReason
      @@stopReasons[@context_container.stopReason] or raise "Bad stop reason: #{@context_container.stopReason}"
    end
    private :getStopReason

    def stopReason=(val)
      @context_container.stopReason = val
    end

    def interface
      @context_container.interface
    end
    
    # Handlers called by dbgp-command classes
    def do_status()
      complete_response_print({:status => (@startedAsInteractiveShell ?
                                           :interactive : getStopReason()),
                                :reason => :ok})
    end

    def do_ishell_status(attrs)
      complete_response_print(attrs.merge({:status => getStopReason(),
                                            :reason => :ok}))
    end

    def thread_id_from_context
      label = Thread.current == Thread.main ? "main" : "Thread"
      num = @context_container.context.thnum()
      return "#{label} #{num}"
    end

    def broadcast_complete_response(attrs)
      @contexts.each do |thnum, contextContainer|
        @context_container = contextContainer
        complete_response_print(attrs)
      end
    end

    def wrap_up(last_ex=nil)
      @contexts.each do |thnum, contextContainer|
        @context_container =  contextContainer
        complete_response_print({:command => @context_container.lastContinuationCommand || :run,
                                  :status => (@context_container.lastContinuationStatus = :stopped),
                                  :reason => :ok})
        if (@context_container.context.thread rescue Thread.main) == Thread.main
          begin
            if last_ex && @stderr
              msg = get_exception_msg(last_ex)
              @stderr.write(msg)
            end
            #rescue Exception => ex
            #  makeErrorResponse(999, ex)
          end
        else
          begin
            @context_container.context.thread.exit()
          rescue
          end
        end
        @context_container.shutdown
      end
    end
    
    # @interface.close;exit!
    
    #public helpers

    def do_stderr(cmdArgs)
      @orig_stderr = $stderr
      $stderr = @stderr = do_common_stdio_redirection(cmdArgs, $stderr, 'stderr')
      @logger.rebind()
    end
    def do_stdout(cmdArgs)
      @orig_stdout = $stdout
      $stdout = @stdout = do_common_stdio_redirection(cmdArgs, $stdout, 'stdout')
    end

    def restore_stdio
      $stderr = @stderr = @orig_stderr if @orig_stderr
      $stdout = @stdout = @orig_stdout if @orig_stdout
    end

    def do_common_stdio_redirection(cmdArgs, origStream, streamType)
      copyType = cmdArgs.getArg('-c', :default => 0).to_i
      raise "Invalid -c value of #{copyType}" unless (Debugger::DBGP::Redirect_Disable .. Debugger::DBGP::Redirect_Redirect) === copyType
      # Debugger::
      obj = Debugger::DBGP::RedirectStdOutput.new(origStream,
                                                 @context_container.interface,
                                                 streamType,
                                                 copyType,
                                                  self)
      obj.default_encoding = @settings['data_encoding'][0]
      complete_response_print({:success => 1})
      return obj
    end
    private :do_common_stdio_redirection

    private
    
    def process_commands(file, line)
      state = State.new do |s|
        s.context = @context_container.context
        s.file    = file
        s.line    = line
        s.binding = s.context.frame_binding(0)
        s.display = display
        s.interface = @context_container.interface
      end
      commands = Command.commands.map{|cmd| cmd.new(state) }
      chr_zero = 0.chr()
      while !state.proceed?
        input = @context_container.interface.read_command(@mutex)
        break unless input
        cmd_line = input
        begin
        # input.split(chr_zero).each do |cmd_line|
          @logger.debug("@@@@ Got command [#{cmd_line}]")
          cmd_args = CommandArgs.new(cmd_line)
          @context_container.cmd_name = cmd_args.shift
          @context_container.transactionID = cmd_args.getArg('-i')
          @threadID = cmd_args.getArg('-z', :default => nil)
          
          # All the dbgp_x command classes define regexp =
          # /^[name]\b/

          begin
            # @logger.debug("QQQ: Command: #{@context_container.cmd_name}")
            if cmd = commands.find{ |c| c.handles(@context_container.cmd_name) }
              if @context_container.context.dead? && cmd.class.need_context
                makeErrorResponse(DBP_E_CommandUnimplemented,
                                   "Command #{@context_container.cmd_name} is unavailable")
              elsif @supportedCommands[@context_container.cmd_name] == 0
                makeErrorResponse(DBP_E_CommandUnimplemented,
                                   "Command #{@context_container.cmd_name} is not currently supported")                
              else
                cmd.execute(self, cmd_args)
              end
            else
                makeErrorResponse(DBP_E_CommandUnimplemented,
                                 "Command #{@context_container.cmd_name} not recognized")
            end
          rescue DBGP_Exception => db_ex
            makeErrorResponse(db_ex.ecode, db_ex) #trimExceptionInfo(ex))
          rescue Exception => ex
            makeErrorResponse(DBP_E_InternalException, ex) #trimExceptionInfo(ex))
          end
        end
      end
      # At this point we fall back to the at_line command, and will be
      # reinvoked at some later time.
      @logger.debug("No more commands")
    end # end function process_commands

    def print(*args)
      #@logger.debug(args.join(" "))
      @context_container.interface.print(*args)
    end
    
    def complete_response_print(attrs, inner_XML_EncodedText=nil)
      attrs ||= {}
      attrs[:command] = @context_container.cmd_name unless attrs.has_key?(:command)
      attrs[:transaction_id] = @context_container.transactionID unless attrs.has_key?(:transaction_id)
      #XXX Does this work?
      attrs[:thread] ||= @threadID || thread_id_from_context()
      tag_parts = [
        sprintf("%s\n<response %s ", xmlHeader(), namespaceAttr()),
        hashToAttrValues(attrs),
        inner_XML_EncodedText ? ">#{inner_XML_EncodedText}</response>" : " />"]
      printWithLength(tag_parts.join(""))
    end
    public :complete_response_print

    def send_init_packet(file)
      # Send the init command at this point
      # Note: The parent field only makes sense for
      # handling multi-process debugging.
      
      attrs = {
        :appid => $$.to_s,  # getpid
        :idekey => ENV.fetch('DBGP_IDEKEY', ""),
        :thread => thread_id_from_context(),
        :language => :Ruby,
        :protocol_version => settings['protocol_version'][0]
      }
      if (cookie = ENV.fetch('DBGP_COOKIE', "")).length > 0
        attrs[:session] = cookie
      end
      attrs[:parent] = Process.ppid unless running_on_windows()
      if @startedAsInteractiveShell
        attrs[:interactive] = '>'
      else
        attrs[:fileuri] = fileToURI(file)
      end
      hostname = ENV.fetch('HOST_HTTP', nil)
      unless hostname
        require "socket"
        hostname = Socket.gethostname
      end
      attrs[:hostname] = hostname if hostname

      initString = [xmlHeader(), "\n",
        "<init ",
        namespaceAttr(), " ",
        hashToAttrValues(attrs),
        " />"].join("");
      printWithLength(initString)
    end
    
    def complete_stream_print(attrs, inner_XML_EncodedText="")
      tag1 = ((sprintf(%Q(%s\n<stream %s ),
                          xmlHeader(), namespaceAttr(), @context_container.cmd_name, @context_container.transactionID)) + hashToAttrValues(attrs))
      tag2 = ">#{inner_XML_EncodedText}</stream>"
      printWithLength(tag1 + tag2)
    end
    public :complete_stream_print

    def printWithLength(str)
      printWithLength_helper(@context_container.interface, str)
    end
    
    def makeErrorResponse(ecode, ex)
      msgFinal = get_exception_msg(ex)
      @logger.error("Error #{ecode}:#{msgFinal}\n")
      innerElement = sprintf(%Q(<error code="%d" apperr="4"><message>%s</message></error>),
                          ecode, xmlEncode(msgFinal))
      complete_response_print(nil, innerElement);
    end

    def emitBanner
      require 'rbconfig'
      cnf = Config::CONFIG
      printf("Ruby %s [%s]\n", RUBY_VERSION, cnf['arch'])
    end
    
    class State # :nodoc:
      attr_accessor :context, :file, :line, :binding
      attr_accessor :frame_pos, :previous_line, :display
      attr_accessor :interface

      def initialize
        @frame_pos = 0
        @previous_line = nil
        @proceed = false
        yield self
      end

      def print(*args)
        @interface.print(*args)
      end

      def confirm(*args)
        true
      end

      def proceed?
        @proceed
      end

      def proceed
        @proceed = true
      end
    end # end class State


  end # end class DBGP_CommandProcessor
end # end module Debugger
