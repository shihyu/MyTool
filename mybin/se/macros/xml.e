////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50558 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "tagsdb.sh"
#include "color.sh"
#include "xml.sh"
#include "diff.sh"
#include "eclipse.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "backtag.e"
#import "c.e"
#import "codehelp.e"
#import "context.e"
#import "csymbols.e"
#import "cutil.e"
#import "cjava.e"
#import "error.e"
#import "files.e"
#import "guicd.e"
#import "html.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "mfsearch.e"
#import "mprompt.e"
#import "optionsxml.e"
#import "picture.e"
#import "put.e"
#import "recmacro.e"
#import "seek.e"
#import "sellist.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "toolbar.e"
#import "treeview.e"
#import "url.e"
#import "xmlcfg.e"
#import "xmlwrap.e"
#import "toast.e"
#import "se/messages/Message.e"
#import "se/messages/MessageCollection.e"
#require "se/options/DialogExporter.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  \1id=../dtds/file1.dtd\1t=system\1lf=c:\dtds\file1.dtd\1cfg=file1\1lfdate=344455667\1

  "t" can be:
     system
     public
     inline  (lf= <nothing> )
  For each cfg name, there is:
     <cfg>.vtg
     <cfg>.tagdoc

*/

#define XMLNAMESPACE_TAGFILE_XHTML get_env('VSROOT'):+'XMLNamespaces':+FILESEP:+'www.w3.org':+FILESEP:+'1999':+FILESEP:+'xhtml':+FILESEP:+'tags.vtg'
#define XMLNAMESPACE_XHTML 'http://www.w3.org/1999/xhtml'
#define XMLNAMESPACE_XSL 'http://www.w3.org/1999/XSL/Transform'

#define XML_VALIDATION_MESSAGE_TYPE 'XML Error'

/**
 * Maximum seek position within an XML document where
 * syntax indent and SmartPaste&reg; will still work.
 * Beyond this point, Enter and paste will work the
 * same as it does in fundamental mode.
 * 
 * @default 125k
 * @categories Configuration_Variables
 */
int def_xml_max_smart_editing=725*1024;

/**
 * If a document contains excessive XML validation errors, 
 * the number of message actually logged generated can be 
 * capped by setting the limit to a value greater than 0. 
 *  
 * @default 25000
 * @categories Configuration_Variables
 */
int def_xml_messages_limit = 25000;

static _str gtkinfo;
static _str gtk;


int xmlQFormWID()
{
   // RGH - 4/25/06
   // No more XML output form..._tboutputwin_form
   if(isEclipsePlugin()){
      int formwid = _find_object(ECLIPSE_OUTPUT_CONTAINERFORM_NAME,'n');
      if (formwid > 0) {
         return formwid.p_child;
      }
      return 0;
   } else {
      int formwid=_find_formobj('_tboutput_form','N');
      _nocheck _control xmlerrorlist;
      _nocheck _control _output_sstab;
      if (!formwid) {
         tbShow('_tboutput_form');
         formwid=_find_formobj('_tboutput_form','N');
         if (!formwid) return -1;
         formwid._output_sstab.xmlerrorlist._delete_line();
      }
      if (!formwid) return -1;
      _nocheck _control _output_sstab;
      return formwid._output_sstab.xmlerrorlist;

   }
}
void activateXMLTab()
{
   // RGH - 4/25/2006
   // Activate _tboutputwin_form here
   if(isEclipsePlugin()){
      _outputWindow_activate();
      return;
   }
   int formwid=_find_formobj('_tboutput_form','N');
   _nocheck _control xmlerrorlist;
   _nocheck _control _output_sstab;
   if (!formwid) {
      tbShow('_tboutput_form');
      formwid=_find_formobj('_tboutput_form','N');
      if (!formwid) return;
      formwid._output_sstab.p_ActiveTab = OUTPUTTOOLTAB_XMLOUT;
   }

}
static _str xml_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   typeless status=0;
   _str ch=get_text_safe();
   if (ch=='') {
      status=search('[~ \t]','rh@');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      ch=get_text_safe();
   }
   typeless start_seek=0;
   if (ch=='"' || ch=="'" ) {
      start_seek=_nrseek()+1;
      ++p_col;
      status=search(ch,'@h');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      gtk=TK_STRING;
      gtkinfo=get_text_safe(_nrseek()-start_seek,start_seek);
      ++p_col;
      return(gtk);
   }
   if (ch=='>' || ch=='[' || ch=='=') {
      right();
      gtk=gtkinfo=ch;
      return(gtk);

   }
   int start_col=p_col;
   search('[ \t=>"'']|$','rh@');
   gtk=TK_ID;
   gtkinfo=_expand_tabsc(start_col,p_col-start_col);
   return(gtk);
}
int _mapxml_get_doctype_info(_str &maptype,_str &mapid,int &markid, boolean &istaglib)
{
   mapid='';
   maptype='';
   markid= NULL_MARKID;
   istaglib = false;

   save_pos(auto p);
   top();
   typeless status=search('<!DOCTYPE([ \t]|$)','>rh@xcs');
   if (status) {
      restore_pos(p);
      return(status);
   }
   boolean have_inline=false;
   for (;;) {
      xml_next_sym();

      if(gtkinfo=="taglib") {
         istaglib = true;   
      }

      if (gtk=='' || gtk=='>') {
         break;
      }

      if (gtk==TK_ID) {
         if (gtkinfo=='PUBLIC' || gtkinfo=='SYSTEM') {
            _str new_maptype=gtkinfo;
            xml_next_sym();
            if (gtk==TK_STRING) {
               mapid=gtkinfo;
               maptype=new_maptype;
               if (maptype=='PUBLIC') {
                  xml_next_sym();
                  if (gtk==TK_STRING) {
                     mapid=gtkinfo;
                     maptype='SYSTEM';
                  }
               }
            }
         }
      } else if (gtk=='[') {
         if (markid== NULL_MARKID) {
            markid=_alloc_selection();
         }
         _deselect(markid);
         _select_char(markid,'N');
         status=search(']','@h');
         if (status) {
            _free_selection(markid);
            markid=NULL_MARKID;
            break;
         } else {
            _select_char(markid);
            ++p_col;
         }
      }
   }
   restore_pos(p);
   return(0);
}
boolean _UrlEq(_str url1,_str url2)
{
   // verify that both URL's are http url's
   boolean url1_http = (lowcase(substr(url1,1,7)) == "http://");
   boolean url2_http = (lowcase(substr(url2,1,7)) == "http://");
   if (url1_http != url2_http) {
      return false;
   }
   // if they are both not http, then assume they are file names
   if (!url1_http && !url2_http) {
      return file_eq(absolute(url1), absolute(url2));
   }

   _str path1="", rest1="";
   _str path2="", rest2="";
   parse url1 with 'http://','i' path1 '/' rest1;
   parse url2 with 'http://','i' path2 '/' rest2;
   if (!strieq(path1,path2)) {
      return(false);
   }
   return(rest1==rest2);
}
_str _UrlCase(_str url)
{
   _str path1="", rest1="";
   parse url with 'http://','i' path1 '/' +0 rest1;
   if (rest1=='') {
      return(lowcase(url));
   }
   return('http://'lowcase(path1):+rest1);
}

#define SLICKEDIT_WEBSITE_PREFIX 'http://www.slickedit.com/'
#define SLICKEDIT_WEBSITE_LOCAL  "%VSROOT%sysconfig/http/www.slickedit.com/"
_str def_url_mapping_search_directory = '';
static boolean _mapurl_found(_str orig_httpfile,_str &new_file)
{
   int handle=_cfg_get_useroptions();
   if (handle<0) {
      return(false);
   }

   if (strieq(SLICKEDIT_WEBSITE_PREFIX,substr(orig_httpfile,1,length(SLICKEDIT_WEBSITE_PREFIX)))) {
      // remove http://www.slickedit.com/ and replace it with %VSROOT%sysconfig/http/www.slickedit.com/
      _str localURL = SLICKEDIT_WEBSITE_LOCAL :+ substr(orig_httpfile, length(SLICKEDIT_WEBSITE_PREFIX) + 1);
      localURL = _replace_envvars(localURL);
      localURL = translate(localURL, FILESEP, FILESEP2);
      new_file = localURL;
      return 1;
   }

   int i=0;
   int longest_match_len=0;
   typeless array[];
   _xmlcfg_find_simple_array(handle,"/Options/URLMappings/MapURL",array);
   for (i=0;i<array._length();++i) {
      _str from=_xmlcfg_get_attribute(handle,array[i],'From');
      if (_UrlEq(substr(orig_httpfile,1,length(from)),from) && length(from)>longest_match_len) {
         longest_match_len=length(from);
         _str To=_xmlcfg_get_attribute(handle,array[i],'To');
         new_file=To:+substr(orig_httpfile,length(from)+1);
      }
   }
   //return(false);
   if (longest_match_len) {
      return(true);
   }

   //Look in the default UM search directory
   if (file_exists(def_url_mapping_search_directory)) {
      orig_httpfile = _strip_filename(orig_httpfile,'P');
      _str tempSearchDir = def_url_mapping_search_directory;
      _maybe_append_filesep(tempSearchDir);
      orig_httpfile = tempSearchDir :+ orig_httpfile;
      if (file_exists(orig_httpfile)) {
         new_file = orig_httpfile;
         return(true);
      }
   }

   return(false);
}

//Global array used to store namespace mappings that is passed
//to the xerces parser to do mappings of namespaces.
_str UM_currentNamespaceMappings[];
/**
 * Called by xerces derived parser to get the namespace mappings 
 * for the current file.  Store them in the variable 
 * _currentNamespaceMappings.
 *  
 * @return 
 * 
 * @author David A. O'Brien (updated 1/11/2008)
 */
void UM_map_namespaces_found()
{
   save_pos(auto p);
   top();
   _str NamespacesHashtab:[];
   UM_currentNamespaceMappings._makeempty();

   //_str xsl_doctype_system='';
   //_str xsl_prefix='';
   //_str document_tag='';
   typeless junk=0;
   typeless handle=0;
   typeless status=search('<[^!?]','@rhxcs');
   if (!status) {
      //document_tag=_html_GetTag(1,junk);
      //if (pos(':',document_tag)) {
      //   parse document_tag with xsl_prefix':'document_tag;
      //}
      status=search('>','@rhxcs');
      if (!status) {
         right();
         _xml_get_current_namespaces(NamespacesHashtab);
      }
   }

   //if the file contains namespaces, add to first element of UM_currentNamespaceMappings.
   if (NamespacesHashtab._length()) {
      _str newname;
      foreach (auto orig_namespace in NamespacesHashtab) {
         if (_mapurl_found(orig_namespace, newname)) {
            if (UM_currentNamespaceMappings._length() == 0) {
               UM_currentNamespaceMappings[0] = ' ';
            }
            UM_currentNamespaceMappings[0] = UM_currentNamespaceMappings[0] :+ ' ' :+ orig_namespace :+ ' ' :+ newname;
         }
      }
      if (UM_currentNamespaceMappings._length()) {
      strip(UM_currentNamespaceMappings[0]);
   }
   }
   restore_pos(p);
   return;
}

static long ginlineBufSize;
static _str ginlineBufName;
static _str gorigBufName;
int _mapxml_find_system_file(
   _str systemid,
   _str buf_name,_str &local_dtd_filename,
   long seekPos=-1,
   boolean &was_mapped=false)
{
   was_mapped=false;
   if (seekPos>=0 && gorigBufName==buf_name && seekPos<ginlineBufSize) {
      buf_name=ginlineBufName;
   }
   local_dtd_filename='';
   if (systemid==null || systemid:=='') {
      return(0);
   }
   systemid=translate(systemid,'/',FILESEP);
   if (substr(systemid,1,6):=="ftp://"
       ) {
      // Don't support ftp
      return(1);
   }
   _str new_mapid='';
   if (strieq(substr(systemid,1,7),"http://")) {
      if (_mapurl_found(systemid,new_mapid)) {
         systemid=new_mapid;
         was_mapped=true;
      }
      if (strieq(substr(systemid,1,7),"http://")) {
         local_dtd_filename= _UrlToSlickEdit(systemid);
         return(0);
      }
   }
   systemid=translate(systemid,FILESEP,FILESEP2);
   if (substr(systemid,1,5):=="file:") {
      systemid=substr(systemid,6);
      int nonSlash=pos('[~/|\\]',systemid,1,'r');
      if (nonSlash>1) {
         // absolute file
         local_dtd_filename=absolute(systemid,absolute(FILESEP));
      } else {
         // relative file
         local_dtd_filename=absolute(systemid,_strip_filename(buf_name,'N'));
      }
      
   } else if (strieq(substr(buf_name,1,7),"http://")) {
      // if the path we are finding the system file relative to
      // is a URL, then "absolute" won't quite do it for us
      // so we need to put together the URL naively and attempt
      // to map the URL to a local file.
      local_dtd_filename = _strip_filename(buf_name,'N') :+ systemid;
      if (_mapurl_found(local_dtd_filename,new_mapid)) {
         local_dtd_filename=new_mapid;
         was_mapped=true;
      }
      if (strieq(substr(local_dtd_filename,1,7),"http://")) {
         local_dtd_filename= _UrlToSlickEdit(local_dtd_filename);
         return(0);
      }
      local_dtd_filename=absolute(systemid,_strip_filename(buf_name,'N'));
   } else {
      local_dtd_filename=absolute(systemid,_strip_filename(buf_name,'N'));
   }
   // try file-to-file URL mapping
   if (_mapurl_found(local_dtd_filename,new_mapid)) {
      local_dtd_filename=new_mapid;
      was_mapped=true;
   }
   if (!file_exists(local_dtd_filename)) {
      return(1);
   }
   return(0);
}
definit() {
   if (arg(1):!='L') {
      _xmlTempTagFileList._makeempty();
   }
}
int _exit_xml()
{
   config := tagfile := "";
   foreach (config => tagfile in _xmlTempTagFileList) {
      if (tagfile != "" && file_exists(tagfile)) {
         tag_close_db(tagfile);
         delete_file(tagfile);
      }
   }
   return(0);
}
static _str _mapxml_http_load_error_message(int status, _str local_dtd_filename, _str buf_name)
{
   if (buf_name=='') {
      if (status==FILE_NOT_FOUND_RC) {
         return nls("File '%s1' not found.",_SlickEditToUrl(local_dtd_filename));
      } else {
         return nls("Error loading file '%s1'. %s2.",_SlickEditToUrl(local_dtd_filename),get_message(status));
      }
   } else {
      if (status==FILE_NOT_FOUND_RC) {
         return nls("DTD '%s1' for file '%s2' not found.",_SlickEditToUrl(local_dtd_filename),buf_name);
      } else {
         return nls("Error processing DTD '%s1' for file '%s2'. %s3.",_SlickEditToUrl(local_dtd_filename),buf_name,get_message(status));
      }
   }
}
static _str _mapxml_http_load_error_alert(int status, _str local_dtd_filename)
{
   if (status==FILE_NOT_FOUND_RC) {
      return nls("DTD '%s1' not found.",_SlickEditToUrl(local_dtd_filename));
   } else {
      return nls("Error processing DTD '%s1'. %s2.",_SlickEditToUrl(local_dtd_filename),get_message(status));
   }
}
_str _mapxml_http_load_error(_str systemid,boolean &was_mapped,int &status,_str &local_dtd_filename,_str buf_name,boolean sendToOutputWindow=false)
{
   _str info='';
   if (was_mapped) {
      info='This error occurred with a mapped URL.  Use the URL Mappings dialog ("Tools","Options","URL Mappings...") to correct your URL mappings';
   } else {
      info='If you want to work off-line, use the URL Mappings dialog ("Tools","Options","URL Mappings...") to map a URL to a local path containing the files.':+"\n\n":+
           'You may not be able to get HTTP accesss due to your proxy settings, use the Proxy Settings dialog ("Tools","Options","Proxy Settings...") to configure your proxy settings.';
   }
   result := "";
   langId := _isEditorCtl()? p_LangId:"xml";
   if (sendToOutputWindow && !LanguageSettings.getAutoValidateOnOpen(langId)) {
      outputMessage := _mapxml_http_load_error_message(status,local_dtd_filename,buf_name);
      _SccDisplayOutput(outputMessage,false,false,true);
      _SccDisplayOutput(info,false,false,true);
      return result;
   } else {
      //result=show('-modal _dtd_open_error_form',status,local_dtd_filename,buf_name,info);
      _str alertMsg = _mapxml_http_load_error_alert(status,local_dtd_filename);
      _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_DTD_LOAD_ERROR, alertMsg);
      if (result=='') return(result);
   }
   status=_mapxml_find_system_file(systemid,buf_name,local_dtd_filename,-1,was_mapped);
   return(result);
}
static int _mapxml_create_tagfile(_str maptype,_str mapid,int markid,_str buf_name, _str &tagfile,_str DocumentName, boolean doUpdate=false)
{
   if (DocumentName=='') DocumentName=buf_name;
   _str local_dtd_filename='';
   boolean was_mapped=false;
   int status=0;
   if (mapid!='') {
      if (maptype == 'SYSTEM' || maptype == 'SCHEMA') {
         status=_mapxml_find_system_file(mapid,buf_name,local_dtd_filename,-1,was_mapped);
         if (status) {
            status=FILE_NOT_FOUND_RC;
            if (!was_mapped) {
               desc := (maptype=='SCHEMA') ? 'schema' : 'DTD';
               _str alertMsg = (nls("Error processing %s for file '%s'.\n\nFile '%s' not found", desc, DocumentName,local_dtd_filename));
               _ActivateAlert(ALERT_GRP_WARNING_ALERTS, ALERT_SCHEMA_LOAD_ERROR, alertMsg);
               return(1);
            }
         }
      }
   }

   _str default_dtd='';
   tagfile=_xml_GetConfigTagFile();
   if (!status && local_dtd_filename=='' && markid==NULL_MARKID) {
      parse name_info(find_index('def_default_dtd_'_file_case(_get_extension(buf_name)),MISC_TYPE)) with default_dtd;
      default_dtd=_replace_envvars(default_dtd);
      if (file_eq(_get_extension(default_dtd),'vtg')) {
         tagfile=default_dtd;
         return(0);
      }
      local_dtd_filename=default_dtd;
      if (local_dtd_filename=='') {
         // Can't find DTD for this file
         return(1);
      }
   }

   // check if this DTD is already tagged and use that tag file
   // instead of opening the file and creating a new tag file
   if (local_dtd_filename != '' && _xmlTempTagFileList._indexin(local_dtd_filename)) {
      tagfile = _xmlTempTagFileList:[local_dtd_filename];
      if (tagfile != '' && tag_read_db(tagfile) >= 0) {
         lastDateTagged := "";
         dateStatus := tag_get_date(local_dtd_filename, lastDateTagged);
         if (!tag_get_date(local_dtd_filename, lastDateTagged) && lastDateTagged == _file_date(local_dtd_filename, 'B')) {
            return 0;
         }
      }
   }
         
   // Build the tag file
   typeless result=0;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=_UTF8();// _load_option_UTF8(p_buf_name);
   if (status || local_dtd_filename!='') {
      if (!status) {
         status=get(maybe_quote_filename(local_dtd_filename),'','A');
      }
      if (status) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         if (!was_mapped && status==FILE_NOT_FOUND_RC) {
           // _message_box(nls("Error processing DTD '%s1' for file '%s2'.\n\nFile '%s3' not found",
           //                  _SlickEditToUrl(local_dtd_filename),DocumentName,_SlickEditToUrl(local_dtd_filename)));
            int wid = p_window_id;
            _switch_to_xml_output(true);
            _xml_display_output(nls("Error processing DTD '%s1' for file '%s2'.\n\nFile '%s3' not found.",
                             _SlickEditToUrl(local_dtd_filename),DocumentName,_SlickEditToUrl(local_dtd_filename)));
            top_of_buffer();
            p_window_id = wid;
            wid._set_focus();
            activate_window(orig_view_id);
         } else {
            for (;;) {
               result=_mapxml_http_load_error(mapid,was_mapped,status,local_dtd_filename,DocumentName,!doUpdate);
               if (result=='') return(result);
               if (status) {
                  status=FILE_NOT_FOUND_RC;
               } else {
                  _create_temp_view(temp_view_id);
                  p_UTF8=_UTF8();// _load_option_UTF8(p_buf_name);
                  status=get(local_dtd_filename,'','A');
                  if (!status) {
                     break;
                  }
                  _delete_temp_view(temp_view_id);
                  activate_window(orig_view_id);
               }
               //_message_box(nls("Error processing DTD '%s1' for file '%s2'.\n\n",_SlickEditToUrl(local_dtd_filename),buf_name):+get_message(status)"\n\n":+info);
            }
         }
         if (status) {
            return(status);
         }
      }
      p_buf_name=local_dtd_filename;
   }
   ginlineBufSize=0;ginlineBufName='';

   if (markid!=NULL_MARKID) {
      top();up();
      int Noflinesb4=p_Noflines;
      insert_line('');
      _copy_to_cursor(markid);
      p_line=p_Noflines-Noflinesb4+1;
      p_col=1;
      ginlineBufSize=_QROffset();
      ginlineBufName=buf_name;
      p_buf_name=buf_name;
   }
   if (p_buf_name=='') {
      p_buf_name=_strip_filename(buf_name,'e')'.dtd';
   }
   gorigBufName=p_buf_name;

   // check if this DTD is already tagged and use that tag file
   // instead of creating a new tag file
   if (tagfile=='' && _xmlTempTagFileList._indexin(p_buf_name)) {
      tagfile = _xmlTempTagFileList:[p_buf_name];
      if (tagfile != '' && tag_read_db(tagfile) >= 0) {
         lastDateTagged := "";
         if (tag_get_date(p_buf_name, lastDateTagged) && lastDateTagged == p_file_date) {
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            return 0;
         }
      }
   }
         
   if (tagfile=='') {
      tagfile=mktemp(1,'.vtg');
      _xmlTempTagFileList:[p_buf_name]=tagfile;
   }
   tag_close_db(tagfile);
   status=tag_create_db(tagfile);
   if (status < 0) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return(status);
   }
   if (maptype=='SCHEMA') {
      _SetEditorLanguage('xsd',false,false,true);
   } else {
      _SetEditorLanguage('dtd',false,false,true);
   }
   //_showbuf(p_buf_id);
   RetagCurrentFile();
   tag_set_date(p_buf_name, p_file_date);
   tag_close_db(null,true);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(0);
}
_command void apply_dtd_changes() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if(p_LangId == "html") {
      _mapjsp_init_file(p_window_id, true);
   } else {
      _mapxml_init_file(true);
   }
}
void _mapxml_init_file(boolean doUpdate=false)
{
   _str NamespaceHashtab:[];
   save_pos(auto p2);
   top();
   _str xsl_doctype_system='';
   _str xsl_prefix='';
   _str document_tag='';
   typeless junk=0;
   typeless handle=0;
   typeless status=search('<[^!?]','@rhxcs');
   if (!status) {
      document_tag=_html_GetTag(1,junk);
      if (pos(':',document_tag)) {
         parse document_tag with xsl_prefix':'document_tag;
      }
      status=search('>','@rhxcs');
      if (!status) {
         right();
         _xml_get_current_namespaces(NamespaceHashtab);
         // Here we do something simple to handle the "xsl:output" information which is not
         // in the first tag.  This is a bit of a hack because we are treating the doctype-system
         // DTD like the !DOCTYPE but it is really an additional DTD.
         /*
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" doctype-system="http://www.w3.org/TR/2000/CR-SVG-20001102/DTD/svg-20001102.dtd" />
    <xsl:template match="/">
        <svg width="8cm" height="4cm">

        </svg>
    </xsl:template>
</xsl:stylesheet>


         */
         if (file_eq(_get_extension(p_buf_name),'xsl')) {
            bottom();
            handle=_xmlcfg_open_from_buffer(p_window_id,status,VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR);
            if (handle>=0) {
               if(document_tag=='stylesheet') {
                  int output_index=_xmlcfg_find_simple(handle,'/'xsl_prefix:+':stylesheet/'xsl_prefix':output');
                  if (output_index>=0) {
                     xsl_doctype_system=_xmlcfg_get_attribute(handle,output_index,'doctype-system');
                     if (xsl_doctype_system!='') {
                        NamespaceHashtab:['']=xsl_doctype_system;
                     }
                  }
               }
               _xmlcfg_close(handle);
            }
         }

      }
   }
   restore_pos(p2);
   // Get recognized namespaces
   // Use pipe separator for namespace info
   // Check if this is an XSL document
   if (doUpdate) {
      _UrlSetCaching(2);
      _mapxml_init_file2(doUpdate,NamespaceHashtab,xsl_doctype_system);
      _UrlSetCaching(1);
   } else {
      _mapxml_init_file2(doUpdate,NamespaceHashtab,xsl_doctype_system);
   }
   _str tagfile=_clex_xmlGetConfig();
   if (tagfile=='') {
      _clex_xmlSetConfig(doUpdate,_xml_MakeConfig('',NamespaceHashtab));
   }
   typeless i;
   for (i=null;;) {
      typeless value=NamespaceHashtab._nextel(i);
      if (i==null) {
         break;
      }
      //say('i='i' value='value);
      //say('v='value);
      _str tag_filename='';
      if(_xml_NamespaceToTagFile(tag_filename, value) < 0) {
         continue;
      }
      //say('tf='tag_filename);
      //f:\vslick70\XMLNamespaces\www.w3.org\1999\xhtml\
      int cfg_color=CFG_KEYWORD;
      if ((file_eq(tag_filename,XMLNAMESPACE_TAGFILE_XHTML) ||
           (i=='' && xsl_prefix!='' && xsl_doctype_system!='') )

          // Might want to change this to check for XSL style-sheet document node
          && file_eq(_get_extension(p_buf_name),'xsl')
          ) {
         cfg_color=CFG_XHTMLELEMENTINXSL;
         //say('**********************');
      }
      //cfg_color=CFG_PPKEYWORD;
      //cfg_color=CFG_KEYWORD;
      _xml_addTagsToColorCoding(tag_filename,i,cfg_color);
   }

}
static _str _xml_MakeConfig(_str tagfile,_str (&NamespaceHashtab):[])
{
   _str string='';
   typeless i;
   for (i=null;;) {
      typeless value=NamespaceHashtab._nextel(i);
      if (i==null) {
         break;
      }
      if (string=='') {
         string=i'='value;
      } else {
         string=string';'i'='value;
      }
   }
   //say('s='string);
   return(tagfile'|'string);
}
_str _xml_GetConfigTagFile()
{
   _str tagfile='', string='';
   parse _clex_xmlGetConfig() with tagfile'|'string;
   return(tagfile);
}
_str _xml_GetConfigNamespace()
{
   _str tagfile='', string='';
   parse _clex_xmlGetConfig() with tagfile'|'string;
   if (first_char(string)=='=') {
      string=substr(string,2);
   }
   return(string);
}
/**
 * Retarget the given tag for the specified namespace.
 * If it's original namespace was specified on the schema,
 * remove the original namespace prefix.
 * If a new namespace was specified when the schema was
 * imported, prepend that namespace.
 *
 * @param tag_name      tag to fix
 * @param default_ns    original default namespace
 * @param target_ns     target namespace
 */
_str _xml_retargetNamespace(_str name,_str default_ns=null, _str target_ns=null)
{
   if (default_ns!=null) {
      if (pos(default_ns':',name)==1) {
         name=substr(name,length(default_ns)+2);
      }
   }
   if (target_ns!=null) {
      int k=pos(':',name);
      if (k) {
         name=substr(name,k+1);
      }
      if (target_ns!='') {
         name=target_ns:+':':+name;
      }
   }
   return name;
}
static void _xml_addTagsToColorCoding(_str tagfile, _str prefix=null, int cfg_color=CFG_KEYWORD)
{
   status := tag_read_db(tagfile);
   if (status < 0) {
      return;
   }

   _str default_ns = null;
   status = tag_find_global(VS_TAGTYPE_package,0,0);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_name,default_ns);
   }

   _str tag_name='';
   _str tag_type='';
   _str file_name='';
   _str class_name='';
   int line_no=0;
   int tag_flags=0;
   _str list[];
   status=tag_find_global(VS_TAGTYPE_tag,0,0);
   for (;!status;) {
      tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
      list[list._length()]=tag_name;
      status=tag_next_global(VS_TAGTYPE_tag,0,0);
      if (!(tag_flags& VS_TAGFLAG_final)) {
         tag_name=_xml_retargetNamespace(tag_name,default_ns,prefix);
         _clex_xmlAddKeywordAttrs("/"tag_name,"",cfg_color);
      }
   }
   int i;
   for (i=0;i<list._length();++i) {
      tag_name=list[i];
      //status=tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
      status=tag_find_in_class(tag_name);
      _str attr_name;
      _str attr_list='';
      for (;!status;) {
         tag_get_info(attr_name,tag_type,file_name,line_no,class_name,tag_flags);
         if (tag_type=='enumc') {
            status=tag_next_in_class();
            continue;
         }
         attr_name=_xml_retargetNamespace(attr_name,default_ns,null);
         attr_list=attr_list:+' ':+attr_name;
         status=tag_next_in_class();
      }
      tag_reset_find_in_class();
      tag_name=_xml_retargetNamespace(tag_name,default_ns,prefix);
      _clex_xmlAddKeywordAttrs(tag_name,attr_list,cfg_color);
   }
   list._makeempty();

   status=tag_find_global(VS_TAGTYPE_constant,0,0);
   for (;!status;) {
      tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
      if (tag_type=='const') {
         // Add constants like &lt;, &gt;
         _str kwd='&'tag_name';';
         //say('kwd='kwd);
         _clex_xmlAddKeywordAttrs(kwd,'');
      }
      status=tag_next_global(VS_TAGTYPE_constant,0,0);
   }

   tag_reset_find_in_class();
   tag_close_db(tagfile);
}

/**
 * Holds a list of space-separated extensions on which to bypass 
 * XML color coding set up.  Adding an extension to this list 
 * will prevent the editor from trying to fetch the dtd/schema 
 * when these XML files are loaded. 
 *  
 * Note: You must prepend the '.' to the extension (e.g. '.xml' 
 * NOT 'xml'). 
 *
 * @default ''
 * @categories Configuration_Variables
 */
_str def_xml_no_schema_list;

/**
 *  
 *  
 * @param doUpdate
 * @param NamespaceHashtab
 * @param xsl_doctype_system
 */
static void _mapxml_init_file2(boolean doUpdate,_str (&NamespaceHashtab):[],_str xsl_doctype_system='')
{
   int markid;
   _str mapid;
   _str maptype;
   typeless status=0;
   _str mapprefix=null;
   boolean istaglib=false;
   boolean addTagsToColorCoding=true;
   if (!doUpdate && pos(' .'p_LangId' ',' 'def_xml_no_schema_list' ')) {
      status=1;
      mapid='';
      maptype='';
      markid= NULL_MARKID;
      NamespaceHashtab._makeempty();
   } else {
      status=_mapxml_get_doctype_info(maptype,mapid,markid,istaglib);
   }

   if (status) {
      maptype='';mapid='';markid=NULL_MARKID;
      if (xsl_doctype_system!='') {
         mapid=xsl_doctype_system;
         maptype='SYSTEM';
         //_message_box('special case 'mapid);
         addTagsToColorCoding=false;
      } else {
         // go through our possible namespaces

         foreach (auto prefix => auto id in NamespaceHashtab) {
            if (prefix != 'xsi') {
               mapid=id;
               maptype='SCHEMA';
               mapprefix=prefix;
               break;
            }
         }
      }

   }
   _str tagfile;
   if (!doUpdate && pos(' .'p_LangId' ',' 'def_xml_no_schema_list' ')) {
      status = 1;
   } else {
      status=_mapxml_create_tagfile(maptype,mapid,markid,p_buf_name,tagfile,p_DocumentName,doUpdate);
   }
   //say('create status='status);
   //say('tagfile='tagfile);
   if (markid!=NULL_MARKID) {
      _free_selection(markid);
   }
   if (status) {
      _clex_xmlSetConfig(doUpdate,'');
      return;
   }
   //say('tagfile='tagfile' bn='p_buf_name);

   _clex_xmlSetConfig(doUpdate,_xml_MakeConfig(tagfile,NamespaceHashtab));

   if (addTagsToColorCoding) {
      _xml_addTagsToColorCoding(tagfile,mapprefix);
   }
}
#if 0
_command void test2()
{
   _mapxml_init_file();
}
_command void test()
{
   _str maptype='', mapid='';
   typeless markid=0;
   boolean istaglib=false;
   int status=_mapxml_get_doctype_info(maptype,mapid,markid,istaglib);
   if (markid!=NULL_MARKID) {
      typeless orig_markid=_duplicate_selection('');
      _show_selection(markid);
      messageNwait('selection');
      _show_selection(orig_markid);
      _free_selection(markid);
   }
   //say('markid='markid);
   //say('maptype='maptype);
   //say('mapid='mapid);

}
#endif

defeventtab xml_keys;
def  ' '= html_space;
def  '%'-'&'= auto_codehelp_key;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  '/'= xml_slash;
def  ':'= html_key;
def  '<'= auto_codehelp_key;
def  '='= auto_codehelp_key;
def  '>'= xml_gt;
def  '{'= html_key;
def  '}'= html_key;
def  'ENTER'= xml_enter;
def  'TAB'= smarttab;

_str get_prev_char()
{
   if (p_col==1) return('');
   left();
   _str ch=get_text_safe(-2);
   right();
   return(ch);
}
/*_command void xml_maybe_auto_codehelp_key() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   if (command_state()) {
      call_root_key(last_event());
      return;
   }
   // Handle embedded language
   int embedded_status=_EmbeddedStart(orig_values,'');
   if (embedded_status==1) {
      call_key(last_event());
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (file_eq(get_extension(p_buf_name),'xsl')) {
      key=last_event();
      switch (key) {
      case '<':
         call_root_key(last_event());
         return;
      case '?':
      case '!':
         if (p_col==1) {
            call_root_key(last_event());
         }
         left();
         if (get_text()!='<') {
            right();
            call_root_key(last_event());
         }
         right();
         break;
      case ':':
         if (p_col<5 || get_text(4,_nrseek()-4)!='<xsl') {
            call_root_key(last_event());
            return;
         }
         break;
      default:
          call_root_key(last_event());
          return;
      }
      keyin(last_event());
      _macro('m', _macro('s'));
      list_symbols();
      return;
   }
   auto_codehelp_key();
}
*/

/** 
 * Called on a '/' keystroke in xml mode.
 * 
 */
_command void xml_slash() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   _str key='/';
   if (command_state()) {
      call_root_key(key);
      return;
   }
   // Handle embedded language
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(key, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }

   //int cfg2=_clex_find(0,'g');
   //if (cfg2==CFG_COMMENT || cfg2==CFG_STRING) {
   //   if (cfg2==CFG_COMMENT) say("Comment");
   //   else say("String");
   //   return;
   //}

   if (p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART||
       get_prev_char()!='<') {
      keyin(key);
      return;
   }
   boolean prev_is_lt=(get_prev_char()=='<');
   boolean next_is_gt=(get_text()=='>');
   keyin(key);
   if (!prev_is_lt) {
      return;
   }
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return;
   }
   _str start_tag='';
   int orig_col=p_col;
   int after_first_non_blank_col=0;
   int col=_xml_slash(start_tag,after_first_non_blank_col);
   if (col /*|| after_first_non_blank_col*/) {
      _str gt = (next_is_gt ? ('') : ('>'));
      _str line='';
      get_line(line);
      if (line=='</') {
         if (!col) {
            return;
         }
         replace_line(indent_string(col-1):+strip(line):+start_tag:+gt);
         _end_line();
         return;
      }
      p_col=orig_col;
      if (pos(start_tag, _expand_tabsc(orig_col, -1, 'S'), 1) != 1) {
         _insert_text(start_tag:+gt);
      }
   } else if (prev_is_lt) {
      left();
      _delete_char();
      auto_codehelp_key();
   }
}

static int _xml_matchTagBackward(_str &start_tag,int &after_first_non_blank_col=0)
{
   int status;
   int level = 0;

   //Move back past the '</'
   if (p_col < 3) {
      return -1;
   }
   p_col -= 2;
   if (XW_FOUND_S_TAG == XW_FindParentBlockTag2(start_tag, level)) {
      return 0;
   }
   return -1;

   //Replaced following code with above more robust search from xml/html wrapping search

   after_first_non_blank_col=0;
   level = 0;
   _str search_str;
   for (;;) {
      status = search('[<>]', "-rh@XCS");
      if (status) {
         return(-1);
      }
      //status = search(search_str, "-ri@CK");
      _str ch=get_text_safe();
      _str word=get_text_safe(2);
      if (word=='</') {  // Found ending tag.
         int col=p_col;
         int start=0;
         //++p_col;
         _str tag=_html_GetTag(1,start);
         //--p_col;
         //say('tag='tag' line='p_line);
         if (tag!='') {
            //_message_box('tag='tag' start='start' level='level);
            status=_html_matchTagBackward(tag);
            if (status) return(-1);
            //_message_box('after tag='tag' start='start);
            
         } else {
            ++level;
         }
         if(p_col==1) {
            status=up();
            if (status) return(-1);
            _end_line();
         } else {
            --p_col;
         }
         //status = search(">", "-r@CK");  // skip to the end of the previous tag
         //status = search(">", "-r@XCS");  // skip to the end of the previous tag
         //if (status) return(-1);
      } else if (ch=='<') {
         //_str ch2=get_text(2);
         if (word=='<!' || word=='<?') {
            status = search(">", "-rh@XCS");  // skip to the end of the previous tag
            if (status) return(-1);
            continue;
         }
         --level;
         //_message_box('< level='level);
         if (level<0) {
            // We are lost
            return(-1);
         }
         if (!level) {
            int col=p_col;
            int start=0;
            start_tag=_html_GetTag(1,start);
            first_non_blank();
            if (col!=p_col) {
               after_first_non_blank_col=col;
               return(-1);
            }
            return(0);  // found matching tag and cursor also already at the beginning of the tag
         }
         //status = search(">", "-rh@CK");  // skip to the end of the previous tag
         status = search(">", "-rh@XCS");  // skip to the end of the previous tag
         if (status) return(-1);
      } else if(word=='/>' ) {
         status = search(">", "-rh@XCS");  // skip to the end of the previous tag
         if (status) return(-1);
      } else {
         // hit >
         if(p_col==1) {
            status=up();
            if (status) return(-1);
            _end_line();
         } else {
            --p_col;
         }
      }
   }
   return(-1);
}
/*
    Only call if not in comment or string and have </
*/
static int _xml_slash(_str &start_tag,int &after_first_non_blank_col=0)
{
   if (_nrseek()>def_xml_max_smart_editing) {
      return(0);
   }
   save_pos(auto p);

   // tagging for these languages is not strictly XML outlining,
   // so we need to use old-style tag matching
   if (p_LangId != 'xml' && _FindLanguageCallbackIndex("vs%s_list_tags")) {
      if (_xml_matchTagBackward(start_tag)) {
         restore_pos(p);
         return(0);
      }
      int col=p_col;
      restore_pos(p);
      return(col);
   }
   if (p_buf_size>def_update_context_max_file_size) {
      return(0);
   }
   // For regular XML, we can use the current context
   // to find the current tag, quicker than doing
   // a lot of recursive searching backwards
   int status=_nrseek(_nrseek()-2);
   if (status) {
      return(0);
   }
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int context_id = tag_current_context();
   if (context_id <=0) {
      restore_pos(p);
      return(0);
   }

   VS_TAG_BROWSE_INFO cm;
   tag_browse_info_init(cm);
   tag_get_context_info(context_id,cm);
   start_tag=cm.member_name;
   _GoToROffset(cm.seekpos);
   int col=p_col;
   restore_pos(p);
   return(col);
}

_command void xml_gt() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   _str key='>';
   if (command_state()) {
      call_root_key(key);
      return;
   }
   // Handle embedded language
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(key, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   _insert_text(key);
   if (XW_isSupportedLanguage2()) {
      if (ST_doSymbolTranslation()) {
         ST_nag();
         return;
      }
   }
   if (p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART) {
      return;
   }
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return;
   }
   _str line='';
   get_line(line);
   int col=_xml_gt();
   if (col) {
      replace_line(indent_string(col-1):+strip(line));
      _end_line();
   }

   XW_gt();

}
//finds column of opening '<' so can move either closing '>' or '/>' when
//appearing alone on a line to line up with the '<'
int _xml_gt()
{
   get_line(auto line);
   if (line!='>' && line!='/>') {
      return(0);
   }
   save_pos(auto p);
   int status=search('<','-rh@xcs');
   if (status) {
      return(0);
   }
   int col=p_col;
   restore_pos(p);
   return(col);
}

_command void xml_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (ispf_common_enter()) return;
   if (command_state()) {
      call_root_key(ENTER);
      return;
   }

   // Handle embedded language
   typeless orig_values;
   int embedded_status=_EmbeddedStart(orig_values);
   if (embedded_status==1) {
      call_key(ENTER, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }
   if (p_window_state:=='I') {
      call_root_key(ENTER);
   } else if (XW_doEnter()) {
      return;
   } else if (p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
          _nrseek()>def_xml_max_smart_editing
          ) {
         call_root_key(ENTER);
      } else {
      if (_in_comment(1) || _xml_InString()) {
         call_root_key(ENTER);
      } else if (_xml_expand_enter() ) {
          call_root_key(ENTER);
      } else if (_argument=='') {
         _undo('S');
      }
   }
}
boolean _xml_expand_enter()
{
   int col=0;
   if (LanguageSettings.getSyntaxExpansion(p_LangId)) {
      col=xml_indent_col(0);
   } else {
      col=_first_non_blank_col();
   }
   indent_on_enter(0,col);
   return(false);
}


static int NoSyntaxIndentCase(int non_blank_col,int orig_linenum,int orig_col,typeless p,int syntax_indent)
{
   // SmartPaste(R) should set the non_blank_col
   restore_pos(p);
   if (non_blank_col) {
      //messageNwait("fall through case 1");
      return(non_blank_col);
   }
   get_line(auto line);line=expand_tabs(line);
   if (line=="") {
      restore_pos(p);
      return(p_col);
   }
   //messageNwait("fall through case 3");
   first_non_blank();
   int col=p_col;
   restore_pos(p);
   return(col);
}
int xml_indent_col(int non_blank_col, boolean paste_open_block = false)
{
   int orig_col=p_col;
   int orig_linenum=p_line;
   save_pos(auto p);
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   if ( syntax_indent<=0) {
      // Find non-blank-col
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,0));
   }

   if (p_col==1) {
      up();_end_line();
   } else {
      left();
   }
   int MaxSkipPreprocessing=VSCODEHELP_MAXSKIPPREPROCESSING;
   // Skip spaces backward
   typeless status=search("[~ \t]","@rh-");
   if (status) {
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
   }
   _str word="";
   _str ch1=get_text_safe();
   _str ch2=get_text_safe(2);
   typeless junk=0;
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_WINDOW_TEXT && (ch1!='<' && ch1!='>' && ch2!='/>')) {
      boolean doIndent=false;
      word_chars := _clex_identifier_chars();
      if (_LanguageInheritsFrom('dtd') && pos('['word_chars']',get_text_safe(-2),1,'r')) {
         save_pos(auto p2);
         prev_full_word();
         left();
         if (get_text_safe()=='') {
            prev_full_word();
            word=cur_word(junk);
            if (word=='!ATTLIST') {
               doIndent=true;
            }
         }
         restore_pos(p2);
      }
      if (!doIndent) {
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }
   }
   // Found something like &lt;  or &gt;
   if (cfg==CFG_KEYWORD && ch1==';') {
      return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
   }

   status=search("[<>]","@rh-xcs");
   for (;;) {
      if (status) {
         return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
      }

      cfg=_clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         status=repeat_search();
         continue;
      }

      _str ch=get_text_safe();
      _str text="";
      int col=0;
      //messageNwait('ch='ch);
      switch (ch) {
      case '<':
         text=get_text_safe(2);
         /*if (text=='</' || text=='<!' || text=='<?' || text=='<%') {
            col=p_col;
         } else {
            col=p_col+p_SyntaxIndent;
         } */
         col=p_col+p_SyntaxIndent;
         restore_pos(p);
         return(col);
      default: // '>'
         if (p_col!=1) {
            left();
            if (get_text_safe()=='/') {   // hit />
               right();
               status=search('<','-rh@xcs');
               if (status) {
                  return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
               }
               col=p_col;
               restore_pos(p);
               return(col);
            }
            right();
         }
         status=search('<','-rh@xcs');
         if (status) {
            return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
         }
         text=get_text_safe(2);
         if (text=='</') {
            /*
                 (Clark) Either code path is fine.  We might want to change this to check the limit 
                 and do _xml_slash if we are less then the def_xml_max_smart_editing limit.  Otherwise,
                 do the first_non_blank.  At the moment, I can't see a reason why using
                 first_non_blank() isn't good enough.
            */
            
            first_non_blank();
            col=p_col;
#if 0
            _str start_tag="";
            col=_xml_slash(start_tag);
            if (!col) {
               return(NoSyntaxIndentCase(non_blank_col,orig_linenum,orig_col,p,syntax_indent));
            }
#endif
            restore_pos(p);
            return(col);
         }
         if (text=='</' || text=='<!' || text=='<?' || text=='<%') {
            col=p_col;
         } else {
            col=p_col+p_SyntaxIndent;
         }
         restore_pos(p);
         return(col);
      }
   }

}
int dtd_smartpaste(boolean char_cbtype,int first_col,int Noflines)
{
   return(xml_smartpaste(char_cbtype,first_col,Noflines));
}
static boolean _xml_InString()
{
   if (//p_LangId!='xml' ||
       //(_lineflags() & EMBEDDEDLANGUAGEMASK_LF)
       //|| !_clex_InString(flags)
       _clex_find(0,'g')!=CFG_STRING
       ) {
      return(false);
   }
   return(true);

}
int xml_smartpaste(boolean char_cbtype,int first_col,int Noflines)
{
   // Go ahead and do smartpaste even when in multi-line string.  This is
   // usually OK for XML
   //if (_xml_InString()) {
   //   return(0);
   //}

   //If pasted stuff starts with comment and indent is different than code,
   // do nothing.
   // Find first non-blank line
   save_pos(auto p4);
   int j;
   _str first_line="";
   for (j=1;j<=Noflines;++j) {
      get_line(first_line);
      int i=verify(first_line,' '\t);
      if ( i ) {
         p_col=text_col(first_line,i,'I');
      }
      if (i) {
         break;
      }
      if(down()) {
         break;
      }
   }
   int comment_col=p_col;
   if (j>1) {
      restore_pos(p4);
   }

   // search for non-blank character
   int status=search('[~ \t]','@mrh');
   if (status) {
      return(0);
   }
   _str ch1=get_text_safe();
   _str ch2=get_text_safe(2);
   _str ch9=get_text_safe(9);
   int cfg=_clex_find(0,'g');
   // IF    (code found AND pasting comment AND code col different than comment indent)
   //    OR first non-blank pasted line starts with non-blank AND
   //       (not pasting character selection OR copied text from column 1)
   //    OR (not pasting start tag or end of tag)
   //    OR pasting &XXX; keyword, another pasting text case
   //    //OR pasting CDATA -- not sure if we want this test or not
   if ((!status && comment_col!='' && p_col!=comment_col)
       || (substr(first_line,1,1)!='' && (!char_cbtype ||first_col<=1))
       || (ch1!='<' && ch1!='>' && ch2!='/>' && cfg==CFG_WINDOW_TEXT)
       || (ch1=='&' && cfg==CFG_KEYWORD)
       //|| (ch9=='<![CDATA[' && cfg==CFG_WINDOW_TEXT)
       ) {
      //say('abort');
      return(0);
   }
   _str start_tag="";
   typeless enter_col=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   if (!status && ch1=='>' || ch2=='/>') {
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=_xml_gt();
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();up();
   } else if (ch2=='</') {  // Pasting end tag
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=_xml_slash(start_tag);
      if (!enter_col) {
         enter_col='';
      }
      _begin_select();up();
   } else {
      _begin_select();up();
      _end_line();
      enter_col=xml_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || enter_col=='' ) {
      return(0);
   }
   return(enter_col);
}
static _str xml_enter_col()
{
   typeless enter_col=0;
   typeless expand=LanguageSettings.getSyntaxExpansion(p_LangId);
   expand=expand && _nrseek()<def_xml_max_smart_editing;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _nrseek()>def_xml_max_smart_editing ||
      xml_enter_col2(enter_col,p_SyntaxIndent,expand) ) {
      return('');
   }
   return(enter_col);
}
static _str xml_enter_col2(_str &enter_col,int syntax_indent,_str expand)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent = p_SyntaxIndent;

   int status=0;
   /*_end_line();
   if (p_col<non_blank_col+1) {
      p_col=non_blank_col+1;
   } */
   if (expand) {
      enter_col=xml_indent_col(0);
   } else {
      enter_col=_first_non_blank_col();
   }
   return(status);
}

int _xml_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            boolean find_parents,int max_matches,
                            boolean exact_match,boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _html_find_context_tags(errorArgs,
                                  prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,
                                  max_matches,exact_match,case_sensitive,
                                  filter_flags,context_flags,visited,depth);
}

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _xml_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                             VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   tag_idexp_info_init(idexp_info);
   int status= _html_get_expression_info(PossibleOperator,idexp_info,visited,depth);
   //say('status='status' l='lastid' pre='prefixexp);
   return(status);
}
static void _xml_get_namespaces(int handle,int NodeIndex,_str (&NamespaceHashtab):[],
                                _str (&NamespaceHashtab2):[])
{
   int LastIndex=_xmlcfg_get_last_child(handle,NodeIndex);
   if (LastIndex<0) {
      return;
   }
   //say('name='_xmlcfg_get_name(handle,LastIndex));
   int AttrIndex=LastIndex;
   for (;;) {
      AttrIndex=_xmlcfg_get_next_attribute(handle,AttrIndex);
      if (AttrIndex<0) {
         break;
      }
      _str AttrName=_xmlcfg_get_name(handle,AttrIndex);
      //say('AttrName='AttrName);
      _str value=_xmlcfg_get_value(handle,AttrIndex);
      if (value=='http://www.w3.org/2000/10/XMLSchema') {
         value='http://www.w3.org/2001/XMLSchema';
      }
      if (strieq(substr(value,1,7),"http://")) {
         value=_UrlCase(value);
      }
      if (AttrName=='xmlns') {
         // XML namespaces are not meant to be parsed. They are only used for scoping
         // the child elements. We will still store the uri value, but it had
         // better be replaced by either:
         // xsi:schemaLocation="uri-path"
         // or
         // xsi:noNamespaceSchemaLocation="uri-path"
         NamespaceHashtab:['']=value;
         NamespaceHashtab2:[value]='';
      } else if (substr(AttrName,1,6)=='xmlns:') {
         // XML namespaces are not meant to be parsed. They are only used for scoping
         // the child elements. We will still store the uri value, but it had
         // better be replaced by either:
         // xsi:schemaLocation="..."
         // or
         // xsi:noNamespaceSchemaLocation="..."
         NamespaceHashtab:[substr(AttrName,7)]=value;
         NamespaceHashtab2:[value]=substr(AttrName,7);
      } else if (length(AttrName)>13 && substr(AttrName,length(AttrName)-13)=="schemaLocation") {
         _str prefix=substr(AttrName,1,length(AttrName)-15);
         if (prefix=='xsi' && pos(' ',value) > 0) {
            _str urlns='';
            _str uri='';
            do {
               parse value with urlns ' ' uri ' ' value;
               uri=strip(uri);
               // Find the matching urlns in the namespace hashtables and replace
               // with uri so we can find the schemas.
               //
               // Note: This method depends on the 'xmlns' attribute coming
               // before the 'xsi:schemaLocation' attribute.
               boolean found_it=false;
               typeless i;
               for( i._makeempty();;) {
                  NamespaceHashtab._nextel(i);
                  if( i._isempty() ) break;
                  if( strieq(urlns,NamespaceHashtab:[i]) ) {
                     // Replace uri with real schema location
                     _str olduri=NamespaceHashtab:[i];
                     NamespaceHashtab:[i]=uri;
                     NamespaceHashtab2._deleteel(olduri);
                     NamespaceHashtab2:[uri]=i;
                     found_it=true;
                     break;
                  }
               }
               if( !found_it ) {
                  // Fall back to old method of making it the default namespace
                  // for elements without a prefix.
                  NamespaceHashtab:['']=uri;
                  NamespaceHashtab2:[uri]='';
               }
            } while( value!="" );
         } else {
            NamespaceHashtab:[prefix]=value;
            NamespaceHashtab2:[value]=prefix;
         }
      } else if (length(AttrName)>24 && strieq(substr(AttrName,length(AttrName)-24),"noNamespaceSchemaLocation")) {
         NamespaceHashtab:['']=value;
         NamespaceHashtab2:[value]='';
      }
   }
   _xml_get_namespaces(handle,LastIndex,NamespaceHashtab,NamespaceHashtab2);
}

#define XSL_NAMESPACE      'http://www.w3.org/1999/XSL/Transform'
#define XHTML_NAMESPACE    'http://www.w3.org/1999/xhtml'
/**
 *  
 *  
 * @param NamespaceHashtab
 */
void _xml_get_current_namespaces(_str (&NamespaceHashtab):[])
{
   NamespaceHashtab._makeempty();
   save_pos(auto p2);
   typeless status=search('[<>]','rh@-xcs');
   if (status) {
      return;
   }
   right();

   typeless EndRealSeekPos=_QROffset();
   restore_pos(p2);

   // We might be able to use def_update_context_max_file_size instead
   if (EndRealSeekPos>def_xml_max_smart_editing) {
      return;
   }

   //Open just up through the root tag
   typeless handle=_xmlcfg_open_from_buffer(p_window_id,status,VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR,0,EndRealSeekPos);
   if (handle<0) {
      return;
   }

   _str NamespaceHashtab2:[];
   _xml_get_namespaces(handle,TREE_ROOT_INDEX,NamespaceHashtab,NamespaceHashtab2);

   // Add the XHTML to namespace list if the XSL namespace is present and XHTML is not.
   // Could check if document not is XSL stylesheet tag but I think is overkill.
   if (NamespaceHashtab2._indexin(XSL_NAMESPACE)) {
      prefix := NamespaceHashtab2:[XSL_NAMESPACE];

      doctype_system := '';
      output_index := _xmlcfg_find_simple(handle,'/'prefix:+':stylesheet/'prefix':output');
      if (output_index >= 0) {
         doctype_system = _xmlcfg_get_attribute(handle, output_index, 'doctype-system');
      }

      if (doctype_system == '' && !NamespaceHashtab2._indexin(XHTML_NAMESPACE)) {
         NamespaceHashtab:[''] = XHTML_NAMESPACE;
      } 
   }

   // if it's empty, just add these
   if (NamespaceHashtab._isempty()) {
      _str ext=_get_extension(p_buf_name);
      if (file_eq(ext,'xsl')) {
         NamespaceHashtab:['xsl']=XMLNAMESPACE_XSL;
         NamespaceHashtab:['']=XMLNAMESPACE_XHTML;
      }

   }

   _xmlcfg_close(handle);
}

static boolean namespacesExistsForDifferentYear(_str &most_recent_file,_str add_path,_str root)
{
   //  Check for a different year    "yyyy/lastname"
   _str temp=_strip_filename(substr(add_path,1,length(add_path)-1),'N');
   //say('h1 temp='temp);
   if (temp=='') {
      return(false);
   }
   _str year=_strip_filename(substr(temp,1,length(temp)-1),'P');
   //say('h2 year='year);
   if (!isinteger(year) || length(year)!=4) {
      return(false);
   }
   temp=root:+_strip_filename(substr(temp,1,length(temp)-1),'N'):+'*';
   _str file=file_match2(temp,1,'-p');
   int most_recent_year=0;
   most_recent_file='';
   for (;;) {
      if (file=='') {
         break;
      }
      if (last_char(file)==FILESEP) {
         typeless temp2=_strip_filename(substr(file,1,length(file)-1),'P');
         // IF this looks like a year
         if (isinteger(temp2) && length(temp2)==4 && year!=temp2 &&
             temp2>most_recent_year) {
            file=root:+stranslate(add_path,FILESEP:+temp2:+FILESEP,FILESEP:+year:+FILESEP):+'tags.vtg';
            //say('try 'file);
            if (file_exists(file)) {
               most_recent_year=temp2;
               most_recent_file=file;
            }
         }


      }
      file=file_match2(temp,0,'-p');
   }
   //say('most_recent_file='most_recent_file);
   if (most_recent_file=='') {
      return(false);
   }
   return(true);
}
int _xml_NamespaceToTagFile(_str &tag_filename, _str xml_namespace)
{
   _str root=get_env('VSROOT'):+'XMLNamespaces':+FILESEP;
   _str add_path="";
   parse xml_namespace with 'http://' add_path;
   if (add_path=='') return(1);
   add_path=translate(add_path,FILESEP,'/');
   _maybe_append_filesep(add_path);
   tag_filename=root:+add_path:+'tags.vtg';
   //say('tf='tag_filename);
   int status=tag_read_db(tag_filename);
   if (status < 0) {
      if(namespacesExistsForDifferentYear(tag_filename,add_path,root)) {
         status=tag_read_db(tag_filename);
      }
   }
   // does the namespace match the XSD tag file namespace?  Then use it.
   //say("_xml_NamespaceToTagFile: namespace="xml_namespace);
   //say("_xml_NamespaceToTagFile: cfgnamespace="_xml_GetConfigNamespace());
   _str config_ns=_xml_GetConfigNamespace();
   _str xsi_ns='';
   parse config_ns with config_ns ';' xsi_ns;
   if (status < 0 && xml_namespace==config_ns) {
      tag_filename=_xml_GetConfigTagFile();
      if (tag_filename!='') {
         status=tag_read_db(tag_filename);
      }
   }
   return(status);
}

void _xml_insert_namespace_context_tags( _str NamespaceHashtab:[],
                                         _str lastid,_str lastid_prefix,
                                         boolean is_attrib,_str clip_prefix, 
                                         int start_or_end,
                                         int &num_matches, int max_matches,
                                         boolean exact_match=false,
                                         boolean insertTagDatabaseNames=false
                                        )
{
   _str only_prefix=null;
   int i=pos(':',lastid_prefix);
   if (i) {
      only_prefix=substr(lastid_prefix,1,i-1);
   }
   typeless prefix;
   for (prefix._makeempty();;) {
       NamespaceHashtab._nextel(prefix);
       if (prefix._isempty()) break;
       //say('prefix='prefix);
       if (only_prefix!=null && prefix!=only_prefix) {
          continue;
       }
       //say("xml_namespace="NamespaceHashtab:[prefix]);
       _str tag_filename='';
       if(_xml_NamespaceToTagFile(tag_filename, NamespaceHashtab:[prefix]) < 0) {
          continue;
       }

       _str orig_tag_name='';
       _str file_name='';
       _str class_name='';
       int line_no=0;
       int tag_flags=0;
       typeless tag_type='';

       typeless status=tag_find_global(VS_TAGTYPE_tag,0,0);
       for (;!status;) {
          tag_get_info(orig_tag_name,tag_type,file_name,line_no,class_name,tag_flags);
          _str tag_name=orig_tag_name;
          tag_get_detail(VS_TAGDETAIL_type_id, tag_type);
          //tag_get_detail(VS_TAGDETAIL_arguments,
          //say("_xml_insert_namespace_context_tags: tag_name="tag_name" prefix="prefix);
          i=pos(':',tag_name);
          if (i) {
             tag_name=substr(tag_name,i+1);
          }
          if (prefix!='') {
             tag_name=prefix:+':':+tag_name;
          }
          if (exact_match && tag_name!=lastid_prefix) {
             status=tag_next_global(VS_TAGTYPE_tag,0,0);
             continue;
          }
          _str temp_prefix=lastid_prefix;
          if (insertTagDatabaseNames) {
             tag_name=orig_tag_name;
             temp_prefix=tag_name;
          }
          HTML_INSERT_TAG_ARGS args;
          args.file_name=file_name;
          args.line_no=line_no;
          args.class_name=class_name;
          args.tag_flags=tag_flags;
          args.signature='';
          if (start_or_end==0) {
             _html_insert_context_tag_item(
                tag_name,
                lastid,false,'', start_or_end,
                num_matches, max_matches,
                false,true,
                tag_filename,tag_type,&args
                );

          } else if (!(tag_flags& VS_TAGFLAG_final)) {
             _html_insert_context_tag_item(
                /*"/"*/tag_name,
                lastid,false,'', 0,
                num_matches, max_matches,
                false,true,
                tag_filename,tag_type,&args
                );
          }
          if (exact_match) {
             break;
          }
          status=tag_next_global(VS_TAGTYPE_tag,0,0);
       }
       tag_reset_find_in_class();
   }
}
void _xml_insert_namespace_context_tags_attrs(_str NamespaceHashtab:[],
                                              int treewid,int tree_index,int pic_index,
                                              _str lastid,_str lastid_prefix,_str match_tag_name,
                                              boolean is_attrib,_str clip_prefix, 
                                              int &num_matches, int max_matches,
                                              int start_or_end=0,boolean exact_match=false,
                                              VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   _str only_prefix='';
   int i=pos(':',match_tag_name);
   _str suffix=match_tag_name;
   if (i) {
      only_prefix=substr(match_tag_name,1,i-1);
      suffix=substr(match_tag_name,i+1);
   }

   _str tag_filename="";
   _str tag_name="";
   _str tag_type="";
   _str file_name="";
   _str class_name="";
   int line_no=0;
   int tag_flags=0;

   typeless prefix;
   for (prefix._makeempty();;) {
       NamespaceHashtab._nextel(prefix);
       if (prefix._isempty()) break;
       if (prefix!=only_prefix) {
          continue;
       }
       if(_xml_NamespaceToTagFile(tag_filename, NamespaceHashtab:[prefix]) < 0) {
          continue;
       }

       _str this_prefix='';
       typeless status=tag_find_global(VS_TAGTYPE_tag,0,0);
       if (!status) {
          tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
          i=pos(':',tag_name);
          if (i) {
             this_prefix=substr(tag_name,1,i-1);
          }
       }
       //say('this_prefix='this_prefix);
       if (this_prefix=='') {
          tag_name=suffix;
       } else {
          tag_name=this_prefix':'suffix;
       }
       _str tagfile_list[];
       tagfile_list[0]=tag_filename;
       tag_list_in_class(lastid_prefix, tag_name,
                         treewid, tree_index, tagfile_list,
                         num_matches, max_matches,
                         VS_TAGFILTER_VAR,VS_TAGCONTEXT_ONLY_inclass,
                         false, false, null, null, visited);
       //say('tag_name='tag_name);
#if 0
       status=tag_find_in_class(tag_name);
       //say('status='status);
       _str attr_name="";
       _str attr_list='';
       for (;!status;) {
          tag_get_info(attr_name,tag_type,file_name,line_no,class_name,tag_flags);
          //say('attr_name='attr_name' rc='num_matches);
          _html_insert_context_tag_item(
             attr_name,
             treewid,tree_index,pic_index,
             lastid,'',true,'',num_matches);
          status=tag_next_in_class();
       }
#endif

      tag_reset_find_in_class();
   }
}
void _xml_insert_namespace_context_tags_attr_values(
   _str NamespaceHashtab:[],
   int treewid,int tree_index,int pic_index,
   _str lastid,_str lastid_prefix,_str match_tag_name,
   _str match_attr_name,
   boolean is_attrib,_str clip_prefix, 
   int &num_matches, int max_matches,
   int start_or_end=0,boolean exact_match=false,
   VS_TAG_RETURN_TYPE (&visited):[]=null)
{
   _str only_prefix='';
   int i=pos(':',match_tag_name);
   _str suffix=match_tag_name;
   if (i) {
      only_prefix=substr(match_tag_name,1,i-1);
      suffix=substr(match_tag_name,i+1);
   }

   _str tag_filename="";
   _str tag_name="";
   _str tag_type="";
   _str file_name="";
   _str class_name="";
   int line_no=0;
   int tag_flags=0;

   typeless prefix;
   for (prefix._makeempty();;) {
       NamespaceHashtab._nextel(prefix);
       if (prefix._isempty()) break;
       if (prefix!=only_prefix) {
          continue;
       }
       if(_xml_NamespaceToTagFile(tag_filename, NamespaceHashtab:[prefix]) < 0) {
          continue;
       }
       _str this_prefix='';
       int status=tag_find_global(VS_TAGTYPE_tag,0,0);
       if (!status) {
          tag_get_info(tag_name,tag_type,file_name,line_no,class_name,tag_flags);
          i=pos(':',tag_name);
          if (i) {
             this_prefix=substr(tag_name,1,i-1);
          }
       }
       //say('this_prefix='this_prefix);
       if (this_prefix=='') {
          tag_name=suffix;
       } else {
          tag_name=this_prefix':'suffix;
       }
       //say(tag_name':'match_attr_name);
       //say('lastid_prefix='lastid_prefix);
       _str tagfile_list[];
       tagfile_list[0]=tag_filename;
       tag_list_in_class(lastid_prefix, tag_name':'match_attr_name,
                         treewid, tree_index, tagfile_list,
                         num_matches, max_matches,
                         VS_TAGFILTER_ENUM,VS_TAGCONTEXT_ONLY_inclass,
                         exact_match, true, null, null, visited);
       //say('tag_name='tag_name);
#if 0
       status=tag_find_in_class(tag_name);
       //say('status='status);
       _str attr_name='';
       _str attr_list='';
       for (;!status;) {
          tag_get_info(attr_name,tag_type,file_name,line_no,class_name,tag_flags);
          //say('attr_name='attr_name' rc='num_matches);
          _html_insert_context_tag_item(
             attr_name,
             treewid,tree_index,pic_index,
             lastid,'',true,'',num_matches);
          status=tag_next_in_class();
       }
#endif

      tag_reset_find_in_class();
   }
}

defeventtab _urlmappings_form;

#define URLMAPPINGS_MODIFIED ctlok.p_user

#region Options Dialog Helper Functions

void _urlmappings_form_init_for_options()
{
   ctlok.p_visible = false;
   ctlcancel.p_visible = false;

   // hide help section on top
   ctllabel1.p_visible = false;
   heightDiff := ctltree1.p_y - ctllabel1.p_y;
   ctltree1.p_y = ctllabel1.p_y;
   ctltree1.p_height += heightDiff;
   ctladd.p_y -= heightDiff;
   ctledit.p_y -= heightDiff;
   ctldelete.p_y -= heightDiff;
}

void _urlmappings_form_save_settings()
{
   URLMAPPINGS_MODIFIED = 0;
}

boolean _urlmappings_form_is_modified()
{
   return (URLMAPPINGS_MODIFIED != 0 || 
           def_url_mapping_search_directory != ctl_UM_defaultSearchDir_text.p_text);
}

boolean _urlmappings_form_apply()
{
   if (ctltree1.okURLMappings()) {
      return false;
   }
   return true;
}

_str _urlmappings_form_build_export_summary(PropertySheetItem (&summary)[])
{
   error := '';
   
   // first the easy part
   PropertySheetItem psi;
   psi.Caption = 'Default search directory';
   psi.Value = def_url_mapping_search_directory;
   summary[0] = psi;

   // this is a bit trickier...
   typeless handle=_cfg_get_useroptions();
   if (handle<0) {
      error = 'Could not load URL Mappings';
   } else {
      int urlmappings_index=_xmlcfg_find_simple(handle,"/Options/URLMappings");
      if (urlmappings_index>=0) {
         int index=_xmlcfg_get_first_child(handle,urlmappings_index);
         while (index>=0) {
            
            psi.Caption = _xmlcfg_get_attribute(handle,index,"From");         
            psi.Value = _xmlcfg_get_attribute(handle,index,"To");         
            summary[summary._length()] = psi;
      
            index=_xmlcfg_get_next_sibling(handle,index);
         }
      }
   }
   
   return error;
}

_str _urlmappings_form_import_summary(PropertySheetItem (&summary)[])
{
   error := '';
   
   handle := _cfg_get_useroptions();
   urlmappings_index := _xmlcfg_find_simple(handle,"/Options/URLMappings");

   if (urlmappings_index < 0) {
      urlmappings_index = _xmlcfg_set_path(handle,"/Options/URLMappings");
   }

   if (urlmappings_index >= 0) {
   
      foreach (auto psi in summary) {
         
         if (psi.Caption == 'Default search directory') {
            // this might be coming from another operating system, so we 
            // will try flipping the fileseps
            psi.Value = stranslate(psi.Value, FILESEP, FILESEP2);

            // make sure it exists...
            if (psi.Value == '' || file_exists(psi.Value)) {
               def_url_mapping_search_directory = psi.Value;
            } else {
               error :+= psi.Value' does not exist.'OPTIONS_ERROR_DELIMITER;
            }
         } else {
            // this is a mapping...
            psi.Value = stranslate(psi.Value, FILESEP, FILESEP2);

            // check for duplicates...
            xml_index := _xmlcfg_find_simple(handle, "//MapURL[@From='"psi.Caption"']", urlmappings_index);
            if (xml_index < 0) {
               // no duplicate, so just add a new one
               xml_index = _xmlcfg_add(handle, urlmappings_index,"MapURL", VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
               _xmlcfg_set_attribute(handle, xml_index, "From", psi.Caption);
            }
            _xmlcfg_set_attribute(handle, xml_index, "To", psi.Value);
         }
      }

      if (_cfg_save_useroptions()) error :+= 'Error saving URL Mappings.'OPTIONS_ERROR_DELIMITER;
   } 
   
   return error;   
}

#endregion Options Dialog Helper Functions

void ctladd.lbutton_up()
{
   status := textBoxDialog("New URL Mapping",
                           0,
                           0,
                           "URL Mapping Options",
                           "",
                           "",
                           "From", "To");

   // user cancelled
   if (status == COMMAND_CANCELLED_RC) return;

   // get the results, add them to the tree
   ctltree1._TreeAddItem(TREE_ROOT_INDEX,
                         _param1"\t"_param2,
                         TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

   URLMAPPINGS_MODIFIED = 1;
}

void ctledit.lbutton_up()
{
   index := ctltree1._TreeCurIndex();
   if (index <= 0) return;

   // get the line we want to edit
   parse ctltree1._TreeGetCaption(index) with auto from auto to;

   status := textBoxDialog("New URL Mapping",
                           0,
                           0,
                           "URL Mapping Options",
                           "",
                           "",
                           "From:"from, "To:"to);

   // user cancelled
   if (status == COMMAND_CANCELLED_RC) return;

   // get the results, add them to the tree
   ctltree1._TreeSetCaption(index, _param1"\t"_param2);

   URLMAPPINGS_MODIFIED = 1;
}

void ctlok.on_create(_str new_item=null)
{
   _urlmappings_form_initial_alignment();

   ctl_UM_defaultSearchDir_text.p_text = def_url_mapping_search_directory;
   int list_width=_dx2lx(SM_TWIP,ctltree1.p_client_width intdiv 2);
   int wid=p_window_id;
   p_window_id=ctltree1;
   _TreeSetColButtonInfo(0,list_width,0,0,"From");
   _TreeSetColButtonInfo(1,MAXINT,0,0,"To");
   p_window_id=wid;

   // disable at first because there is nothing in the tree
   ctledit.p_enabled = ctldelete.p_enabled = false;

   typeless handle=_cfg_get_useroptions();
   if (handle<0) {
      p_active_form._delete_window('');
      return;
   }
   boolean found=false;
   int urlmappings_index=_xmlcfg_find_simple(handle,"/Options/URLMappings");
   if (urlmappings_index>=0) {
      int index=_xmlcfg_get_first_child(handle,urlmappings_index);
      while (index>=0) {
         ctltree1._TreeAddItem(TREE_ROOT_INDEX,
                               _xmlcfg_get_attribute(handle,index,"From")"\t"_xmlcfg_get_attribute(handle,index,"To"),
                               TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
         if (new_item!=null && _xmlcfg_get_attribute(handle,index,"From")==new_item) {
            found=true;
         }

         index=_xmlcfg_get_next_sibling(handle,index);
      }
   }
   if (!found && new_item!=null) {
      ctltree1._TreeAddItem(TREE_ROOT_INDEX,
                            new_item"\t",
                            TREE_ADD_AS_CHILD);
   }

   ctltree1._TreeRetrieveColButtonWidths();
}
void ctlok.lbutton_up()
{
   if (_urlmappings_form_apply()) {
      p_active_form._delete_window(0);
   } else {
      return;
   }

}
void ctlok.on_destroy()
{
   ctltree1._TreeAppendColButtonWidths();
}

static boolean okURLMappings()
{
   _str list = '';
   typeless handle=_cfg_get_useroptions();
   def_url_mapping_search_directory = ctl_UM_defaultSearchDir_text.p_text;

   int urlmappings_index=_xmlcfg_find_simple(handle,"/Options/URLMappings");
   if (urlmappings_index>=0) {
      _xmlcfg_delete(handle,urlmappings_index);
   }
   if(_TreeGetNumChildren(TREE_ROOT_INDEX) > 0) {
      int addafter_index= -1;
      int index = _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for(; index >= 0; ) {
         // get the caption and skip the node reserved for new entry
         _str From="", To="";
         parse _TreeGetCaption(index) with From"\t"To;
         if (From=='' || To=='') {
            _message_box('From or To field can not be blank');
            _TreeSetCurIndex(index);
            return(true);
         }
         int xml_index=0;
         if (addafter_index>=0) {
            xml_index=_xmlcfg_add(handle,addafter_index,"MapURL",VSXMLCFG_NODE_ELEMENT_START_END,0);
         } else {
            addafter_index=xml_index=_xmlcfg_set_path(handle,"/Options/URLMappings/MapURL");
         }
         _xmlcfg_set_attribute(handle,xml_index,"From",From);
         _xmlcfg_set_attribute(handle,xml_index,"To",To);

         // move to next node
         index=_TreeGetNextSiblingIndex(index);
      }
   }
   _cfg_save_useroptions();
   return(false);
}

int ctltree1.on_change(int reason, int index, int column=-1, _str &caption="")
{
   switch (reason) {
   case CHANGE_SELECTED:
      // only have this enabled if there is something worth deleting
      ctledit.p_enabled = ctldelete.p_enabled = (_TreeCurIndex() > 0);
      break;
   }

   return 0;
}

static void doDelete()
{
   // with single node selection, if there is a current index, it is selected
   index := _TreeCurIndex();

   _TreeDelete(index);
   
   // set that we did modify
   URLMAPPINGS_MODIFIED = 1;

}

void ctltree1.'DEL'()
{
   ctltree1.doDelete();
}

void ctldelete.lbutton_up()
{
   ctltree1.doDelete();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _urlmappings_form_initial_alignment()
{
   // size the buttons to the textbox
   rightAlign := p_active_form.p_width - ctltree1.p_x;
   sizeBrowseButtonToTextBox(ctl_UM_defaultSearchDir_text, ctl_UM_browseSearchDirectory_button.p_window_id,
                             0, rightAlign);

   ctledit.p_auto_size = false;
   ctledit.p_width = ctladd.p_width;
   alignUpDownListButtons(ctltree1, rightAlign, ctladd, ctledit, ctldelete);
}

#define BETWEEN_TREE_AND_BUTTONS 100
#define BETWEEN_BUTTONS_AND_BOTTOM 50
void _urlmappings_form.on_resize()
{
   padding := ctltree1.p_x;

   widthDiff := p_width - (ctladd.p_x + ctladd.p_width + padding);
   heightDiff := p_height - (ctl_UM_defaultSearchDir_text.p_y + ctl_UM_defaultSearchDir_text.p_height + padding);

   ctltree1.p_width += widthDiff;
   ctltree1.p_height += heightDiff;

   ctl_UM_defaultSearchDir_text.p_width += widthDiff;
   ctl_UM_browseSearchDirectory_button.p_x += widthDiff;
   ctlok.p_y += heightDiff;
   ctlcancel.p_y=ctlok.p_y;
   ctllabel1.p_width += widthDiff;
   ctladd.p_x += widthDiff;
   ctldelete.p_x = ctledit.p_x = ctladd.p_x;

   ctl_UM_defaultSearchDirectoy_label.p_y += heightDiff;
   ctl_UM_defaultSearchDir_text.p_y += heightDiff;
   ctl_UM_browseSearchDirectory_button.p_y += heightDiff;

   // resize tree columns to 50/50
   width := ctltree1.p_width intdiv 2;
   ctltree1._TreeSetColButtonInfo(0, width);
   ctltree1._TreeSetColButtonInfo(1, width);
}

static void setDirectoryPathText()
{
   int wid=p_window_id;
   _str result = _ChooseDirDialog('',p_prev.p_text);
   if( result=='' ) {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=result;
   end_line();
   _set_focus();
}
void ctl_UM_browseSearchDirectory_button.lbutton_up()
{
   setDirectoryPathText();
}

defeventtab _dtd_open_error_form;
void ctlproxysettings.lbutton_up()
{
   thisForm := p_active_form;
   config('_url_proxy_form', 'D');
   thisForm._delete_window();
}
void ctlURLMappings.lbutton_up()
{
   thisForm := p_active_form;
   config('_urlmappings_form', 'D', ctlURLMappings.p_user);
   thisForm._delete_window();
}
void ctlURLMappings.on_create(int status=FILE_NOT_FOUND_RC,_str local_dtd_filename='dtd-filename',_str buf_name='buf_name',_str info='')
{
   ctllabel1.p_caption = _mapxml_http_load_error_message(status,local_dtd_filename,buf_name):+ "\n\n" :+ info;
   ctlURLMappings.p_user=_SlickEditToUrl(local_dtd_filename);
}
/**
 * Opens the file, specified by the given URL filename, for viewing.
 * 
 * @return Returns 0 if successful. 
 * 
 * @param URLFilename URL filename to open. Currently, only URLs specified with
 *                    the HTTP protocol are supported.
 * @see goto_url
 * @see open_url_in_assoc_app
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */ 
_command int open_url(_str URLFilename='') name_info(','VSARG2_REQUIRES_MDI)
{
   _str result = URLFilename;
   _macro_delete_line();
   _str options='';
   if (result=='') {
      _param1=1;
      _param2=0;
      result=show('-modal _openurl_form');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      if (_param1) {
         options=' +cache ';
      } else {
         options=' -cache';
      }
      if (_param2) {
         options=options:+' +header ';
      } else {
         options=options:+' -header ';
      }
   } else {
      result=strip_options(result,options,true);
      if (options!='') options=options:+' ';
   }
   if (!_isHTTPFile(result)) {
      _str protocol="", rest="";
      parse result with protocol '://' +0 rest;
      if (rest!='') {
         _message_box('Only HTTP transfers are supported');
         return(1);
      }
      result='http://'result;
   }
   result=maybe_quote_filename(result);
   _macro('m',_macro('s'));
   _macro_append('edit('_quote(options:+result)','_quote('EDIT_DEFAULT_FLAGS'));
   int status=edit(options:+result,EDIT_DEFAULT_FLAGS);
   return(status);
}

/**
 * Holds a list of space-separated URI scheme names. 
 *  
 * Note: Use just the names, don't include '://' 
 *  
 * @default "file ftp http https" 
 * @categories Configuration_Variables 
 */
_str def_uri_scheme_list='file ftp http https';
boolean def_url_support=true;

defeventtab _uri_schemes_form;

void _uri_schemes_form_init_for_options ()
{
   _str schemes[];
   _str scheme;
   _str schemeList = def_uri_scheme_list;
   while (schemeList != '') {
      parse schemeList with scheme ' ' schemeList;
      schemes[schemes._length()] = scheme;
   }

   _uri_items._lbclear();

   int i;
   for (i = 0; i < schemes._length(); ++i) {
      _uri_items._lbadd_item(schemes[i]);
   }

   _uri_items._lbtop();
   _uri_items.p_text = _uri_items._lbget_text();
   _uri_items._lbselect_line();
}


void _uri_schemes_form_save_settings ()
{
   _SetDialogInfoHt('modified', false, _uri_items);
}


void _uri_schemes_form_apply ()
{
   change_URI_schemes();
}


boolean _uri_schemes_form_is_modified ()
{
   if (_GetDialogInfoHt('modified', _uri_items)) {
      return true;
   }
   return false;
}

#endregion


void change_URI_schemes ()
{
   _str newSchemes = '';
   _uri_items._lbsort();
   _uri_items._lbtop();
   _uri_items._lbup();
   while (!_uri_items._lbdown()) {
      newSchemes = newSchemes' '_uri_items._lbget_text();
   }
   newSchemes = strip(newSchemes);
   def_uri_scheme_list = newSchemes;
}

void _ctl_add.lbutton_up ()
{
   typeless newURIScheme = 0;

   newURIScheme = show('-modal _newURI_form');

   if (newURIScheme == '') {
      return;
   }

   _uri_items._lbadd_item(newURIScheme);
   _uri_items._lbsort();
   _uri_items._lbtop();
   _uri_items._lbfind_and_select_item(newURIScheme);
   _SetDialogInfoHt('modified', true, _uri_items);
}


void _ctl_delete.lbutton_up ()
{
   if (_uri_items._lbget_text() != '') {
      _SetDialogInfoHt('modified', true, _uri_items);
   }
   _uri_items._lbdelete_item();
   _uri_items.p_text = _uri_items._lbget_text();
   _uri_items._lbselect_line();
}


defeventtab _newURI_form;


_ok.lbutton_up ()
{
   boolean problems = false;
   _str URIscheme = ctl_URIscheme.p_text;

   int badChars;
   badChars = pos(' ', URIscheme);
   if (badChars) {
      URIscheme = substr(URIscheme, 1, badChars-1);
      ctl_URIscheme.p_text = URIscheme;
      problems = true;
   }

   badChars = pos('://', URIscheme);
   if (badChars) {
      URIscheme = substr(URIscheme, 1, badChars-1);
      ctl_URIscheme.p_text = URIscheme;
      problems = true;
   }

   if (!problems) {
      p_active_form._delete_window(URIscheme);
   }
}


_cancel.lbutton_up ()
{
   p_active_form._delete_window('');
}

defeventtab _openurl_form;
void ctlcombo1.on_change(int reason)
{
   boolean enabled= p_text!='';
   if (enabled!=ctlok.p_enabled) {
      ctlok.p_enabled=enabled;
   }

}
void ctlok.on_create()
{
   ctlok.p_enabled=false;
   ctlcombo1._retrieve_list();
   ctlusecache.p_value=0;
   _retrieve_prev_form();
   ctlincludeheader.call_event(ctlincludeheader,LBUTTON_UP,'W');
   ctlcombo1.call_event(CHANGE_OTHER,ctlcombo1,ON_CHANGE,'W');
}
void ctlincludeheader.lbutton_up()
{
   // Including the header means we want the status and headers from the
   // server, so do not use cache setting.
   ctlusecache.p_enabled= (p_value==0);
}
void ctlok.lbutton_up()
{
   typeless result=translate(ctlcombo1.p_text,'/','\');
   if (!_isHTTPFile(result)) {
      _str protocol="", rest="";
      parse result with protocol '://' +0 rest;
      if (rest!='') {
         _message_box('Only HTTP transfers are supported');
         return;
      }
      result='http://'result;
   }
   // Can only use cache if we are not including the header from the server
   _param1= (ctlusecache.p_value && ctlincludeheader.p_value==0);
   _param2=ctlincludeheader.p_value;
   ctlcombo1._append_retrieve(ctlcombo1,ctlcombo1.p_text);
   _save_form_response();
   p_active_form._delete_window(result);
}






/**
 * Display a string in the XML Output tab
 *
 * @param str Message to display
 * @param highlight non zero if the line should be highlighted
 *
 */
void _xml_display_output(_str str, boolean highlight = false)
{
   bottom();
   str = strip(str, 'T', "\n\r");
   insert_line(str);
   if (highlight) {
      p_col=1;_SetTextColor(CFG_FILENAME,_line_length(),false);

   }
}


boolean isXMLErrorLine()
{
   _str line, rest;
   get_line(line);
   parse line with line rest;
   if (lowcase(line)=='file' || lowcase(line)=='document') {
      return false;
   }
   _str linetype='';
   parse rest with line linetype rest;
   if (lowcase(linetype)=="error") {
      return true;
   }
   return false;
}

int xmlMoveToError(boolean next = true)
{
   int formwid=_find_formobj('_tboutputwin_form','N');
   _nocheck _control ctloutput;
   if (!formwid) {
      formwid=activate_toolbar("_tboutputwin_form","");
      if (!formwid) return -1;
      formwid.ctloutput._delete_line();
   }
   if (!formwid) return -1;
   int wid=p_window_id;
   p_window_id=formwid.ctloutput;
   if (next) {
      rc = down();
      while (rc != BOTTOM_OF_FILE_RC && !isXMLErrorLine()) {
         rc = down();
      }

      if (rc == BOTTOM_OF_FILE_RC) {
         p_window_id=wid;
         wid._set_focus();
         return 1;
      }

   } else {
      rc = up();
      while (rc != TOP_OF_FILE_RC && !isXMLErrorLine()) {
         rc = up();
      }
      if (rc == TOP_OF_FILE_RC) {
         p_window_id=wid;
         wid._set_focus();
         return 1;
      }
   }
   // Now simulate a double click or enter and let the
   // normal behavior take over
   call_event(p_window_id, LBUTTON_DOUBLE_CLICK,'W');
   return 0;
}


int _switch_to_xml_output(boolean clear = false)
{
   int formwid=_find_formobj('_tboutputwin_form','N');
    _nocheck _control ctloutput;
    if (!formwid) {
       formwid=activate_toolbar("_tboutputwin_form","");
       if (!formwid) return -1;
       formwid.ctloutput._delete_line();
    }
    if (!formwid) return -1;
    int wid=p_window_id;
    p_window_id=formwid.ctloutput;
    if (clear) {
       _lbclear();
    }
    return 0;
}
/**
 * Show the errors (if any) for the specified XML document
 * It is assumed that current window/buffer is the one that
 * corresponds to the XML document handle passed in
 *
 * @param handle the handle to the XML document returned from _xml_openXXX
 *
 * @return 0 if successful, non zero otherwise
 *
 */
int xmlshowErrors(int handle, _str name, int flags, boolean gotoError)
{
   int formwid;
   // RGH - 4/26/2006
   // For the plugin, have to get the right window ID
   if (!isEclipsePlugin()) {
      formwid = activate_toolbar("_tboutputwin_form", "");
   } else {
      formwid = xmlQFormWID();
   }
   if (!formwid) return -1;

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(XML_VALIDATION_MESSAGE_TYPE);

   _nocheck _control ctloutput;
   formwid.ctloutput._delete_line();
   int wid=p_window_id;
   p_window_id=formwid.ctloutput;
   _lbclear();
   int errcnt=_xml_get_num_errors(handle);
   if (errcnt==0) {
      _xml_display_output("File "name, true);
      if (flags != VSXML_VALIDATION_SCHEME_WELLFORMEDNESS) {
         _xml_display_output("    Document is valid");
      } else {
         _xml_display_output("    Document is well-formed");
      }
   } else {
      _str oldfn = "";
      int i;
      int line=0, col=0;
      _str fn="", msg="";
      mCollection->startBatch();
      for (i=0;i<errcnt;i++) {
         _xml_get_error_info(handle, i, line, col, fn, msg);
         if (!(fn :== oldfn)) {
            _xml_display_output("File "fn, true);
         }
         oldfn = fn;
         _xml_display_output("  "line" "col": Error "msg);

         if (i < def_xml_messages_limit) {
            se.messages.Message tmpMsg;
            tmpMsg.m_creator = XML_VALIDATION_MESSAGE_TYPE;
            tmpMsg.m_type = "Error";
            tmpMsg.m_description = msg;
            tmpMsg.m_sourceFile = fn;
            tmpMsg.m_lineNumber = line;
            tmpMsg.m_colNumber = col;
            tmpMsg.m_date = '';
            mCollection->newMessage(tmpMsg);
         }
      }
      mCollection->endBatch();
      mCollection->notifyObservers();

      // Go to first error
      _mfXMLOutputIsActive=true;
      _xml_get_error_info(handle, 0, line, col, fn, msg);
      top();
      if (gotoError == 1) {
         down();
         // RGH - 4/26/2006
         // Set p_window_id to the right control for the plugin
         if (isEclipsePlugin()) {
            p_window_id = formwid._find_control("ctloutput");
         } else {
            p_window_id=wid;
         }
         wid._set_focus();
         int linenum=0, colnum=0;
         _mffindGetDest(fn,linenum,colnum);
         _mffindGoTo(fn,line,col);
         return 0;
      }
   }
   p_window_id=wid;
   wid._set_focus();
   return 0;
}

/**
 * Parse the buffer in the current window and show the errors
 *
 * @param flags Specify if validation should be done or not<P>
 *              The flags include the following:
 *                  <DL>
 *                  <DT>VSXML_VALIDATION_SCHEME_WELLFORMEDNESS</dt><DD>
 *                  When specified, performs a well-formedness check on the
 *                  document.  No validation is done</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_VALIDATE</dt><DD>
 *                  When specified, the document is validated against the
 *                  documents DTD or schema.</DD>
 *                  <DT>VSXML_VALIDATION_SCHEME_AUTO</DT><DD>
 *                  When specified, validates the document if a DTD or schema
 *                  is specified in the XML document.  If neither a DTD or
 *                  schema definition is specified, then a well-formedness
 *                  check is performed.</DD>
 *
 */
void xmlparse(int flags, boolean gotoError = true)
{
   int showErrorFlag = 1;

   mou_hour_glass(1);
   typeless status = 0;
   typeless handle = _xml_open_from_control(p_window_id,status,flags);

   if (status < 0) {
      mou_hour_glass(0);

      _str buffName = _build_buf_name();
      _str dirName = _strip_filename(buffName, 'EN');
      if (status == ACCESS_DENIED_RC) {
         _message_box("Error parsing "buffName"\nUnable to write temporary work file in directory "dirName"\nReason: "get_message(status)"\nVerify space is available and that you have proper permissions.");
         message(get_message(status));
         return;
      } else {
         _message_box(get_message(status));
         return;
      }
   }

   xmlshowErrors(handle, _build_buf_name(), flags, gotoError);
   int errcnt=_xml_get_num_errors(handle);
   if (gotoError) {
      if (errcnt>0) {
         _beep();
         delay(35);
         _beep();
      }
      else {
         _beep();
      }
   }
   _xml_close(handle);
   mou_hour_glass(0);
}

int _OnUpdate_xml_validate(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   _str lang=target_wid.p_LangId;
   return (_LanguageInheritsFrom('xml',lang)? MF_ENABLED:MF_GRAYED);
}

int _OnUpdate_xml_wellformedness(CMDUI &cmdui,int target_wid,_str command)
{
   return _OnUpdate_xml_validate(cmdui, target_wid, command);
}

/**
 * Auto validate the buffer in the current window
 *
 */
_command void xml_validate() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
   xmlparse(VSXML_VALIDATION_SCHEME_VALIDATE);
}

/**
 * Check the well-formedness of the buffer in the current window
 *
 */
_command void xml_wellformedness() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
   xmlparse(VSXML_VALIDATION_SCHEME_WELLFORMEDNESS);
}

_command void xml_validatefile(_str filename="")
{
   _str param = filename;
   if (param=="") {
      param=p_buf_name; // use the name of the current buffer
   }
   typeless status = 0;
   typeless handle = _xml_open(param,status,VSXML_VALIDATION_SCHEME_VALIDATE);
   if (status < 0) {
      message(get_message(status));
      return;
   }
   xmlshowErrors(handle, param, VSXML_VALIDATION_SCHEME_VALIDATE, false);
   _xml_close(handle);
}
/* End XMLCodeReview */


/**
 * Activates XML file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void xml_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('xml');
}

/**
 * Activates XSD file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void xsd_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('xsd');
}

/**
 * Activates XMLDOC file editing mode.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void xmldoc_mode() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage('xmldoc');
}
int _xml_find_matching_word(boolean quiet,int pmatch_max_diff=MAXINT)
{
   if (pmatch_max_diff!=MAXINT) {
      if (p_buf_size>def_xml_max_smart_editing) {
      //if (p_buf_size>pmatch_max_diff) {
         return(-1);
      }
   }
   return(htool_matchtag(quiet));
}

int _ant_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

_str _ant_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0, _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null)
{
   if (info == null) {
      return '';
   }
   _str decl = decl_indent_string;
   if (_get_extension(info.file_name) == 'properties') {
      decl :+= info.member_name:+'='info.return_type;
   } else {
      decl :+= info.return_type;
   }
   return decl;
}

int _ant_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                         _str lastid,int lastidstart_offset,
                         int info_flags,typeless otherinfo,
                         boolean find_parents,int max_matches,
                         boolean exact_match, boolean case_sensitive,
                         int filter_flags=VS_TAGFILTER_ANYTHING,
                         int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                         VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                               info_flags,otherinfo,false,max_matches,
                               exact_match,case_sensitive,
                               filter_flags,context_flags,visited,depth);
}

// UPDATE AUTOMATICALLY INSERTED URL MAPPINGS
static void insertURLMapping(int handle, _str from, _str to)
{
   if (handle < 0) {
      return;
   }
   urlmappings_index := _xmlcfg_find_simple(handle,"/Options/URLMappings");
   if (urlmappings_index < 0) {
      urlmappings_index = _xmlcfg_set_path(handle,"/Options/URLMappings");
   }
   if (urlmappings_index < 0) {
      return;
   }

   // check for duplicates...
   xml_index := _xmlcfg_find_simple(handle, "//MapURL[@From='"from"']", urlmappings_index);
   if (xml_index < 0) {
      // no duplicate, so just add a new one
      xml_index = _xmlcfg_add(handle, urlmappings_index, "MapURL", VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle, xml_index, "From", from);
   }
   if (xml_index > 0) {
      _xmlcfg_set_attribute(handle, xml_index, "To", to);
   }
}

void upgradeURLMappingNames(_str version) {

   int handle = _cfg_get_useroptions();
   if (handle < 0) {
      return;
   }
   int list:[];
   typeless array[];
   _xmlcfg_find_simple_array(handle, "/Options/URLMappings/MapURL", array);
   foreach (auto node in array) {
      from := _xmlcfg_get_attribute(handle, node, 'From');
      if (from != '') {
         list:[from] = node;
      }
   }

   int status = 0;
   _str UpdateVersion = '18.0.1.0'; 
#if __WINDOWS__
   // searching for Microsoft.Build.xsd schema file
   if (_version_compare(UpdateVersion, version) > 0) {
      _str msbuildSchema = 'http://schemas.microsoft.com/developer/msbuild/2003';
      if (!list._indexin(msbuildSchema)) {
         _str schemaFile;
         _str installDir;

         installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '12.0');
         if (installDir == '') {
            installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '11.0');
            if (installDir == '') {
               installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '10.0');
               if (installDir == '') {
                  installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VS7', '', '9.0');
               }
            }
         }

         // check Express installs?


         if (installDir != '') {
            _maybe_append(installDir, FILESEP);
            schemaFile = installDir:+'Xml\Schemas\1033\Microsoft.Build.xsd';
            if (!file_exists(schemaFile)) {
               schemaFile = '';
            }
         }

         if (schemaFile == '') {
            // try framework dir
            installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkDir64');
            if (installDir != '') {
               frameworkVer := _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkVer64');
               if (frameworkVer != '') {
                  _maybe_append(installDir, FILESEP);
                  installDir :+= frameworkVer; _maybe_append(installDir, FILESEP);
                  schemaFile = installDir:+'Microsoft.Build.xsd';
                  if (!file_exists(schemaFile)) {
                     schemaFile = '';
                  }
               }
            }

            if (schemaFile == '') {
               installDir = _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkDir32');
               if (installDir != '') {
                  frameworkVer := _ntRegQueryValue(HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\VisualStudio\SxS\VC7', '', 'FrameworkVer32');
                  if (frameworkVer != '') {
                     _maybe_append(installDir, FILESEP);
                     installDir :+= frameworkVer; _maybe_append(installDir, FILESEP);
                     schemaFile = installDir:+'Microsoft.Build.xsd';
                     if (!file_exists(schemaFile)) {
                        schemaFile = '';
                     }
                  }
               }
            }
         }

         if (schemaFile != '') {
            insertURLMapping(handle, msbuildSchema, schemaFile);
            status = 1;
         }
      }
   }
#endif

   if (status) {
      _cfg_save_useroptions(true);
   }
}

