#!/usr/bin/ruby
# Copyright (c) 2005-2006 ActiveState Software Inc.
#
# See the LICENSE file for full details on this software's license.
#
# Authors:
#    Eric Promislow <EricP@ActiveState.com>

require 'rdbgp/helper.rb'

module Debugger
module DBGP
class Properties

  include Helpers

  attr_reader :contextProperties, :contextPropertyNames, :punctuationVariables
  attr_writer :default_encoding
  
  def initialize    
    @contextProperties = {"Globals" => GlobalVars,
      "Locals" => LocalVars,
      "Special" => PunctuationVariables,
      "Self" => InstanceVars,
      "Builtins" => BuiltinGlobals,
    }
    # Impose our own order so they show up in the IDE in the same order
    @contextPropertyNames = %w/Locals Self Globals Builtins Special/
    @punctuationVariables = ['$_', '$?', '$@', '$.', '@+', '@-', '$+', '$&', '$!', '$\'', '$`', '$$', '$0']

    @class_to_ktype = {
      "NilClass" => 'null',
      "Array" => 'array',
      "Hash" => 'hash',
      "Bignum" => 'int',
      "Fixnum" => 'int',
      "Integer" => 'int',
      "Numeric" => 'int',
      "Float" => 'float',
      "TrueClass" => 'bool',
      "FalseClass" => 'bool',
      "String" => 'string',
      "Symbol" => 'symbol',
      "Binding" => 'resource',
      "Class" =>  'resource',
      "Continuation" =>  'resource',
      "Exception" => 'resource',
      "Method" => 'resource',
      "Module" => 'resource',
      "Proc" => 'resource',
      "Thread" => 'resource',
    }
    @default_encoding = 'base64'
  end

  # Return an XML-encoded list of sub-properties
  def emitContextProperties(namesAndValues, max_data_size)
    res = []
    namesAndValues.each {|rawname, val|
      res << _get_fold_property_parts(rawname, rawname, val, max_data_size)
    }
    return res.join("\n")
  end

  def emitProperty(name, val, page_index,
                   page_size, max_data_size, ignore_at_signs=true)
    start_tag, body, end_tag = _get_property_parts(name, name, val, max_data_size, page_index, page_size)
    res = [start_tag, body, "\n",
      _get_children_properties(name, val, page_index,
                               page_size, max_data_size, ignore_at_signs),
      end_tag]
    return res.join("")
  end

  def trim_data(s, max_data_size)
    if s.length > max_data_size
      return s[0 .. max_data_size - 4] + "..."
    end
    return s
  end

  def emitPropertyValue(context_id, name, val)
    data_str = removeObjectID(val.inspect)
    attrs = { :size => data_str.length,
      :encoding => @default_encoding}
    inner_XML_EncodedText = ("<![CDATA[" +
                             encodeData(data_str, @default_encoding) +
                             "]]>")
    return [attrs, inner_XML_EncodedText]
  end

  # Public helper function
  
  def get_sorted_object_varnames(ivars, cvars, ignore_at_signs=true)
    if ignore_at_signs
      all_vars = (ivars.collect {|iv| [iv[1 .. -1].downcase, iv, true] } +
                    cvars.collect {|cv| [cv[2 .. -1].downcase, cv, false] })
    else
      all_vars = (ivars.collect {|iv| [iv.downcase, iv, true] } +
                    cvars.collect {|cv| [cv.downcase, cv, false] })
    end
    return all_vars.sort.collect{|a,b,c| [b, c]}
  end

  # Helper functions
  private

  def _get_fold_property_parts(name, key_name, val, max_data_size, page_index=0, page_size=0, address=nil)
    start_tag, body, end_tag = _get_property_parts(name, key_name, val, max_data_size, page_index, page_size, address)
    res = start_tag + body + end_tag
    return res
  end

  def _get_index_bounds(page_index, page_size, num_children)
    first_index = page_index * page_size
    last_index = first_index + page_size - 1
    last_index = num_children - 1 if last_index >= num_children
    return first_index, last_index
  end

  def _get_children_properties(name, val, page_index,
                               page_size, max_data_size, ignore_at_signs)
    begin
      ltype = _get_dbgp_typename(val, name)
      res = ""
      case ltype
      when 'array'
        first_index, last_index = _get_index_bounds(page_index, page_size, val.length)
        idx = first_index
        val[first_index .. last_index].each {|child_val|
          key_name = "[#{idx}]"
          res += _get_fold_property_parts("#{name}#{key_name}", key_name, child_val, max_data_size, page_index, page_size)
          idx += 1
        }
      when 'hash'
        val_keys = val.keys.sort { |a, b|
          # Impose a total order over all possible Ruby values
          ra = a.respond_to?(:<=>)
          rb = b.respond_to?(:<=>)
          if ra == rb
            (ra && a.class == b.class) ? a <=> b : a.to_s <=> b.to_s
          else
            # Put non-sortable values before sortable ones.
            ra ? 1 : -1
          end
        }
        first_index, last_index = _get_index_bounds(page_index, page_size, val_keys.length)
        val_keys[first_index .. last_index].each {|child_key|
          key_name = child_key.inspect
          res += _get_fold_property_parts("#{name}[#{key_name}]", key_name, val[child_key], max_data_size, page_index, page_size, child_key.object_id)
        }
      when 'object'
        # Don't use accessors to evaluate the locals.
        ivars = _get_object_vars(val, ignore_at_signs)
        first_index, last_index = _get_index_bounds(page_index, page_size, ivars.length)
        idx = first_index
        val_class = val.class
        ivars[first_index .. last_index].each {|var_name, is_instance_var|
          begin
            key_name = "." + var_name
            new_val = is_instance_var ? val.instance_variable_get(var_name) : val_class.class_eval(var_name)
            res += _get_fold_property_parts("#{name}#{key_name}", key_name, new_val, max_data_size, page_index, page_size)
          end
        }
      end
    end
    return res
  end

  def removeObjectID(inspectString)
    if inspectString =~ /^(#<.*?):0x[0-9a-fA-F]+(.*>)$/
      return $1 + $2
    else
      return inspectString
    end
  end

  def _get_property_parts(rawname, key_name, val, max_data_size, this_page, page_size, address=nil)
    lvs = {}
    lvs['fullname'] = xmlAttrEncode(rawname)
    lvs['name'] = xmlAttrEncode(key_name)
    lvs['classname'] = xmlAttrEncode(val.class.to_s)
    lvs['type'] = _get_dbgp_typename(val, rawname)
    lvs['encoding'] = xmlAttrEncode(@default_encoding)
    if page_size != 0
      lvs['page'] = this_page
      lvs['pagesize'] = page_size
    end
    lvs['address'] = address
    case lvs['type']
    when "null"
      xval = nil
      numchildren = 0
    when "resource"
      xval = removeObjectID(val.inspect)
      numchildren = 0
    when "bool"
      xval = (val ? "1" : "0")
      numchildren = 0
    when "int"
      xval = val.to_s
      numchildren = 0
    when "float"
      xval = val.to_s
      numchildren = 0
    when "string"
      xval = val
      numchildren = 0
    when "symbol"
      xval = val.to_s
      numchildren = 0
    when "object"
      numchildren = get_num_object_vars(val)
      xval = cdataEncode(removeObjectID(val.inspect))
    else
      numchildren = val.length
      xval = cdataEncode(removeObjectID(val.inspect))
    end
    if !xval.nil? && (lvs['size'] = xval.length) > max_data_size
      if max_data_size <= 3
        #Unlikely boundary condition
        xval = xval[0 .. max_data_size - 1]
      else
        # Add ellipse to show we truncated
        xval = xval[0 .. max_data_size - 4] + "..."
      end
      lvs['size'] = max_data_size
    end
    if numchildren > 0
      lvs['children'] = "1"
      lvs['numchildren'] = numchildren
    else
      lvs['children'] = "0"
      lvs['numchildren'] = nil
    end
    
    start_tag = '<property '
    lvs.each {|attr_name, attr_val|
      next if attr_val.nil?
      start_tag += %Q( #{attr_name}="#{attr_val.to_s}")
    }
    start_tag += ">"
    if xval
      xval = trim_data(xval, max_data_size)
      body = ("<![CDATA[" + encodeData(xval, @default_encoding) + "]]>")
    else
      body = ""
    end
    end_tag = "</property>"
    return start_tag, body, end_tag
  end

  def _get_dbgp_typename(val, rawname)
    ### $stderr.printf("_get_dbgp_typename(%s), val(%s), class(%s)\n", rawname, val, val.class)

    if @class_to_ktype.has_key?(val.class.to_s)
      return @class_to_ktype[val.class.to_s]
    else
      return "object"
    end
  end

  def _get_ivs(val)
    begin
      ivs = val.instance_variables
    rescue => ex
      ivs = []
    end
    return ivs
  end

  def _get_cvs(val)
    begin
      cvs = val.class.class_variables
    rescue => ex
      cvs = []
    end
    return cvs
  end

  def _get_object_vars(val, ignore_at_signs)
    get_sorted_object_varnames(_get_ivs(val), _get_cvs(val), ignore_at_signs)
  end
  
  def get_num_object_vars(val)
    return _get_ivs(val).size + _get_cvs(val).size
  end

end #class

end #module DBGP
end #module Debugger
