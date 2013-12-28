
require 'rdbgp/helper.rb'
require 'rdbgp/DB/constants.rb'

module Debugger
  class DBGP_Source < Command # :nodoc:
    self.cmd_name = :source
     include Helpers
     include DBGP::Constants

    def execute(processor, cmdArgs)
      beginLine, endLine, fileURI = cmdArgs.pickArgs('b+:e+:f:')
      raise DBGP_Exception.new(DBP_E_InvalidOption, "No file URI specified.") unless fileURI
      fileName = uriToFile(fileURI)
      source = Debugger.source_for(fileName)
      raise DBGP_Exception.new(DBP_E_CantOpenSource, "No source available for URI #{fileURI} (file #{fileName}).") unless source
      numLines = source.size
      processor.logger.debug("source(#{fileURI}) => #{numLines} lines")
      actualBeginLine = beginLine <= 0 ? 0 : beginLine - 1
      # Sanity-check the end-line
      if endLine == 0
        actualEndLine = numLines - 1
      elsif endLine >= numLines
        actualEndLine = numLines - 1
      elsif endLine < beginLine
        actualEndLine = beginLine
      else
        actualEndLine = endLine
      end
      a1 = source[actualBeginLine .. actualEndLine]
      s2 = a1.join("")
      s2 = "" if s2.nil?
      encoding = processor.settings['data_encoding'][0]
      inner_XML_EncodedText = cdata(encodeData(cdataEncode(s2), encoding))
      attrs = {
        :success => 1,
        :encoding => encoding
      }
      processor.complete_response_print(attrs, inner_XML_EncodedText)
    end
  end
end
