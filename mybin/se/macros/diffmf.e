////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50120 $
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
#import "ccode.e"
#import "diff.e"
#import "diffedit.e"
#import "diffinsertsym.e"
#import "diffprog.e"
#import "difftags.e"
#import "dlgman.e"
#import "fileman.e"
#import "files.e"
#import "guiopen.e"
#import "ini.e"
#import "listproc.e"
#import "main.e"
#import "mprompt.e"
#import "project.e"
#import "restore.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

defeventtab _difftree_output_form;

/*
10:59am 5/27/1998
TreeUserInfo for treenodes is in the following format:

binarydatestring<ascii1>[manually hidden flag]

if "manually hidden flag" is 1, this node was manually hidden by the user.
Otherwise, it can be ''.

*/
#define GExcludeFilespecList ctlclose.p_user
#define GPath1               tree1.p_user
#define GPath2               tree2.p_user
#define GRecursive           ctlleft.p_user
#define GModified            ctlright.p_user
#define GNoOnChange          ctlcopy_right.p_user
#define GReportInfo          ctlcopy_left.p_user
#define GNumHidden           ctlnext_mismatch.p_user
#define GChildDiffInfoList   ctlprev_mismatch.p_user
#define GShowNoEditorOptions ctlrefresh.p_user
#define GOEMMode             ctloptions.p_user

// Indexes for _SetDialogInfo and _GetDialogInfo
#define RESTORE_FROM_INI     0
#define FILESPEC_LIST        1

struct REPORT_INFO {
   int action;
   _str time;
   _str data1,
        data2,
        data3,
        data4;
};

/*
DIFF_REPORT_CREATED          data2=path1 data3=path2 data4=filespecs
DIFF_REPORT_LOADED           data1=filename data2=path1 data3=path2 data4=filespecs
DIFF_REPORT_DIFF             data1=filename1 data2=filename2 data3-4 unused
DIFF_REPORT_FILE_CHANGE      data1=filename1 data3-4 unused

DIFF_REPORT_COPY_FILE        data1=sourceFilename data2=destFilename data3-4 unused
DIFF_REPORT_COPY_TREE        data1=path1 data2=path2 data3-4 unused
DIFF_REPORT_COPY_TREE_FILE   data1=sourceFilename data2=destFilename data3-4 unused

DIFF_REPORT_DELETE_FILE      data1=filename
DIFF_REPORT_DELETE_TREE      data1=path1 data2-4 unused
DIFF_REPORT_DELETE_TREE_FILE data1=Filename data2-4 unused

//not going to use these right now
DIFF_REPORT_SAVED_DIFF_STATE data1=filename data2-data4 unused
DIFF_REPORT_SAVED_PATH1_LIST data1=path(from diff) data2=filename
DIFF_REPORT_SAVED_PATH2_LIST data1=path(from diff) data2=filename data3-4 unused

DIFF_REPORT_REFRESH_CHANGED   data1-4 unused
DIFF_REPORT_REFRESH_ALL       data1-4 unused
*/
void _AppendToDiffReport(int action,
                    _str data1='',_str data2='',
                    _str data3='',_str data4='')
{
   if ( data4==null ) {
      data4='';
   }
   REPORT_INFO Report[];
   Report=GReportInfo;
   int len=0;
   if (Report._varformat()==VF_ARRAY) {
      len=Report._length();
   }
   Report[len].action=action;
   Report[len].time=_time();
   Report[len].data1=maybe_quote_filename(data1);
   Report[len].data2=maybe_quote_filename(data2);
   Report[len].data3=maybe_quote_filename(data3);
   Report[len].data4=maybe_quote_filename(data4);
   GReportInfo=Report;
}

static void GenerateReport()
{
   REPORT_INFO Report[];
   Report=GReportInfo;
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   _delete_line();
   int i,len=Report._length();
   for (i=0;i<len;++i) {
      REPORT_INFO *pCur=&Report[i];
      //time=_time()':'
      _str line=pCur->time':';
      switch (pCur->action) {
      case DIFF_REPORT_CREATED:
         line=line:+'Started diff of 'pCur->data1' and 'pCur->data2;
         insert_line(line);
         line=substr('',1,length(pCur->time)):+'Filespecs='pCur->data3;
         insert_line(line);
         break;
      case DIFF_REPORT_LOADED:
         line=line:+'Loaded diff of 'pCur->data2' and 'pCur->data3' from 'pCur->data1;
         insert_line(line);
         line=substr('',1,length(pCur->time)):+'Filespecs='pCur->data4;
         insert_line(line);
         break;
      case DIFF_REPORT_DIFF:
         line=line:+'Diffed 'pCur->data1' and 'pCur->data2;
         insert_line(line);
         break;
      case DIFF_REPORT_FILE_CHANGE:
         line=line:+pCur->data1' changed during diff';
         insert_line(line);
         break;
      case DIFF_REPORT_COPY_FILE:
         line=line:+'Copied 'pCur->data1' to 'pCur->data2;
         insert_line(line);
         break;
      case DIFF_REPORT_COPY_TREE:
         line=line:+'Copying tree 'pCur->data1' to 'pCur->data2;
         insert_line(line);
         break;
      case DIFF_REPORT_COPY_TREE_FILE  :
         line=line:+'Copied 'pCur->data1' to 'pCur->data2' during tree copy';
         insert_line(line);
         break;
      case DIFF_REPORT_DELETE_FILE:
         line=line:+'Deleted 'pCur->data1;
         insert_line(line);
         break;
      case DIFF_REPORT_DELETE_TREE:
         line=line:+'Deleting tree 'pCur->data1;
         insert_line(line);
         break;
      case DIFF_REPORT_DELETE_TREE_FILE:
         line=line:+'Deleted 'pCur->data1' during tree delete';
         insert_line(line);
         break;
      case DIFF_REPORT_REFRESH_CHANGED:
         line=line:+'Refreshed modified files';
         insert_line(line);
         break;
      case DIFF_REPORT_REFRESH_ALL:
         line=line:+'Refreshed all files';
         insert_line(line);
         break;
      }
   }
   int bid=p_buf_id;
   p_modify=0;
   p_window_id=orig_view_id;
   show('-modal _showbuf_form',bid,'Multi-File Diff Report','S');
   p_active_form._set_foreground_window();
   _delete_temp_view(temp_view_id);
}

#define DEFAULT_DIFF_VIEW_OPTIONS DIFF_VIEW_DIFFERENT_FILES|DIFF_VIEW_VIEWED_FILES|DIFF_VIEW_MISSING_FILES1|DIFF_VIEW_MISSING_FILES2

defload()
{
   if (_pic_file_match<=0) {
      _pic_file_match=_update_picture(-1,'_filemch.ico');
      if (_pic_file_match>0) {
         set_name_info(_pic_file_match,"These files match");
      }
   }
   if (_pic_filed<=0) {
      _pic_filed=_update_picture(-1,'_diffd.ico');
      if (_pic_filed>0) {
         set_name_info(_pic_filed,"These files are different");
      }
   }
   if (_pic_filed2<=0) {
      _pic_filed2=_update_picture(-1,'_diffd2.ico');
      if (_pic_filed2>0) {
         set_name_info(_pic_filed2,"These files are different, but you have viewed them");
      }
   }


   if (_pic_symbol<=0) {
      _pic_symbol=_update_picture(-1,'_symbolmch.ico');
      if (_pic_symbol>0) {
         set_name_info(_pic_symbol,"These symbols match");
      }
   }
   if (_pic_symbold<=0) {
      _pic_symbold=_update_picture(-1,'_symbold.ico');
      if (_pic_symbold>0) {
         set_name_info(_pic_symbold,"These symbols are different");
      }
   }
   if (_pic_symbold2<=0) {
      _pic_symbold2=_update_picture(-1,'_symbold2.ico');
      if (_pic_symbold2>0) {
         set_name_info(_pic_symbold2,"These symbols are different, but you have viewed them");
      }
   }


   if (_pic_filem<=0) {
      _pic_filem=_update_picture(-1,'_diffm.ico');
      if (_pic_filem>0) {
         set_name_info(_pic_filem,"This file does not exist");
      }
   }
   if (_pic_filep<=0) {
      _pic_filep=_update_picture(-1,'_diffp.ico');
      if (_pic_filep>0) {
         set_name_info(_pic_filep,"This file only exists in this path");
      }
   }
   if (_pic_symbolm<=0) {
      _pic_symbolm=_update_picture(-1,'_symbolm.ico');
      if (_pic_symbolm>0) {
         set_name_info(_pic_symbolm,"This symbol does not exist");
      }
   }
   if (_pic_symbolp<=0) {
      _pic_symbolp=_update_picture(-1,'_symbolp.ico');
      if (_pic_symbolp>0) {
         set_name_info(_pic_symbolp,"This symbol only exists in this path");
      }
   }
   if (_pic_fldopenp<=0) {
      _pic_fldopenp=_update_picture(-1,'_diffopp.ico');
      if (_pic_fldopenp>0) {
         set_name_info(_pic_fldopenp,"This directory only exists in this path");
      }
   }
   if (_pic_fldopenm<=0) {
      _pic_fldopenm=_update_picture(-1,'_diffopm.ico');
      if (_pic_fldopenm>0) {
         set_name_info(_pic_fldopenm,"This directory does not exist");
      }
   }
   if (_pic_symbolmoved<=0) {
      _pic_symbolmoved=_update_picture(-1,'_diffmoved.ico');
      if (_pic_symbolmoved>0) {
         set_name_info(_pic_symbolmoved,"These symbols match, but have moved");
      }
   }
   rc=0;
}

void _difftree_output_form.on_resize()
{
   boolean oldcopy=ctlcopy_right.p_visible;
   ctlleft.p_visible=ctlright.p_visible=0;
   ctlcopy_right.p_visible=ctlcopy_left.p_visible=0;
   int xbuff=tree1.p_x;
   tree1.p_width=(_dx2lx(SM_TWIP,p_active_form.p_client_width) intdiv 2)-xbuff;
   tree2.p_x=tree1.p_x+tree1.p_width+_twips_per_pixel_x();
   ctlpath2label.p_x=tree2.p_x;
   tree2.p_width=tree1.p_width;
   int formheight=_dy2ly(SM_TWIP,p_active_form.p_client_height);

   //10:42am 5/13/1998
   //Too much flicker turning all controls on and off, so just do the ones that
   //get "overwritten"
   //ctloptions.p_visible=ctlclose.p_visible=ctlnext_mismatch.p_visible=ctlleft.p_visible=ctlright.p_visible=ctlreport.p_visible=0;
   boolean cpy_visible=ctlcopy_right.p_visible;


   ctlclose.p_y=(formheight-xbuff)-ctlclose.p_height;
   ctlrefresh.p_y=ctlsave.p_y=ctlnext_mismatch.p_y=ctlprev_mismatch.p_y=ctloptions.p_y=ctlreport.p_y=ctlclose.p_y;
   ctlleft.p_y=(ctlclose.p_y-xbuff)-ctlleft.p_height;
   ctlright.p_y=ctlleft.p_y;
   ctlright.p_x=tree2.p_x;                                                                              //10:42am 5/13/1998
   //Too much flicker turning all controls on and off, so just do the ones that
   //get "overwritten"
   //ctloptions.p_visible=ctlclose.p_visible=ctlnext_mismatch.p_visible=ctlleft.p_visible=ctlright.p_visible=ctlreport.p_visible=0;
   //ctloptions.p_visible=ctlclose.p_visible=ctlnext_mismatch.p_visible=ctlleft.p_visible=ctlright.p_visible=ctlreport.p_visible=1;
   ctlleft.p_visible=ctlright.p_visible=1;
   ctlcopy_right.p_visible=ctlcopy_left.p_visible=cpy_visible;


   tree1.p_height=tree2.p_height=ctlleft.p_y-((xbuff*2)+tree1.p_y);
   int filenamewidth=ctlpath2label.p_x-ctlpath1label.p_x-ctlpath1label._text_width('Path &1:');
   ctlpath1label.p_caption='Path &1:':+_ShrinkFilename(ctlpath1label.p_user,filenamewidth);
   ctlpath2label.p_caption='Path &2:':+_ShrinkFilename(ctlpath2label.p_user,filenamewidth);
   ctlcopy_right.p_y=ctlright.p_y;

   ctlcopy_left.p_y=ctlleft.p_y;

   int xbuf=ctlcopy_right.p_x-(ctlleft.p_x+ctlleft.p_width);
   ctlcopy_left.p_x=ctlright.p_x+ctlright.p_width+xbuf;
   ctlcopy_left.p_x+ctlcopy_left.p_width+xbuf;
   ctlcopy_right.p_visible=ctlcopy_left.p_visible=oldcopy;
   ctlleft.p_visible=ctlright.p_visible=1;
}

void ctloptions.lbutton_up()
{
   show('-modal _diffsetup_form','','','',1,GShowNoEditorOptions);
}

void ctlreport.lbutton_up()
{
   GenerateReport();
}

int ctlsave.lbutton_up(_str arg1='')
{
   _str result='';
   _str filename='';
   _str pathname='';
   _str cur='';
   _str loadOptions="";
   if (arg1=='') {
      result=show('-modal _difftree_save_form',ctlpath1label.p_user,ctlpath2label.p_user);
      if (result=='') return(COMMAND_CANCELLED_RC);
      if (result=='S') {
         //Save state
         result=_OpenDialog('-modal',
                            'Save Diff State As', // Dialog Box Title
                            '',                   // Initial Wild Cards
                            'Diff History Files (*.':+DIFF_STATEFILE_EXT:+')',       // File Type List
                            OFN_SAVEAS,        // Flags
                            DIFF_STATEFILE_EXT
                            );
         if (result=='') return(COMMAND_CANCELLED_RC);
         filename=strip_options(result,loadOptions,true);
         if ( loadOptions!="" ) {
            loadOptions=loadOptions:+" +t";
         }
         SaveMFDiffInfo(filename,loadOptions);
         _AppendToDiffReport(DIFF_REPORT_SAVED_DIFF_STATE,result);
         GModified=0;
         return(0);
      }
   }else{
      //If arg(1) is not blank, we are using the "listonly" option.
      //Build flags like the dialog would return from the options listed
      //in arg(1)
      //
      //arg(1) in format:
      //for arg1 format, see the DIFF_SETUP_INFO struct, fileListInfo field
      filename=parse_file(arg1);
      pathname=parse_file(arg1);
      _str side='';
      if (lowcase(pathname)=='path1filelist') {
         side='L';
      }else if (lowcase(pathname)=='path2filelist') {
         side='R';
      }
      if (filename=='' || side=='' || arg1=='') {
         _message_box(nls("More information required for -listonly option"));
         return(1);
      }
      int flags=0;
      for (;;) {
         parse arg1 with cur ',' arg1;
         if (cur=='') break;
         switch (lowcase(cur)) {
         case 'differentfiles':
            flags|=DIFF_VIEW_DIFFERENT_FILES;
            break;
         case 'vieweddifferentfiles':
            flags|=DIFF_VIEW_VIEWED_FILES;
            break;
         case 'matchingfiles':
            flags|=DIFF_VIEW_MATCHING_FILES;
            break;
         case 'filesnotinpath1':
            flags|=DIFF_VIEW_MISSING_FILES1;
            break;
         case 'filesnotinpath2':
            flags|=DIFF_VIEW_MISSING_FILES2;
            break;
         default:
            _message_box(nls("Unrecognized option for -listonly option"));
            return(1);
         }
      }
      result=upcase(side)' 'flags;
   }
   _str type='';
   typeless flags='';
   _str ch=substr(result,1,1);
   if (ch=='L' || ch=='R') {
      //Save file list
      parse result with type ' ' flags;
      if (filename=='') {
         result=_OpenDialog('-modal',
                            'Save Diff Filelist As',                   // Dialog Box Title
                            '',                   // Initial Wild Cards
                            'Diff Filelist (*.lst)',    // File Type List
                            OFN_SAVEAS,
                            'lst'
                            );
         if (result=='') return(COMMAND_CANCELLED_RC);
         filename=strip_options(result,loadOptions,true);
         if ( loadOptions!="" ) {
            loadOptions=loadOptions:+" +t";
         }
      }
      int temp_view_id=0;
      int orig_view_id=_create_temp_view(temp_view_id,loadOptions);
      p_UTF8=_load_option_UTF8(p_buf_name);
      p_window_id=orig_view_id;
      if (ch=='L') {
         _AppendToDiffReport(DIFF_REPORT_SAVED_PATH1_LIST,GPath1,filename);
         tree1.WriteDiffTreeData(TREE_ROOT_INDEX,0,temp_view_id,'L',flags);
      }else if (ch=='R') {
         _AppendToDiffReport(DIFF_REPORT_SAVED_PATH2_LIST,GPath2,filename);
         tree2.WriteDiffTreeData(TREE_ROOT_INDEX,0,temp_view_id,'L',flags);
      }
      p_window_id=temp_view_id;
      int status=_save_file('+o 'filename);
      if (status) {
         _message_box(nls("Could not save file '%s'\n\n%s",filename,get_message(status)));
         return(status);
      }
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return(0);
   }
   return(0);
}

static int GetPathIndex(_str Path,_str BasePath,int (&PathTable):[],
                        int FolderIndex=_pic_fldopen,boolean recursive=false,
                        int IndexTable:[]=null)
{
   _str PathsToAdd[];int count=0;
   _str OtherPathsToAdd[];
   int Othercount=0;
   Path=strip(Path,'B','"');
   BasePath=strip(BasePath,'B','"');
   if (PathTable._indexin(_file_case(Path))) {
      return(PathTable:[_file_case(Path)]);
   }
   int Parent=TREE_ROOT_INDEX;
   for (;;) {
      PathsToAdd[count++]=Path;
      if (Path=='') {
         break;
      }
      Path=substr(Path,1,length(Path)-1);
      _str tPath=_strip_filename(Path,'N');
      if (file_eq(Path:+FILESEP,BasePath) || file_eq(tPath,Path)) break;
      if (isunc_root(Path)) break;
      Path=tPath;
      if (PathTable._indexin(_file_case(Path))) {
         Parent=PathTable:[_file_case(Path)];
         break;
      }
   }
   PathsToAdd._sort('F');
   int i;
   for (i=0;i<PathsToAdd._length();++i) {
      if ( (FolderIndex==_pic_fldopenp || FolderIndex==_pic_fldopenm) &&
           !recursive) {
         continue;
      }
      if (IndexTable._indexin(PathsToAdd[i])) {
         FolderIndex=IndexTable:[PathsToAdd[i]];
      }
      Parent=_TreeAddItem(Parent,
                          PathsToAdd[i],
                          TREE_ADD_AS_CHILD/*|TREE_ADD_SORTED_FILENAME*/,
                          FolderIndex,
                          FolderIndex,
                          1);
      PathTable:[_file_case(PathsToAdd[i])]=Parent;
   }
   return(Parent);
}

static void GetFolderIndexes(_str path1,_str path2,int &index1,int &index2,
                             _str Options,int BothIndex,int PlusIndex,
                             int MinusIndex)
{
   typeless exist1=0;
   typeless exist2=0;
   path1=strip(path1,'B','"');
   path2=strip(path2,'B','"');
   if (pos(' +d ',' 'Options' ',1,'i')) {
      if (substr(path1,1,2)!='\\') {
         if (last_char(path1)==FILESEP) {
            path1=substr(path1,1,length(path1)-1);
         }
         exist1=file_match(maybe_quote_filename(path1)' 'Options' -p',1)!='';
      }else{
         //For UNC names, we can't just file match for a directory, so
         //we have to look for the first file...
         _maybe_append_filesep(path1);
         path1=path1'*';
         exist1=file_match(maybe_quote_filename(path1)' +p',1)!='';
      }
      if (substr(path2,1,2)!='\\') {
         if (last_char(path2)==FILESEP) {
            path2=substr(path2,1,length(path2)-1);
         }
         exist2=file_match(maybe_quote_filename(path2)' 'Options' -p',1)!='';
      }else{
         //For UNC names, we can't just file match for a directory, so
         //we have to look for the first file...
         _maybe_append_filesep(path2);
         path2=path2'*';
         exist2=file_match(maybe_quote_filename(path2)' +p',1)!='';
      }
   }else{
      exist1=file_match(maybe_quote_filename(path1)' 'Options' -p',1)!='';
      exist2=file_match(maybe_quote_filename(path2)' 'Options' -p',1)!='';
   }
   if (exist1 && exist2) {
      index1=BothIndex;
      index2=BothIndex;
      //index1=_pic_fldopen;
      //index2=_pic_fldopen;
   }else if (exist1 && !exist2) {
      index1=PlusIndex;
      index2=MinusIndex;
      //index1=_pic_fldopenp;
      //index2=_pic_fldopenm;
   }else if (!exist1 && exist2) {
      index1=MinusIndex;
      index2=PlusIndex;
      //index1=_pic_fldopenm;
      //index2=_pic_fldopenp;
   }else if (!exist1 && !exist2) {
      //THIS CANNOT HAPPEN
      index1=MinusIndex;
      index2=MinusIndex;
   }
}

int _srg_diff(_str option='',_str info='')
{
   if (option=='N' || option=='R') {
      typeless numlines='';
      typeless tempGMFDiffViewOptions='';
      parse info with numlines tempGMFDiffViewOptions .;
      //Can't parse this directly because it is an int
      GMFDiffViewOptions=tempGMFDiffViewOptions;
   }else{
      insert_line("DIFF: 0 "GMFDiffViewOptions);
   }
   return(0);
}

/**
 * @return Return true if tagging is supported for the given
 *         language and if that tagging support is useful for
 *         diff symbols.
 * 
 * @param lang  language type identifier 
 */
boolean _diff_istagging_supported(_str lang)
{
   if (_LanguageInheritsFrom('html',lang) || _LanguageInheritsFrom('xml',lang)) {
      return(false);
   }
   return(_istagging_supported(lang));
}

static void FillInMissing(_str FileTable:[],int otherwid,
                          _str path1,_str path2,
                          int (&PathTable1):[],
                          int (&PathTable2):[],
                          boolean recursive)
{
   path1=strip(path1,'B','"');
   path2=strip(path2,'B','"');
   int LastParent=TREE_ROOT_INDEX;
   _str FileArray[];
   _str filename='';
   int count=0;
   typeless i;
   for (i._makeempty();;) {
      FileTable._nextel(i);
      if (i._isempty()) break;
      filename=FileTable:[i];
      FileArray[count++]=filename;
   }
   _str curpath='';
   _str curpath2='';
   _str tempdir='';
   _str IndexTable:[];
   int Index1Table:[];
   int Index2Table:[];
   FileArray._sort('F');
   for (i=0;i<FileArray._length();++i) {
      filename=FileArray[i];
      curpath=_strip_filename(filename,'N');
      boolean isdir=last_char(filename)==FILESEP;
      if (isdir) {
         tempdir=substr(filename,1,length(filename)-1);
         tempdir=_strip_filename(tempdir,'P');
         if (tempdir=='..') continue;
         if (tempdir=='.') {
            //What we want is the path without the '.' at the end
            filename=substr(filename,1,length(filename)-1);
            curpath=_strip_filename(filename,'N');
         }
      }else{
         filename=_strip_filename(filename,'P');
      }
      if (length(path1)==length(curpath)) {
         curpath2=path2;
      }else{
         if (last_char(path2)=='"') {
            curpath2=substr(path2,1,length(path2)-1);
            _maybe_append_filesep(curpath2);
            curpath2=curpath2:+substr(curpath,length(path1)+1)'"';
         }else{
            curpath2=path2:+substr(curpath,length(path1)+1);
         }
      }
      typeless index1=0;
      typeless index2=0;
      typeless index=curpath"\t"curpath2;
#if 0
      if (!IndexTable._indexin(index)) {
         _str tcurpath=curpath,tcurpath2=curpath2;
         for (;;) {
            GetFolderIndexes(tcurpath,tcurpath2,
                             index1,index2,
                             '+d',_pic_fldopen,_pic_fldopenp,_pic_fldopenm);
            index=tcurpath"\t"tcurpath2;
            if (IndexTable._indexin(index)) break;

            IndexTable:[index]=index1"\t"index2;
            Index1Table:[tcurpath]=index1;
            Index2Table:[tcurpath2]=index2;
            tcurpath=_parent_path(tcurpath);
            tcurpath2=_parent_path(tcurpath2);
         }
      }
#else
      index=curpath"\t"curpath2;
      if (!IndexTable._indexin(index)) {
         GetFolderIndexes(curpath,curpath2,
                          index1,index2,
                          '+d',_pic_fldopen,_pic_fldopenp,_pic_fldopenm);
         IndexTable:[index]=index1"\t"index2;
      }else{
         parse IndexTable:[index] with index1 "\t" index2;
      }
#endif
      index=curpath"\t"curpath2;
      parse IndexTable:[index] with index1 "\t" index2;
      typeless pindex=GetPathIndex(curpath,path1,PathTable1,index1,recursive);
      typeless pindex2=otherwid.GetPathIndex(curpath2,path2,PathTable2,index2,recursive);
      if (!isdir && pindex>=0 && pindex2>=0) {
         _str rfilename=_strip_filename(filename,'P');
         _str date=_file_date(_TreeGetCaption(pindex):+rfilename,'B');

         /*int state=-1;
         if (_diff_istagging_supported(_Ext2LangId(get_extension(rfilename)))) {
            //Expand set state expandable if this file is taggable
            state=0;
         }*/
         int newIndex1=_TreeAddItem(pindex,
                                rfilename,
                                TREE_ADD_AS_CHILD,
                                _pic_filep,
                                _pic_filep,
                                -1,0,date:+ASCII1);

         int newIndex2=otherwid._TreeAddItem(pindex2,
                                         rfilename,
                                         TREE_ADD_AS_CHILD,
                                         _pic_filem,
                                         _pic_filem,
                                         -1,0,'-':+ASCII1);

         //This part isn't pretty(hardcoded wid's)
         int state1=0;
         int state2=0;
         int bm1_1=0;
         int bm1_2=0;
         int bm2_1=0;
         int bm2_2=0;
         int flags1=0;
         int flags2=0;
         if (!(GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES1)) {
            tree1._TreeGetInfo(newIndex1,state1,bm1_1,bm2_1,flags1);
            tree2._TreeGetInfo(newIndex2,state2,bm1_2,bm2_2,flags2);
            if ( (bm1_1==_pic_filem && bm1_2==_pic_filep) ) {
               tree1._TreeSetInfo(newIndex1,state1,bm1_1,bm2_1,flags1|TREENODE_HIDDEN);
               tree2._TreeSetInfo(newIndex2,state2,bm1_2,bm2_2,flags2|TREENODE_HIDDEN);
            }
         }
         if (!(GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES2)) {
            tree1._TreeGetInfo(newIndex1,state1,bm1_1,bm2_1,flags1);
            tree2._TreeGetInfo(newIndex2,state2,bm1_2,bm2_2,flags2);
            if ( (bm1_1==_pic_filep && bm1_2==_pic_filem) ) {
               tree1._TreeSetInfo(newIndex1,state1,bm1_1,bm2_1,flags1|TREENODE_HIDDEN);
               tree2._TreeSetInfo(newIndex2,state2,bm1_2,bm2_2,flags2|TREENODE_HIDDEN);
            }
         }
      }
   }
}

static void saveAndRemoveWholePaths(int index,_str (&wholePaths):[]) {
   index = _TreeGetFirstChildIndex(index);
   for (;index>=0;) {
      _str curCap = _TreeGetCaption(index);
      if ( last_char(curCap)==FILESEP ) {
         wholePaths:[index] = curCap;

         curCap = substr(curCap,1,length(curCap)-1);
         _TreeSetCaption(index,_strip_filename(curCap,'P'));
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void restoreWholePaths(int index,_str (&wholePaths):[]) {
   for (i:=null;;) {
      wholePaths._nextel(i);
      if (i._isempty()) break;
      _TreeSetCaption(i,wholePaths:[i]);
   }
}

static void FileSort(int index)
{
   for (;index>=0;) {
      int cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) {
         FileSort(cindex);
         _str wholePaths:[]=null;
         saveAndRemoveWholePaths(index,wholePaths);
         _TreeSortCaption(index,'F');
         restoreWholePaths(index,wholePaths);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

void ctlclose.lbutton_up()
{
   int fid=p_active_form;
   if (GModified &&
       !(def_diff_edit_options&DIFFEDIT_NO_PROMPT_ON_MFCLOSE) &&
       (_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)!=SW_HIDE) ) {
      int result=_difftree_save_prompt();
      if (_param1==1) {
         def_diff_edit_options|=DIFFEDIT_NO_PROMPT_ON_MFCLOSE;
      }
      if (result==IDCANCEL) {
         fid._set_focus();
         return;//May not have wanted to exit
      }
      if (result==IDYES) {
         typeless status=ctlsave.call_event(ctlsave,LBUTTON_UP);
         if (status) return;
      }
   }
   fid._delete_window('');
}

static void HideAllChildren(int index,int SearchBMIndex=0)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   index=_TreeGetFirstChildIndex(index);
   while (index>=0) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (state>=0) {
         HideAllChildren(_TreeGetFirstChildIndex(index));
      }
      if (!SearchBMIndex||bm1==SearchBMIndex) {
         _TreeGetInfo(index,state,bm1,bm2,flags);
         _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_HIDDEN);
      }
      index=_TreeGetNextSiblingIndex(index);
      if (index<0) break;
   }
}

static boolean isFolder(int index)
{
   return(index==_pic_fldopenm || index==_pic_fldopenp ||
          index==_pic_fldopen);
}

//Hides a node that has all hidden children
static int MaybeHideNode(int index)
{
   if (index<0) {
      return(0);
   }
   int CIndex=_TreeGetFirstChildIndex(index);
   if (CIndex<0) {
      return(0);
   }
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int count=0;
   int NonHiddenExist=0;
   while (CIndex>=0) {
      _TreeGetInfo(CIndex,state,bm1,bm2,flags);
      if (state>=0) {
         count+=MaybeHideNode(CIndex);
      }
      _TreeGetInfo(CIndex,state,bm1,bm2,flags);
      if (!(flags&TREENODE_HIDDEN) && !isFolder(bm1)) {
         ++count;
      }
      CIndex=_TreeGetNextSiblingIndex(CIndex);
      if (CIndex<0) break;
   }
   if (!count) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_HIDDEN);
   }
   return(count);
}

static void GiveMFDIffFocus(int wid)
{
   if (_iswindow_valid(wid)) {
      wid._set_foreground_window();
   }
}

static void MakeRelativeTable(_str FileTable:[],_str BasePath,
                              _str (&RelativeTable):[])
{
   _maybe_append_filesep(BasePath);
   typeless i;
   for (i._makeempty();;) {
      FileTable._nextel(i);
      if (i._varformat()==VF_EMPTY) break;
      _str path=substr(i,length(BasePath)+1);
      RelativeTable:[_file_case(path)]=path;
   }
}

static void FillInMissing2(_str RelativeTable1:[],
                           _str RelativeTable2:[],
                           _str CurFileTable:[],
                           int (&PathTable):[],
                           _str BasePath,
                           _str OtherBasePath
                          )
{
   int index=0;
   _maybe_append_filesep(BasePath);
   typeless i;
   for (i._makeempty();;) {
      RelativeTable1._nextel(i);
      _str CurPath=BasePath;
      int p=pos(FILESEP,i);
      if (p) {
         CurPath=BasePath:+substr(i,1,p-1);
      }
      if (i._varformat()==VF_EMPTY) break;
      if (!RelativeTable2._indexin(i)) {
         //This File is missing....
         index=GetPathIndex(CurPath,BasePath,PathTable);
      }
   }
}


static void MFDiffTreeCreate(MFDIFF_SETUP_INFO *pSetupInfo)
{
   mou_hour_glass(1);
   _SetDialogInfo(RESTORE_FROM_INI,pSetupInfo->RestoreFromINI);
   typeless status=0;
   typeless result=0;
   typeless x=_GetDialogInfo(RESTORE_FROM_INI);
   typeless modalOption='';
   typeless filespec_list='';
   boolean gShowNoEditorOptions=false;
   int LastParent=0;
   int LastParent1=0;
   int LastParent2=0;
   int parent1=0;
   int parent2=0;
   int i=0;
   int bmindex=0;
   int newIndex1=0;
   int newIndex2=0;
   _str filename1='';
   _str filename2='';
   _str curpath1='';
   _str curpath2='';
   _str date1='';
   _str date2='';
   GNumHidden=0;
   GModified=0;
   _str Directories[];
   int PathTable1:[],PathTable2:[];
   GOEMMode=pSetupInfo->ShowNoEditorOptions;
   if (pSetupInfo->DiffStateFilename._varformat()==VF_LSTR &&
       pSetupInfo->DiffStateFilename!='') {
      _str path1,path2;
      mou_hour_glass(1);
      //This is a filename with stuff to load...
      _str filename=pSetupInfo->DiffStateFilename;
      status=_ini_get_value(filename,'State','GMFDiffViewOptions',result,'');
      if (result!='') GMFDiffViewOptions=result;

      status=_ini_get_value(filename,'State','filespec_list',result,'');
      if (result!='') _SetDialogInfo(FILESPEC_LIST,result);

      status=_ini_get_value(filename,'State','exclude_filespec_list',result,'');
      if (result!='') GExcludeFilespecList=result;

      status=_ini_get_value(filename,'State','path1',result,'');
      if (result!='') path1=GPath1=result;

      status=_ini_get_value(filename,'State','path2',result,'');
      if (result!='') path2=GPath2=result;

      status=_ini_get_value(filename,'State','recursive',result,'');
      if (result!='') GRecursive=result;

      tree1.ReadTree(filename,'TreeData1');
      tree2.ReadTree(filename,'TreeData2');
      p_active_form.p_caption='Multi-File Diff Output ('GPath1' 'GPath2')';
      modalOption=_default_option(VSOPTION_MDI_SHOW_WINDOW_FLAGS)==SW_HIDE;
      tree1.call_event(CHANGE_SELECTED,tree1._TreeCurIndex(),tree1,ON_CHANGE,'W');
      tree2.call_event(CHANGE_SELECTED,tree2._TreeCurIndex(),tree2,ON_CHANGE,'W');
      filespec_list=_GetDialogInfo(FILESPEC_LIST);
      if ( filespec_list==null ) filespec_list='';

      _AppendToDiffReport(DIFF_REPORT_LOADED,filename,path1,path2,filespec_list);
      pSetupInfo->Filespecs=filespec_list;
      pSetupInfo->ExcludeFilespecs=GExcludeFilespecList;
      pSetupInfo->Path1=path1;
      pSetupInfo->Path2=path2;
      pSetupInfo->recursive=GRecursive;
      gShowNoEditorOptions=pSetupInfo->ShowNoEditorOptions;
      mou_hour_glass(0);
   }else{
      GPath1=pSetupInfo->Path1;
      GPath2=pSetupInfo->Path2;

      p_active_form.p_caption='Multi-File Diff Output ('pSetupInfo->Path1' 'pSetupInfo->Path2')';
      GRecursive=pSetupInfo->recursive;
      _SetDialogInfo(FILESPEC_LIST,pSetupInfo->Filespecs);
      GExcludeFilespecList=pSetupInfo->ExcludeFilespecs;
      LastParent1=LastParent2=TREE_ROOT_INDEX;
      for (i=0;i<pSetupInfo->OutputTable._length();++i) {
         parse pSetupInfo->OutputTable[i] with filename1 "\t" date1 "\t" filename2 "\t" date2 "\t" status;
         curpath1=_strip_filename(filename1,'N');
         curpath2=_strip_filename(filename2,'N');
         filename1=_strip_filename(filename1,'P');
         filename2=_strip_filename(filename2,'P');
         if (_GetDialogInfo(FILESPEC_LIST)==null) {
            GPath1=pSetupInfo->Path1:+filename1;
            GPath2=pSetupInfo->Path2:+filename2;
         }
         parent1=tree1.GetPathIndex(curpath1,pSetupInfo->Path1,PathTable1,_pic_fldopen,pSetupInfo->recursive);
         parent2=tree2.GetPathIndex(curpath2,pSetupInfo->Path2,PathTable2,_pic_fldopen,pSetupInfo->recursive);
         if (status) {
            bmindex=_pic_filed;
         }else if (last_char(filename1)==FILESEP) {
            bmindex=_pic_fldopen;
         }else{
            bmindex=_pic_file_match;
         }

         int state=-1;
         if (def_mfdiff_functions==1 &&
             _diff_istagging_supported(_Filename2LangId(filename1))) {
            //Expand set state expandable if this file is taggable
            state=0;
         }
         newIndex1=tree1._TreeAddItem(parent1,
                                      filename1,
                                      TREE_ADD_AS_CHILD,
                                      bmindex,
                                      bmindex,
                                      state,
                                      0,
                                      date1:+ASCII1);
         newIndex2=tree2._TreeAddItem(parent2,
                                      filename2,
                                      TREE_ADD_AS_CHILD,
                                      bmindex,
                                      bmindex,
                                      state,
                                      0,
                                      date2:+ASCII1);
         if (bmindex==_pic_file_match && !(GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES)) {
            tree1._TreeSetInfo(newIndex1,-1,bmindex,bmindex,TREENODE_HIDDEN);
            tree2._TreeSetInfo(newIndex2,-1,bmindex,bmindex,TREENODE_HIDDEN);
         }else if (bmindex==_pic_filed && !(GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_FILES)) {
            tree1._TreeSetInfo(newIndex1,state,bmindex,bmindex,TREENODE_HIDDEN);
            tree2._TreeSetInfo(newIndex2,state,bmindex,bmindex,TREENODE_HIDDEN);
         }
      }
      LastParent=TREE_ROOT_INDEX;
      tree1.FillInMissing(pSetupInfo->FileTable1,tree2,pSetupInfo->Path1,pSetupInfo->Path2,PathTable1,PathTable2,pSetupInfo->recursive);
      tree2.FillInMissing(pSetupInfo->FileTable2,tree1,pSetupInfo->Path2,pSetupInfo->Path1,PathTable2,PathTable1,pSetupInfo->recursive);

      if (!(GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES1)) {
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_fldopenm);
      }else if (!(GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES2)) {
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_fldopenm);
      }
      tree1._TreeTop();//tree2._TreeTop();
      tree1.call_event(CHANGE_SELECTED,tree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX),tree1,ON_CHANGE,'W');
      tree1.FileSort(TREE_ROOT_INDEX);
      tree2.FileSort(TREE_ROOT_INDEX);
      _AppendToDiffReport(DIFF_REPORT_CREATED,pSetupInfo->Path1,pSetupInfo->Path2,_GetDialogInfo(FILESPEC_LIST));
   }
   if (modalOption!='') {
      _post_call(GiveMFDIffFocus,p_active_form);
   }
   ctlpath1label.p_user=pSetupInfo->Path1;
   ctlpath1label.p_caption='Path &1:'pSetupInfo->Path1;
   ctlpath2label.p_user=pSetupInfo->Path2;
   ctlpath2label.p_caption='Path &2:'pSetupInfo->Path2;
   tree1.MaybeHideNode(TREE_ROOT_INDEX);
   tree2.MaybeHideNode(TREE_ROOT_INDEX);
   //ctlcopy_left.ctlcopy_right.p_visible=0;
   if (def_diff_edit_options&DIFFEDIT_START_AT_FIRST_DIFF) {
      ctlnext_mismatch.call_event(ctlnext_mismatch,LBUTTON_UP);
      tree1._set_focus();
   }
   _str file_list_info=pSetupInfo->fileListInfo;
   if (file_list_info!=null && file_list_info!='') {
      //If this is not blank, the "listonly" option is on.  Call the save
      //button's event, and close the dialog
      ctlsave.call_event(file_list_info,ctlsave,LBUTTON_UP,'w');
      p_active_form._delete_window(0);
   }
   if (pSetupInfo->ExpandFirst._varformat()!=VF_EMPTY &&
       pSetupInfo->ExpandFirst) {
      tree1.ExpandFile2();
   }
   mou_hour_glass(0);
}

static void ExpandFile2(int index=TREE_ROOT_INDEX)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   for (;index>=0;) {
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (!(flags&TREENODE_HIDDEN) &&
          (bm1==_pic_filed ||bm1==_pic_filed2) ) {
         _TreeSetInfo(index,1);
         call_event(CHANGE_EXPANDED,index,p_window_id,ON_CHANGE,'W');
         return;
      }
      int cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) {
         ExpandFile2(cindex);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void BlastTagInfo(int index)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   for (;;) {
      if (index<0) break;
      _TreeGetInfo(index,state,bm1);
      int pindex=_TreeGetParentIndex(index);
      if (index!=TREE_ROOT_INDEX &&
          pindex!=TREE_ROOT_INDEX &&
          !_IsFunctionIndex(index)) {
         _str filename=_TreeGetCaption(pindex):+_TreeGetCaption(index);
         _DiffTagDeleteInfo(_DiffTagInfoGetIndex(p_window_id,filename));
         _DiffTagDeleteInfo(_DiffTagInfoGetIndex(p_window_id,filename));
      }
      if (bm1==_pic_fldopen) {
         int cindex=_TreeGetFirstChildIndex(index);
         if (cindex>0) {
            BlastTagInfo(cindex);
         }
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

void tree1.on_destroy()
{
   if (GOEMMode) {
      int wid=p_window_id;
      save_window_config();
      p_window_id=wid;
   }
   tree1.BlastTagInfo(tree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   tree2.BlastTagInfo(tree2._TreeGetFirstChildIndex(TREE_ROOT_INDEX));

   if ( _GetDialogInfo(RESTORE_FROM_INI) ) {
      int x,y,width,height;
      _DiffGetDimensionsAndState(x,y,width,height);
      _DiffWriteConfigInfoToIniFile("MFDiffGeometry",x,y,width,height);
   }
}

void tree1.on_create(MFDIFF_SETUP_INFO *pSetupInfo)
{
   MFDiffTreeCreate(pSetupInfo);
}

#define DIFF_CAPTION            '&Diff...'
#define DIFF_CAPTION2           'Diff...'
#define VIEW_CAPTION            '&View...'
#define VIEW_CAPTION2           'View...'
#define COPY_RIGHT_CAPTION      'Copy File>>'
#define COPY_LEFT_CAPTION       '<<Copy File'
#define COPY_TREE_RIGHT_CAPTION 'Copy Tree>>'
#define COPY_TREE_LEFT_CAPTION  '<<Copy Tree'
#define DELETE_FILE_CAPTION     'Del File'
#define DELETE_TREE_CAPTION     'Del Tree'

#define COPY_SYMBOL_RIGHT_CAPTION 'Copy Symbol>>'
#define COPY_SYMBOL_LEFT_CAPTION  '<<Copy Symbol'
#define DELETE_SYMBOL_CAPTION     'Del Symbol'

void tree1.lbutton_up()
{
#if 0
   GNoOnChange=1;
   tree2._TreeCurLineNumber(_TreeCurLineNumber());
   GNoOnChange=0;
#endif
}

void tree1.lbutton_double_click()
{
   ctlleft.call_event('M',ctlleft,LBUTTON_UP,'W');
}

void tree2.lbutton_up()
{
#if 0
   GNoOnChange=1;
   tree1._TreeCurLineNumber(_TreeCurLineNumber());
   GNoOnChange=0;
#endif
}

static void TreeEnter()
{
   int index=_TreeCurIndex();
   int otherwid=( (p_window_id==tree1) ? tree2:tree1);
   int otherindex=otherwid._TreeCurIndex();
   int state=0;
   typeless newstate=0;
   _TreeGetInfo(index,state);
   if (state>-1) {
      newstate=!state;
      _TreeSetInfo(index,newstate);
      otherwid._TreeSetInfo(otherindex,newstate);
   }else{
      if (p_window_id==tree1) {
         ctlleft.call_event('M',ctlleft,LBUTTON_UP,'W');
      }else{
         ctlright.call_event('M',ctlleft,LBUTTON_UP,'W');
      }
   }
   int bm1=0;
   _TreeGetInfo(index,state,bm1);

   int tree1index=tree1._TreeCurIndex();
   int tree2index=tree2._TreeCurIndex();

   _str date1='';
   _str date2='';
   if (!_IsFunctionIndex(tree1index)) {
      _str info1=tree1._TreeGetUserInfo(tree1index);
      _str info2=tree2._TreeGetUserInfo(tree2index);

      parse info1 with date1 (_chr(1)) .;
      parse info2 with date2 (_chr(1)) .;

      _str filename1='',filename2='';
      tree1.GetFilenameFromIndex(tree1index,filename1);
      tree2.GetFilenameFromIndex(tree2index,filename2);

      if (def_mfdiff_functions==1) {
         if (bm1!=_pic_fldopen &&
             bm1!=_pic_filep &&
             bm1!=_pic_filem) {
            if (tree1._TreeGetFirstChildIndex(tree1index) < 0 ||
                (_file_date(filename1,'B') != date1 ||
                 _file_date(filename2,'B') != date2)
                ) {
               int status=_DiffExpandTaggingInformation(tree1index,tree2index);
               if (!status) {
                  tree1._TreeSetUserInfo(tree1index,_file_date(filename1,'B'):+ASCII1);
                  tree2._TreeSetUserInfo(tree2index,_file_date(filename2,'B'):+ASCII1);
               }
            }
         }
      }
   }
}

void tree1.ENTER()
{
   TreeEnter();
}

void tree2.ENTER()
{
   TreeEnter();
}

static void DiffPrefixMatch()
{
   typeless event=last_event();
   int wid=p_window_id;
   int otherwid=(p_window_id==tree1?tree2:tree1);
   int index=find_index('_ul2_tree',EVENTTAB_TYPE);
   if (index) {
      wid.call_event(index,event,'E');
      otherwid.call_event(index,event,'E');
   }
}

void tree1.'A'-'Z','a'-'z'()
{
   DiffPrefixMatch();
}

void tree2.'A'-'Z','a'-'z'()
{
   DiffPrefixMatch();
}

void tree2.lbutton_double_click()
{
   ctlright.call_event('M',ctlright,LBUTTON_UP,'W');
}

static void SyncScrollPositions(_str wids)
{
   typeless wid1,wid2;
   parse wids with wid1 wid2;
   wid2._TreeScroll(wid1._TreeScroll());
}

static void TreeSwitchFocus(int oldwid,int newwid)
{
   int NumSelected1=newwid._TreeGetNumSelectedItems();
   int NumSelected2=oldwid._TreeGetNumSelectedItems();
   p_window_id=newwid;
   _set_focus();
#if 0
   if (NumSelected1||NumSelected2>1 ) {
      return;
   }
#endif
   oldwid._TreeDeselectAll();
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int index=_TreeCurIndex();
   if (index<0) return;
   if (!NumSelected1) {
      _TreeSelectLine(index);
   }
}

void tree1.tab()
{
   TreeSwitchFocus(tree1,tree2);
}

void tree2.s_tab()
{
   TreeSwitchFocus(tree2,tree1);
}

tree1.on_got_focus()
{
   //We can only have a selection in one tree at a time
   TreeSwitchFocus(tree2,tree1);
}

tree2.on_got_focus()
{
   //We can only have a selection in one tree at a time
   TreeSwitchFocus(tree1,tree2);
}

#define MFDIFF_SELECTED_DIFF_FILE          0x1
#define MFDIFF_SELECTED_MISSING_FILE       0x2
#define MFDIFF_SELECTED_MISSING_FOLDER     0x4
#define MFDIFF_SELECTED_ONLY_FILE          0x8
#define MFDIFF_SELECTED_ONLY_FOLDER        0x10
#define MFDIFF_SELECTED_MATCHING_FILE      0x20
#define MFDIFF_SELECTED_MATCHING_FOLDER    0x40

#define NoFileSetup()         ctlcopy_left.p_caption=COPY_LEFT_CAPTION;\
                              ctlcopy_right.p_caption=COPY_RIGHT_CAPTION;\
                              ctlleft.p_enabled=ctlright.p_enabled=0;\
                              ctlcopy_left.p_enabled=ctlcopy_right.p_enabled=0;\
                              ctlleft.p_caption=DIFF_CAPTION;\
                              ctlright.p_caption=DIFF_CAPTION2;

#define DiffFileSetup(e)      ctlcopy_left.p_caption=COPY_LEFT_CAPTION;\
                              ctlcopy_right.p_caption=COPY_RIGHT_CAPTION;\
                              ctlleft.p_enabled=ctlright.p_enabled=e;\
                              ctlcopy_left.p_enabled=ctlcopy_right.p_enabled=1;\
                              ctlleft.p_caption=DIFF_CAPTION;\
                              ctlright.p_caption=DIFF_CAPTION2;

#define DiffFunctionSetup(e)  ctlcopy_left.p_caption=COPY_SYMBOL_LEFT_CAPTION;\
                              ctlcopy_right.p_caption=COPY_SYMBOL_RIGHT_CAPTION;\
                              ctlleft.p_enabled=ctlright.p_enabled=e;\
                              ctlcopy_left.p_enabled=ctlcopy_right.p_enabled=1;\
                              ctlleft.p_caption=DIFF_CAPTION;\
                              ctlright.p_caption=DIFF_CAPTION2;

#define OnlyFileSetup(e)     ctlcopy_right.p_caption=COPY_RIGHT_CAPTION;\
                             ctlcopy_left.p_caption=DELETE_FILE_CAPTION;\
                             ctlright.p_enabled=0;\
                             ctlleft.p_caption=VIEW_CAPTION;\
                             ctlleft.p_enabled=e;\
                             ctlcopy_left.p_enabled=1;\
                             ctlcopy_right.p_enabled=1;

#define OnlyFunctionSetup(e) ctlcopy_right.p_caption=COPY_SYMBOL_RIGHT_CAPTION;\
                             ctlcopy_left.p_caption=DELETE_SYMBOL_CAPTION;\
                             ctlright.p_enabled=0;\
                             ctlleft.p_caption=VIEW_CAPTION;\
                             ctlleft.p_enabled=e;\
                             ctlcopy_left.p_enabled=1;\
                             ctlcopy_right.p_enabled=1;

#define MissingFileSetup(e)  ctlcopy_left.p_caption=COPY_LEFT_CAPTION;\
                             ctlcopy_right.p_caption=DELETE_FILE_CAPTION;\
                             ctlleft.p_enabled=0;\
                             ctlright.p_caption=VIEW_CAPTION;\
                             ctlright.p_enabled=e;\
                             ctlcopy_left.p_enabled=1;\
                             ctlcopy_right.p_enabled=1;

#define MissingFunctionSetup(e)  ctlcopy_left.p_caption=COPY_SYMBOL_LEFT_CAPTION;\
                             ctlcopy_right.p_caption=DELETE_SYMBOL_CAPTION;\
                             ctlleft.p_enabled=0;\
                             ctlright.p_caption=VIEW_CAPTION;\
                             ctlright.p_enabled=e;\
                             ctlcopy_left.p_enabled=1;\
                             ctlcopy_right.p_enabled=1;

#define OnlyFolderSetup()    ctlcopy_right.p_caption=COPY_TREE_RIGHT_CAPTION;\
                             ctlcopy_left.p_caption=DELETE_TREE_CAPTION;\
                             ctlcopy_right.p_enabled=ctlcopy_left.p_enabled=1;\
                             ctlleft.p_enabled=ctlright.p_enabled=0;

#define MissingFolderSetup() ctlcopy_right.p_caption=DELETE_TREE_CAPTION;\
                             ctlcopy_left.p_caption=COPY_TREE_LEFT_CAPTION;\
                             ctlcopy_left.p_enabled=ctlcopy_right.p_enabled=1;\
                             ctlleft.p_enabled=ctlright.p_enabled=0;

#define MatchingFileSetup(e) ctlleft.p_caption=VIEW_CAPTION;\
                             ctlright.p_caption=VIEW_CAPTION2;\
                             ctlleft.p_enabled=ctlright.p_enabled=e;\
                             ctlcopy_left.p_enabled=ctlcopy_right.p_enabled=0;

#define MatchingFolderSetup() ctlcopy_right.p_caption=COPY_TREE_RIGHT_CAPTION;\
                              ctlcopy_left.p_caption=COPY_TREE_LEFT_CAPTION;\
                              ctlcopy_left.p_enabled=1;\
                              ctlcopy_right.p_enabled=1;\
                              ctlleft.p_enabled=ctlright.p_enabled=0;

#define EqOneOrBoth(a,b,c) ( (a==b) || (a==(b|c)) )

#define PicMissingOrOnly(a,b,c) ( (a==tree1) ? (b):(c) )

/**
 *
 * @param index  Index of tree node
 *
 * @return true if <B>index</B> is the index of a symbol item in the tree.
 */
boolean _IsFunctionIndex(int index)
{
   typeless junk;
   int bm1=0;
   _TreeGetInfo(index,junk,bm1);

   if (bm1==_pic_symbol   ||
       bm1==_pic_symbold  ||
       bm1==_pic_symbold2 ||
       bm1==_pic_symbolp  ||
       bm1==_pic_symbolm  ||
       bm1==_pic_symbolmoved
       ) {
      return(true);
   }

   return(false);
}

static void EnableButtons()
{
   int wid=p_window_id;
   p_window_id=tree1;
   int copy1wid=ctlcopy_right;
   int copy2wid=ctlcopy_left;
   int diff1wid=ctlleft;
   int diff2wid=ctlright;
   int NumSelected=_TreeGetNumSelectedItems();
   if (!NumSelected) {
      p_window_id=tree2;
      NumSelected = _TreeGetNumSelectedItems();
      copy1wid=ctlcopy_left;
      copy2wid=ctlcopy_right;
      diff1wid=ctlright;
      diff2wid=ctlleft;
   }
   if (tree1._TreeCurIndex() < 0 ||
       tree2._TreeCurIndex() < 0) {
      NoFileSetup();
      return;
   }
   int tree1index=tree1._TreeCurIndex();
   int tree2index=tree2._TreeCurIndex();

   typeless junk;
   int tree1_bmindex1=0;
   int tree1_bmindex2=0;
   int tree2_bmindex1=0;
   int tree2_bmindex2=0;
   int flags=0;
   tree1._TreeGetInfo(tree1index,junk,tree1_bmindex1,tree1_bmindex2,flags);
   tree2._TreeGetInfo(tree2index,junk,tree2_bmindex1,tree2_bmindex2,flags);

   if (tree1._IsFunctionIndex(tree1index)) {
      if (NumSelected>1) {
         MatchingFileSetup(0);
         return;
      }
      if (tree1_bmindex1==_pic_symbold||
          tree1_bmindex1==_pic_symbold2) {
         DiffFunctionSetup(1);
      }else if (tree1_bmindex1==_pic_symbolm) {
         MissingFunctionSetup(1);
      }else if (tree1_bmindex1==_pic_symbolp) {
         OnlyFunctionSetup(1);
      }else if (tree1_bmindex1==_pic_symbol) {
         MatchingFileSetup(1);
      }else if (tree1_bmindex1==_pic_symbolmoved) {
         MatchingFileSetup(1);
      }
      return;
   }

   int index=0;
   int state=0;
   int bm1=0,bm2=0;
   int pbm1=0;
   if (NumSelected<=1) {
      if (tree1_bmindex1==_pic_filed||
          tree1_bmindex1==_pic_filed2) {
         DiffFileSetup(1);
      }else if (tree1_bmindex1==_pic_filem) {
         MissingFileSetup(1);
      }else if (tree1_bmindex1==_pic_filep) {
         OnlyFileSetup(1);
      }else if (tree1_bmindex1==_pic_fldopenp) {
         OnlyFolderSetup();
      }else if (tree1_bmindex1==_pic_fldopenm) {
         MissingFolderSetup();
      }else if (tree1_bmindex1==_pic_file_match) {
         MatchingFileSetup(1);
      }else if (tree1_bmindex1==_pic_fldopen) {
         MatchingFolderSetup();
      }
   }else{
      int SelectedItems=0;
      boolean had_file=false,had_function=false;
      int info;
      for (ff:=1;;ff=0) {
         index=_TreeGetNextSelectedIndex(ff,info);
         if (index<0) break;
         _TreeGetInfo(index,state,bm1,bm2,flags);

         //Get the parent index, then get the parent bitmaps and see if the
         //parent is a function or a file.

         int pindex=_TreeGetParentIndex(index);
         _TreeGetInfo(pindex,state,pbm1);
         if (DiffIsFileBitmap(pbm1)) {
            //If the parent is File bitmap, these are functions we are looking
            //at, not files
            had_function=true;
         }else{
            had_file=true;
            if (bm1==_pic_file_match) {
               SelectedItems|=MFDIFF_SELECTED_MATCHING_FILE;
            }else if (bm1==_pic_filed ||
                      bm1==_pic_filed2) {
               SelectedItems|=MFDIFF_SELECTED_DIFF_FILE;
            }else if (bm1==_pic_filem) {
               SelectedItems|=PicMissingOrOnly(p_window_id,MFDIFF_SELECTED_MISSING_FILE,MFDIFF_SELECTED_ONLY_FILE);
            }else if (bm1==_pic_filep) {
               SelectedItems|=PicMissingOrOnly(p_window_id,MFDIFF_SELECTED_ONLY_FILE,MFDIFF_SELECTED_MISSING_FILE);
            }else if (bm1==_pic_fldopenp) {
               SelectedItems|=PicMissingOrOnly(p_window_id,MFDIFF_SELECTED_ONLY_FOLDER,MFDIFF_SELECTED_MISSING_FOLDER);
            }else if (bm1==_pic_fldopenm) {
               SelectedItems|=PicMissingOrOnly(p_window_id,MFDIFF_SELECTED_MISSING_FOLDER,MFDIFF_SELECTED_ONLY_FOLDER);
            }else if (bm1==_pic_fldopen) {
               SelectedItems|=MFDIFF_SELECTED_MATCHING_FOLDER;
            }
         }
         if (had_function && had_file) {
            NoFileSetup();
            return;
         }
      }
      ctlleft.p_enabled=ctlright.p_enabled=0;//Can't diff w/ multiple files
      if (EqOneOrBoth(SelectedItems,MFDIFF_SELECTED_DIFF_FILE,MFDIFF_SELECTED_MATCHING_FILE)) {
         DiffFileSetup(0);
      }else if (EqOneOrBoth(SelectedItems,MFDIFF_SELECTED_MISSING_FILE,MFDIFF_SELECTED_MATCHING_FILE)) {
         MissingFileSetup(0);
      }else if (EqOneOrBoth(SelectedItems,MFDIFF_SELECTED_ONLY_FILE,MFDIFF_SELECTED_MATCHING_FILE)) {
         OnlyFileSetup(0);
      }else if (EqOneOrBoth(SelectedItems,MFDIFF_SELECTED_ONLY_FOLDER,MFDIFF_SELECTED_MATCHING_FILE)) {
         OnlyFolderSetup();
      }else if (SelectedItems==MFDIFF_SELECTED_MISSING_FOLDER) {
         MissingFolderSetup();
      }else if (SelectedItems==MFDIFF_SELECTED_MATCHING_FILE) {
         MatchingFileSetup(0);
      }else if (SelectedItems==MFDIFF_SELECTED_MATCHING_FOLDER) {
         MatchingFolderSetup();
      }else{
         NoFileSetup();
      }
   }
   p_window_id=wid;
}

/**
 *
 * @param bitmap_index
 *
 * @return Return true if bitmap_index is the index of a bitmap
 *         used to show a file icon in the multi file diff
 *         dialog
 */
static boolean DiffIsFileBitmap(int bitmap_index)
{
   return(bitmap_index==_pic_file_match ||
          bitmap_index==_pic_filed ||
          bitmap_index==_pic_filed2 ||
          bitmap_index==_pic_filep);
}

//For debugging
_str _ReasonName(_str reason)
{
   if (reason==CHANGE_OTHER) return('CHANGE_OTHER');
   if (reason==CHANGE_CLINE) return('CHANGE_CLINE');
   if (reason==CHANGE_CLINE_NOTVIS) return('CHANGE_CLINE_NOTVIS');
   if (reason==CHANGE_CLINE_NOTVIS2) return('CHANGE_CLINE_NOTVIS2');

   if (reason==CHANGE_BUTTON_PRESS) return('CHANGE_BUTTON_PRESS');

   if (reason==CHANGE_SELECTED) return('CHANGE_SELECTED');
   if (reason==CHANGE_PATH) return('CHANGE_PATH');
   if (reason==CHANGE_FILENAME) return('CHANGE_FILENAME');
   if (reason==CHANGE_DRIVE) return('CHANGE_DRIVE');

   if (reason==CHANGE_EXPANDED) return('CHANGE_EXPANDED');
   if (reason==CHANGE_COLLAPSED) return('CHANGE_COLLAPSED');
   if (reason==CHANGE_LEAF_ENTER) return('CHANGE_LEAF_ENTER');
   if (reason==CHANGE_SCROLL) return('CHANGE_SCROLL');
   if (reason==CHANGE_NEW_FOCUS) return('CHANGE_NEW_FOCUS');
   if (reason==CHANGE_TABDEACTIVATED) return('CHANGE_TABDEACTIVATED');
   if (reason==CHANGE_TABACTIVATED) return('CHANGE_TABACTIVATED');

   if (reason==CHANGE_CLICKED_ON_HTML_LINK) return('CHANGE_CLICKED_ON_HTML_LINK');
   return('');
}

void tree1.on_change(int reason, int index=0)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _str oname=p_name;
   if (index<0 && reason!=CHANGE_SCROLL) {
      return;
   }
   int cur_index=_TreeCurIndex();
   if ( cur_index<0 ) return;
   if ( index ) {
      _TreeGetInfo(cur_index,state,bm1,bm2,flags);
   }
   if ( cur_index<0 ) return;
   _str cap=_TreeGetCaption(cur_index);
   _TreeGetInfo(cur_index,state,bm1,bm2,flags);
   if (!p_visible && reason!=CHANGE_EXPANDED) {
      return;
   }
   if (/*!p_visible||*/GNoOnChange==1) {
      return;
   }
   typeless sp=0;
   int wid=0;
   int owid=0;
   int CurIndex=0;
   int CurIndex2=0;
   int NumSelected1=0;
   int NumSelected2=0;
   typeless status=0;
   typeless foundNode=0;
   switch (reason) {
   case CHANGE_SELECTED:
      if (index<0) {
         ctlleft.p_enabled=0;
         ctlright.p_enabled=0;
         return;
      }
      _TreeGetInfo(cur_index,state,bm1,bm2,flags);
      if (flags&TREENODE_HIDDEN) {
         foundNode=0;
         origIndex := cur_index;
         while (flags&TREENODE_HIDDEN) {
            status=call_event(p_window_id,DOWN);
            if (status) break;
            cur_index=_TreeCurIndex();

            // If there was only one index and it was hidden,
            // this could be the same. Check for that too.
            if ( cur_index<0 || cur_index==origIndex ) break;
            _TreeGetInfo(cur_index,state,bm1,bm2,flags);
         }
         if (!foundNode) {
            ctlleft.p_enabled=0;
            ctlright.p_enabled=0;
         }
      }
      GNoOnChange=1;
      NumSelected1 = tree1._TreeGetNumSelectedItems();
      NumSelected2 = tree2._TreeGetNumSelectedItems();
      if (p_window_id==tree1) {
         tree2._TreeCurLineNumber(_TreeCurLineNumber());
         if (NumSelected1 && NumSelected2) {
            tree2._TreeSelectLine(tree2._TreeCurIndex(),true);
         }
         tree2._TreeRefresh();
      }else{
         tree1._TreeCurLineNumber(tree2._TreeCurLineNumber());
         if (NumSelected1 && NumSelected2) {
            tree1._TreeSelectLine(tree1._TreeCurIndex(),true);
         }
         tree1._TreeRefresh();
      }
      GNoOnChange=0;
      EnableButtons();
      sp=_TreeScroll();
      if (p_window_id==tree1) {
         owid=tree2;
      }else{
         owid=tree1;
      }
      GNoOnChange=1;
      owid._TreeScroll(sp);
      GNoOnChange=0;
      break;
   case CHANGE_SCROLL:
      sp=_TreeScroll();
      if (p_window_id==tree1) {
         owid=tree2;
      }else{
         owid=tree1;
      }
      GNoOnChange=1;
      owid._TreeScroll(sp);
      GNoOnChange=0;
      break;
   case CHANGE_COLLAPSED:
   case CHANGE_EXPANDED:
      int CollapseIndex=index;
      _TreeGetInfo(CollapseIndex,state,bm1);
      CurIndex=_TreeCurIndex();
      _TreeSetCurIndex(CollapseIndex);

      wid=p_window_id;p_window_id=(wid==tree1?tree2:tree1);
      CurIndex2=_TreeCurIndex();
      _TreeCurLineNumber(wid._TreeCurLineNumber());
      int CollapseIndex2=_TreeCurIndex();
      _TreeSetInfo(CollapseIndex2,(reason==CHANGE_COLLAPSED?0:1) );

      _TreeCurLineNumber(wid._TreeCurLineNumber());

      _post_call(SyncScrollPositions,tree1' 'tree2);
      p_window_id=wid;
      if (def_mfdiff_functions==1 && reason==CHANGE_EXPANDED && bm1!=_pic_fldopen) {
         _DiffExpandTaggingInformation(tree1._TreeCurIndex(),tree2._TreeCurIndex());
      }
      break;
   /*case CHANGE_LEAF_ENTER:
      CurIndex=_TreeCurIndex();
      wid=p_window_id;p_window_id=(wid==tree1?tree2:tree1);
      CollapseIndex2=_TreeCurIndex();
      _TreeGetInfo(CollapseIndex,state,bm1,bm2);
      if (bm1!=_pic_fldopen &&
          bm1!=_pic_filep &&
          bm1!=_pic_filem) {
         _DiffExpandTaggingInformation(CollapseIndex,CollapseIndex2);
      }
      p_window_id=wid;
      break;*/
   }
}

static void ReplaceIndexesUp(int index,int bmindex)
{
   int state=0;
   for (;index>0;) {
      _TreeGetInfo(index,state);
      _TreeSetInfo(index,state,bmindex,bmindex);
      index=_TreeGetParentIndex(index);
   }
}

static int MyMakePath(_str DestPath,int spindex,int dpindex)
{
   typeless status=make_path(DestPath);
   if (status) return(status);
   tree1.ReplaceIndexesUp(dpindex,_pic_fldopen);
   tree2.ReplaceIndexesUp(spindex,_pic_fldopen);
   return(status);
}

static int MaybeWarnModified(_str FileName)
{
   FileName=strip(FileName,'b','"');
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FileName,temp_view_id,orig_view_id,'+b');
   if (!status) {
      int result=IDYES;
      if (p_modify) {
         result=_message_box(nls("You have a modified buffer for '%s'.\n\nContinue?",FileName),'',MB_YESNOCANCEL|MB_ICONQUESTION);
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      if (result!=IDYES) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   return(0);
}

static int MaybeSaveBuffer(_str FileName,int filestatus=0)
{
   FileName=strip(FileName,'b','"');
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(FileName,temp_view_id,orig_view_id,'+b');
   if (!status) {
      int result=IDNO;
      if (p_modify||filestatus) {
         _str msg='';
         if (p_modify) {
            msg="The buffer '%s' is modified.\n\nDo you wish to save it before copying?";
         }else{
            msg="The buffer '%s' is does not match the file on disk.\n\nDo you wish to save it before copying?";
         }
         result=prompt_for_save(nls(msg,FileName));
      }
      activate_window(temp_view_id);
      if (result==IDYES) {
         _project_disable_auto_build(true);
         status=save();
         _project_disable_auto_build(false);
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }
   }
   return(0);
}

static int ReloadBuffer(_str Filename)
{
   int view_id=p_window_id;
   _str options='';
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();

   int status=load_files('+b 'Filename);
   if (status) {
      _message_box(nls("Unable to reload %s",Filename)"\n\n"get_message(status));
      return(FILE_NOT_FOUND_RC);
   }
   if (p_buf_width==1) {
      options='+LW';
   } else if (p_buf_width) {
      options='+'p_buf_width;
   }
   _str buf_name=p_buf_name;
   int buf_id=p_buf_id;
   boolean modify=p_modify;
   int oldp_line_numbers_len=p_line_numbers_len;
   typeless bfiledate=_file_date(p_buf_name,'B');
   activate_window(view_id);_set_focus();

   /* Make a view&buffer windows list which contains window and position info. */
   /* for all windows. */
   _str noption='';
   int temp_view_id=_list_bwindow_pos(buf_id);
   activate_window(VSWID_HIDDEN);
   // Use def_load_options for network,spill, and undo options. */
   status=load_files(def_load_options:+' +q +d +r +l ':+options' ':+maybe_quote_filename(Filename));
   if (status) {
      if (status==NEW_FILE_RC) {
         status=FILE_NOT_FOUND_RC;
         _delete_buffer();
      }
      activate_window(view_id);_set_focus();
      _message_box(nls("Unable to reload %s",Filename)"\n\n"get_message(status));
      p_file_date=(long)bfiledate;
   } else {
      p_line_numbers_len=oldp_line_numbers_len;
      // Need to do an add buffer here so the debugging
      // information is updated.
      // load_files with +r options calls the delete buffer
      // callback.  Here we read this buffer.
      call_list('_internal_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      call_list('_buffer_add_',p_buf_id,p_buf_name,p_buf_flags);
      _set_bwindow_pos(temp_view_id);
      noption='';
   }
   if (temp_view_id!='') {
      _delete_temp_view(temp_view_id);
   }
   p_window_id=view_id;
   return(0);
}

int _UpdateFileBitmaps(_str filename1,int &index1,int Tree1WID,
                       _str filename2,int &index2,int Tree2WID,
                       int FilesMatch=0,boolean DoEnableButtons=true)
{
   int pindex=0;
   if (!index1) {
      pindex=Tree1WID._TreeSearch(TREE_ROOT_INDEX,_strip_filename(filename1,'N'),'t'_fpos_case);
      if (pindex<0) {
         return(1);
      }
      index1=Tree1WID._TreeSearch(pindex,_strip_filename(filename1,'P'),_fpos_case);
   }
   if (!index2) {
      pindex=Tree2WID._TreeSearch(TREE_ROOT_INDEX,_strip_filename(filename2,'N'),'t'_fpos_case);
      if (pindex<0) {
         return(1);
      }
      index2=Tree2WID._TreeSearch(pindex,_strip_filename(filename2,'P'),_fpos_case);
   }
   int orig_wid=p_window_id;
   int wid=p_active_form;
   int filestatus=0;
   boolean inmem1=1;
   boolean inmem2=1;
   int status1=0;
   int status2=0;
   int viewid1=0;
   int viewid2=0;
   int orig_view_id=0;
   int junk_view_id=0;
   if (!FilesMatch) {
      status1=_mdi.p_child._open_temp_view(filename1,viewid1,orig_view_id,'',inmem1);
      if (status1) {
         orig_wid=p_window_id;
         return(status1);
      }
      status2=_mdi.p_child._open_temp_view(filename2,viewid2,junk_view_id,'',inmem2);
      if (status2) {
         orig_wid=p_window_id;
         return(status2);
      }
      p_window_id=orig_view_id;
      long seek1,seek2;
      seek1=seek2=0;
      int line1=0,line2=0;
      int NCSStatus1=0,NCSStatus2=0;
      if (def_diff_options&DIFF_LEADING_SKIP_COMMENTS) {
         NCSStatus1=_GetNonCommentSeek(viewid1,seek1,line1);
         NCSStatus2=_GetNonCommentSeek(viewid2,seek2,line2);
      }

      //If both of these are STRING_NOT_FOUND_RC we know that the file is all comments
      if (NCSStatus1==STRING_NOT_FOUND_RC &&
          NCSStatus2==STRING_NOT_FOUND_RC) {
         filestatus=0;
      }else{
         if (!(def_diff_options&FORCE_PROCESS_OPTIONS)&&
             !(def_diff_options&DIFF_DONT_COMPARE_EOL_CHARS)) {
            filestatus=FastCompare(viewid1,seek1,viewid2,seek2);
         }else{
            filestatus=Diff(viewid1,viewid2,
                            def_diff_options|DIFF_OUTPUT_BOOLEAN|DIFF_NO_BUFFER_SETUP,
                            0,
                            0,0,//Do nothing
                            def_load_options,0,
                            0,//This is pass by reference
                            def_max_fast_diff_size,
                            line1,line2,
                            def_smart_diff_limit,
                            null);
         }
      }
      if (inmem1) {
         p_window_id=viewid1;_delete_window();
      }else{
         _delete_temp_view(viewid1);
      }
      if (inmem2) {
         p_window_id=viewid2;_delete_window();
      }else{
         _delete_temp_view(viewid2);
      }
   }
   p_window_id=wid;
   int state1=0;
   int state2=0;
   int bmindex=0;
   Tree1WID._TreeGetInfo(index1,state1);
   Tree2WID._TreeGetInfo(index2,state2);
   if (filestatus) {
      bmindex=_pic_filed2;
   }else{
      bmindex=_pic_file_match;
   }
   int flags=0;
   if (bmindex==_pic_file_match) {
      if (!(GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES)) flags=TREENODE_HIDDEN;
   }else if (bmindex==_pic_filed2) {
      if (!(GMFDiffViewOptions&DIFF_VIEW_VIEWED_FILES)) flags=TREENODE_HIDDEN;
   }
   Tree1WID._TreeSetInfo(index1,state1,bmindex,bmindex,flags);
   Tree2WID._TreeSetInfo(index2,state2,bmindex,bmindex,flags);
   if (DoEnableButtons) Tree1WID.p_parent.EnableButtons();
   p_window_id=orig_wid;
   return(0);
}

static void GetFileListFromTree2(int index,
                                 int (&DestIndexList)[],
                                 boolean Recursive,
                                 boolean IncludeMissing,
                                 boolean IncludeOnly)
{
   /*
   "IncludeOnly" means include files that only exist on one side
   */
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _str Caption=_TreeGetCaption(index);
   DestIndexList[DestIndexList._length()]=index;
   index=_TreeGetFirstChildIndex(index);
   for (;;) {
      if (index<0) break;
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (!(flags&TREENODE_HIDDEN)) break;
      index=_TreeGetNextSiblingIndex(index);
   }
   _str Filename='';
   for (;;) {
      if (index<0) break;
      Filename=_TreeGetCaption(index);
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (last_char(Filename)==FILESEP) {
         if (Recursive) {
            GetFileListFromTree2(index,DestIndexList,Recursive,IncludeMissing,IncludeOnly);
         }
      }else{
         if ( (bm1==_pic_filem && IncludeMissing) ||
              (bm1==_pic_filep && IncludeOnly) ||
              (bm1!=_pic_filem && bm1!=_pic_filep) ) {
            DestIndexList[DestIndexList._length()]=index;
         }
      }
      for (;;) {
         index=_TreeGetNextSiblingIndex(index);
         if (index<0) break;
         _TreeGetInfo(index,state,bm1,bm2,flags);
         if (!(flags&TREENODE_HIDDEN)) break;
      }
   }
}

static void MyCopyTree(int SourceTreeWID,int SourceIndex,
                       int DestTreeWID,  int DestIndex)
{
   _str path1=SourceTreeWID._TreeGetCaption(SourceIndex);
   _str path2=DestTreeWID._TreeGetCaption(DestIndex);
   typeless result=show('-modal _vc_auto_inout_form',
               "Copy '"path1"' to '"path2"'?",
               'Recursive');
   if (result!=IDYES) return;
   boolean CopyRecursive=_param1;
   _AppendToDiffReport(DIFF_REPORT_COPY_TREE,path1,path2);

   int SourceIndexList[];
   SourceIndexList._makeempty();
   int DestIndexList[];
   DestIndexList._makeempty();
   SourceTreeWID.GetFileListFromTree2(SourceIndex,SourceIndexList,CopyRecursive,0,1);
   DestTreeWID.GetFileListFromTree2(DestIndex,DestIndexList,CopyRecursive,1,0);

   typeless status=0;
   _str SourcePath='';
   _str SourceFilename='';
   _str SourceRFilename='';
   _str DestPath='';
   _str DestRFilename='';
   _str DestFilename='';
   int i;
   for (i=0;i<SourceIndexList._length();++i) {
      SourcePath=SourceTreeWID._TreeGetCaption(SourceTreeWID._TreeGetParentIndex(SourceIndexList[i]));
      SourceRFilename=SourceTreeWID._TreeGetCaption(SourceIndexList[i]);
      if (last_char(SourceRFilename)==FILESEP) {
         SourceFilename=SourceRFilename;
      }else{
         SourceFilename=SourcePath:+SourceRFilename;
      }

      DestPath=DestTreeWID._TreeGetCaption(DestTreeWID._TreeGetParentIndex(DestIndexList[i]));
      DestRFilename=DestTreeWID._TreeGetCaption(DestIndexList[i]);
      if (last_char(DestRFilename)==FILESEP) {
         DestFilename=DestRFilename;
      }else{
         DestFilename=DestPath:+DestRFilename;
      }
      if (last_char(SourceFilename)==FILESEP) {
         //These are paths
         if (file_match(maybe_quote_filename(DestFilename:+ALLFILES_RE),1)=='') {
            status=make_path(DestFilename);
         }
         if (status) {
            _message_box(nls("Could not create path '%s'",DestFilename));
         }else{
            SourceTreeWID.SetMatchingBitmap(SourceIndexList[i],_pic_fldopen);
            DestTreeWID.SetMatchingBitmap(DestIndexList[i],_pic_fldopen);
         }
      }else{
         status=copy_file(SourceFilename,DestFilename);
         if (status) {
            result=_message_box(nls("Could not copy file '%s' to '%s'\n%s\n\nContinue?",SourceFilename,DestFilename,get_message(status)),'',MB_YESNOCANCEL);
            if (result!=IDYES) break;
         }else{
            SourceTreeWID.SetMatchingBitmap(SourceIndexList[i],_pic_file);
            DestTreeWID.SetMatchingBitmap(DestIndexList[i],_pic_file);
         }
      }
   }
   clear_message();
}

static void SetMatchingBitmap(int index,int NewBitmap)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   if (!(GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES) &&
       NewBitmap==_pic_file) {
      flags|=TREENODE_HIDDEN;
   }
   _TreeSetInfo(index,state,NewBitmap,NewBitmap,flags);
}

static void MyDeleteTree(int SourceTreeWID,int SourceIndex,
                         int DestTreeWID,  int DestIndex)
{
   _str SourceFileList[],DestFileList[];
   int SourceFolderIndexList[],SourceFileIndexList[];
   int DestFolderIndexList[],DestFileIndexList[];
   //RELAX!!!We have already been prompted before this call
   //SourceTreeWID.GetFileListFromTree(SourceIndex,SourceFileList,SourceFolderIndexList,SourceFileIndexList);
   int IndexList[];IndexList._makeempty();
   int DestIndexList[];DestIndexList._makeempty();
   SourceTreeWID.GetFileListFromTree2(SourceIndex,IndexList,1,0,1);
   DestTreeWID.GetFileListFromTree2(DestIndex,DestIndexList,1,1,0);
   _AppendToDiffReport(DIFF_REPORT_DELETE_TREE,SourceTreeWID._TreeGetCaption(SourceIndex));

   typeless status=0;
   typeless result=0;
   _str DirList[];
   _str filename='';
   int index=0;
   int i;
   for (i=0;i<IndexList._length();++i) {
      index=IndexList[i];
      filename=SourceTreeWID._TreeGetCaption(index);
      if (last_char(filename)==FILESEP) {
         DirList[DirList._length()]=maybe_quote_filename(_file_case(_strip_filename(filename,'N')))' 'IndexList[i]' 'DestIndexList[i];
      }else{
         filename=SourceTreeWID._TreeGetCaption(SourceTreeWID._TreeGetParentIndex(index)):+filename;
         status=delete_file(filename);
         if (status) {
            result=_message_box(nls("Could not delete file %s\n%s\n\nContinue?",filename,get_message(status)),'',MB_YESNOCANCEL|MB_ICONQUESTION);
            if (result!=IDYES) break;
         }else{
            _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,filename);
            SourceTreeWID._TreeDelete(IndexList[i]);
            DestTreeWID._TreeDelete(DestIndexList[i]);
         }
      }
   }

   //Start at the end of the array, these paths have to be deleted first
   typeless SourceDirIndex='';
   typeless DestDirIndex='';
   for (i=DirList._length()-1;i>=0;--i) {
      _str dirName=parse_file(DirList[i]);
      status=rmdir(dirName);
      if (status) {
         result=_message_box(nls("Could not remove directory %s1\n%s2\nContinue?",dirName,get_message(status)),'',MB_YESNOCANCEL|MB_ICONQUESTION);
         if (result!=IDYES) break;
      }else{
         _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,i);
         parse DirList[i] with SourceDirIndex DestDirIndex;
         SourceTreeWID._TreeDelete(SourceDirIndex);
         DestTreeWID._TreeDelete(DestDirIndex);
      }
   }
   clear_message();
   //Should not hurt anything to delete the whole thing even if we couldn't
   //delete a directory
   //SourceTreeWID._TreeDelete(SourceIndex);
   //DestTreeWID._TreeDelete(DestIndex);
}

int def_vcflags;
static int ShowOnlyFile(int FileIndex)
{
   if (_IsFunctionIndex(FileIndex)) {
      int FunctionIndex=FileIndex;
      FileIndex=_TreeGetParentIndex(FunctionIndex);
      int PathIndex=_TreeGetParentIndex(FileIndex);
      _str Filename=_TreeGetCaption(PathIndex):+_TreeGetCaption(FileIndex);
      _str Range=_TreeGetUserInfo(FunctionIndex);
      typeless FirstLine='';
      typeless LastLine='';
      typeless NewBufId=0;
      int NewViewId=0;
      int BufId=0;
      int markid=0;
      boolean inmem=false;
      parse Range with FirstLine ',' LastLine;
      int status=_DiffLoadFileAndGetRegionView(Filename,false,false,FirstLine,LastLine,false,NewBufId,BufId,markid,inmem,NewViewId,false,true,false);
      int oldvcflags=def_vcflags;
      def_vcflags&=~VCF_AUTO_CHECKOUT;
      show('-modal _showbuf_form',NewBufId,Filename,'',1);
      def_vcflags=oldvcflags;
      _delete_temp_view(NewViewId);
      if (!inmem) {
         int orig_view_id=p_window_id;
         p_window_id=VSWID_HIDDEN;
         _safe_hidden_window();
         status=load_files('+bi 'BufId);
         if (!status) {
            _delete_buffer();
         }
         p_window_id=orig_view_id;
      }
      return(status);
   }else{
      int PathIndex=_TreeGetParentIndex(FileIndex);
      if (PathIndex<0) return(1);
      _str Filename=_TreeGetCaption(PathIndex):+_TreeGetCaption(FileIndex);
      return(_DiffShowFile(Filename));
   }
}

int _DiffShowFile(_str Filename,_str caption='')
{
   int orig_view_id=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   int inmem=1;
   int bid=-1;
   int status=load_files('+q +b 'Filename);
   if (status) {
      inmem=0;
      status=load_files('+q 'maybe_quote_filename(Filename));
      if (status) {
         p_window_id=orig_view_id;
         return(status);
      }
      _SetEditorLanguage();
   }
   bid=p_buf_id;
   p_window_id=orig_view_id;
   int oldvcflags=def_vcflags;
   def_vcflags&=~VCF_AUTO_CHECKOUT;
   if ( caption=='' ) {
      caption=Filename;
   }
   show('-modal _showbuf_form',bid,caption,'',1);
   def_vcflags=oldvcflags;
   p_window_id=VSWID_HIDDEN;
   //Be sure that we are deleting the right buffer, a timer function could
   //have changed what is here!!!
   status=load_files('+bi 'bid);
   if (!inmem) {
      if (!status) {
         _delete_buffer();
      }
   }
   p_window_id=orig_view_id;
   return(status);
}

static int GetFilenameFromIndex(int index,_str &Filename)
{
   Filename=_TreeGetCaption(index);
   int PathIndex=_TreeGetParentIndex(index);
   if (PathIndex<0) return(1);
   Filename=_TreeGetCaption(PathIndex):+Filename;
   return(0);
}

//10:17am 9/11/1998
//wid is actually the active wid when we get called, but it just seemed
//weird to only pass in one...
static int GetSourceAndDestFilename(int wid,int otherwid,int index,
                                    int &OtherIndex,_str &SourceFilename,
                                    _str &DestFilename,boolean &FilesExist)
{
   int origwid=p_window_id;
   p_window_id=wid;

   int status=GetFilenameFromIndex(index,SourceFilename);
   if (status) {
      p_window_id=origwid;
      return(status);
   }

   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int linenum=0;
   _TreeGetInfo(index,state,bm1,bm2,flags,linenum);
   p_window_id=otherwid;
   int DestIndex=_TreeGetIndexFromLineNumber(linenum);
   if (DestIndex<0) return(1);
   OtherIndex=DestIndex;
   status=GetFilenameFromIndex(DestIndex,DestFilename);
   if (bm1==_pic_filem) {
      _str temp=SourceFilename;
      SourceFilename=DestFilename;
      DestFilename=temp;
      FilesExist=false;
   }else if (bm1==_pic_filep) {
      //_str temp=DestFilename;
      //DestFilename=SourceFilename;
      //SourceFilename=temp;
      FilesExist=false;
   }else if (bm1==_pic_filed ||
             bm1==_pic_filed2||
             bm1==_pic_file_match) {
      FilesExist=true;
   }
   p_window_id=origwid;
   return(0);
}

static void DeselectNode(int index)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeDeselectLine(index);
}

static boolean PathExists(_str Path)
{
   _maybe_append_filesep(Path);
   _str WPath=Path:+ALLFILES_RE;
   _str match=file_match(WPath' +p +d',1);
   return(match!='');
}

static void CopySelectedFiles(_str ButtonName)
{
   int OrigWID=p_window_id;
   int SelTreeWid=tree1;
   p_window_id=tree1;
   int NumSelected=_TreeGetNumSelectedItems();

   int CurTreeWID=tree1;
   int otherwid=tree2;

   if (!NumSelected) {
      NumSelected=tree2._TreeGetNumSelectedItems();
      SelTreeWid=tree2;
   }
   if (ButtonName=='ctlcopy_left') {
       p_window_id=tree2;
       otherwid=tree1;
   }
   if (!NumSelected) {
      p_window_id=OrigWID;
      return;
   }
   int wid=0;
   int index=0;
   int status=0;
   int result=0;
   int viewid1=0;
   int viewid2=0;
   int OtherIndex=0;
   _str PathTable:[];
   typeless buf1=0;
   typeless buf2=0;
   boolean inmem1=0;
   boolean inmem2=0;
   int orig_view_id=0;
   int junk_view_id=0;
   PathTable._makeempty();
   boolean SelectCurrentNodeWhenDone=false;
   int OrigIndex=_TreeCurIndex();
   int info;
   INTARRAY deselectList1;
   INTARRAY deselectList2;
   for (ff:=1;;ff=0) {
      index=SelTreeWid._TreeGetNextSelectedIndex(ff,info);
      if (index<0) {
         break;
      }
      _str SourceFilename,DestFilename;
      boolean FileExists=false;
      status=GetSourceAndDestFilename(p_window_id,otherwid,index,
                                      OtherIndex,SourceFilename,DestFilename,
                                      FileExists);
#if 0 //2:30pm 4/16/1999
      if (FileExists) {
         if ( (p_window_id==tree1 && OrigWID==ctlcopy_left) ||
              (p_window_id==tree2 && OrigWID==ctlcopy_right ) ) {
            temp=SourceFilename;
            SourceFilename=DestFilename;
            DestFilename=temp;
         }
      }
#endif
      if (status) {
         result=_message_box(nls("Could not copy '%s' to '%s'\n\n%s\n\nContinue?",SourceFilename,DestFilename,get_message(status)),'',MB_YESNOCANCEL);
         if (result!=IDYES) {
            p_window_id=OrigWID;
            return;
         }
         continue;
      }
      /*
      Because someone could be editing
         1. If there is a buffer for the source file, diff the bufffer with
            the file on disk.  If the two do not match, prompt the user to
            save the buffer before copying.

         2. If there is a buffer for the destination file, and it is modified,
            allow the user to cancel before performing the copy.
      */
      mou_hour_glass(1);

      buf1=buf_match(absolute(SourceFilename),1)!='';
      buf2=buf_match(absolute(DestFilename),1)!='';

      int filestatus=0;
      {
         //Ok, to REALLY do this right, we have to be sure that the buffer actually
         //matches the file on disk.  We don't have to worry about any diff
         //options, just run the FastCompare.
         wid=p_window_id;
         inmem1=inmem2=1;
         status=_mdi.p_child._open_temp_view(SourceFilename,viewid1,orig_view_id,'+b');
         if (!status) {
            status=_mdi.p_child._open_temp_view(SourceFilename,viewid2,junk_view_id,'+d');
            if (!status) {
               p_window_id=orig_view_id;
               long seek1,seek2;
               seek1=seek2=0;
               int line1=0,line2=0;
               filestatus=FastCompare(viewid1,seek1,viewid2,seek2);
               _delete_temp_view(viewid2);
            }
            p_window_id=orig_view_id;
            _delete_temp_view(viewid1);
            p_window_id=wid;
         }
         p_window_id=wid;
      }

      if (buf1) {
         MaybeSaveBuffer(SourceFilename,filestatus);
      }

      if (buf2) {
         status=MaybeWarnModified(DestFilename);
         if (status) {
            p_window_id=OrigWID;
            return;
         }
      }

      if (!FileExists) {
         _str DestPath=_strip_filename(DestFilename,'N');
         if (!PathTable._indexin(DestPath) ) {
            if (!PathExists(DestPath)) {
               status=make_path(DestPath);
               if (!status) {
                  PathTable:[_file_case(DestPath)]=DestPath;
               }
               //I'm not going to stop if we get a status, we'll let the
               //user decide when the file cannot be copied
            }else{
               PathTable:[_file_case(DestPath)]=DestPath;
            }
         }
      }
      status=copy_file(SourceFilename,DestFilename);
      mou_hour_glass(0);

      if (buf2) {
         ReloadBuffer(DestFilename);
      }

      if (status) {
         result=_message_box(nls("Could not copy '%s' to '%s'\n\n%s\n\nContinue?",SourceFilename,DestFilename,get_message(status)),'',MB_YESNOCANCEL);
         if (result!=IDYES) {
            p_window_id=OrigWID;
            return;
         }
      }else{
         _UpdateFileBitmaps(SourceFilename,index,wid,
                            DestFilename,OtherIndex,otherwid,0,false);
         _AppendToDiffReport(DIFF_REPORT_COPY_FILE,SourceFilename,DestFilename);

         // Can't deselect right now because that will cause us to refresh the
         // selected items
         deselectList1[deselectList1._length()] = index;
         deselectList2[deselectList2._length()] = OtherIndex;
         SelectCurrentNodeWhenDone=true;
      }
   }
   p_window_id = tree1;
   for ( i:=0;i<deselectList1._length();++i) {
      _TreeDeselectLine(deselectList1[i]);
   }
   p_window_id = tree2;
   for ( i=0;i<deselectList2._length();++i) {
      _TreeDeselectLine(deselectList2[i]);
   }
   if (def_diff_edit_options&DIFFEDIT_AUTO_JUMP &&
       _TreeCurIndex()==OrigIndex) {
      ctlnext_mismatch.call_event(ctlnext_mismatch,LBUTTON_UP);
   }
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   if (SelectCurrentNodeWhenDone) {
      int ci=_TreeCurIndex();
      if (ci>=0) {
         _TreeSelectLine(ci);
      }

      ci=_TreeCurIndex();
   }
   p_window_id=OrigWID;
}

static int OverlaySymbol(_str SymbolName,
                         _str SourceFilename,_str DestFilename,
                         _str SourceInfo,_str DestInfo,boolean flip)
{
   int result=_message_box(nls("Replace '%s' from '%s' with '%s' from '%s'?",SymbolName,DestFilename,SymbolName,SourceFilename),'',MB_YESNOCANCEL);
   if (result!=IDYES) {
      return(COMMAND_CANCELLED_RC);
   }
   int source_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(SourceFilename,source_view_id,orig_view_id);
   if (status) return(status);
   int dest_view_id=0;
   typeless junk;
   _open_temp_view(DestFilename,dest_view_id,junk);
   if (status) return(status);

   typeless StartLineSource='';
   typeless EndLineSource='';
   typeless StartLineDest='';
   typeless EndLineDest='';
   parse SourceInfo with StartLineSource ',' EndLineSource;
   parse DestInfo with StartLineDest ',' EndLineDest;

   int markid=_alloc_selection();

   p_window_id=dest_view_id;
   p_line=StartLineDest;
   _select_line(markid);
   p_line=EndLineDest;
   status=_select_line(markid);
   if (status) {
      clear_message();
   }
   _delete_selection(markid);
   if (p_line!=p_Noflines) {
      up();
   }

   p_window_id=source_view_id;
   p_line=StartLineSource;
   _select_line(markid);
   p_line=EndLineSource;
   status=_select_line(markid);
   if (status) {
      clear_message();
   }

   p_window_id=dest_view_id;
   _copy_to_cursor(markid);

   _free_selection(markid);
   status=save();
   p_window_id=orig_view_id;

   if (flip) {
      _DiffExpandTags2(dest_view_id.p_buf_id,
                       source_view_id.p_buf_id,
                       tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                       tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                       '+bi','+bi');
   }else{
      _DiffExpandTags2(source_view_id.p_buf_id,
                       dest_view_id.p_buf_id,
                       tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                       tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                       '+bi','+bi');
   }

   _delete_temp_view(source_view_id);
   _delete_temp_view(dest_view_id);

   return(status);
}

static _str GetLexerName(_str Filename)
{
   lang := _Filename2LangId(Filename);
   return _LangId2LexerName(lang);
}

static void DiffGetAllComments(_str Filename,_str (&Comments)[],_str FieldName)
{
   _str LexerName=GetLexerName(Filename);
   _str SystemFile='';
   _str UserFile='';
   parse LEXER_FILE_LIST with SystemFile (PATHSEP) UserFile;

   _ini_get_all_values(UserFile,LexerName,FieldName,Comments);

   if (Comments._length()) {
      return;
   }

   Comments=null;
   _ini_get_all_values(SystemFile,LexerName,FieldName,Comments);
}

static int DiffDeleteSymbol(_str Filename,_str SymbolName,_str Range,_str SourceFilename,
                            boolean FlipSourceDest=false)
{
   _str Comments[]=null;
   DiffGetAllComments(Filename,Comments,"linecomment");
   COMMENT_TYPE CommentInfo[]=null;
   int i;
   for (i=0;i<Comments._length();++i) {
      COMMENT_TYPE cur=_process_comment('linecomment='Comments[i]);
      if (cur.delim1!='') {
         CommentInfo[CommentInfo._length()]=cur;
      }
   }

   Comments=null;
   DiffGetAllComments(Filename,Comments,"mlcomment");
   for (i=0;i<Comments._length();++i) {
      COMMENT_TYPE cur=_process_comment('mlcomment='Comments[i]);
      if (cur.delim1!='' && cur.nesting) {
         CommentInfo[CommentInfo._length()]=cur;
      }
   }
   if (!CommentInfo._length()) {
      _message_box(nls("This symbol cannot be deleted because there is not a suitable comment type."));
      return(1);
   }

   _str CommentDescriptions[]=null;
   for (i=0;i<CommentInfo._length();++i) {
      CommentDescriptions[i]=GetCommentDescription(&(CommentInfo[i]));
   }
   typeless status=show('-modal _diff_delete_symbol_form',CommentDescriptions,Range);
   if (status=='') {
      return(COMMAND_CANCELLED_RC);
   }
   int result=_message_box(nls("Save changes to '%s'",Filename),'',MB_YESNOCANCEL);
   if (result!=IDYES) {
      return(COMMAND_CANCELLED_RC);
   }
   int temp_view_id=0;
   int orig_view_id=0;
   status=_open_temp_view(Filename,temp_view_id,orig_view_id);
   if (status) {
      return(status);
   }
   int index=0;
   int column=0;
   int bufid=p_buf_id;
   typeless markid=0;
   typeless sln='';
   typeless eln='';
   parse Range with sln ',' eln;
   if (_param1<0) {
      p_line=sln;
      markid=_alloc_selection();
      p_line=sln;
      _select_line(markid);
      p_line=eln;
      status=_select_line(markid);
      if (status) clear_message();
      _delete_selection(markid);
   }else{
      index=_param1-1;
      if (index>=0) {
         //If this ever comes back 0, something really weird happened.
         if (CommentInfo[index].delim2=='') {
            p_line=sln;
            column=1;
            if (CommentInfo[index].startcol) {
               column=CommentInfo[index].startcol;
            }
            for (i=sln;i<=eln;++i) {
               p_col=column;
               _insert_text(CommentInfo[index].delim1' DEL ');
               down();
            }
         }else{
            p_line=sln;
            p_col=1;
            _insert_text(CommentInfo[index].delim1);
            p_line=eln;
            _end_line();
            _insert_text(CommentInfo[index].delim2);
         }
      }
   }
   status=save();
   p_window_id=orig_view_id;

   if (FlipSourceDest) {
      _DiffExpandTags2('',
                       SourceFilename,
                       tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                       tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                       '+bi 'bufid,'');
   }else{
      _DiffExpandTags2(SourceFilename,
                       '',
                       tree1._TreeGetParentIndex(tree1._TreeCurIndex()),
                       tree2._TreeGetParentIndex(tree2._TreeCurIndex()),
                       '','+bi 'bufid);
   }
   _delete_temp_view(temp_view_id);


   return(status);
}

static _str GetCommentDescription(COMMENT_TYPE *pCommentInfo)
{
   _str Desc='';
   if (pCommentInfo->delim2=='') {
      //This is a line comment type
      Desc=pCommentInfo->delim1' DEL ';
      if (pCommentInfo->startcol) {
         Desc=Desc' starting in column 'pCommentInfo->startcol;
      }else{
         Desc=Desc' starting in column 1';
      }
   }else{
      Desc='Use 'pCommentInfo->delim1' 'pCommentInfo->delim2' to comment out symbol';
   }
   return(Desc);
}

//This function uses inheritance so that it actually works for the ctlleft
//button, the ctlright button, the ctlcopy_right button, and the ctlcopy_left
//button
void ctlleft.lbutton_up()
{
   if (!p_enabled) {
      return;
   }
   GModified=1;
   int curindex=0;
   int curindex1=0;
   int curindex2=0;
   int sourceTreeWID=( (p_window_id==ctlleft||p_window_id==ctlcopy_right) ?tree1:tree2);
   int destTreeWID=  ( (p_window_id==ctlleft||p_window_id==ctlcopy_right) ?tree2:tree1);
   if (p_caption==DIFF_CAPTION||
       p_caption==DIFF_CAPTION2||
       p_caption==VIEW_CAPTION) {
      curindex=tree1._TreeCurIndex();
      curindex2=tree2._TreeCurIndex();
   }else{
      curindex=sourceTreeWID._TreeCurIndex();
      curindex2=destTreeWID._TreeCurIndex();
   }

   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int index1=0;
   int index2=0;
   int HidNodes=0;
   int pi=sourceTreeWID._TreeGetParentIndex(curindex);
   int pi2=destTreeWID._TreeGetParentIndex(curindex2);
   if (pi==TREE_ROOT_INDEX) {
      switch (p_caption) {
      case COPY_TREE_RIGHT_CAPTION:
      case COPY_TREE_LEFT_CAPTION:
         index1=tree1._TreeCurIndex();
         index2=tree2._TreeCurIndex();
         mou_hour_glass(1);
         MyCopyTree(sourceTreeWID,curindex,destTreeWID,curindex2);
         mou_hour_glass(0);
         tree1.MaybeHideNode(tree1._TreeGetParentIndex(index1));
         tree2.MaybeHideNode(tree2._TreeGetParentIndex(index2));

         tree1._TreeGetInfo(index1,state,bm1,bm2,flags);
         //Move to next mismatch
         if (!(flags&TREENODE_HIDDEN) && def_diff_edit_options&DIFFEDIT_AUTO_JUMP) {
            ctlnext_mismatch.call_event(ctlnext_mismatch,LBUTTON_UP);
            tree1._set_focus();
         }
         return;
      default:
         //Only tree copy is valid in this case
         return;
      }
   }

   _str Path1='';
   _str File1='';
   _str Path2='';
   _str File2='';
   if (p_caption==DIFF_CAPTION ||
       p_caption==DIFF_CAPTION2||
       p_caption==VIEW_CAPTION ||
       p_caption==VIEW_CAPTION2) {
      sourceTreeWID._TreeGetInfo(curindex,state,bm1,bm2,flags);
      if (bm1==_pic_symbol   ||
          bm1==_pic_symbold  ||
          bm1==_pic_symbold2 ||
          bm1==_pic_symbolmoved) {
         int wid=p_window_id;
         p_window_id=tree1;
         int gpi1=_TreeGetParentIndex(pi);
         Path1=_TreeGetCaption(gpi1);
         File1=_TreeGetCaption(pi);

         p_window_id=tree2;
         int gpi2=_TreeGetParentIndex(pi2);
         Path2=_TreeGetCaption(gpi2);
         File2=_TreeGetCaption(pi2);
         p_window_id=wid;
      }else{
         Path1=tree1._TreeGetCaption(pi);
         File1=tree1._TreeGetCaption(tree1._TreeCurIndex());

         Path2=tree2._TreeGetCaption(tree2._TreeGetParentIndex(curindex2));
         File2=tree2._TreeGetCaption(tree2._TreeCurIndex());
      }
   }else{
      Path1=sourceTreeWID._TreeGetCaption(pi);
      File1=sourceTreeWID._TreeGetCaption(sourceTreeWID._TreeCurIndex());

      Path2=destTreeWID._TreeGetCaption(destTreeWID._TreeGetParentIndex(curindex2));
      File2=destTreeWID._TreeGetCaption(destTreeWID._TreeCurIndex());
   }
   _str iniRestoreOption='';
   if ( _GetDialogInfo(RESTORE_FROM_INI) ) {
      iniRestoreOption='-restorefromini';
   }

   int fid=0;
   typeless result=0;
   typeless StartLine=0;
   typeless EndLine=0;
   typeless InitDestLine=0;
   switch (p_caption) {
   case DELETE_SYMBOL_CAPTION:
      {
         int gpi=sourceTreeWID._TreeGetParentIndex(pi);
         int gpi2=destTreeWID._TreeGetParentIndex(pi2);
         _str SourceFilename=sourceTreeWID._TreeGetCaption(gpi):+sourceTreeWID._TreeGetCaption(pi);
         _str DestFilename=destTreeWID._TreeGetCaption(gpi2):+destTreeWID._TreeGetCaption(pi2);
         _str symbol=destTreeWID._TreeGetCaption(curindex2);
         DiffDeleteSymbol(DestFilename,symbol,destTreeWID._TreeGetUserInfo(curindex2),SourceFilename,tree1==destTreeWID);
      }
      break;
   case COPY_SYMBOL_LEFT_CAPTION:
   case COPY_SYMBOL_RIGHT_CAPTION:
      {
         int gpi=sourceTreeWID._TreeGetParentIndex(pi);
         int gpi2=destTreeWID._TreeGetParentIndex(pi2);
         _str SourceFilename=sourceTreeWID._TreeGetCaption(gpi):+sourceTreeWID._TreeGetCaption(pi);
         _str DestFilename=destTreeWID._TreeGetCaption(gpi2):+destTreeWID._TreeGetCaption(pi2);
         _str symbol=sourceTreeWID._TreeGetCaption(curindex);

         sourceTreeWID._TreeGetInfo(curindex,state,bm1);
         mou_hour_glass(1);
         if (bm1==_pic_symbold) {
            _str SourceInfo=sourceTreeWID._TreeGetUserInfo(curindex);
            _str DestInfo=destTreeWID._TreeGetUserInfo(curindex2);
            OverlaySymbol(symbol,SourceFilename,DestFilename,SourceInfo,DestInfo,destTreeWID==tree1);
         }else{
            _str val=sourceTreeWID._TreeGetUserInfo(curindex);
            parse val with StartLine ',' EndLine;
            int status=_DiffTagGetInitDestLine(_DiffTagInfoGetIndex(sourceTreeWID,SourceFilename),
                                               _DiffTagInfoGetIndex(destTreeWID,DestFilename),
                                               symbol,InitDestLine);
            if (status) {
               InitDestLine=-1;
            }
            status=_DiffInsertSymbol(SourceFilename,
                                     symbol,
                                     StartLine,
                                     EndLine,
                                     DestFilename,
                                     sourceTreeWID,
                                     destTreeWID,
                                     p_caption==COPY_SYMBOL_LEFT_CAPTION,
                                     InitDestLine);
            if (status=='') {
               mou_hour_glass(0);
               return;
            }
         }
         mou_hour_glass(0);
         break;
      }
   case DELETE_TREE_CAPTION:
      Path2=destTreeWID._TreeGetCaption(destTreeWID._TreeCurIndex());
      result=_message_box(nls("Are you sure you wish to remove the directory '%s'?",Path2),
                          '',MB_YESNOCANCEL|MB_ICONQUESTION);
      if (result==IDYES) {
         MyDeleteTree(destTreeWID,curindex2,sourceTreeWID,curindex);
      }
      break;
   case DIFF_CAPTION:
   case DIFF_CAPTION2:
      {
         curindex1=tree1._TreeCurIndex();
         int pindex1=tree1._TreeGetParentIndex(curindex1);

         curindex2=tree2._TreeCurIndex();
         int pindex2=tree2._TreeGetParentIndex(curindex2);

         if (!tree1._IsFunctionIndex(curindex1)) {
            fid=p_active_form;
            _str AutoCloseOption=(def_diff_edit_options&DIFFEDIT_AUTO_CLOSE)?' -autoclose ':'';
            _mdi.p_child.diff(iniRestoreOption' -RegisterAsMFDChild 'fid' -nomapping  -RefreshTagsClose 'curindex1' 'curindex2' 'AutoCloseOption' 'maybe_quote_filename(Path1:+File1)' 'maybe_quote_filename(Path2:+File2));
            _AppendToDiffReport(DIFF_REPORT_DIFF,Path1:+File1,Path2:+File2);
            break;
         }else{
            fid=p_active_form;

            _str range1=tree1._TreeGetUserInfo(curindex1);
            _str range2=tree2._TreeGetUserInfo(curindex2);

            //gpindexX is for "Grandparent", not "global"
            int gpindex1,gpindex2;

            File1=tree1._TreeGetCaption(pindex1);
            File2=tree2._TreeGetCaption(pindex2);

            gpindex1=tree1._TreeGetParentIndex(pindex1);
            gpindex2=tree2._TreeGetParentIndex(pindex2);

            Path1=tree1._TreeGetCaption(gpindex1);
            Path2=tree2._TreeGetCaption(gpindex2);

            _str AutoCloseOption=(def_diff_edit_options&DIFFEDIT_AUTO_CLOSE)?' -autoclose ':'';
            _mdi.p_child.diff(iniRestoreOption' -range1:'range1' -range2:'range2' -RefreshTagsClose 'pindex1' 'pindex2' -RegisterAsMFDChild 'fid' -nomapping 'AutoCloseOption' 'maybe_quote_filename(Path1:+File1)' 'maybe_quote_filename(Path2:+File2));
            _AppendToDiffReport(DIFF_REPORT_DIFF,Path1:+File1,Path2:+File2);
            break;
         }
      }
   case VIEW_CAPTION:
   case VIEW_CAPTION2:
      if (ctlleft.p_enabled && ctlright.p_enabled) {
         _str rangeinfo='';
         if (sourceTreeWID._IsFunctionIndex(curindex)) {
            _str r1=sourceTreeWID._TreeGetUserInfo(curindex);
            _str r2=destTreeWID._TreeGetUserInfo(curindex2);
            rangeinfo='-range1:'r1' -range2:'r2;
         }
         curindex1=tree1._TreeCurIndex();
         curindex2=tree2._TreeCurIndex();
         int pindex1=tree1._TreeGetParentIndex(curindex1);
         int pindex2=tree2._TreeGetParentIndex(curindex2);

         fid=p_active_form;
         _mdi.p_child.diff(iniRestoreOption' -RegisterAsMFDChild 'fid' -r1 -r2 -q -showalways -nomapping -RefreshTagsClose 'curindex1' 'curindex2' 'rangeinfo' 'maybe_quote_filename(Path1:+File1)' 'maybe_quote_filename(Path2:+File2));
      }else if (ctlleft.p_enabled) {
         tree1.ShowOnlyFile(tree1._TreeCurIndex());
      }else if (ctlright.p_enabled) {
         tree2.ShowOnlyFile(tree2._TreeCurIndex());
      }
      break;
   case COPY_TREE_RIGHT_CAPTION:
   case COPY_TREE_LEFT_CAPTION:
      index1=tree1._TreeCurIndex();
      index2=tree2._TreeCurIndex();
      MyCopyTree(sourceTreeWID,curindex,destTreeWID,curindex2);
      HidNodes=tree1.MaybeHideNode(tree1._TreeGetParentIndex(index1));
      tree2.MaybeHideNode(tree2._TreeGetParentIndex(index2));
      tree1.call_event(CHANGE_SELECTED,tree1._TreeCurIndex(),tree1,ON_CHANGE,'w');
      tree2.call_event(CHANGE_SELECTED,tree2._TreeCurIndex(),tree1,ON_CHANGE,'w');

      tree1._TreeGetInfo(index1,state,bm1,bm2,flags);
      //Move to next mismatch
      if (!(flags&TREENODE_HIDDEN) && def_diff_edit_options&DIFFEDIT_AUTO_JUMP) {
         ctlnext_mismatch.call_event(ctlnext_mismatch,LBUTTON_UP);
         tree1._set_focus();
      }
      break;
   case COPY_RIGHT_CAPTION:
   case COPY_LEFT_CAPTION:
      //arg(1) is 'M' if we want a message before the copy
      CopySelectedFiles(p_name);
      tree1.call_event(CHANGE_SELECTED,tree1._TreeCurIndex(),tree1,ON_CHANGE,'w');
      tree2.call_event(CHANGE_SELECTED,tree2._TreeCurIndex(),tree1,ON_CHANGE,'w');
      break;
   case DELETE_FILE_CAPTION:
      DelKey();
   }
}

void tree2.on_change(int reason, int index=0)
{
#if 0
   switch (reason) {
   case CHANGE_SELECTED:
      break;
   case CHANGE_SCROLL:
      tree1._TreeScroll(_TreeScroll());
      break;
   }
#else
   tree2.call_event(reason,index,tree1,ON_CHANGE,'W');
#endif
}

void tree1.'C-H'()
{
   MFDiffCommand('HideCurrent');
}

void tree2.'C-H'()
{
   MFDiffCommand('HideCurrent');
}

void tree1.left()
{
   GNoOnChange=1;
   int index=find_index('_ul2_tree',EVENTTAB_TYPE);
   //message('index='index);
   if (index) {
      tree1.call_event(index,LEFT,'E');
      tree2.call_event(index,LEFT,'E');
   }
   GNoOnChange=0;
}
void tree2.left()
{
   GNoOnChange=1;
   int index=find_index('_ul2_tree',EVENTTAB_TYPE);
   if (index) {
      tree1.call_event(index,LEFT,'E');
      tree2.call_event(index,LEFT,'E');
   }
   GNoOnChange=0;
}

void tree1.right()
{
   int index=find_index('_ul2_tree',EVENTTAB_TYPE);
   if (index) {
      tree2.call_event(index,RIGHT,'E');
      tree1.call_event(index,RIGHT,'E');
   }
}
void tree2.right()
{
   int index=find_index('_ul2_tree',EVENTTAB_TYPE);
   if (index) {
      tree2.call_event(index,RIGHT,'E');
      tree1.call_event(index,RIGHT,'E');
   }
}

static int GetOtherTreeWID(int wid)
{
   if (wid==tree1) {
      return(tree2);
   }
   return(tree1);
}

static int PromptDeleteOnlyFile(int wid,int index1,int otherwid,int index2,
                                boolean &NoPrompt=false)
{
   _str Filename='';
   typeless status=wid.GetFilenameFromIndex(index1,Filename);
   if (status) return(status);

#if 0
   result=_message_box(nls("Are you sure you wish to delete the file %s?",Filename),
                       '',MB_YESNOCANCEL|MB_ICONQUESTION);
#endif
   _str buttons='';
   typeless result='';
   if (!NoPrompt) {
      buttons="Yes,Yes to &All,No,Cancel:_cancel\tAre you sure you wish to delete the file '"Filename"'?";
      result=show('-modal _textbox_form',
                  'Delete File(s)',
                  TB_RETRIEVE_INIT, //Flags
                  '',//width
                  '',//help item
                  buttons,
                  'OpenTBMenuDeleteFile');
      if (result=='') {
         return(COMMAND_CANCELLED_RC);
      }
      if (result==2) {
         NoPrompt=1;
      }
   }
   if (result==1 || NoPrompt) {
      status=delete_file(Filename);
      if (status) {
         _message_box(nls("Could not delete file %s.\n%s",Filename,get_message(status)));
         return(status);
      }
      _AppendToDiffReport(DIFF_REPORT_DELETE_FILE,Filename);
      wid._TreeDelete(index1);
      otherwid._TreeDelete(index2);
      tree1.call_event(CHANGE_SELECTED,tree1._TreeCurIndex(),tree1,ON_CHANGE,'w');
      tree2.call_event(CHANGE_SELECTED,tree2._TreeCurIndex(),tree1,ON_CHANGE,'w');

   }
   if (status) {
      _message_box(nls("Could not delete file '%s'\n\n%s",Filename,get_message(status)));
      return(status);
   }
   return(0);
}

static int PromptDeleteDifferentFile(int wid,int index1,int otherwid,int index2,
                                     boolean &NoPrompt=false)
{
   _str Filename1='';
   _str Filename2='';
   typeless status=wid.GetFilenameFromIndex(index1,Filename1);
   if (status) return(status);
   status=otherwid.GetFilenameFromIndex(index2,Filename2);
   if (status) return(status);
   _str Captions[];
   Captions[0]='Delete 'Filename1;
   Captions[1]='Delete 'Filename2;
   Captions[2]='Delete both';
   //result=show('-modal _rb_form',
   //            'Delete Files');
   typeless result=RadioButtons("Delete Files",Captions);
   if (result==COMMAND_CANCELLED_RC) return(COMMAND_CANCELLED_RC);
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeGetInfo(index1,state,bm1,bm2,flags);
   if (result==1) {
      status=delete_file(Filename1);
      if (status) {
         _message_box(nls("Could not delete file %s\n\n%s",Filename1,get_message(status)));
         return(status);
      }
      _TreeDeselectLine(index1);
//      _TreeSetInfo(index1,state,_pic_filem,_pic_filem,flags&~TREENODE_SELECTED);
//      otherwid._TreeSetInfo(index2,state,_pic_filep,_pic_filep,flags&~TREENODE_SELECTED);
      otherwid._TreeDeselectLine(index2);
      tree1.call_event(CHANGE_SELECTED,index1,tree1,ON_CHANGE,'W');
      _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,Filename1);
   }else if (result==2) {
      status=delete_file(Filename2);
      if (status) {
         _message_box(nls("Could not delete file %s\n\n%s",Filename2,get_message(status)));
         return(status);
      }
      _TreeDeselectLine(index1);
      //_TreeSetInfo(index1,state,_pic_filep,_pic_filep,flags&~TREENODE_SELECTED);
      //otherwid._TreeSetInfo(index2,state,_pic_filem,_pic_filem,flags&~TREENODE_SELECTED);
      otherwid._TreeDeselectLine(index2);
      tree1.call_event(CHANGE_SELECTED,index1,tree1,ON_CHANGE,'W');
      _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,Filename2);
   }else if (result==3) {
      status=delete_file(Filename1);
      if (status) {
         _message_box(nls("Could not delete file %s\n\n%s",Filename1,get_message(status)));
         return(status);
      }
      status=delete_file(Filename2);
      if (status) {
         _message_box(nls("Could not delete file %s\n\n%s",Filename2,get_message(status)));
         return(status);
      }
      _TreeDelete(index1);
      otherwid._TreeDelete(index2);
      tree1.call_event(CHANGE_SELECTED,index1,tree1,ON_CHANGE,'W');
      _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,Filename1);
      _AppendToDiffReport(DIFF_REPORT_DELETE_TREE_FILE,Filename2);
   }
   return(0);
}

static int DelFileInTree(int wid,int index1,int otherwid,int index2,boolean &NoPrompt=false)
{
   int origwid=p_window_id;
   p_window_id=wid;
   int state=0;
   int bm1_1=0,bm1_2=0;
   int flags=0;
   _TreeGetInfo(index1,state,bm1_1,bm1_2,flags);
   int status=0;
   if (bm1_1==_pic_filep) {
      status=PromptDeleteOnlyFile(p_window_id,index1,otherwid,index2,NoPrompt);
   }else if (bm1_1==_pic_filem) {
      status=PromptDeleteOnlyFile(otherwid,index2,p_window_id,index1,NoPrompt);
   }else if (bm1_1==_pic_file_match ||
             bm1_1==_pic_filem ||
             bm1_1==_pic_filed ||
             bm1_1==_pic_filed2) {
      status=PromptDeleteDifferentFile(p_window_id,index1,otherwid,index2,NoPrompt);
   }
   p_window_id=origwid;
   return(status);
}

static int DelKey()
{
   int origwid=p_window_id;
   p_window_id=tree1;
   int NumSelected=tree1._TreeGetNumSelectedItems();;
   if (!NumSelected) {
      p_window_id=tree2;
      NumSelected=tree2._TreeGetNumSelectedItems();
   }
   if (!NumSelected) {
      p_window_id=origwid;
      //Little hack here.  This way we wind up with two tree window ids.
      //The original wid on the way in might have been a command button
      int otherwid=GetOtherTreeWID(p_window_id);
      int wid=GetOtherTreeWID(otherwid);
      return(DelFileInTree(wid,wid._TreeCurIndex(),otherwid,otherwid._TreeCurIndex()));
   }
   int index1=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   boolean NoPrompt=false;

   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int linenumber=0;
   int index2=0;
   int nextindex=0;
   typeless status=0;
   int info=0;
   _TreeGetSelectionIndices(auto indices);
   foreach (index1 in indices) {
      _TreeGetInfo(index1,state,bm1,bm2,flags,linenumber);
      int otherwid=GetOtherTreeWID(p_window_id);
      index2=otherwid._TreeGetIndexFromLineNumber(linenumber);
      status=DelFileInTree(p_window_id,index1,otherwid,index2,NoPrompt);
      if (status) {
         return(status);
      }
   }
   p_window_id=origwid;
   return(0);
}

void tree1.del()
{
   DelKey();
}

void tree2.del()
{
   DelKey();
}

static void rclickmenu()
{
   call_event(p_window_id,LBUTTON_DOWN);
   int MenuIndex=find_index("_mfdiff_menu",oi2type(OI_MENU));
   int menu_handle=_mdi._menu_load(MenuIndex,'P');

   _str path1=ctlpath1label.p_caption;
   _str path2=ctlpath2label.p_caption;
   parse path1 with 'Path &1:' path1;
   parse path2 with 'Path &2:' path2;
   int status=_menu_set_state(menu_handle,
                          2,MF_ENABLED,'p',
                          'Show files not in 'path1,
                          'MFDiffCommand hmissing1','','',
                          'Show files Missing from 'path1);
   status=_menu_set_state(menu_handle,
                          3,MF_ENABLED,'p',
                          'Show files not in 'path2,
                          'MFDiffCommand hmissing2','','',
                          'Show files Missing from 'path2);

   int x,y;
   mou_get_xy(x,y);

   if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES) {
      _menu_set_state(menu_handle,"match",MF_CHECKED,'C');
   }
   if (GMFDiffViewOptions&DIFF_VIEW_VIEWED_FILES) {
      _menu_set_state(menu_handle,"viewed",MF_CHECKED,'C');
   }
   if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES1) {
      _menu_set_state(menu_handle,"missing1",MF_CHECKED,'C');
   }
   if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES2) {
      _menu_set_state(menu_handle,"missing2",MF_CHECKED,'C');
   }
   if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_FILES) {
      _menu_set_state(menu_handle,"different",MF_CHECKED,'C');
   }

   if (!GNumHidden) {
      _menu_set_state(menu_handle,"hiddenexist",MF_GRAYED,'C');
   }


   _str MissingFilePath='';
   if (p_window_id==tree1) {
      MissingFilePath=path2;
   }else{
      MissingFilePath=path1;
   }
   int flags=0;
   _str caption='';
   typeless SelectionMenuHandle='';
   status=_menu_get_state(menu_handle,
                          9,
                          flags,
                          'p',
                          caption,
                          SelectionMenuHandle);
   if (!status) {
      status=_menu_set_state(SelectionMenuHandle,
                             1,MF_ENABLED,'p',
                             'Select files Missing from 'MissingFilePath,
                             'MFDiffCommand SelectMissing','','',
                             'Select files Missing from 'MissingFilePath);
   }
   /*if (_TagDiffingEnabled) {
      _menu_insert(menu_handle,
                   -1,
                   MF_ENABLED,
                   "List Tag Information",
                   "diff_list_tag_info");
   }*/
   if (def_mfdiff_functions==1) {
      _menu_insert(menu_handle,6,0,'-');
      _menu_insert(menu_handle,6,0,'Show different symbols','MFDiffCommand hdifferentfunctions','differentfunctions');
      _menu_insert(menu_handle,7,0,'Show matching symbols','MFDiffCommand hmatchingfunctions','matchingfunctions');
      _menu_insert(menu_handle,8,0,'Show symbols missing from files in 'path1,'MFDiffCommand hmissingfunctions1','missingfunctions1');
      _menu_insert(menu_handle,9,0,'Show symbols missing from files in 'path2,'MFDiffCommand hmissingfunctions2','missingfunctions2');
      _menu_insert(menu_handle,10,0,'Show matching symbols that have moved','MFDiffCommand hmovedfunctions','movedfunctions');
      _menu_insert(menu_handle,11,0,'-');
      _menu_insert(menu_handle,12,0,'Write symbol list info','diff_list_tag_info');


      if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_SYMBOLS) {
         _menu_set_state(menu_handle,"differentfunctions",MF_CHECKED,'C');
      }
      if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_SYMBOLS) {
         _menu_set_state(menu_handle,"matchingfunctions",MF_CHECKED,'C');
      }
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_SYMBOLS1) {
         _menu_set_state(menu_handle,"missingfunctions1",MF_CHECKED,'C');
      }
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_SYMBOLS2) {
         _menu_set_state(menu_handle,"missingfunctions2",MF_CHECKED,'C');
      }
      if (GMFDiffViewOptions&DIFF_VIEW_MOVED_SYMBOLS) {
         _menu_set_state(menu_handle,"movedfunctions",MF_CHECKED,'C');
      }
   }

   // Add menu item to edit file in editor
   int index=_TreeCurIndex();
   {
      if ( index>-1 ) {
         _TreeGetInfo(index,auto state,auto bm1);
         // Check to see if this is a file bitmap for a file that is really here
         if ( bm1==_pic_file_match||bm1==_pic_filed||bm1==_pic_filed2||bm1==_pic_filep) {
            pindex := _TreeGetParentIndex(index);
            if ( pindex>-1 ) {
               filename := _TreeGetCaption(pindex):+_TreeGetCaption(index);
               _menu_insert(menu_handle,13,0,'-');
               _menu_insert(menu_handle,14,0,'Open in editor','edit 'maybe_quote_filename(filename));
            }
         }
      }
   }

   status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
}

void tree1.rbutton_up()
{
   rclickmenu();
}

void tree2.rbutton_up()
{
   rclickmenu();
}

static void RefreshByDate(int index1,int index2)
{
   int origParent=tree1._TreeGetParentIndex(index1);
   int s1=tree1._TreeScroll();
   int s2=tree2._TreeScroll();
   _str cap1='';
   _str cap2='';
   int state1=0;
   int bm11=0,bm12=0;
   int flags1=0;
   int state2=0;
   int bm21=0,bm22=0;
   int flags2=0;
   int flags=0;
   int state=0;
   int newindex1=0;
   int newindex2=0;
   int nextindex1=0;
   int nextindex2=0;
   int ci1=0;
   int ci2=0;
   int File1ViewId=0;
   int File2ViewId=0;
   int orig_view_id=0;
   int StartLine1=0;
   int StartLine2=0;
   _str filename1='';
   _str filename2='';
   typeless junk;
   typeless status=0;
   typeless file_date1='';
   typeless file_date2='';
   typeless info1='';
   typeless info2='';
   typeless old_file_date1='';
   typeless old_file_date2='';
   typeless manually_hidden1='';
   typeless manually_hidden2='';
   typeless OutputBufId='';
   boolean file1inmem=false;
   boolean file2inmem=false;
   for (;;) {
      if (index1<0||index2<0) break;
      cap1=tree1._TreeGetCaption(index1);
      cap2=tree2._TreeGetCaption(index2);
      if (last_char(cap1)==FILESEP) {
         //Directory node
         tree1._TreeGetInfo(index1,state1,bm11,bm12,flags1);
         tree2._TreeGetInfo(index2,state2,bm21,bm22,flags2);
         GetFolderIndexes(cap1,cap2,newindex1,newindex2,'+d',
                          _pic_fldopen,_pic_fldopenp,_pic_fldopenm);
         if (bm11!=newindex1 ||
             bm12!=newindex2) {

            tree1._TreeSetInfo(index1,state1,newindex1,newindex1,flags1);
            tree2._TreeSetInfo(index2,state2,newindex2,newindex2,flags2);
         }
         ci1=tree1._TreeGetFirstChildIndex(index1);
         ci2=tree2._TreeGetFirstChildIndex(index2);
         if (ci1>=0 && ci2>=0) RefreshByDate(ci1,ci2);
      }else{
         //File node
         info1=tree1._TreeGetUserInfo(index1);
         parse info1 with old_file_date1 (ASCII1) manually_hidden1 .;
         info2=tree2._TreeGetUserInfo(index2);
         parse info2 with old_file_date2 (ASCII1) manually_hidden2 .;

         filename1=tree1._TreeGetCaption(tree1._TreeGetParentIndex(index1)):+tree1._TreeGetCaption(index1);
         file_date1=_file_date(filename1,'B');

         filename2=tree2._TreeGetCaption(tree2._TreeGetParentIndex(index2)):+tree2._TreeGetCaption(index2);
         file_date2=_file_date(filename2,'B');

         if (old_file_date1!=file_date1 ||
             old_file_date2!=file_date2) {
            GetFolderIndexes(filename1,filename2,newindex1,newindex2,'',
                             _pic_file_match,_pic_filep,_pic_filem);
            tree1._TreeGetInfo(index1,state1,bm11,bm12,flags1);
            tree2._TreeGetInfo(index2,state2,bm21,bm22,flags2);
            if (newindex1==_pic_filem || newindex2==_pic_filem) {
               if (newindex1==newindex2) {
                  //Files do not exist
                  nextindex1=tree1._TreeGetNextSiblingIndex(index1);
                  nextindex2=tree2._TreeGetNextSiblingIndex(index2);
                  tree1._TreeDelete(index1);
                  tree2._TreeDelete(index2);
                  index1=nextindex1;
                  index2=nextindex2;
                  continue;
               }
               tree1._TreeSetInfo(index1,state1,newindex1,newindex1,flags1);
               tree2._TreeSetInfo(index2,state2,newindex2,newindex2,flags2);
               index1=tree1._TreeGetNextSiblingIndex(index1);
               index2=tree2._TreeGetNextSiblingIndex(index2);
               continue;
            }
            status=_open_temp_view(filename1,File1ViewId,orig_view_id,'',file1inmem);
            if (status) {
               _message_box(nls("Could not open file %s\ns",filename1,get_message(status)));
            }
            p_window_id=orig_view_id;
            status=_open_temp_view(filename2,File2ViewId,junk,'',file2inmem);
            if (status) {
               _message_box(nls("Could not open file %s\n%s",filename2,get_message(status)));
            }
            p_window_id=orig_view_id;
            if (!(def_diff_options&FORCE_PROCESS_OPTIONS)&&
                !(def_diff_options&DIFF_DONT_COMPARE_EOL_CHARS)) {
               message('Fast Comparing 'filename1' and 'filename2);
               //This means we are in the "sunny day" scenario.  Even a size
               //mismatch is good enough
               long seek1,seek2;
               seek1=seek2=0;
               if (def_diff_options&DIFF_LEADING_SKIP_COMMENTS) {
                  _GetNonCommentSeek(File1ViewId,seek1);
                  _GetNonCommentSeek(File2ViewId,seek2);
               }
               status=FastCompare(File1ViewId,seek1,File2ViewId,seek2);
               //status=0;
            }else{
               message('Comparing 'filename1' and 'filename2);
               OutputBufId='';//Shouldn't have to do this...
               flags=def_diff_options|DIFF_OUTPUT_BOOLEAN;
               StartLine1=StartLine2=0;
               if (def_diff_options&DIFF_LEADING_SKIP_COMMENTS) {
                  _GetNonCommentSeek(File1ViewId,junk,StartLine1);
                  _GetNonCommentSeek(File2ViewId,junk,StartLine2);
               }
               status=Diff(File1ViewId,File2ViewId,
                           flags|DIFF_NO_BUFFER_SETUP,
                           0,
                           0,0,//Do nothing
                           def_load_options,0,
                           OutputBufId,//This is pass by reference
                           def_max_fast_diff_size,
                           StartLine1,StartLine2,
                           def_smart_diff_limit,
                           null);

            }
            tree1._TreeGetInfo(index1,state);
            if (state>-1) {
               _DiffExpandTags2(File1ViewId.p_buf_id,
                                File2ViewId.p_buf_id,
                                index1,
                                index2,
                                '+bi','+bi');
            }

            if (file1inmem) {
               p_window_id=File1ViewId;
               _delete_window();
            }else{
               _delete_temp_view(File1ViewId);
            }
            if (file2inmem) {
               p_window_id=File2ViewId;
               _delete_window();
            }else{
               _delete_temp_view(File2ViewId);
            }
            p_window_id=orig_view_id;
            tree1._TreeGetInfo(index1,state1,bm11,bm12,flags1);
            tree2._TreeGetInfo(index2,state2,bm21,bm22,flags2);
            if (status) {
               //Files do not match
               if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_FILES) {
                  flags1&=~TREENODE_HIDDEN;
                  flags2&=~TREENODE_HIDDEN;
               }else{
                  flags1|=TREENODE_HIDDEN;
                  flags2|=TREENODE_HIDDEN;
               }
               tree1._TreeSetInfo(index1,state1,_pic_filed,_pic_filed,flags1);
               tree2._TreeSetInfo(index2,state2,_pic_filed,_pic_filed,flags2);
            }else{
               //Files match
               if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES) {
                  flags1&=~TREENODE_HIDDEN;
                  flags2&=~TREENODE_HIDDEN;
               }else{
                  flags1|=TREENODE_HIDDEN;
                  flags2|=TREENODE_HIDDEN;
               }
               tree1._TreeSetInfo(index1,state1,_pic_file_match,_pic_file_match,flags1);
               tree2._TreeSetInfo(index2,state2,_pic_file_match,_pic_file_match,flags2);
            }
         }else{
            message('Skipping 'filename1' and 'filename2);
         }
      }
      index1=tree1._TreeGetNextSiblingIndex(index1);
      index2=tree2._TreeGetNextSiblingIndex(index2);
   }
   if (origParent==TREE_ROOT_INDEX) {
      tree1._TreeScroll(s1);
      tree2._TreeScroll(s2);
   }
   clear_message();
}

void ctlrefresh.lbutton_up()
{

   typeless result=_message_box("Refresh modified files only?",'',MB_YESNOCANCEL|MB_ICONQUESTION);
   if (result==IDCANCEL) return;
   if (result==IDNO) {
      //message('Building File Lists...');
      int ProgressFormWID=show('-desktop -hidden _difftree_progress_form');
      typeless disabled_wid_list=_enable_non_modal_forms(0,ProgressFormWID);
      ProgressFormWID._DiffHideProgressGauge();
      ProgressFormWID.p_visible=1;
      mou_hour_glass(1);
      typeless recursive=GRecursive;
      _str FileTable1:[],FileTable2:[];
      _str Path1,Path2;
      _str filespec_list='';
      int NumFilesInPath1=0;
      int NumFilesInPath2=0;
      if (_GetDialogInfo(FILESPEC_LIST)==null) {
         NumFilesInPath1=NumFilesInPath2=1;
         Path1=GPath1;
         Path2=GPath2;
         Path1=strip(Path1,'B','"');
         Path2=strip(Path2,'B','"');
         FileTable1:[_file_case(Path1)]=Path1;
         FileTable2:[_file_case(Path2)]=Path2;
         Path1=_strip_filename(Path1,'N');
         Path2=_strip_filename(Path2,'N');
      }else{
         filespec_list=_GetDialogInfo(FILESPEC_LIST);
         if ( filespec_list==null ) filespec_list='';

         NumFilesInPath1=_GetFileTable(FileTable1,GPath1,filespec_list,GExcludeFilespecList,GRecursive,ProgressFormWID);
         if (NumFilesInPath1<0) {
            _enable_non_modal_forms(1,0,disabled_wid_list);
            return;
         }
         NumFilesInPath2=_GetFileTable(FileTable2,GPath2,filespec_list,GExcludeFilespecList,GRecursive,ProgressFormWID);
         if (NumFilesInPath2<0) {
            _enable_non_modal_forms(1,0,disabled_wid_list);
            return;
         }
         Path1=GPath1;Path2=GPath2;
      }

      _AppendToDiffReport(DIFF_REPORT_REFRESH_ALL);
      tree1._TreeDelete(TREE_ROOT_INDEX,'C');
      tree2._TreeDelete(TREE_ROOT_INDEX,'C');

      if (!NumFilesInPath1 && !NumFilesInPath2) {
         _message_box("No Files match these parameters");
         _enable_non_modal_forms(1,0,disabled_wid_list);
         return;
      }
      _str OutputTable[];
      _str Directories[];
      boolean compareAllSymbols=true;
      _SetDialogInfo(FILESPEC_LIST,filespec_list);
      typeless status=DiffFileTables(FileTable1,GPath1,FileTable2,GPath2,OutputTable,ProgressFormWID,compareAllSymbols);
      if (status!=COMMAND_CANCELLED_RC) {
         ProgressFormWID._delete_window();
      }
      _enable_non_modal_forms(1,0,disabled_wid_list);
      if (status) {
         return;
      }
      MFDIFF_SETUP_INFO SetupInfo;
      SetupInfo.FileTable1=FileTable1;
      SetupInfo.Path1=Path1;
      SetupInfo.FileTable2=FileTable2;
      SetupInfo.Path2=Path2;
      SetupInfo.OutputTable=OutputTable;
      SetupInfo.BasePath1=Path1;
      SetupInfo.BasePath2=Path2;
      SetupInfo.recursive=GRecursive;

      SetupInfo.Filespecs=filespec_list;
      SetupInfo.ExcludeFilespecs=GExcludeFilespecList;
      SetupInfo.ExpandFirst=compareAllSymbols;
      SetupInfo.ShowNoEditorOptions=GShowNoEditorOptions;
      SetupInfo.RestoreFromINI=0;
      MFDiffTreeCreate(&SetupInfo);
      mou_hour_glass(0);
      p_active_form._set_foreground_window();
   }else if (result==IDYES) {
      _AppendToDiffReport(DIFF_REPORT_REFRESH_CHANGED);
      RefreshByDate(tree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX),
                    tree2._TreeGetFirstChildIndex(TREE_ROOT_INDEX));
   }
   EnableButtons();
}

//You can't pass a pointer to a builtin, so I had to do this.  Maybe it would
//have been better to duplicate code for next and prev...
static int MyTreeGetPrevIndex(int index) {return(_TreeGetPrevIndex(index));}
static int MyTreeGetNextIndex(int index) {return(_TreeGetNextIndex(index));}

static int FindMismatchNode2(typeless *pfn)
{
   int index=_TreeCurIndex();
   int state=0;
   int bmindex=0;
   for (;;) {
      index=(*pfn)(index);
      if (index<0) break;
      _TreeGetInfo(index,state,bmindex,bmindex);
      if (bmindex!=_pic_file_match && bmindex!=_pic_fldopen) return(index);
   }
   return(-1);
}

static void FindMismatchNode(typeless *pfn)
{
   int index=tree1.FindMismatchNode2(pfn);
   if (index<0) {
      _message_box(nls(get_message(VSDIFF_NO_MORE_DIFFERENCES_RC)));
      return;
   }
   tree1._TreeSetCurIndex(index);
   //tree2._TreeCurLineNumber(tree1._TreeCurLineNumber());
   tree2._TreeScroll(tree1._TreeScroll());
   tree1._TreeDeselectAll();
   tree2._TreeDeselectAll();

   int wid=p_window_id;
   p_window_id=tree1;
   index=_TreeCurIndex();
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeSelectLine(index);
   p_window_id=wid;
}

void _difftree_output_form.C_F6()
{
   FindMismatchNode(MyTreeGetNextIndex);
}
void ctlnext_mismatch.lbutton_up()
{
   FindMismatchNode(MyTreeGetNextIndex);
}
void _difftree_output_form.'C-S-F6'()
{
   FindMismatchNode(MyTreeGetPrevIndex);
}
void _difftree_output_form.ESC()
{
   ctlclose.call_event(ctlclose,LBUTTON_UP);
}
void ctlprev_mismatch.lbutton_up()
{
   FindMismatchNode(MyTreeGetPrevIndex);
}

#define MATCHING_FILES 1
#define VIEWED_FILES   2
#define MISSING_FILES  3

static void ReplaceFiles(int index,int bmindex)
{
   int UnhidParents=0;
   int state=0;
   int curbmindex=0;
   int flags=0;
   int pindex=0;
   int cindex=0;
   typeless userinfo='';
   typeless manuallyhidden=0;
   typeless date='';
   for (;index>=0;) {
      _TreeGetInfo(index,state,curbmindex,curbmindex,flags);
      userinfo=_TreeGetUserInfo(index);
      if (userinfo==null) {
         manuallyhidden=0;
      }else{
         parse userinfo with date (ASCII1) manuallyhidden .;
      }
      if ((flags&TREENODE_HIDDEN) &&
          (curbmindex==bmindex || (bmindex<0 && manuallyhidden==1)) ) {
         _TreeSetInfo(index,state,curbmindex,curbmindex,flags&~TREENODE_HIDDEN);
         _TreeSetUserInfo(index,date:+ASCII1);
         if (bmindex<0) {
            //showing the manually hidden nodes
            --GNumHidden;
         }
         if (!UnhidParents) {
            UnhidParents=1;
            pindex=_TreeGetParentIndex(index);
            while (pindex>=0) {
               _TreeGetInfo(pindex,state,curbmindex,curbmindex,flags);
               if (flags&TREENODE_HIDDEN) {
                  _TreeSetInfo(pindex,state,curbmindex,curbmindex,flags&~TREENODE_HIDDEN);
                  userinfo=_TreeGetUserInfo(pindex);
                  parse userinfo with date (ASCII1) manuallyhidden .;
                  _TreeSetUserInfo(pindex,date:+ASCII1);
               }
               pindex=_TreeGetParentIndex(pindex);
            }
         }
      }
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0 &&
          curbmindex!=_pic_filed &&
          curbmindex!=_pic_filed2 &&
          curbmindex!=_pic_file_match
          ) {
         ReplaceFiles(cindex,bmindex);
      }
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void ReplaceFunctions(int index,int bmindex)
{
   int UnhidParents=0;
   int state=0;
   int curbmindex=0;
   int flags=0;
   int cindex=0;
   typeless userinfo='';
   for (;index>=0;) {
      _TreeGetInfo(index,state,curbmindex,curbmindex,flags);

      userinfo=_TreeGetUserInfo(index);
      if (_IsFunctionIndex(index) &&
          (flags&TREENODE_HIDDEN) &&
          (curbmindex==bmindex)) {
         _TreeSetInfo(index,state,curbmindex,curbmindex,flags&~TREENODE_HIDDEN);
      }
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) ReplaceFunctions(cindex,bmindex);
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void HideFiles(int index,int bmindex)
{
   int state=0;
   int curbmindex=0;
   int flags=0;
   int cindex=0;
   for (;index>=0;) {
      _TreeGetInfo(index,state,curbmindex,curbmindex,flags);
      if (!(flags&TREENODE_HIDDEN) && curbmindex==bmindex) {
         _TreeSetInfo(index,state,curbmindex,curbmindex,flags|TREENODE_HIDDEN);
      }
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) HideFiles(cindex,bmindex);
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void HideFunctions(int index,int bmindex)
{
   int state=0;
   int curbmindex=0;
   int flags=0;
   int cindex=0;
   for (;index>=0;) {
      _TreeGetInfo(index,state,curbmindex,curbmindex,flags);

      if (_IsFunctionIndex(index) &&
          !(flags&TREENODE_HIDDEN) && curbmindex==bmindex) {
         _TreeSetInfo(index,state,curbmindex,curbmindex,flags|TREENODE_HIDDEN);
      }
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) HideFunctions(cindex,bmindex);
      index=_TreeGetNextSiblingIndex(index);
   }
}

static void HideCurrent()
{
   int index=_TreeCurIndex();
   if (index<1) return;//ShowRoot is off
   ++GNumHidden;
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_HIDDEN);
   typeless info=_TreeGetUserInfo(index);
   typeless date='';
   parse info with date (ASCII1) .;
   info=date:+ASCII1:+1;//The 1 means that this item was manually hidden
   _TreeSetUserInfo(index,info);
}

static void SelectFilesWithBitmaps2(int index,int bmindex)
{
   int cindex=0;
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   for (;;) {
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>=0) {
         SelectFilesWithBitmaps2(cindex,bmindex);
      }else{
         _TreeGetInfo(index,state,bm1,bm2,flags);
         if (bm1==bmindex) {
            _TreeSelectLine(index);
         }
      }
      index=_TreeGetNextSiblingIndex(index);
      if (index<0) break;
   }
}

static void HideLinesInBothTrees(int Indexes[]=null)
{
   int wid=p_window_id;
   GNoOnChange=1;
   int index=_TreeCurIndex();
   if (Indexes==null) {
      index=_TreeCurIndex();
      Indexes[0]=index;
   }
   int i;
   int ln=0;
   int firstwid=0;
   for (i=0;i<Indexes._length();++i) {
      _TreeSetCurIndex(Indexes[i]);
      ln=_TreeCurLineNumber();
      HideCurrent();

      firstwid=p_window_id;
      if (p_window_id==tree1) {
         p_window_id=tree2;
      }else{
         p_window_id=tree1;
      }
      _TreeCurLineNumber(ln);
      HideCurrent();
   }

   GNoOnChange=0;
}

static void SelectFilesWithBitmaps(int index,int bmindex)
{
   int NumSelected=_TreeGetNumSelectedItems();
   if (NumSelected==1) {
      int info;
      if (_TreeGetNextSelectedIndex(1, info) == _TreeCurIndex()) {
         _TreeDeselectAll();
      }
   }

   SelectFilesWithBitmaps2(index,bmindex);

   // select the last one
   int indices[];
   _TreeGetSelectionIndices(indices);
   LastSelIndex := -1;
   if (indices._length()) {
      LastSelIndex = indices[indices._length() - 1];
   }

   int otherwid=( (p_window_id==tree1) ? tree2:tree1);

   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   int linenum=0;
   if (LastSelIndex>=0) {
      _TreeSetCurIndex(LastSelIndex);
      _TreeGetInfo(LastSelIndex,state,bm1,bm2,flags,linenum);
      index=otherwid._TreeGetIndexFromLineNumber(linenum);
      otherwid._TreeSetCurIndex(index);
      otherwid._TreeScroll(_TreeScroll());
      p_redraw=1;
      otherwid.p_redraw=1;
      //It would be better if this wasn't here
   }
}

_command void MFDiffCommand(_str cmdName='')
{
   if (p_name!='tree1' && p_name!='tree2') {
      message('This command cannot be run from the command line');
      return;
   }
   int state=0;
   int NumSelected=0;
   int pbm1=0;
   tree1.p_redraw=0;
   tree2.p_redraw=0;
   if (cmdName=='') {
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      return;
   }
   switch (cmdName) {
   case 'DeselectAll':
      tree1._TreeDeselectAll();
      tree2._TreeDeselectAll();
      break;
   case 'SelectMissing':
      SelectFilesWithBitmaps(TREE_ROOT_INDEX,_pic_filep);
      break;
   case 'SelectDifferent':
      SelectFilesWithBitmaps(TREE_ROOT_INDEX,_pic_filed);
      SelectFilesWithBitmaps(TREE_ROOT_INDEX,_pic_filed2);
      break;
   case 'HideCurrent':
      int selwid=tree1;

      int wid=p_window_id;
      p_window_id=tree1;
      int curindex=_TreeCurIndex();
      int pindex=_TreeGetParentIndex(curindex);
      if (pindex>=0) {
         _TreeGetInfo(pindex,state,pbm1);
         if (pbm1==_pic_file_match||
             pbm1==_pic_symbold||
             pbm1==_pic_symbold2||
             pbm1==_pic_symbolm||
             pbm1==_pic_symbolp
             ) {
            message('Cannot hide individual functions');
            return;
         }
      }
      NumSelected=_TreeGetNumSelectedItems();
      p_window_id=wid;

      if (!NumSelected) {
         selwid=tree2;
         NumSelected=tree2._TreeGetNumSelectedItems();
      }
      if (!NumSelected) {
         HideLinesInBothTrees();
      }else{
         int Indexes[];
         selwid._TreeGetSelectionIndices(Indexes);
         selwid.HideLinesInBothTrees(Indexes);
      }

      tree1.p_redraw=1;
      tree2.p_redraw=1;
      return;
   case 'ShowHidden':
      //Show those items that were manually hidden
      tree1.ReplaceFiles(TREE_ROOT_INDEX,-1);
      tree2.ReplaceFiles(TREE_ROOT_INDEX,-1);
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      break;
   case 'hdifferent':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_FILES) {
         GMFDiffViewOptions&=~DIFF_VIEW_DIFFERENT_FILES;
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_filed);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_filed);
         tree1.MaybeHideNode(TREE_ROOT_INDEX);
         tree2.MaybeHideNode(TREE_ROOT_INDEX);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_DIFFERENT_FILES;
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_filed);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_filed);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hdifferentfunctions':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_SYMBOLS) {
         GMFDiffViewOptions&=~DIFF_VIEW_DIFFERENT_SYMBOLS;
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_symbold);
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_symbold);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_DIFFERENT_SYMBOLS;
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbold);
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbold);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hmatching':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES) {
         GMFDiffViewOptions&=~DIFF_VIEW_MATCHING_FILES;
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_file_match);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_file_match);
         tree1.MaybeHideNode(TREE_ROOT_INDEX);
         tree2.MaybeHideNode(TREE_ROOT_INDEX);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MATCHING_FILES;
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_file_match);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_file_match);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      mou_hour_glass(0);
      break;
   case 'hmatchingfunctions':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_SYMBOLS) {
         GMFDiffViewOptions&=~DIFF_VIEW_MATCHING_SYMBOLS;
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_symbol);
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_symbol);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MATCHING_SYMBOLS;
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbol);
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbol);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      mou_hour_glass(0);
      break;
   case 'hviewed':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_VIEWED_FILES) {
         GMFDiffViewOptions&=~DIFF_VIEW_VIEWED_FILES;
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_filed2);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_filed2);
         tree1.MaybeHideNode(TREE_ROOT_INDEX);
         tree2.MaybeHideNode(TREE_ROOT_INDEX);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_VIEWED_FILES;
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_filed2);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_filed2);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hmissing1':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES1) {
         GMFDiffViewOptions&=~DIFF_VIEW_MISSING_FILES1;
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_filep);
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_filem);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_fldopenm);

         tree1.MaybeHideNode(TREE_ROOT_INDEX);
         tree2.MaybeHideNode(TREE_ROOT_INDEX);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MISSING_FILES1;
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_filep);
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_filem);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_fldopenm);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hmissingfunctions1':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_SYMBOLS1) {
         GMFDiffViewOptions&=~DIFF_VIEW_MISSING_SYMBOLS1;
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_symbolp);
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_symbolm);
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_fldopenp);
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_fldopenm);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MISSING_SYMBOLS1;
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolp);
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolm);
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_fldopenp);
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_fldopenm);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      mou_hour_glass(0);
      break;
   case 'hmissing2':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES2) {
         GMFDiffViewOptions&=~DIFF_VIEW_MISSING_FILES2;
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_filep);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_filem);
         tree1.HideFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree2.HideFiles(TREE_ROOT_INDEX,_pic_fldopenm);

         tree1.MaybeHideNode(TREE_ROOT_INDEX);
         tree2.MaybeHideNode(TREE_ROOT_INDEX);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MISSING_FILES2;
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_filep);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_filem);
         tree1.ReplaceFiles(TREE_ROOT_INDEX,_pic_fldopenp);
         tree2.ReplaceFiles(TREE_ROOT_INDEX,_pic_fldopenm);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hmissingfunctions2':
      mou_hour_glass(1);
      if (GMFDiffViewOptions&DIFF_VIEW_MISSING_SYMBOLS2) {
         GMFDiffViewOptions&=~DIFF_VIEW_MISSING_SYMBOLS2;
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_symbolp);
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_symbolm);
         tree1.HideFunctions(TREE_ROOT_INDEX,_pic_fldopenp);
         tree2.HideFunctions(TREE_ROOT_INDEX,_pic_fldopenm);
      }else{
         GMFDiffViewOptions|=DIFF_VIEW_MISSING_SYMBOLS2;
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolp);
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolm);
         tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_fldopenp);
         tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_fldopenm);
      }

      tree2._TreeScroll(tree1._TreeScroll());
      tree1.p_redraw=1;
      tree2.p_redraw=1;
      //It would be better if this wasn't here

      mou_hour_glass(0);
      break;
   case 'hmovedfunctions':
      {
         mou_hour_glass(1);
         if (GMFDiffViewOptions&DIFF_VIEW_MOVED_SYMBOLS) {
            GMFDiffViewOptions&=~DIFF_VIEW_MOVED_SYMBOLS;
            tree1.HideFunctions(TREE_ROOT_INDEX,_pic_symbolmoved);
            tree2.HideFunctions(TREE_ROOT_INDEX,_pic_symbolmoved);
         }else{
            GMFDiffViewOptions|=DIFF_VIEW_MOVED_SYMBOLS;
            tree1.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolmoved);
            tree2.ReplaceFunctions(TREE_ROOT_INDEX,_pic_symbolmoved);
         }

         tree2._TreeScroll(tree1._TreeScroll());
         tree1.p_redraw=1;
         tree2.p_redraw=1;
         //It would be better if this wasn't here

         mou_hour_glass(0);
         break;
      }
   }
   tree1.call_event(CHANGE_SELECTED,tree1._TreeCurIndex(),tree1,ON_CHANGE,'w');
   tree2.call_event(CHANGE_SELECTED,tree2._TreeCurIndex(),tree1,ON_CHANGE,'w');
}

static void InsertByFlags(int bmindex,_str path,int flags,int origwid=0)
{
   if (bmindex==_pic_file_match) {
      if (flags&DIFF_VIEW_MATCHING_FILES) {
         insert_line(path);
      }
   }else if (bmindex==_pic_filem) {
      if (flags&DIFF_VIEW_MISSING_FILES1) {
         if (origwid.p_name=='tree1') {
            insert_line(path);
         }
      }
      if (flags&DIFF_VIEW_MISSING_FILES2) {
         if (origwid.p_name=='tree2') {
            insert_line(path);
         }
      }
   }else if (bmindex==_pic_filep) {
      if (flags&DIFF_VIEW_MISSING_FILES1) {
         if (origwid.p_name=='tree2') {
            insert_line(path);
         }
      }
      if (flags&DIFF_VIEW_MISSING_FILES2) {
         if (origwid.p_name=='tree1') {
            insert_line(path);
         }
      }
   }else if (bmindex==_pic_filed2) {
      if (flags&DIFF_VIEW_VIEWED_FILES) {
         insert_line(path);
      }
   }else if (bmindex==_pic_filed) {
      if (flags&DIFF_VIEW_DIFFERENT_FILES) {
         insert_line(path);
      }
   }
}

//ParentIndex is actually the linenumber of the parent entry in the file
static void WriteDiffTreeData(int index,int indent,int temp_view_id,_str options='',int OutputFlags=0)
{
   int state=0;
   int bm1=0,bm2=0;
   int flags=0;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   _str cap=_TreeGetCaption(index);
   typeless info=_TreeGetUserInfo(index);
   _str date='';
   typeless manually_hidden='';
   if (info!=null) {
      parse info with date (ASCII1) manually_hidden .;
   }
   int pindex=_TreeGetParentIndex(index);
   _str path='';
   if (pindex>=0) {
      path=_TreeGetCaption(pindex);
   }
   int orig_view_id=p_window_id;
   int origwid=p_window_id;
   p_window_id=temp_view_id;
   if (options=='') {
      insert_line(indent"\1"cap"\1"state"\1"name_name(bm1)"\1"name_name(bm2)"\1"flags"\1"date);
   }else if (pindex>0) {
      InsertByFlags(bm1,path:+cap,OutputFlags,origwid);
   }
   int pLineNum=p_line;
   p_window_id=orig_view_id;
   int cindex=_TreeGetFirstChildIndex(index);
   if (cindex>-1) {
      WriteDiffTreeData(cindex,indent+1,temp_view_id,options,OutputFlags);
   }
   int sindex=0;
   for (;;) {
      sindex=_TreeGetNextSiblingIndex(index);
      if (sindex<0) break;
      //message('writing '_TreeGetCaption(sindex));
      _TreeGetInfo(sindex,state,bm1,bm2,flags);
      if (!_IsFunctionIndex(sindex)) {
         cap=_TreeGetCaption(sindex);
         info=_TreeGetUserInfo(sindex);
         parse info with date (ASCII1) manually_hidden .;
         path=_TreeGetCaption(_TreeGetParentIndex(sindex));
         orig_view_id=p_window_id;
         p_window_id=temp_view_id;
         if (options=='') {
            insert_line(indent"\1"cap"\1"state"\1"name_name(bm1)"\1"name_name(bm2)"\1"flags"\1"date);
         }else{
            InsertByFlags(bm1,path:+cap,OutputFlags,origwid);
         }
         pLineNum=p_line;
         p_window_id=orig_view_id;
      }
      index=sindex;
      cindex=_TreeGetFirstChildIndex(index);
      if (cindex>-1) {
         WriteDiffTreeData(cindex,indent+1,temp_view_id,options,OutputFlags);
      }
   }
}

static void InsertDataForTree(int temp_view_id)
{
   int orig_view_id=p_window_id;
   boolean showRoot=p_ShowRoot;
   _str controlName=p_name;
   p_window_id=temp_view_id;
   insert_line(controlName);
   insert_line('p_ShowRoot='showRoot);
   p_window_id=orig_view_id;
   int index=TREE_ROOT_INDEX;
   WriteDiffTreeData(TREE_ROOT_INDEX,0,temp_view_id);
}

static int SaveMFDiffInfo(_str filename,_str loadOptions="")
{
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id,loadOptions);
   p_UTF8=_load_option_UTF8(filename);
   p_window_id=orig_view_id;

   p_window_id=tree1;
   _ini_set_value(filename,'State','GMFDiffViewOptions',GMFDiffViewOptions);
   _str filespec_list=_GetDialogInfo(FILESPEC_LIST);
   if ( filespec_list==null ) filespec_list='';
   _ini_set_value(filename,'State','filespec_list',filespec_list);
   _ini_set_value(filename,'State','exclude_filespec_list',GExcludeFilespecList);
   _ini_set_value(filename,'State','path1',GPath1);
   _ini_set_value(filename,'State','path2',GPath2);
   _ini_set_value(filename,'State','recursive',GRecursive);
   tree1.InsertDataForTree(temp_view_id);

   p_window_id=temp_view_id;
   p_window_id=orig_view_id;
   typeless status=_ini_put_section(filename,'TreeData1',temp_view_id);

   orig_view_id=_create_temp_view(temp_view_id);
   p_UTF8=_load_option_UTF8(filename);
   p_window_id=orig_view_id;
   tree2.InsertDataForTree(temp_view_id);
   status=_ini_put_section(filename,'TreeData2',temp_view_id);

   //p_window_id=temp_view_id;
   //status=_save_file('+o');
   return(status);
}

static void AddChildren(int Parent,int Indent,int tree_view_id,int hashtab:[]=null)
{
   int orig_view_id=p_window_id;
   int Last=Parent;
   typeless IndentLevel='';
   typeless cap='';
   typeless state='';
   typeless bm1Name='';
   typeless bm2Name='';
   typeless flags='';
   typeless date='';
   int bm1=0;
   int bm2=0;
   while (!down()) {
      _str line='';
      get_line(line);
      //IndentLevel=GetIndent(line);
      parse line with IndentLevel"\1"cap"\1"state"\1"bm1Name"\1"bm2Name"\1"flags"\1"date .;
      if (hashtab._indexin(bm1Name)) {
         bm1=hashtab:[bm1Name];
      }else{
         bm1=find_index(bm1Name,PICTURE_TYPE);
         hashtab:[bm1Name]=bm1;
      }
      if (hashtab._indexin(bm2Name)) {
         bm2=hashtab:[bm2Name];
      }else{
         bm2=find_index(bm2Name,PICTURE_TYPE);
         hashtab:[bm2Name]=bm2;
      }
      if (IndentLevel>Indent) {
         up();
         AddChildren(Last,IndentLevel,tree_view_id,hashtab);
      }else if (IndentLevel<Indent) {
         if (IndentLevel>0) up();
         return;
      }else{
         p_window_id=tree_view_id;
         boolean IsCurIndex=0;
         Last=_TreeAddItem(Parent,
                           cap,
                           TREE_ADD_AS_CHILD,
                           bm1,
                           bm2,
                           state,      //Initial State
                           flags,
                           date);
         if (IsCurIndex) {
            _TreeSetCurIndex(Last);
         }
         p_window_id=orig_view_id;
      }
   }
}

static int ReadTree(_str filename,_str section)
{
   //status=_open_temp_view(filename,temp_view_id,orig_view_id);
   int orig_view_id=p_window_id;
   int temp_view_id=0;
   typeless status=_ini_get_section(filename,section,temp_view_id);
   if (status) {
      if (status==NEW_FILE_RC) {
         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      }
      return(status);
   }
   p_window_id=temp_view_id;
   p_line=3;//Skip the first 3 lines
   AddChildren(0,0,orig_view_id);
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

defeventtab _difftree_save_form;

ctlstate.lbutton_up()
{
   if (p_window_id==ctlstate) {
      ctlmatching.p_enabled=ctlviewed.p_enabled=ctlmissing1.p_enabled=ctlmissing2.p_enabled=ctldifferent.p_enabled=0;
   }else{
      ctlmatching.p_enabled=ctlviewed.p_enabled=ctlmissing1.p_enabled=ctlmissing2.p_enabled=ctldifferent.p_enabled=1;
   }
}

#define SAVE_PATH1_CAPTION "Save Path &1 Filelist ()"
#define SAVE_PATH2_CAPTION "Save Path &2 Filelist ()"

void ctlok.on_create(_str path1='', _str path2='')
{
   if (GMFDiffViewOptions&DIFF_VIEW_MATCHING_FILES) {
      ctlmatching.p_value=1;
   }
   if (GMFDiffViewOptions&DIFF_VIEW_VIEWED_FILES) {
      ctlviewed.p_value=1;
   }
   if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES1) {
      ctlmissing1.p_value=1;
   }
   if (GMFDiffViewOptions&DIFF_VIEW_MISSING_FILES2) {
      ctlmissing2.p_value=1;
   }
   if (GMFDiffViewOptions&DIFF_VIEW_DIFFERENT_FILES) {
      ctldifferent.p_value=1;
   }
#define RB_CHEAT_FACTOR 200
//Cheat factor for width of a radio button
   ctllist_left.p_width=ctllist_left._text_width(SAVE_PATH1_CAPTION)+
                        ctllist_left._text_width(path1)+RB_CHEAT_FACTOR;
   int path1CaptionLength=ctllist_left._text_width(SAVE_PATH1_CAPTION);
   int path2CaptionLength=ctllist_right._text_width(SAVE_PATH2_CAPTION);
   if (ctllist_left.p_width+ctllist_left.p_x > p_active_form.p_width) {
      path1=_ShrinkFilename(path1,p_active_form.p_width-(ctllist_left.p_x+RB_CHEAT_FACTOR+path1CaptionLength));
   }
   ctllist_left.p_caption=stranslate(SAVE_PATH1_CAPTION,'('path1')','()');

   ctllist_right.p_width=ctllist_right._text_width(SAVE_PATH1_CAPTION)+
                         ctllist_right._text_width(path2)+RB_CHEAT_FACTOR;
   if (ctllist_right.p_width+ctllist_right.p_x>p_active_form.p_width) {
      path2=_ShrinkFilename(path2,p_active_form.p_width-(ctllist_right.p_x+RB_CHEAT_FACTOR+path2CaptionLength));
   }
   ctllist_right.p_caption=stranslate(SAVE_PATH2_CAPTION,'('path2')','()');
}

_str ctlok.lbutton_up()
{
   if (ctlstate.p_value) {
      p_active_form._delete_window('S');
      return('S');
   }
   int flags=0;
   if (ctlmatching.p_value) flags|=DIFF_VIEW_MATCHING_FILES;
   if (ctlviewed.p_value) flags|=DIFF_VIEW_VIEWED_FILES;
   if (ctlmissing1.p_value) flags|=DIFF_VIEW_MISSING_FILES1;
   if (ctlmissing2.p_value) flags|=DIFF_VIEW_MISSING_FILES2;
   if (ctldifferent.p_value) flags|=DIFF_VIEW_DIFFERENT_FILES;
   if (ctllist_left.p_value) {
      p_active_form._delete_window('L 'flags);
      return('L 'flags);
   }else if (ctllist_right.p_value) {
      p_active_form._delete_window('R 'flags);
      return('R 'flags);
   }
   p_active_form._delete_window();
   return('');
}

defeventtab _difftree_saveprompt_form;

int _difftree_save_prompt(_str Caption='Do you wish to save these results?',
                          _str CheckboxCaption="Don't show this message again",
                          _str Button1Caption='&Yes',
                          _str Button2Caption='&No')
{
   _param1=0;
   typeless result=show('-modal _difftree_saveprompt_form',Caption,CheckboxCaption,Button1Caption,Button2Caption);
   if (result=='') {
      return(IDCANCEL);
   }
   return(result);
}

void ctlyes.on_create(_str Caption,
                      _str CheckboxCaption,
                      _str Button1Caption,
                      _str Button2Caption)
{
   ctllabel1.p_caption=Caption;
   ctlcheck1.p_caption=CheckboxCaption;
   ctlyes.p_caption=Button1Caption;
   ctlno.p_caption=Button2Caption;
   if (Button2Caption=='') {
      ctlno.p_visible=ctlno.p_enabled=false;
      ctlcancel.p_x = ctlno.p_x;
   }

   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   ctllabel1.p_x=(client_width intdiv 2) - (ctllabel1.p_width intdiv 2);
   ctlcheck1.p_x=(client_width intdiv 2) - (ctlcheck1.p_width intdiv 2);
}

int ctlyes.lbutton_up()
{
   _param1=ctlcheck1.p_value;
   p_active_form._delete_window(IDYES);
   return(IDYES);
}

int ctlno.lbutton_up()
{
   _param1=ctlcheck1.p_value;
   p_active_form._delete_window(IDNO);
   return(IDNO);
}
