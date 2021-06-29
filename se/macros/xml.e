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
#import "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "autobracket.e"
#import "backtag.e"
#import "beautifier.e"
#import "c.e"
#import "cfg.e"
#import "cidexpr.e"
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
#import "menu.e"
#import "mfsearch.e"
#import "mprompt.e"
#import "notifications.e"
#import "optionsxml.e"
#import "picture.e"
#import "pmatch.e"
#import "put.e"
#import "recmacro.e"
#import "seek.e"
#import "sellist.e"
#import "seltree.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "se/ui/toolwindow.e"
#import "treeview.e"
#import "url.e"
#import "xmlcfg.e"
#import "xmlwrap.e"
#import "toast.e"
#import "util.e"
#import "vc.e"
#import "sc/lang/ScopedTimeoutGuard.e"
#import "se/messages/Message.e"
#import "se/messages/MessageCollection.e"
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

static _str gBuiltinXMLNamespaces:[] = {
   "docbook"   => "http://docbook.org/ns/docbook",
   "mathml"    => "http://www.w3.org/1998/Math/MathML",
   "xhtml"     => "http://www.w3.org/1999/xhtml",
   "html"      => "http://www.w3.org/1999/xhtml",
   "xsl"       => "http://www.w3.org/1999/XSL/Transform",
   "svg"       => "http://www.w3.org/2000/SVG",
   "xsd"       => "http://www.w3.org/2001/XMLSchema",
};

static const XML_VALIDATION_MESSAGE_TYPE= 'XML Error';

const XML_TAGFILE_CACHE_DIR= "XMLCache";

/**
 * Maximum seek position within an XML document where
 * syntax indent and SmartPaste&reg; will still work.
 * Beyond this point, Enter and paste will work the
 * same as it does in fundamental mode.
 * 
 * @default 125k
 * @categories Configuration_Variables
 */
int def_xml_max_smart_editing_ksize=725;

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


/**
 * Global hash table listing temporary tag files created from previously parsed DTD or Schema files.
 * 
 * @author dbrueni (11/26/18)
 */
static _str _xmlTempTagFileList:[];


int xmlQFormWID()
{
   // RGH - 4/25/06
   // No more XML output form..._tboutputwin_form
   if(isEclipsePlugin()){
      int formwid = _find_formobj(ECLIPSE_OUTPUT_CONTAINERFORM_NAME,'n');
      if (formwid > 0) {
         return formwid.p_child;
      }
      return 0;
   } else {
      int formwid=_find_formobj('_tboutput_form','N');
      _nocheck _control xmlerrorlist;
      _nocheck _control _output_sstab;
      if (!formwid) {
         show_tool_window('_tboutput_form');
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
      show_tool_window('_tboutput_form');
      formwid=_find_formobj('_tboutput_form','N');
      if (!formwid) return;
      formwid._output_sstab.p_ActiveTab = OUTPUTTOOLTAB_XMLOUT;
   }

}
static _str xml_next_sym()
{
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   typeless status=0;
   ch := get_text_safe();
   if (ch=="") {
      status=search('[~ \t]','rh@');
      if (status) {
         gtk=gtkinfo="";
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
         gtk=gtkinfo="";
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
   start_col := p_col;
   search('[ \t=>"'']|$','rh@');
   gtk=TK_ID;
   gtkinfo=_expand_tabsc(start_col,p_col-start_col);
   return(gtk);
}
static int _mapxml_get_doctype_info(_str &maptype,_str &mapid,_str &systemid,_str &doctype,int &markid, bool &istaglib)
{
   mapid="";
   systemid="";
   maptype="";
   doctype="";
   markid= NULL_MARKID;
   istaglib = false;

   save_pos(auto p);
   top();
   typeless status=search('<!DOCTYPE([ \t]|$)','>rh@xcs');
   if (status) {
      restore_pos(p);
      return(status);
   }
   have_inline := false;
   for (;;) {
      xml_next_sym();

      if (gtk==TK_ID && doctype=="") {
         doctype=gtkinfo;
         if(gtkinfo=="taglib") {
            istaglib = true;   
         }
      }

      if (gtk=="" || gtk=='>') {
         break;
      }

      if (gtk==TK_ID) {
         if (gtkinfo=='PUBLIC' || gtkinfo=='SYSTEM') {
            new_maptype := gtkinfo;
            xml_next_sym();
            if (gtk==TK_STRING) {
               mapid=gtkinfo;
               maptype=new_maptype;
               if (maptype=='PUBLIC') {
                  xml_next_sym();
                  if (gtk==TK_STRING) {
                     systemid=gtkinfo;
                     maptype='SYSTEM';
                  }
               } else if (maptype=='SYSTEM') {
                  systemid=mapid;
                  mapid="";
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
bool _UrlEq(_str url1,_str url2)
{
   if (_FILESEP=='\') {
      url1=translate(url1,'/','\');
      url2=translate(url2,'/','\');
   }
   // verify that both URL's are http url's
   url1_http := (lowcase(substr(url1,1,7)) == "http://");
   url2_http := (lowcase(substr(url2,1,7)) == "http://");
   if (url1_http != url2_http) {
      return false;
   }
   // if they are both not http, then assume they are file names
   if (!url1_http && !url2_http) {
      return _file_eq(absolute(url1), absolute(url2));
   }

   path1 := rest1 := "";
   path2 := rest2 := "";
   parse url1 with 'http://','i' path1 '/' rest1;
   parse url2 with 'http://','i' path2 '/' rest2;
   if (!strieq(path1,path2)) {
      return(false);
   }
   return(rest1==rest2);
}
_str _UrlCase(_str url)
{
   if (_FILESEP=='\') {
      url=translate(url,'/','\');
   }
   path1 := rest1 := "";
   parse url with 'http://','i' path1 '/' +0 rest1;
   if (rest1=="") {
      return(lowcase(url));
   }
   return('http://'lowcase(path1):+rest1);
}

static const SLICKEDIT_WEBSITE_PREFIX= 'http://www.slickedit.com/';
static const SLICKEDIT_WEBSITE_LOCAL=  "http/www.slickedit.com/";
_str def_url_mapping_search_directory = "";
static bool _mapurl_found(_str orig_httpfile,_str &new_file)
{
   handle := _cfg_get_useroptions();
   if (handle<0) {
      return(false);
   }

   if (strieq(SLICKEDIT_WEBSITE_PREFIX,substr(orig_httpfile,1,length(SLICKEDIT_WEBSITE_PREFIX)))) {
      // remove http://www.slickedit.com/ and replace it with %VSROOT%toolconfig/http/www.slickedit.com/
      localURL := _getToolConfigPath():+SLICKEDIT_WEBSITE_LOCAL :+ substr(orig_httpfile, length(SLICKEDIT_WEBSITE_PREFIX) + 1);
      localURL = _replace_envvars(localURL);
      localURL = translate(localURL, FILESEP, FILESEP2);
      new_file = absolute(localURL,null,true);
      //say("_mapurl_found H"__LINE__": new_file="new_file" localURL="localURL);
      return true;
   }

   i := 0;
   longest_match_len := 0;
   typeless array[];
   _xmlcfg_find_simple_array(handle,"//p",array);
   for (i=0;i<array._length();++i) {
      _str from=_xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROPERTY_NAME);
      if (_UrlEq(substr(orig_httpfile,1,length(from)),from) && length(from)>longest_match_len) {
         longest_match_len=length(from);
         _str To=_xmlcfg_get_attribute(handle,array[i],VSXMLCFG_PROPERTY_VALUE);
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

   //_str xsl_doctype_system="";
   //_str xsl_prefix="";
   //_str document_tag="";
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
      newname := "";
      foreach (auto orig_namespace in NamespacesHashtab) {
         if (_mapurl_found(orig_namespace, newname)) {
            if (UM_currentNamespaceMappings._length() == 0) {
               UM_currentNamespaceMappings[0] = ' ';
            }
            UM_currentNamespaceMappings[0] :+= ' ' :+ orig_namespace :+ ' ' :+ newname;
         }
      }
      if (UM_currentNamespaceMappings._length()) {
         strip(UM_currentNamespaceMappings[0]);
      }
   }
   restore_pos(p);
   return;
}

static bool gDTDsWarnedAbout:[];
static long ginlineBufSize;
static _str ginlineBufName;
static _str gorigBufName;

int _mapxml_find_system_file(
   _str systemid,
   _str buf_name,_str &local_dtd_filename,
   long seekPos=-1,
   bool &was_mapped=false)
{
   was_mapped=false;
   if (seekPos>=0 && gorigBufName==buf_name && seekPos<ginlineBufSize) {
      buf_name=ginlineBufName;
   }
   local_dtd_filename="";
   if (systemid==null || systemid:=="") {
      return(0);
   }
   systemid=translate(systemid,'/',FILESEP);
   if (substr(systemid,1,6):=="ftp://"
       ) {
      // Don't support ftp
      return(1);
   }
   new_mapid := "";
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
      nonSlash := pos('[~/|\\]',systemid,1,'r');
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
      gDTDsWarnedAbout._makeempty();
      _xmlTempTagFileList._makeempty();
      UM_currentNamespaceMappings._makeempty();
   }
}

static _str _mapxml_http_load_error_message(int status, _str local_dtd_filename, _str buf_name)
{
   if (buf_name=="") {
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

_str _mapxml_http_load_error(_str systemid,
                             bool &was_mapped,
                             int &status,
                             _str &local_dtd_filename,
                             _str buf_name,
                             bool sendToOutputWindow=false,
                             _str mode_name="",
                             bool doForceUpdate=false)
{
   langId := "xml";
   filename := langId;
   if (_isEditorCtl()) {
      langId   = p_LangId;
      filename = p_buf_name;
   }

   // if we have already warned about this DTD in this file, 
   // then let's not do it again.
   if (gDTDsWarnedAbout._indexin(_file_case(filename):+"\t":+local_dtd_filename)) return "";
   gDTDsWarnedAbout:[_file_case(filename):+"\t":+local_dtd_filename] = true;

   if (sendToOutputWindow && !LanguageSettings.getAutoValidateOnOpen(langId)) {
      info := "";
      if (was_mapped) {
         info='This error occurred with a mapped URL.':+"\n":+
              'Use the URL Mappings dialog ("Tools","Options","Network & Internet Options","URL Mappings...") to correct your URL mappings';
      } else {
         info="";
         if (!doForceUpdate && mode_name!="") {
            info="This processing is needed for better color coding and auto completions but can cause delays.\n\n";
            info:+="To turn this feature off, uncheck option for 'Use schema for color coding' at Document>"mode_name" Options...>Color Coding>Language Tab.\n\n";
         }
         info:+='If you want to work off-line, use the URL Mappings dialog ("Tools","Options","Network & Internet Options","URL Mappings...") to':+"\n":+
                'map a URL to a local path containing the files. The local path need not exist if no schema file exists.':+"\n\n":+
                'You may not be able to get HTTP accesss due to your proxy settings.':+"\n":+
                'Use the Proxy Settings dialog ("Tools","Options","Network & Internet Options","Proxy Settings...") to configure your proxy settings.';
      }

      outputMessage := _mapxml_http_load_error_message(status,local_dtd_filename,buf_name);
      _SccDisplayOutput(outputMessage,false,false,true);
      _SccDisplayOutput(info,false,false,true);
   } else {
      //result=show('-modal _dtd_open_error_form',status,local_dtd_filename,buf_name,info);
      alertMsg := _mapxml_http_load_error_alert(status,local_dtd_filename);
      notifyUserOfWarning(ALERT_DTD_LOAD_ERROR, alertMsg, local_dtd_filename, 0);
   }
   return "";
}

/** 
 * @return 
 * Map the given DTD to an internal tag file name stored under the user's 
 * configuration directory.  This tag file is used to cache tagging information 
 * for a remote DTD or Schema so that it does not have to be downloaded and 
 * parsed again the next time it is referenced in another XML document. 
 * This data lives beyond the length of the editor session so that it may be 
 * re-used the next time you start SlickEdit with the same configuration directory. 
 */ 
static _str _mapxml_get_tagfile_for_dtd(_str dtd_filename)
{
   path := _tagfiles_path();
   _maybe_append_filesep(path);
   path :+= XML_TAGFILE_CACHE_DIR;
   if (!isdirectory(path)) {
      mkdir(path);
   }
   _maybe_append_filesep(path);
   path :+= "internal_xml_";
   hashVal := _dec2hex(_string_hash(dtd_filename, true), zeroPadWidth:8);
   path :+= hashVal;
   lastDirName := _strip_filename(dtd_filename, "/N");
   lastDirName = _strip_filename(lastDirName, '/P');
   path :+= "_";
   path :+= lastDirName;
   path :+= "_";
   fileName := _strip_filename(dtd_filename, 'P');
   fileName = stranslate(fileName, '_', ' ');
   path :+= fileName;
   path :+= TAG_FILE_EXT;
   return path;
}

static int _mapxml_create_tagfile(_str maptype,
                                  _str mapid,
                                  _str systemid,
                                  int markid,
                                  _str buf_name, 
                                  _str &tagfile,
                                  _str DocumentName, 
                                  bool doForceUpdate=false,
                                  int depth=0)
{
   if (_chdebug) {
      isay(depth, "_mapxml_create_tagfile H"__LINE__": maptype="maptype);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": mapid="mapid);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": systemid="systemid);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": markid="markid);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": buf_name="buf_name);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": tag_file="tagfile);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": documentName="DocumentName);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": doForceUpdate="doForceUpdate);
   }

   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if (DocumentName=="") DocumentName=buf_name;
   local_dtd_filename := "";
   was_mapped := false;
   status := 0;
   if (maptype=="SYSTEM" && systemid!="") {
      status=_mapxml_find_system_file(systemid,buf_name,local_dtd_filename,-1,was_mapped);
      if (status) {
         status=FILE_NOT_FOUND_RC;
         if (!was_mapped) {
            desc := 'DTD';
            alertMsg := (nls("Error processing %s for file '%s'.\n\nFile '%s' not found", desc, DocumentName,local_dtd_filename));
            notifyUserOfWarning(ALERT_SCHEMA_LOAD_ERROR, alertMsg, local_dtd_filename);
            return(1);
         }
      }
   }

   if (local_dtd_filename=="" && mapid!="") {
      if (maptype == 'SYSTEM' || maptype == 'SCHEMA') {
         status=_mapxml_find_system_file(mapid,buf_name,local_dtd_filename,-1,was_mapped);
         if (status) {
            status=FILE_NOT_FOUND_RC;
            if (!was_mapped) {
               desc := (maptype=='SCHEMA') ? 'schema' : 'DTD';
               alertMsg := (nls("Error processing %s for file '%s'.\n\nFile '%s' not found", desc, DocumentName,local_dtd_filename));
               notifyUserOfWarning(ALERT_SCHEMA_LOAD_ERROR, alertMsg, local_dtd_filename);
               return(1);
            }
         }
      }
   }
   // This if is currently never true due to how _mapxml_init_file2 is written.
   // This allows us to add another option where we process DTD color coding if
   // the file is local (or an internal subset).
   if (!doForceUpdate && !use_schema_for_color_coding(p_LangId) && 
       strieq(substr(local_dtd_filename,1,7),"http:":+_FILESEP:+_FILESEP)) {
      modeName := p_mode_name;
      orig_view_id := p_window_id;
      wid := p_window_id;
      _switch_to_xml_output(true);
      _xml_display_output(nls("Bypassing processing DTD '%s1' for file '%s2' to avoid potential delays.",
                       _SlickEditToUrl(local_dtd_filename),DocumentName,_SlickEditToUrl(local_dtd_filename)));
      _xml_display_output(nls("This processing is needed for better color coding and auto completions."));
      _xml_display_output(nls("To turn this on, check option for 'Use schema for color coding' at Document>"modeName" Options...>Color Coding>Language Tab."));
      top_of_buffer();
      p_window_id = wid;
      wid._set_focus();
      activate_window(orig_view_id);
      return 1;
   }

   default_dtd := "";
   tagfile=_xml_GetConfigTagFile();
   if (!status && local_dtd_filename=="" && markid==NULL_MARKID) {
      default_dtd=_ExtensionGetDefaultDTD(_file_case(_get_extension(buf_name)));
      default_dtd=_replace_envvars(default_dtd);
      if (_file_eq(_get_extension(default_dtd,true),TAG_FILE_EXT)) {
         tagfile=default_dtd;
         return(0);
      }
      local_dtd_filename=default_dtd;
      if (local_dtd_filename=="") {
         // Can't find DTD for this file
         return(1);
      }
   }

   if (_chdebug) {
      isay(depth, "_mapxml_create_tagfile H"__LINE__": local_dtd_filename="local_dtd_filename);
      isay(depth, "_mapxml_create_tagfile H"__LINE__": tagfile="tagfile);
      idump(depth, _xmlTempTagFileList, "_mapxml_create_tagfile H"__LINE__": xmlTempTagFileList");
   }

   // check if this DTD is already tagged and use that tag file
   // instead of opening the file and creating a new tag file
   if (local_dtd_filename != "" && _xmlTempTagFileList._indexin(local_dtd_filename)) {
      // check if the tag file is readable and already built and up-to-date
      tagfile = _xmlTempTagFileList:[local_dtd_filename];
      if (tagfile != "" && tag_read_db(tagfile) >= 0) {
         lastDateTagged := "";
         dateStatus := tag_get_date(local_dtd_filename, lastDateTagged);
         if (!dateStatus && lastDateTagged == _file_date(local_dtd_filename, 'B')) {
            return 0;
         }
      }
   }

   // try again, in case if the DTD isn't in the table yet
   if (local_dtd_filename != "") {
      // check if the tag file is readable and already built and up-to-date
      tagfile = _mapxml_get_tagfile_for_dtd(local_dtd_filename);
      if (tagfile != "" && tag_read_db(tagfile) >= 0) {
         _xmlTempTagFileList:[local_dtd_filename] = tagfile;
         lastDateTagged := "";
         dateStatus := tag_get_date(local_dtd_filename, lastDateTagged);
         if (!dateStatus && lastDateTagged == _file_date(local_dtd_filename, 'B')) {
            return 0;
         }
      }
   }
         
   xhtml_namespace := gBuiltinXMLNamespaces:["xhtml"];
   mode_name := p_mode_name;
   // Build the tag file
   typeless result=0;
   temp_view_id := 0;
   orig_view_id := _create_temp_view(temp_view_id);
   p_UTF8=_UTF8();// _load_option_UTF8(p_buf_name);
   if (status || local_dtd_filename!="") {
      if (!status) {
         // Takes too long to timeout on http://www.w3.org/1999/xhtml. It
         // doesn't seem to be accessible any more.
         // Force quick failure.
         temp:=translate(xhtml_namespace,FILESEP,FILESEP2);
         if (!was_mapped && _file_eq(local_dtd_filename,temp)) {
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            activate_window(orig_view_id);
            result="";
            return(result);
         } else {
            status=get(_maybe_quote_filename(local_dtd_filename),"",'A');
         }
      }
      if (status) {
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         if (!was_mapped && status==FILE_NOT_FOUND_RC && !_isHTTPFile(local_dtd_filename)) {
           // _message_box(nls("Error processing DTD '%s1' for file '%s2'.\n\nFile '%s3' not found",
           //                  _SlickEditToUrl(local_dtd_filename),DocumentName,_SlickEditToUrl(local_dtd_filename)));
            wid := p_window_id;
            _switch_to_xml_output(true);
            _xml_display_output(nls("Error processing DTD '%s1' for file '%s2'.\n\nFile '%s3' not found.",
                             _SlickEditToUrl(local_dtd_filename),DocumentName,_SlickEditToUrl(local_dtd_filename)));
            top_of_buffer();
            p_window_id = wid;
            wid._set_focus();
            activate_window(orig_view_id);
         } else {
            for (;;) {
               result=_mapxml_http_load_error(mapid,was_mapped,status,local_dtd_filename,DocumentName,!doForceUpdate,mode_name,doForceUpdate);
               if (result=="") {
                  activate_window(orig_view_id);
                  return(result);
               }
               if (status) {
                  status=FILE_NOT_FOUND_RC;
               } else {
                  _create_temp_view(temp_view_id);
                  p_UTF8=_UTF8();// _load_option_UTF8(p_buf_name);
                  status=get(local_dtd_filename,"",'A');
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
   ginlineBufSize=0;ginlineBufName="";

   if (markid!=NULL_MARKID) {
      top();up();
      Noflinesb4 := p_Noflines;
      insert_line("");
      _copy_to_cursor(markid);
      p_line=p_Noflines-Noflinesb4+1;
      p_col=1;
      ginlineBufSize=_QROffset();
      ginlineBufName=buf_name;
      p_buf_name=buf_name;
   }
   if (p_buf_name=="") {
      p_buf_name=_strip_filename(buf_name,'e')'.dtd';
   }
   gorigBufName=p_buf_name;

   // check if this DTD is already tagged and use that tag file
   // instead of creating a new tag file
   if (tagfile=="" && _xmlTempTagFileList._indexin(p_buf_name)) {
      // check if the tag file is readable and already built and up-to-date
      tagfile = _xmlTempTagFileList:[p_buf_name];
      if (tagfile != "" && tag_read_db(tagfile) >= 0) {
         lastDateTagged := "";
         dateStatus := tag_get_date(p_buf_name, lastDateTagged);
         if (!dateStatus && lastDateTagged == p_file_date) {
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            return 0;
         }
      }
   }

   if (tagfile=="") {
      tagfile=_mapxml_get_tagfile_for_dtd(p_buf_name);
      if (_chdebug) {
         isay(depth, "_mapxml_create_tagfile H"__LINE__": p_buf_name="p_buf_name);
         isay(depth, "_mapxml_create_tagfile H"__LINE__": local_dtd_filename="local_dtd_filename);
         isay(depth, "_mapxml_create_tagfile: tagfile="tagfile);
      }

      // check if this DTD is already tagged and use that tag file
      // instead of creating a new tag file
      if (tagfile!="" && tag_read_db(tagfile) >= 0) {
         lastDateTagged := "";
         dateStatus := tag_get_date(p_buf_name, lastDateTagged);
         if (!dateStatus && lastDateTagged == p_file_date) {
            _xmlTempTagFileList:[local_dtd_filename]=tagfile;
            _xmlTempTagFileList:[p_buf_name]=tagfile;
            _delete_temp_view(temp_view_id);
            activate_window(orig_view_id);
            return 0;
         }
      }
   }

   _xmlTempTagFileList:[local_dtd_filename]=tagfile;
   _xmlTempTagFileList:[p_buf_name]=tagfile;

   // rebuild the tag file from scratch
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
   tag_set_date(p_buf_name, p_file_date, 0, null, p_LangId);
   tag_close_db(null,true);

   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(0);
}
_command void apply_dtd_changes() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   gDTDsWarnedAbout._makeempty();
   if(p_LangId == "html") {
      _mapjsp_init_file(p_window_id, true);
   } else {
      _mapxml_init_file(doForceUpdate:true, addTagsToColorCoding:true);
   }
}
void _mapxml_init_file(bool doForceUpdate=false, bool addTagsToColorCoding=true, int depth=0)
{
   _str NamespaceHashtab:[];
   _save_pos2(auto p2);
   top();
   xsl_doctype_system := "";
   xsl_prefix := "";
   document_tag := "";
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
         _xml_get_current_namespaces(NamespaceHashtab, depth+1);
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
         if (_file_eq(_get_extension(p_buf_name),'xsl')) {
            bottom();
            handle=_xmlcfg_open_from_buffer(p_window_id,status,VSXMLCFG_OPEN_RETURN_TREE_ON_ERROR);
            if (handle>=0) {
               if(document_tag=='stylesheet') {
                  int output_index=_xmlcfg_find_simple(handle,'/'xsl_prefix:+':stylesheet/'xsl_prefix':output');
                  if (output_index>=0) {
                     xsl_doctype_system=_xmlcfg_get_attribute(handle,output_index,'doctype-system');
                     if (xsl_doctype_system!="") {
                        NamespaceHashtab:[""]=xsl_doctype_system;
                     }
                  }
               }
               _xmlcfg_close(handle);
            }
         }

      }
   }
   _restore_pos2(p2);
   // Get recognized namespaces
   // Use pipe separator for namespace info
   // Check if this is an XSL document
   if (doForceUpdate) {
      _UrlSetCaching(2);
      _mapxml_init_file2(doForceUpdate,NamespaceHashtab,xsl_doctype_system,addTagsToColorCoding,depth+1);
      _UrlSetCaching(1);
   } else {
      _mapxml_init_file2(doForceUpdate,NamespaceHashtab,xsl_doctype_system,addTagsToColorCoding,depth+1);
   }
   tagfile := _xml_GetConfigTagFile();
   if (tagfile=="") {
      _clex_xmlSetConfig(doForceUpdate,_xml_MakeConfig("",NamespaceHashtab));
   }

   foreach (auto i => auto value in NamespaceHashtab) {
      //say('i='i' value='value);
      tag_filename := "";
      if (_xml_NamespaceToTagFile(tag_filename, value, depth+1) < 0) {
         continue;
      }
      //say('tf='tag_filename);
      //f:\vslick70\XMLNamespaces\www.w3.org\1999\xhtml\
      cfg_color := CFG_TAG;
      xhtml_namespace := gBuiltinXMLNamespaces:["xhtml"];
      if ((value == xhtml_namespace ||
           (i=="" && xsl_prefix!="" && xsl_doctype_system!="") )

          // Might want to change this to check for XSL style-sheet document node
          && _file_eq(_get_extension(p_buf_name),'xsl')
          ) {
         cfg_color=CFG_XHTMLELEMENTINXSL;
         //say('**********************');
      }
      //cfg_color=CFG_PPKEYWORD;
      //cfg_color=CFG_KEYWORD;
      if (addTagsToColorCoding) {
         _xml_addTagsToColorCoding(tag_filename,i,cfg_color);
      }
   }

}
static _str _xml_MakeConfig(_str tagfile,_str (&NamespaceHashtab):[])
{
   string := "";
   foreach (auto i => auto value in NamespaceHashtab) {
      if (string=="") {
         string = i"="value;
      } else {
         string :+= ";"i"="value;
      }
   }
   //say('s='string);
   return(tagfile'|'string);
}
_str _xml_GetConfigTagFile()
{
   tagfile := string := "";
   parse _clex_xmlGetConfig() with tagfile'|'string;
   return(tagfile);
}
_str _xml_GetConfigNamespace()
{
   tagfile := string := "";
   parse _clex_xmlGetConfig() with tagfile'|'string;
   _maybe_strip(string, '=', stripFromFront:true);
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
      k := pos(':',name);
      if (k) {
         name=substr(name,k+1);
      }
      if (target_ns!="") {
         name=target_ns:+':':+name;
      }
   }
   return name;
}
static void _xml_addTagsToColorCoding(_str tagfile, _str prefix=null, int cfg_color=CFG_TAG)
{
   if (!_haveContextTagging()) {
      return;
   }

   local_dtd_filename := "";
   foreach (auto dtd_filename => auto dtd_tagfile in _xmlTempTagFileList) {
      if (file_eq(tagfile, dtd_tagfile)) {
         local_dtd_filename = dtd_filename;
         break;
      }
   }

   tag_browse_info_init(auto cm);
   status := tag_read_db(tagfile);
   if (status < 0) {
      return;
   }

   _str default_ns = null;
   status = tag_find_global(SE_TAG_TYPE_PACKAGE,0,0);
   if (!status) {
      tag_get_detail(VS_TAGDETAIL_name,default_ns);
   }

   _str list[];
   status=tag_find_global(SE_TAG_TYPE_TAG,0,0);
   for (;!status;) {
      tag_get_detail(VS_TAGDETAIL_name, cm.member_name);
      tag_get_detail(VS_TAGDETAIL_flags, cm.flags);
      list :+= cm.member_name;
      status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
      if (!(cm.flags & SE_TAG_FLAG_FINAL)) {
         tag_name := _xml_retargetNamespace(cm.member_name,default_ns,prefix);
         _clex_xmlAddKeywordAttrs("/"tag_name,"",cfg_color);
      }
   }

   foreach (auto tag_name in list) {
      status=tag_find_in_class(tag_name);
      attr_list := "";
      for (;!status;) {
         tag_get_detail(VS_TAGDETAIL_type, cm.type_name);
         if (cm.type_name == "enumc") {
            status=tag_next_in_class();
            continue;
         }
         tag_get_detail(VS_TAGDETAIL_name, cm.member_name);
         attr_name := _xml_retargetNamespace(cm.member_name,default_ns,null);
         attr_list :+= ' ':+attr_name;
         status=tag_next_in_class();
      }
      tag_reset_find_in_class();
      tag_name=_xml_retargetNamespace(tag_name,default_ns,prefix);
      _clex_xmlAddKeywordAttrs(tag_name,attr_list,cfg_color);
   }
   list._makeempty();

   status=tag_find_global(SE_TAG_TYPE_CONSTANT,0,0);
   while (!status) {
      tag_get_detail(VS_TAGDETAIL_type, cm.type_name);
      if (cm.type_name == "const") {
         // Add constants like &lt;, &gt;
         tag_get_detail(VS_TAGDETAIL_name, cm.member_name);
         kwd := '&'cm.member_name';';
         //say('kwd='kwd);
         _clex_xmlAddKeywordAttrs(kwd,"");
      }
      status=tag_next_global(SE_TAG_TYPE_CONSTANT,0,0);
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
_str def_xml_no_schema_list = '.xsd .xmldoc .xsl .xslt';

bool use_schema_for_color_coding(_str langId, bool value = null)
{
   inList := pos(' .'langId' ',' 'def_xml_no_schema_list' ');

   if (value == null) {
      // return true if the language is not in the list
      value = (inList == 0);
   } else {
      gDTDsWarnedAbout._makeempty();
      if (value) {
         // if it's in the list, remove it
         if (inList) {
            // substract off the space added at the beginning
            inList--;
            before := !inList ? "" : substr(def_xml_no_schema_list, 1, inList - 1);
            after := substr(def_xml_no_schema_list, inList + length('.'langId) + 2);
            def_xml_no_schema_list = before :+ after;
         }
      } else {
         // add it to the list, if it's not there already
         if (!inList) def_xml_no_schema_list = strip(def_xml_no_schema_list :+ ' .'langId);
      }
   }

   return value;
}

/**
 *  
 *  
 * @param doUpdate
 * @param NamespaceHashtab
 * @param xsl_doctype_system
 */
static void _mapxml_init_file2(bool doForceUpdate,
                               _str (&NamespaceHashtab):[],
                               _str xsl_doctype_system="",
                               bool addTagsToColorCoding=true,
                               int depth=0)
{
   markid := NULL_MARKID;
   maptype := "";
   mapid := "";
   systemid := "";
   doctype := "";
   status := 0;
   _str mapprefix=null;
   istaglib := false;
   if (!doForceUpdate && !use_schema_for_color_coding(p_LangId)) {
      status=1;
      mapid="";
      maptype="";
      markid= NULL_MARKID;
      NamespaceHashtab._makeempty();
   } else {
      status=_mapxml_get_doctype_info(maptype,mapid,systemid,doctype,markid,istaglib);
   }

   if (status) {
      maptype="";
      mapid="";
      systemid="";
      markid=NULL_MARKID;
      if (xsl_doctype_system!="") {
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
   tagfile := "";
   if (!doForceUpdate && !use_schema_for_color_coding(p_LangId)) {
      status = 1;
   } else {
      // check if we have a local XML namespace tag file for this namespace
      haveBuiltinNamespaceTagFile := false;
      if (systemid == null || systemid == "") {
         foreach (auto ns => auto ns_name in gBuiltinXMLNamespaces) {
            if (mapid == ns_name) {
               status = _xml_NamespaceToTagFile(tagfile, mapid, depth+1);
               if (status >= 0) {
                  haveBuiltinNamespaceTagFile = true;
                  break;
               }
            }
         }
      }
      // otherwise, we need to try to map the tag file
      if (!haveBuiltinNamespaceTagFile) {
         status=_mapxml_create_tagfile(maptype,mapid,systemid,markid,p_buf_name,tagfile,p_DocumentName,doForceUpdate,depth);
      }
   }
   //say('create status='status);
   //say('tagfile='tagfile);
   if (markid!=NULL_MARKID) {
      _free_selection(markid);
   }
   if (status) {
      _clex_xmlSetConfig(doForceUpdate,"");
      return;
   }
   //say('tagfile='tagfile' bn='p_buf_name);

   _clex_xmlSetConfig(doForceUpdate,_xml_MakeConfig(tagfile,NamespaceHashtab));

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
   maptype := mapid := "";
   typeless markid=0;
   istaglib := false;
   int status=_mapxml_get_doctype_info(maptype,mapid,markid,istaglib);
   if (markid!=NULL_MARKID) {
      typeless orig_markid=_duplicate_selection("");
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
def  '-'= xml_dash;
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
   if (p_col<=1) return("");
   left();
   ch:=get_text_safe(-2);
   right();
   return(ch);
}
_str get_prev_prev_char()
{
   if (p_col<=2) return("");
   left();
   left();
   ch := get_text_safe(-2);
   right();
   right();
   return(ch);
}

/** 
 * Move the start of the enclosing XML tag.
 */
_command void xml_parent() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Handle embedded language
   embedded_status := _EmbeddedStart(auto orig_values);
   if (embedded_status==1) {
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }

   col := _xml_parent(auto start_tag,auto errorArg);
   if (col <= 0) {
      error_msg := (col < 0)? "  ":+get_message(col, errorArg) : "";
      message("Parent tag not found.":+error_msg);
   }
}
int _OnUpdate_xml_parent(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   lang := target_wid.p_LangId;
   if (_LanguageInheritsFrom("html", lang)) return MF_ENABLED;
   return (_LanguageInheritsFrom('xml',lang)? MF_ENABLED:MF_GRAYED);
}

/** 
 * Position cursor on the enclosing start tag.
 */
int _xml_parent(_str &start_tag,_str &errorArg=null)
{
   start_tag = "";
   if (_nrseek() > def_xml_max_smart_editing_ksize*1024) {
      errorArg = "def_xml_max_smart_editing_ksize";
      return VSCODEHELPRC_FILE_TOO_LARGE;
   }

   // This has to at least look like XML or HTML
   if (!_LanguageInheritsFrom("xml") && !_LanguageInheritsFrom("html")) {
      return TAGGING_NOT_SUPPORTED_FOR_FILE_RC;
   }

   // Special case for BBC, which inherits from HTML, but is not HTML
   if (_LanguageInheritsFrom("bbc")) {
      return TAGGING_NOT_SUPPORTED_FOR_FILE_RC;
   }

   // buffer to large for context tagging?
   if (p_buf_size>def_update_context_max_ksize*1024) {
      errorArg = "def_update_context_max_ksize";
      return VSCODEHELPRC_FILE_TOO_LARGE;
   }

   // if we are on an identifier, skip to the beginning of it
   save_pos(auto p);
   not_word_re := _clex_identifier_notre();
   if (pos(not_word_re, get_text(), 1, 'r') == 0) {
      if (!search(not_word_re, 'rh-')) {
         right();
      }
   }

   // For regular XML, we can use the current context
   // to find the current tag, quicker than doing
   // a lot of recursive searching backwards
   if (get_text(1, _nrseek()-1) == '/') {
      _nrseek(_nrseek()-1);
   }
   if (get_text(1, _nrseek()-1) == '<') {
      _nrseek(_nrseek()-1);
   }
   if (get_text(1) == '<' && get_text(1, _nrseek()-1) != '>') {
      _nrseek(_nrseek()-1);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   // if the current file is not in XML mode, switch to a temp view
   // and force it's mode to XML in order to get the "pure" XML outline
   save_pos(auto start_pos);
   xml_list_tags_index  := _FindLanguageCallbackIndex("vs%s_list_tags", "xml");
   lang_list_tags_index := _FindLanguageCallbackIndex("vs%s_list_tags", p_LangId);
   orig_view_id := temp_view_id := 0;
   orig_filename := p_buf_name;
   orig_langId := p_LangId;
   if (xml_list_tags_index != lang_list_tags_index) {
      status := _open_temp_view(orig_filename, temp_view_id, orig_view_id, "+bi "p_buf_id);
      if (status < 0) {
         p_window_id=orig_view_id;
         temp_view_id = 0;
      } else {
         p_buf_name = orig_filename:+".temp.xml";
         restore_pos(start_pos);
         p_LangId = "xml";
      }
   }

   // make sure the context is up-to-date, and get the current scope 
   // under the cursor
   _UpdateContext(true);
   context_id := tag_current_context();
   if (context_id <=0) {
      // clean up the temporary buffer
      if (xml_list_tags_index != lang_list_tags_index && temp_view_id != 0) {
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id,false);
         p_buf_name = orig_filename;
         p_LangId = orig_langId;
      }
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   tag_get_context_info(context_id, auto cm);
   start_tag=cm.member_name;
   _GoToROffset(cm.seekpos);
   col := p_col;

   // clean up the temporary buffer
   if (xml_list_tags_index != lang_list_tags_index && temp_view_id != 0) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id,false);
      p_buf_name = orig_filename;
      p_LangId = orig_langId;
      _GoToROffset(cm.seekpos);
   }

   return(col);
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
_command void xml_slash() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   key := '/';
   if (command_state()) {
      call_root_key(key);
      return;
   }
   // Handle embedded language
   embedded_status := _EmbeddedStart(auto orig_values);
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

   if (p_window_state:=='I' || p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART) {
      keyin(key);
      return;
   }
   prev_is_lt := (get_prev_char()=='<');
   next_is_gt := (get_text()=='>');
   keyin(key);
   if (!prev_is_lt) {
      // check if they have <tagname/
      // which we can auto-complet eto <tagname/>
      if (!next_is_gt) {
         have_start_tag:=false;
         save_pos(auto p);
         left();
         left();
         while (p_col > 1 && _clex_is_identifier_char(get_text())) left();
         have_start_tag = (get_text()=='<');
         restore_pos(p);
         if (have_start_tag) keyin('>');
      }
      return;
   }
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
      return;
   }

   sc.lang.ScopedTimeoutGuard timeout(def_match_paren_timeout);
   start_tag := "";
   orig_col := p_col;
   after_first_non_blank_col := 0;
   int col=_xml_slash(start_tag, after_first_non_blank_col, canTimeout:true);
   if (col /*|| after_first_non_blank_col*/) {
      _str gt = (next_is_gt ? ("") : ('>'));
      line := "";
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

/**
 * If the user just typed <code>&lt;!-</code> to open a multiple line comment,
 * complete the comment with <code>--&gt;</code>.  Do not complete the comment
 * if there is text after the cursor, since they are probably trying to
 * surround something.
 *
 * @appliesTo  Edit_Window, Editor_Control
 *
 * @categories Edit_Window_Methods, Editor_Control_Methods
 */
_command void xml_dash() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   static bool skip_second_dash;

   if (command_state() || _MultiCursorAlreadyLooping()) {
      call_root_key(last_event());
      skip_second_dash=false;
      return;
   }
   if (_in_comment() || _in_string()) {
      doInsert := false;
      if (p_col>4) {
         p_col-=4;
         temp := get_text(7);
         p_col+=4;
         if (temp == '<!---->') {
            doInsert = true;
         }
      }
      if (doInsert) {
         if (!skip_second_dash) {
            _insert_text('-');
         }
      } else {
         keyin('-');
      }
      skip_second_dash=false;
      return;
   }

   do {
      // option is turned off
      if (!def_auto_complete_block_comment) {
         break;
      }
      // we need to be at the end of the line, otherwise we should not be doing this
      get_line(auto orig_line);
      line := strip(orig_line,'T');
      if (_last_char(line)=='>' && p_col != text_col(_rawText(line))) {
         break;
      }
      if (_last_char(line)!='>' && p_col != text_col(_rawText(line))+1 ) {
         break;
      }

      // check if we are after a <! with an optional first dash
      save_pos(auto p);
      left();
      first_dashes := '--';
      have_first_dash := false;
      if (get_text() == '-') {
         left();
         first_dashes = '-';
      }
      if (get_text() == '!') {
         left();

         // the next character needs to be a less than
         if (get_text() != '<') {
            restore_pos(p);
            break;
         }

         // check where the next block comment starts
         save_pos(auto before_next_search);
         next_comment_start := (long)MAXINT;
         status := search('<!--','@hCc');
         if (!status) next_comment_start = _QROffset();
         restore_pos(before_next_search);

         // look for a comment end sequence to match up with
         // this needs to be before the next block comment starts
         status = search('-->','@hXcs');
         if (get_text() == '<' && (status < 0 || _QROffset() > next_comment_start)) {
            restore_pos(p);
            _insert_text_raw(first_dashes);
            //Insert an undo step here, so user can undo just the auto insertion of '*/'
            _undo('S');
            _insert_text_raw('--');
            if (_last_char(line) == ">") {
               _delete_text(1);
            }
            _insert_text_raw('>');
            p_col -= 3;
            message("Type '-->' on a subsequent line to finish this block comment.");
            skip_second_dash = (first_dashes == '--');
            return;
         }

         // we have a closing comment to match up with
         if (!status && _QROffset() < next_comment_start) {
            restore_pos(p);
            _insert_text_raw(first_dashes);
            //Insert an undo step here, so user can undo just the auto insertion of '*/'
            _undo('S');
            if (_last_char(line) == ">") {
               _delete_text(1);
            }
            skip_second_dash = (first_dashes == '--');
            return;
         }
      }
      restore_pos(p);
   
   } while (false);

   keyin('-');
   skip_second_dash=false;
}

static int _xml_matchTagBackward(_str &start_tag,int &after_first_non_blank_col=0,bool canTimeout=true)
{
   int status;
   level := 0;

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
      ch := get_text_safe();
      word := get_text_safe(2);
      if (word=='</') {  // Found ending tag.
         col := p_col;
         start := 0;
         //++p_col;
         _str tag=_html_GetTag(1,start);
         //--p_col;
         //say('tag='tag' line='p_line);
         if (tag!="") {
            //_message_box('tag='tag' start='start' level='level);
            status=_html_matchTagBackward(tag, canTimeout:canTimeout);
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
            col := p_col;
            start := 0;
            start_tag=_html_GetTag(1,start);
            _first_non_blank();
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
static int _xml_slash(_str &start_tag, int &after_first_non_blank_col=0, bool canTimeout=true)
{
   if (_nrseek()>def_xml_max_smart_editing_ksize*1024) {
      return(0);
   }
   save_pos(auto p);

   // tagging for these languages is not strictly XML outlining,
   // so we need to use old-style tag matching
   if (p_LangId != 'xml' && _FindLanguageCallbackIndex("vs%s_list_tags")) {
      if (_xml_matchTagBackward(start_tag, canTimeout:canTimeout)) {
         restore_pos(p);
         return(0);
      }
      col := p_col;
      restore_pos(p);
      return(col);
   }
   if (p_buf_size>def_update_context_max_ksize*1024) {
      return(0);
   }
   // For regular XML, we can use the current context
   // to find the current tag, quicker than doing
   // a lot of recursive searching backwards
   int status=_nrseek(_nrseek()-2);
   if (status) {
      return(0);
   }

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   _UpdateContextAndTokens(true);

   context_id := tag_current_context();
   if (context_id <=0) {
      restore_pos(p);
      return(0);
   }

   tag_get_context_info(context_id, auto cm);
   start_tag=cm.member_name;
   _GoToROffset(cm.seekpos);
   col := p_col;
   restore_pos(p);
   return(col);
}

/** 
 * If the previous characters are '--' and we are not in
 * a string or comment, then the slash should look for
 * a &lt;!-----&gt; that needs to be fixed to create a block comment.
 * 
 * @return 'true' if the comment was completed.
 */
bool _xml_gt_comment()
{
   cfg := _clex_find(0,'g');
   if (p_col > 2 && 
       get_text(2,(int)_QROffset()-2)=='--' &&
       cfg!=CFG_STRING && 
       cfg!=CFG_COMMENT && 
       cfg!=CFG_IMAGINARY_LINE) {

      start_line := 0;
      orig_offset := _QROffset();
      save_search(auto s1,auto s2,auto s3,auto s4,auto s5);

      // XML/HTML comments can not be nested
      prev_comment_offset := (long)0;
      status := search('-->','@-rhCc');
      if (!status) {
         prev_comment_offset = _QROffset()-4;
         _GoToROffset(orig_offset);
      }
      have_prev_comment_start := false;
      status = search('<!--','@-rhCc');
      if (!status && _QROffset() >= prev_comment_offset) {
         prev_comment_offset = _QROffset();
         _GoToROffset(orig_offset);
         have_prev_comment_start = true;
      }

      // look for a comment that can be adjusted
      status = search('\<\!----\>[ \t]*$','@-rhCc');
      if (!status && _QROffset() >= prev_comment_offset) {
         start_line=p_line;
         p_col+=4;
         _delete_text(3);
      }

      // we finished the comment
      restore_search(s1,s2,s3,s4,s5);
      if (start_line > 0) {
         _GoToROffset(orig_offset-3);
         message("Finished comment starting on line ":+start_line);
      } else {
         _GoToROffset(orig_offset);
         message("Comment close does match comment start.");
      }

      // just finish the comment end, as is
      keyin('>');
      return true;
   }

   // nothing happened
   return false;
}

_command void xml_gt() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL)
{
   key := '>';
   if (command_state()) {
      call_root_key(key);
      return;
   }
   // Handle embedded language
   embedded_status := _EmbeddedStart(auto orig_values);
   if (embedded_status==1) {
      call_key(key, "\1", "L");
      _EmbeddedEnd(orig_values);
      return; // Processing done for this key
   }

   // block comment handling?
   if (_xml_gt_comment()) {
      return;
   }

   if (_haveBeautifiers()) {
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
      cfg := _clex_find(0,'g');
      if (cfg==CFG_COMMENT || cfg==CFG_STRING) {
         return;
      }
      line := "";
      get_line(line);
      int col=_xml_gt();
      if (col) {
         replace_line(indent_string(col-1):+strip(line));
         _end_line();
      }
      XW_gt();
   } else {
      // Standard.  This works because the configuration is identical
      // for both XML and HTML.
      maybe_insert_html_close_tag();
   }
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
   status := search('<','-rh@xcs');
   if (status) {
      return(0);
   }
   col := p_col;
   restore_pos(p);
   return(col);
}

_command void xml_enter() name_info(','VSARG2_MULTI_CURSOR|VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   if (ispf_common_enter()) return;
   if (command_state()) {
      call_root_key(ENTER);
      return;
   }
   // Handle embedded language
   embedded_status := _EmbeddedStart(auto orig_values);
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
          _nrseek()>def_xml_max_smart_editing_ksize*1024
          ) {
      call_root_key(ENTER);
   } else {
      if (_in_comment(true) || _xml_InString()) {
         call_root_key(ENTER);
      } else if (_xml_expand_enter() ) {
          call_root_key(ENTER);
      } else if (_argument=="") {
         _undo('S');
      }
   }
}
bool _xml_supports_syntax_indent(bool return_true_if_uses_syntax_indent_property=true) {
   return true;
}
bool _xml_expand_enter()
{
   col := 0;
   if (p_indent_style==INDENT_SMART) {
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
   _first_non_blank();
   col := p_col;
   restore_pos(p);
   return(col);
}
int xml_indent_col(int non_blank_col, bool paste_open_block = false)
{
   orig_col := p_col;
   orig_linenum := p_line;
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
   word := "";
   ch1 := get_text_safe();
   ch2 := get_text_safe(2);
   typeless junk=0;
   int cfg=_clex_find(0,'g');
   if (cfg==CFG_WINDOW_TEXT && (ch1!='<' && ch1!='>' && ch2!='/>')) {
      doIndent := false;
      word_chars := _clex_identifier_chars();
      if (_LanguageInheritsFrom('dtd') && pos('['word_chars']',get_text_safe(-2),1,'r')) {
         save_pos(auto p2);
         prev_full_word();
         left();
         if (get_text_safe()=="") {
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

      ch := get_text_safe();
      text := "";
      col := 0;
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
                 and do _xml_slash if we are less then the def_xml_max_smart_editing_ksize limit.  Otherwise,
                 do the first_non_blank.  At the moment, I can't see a reason why using
                 first_non_blank() isn't good enough.
            */
            
            _first_non_blank();
            col=p_col;
#if 0
            start_tag := "";
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
int dtd_smartpaste(bool char_cbtype,int first_col,int Noflines)
{
   return(xml_smartpaste(char_cbtype,first_col,Noflines));
}
static bool _xml_InString()
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
int xml_smartpaste(bool char_cbtype,int first_col,int Noflines)
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
   first_line := "";
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
   comment_col := p_col;
   if (j>1) {
      restore_pos(p4);
   }

   // search for non-blank character
   status := search('[~ \t]','@mrh');
   if (status) {
      return(0);
   }
   ch1 := get_text_safe();
   ch2 := get_text_safe(2);
   ch9 := get_text_safe(9);
   int cfg=_clex_find(0,'g');
   // IF    (code found AND pasting comment AND code col different than comment indent)
   //    OR first non-blank pasted line starts with non-blank AND
   //       (not pasting character selection OR copied text from column 1)
   //    OR (not pasting start tag or end of tag)
   //    OR pasting &XXX; keyword, another pasting text case
   //    //OR pasting CDATA -- not sure if we want this test or not
   if ((!status && comment_col!="" && p_col!=comment_col)
       || (substr(first_line,1,1)!="" && (!char_cbtype ||first_col<=1))
       || (ch1!='<' && ch1!='>' && ch2!='/>' && cfg==CFG_WINDOW_TEXT)
       || (ch1=='&' && cfg==CFG_KEYWORD)
       //|| (ch9=='<![CDATA[' && cfg==CFG_WINDOW_TEXT)
       ) {
      //say('abort');
      return(0);
   }
   start_tag := "";
   typeless enter_col=0;
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   int syntax_indent=p_SyntaxIndent;
   if (!status && ch1=='>' || ch2=='/>') {
      // IF pasting stuff contains code AND first char of code }
      ++p_col;
      enter_col=_xml_gt();
      if (!enter_col) {
         enter_col="";
      }
      _begin_select();up();
   } else if (ch2=='</') {  // Pasting end tag
      // IF pasting stuff contains code AND first char of code }
      _SetTimeout(def_match_paren_timeout);
      ++p_col;
      enter_col=_xml_slash(start_tag, canTimeout:true);
      if (!enter_col) {
         enter_col="";
      }
      _begin_select();up();
      _SetTimeout(0);
   } else {
      _begin_select();up();
      _end_line();
      enter_col=xml_enter_col();
      status=0;
   }
   //IF no code found/want to give up OR ... OR want to give up
   if (status || enter_col=="" ) {
      return(0);
   }
   return(enter_col);
}
static _str xml_enter_col()
{
   typeless enter_col=0;
   if ( command_state() || p_window_state:=='I' ||
      p_SyntaxIndent<0 || p_indent_style!=INDENT_SMART ||
      _nrseek()>def_xml_max_smart_editing_ksize*1024 ||
      xml_enter_col2(enter_col,p_SyntaxIndent) ) {
      return("");
   }
   return(enter_col);
}
static _str xml_enter_col2(_str &enter_col,int syntax_indent)
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent = p_SyntaxIndent;

   status := 0;
   /*_end_line();
   if (p_col<non_blank_col+1) {
      p_col=non_blank_col+1;
   } */
   if (p_indent_style==INDENT_SMART) {
      enter_col=xml_indent_col(0);
   } else {
      enter_col=_first_non_blank_col();
   }
   return(status);
}

int _xml_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                           _str lastid,int lastidstart_offset,
                           int info_flags,typeless otherinfo,
                           bool find_parents,int max_matches,
                           bool exact_match,bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _html_find_context_tags(errorArgs,
                                  prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,find_parents,
                                  max_matches,exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
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
int _xml_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
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
   LastIndex := _xmlcfg_get_last_child(handle,NodeIndex);
   if (LastIndex<0) {
      return;
   }
   //say('name='_xmlcfg_get_name(handle,LastIndex));
   AttrIndex := LastIndex;
   for (;;) {
      AttrIndex = _xmlcfg_get_next_attribute(handle,AttrIndex);
      if (AttrIndex < 0) {
         break;
      }
      AttrName := _xmlcfg_get_name(handle,AttrIndex);
      //say('AttrName='AttrName);
      value := _xmlcfg_get_attribute(handle, LastIndex, AttrName);
      if (value=='http://www.w3.org/2000/10/XMLSchema') {
         value='http://www.w3.org/2001/XMLSchema';
      }
      value = stranslate(value, " ", "[\n\r\t\v ]+", "r");
      value = strip(value);
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
         NamespaceHashtab:[""]=value;
         NamespaceHashtab2:[value]="";
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
         prefix := substr(AttrName,1,length(AttrName)-15);
         if (prefix=='xsi' && pos(' ',value) > 0) {
            urlns := "";
            uri   := "";
            do {
               urlns = parse_file(value, false);
               uri   = parse_file(value, false);
               // Find the matching urlns in the namespace hashtables and replace
               // with uri so we can find the schemas.
               //
               // Note: This method depends on the 'xmlns' attribute coming
               // before the 'xsi:schemaLocation' attribute.
               found_it := false;
               foreach (auto i => auto namespace_name in NamespaceHashtab) {
                  if( strieq(urlns, namespace_name) ) {
                     // Replace uri with real schema location
                     olduri := namespace_name;
                     NamespaceHashtab:[i] = uri;
                     NamespaceHashtab2._deleteel(olduri);
                     NamespaceHashtab2:[uri] = i;
                     found_it=true;
                     break;
                  }
               }
               if( !found_it ) {
                  // Fall back to old method of making it the default namespace
                  // for elements without a prefix.
                  NamespaceHashtab:[""]=uri;
                  NamespaceHashtab2:[uri]="";
               }
            } while( value!="" );
         } else {
            NamespaceHashtab:[prefix]=value;
            NamespaceHashtab2:[value]=prefix;
         }
      } else if (length(AttrName)>24 && strieq(substr(AttrName,length(AttrName)-24),"noNamespaceSchemaLocation")) {
         NamespaceHashtab:[""]=value;
         NamespaceHashtab2:[value]="";
      }
   }
   _xml_get_namespaces(handle,LastIndex,NamespaceHashtab,NamespaceHashtab2);
}


/**
 *  
 *  
 * @param NamespaceHashtab
 */
void _xml_get_current_namespaces(_str (&NamespaceHashtab):[], int depth=0)
{
   NamespaceHashtab._makeempty();
   save_pos(auto p2);
   cfg:=_clex_find(0,'g');
   // CDATA strings can be huge (10,000 lines or more). Optimize that case here.
   typeless status;
   if ((cfg==CFG_TAG || cfg==CFG_STRING) || (cfg!=CFG_COMMENT && get_text()=='<') && _LanguageInheritsFrom('xml') && _xml_in_cdata()) {
   } else {
      status=search('[<>]','rh@-xcs');
      if (status) {
         return;
      }
      right();
   }

   typeless EndRealSeekPos=_QROffset();
   restore_pos(p2);

   // We might be able to use def_update_context_max_ksize instead
   if (EndRealSeekPos>def_xml_max_smart_editing_ksize*1024) {
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
   xsl_namespace := gBuiltinXMLNamespaces:["xsl"];
   xhtml_namespace := gBuiltinXMLNamespaces:["xhtml"];
   if (NamespaceHashtab2._indexin(xsl_namespace)) {
      prefix := NamespaceHashtab2:[xsl_namespace];

      doctype_system := "";
      output_index := _xmlcfg_find_simple(handle,'/'prefix:+':stylesheet/'prefix':output');
      if (output_index >= 0) {
         doctype_system = _xmlcfg_get_attribute(handle, output_index, 'doctype-system');
      }

      if (doctype_system == "" && !NamespaceHashtab2._indexin(xhtml_namespace)) {
         NamespaceHashtab:[""] = xhtml_namespace;
      } 
   }

   // if it's empty look for doc type information
   if (NamespaceHashtab._isempty()) {
      status = _mapxml_get_doctype_info(auto mapType, auto mapId, auto systemId, auto doctype, auto markid, auto istaglib);
      if (!status && systemId != "") {
         NamespaceHashtab:[""] = systemId;
      }
      if (_chdebug) {
         isay(depth, "_xml_get_current_namespaces H"__LINE__": status="status);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": mapType="mapType);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": mapId="mapId);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": systemId="systemId);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": markId="markid);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": istaglib="istaglib);
         isay(depth, "_xml_get_current_namespaces H"__LINE__": doctype="doctype);
      }
      if (markid!=NULL_MARKID) {
         _free_selection(markid);
      }
   }

   // if it's empty, just add these
   if (NamespaceHashtab._isempty()) {
      ext := _get_extension(p_buf_name);
      if (_file_eq(ext,'xsl') || p_LangId == "xsl") {
         NamespaceHashtab:['xsl']=xsl_namespace;
         NamespaceHashtab:[""]=xhtml_namespace;
      } else if (p_LangId == "xsd") {
         NamespaceHashtab:["xsd"]=gBuiltinXMLNamespaces:[p_LangId];
         NamespaceHashtab:["xs"]=gBuiltinXMLNamespaces:[p_LangId];
         NamespaceHashtab:[""]=gBuiltinXMLNamespaces:[p_LangId];
      } else if (gBuiltinXMLNamespaces._indexin(p_LangId)) {
         NamespaceHashtab:[""]=gBuiltinXMLNamespaces:[p_LangId];
      } else if (gBuiltinXMLNamespaces._indexin(ext)) {
         NamespaceHashtab:[""]=gBuiltinXMLNamespaces:[ext];
      }
   }

   if (_chdebug) {
      idump(depth, NamespaceHashtab, "_xml_get_current_namespaces H"__LINE__": NamespaceHashtab");
   }
   _xmlcfg_close(handle);
}

static bool namespacesExistsForDifferentYear(_str &most_recent_file,_str add_path,_str root)
{
   //  Check for a different year    "yyyy/lastname"
   temp_path := add_path;
   _maybe_strip_filesep(temp_path);
   temp_path = _strip_filename(temp_path, 'N');
   //say('h1 temp='temp);
   if (temp_path == "") {
      return(false);
   }

   _maybe_strip_filesep(temp_path);
   year := _strip_filename(temp_path, 'P');
   //say('h2 year='year);
   if (year != "TR" && (!isinteger(year) || length(year)!=4)) {
      return(false);
   }
   _maybe_strip_filesep(temp_path);
   temp_path = _strip_filename(temp_path, 'N');
   temp_path = root:+temp_path:+'*';
   most_recent_year := "0";
   most_recent_file = "";
   found_file := file_match2(temp_path,1,'-p');
   while (found_file != "") {
      if (_last_char(found_file)==FILESEP) {
         found_year := found_file;
         _maybe_strip_filesep(found_year);
         found_year = _strip_filename(found_year, 'P');
         // IF this looks like a year
         if (isinteger(found_year) && length(found_year)==4 && year!=found_year && found_year > most_recent_year) {
            found_file = root:+stranslate(add_path, FILESEP:+found_year:+FILESEP, FILESEP:+year:+FILESEP) :+ 'tags':+TAG_FILE_EXT;
            //say('try 'found_file);
            if (file_exists(found_file)) {
               most_recent_year = found_year;
               most_recent_file = found_file;
            }
         }
      }
      found_file = file_match2(temp_path,0,'-p');
   }
   //say('most_recent_file='most_recent_file);
   if (most_recent_file == "") {
      return(false);
   }
   return(true);
}

static int _xml_NamespaceToTagFile(_str &tag_filename, _str xml_namespace, int depth)
{
   if (!_haveContextTagging()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   root := _getSlickEditInstallPath():+'XMLNamespaces':+FILESEP;
   parse xml_namespace with 'http://' auto add_path;
   if (add_path=="") return(1);
   add_path=translate(add_path,FILESEP,'/');
   _maybe_append_filesep(add_path);
   tag_filename = root:+add_path:+'tags':+TAG_FILE_EXT;
   if (_chdebug) {
      isay(depth, "_xml_NamespaceToTagFile H"__LINE__": tag_filename="tag_filename);
   }

   //say('tf='tag_filename);
   status := tag_read_db(tag_filename);
   if (status < 0) {
      if (namespacesExistsForDifferentYear(tag_filename, add_path, root)) {
         status = tag_read_db(tag_filename);
      }
   }
   if (status < 0) {
      tag_filename = "";
   }
   // does the namespace match the XSD tag file namespace?  Then use it.
   //say("_xml_NamespaceToTagFile: namespace="xml_namespace);
   //say("_xml_NamespaceToTagFile: cfgnamespace="_xml_GetConfigNamespace());
   config_ns := _xml_GetConfigNamespace();

   if (_chdebug) {
      isay(depth, "_xml_NamespaceToTagFile H"__LINE__": xml_namespace="xml_namespace);
      isay(depth, "_xml_NamespaceToTagFile H"__LINE__": config_ns="config_ns);
      idump(depth, _xmlTempTagFileList, "_xml_NamespaceToTagFile H"__LINE__": _xmlTempTagFileList");
   }

   // does the namespace match the XSD tag file namespace?  Then use it.
   //say("_xml_NamespaceToTagFile: namespace="xml_namespace);
   //say("_xml_NamespaceToTagFile: cfgnamespace="_xml_GetConfigNamespace());
   xsi_ns := "";
   parse config_ns with config_ns ';' xsi_ns;
   if (status < 0 && xml_namespace==config_ns) {
      tag_filename = _xml_GetConfigTagFile();
      if (_chdebug) {
         isay(depth, "_xml_NamespaceToTagFile H"__LINE__": tag_filename="tag_filename);
      }
      if (tag_filename!="") {
         status=tag_read_db(tag_filename);
      }
   }
   if (_chdebug) {
      isay(depth, "_xml_NamespaceToTagFile H"__LINE__": status="status);
   }
   return(status);
}

void _xml_insert_namespace_context_entities(_str NamespaceHashtab:[],
                                            _str lastid,_str lastid_prefix,
                                            int &num_matches, int max_matches,
                                            bool exact_match=false,
                                            bool case_sensitive=false,
                                            int depth=0)
{
   only_prefix := "";
   i := pos(':',lastid_prefix);
   if (i) {
      only_prefix=substr(lastid_prefix,1,i-1);
   } else {
      only_prefix = null;
   }

   foreach (auto prefix => auto namespace_name in NamespaceHashtab) {
       if (_chdebug) {
          isay(depth, "_xml_insert_namespace_context_entities: prefix="prefix" namespace="namespace_name);
       }
       if (only_prefix!=null && prefix!=only_prefix) {
          continue;
       }

       tag_filename := "";
       if (_xml_NamespaceToTagFile(tag_filename, namespace_name, depth+1) < 0) {
          continue;
       }
       if (_chdebug) {
          isay(depth, "_xml_insert_namespace_context_entities: tag_filename="tag_filename);
       }

       status := tag_find_global(SE_TAG_TYPE_CONSTANT,0,0);
       for (;!status;) {
          tag_get_tag_browse_info(auto cm);
          tag_name := cm.member_name;
          //tag_get_detail(VS_TAGDETAIL_arguments,
          //say("_xml_insert_namespace_context_entities: tag_name="tag_name" prefix="prefix);
          if (exact_match && tag_name!=lastid_prefix) {
             status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
             continue;
          }
          temp_prefix := lastid_prefix;
          _html_insert_context_tag_item(tag_name,
                                        exact_match? lastid:lastid_prefix,
                                        false, "", 0,
                                        num_matches, max_matches,
                                        exact_match, case_sensitive,
                                        tag_filename,cm.type_name,&cm,depth);
          if (exact_match) {
             break;
          }
          status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
       }
       tag_reset_find_in_class();
   }
}

void _xml_insert_namespace_context_tags(_str NamespaceHashtab:[],
                                        _str lastid,_str lastid_prefix,
                                        bool is_attrib,_str clip_prefix, 
                                        int start_or_end,
                                        int &num_matches, int max_matches,
                                        bool exact_match=false,
                                        bool case_sensitive=false,
                                        bool insertTagDatabaseNames=false,
                                        int depth=0,
                                        bool (&tagsAllowedInContextModel):[]=null)
{
   only_prefix := "";
   i := pos(':',lastid_prefix);
   if (i) {
      only_prefix=substr(lastid_prefix,1,i-1);
   } else {
      only_prefix = null;
   }
   if (_chdebug) {
      isay(depth, "_xml_insert_namespace_context_tags: lastid="lastid"=");
      isay(depth, "_xml_insert_namespace_context_tags: lastid_prefix="lastid_prefix"=");
      isay(depth, "_xml_insert_namespace_context_tags: only_prefix="(only_prefix!=null? only_prefix:"(null)"));
   }

   foreach (auto prefix => auto namespace_name in NamespaceHashtab) {
       if (_chdebug) {
          isay(depth, "_xml_insert_namespace_context_tags: prefix="prefix" namespace="namespace_name);
       }
       if (only_prefix!=null && prefix!=only_prefix) {
          continue;
       }

       tag_filename := "";
       if (_xml_NamespaceToTagFile(tag_filename, namespace_name, depth+1) < 0) {
          continue;
       }
       if (_chdebug) {
          isay(depth, "_xml_insert_namespace_context_tags: tag_filename="tag_filename);
          isay(depth, "_xml_insert_namespace_context_tags: tag_current_db()="tag_current_db());
       }

       status := tag_find_global(SE_TAG_TYPE_TAG,0,0);
       if (_chdebug) {
          isay(depth, "_xml_insert_namespace_context_tags: status="status);
       }
       while (!status) {
          tag_get_tag_browse_info(auto cm);
          tag_name := cm.member_name;
          //tag_get_detail(VS_TAGDETAIL_arguments,
          //say("_xml_insert_namespace_context_tags: tag_name="tag_name" prefix="prefix);
          i=pos(':',tag_name);
          if (i) {
             tag_name=substr(tag_name,i+1);
          }
          if (prefix!="") {
             tag_name=prefix:+':':+tag_name;
          }
          if (exact_match && tag_name!=lastid_prefix) {
             status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
             continue;
          }
          temp_prefix := lastid_prefix;
          if (insertTagDatabaseNames) {
             tag_name = cm.member_name;
             temp_prefix=tag_name;
          }
          // only allowing tags from the parent tags content model?
          if (tagsAllowedInContextModel._length() > 0) {
             if (!tagsAllowedInContextModel._indexin(cm.member_name) && !tagsAllowedInContextModel._indexin(tag_name)) {
                if (_chdebug) {
                   isay(depth, "_xml_insert_namespace_context_tags: NOT ALLOWED IN CONTEXT, tag_name="tag_name"=");
                }
                status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
                continue;
             }
          }
          if (_chdebug) {
             isay(depth, "_xml_insert_namespace_context_tags: tag_name="tag_name"=");
          }
          if (start_or_end==0) {
             _html_insert_context_tag_item(tag_name,
                                           exact_match? lastid:lastid_prefix,
                                           false,"", start_or_end,
                                           num_matches, max_matches,
                                           exact_match, case_sensitive,
                                           tag_filename,cm.type_name,&cm,depth);

          } else if (!(cm.flags & SE_TAG_FLAG_FINAL)) {
             _html_insert_context_tag_item(/*"/"*/tag_name,
                                                  exact_match? lastid:lastid_prefix,
                                                  false,"", 0,
                                                  num_matches, max_matches,
                                                  exact_match, case_sensitive,
                                                  tag_filename,cm.type_name,&cm,depth);
          }
          if (exact_match) {
             break;
          }
          status=tag_next_global(SE_TAG_TYPE_TAG,0,0);
       }
       tag_reset_find_in_class();
   }
}
void _xml_insert_namespace_context_tags_attrs(_str NamespaceHashtab:[],
                                              _str lastid,_str lastid_prefix,
                                              _str match_tag_name,
                                              bool is_attrib,_str clip_prefix, 
                                              int &num_matches, int max_matches,
                                              int start_or_end=0,
                                              bool exact_match=false,
                                              bool case_senstive=false, 
                                              VS_TAG_RETURN_TYPE (&visited):[]=null,
                                              int depth=0)
{
   only_prefix := "";
   i := pos(':',match_tag_name);
   suffix := match_tag_name;
   if (i) {
      only_prefix=substr(match_tag_name,1,i-1);
      suffix=substr(match_tag_name,i+1);
   }

   tag_init_tag_browse_info(auto cm);

   foreach (auto prefix => auto namespace_name in NamespaceHashtab) {
       if (prefix != only_prefix) {
          continue;
       }

       tag_filename := "";
       if (_xml_NamespaceToTagFile(tag_filename, namespace_name, depth+1) < 0) {
          continue;
       }

       _str found_tags[];
       found_tags :+= match_tag_name;
       this_prefix := "";
       status := tag_find_global(SE_TAG_TYPE_TAG,0,0);
       while (!status) {
          tag_get_tag_browse_info(cm);
          if (cm.type_id == SE_TAG_TYPE_TAG && cm.class_name == "") {
             if (cm.member_name == suffix || endsWith(cm.member_name, ":":+suffix)) {
                found_tags :+= cm.member_name;
             }
          }
          status = tag_next_global(SE_TAG_TYPE_TAG, 0, 0);
       }

       _str tagfile_list[];
       tagfile_list :+= tag_filename;
       foreach (auto tag_class in found_tags) {
          tag_list_in_class(lastid_prefix, tag_class,
                            0, 0, tagfile_list,
                            num_matches, max_matches,
                            SE_TAG_FILTER_MEMBER_VARIABLE,SE_TAG_CONTEXT_ONLY_INCLASS,
                            exact_match, case_senstive, null, null, 
                            visited, depth+1);
          if (num_matches >= max_matches) break;
          if (_CheckTimeout()) break;
       }
       tag_reset_find_in_class();
   }
}

void _xml_insert_namespace_context_tags_attr_values(_str NamespaceHashtab:[],
                                                    _str lastid,_str lastid_prefix,
                                                    _str match_tag_name,
                                                    _str match_attr_name,
                                                    bool is_attrib,_str clip_prefix, 
                                                    int &num_matches, int max_matches,
                                                    int start_or_end=0,
                                                    bool exact_match=false, 
                                                    bool case_senstive=false, 
                                                    VS_TAG_RETURN_TYPE (&visited):[]=null,
                                                    int depth=0)
{
   only_prefix := "";
   i := pos(':',match_tag_name);
   suffix := match_tag_name;
   if (i) {
      only_prefix=substr(match_tag_name,1,i-1);
      suffix=substr(match_tag_name,i+1);
   }

   tag_init_tag_browse_info(auto cm);

   foreach (auto prefix => auto namespace_name in NamespaceHashtab) {
       if (prefix!=only_prefix) {
          continue;
       }

       tag_filename := "";
       if (_xml_NamespaceToTagFile(tag_filename, namespace_name, depth+1) < 0) {
          continue;
       }

       _str found_tags[];
       found_tags :+= match_tag_name;
       this_prefix := "";
       status := tag_find_global(SE_TAG_TYPE_TAG,0,0);
       while (!status) {
          tag_get_tag_browse_info(cm);
          if (cm.type_id == SE_TAG_TYPE_TAG && cm.class_name == "") {
             if (cm.member_name == suffix || endsWith(cm.member_name, ":":+suffix)) {
                found_tags :+= cm.member_name;
             }
          }
          status = tag_next_global(SE_TAG_TYPE_TAG, 0, 0);
       }

       _str tagfile_list[];
       tagfile_list :+= tag_filename;
       foreach (auto tag_class in found_tags) {
          tag_list_in_class(lastid_prefix, 
                            tag_class :+ VS_TAGSEPARATOR_class :+ match_attr_name,
                            0, 0, tagfile_list,
                            num_matches, max_matches,
                            SE_TAG_FILTER_ENUM,SE_TAG_CONTEXT_ONLY_INCLASS,
                            exact_match, case_senstive, null, null, 
                            visited, depth+1);
          if (num_matches >= max_matches) break;
          if (_CheckTimeout()) break;
       }
       tag_reset_find_in_class();
   }
}

#region Options Dialog Helper Functions

defeventtab _urlmappings_form;

static _str URLMAPPINGS_MODIFIED(...) {
   if (arg()) ctlok.p_user=arg(1);
   return ctlok.p_user;
}

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
   URLMAPPINGS_MODIFIED(0);
}

bool _urlmappings_form_is_modified()
{
   return (URLMAPPINGS_MODIFIED() != 0 || 
           def_url_mapping_search_directory != ctl_UM_defaultSearchDir_text.p_text);
}

bool _urlmappings_form_apply()
{
   gDTDsWarnedAbout._makeempty();
   if (ctltree1.okURLMappings()) {
      return false;
   }
   return true;
}


/**
 * This function returns a XMLCFG tree handle to the "options.xml" file.
 *
 * @return If successful, an XMLCFG tree handle to "options.xml" is returned.
 *         Otherwise a negative return code.  If the "options.xml" file does not exist, it is created.
 */
static int _cfg_get_useroptions()
{
   int *phandle = _GetDialogInfoHtPtr(OPTIONS_XML_HANDLE, _mdi);
   if (phandle != null && *phandle>=0) {
      return *phandle;
   }

   int options_handle = _plugin_get_profile(VSCFGPACKAGE_MISC,VSCFGPROFILE_URL_MAPPINGS);
   if (options_handle<0) {
      options_handle=_xmlcfg_create_profile(auto profile_node,VSCFGPACKAGE_MISC,VSCFGPROFILE_URL_MAPPINGS,VSCFGPROFILE_URL_MAPPINGS_VERSION);
   }

   _SetDialogInfoHt(OPTIONS_XML_HANDLE, options_handle, _mdi);
   return(options_handle);
}

static int _cfg_save_useroptions(bool quiet = false)
{
   int options_handle = _cfg_get_useroptions();
   if (options_handle < 0) {
      return ERROR_WRITING_FILE_RC;;
   }
   _plugin_set_profile(options_handle);
   return(0);
}

_str _urlmappings_form_build_export_summary(PropertySheetItem (&summary)[])
{
   error := "";
   
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
      int urlmappings_index = _xmlcfg_get_first_child_element(handle);
      if (urlmappings_index>=0) {
         int index=_xmlcfg_get_first_child_element(handle,urlmappings_index);
         while (index>=0) {
            
            psi.Caption = _xmlcfg_get_attribute(handle,index,VSXMLCFG_PROPERTY_NAME);         
            psi.Value = _xmlcfg_get_attribute(handle,index,VSXMLCFG_PROPERTY_VALUE);
            summary[summary._length()] = psi;
      
            index=_xmlcfg_get_next_sibling(handle,index);
         }
      }
   }
   
   return error;
}

_str _urlmappings_form_import_summary(PropertySheetItem (&summary)[])
{
   error := "";
   
   handle := _cfg_get_useroptions();
   urlmappings_index := _xmlcfg_get_first_child_element(handle);

   if (urlmappings_index >= 0) {
   
      foreach (auto psi in summary) {
         
         if (psi.Caption == 'Default search directory') {
            // this might be coming from another operating system, so we 
            // will try flipping the fileseps
            psi.Value = stranslate(psi.Value, FILESEP, FILESEP2);

            // make sure it exists...
            if (psi.Value == "" || file_exists(psi.Value)) {
               def_url_mapping_search_directory = psi.Value;
               _config_modify_flags(CFGMODIFY_DEFVAR);
            } else {
               error :+= psi.Value' does not exist.'OPTIONS_ERROR_DELIMITER;
            }
         } else {
            // this is a mapping...
            psi.Value = stranslate(psi.Value, FILESEP, FILESEP2);

            // check for duplicates...
            xml_index := _xmlcfg_find_simple(handle, "//p[@n='"psi.Caption"']", urlmappings_index);
            if (xml_index < 0) {
               // no duplicate, so just add a new one
               xml_index = _xmlcfg_add_property(handle, urlmappings_index,psi.Caption,psi.Value);
            } else {
               _xmlcfg_set_attribute(handle, xml_index, VSXMLCFG_PROPERTY_VALUE, psi.Value);
            }
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
                           "From", "-bf To");

   // user cancelled
   if (status == COMMAND_CANCELLED_RC) return;

   // get the results, add them to the tree
   ctltree1._TreeAddItem(TREE_ROOT_INDEX,
                         _param1"\t"_param2,
                         TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);

   URLMAPPINGS_MODIFIED(1);
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
                           "From:"from, "-bf To:"to);

   // user cancelled
   if (status == COMMAND_CANCELLED_RC) return;

   // get the results, add them to the tree
   ctltree1._TreeSetCaption(index, _param1"\t"_param2);

   URLMAPPINGS_MODIFIED(1);
}

void ctlok.on_create(_str new_item=null)
{
   ctl_UM_defaultSearchDir_text.p_text = def_url_mapping_search_directory;
   int list_width=_dx2lx(SM_TWIP,ctltree1.p_client_width intdiv 2);
   wid := p_window_id;
   p_window_id=ctltree1;
   _TreeSetColButtonInfo(0,list_width,0,0,"From");
   _TreeSetColButtonInfo(1,MAXINT,0,0,"To");
   p_window_id=wid;

   // disable at first because there is nothing in the tree
   ctledit.p_enabled = ctldelete.p_enabled = false;

   typeless handle=_cfg_get_useroptions();
   if (handle<0) {
      p_active_form._delete_window("");
      return;
   }
   found := false;
   int urlmappings_index=_xmlcfg_get_first_child_element(handle);
   if (urlmappings_index>=0) {
      int index=_xmlcfg_get_first_child_element(handle,urlmappings_index);
      while (index>=0) {
         ctltree1._TreeAddItem(TREE_ROOT_INDEX,
                               _xmlcfg_get_attribute(handle,index,VSXMLCFG_PROPERTY_NAME)"\t"_xmlcfg_get_attribute(handle,index,VSXMLCFG_PROPERTY_VALUE),
                               TREE_ADD_AS_CHILD, 0, 0, TREE_NODE_LEAF);
         if (new_item!=null && _xmlcfg_get_attribute(handle,index,VSXMLCFG_PROPERTY_NAME)==new_item) {
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

static bool okURLMappings()
{
   list := "";
   typeless handle=_cfg_get_useroptions();
   def_url_mapping_search_directory = ctl_UM_defaultSearchDir_text.p_text;
   _config_modify_flags(CFGMODIFY_DEFVAR);

   int urlmappings_index=_xmlcfg_get_first_child_element(handle);
   if (urlmappings_index>=0) {
      _xmlcfg_delete(handle,urlmappings_index,true);
   }
   if(_TreeGetNumChildren(TREE_ROOT_INDEX) > 0) {
      addafter_index := -1;
      index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for(; index >= 0; ) {
         // get the caption and skip the node reserved for new entry
         From := To := "";
         parse _TreeGetCaption(index) with From"\t"To;
         if (From=="" || To=="") {
            _message_box('From or To field can not be blank');
            _TreeSetCurIndex(index);
            return(true);
         }
         _xmlcfg_add_property(handle,urlmappings_index,From,To);

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
   URLMAPPINGS_MODIFIED(1);

}

void ctltree1.'DEL'()
{
   ctltree1.doDelete();
}

void ctldelete.lbutton_up()
{
   ctltree1.doDelete();
}

void _urlmappings_form.on_resize()
{
   padding := ctltree1.p_x;

   widthDiff := p_width - (ctladd.p_x_extent + padding);
   heightDiff := p_height - (ctl_UM_defaultSearchDir_text.p_y_extent + padding);

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

   // size the buttons to the textbox
   rightAlign := p_active_form.p_width - ctltree1.p_x;
   sizeBrowseButtonToTextBox(ctl_UM_defaultSearchDir_text, 
                             ctl_UM_browseSearchDirectory_button.p_window_id,
                             0, rightAlign);

   alignUpDownListButtons(ctltree1.p_window_id, 
                          rightAlign, 
                          ctladd.p_window_id, 
                          ctledit.p_window_id, 
                          ctldelete.p_window_id);
}

static void setDirectoryPathText()
{
   wid := p_window_id;
   _str result = _ChooseDirDialog("",p_prev.p_text);
   if( result=="" ) {
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
void ctlURLMappings.on_create(int status=FILE_NOT_FOUND_RC,_str local_dtd_filename='dtd-filename',_str buf_name='buf_name',_str info="")
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
_command int open_url(_str URLFilename="") name_info(','VSARG2_REQUIRES_MDI|VSARG2_READ_ONLY)
{
   _str result = URLFilename;
   _macro_delete_line();
   options := "";
   if (result=="") {
      _param1=1;
      _param2=0;
      result=show('-modal _openurl_form');
      if (result=="") {
         return(COMMAND_CANCELLED_RC);
      }
      if (_param1) {
         options=' +cache ';
      } else {
         options=' -cache';
      }
      if (_param2) {
         options :+= ' +header ';
      } else {
         options :+= ' -header ';
      }
   } else {
      result=strip_options(result,options,true);
      if (options!="") options :+= ' ';
   }
   if (!_isHTTPFile(result)) {
      protocol := rest := "";
      parse result with protocol '://' +0 rest;
      if (rest!="") {
         _message_box('Only HTTP transfers are supported');
         return(1);
      }
      result='http://'result;
   }
   result=_maybe_quote_filename(result);
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
bool def_url_support=true;

defeventtab _uri_schemes_form;

void _uri_schemes_form_init_for_options ()
{
   _str schemes[];
   _str scheme;
   _str schemeList = def_uri_scheme_list;
   while (schemeList != "") {
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


bool _uri_schemes_form_is_modified ()
{
   if (_GetDialogInfoHt('modified', _uri_items)) {
      return true;
   }
   return false;
}

#endregion


void change_URI_schemes ()
{
   newSchemes := "";
   _uri_items._lbsort();
   _uri_items._lbtop();
   _uri_items._lbup();
   while (!_uri_items._lbdown()) {
      newSchemes :+= ' '_uri_items._lbget_text();
   }
   newSchemes = strip(newSchemes);
   def_uri_scheme_list = newSchemes;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void _ctl_add.lbutton_up ()
{
   typeless newURIScheme = 0;

   newURIScheme = show('-modal _newURI_form');

   if (newURIScheme == "") {
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
   if (_uri_items._lbget_text() != "") {
      _SetDialogInfoHt('modified', true, _uri_items);
   }
   _uri_items._lbdelete_item();
   _uri_items.p_text = _uri_items._lbget_text();
   _uri_items._lbselect_line();
}


defeventtab _newURI_form;


_ok.lbutton_up ()
{
   problems := false;
   URIscheme := ctl_URIscheme.p_text;

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
   p_active_form._delete_window("");
}

defeventtab _openurl_form;
void ctlcombo1.on_change(int reason)
{
   enabled := p_text!="";
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
   ctlemptycache.p_enabled= (p_value==0);
}
void ctlok.lbutton_up()
{
   typeless result=translate(ctlcombo1.p_text,'/','\');
   if (!_isHTTPFile(result)) {
      protocol := rest := "";
      parse result with protocol '://' +0 rest;
      if (rest!="") {
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

void ctlemptycache.lbutton_down()
{
   clear_url_cache();
}

static _str clear_url_cache_cb(int reason, typeless user_data, typeless info=null)
{
   configDir := _ConfigPath();
   _maybe_append_filesep(configDir);
   switch (reason) {
   case SL_ONDELKEY:
      _TreeGetSelectionIndices(auto indices);
      if (indices._length() <= 0) {
         indices[0] = _TreeCurIndex();
      }
      foreach (auto index in indices) {
         path := _TreeGetCaption(index);
         delete_file(configDir:+path);
         _TreeDelete(index);
      }
   }
   return "";
}

/**
 * Clear the URL / Http file cache.  Lists the files cached and allows you to 
 * selectively delete items or delete everything. 
 * 
 * @param wildcards    file wildcars for specific files or file types to clean up. 
 *  
 * @categories File_Functions
 */
_command void clear_url_cache(_str wildcards="") name_info(',')
{
   path := "";
   _str cachedUrlFiles[];
   configDir := _ConfigPath();
   _maybe_append_filesep(configDir);

   mou_hour_glass(true);
   orig_view_id := _create_temp_view(auto filelist_view_id);
   foreach (auto protocol in "http https ftp ftps") {
      filelist_view_id.insert_file_list("+T +P -D -U -V ":+_maybe_quote_filename(configDir:+protocol:+FILESEP:+wildcards));
   }

   filelist_view_id.top();
   loop {
      filelist_view_id.get_line(path);
      path = strip(path);
      if (path != "") {
         cachedUrlFiles :+= relative(path, configDir);
      }
      if (filelist_view_id.down()) {
         break;
      }
   }

   activate_window(orig_view_id);
   _delete_temp_view(filelist_view_id);
   mou_hour_glass(false);

   if (cachedUrlFiles._length() <= 0) {
      _message_box("URL cache is empty.");
      return;
   }

   result := select_tree(cap_array:cachedUrlFiles, 
                         callback:clear_url_cache_cb,
                         caption:"Select files to delete from URL cache", 
                         sl_flags:SL_FILENAME|SL_SELECTALL|SL_DELETEBUTTON|SL_ALLOWMULTISELECT|SL_COMBO|SL_INVERT|SL_DEFAULTCALLBACK);
   if (result == COMMAND_CANCELLED_RC || result == "") {
      return;
   }
   // delete the files they selected
   foreach (path in result) {
      delete_file(configDir:+path);
   }
}

/**
 * Display a string in the XML Output tab
 *
 * @param str Message to display
 * @param highlight non zero if the line should be highlighted
 *
 */
void _xml_display_output(_str str, bool highlight = false)
{
   bottom();
   str = strip(str, 'T', "\n\r");
   insert_line(str);
   if (highlight) {
      p_col=1;_SetTextColor(CFG_FILENAME,_line_length(),false);

   }
}


bool isXMLErrorLine()
{
   _str line, rest;
   get_line(line);
   parse line with line rest;
   if (lowcase(line)=='file' || lowcase(line)=='document') {
      return false;
   }
   linetype := "";
   parse rest with line linetype rest;
   if (lowcase(linetype)=="error") {
      return true;
   }
   return false;
}

int xmlMoveToError(bool next = true)
{
   //int formwid=_find_formobj('_tboutputwin_form','N');
   formwid := tw_find_form('_tboutputwin_form');
   _nocheck _control ctloutput;
   if (!formwid) {
      formwid = activate_tool_window('_tboutputwin_form');
      if (!formwid) return -1;
      formwid.ctloutput._delete_line();
   }
   if (!formwid) return -1;
   wid := p_window_id;
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


int _switch_to_xml_output(bool clear = false)
{
    formwid := _find_formobj('_tboutputwin_form','N');
    _nocheck _control ctloutput;
    if (!formwid) {
       formwid = activate_tool_window('_tboutputwin_form');
       if (!formwid) return -1;
       formwid.ctloutput._delete_line();
    }
    if (!formwid) return -1;
    wid := p_window_id;
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
 * @param handle     the handle to the XML document returned from
 *                   {@link _xml_open} or {@link _xml_open_from_buffer}
 *
 * @return 0 if successful, non zero otherwise
 *
 */
int xmlshowErrors(int handle, _str name, int flags, bool gotoError, bool isAutoValidation)
{
   errcnt := _xml_get_num_errors(handle);
   // RGH - 4/26/2006
   // For the plugin, have to get the right window ID
   formwid := 0;
   if (!isEclipsePlugin()) {
      // no need to give focus to Output tool window if there are no errors
      // and this is an auto-validation case
      if (isAutoValidation && errcnt == 0) {
         formwid = _find_formobj('_tboutputwin_form','N');
      }
      if (!formwid) {
         formwid = activate_tool_window('_tboutputwin_form', 
                                        set_focus: !(isAutoValidation && errcnt == 0),
                                        focus_control_name: "", 
                                        restore_group: false);
      }
   } else {
      formwid = xmlQFormWID();
   }
   if (!formwid) return -1;

   se.messages.MessageCollection* mCollection = get_messageCollection();
   mCollection->removeMessages(XML_VALIDATION_MESSAGE_TYPE);

   _nocheck _control ctloutput;
   formwid.ctloutput._delete_line();
   wid := p_window_id;
   p_window_id=formwid.ctloutput;
   _lbclear();
   errcnt = _xml_get_num_errors(handle);
   if (errcnt==0) {
      _xml_display_output("File "name, true);
      msg := "";
      if (flags != VSXML_VALIDATION_SCHEME_WELLFORMEDNESS) {
         msg = "Document is valid";
      } else {
         msg = "Document is well-formed";
      }
      _xml_display_output("    ":+msg);
      _xml_display_output("");
      if (isAutoValidation) {
         notifyUserOfFeatureUse(NF_AUTO_XML_VALIDATION, name, 0, "", msg);
      }
   } else {
      if (isAutoValidation) {
         notifyUserOfWarning(ALERT_XML_ERROR, "Document has ":+errcnt:+" errors.", name);
      }
      oldfn := "";
      int i;
      line := col := 0;
      fn := msg := "";
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
            tmpMsg.m_date = "";
            mCollection->newMessage(tmpMsg);
         }
      }
      mCollection->endBatch();
      mCollection->notifyObservers();
      _xml_display_output("");

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
         linenum := colnum := 0;
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
int xmlparse(int flags, bool gotoError=true, bool isAutoValidation=false)
{
   showErrorFlag := 1;

   mou_hour_glass(true);
   typeless status = 0;
   typeless handle = _xml_open_from_control(p_window_id,status,flags);

   if (status < 0) {
      mou_hour_glass(false);

      buffName := _build_buf_name();
      dirName := _strip_filename(buffName, 'EN');
      if (status == ACCESS_DENIED_RC) {
         _message_box("Error parsing "buffName"\nUnable to write temporary work file in directory "dirName"\nReason: "get_message(status)"\nVerify space is available and that you have proper permissions.");
         message(get_message(status));
         return status;
      } else {
         _message_box(get_message(status));
         return status;
      }
   }

   xmlshowErrors(handle, _build_buf_name(), flags, gotoError, isAutoValidation);
   errcnt := _xml_get_num_errors(handle);
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
   mou_hour_glass(false);
   return errcnt;
}

int _OnUpdate_xml_validate(CMDUI &cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }
   lang := target_wid.p_LangId;
   if (!_haveXMLValidation()) {
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         _menuRemoveExtraSeparators(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO_OR_STANDARD;
      }
      return MF_GRAYED|MF_REQUIRES_PRO_OR_STANDARD;
   }
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
_command int xml_validate() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveXMLValidation()) {
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
   return xmlparse(VSXML_VALIDATION_SCHEME_VALIDATE);
}

/**
 * Check the well-formedness of the buffer in the current window
 *
 */
_command int xml_wellformedness() name_info(','VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveXMLValidation()) {
      return VSRC_FEATURE_REQUIRES_PRO_OR_STANDARD_EDITION;
   }
   gXMLAutoValidateBehavior=VSXML_AUTOVALIDATE_BEHAVIOR_ENABLE;
   return xmlparse(VSXML_VALIDATION_SCHEME_WELLFORMEDNESS);
}

_command void xml_validatefile(_str filename="") name_info(','VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION)
{
   if (!_haveXMLValidation()) {
      return;
   }
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
   xmlshowErrors(handle, param, 
                 VSXML_VALIDATION_SCHEME_VALIDATE, 
                 gotoError:false, 
                 isAutoValidation:false);
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
int _xml_find_matching_word(bool quiet,int pmatch_max_diff_ksize=MAXINT,int pmatch_max_level=MAXINT)
{
   if (pmatch_max_diff_ksize!=MAXINT) {
      if (p_buf_size>def_xml_max_smart_editing_ksize*1024) {
      //if (p_buf_size>def_pmatch_max_ksize*1024) {
         return(-1);
      }
   }
   return(htool_matchtag(quiet,pmatch_max_diff_ksize,pmatch_max_level));
}

int _ant_get_expression_info(bool PossibleOperator, VS_TAG_IDEXP_INFO &info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator, info, visited, depth);
}

_str _ant_get_decl(_str lang, VS_TAG_BROWSE_INFO &info, int flags=0, _str decl_indent_string="",
                 _str access_indent_string="", _str (&header_list)[] = null)
{
   if (info == null) {
      return "";
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
                           bool find_parents,int max_matches,
                           bool exact_match, bool case_sensitive,
                           SETagFilterFlags filter_flags=SE_TAG_FILTER_ANYTHING,
                           SETagContextFlags context_flags=SE_TAG_CONTEXT_ALLOW_LOCALS,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0,
                           VS_TAG_RETURN_TYPE &prefix_rt=null)
{
   return _java_find_context_tags(errorArgs,prefixexp,lastid,lastidstart_offset,
                                  info_flags,otherinfo,false,max_matches,
                                  exact_match,case_sensitive,
                                  filter_flags,context_flags,
                                  visited,depth,prefix_rt);
}

bool _xml_event_cancels_surround(_str event)
{
   // Strict on ending the surround once typing starts, to avoid
   // getting into a situation where an event being handed in 
   // do_surround_keys would initiate another recursive surround.
   return vsIsKeyEvent(event2index(event));
}

void _xml_snippet_find_leading_context(long selstart, long selend)
{
   _html_snippet_find_leading_context(selstart,selend);
}

#if 0

int _xml_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                             _str tag_name, _str class_name,
                             _str type_name, SETagFlags tag_flags,
                             _str file_name, _str return_type,
                             struct VS_TAG_RETURN_TYPE &rt,
                             struct VS_TAG_RETURN_TYPE (&visited):[],
                             int depth=0)
{
   if (_chdebug) {
      isay(depth, "_xml_analyze_return_type: IN");
   }
   save_pos(auto p);
   status := _xml_parent(auto parent_tag_name);
   if (status > 0 && parent_tag_name != "") {
      if (_chdebug) {
         isay(depth, "_xml_analyze_return_type: parent tag="parent_tag_name);
      }
      tag_push_matches();
      num_parent_tags := 0;
      status = tag_list_context_globals(0, 0, 
                                        parent_tag_name, true, 
                                        tag_files, 
                                        SE_TAG_FILTER_MISCELLANEOUS, 
                                        SE_TAG_CONTEXT_ANYTHING, 
                                        num_parent_tags, 10, 
                                        true, true,
                                        visited, depth+1);
      bool tagsAllowedInContextModel:[];
      num_parent_tags = tag_get_num_of_matches();
      for (i:=1; i<=num_parent_tags; i++) {
         tag_get_match_browse_info(i, auto parent_cm);
         if (parent_cm.arguments != null) {
            word_re := _clex_identifier_re();
            word_re = stranslate(word_re, '', '?');
            arg_pos := 1;
            loop {
               status = pos(word_re, parent_cm.arguments, arg_pos, 'r');
               if (status <= 0) break;
               arg_pos = status+pos('');
               child_tag_name := get_match_substr(parent_cm.arguments);
               if (!tagsAllowedInContextModel._indexin(child_tag_name)) {
                  rt.return_type = child_tag_name;
                  tag_return_type_init(auto child_rt);
                  child_rt.return_type = child_tag_name;
                  rt.alt_return_types :+= child_rt;
                  tagsAllowedInContextModel:[child_tag_name] = true;
                  if (_chdebug) {
                     isay(depth+1, "_xml_analyze_return_type: FOUND: "child_tag_name);
                  }
               }
            }
         }
      }
      tag_pop_matches();
      return 0;
   }
   if (_chdebug) {
      isay(depth, "_xml_analyze_return_type: OUT");
   }
   return status;
}


int _xml_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                           struct VS_TAG_RETURN_TYPE &rt_candidate,
                           _str tag_name,_str type_name, 
                           SETagFlags tag_flags,
                           _str file_name, int line_no,
                           _str prefixexp,typeless tag_files,
                           int tree_wid, int tree_index,
                           VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   if (_chdebug) {
      isay(depth, "_xml_match_return_type: IN");
      tag_return_type_dump(rt_expected,  "_xml_match_return_type: EXPECTED");
      tag_return_type_dump(rt_candidate, "_xml_match_return_type: CANDIDATE");
   }

   if (_chdebug) {
      isay(depth, "_xml_match_return_type: OUT");
   }

   return 0;
}



/**
 * get the position of a comparible identifier in the
 * current expression that we can use to determine the expected
 * return type
 *
 * @param lhs_start_offset   (reference) seek position of matching identifier
 * @param expression_op      (reference) expression operator
 * @param pointer_count      (reference) set to number of times lhs is dereferenced
 *                           either through an array operator or * (future fix)
 * @param depth              (optional) recursive call depth for debugging 
 *
 * @return 0 on success, non-zero otherwise
 */
int _xml_get_expression_pos(int &lhs_start_offset,
                            _str &expression_op,
                            int &pointer_count,
                            int depth=0)
{
   if (_chdebug) {
      isay(depth, "_xml_get_expression_pos: IN");
   }
   save_pos(auto p);
   status := _xml_parent(auto parent_tag_name);
   if (status > 0 && parent_tag_name != "") {
      if (_chdebug) {
         isay(depth, "_xml_get_expression_pos: parent tag="parent_tag_name);
      }
      lhs_start_offset = (int)_QROffset();
      expression_op = parent_tag_name;
      pointer_count = 0;
      restore_pos(p);
      return 0;
   }
   if (_chdebug) {
      isay(depth, "_xml_get_expression_pos: OUT");
   }
   restore_pos(p);
   return status;
}

#endif
