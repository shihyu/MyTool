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
#import "complete.e"
#import "dirlist.e"
#import "drvlist.e"
#import "filelist.e"
#import "files.e"
#import "ftp.e"
#import "main.e"
#import "sellist.e"
#import "setupext.e"
#import "stdprocs.e"
#endregion

bool def_add_to_project_save_as = false;

struct OPENFNUSER{
   int flags;
   _str default_ext;
   _str name_part;
   _str cwd;
   _str last_data;
};

static _str ignore_change=0;
static int gOpenFnEnter=0; // wrapper flag for _openfn.enter()
static _str gOpenFnEnterText="";

static const APPENDCAPTION= '&Append';
static _str _open_rflags()
{
   OPENFNUSER openfnuser;openfnuser=_openfn.p_user;
   int flags=openfnuser.flags;
   if (!(flags & OFN_PREFIXFLAGS)) {
      return('');
   }
   rflags := "";
   if (_openreadonly.p_visible && _openreadonly.p_value) {
      if (_openreadonly.p_caption==APPENDCAPTION) {
         rflags :+= '-a ';
      } else {
         rflags :+= '-r ';
      }
   }
   if (_openkeep_old.p_visible && _openkeep_old.p_value) {
      rflags :+= '-n ';
   }

   wid := _find_control('ctlAddToProject');
   if (wid) {
      if (wid.p_enabled && wid.p_value) {
         rflags :+= '+p ';
      }
   }
   return(rflags);
}
static _str _open_get_result2(_str have_wildcards='')
{
   open_wildcards := have_wildcards != '';
   rest := _openfn.p_text;
   if (def_unix_expansion) {
      rest=_unix_expansion(rest);
   }
   OPENFNUSER openfnuser;openfnuser=_openfn.p_user;
   int flags=OFN_ALLOWMULTISELECT;
   default_ext := "";
   name_part := "";
   HaveFileTypes := _find_control('_openfile_types');
   if (HaveFileTypes) {
      flags=openfnuser.flags;default_ext=openfnuser.default_ext;
      name_part=openfnuser.name_part;
      _param1=_openfile_types.p_text;
   }
   hit_dir := false;
   hit_wildcard := false;
   hit_normal := false;
   hit_semi := -1;
   wildcards := "";
   path := "";
   result := "";
   bresult := "";  // result not in abolute form for retrieval
   new_encoding_info := "";
   cwd := absolute(_opendir_list._dlpath());
   _str filenames;
   _str bfilename;
   _str filename;
   _str text;
   _str new_path;
   _str server,sharep;
   for (;;) {
      parse rest with filenames ';' rest;
      if (filenames=='') break;
      ++hit_semi;
      for (;;){
         if ((flags & OFN_SAVEAS) || !(flags & OFN_ALLOWMULTISELECT)) {
            bfilename=_maybe_quote_filename(filenames);
            filenames='';
         } else {
            bfilename=parse_file(filenames);
         }
         if (bfilename=='') break;
         filename=_absolute2(bfilename,cwd);
         if ((flags & OFN_NODATASETS) && _DataSetIsFile(filename)) {
            _message_box("Datasets not supported here");
            text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
            return('');
         }
         // Check if this is a directory specification.
         bool hasWildcards;
         if (isdirectory(filename)) {
            hit_dir=true;
            path=filename;
            name_part='';hasWildcards=false;
         } else {
            if (default_ext!='.' && filename==_strip_filename(filename,'e')) {
               if (default_ext=='') {
                  filename=_maybe_quote_filename(strip(filename,'B','"'));
               } else {
                  filename=_maybe_quote_filename(strip(filename,'B','"')'.'default_ext);
               }
            }
            result :+= ' 'filename;
            if (bresult=='') {
               bresult=bfilename;
            } else {
               bresult :+= ' 'bfilename;
            }
            new_path=_strip_filename(strip(filename,'B','"')/*filename*/,'N');
            name_part=_strip_filename(strip(filename,'B','"'),'P');
            // Check if path exists
            if (new_path!=''){
               path=new_path;
               if(!isdirectory(new_path)) {
                  _message_box(new_path"\n"nls("Path does not exist.")"\n":+
                               nls("Please verify that the correct path was given."),
                               p_active_form.p_caption
                            );
                  text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
                  return('');
               }
            }
            if (_isUnix()) {
               if (flags & OFN_SAVEAS) {
                  hasWildcards=verify(filename,'*','M')!=0;
               } else {
                  hasWildcards=iswildcard(name_part) && !file_exists(strip(filename,'B','"'));
               }
            } else {
               hasWildcards=iswildcard(name_part);
            }
         }
         if (!open_wildcards && hasWildcards) {
            wildcards :+= ' 'name_part;
            hit_wildcard=true;
         } else if(name_part!=''){
            ++hit_normal;
         }
         //messageNwait('hit_n='hit_normal' hit_w='hit_wildcard' hit_s='hit_semi);
         bool b;
         if (open_wildcards) {
            b=hit_dir;
         } else {
            b=(hit_normal && (hit_wildcard || hit_dir || hit_semi)) ||
             (hit_normal>1 && !(flags & OFN_ALLOWMULTISELECT));
         }
         if (b) {
            _message_box(result"\n"nls("The above file name is invalid."),
                         p_active_form.p_caption
                         );

            text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
            return('');
         }
      }
   }
   if (hit_normal) {
      if (flags & OFN_APPEND) {
         if (_openreadonly.p_value) {
            flags|=OFN_FILEMUSTEXIST;
            flags&=~OFN_SAVEAS;
         }
      }
      found_at_least_one_file := false;
      if ((flags & OFN_FILEMUSTEXIST)||
           ((flags & OFN_SAVEAS) && !(flags & OFN_NOOVERWRITEPROMPT)) ) {
         rest=result;
         hit_wildcard=false;
         for (;;) {
            filename=parse_file(rest);
            if (filename=='') break;
            file_exists := file_match('-p 'filename,1)!='';
            found_at_least_one_file=found_at_least_one_file || file_exists;
            bool hasWildcards2;

            if (_isUnix()) {
               if (flags & OFN_SAVEAS) {
                  hasWildcards2=verify(filename,'*','M')!=0;
               } else {
                  hasWildcards2=iswildcard(filename) && !file_exists;
               }
            } else {
               hasWildcards2=iswildcard(filename);
            }
            hit_wildcard=hit_wildcard || hasWildcards2;
            if (flags & OFN_FILEMUSTEXIST) {
               if(!file_exists && !(open_wildcards && iswildcard(filename))) {
                  _message_box(filename"\n"nls("File not found.")"\n":+
                            nls("Please verify that the correct file name was given."),
                               p_active_form.p_caption
                              );
                  p_window_id=_openfn;
                  text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
                  return('');
               }
            }
            if (flags & OFN_SAVEAS) {
               if (file_exists) {
                  int status=_message_box(nls("%s already exists.",filename)"\n\n":+
                            nls("Do you want to replace it?"),
                            p_active_form.p_caption,
                            MB_YESNOCANCEL|MB_ICONQUESTION,IDNO
                            );
                  if (status!=IDYES) {
                     p_window_id=_openfn;
                     text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
                     return('');
                  }
               }
            }
         }
      }
      if ((flags & OFN_FILEMUSTEXIST) && hit_wildcard &&
          open_wildcards && !found_at_least_one_file) {
         _message_box(nls("No wild card files found.")"\n":+
                   nls("Please verify that the correct file name was given."),
                      p_active_form.p_caption
                     );
         p_window_id=_openfn;
         text=_openfn.p_text;_openfn.set_command(text,1,length(text)+1);_openfn._set_focus();
         return('');
      }
      result=strip(result);
      if (result=='') {
         return('');
      }
      if (!_find_control('_openchange_dir')) {
         return(result);
      }
      if (!(flags & OFN_SAVEAS)) {
         _append_retrieve(_openfn,_maybe_quote_filename(absolute(bresult)),_openfile_list.p_user);
      }
      if (_UTF8()) {
         if (flags & OFN_SAVEAS) {
            new_encoding_info = _EncodingGetComboSetting();
            if (new_encoding_info != "") {
               new_encoding_info :+= " ";
            }
            //say("new_encoding_info='"new_encoding_info"'");
         }
      }
      return(_open_rflags():+new_encoding_info:+result);
   }
   if (!hit_wildcard && !hit_dir && (flags & OFN_ALLOWMULTISELECT)){
      if (!HaveFileTypes) {
         result=_openfile_list._lbmulti_select_result('',cwd);
         return(strip(result));
      }
      /* Nothing selected? */
      result=_openfile_list._lbmulti_select_result('',cwd);
      if (result=='') {
         return('');
      }
      return(_open_rflags():+strip(result));
   }
   if (!hit_normal && !hit_wildcard && !hit_dir) return('');
   if (wildcards=='') {
      wildcards=_open_get_wildcards();
   }
   // Convert *.c *.h to *.c;*.h
   rest=wildcards;
   wildcards='';
   for (;;) {
      _str wildcard=parse_file(rest);
      if (wildcard=='') break;
      if (wildcards!='') {
         wildcards :+= ';'wildcard;
      } else {
         wildcards=wildcard;
      }
   }
   if (path!='') {
      p_window_id=_openfn;
      if (_isWindows()) {
         _openfile_list._flfilename(wildcards,path,true);
         if (substr(path,1,2)=='\\') {
            _opendir_list._dlpath(path);
            parse path with '\\'  server '\' sharep'\' rest ;
            unc_name := '\\'server'\'sharep;
            _opendrives._dvldrive(unc_name);
         } else {
            //_opendir_list._dlpath(path)
            if (gOpenFnEnter) {
               _opendir_list._dlpath(path,true);
            } else {
               _opendir_list._dlpath(path);
            }
            _opendrives._dvldrive('');
         }
      } else {
         //chdir path,1
         _openfile_list._flfilename(wildcards,path,true);
         if (gOpenFnEnter) {
            _opendir_list._dlpath(path,true);
         } else {
            _opendir_list._dlpath(path);
         }
         //_opendrives._dvldrive('')
      }
      _set_sel(1,length(p_text)+1);
   } else {
      _openfile_list._flfilename(wildcards);
      ignore_change=0;
   }
   return('');
}
_str _open_get_result(_str wildcards='')
{
   gOpenFnEnter = 1;
   gOpenFnEnterText = _openfn.p_text;
   _str result=_open_get_result2(wildcards);
   gOpenFnEnter = 0;
   return(result);
}
_str _open_get_wildcards()
{
   _str path;
   _str wildcards;
   parse _openfile_list._flfilename() with path';'wildcards;
   if (wildcards=='') {
      parse _openfile_types.p_text with '('wildcards')' ;
      if (wildcards=='') {
         return(ALLFILES_RE);
      }
      return(wildcards);
   }
   return(wildcards);
}
_open_flags()
{
   OPENFNUSER openfnuser;openfnuser=_openfn.p_user;
   return(openfnuser.flags);
}
_str _absolute2(_str path,_str cwd)
{
   path=strip(path,'B','"');
   _maybe_append_filesep(cwd);
   return _maybe_quote_filename(absolute(path,cwd));
}
