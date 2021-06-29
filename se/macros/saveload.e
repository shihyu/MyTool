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
//#include "os390.sh"
#require "se/lang/api/LanguageSettings.e"
#require "se/lang/api/ExtensionSettings.e"
#import "backtag.e"
#import "files.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "filewatch.e"
#import "autosave.e"
#endregion

using se.lang.api.LanguageSettings;
using se.lang.api.ExtensionSettings;

no_code_swapping   /* Just in case there is an I/O error reading */
                   /* the slick.sta file, this will ensure user */
                   /* safe exit and save of files.  */


int def_maxbackup_ksize=20000;

/**
 * Writes current buffer to filename.  This function is a hook function 
 * that the user may replace.  Options allowed by <b>_save_file</b> 
 * built-in may be specified.
 * @param filename parameter should not contain options.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */
_str save_file(_str filename,_str options)
{
#if 0
   int renumber_flags=numbering_options();
   if (renumber_flags&VSRENUMBER_AUTO) {
      if (renumber_flags&VSRENUMBER_COBOL) {
         renumber_lines(1,6,'0',false,true);
      }
      if (renumber_flags&VSRENUMBER_STD) {
         renumber_lines(73,80,'0',false,true);
      }
   }
#endif
   typeless status=_save_file(options " "_maybe_quote_filename(filename));
   if (!status && _file_eq(strip(filename,'B','"'),p_buf_name)) {
      if (p_modified_temp_name!='') {
         _as_removefilename(p_modified_temp_name,true);
         p_modified_temp_name='';
      }
      //_cbsave_filewatch();
#if 1
      call_list('_cbsave_');
      //10:51am 7/3/1997
      //Dan modified for auto-tagging
      if (def_autotag_flags2&AUTOTAG_ON_SAVE) {
         //messageNwait(nls('got here'));
         TagFileOnSave();
      }
#endif
   }
   return(status);

}
/**
 * Deletes the current buffer.  This function is a hook function and may 
 * be replaced.
 * 
 * @appliesTo Edit_Window
 * 
 * @categories File_Functions
 * 
 */ 
int quit_file()  /* Remove the current file. */
{
   call_list('_cbquit_',p_buf_id,p_buf_name,p_DocumentName,p_buf_flags);
   int buf_id=p_buf_id;
   _str buf_name=p_buf_name;
   _str doc_name=p_DocumentName;
   int buf_flags=p_buf_flags;
  _delete_buffer();   /* In the case of a remote file, there */
                      /* might be a temp file which should be */
                      /* deleted here. */
  call_list('_cbquit2_',buf_id,buf_name,doc_name,buf_flags);
  return(0);

}
/**
 * Renames current buffer to <i>filename</i> specified.  <i>filename</i> is 
 * converted to absolute (exact path specification).
 * 
 * @return Returns 0 if successful.  Otherwise a non-zero return code is 
 * returned.
 *
 * @categories Buffer_Functions
 */
int name_file(_str filename,bool doAbsolute=true)
{
   _str new_name=filename;
   if (doAbsolute) {
      new_name=absolute(strip(filename));
   }
   status := 0;
   // If the new file name is a data set and the old buffer is not
   // in read-only mode, put an ENQ on the new data set name.
   int eStatus;
   _str oldName=p_buf_name;

   // Rename buffer.
   status = name_file2(new_name);

   return(status);
}
int name_file2(_str new_name)
{
   call_list('_buffer_renamed_',p_buf_id,p_buf_name,new_name,p_buf_flags);
   _str oldBufName=p_buf_name;
   p_buf_name=  new_name;
   docname("");
   if (p_modified_temp_name!="" && p_buf_name!=new_name) {
      // Let autosave delete this temp file on exit.
      _as_addfilename(p_modified_temp_name);
      p_modified_temp_name="";
   }
   call_list('_buffer_renamedAfter_',p_buf_id,oldBufName,new_name,p_buf_flags);
   return(0);
}
/**
 * 
 *
 * @return
 */

/**
 * Loads filename.  Filename may contain options allowed by 
 * <b>load_files</b> built-in.
 * 
 * @param filename may contain options. Only one filename may be given
 * 
 * @return  Returns 0 if successful.  Otherwise an error code 
 * is returned in which negative numbers are valid input codes 
 * to the <b>get_message</b> built-in.  On error, message is displayed.
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Edit_Window_Methods, Editor_Control_Methods, File_Functions
 */
_str edit_file(_str filename)
{
   return(load_files(filename));

}

// (Clark) Don't want to carry over previous version default settings so I
// changed the name of the variable.
_str def_xml_ext3=".xml .ent";

_str def_internal_utf8_ext3=".als .api .vlx .vpwhist .vpwhistu";

//*.api
static bool gConfigFileEncodingHashTab:[ ]= {
//User configuration files that are UTF-8
   "asciitab"=>false,
   "asciitab.u"=>false,
   "vslick.ini"=>true,
   "user.vlx"=>true,
   "alias.slk"=>true,
   "uprint.ini"=>true,
   "usscheme.ini"=>true,
   "usrpacks.slk"=>true,
   "ubox.ini"=>true,   // Old configuration file
   "projects.slk"=>true, "uproject.slk"=>true,
   "uservc.slk"=>true,
   "uformat.ini"=>true,  // Old configuration file
   "vrestore.slk"=>true,
   //"*.als"=>true,

   "diffmap.ini"=>true,
   "filepos.slk"=>true,
   "selmode.ini"=>true,
// User configuration files that are NOT UTF-8
   //"usercpp.h"=>false

// System configuration files that are UTF-8
   //"vslick.ini"=>true,  already listed
   "vslick.vlx"=>true,
   //"alias.slk"=>true, already listed
   "print.ini"=>true,
   "box.ini"=>true,    // Old configuration file
   "vsscheme.ini"=>true,
   "prjpacks.slk"=>true, "uprjpack.slk"=>true,
   "vcsystem.lk"=>true, "uvcsys.slk"=>true,
   "format.ini"=>true,  // Old configuration file
   //"cob.als"=>true,
   "vslick.vsm"=>true,

   "vslick.lst"=>true,"uvslick.lst"=>true,


   "c.api"=>true,
   "java.api"=>true,
   "js.api"=>true,
   "mfc.api"=>true,
   "os2.api"=>true,
   "unixc.api"=>true,
   "unixx11.api"=>true,
   "unixxm.api"=>true,
   "win32.api"=>true,
   "state.slk"=>true,
   "windowstate.slk"=>true,
   "layoutstate.ini"=>true,
// System configuration files that NOT UTF-8
   //"syscpp.h"=>false,
   //(** Spelling) "smain.dct"=>false, "scommon.lst"=>false,
   //*.tagdoc=>false, builtins.*=>false, *.c=>false, *.h=>false, *.java=>false, *.e=>false, *.h=>false,

// Configuration Files with undetermined encoding or that
// might not exist in verision 7.0
   //"ftp.ini"=>true,"uftp.ini"=>true,
};

_str _load_option_encoding(_str filename,int &encoding_set_by_user=-1)
{
   if (_DataSetIsFile(filename)) {
      return('');
   }

   typeless seekpos=0;
   col := 0;
   hex_mode := 0;
   SelDispTempNum := "";
   XWscheme := XWoptions := "";
   SoftWrap := 0;
   langId := "";
   if (!isEclipsePlugin()) {

      PERFILEDATA_INFO info;
      if (!_filepos_get_info(filename,info)) {
         encoding_set_by_user = info.m_encodingSetByUser;
         if (info.m_encodingSetByUser>=0) {
            return(_EncodingToOption(info.m_encodingSetByUser));
         }
      }
   }

   // try the encoding for the extension
   _str ext=_get_extension(filename);
   encoding := ExtensionSettings.getEncoding(ext, '');
   if (encoding != '') {
      return encoding;
   }

   if ( pos(' .'ext' ',' 'def_xml_ext3' ',1,_fpos_case) ) {
      return('+fautoxml');
   } else {
      if ( pos(' .'langId' ',' 'def_xml_ext3' ',1,_fpos_case) ) {
         return('+fautoxml');
      }
   }
   if ( pos(' .'ext' ',' 'def_internal_utf8_ext3' ',1,_fpos_case) ) {
      return('+futf8');
   } else {
      if ( pos(' .'langId' ',' 'def_internal_utf8_ext3' ',1,_fpos_case) ) {
         return('+futf8');
      }
   }
   utf8 := gConfigFileEncodingHashTab:[_strip_filename(_file_case(filename),'P')];
   if (utf8==null) {
      if (isinteger(def_encoding)) {
         def_encoding='+fautounicode2';
         _config_modify_flags(CFGMODIFY_DEFVAR);
         _SlickEditUtil_UpdateOptions();
      }
      if (def_encoding!='') {
         return(def_encoding);
      }
      return('');
   }
   if (!utf8) {
      return '+fautotext';
   }
   return('+futf8');
}

_str _EncodingToOption(int encoding)
{
   switch (encoding) {
   case VSCP_ACTIVE_CODEPAGE:
      return('+ftext');
   case VSCP_EBCDIC_SBCS:
      return('+febcdic');
   case VSENCODING_UTF8:
      return('+futf8');
   case VSENCODING_UTF8_WITH_SIGNATURE:
      return('+futf8s');
   case VSENCODING_UTF16LE:
      return('+futf16le');
   case VSENCODING_UTF16LE_WITH_SIGNATURE:
      return('+futf16les');
   case VSENCODING_UTF16BE:
      return('+futf16be');
   case VSENCODING_UTF16BE_WITH_SIGNATURE:
      return('+futf16bes');
   case VSENCODING_UTF32LE:
      return('+futf32le');
   case VSENCODING_UTF32LE_WITH_SIGNATURE:
      return('+futf32les');
   case VSENCODING_UTF32BE:
      return('+futf32be');
   case VSENCODING_UTF32BE_WITH_SIGNATURE:
      return('+futf32bes');
   case VSENCODING_AUTOUNICODE:
   case VSENCODING_AUTOUNICODE|VSENCODING_AUTOTEXT:
      return('+fautounicode');
   case VSENCODING_AUTOUNICODE2:
   case VSENCODING_AUTOUNICODE2|VSENCODING_AUTOTEXT:
      return('+fautounicode2');
   case VSENCODING_AUTOEBCDIC:
   case VSENCODING_AUTOEBCDIC|VSENCODING_AUTOTEXT:
      return('+fautoebcdic');
   case VSENCODING_AUTOEBCDIC_AND_UNICODE:
   case VSENCODING_AUTOEBCDIC_AND_UNICODE|VSENCODING_AUTOTEXT:
      return('+fautoebcdic,unicode');
   case VSENCODING_AUTOEBCDIC_AND_UNICODE2:
   case VSENCODING_AUTOEBCDIC_AND_UNICODE2|VSENCODING_AUTOTEXT:
      return('+fautoebcdic,unicode2');
   case VSENCODING_AUTOXML:
      return('+fautoxml');
   case VSENCODING_AUTOHTML:
      return('+fautohtml');
   case VSENCODING_AUTOHTML5:
      return('+fautohtml5');
   case VSENCODING_AUTOTEXT:
      return('+fautotext');
   case VSENCODING_AUTOTEXTUNICODE:
      return('+fautotextunicode');
   default:
      return('+fcp'encoding);
   }
}

int _OptionToEncoding(_str option)
{
   switch (lowcase(strip(option))) {
   case '+fautounicode':
   case '+fautounicode,text':
      return(VSENCODING_AUTOUNICODE);
   case '+fautounicode2':
   case '+fautounicode2,text':
      return(VSENCODING_AUTOUNICODE2);
   case '+fautoebcdic':
   case '+fautoebcdic,text':
      return(VSENCODING_AUTOEBCDIC);
   case '+fautoebcdic,unicode':
   case '+fautoebcdic,unicode,text':
      return(VSENCODING_AUTOEBCDIC_AND_UNICODE);
   case '+fautoebcdic,unicode2':
   case '+fautoebcdic,unicode2,text':
      return(VSENCODING_AUTOEBCDIC_AND_UNICODE2);
   case '+fautoxml':
      return(VSENCODING_AUTOXML);
   case '+fautohtml':
      return(VSENCODING_AUTOHTML);
   case '+fautohtml5':
      return(VSENCODING_AUTOHTML5);
   case '+fautotext':
      return(VSENCODING_AUTOTEXT);
   case '+fautotextunicode':
      return(VSENCODING_AUTOTEXTUNICODE);
   case '+futf8':
      return(VSENCODING_UTF8);
   case '+futf8s':
      return(VSENCODING_UTF8_WITH_SIGNATURE);
   case '+futf16le':
      return(VSENCODING_UTF16LE);
   case '+futf16les':
      return(VSENCODING_UTF16LE_WITH_SIGNATURE);
   case '+futf16be':
      return(VSENCODING_UTF16BE);
   case '+futf16bes':
      return(VSENCODING_UTF16BE_WITH_SIGNATURE);
   case '+futf32le':
      return(VSENCODING_UTF32LE);
   case '+futf32les':
      return(VSENCODING_UTF32LE_WITH_SIGNATURE);
   case '+futf32be':
      return(VSENCODING_UTF32BE);
   case '+futf32bes':
      return(VSENCODING_UTF32BE_WITH_SIGNATURE);
   case '+facp':
      return(_GetACP());
   }
   if( substr(lowcase(strip(option)),1,length('+fcp'))=='+fcp' ) {
      typeless encoding=substr(option,length('+fcp')+1);
      if( isinteger(encoding) ) {
         return(encoding);
      }
   }
   return(0);
}

_str _EncodingToName(int encoding)
{
   _str encodingOption=_EncodingToOption(encoding);
   // Parse off the "+f" at the beginning to make the name more readable
   encodingName := substr(encodingOption,3);
   return(encodingName);
}

_str _NameToEncoding(_str encodingName)
{
   encodingOption := "+f":+encodingName;
   return( _OptionToEncoding(encodingOption) );
}
/*
This function is a really bad idea because
_load_option_encoding() can return a string with multiple options like "+lb +ftext"
and _OptionToEncoding can't handle this. Caller must do more parsing that this
function is designed to do.

int _load_option_encoding_flag(_str filename)
{
   //return(VSENCODING_AUTOUNICODE);
   _str option=_load_option_encoding(filename);
   return(_OptionToEncoding(option));
} 
*/ 
bool _load_option_UTF8(_str filename)
{
   if (!_UTF8()) return(false);
   typeless encoding=_load_option_encoding(filename);
   switch (substr(encoding,3)) {
   case '':
   case 'autounicode':  // Could open the file to check this one,
                        // but this is probably over kill
   case 'autounicode2':  // Could open the file to check this one,
                        // but this is probably over kill
   case 'autoebcdic':
   case 'autoebcdic,unicode':
   case 'autoebcdic,unicode2':

   case 'text':
      return(false);
   }
   return(true);
}

/** 
 * Returns file load options string based on <i>filename</i> and
 * global settings. The option string returned by this function
 * is valid input to the <b>load_files</b>() function.  This
 * function is used by the edit command.
 * 
 * @returns the file load optiosn string
 * @categories File_Functions
 */
_str build_load_options(_str filename)
{
   _str options=def_load_options;
   env_options := get_env(_SLICKLOAD);
   driveletter := substr(absolute(filename),1,1);
   if ( env_options!='' && isalpha(driveletter) &&
     pos(driveletter'\:{?*}(?\:|$)',env_options,1,'ri') ) {
      options :+= " "substr(env_options,pos('S0'),pos('0'));
   }
   _str bufext=_get_extension(filename);
   if ( pos(' .'bufext' ',' 'def_preload_ext' ',1,_fpos_case) ) {
      options :+= ' +LCZ';
   }
   // -1 means use whatever the user has selected for his/her global encoding.
   encoding_set_by_user := -1;
   _str encoding=_load_option_encoding(filename,encoding_set_by_user);
   /*
      If add support for p_line_endings_set_by_user, will need to add
      the options that are "not set" before the +fenddefaults. The options
      that have a setting need to be added after +fenddefaults.

      p_line_endings_set_by_user=''  // not set
      p_line_endings_set_by_user='+fd' // DOS
      p_line_endings_set_by_user='+fu' // Unix EOL
      p_line_endings_set_by_user='+fm' // Classic Mac
      p_line_endings_set_by_user='+fddd' // Single byte EOL character specified by 1 to 3 decimal digits
   */
   int f2li_flag;
   if (encoding_set_by_user<0) {
      f2li_flag=0;
   } else {
      f2li_flag=F2LI_NO_CHECK_BINARY_DATA;
   }

   _str lang=_Filename2LangId(filename,f2li_flag);
   if (pos('+e ',options' ',1,'i')) {
      _str tabs=LanguageSettings.getTabs(lang);
      increment := "";
      parse tabs with '+'increment;
      if (isinteger(increment) && increment>1) {
         i := pos('+e ',options' ',1,'i');
         options=substr(options,1,i-1):+'+e:'increment:+substr(options,i+2);
      }
   }

   _str fl_opts = _LangGetProperty(lang,VSLANGPROPNAME_LOAD_FILE_OPTIONS);
   if (fl_opts != '') {
      if (pos('+e ',fl_opts' ',1,'i')) {
         _str tabs=LanguageSettings.getTabs(lang);
         increment := "";
         parse tabs with '+'increment;
         if (isinteger(increment) && increment>1) {
            i := pos('+e ',fl_opts' ',1,'i');
            fl_opts=substr(fl_opts,1,i-1):+'+e:'increment:+substr(fl_opts,i+2);
         }
      }
      options :+= ' 'fl_opts;
   }

   if (encoding_set_by_user<0) {
      encoding :+= " +fenddefaults";
   }
   if (encoding!='') {
      options :+= ' ':+encoding;
   }
   if (
       _DataSetIsFile(filename) ||
       (def_load_partial && def_load_partial_ksize > 0)) {
      // push the filesize check into the built-in load_files() call so
      // that we don't check the filesize twice.
      options :+= ' -L:'def_load_partial_ksize;
   }
   // IF .editorconfig file support is enabled
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      EDITOR_CONFIG_PROPERITIES ecprops;
      _EditorConfigGetProperties(filename,ecprops,lang,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
      // Specify line endings for new files.
      if (ecprops.m_property_set_flags & ECPROPSETFLAG_EOL_STYLE) {
         options :+= ' +fn'ecprops.m_eol_style;
      }
   }
   return(options);

}

/** 
 * Returns file save options string based on <i>filename</i> and global settings.  
 * The option string returned by this function is valid input to
 * the <b>_save_file</b>() function.  This function is used by
 * the edit command.
 * 
 * @returns the file save options string
 * 
 * @example
 * <pre>
 * #stop_command ;c; ...
 * 
 *    See replace command.
 * #start
 * </pre>
 * @categories File_Functions
 */
_str build_save_options(_str filename)
{
   _str options=def_save_options;
   env_options := get_env(_SLICKSAVE);
   driveletter := substr(absolute(filename),1,1);
   if ( env_options!='' && isalpha(driveletter) &&
     pos(driveletter'\:{?*}(?\:|$)',env_options,1,'ri')) {
     options :+= " "substr(env_options,pos('S0'),pos('0'));
   }
   _str fs_opts = _LangGetProperty(p_LangId,VSLANGPROPNAME_SAVE_FILE_OPTIONS);
   if (fs_opts != '') {
      options :+= ' 'fs_opts;
   }
   // IF .editorconfig file support is enabled
   if (_default_option(VSOPTION_EDITORCONFIG_FLAGS)) {
      EDITOR_CONFIG_PROPERITIES ecprops;
      _EditorConfigGetProperties(filename,ecprops,p_LangId,_default_option(VSOPTION_EDITORCONFIG_FLAGS));
      // Specify line endings for new files.
      if (ecprops.m_property_set_flags & ECPROPSETFLAG_STRIP_TRAILING_SPACES) {
         if (ecprops.m_strip_trailing_spaces) {
            options :+= ' +s';
         } else {
            options :+= ' -s';
         }
      }
   }
   options:+=" +fenddefaults";
   return(options);
}
bool _HaveValidOuputFileName(_str BufferName)
{
   int type=_FileQType(BufferName);
   if (type==VSFILETYPE_GVFS_FILE || type==VSFILETYPE_PLUGIN_FILE ) {
      return true;
   }
   if (type!=VSFILETYPE_NORMAL_FILE) {
      return false;
   }
   if (_isUnix()) {
      return( substr(BufferName,1,1)==FILESEP );
   }
    // IF this is a UNC name
    if(substr(BufferName,1,1)==FILESEP && substr(BufferName,2,1)==FILESEP) {
       return(true);
    }
    if( substr(BufferName,2,1)==':' && substr(BufferName,3,1)==FILESEP ) {
       return(true);
    }
    return(false);
}
