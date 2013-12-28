////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47496 $
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
#include "hthelp.sh"
#import "complete.e"
#import "dlgman.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "optionsxml.e"
#import "picture.e"
#import "put.e"
#import "saveload.e"
#import "seek.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#endregion

/*
4:02pm 5/13/1996
p_user variables used:

_help_build_index_form:

   _up.p_user      - This is a modified flag

   _ok.p_user      - This is the help idx filename.  THIS IS NEVER
                     A QUOTED FILENAME!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ctlhelp.p_user   -- Indicates that the user has already been prompted whether to scan for help files

_help_index_form:

   _ok.p_user      - This is the help idx filename

   text1.p_user    - Used as a semaphore to not insert a hit list

   _close.p_user   - Used so that text1 is not selected the first time coming up
*/



#define HELP_AUTOSTART_TIMEOUT 30  // 30 seconds

#define HTLP_FILENAME_LENGTH 12
#define HTLP_FILEDESCRIPTION_LENGTH 64
#define HELP_DLL_NAME 'vshlp.dll'
#define VSHLP_DONE 1

_str def_helpidx_filename;
_str def_helpidx_path;

static _str _init_help;

    NTINDEXHELPOPTIONS def_ntIndexHelpOptions={
       true,
       "MSIN",
       "vcbks40.mvb",
       "KeywordLookup(`%K')",
       "",      //CmdViewer
    };

defeventtab _help_build_index_form;

#region Options Dialog Helper Functions

void _help_build_index_form_init_for_options(_str option = '')
{
   /* 
      (clark) We could call init_help_build_index_form() here but
      we already called it in the _ok.create().
   */
   //init_help_build_index_form(option);

   _ok.p_visible = false;
   _cancel.p_visible = false;
   ctlhelp.p_visible = false;
   _more.p_visible = false;

   _load_file.p_x = _ok.p_x;
   _scan.p_x = _cancel.p_x;
   ctldefault.p_x = ctlhelp.p_x;
}

void _help_build_index_form_save_settings(_str (&settings):[])
{
   // save the help files
   settings:['helpfiles'] = get_help_files_list();
   // save help path
   settings:['helppath'] = _helpfile_path.p_text;
}

boolean _help_build_index_form_is_modified(_str (&settings):[])
{
// return true;
   if (settings:['helppath'] != _helpfile_path.p_text) return true;

   if (settings:['helpfiles'] != get_help_files_list()) return true;

   return false;
}

_str get_help_files_list()
{
   // save list box stuff
   _help_file_list._lbtop();
   list := _help_file_list._lbget_text();
   while (!_help_file_list._lbdown()) {
      list :+= ' '_help_file_list._lbget_text();
   }

   return list;
}

boolean _help_build_index_form_apply(_str idxfilename_arg = '')
{
   _str filename="";
   _str idxfilename="";
   _str idxpath="";

   filename='vslick.idx';
   idxfilename=_replace_envvars(def_helpidx_filename);
   idxpath=_replace_envvars(def_helpidx_path);

   if (idxpath!=_helpfile_path.p_text) {
      idxpath=_helpfile_path.p_text;
   }
   if (idxfilename!=_ok.p_user) {
      idxfilename=_ok.p_user;
   }
   if (idxfilename=='') {
      idxfilename= _ConfigPath():+"vslick.idx";
      _ok.p_user=idxfilename;
   }
   // Remove null paths
   int i=1;
   for (i=1;i<length(idxpath);++i) {
      int j=i;
      boolean changed=false;
      while (_Substr(idxpath,j,1)==PATHSEP) {
         changed=true;
         ++j;
      }
      if (changed) {
         idxpath=substr(idxpath,1,i):+substr(idxpath,j);
      }
   }
   typeless result=0;
   if (idxfilename=='') {

      if (idxfilename_arg!='') {
         _ok.p_user=strip(idxfilename=idxfilename_arg,'B','"');
      }else{
         result=_OpenDialog('-modal',
                     'Save As',
                     '*.idx',
                     'Help Index Files (*.idx), All Files ('ALLFILES_RE')',
                     OFN_SAVEAS,
                     'idx',
                     _ConfigPath():+filename,
                     '');
         if (result=='') {
            return false;
         }
         idxfilename=result;
         _ok.p_user=strip(result,'B','"');
      }
   }
   //I don't think we should bother to check a modify flag anymore -
   //Dan 3:45pm 8/15/1996
   mou_hour_glass(1);
   filename=_ok.p_user;
   int wid_rhfl=_control _real_help_file_list;
   int wid_kl=_control _keyword_list;
   int wid=p_window_id;
   int fid=p_active_form;
   p_window_id=_mdi.p_child;
   typeless status=_hi_add_files(strip(filename,'B','"'), wid_rhfl, wid_kl,1);
   if (status<0) {
      _message_box(nls('Error writing %s.  ',filename)get_message(status));
   }
   //fid.set_helpfile_path();
   mou_hour_glass(0);
   p_window_id=wid;
   if(def_helpidx_filename!=_encode_vsenvvars(idxfilename,true)) {
      def_helpidx_filename=_encode_vsenvvars(idxfilename,true);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (def_helpidx_path!=_encode_vsenvvars(idxpath,false)) {
      def_helpidx_path=_encode_vsenvvars(idxpath,false);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   return true;
}

#endregion Options Dialog Helper Functions

void _help_build_index_form.on_resize()
{
   // we only do resizing when this form is embedded in the options dialog
   if (_more.p_visible) return;

   // buffer between controls
   buffer := 120;

   // available width and height
   width := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   height := _dy2ly(SM_TWIP,p_active_form.p_client_height);

   // make the help frame a wee bit smaller than the form
   widthDiff := width - (ctlframe.p_width + (2 * buffer));
   if (widthDiff) {
      ctlframe.p_width += widthDiff;
      _help_file_list.p_width += widthDiff;
      _helpfile_path.p_width += widthDiff;
      _keyword_list.p_width += widthDiff;
   
      // move buttons over
      _up.p_x += widthDiff;
      _down.p_x += widthDiff;
      _add.p_x += widthDiff;
      _remove.p_x += widthDiff;
   }

   // we add any extra height to the help file list
   heightDiff := height - (_keyword_list.p_y + _keyword_list.p_height + (2 * buffer));
   if (heightDiff) {
      // move stuff down
      _edit.p_y += heightDiff;
      _export.p_y += heightDiff;
   
      // help file path stuff
      ctlpathlabel.p_y += heightDiff;
      _helpfile_path.p_y += heightDiff;
   
      // buttons
      _ok.p_y += heightDiff;
      _cancel.p_y += heightDiff;
      ctlhelp.p_y += heightDiff;
      _more.p_y += heightDiff;
      _load_file.p_y += heightDiff;
      _scan.p_y += heightDiff;
      ctldefault.p_y += heightDiff;
   
      // keyword stuff
      _show_keywords.p_y += heightDiff;
      _keyword_list.p_y += heightDiff;
   
      // make it taller!
      ctlframe.p_height += heightDiff;
      _help_file_list.p_height += heightDiff;
   }
}

static int HelpPromptAndScan()
{
   if (ctlhelp.p_user==1) {
      return(0);
   }
   ctlhelp.p_user=1;
   int result=_message_box(nls("You do not have a word help index file.\n\nWould you like SlickEdit to scan for help files at this time?"),
                       '',
                       MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result==IDCANCEL) {
      //p_active_form._delete_window();
      //return(1);
      return(0);
   }
   if (result!=IDYES) {
      //return 1;
      return(0);
   }
   _scan_for_files();
   return(0);
}
_ok.on_create(_str option="", typeless filelist=null, _str idxfilename="")
{
   _help_build_index_form_initial_alignment();
   init_help_build_index_form(option, filelist, idxfilename);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _help_build_index_form_initial_alignment()
{
   rightAlign := ctlframe.p_width - ctlframe.p_x;
   alignUpDownListButtons(_help_file_list, rightAlign, _add, _up, _down, _remove);
}

void init_help_build_index_form(_str option="", typeless filelist=null, _str idxfilename="")
{
   if (filelist._varformat()!=VF_ARRAY) {
      SetupForm(_replace_envvars(def_helpidx_path),_replace_envvars(def_helpidx_filename),'vslick.idx',HelpPromptAndScan);
   }else{
      int i;
      for (i=0;i<filelist._length();++i) {
         _add.call_event(filelist[i],_add,LBUTTON_UP,'W');
      }
      _ok.call_event(idxfilename,_ok,LBUTTON_UP,'W');
   }
}

ctldefault.lbutton_up()
{
   show("-modal _default_help_form");
}
_scan.lbutton_up()
{
   _scan_for_files();
}

_more.lbutton_up()
{
   if (pos('>>',p_caption)) {
      _dmmore();
   }else{
      _dmless();
   }
}


_command void configure_index_file() name_info(','VSARG2_EDITORCTL)
{
   config('_help_build_index_form', 'D'); 
}

static void SetupForm(_str PathList,_str FileName,_str DefaultFilename,
                      typeless *pfnCallBack)
{
   _more._dmless();
   //width=_text_width('WWWWWWWW.WWWW');
   //messageNwait('width='width);
   _help_file_list._col_width(0,1500 /*width*/);
   _help_file_list._col_width(1,200);
   _help_file_list._col_width(-1,1);
   if (FileName!='' && file_match('-p 'maybe_quote_filename(FileName),1)=='') {
      //FileName=slick_path_search(DefaultFilename);
      //say('FileName='FileName);
      //if (FileName!='') {
      //   FileName=absolute(FileName);
      //}
      //_config_modify=1;
   }
   if (FileName!='') {
      get_indexfile_info(FileName);
   }else{
      PathList="";
   }
   p_window_id=_control _help_file_list;
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str title="";
      _str filename=_lbget_text();
      parse filename with filename " @\t-\t @","r" title;
      _str real_filename=get_help_filename(filename,PathList);
      //messageNwait("_ok.on_create: real_filename="real_filename);
      add_file_to_list(real_filename,title, p_line);
   }
   int fid=p_active_form;
   _lbtop();_lbselect_line();
   if (FileName=='') {
      int status=(*pfnCallBack)();
      if (status) return;
   }
   _helpfile_path.p_text=PathList;
   if (PathList=='') {
      fid.set_helpfile_path();
   }
   int wid=p_window_id;
}

static _str MaybeStripTrailingQuote(_str FileName)
{
   if (last_char(FileName)=='"' && length(FileName)>1) {
      FileName=substr(FileName,1,length(FileName)-1);
   }
   return(FileName);
}
static _str MaybeStripLeadingQuote(_str FileName)
{
   if (substr(FileName,1,1)=='"') {
      FileName=substr(FileName,2);
   }
   return(FileName);
}

static void _scan_for_files()
{
   mou_hour_glass(1);
   filetype:='help';
   ext:='hlp';
   int wid=_helpfile_path;
   _str path=get_env('PATH'):+PATHSEP:+_ConfigPath():+PATHSEP:+_helpfile_path.p_text:+PATHSEP:+get_env('HELPFILES');

   _str vchelp_path="";
   _str curpath="";
   _str winpath="";
   _str word="";
   int i=0;
   typeless status=0;

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_window_id=temp_view_id;
#if !__UNIX__
   // Convert Borland C++ bin directory to help directory
   // We could use registry, but this will work under windows which
   // is important for now.
   i=pos("\\\\bc{:d(:d|)}\\\\bin",path,1,"ri");
   if (i) {
      word=substr(path,pos('S0'),pos('0'));
      path=stranslate(path,"\\bc"word"\\help","\\bc"word"\\bin","i");
   }
   vchelp_path="";
   winpath="";
   if (machine()=='WINDOWS') {
      vchelp_path=_get_vchelp_path();
      if (vchelp_path!="") {
         //messageNwait("_scan_for_files: vchelp_path="vchelp_path);
         status=insert_file_list("-v +p "maybe_quote_filename(vchelp_path:+"vcbks*.mvb"));
      }

      vchelp_path=_get_delphihelp_path();
      if (vchelp_path!="") {
         path=vchelp_path:+PATHSEP:+path;
      }
      winpath=_get_windows_directory();
   }
#else
   winpath="";
#endif

   for (;;) {
      parse path with curpath (PATHSEP) path;
      if (curpath=='' && path=='') break;
      if (curpath=='') continue;
      if (last_char(curpath)!='\') {
         curpath=curpath'\';
      }
      message('Searching for 'filetype' files in 'curpath);
      if (file_eq(curpath,winpath)) {
         continue;
      }
#if !__UNIX__
      if (pos(':c\:\\(winnt|winnt35|win31|windows|win95)',curpath,1,'ri')) {
         continue;
      }
#endif
      insert_file_list('-v +p 'maybe_quote_filename(curpath'*.'ext));
   }
   //We have to make sure that there are no instances of vc50kwds.hlp
   //because this will hang the help indexer...
   top();up();
   while (!down()) {
      _str line="";
      get_line(line);
      _str rfilename=_strip_filename(line,'P');
      if (file_eq(rfilename,"vc50kwds.hlp")) {
         _delete_line();
         up();
         //delete_file(line);
         //Wanted to delete this but cannot because the user could have
         //a 3.0 installation in the path that we found it in
      }
   }

   _str filename="";
   clear_message();
   top();up();
   p_window_id=orig_view_id;
   _str invalid_file_list='';
   for (;;) {
      p_window_id=temp_view_id;
      if (down()) {
         break;
      }
      get_line(filename);
      filename=strip(filename);
      p_window_id=orig_view_id;
      status=call_event(filename, (_control _add), LBUTTON_UP, 'W');
      if (status==INCORRECT_VERSION_RC) {
         if (invalid_file_list=='') {
            invalid_file_list=filename;
         }else{
            invalid_file_list=invalid_file_list"\n"filename;
         }
      }
   }
   if (invalid_file_list!='') {
      _str str=nls("SlickEdit was unable to index the following Windows 95":+\
          " help files.\n(We cannot find documentation for this new format).\n\n"):+\
          invalid_file_list;
      if (length(str)>511) {
         str=substr(invalid_file_list,1,511);
      }
      _message_box(str);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   clear_message();
   mou_hour_glass(0);
}

_ok.on_load()
{
   _help_file_list._set_focus();
}

static void set_helpfile_path()
{
   int help_file_path_wid=_helpfile_path;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   p_window_id=(_control _real_help_file_list);
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str filename=_lbget_text();
      parse filename with filename "\t" ;
      p_window_id=temp_view_id;
      insert_line(MaybeStripLeadingQuote(_strip_filename(filename,'n')));
      p_window_id=orig_view_id;
      p_window_id=_real_help_file_list;
   }
   p_window_id=temp_view_id;
   if (p_Noflines) {
      typeless status=sort_buffer();
      _remove_duplicates();
   }
   p_line=0;
   while (!down()) {
      _str line="";
      get_line(line);
      if (help_file_path_wid.p_text=='') {
         help_file_path_wid.p_text=line;
      }else{
         help_file_path_wid.p_text=help_file_path_wid.p_text:+PATHSEP:+line;
      }
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
}

//Filename to write can be passed in as arg(1)
_ok.lbutton_up(_str idxfilename_arg="")
{

   if (!_help_build_index_form_apply(idxfilename_arg)) {
      return '';
   }

   p_active_form._delete_window(0);
}

_load_file.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
               'Open Help Index File',
               '*.idx',
               'Help Index Files (*.idx), All Files ('ALLFILES_RE')',
               0,  //OFN_FILEMUSTEXIST can create new file.
               'idx',
               '',
               '');
   if (result=='') {
      return('');
   }
   get_indexfile_info(result);
   _ok.p_user=strip(result,'B','"');
   if (file_match('-p 'result,1)=='') {
      _help_file_list.refresh();
      _message_box(nls("File '%s' not found.  Creating new index file.",result));
   }
}

static void get_indexfile_info(_str helpfilename)
{
   int fid=p_active_form;
   _help_file_list._lbclear();
   helpfilename=strip(helpfilename,'B','"');
   _ok.p_user=helpfilename;
   fid=p_active_form;
   typeless status=_hi_new_idx_file(helpfilename);
   if (status==1) {
      _help_file_list._hi_insert_helpfile_list(helpfilename);
   }else{
      int temp_view_id=0;
      int orig_view_id=0;
      status=_open_temp_view(helpfilename, temp_view_id, orig_view_id);
      if (!status) {
         p_window_id=temp_view_id;
#if 0
         get_line(line);
         line=substr(line,3);//Skip the number of filenames in the file
         for (;;) {
            parse line with filename (_chr(0)) filedescription (_chr(1)) line;
            if (filename=='') break;
            fid._help_file_list._lbadd_item(filename"\t-\t"filedescription);
         }
#endif
         _nrseek(0);
         typeless byte1=_asc(get_text_raw(1));
         _nrseek(1);
         typeless byte2=_asc(get_text_raw(1));
         _nrseek(2);
         int num_files=byte2*256+byte1;
         typeless seek_pos=_nrseek();
         int i;
         for (i=1;i<=num_files;++i) {
            _str filename=get_text(HTLP_FILENAME_LENGTH, seek_pos);
            seek_pos+=HTLP_FILENAME_LENGTH;
            _str filedescription=get_text(HTLP_FILEDESCRIPTION_LENGTH, seek_pos);
            seek_pos+=HTLP_FILEDESCRIPTION_LENGTH;
            fid._help_file_list._lbadd_item(filename"\t-\t"filedescription);
   #if 0
            real_filename=get_help_filename(filename);
            if (real_filename!='') {
               line=fid._help_file_list.p_line;
               add_file_to_list(real_filename, line);
            }
   #endif
         }
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
   }
   p_window_id=fid;
   _help_file_list._lbtop();
   _help_file_list._lbselect_line();
   fid.p_caption='Configure Help Index File';

   if (getOptionsFormFromEmbeddedDialog() > 0) {
      fid.p_caption :+= '- 'helpfilename;
   }
}

static void upbutton(int line)
{
   if (p_Noflines<=1) {
      return;
   }
   p_line=line;
   _str item=_lbget_text();
   _lbdelete_item();
   if (p_line!=p_Noflines) {
      _lbup();
   }
   if (p_line<1) {
      _lbbottom();
   }else{
      if (line-1) {
         while (p_line>=line-1) {
            _lbup();
         }
      }
   }
   _lbadd_item(item);
   _lbselect_line();
   _help_file_list._set_focus();
}

static void downbutton(int line)
{
   p_line=line;
   _str curline=_lbget_text();
   boolean onbottom=p_line==p_Noflines;
   _lbdelete_item();
   if (onbottom) {
      _lbtop();
      _lbup();
   }
   _lbadd_item(curline);
   _lbselect_line();
   _help_file_list._set_focus();
}

_up.lbutton_up()
{
   _up.p_user=1;
   int line=_help_file_list.p_line;
   _help_file_list.upbutton(line);
   _real_help_file_list.upbutton(line);
}

_down.lbutton_up()
{
   _up.p_user=1;
   int line=_help_file_list.p_line;
   _help_file_list.downbutton(line);
   _real_help_file_list.downbutton(line);
}

_add.lbutton_up(_str ifilename="")
{
   _str filetype="";
   _str title="";
   _str ext="";
   filetype='Help Files (*.hlp;*.mvb)';
   title='Add Help File';
   ext='hlp';

   _str filenamelist="";
   if (ifilename=='') {
      filenamelist=_OpenDialog('-modal',
                  filetype,
                  '*.idx',
                  filetype',All Files ('ALLFILES_RE')',
                  OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
                  ext,
                  '',
                  '');
      if (filenamelist=='') {
         //messageNwait('return 1');
         return('');
      }
   }else{
      filenamelist=maybe_quote_filename(ifilename);
   }

   typeless OldVCHelpFile=0;
   typeless status=0;
   int old_linenum=0;
   _str helpfilename="";
   _str filename="";
   _str result="";
   typeless junk="";
   _str temp="";
   _str msg="";
   _str str="";
   _str line="";
   int linenum=0;

   for (;;) {
      result=parse_file(filenamelist);
      if (result=='') break;
      result=strip(result,"B",'"');
      message('Checking file validity ('result')');
      OldVCHelpFile=0;
      if (file_eq(_strip_filename(result,'p'),'vckwds.hlp')) {
         status=0;
      } else {
         status=_winhelpfind(result,'',0xF002,0);
         if (!status) {
            //Cannot let the user add vc50kwds.hlp because this will hang the editor
            if (file_eq(_strip_filename(result,'P'),"vc50kwds.hlp")) {
               status=1;
               OldVCHelpFile=1;
            }
         }
      }
      if (status) {
         msg='';
         if (ifilename=='') {
            if (status==INCORRECT_VERSION_RC) {
               msg=nls("SlickEdit's Help Indexer does not yet support this":+\
                   "Winhelp format.\n(We cannot find documentation).");
               _message_box(msg);
            }else{
               if (!OldVCHelpFile) {
                  _message_box(nls("%s is not a valid Windows help file.%s",result,msg));
               }else{
                  _message_box(nls("%s is an old list of VC++ keywords.\n\nPlease add vckwds.hlp instead.",result));
               }
            }
         }
         if (filenamelist=='') {
            //messageNwait('return 2');
            return(status);
         }else{
            continue;//Do not add to list
         }
      }
      clear_message();
      _up.p_user=1;
      old_linenum=_help_file_list.p_line;
      typeless p;
      _help_file_list.save_pos(p);
      _help_file_list._lbtop();
      filename=MaybeStripTrailingQuote(_strip_filename(result, 'p'));
      junk='';
      status=_help_file_list._lbi_search(junk,filename);
      if (!status) {
         _help_file_list.restore_pos(p);
         _help_file_list._lbselect_line();
         if (ifilename=='') {
            _message_box(nls("%s is already in this index file.",_strip_filename(result,'p')));
         }else{
            //messageNwait('matched on 'filename);
         }
         //messageNwait('return 3');
         return('');
      }
      _help_file_list.restore_pos(p);
      helpfilename='';
      if (file_exists(strip(result,'B','"'))) {
         helpfilename=result;
      }
      if (helpfilename=='') {
         _message_box(nls("Could not find help file %s in Help file path, or PATH.", result));
         //messageNwait('return 4');
         return('');
      }
      p_window_id=_help_file_list;
      //_lbbottom();
      if (file_eq(_strip_filename(helpfilename,'p'),'vckwds.hlp')) {
         str='List of keywords in Visual C++';
      }else{
         str=_winhelptitle(helpfilename);
      }
      //messageNwait('got here helpfilename='helpfilename' str='str);
      temp=MaybeStripTrailingQuote(_strip_filename(helpfilename,"P"));
      if (str=="" && file_eq(substr(temp,1,5),"vcbks")) {
         str="Microsoft Visual C++ On-Line Books";
      }
      line=MaybeStripTrailingQuote(_strip_filename(helpfilename,'p'));
      linenum=_help_file_list.p_line;
      _lbadd_item(line"\t-\t"str);
      //_lbselect_line();
      maybe_add_to_path(helpfilename);
      if (linenum==_help_file_list.p_Noflines) {
         linenum--;
      }
      add_file_to_list(helpfilename,str,linenum);
      //_helpfile_path.p_text=def_helpidx_path;
      if (p_Noflines==1) {
         _lbtop();
         _lbselect_line();
         call_event(CHANGE_SELECTED, _help_file_list, ON_CHANGE, 'W');
      }
      _set_focus();
      if (ifilename!='') {
         if (old_linenum) {
            restore_pos(p);
            _lbselect_line();
         } else {
            _lbtop();_lbselect_line();
         }
      }
   }
   //messageNwait('return 5');
   return(0);
}

static void maybe_add_to_path(_str filename)
{
   _str filepath=_strip_filename(filename,'n');
   if (pos(PATHSEP:+filepath:+PATHSEP,PATHSEP:+_helpfile_path.p_text:+PATHSEP,1,_fpos_case)) {
      return;/* Path is somewhere in list */
   }
   if (_helpfile_path.p_text!='') {
      _str spacer=(last_char(_helpfile_path.p_text)==PATHSEP)?'':PATHSEP;
      _helpfile_path.p_text=_helpfile_path.p_text:+spacer:+filepath;
      return;
   }
   _helpfile_path.p_text=filepath;
}
#if !__UNIX__
_str _get_vchelp_path()
{
   _str value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\mdpfile\\shell\\open\\command","");
   if (value=="") return("");
   _str vcpp_path=_strip_filename(strip(parse_file(value),"B",'"'),"N");
   if (vcpp_path!="") {
      vcpp_path=_strip_filename(substr(vcpp_path,1,length(vcpp_path)-1),"N");
      //messageNwait("get_help_filename: h1 vcpp_path="vcpp_path);
      vcpp_path=vcpp_path:+"help\\";
      //messageNwait("get_help_filename: vcpp_path="path);
   }
   return(vcpp_path);
}
_str _get_delphihelp_path()
{
   _str value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\delphiunit\\shell\\open\\command","");
   parse value with value " %1";
   if (value=="") return("");
   _str vcpp_path=_strip_filename(strip(value,"B",'"'),"N");
   if (vcpp_path!="") {
      vcpp_path=_strip_filename(substr(vcpp_path,1,length(vcpp_path)-1),"N");
      //messageNwait("get_help_filename: h1 vcpp_path="vcpp_path);
      vcpp_path=vcpp_path:+"help\\";
      //messageNwait("get_help_filename: vcpp_path="path);
   }
   return(vcpp_path);
}
#endif
static bigstring get_help_filename(_str filename, _str path="")
{
   boolean done=0;
   if (path=='') {
      if (_find_control('_helpfile_path')) {
         path=strip(_helpfile_path.p_text);
      } else {
         path="";
      }
   }
   //Dan added 6/14 to because api files are usually in our directory
   _str tfilename=slick_path_search(filename);
   if (tfilename!='') {
      return(absolute(tfilename));
   }//End fix
   _str vchelp_path="";
#if __NT__
   if (machine()=='WINDOWS') {
      vchelp_path=_get_vchelp_path();
      if (vchelp_path!="") {
         if (path=="") {
            path=vchelp_path;
         } else {
            if (last_char(path)!=PATHSEP) {
               path=path:+PATHSEP;
            }
            path=path:+vchelp_path;
         }
      }
   }
#endif
   _str cpath="";
   message("Searching for "filename);
   for (;;) {
      tfilename=filename;
      parse path with cpath (PATHSEP) path;
      if (cpath=="") {
         if (!done) {
            path=strip(get_env('PATH'));
            done=1;
            continue;
         }
         clear_message();
         return('');
      }
      if (pos('\*|\.', cpath, 1, 'ri')) {
         cpath=_strip_filename(cpath, 'n');
      }
      if (last_char(cpath)==FILESEP) {
         tfilename=cpath:+tfilename;
      }else{
         tfilename=cpath:+FILESEP:+tfilename;
      }
      //messageNwait("get_help_filename: tfilename="tfilename);
      if (file_match(maybe_quote_filename(tfilename)' -p', 1)!='') {
         clear_message();
         return(tfilename);
      }
   }
   clear_message();
   return('');
}

#if 0
static show_list_box()
{
   _lbtop();_lbup();
   while (!_lbdown()) {
      get_line(line);
      messageNwait('line=<'_lbget_text()'>');
   }
}
#endif

_remove.lbutton_up()
{
#if 0
   _real_help_file_list.show_list_box();
   _help_file_list.show_list_box();
#endif
   _str filename=_help_file_list._lbget_text();
   if (filename!='') {
      parse filename with filename " @\t",'r' . ;
#if 1
      remove_file_from_list(filename);
#else
      line=_help_file_list.p_line;
      wid=p_window_id;
      p_window_id=(_control _real_help_file_list);
      p_line=line;
      _lbselect_line();
      _lbdelete_item();
      p_window_id=wid;
#endif
   }
   _up.p_user=1;
   p_window_id=_help_file_list;
   _lbdelete_item();
   _lbselect_line();
   call_event(CHANGE_SELECTED, _help_file_list, ON_CHANGE, 'W');
}

void _edit.lbutton_up()
{
   p_window_id=_help_file_list;
   _str line=_lbget_text();
   if (line=='') {
      return;
   }
   _str filename="";
   _str description="";
   parse line with filename "\t-\t" description ;
   typeless result=show('-modal _textbox_form',
                        'Edit Description',
                        0,//Flags
                        '',//TB width
                        '',//help item
                        '',//Buttons and captions
                        '',//retrieve name
                        '-e _length_under_64 Help File Description:'strip(description));
   if (result=='') {
      return;
   }
   _up.p_user=1;
   _str new_description=_param1;
   _str new_line=filename"\t-\t"new_description;
   _lbset_item(new_line);
   _lbselect_line();
   int linenum=p_line;
   p_window_id=_real_help_file_list;
   p_line=linenum;
   _str real_filename="";
   parse _lbget_text() with real_filename "\t" description;
   _lbset_item(real_filename"\t"new_description);
   _help_file_list._set_focus();
}

int _length_under_64(_str str)
{
   if (length(str)>64) {
      _message_box(nls("Help File Descriptions are limited to 64 characters."));
      return(1);
   }
   return(0);
}

_help_file_list.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      _show_keywords.call_event(_show_keywords, LBUTTON_UP);
   }
}

_show_keywords.lbutton_up()
{
   int fid=p_active_form;
   if (p_value) {
      _str filename=_help_file_list._lbget_text();
      parse filename with filename " @\t",'r' .;
      message("Inserting Keywords for "filename".");
      p_window_id=_control _keyword_list;
      _lbclear();
      filename=_help_file_list._lbget_text();
      parse filename with filename " @\t",'r' . ;
      if (filename=='') {
         clear_message();
         return('');
      }
      _str real_filename=get_file_from_list(filename);
      if (real_filename=='') {
         real_filename=get_help_filename(filename);
         if (real_filename=='') {
            _message_box(nls("Could not find file %s in Help File Path, or Path.", strip(filename)));
            clear_message();
            return('');
         }
      }
      p_window_id=fid._keyword_list;
      mou_hour_glass(1);
      if (file_eq(_strip_filename(real_filename,'p'),'vckwds.hlp')) {
         _str path=_strip_filename(real_filename,'n');
         _lbinsert_file(path:+'vckwds.lst');
      }else{
         typeless status=_winhelpfind(real_filename,"",0,1);
      }
      mou_hour_glass(0);
      _lbtop();
      _lbselect_line();
   }
   _help_file_list._set_focus();
   clear_message();
}

static void add_file_to_list(_str filename, _str title, int line)
{
   int wid=p_window_id;
   p_window_id=_control _real_help_file_list;
   p_line=line;
   _lbadd_item(strip(filename,'B','"')"\t"title);
   p_window_id=wid;
}

static void remove_file_from_list(_str &filename)
{
   int wid=p_window_id;
   p_window_id=_control _real_help_file_list;
   _lbtop();
   _str junk='';
   _str line="";
   filename=get_help_filename(filename);
   if (!_lbi_search(junk,filename)) {
      _lbdelete_item();
   }else{
      messageNwait('Could not find 'filename' in list');
      wid=p_window_id;
      p_window_id=_control _real_help_file_list;
      _lbtop();_lbup();
      while (!_lbdown()) {
         line=_lbget_text();
      }
      p_window_id=wid;
   }
   p_window_id=wid;
}

static bigstring get_file_from_list(_str &filename)
{
   int wid=p_window_id;
   _str name='';
   p_window_id=_control _real_help_file_list;
   p_line=0;
   //_lbtop();
   //if (!search(_escape_re_chars(filename)'$','r@'_fpos_case)) {
   if (!search(_escape_re_chars(filename)'($|\t)','r@'_fpos_case)) {
      name=_lbget_text();
      if (pos("\t",name)) {
         parse name with name "\t" .;
      }
   }
   p_window_id=wid;
   return(name);
}

_export.lbutton_up()
{
   _str sfileline=_help_file_list._lbget_text();
   if (sfileline=='') {
      return('');
   }
   _str sfilename="";
   _str description="";
   parse sfileline with sfilename "\t-\t" description;
   _str absfilename=get_file_from_list(sfilename);
   typeless result=_OpenDialog('-modal',
                               'Save As',
                               '*.hlt',
                               'Help List Text Files (*.hlt), All Files ('ALLFILES_RE')',
                               0,
                               'hlt',
                               '',
                               '');
   if (result=='') {
      return('');
   }
   _str filename=strip(result,'B','"');
   _str options=(file_exists(filename))?'':'+t';
   if (options=='') {
      _str answer=_message_box(nls("Are you sure you wish to overwrite the existing file?")
                               ,''
                               ,MB_YESNOCANCEL|MB_ICONQUESTION);
      if (answer!=IDYES) {
         return('');
      }
   }
   _str path="";
   typeless mark_id='';
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(filename, temp_view_id, orig_view_id, options);
   if (!status) {
      if (options=='') {
         mark_id=_alloc_selection();
         top();_select_line(mark_id);
         bottom();_select_line(mark_id);
         _delete_selection(mark_id);
         _free_selection(mark_id);
      }
      mou_hour_glass(1);
      p_window_id=temp_view_id;
      _delete_line();
      if (absfilename=='') {
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
         _message_box(nls("Could not find %s in Help File Path, or Path.",sfilename));
         mou_hour_glass(0);
         return('');
      }
      insert_line(MaybeStripTrailingQuote(_strip_filename(absfilename, 'p')));
      insert_line(_winhelptitle(absfilename));
      if (file_eq(_strip_filename(absfilename,'p'),'vckwds.hlp')) {
         path=_strip_filename(absfilename,'n');
         get(path:+'vckwds.lst');
      }else{
         _winhelpfind(absfilename,"",0,0);
      }
      _save_file(build_save_options(absfilename));
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      mou_hour_glass(0);
   }
}

/**
 * Provides indexed help on the word at the cursor.  If there is no word at 
 * the cursor, the Help Index dialog box is still displayed.
 * 
 * @categories Miscellaneous_Functions
 * 
 */
_command void help_index() name_info(','VSARG2_EDITORCTL)
{
   _str word="";
   if (_isEditorCtl()) {
      int junk=0;
      word=cur_word(junk);
   }
   typeless result=show('-modal _help_index_form',_replace_envvars(def_helpidx_filename),word);
}

defeventtab _help_index_form;

_ok.on_create(_str idx_filename="",_str defaultHelpOnWord="",
              _str option="",  // Specify 'A' for API Apprentice IDX files. (no longer supported)
              boolean AttemptImmediate=false,
              boolean closeIfNone=false)
{
   /*AttemptImmediate is just to go ahead and call help if there is an exact match.
     I'm adding this for the API Assistant stuff.
     1:46pm 5/22/1996*/

   real_idx_filename:=_replace_envvars(def_helpidx_filename);
   typeless flags=def_help_flags;
   default_filename:='vslick.idx';

   if (idx_filename==real_idx_filename && 
       (real_idx_filename=='' || 
        file_match('-p 'maybe_quote_filename(real_idx_filename),1)=='')) {
      real_idx_filename=slick_path_search(default_filename);
      if (real_idx_filename!="") {
         real_idx_filename=absolute(real_idx_filename);
      }
      idx_filename=real_idx_filename;
      //_config_modify=1;
   } 

   _init_help=1;
   _ok.p_user=strip(idx_filename,'B','"');
   _close.p_value=flags&HF_CLOSE;
   _exact.p_value=flags&HF_EXACTMATCH;
   ctlusedefault.p_value=flags&HF_USEDEFAULT;
   ctlusedefault.call_event(ctlusedefault,lbutton_up);
   p_active_form.p_caption='Help Index - 'idx_filename;
   ctlconfig.p_command="configure-index-file";
   typeless status=0;
   
   text1.p_user=0;
   text1.p_text=defaultHelpOnWord;
   text1.p_user=1;
   status=insert_hit_list(defaultHelpOnWord,AttemptImmediate);
   if (status==INCORRECT_VERSION_RC) {//Old Idx file
      _message_box(nls("You have an old index file.  You should rebuild it now."));
      //p_active_form._delete_window(status);
      //return(status);
      _mdi.configure_index_file();
   }
   if (closeIfNone && list1.p_Noflines==0 ) {
      p_active_form._delete_window(2);
      return(1);
   }
   //status==1 means bring it up immediately if we can
   if (status==1 && list1.p_Noflines==1 ) {
      //Go ahead and bring up the help
      _close.p_value=1;
      _ok.call_event(_ok,LBUTTON_UP);
      return('');
   }
   if (list1.p_Noflines==1) {
      list1.call_event(list1, LBUTTON_DOUBLE_CLICK);
      //messageNwait("_word_help: h1");
      //_syshelp(_param1, _param2, HELP_PARTIALKEY);
   }else{
      //Do that column thing....
      list1._col_width(0,5000 /*width*/);
      list1._col_width(-1,-1);
   }
   
}

void _help_index_form.on_resize()
{
   // enforce a minimum size, otherwise it gets a bit silly
   // have we set the min size yet?  if not, min width will be 0
   if (!_minimum_width()) {
      minWidth := ctlhelp.p_width * 5;
      minHeight := ctlhelp.p_height * 8;
      _set_minimum_size(minWidth, minHeight);
   }

   // figure out how much the size has changed
   padding := label1.p_x;
   xDiff := p_width - (ctlconfig.p_x + ctlconfig.p_width + padding);
   yDiff := p_height - (ctlhelp.p_y + ctlhelp.p_height + padding);

   // now move everything appropriately
   ctlconfig.p_x += xDiff;
   list1.p_width += xDiff;
   _ok.p_x += xDiff;
   ctlcancel.p_x += xDiff;
   ctlhelp.p_x += xDiff;

   list1.p_height += yDiff;
   _ok.p_y += yDiff;
   ctlcancel.p_y += yDiff;
   ctlhelp.p_y += yDiff;
   ctlusedefault.p_y += yDiff;
   _close.p_y += yDiff;
}

void ctlusedefault.lbutton_up()
{
   if (ctlusedefault.p_value) {
      list1.p_no_select_color=1;
      list1.p_enabled=0;
      list1.p_forecolor=_rgb(80,80,80);
      list1._lbdeselect_all();
   } else {
      list1.p_no_select_color=0;
      list1.p_enabled=1;
      list1.p_forecolor=0x80000008;
   }
}

//if arg(2)!=0,Returns 1 if Help can be called immediately
//Dan added this for the API Assistant 1:47pm 5/22/1996
static int insert_hit_list(_str keyword, boolean AttemptImmediate=false)
{
   _str text=keyword;
   if (text=='') {
      list1._lbclear();
      return(0);
   }
   typeless status=0;
   p_window_id=_control list1;
   _lbclear();
   _str filename=strip(_ok.p_user,'B','"');
   if (!AttemptImmediate) {
      status=_hi_hit_list(text, filename, 0, (typeless)_init_help, _exact.p_value);
   }else{
      status=_hi_hit_list(text, filename, 0, (typeless)_init_help, 1);
   }
   //messageNwait("status="status" text="text" filename="filename" bv="(INCORRECT_VERSION_RC)" N="p_Noflines);
   if (status==INCORRECT_VERSION_RC) return(status);
   _lbtop();
   _lbselect_line();
   if (_init_help) {
      _init_help=0;
   }
   _begin_line();
   if (AttemptImmediate && list1.p_Noflines) {
      return(1);
   }
   return(0);
}

text1.on_change()
{
   typeless status=0;
   if (text1.p_user) {
      status=insert_hit_list(p_text);
      if (status==INCORRECT_VERSION_RC) {
         _message_box(nls("You have an old index file.  You should rebuild it now."));
         _mdi.configure_index_file();
      }
   }
}

#if 0
text1.\0-\31()
{
   event=last_event()
   list1._set_focus();
   p_window_id=list1;
   call_event(list1,event);
}
#endif

void list1.on_change(int reason)
{
   if (p_line==0) {
      _lbtop();
      _lbselect_line();
   }
}
text1.'PGDN','PGUP','C_HOME','C_END','DOWN','UP','C-K','C-I','C-N','C-P'()
{
   list1.call_event(list1,last_event());
}
#if 0
text1.up,down,c_home,c_end()
{
   event=last_event();
   list1._set_focus();
   switch (event) {
   case C_END:
      list1._lbbottom();
      break;
   case C_HOME:
      list1._lbtop();
      break;
   case DOWN:
      list1._lbdown();
      break;
   case UP:
      list1._lbup();
      break;
   }
   list1._lbselect_line();
}
#endif

#if 0
list1.on_got_focus()
{
   /* seem to need this */
}
#endif

list1.lbutton_double_click, enter()
{
   typeless flags=0;
   flags=def_help_flags;
   typeless new_help_flags=0;
   if (_close.p_value) {
      new_help_flags|=HF_CLOSE;
   }else{
      new_help_flags&=~HF_CLOSE;
   }
   if (_exact.p_value) {
      new_help_flags|=HF_EXACTMATCH;
   }else{
      new_help_flags&=~HF_EXACTMATCH;
   }
   if (ctlusedefault.p_value) {
      new_help_flags|=HF_USEDEFAULT;
   }else{
      new_help_flags&=~HF_USEDEFAULT;
   }
   if (new_help_flags!=flags) {
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_help_flags=new_help_flags;
   }
   flags=new_help_flags;
   if (text1.p_text=='') {
      return('');
   }
   _str line=_lbget_text();
   _str str=" @\t?@\t";
   str=str'\- @';
   //2:16pm 8/14/1996 - This keeps people from getting a bogus error message
   //                   when the press ok with choices available in list box
   if (line=='') {
      _message_box(nls("No item selected"));
      return(1);
   }
   _str keyword="";
   _str filename="";
   _str realfilename="";
   parse line with keyword (str),'r' filename;
   filename=strip(filename);

   realfilename=get_help_filename(filename,_replace_envvars(def_helpidx_path));
   if (realfilename=='') {
      _message_box(nls("Could not find file %s in Help File Path, or Path.",filename));
   }
   _param1=realfilename;
   _param2=keyword;
   if (_close.p_value) {
      p_active_form._delete_window(0);
   }

   typeless ss="";
   typeless start_ss="";
   typeless status=0;
   int timeout=0;
   _str path="";

   if ((flags & HF_USEDEFAULT) ||
       ( file_eq("mvb",_get_extension(realfilename)) && def_ntIndexHelpOptions.usedde &&
        def_ntIndexHelpOptions.CmdViewer!="")
      ) {
      _ntDefaultHelp(realfilename, keyword);
   } else if (file_eq("mvb",_get_extension(realfilename)) ||
             file_eq(_strip_filename(realfilename,'p'),'vckwds.hlp')) {
      if (!HTMLHelpAvailable() && !VCPPIsUp(def_vcpp_version)) {
         path='';
         //11:13am 8/20/1998
         //Don't take this until we merge the VC++ stuff..
         status=GetVCPPBinPath(path,def_vcpp_version,1);
         if ( status ) return(status);
         if ( path==''|| !file_exists(path) ) {
            return(FILE_NOT_FOUND_RC);
         }
         shell(path,'A');
         timeout=VCPP_STARTUP_TIMEOUT;
         if (timeout>60) timeout=59;
         parse _time("M") with . ":" . ":" start_ss;
         for (;;) {
            delay(50);
            if (VCPPIsVisible(def_vcpp_version)) break;
            parse _time("M") with . ":" . ":" ss;
            if (ss<start_ss) ss=ss:+60;
            if (ss-start_ss>timeout) break;
         }
      }
      VCPP5Help(keyword,def_vcpp_version);
   } else {
      _syshelp(realfilename, keyword, HELP_PARTIALKEY);
   }
   return(0);
}


void _ok.lbutton_up()
{
   list1.call_event(list1, LBUTTON_DOUBLE_CLICK);
}

_exact.lbutton_up()
{
   text1.call_event(CHANGE_OTHER, text1, ON_CHANGE, "W");
   text1._set_focus();
}
#if 0
_help_index_form.on_got_focus()
{
   text1._set_focus();
}
#endif

   #define HELP_PARSE_CHAR "%"
_str _parse_ddehelp_command(_str &command,_str mvbfile,_str keyword)
{
   int j=1;
   for (;;) {
     j=pos(HELP_PARSE_CHAR,command,j);
     if ( ! j ) { break; }
     _str ch=upcase(substr(command,j+1,1));
     _str s="";
     int len=2;
     if ( ch=='K' ) {
       s=keyword;
     } else if ( ch=='F' ) {
        s=mvbfile;
     } else if ( ch==HELP_PARSE_CHAR ) {
       s=HELP_PARSE_CHAR;
     } else {
       len=1;
       s='';
     }
     command=substr(command,1,j-1):+s:+substr(command,j+len);
     j=j+length(s);
   }
   return(command);
}

static void _mvb_dde_help(_str mvbfile,_str keyword)
{
   _str exe_name="";
   _str value="";
   _str server=_parse_ddehelp_command(def_ntIndexHelpOptions.dde_server,mvbfile,keyword);
   _str item=_parse_ddehelp_command(def_ntIndexHelpOptions.dde_item,mvbfile,keyword);
   _str topic=_parse_ddehelp_command(def_ntIndexHelpOptions.dde_topic,mvbfile,keyword);
   typeless status=_ddecommand(server,item,topic);
   if (status) {
      if (upcase(server)!="MSIN") {
         _message_box(nls("Server %s not responding",server));
         return;
      }
      if (def_ntIndexHelpOptions.CmdViewer!="") {
         exe_name=maybe_quote_filename(def_ntIndexHelpOptions.CmdViewer);
      } else {
         value=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Classes\\mdpfile\\shell\\open\\command","");
         if (value=="") {
            exe_name=path_search("msdev.exe","PATH","P");
            if (exe_name=="") {
               _message_box("Can't find msdev.exe.  Please start it running.");
               return;
            }
         } else {
            _str quoted_value=maybe_quote_filename(value);
            exe_name=parse_file(quoted_value);
         }
      }
      status=shell(exe_name,"a");
      //messageNwait("defmain: status="status);
      if (!status) {
         int timeout=HELP_AUTOSTART_TIMEOUT;
         if (timeout>60) timeout=59;
         typeless ss="", start_ss="";
         parse _time("M") with . ":" . ":" start_ss;
         for (;;) {
            status=_ddecommand(server,item,topic);
            if (!status) break;
            parse _time("M") with . ":" . ":" ss;
            if (ss<start_ss) ss=ss:+60;
            if (ss-start_ss>timeout) break;
         }
         if (status) {
            _message_box("Timeout trying to send Visual C++ DDE message.  Try again.");
         }
      } else {
         if (status==FILE_NOT_FOUND_RC) {
            _str filename=parse_file(exe_name);
            _message_box(nls("Program '%s' not found",filename));
         } else if(status!=0) {
            _message_box(nls("Failed to execute '%s'.",exe_name));
         }
      }
   }
}
void _ntDefaultHelp(_str mvbfile,_str keyword)
{
   if(def_ntIndexHelpOptions.usedde) {
      _mvb_dde_help(mvbfile,keyword);
      return;
   }
   _str command=_parse_ddehelp_command(def_ntIndexHelpOptions.CmdViewer,mvbfile,keyword);
   if (command=="") {
      _message_box("No default help set up");
      return;
   }
   typeless status=shell(command,"A");
   if (status==FILE_NOT_FOUND_RC) {
      _str filename=parse_file(command);
      _message_box(nls("Program '%s' not found",filename));
   } else if(status!=0) {
      _message_box(nls("Failed to execute '%s'.",command));
   }
}

defeventtab _default_help_form;
ctlok.on_create()
{
   ctlprogram.p_text=def_ntIndexHelpOptions.CmdViewer;
   ctlserver.p_text=def_ntIndexHelpOptions.dde_server;
   ctltopic.p_text=def_ntIndexHelpOptions.dde_topic;
   ctlitem.p_text=def_ntIndexHelpOptions.dde_item;
   ctlusedde.p_value=(int)def_ntIndexHelpOptions.usedde;
}
ctlok.lbutton_up()
{
   _config_modify_flags(CFGMODIFY_DEFVAR);
   def_ntIndexHelpOptions.CmdViewer=ctlprogram.p_text;
   def_ntIndexHelpOptions.dde_server=ctlserver.p_text;
   def_ntIndexHelpOptions.dde_topic=ctltopic.p_text;
   def_ntIndexHelpOptions.dde_item=ctlitem.p_text;
   def_ntIndexHelpOptions.usedde=ctlusedde.p_value!=0;
   p_active_form._delete_window(1);
}
