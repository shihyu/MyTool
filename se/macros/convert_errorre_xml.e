/* 
CONVERT FROM: 
<ErrorExpressions
	xmlns="http://www.slickedit.com/schema/11.0/ErrorRE.xsd">
	<Tool
		Name="default"
		Priority="0"
		Enabled="1">
		<Expression
			Name="def1"
			OldName="def_error_re"
			Priority="0"
			Enabled="1">
			<RE>
				<![CDATA[^\*@(cfe\: (Error|Warning)\:|error(~:f|[*:])|warning(~:f|[:*])|\(|<|)\*@ *{:q|(.\\|):p}( +| *\(|\:|, line ){:d#}(,|\:|)( *{:d#}|> :i|)(\)|) @(error|){(\:|Error[~s]|Fatal|Warning)?*$}]]>
			</RE>
		</Expression>
		<Expression
			Name="def2"
			OldName="def_error_re2"
			Priority="1"
			Enabled="1">
			<RE>
				<![CDATA[^link *\:?*\:{}{}{}{?*}$]]>
			</RE>
			<Matches>
				<![CDATA["Frame1.java": Error #: 202 : 'class' or 'interface' expected at line 8, column 1]]>
			</Matches>
      </Expression>
 
TO:
 
  <p n="category">
      <attrs position="1" enabled="1">
  </p>
  <p n="category,def1">
      <attrs position="1" enabled="1">
      <re>
          <![CDATA[^  File \"{#0[^"]+}\", line {#1:i}?*(\n|\r\n|\r)?*(\n|\r\n|\r)( *?\^(\n|\r\n|\r)|){#3[^ ]+\: ?*}$]]>
      </re>
      <test_case>
      </test_case>
  </p>
 
*/
#pragma option(pedantic,on)
#include "slick.sh"
#include "errorre.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"
#import "xmldoc.e"
#import "error.e"
static void fetch_old_error_info_for_tool(int handle, int tool_node,ERRORRE_INFO (&errorre_list)[]) {
   largest:=0;
   typeless array[];
   _xmlcfg_find_simple_array(handle,"Expression",array,tool_node);
   for (i:=0;i<array._length();++i) {
      int node=array[i];
      ERRORRE_INFO info;
      info.m_name=_xmlcfg_get_attribute(handle,node,"Name");
      info.m_enabled=_xmlcfg_get_attribute(handle,node,"Enabled")?true:false;
      info.m_macro=_xmlcfg_get_attribute(handle,node,"Macro");
      int re_node=_xmlcfg_find_child_with_name(handle,node,"RE");
      if (re_node>=0) {
         info.m_re=_xmlcfg_get_text(handle,re_node);
      } else {
         info.m_re='';
      }
      int test_case_node=_xmlcfg_find_child_with_name(handle,node,"Matches");
      if (test_case_node>=0) {
         info.m_test_case=_xmlcfg_get_text(handle,test_case_node);
      } else {
         info.m_test_case='';
      }
      info.m_enabled=_xmlcfg_get_attribute(handle,node,"Enabled")?true:false;
      
      
      // langid;pattern
      index:=_xmlcfg_get_attribute(handle,node,"Priority");
      errorre_list[errorre_list._length()]=info;
   }
}
static int convert_error_xml_to_profile(_str error_xml_filename) {
   
   handle:=_xmlcfg_open(error_xml_filename,auto status);
   if (handle<0) {
      return handle;
   }
   expressions_node:=_xmlcfg_set_path(handle,"/ErrorExpressions");
   _xmlcfg_sort_on_attribute(handle,expressions_node,'Priority','n');
   ERRORRE_FOLDER_INFO folder_array[];
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/ErrorExpressions/Tool",array);
   for (k:=0;k<array._length();++k) {
      int tool_node=array[k];
      ERRORRE_FOLDER_INFO info;
      info.m_name=_xmlcfg_get_attribute(handle,tool_node,"Name");
      info.m_enabled=_xmlcfg_get_attribute(handle,tool_node,"Enabled")?true:false;
      info.m_errorre_array._makeempty();
      
      index:=_xmlcfg_get_attribute(handle,tool_node,"Priority");

      _xmlcfg_sort_on_attribute(handle,tool_node,'Priority','n');
      fetch_old_error_info_for_tool(handle,tool_node, info.m_errorre_array);
      folder_array[folder_array._length()]=info;
   }
   _xmlcfg_close(handle);
   _errorre_save_error_parsing_table(folder_array);
   return 0;
}
defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   convert_error_xml_to_profile(filename);
}
