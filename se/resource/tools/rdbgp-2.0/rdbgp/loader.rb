# Extend module Debugger from ruby-debug.rb

require 'pp'
require 'stringio'
require "socket"
require 'thread'

begin
  rubyVersionArray = RUBY_VERSION.split('.')
  baseDir = File.dirname(File.dirname(File.expand_path(__FILE__))) + File::SEPARATOR
  $:.push((baseDir + rubyVersionArray[0..2].join(".")))
  $:.push((baseDir + rubyVersionArray[0..1].join(".")))
  require 'ruby-debug-base'
  $:.pop
  $:.pop
rescue LoadError => ex1
  # Try loading it as a gem, but if it fails give the
  # original error.
  begin
    require 'rubygems'
    require 'ruby-debug-base'
  rescue LoadError
    $stderr.write("\Error: #{ex1}\n\n")
    $stderr.write("The Komodo ruby debugger couldn't load the ruby-debug-base component.\n")
    $stderr.write("  This library ships with Komodo, but also can be installed by running `gem install ruby-debug-base'\n")
    exit
  end
end

require 'rdbgp/processor'
require 'rdbgp/helper'

module Debugger

  class LoggerWrapper
    require 'logger'
    def initialize(logfile, verboseLevel)
      @orig_stderr = $stderr.clone
      @orig_stdout = $stdout.clone
      @verboseLevel = (verboseLevel.to_i == 0 ? 0 : 4) rescue 0
      case logfile
      when 'stdout'
        #$stderr.write("logging to stdout...\n")
        @fd = @orig_stdout
      when 'stderr'
        #$stderr.write("logging to stderr...\n")
        @fd = @orig_stderr
      else
        begin
          @fd = File.open(logfile, "w")
          #$stderr.write("logging to file #{logfile}...\n")
        rescue Errno::ENOENT => ex
          @orig_stderr.write("Error opening #{logfile}: #{ex}\n")
          @fd = @orig_stderr
        rescue Exception
        end
      end
      rebind()
    end

    def rebind
      #@logger = Logger.new(@orig_stderr)
      #@logger.level= Logger::DEBUG
      #return
      @logger = Logger.new(@fd)
      logLevel = [Logger::FATAL, Logger::ERROR, Logger::WARN,
        Logger::INFO, Logger::DEBUG].fetch(@verboseLevel, Logger::FATAL)
      @logger.level= logLevel
    end

    def method_missing(id, *args)
      begin
        @logger.send(id, *args)
      rescue IOError
      end
    end
  end
  
  class << self

    # Things taken from the old ruby-debug.rb
    
    # Based on start_client
    include Helpers
    
    def start_dbpg_client(options)
      host = options['host']
      port = options['port']
      is_interactive_shell = options['interactive']
      verbose = options['verbose']
      logfile = process_logfile_name(options['logfile'])
      #$stderr.write("About to write to logfile: #{logfile || "<none>"}\n")
      @logger = LoggerWrapper.new(logfile || 'stderr', verbose)
      @processor = DBGP_CommandProcessor.new(host, port, is_interactive_shell, @logger, options['localdebugger'])
      Debugger.handler = @processor
      
      # Start up the debugger and get out of the way.
      #$stderr.write("About to start the debugger...\n")
      #$stderr.flush
      Debugger.start()
      #$stderr.write("Started\n")
      #$stderr.flush
      #Debugger.catchpoint="Exception"
    end

    def wrap_up(last_ex)
      begin
        @processor.wrap_up(last_ex)
      end
    end

    private
    def process_logfile_name(logfile)
      # Check to see if the filename is urlencoded
      case logfile
      when 'stdout', 'stderr'
        return logfile
      end
      if (logfile =~ /\%u?[a-fA-F0-9]{2}/ &&
            !FileTest.directory?(logfile) &&
            !FileTest.directory?(File.dirname(logfile)))
        require 'cgi'
        logfile = CGI.unescape(logfile);
      end
      if FileTest.directory?(logfile)
        logfile = logfile.gsub('\\', '/').sub(%r(/$), '') + "/ruby_dbgp.log"
      end
      logfile
    end
  end
end

END {
  Debugger.skip {
    Debugger.wrap_up($!)
  }
  if Debugger.started?
    Debugger.stop()
  end
}
