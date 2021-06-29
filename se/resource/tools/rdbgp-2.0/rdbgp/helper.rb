# Helpers for dbgp-based debugging

module Debugger
  module Helpers

    class DBGP_Exception < Exception
      attr_accessor :ecode
      def initialize(ecode, message)
        if message.is_a?(Exception)
          super(message.message)
          self.set_backtrace(message.backtrace)
        else
          super(message)
        end
        @ecode = ecode
      end
    end

    require 'cgi'
    require 'uri'

    @_common_types = {
      "NilClass" => 'null',
      "FixNum" => 'int',
      "Integer" => 'int',
      "Float" => 'float',
      "Bignum" => 'float',
      "String" => 'string',
    }
    
    def test_helper(s)
      puts "Hit test_helper: #{s}"
      exit!
    end
    
    def cdata(str)
      "<![CDATA[" + str + "]]>"
    end
  
    def cdataEncode(str)
      # No need to escape quotes.
      return str.gsub(/\]\]>/, "]]&gt;")
    end
  
    def decodeData(str, currDataEncoding)
      case currDataEncoding
      when 'none', 'binary'
        finalStr = str
      when 'urlescape'
        require 'cgi'
        finalStr = CGI.unescape(outLogName);
      when 'base64'
        finalStr = str.unpack("m")[0]
      else
        dblog("Converting #{str} with unknown encoding of #{currDataEncoding}\n")
        finalStr = str;
      end
      return finalStr
    end
  
    def encodeData(str, currDataEncoding)
      begin
        case currDataEncoding
        when 'none', 'binary'
          finalStr = str
        when 'urlescape'
          require 'cgi'
          finalStr = CGI.escape(outLogName);
        when 'base64'
          finalStr = [str].pack("m")
        else
          dblog("Converting #{str} with unknown encoding of #{currDataEncoding}\n")
          finalStr = str;
        end
      end
    end
  
    def endPropertyTag(encVal, encoding)
      return ((!encVal.nil? && encVal.length > 0) ?
              "><![CDATA[#{encVal}]]></property>\n" :
                "/>\n")
    end
    
    def fileToURI(filename)
      abspath1 = File.expand_path(filename, @initial_dir)
      abspath2 = encode_win_file_parts(abspath1)
      slNum = ?/ #/
      # bug 80991 - handle unc paths
      leadingSlashes = (['//', '\\\\'].index(filename[0 .. 1]) ?
                        '/' : (abspath2[0] == slNum ? "//" : "///"))
      final = "file:#{leadingSlashes}#{abspath2}"
      @logger.debug(sprintf("fileToURI(%s) => %s", filename, final))
      return final
    end

    def running_on_windows
      # return @windows_platform_names.has_key?(RUBY_PLATFORM)
      return {"i386-cygwin" => nil, "i386-mswin32" => nil}.has_key?(RUBY_PLATFORM)
    end

    def uriToFile(uri)
      # Workaround bug 70770 where Komodo sometimes doesn't escape spaces in URIs
      fpath1 = URI.parse(uri.gsub(" ", "%20")).path
      # Bug fix in URI version 1.8.2.2 (at least)
      if running_on_windows()
        if fpath1.match(/^\/\w:/)
          fpath1 = fpath1[1 .. -1]
        end
      end
      return fpath1
    end
    
    def getCommonType(val)
      if @_common_types.has_key?(val)
        return @_common_types[val]
      else
        return 'object'
      end
    end

    # One day sort these names so we can do string-based testing
    def hashToAttrValues(attrs)
      str = attrs ? attrs.map{|key,val| "#{key}=\"#{xmlAttrEncode(val.to_s)}\""}.join(" ") : ""
      return str

      #return (attrs.to_a{|key,val| "#{key}=\"#{xmlAttrEncode(val.to_s)}\""}.join(" "))# rescue ""
      # (attrs.sort{|key,val| "#{key}=\"#{xmlAttrEncode(val.to_s)}\""}.join(" "))
    end
  
    def isWin32()
      RUBY_PLATFORM =~ /mswin32/ || RUBY_PLATFORM =~ /cygwin/
    end
  
    def makeErrorResponse(cmd, transactionID, code, error)
      printWithLength(sprintf(%Q(%s\n<response %s command="%s" 
                          transaction_id="%s" ><error code="%d" apperr="4">
                          <message>%s</message>
                          </error></response>),
                              xmlHeader(),
                              namespaceAttr(),
                              cmd,
                              transactionID,
                              code,
                              xmlEncode(error)));
    end
    
    def namespaceAttr()
      return 'xmlns="urn:debugger_protocol_v1"'
    end
  
    def printWithLength_helper(interface, str)
      argLen = str.length
      finalStr = sprintf("%d\0%s\0", argLen, str);
      # Ruby doesn't do null-byte truncation
      # even though the method takes only a string arg
  
      # We can use @socket as this module gets included into the debugger class
      begin
        interface.syswrite(finalStr)
      rescue SystemCallError
        @logger.error("socket.syswrite: SystemCallError")
      rescue IOError
        @logger.error("socket.syswrite: IOError") unless interface.closed?
      end
      #@logger.debug(zescape(finalStr))
    end
    
    def zescape(str)
      str.gsub(/[\x00-\x08\x0b\x0c\x0e-\x1f]/){|ch| sprintf('\\x%02x', ch[0])}
    end
   
    def safe_dump(str)
      str.gsub(%r{([^\x09\x0a\0x0d\x20-\x7f])}){sprintf('\\x%02x', $1[0])}
    end
    
    def trimExceptionInfo(msg="")
      msg.to_s.sub(/ for \#<<DEBUGGER__::Context:0x\d+>\s*$/, '')
    end
  
    def xmlAttrEncode(str)
      return xmlEncode(str).gsub(/([\'\"])/) { '&#' + $1[0].to_s + ';' }
    end    
      
    def xmlEncode(str)
      # No need to escape quotes.
      return str.
        gsub('&', '&amp;').
        gsub('<', '&lt;').
        gsub('>', '&gt;').
        gsub(/([\x00-\x08\x0b\x0c\x0e-\x1f])/){"&#" + $1[0].to_s + ";"}
    end
  
    def xmlHeader(encoding='utf-8')
      %Q(<?xml version="1.0" encoding="#{encoding}" ?>);
    end
  
    def xsdNamespace
      return %q(xmlns:xsd="http://www.w3.org/2001/XMLSchema")
    end
    
    def xsiNamespace
      return %q(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance")
    end

    #############################################################
    # Helper functions for property methods

    def debug_log_eval(str, binding)
      if str =~ /^\!backdoor\b(.*)$/
        # backdoor in this context..., must return something
        #
        # samples
        #
        # !backdoor @debugger__.instance_eval('@logger.level = Logger::DEBUG')
        # !backdoor $ldebug=true
        #
        # Sort ignoring @
        # !backdoor @settings['sort_ignore_at_signs'][0] = 0
        #
        # This is all it is: use the binding of the current state
        #
        return @state.eval($1) || ""
      end

      begin
        # Replace instance and class variables in expressions
        # with calls to reflection API
        # Do not use getters -- this can cause unwanted side-effects
        # for complex getters.
        #
        #XXX - don't translate instances of /\.@\w/ inside keys.
        #
        # Also, note that dbgp doesn't allow for non-string keys.
        
        str2 = reflect_expression(str)
        return eval(str2, binding)
      rescue StandardError, ScriptError => e
        @logger.debug("trying to eval[#{str} => #{e}")
      end
      return nil
    end

    def debug_log_eval_check_address(str, binding, key_address)
      if key_address.to_s.length > 0 && str =~ /^(.*)\[([^\[\]]*)\]$/
        first_part = $1
        # Ignore the key, as we're using key_address
        str2 = reflect_expression(first_part) + "[ObjectSpace._id2ref(#{key_address.to_i})]";
        begin
          # @logger.debug("About to eval {#{str2}}...")
          res = eval(str2, binding)
          return res
        rescue StandardError, ScriptError => e
          @logger.debug("trying to eval[#{str} => #{e}")
        end
      end
      return debug_log_eval(str, binding)
    end

    def debug_log_hashval_set(lhs, new_val2, binding, key_address)
      if lhs =~ /^(.*)\[([^\[\]]*)\]$/
        first_part = $1
        # Ignore the key, as we're using key_address
        str2 = reflect_expression(first_part) + "[ObjectSpace._id2ref(#{key_address})] = " + new_val2;
        begin
          # @logger.debug("About to eval {#{str2}}...")
          res = eval(str2, binding)
          return true
        rescue StandardError, NameError, ScriptError => e
          @logger.debug("Trying to eval (%s), got error %s", str2, msg)
          @logger.debug("do_property_set:%s:%d", __FILE__, __LINE__)
        rescue => msg
          @logger.debug("Trying to eval (%s), got error %s", str2, msg)
          @logger.debug("do_property_set:%s:%d", __FILE__, __LINE__)
        end
      end
    end

    def debug_log_set(lhs, new_val, binding, key_address=nil)
      new_val2 = new_val.to_s
      if ! key_address.nil?
        res = debug_log_hashval_set(lhs, new_val2, binding, key_address.to_i)
        return if res
      end
      if lhs =~ /^(.*)\.(@@\w+)$/
        first_part, accessor = $1, $2
        # For some reason this one needs the string-eval form, not the block.
        str2 = reflect_expression(first_part) + ".class.class_eval(%Q(#{accessor} = #{new_val2}))"
      elsif lhs =~ /^(.*)\.(@\w+)$/
        first_part, accessor = $1, $2
        str2 = reflect_expression(first_part) + ".instance_eval{" + accessor + " = " + new_val2 + "}"
      else
        str2 = reflect_expression(lhs) + " = " + new_val2
      end
      begin
        # @logger.debug("debug_log_set: About to eval {#{str2}}...")
        res = eval(str2, binding)
        return
      rescue StandardError, NameError, ScriptError => e
        @logger.debug("trying to eval[#{str2} => #{e}")
      rescue => msg
        @logger.debug("Trying to eval (%s), got error %s", str2, msg)
      end
    end
    
    def reflect_expression(str)
      return str.gsub(/.(@@\w+)/, %Q(.class.class_eval("\\1"))).gsub(/\.(\@\w+)/, %Q(.instance_eval("\\1")))
    end
    
    #############################################################
    # Error Message helpers

    def get_exception_msg(ex)
      if ex.is_a?(Exception)
        msg = ex.message
        bt = ("\n" + ex.backtrace.map{|l| "\t#{l}"}.join("\n")) rescue ""
        msgFinal = msg + bt
      else
        msgFinal = ex.to_s
      end
      if ! msgFinal.match(/[\r\n]$/)
        msgFinal += "\n"
      end
    end

    #############################################################

    private
    def fmt_time
      return Time.new.localtime().to_s.sub(%r{(\w+) (Standard|Daylight) Time}) {
        $1[0,1] + $2[0,1] + "T"
      }
    end
  
    #XXX Stuff to move back to filetable.rb
    #Precondition: backslashes have been flipped
    def encode_win_file_parts(full_win_name)
      if full_win_name =~ %r(^\w:#{File::SEPARATOR})
        volume, path = full_win_name.split(File::SEPARATOR, 2)
      else
        path = full_win_name
      end
      dir_parts = path.split(File::SEPARATOR).collect {|x| uri_encode(x) }
      new_name = File.join(dir_parts)
      new_name = "#{volume}#{File::SEPARATOR}#{new_name}" if !volume.nil? 
      return new_name
    end
    private :encode_win_file_parts
  
    def uri_decode(todecode)
      CGI.unescape(todecode)
    end
    private :uri_decode
  
    def uri_encode(toencode)
      CGI.escape(toencode).gsub(/\+/, '%20')
      # Note on '/\+/' -- used to be '+', but versions < 1.8.2
      # have trouble with regexp metacharacters in strings.
    end
    private :uri_encode

  end
end
