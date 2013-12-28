////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50532 $
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
#include "diff.sh"
#include "tagsdb.sh"
#include "color.sh"
#include "markers.sh"
#import "debug.e"
#import "diffedit.e"
#import "diffprog.e"
#import "diffsetup.e"
#import "difftags.e"
#import "dlgman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "ini.e"
#import "main.e"
#import "makefile.e"
#import "merge.e"
#import "mprompt.e"
#import "picture.e"
#import "put.e"
#import "recmacro.e"
#import "saveload.e"
#import "seldisp.e"
#import "sellist.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"
#import "url.e"
#import "util.e"
#import "varedit.e"
#endregion

int def_diff_max_sourcediff_size = 1000000;

static int bMatches[];
static int ToolBoxWID;
static _str diff_form_size;
//   DiffUpdateInfo.timer_handle=-1;
static boolean gignore_change;

//Will try to diff build window

#define USING_MAP_DEBUG_FILE 0
#define FILE_TABLE_DELIM      "\t"

//_str def_max_diffhist='10 10 10 10';

static void diff_init(int id,int OtherWid
                      /*int vid/*,int id,int OtherViewId, _str OtherFilename*/*/)
{
   p_buser=p_color_flags;
   p_color_flags|=MODIFY_COLOR_FLAG;
}

static _str diff_get_http_filename(_str filename,boolean &is_http_filename=false)
{
   is_http_filename=false;
   if (!_diff_is_http_filename(filename)) {
      return(filename);
   }else{
      is_http_filename=true;
      return(_UrlToSlickEdit(filename));
   }
}

static boolean file_exists4(_str filename,boolean doAbsolute=true,
                            int BufferIndex=-1,_str &DocName='',
                            boolean ViewId=false)
{
   _str hidden='h';
   filename=strip(filename,'b','"');
   _str afilename=filename;
   if (doAbsolute) {
      afilename=_diff_absolute(afilename);
   }
   if (p_active_form.p_name=='_diffsetup_form') {
      if ((p_next.p_next.p_next.p_next.p_next.p_value && buf_match(afilename,1,'E')=='') ||
          (p_next.p_next.p_next.p_next.p_value && file_match(maybe_quote_filename(afilename)' +d -p',1)=='') ) {
         if (substr(afilename,1,2)=='\\' && last_char(afilename)!=FILESEP) {
            //This is a UNC name, could be a UNC ROOT...
            afilename=afilename:+FILESEP:+ALLFILES_RE;
            _str first_file_name=file_match(maybe_quote_filename(afilename)' +d -p',1);
            return(first_file_name!='');
         }
         return(0);
      }
   }else{
      _str opt='';
      if (BufferIndex>-1) {
         opt='+bi';
         filename=BufferIndex;
      }else if (ViewId) {
         opt='+bi';
         filename=filename.p_buf_id;
      }
      if (BufferIndex>-1||ViewId) {
         int orig_view_id=p_window_id;
         p_window_id=VSWID_HIDDEN;
         _safe_hidden_window();
         typeless status=load_files(opt' 'filename);
         if (status) {
            return(0);
         }
         DocName=p_DocumentName;
         p_window_id=orig_view_id;
      }else{
         if (buf_match(afilename,1,'E':+hidden)=='' && file_match(maybe_quote_filename(filename)' -D -P',1)=='')  {
            return(0);
         }
      }
   }
   return(1);
}

_control _ctlfile1,_ctlfile1label,_ctlfile2,_ctlfile2label,vscroll1,\
         _ctlcopy_right_all,hscroll1,_ctlfile1_readonly,_ctlfile2_readonly;

static int SaveFileInFormat(int ViewId,int MarkId,_str TypeOption)
{
   typeless status=0;
   int orig_view_id=p_window_id;
   if (MarkId<0) {
      p_window_id=ViewId;
      status=_save_file(TypeOption' +o 'maybe_quote_filename(p_buf_name));
      if (status) {
         _message_box(nls("Could not save file '%s1'\n\n%s2",p_buf_name,get_message(status)));
      }
      p_window_id=orig_view_id;
      return(status);
   }

   _begin_select(MarkId);//Now go fix the whole file

   status=_save_file(TypeOption' +o 'maybe_quote_filename(p_buf_name));
   if (status) {
      _message_box(nls("Could not save file '%s1'\n\n%s2",p_buf_name,get_message(status)));
   }

   p_window_id=orig_view_id;
   return(status);
}

static int CheckForDifferentEOLChars(int ViewId1,int ViewId2,
                                     DIFF_MISC_INFO misc,
                                     int &flags)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId1;
   _str EOL1=p_newline;
   p_window_id=ViewId2;
   _str EOL2=p_newline;
   p_window_id=orig_view_id;
   if (EOL1!=EOL2) {
#if 0 //1:56pm 1/7/2000
      result=_message_box(nls("These files have different End Of Line(EOL) characters.\n\nWould you like to diff them without comparing EOL Characters?"),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDCANCEL) return(COMMAND_CANCELLED_RC);
      if (result==IDYES) {
         flags|=DIFF_DONT_COMPARE_EOL_CHARS;
      }
#else
      int status=show('-modal _textbox_form',
                      'EOL Characters do not match',
                      TB_RETRIEVE_INIT, //Flags
                      '',//width
                      '',//help item
                      "Compare EOL chars,Do not compare EOL chars,Convert EOL chars,Cancel:_cancel\tThese files have different End Of Line(EOL) characters:"
                      );
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      }
      if (status==1) {
         return(0);
      }
      if (status==2) {
         flags|=DIFF_DONT_COMPARE_EOL_CHARS;
         return(0);
      }
      if (status==3) {
         _str Captions[];
         Captions[0]="Convert both files to DOS file format";
         Captions[1]="Convert both files to UNIX file format";
         status=RadioButtons("Convert File Types",Captions);
         if (status==COMMAND_CANCELLED_RC) {
            return(COMMAND_CANCELLED_RC);
         }
         if (status==1) {
            SaveFileInFormat(ViewId1,misc.MarkId1,'+fd');
            SaveFileInFormat(ViewId2,misc.MarkId2,'+fd');
         }else if (status==2) {
            SaveFileInFormat(ViewId1,misc.MarkId1,'+fu');
            SaveFileInFormat(ViewId2,misc.MarkId2,'+fu');
         }
      }
#endif
   }
   return(0);
}

void _BlastUndoInfo()
{
   int old=p_undo_steps;
   p_undo_steps=0;
   p_undo_steps=old;
}

struct DIFF_SETUP_INFO {
   _str path1;             //Just a path if using MFDiff
   _str path2;
   _str filespec;          //'' if not using mutlti-file diff
   _str excludeFilespec;   //'' if not using mutlti-file diff
   boolean recursive;      //Only matters if using mutlti-file diff
   boolean smartDiff;      //Only matters if NOT USING mutlti-file diff...Probably won't matter at all
   boolean interleaved;    //Only matters if NOT USING mutlti-file diff
   int recordWidth;        //Only matters if NOT USING mutlti-file diff
   boolean file1IsFile;    //Only matters if NOT USING mutlti-file diff
   boolean file2IsFile;    //Only matters if NOT USING mutlti-file diff
   int firstline1;
   int firstline2;
   int lastline1;
   int lastline2;
   boolean buf1;           //Only matters if NOT USING mutlti-file diff
   boolean buf2;           //Only matters if NOT USING mutlti-file diff
   _str fileListInfo;      //If not blank, this information is for the "-listonly" option
                           //format: -listonly output_filename path1filelist|path2filelist [differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2][,nextoption]
   boolean compareAllSymbols;
   boolean compareOnly;
   boolean restoreFromINI;
};


static void InitDiffSetupStruct(DIFF_SETUP_INFO *psetupInfo)
{
   psetupInfo->path1='';
   psetupInfo->path2='';
   psetupInfo->filespec='';
   psetupInfo->excludeFilespec='';
   psetupInfo->recursive=false;
   psetupInfo->smartDiff=false;
   psetupInfo->interleaved=false;
   psetupInfo->recordWidth=0;
   psetupInfo->file1IsFile=false;
   psetupInfo->file2IsFile=false;
   psetupInfo->compareAllSymbols=false;
   psetupInfo->compareOnly=false;
   psetupInfo->restoreFromINI=false;
}

boolean gDiffCancel=0;

//Now dup'd in diff.e and diffedit.e
static int GetOtherWid(int &wid)
{
   int otherwid=0;
   wid=p_window_id;
   if (wid==_ctlfile1) {
      otherwid=_ctlfile2;
   }else{
      otherwid=_ctlfile1;
   }
   return(otherwid);
}

void _diff_remove_nosave_lines()
{
   if (p_NofNoSave) {
      int old_ModifyFlags=p_ModifyFlags;
      typeless p;
      _save_pos2(p);
      top();
      for (;;) {
         if (_lineflags()&NOSAVE_LF) {
            if (_delete_line()) {
               break;
            }
         } else {
            if(down()) break;
         }
      }
      _restore_pos2(p);
      p_ModifyFlags=old_ModifyFlags;
   }
}
void _diff_show_all()
{
   if (p_Nofhidden) {
      show_all();
      //Just line them back up together.  I was not able to reproduce this,but
      //Clark and I saw some peculiarities 10:47am 4/4/1996
      int wid=0;
      int otherwid=GetOtherWid(wid);
      //3:30pm 6/11/1997:
      //Changed this so that it should work for either file
      otherwid.set_scroll_pos(wid.p_left_edge,wid.p_cursor_y);
   }
}

DIFF_SETUP_DATA gDiffSetupData;

void InitMiscDiffInfo(DIFF_MISC_INFO &misc,_str Type)
{
   misc.DiffParentWID=-1;
   misc.Buf1StartTime='';
   misc.Buf2StartTime='';
   misc.IntraLineIsOff=0;
   misc.DontDeleteMergeOutput=false;
   misc.Bookmarks=null;
   misc.PreserveInfo='';
   misc.AutoClose=false;
   misc.MarkId1=-1;
   misc.WholeFileBufId1=-1;
   misc.MarkId2=-1;
   misc.WholeFileBufId2=-1;
   misc.OrigEncoding1=-1;
   misc.OrigEncoding2=-1;
   misc.RefreshTagsOnClose=false;
   misc.SymbolViewId1=0;
   misc.SymbolViewId2=0;
}

static void MarkSection(int ViewId,int MarkId,int FirstLine,int LastLine)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   p_line=FirstLine;
   typeless status=_select_line(MarkId);
   p_line=LastLine;
   status=_select_line(MarkId);
   p_window_id=orig_view_id;
}

/** 
 * Return the load_files option to force a buffer to have the 
 * same newline characters as <B>NewLine</B> 
 *  
 * @param NewLine new line character(s) to create load_files 
 *                option for
 * 
 * @return _str string "+F..." to match the new line 
 *         character(s) in <B>NewLine</B>
 */
static _str getNewLineOption(_str NewLine)
{
   Options:='+F';
   if (length(NewLine)==2) {
      if (NewLine=="\r\n") {
         //DOS file
         Options=Options'D';
      }else if (NewLine=="\r\n") {
         //Mac file
         Options=Options'M';
      }
   }else{
      Options=Options:+_asc(NewLine);
   }
   return Options;
}

static int GetViewWithRegion(int ViewId,int FirstLine,int LastLine,int &markid,_str NewLine,
                             boolean OrigReadOnly)
{
   //int orig_view_id=_create_temp_view(temp_view_id);
   p_window_id=ViewId;
   _str BufName=p_buf_name;
   _str Options=build_load_options(BufName);
   int orig_view_id=p_window_id;

   //Have to match the EOL chars with the "ParentFile", so we don't get unnecessary
   //messages
   if (NewLine!='') {
      Options :+= getNewLineOption(NewLine);
   }
   int temp_view_id=0;
   typeless status=_create_temp_view(temp_view_id);

   typeless steps=32000;
   _str rest='';
   if (pos('+u',def_load_options,1,'i')) {
      parse def_load_options with '+U:' undo rest;
      steps=undo;
   }
   p_undo_steps=steps;
   markid=_alloc_selection();
   p_window_id=ViewId;

   typeless encoding=p_encoding;
   _str mode_name=p_mode_name;
   _str lang=p_LangId;
   int color_flags=p_color_flags;
   _str lexer_name=p_lexer_name;
   _str tabs=p_tabs;
   typeless mode_eventtab=p_mode_eventtab;
   int index=p_index;
   int indent_style=p_indent_style;
   int syntax_indent=p_SyntaxIndent;


   MarkSection(ViewId,markid,FirstLine,LastLine);
   p_window_id=temp_view_id;
   p_encoding=encoding;
   p_DocumentName=BufName' (lines 'FirstLine'-'LastLine')';
   _copy_to_cursor(markid);
   //Selection got moved
   _deselect(markid);
   MarkSection(ViewId,markid,FirstLine,LastLine);
   top();up();
   while (!down()) {
      _lineflags(0,INSERTED_LINE_LF|MODIFY_LF|NOSAVE_LF);
   }

   p_mode_name=mode_name;
   p_LangId=lang;
   p_color_flags=color_flags;
   p_lexer_name=lexer_name;
   p_tabs=tabs;
   p_modify=0;
   p_readonly_mode=OrigReadOnly;
   p_mode_eventtab=mode_eventtab;
   p_index=index;
   p_indent_style=indent_style;
   p_SyntaxIndent=syntax_indent;

   p_window_id=orig_view_id;
   //_free_selection(markid);
   return(temp_view_id);
}

int _DiffLoadFileAndGetRegionView(_str filename,boolean FilenameIsBufferId,
                                  boolean FilenameIsViewId,int FirstLine,int LastLine,
                                  boolean IsDisk,_str &NewFilename,int &BufId,
                                  int &MarkId,boolean &InMem,int &NewViewId,boolean &OldReadOnly=false,
                                  boolean &modify=true,boolean SetReadOnly=true,
                                  _str &FileDate='')
{
   //First Load the original file
   InMem=1;
   _str Options=build_load_options(filename);
   /*if (NewLine!='') {
      Options=' +F'_asc(NewLine);
   }*/
   typeless status=0;
   filename=strip(filename,'B','"');
   origWID := _create_temp_view(auto tempWID);
   if (FilenameIsBufferId) {
      status = load_files(Options' +q +bi 'filename);
   }else if (FilenameIsViewId) {
      status = load_files(Options' +q +bi 'filename.p_buf_id);
   }else if (IsDisk) {
      _str opts=build_load_options(filename);
      status = load_files(Options' +q 'opts' +d 'maybe_quote_filename(filename));
      if (!status) {
         _SetEditorLanguage();
      }
      InMem=0;
   }else{
      status = load_files(Options' +q +b 'filename);
      if (status) {
         InMem=0;
         status = load_files(Options' 'maybe_quote_filename(filename));
      }
   }
   if (status) {
      _delete_temp_view(tempWID,false);
      return(status);
   }
   FileDate=_file_date(p_buf_name,'B');
   if (!InMem) p_buf_flags|=VSBUFFLAG_HIDDEN;
   if (LastLine<0) LastLine=p_Noflines;
   if (SetReadOnly) {
      typeless t=2;
      OldReadOnly=p_readonly_mode;
      p_readonly_mode=t;
   }
   if (!InMem) {
      _SetEditorLanguage();
   }
   BufId=p_buf_id;
   _str NewLine=p_newline;
   modify=p_modify;
   p_window_id=origWID;
   NewViewId=GetViewWithRegion(tempWID,FirstLine,LastLine,MarkId,NewLine,OldReadOnly);
   p_window_id=NewViewId;
   NewFilename=p_buf_id;
   p_window_id=origWID;
   _delete_temp_view(tempWID,false);
   return(0);
}

int _DiffLoadFileAndGetRegionView2(_str filename,int SourceBufId,
                                   int ViewId,int FirstLine,int LastLine,
                                   boolean IsDisk,int &NewBufId,int &BufId,
                                   int &MarkId,int &InMem,int &NewViewId,
                                   _str &FileDate,_str SymbolName,
                                   DIFF_DELETE_ITEM (*pDelItemList)[]
                                   )
{
   tag_tree_decompose_caption(SymbolName,auto tag_name);
   boolean OldReadOnly=false;
   //First Load the original file
   int orig_view_id=p_window_id;

   if ( SymbolName!='' && FirstLine==0 && LastLine==0 ) {
      // If we were given a name, we need to figure out what the first and last
      // line are.
      _str TagType='';
      FirstLine=0;LastLine=0;
      int CommentLine=0;
      int status=FindSymbolInfo(filename,tag_name,SymbolName,FirstLine,LastLine,CommentLine,TagType);
   }

   typeless status=0;
   origWID := _create_temp_view(auto tempWID);
   InMem=1;
   _str Options=build_load_options(filename);
   filename=strip(filename,'B','"');
   if (SourceBufId>-1) {
      status=load_files(Options' +q +bi 'SourceBufId);
   }else if (ViewId) {
      status=load_files(Options' +q +bi 'ViewId.p_buf_id);
   }else if (IsDisk) {
      _str opts=build_load_options(filename);
      status=load_files(Options' +q 'opts' +d 'maybe_quote_filename(filename));
      if (!status) {
         _SetEditorLanguage();
      }
      InMem=0;
   }else{
      status=load_files(Options' +q +b 'filename);
      if (status) {
         InMem=0;
         status=load_files(Options' 'maybe_quote_filename(filename));
      }
   }
   if (status) {
      _delete_temp_view(tempWID,false);
      return(status);
   }
   if ( !InMem ) {
      diffAddToDeleteList(p_buf_id,false,pDelItemList);
   }
   FileDate=_file_date(p_buf_name,'B');
   if (!InMem) p_buf_flags|=VSBUFFLAG_HIDDEN;
   if (LastLine<0) LastLine=p_Noflines;

   typeless t=2;
   OldReadOnly=p_readonly_mode;
   p_readonly_mode=t;

   if (!InMem) {
      _SetEditorLanguage();
   }
   BufId=p_buf_id;
   _str NewLine=p_newline;
   p_window_id = origWID;
   NewViewId=GetViewWithRegion(tempWID,FirstLine,LastLine,MarkId,NewLine,OldReadOnly);
   p_window_id=NewViewId;
   NewBufId=p_buf_id;
   p_window_id=origWID;
   _delete_temp_view(tempWID,false);
   return(0);
}

static void GetOptionsFromFile2(_str field_name,_str &result)
{
   result='';
   top();
   int status=search('^'_escape_re_chars(field_name)'\:?@$','@ri');
   if (!status) {
      _str line='';
      get_line(line);
      parse line with (field_name:+':') result;
   }
}

static int GetOptionsFromFile(_str options_filename,
                              _str &filespec,
                              _str &excludeFilespec,
                              boolean &recursive,
                              _str &filename1,
                              _str &filename2)
{
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(options_filename,temp_view_id,orig_view_id);
   if (status) return(status);
   GetOptionsFromFile2('filespec',filespec);
   GetOptionsFromFile2('excludefilespec',excludeFilespec);
   _str recursivestr='';
   GetOptionsFromFile2('recursive',recursivestr);
   if ( recursivestr=='' || !isinteger(recursivestr) ) {
      recursive=false;
   }else{
      int recursiveint=(int)recursivestr;
      recursive=recursiveint!=0;
   }
   GetOptionsFromFile2('path1',filename1);
   GetOptionsFromFile2('path2',filename2);
   p_window_id=orig_view_id;
   ConvertFromSemiDelims(filespec);
   ConvertFromSemiDelims(excludeFilespec);
   _delete_temp_view(temp_view_id);
   return(0);
}

static void ConvertFromSemiDelims(_str &filespec)
{
   if (pos(PATHSEP,filespec)) {
      _str cur='';
      _str temp='';
      for (;;) {
         parse filespec with cur (PATHSEP) filespec;
         if (cur=='') break;
         temp=temp' 'maybe_quote_filename(cur);
      }
      filespec=temp;
   }
}


static void GetBufferInfoFromView(int ViewId,boolean &Modify,
                                  _str &BufName,_str &DocName,
                                  _str &Encoding,_str &Utf8)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   Modify=p_modify;
   BufName=p_buf_name;
   DocName=p_DocumentName;
   Encoding=p_encoding;
   Utf8=p_UTF8;
   p_window_id=orig_view_id;
}

static int CheckEncoding(boolean &unicodeSourceFiles,int ViewId1,int ViewId2,
                         _str File1Title='',_str File2Title='',
                         _str OutputEncodingOption='',
                         boolean ReturnIfEncoded=false)
{
   _str encoding1,encoding2;
   boolean modify1,modify2;
   _str bufname1,bufname2,docname1,docname2,utf81,utf82;
   GetBufferInfoFromView(ViewId1,modify1,bufname1,docname1,encoding1,utf81);
   GetBufferInfoFromView(ViewId2,modify2,bufname2,docname2,encoding2,utf82);

   if ((encoding1==VSCP_EBCDIC_SBCS && utf82) ||
       (encoding2==VSCP_EBCDIC_SBCS && utf81)) {
      _message_box(nls("You cannot diff a unicode file with an EBCDIC file."));
      return(1);
   }

   bufname1=bufname1!=''?bufname1:docname1;
   if ( bufname1=='' ) bufname1=File1Title;

   bufname2=bufname2!=''?bufname2:docname2;
   if ( bufname2=='' ) bufname2=File2Title;

   if ( ReturnIfEncoded) {
      unicodeSourceFiles=(utf81!=0 || utf82!=0);
      return(0);
   }

   typeless status=0;
   _str msg='';
   if (utf81!=utf82) {
      msg="You are attempting to diff a unicode file with a non-unicode file.  '%s' cannot temporarily be converted to unicode because the buffer is modified.  Please close the file first.";
      if (modify1) {
         _message_box(nls(msg,bufname1));
         return(1);
      }else if (modify2) {
         _message_box(nls(msg,bufname2));
         return(1);
      }
      // We have to change one of these to match the other.
      status=show('-modal _diff_encoding_form',bufname1,bufname2,encoding1,encoding2,modify1,modify2);
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      }else if (status==-1) {
         return(0);//Nothing to do
      }else{
         _str option=status;//This is the option to reload one or both files with
         int orig_view_id=p_window_id;

         DIFF_MISC_INFO misc=_DiffGetMiscInfo();

         p_window_id=ViewId1;
         status=MaybeReloadFile(option,misc.OrigEncoding1);
         p_window_id=orig_view_id;
         if (status) return(status);

         p_window_id=ViewId2;
         status=MaybeReloadFile(option,misc.OrigEncoding2);
         p_window_id=orig_view_id;
         if (status) return(status);

         OutputEncodingOption=option;
         _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,_ctlfile1);
      }
   }
   unicodeSourceFiles=encoding1!=0 || encoding2!=0;

   return(0);
}

static int MaybeReloadFile(_str option,int &OrigEncoding)
{
   _str filename=p_buf_name;

   // There are cases where we append a FILESEP to the buf name after it is
   // loaded so that if we do a "+b filename" on the same name later, we do
   // not get the one loaded by the diff by accident.
   _str ch=last_char(filename);
   filename=strip(filename,'T',FILESEP);

   if (p_encoding) {
      return(0);
   }
   /*if (p_modify) {
      _message_box(nls("You are attempting to diff a unicode file with a non-unicode file.  '%s' cannot temporarily be converted to unicode because the buffer is modified.  Please close the file first.",filename));
      return(1);
   }*/

   //Was going to use this to double check the buffer size against the file size,
   //but it may not work.
   /*if (p_RBufSize!=_filesize(filename)) {
      say('filename='filename' p_RBufSize='p_RBufSize' size='_filesize(filename));
      _message_box(nls("SlickEdit cannot change the encoding for '%s' because the buffer size does not match the size on disk.  Please close the file first.",filename));
      return(1);
   }*/

   OrigEncoding=p_encoding;
   int status=load_files(def_load_options' +r +d 'option' 'maybe_quote_filename(filename));
   if (!status && ch==FILESEP) {
      p_buf_name=p_buf_name:+FILESEP;
   }

   return(status);
}

int _DiffWriteConfigInfoToIniFile(_str SectionName,int DialogX,int DialogY,int DialogWidth,int DialogHeight,
                                  _str WindowState='')
{
   _str ini_filename=_ConfigPath():+DIFFMAP_FILENAME;
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);
   insert_line('x='DialogX);
   insert_line('y='DialogY);
   insert_line('width='DialogWidth);
   insert_line('height='DialogHeight);
   if ( WindowState!='' ) insert_line('window_state='WindowState);
   insert_line('def_diff_options='def_diff_options);
   insert_line('def_diff_edit_options='def_diff_edit_options);
   p_window_id=orig_view_id;
   int status=_ini_put_section(ini_filename,SectionName,temp_view_id);
   return(status);
}

int _DiffGetConfigInfoFromIniFile(_str SectionName,int &DialogX,int &DialogY,int &DialogWidth,int &DialogHeight,_str &WindowState='',int &DiffEditOptions=0,int &DiffOptions=0)
{
   DialogWidth=MAXINT;
   DialogHeight=MAXINT;
   DialogX=MAXINT;
   DialogY=MAXINT;
   _str ini_filename=_ConfigPath():+DIFFMAP_FILENAME;
   int temp_view_id=0;
   int status=_ini_get_section(ini_filename,SectionName,temp_view_id);
   if ( status ) {
      return(1);
   }
   int geometryInfo:[];
   _str window_state='';
   int orig_view_id=p_window_id;
   p_window_id=temp_view_id;
   top();up();
   while (!down()) {
      _str line='';
      get_line(line);
      if ( line=='' ) continue;
      _str lhs,rhs;
      parse line with lhs '=' rhs;
      if ( lhs=='window_state' ) {
         window_state=rhs;
      }else if ( isinteger(rhs) ) {
         geometryInfo:[lhs]=(int)rhs;
      }
   }

   if ( geometryInfo:["x"]==null
        || geometryInfo:["y"]==null
        || geometryInfo:["width"]==null
        || geometryInfo:["height"]==null 
        ) {
      return(1);
   }
   if (geometryInfo:["def_diff_options"]==null ) {
      def_diff_options=0;
   }
   if ( geometryInfo:["def_diff_edit_options"]==null ) {
      def_diff_edit_options=0;
   }
   if ( window_state=='' ) {
      window_state='N';
   }

   DialogX=geometryInfo:["x"];
   DialogY=geometryInfo:["y"];
   DialogWidth=geometryInfo:["width"];
   DialogHeight=geometryInfo:["height"];
   WindowState=window_state;
   DiffOptions=geometryInfo:["def_diff_options"];
   DiffEditOptions=geometryInfo:["def_diff_edit_options"];

   DialogX=_dx2lx(SM_TWIP,DialogX);
   DialogWidth=_dx2lx(SM_TWIP,DialogWidth);
   DialogY=_dy2ly(SM_TWIP,DialogY);
   DialogHeight=_dy2ly(SM_TWIP,DialogHeight);

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static boolean NeedToPromptForArgs(_str arg1,int &modal,boolean &restorefromini)
{
   if ( arg1=='' ) {
      return(true);
   }
   for (;;) {
      _str cur=lowcase(parse_file(arg1));
      if ( cur=='' ) break;
      if ( cur != '-modal' 
           && cur != '-restorefromini' ) {
         return(false);
      }
      switch (cur) {
      case '-modal':
         modal=1;break;
      case '-restorefromini':
         restorefromini=true;break;
      }
   }
   return(true);
}

int _DiffShowComment();

#define DiffGetForceDiskLoadString(a,b,c) ( (a && !b && c<0)?'+d':'')

static int DiffSetupDialog(_str File1Name,boolean RestoreFromINI)
{
   int DialogX=MAXINT,DialogY=MAXINT,DialogWidth=MAXINT,DialogHeight=MAXINT;
   if ( RestoreFromINI ) {
      _DiffGetConfigInfoFromIniFile("DiffSetupGeometry",DialogX,DialogY,DialogWidth,DialogHeight);
   }
   sessionName := "";
   int wid=show('-app -hidden _diffsetup_form',File1Name,false,RestoreFromINI,&sessionName);
   if ( !wid ) {
      return(1);
   }
   if ( DialogX!=MAXINT ) {
      wid.p_x=DialogX;
      wid.p_y=DialogY;
   }
   wid.p_ShowModal = 1;
   wid.p_visible   = 1;
   _str result=_modal_wait(wid);
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   return(0);
}

_command diff_options()
{
   show('-modal _diffsetup_form',"",true,false);
}

/**
 * @return Returns true if the given buffer correspond to the
 *         name of an interleaved diff buffer.
 * 
 * @param name     document name to check.
 */
boolean _isInterleavedDiffBufferName(_str name)
{
   return (substr(name,1,5)=="Diff<" && last_char(name)=='>');
}

static void clearLineFlags()
{
   top();up();
   while (!down()) {
      _lineflags(0,MODIFY_LF);
      _lineflags(0,INSERTED_LINE_LF);
   }
}

static boolean gShowWarningMessage = true;

static void setupOKButton(_str Comment,_str CommentButtonCaption,typeless OkPtr)
{
   _nocheck _control _ctlok;
   if (gDiffSetupData.Comment!='') {
      _ctlok.p_visible=1;
      _ctlok.p_enabled=1;
      if (gDiffSetupData.CommentButtonCaption!='') {
         _ctlok.p_caption=strip(gDiffSetupData.CommentButtonCaption,'B','"');
      }
      _ctlok.p_width=max(diff_form_wid._ctlok._text_width(' '_ctlok.p_caption' '),_ctlok.p_prev.p_width);
      _ctlok.p_cancel=false;
   }else if (OkPtr._varformat()==VF_FUNPTR ||
             (OkPtr._varformat()==VF_LSTR && substr((typeless) OkPtr,1,1)=='&')) {
      if (gDiffSetupData.CommentButtonCaption!='') {
         _ctlok.p_caption=strip(gDiffSetupData.CommentButtonCaption,'B','"');
      }
      _ctlok.p_visible=1;
      _ctlok.p_enabled=1;
   }
}

static void setupCodeToggleButton(boolean sourceDiffOption,int balanaceBuffersStatus)
{
   wid := _find_object("ctltypetoggle",'N');
   
   ctltypetoggle.p_visible = false;
   if ( sourceDiffOption && !balanaceBuffersStatus ) {
      ctltypetoggle.p_visible = true;
      ctltypetoggle.p_caption = "Line Diff";
      ctltypetoggle.p_enabled = 1;
   }else{
      if ( _ctlfile1.p_lexer_name!="" && _ctlfile2.p_lexer_name!="" ) {
         ctltypetoggle.p_visible = true;
         ctltypetoggle.p_caption = "Source Diff";
         ctltypetoggle.p_enabled = 1;
      }
   }
}

_str _DiffFilename2LangId(_str filename,int bufferIndex=-1)
{
   langID := "";
   if ( bufferIndex<0 ) {
      langID = _Filename2LangId(filename);
   }else{
      status := _open_temp_view("",auto temp_wid,auto orig_wid,"+bi ":+bufferIndex);
      if ( !status ) {
         // Was loaded already, see if there is already a lang id
         if ( p_LangId!="" ) {
            langID = p_LangId;
         }else{
            bufName := p_buf_name;
            langID = _Filename2LangId(bufName);
         }
         _delete_temp_view(temp_wid);
         p_window_id = orig_wid;
      }
   }
   return langID;
}

static void diffAddToDeleteList(int itemID,boolean isView,DIFF_DELETE_ITEM (*pItemList)[])
{
   DIFF_DELETE_ITEM curItem;
   curItem.isSuspended = false;
   curItem.isView = isView;
   curItem.item = itemID;

   pItemList->[pItemList->_length()] = curItem;
}

static void gotoPosMarker(int posMarkerId)
{
   if ( posMarkerId>-1 ) {
      wid := _find_control("_ctlfile1");
      _ctlfile1._begin_select(posMarkerId);
      _ctlfile2.p_line = _ctlfile1.p_line;
      _ctlfile1.center_line();
      _ctlfile2.center_line();
      _free_selection(posMarkerId);
   }
}

/** 
 * 
 * @param specifiedSourceDiffOnCommandLine 
 * @param balanceBuffersFirst set to true if we are doing a code 
 *                            diff
 * @param fileSizeIsOK set to true if file size is less than 
 *                     <B>def_diff_max_sourcediff_size</B> or
 *                     the user decides to go ahead anyway
 * @param Wid1 Window that has file 1
 * @param Wid2 Window that has file 2
 * 
 * @return int 0 if completes successfully. 
 *         COMMAND_CANCELLED_RC if the usere cancels during one
 *         of the prompts
 */
static int MaybePromptAboutSourceDiff(boolean specifiedSourceDiffOnCommandLine,boolean &balanceBuffersFirst,boolean &fileSizeIsOK,int Wid1,int Wid2) 
{
   boolean dontShowAgain = false;
   typeless useSourceDiffResult=IDYES;
   if ( gShowWarningMessage && !specifiedSourceDiffOnCommandLine ) {
      useSourceDiffResult=show('-modal _vc_auto_inout_form',
                               "You are about to run Source Diff which will balance whitespace and newline characters in a read-only copy of file 2 before comparing the files.\n\nDo you wish to use Source Diff?",
                               "Don't show this again");
      dontShowAgain=_param1;
      if ( dontShowAgain ) {
         gShowWarningMessage = false;
      }
   }
   if ( useSourceDiffResult==IDYES ) {
      balanceBuffersFirst = true;
   }else if ( useSourceDiffResult==IDNO ) {
      balanceBuffersFirst = false;
   }else if ( useSourceDiffResult=="" ) {
      balanceBuffersFirst = false;
      return COMMAND_CANCELLED_RC;
   }
   if ( !balanceBuffersFirst ) {
       if ( dontShowAgain ) {
          def_diff_options |= DIFF_NO_SOURCE_DIFF;
       }
       if ( gDiffSetupData.ReadOnly2==DIFF_READONLY_SOURCEDIFF ) {
          gDiffSetupData.ReadOnly2 = DIFF_READONLY_OFF;
       }
    }
   return 0;
}

static void setupProgressForFileDiff(int gauge_form_wid,int &gaugeWID)
{
   origWID := p_window_id;
   p_window_id = gauge_form_wid;
   p_active_form.p_caption='Diff Progress';
   _nocheck _control gauge1;
   gaugeWID=gauge1;

   // We leave this visible because it is used later, but set the caption blank
   // so that the user will not see the "label1" caption that is there by default
   label1.p_caption = "";

   label2.p_visible = 0;
   label3.p_visible = 0;
   cancelSpace := ctlcancel.p_y - (gauge1.p_y+gauge1.p_height);
   labelSpace := label3.p_y - (label2.p_y+label2.p_height);

   gauge1.p_y = label2.p_y;
   ctlcancel.p_y = gauge1.p_y + gauge1.p_height + cancelSpace;

   p_active_form.p_height -= (label2.p_height+label3.p_height+(2*labelSpace));

   label2._delete_window();
   label3._delete_window();

   ctlcancel.refresh('W');

   p_window_id = origWID;
}

/**
 * Visually compare two files or directories for differences.
 * <p>
 * Command line usage:
 * <pre>
 *    diff [options] &lt;file1&gt; &lt;file2&gt;
 * </pre>
 * <p>
 * Command line options:  (options are case insensitive)
 * <dl compact>
 * <dt><b>-i</b>
 * <dd>interleaved output
 * <dt><b>-r1</b>
 * <dd>make file 1 read only
 * <dt><b>-r2</b>
 * <dd>make file 2 read only
 * <dt><b>-q</b>
 * <dd>quiet option:only shuts off the "Files match" message
 * <dt><b>-modal</b>
 * <dd>run diff modally
 * <dt><b>-B1</b>
 * <dd>filename1 is a buffer name and should be loaded +b w/o absolute
 * <dt><b>-B2</b>
 * <dd>filename2 is a buffer name and should be loaded +b w/o absolute
 * <dt><b>-bi1</b>
 * <dd>filename1 is a buffer id
 * <dt><b>-bi2</b>
 * <dd>filename2 is a buffer id
 * <dt><b>-preserve1</b>
 * <dd>Do not delete buffer 1 when the diff closes.  Should
 *     be used in conjunction with -b1 or -bi1.  If the user
 *     chooses to "save" changes to this buffer, the modify
 *     flag will be left on to show the caller that the user
 *     wishes to save the file.  If the user does not save
 *     changes to the buffer, all changes will be undone, and
 *     the modify flag will be off.
 *     When using this option, be sure to turn
 *     p_modify(VSP_MODIFY) off, and set
 *     p_undo_steps(VSP_UNDOSTEPS) to a large number(32000 or more).
 * <dt><b>-preserve2</b>
 * <dd>Same as -preserve1, except for buffer 2.
 * <dt><b>-NoMap</b>
 * <dd>Do not add information about this diff to the mapping files
 * <dt><b>-optionsfile</b>
 * <dd>Put options in a file.  Used to launch a multifile
 *     diff in a different process.
 *     Supports the following options:
 *     <pre>
 *         filespec:&lt;filespec list, space delimited&gt;
 *         excludefilespec:&lt;filespec list, space delimited&gt;
 *         recursive:1|0
 *         path1:&lt;first path&gt;
 *         path2:&lt;second path&gt;
 *     </pre>
 *     diff will delete the file after it retrieves the
 *     information from the file
 * <dt><b>-listonly</b> &lt;outputfile&gt; &lt;PATH1FILELIST|PATH2FILELIST&gt;
 *                      &lt;differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2&gt;
 * <dd>will run a multifile diff
 *     and give the for the path specified by the second argument
 *     in the output file specified.  The third argument is a
 *     comma delimited list of what type of items to put in
 *     the output file.
 * <dt><b>-verifymfd</b>
 * <dd>verify multifile diff input is valid
 * <dt><b>-registerasmfdchild</b> &lt;parent_wid&gt;
 * <dd>specify that this diff will be a child of the
 *     multi-file diff dialog &lt;parent_wid&gt;
 * <dt><b>-refreshtagsclose</b> &lt;file1&gt; &lt;file2&gt;
 * <dd>must be used "-registerasmfdchild &lt;wid&gt;".  When this
 *     diff is closed, recompare file1 and file2 and refresh
 *     the tags expanded for this file in the parent dialog.
 * <dt><b>-nomapping</b>
 * <dd>Do not save mapping for these files in diffmap.ini.
 *     This option should be used for diffs that are done
 *     with data that are not real files, like two old
 *     versions of a file from a version control system
 * <dt><b>-d1</b>                  
 * <dd>Get file one from disk
 * <dt><b>-d2</b>
 * <dd>Get file two from disk
 * <dt><b>-dialogtitle</b> &lt;title&gt; 
 * <dd>Set title of diff dialog to <B>title</B>
 * <dt><b>-file1title</b>  &lt;title&gt; 
 * <dd>Set title of file1 dialog to <B>title</B>
 * <dt><b>-file2title</b>  &lt;title&gt;
 * <dd>Set title of file2 dialog to <B>title</B>
 * <dt><b>-savebutton1caption</b>  &lt;caption&gt; 
 * <dd>Set title caption of file1's save button
 * <dt><b>-savebutton2caption</b> &lt;caption&gt; 
 * <dd>Set title caption of file2's save button
 * <dt><b>-viewonly</b>
 * <dd>View differences only.  Buffers are set to read only
 *     and  copy/delete buttons are hidden.
 * <dt><b>-comment</b>
 * <dd>currently unused
 * <dt><b>-ok</b>
 * <dd>currently unused
 * <dt><b>-commentbuttoncaption</b>
 * <dd>currently unused - Caption for <B>OK</B> button
 * <dt><b>-viewid1</b>             
 * <dd>file1 is a view id
 * <dt><b>-viewid2</b>             
 * <dd>file2 is a view id
 * <dt><b>-imaginarylinecaption</b>
 * <dd>caption to use for <I>Imaginary Buffer Line</B>s
 * <dt><b>-autoclose</b>
 * <dd>If a diff is launched from a multi-file diff, when the
 *     <B>Next Diff</B> button is pressed and there are no
 *     more differences, automatically close this diff dialog
 * <dt><b>-geometry</b> &lt;width&gt;[xHeight [+X[+Y]]l]
 * <dd>specify width, height, x and y
 * <dt><b>-restorefromini</b>
 * <dd>save/restore geometry information and options to/from diffmap.ini.
 * <dt><b>-tags</b>
 * <dd>Show different tags for these files.
 * <dt><b>-matchmode2</b>
 * <dd>Set file 2's mode to match that of file 1.
 * <dt><b>-range1:</b>  &lt;start,end&gt
 * <dd>Set the range of lines to compare in file 1.
 * <dt><b>-range2:</b>  &lt;start,end&gt
 * <dd>Set the range of lines to compare in file 2.
 * <dt><b>-noeol</b>               
 * <dd>Do not compare the EOL characters
 * <dt><b>-symbol</b> &lt;symbolname&gt; 
 * <dd>Compare symbol named <B>symbolname</B> in both files
 * <dt><b>-useglobaldata</b>       
 * <dd>Get options from the <B>gDiffSetupData</B> global struct.
 * <dt><b>-sourcediff</b>       
 * <dd>Diff code, use token information to balance files before 
 * running diff 
 * </dl>
 * <p>
 * The options below are intended only to be used to implement
 * asynchronous diffs which invoke another copy of the editor.
 * <dl compact>
 * <dt><b>-optionflags</b> &lt;flags&gt;
 * <dd>set def_diff_options to flags
 * <dt><b>-recursive</b>
 * <dd>recurse subdirectories(multi-file only)
 * <dt><b>-loadstate</b> &lt;diffstatefilename&gt;
 * <dd>Load the previously saved diff output specified
 * </dl>
 * 
 * @return 0 if successful, Otherwise a nonzero error code.
 *         <p>
 *         Note that "successful" implies nothing about the 
 *         number of differences between the files, just that 
 *         all files were loaded successfully, 
 *         and the difference engine ran succesfully.
 * 
 * @param cmdline
 * @param showNoEditorOptions
 * 
 * @see merge
 * @see diff_with
 * @categories Buffer_Functions, File_Functions
 */
_command int diff(_str cmdline='',boolean showNoEditorOptions=false) name_info(FILE_ARG'*,'VSARG2_EDITORCTL)
{
   _str LineInfo1="1",LineInfo2="1";
   int index=find_index('Diff',PROC_TYPE);
   if (!index || !index_callable(index)) {
      _message_box("vsvcs.dll not loaded");
      return(1);
   }
   if (p_window_id==_mdi) {
      p_window_id=_mdi.p_child;
   }
   int was_recording=_macro();
   _macro_delete_line();
   if (!pos(' -useglobaldata ',' 'cmdline' ',1,'i')) {
      _DiffInitGSetupData();
   }
   typeless x1='';
   typeless x2='';
   int file1inmem=1,file2inmem=1;
   _str file1disk='',file2disk='';
   _str DialogTitle='Diff';
   boolean ViewOnly=false;
   int gaugeFormWID=0;
   int gaugeWID=0;
   int diff_form_wid=0;
   int OutputBufId=0;
   boolean SomeBuf1=false;
   boolean SomeBuf2=false;
   boolean GetBufferIndex1=false;
   boolean GetBufferIndex2=false;
   boolean HaveFile2Name=false;
   boolean FileName1IsViewId=false,FileName2IsViewId=false;
   boolean UsedGlobalData=false;
   boolean SoftWrap1=false,SoftWrap2=false;
   boolean specifiedSourceDiffOnCommandLine = false;
   DIFF_DELETE_ITEM delItemList[];
   int bufferState1 = -1;
   int bufferState2 = -1;
   _str vcType = "";
   DIFF_MISC_INFO misc;
   InitMiscDiffInfo(misc,'diff');
   _str ImaginaryLineCaption=null;
   int LastLine2=0;
   int modal=0;
   _str temp='';
   _str filename1='';
   _str filename2='';
   _str name='';
   typeless status=0;
   int posMarkerId=-1;

   boolean file1trydisk=false;
   boolean file2trydisk=false;
   int NumOutputBuffers=0;
   int File2Size=0;
   if (!pos(' -useglobaldata ',' 'cmdline' ',1,'i')) {
      if (!_no_child_windows()) {
         gDiffSetupData.File1Name=_mdi.p_child.p_buf_name;
      }else{
         gDiffSetupData.File1Name=getcwd();
         _maybe_append_filesep(gDiffSetupData.File1Name);
      }
   }
   int quiet=0;
   int showalways=0;
   int ParentWIDToRegister=0;
   _str DocName1='',DocName2='';
   int diff_options=def_diff_options;
   int flags=diff_options;
   boolean got_data_from_file=false;
   boolean diff_tags=false;
   int bufwidth=0;
   int DialogWidth=MAXINT,DialogHeight=MAXINT,DialogX=MAXINT,DialogY=MAXINT;
   _str WindowState='';
   boolean restorefromini=false;
   boolean RangeSpecified1=false;
   boolean RangeSpecified2=false;
   boolean usedRegion = false;
   boolean matchMode2 = false;
   if ( NeedToPromptForArgs(cmdline,modal,restorefromini) /*arg(1)=='' || lowcase(arg(1))=='-modal'*/ ) {
      _macro('m',was_recording);

      if ( restorefromini ) {
         _DiffGetConfigInfoFromIniFile("VSDiffGeometry",DialogX,DialogY,DialogWidth,DialogHeight,WindowState,def_diff_edit_options,def_diff_options);
      }

      status=DiffSetupDialog(gDiffSetupData.File1Name,restorefromini);
      if ( status || gDiffSetupData.SetOptionsOnly ) {
         return(status);
      }
      mou_hour_glass(1);
      if (def_diff_options!=diff_options) {
         flags=def_diff_options;
      }
      if (_DiffIsDirectory(gDiffSetupData.File1Name) ||
          gDiffSetupData.DiffTags==1) {
         refresh();
         SaveDiffMapInfo(gDiffSetupData.File1Name,gDiffSetupData.File2Name,
                         gDiffSetupData.FileSpec,gDiffSetupData.ExcludeFileSpec);
         return(MFDiff2(gDiffSetupData,showNoEditorOptions,restorefromini));
      }
      bufwidth=gDiffSetupData.RecordFileWidth;
      file1trydisk=!gDiffSetupData.File1IsBuffer;
      file2trydisk=!gDiffSetupData.File2IsBuffer;

   }else{
      mou_hour_glass(1);
      _str arg1=cmdline;
      int VerifyMFDInput=0;
      _str file_list_info='';//If not blank, this information is for the "-listonly" option
      for (;;) {
         filename1=parse_file(arg1);
         if (substr(filename1,1,1)!='-' || isinteger(filename1)) break;
         _str option=lowcase(substr(filename1,2));
         //If we hit these options, we assume VC diff!
         if (option=='r1') {
            gDiffSetupData.ReadOnly1=DIFF_READONLY_SET_BY_USER;
         }else if (option=='r2') {
            gDiffSetupData.ReadOnly2=DIFF_READONLY_SET_BY_USER;
         }else if (option=='returnlastmatched') {
            return(DiffFilesMatched());
         }else if (substr(option,1,7)=='range1:') {
            RangeSpecified1=true;
            // The 8 is not a typo, it is to skip over 'range1:'
            parse option with 8 x1 ',' x2;
            gDiffSetupData.File1FirstLine=x1;
            if (x2=='') {
               gDiffSetupData.File1LastLine=-1;
            } else {
               gDiffSetupData.File1LastLine=x2;
            }
         }else if (substr(option,1,7)=='range2:') {
            RangeSpecified2=true;
            // The 8 is not a typo, it is to skip over 'range2:'
            parse option with 8 x1 ',' x2;
            gDiffSetupData.File2FirstLine=x1;
            if (x2=='') {
               gDiffSetupData.File2LastLine=-1;
            } else {
               gDiffSetupData.File2LastLine=x2;
            }
         }else if (option=='q') {
            gDiffSetupData.Quiet=1;
         }else if (option=='showalways') {
            gDiffSetupData.ShowAlways=1;
         }else if (option=='i') {
            gDiffSetupData.Interleaved=1;
         }else if (option=='modal') {
            modal=1;
         }else if (option=='b1') {
            gDiffSetupData.File1IsBuffer=1;
         }else if (option=='b2') {
            gDiffSetupData.File2IsBuffer=1;
         }else if (option=='optionflags') {
            typeless ops=parse_file(arg1);
            if (isinteger(ops)) {
               diff_options=def_diff_options=ops;
            }
         }else if (option=='recursive') {
            gDiffSetupData.Recursive=1;
         }else if (option=='loadstate') {
            _str stateFilename=parse_file(arg1);
            _DiffLoadDiffStateFile(stateFilename);
            return(0);
         }else if (option=='listonly') {
            //for arg1 format, see the DIFF_SETUP_INFO struct, fileListInfo field
            file_list_info=parse_file(arg1);//This will grab the filename
            _str pathinfo=parse_file(arg1);//grab the path info
            if (upcase(pathinfo)!='PATH1FILELIST' &&
                upcase(pathinfo)!='PATH2FILELIST') {
               _message_box(nls("Error in -listonly option\n\nUsage:-listonly <output_filename> <path1filelist|path2filelist> <differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2>"));
               return(1);
            }
            file_list_info=file_list_info' 'pathinfo;

            _str options=parse_file(arg1);//grab the options;
            if (!pos('differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2',options,1,'ri')) {
               _message_box(nls("Error in -listonly option\n\nUsage:-listonly <output_filename> <path1filelist|path2filelist> <differentfiles|vieweddifferentfiles|matchingfiles|filesnotinpath1|filesnotinpath2>"));
               return(1);
            }
            file_list_info=file_list_info' 'options;
            gDiffSetupData.FileListInfo=file_list_info;
         }else if (option=='verifymfd') {
            VerifyMFDInput=1;
         }else if (option=='registerasmfdchild') {
            ParentWIDToRegister=(typeless)parse_file(arg1);
         }else if (option=='refreshtagsclose') {
            misc.RefreshTagsOnClose=true;
            misc.TagParentIndex1=(typeless)parse_file(arg1);
            misc.TagParentIndex2=(typeless)parse_file(arg1);
            if (!isinteger(misc.TagParentIndex1) ||
                !isinteger(misc.TagParentIndex2)) {
               message('Cannot refresh tags after diff, invalid parent index');
               misc.RefreshTagsOnClose=false;
               misc.TagParentIndex1=0;
               misc.TagParentIndex2=0;
            }
         }else if (option=='nomapping') {
            gDiffSetupData.NoMap=true;
         }else if (option=='preserve1') {
            gDiffSetupData.Preserve1=true;
         }else if (option=='preserve2') {
            gDiffSetupData.Preserve2=true;
         }else if (option=='bi1') {
            GetBufferIndex1=true;
         }else if (option=='bi2') {
            GetBufferIndex2=true;
         }else if (option=='d1') {
            file1trydisk=1;
         }else if (option=='d2') {
            file2trydisk=1;
         }else if (option=='dialogtitle') {
            DialogTitle=parse_file(arg1);
         }else if (option=='file1title') {
            gDiffSetupData.File1Title=strip(parse_file(arg1),'B','"');
         }else if (option=='file2title') {
            gDiffSetupData.File2Title=strip(parse_file(arg1),'B','"');
         }else if (option=='viewonly') {
            ViewOnly=true;
         }else if (option=='comment') {
            gDiffSetupData.Comment=parse_file(arg1);
         }else if (option=='ok') {
            misc.OkPtr=(typeless)parse_file(arg1);
         }else if (option=='commentbuttoncaption') {
            gDiffSetupData.CommentButtonCaption=parse_file(arg1);
         }else if (option=='viewid1') {
            FileName1IsViewId=true;
         }else if (option=='viewid2') {
            FileName2IsViewId=true;
         }else if (option=='imaginarylinecaption') {
            ImaginaryLineCaption=strip(parse_file(arg1),'B','"');
            DiffSetImaginaryBufferLineText(ImaginaryLineCaption);
         }else if (option=='autoclose') {
            misc.AutoClose=true;
         }else if (option=='geometry') {
            _str geo=parse_file(arg1);
            _str temp_width='',temp_height='',temp_x='',temp_y='';
            parse geo with temp_width 'x','i' temp_height '+' temp_x '+' temp_y;
            if (temp_width!='') {
               DialogWidth=(int)temp_width;
               DialogWidth=_dx2lx(SM_TWIP,DialogWidth);
            }
            if (temp_height!='') {
               DialogHeight=(int)temp_height;
               DialogHeight=_dx2lx(SM_TWIP,DialogHeight);
            }
            if (temp_x!='') {
               DialogX=(int)temp_x;
               DialogX=_dx2lx(SM_TWIP,DialogX);
            }
            if (temp_y!='') {
               DialogY=(int)temp_y;
               DialogY=_dx2lx(SM_TWIP,DialogY);
            }
         }else if (option=='restorefromini') {
            _DiffGetConfigInfoFromIniFile("VSDiffGeometry",DialogX,DialogY,DialogWidth,DialogHeight,WindowState);
         }else if (option=='tags') {
            gDiffSetupData.DiffTags=true;
         }else if (option=='noeol') {
            flags|=DIFF_DONT_COMPARE_EOL_CHARS;
            def_diff_options|=DIFF_DONT_COMPARE_EOL_CHARS;
         }else if (option=='symbol1') {
            gDiffSetupData.Symbol1Name=parse_file(arg1);
         }else if (option=='symbol2') {
            gDiffSetupData.Symbol2Name=parse_file(arg1);
         }else if (option=='savebutton1caption') {
            gDiffSetupData.SaveButton1Caption=strip(parse_file(arg1),'B','"');
         }else if (option=='savebutton2caption') {
            gDiffSetupData.SaveButton2Caption=strip(parse_file(arg1),'B','"');
         }else if (option=='sourcediff') {
            gDiffSetupData.balanceBuffersFirst = true;
            if ( gDiffSetupData.ReadOnly2 == DIFF_READONLY_OFF ) {
               gDiffSetupData.ReadOnly2 = DIFF_READONLY_SOURCEDIFF;
            }
            specifiedSourceDiffOnCommandLine = true;
         }else if (option=='posmarkerid') {
            tempPosMarkerId := parse_file(arg1);
            if ( isinteger(tempPosMarkerId) ) {
               posMarkerId = (int)tempPosMarkerId;
            }
         }else if (option=='nosourcediff') {
            gDiffSetupData.noSourceDiff = true;
            gDiffSetupData.balanceBuffersFirst = false;
         }else if (option=='bufferstate1') {
            // Buffer state was specified, override whether file was in memory or not
            curBufState := parse_file(arg1);
            if ( isinteger(curBufState) ) {
               bufferState1 = (int) curBufState;
            }
         }else if (option=='bufferstate2') {
            // Buffer state was specified, override whether file was in memory or not
            curBufState := parse_file(arg1);
            if ( isinteger(curBufState) ) {
               bufferState2 = (int) curBufState;
            }
         }else if (option=='vcdiff') {
            vcType = parse_file(arg1);
         }else if (option=='matchmode2') {
            matchMode2 = true;
         }else if (option=='optionsfile') {
            _str options_filename=parse_file(arg1);
            GetOptionsFromFile(options_filename,
                               gDiffSetupData.FileSpec,
                               gDiffSetupData.ExcludeFileSpec,
                               gDiffSetupData.Recursive,
                               gDiffSetupData.File1Name,
                               gDiffSetupData.File2Name);
            got_data_from_file=true;
            delete_file(options_filename);
            break;
         }else if (option=='useglobaldata') {
            UsedGlobalData=true;
            filename1='';
            if (gDiffSetupData.Quiet) {
               quiet=1;
            }
            if (gDiffSetupData.Modal) {
               modal=1;
            }
            if (gDiffSetupData.ViewId1>0) {
               FileName1IsViewId=true;
               gDiffSetupData.File1Name=filename1=gDiffSetupData.ViewId1;
            }
            if (gDiffSetupData.ViewId2>0) {
               FileName2IsViewId=true;
               filename2=gDiffSetupData.ViewId2;
               gDiffSetupData.File2Name=filename2;
            }
            if (gDiffSetupData.ViewOnly) {
               ViewOnly=true;
            }
            if (gDiffSetupData.DialogTitle!='') {
               DialogTitle=gDiffSetupData.DialogTitle;
            }
            if (gDiffSetupData.ImaginaryLineCaption!=null) {
               ImaginaryLineCaption=gDiffSetupData.ImaginaryLineCaption;
               DiffSetImaginaryBufferLineText(ImaginaryLineCaption);
            }
            if (gDiffSetupData.AutoClose) {
               misc.AutoClose=true;
            }
            if (gDiffSetupData.File1FirstLine._varformat()==VF_INT
                && gDiffSetupData.File1LastLine._varformat()==VF_INT
                && gDiffSetupData.File2FirstLine._varformat()==VF_INT
                && gDiffSetupData.File2LastLine._varformat()==VF_INT
                ) {

               LastLine2=gDiffSetupData.File2LastLine;
            }
            if (!gDiffSetupData.File1IsBuffer &&
                !gDiffSetupData.ViewId1 &&
                gDiffSetupData.BufferIndex1<0) {
               gDiffSetupData.File1Name=absolute(gDiffSetupData.File1Name);
            }
            if (!gDiffSetupData.File2IsBuffer &&
                !gDiffSetupData.ViewId2 &&
                gDiffSetupData.BufferIndex2<0) {
               gDiffSetupData.File2Name=absolute(gDiffSetupData.File2Name);
            }
            break;
         }
      }
      if (!got_data_from_file && !UsedGlobalData) {
         gDiffSetupData.File1Name=filename1;
         if (!UsedGlobalData) {
            gDiffSetupData.File2Name=parse_file(arg1);
         }
         gDiffSetupData.File1Name=strip(gDiffSetupData.File1Name,'B','"');
         isRealFile := file_exists(gDiffSetupData.File1Name);
         // First check to see if this is a file that exists.  This will keep us
         // from accidentally trying to treat a filename with a non-star wildcard
         // character as a wildcard.
         // Ex: [139]test1.cpp is a valid filename on UNIX, but also '[' and ']'
         // are wildcar characters on UNIX
         if ( !isRealFile ) {
            _str MaybeFilespec=_strip_filename(gDiffSetupData.File1Name,'P');
            if (iswildcard(MaybeFilespec)) {
               gDiffSetupData.File1Name=_strip_filename(gDiffSetupData.File1Name,'N');
               gDiffSetupData.FileSpec=MaybeFilespec;
               gDiffSetupData.ExcludeFileSpec='';
               VerifyMFDInput=1;
            }
         }
      }
      if (GetBufferIndex1) {
         gDiffSetupData.BufferIndex1=(int)gDiffSetupData.File1Name;
      }
      if (GetBufferIndex2) {
         gDiffSetupData.BufferIndex2=(int)gDiffSetupData.File2Name;
      }
      if (gDiffSetupData.DiffStateFile!='') {
         _DiffLoadDiffStateFile(gDiffSetupData.DiffStateFile,showNoEditorOptions);
         return(0);
      }

      if (gDiffSetupData.FileSpec!='' || gDiffSetupData.Recursive || gDiffSetupData.DiffTags) {
         if (gDiffSetupData.FileSpec=='') {
            if (isdirectory(gDiffSetupData.File2Name)) {
               _maybe_append_filesep(gDiffSetupData.File2Name);
               if (gDiffSetupData.DiffTags) {
                  gDiffSetupData.File2Name=gDiffSetupData.File2Name:+_strip_filename(gDiffSetupData.File1Name,'P');
               }
            }
            if (gDiffSetupData.Recursive) {
               gDiffSetupData.FileSpec=_strip_filename(gDiffSetupData.File1Name,'P');
               gDiffSetupData.File1Name=_strip_filename(gDiffSetupData.File1Name,'N');
            }
         }
         //Multi file diff....
         //filename1,filename2 are really paths

         if (!VerifyMFDInput && !gDiffSetupData.DiffTags) {
            //9:02am 6/17/1998
            //This info should have already been verified by the dialog
            status=VerifyMultiFileDiffInput(gDiffSetupData.File1Name,gDiffSetupData.File2Name,gDiffSetupData.FileSpec,gDiffSetupData.ExcludeFileSpec);
            if (status) {
               return(DisplayMFDiffErrorMessage(status));
            }
         }
         return(MFDiff2(gDiffSetupData,showNoEditorOptions,restorefromini));
         //return(SetupAndCallMFDiff(gDiffSetupData,file_list_info));
      }else{
         //This is a hack to make comparing to files w/the same name a little
         //easier 9:26am 6/17/1996
         int ValidUNCRoot=0;
         if (isunc_root(gDiffSetupData.File2Name)) {
            temp=gDiffSetupData.File2Name;
            if (last_char(gDiffSetupData.File2Name)!=FILESEP) {
               temp=temp:+FILESEP'*';
               name=file_match(temp' +p',1);
               if (name!='') ValidUNCRoot=1;
            }
         }
         if (!FileName2IsViewId) {
            if (last_char(gDiffSetupData.File2Name)==FILESEP ||
                file_eq( file_match(gDiffSetupData.File2Name' -p +d',1),gDiffSetupData.File2Name:+FILESEP) ) {
               _maybe_append_filesep(gDiffSetupData.File2Name);
               gDiffSetupData.File2Name=gDiffSetupData.File2Name:+_strip_filename(gDiffSetupData.File1Name,'p');
            }
         }
         if (gDiffSetupData.File1Name=='.process' || gDiffSetupData.File2Name=='.process') {
            _message_box(nls("Cannot diff buffer '.process'"));
            return(1);
         }
         //We pass in modal because modal means that we have a VC diff,
         //which means that we want to include buffers with the hidden flag
         //in our search
         SomeBuf1=gDiffSetupData.File1IsBuffer || gDiffSetupData.BufferIndex1>-1;
         SomeBuf2=gDiffSetupData.File2IsBuffer || gDiffSetupData.BufferIndex2>-1;
         if ( FileName1IsViewId ) {
            gDiffSetupData.ViewId1=(int)gDiffSetupData.File1Name;
         }
         if ( FileName2IsViewId ) {
            gDiffSetupData.ViewId2=(int)gDiffSetupData.File2Name;
         }
         if (!file_exists4(gDiffSetupData.File1Name,!SomeBuf1,gDiffSetupData.BufferIndex1,DocName1,gDiffSetupData.ViewId1!=0) && !gDiffSetupData.Recursive) {
            _message_box(nls("File '%s' does not exist.",gDiffSetupData.File1Name));
            return(FILE_NOT_FOUND_RC);
         }
         if (!file_exists4(gDiffSetupData.File2Name,!SomeBuf2,gDiffSetupData.BufferIndex2,DocName2,gDiffSetupData.ViewId2!=0) && !gDiffSetupData.Recursive) {
            _message_box(nls("File '%s' does not exist.",gDiffSetupData.File2Name));
            return(FILE_NOT_FOUND_RC);
         }
      }
   }
   if (!gDiffSetupData.NoMap) {
      SaveDiffMapInfo(gDiffSetupData.File1Name,gDiffSetupData.File2Name,
                      gDiffSetupData.FileSpec,gDiffSetupData.ExcludeFileSpec);
   }
   //Be sure that filenames have double quotes if necessary
   if (!gDiffSetupData.File1IsBuffer && gDiffSetupData.BufferIndex1<0 && !FileName1IsViewId) {
      gDiffSetupData.File1Name=_diff_absolute(gDiffSetupData.File1Name);
   }
   if (!gDiffSetupData.File2IsBuffer && gDiffSetupData.BufferIndex2<0 && !FileName2IsViewId) {
      gDiffSetupData.File2Name=_diff_absolute(gDiffSetupData.File2Name);
   }

   _str name1='',name2='';
   _str maybe_url1=gDiffSetupData.File1Name;
   _str maybe_url2=gDiffSetupData.File2Name;
   boolean file1ishttp=false,file2ishttp=false;
   gDiffSetupData.File1Name=diff_get_http_filename(gDiffSetupData.File1Name,file1ishttp);
   if (file1ishttp) {
      name1=maybe_url1;
      gDiffSetupData.ReadOnly1=DIFF_READONLY_SET_BY_USER;
   }
   gDiffSetupData.File2Name=diff_get_http_filename(gDiffSetupData.File2Name,file2ishttp);
   if (file2ishttp) {
      name2=maybe_url2;
      gDiffSetupData.ReadOnly2=DIFF_READONLY_SET_BY_USER;
   }
   file1disk=DiffGetForceDiskLoadString(file1trydisk,gDiffSetupData.File1IsBuffer,gDiffSetupData.BufferIndex1);
   file2disk=DiffGetForceDiskLoadString(file2trydisk,gDiffSetupData.File2IsBuffer,gDiffSetupData.BufferIndex2);
   int orig_view_id=p_window_id;
   int ViewId1=0;
   int ViewId2=0;
   typeless buf_id=0;
   typeless otherbufinfo1='';
   typeless otherbufinfo2='';
   _str parent_option='';
   _str bufwidthstr='';
   _str lang='';
   int wid=0;
   boolean fileSizeIsOK = 1;
   boolean unicodeSourceFiles=false;
   int Wid1=0,Wid2=0;
   _str output_encoding_option='';
   if ( gDiffSetupData.Interleaved ) {
      if (gDiffSetupData.File1Name=="") {
         gDiffSetupData.File1Name = gDiffSetupData.BufferIndex1;
         file1disk = '+bi';
         file1inmem = 1;
      }
      status=GetFileHidden(gDiffSetupData.File1Name,ViewId1,orig_view_id,file1inmem,file1disk);
      if (status) {
         _message_box(nls("Could not open file '%s'.\n\n%s",gDiffSetupData.File1Name,get_message(status)));
      }
      if (gDiffSetupData.File2Name=="") {
         gDiffSetupData.File2Name = gDiffSetupData.BufferIndex2;
         file2disk = '+bi';
         file2inmem = 1;
      }
      status=GetFileHidden(gDiffSetupData.File2Name,ViewId2,orig_view_id,file2inmem,file2disk,File2Size);
      p_window_id=orig_view_id;
      if (status) {
         _message_box(nls("Could not open file '%s'.\n\n%s",gDiffSetupData.File2Name,get_message(status)));
      }
      CheckEncoding(unicodeSourceFiles,ViewId1,ViewId2,gDiffSetupData.File1Title,gDiffSetupData.File2Title,output_encoding_option,true);
      if (unicodeSourceFiles) {
         _message_box(nls("You must use the interactive dialog box to diff unicode source files"));
         _delete_temp_view(ViewId1);
         _delete_temp_view(ViewId2);
         return(1);
      }
   }else{
      parse buf_match(gDiffSetupData.File1Name,1,'xhv') with buf_id otherbufinfo1;
      if (debug_active()) {
         if (dbg_have_updated_disassembly(gDiffSetupData.File1Name)) {
            _message_box(nls("You cannot diff the file '%s' while debugging.",gDiffSetupData.File1Name));
            return(1);
         }
         if (dbg_have_updated_disassembly(gDiffSetupData.File2Name)) {
            _message_box(nls("You cannot diff the file '%s' while debugging.",gDiffSetupData.File2Name));
            return(1);
         }
      }
      if (buf_id!="" && _isdiffed(buf_id)) {
         _message_box(nls("You cannot diff the file '%s' because it is already being diffed.",gDiffSetupData.File1Name));
         return(1);//Thought about returning ACCESS_DENIED_RC
      }
      parse buf_match(gDiffSetupData.File2Name,1,'xhv') with buf_id otherbufinfo2;
      if (buf_id!="" && _isdiffed(buf_id)) {
         _message_box(nls("You cannot diff the file '%s' because it is already being diffed.",gDiffSetupData.File2Name));
         return(1);
      }

      DiffSetupDocumentNames(gDiffSetupData.BufferIndex1,gDiffSetupData.ViewId1,
                             name1,DocName1,otherbufinfo1,file1disk,gDiffSetupData.File1Title,gDiffSetupData.File1Name);
      DiffSetupDocumentNames(gDiffSetupData.BufferIndex2,gDiffSetupData.ViewId2,
                             name2,DocName2,otherbufinfo2,file2disk,gDiffSetupData.File2Title,gDiffSetupData.File2Name);
      diff_form_wid = show('-desktop -xy -span -hidden -new _diff_form',name1,name2,'diff');
      if ( diff_form_wid ) {
         _SetDialogInfo(DIFFEDIT_READONLY1_VALUE,gDiffSetupData.ReadOnly1,diff_form_wid._ctlfile1);
         _SetDialogInfo(DIFFEDIT_READONLY2_VALUE,gDiffSetupData.ReadOnly2,diff_form_wid._ctlfile1);
      }

      mou_hour_glass(1);
      if (gDiffSetupData.File1LastLine>0 || gDiffSetupData.Symbol1Name!='' ) {
         status=_DiffLoadFileAndGetRegionView2(gDiffSetupData.File1Name,
                                               gDiffSetupData.BufferIndex1,
                                               gDiffSetupData.ViewId1,
                                               gDiffSetupData.File1FirstLine,
                                               gDiffSetupData.File1LastLine,
                                               file1trydisk,
                                               gDiffSetupData.BufferIndex1,
                                               misc.WholeFileBufId1,
                                               misc.MarkId1,
                                               auto parent1InMem,
                                               misc.SymbolViewId1,
                                               misc.File1Date,
                                               gDiffSetupData.Symbol1Name,
                                               &delItemList);
         if (status) {
            mou_hour_glass(0);
            return(status);
         }
         if (gDiffSetupData.File1Title=='') {
            gDiffSetupData.File1Title=gDiffSetupData.File1Name;
         }
         gDiffSetupData.File1Name='';
         file1inmem = parent1InMem;
         usedRegion = true;
      }

      if (gDiffSetupData.File2LastLine>0  || gDiffSetupData.Symbol2Name!='' ) {
         status=_DiffLoadFileAndGetRegionView2(gDiffSetupData.File2Name,
                                               gDiffSetupData.BufferIndex2,
                                               gDiffSetupData.ViewId2,
                                               gDiffSetupData.File2FirstLine,
                                               gDiffSetupData.File2LastLine,
                                               file2trydisk,
                                               gDiffSetupData.BufferIndex2,
                                               misc.WholeFileBufId2,
                                               misc.MarkId2,
                                               auto parent2InMem,
                                               misc.SymbolViewId2,
                                               misc.File1Date,
                                               gDiffSetupData.Symbol2Name,
                                               &delItemList);
         if (status) {
            mou_hour_glass(0);
            return(status);
         }
         if (gDiffSetupData.File2Title=='') {
            gDiffSetupData.File2Title=gDiffSetupData.File2Name;
         }
         gDiffSetupData.File2Name='';
         file2inmem = parent2InMem;
         usedRegion = true;
      }else{
         if (_DiffIsDirectory(gDiffSetupData.File2Name)) {
            _maybe_append_filesep(gDiffSetupData.File2Name);
            gDiffSetupData.File2Name=gDiffSetupData.File2Name:+_strip_filename(gDiffSetupData.File1Name,'p');
         }
      }
      mou_hour_glass(0);
      diff_options=def_diff_options;
      flags=diff_options;

      if (def_keys=='') {//SlickEdit emulation
         _nocheck _control _ctlundo;
         diff_form_wid._ctlundo.p_caption='Undo';
      }
      _nocheck _control _ctlfile1save;
      _nocheck _control _ctlfile2save;
      if (gDiffSetupData.SaveButton1Caption!='') {
         diff_form_wid._ctlfile1save.SetSaveButtonCaption(gDiffSetupData.SaveButton1Caption);
      }
      if (gDiffSetupData.SaveButton2Caption!='') {
         diff_form_wid._ctlfile2save.SetSaveButtonCaption(gDiffSetupData.SaveButton2Caption);
      }
      diff_form_wid.setupOKButton(gDiffSetupData.Comment,gDiffSetupData.CommentButtonCaption,misc.OkPtr);
      Wid1=diff_form_wid._ctlfile1;
      Wid2=diff_form_wid._ctlfile2;
      _nocheck _control ctlconflictindicator;
      diff_form_wid.ctlconflictindicator.p_visible=0;
      _nocheck _control _ctlcopy_right;

      misc.DiffParentWID=ParentWIDToRegister;
      diff_form_wid.p_caption=strip(DialogTitle,'B','"');

      if ( misc.SymbolViewId1!=0 ) {
         diff_form_wid.diffAddToDeleteList(misc.SymbolViewId1,true,&delItemList);
      }
      if ( misc.SymbolViewId2!=0 ) {
         diff_form_wid.diffAddToDeleteList(misc.SymbolViewId2,true,&delItemList);
      }

      misc.PreserveInfo=gDiffSetupData.Preserve1' 'gDiffSetupData.Preserve2;
      Wid1._delete_buffer();
      status=1;
      bufwidthstr=bufwidth?'+'bufwidth:'';

      status=DiffLoadBuffer(bufwidth,
                            file1disk,
                            gDiffSetupData.File1Name,
                            gDiffSetupData.BufferIndex1,
                            gDiffSetupData.ViewId1,
                            Wid1,
                            name1,
                            file1ishttp,
                            maybe_url1,
                            file1inmem,
                            SoftWrap1,
                            gDiffSetupData.File1FirstLine!=0 && gDiffSetupData.File1LastLine);
      diff_form_wid.vscroll1._ScrollMarkupSetAssociatedEditor(diff_form_wid._ctlfile1);

      if (status) {
         _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
         diff_form_wid._delete_window();
         return(status);
      }
      /*
      3:33pm 7/31/1998
      Nasty little problem here:  If we are diffing a file and a buffer, we
      will be doing a load_files +b on this same name later, so to be sure
      that we don't get this buffer by accident, we will append a filesep to
      the buffer name so that it doesn't get loaded by accident
      */
      Wid1.p_buf_name=Wid1.p_buf_name:+FILESEP;

      Wid1.top();Wid1.up();
      if (file1inmem){
         Wid1.clearLineFlags();
      }
      if (gDiffSetupData.Preserve1) {
         file1inmem=1;
      }
      if ( bufferState1>-1 ) {
         // Buffer state was specified, override whether file was in memory or not
         file1inmem = bufferState1;
      }
      if ( bufferState2>-1 ) {
         // Buffer state was specified, override whether file was in memory or not
         file2inmem = bufferState2;
      }
      diff_form_wid.DiffSetupWindows(Wid1,diff_form_wid._ctlfile1_readonly,file1inmem,
                                     gDiffSetupData.ReadOnly1);
      if ( !file1inmem ) {
         diff_form_wid.diffAddToDeleteList(diff_form_wid._ctlfile1.p_buf_id,false,&delItemList);
      }
      if (ViewOnly) {
         diff_form_wid.DiffSetupDialogForViewing();
      }
      lang=_DiffFilename2LangId(gDiffSetupData.File1Name);
      if (lang!='' && !file1inmem && gDiffSetupData.BufferIndex1<0 && !gDiffSetupData.ViewId1 && !gDiffSetupData.File1IsBuffer) {
         Wid1._SetEditorLanguage(lang);
      }
      diff_form_wid._ctlfile1.p_SoftWrap=0;
      if (status) {
         _message_box(nls("Could not open file '%s'.\n\n%s",gDiffSetupData.File1Name,get_message(status)));
         return(status);
      }
      ViewId1=Wid1.p_window_id;
      Wid2._delete_buffer();

      status=DiffLoadBuffer(bufwidth,
                            file2disk,
                            gDiffSetupData.File2Name,
                            gDiffSetupData.BufferIndex2,
                            gDiffSetupData.ViewId2,
                            Wid2,
                            name2,
                            file2ishttp,
                            maybe_url2,
                            file2inmem,
                            SoftWrap2,
                            gDiffSetupData.File2FirstLine!=0 && gDiffSetupData.File2LastLine);
      if ( !file2inmem ) {
         diff_form_wid.diffAddToDeleteList(diff_form_wid._ctlfile2.p_buf_id,false,&delItemList);
      }
      if (status) {
         _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
         diff_form_wid._delete_window();
         return(status);
      }
      _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,diff_form_wid._ctlfile1);
      if ( gDiffSetupData.balanceBuffersFirst ) {
         status = MaybePromptAboutSourceDiff(specifiedSourceDiffOnCommandLine, gDiffSetupData.balanceBuffersFirst, fileSizeIsOK, Wid1, Wid2);
         if ( status==COMMAND_CANCELLED_RC ) {
            _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
            if (last_char(diff_form_wid._ctlfile1.p_buf_name)==FILESEP) {
               diff_form_wid._ctlfile1.p_buf_name=substr(diff_form_wid._ctlfile1.p_buf_name,1,length(diff_form_wid._ctlfile1.p_buf_name)-1);
            }
            diff_form_wid._delete_window(0);
            if (gaugeFormWID) {
               gaugeFormWID._delete_window();
            }
            return(COMMAND_CANCELLED_RC);
         }
      }

      if ( gDiffSetupData.balanceBuffersFirst ) {
         orig_bufid    := Wid2.p_buf_id;
         int tempwid=p_window_id;
         p_window_id=Wid2;

         markid := _alloc_selection();
         top();
         _select_line(markid);

         bottom();
         _select_line(markid);
         p_window_id = HIDDEN_WINDOW_ID;
         _safe_hidden_window();
         encodingOption := _EncodingToOption(Wid1.p_encoding);
         origWID := _create_temp_view(auto copyWID);
         newLineOption := getNewLineOption(Wid1.p_newline);
         load_files(encodingOption:+' ':+newLineOption:+' +t');
         p_DocumentName = name2;
         newBufId := p_buf_id;
         _delete_line();
         _copy_to_cursor(markid);
         _free_selection(markid);
         p_undo_steps = Wid1.p_undo_steps;
         p_buf_flags = VSBUFFLAG_HIDDEN;
         p_modify    = 0;
         p_window_id=Wid2;
         load_files("+bi ":+newBufId);
         gDiffSetupData.BufferIndex2 = newBufId;
         p_buf_name     = "";
         origFile2InMem := file2inmem;
         file2inmem = 0;

         p_window_id=tempwid;

         diff_form_wid.diffAddToDeleteList(copyWID,true,&delItemList);

         if ( !origFile2InMem && !RangeSpecified2 && gDiffSetupData.Symbol2Name=="" ) {
            diff_form_wid.diffAddToDeleteList(orig_bufid,false,&delItemList);
         }
      }
      if ( gDiffSetupData.balanceBuffersFirst ) {
         _SetDialogInfo(DIFFEDIT_CODE_DIFF,1,diff_form_wid._ctlfile1);
      }
      _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,diff_form_wid._ctlfile1);
      _SetDialogInfo(DIFFEDIT_VC_DIFF_TYPE,vcType,diff_form_wid._ctlfile1);
      status=diff_form_wid.CheckEncoding(unicodeSourceFiles,
                                         diff_form_wid._ctlfile1.p_window_id,
                                         diff_form_wid._ctlfile2.p_window_id,
                                         gDiffSetupData.File1Title,
                                         gDiffSetupData.File2Title
                                         );
      misc=_GetDialogInfo(DIFFEDIT_CONST_MISC_INFO,diff_form_wid._ctlfile1);
      if (status) {
         // Get rid of the trailing FILESEP that we put on.
         if (last_char(Wid1.p_buf_name)==FILESEP) {
            Wid1.p_buf_name=substr(Wid1.p_buf_name,1,length(Wid1.p_buf_name)-1);
         }
         _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
         diff_form_wid._delete_window(status);
         return(status);
      }
      /*
      3:38pm 7/31/1998
      Now that we have both buffers loaded, we can get rid of the filesep...
      (see note above)
      */
      Wid1.p_buf_name=substr(Wid1.p_buf_name,1,length(Wid1.p_buf_name)-1);
      wid=p_window_id;
      p_window_id=diff_form_wid;
      p_window_id=wid;
      Wid2.top();Wid2.up();
      if (file2inmem) {
         Wid2.clearLineFlags();
      }
      if (gDiffSetupData.Preserve2) {
         file2inmem=1;
      }
      diff_form_wid.DiffSetupWindows(Wid2,diff_form_wid._ctlfile2_readonly,file2inmem,
                                     gDiffSetupData.ReadOnly2);
      if ( !file2inmem ) {
         diff_form_wid.diffAddToDeleteList(diff_form_wid._ctlfile2.p_buf_id,false,&delItemList);
      }

      if ( gDiffSetupData.balanceBuffersFirst ) {
         Wid2._SetEditorLanguage(Wid1.p_LangId);
      }else{
         lang = _DiffFilename2LangId(gDiffSetupData.File2Name,gDiffSetupData.BufferIndex2);
         if (lang!='' && !file2inmem && misc.WholeFileBufId2<0) {
            Wid2._SetEditorLanguage(lang);
         }
      }
      diff_form_wid._ctlfile2.p_SoftWrap=0;
      if (status) {
         _message_box(nls("Could not open file '%s'.\n\n%s",gDiffSetupData.File2Name,get_message(status)));
         return(status);
      }
      File2Size=Wid2.p_Noflines;
      ViewId2=Wid2.p_window_id;
      {
         int orig_view_id2=p_window_id;
         p_window_id=ViewId2;
         p_window_id=orig_view_id2;
      }
      _nocheck _control _ctlcopy_right_line;
      _nocheck _control _ctlcopy_right_all;
      misc.Buf1StartTime=_file_date(Wid1.p_buf_name,'B');
      misc.Buf2StartTime=_file_date(Wid2.p_buf_name,'B');
      _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,diff_form_wid._ctlfile1);
   }
   mou_hour_glass(1);
   if (def_diff_edit_options & DIFFEDIT_SHOW_GAUGE) {
      gaugeFormWID=show('-mdi _difftree_progress_form');
      setupProgressForFileDiff(gaugeFormWID,gaugeWID);
   }else{
      gaugeWID=0;
   }
   boolean AllCommentOverride=false;

   if (!(flags&DIFF_DONT_COMPARE_EOL_CHARS)) {
      status=CheckForDifferentEOLChars(ViewId1,ViewId2,misc,flags);
      if (!gDiffSetupData.Interleaved) {
         _control _ctlcopy_right;
         _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,diff_form_wid._ctlfile1);
      }
      if (status==COMMAND_CANCELLED_RC) {
         p_window_id=orig_view_id;
         //_delete_temp_view(ViewId1);
         //_delete_temp_view(ViewId2);

         if (!gDiffSetupData.Interleaved) {
            _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
            diff_form_wid._delete_window();
         }

         gaugeFormWID._delete_window();
         return(COMMAND_CANCELLED_RC);
      }
   }

   int ff=1;
   _str str1='';
   _str str2='';
   _str bufname='';
   typeless StartLine1=0;
   typeless StartLine2=0;
   typeless junk;
   boolean balancedFiles = false;
   boolean diffFailed = false;

   if (gDiffSetupData.Interleaved) {
      ff=1;NumOutputBuffers=0;
      for (;;) {
         ++NumOutputBuffers;
         str1=file1trydisk?'(File)':'(Buffer)';
         str2=file2trydisk?'(File)':'(Buffer)';
         bufname=buf_match('Diff:'gDiffSetupData.File1Name:+str1'|'gDiffSetupData.File2Name:+str2,ff);
         if (bufname=='') break;
         ff=0;
      }
      StartLine1=StartLine2=0;
      int NCSStatus1=0,NCSStatus2=0;
      if (diff_options&DIFF_LEADING_SKIP_COMMENTS) {
         NCSStatus1=_GetNonCommentSeek(ViewId1,junk,StartLine1);
         NCSStatus2=_GetNonCommentSeek(ViewId2,junk,StartLine2);
         //If we get STRING_NOT_FOUND_RC for both of these, the files are all
         //comment
         if (NCSStatus1==STRING_NOT_FOUND_RC &&
             NCSStatus2==STRING_NOT_FOUND_RC) {
            AllCommentOverride=true;
         }
      }
      //For interleaved output, we still have to generate the buffer even
      //if AllCommentOverrideis true.  The user will still get the files match
      //message though.
      Diff(ViewId1,ViewId2,
           flags|DIFF_OUTPUT_INTERLEAVED,
           NumOutputBuffers,(int)file1trydisk,
           (int)file2trydisk,def_load_options,gaugeWID,
           OutputBufId,//This is pass by reference
           def_max_fast_diff_size,
           StartLine1?StartLine1:1,
           StartLine2?StartLine2:1,
           def_smart_diff_limit,
           ImaginaryLineCaption);
   }else{
      Wid1._diff_show_all();
      Wid2._diff_show_all();
      Wid1._diff_remove_nosave_lines();
      Wid2._diff_remove_nosave_lines();
      StartLine1=StartLine2=1;
      int NCSStatus1=0,NCSStatus2=0;
      if (diff_options&DIFF_LEADING_SKIP_COMMENTS) {
         NCSStatus1=_GetNonCommentSeek(ViewId1,junk,StartLine1);
         NCSStatus2=_GetNonCommentSeek(ViewId2,junk,StartLine2);
         //If we get STRING_NOT_FOUND_RC for both of these, the files are all
         //comment
         if (NCSStatus1==STRING_NOT_FOUND_RC &&
             NCSStatus2==STRING_NOT_FOUND_RC) {
            AllCommentOverride=true;
         }
      }
      if (!AllCommentOverride) {
         if (!(gDiffSetupData.BufferIndex1>-1 && misc.WholeFileBufId1>=0)) {
            LineInfo1=StartLine1;
         }
         if (!(gDiffSetupData.BufferIndex1>-1 && misc.WholeFileBufId2>=0)) {
            LineInfo2=StartLine2;
         }
         boolean calledBalanceFiles = false;
         if ( gDiffSetupData.balanceBuffersFirst && fileSizeIsOK ) {
            status = _DiffBalanceFiles(ViewId1,ViewId2,balancedFiles,gaugeWID);
            if ( status==COMMAND_CANCELLED_RC ) {
               // User has cancelled
               // Check for that specifically because it could return 
               // CLEX_NO_INFO_FOR_FILE_RC, and we just continue
               if ( gaugeFormWID ) {
                  gaugeFormWID._delete_window();
               }
               if ( diff_form_wid ) {
                  ctlfile1WID := diff_form_wid._find_control("_ctlfile1");
                  _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
                  diff_form_wid._delete_window();
               }
               return status;
            }
            ViewId2.clearLineFlags();
            calledBalanceFiles = true;
         }
         diff_form_wid.setupCodeToggleButton(gDiffSetupData.balanceBuffersFirst,status);
         status = Diff(ViewId1,
                       ViewId2,
                       flags,//Ignore leading spaces, all spaces, etc.
                       0,//N/A (Interleaved output)
                       (int)calledBalanceFiles,
                       0,//N/A (Interleaved output)
                       def_load_options,//Interleaved output
                       gaugeWID,
                       OutputBufId,//This is pass by reference
                       def_max_fast_diff_size,
                       LineInfo1,
                       LineInfo2,
                       def_smart_diff_limit,
                       ImaginaryLineCaption);
         if ( status ) {
            diffFailed = status;
         }
         _control _ctlcopy_right;
         misc.SoftWrap1=SoftWrap1;
         misc.SoftWrap2=SoftWrap2;

         _SetDialogInfo(DIFFEDIT_CONST_MISC_INFO,misc,diff_form_wid._ctlfile1);
      }
      if (gaugeFormWID) {
         gaugeFormWID._delete_window();
      }
   }
   //Cleanup if interleaved output
   _str lang1='';
   _str lang2='';
   if (gDiffSetupData.Interleaved) {
      if (file1inmem || (gDiffSetupData.File1Name==gDiffSetupData.File2Name && file1disk=='')) {
         p_window_id=ViewId1;
         p_buf_flags&=~VSBUFFLAG_HIDDEN;
         _delete_window();
      }else{
         _delete_temp_view(ViewId1);
      }
      if (file2inmem || (gDiffSetupData.File1Name==gDiffSetupData.File2Name && file2disk=='')) {
         p_window_id=ViewId2;
         p_buf_flags&=~VSBUFFLAG_HIDDEN;
         _delete_window();
      }else{
         _delete_temp_view(ViewId2);
      }
      //status=edit('+b Diff:'_diff_absolute(filename1):+str1'|'_diff_absolute(filename2):+str2':'NumOutputBuffers);
      status=edit('+bi 'OutputBufId);
      if (status) {
         mou_hour_glass(0);
         return(status);
      }
      lang1=_DiffFilename2LangId(gDiffSetupData.File1Name);
      lang2=_DiffFilename2LangId(gDiffSetupData.File2Name);
      if (lang1!='') {
         _SetEditorLanguage(lang1);
      }else{
         if (lang2!='') {
            _SetEditorLanguage(lang2);
         }
      }
      //read_only_mode();
      p_color_flags|=MODIFY_COLOR_FLAG;
      top();
      if (gaugeFormWID) {
         gaugeFormWID._delete_window();
      }
      _str diffDocName = "Diff<":+_strip_filename(gDiffSetupData.File1Name,"P"):+">";
      docname(diffDocName);
      p_modify=false;
   }
   mou_hour_glass(0);
   _mdi.p_child._set_focus();
   if (!gDiffSetupData.Interleaved) {
      Wid1._DiffSetWindowFlags();
      Wid2._DiffSetWindowFlags();
      if (def_diff_edit_options&DIFFEDIT_START_AT_TOP) {
         Wid1.top();Wid2.top();
      }else if (def_diff_edit_options&DIFFEDIT_START_AT_FIRST_DIFF) {
         Wid1.top();Wid1.up();Wid2.top();Wid2.up();
         _control _ctlnext_difference;
         diff_form_wid._ctlnext_difference.call_event(true,diff_form_wid._ctlnext_difference,LBUTTON_UP,'W');
         //Wid1.diff_next_difference();
      }
      int p1=1;
      //if (_default_option('T')) p1=1;

      int WindowHeightInLines=Wid1.p_char_height;

      int fontIndex=CFG_DIFF_EDITOR_WINDOW;
      if ( unicodeSourceFiles ) {
         fontIndex=CFG_UNICODE_SOURCE_WINDOW;
      }
      diff_form_wid.DiffSetDialogFont(fontIndex);
      diff_form_wid._DiffSetupScrollBars();

      if (AllCommentOverride) {
         diff_form_wid.EvenComments();
      }
      Wid1._BlastUndoInfo();
      Wid2._BlastUndoInfo();
      //diff_form_wid.UpdateForm();
      Wid1._set_focus();

      // Setting p_readonly_mode to 2 sets read-only mode but does
      // not DEQ the data set.
      typeless t=2;
      Wid1.p_readonly_mode=t;
      Wid2.p_readonly_mode=t;
   }
   if (gDiffSetupData.CompareOnly) {
      _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
      diff_form_wid._delete_window(0);
      return(0);
   }
   if (DiffFilesMatched() || AllCommentOverride) {
      //messageNwait(nls('DiffFilesMatched()=%s StartLine1=%s StartLine2=%s',DiffFilesMatched(),StartLine1,StartLine2));
      if (gDiffSetupData.Interleaved) {
         if (StartLine1||StartLine2) {
            if ( !quiet ) {
               _message_box(nls("Files match (except for leading comments)"));
            }
         }else{
            if ( !quiet ) {
               _message_box(nls("Files match"));
            }
         }
      }else{
         if (quiet) {
            _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
            diff_form_wid._delete_window(0);
            return(0);
         }
         diff_form_wid._DiffSetFilesMatch('Files match');
         if (!showalways) {
            int result=0;
            if (!gDiffSetupData.Quiet) {
               if (StartLine1!=1||StartLine2!=1) {
                  result=_message_box(nls("Files match (except for leading comments), view them anyway?"),'',MB_YESNOCANCEL|MB_ICONQUESTION);
               }else{
                  msg := nls("Files match, view them anyway?");
                  if ( balancedFiles ) {
                     msg = nls("No significant changes in files, view them anyway?");
                  }
                  result=_message_box(msg,'',MB_YESNO|MB_ICONQUESTION);
               }
            }
            if (result==IDNO) {
               _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
               diff_form_wid._delete_window(0);
               return(COMMAND_CANCELLED_RC);
            }
         }
      }
   } else {
      filesMatch := false;
   }
   _macro('m',was_recording);
   _macro_append(nls("diff('%s %s');",gDiffSetupData.File1Name,gDiffSetupData.File2Name));
   if ( diff_form_wid ) {
      _nocheck _control _ctlhelp;


      if ( !gDiffSetupData.Interleaved ) {
         diff_form_wid._DiffSetupHorizontalScrollBar();
         if ( DialogX!=MAXINT ) {
            diff_form_wid.p_x=DialogX;
         }
         if ( DialogY!=MAXINT ) {
            diff_form_wid.p_y=DialogY;
         }
         if ( DialogWidth!=MAXINT ) {
            diff_form_wid.p_width=DialogWidth;
         }
         if ( DialogHeight!=MAXINT ) {
            diff_form_wid.p_height=DialogHeight;
         }
         if ( WindowState!='' ) {
            diff_form_wid.p_window_state=WindowState;
         }
         if ( usedRegion || gDiffSetupData.noSourceDiff ) {
            diff_form_wid.ctltypetoggle.p_visible = diff_form_wid.ctltypetoggle.p_enabled =0;
         }
         if ( matchMode2 ) {
            diff_form_wid._ctlfile2.select_mode(diff_form_wid._ctlfile1.p_mode_name);
         }
         if ( !diffFailed ) diff_form_wid.p_visible=1;
         diff_form_wid.call_event(diff_form_wid,ON_GOT_FOCUS);
         _SetDialogInfoHt("DeleteList",delItemList,diff_form_wid._ctlfile1);
         if ( posMarkerId>-1 ) {
            diff_form_wid.gotoPosMarker(posMarkerId);
         }
         if ( modal && !diffFailed ) {
            //VCdiff
            status=_modal_wait(diff_form_wid);
         }
      }
      if ( diffFailed ) {
         diff_form_wid._delete_window();
      }
   }
   return(0);
}

/** 
 * Call the diff modally.  <B>Use this when calling the diff 
 * programatically so that source diff and line diff can be 
 * toggle</B>
 * 
 * @param commandLine same as commandline for <b>diff</b>, but 
 *                    do not include <i>-modal</i>
 * @param vcdiffType name of version control system etc.
 * 
 * @return int 0 if sucessful (return code from <b>diff</b>. 
 *         Noted that success means nothing about whether or not
 *         the files match.
 */
int _DiffModal(_str commandLine, _str vcdiffType="toggle")
{
   int status = 0;
   commandLine = stranslate(commandLine,"","-modal",'i');
   _str sourceDiffOption = "";
   if ( pos("-sourcediff",commandLine,1,'i') ) {
      sourceDiffOption = "-sourcediff";
      commandLine = stranslate(commandLine,"","-sourcediff",'i');
   }
   for ( ;; ) {
      _str diff_cmdline='-modal -vcdiff 'vcdiffType' 'sourceDiffOption' 'commandLine;
      // If user chooses source diff or line diff, the next 'type' will be returned 
      // in _param1, so first intialize it here
      _param1 = "";
      status = diff(diff_cmdline);
      if ( _param1=="" ) break;
      if ( _param1=="code" ) {
         sourceDiffOption = "-sourcediff";
      }else{
         sourceDiffOption = "";
      }
   }
   return status;
}

/**
 * Compare the current buffer against another file. 
 * <p> 
 * Command line usage:
 * <pre>
 *    diff-with &lt;dir or file name&gt;
 * </pre> 
 * <p> 
 * The directory name can be just a directory root, and 
 * diff-with will splice together the entire matching file 
 * path for you.  For example, if the current file is 
 * <code>"E:\13.0.2\unittest\cparse\testcparse.cpp"</code>, 
 * you can compare it to 
 * <code>"E:\14.0.0\unittest\cparse\testcparse.cpp"</code> 
 * simply using the command: 
 * <pre> 
 *     diff-with e:\14.0.0
 * </pre>
 * 
 * @return 0 if successful, Otherwise a nonzero error code.
 *         <p>
 *         Note that "successful" implies nothing about the 
 *         number of differences between the files, just that
 *         all files were loaded successfully,
 *         and the difference engine ran succesfully.
 * 
 * @param dirname    file or directory name to compare against
 * 
 * @see diff
 * @categories Buffer_Functions, File_Functions
 */
_command int diff_with(_str dirname='') name_info(FILE_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   _str args='';
   for (;;) {
      last_dirname := dirname;
      filename1 := parse_file(dirname);
      if (substr(filename1,1,1) != '-') {
         dirname = last_dirname;
         break;
      }
      args = args' 'filename1;
   }

   // Try to piece together full path to diff with based on the
   // root diretory name passed in.
   // Example:
   filedir  := _strip_filename(p_buf_name, 'n');
   filename := _strip_filename(p_buf_name, 'p');
   if (dirname!='' && (!file_exists(dirname) || isdirectory(dirname)) ) {
      candidate := absolute(filename, dirname);
      while (!file_exists(candidate) && pos(FILESEP, filedir) >= 1) {
         filedir  = strip(filedir, 'T', FILESEP);
         dirpart := _strip_filename(filedir, 'p');
         filedir  = _strip_filename(filedir, 'n');
         _maybe_append_filesep(dirpart);
         dirpart :+= filename;
         filename = dirpart;
         candidate = absolute(filename, dirname);
      }
      if (file_exists(candidate)) {
         dirname = candidate;
      }
   }

   if (dirname=='') {
      dirname = _ChooseDirDialog("Choose path to diff \"":+filename:+"\" with", "", filename);
   }

   return _DiffModal(args" -B1 "maybe_quote_filename(p_buf_name)" "maybe_quote_filename(dirname));
}

/**
 * Compare the current file, assuming it is modified, against
 * the original version on disk. 
 * 
 * @return 0 if successful, Otherwise a nonzero error code.
 *         <p>
 *         Note that "successful" implies nothing about the 
 *         number of differences between the files, just that
 *         all files were loaded successfully,
 *         and the difference engine ran succesfully.
 * 
 * @param diffargs    Arguments to pass along to the diff command
 * 
 * @see diff 
 * @see diff_with 
 *  
 * @categories Buffer_Functions, File_Functions
 */
_command int diff_current_file(_str diffargs="") name_info(FILE_ARG','VSARG2_EDITORCTL|VSARG2_READ_ONLY)
{
   editorWid := p_window_id;
   if (!_isEditorCtl()) {
      if (_no_child_windows()) {
         return 0;
      }
      editorWid = _mdi.p_child;
   }

   if (!editorWid.p_modify) {
      message("File is not modified.");
      return 0;
   }
   
   return _DiffModal(diffargs" -bi1 -d2 "editorWid.p_buf_id" "maybe_quote_filename(editorWid.p_buf_name));
}
int _OnUpdate_diff_current_file(CMDUI &cmdui,int target_wid,_str command)
{
   if (_no_child_windows()) {
      return MF_GRAYED;
   }
   if (!target_wid.p_modify) {
      return MF_GRAYED|MF_ENABLED;
   }
   return MF_ENABLED;
}

static void SetSaveButtonCaption(_str caption)
{
   p_caption=caption;
   p_width=max(p_width,_text_width(caption)+200);
}

static void DiffSetupDocumentNames(int BufferIndex,int ViewId,_str &name,
                                   _str DocName,
                                   _str otherbufinfo,_str filediskstr,
                                   _str Title,_str Filename)
{
   typeless status=0;
   if (BufferIndex>-1 || ViewId) {
      name=DocName;
      _str opt='';
      if (BufferIndex) {
         opt='+bi';
      }
      if (Title=='') {
         name=DocName;
         if (DocName=='') {
            int orig_view_id=p_window_id;
            p_window_id=VSWID_HIDDEN;
            _safe_hidden_window();
            bufIDLoaded := -1;
            if (ViewId) {
               status=load_files('+bi 'ViewId.p_buf_id);
               bufIDLoaded = ViewId.p_buf_id;
            }else if (BufferIndex) {
               status=load_files('+bi 'BufferIndex);
               bufIDLoaded = BufferIndex;
            }else{
               status=load_files(opt' 'Filename);
            }
            name=p_DocumentName;
            if (name=='') {
               name=p_buf_name;
            }
            if ( name=="" ) {
               name = "Untitled Buffer <":+bufIDLoaded:+'>';
            }
            p_window_id=orig_view_id;
         }
      }else{
         name=Title;
      }
      if ((otherbufinfo=='' || filediskstr!='') && !ViewId) {
         name=name'(File)';
      }else{
         name=name'(Buffer)';
      }
   }else if (name=='') {
      name=Filename;
      name=strip(name,'B','"');
      if (otherbufinfo==''||filediskstr!='') {
         name=name'(File)';
      }else{
         name=name'(Buffer)';
      }
      if (Title!='') {
         name=Title;
      }
   }
}

static void DiffSetupDialogForViewing()
{
   _nocheck _control _ctlcopy_right_line;
   _nocheck _control _ctlcopy_right_all;
   _nocheck _control _ctlfile1save;
   _nocheck _control _ctlcopy_left;
   _nocheck _control _ctlcopy_left_line;
   _nocheck _control _ctlcopy_left_all;
   _nocheck _control _ctlfile2_readonly;
   _nocheck _control _ctlfile2save;
   _ctlcopy_right.p_visible=0;
   _ctlcopy_right_line.p_visible=0;
   _ctlcopy_right_all.p_visible=0;
   _ctlfile1_readonly.p_visible=0;
   _ctlfile1save.p_visible=0;

   _ctlcopy_left.p_visible=0;
   _ctlcopy_left_line.p_visible=0;
   _ctlcopy_left_all.p_visible=0;
   _ctlfile2_readonly.p_visible=0;
   _ctlfile2save.p_visible=0;
   _ctlfile1_readonly.p_value=1;
   _ctlfile2_readonly.p_value=1;
   call_event('F',p_window_id,ON_RESIZE,'W');
}

static void DiffSetupWindows(int editorctl_wid,int readonly_wid,int inmem,
                             DIFF_READONLY_TYPE ReadOnly
                             )
{
   int id=editorctl_wid.p_name=='_ctlfile1'?DIFFEDIT_CONST_BUFFER_INFO1:DIFFEDIT_CONST_BUFFER_INFO2;
   _SetDialogInfo(id,editorctl_wid.p_buf_id' 'inmem' 'editorctl_wid.p_readonly_mode,_ctlfile1);
   readonly_wid.p_value=(int)(editorctl_wid.p_readonly_mode||ReadOnly!=DIFF_READONLY_OFF);
   editorctl_wid.p_ProtectReadOnlyMode=(readonly_wid.p_value)?VSPROTECTREADONLYMODE_ALWAYS:VSPROTECTREADONLYMODE_NEVER;
   readonly_wid.p_enabled=!readonly_wid.p_value;
}

void _DiffSetWindowFlags()
{
   p_window_flags|=(OVERRIDE_CURLINE_RECT_WFLAG|CURLINE_RECT_WFLAG|OVERRIDE_CURLINE_COLOR_WFLAG);
   p_window_flags&=~(CURLINE_COLOR_WFLAG);
   p_window_flags|=VSWFLAG_NOLCREADWRITE;

   p_buser=p_color_flags;
   p_color_flags|=MODIFY_COLOR_FLAG;
}

static int MFDiff2(DIFF_SETUP_DATA &DiffSetupData,boolean showNoEditorOptions,boolean restorefromini)
{
   DIFF_SETUP_INFO MFDiffSetup;
   InitDiffSetupStruct(&MFDiffSetup);

   MFDiffSetup.path1=DiffSetupData.File1Name;
   MFDiffSetup.path2=DiffSetupData.File2Name;
   MFDiffSetup.filespec=DiffSetupData.FileSpec;
   MFDiffSetup.excludeFilespec=DiffSetupData.ExcludeFileSpec;
   MFDiffSetup.recursive=DiffSetupData.Recursive;
   MFDiffSetup.compareAllSymbols=DiffSetupData.DiffTags;
   MFDiffSetup.fileListInfo=DiffSetupData.FileListInfo;
   MFDiffSetup.compareAllSymbols=DiffSetupData.DiffTags;
   MFDiffSetup.compareOnly=DiffSetupData.CompareOnly;
   MFDiffSetup.restoreFromINI=restorefromini;

   status := MFDiff(&MFDiffSetup,showNoEditorOptions);

   return(status);
}

/** 
 * If there is a <B>ViewId</B>>0 and <B>BufferIndex</B>>0, and
 * <B>range</B>==true, prefer the Buffer name
 */
static int DiffLoadBuffer(int BufWidth,
                          _str DiskPrefix,
                          _str FileName,
                          int BufferIndex,
                          int ViewId,
                          int editorwid,
                          _str DisplayName,
                          boolean IsURL,
                          _str URLName,
                          int &InMem,
                          boolean &SoftWrap=false,
                          boolean range=false)
{
   int status=1;
   _str bufwidthstr=BufWidth?'+'BufWidth:'';
   if ( DiskPrefix=="" || FileName=="" ) {
      if (ViewId && !(range && BufferIndex>-1) ) {
         status=editorwid.load_files(def_load_options' 'bufwidthstr' +q +bi 'ViewId.p_buf_id);
      }else if (BufferIndex>-1) {
         status=editorwid.load_files(def_load_options' 'bufwidthstr' +q +bi 'BufferIndex);
      }else{
         status=editorwid.load_files(def_load_options' 'bufwidthstr' +q +b 'strip(FileName,'B','"'));
      }
   }
   if (status) {
      InMem=0;
      _str opts=build_load_options(FileName);
      _str nowindow=(def_one_file!='')?'-w':'';
      _str temp=DiskPrefix' 'maybe_quote_filename(FileName);
      status=editorwid.load_files(opts' 'bufwidthstr' 'nowindow' 'temp);
      // say(opts' 'bufwidthstr' 'nowindow' 'temp' status='status);
      if (status) {
         _message_box(nls("Could not open file '%s'\n\n%s",DisplayName,get_message(status)));
         return(status);
      }
      editorwid.p_buf_flags=VSBUFFLAG_HIDDEN;
      if (IsURL) {
         editorwid.p_DocumentName=URLName;
      }
   }
   if (!status) {
      SoftWrap=editorwid.p_SoftWrap;
   }
   return(status);
}

static void AddImaginaryLines(int NumLines)
{
   DiffIntraLineColoring(0,p_buf_id);
   save_pos(auto p);
   int i;
   for (i=0;i<NumLines;++i) {
      bottom();
      DiffInsertImaginaryBufferLine();
   }
   restore_pos(p);
   DiffIntraLineColoring(1,p_buf_id);
}

static void EvenComments()
{
   if (_ctlfile1.p_Noflines > _ctlfile2.p_Noflines) {
      _ctlfile2.AddImaginaryLines(_ctlfile1.p_Noflines-_ctlfile2.p_Noflines);
   }else if (_ctlfile1.p_Noflines < _ctlfile2.p_Noflines) {
      _ctlfile1.AddImaginaryLines(_ctlfile2.p_Noflines-_ctlfile1.p_Noflines);
   }
}

static int GetFileHidden(_str &filename,
                         int &ViewId,
                         int &orig_view_id,
                         int &fileinmem,
                         _str options='',
                         int &num_lines=0,
                         _str lang=''
                        )
{
   fileinmem=1;
   int status=0;
   if (!pos('+d',options,1,'i')) {
      status=_open_temp_view(filename,ViewId,orig_view_id,'+b 'options);
      if (!status) {
         _SetEditorLanguage(lang);
         num_lines=p_Noflines;
         p_window_id=orig_view_id;
      }
   }else{
      status=1;
   }
   if (status) {
      fileinmem=0;
      if ( pos(' +bi ',' 'options' ') ) fileinmem=1;
      status=_open_temp_view(filename,ViewId,orig_view_id,options);
      if (!status) {
         _SetEditorLanguage(lang);
         num_lines=p_Noflines;
         p_window_id=orig_view_id;
      }
   }
   return(status);
}


void _DiffLoadDiffStateFile(_str filename,boolean showNoEditorOptions=false)
{
   _str parent_option='-desktop';
   boolean modaloption=false;
   boolean restoreFromINI=false;
   if (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE) {
      modaloption=true;
      restoreFromINI=true;
   }
   MFDIFF_SETUP_INFO SetupInfo;
   SetupInfo.DiffStateFilename=filename;
   SetupInfo.ShowNoEditorOptions=showNoEditorOptions;
   SetupInfo.RestoreFromINI=restoreFromINI;
   int wid=show('-new -xy 'parent_option' _difftree_output_form',
            &SetupInfo);
   if (modaloption) {
      wid.p_visible=1;
      _modal_wait(wid);
   }
}

static _str MaybeAppendFilesepQuoted(_str Path)
{
   if (last_char(Path)=='"') {
      Path=substr(Path,1,length(Path)-1);
      _maybe_append_filesep(Path);
      Path=Path:+'"';
      return(Path);
   }
   _maybe_append_filesep(Path);
   return(Path);
}

int _GetFileTable(_str (&FileTable):[],_str Path,_str Filespecs,
                  _str ExcludeFilespecs,boolean recursive,
                  int ProgressFormWID)
{
   Filespecs=stranslate(Filespecs,PATHSEP,' ');
   status := _DiffGetFileTable(Path,Filespecs,ExcludeFilespecs,(int)recursive,FileTable,ProgressFormWID);
   return status ? status:FileTable._length();
}

boolean _DiffFileIsExcluded(_str Filename,_str ExcludeFilespecs,_str Path)
{
   int posStart=1;
   _str cur='';
   for (;;) {
      cur=parse_file(ExcludeFilespecs);
      if (cur=='') break;
      cur=strip(cur,'b','"');
      if (last_char(cur)==FILESEP) {
         cur=substr(cur,1,length(cur)-1);
         posStart=length(Path)+1;
         if (pos(FILESEP,cur)) {
            _str dir_name = _strip_filename(cur,'N');
            _str basename = _strip_filename(cur,'P');
            if (pos(dir_name,Filename,posStart,_fpos_case)==1) {
               _str tmpFilename=Filename;
               while (pos(FILESEP,tmpFilename)) {
                  tmpFilename=_strip_filename(tmpFilename,'N');
                  if (last_char(tmpFilename)==FILESEP) {
                     tmpFilename=substr(tmpFilename,1,length(tmpFilename)-1);
                  }
                  if (_FilespecMatches(basename,_strip_filename(tmpFilename,'P'))) {
                     return(true);
                  }
               }
            }


            continue;
         }
         _str tmpFilename=Filename;
         while (pos(FILESEP,tmpFilename)) {
            tmpFilename=_strip_filename(tmpFilename,'N');
            if (last_char(tmpFilename)==FILESEP) {
               tmpFilename=substr(tmpFilename,1,length(tmpFilename)-1);
            }
            if ( length(tmpFilename)<posStart ) {
               break;
            }
            if (_FilespecMatches(cur,_strip_filename(tmpFilename,'P'))) {
               return(true);
            }
         }
         continue;
      }
      if (_FilespecMatches(cur,_strip_filename(Filename,'P'))) {
         return(true);
      }
   }
   return(false);
}

int _GetNonCommentSeek(int ViewId,long &SeekPos,int &line_num=0)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   boolean DoClex=true;
   _str extension='';
   _str lang='';
   _str buf_name='';
   int setup_index=0;
   {
      //Only want to do this once!!!
      if ( p_LangId == '' ) {
         extension= _get_extension(p_buf_name);
         buf_name=p_buf_name;
         lang=extension;
         check_and_load_support(extension,setup_index,buf_name);

         lang=_DiffFilename2LangId(buf_name);

         if ( setup_index ) {
            VS_LANGUAGE_SETUP_OPTIONS setup;
            _GetLanguageSetupOptions(lang,setup);

            p_mode_name=setup.mode_name;
            p_LangId=lang;
            p_color_flags=setup.color_flags;
            p_lexer_name=setup.lexer_name;
         }else{
            DoClex=false;
         }
      }
   }
   if ( p_LangId=="fundamental") _SetEditorLanguage();
   _GoToROffset(0);
   int status=0;
   if (DoClex) {
      if (!(p_color_flags&LANGUAGE_COLOR_FLAG)) {
         SeekPos=0;
         return(0);
      }
      status=_clex_find(COMMENT_CLEXFLAG,'N');
   }
   SeekPos=_QROffset();
   line_num=p_line;
   p_window_id=orig_view_id;
   return(status);
}

static void parseDiffFileInfo(_str fileInfo,int &year,int &month,int &day,
                              int &hours,int &minutes,int &milliseconds,long &size)
{
   parse fileInfo with auto fileDate FILE_TABLE_DELIM auto fileSize;

   sYear := substr(fileDate,1,4);
   sMonth := substr(fileDate,5,2);
   sDay := substr(fileDate,7,2);
   sHours := substr(fileDate,9,2);
   sMinutes := substr(fileDate,11,2);
   sMilliseconds := substr(fileDate,13);

   year = (int)sYear;
   month = (int)sMonth;
   day = (int)sDay;
   hours = (int)sHours;
   minutes = (int)sMinutes;
   milliseconds = (int)sMilliseconds;

   size = (long)fileSize;
}

/** 
 * Compare file info strings.  NOTE: Only allows for 2 second 
 * difference in file date 
 *  
 * @param fileinfo1 String set in _DiffGetFileTable
 * @param fileinfo2 String set in _DiffGetFileTable
 * 
 * @return boolean true if file info strings match
 */
static boolean diffFileInfoMatches(_str fileinfo1,_str fileinfo2,boolean matchSizeOnly=false)
{
   match := true;

   parseDiffFileInfo(fileinfo1,auto year1,auto month1,auto day1,
                     auto hours1,auto minutes1,auto milliseconds1,auto size1);
   parseDiffFileInfo(fileinfo2,auto year2,auto month2,auto day2,
                     auto hours2,auto minutes2,auto milliseconds2,auto size2);

   do {
      if ( size1!=size2 ) {
         match = false;
         break;
      }
      if ( matchSizeOnly ) break;

      if ( year1!=year2 ) {
         match = false;
         break;
      }

      if ( month1!=month2 ) {
         match = false;
         break;
      }

      if ( day1!=day2 ) {
         match = false;
         break;
      }

      if ( hours1!=hours2 ) {
         match = false;
         break;
      }

      if ( minutes1!=minutes2 ) {
         match = false;
         break;
      }

      if ( abs(milliseconds1-milliseconds2) > 2000 ) {
         // Allow for a 2 second difference because of FAT file systems
         match = false;
         break;
      }
   } while (false);
   return match;
}

static int FastCompareFiles(_str filename1,_str filename2,int ProgressFormWID)
{
   int status = 0;
   do {
      orig_view_id := p_window_id;
      status = _open_temp_view(filename1,auto File1ViewId,auto junk);
      if (status) {
         p_window_id=orig_view_id;
         break;
      }
      status=_open_temp_view(filename2,auto File2ViewId,junk);
      if (status) {
         _delete_temp_view(File1ViewId);
         p_window_id=orig_view_id;
         break;
      }
      p_window_id=orig_view_id;
      if ( ProgressFormWID ) {
         process_events(gDiffCancel);
         if (gDiffCancel) {
            _delete_temp_view(File1ViewId);
            _delete_temp_view(File2ViewId);
            status = COMMAND_CANCELLED_RC;
            break;
         }
      }
      _nocheck _control label1;
      if (ProgressFormWID) {
         ProgressFormWID._DiffSetProgressMessage('Fast Comparing',filename1,filename2);
      }
      //This means we are in the "sunny day" scenario.  Even a size
      //mismatch is good enough
      long seek1,seek2;
      seek1=seek2=0;
      int NCSStatus1=0,NCSStatus2=0;
      if (def_diff_options&DIFF_LEADING_SKIP_COMMENTS) {
         NCSStatus1=_GetNonCommentSeek(File1ViewId,seek1);
         NCSStatus2=_GetNonCommentSeek(File2ViewId,seek2);
      }
      //If we get STRING_NOT_FOUND_RC for both of these, the files are all
      //comment
      if (NCSStatus1==STRING_NOT_FOUND_RC &&
          NCSStatus2==STRING_NOT_FOUND_RC) {
         status=0;
      }else{
         if ( !(def_diff_options&DIFF_NO_SOURCE_DIFF) ) {

            lang := _DiffFilename2LangId(filename1,File1ViewId.p_buf_id);
            File1ViewId._SetEditorLanguage(lang);

            lang = _DiffFilename2LangId(filename2,File2ViewId.p_buf_id);
            File2ViewId._SetEditorLanguage(lang);

            status = _DiffBalanceFiles(File1ViewId,File2ViewId,auto balancedFiles,0);
         }
         status=FastCompare(File1ViewId,seek1,File2ViewId,seek2,def_diff_options);
         _delete_temp_view(File1ViewId);
         _delete_temp_view(File2ViewId);
      }
   } while (false);
   return status;
}
int DiffFileTables(_str (&FileTable1):[],_str BasePath1,
                   _str (&FileTable2):[],_str BasePath2,
                   _str (&Output)[],int ProgressFormWID,
                   boolean CompareAllSymbols=false)
{
   BasePath1=strip(BasePath1,'B','"');
   BasePath2=strip(BasePath2,'B','"');
   int path1len=length(BasePath1);
   int path2len=length(BasePath2);
   int count=0;
   int dcount=0;
   _str DelTable1:[];
   _str DelTable2:[];
   int NumFiles=0;
   typeless i;
   for (i._makeempty();;++NumFiles) {
      FileTable1._nextel(i);
      if (i._isempty()) break;
   }
   _nocheck _control gauge1;
   if (ProgressFormWID) {
      ProgressFormWID._DiffShowProgressGauge();
      ProgressFormWID.gauge1.p_min=0;
      ProgressFormWID.gauge1.p_max=NumFiles;
   }
   _str filename1='';
   _str filename2='';
   int orig_view_id=0;
   int status=0;
   int File1ViewId=0;
   int File2ViewId=0;
   typeless junk;
   boolean cancelled = false;

   if ( !(def_diff_options&DIFF_NO_SOURCE_DIFF) ) {
      // Add notification here
   }

   for (i._makeempty();;) {
      if (ProgressFormWID) {
         ++ProgressFormWID.gauge1.p_value;
      }
      FileTable1._nextel(i);
      if ( progress_cancelled() ) {
         cancelled = true;
         break;
      }
      if (i._isempty()) {
         if (ProgressFormWID) {
            ProgressFormWID.gauge1.p_value=ProgressFormWID.gauge1.p_max;
            ProgressFormWID.gauge1.refresh('W');
         }
         break;
      }
      filename1=FileTable1:[i];
      parse filename1 with filename1 FILE_TABLE_DELIM auto fileinfo1;
      filename2=BasePath2:+substr(filename1,path1len+1);
      if (last_char(filename1)==FILESEP) {
         filename1=substr(filename1,1,length(filename1)-1);
         if (_strip_filename(filename1,'P')=='..') {
            DelTable1:[filename1]='';
            DelTable2:[filename2]='';
            continue;
         }
         filename1=_strip_filename(filename1,'N');
         filename2=substr(filename2,1,length(filename2)-1);
         filename2=_strip_filename(filename2,'N');

         if (FileTable2._indexin(filename2)) {
            //Have to put '0' at the end for status...
            //Directories[dcount++]=filename1"\tfilename2;
            DelTable1:[filename1]='';
            DelTable2:[filename2]='';
            continue;
         }
      }
      casedFilename2 := _file_case(filename2);
      if (FileTable2._indexin(casedFilename2)) {
         parse FileTable2:[casedFilename2] with . FILE_TABLE_DELIM auto fileinfo2;

         boolean fileInfoMatches=false;

         if ( def_diff_options&DIFF_MFDIFF_REQUIRE_TEXT_MATCH ) {
            status=FastCompareFiles(filename1,filename2,ProgressFormWID);
            if ( status==COMMAND_CANCELLED_RC ) break;
         }else if ( def_diff_options&DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH ) {
            if ( diffFileInfoMatches(fileinfo1,fileinfo2) ) {
               status=0;
            }else{
               if ( def_diff_options&DIFF_MFDIFF_SIZE_ONLY_MATCH_IS_MISMATCH &&
                    diffFileInfoMatches(fileinfo1,fileinfo2,true) ) {
                  status=1;
               } else {
                  status=FastCompareFiles(filename1,filename2,ProgressFormWID);
               }
            }
            //if ( fileinfo1==fileinfo2 ) {
            //   status=0;
            //}else{
            //   status=1;
            //}
         }else {
            // If DIFF_MFDIFF_REQUIRE_SIZE_DATE_MATCH and DIFF_MFDIFF_REQUIRE_TEXT_MATCH
            // are not set, just check the size
            parse fileinfo1 with FILE_TABLE_DELIM auto filesize1;
            parse fileinfo2 with FILE_TABLE_DELIM auto filesize2;
            if ( filesize1==filesize2 ) {
               status=0;
            }else{
               status=1;
            }
         }
         Output[count++]=filename1"\t"_file_date(filename1,'B')"\t"filename2"\t"_file_date(filename2,'B')"\t"status;
         DelTable1:[filename1]='';
         DelTable2:[filename2]='';
      }
   }
   if (ProgressFormWID) {
      ProgressFormWID.gauge1.p_value=ProgressFormWID.gauge1.p_max;
   }
   clear_message();
   RemoveFromTable(FileTable1,DelTable1);
   RemoveFromTable(FileTable2,DelTable2);

   foreach ( auto curIndex => auto curFilename in FileTable1 ) {
      parse FileTable1:[curIndex] with curFilename FILE_TABLE_DELIM .;
      FileTable1:[curIndex] = curFilename;
   }

   foreach ( curIndex => curFilename in FileTable2 ) {
      parse FileTable2:[curIndex] with curFilename FILE_TABLE_DELIM .;
      FileTable2:[curIndex] = curFilename;
   }

   if ( cancelled ) return(1);
   return(0);
}

static boolean VerifyPath(_str path)
{
   //Strip trailing filesep, throws off file_match
   _str match='';
   if (last_char(path)==FILESEP) path=substr(path,1,length(path)-1);
   path=maybe_quote_filename(path);
   if (isunc_root(path) || isdrive(path)) {
      //If it is a unc root, file_match won't work the same, have to tinker a
      //little(This is actually an os thing, tested with "fftest" program
      match=file_match(path:+FILESEP:+ALLFILES_RE' +p +d',1);
      if (match=='') {
         return(1);
      }
      //This actually comes back with <path>FILESEP.FILESEP
      //ex:
      //\\dan\test\ -> \\dan\test\.\
      //But it seems to be consistent.  Thought about using chdir to see
      //if it was valid, but among other problems(don't know if we can still
      //cd to UNC name), thought that this could cause problems on UNIX
   }else{
      //If this is a "normal" situation, doing a file match with the
      //name missing the trailing FILESEP, will come back with it if
      //there is a directory there ex:
      //c:\dan\test -> c:\dan\test\.\
      if (substr(path,1,1)=='"') {
         if (last_char(path)=='"') path=substr(path,1,length(path)-1);
         if (last_char(path)==FILESEP) {
            path=substr(path,1,length(path)-1);
         }
         path=path:+'"';
         match=file_match(path' -p +d',1);
      }else{
         match=file_match(path' -p +d',1);
      }
      //If it is a directory, match will come back with trailing filesep
      if (last_char(match)!=FILESEP) {
         //Last chance...
         match=buf_match(path,1,'eh');
         if (match!='') {
            return(0);//Probably an ftp buffer...
         }
         return(1);
      }
   }
   return(0);
}

static void RemoveFromTable(_str (&FileTable):[],_str RemoveTable:[])
{
   typeless i;
   for (i._makeempty();;) {
      RemoveTable._nextel(i);
      if (i._isempty()) break;
      FileTable._deleteel(_file_case(i));
   }
}

#define MFDIFF_INPUT_ERROR_PATH1            1
#define MFDIFF_INPUT_ERROR_PATH2            2
#define MFDIFF_INPUT_ERROR_EQIVILANT_PATHS  3
#define MFDIFF_INPUT_ERROR_BLANK            4
#define MFDIFF_INPUT_ERROR_FILESPEC_HAS_DIR 5

//This is used for commmand line stuff....
//Others check return codes and call _text_box_error in the appropriate place
static int DisplayMFDiffErrorMessage(int status)
{
   switch (status) {
   case MFDIFF_INPUT_ERROR_PATH1:
      _message_box(nls("Error in Path 1"));
      break;
   case MFDIFF_INPUT_ERROR_PATH2:
      _message_box(nls("Error in Path 2"));
      break;
   case MFDIFF_INPUT_ERROR_EQIVILANT_PATHS:
      _message_box(nls("Paths must be different"));
      break;
   case MFDIFF_INPUT_ERROR_BLANK:
      _message_box(nls("Must specify filespec"));
      break;
   case MFDIFF_INPUT_ERROR_FILESPEC_HAS_DIR:
      _message_box(nls("Exclude filespec may not have path information"));
      break;
   }
   return(status);
}

static int VerifyFilespec(_str filespec,_str option='')
{
   if (option=='N') {
      for (;;) {
         _str cur='';
         parse filespec with cur filespec;
         if (cur=='') {
            break;
         }
         int p=pos(FILESEP,cur);
         if (p && p!=length(cur)) {
            return(MFDIFF_INPUT_ERROR_FILESPEC_HAS_DIR);
         }
       }
      if (pos(FILESEP,filespec)) {
         return(MFDIFF_INPUT_ERROR_FILESPEC_HAS_DIR);
      }
   }else {
      if (filespec=='') {
         //If it was blank, just put in a '*', this is probably what they meant
         return(MFDIFF_INPUT_ERROR_BLANK);
      }
   }
   return(0);
}

static boolean PathIsDiffFileList(_str path)
{
   return(file_eq(_get_extension(path),DIFF_LIST_FILE_EXT));
}


static int VerifyMultiFileDiffInput(_str path1,_str path2,
                                    _str filespec,_str excludeFilespec)
{
   if (!PathIsDiffFileList(path1)) {
      if (VerifyPath(path1)) return(MFDIFF_INPUT_ERROR_PATH1);
   }
   if (VerifyPath(path2)) return(MFDIFF_INPUT_ERROR_PATH2);
   path1=MaybeAppendFilesepQuoted(path1);
   path2=MaybeAppendFilesepQuoted(path2);
   //Be sure that paths are different
   if (file_eq(path1,path2)) {
      return(MFDIFF_INPUT_ERROR_EQIVILANT_PATHS);
   }
   typeless status=0;
   //if (PathIsDiffFileList(path1)) {
      status=VerifyFilespec(filespec);
      if (status) {
         return(status);
      }
      status=VerifyFilespec(excludeFilespec,'N');
      if (status) {
         return(status);
      }
   //}
   return(0);
}


static int GetFileTablesFromList(_str ListFilename,_str path2,
                                 _str (&FileTable1):[],
                                 _str (&FileTable2):[])
{
   _str path1=_strip_filename(ListFilename,'N');
   path1=MaybeAppendFilesepQuoted(path1);
   path2=MaybeAppendFilesepQuoted(path2);
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(ListFilename,temp_view_id,orig_view_id);
   if (status) return(status);
   p_window_id=temp_view_id;
   int count=0;
   top();up();
   _str line='';
   _str rfilename='';
   while (!down()) {
      get_line(line);
      rfilename=strip(parse_file(line),'B','"');
      _str filename=maybe_quote_filename(path1:+rfilename);
      _str filename2=maybe_quote_filename(path2:+rfilename);
      FileTable1:[_file_case(filename)]=filename;
      FileTable2:[_file_case(filename2)]=filename2;
   }
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}
_command void TreeDiff(_str arg1='')
{
   //This is really simplified...
   _str path1=parse_file(arg1);
   if (path1=='') {
      _message_box(nls('Path1 is required'));
      return;
   }
   _maybe_append_filesep(path1);
   _str path2=parse_file(arg1);
   if (path2=='') {
      _message_box(nls('Path2 is required'));
      return;
   }
   _maybe_append_filesep(path2);
   _str filespecs=arg1;
   if (filespecs=='') {
      _message_box(nls('filespecs are required'));
      return;
   }
   filespecs=strip(filespecs,'B','"');
   _str tempfile='';
   MakeOptionsFile(tempfile,filespecs,'',def_diff_options,1,path1,path2);
   diff('-optionsfile 'tempfile);
}

static int MakeOptionsFile(_str &filename,_str Filespecs,_str ExcludeFilespecs,
                           int optionflags,boolean recursive,
                           _str path1,_str path2,boolean showNoEditorOptions=false)
{
   filename=mktemp();
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   insert_line('filespec:'Filespecs);
   insert_line('excludefilespec:'ExcludeFilespecs);
   insert_line('optionflags:'optionflags);
   insert_line('recursive:'recursive);
   insert_line('path1:'maybe_quote_filename(path1));
   insert_line('path2:'maybe_quote_filename(path2));
   insert_line('shownoeditoroptions:'maybe_quote_filename(showNoEditorOptions));
   int status=_save_file('+o 'filename);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(status);
}

static int MFDiff(DIFF_SETUP_INFO *pSetupInfo,boolean showNoEditorOptions)
{
   int mfdiff_callback_index=find_index("_diff_mf_callback1",PROC_TYPE);
   if (pSetupInfo->compareOnly && !mfdiff_callback_index) {
      // If we are doing a compare only, but no callback was specified, there is
      // nothing to do
      if (pSetupInfo->compareAllSymbols) {
         int diff_tags_index=find_index("_diff_tags_callback1",PROC_TYPE);
         if (diff_tags_index && index_callable(diff_tags_index)) {
            return(_DiffExpandTags2(pSetupInfo->path1,pSetupInfo->path2,-1,-1));
         }
      }
      return(1);
   }
   if (! (GMFDiffViewOptions&(DIFF_VIEW_DIFFERENT_SYMBOLS|DIFF_VIEW_MISSING_SYMBOLS1|DIFF_VIEW_MISSING_SYMBOLS2) ) ) {
      GMFDiffViewOptions|=DIFF_VIEW_DIFFERENT_SYMBOLS|DIFF_VIEW_MISSING_SYMBOLS1|DIFF_VIEW_MISSING_SYMBOLS2;
   }
   _str path1=_diff_absolute(pSetupInfo->path1),path2=_diff_absolute(pSetupInfo->path2);
   _str Filespecs=pSetupInfo->filespec,ExcludeFilespecs=pSetupInfo->excludeFilespec;
   boolean recursive=pSetupInfo->recursive;
   _str recursiveOptionString='';
   _str cmdline='';
   typeless status=0;
   _str tempname='';
   if ((def_diff_edit_options&DIFFEDIT_SPAWN_MFDIFF)
       && (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)!=SW_HIDE)
       && _win32s()!=1/*just in case*/) {
      recursiveOptionString=(recursive?'-recursive':'');

      cmdline=maybe_quote_filename(editor_name('P'):+'vs');//editor name
      status=MakeOptionsFile(tempname,Filespecs,ExcludeFilespecs,def_diff_options,recursive,path1,path2,showNoEditorOptions);
      cmdline=cmdline' +new -q -st 0 -mdihide -p diff -optionsfile 'tempname;
      status=list_modified('',true);
      if (status==COMMAND_CANCELLED_RC) {
         return(COMMAND_CANCELLED_RC);
      }
      status=shell(cmdline,'QA');
      return(0);
   }
   _str FileTable1:[],FileTable2:[];

   int ProgressFormWID=0;
   if (!pSetupInfo->compareAllSymbols) {
      ProgressFormWID=show('-desktop -hidden _difftree_progress_form');
   }
   _str disabled_wid_list='';
   if (ProgressFormWID) {
      ProgressFormWID._DiffHideProgressGauge();
      ProgressFormWID.p_visible=1;
      disabled_wid_list=_enable_non_modal_forms(0,ProgressFormWID);
      if (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE) {
         ProgressFormWID._ShowWindow(SW_SHOWNOACTIVATE);
      }
      ProgressFormWID._set_foreground_window();
   }

   int NumFilesInPath1=0;
   int NumFilesInPath2=0;
   if (PathIsDiffFileList(path1)) {
      GetFileTablesFromList(path1,path2,FileTable1,FileTable2);
      path1=_strip_filename(path1,'N');
      pSetupInfo->path1=path1;
   }else if (pSetupInfo->compareAllSymbols){
      NumFilesInPath1=NumFilesInPath2=1;
      pSetupInfo->path1=strip(pSetupInfo->path1,'B','"');
      pSetupInfo->path2=strip(pSetupInfo->path2,'B','"');

      justPath1 := _file_path(path1);
      justPath2 := _file_path(path2);

      justName1 := _strip_filename(pSetupInfo->path1,'P');
      justName2 := _strip_filename(pSetupInfo->path2,'P');

      NumFilesInPath1=_GetFileTable(FileTable1,justPath1,justName1,"",false,0);
      NumFilesInPath1=_GetFileTable(FileTable2,justPath2,justName2,"",false,0);
   }else{
      NumFilesInPath1=_GetFileTable(FileTable1,path1,Filespecs,ExcludeFilespecs,recursive,ProgressFormWID);
      if (NumFilesInPath1<0) {
         _enable_non_modal_forms(1,0,disabled_wid_list);
         if (ProgressFormWID) {
            ProgressFormWID._delete_window();
         }
         return(1);
      }
      NumFilesInPath2=_GetFileTable(FileTable2,path2,Filespecs,ExcludeFilespecs,recursive,ProgressFormWID);
      if (NumFilesInPath2<0) {
         _enable_non_modal_forms(1,0,disabled_wid_list);
         if (ProgressFormWID) {
            ProgressFormWID._delete_window();
         }
         return(1);
      }
   }

   clear_message();

   if (!NumFilesInPath1 && !NumFilesInPath2) {
      _message_box("No Files match these parameters");
      _enable_non_modal_forms(1,0,disabled_wid_list);
      if (ProgressFormWID) {
         ProgressFormWID._delete_window();
      }
      return(1);
   }
   _str OutputTable[];
   status=DiffFileTables(FileTable1,path1,FileTable2,path2,OutputTable,ProgressFormWID,pSetupInfo->compareAllSymbols);
   if (status) {
      _enable_non_modal_forms(1,0,disabled_wid_list);
      if (ProgressFormWID) {
         ProgressFormWID._delete_window();
      }
      return(status);
   }
   _str parent_option='-desktop';
   typeless modaloption='';
   if (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE ||
       showNoEditorOptions) {
      modaloption=' -modal ';
   }
   if (ProgressFormWID) {
      _enable_non_modal_forms(1,0,disabled_wid_list);
   }
   if (ProgressFormWID) {
      ProgressFormWID._delete_window();
   }
   if (pSetupInfo->compareAllSymbols) {
      path1=_strip_filename(path1,'N');
      path2=_strip_filename(path2,'N');
   }
   MFDIFF_SETUP_INFO SetupInfo;
   SetupInfo.FileTable1=FileTable1;
   SetupInfo.Path1=path1;
   SetupInfo.FileTable2=FileTable2;
   SetupInfo.Path2=path2;
   SetupInfo.OutputTable=OutputTable;
   SetupInfo.BasePath1=path1;
   SetupInfo.BasePath2=path2;
   SetupInfo.Filespecs=Filespecs;
   SetupInfo.ExcludeFilespecs=ExcludeFilespecs;
   SetupInfo.modalOption=modaloption;
   SetupInfo.recursive=recursive;
   SetupInfo.fileListInfo=pSetupInfo->fileListInfo;
   SetupInfo.ExpandFirst=pSetupInfo->compareAllSymbols;
   SetupInfo.ShowNoEditorOptions=showNoEditorOptions;
   SetupInfo.RestoreFromINI=pSetupInfo->restoreFromINI;
   if (pSetupInfo->compareOnly) {
      // Run the diff operation and call all of the callbacks, but do not bring
      // up the dialog
      return(MFDiffNoDialog(&SetupInfo,mfdiff_callback_index));
   }
   // For better multi-monitor support, 
   typeless formwid=show('-new -xy 'parent_option' _difftree_output_form',
                &SetupInfo
                );
   if ( formwid>=0 ) {

      if ( modaloption!='' ) {
         if ( pSetupInfo->restoreFromINI ) {
            int DialogX,DialogY,DialogWidth,DialogHeight;
            status=_DiffGetConfigInfoFromIniFile("MFDiffGeometry",DialogX,DialogY,DialogWidth,DialogHeight);
            if (!status) {
               formwid.p_x=DialogX;
               formwid.p_y=DialogY;
               formwid.p_width=DialogWidth;
               formwid.p_height=DialogHeight;
            }
         }
         _modal_wait(formwid);
      }
      if ( modaloption=='' ) {
         _nocheck _control tree1;
         _nocheck _control tree2;
         int s1=formwid.tree1._TreeScroll();
         int s2=formwid.tree2._TreeScroll();
         formwid.tree2._TreeScroll(s1);
      }
   }
   return(0);
}

// These constants have to match the ones in vs.h

#define DIFF_FILE_STATUS_MATCH     0
#define DIFF_FILE_STATUS_PATH1     1
#define DIFF_FILE_STATUS_PATH2     2
#define DIFF_FILE_STATUS_DIFFERENT 3

static int MFDiffNoDialog(MFDIFF_SETUP_INFO *pSetupInfo,int mfdiff_callback_index)
{
   if (!index_callable(mfdiff_callback_index)) {
      return(1);
   }
   _str filename1='';
   _str date1='';
   _str filename2='';
   _str date2='';
   _str state=0;
   typeless i;
   for (i=0;i<pSetupInfo->OutputTable._length();++i) {
      parse pSetupInfo->OutputTable[i] with filename1 date1 filename2 date2 state;
      int filestate=state?DIFF_FILE_STATUS_DIFFERENT:DIFF_FILE_STATUS_MATCH;
      call_index(filename1,filename2,filestate,mfdiff_callback_index);
   }
   for (i._makeempty();;) {
      pSetupInfo->FileTable1._nextel(i);
      if (i._isempty()) break;
      call_index(i,'',DIFF_FILE_STATUS_PATH1,mfdiff_callback_index);
   }
   for (i._makeempty();;) {
      pSetupInfo->FileTable2._nextel(i);
      if (i._isempty()) break;
      call_index(i,'',DIFF_FILE_STATUS_PATH2,mfdiff_callback_index);
   }
   call_index('','',-1,mfdiff_callback_index);
   return(0);
}


static void MaybeAddDelims(_str &path)
{
   if (path=='') return;
   if (substr(path,1,1)!=ASCII1) {
      path=ASCII1:+path;
   }
   if (last_char(path)!=ASCII1) {
      path=path:+ASCII1;
   }
}

static void GetMapPoints(_str DiffPath1,_str &MapPoint1,
                         _str DiffPath2,_str &MapPoint2)
{
   DiffPath1=_strip_filename(DiffPath1,'N');
   DiffPath2=_strip_filename(DiffPath2,'N');
   _str cur1=DiffPath1;
   _str last1=cur1;
   _str cur2=DiffPath2;
   _str last2=cur2;
   _str curName1='';
   _str curName2='';
   for (;;) {
      last1=cur1;
      last2=cur2;
      cur1=substr(cur1,1,length(cur1)-1);
      cur2=substr(cur2,1,length(cur2)-1);
      curName1=_strip_filename(cur1,'P');
      curName2=_strip_filename(cur2,'P');
      if (!file_eq(curName1,curName2)) {
         break;
      }
      cur1=_strip_filename(cur1,'N');
      cur2=_strip_filename(cur2,'N');
      if (cur1==''||cur2=='') break;
   }
   MapPoint1=stranslate(last1,'','"');
   MapPoint2=stranslate(last2,'','"');
}

static int AddToLogfile(_str Filename,
                        _str time,
                        _str Filename1='',
                        _str Filename2='',
                        _str Filespecs='',
                        _str ExcludeFilespecs='')
{
   _str NewName=_strip_filename(Filename,'E')'.log';
   int temp_view_id=0;
   int orig_view_id=0;
   typeless status=_open_temp_view(NewName,temp_view_id,orig_view_id);
   if (status) {
      orig_view_id=_create_temp_view(temp_view_id);
      p_buf_name=NewName;
   }
   bottom();

   _str FileInfo=file_match(Filename' +v -p',1);

   typeless exist=0;
   if (Filename1!='') {
      //We will only have Filename1 if we are saving "before" information
      if (p_Noflines) insert_line('');
      insert_line(time'****************OLD**************************');
      exist=file_match(Filename' -p',1)!='';
      if (exist) {
         get(Filename);
      }else{
         insert_line('*[no file]');
      }
      bottom();
      insert_line(time'****************Applied**********************');
      insert_line('*Filename1='Filename1);
      insert_line('*Filename2='Filename2);
      insert_line('*Filespecs='Filespecs);
      insert_line('*ExcludeFilespecs='ExcludeFilespecs);
      insert_line('************************************************************');
   }
   _save_file('+o');
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}


static void SaveDiffMapInfo(_str filename1,_str filename2,
                            _str filespec,_str excludeFilespec)
{
   _str path=_ConfigPath();
   if (last_char(path)!=FILESEP) path=path:+FILESEP;
   _str HistoryFilename=path:+DIFFMAP_FILENAME;
   //status=_open_temp_view(HistoryFilename,temp_view_id,orig_view_id);
   int orig_view_id=p_window_id;
   int temp_view_id=0;
   typeless status=_ini_get_section(HistoryFilename,"Mappings",temp_view_id);
   if (status) {
      if (status==FILE_NOT_FOUND_RC ||
          status==STRING_NOT_FOUND_RC) {
         orig_view_id=_create_temp_view(temp_view_id);
      }else{
         return;//Not that important
      }
   }
   p_window_id=temp_view_id;
#if 1
   _str DiffPath1=_strip_filename(_diff_absolute(filename1),'N');
   _str DiffPath2=_strip_filename(_diff_absolute(filename2),'N');
#else
   _str DiffPath1=strip_filename(filename1,'N');
   _str DiffPath2=strip_filename(filename2,'N');
#endif
   filename1=stranslate(filename1,'','"');
   filename2=stranslate(filename2,'','"');
   _str MapPoint1='';
   _str MapPoint2='';
   _str line='';
   _str paths='';
   _str beglist='';
   _str endlist='';
   GetMapPoints(DiffPath1,MapPoint1,DiffPath2,MapPoint2);
   top();up();
   status=search('^'_escape_re_chars(MapPoint1)'($|\1)','@r'_fpos_case);
   if (status) {
      top();up();
      insert_line(MapPoint1:+ASCII1:+MapPoint2:+ASCII1);
   }else{
      get_line(line);
      parse line with . (ASCII1) paths;
      paths=ASCII1:+paths;
      parse paths with beglist (ASCII1:+MapPoint2:+ASCII1) endlist;
      MaybeAddDelims(beglist);
      MaybeAddDelims(endlist);
      _delete_line();
      top();up();
      insert_line(MapPoint1:+ASCII1:+MapPoint2:+beglist:+endlist);
   }
   #if USING_MAP_DEBUG_FILE
   time=_time()"\t"_date();
   //THIS IS THE CODE I AM ADDING FOR CLARK TO TRY TO FIGURE OUT WHAT IS
   //WRONG WITH HIS MAPPING STUFF
   AddToLogfile(HistoryFilename,time,filename1,filename2,filespec,excludeFilespec);
   #endif
   p_window_id=orig_view_id;
   status=_ini_put_section(HistoryFilename,"Mappings",temp_view_id);
   _str name='';
   typeless MaxNumMaps='';
   typeless MaxPath2NumHist='';
   typeless MaxNumFilespecHist='';
   typeless MaxNumExcludeFilespecHist='';
   parse def_max_diffhist with MaxNumMaps MaxPath2NumHist MaxNumFilespecHist MaxNumExcludeFilespecHist;
   AddHistoryInfo(filename1,"Path1History",MaxPath2NumHist);
   if (last_char(filename2)==FILESEP) {
      AddHistoryInfo(filename2,"Path2History",MaxPath2NumHist);
   }else{
      name=filename2;
      // If this is an integer, it is a buffer id.  Don't add it.
      if ( !isinteger(name) ) {
         AddHistoryInfo(name,"Path2History",MaxPath2NumHist);
      }
   }
   if (filespec!='') {
      AddHistoryInfo(filespec,"FilespecsHistory",MaxNumFilespecHist);
   }
   if (excludeFilespec!='') {
      AddHistoryInfo(excludeFilespec,"ExcludeFilespecsHistory",MaxNumExcludeFilespecHist);
   }
}

static void AddHistoryInfo(_str Info,_str SectionName,int MaxNum)
{
   int temp_view_id=0;
   int orig_view_id=p_window_id;
   _str path=_ConfigPath();
   if (last_char(path)!=FILESEP) path=path:+FILESEP;
   _str HistoryFilename=path:+DIFFMAP_FILENAME;
   int status=_ini_get_section(HistoryFilename,SectionName,temp_view_id);
   if (status) {
      orig_view_id=_create_temp_view(temp_view_id);
   }
   p_window_id=temp_view_id;
   top();up();
   status=search('^'_escape_re_chars(Info)'$','@r'_fpos_case);
   if (!status) {
      _delete_line();
   }
   top();up();
   insert_line(Info);
   bottom();
   while (p_Noflines>MaxNum) {
      _delete_line();
   }
   p_window_id=orig_view_id;
   status=_ini_put_section(HistoryFilename,SectionName,temp_view_id);
}

defeventtab _merge_setup_form;

// Used for rev1 and rev2 textboxes also
void _ctlbase.on_change()
{
   _str filename=strip(p_text,'B','"');
   _str match=buf_match(filename,1,'E');
   p_next.p_next.p_next.p_enabled=match!='';
   //p_next.p_next.p_value=1;
}

void ctlbrowse_output.lbutton_up()
{
   int wid=p_window_id;
   int open_flags=0;
   if (p_prev.p_name!='_ctloutput') {
      open_flags=OFN_FILEMUSTEXIST;
   }
   typeless result=_OpenDialog('-modal',
                      '',                   // Dialog Box Title
                      '',                   // Initial Wild Cards
                      def_file_types,       // File Type List
                      open_flags     // Flags
                      );
   if (result=='') {
      return;
   }
   p_window_id=wid.p_prev;
   p_text=strip(result,'B','"');
   end_line();
   _set_focus();
   return;
}

_ctlok.on_create()
{
   _merge_setup_form_initial_alignment();

   _ctlinteractive.p_value=1;
   p_active_form._retrieve_prev_form();
   if (!ctlshowchanges.p_value &&
       !ctlautomerge.p_value) {
      ctlautomerge.p_value=1;
   }
   _ctlbase.call_event(CHANGE_OTHER,_ctlbase,ON_CHANGE,"W");
   _ctlrev1.call_event(CHANGE_OTHER,_ctlrev1,ON_CHANGE,"W");
   _ctlrev2.call_event(CHANGE_OTHER,_ctlrev2,ON_CHANGE,"W");
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _merge_setup_form_initial_alignment()
{
   rightAlign := frame1.p_width - label1.p_x;
   sizeBrowseButtonToTextBox(_ctlbase, ctlbrowsedir.p_window_id, ctlpath1_buffer.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(_ctlrev1, ctlcommand2.p_window_id, ctlcommand3.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(_ctlrev2, ctlcommand4.p_window_id, ctlcommand5.p_window_id, rightAlign);
   sizeBrowseButtonToTextBox(_ctloutput.p_window_id, ctlcommand6.p_window_id, 0, rightAlign);
}

//Runs both buttons
_ctlinteractive.lbutton_up()
{
   if (p_name=='_ctlinteractive') {
      _ctlsmart_merge.p_enabled=p_value!=0;
      ctlshowchanges.p_enabled=p_value!=0;
   }else{
      _ctlsmart_merge.p_enabled=p_value==0;
      ctlshowchanges.p_enabled=p_value==0;
   }
   if (!ctlshowchanges.p_enabled) {
      ctlautomerge.p_value=1;
   }
}

/**
 * Call this as a method on a text box to show an
 * error message, activate the text box, and select
 * the text.
 *
 * @param msg    Message to be displayed.
 */
void _text_box_error(_str msg)
{
   _message_box(nls("%s",msg));
   _set_focus();
   _set_sel(1,length(p_text)+1);
   return;
}

static int MergeCheckFilename(_str option='')
{
   typeless status=0;
   int orig_view_id=0;
   _str filename='';
   if (option!='N') {
      if (MergeSetupBuffer()) {
         filename=p_text;
         orig_view_id=p_window_id;
         p_window_id=VSWID_HIDDEN;
         _safe_hidden_window();
         status=load_files('+b 'strip(filename,'B','"'));
         p_window_id=orig_view_id;
         return(status);
      }
   }
   if (p_text=='') {
      _text_box_error("You must fill in all four filenames");
      return(1);
   }
   if (iswildcard(p_text) && !file_exists(p_text)) {
      _text_box_error("Wildcards not allowed");
      return(1);
   }
   filename=file_match(maybe_quote_filename(p_text)' -p',1);
   if (option!='N') {
      if (filename=='') {
         _text_box_error(nls("Could not find file %s",p_text));
         return(FILE_NOT_FOUND_RC);
      }
   }else{
#if 0
      if (!_ctloverwrite.p_value && filename!='') {
         result=_message_box(nls("File '%s' exists.\n\nOverwrite?",filename),
                             '',
                             MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result!=IDYES) {
            _set_focus();
            _set_sel(1,length(p_text)+1);
            return(1);
         }
      }
#endif
   }
   return(0);
}

struct DIFF_MERGE_INFO_T {
   _str basefilename;
   boolean diskbase;
   _str rev1filename;
   boolean disk1;
   _str rev2filename;
   boolean disk2;
   _str outputfilename;
   boolean overwriteoutput;
   boolean smart;
   boolean interleaved;
   boolean AutoMerge;
   boolean ShowChanges;
   boolean ForceConflict;
   boolean IgnoreSpaces;
};

static boolean MergeSetupBuffer()
{
   return(p_next.p_next.p_next.p_value!=0 &&
          p_next.p_next.p_next.p_enabled);
}

int _ctlok.lbutton_up()
{
   DIFF_MERGE_INFO_T temp;
   typeless status=_ctlbase.MergeCheckFilename();
   if (status) {
      return(status);
   }

   status=_ctlrev1.MergeCheckFilename();
   if (status) return(status);

   status=_ctlrev2.MergeCheckFilename();
   if (status) return(status);

   status=_ctloutput.MergeCheckFilename('N');
   if (status) return status;

   temp.diskbase=       !_ctlbase.MergeSetupBuffer();
   temp.basefilename=   strip(_ctlbase.p_text,'B','"');
   if (temp.diskbase) {
      temp.basefilename=   absolute(_ctlbase.p_text);
   }

   temp.disk1=          !_ctlrev1.MergeSetupBuffer();
   temp.rev1filename=   strip(_ctlrev1.p_text,'B','"');
   if (temp.disk1) {
      temp.rev1filename=   absolute(_ctlrev1.p_text);
   }

   temp.disk2=          !_ctlrev2.MergeSetupBuffer();
   temp.rev2filename=   strip(_ctlrev2.p_text,'B','"');
   if (temp.disk2) {
      temp.rev2filename=   absolute(_ctlrev2.p_text);
   }
   temp.outputfilename= absolute(strip(_ctloutput.p_text,'B','"'));
   //temp.overwriteoutput=_ctloverwrite.p_value!=0;
   temp.smart          =(_ctlsmart_merge.p_value!=0 && _ctlsmart_merge.p_enabled!=0);
   temp.interleaved    =_ctlinterleaved.p_value!=0;

   temp.AutoMerge=false;
   temp.ForceConflict=false;
   temp.ShowChanges=false;

   if (ctlautomerge.p_value) {
      temp.AutoMerge=true;
   }else if (ctlshowchanges.p_value) {
      temp.ShowChanges=true;
   }
   temp.IgnoreSpaces=ctlignorespaces.p_value!=0;

   status=DoubleCheckAllFilenames(temp.basefilename,temp.rev1filename,
                                  temp.rev2filename,temp.outputfilename);
   if (status) return(status);

   _param1=temp;
   p_active_form._save_form_response();
   p_active_form._delete_window(0);
   return(0);
}

static int DoubleCheckAllFilenames(_str basefilename,_str rev1filename,
                                   _str rev2filename,_str outputfilename)
{
   basefilename=maybe_quote_filename(basefilename);
   rev1filename=maybe_quote_filename(rev1filename);
   rev2filename=maybe_quote_filename(rev2filename);
   outputfilename=maybe_quote_filename(outputfilename);
   if (pos(' 'basefilename' ',' 'rev1filename' 'rev2filename' 'outputfilename,1,_fpos_case)) {
      _message_box(nls("You have used %s twice.",basefilename));
      return(1);
   }
   if (pos(' 'rev1filename' ',' 'basefilename' 'rev2filename' 'outputfilename,1,_fpos_case)) {
      _message_box(nls("You have used %s twice.",rev1filename));
      return(1);
   }
   if (pos(' 'rev2filename' ',' 'basefilename' 'rev1filename' 'outputfilename,1,_fpos_case)) {
      _message_box(nls("You have used %s twice.",rev2filename));
      return(1);
   }
   /*if (pos(' 'outputfilename' ',' 'basefilename' 'rev1filename' 'rev2filename,1,_fpos_case)) {
      _message_box(nls("You have used %s twice.",outputfilename));
      return(1);
   }*/
   return(0);
}

static _str OnDisk(boolean UseDisk=false,
                   boolean UseBufId=false,
                   boolean UseViewId=false)
{
   if (arg()>=3) {
      if (UseViewId) {
         return('+v');
      }
   }
   if (arg()>=2) {
      if (UseBufId) {
         return('+bi');
      }
   }
   if (UseDisk) {
      return('+d');
   }
   return('+b');
}

#define MERGE_BASE_IS_ID      0x1
#define MERGE_REV1_IS_ID      0x2
#define MERGE_REV2_IS_ID      0x4
#define MERGE_OUTPUT_IS_ID    0x8
#define MERGE_BASE_IS_VIEW   0x10
#define MERGE_REV1_IS_VIEW   0x20
#define MERGE_REV2_IS_VIEW   0x40
#define MERGE_OUTPUT_IS_VIEW 0x80

static int BuildFlags(boolean BaseIsID,boolean Rev1IsID,
                      boolean Rev2IsID,boolean OutputIsID,
                      boolean BaseIsViewID,boolean Rev1IsViewID,
                      boolean Rev2IsViewID,boolean OutputIsViewID)
{
   int flags=0;
   if (BaseIsID) {
      flags|=MERGE_BASE_IS_ID;
   }else if (BaseIsViewID) {
      flags|=MERGE_BASE_IS_VIEW;
   }
   if (Rev1IsID) {
      flags|=MERGE_REV1_IS_ID;
   }else if (Rev1IsViewID) {
      flags|=MERGE_REV1_IS_VIEW;
   }
   if (Rev2IsID) {
      flags|=MERGE_REV2_IS_ID;
   }else if (Rev2IsViewID) {
      flags|=MERGE_REV2_IS_VIEW;
   }
   if (OutputIsID) {
      flags|=MERGE_OUTPUT_IS_ID;
   }else if (OutputIsViewID) {
      flags|=MERGE_OUTPUT_IS_VIEW;
   }
   return(flags);
}

static void SelectModeBothViews(int OutputViewId1/*,int OutputViewId2*/,_str lang)
{
   int orig_view_id=p_window_id;
   p_window_id=OutputViewId1;
   _SetEditorLanguage(lang);
   p_window_id=orig_view_id;
}

static int GetEncodingFromView(int ViewId)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   int encoding=p_encoding;
   p_window_id=orig_view_id;
   return(encoding);
}

static boolean GetUTF8PropFromView(int ViewId)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   boolean utf8=p_UTF8;
   p_window_id=orig_view_id;
   return(utf8);
}

static void SetUTF8PropForView(int ViewId,boolean utf8)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   p_UTF8=utf8;
   p_window_id=orig_view_id;
}

static int MergeCheckEncodings(int BaseFileViewId,int Rev1ViewId,int Rev2ViewId)
{
   int Encoding1=GetEncodingFromView(BaseFileViewId);
   int Encoding2=GetEncodingFromView(Rev1ViewId);
   int Encoding3=GetEncodingFromView(Rev2ViewId);
   if (Encoding1!=Encoding2 ||
      Encoding2!=Encoding3) {
      _message_box(nls('All files must have the same encoding'));
      return(1);
   }
   return(0);
}

/*static int MergeCheckUnicode(int BaseFileViewId,int Rev1ViewId,int Rev2ViewId)
{
   boolean UTF8_1=GetUTF8PropFromView(BaseFileViewId);
   boolean UTF8_2=GetUTF8PropFromView(Rev1ViewId);
   boolean UTF8_3=GetUTF8PropFromView(Rev2ViewId);
   if (UTF8_1!=UTF8_2 ||
      UTF8_2!=UTF8_3) {
      _message_box(nls('Unicode files in 3-way merge is not supported for this release'));
      return(1);
   }
   return(0);
}*/

static void SetEncodingForView(int ViewId,int encoding)
{
   int orig_view_id=p_window_id;
   p_window_id=ViewId;
   p_encoding=encoding;
   p_window_id=orig_view_id;
}

static void MergeSetOutputEncoding(int BaseFileViewId, int OutputViewId1/*,OutputViewId2*/)
{
   int BaseEncoding=GetEncodingFromView(BaseFileViewId);
   boolean BaseUTF8=GetUTF8PropFromView(BaseFileViewId);
   SetEncodingForView(OutputViewId1,BaseEncoding);
   SetUTF8PropForView(OutputViewId1,BaseUTF8);
}

static int OpenAllViews(DIFF_MERGE_INFO_T mInfo,var BaseFileViewId,var Rev1ViewId,
                        var Rev2ViewId,var OutputViewId1,
                        var OutputExists,boolean BaseIsBuffer,
                        boolean Rev1IsBuffer,boolean Rev2IsBuffer,
                        boolean OutputIsBuffer,
                        int IDAndViewFlags)
{
   //Id changes in here
   int orig_view_id=p_window_id;
   int orig_wid=p_window_id;
   _str load_opts=OnDisk(mInfo.diskbase,(IDAndViewFlags&MERGE_BASE_IS_ID)!=0,(IDAndViewFlags&MERGE_BASE_IS_VIEW)!=0);
   if (load_opts=='+v') {
      load_opts='+bi 'mInfo.basefilename.p_buf_id;
   }
   // Put the +l at the beginning of the string in case we have a +b[i] option
   if (!pos(' +b ',' 'load_opts' ')) load_opts='+l 'load_opts;
   int status=_open_temp_view(mInfo.basefilename,BaseFileViewId,orig_view_id,load_opts);
   if (status) {
      _message_box(nls("Could not open file %s\n%s",mInfo.basefilename,get_message(status)));
      return(status);
   }
   if (pos(' +d ',' 'load_opts' ')) {
      // File was loaded from disk
      _SetEditorLanguage();
   }
   _diff_remove_nosave_lines();
   p_window_id=orig_view_id;
   load_opts=OnDisk(mInfo.disk1,(IDAndViewFlags&MERGE_REV1_IS_ID)!=0,(IDAndViewFlags&MERGE_REV1_IS_VIEW)!=0);
   if (load_opts=='+v') {
      load_opts='+bi 'mInfo.rev1filename.p_buf_id;
   }
   // Put the +l at the beginning of the string in case we have a +b[i] option
   load_opts='+l 'load_opts;
   if (!pos(' +b ',' 'load_opts' ')) load_opts='+l 'load_opts;
   status=_open_temp_view(mInfo.rev1filename,Rev1ViewId,orig_view_id,load_opts);
   if (status) {
      _message_box(nls("Could not open file %s\n%s",mInfo.rev1filename,get_message(status)));
      return(status);
   }
   if (pos(' +d ',' 'load_opts' ')) {
      // File was loaded from disk
      _SetEditorLanguage();
   }
   _diff_remove_nosave_lines();
   p_window_id=orig_view_id;
   load_opts=OnDisk(mInfo.disk2,(IDAndViewFlags&MERGE_REV2_IS_ID)!=0,(IDAndViewFlags&MERGE_REV2_IS_VIEW)!=0);
   if (load_opts=='+v') {
      load_opts='+bi 'mInfo.rev2filename.p_buf_id;
   }
   // Put the +l at the beginning of the string in case we have a +b[i] option
   if (!pos(' +b ',' 'load_opts' ')) load_opts='+l 'load_opts;
   status=_open_temp_view(mInfo.rev2filename,Rev2ViewId,orig_view_id,load_opts);
   if (status) {
      _message_box(nls("Could not open file %s\n%s",mInfo.rev2filename,get_message(status)));
      return(status);
   }
   if (pos(' +d ',' 'load_opts' ')) {
      // File was loaded from disk
      _SetEditorLanguage();
   }
   _diff_remove_nosave_lines();
   p_window_id=orig_view_id;
   if ( MergeCheckEncodings(BaseFileViewId,Rev1ViewId,Rev2ViewId) ) {
      p_window_id=orig_view_id;
      _delete_temp_view(BaseFileViewId);
      _delete_temp_view(Rev1ViewId);
      _delete_temp_view(Rev2ViewId);
      return(1);
   }
   //Do not give this buffer a name right now...
   if (orig_view_id=='') return(INSUFFICIENT_MEMORY_RC);//We are in BAD shape
   p_window_id=orig_view_id;

   int temp_view_id=0;
   int junk_view_id=0;
   OutputExists=1;
   //def_load_options' +q +c +b 'mInfo.outputfilename);
   if (OutputIsBuffer) {
      //status=1;
      if (IDAndViewFlags&MERGE_OUTPUT_IS_VIEW) {
         status=_open_temp_view('',temp_view_id,junk_view_id,def_load_options' +bi 'mInfo.outputfilename.p_buf_id);
      }else if (IDAndViewFlags&MERGE_OUTPUT_IS_ID) {
         status=_open_temp_view('',temp_view_id,junk_view_id,def_load_options' +bi 'mInfo.outputfilename);
      }else{
         status=_open_temp_view(mInfo.outputfilename,temp_view_id,junk_view_id,def_load_options' +b');
      }
      if (status) {
         _message_box(nls("Could not open file '%s'\n\n%s",mInfo.outputfilename,get_message(status)));
         return(status);
      }
   }else{
      _str output_on_disk_option='';
      if (file_eq(mInfo.outputfilename,mInfo.basefilename)
          || file_eq(mInfo.outputfilename,mInfo.rev1filename)
          || file_eq(mInfo.outputfilename,mInfo.rev2filename)
          ) {
         output_on_disk_option='+d';
      }
      status=_open_temp_view(mInfo.outputfilename,temp_view_id,junk_view_id,def_load_options' 'output_on_disk_option);
      if (status) {
         status=_open_temp_view(mInfo.outputfilename,temp_view_id,junk_view_id,def_load_options' +t ');
         if (status) {
            _message_box(nls("Could not open file '%s'\n\n%s",mInfo.outputfilename,get_message(status)));
            return(status);
         }
      }
      OutputExists=0;
      OutputViewId1=temp_view_id;
   }
   _diff_remove_nosave_lines();
   if (status) {
      OutputExists=0;
      orig_view_id=_create_temp_view(OutputViewId1);
      if (orig_view_id=='') return(INSUFFICIENT_MEMORY_RC);//We are in BAD shape
      if (OutputIsBuffer) {
         p_DocumentName=mInfo.outputfilename;
      }else{
         p_buf_name=absolute(mInfo.outputfilename);
      }
   }else{
      delete_all();
      OutputViewId1=p_window_id;
      int undo_steps=p_undo_steps;
      p_undo_steps=0;
      p_undo_steps=undo_steps;
      if (!OutputIsBuffer) {
         p_buf_name=absolute(mInfo.outputfilename);
      }
   }
   MergeSetOutputEncoding(BaseFileViewId,OutputViewId1);
   _str OutputLanguage=p_LangId;

   p_window_id=OutputViewId1;
   _str BaseFilenameFromBuffer='';

   if (OutputLanguage!='') {
      SelectModeBothViews(OutputViewId1,OutputLanguage);
   }else{
      p_window_id=BaseFileViewId;
      OutputLanguage=p_LangId;
      BaseFilenameFromBuffer=p_buf_name;
      if (OutputLanguage!='') {
         SelectModeBothViews(OutputViewId1,OutputLanguage);
      }else{
         OutputLanguage=_get_extension(BaseFilenameFromBuffer);
         if (OutputLanguage!='') {
            SelectModeBothViews(OutputViewId1,OutputLanguage);
         }
      }
   }
   _str bufname=p_buf_name;
   docname=p_DocumentName;

   //Now go back and give the first buffer a name
   p_window_id=OutputViewId1;
   p_window_id=orig_view_id;
   p_window_id=orig_wid;
   return(0);
}

struct BUFFER_INFO_T {
   int buf_flags;
   int inmem;
};

static BUFFER_INFO_T BufferInfoArray[];

#define MERGE_SMART              0x01
#define MERGE_DIALOG_OUTPUT      0x02
#define MERGE_INTERLEAVED_OUTPUT 0x04
#define MERGE_FORCE_CONFLICT     0x08
#define MERGE_SHOW_CHANGES       0x10
#define MERGE_IGNORE_ALL_SPACES  0x20
#define MERGE_DETECT_CONFLICT    0x40

static void SetUndoSteps()
{
   _str list = def_load_options;
   list=lowcase(list);
   typeless undosteps=0;
   for (;;) {
      _str cur=parse_file(list);
      if (cur=='') break;
      if (substr(cur,2,2)=='u:') {
         parse cur with 'u:' undosteps;
      }
   }
   p_undo_steps=undosteps;
}

#define BUTTON_CHEAT_WIDTH 200

static void DiffSetDialogFont(int fontIndex=CFG_DIFF_EDITOR_WINDOW)
{
   _str font_name='';
   typeless font_size=10;
   typeless font_flags=0;
   parse _default_font(fontIndex) with font_name','font_size','font_flags','.;
   int font_bold=font_flags&F_BOLD;
   int font_italic=font_flags&F_ITALIC;
   int font_strike_thru=font_flags&F_STRIKE_THRU;
   int font_underline=font_flags&F_UNDERLINE;

   _nocheck _control _ctlfile1,_ctlfile2;
   // Turn off redraw so we are not recalculating the world on every
   // little font change.
   _ctlfile1.p_redraw=_ctlfile2.p_redraw=false;
   _ctlfile1.p_font_name=font_name;
   _ctlfile2.p_font_name=font_name;
   _ctlfile1.p_font_size=_ctlfile2.p_font_size=font_size;
   _ctlfile1.p_font_bold=_ctlfile2.p_font_bold=font_bold != 0;
   _ctlfile1.p_font_italic=_ctlfile2.p_font_italic=font_italic != 0;
   _ctlfile1.p_font_strike_thru=_ctlfile2.p_font_strike_thru=font_strike_thru != 0;
   _ctlfile1.p_redraw=_ctlfile2.p_redraw=true;
}

#define CONFLICT_PREFIX_RE '^\*\*\*\*\*\*\* Conflict'

/**
 * Displays 3 Way Merge Setup dialog box.  A 3 Way Merge is typically used 
 * after two people make a local copy of the same source file and make some 
 * modifications to their local copy.   A 3 Way Merge very cleverly takes both 
 * sets of changes and creates an new source file.   If there are any conflicts 
 * (because they edited the same area of code), a dialog box is displayed which 
 * lets you select whose change you want in the output file.  Our 3 Way Merge 
 * lets you edit the output file without exiting 3 Way Merge mode.
 *
 * <P>Command line usage:
 *    merge [options] &lt;base&gt; &lt;rev1&gt; &lt;rev2&gt; &lt;out&gt;
 * <P>Command line options(case insensitive):
 * <UL>
 * <LI>   -bb                     - Base is a buffer name and should be loaded +b w/o absolute
 * <LI>   -bbi                    - Base is a buffer id and should be loaded +b w/o absolute
 * <LI>   -b1                     - rev1 is a buffer name and should be loaded +b w/o absolute
 * <LI>   -b1i                    - rev1 is a buffer id and should be loaded +b w/o absolute
 * <LI>   -b2                     - rev2 is a buffer name and should be loaded +b w/o absolute
 * <LI>   -b2i                    - rev2 is a buffer id and should be loaded +b w/o absolute
 * <LI>   -bout                   - output is a buffer name, and should not be deleted when
 *                              the merge dialog is closed(saved for the user).
 * <LI>   -bouti                  - output is a buffer id, and should not be deleted when
 *                              the merge dialog is closed(saved for the user).
 * <LI>   -smart                  - same as the "use smart merge" button on the dialog
 *                              (uses the diff to try to resolve some conflicts)
 * <LI>   -interleaved            - same as turning on "interleaved output" on dialog
 * <LI>   -q                      - quiet option:only shuts off "Merge complete x
 *                              conflicts" message
 * <LI>   -callersaves            - If this option is used, the file is not actually
 *                              saved after the user is prompted.  A 1 is returned
 *                              if the user chose to save the file.  Returns 2
 *                              if the user chose not to save the file.
 * 
 * @return If successful, returns: 1 if there were conflicts. if callersaves 
 *    option is specified, returns 1 or 2. 0 if no conflicts.  Otherwise, a 
 *    negative error code is returned.
 * 
 *    Note that "successful" implies nothing about the number of differences
 *    between the files, just that all files were loaded successfully,
 *    and the merge engine ran succesfully.
 * 
 * @see diff
 * 
 * @categories Buffer_Functions, File_Functions
 */
_command int merge(_str arg1='') name_info(FILE_ARG'*,'VSARG2_EDITORCTL)
{
   DIFF_MISC_INFO misc;
   InitMiscDiffInfo(misc,'merge');
   if (p_window_id==_mdi) {
      p_window_id=_mdi.p_child;
   }
   int real_orig_view_id=p_window_id;
   DIFF_MERGE_INFO_T mInfo;
   boolean BaseIsBuffer=false,Rev1IsBuffer=false,Rev2IsBuffer=false,
           Quiet=false,CallerSaves=false,
           BaseIsID=false,Rev1IsID=false,Rev2IsID=false,OutputIsID=false ;
   int OutputIsBuffer=-1;
   boolean UseGlobal=false;
   boolean BaseIsViewId=false,
           Rev1IsViewId=false,
           Rev2IsViewId=false,
           OutputIsViewId=false;
   boolean IndividualConflictUndo=false;
   boolean saveOutput = false;
   boolean detectConflictsOnly = false;

   _str Copy1Caption="Copy &1>>";;
   _str Copy2Caption="Copy &2>>";;
   _str Copy1AllCaption="Copy 1 All>>";;
   _str Copy2AllCaption="Copy 2 All>>";;
   _str ImaginaryLineCaption=null;
   _str saveCallback=null;

   boolean ForceConflict=false;
   boolean ShowChanges=false;
   MERGE_DIALOG_INFO DialogInfo=null;
   DialogInfo.BaseDocname='';
   DialogInfo.Rev1Docname='';
   DialogInfo.Rev2Docname='';
   DialogInfo.OutputDocName='';
   boolean editoutput=true;
   _str option='';
   _str basefilename='';
   typeless status=0;
   if (arg1=='') {
      status=show('-modal _merge_setup_form');
      if (status) {
         return(status);
      }
      mInfo=_param1;
   }else{
      mInfo.smart=false;
      mInfo.interleaved=false;
      mInfo.AutoMerge=false;
      mInfo.ShowChanges=false;
      mInfo.ForceConflict=false;
      mInfo.IgnoreSpaces=false;
      for (;;) {
         basefilename=parse_file(arg1);
         if (substr(basefilename,1,1)!='-') {
            break;
         }
         option=lowcase(substr(basefilename,2));
         if (option=='bb') {
            BaseIsBuffer=true;
         }else if (option=='b1') {
            Rev1IsBuffer=true;
         }else if (option=='b2') {
            Rev2IsBuffer=true;
         }else if (option=='bout') {
            OutputIsBuffer=1;
         }else if (option=='bbi') {
            BaseIsBuffer=true;
            BaseIsID=true;
         }else if (option=='bv') {
            BaseIsBuffer=true;
            BaseIsViewId=true;
         }else if (option=='b1i') {
            Rev1IsBuffer=true;
            Rev1IsID=true;
         }else if (option=='b1v') {
            Rev1IsBuffer=true;
            Rev1IsViewId=true;
         }else if (option=='b2i') {
            Rev2IsBuffer=true;
            Rev2IsID=true;
         }else if (option=='b2v') {
            Rev2IsBuffer=true;
            Rev2IsViewId=true;
         }else if (option=='bouti') {
            OutputIsBuffer=1;
            OutputIsID=true;
         }else if (option=='boutv') {
            OutputIsBuffer=1;
            OutputIsViewId=true;
         }else if (option=='interleaved') {
            mInfo.interleaved=true;
         }else if (option=='smart') {
            mInfo.smart=true;
         }else if (option=='quiet') {
            Quiet=true;
         }else if (option=='callersaves') {
            CallerSaves=true;
         }else if (option=='savecallback') {
            saveCallback=parse_file(arg1);
         }else if (option=='forceconflict') {
            ForceConflict=true;
         }else if (option=='showchanges') {
            ShowChanges=true;
         }else if (option=='copy1caption') {
            Copy1Caption=parse_file(arg1);
         }else if (option=='copy2caption') {
            Copy2Caption=parse_file(arg1);
         }else if (option=='copy1allcaption') {
            Copy1AllCaption=parse_file(arg1);
         }else if (option=='copy2allcaption') {
            Copy2AllCaption=parse_file(arg1);
         }else if (option=='individualundo') {
            IndividualConflictUndo=true;
         }else if (option=='ignorespaces') {
            mInfo.IgnoreSpaces=true;
         }else if (option=='imaginarylinecaption') {
            ImaginaryLineCaption=strip(parse_file(arg1),'B','"');
         }else if (option=='basefilecaption') {
            DialogInfo.BaseDocname=parse_file(arg1);
            DialogInfo.BaseDocname=strip(DialogInfo.BaseDocname,'B','"');
         }else if (option=='rev1filecaption') {
            DialogInfo.Rev1Docname=parse_file(arg1);
            DialogInfo.Rev1Docname=strip(DialogInfo.Rev1Docname,'B','"');
         }else if (option=='rev2filecaption') {
            DialogInfo.Rev2Docname=parse_file(arg1);
            DialogInfo.Rev2Docname=strip(DialogInfo.Rev2Docname,'B','"');
         }else if (option=='outputfilecaption') {
            DialogInfo.OutputDocName=parse_file(arg1);
            DialogInfo.OutputDocName=strip(DialogInfo.OutputDocName,'B','"');
         }else if (option=='dialogtitle') {
            DialogInfo.DialogTitle=parse_file(arg1);
            DialogInfo.DialogTitle=strip(DialogInfo.DialogTitle,'B','"');
         }else if (option=='noeditoutput') {
            editoutput=false;
         }else if (option=='saveoutput') {
            saveOutput=true;
         }else if (option=='detectconflictsonly') {
            detectConflictsOnly=true;
         }else if (option=='useglobaldata') {
            UseGlobal=true;
            if (gMergeSetupData.BaseFilename!='') {
               mInfo.basefilename=gMergeSetupData.BaseFilename;
            }
            if (gMergeSetupData.BaseIsBuffer) {
               BaseIsBuffer=true;
            }
            if (gMergeSetupData.BaseBufferId>-1) {
               BaseIsBuffer=true;
               BaseIsID=true;
               mInfo.basefilename=gMergeSetupData.BaseBufferId;
            }
            if (gMergeSetupData.BaseViewId) {
               BaseIsViewId=true;
               mInfo.basefilename=gMergeSetupData.BaseViewId;
            }
            mInfo.diskbase=!BaseIsBuffer;


            if (gMergeSetupData.Rev1Filename!='') {
               mInfo.rev1filename=gMergeSetupData.Rev1Filename;
            }
            if (gMergeSetupData.Rev1IsBuffer) {
               Rev1IsBuffer=true;
            }
            if (gMergeSetupData.Rev1BufferId>-1) {
               Rev1IsBuffer=true;
               Rev1IsID=true;
            }
            if (gMergeSetupData.Rev1ViewId) {
               Rev1IsViewId=true;
               mInfo.rev1filename=gMergeSetupData.Rev1ViewId;
            }
            mInfo.disk1=!Rev1IsBuffer;


            if (gMergeSetupData.Rev2Filename!='') {
               mInfo.rev2filename=gMergeSetupData.Rev2Filename;
            }
            if (gMergeSetupData.Rev2IsBuffer) {
               Rev2IsBuffer=true;
            }
            if (gMergeSetupData.Rev2ViewId) {
               Rev2IsViewId=true;
               mInfo.rev2filename=gMergeSetupData.Rev2ViewId;
            }
            mInfo.disk2=!Rev2IsBuffer;


            if (gMergeSetupData.OutputFilename!='') {
               mInfo.outputfilename=gMergeSetupData.OutputFilename;
            }
            if (gMergeSetupData.OutputIsBuffer) {
               OutputIsBuffer=1;
            }
            if (gMergeSetupData.OutputBufferId>-1) {
               OutputIsBuffer=1;
               OutputIsViewId=true;
            }
            if (gMergeSetupData.OutputViewId) {
               OutputIsBuffer=1;
               OutputIsViewId=true;
               mInfo.outputfilename=gMergeSetupData.OutputViewId;
            }


            mInfo.overwriteoutput=true;
            if (gMergeSetupData.Smart) {
               mInfo.smart=true;
            }
            if (gMergeSetupData.Interleaved) {
               mInfo.interleaved=true;
            }
            if (gMergeSetupData.Quiet) {
               Quiet=true;
            }
            if (gMergeSetupData.CallerSaves) {
               CallerSaves=true;
            }
            if (gMergeSetupData.ForceConflict) {
               ForceConflict=true;
            }
            if (gMergeSetupData.ShowChanges) {
               ShowChanges=true;
            }
            if (gMergeSetupData.Copy1Caption!='') {
               Copy1Caption=gMergeSetupData.Copy1Caption;
            }
            if (gMergeSetupData.Copy2Caption!='') {
               Copy2Caption=gMergeSetupData.Copy2Caption;
            }
            if (gMergeSetupData.IndividualConflictUndo) {
               IndividualConflictUndo=true;
            }
            if (gMergeSetupData.Copy1AllCaption!='') {
               Copy1AllCaption=gMergeSetupData.Copy1AllCaption;
            }
            if (gMergeSetupData.Copy2AllCaption!='') {
               Copy2AllCaption=gMergeSetupData.Copy2AllCaption;
            }
            if (gMergeSetupData.IgnoreSpaces) {
               mInfo.IgnoreSpaces=true;
            }
            if (gMergeSetupData.ImaginaryLineCaption!=null) {
               ImaginaryLineCaption=gMergeSetupData.ImaginaryLineCaption;
            }
         }
      }
      if (!UseGlobal) {
         mInfo.basefilename=basefilename;
         mInfo.diskbase=!BaseIsBuffer;
         if (mInfo.diskbase) {
            mInfo.basefilename=absolute(mInfo.basefilename);
          }else{
            mInfo.basefilename=strip(mInfo.basefilename,'B','"');
         }

         mInfo.rev1filename=parse_file(arg1);
         mInfo.disk1=!Rev1IsBuffer;
         if (mInfo.disk1) {
            mInfo.rev1filename=absolute(mInfo.rev1filename);
         }else{
            mInfo.rev1filename=strip(mInfo.rev1filename,'B','"');
         }

         mInfo.rev2filename=parse_file(arg1);
         mInfo.disk2=!Rev2IsBuffer;
         if (mInfo.disk2) {
            mInfo.rev2filename=absolute(mInfo.rev2filename);
         }else{
            mInfo.rev2filename=strip(mInfo.rev2filename,'B','"');
         }

         mInfo.outputfilename=parse_file(arg1);
         if (OutputIsBuffer) {
            mInfo.outputfilename=strip(mInfo.outputfilename,'B','"');
         }
         if (mInfo.basefilename==''||mInfo.rev1filename==''||mInfo.rev2filename==''||
             mInfo.outputfilename=='') {
            message('usage:merge [-bb] [-b1] [-b2] [-bout] <basefile> <rev1> <rev2> <outputfilename>');
            return(INVALID_ARGUMENT_RC);
         }
         mInfo.overwriteoutput=true;//Should be a nonexistent temp file - should not matter
         //mInfo.diskbase=mInfo.disk1=true;
         //if vc merge, want to be sure that we get the file in memory if there is one
         //mInfo.disk2=buf_match(absolute(mInfo.rev2filename),1)=='';
      }
   }
   int BaseFileViewId,Rev1ViewId,Rev2ViewId,OutputViewId;

   if (OutputIsBuffer<0) {
      _str afilename=absolute(mInfo.outputfilename);
      _str match=buf_match(afilename,1,'E');
      OutputIsBuffer=(int)(match!='');
   }
   typeless OutputExists=0;
   status=_mdi.OpenAllViews(mInfo,BaseFileViewId,Rev1ViewId,Rev2ViewId,OutputViewId,
                            OutputExists,BaseIsBuffer,Rev1IsBuffer,Rev2IsBuffer,OutputIsBuffer!=0,
                            BuildFlags(BaseIsID,Rev1IsID,Rev2IsID,OutputIsID,
                                       BaseIsViewId,Rev1IsViewId,Rev2IsViewId,OutputIsViewId)
                            );
   if (status) {
      return(status);
   }

   int cvid=0;
   _str BaseDocname='';
   _str OutputDocName='';
   if (BaseIsID||BaseIsViewId) {
      cvid=p_window_id;
      p_window_id=BaseFileViewId;
      BaseDocname=p_DocumentName;
      p_window_id=cvid;
   }
   if (BaseDocname=='') {
      BaseDocname='Base';
   }
   if (OutputIsID||OutputIsViewId) {
      cvid=p_window_id;
      p_window_id=OutputViewId;
      OutputDocName=p_DocumentName;
      p_window_id=cvid;
   }
   if (OutputDocName=='') {
      OutputDocName='Output';
   }
   _str Rev1Docname='';
   if (Rev1IsID||Rev1IsViewId) {
      cvid=p_window_id;
      p_window_id=Rev1ViewId;
      Rev1Docname=p_DocumentName;
      p_window_id=cvid;
   }else{
      Rev1Docname=mInfo.rev1filename;
   }
   if (Rev1Docname=='') {
      Rev1Docname='Revision 1';
   }
   _str Rev2Docname='';
   if (Rev2IsID||Rev2IsViewId) {
      cvid=p_window_id;
      p_window_id=Rev2ViewId;
      Rev2Docname=p_DocumentName;
      p_window_id=cvid;
   }else{
      Rev2Docname=mInfo.rev2filename;
   }
   if (Rev2Docname=='') {
      Rev2Docname='Revision 2';
   }

   mou_hour_glass(1);
   int flags=0;
   if (mInfo.smart) flags|=MERGE_SMART;
   if (mInfo.interleaved) {
      flags|=MERGE_INTERLEAVED_OUTPUT;
   }else{
      flags|=MERGE_DIALOG_OUTPUT;
   }
   if (mInfo.IgnoreSpaces) {
      flags|=MERGE_IGNORE_ALL_SPACES;
   }
   if (ForceConflict || mInfo.ForceConflict) {
      flags|=MERGE_FORCE_CONFLICT;
   }else if (ShowChanges || mInfo.ShowChanges) {
      flags|=MERGE_SHOW_CHANGES;
   }
   if ( detectConflictsOnly ) {
      flags |= MERGE_DETECT_CONFLICT;
      Quiet = 1;
      editoutput = false;
   }
   MERGE_CONFLICT_INFO ConflictInfo;
   int ConflictArray[];
   ConflictInfo.NumResolved=0;
   _str BaseLineMatches[];
   MERGE_PIC_INFO Pics[]=null;
   int PicType;
   status = MergeFiles(BaseFileViewId,Rev1ViewId,Rev2ViewId,OutputViewId,
                       flags,ConflictInfo.ConflictArray,BaseLineMatches,ImaginaryLineCaption,Pics,
                       PicType);
   int num_conflicts=MergeNumConflicts();
   int num_show_changes=MergeNumShowChanges();
   if (flags&MERGE_INTERLEAVED_OUTPUT ||
       (!num_conflicts && !num_show_changes)) {
      if (!editoutput) {
         if ( saveOutput ) {
            // This is a case we hit from shelving, we don't want to edit the 
            // output, but we want to be sure that the output is saved.
            OutputViewId.save();
         }
         if (!OutputIsBuffer) {
            _delete_temp_view(OutputViewId);
         }
         DiffFreeAllColorInfo(Rev1ViewId.p_buf_id);
         DiffFreeAllColorInfo(Rev2ViewId.p_buf_id);
      }else{
         edit('+bi 'OutputViewId.p_buf_id);
         if ( _default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE || saveOutput ) {
            // If the editor is not visible, we are being run from vsmerge,
            // so we have to save the file
            save();
         }
         p_buf_flags&=~VSBUFFLAG_HIDDEN;
         if (!OutputIsViewId) {
            int orig_view_id=p_window_id;
            p_window_id=OutputViewId;
            _delete_window();
            p_window_id=orig_view_id;
         }
      }
      _LineMarkerRemoveAllType(PicType);
      if (!num_conflicts && !Quiet) {
         _message_box(nls("No conflicts detected"));
      }else if (flags&MERGE_INTERLEAVED_OUTPUT) {
         top();
         status=search(CONFLICT_PREFIX_RE,'@rh');
      }
   }else{
      if ( !detectConflictsOnly ) {
         status=MergeDialog(BaseFileViewId,Rev1ViewId,Rev2ViewId,OutputViewId,BaseLineMatches,
                            DialogInfo,Pics,ConflictInfo.ConflictArray,CallerSaves,Quiet,saveCallback);
         _LineMarkerRemoveAllType(PicType);
         if (!OutputIsBuffer) {
            // Be sure this buffer gets deleted
            // If the same buffer is used for base/revison and output the hidden
            // flags seems to get shut off somewhere.
            int orig_view_id=p_window_id;
            p_window_id=OutputViewId;
            p_buf_flags|=VSBUFFLAG_HIDDEN;
            p_window_id=orig_view_id;
         }
         _delete_temp_view(OutputViewId);
      } else {
         DiffFreeAllColorInfo(Rev1ViewId.p_buf_id);
         DiffFreeAllColorInfo(Rev2ViewId.p_buf_id);
      }
   }
   _delete_temp_view(BaseFileViewId);
   _delete_temp_view(Rev1ViewId);
   _delete_temp_view(Rev2ViewId);
   return(status);
}

/**
 * 
 * @param baseFilename 
 * @param rev1Filename 
 * @param rev2Filename 
 * 
 * @return int 1 if a coflict exists, 0 if a conflict does not 
 *         exist, <0 for another error (probably an error
 *         loading a file)
 */
int conflictExists(int baseWID,_str rev1WID,_str rev2WID)
{
   origWID := _create_temp_view(auto tempWID);
   p_window_id = origWID;
   status := merge('-detectConflictsOnly -bv -b1v -b2v -boutv 'baseWID' 'rev1WID' 'rev2WID' 'tempWID);
   _delete_temp_view(tempWID);
   return status;
}
