#
# rdbgp.rb -- top-level library for doing debugging

# Copyright (C) 2007 ActiveState Software Inc.
# All Rights Reserved

# Command-line to run this:
# export RUBYDB_OPTS=<option string>
# export RUBYDB_LIB=<dir containing this file>
# ruby -IRUBYDB_LIB -r $RUBYDB_LIB/rdbgp.rb <ruby options> <file> <file options>

# Gets options from RUBYDB_OPTS, and invokes the 
# Komodo DBGP Ruby debugger (v. 2)

# Syntax for the options:
# RUBYDB_OPTS=(<opt>(\s+<opt>)*)?
# Options (default values in parens:
# HOST=<[\S;:]+> (localhost)
# PORT=\d+ (9000)
# INTERACTIVE=0|1 (0)
# VERBOSE=\d+ (0)
# logfile=stdout|stderr|fname (nil)

# backward compatibility:
# remoteport=<host>:<port>

module Debugger
  class << self
    def parse_options(opts)
      options = {
        'host' => 'localhost',
        'port' => 9000,
        'interactive' => false,
        'verbose'  => 0,
        'logfile'  => nil,
        'localdebugger' => false,
      }
      while opts.length > 0
        if opts =~ /^\s+(.*)$/
          opts = $1
        elsif opts =~ /^(\w+)=(.*)/
          name, rest = $1, $2
          if rest =~ /^([\"\'])(.*?)\1(.*)$/
            val, opts = $2, $3
          elsif rest =~ /^(.*?)\s+(.*)$/
            val, opts = $1, $2
          else
            val = rest
            opts = ""
          end
          named = name.downcase
          if named == "remoteport" && val =~ /^(.*):(\d+)$/
            host, port = $1, $2
            options['host'] = host
            options['port'] = port
          else
            options[named] = val
          end
        else
          break
        end
      end  # end while
      if options['logfile']
        if !options['verbose']
          options['verbose'] = 1
        end
      else
        options['logfile'] = 'stderr'
        options['verbose'] = 0 unless options['verbose']
      end
      %w/interactive localdebugger/.each do |opt|
        if options[opt]
          options[opt] = options[opt] == '0' ? false : true
        end
      end
      return options
    end

    def get_going()
      $stdout.sync = true
      $stderr.sync = true #redundant?
      parts = RUBY_VERSION.split(/\./).map{|a|a.to_i}
      msgs = []
      if (parts <=> [1, 8, 4]) == -1
        msgs << "The Komodo Ruby debugger requires at least version 1.8.4 of Ruby"
        msgs << "The current version is #{RUBY_VERSION}"
        msgs << "Please select a newer interpreter in the preferences section,"
        msgs << "or download a newer version from http://www.ruby-lang.org/"
      elsif parts == [1, 9, 0]
        msgs << "Debugging of Ruby 1.9.0 is not supported. ActiveState "
        msgs << "recommends upgrading with a newer version from http://www.ruby-lang.org/"
      end
      if msgs.size > 0
        msgs << ""
        $stderr.print(msgs.join("\n"))
        exit
      end

      require 'rdbgp/loader'
      
      options = Debugger.parse_options(ENV['RUBYDB_OPTS'])
      begin
        Debugger.start_dbpg_client(options)
        Debugger.current_context.stop_next = 1
      rescue Errno::EBADF
        $stderr.puts "Can't connect to #{options.host}:#{options.port}: #{$!}"
      end
      
    end
  end
end

Debugger.get_going()
