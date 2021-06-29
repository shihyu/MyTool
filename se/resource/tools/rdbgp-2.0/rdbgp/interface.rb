#!/usr/bin/ruby
# Copyright (c) 2005-2007 ActiveState Software Inc.
#
# See the LICENSE file for full details on this software's license.
#
# Authors:
#    Eric Promislow <EricP@ActiveState.com>

# Class for encapsulating reading commands from the debugger client

require 'thread'    # for the queue
require 'monitor'   # for the condition variable

#
# ruby debugger II

require 'rdbgp/helper.rb'

module Debugger  
  class Dbgr_Session
    
    def initialize(sock_, context, logger=nil)
      # @sock = sock_
      @queue = Queue.new
      @context = context
      @logger = logger

      # Making these instances of Debugger::DebugThread stops the
      # debugger from stopping in this code.  That's all they do.

      @producer = DebugThread.new(sock_, context, logger) do |sock, context, logger|
        #Thread.stop
        # Sometimes we read more than one cmd at a time
        # We always append to the last string in @pending, and always put
        # a possibly null string at the end to avoid the boundary condition
        # of finding one complete command
        
        amtToRead = 2048
        finalBuffer = ""
        while true
          begin
            logger.debug("About to read from socket #{sock}")
            thisBuffer = sock.sysread(amtToRead)
          rescue EOFError
            thisBuffer = ""
            break
          rescue Errno::ECONNRESET
            thisBuffer = ""
            break
          end
          leave = thisBuffer.length == 0
          finalBuffer += thisBuffer.delete("\r\n")
          parts = finalBuffer.split(0.chr, -1)
          finalBuffer = parts.pop  # Usually empty
          
          # Some things don't go on the queue,
          # so we'll look for them and do appropriate action
          
          new_parts = parts.delete_if { |p| p.index("STOP") == 0 }
          leave ||= (new_parts.size < parts.size)
          
          ib = new_parts.find { |p| p.index("break ") == 0 }
          if ib
            # Tell whichever context we're associated with that
            # it's time to stop.
            context.stop_next = 1
          end
          
          leave ||= new_parts.find { |p| p.index("stop ") == 0 }
          new_parts.each { |p| @queue.enq(p) }
          if leave
            # This doesn't seem to be needed
            sock.close_read()
            break
          end
        end
      end # end thread
      #@producer.run
      logger.debug("Thread @producer = #{@producer}\n")
    end
    
    def get_command(mutex)
      begin
        #@logger.debug("%%%% unlocking to get a command, thread #{Thread.current}")
        mutex.unlock
        Debugger.resume
        input = @queue.deq
      ensure
        mutex.lock
        #@logger.debug("%%%% locking, got command #{input}, thread #{Thread.current}")
      end
      return input
    end
    
    def end_session
      thr = @producer.join(0.01)
      if !thr
        @producer.exit()
      end
    end
  end

  # See Debugger::RemoteInterface in interface.rb
  class DBGP_Interface # :nodoc:
    
    include Helpers
    def initialize(host, port, context, logger)
      @logger = logger
      
      require "socket"
      @socket = TCPSocket.new(host, port)
      @logger.debug("Connected to #{host}:#{port}")      
      @logger.debug("Created socket #{@socket}")
      @session = Dbgr_Session.new(@socket, context, logger)
      @fatal_messages = ["An existing connection was forcibly closed by the remote host.",
        "An established connection was aborted by the software in your host machine.",]
    end
    
    def read_command(mutex)
      line = @session.get_command(mutex)
      @logger.debug("Read [#{zescape(line || "<empty>")}]")
      return line
    end
      
    def print(*args)
      @socket.printf(*args)
    end
    
    def close
      @socket.close_write
    rescue Exception => ex
      @logger.debug("dbgp_interface.close: Error #{ex}")
    end

    def closed?
      @socket.closed?
    end

    def syswrite(str)
      if !closed?
        begin
          @socket.syswrite(str)
          @socket.flush
        rescue Exception => ex
          if @fatal_messages.detect{|msg| msg[ex.message]}
            @logger.debug("About to shut everything down")
            self.shutdown
            Kernel.exit!
            return
          end
          @logger.debug(get_exception_msg(ex))
          begin
            close()
          rescue Exception => ex
            @logger.debug(get_exception_msg(ex))
          end
        end
      end
    end

    def shutdown
      @session.end_session
    end
    
    # Additional calls for DBGP
    
    private
    
    def send_command(msg)
      @socket.puts msg
    end
  end

end
