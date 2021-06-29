#
# Copyright (c) 2005-2006 ActiveState Software Inc.
#
# See the LICENSE file for full details on this software's license.
#
# Authors:
#    Eric Promislow <EricP@ActiveState.com>

# This class subclasses IO so we can set $defout and $deferr to it,
# but it follows a delegate pattern.

require 'rdbgp/helper.rb'

module Debugger
  module DBGP
  
    Redirect_Disable = 0;
    Redirect_Copy = 1;
    Redirect_Redirect = 2;

  
    class RedirectStdOutput < IO
      include Helpers
      attr_writer :default_encoding
      @default_encoding = nil
      
      def initialize(stdio_fd, komodo_sock, streamType, redirectState, processor)
        @stdio_fd = stdio_fd
        @komodo_sock = komodo_sock
        @redirectState = redirectState
        @streamType = streamType
        @processor = processor
      end
      
      def flush
        Debugger.skip {
          @komodo_sock.flush if @redirectState != Redirect_Disable
          @stdio_fd.flush if @redirectState == Redirect_Copy
        }
      end
      
      def close
        Debugger.skip {
          @komodo_sock.close if @redirectState != Redirect_Disable
          @stdio_fd.close if @redirectState == Redirect_Copy
        }
      end
      
      def print(*args)
        Debugger.skip {
          str = args.join($,)
          doOutput(str)
        }
      end
      
      def printf(*args)
        Debugger.skip {
          doOutput(sprintf(*args))
        }
      end
      
      def putc(obj)
        Debugger.skip {
          if obj.is_a?(Fixnum)
            doOutput([obj].pack("c"))
          else
            doOutput(obj.to_s[0, 1])
          end
        }
      end
      
      def puts(*args)
        Debugger.skip {
          str = args.collect{|x| x[-1] == ?\n ? x : x + "\n"}.join("")
          doOutput(str)
        }
      end
      
      def syswrite(str)
        Debugger.skip {
          doOutput(str)
        }
      end
      
      def write(str)
        Debugger.skip {
          doOutput(str)
        }
      end
      
      def doOutput(str)
        if (@redirectState != Redirect_Disable)
          # Coupling with caller here
          encval = encodeData(str, @default_encoding)
          attrs = {
            :type => @streamType,
            :encoding => @default_encoding
          }
          begin
            @processor.complete_stream_print(attrs, encval)
          rescue
          end
        end
        if (@redirectState != Redirect_Redirect)
          @stdio_fd.print(str)
        end
      end
  end # class
  
  end # DBGP
  end # Debugger
