/* 
CONVERT FROM: 
<Searches>
	<State
		Name="git"
		Search="git"
		Flags="32"
		Colors="CS,,">
		<Files
			Types="*.e;*.sh"
			Excludes=".git/"></Files>
	</State>
	<State
		Name="Git"
		Search="Git"
		Flags="33"
		Colors="CS,,"></State>
</Searches>
 
TO:
<profile n="misc.searches"> 
	<p
		n="git"
		Search="git"
		Flags="32"
		Colors="CS,,">
		<Files
			Types="*.e;*.sh"
         Excludes=".git/"></Files>
	</p>
	<p
		Name="Git"
		Search="Git"
		Flags="33"
      Colors="CS,,">
   </p>
</profile>
 
*/
#pragma option(pedantic,on)
#include "slick.sh"
#include "errorre.sh"
#import "cfg.e"
#import "beautifier.e"
#import "stdprocs.e"
#import "xmldoc.e"
#import "error.e"
static int convert_searches_xml_to_profile(_str xml_filename) {
   handle:=_xmlcfg_open(xml_filename,auto status);
   if (handle<0) {
      return handle;
   }
   int profile_node=_xmlcfg_get_document_element(handle);
   _xmlcfg_set_name(handle,profile_node,VSXMLCFG_PROFILE);
   _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_NAME,_plugin_append_profile_name(VSCFGPACKAGE_MISC,VSCFGPROFILE_SEARCHES));
   _xmlcfg_set_attribute(handle,profile_node,VSXMLCFG_PROFILE_VERSION,VSCFGPROFILE_SEARCHES_VERSION);

   ERRORRE_FOLDER_INFO folder_array[];
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/profile/State",array);
   for (k:=0;k<array._length();++k) {
      int node=array[k];
      _xmlcfg_set_name(handle,node,VSXMLCFG_PROPERTY);
      n:=_xmlcfg_get_attribute(handle,node,'Name');
      _xmlcfg_delete_attribute(handle,node,'Name');
      _xmlcfg_set_attribute(handle,node,VSXMLCFG_PROPERTY_NAME,n,VSXMLCFG_ADD_ATTR_AT_BEGINNING);
   }
   _plugin_set_profile(handle);
   _xmlcfg_close(handle);
   return 0;
}
defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   convert_searches_xml_to_profile(filename);
}
