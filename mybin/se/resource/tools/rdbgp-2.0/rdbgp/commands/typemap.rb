
require 'rdbgp/helper.rb'

module Debugger
  class DBGP_Typemap < Command # :nodoc:
    self.cmd_name = :typemap_get
    include Helpers

    def execute(processor, cmdArgs)
      # Schema, CommonTypeName (type attr) LanguageTypeName (name attr)
      names =  [[:boolean, :bool],
        [:float],
        [:integer, :int],
        [:string]]
      data = names.map {|e|
        xsdName = e[0];
        commonTypeName = e[1] || xsdName;
        languageTypeName = e[2] || commonTypeName;
        {:type => commonTypeName, :name => languageTypeName, "xsi:type" => "xsd:#{xsdName}"}
      }
      innerText = data.map{|h|
        "<map " + h.to_a.map{|key,val| "#{key}=\"#{xmlAttrEncode(val.to_s)}\""}.join(" ") + " />"
      }.join("\n")
      
      attrs = {"xmlns:xsd" => "http://www.w3.org/2001/XMLSchema",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      }
      processor.complete_response_print(attrs, innerText)
    end
  end
end
