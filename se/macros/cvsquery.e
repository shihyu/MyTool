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
#include "cvs.sh"
#include "xml.sh"
#include "diff.sh"
#include "minihtml.sh"
#import "cvs.e"
#import "cvsutil.e"
#import "diff.e"
#import "guiopen.e"
#import "help.e"
#import "main.e"
#import "picture.e"
#import "saveload.e"
#import "seltree.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "svc.e"
#import "taggui.e"
#import "tags.e"
#import "vc.e"
#endregion

static const CVS_QUERY_CAPTION_PREFIX= 'CVS query for ';
static const CVS_QUERY_OUTPUT_CAPTION_PREFIX= 'CVS query output for ';

static const STOP_CAPTION=  '&Stop';
static const CLOSE_CAPTION= 'Close';


_command int cvs_query(_str filename='') name_info(FILE_ARG'*,'VSARG2_CMDLINE|VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( _no_child_windows() && filename=='' ) {
      _str result=_OpenDialog('-modal',
                              'Select file to query history for',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   }else if ( filename=='' ) {
      filename=p_buf_name;
   }
   int status=show('-modal _cvs_query_form',filename);
   return(0);
}

defeventtab _cvs_query_form;

static bool gCancel;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _cvs_query_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctlsymbol_name.p_window_id, ctllist_symbols.p_window_id);
}

void ctlok.on_create(_str filename='')
{
   _retrieve_prev_form();
   p_active_form.p_caption=CVS_QUERY_CAPTION_PREFIX:+filename;
   ctlsymbol_name._retrieve_list();
   ctluser._retrieve_list();
   ctlstart_date._retrieve_list();
   ctlend_date._retrieve_list();

   _cvs_query_form_initial_alignment();
}

static int GetNumDots(_str BranchNumber,_str &Branch='')
{
   p := num_dots := 0;
   lastp := 0;
   for (;;) {
      p=pos('.',BranchNumber,p+1);
      if (!p) break;
      lastp=p;
   }
   Branch=substr(BranchNumber,1,lastp);
   return(num_dots);
}

static _str GetBranch(_str RevisionNumber)
{
   p := num_dots := 0;
   lastp := 0;
   for (;;) {
      p=pos('.',RevisionNumber,p+1);
      if (!p) break;
      lastp=p;
   }
   Branch := substr(RevisionNumber,1,lastp);
   return(Branch);
}

static _str cvs_invalid_filename()
{
   if (_isUnix()) {
      return("1:\\temptree");
   }
   return("1:\\temptree");
}


static int LoadInfoIntoTree(int xml_handle,int xml_index,
                            CVS_VERSION_INFO VersionList[],int &version_index=0)
{
   last_branch := "";
   xml_last_index := -1;
   version_list_len := VersionList._length();
   for (;version_index<version_list_len;++version_index) {
      _str cur_version=VersionList[version_index].RevisionNumber;
      _str cur_branch=GetBranch(cur_version);
      int search_index=xml_last_index;

      add_flags := 0;
      if ( cur_branch==last_branch ) {
         search_index=xml_last_index;
      }else{
         if (cur_branch=="1.") {
            search_index=TREE_ROOT_INDEX;
         }else{
            search_index=_xmlcfg_find_simple(xml_handle,cur_branch);
         }
         add_flags=VSXMLCFG_ADD_AS_CHILD;
      }

      if ( search_index<0 ) {
         _str parent_branch=cur_branch;
         if ( _last_char(parent_branch)=='.' ) {
            parent_branch=substr(parent_branch,1,length(parent_branch)-1);
            parent_branch=GetBranch(parent_branch);
            _maybe_strip(parent_branch, '.');
         }
         int parent_index=_xmlcfg_find_simple(xml_handle,"//"parent_branch);
         if (parent_index<0) parent_index=TREE_ROOT_INDEX;
         search_index=_xmlcfg_add(xml_handle,parent_index,cur_branch,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      }
      xml_last_index=_xmlcfg_add(xml_handle,search_index,cur_version,VSXMLCFG_NODE_ELEMENT_START,add_flags);

      last_branch=cur_branch;
   }
   return(0);
}

static _str GetNamedBranch(_str BranchNumber,CVS_VERSION_INFO (&NamedBranches)[])
{
   BranchNumber=substr(BranchNumber,1,length(BranchNumber)-1);
   if ( BranchNumber=="1" ) {
      return("Tip");
   }
   int len=NamedBranches._length(),i;
   for (i=0;i<len;++i) {
      if ( BranchNumber==_CVSConvertedBranchNumber(NamedBranches[i].RevisionNumber) ) {
         return(NamedBranches[i].Comment);
      }
   }
   return(BranchNumber);
}

static void TraverseTree(int xml_handle,int xml_index,_str (&branches):[][],
                         CVS_VERSION_INFO (&NamedBranches)[])
{
   prev_cap := "";
   for (; xml_index>-1 ;) {
      int xml_child_index=_xmlcfg_get_last_child(xml_handle,xml_index);
      if ( xml_child_index>-1 ) {
         TraverseTree(xml_handle,xml_child_index,branches,NamedBranches);
      }
      cap := _xmlcfg_get_name(xml_handle,xml_index);
      if (xml_index!=TREE_ROOT_INDEX) {
         if (_last_char(cap)!='.') {
            _str branch=GetNamedBranch(GetBranch(cap),NamedBranches);
            branches:[branch][branches:[branch]._length()]=cap;
            end_version := substr(cap,length(cap)-1,2);
            if ( end_version=='.1' ) {
               int xml_parent_index=_xmlcfg_get_parent(xml_handle,xml_index);
               if ( xml_parent_index!=TREE_ROOT_INDEX ) {
                  // This is the branch, go up one more
                  for (;;) {
                     xml_parent_index=_xmlcfg_get_parent(xml_handle,xml_parent_index);
                     if ( xml_parent_index<0 || xml_parent_index==TREE_ROOT_INDEX) {
                        break;
                     }
                     cur_cap := _xmlcfg_get_name(xml_handle,xml_parent_index);
                     if (_last_char(cur_cap)=='.') continue;
                     int len=branches:[branch]._length();
                     branches:[branch][len]=cur_cap;
                     break;
                  }
               }
            }
         }
      }
      xml_index=_xmlcfg_get_prev_sibling(xml_handle,xml_index);
      prev_cap=cap;
   }
}

static void GetIndexNamesFromHashtab(_str (&Names)[],typeless &hashtab)
{
   typeless i;
   for (i._makeempty();;) {
      hashtab._nextel(i);
      if (i._isempty()) break;
      Names[Names._length()]=i;
   }
}

static _str GetHTMLFriendlyTagCaption(_str tag_caption)
{
   _str func_name,sig;
   parse tag_caption with func_name '(' sig ')';
   _str html_friendly_tag_caption=func_name;
   if ( sig!='' ) html_friendly_tag_caption :+= '(...)';
   return(html_friendly_tag_caption);
}

struct OLD_VERSION_SYMBOL_INFO {
   _str filename;
   int StartLine;
   int EndLine;
   _str CVSPath;
};

static void InitMatchedVersions(bool (&MatchedVersions):[],CVS_VERSION_INFO (&VersionList)[])
{
   len := VersionList._length();
   int i;
   for (i=0;i<len;++i) {
      MatchedVersions:[VersionList[i].RevisionNumber]=true;
   }
}

static typeless QUERY_VERSION_INFO(...) {
   _nocheck _control ctlstop;
   if (arg()) ctlstop.p_user=arg(1);
   return ctlstop.p_user;
}

void ctlok.lbutton_up()
{
   query_form_wid := p_active_form;
#if 0 //11:19am 7/8/2003
   if ( ctlsymbol_name.p_text=='' ) {
      ctlsymbol_name._text_box_error("You must fill in a symbol name");
      return;
   }
#endif

   int HistoryViewId;
   ErrorFilename := "";

   symbol_changed := ctlsymbol_changed.p_value!=0;
   by_user := ctlby_user.p_value!=0;
   by_date := ctlby_date.p_value!=0;

   if ( !symbol_changed
        && !by_user
        && !by_date
         ) {
      _message_box(nls("You must select something"));
      return;
   }
   start_date := ctlstart_date.p_text;
   end_date := ctlend_date.p_text;
   typeless start_month,start_day,start_year;
   typeless end_month,end_day,end_year;
   start_int_day := end_int_day := 0;

   bool MatchedVersions:[]=null;

   if ( by_date ) {
      // We can check for a valid date up front...
      if ( start_date=='' ) {
         start_int_day=0;
      }else {
         if ( parse_date(start_date,start_month,start_day,start_year) ) {
            ctlstart_date._text_box_error(nls("You must specify a valid date in the format MM/DD/YYYY"));
            return;
         }else{
            start_int_day=_days_since_ny1980(start_month,start_day,start_year);
         }
      }
      if ( end_date=='' ) {
         end_int_day=0;
      }else {
         if ( parse_date(end_date,end_month,end_day,end_year) ) {
            ctlend_date._text_box_error(nls("You must specify a valid date in the format MM/DD/YYYY"));
            return;
         }else{
            end_int_day=_days_since_ny1980(end_month,end_day,end_year);
         }
      }

      if ( end_int_day < start_int_day && end_int_day>0 ) {
         ctlend_date._text_box_error(nls("The end date must greater than or equal to the start date"));
         return;
      }
   }
   _str filename=GetFilenameFromDialog();
   int status=_CVSGetLogInfoForFile(filename,HistoryViewId,ErrorFilename);
   if ( status ) return;

   CVS_LOG_INFO info;
   _CVSGetLogInfo(filename,info,HistoryViewId);
   InitMatchedVersions(MatchedVersions,info.VersionList);
   user_name := "";

   if ( by_date ) {
      len := info.VersionList._length();
      int i;
      for (i=0;i<len;++i) {
         _str cur_date=info.VersionList[i].Date;
         cur_time := "";
         parse cur_date with cur_date cur_time;
         typeless cur_day, cur_month, cur_year;
         parse cur_date with cur_year'/'cur_month'/'cur_day;
         int cur_int_day=_days_since_ny1980(cur_month,cur_day,cur_year);
         start_date_ok := !start_int_day || ! (cur_int_day<start_int_day);
         end_date_ok := !end_int_day || ! (cur_int_day>end_int_day);
         if ( !start_date_ok || !end_date_ok ) {
            MatchedVersions:[info.VersionList[i].RevisionNumber]=false;
         }
      }
   }
   if ( by_user ) {
      if ( ctluser.p_text=='' ) {
         _message_box(nls("You must specify a user name"));
         _delete_temp_view(HistoryViewId);
         delete_file(ErrorFilename);
         return;
      }
      user_name=ctluser.p_text;
      len := info.VersionList._length();
      int i;
      for (i=0;i<len;++i) {
         if ( user_name!=info.VersionList[i].Author ) {
            MatchedVersions:[info.VersionList[i].RevisionNumber]=false;
         }
      }
   }
   int xml_handle=_xmlcfg_create(cvs_invalid_filename(),VSENCODING_UTF8);
   if ( xml_handle<0 ) {
      _message_box(nls("Could not create temp xml tree"));
      delete_file(ErrorFilename);
      return;
   }
   _str remote_filename;
   _CVSGetModuleFromLocalFile(filename,remote_filename);
   remote_filename :+= _strip_filename(filename,'P');

   int output_form_wid=show('-app -xy -hidden _cvs_query_output_form');
   output_form_wid.refresh('W');
   output_form_wid.p_caption=CVS_QUERY_OUTPUT_CAPTION_PREFIX:+filename;
   html_friendly_tag_caption := "";
   output_form_wid.SetInfoPane(by_date,by_user,symbol_changed,start_date,end_date,user_name,html_friendly_tag_caption);

   AddToQueryOutput(output_form_wid,'<FONT face="Courier">');
   if ( by_user ) _append_retrieve(ctluser,ctluser.p_text);
   if ( by_date ) {
      _append_retrieve(ctlstart_date,ctlstart_date.p_text);
      _append_retrieve(ctlend_date,ctlend_date.p_text);
   }
   _nocheck _control ctlsymbol_name;
   if ( symbol_changed ) _append_retrieve(ctlsymbol_name,ctlsymbol_name.p_text);
   tag_caption := ctlsymbol_name.p_text;
   query_form_wid.p_active_form._delete_window();
   if ( symbol_changed ) {
      startline := endline := commentline := 0;
      type := "";
      tag_name := "";
      tag_tree_decompose_caption(tag_caption,tag_name);
      html_friendly_tag_caption=GetHTMLFriendlyTagCaption(tag_caption);
      status=FindSymbolInfo(filename,
                            tag_name,
                            tag_caption,
                            startline,endline,commentline,type);
      if ( status ) {
         _delete_temp_view(HistoryViewId);
         delete_file(ErrorFilename);
         _message_box(nls("%s",get_message(status)));
         return;
      }

      LoadInfoIntoTree(xml_handle,TREE_ROOT_INDEX,info.VersionList);

      _str branches:[][];
      TraverseTree(xml_handle,TREE_ROOT_INDEX,branches,info.Branches);

      // info.LocalVersion is the current version, use this to figure out
      // what the current branch is.

      _str branch_names[];
      GetIndexNamesFromHashtab(branch_names,branches);
      bool selected_items[];

      int i;
      for (i=0;i<branch_names._length();++i) {
         if (GetNamedBranch(GetBranch(info.LocalVersion),info.Branches) == branch_names[i]) {
            selected_items[i]=true;
         }
      }

      _str branches_to_compare=select_tree(branch_names,null,null,null,selected_items,null,null,"Select branches to query",SL_CHECKLIST);

      _xmlcfg_close(xml_handle);

      if (branches_to_compare=='' || branches_to_compare == COMMAND_CANCELLED_RC) {
         _delete_temp_view(HistoryViewId);
         delete_file(ErrorFilename);
         return;
      }
      output_form_wid.p_visible=true;
      // Do this again to fill in the tag name
      output_form_wid.SetInfoPane(by_date,by_user,symbol_changed,start_date,end_date,user_name,html_friendly_tag_caption);
      FindDifferentVersions(filename,branches_to_compare,branches,tag_name,tag_caption,html_friendly_tag_caption,MatchedVersions,output_form_wid,remote_filename);
   }else{
      output_form_wid.p_visible=true;
      int i=0,len=info.VersionList._length();
      for (i=0;i<len;++i) {
         _str cur_version=info.VersionList[i].RevisionNumber;
         if ( MatchedVersions:[cur_version]==true ) {
            AddToQueryOutput(output_form_wid,'Version 'GetVersionTag(cur_version)'<P>');
            OLD_VERSION_SYMBOL_INFO version_info:[];
            _nocheck _control ctlstop;
            version_info=output_form_wid.QUERY_VERSION_INFO();
            version_info:[cur_version].filename=null;
            version_info:[cur_version].StartLine=-1;
            version_info:[cur_version].EndLine=-1;
            version_info:[cur_version].CVSPath=remote_filename;
            output_form_wid.QUERY_VERSION_INFO(version_info);
         }
      }
      _nocheck _control ctlstop;
      output_form_wid.ctlstop.p_caption=CLOSE_CAPTION;
      output_form_wid.ctlstop.p_cancel=true;
   }
   output_form_wid.SetInfoPane(by_date,by_user,symbol_changed,start_date,end_date,user_name,html_friendly_tag_caption);
   AddToQueryOutput(output_form_wid,'</FONT>');
   _save_form_response();
   _delete_temp_view(HistoryViewId);
   delete_file(ErrorFilename);
}

static _str MakeVersionInfoString(_str cur_version,_str cur_tempfile,_str cur_start_line_number,_str cur_end_line_number)
{
   return(_maybe_quote_filename(cur_version)' '_maybe_quote_filename(cur_tempfile)' '_maybe_quote_filename(cur_start_line_number)' '_maybe_quote_filename(cur_end_line_number));
}

static void GetInfoFromVersionString(_str info,_str &cur_version,_str &cur_tempfile,int &cur_start_line_number,int &cur_end_line_number)
{
   cur_version=parse_file(info);
   cur_tempfile=parse_file(info);
   cur_start_line_number=(typeless)parse_file(info);
   cur_end_line_number=(typeless)parse_file(info);
}

static _str GetVersionTag(_str Version,_str Caption='')
{
   Caption=stranslate(Caption,"&nbsp;"," ");
   if (Caption=='') {
      Caption=Version;
   }
   return('<A href="-viewhist 'Version'">'Caption'</A>');
}

static void MaybeSetEditVersionEntry(_str cur_version,
                                        OLD_VERSION_SYMBOL_INFO (&version_info):[],
                                        _str cur_tempfile,_str RemoteFilename)
{
   if ( version_info:[cur_version]==null ) {
      version_info:[cur_version].filename=cur_tempfile;
      version_info:[cur_version].StartLine=-1;
      version_info:[cur_version].EndLine=-1;
      version_info:[cur_version].CVSPath=RemoteFilename;
   }
}

static int gInFindDifferentVersions;
static _str NonBreaking(_str a) {
   return stranslate(a,"&nbsp;",' ');
}
static void FindDifferentVersions(_str filename,
                                  _str branches_to_compare,_str (&branches):[][],
                                  _str tag_name,_str tag_caption,
                                  _str html_friendly_tag_caption,
                                  bool (&MatchedVersions):[],
                                  int form_wid,
                                  _str RemoteFilename)
{
   gInFindDifferentVersions=1;
   _nocheck _control ctlstop;
   just_name := _strip_filename(filename,'P');

   tip_will_be_compared := pos("\n"branches_to_compare"\n","\nTip\n")!=0;

   bool SaveVersions:[];

   typeless i;
   _str orig_dir=getcwd();
   version_changed := false;
   OLD_VERSION_SYMBOL_INFO version_info:[];
   existed_in_last_version := false;
   outerloop:
   for (i._makeempty();;) {
      branches._nextel(i);
      if (i._isempty()) break;
      if ( pos("\n"i"\n","\n"branches_to_compare"\n") ) {

         int len=branches:[i]._length();

         _str error_filename=mktemp();
         _CVSCreateTempFile(error_filename);

         _str last_tempdir=mktemp();

         _str last_version=branches:[i][0];
         message('Checking out version 'last_version);
         int status=_CVSCheckout(RemoteFilename,last_tempdir,'-r 'last_version,error_filename,true,false,true);
         if (status) {
            _SVCDisplayErrorOutputFromFile(error_filename);
            break;
         }
         last_start_line_number := last_end_line_number := last_comment_line_number := 0;
         last_tag_type := "";
         last_tempfile := last_tempdir:+FILESEP:+just_name;
         int last_status=FindSymbolInfo(last_tempfile,tag_name,tag_caption,
                                        last_start_line_number,last_end_line_number,last_comment_line_number,last_tag_type,
                                        null);
         if (last_status) {
            AddToQueryOutput(form_wid,'<P><font size=small>'html_friendly_tag_caption:+NonBreaking(' does not exist in version '):+last_version);
         }

         int j;
         for (j=1;j<len;++j) {
            version_changed=false;
            _str cur_tempdir=mktemp();

            _str cur_version=branches:[i][j];

            message('Checking out version 'cur_version);
            compare_these_versions := (MatchedVersions==null) || (MatchedVersions:[last_version]==true) || (MatchedVersions:[cur_version]==true);
            if ( compare_these_versions ) {
               status=_CVSCheckout(RemoteFilename,cur_tempdir,'-r 'cur_version,error_filename,true,false,true);
               if (status) {
                  _SVCDisplayErrorOutputFromFile(error_filename);
                  break;
               }
            }

            cur_start_line_number := cur_end_line_number := cur_comment_line_number := 0;
            cur_tag_type := "";
            cur_tempfile := cur_tempdir:+FILESEP:+just_name;
            int cur_status=FindSymbolInfo(cur_tempfile,tag_name,tag_caption,
                                          cur_start_line_number,cur_end_line_number,cur_comment_line_number,cur_tag_type,
                                          null);
            if ( !compare_these_versions ) {
               // Still have to copy this information, because when there is a
               // changed symbol, we may be comparing against a version that did
               // not meet date/user criteria

               last_start_line_number=cur_start_line_number;
               last_end_line_number=cur_end_line_number;
               last_comment_line_number=cur_comment_line_number;
               last_tag_type=cur_tag_type;
               last_status=cur_status;
               last_tempdir=cur_tempdir;
               last_tempfile=cur_tempfile;
               last_version=cur_version;
               continue;
            }
            if (cur_status) {
               // Does not exist in current version
               if ( existed_in_last_version ) {
                  AddToQueryOutput(form_wid,'<P>'html_friendly_tag_caption'<FONT color=red>'NonBreaking(' did not exist in version '):+GetVersionTag(cur_version)'</FONT>&nbsp;<A href="-all 'last_version' 'cur_version'">':+NonBreaking('Compare Versions '):+last_version:+NonBreaking(' and '):+cur_version'</A>');
               }else{
                  AddToQueryOutput(form_wid,'<P>'html_friendly_tag_caption:+NonBreaking(' did not exist in version '):+GetVersionTag(cur_version)'&nbsp;<A href="-all 'last_version' 'cur_version'">':+NonBreaking('Compare Versions '):+last_version:+NonBreaking(' and '):+cur_version'</A>');
               }
               MaybeSetEditVersionEntry(cur_version,version_info,cur_tempfile,RemoteFilename);
               MaybeSetEditVersionEntry(last_version,version_info,last_tempfile,RemoteFilename);
               form_wid.QUERY_VERSION_INFO(version_info);

               existed_in_last_version=false;
            }

            if (!last_status && !cur_status && compare_these_versions) {
               existed_in_last_version=true;
               // Here compare the versions
               bool matched;
               message('Comparing versions 'last_version' and 'cur_version);
               int compare_status=CompareSections(last_tempfile,last_start_line_number,last_end_line_number,
                                                  cur_tempfile,cur_start_line_number,cur_end_line_number,matched);
               if (compare_status) {
                  _message_box(nls("Could not compare versions %s and %s\n\n%s",last_version,cur_version,get_message(status)));
               }
               if (!matched) {
                  version_changed=true;
                  AddToQueryOutput(form_wid,'<P>'html_friendly_tag_caption'<FONT color=red>':+NonBreaking(' changed between '):+GetVersionTag(last_version):+NonBreaking(' and ')GetVersionTag(cur_version)'</FONT>&nbsp;<A href="'last_version' 'cur_version'">':+NonBreaking('Compare Symbols'):+'</A>&nbsp;<A href="-all 'last_version' 'cur_version'">'NonBreaking('Compare Files</A>') );
                  version_info:[cur_version].filename=cur_tempfile;
                  version_info:[cur_version].StartLine=cur_start_line_number;
                  version_info:[cur_version].EndLine=cur_end_line_number;
                  version_info:[cur_version].CVSPath=RemoteFilename;

                  version_info:[last_version].filename=last_tempfile;
                  version_info:[last_version].StartLine=last_start_line_number;
                  version_info:[last_version].EndLine=last_end_line_number;
                  version_info:[last_version].CVSPath=RemoteFilename;

                  form_wid.QUERY_VERSION_INFO(version_info);

               }else{
                  MaybeSetEditVersionEntry(cur_version,version_info,cur_tempfile,RemoteFilename);
                  MaybeSetEditVersionEntry(last_version,version_info,last_tempfile,RemoteFilename);
                  form_wid.QUERY_VERSION_INFO(version_info);

                  if ( existed_in_last_version ) {
                     //AddToQueryOutput(form_wid,'<P>'html_friendly_tag_caption:+NonBreaking(' did not change between ')GetVersionTag(last_version):+NonBreaking(' and '):+GetVersionTag(cur_version));
                  }
               }
            }else if ( !compare_these_versions ) {
               message('Skipping verison 'cur_version' because it does not match other query parameters');
            }

            last_start_line_number=cur_start_line_number;
            last_end_line_number=cur_end_line_number;
            last_comment_line_number=cur_comment_line_number;
            last_tag_type=cur_tag_type;
            last_status=cur_status;
            last_tempdir=cur_tempdir;
            last_tempfile=cur_tempfile;
            last_version=cur_version;
            gCancel=false;
            process_events(gCancel);
            if (gCancel) break outerloop;
         }
         delete_file(error_filename);
      }
   }
   form_wid.ctlstop.p_caption=CLOSE_CAPTION;
   form_wid.ctlstop.p_cancel=true;
   gInFindDifferentVersions=0;
}

static void AddToQueryOutput(int form_wid,_str caption)
{
   _nocheck _control ctlminihtml1;
   form_wid.ctlminihtml1.p_text=form_wid.ctlminihtml1.p_text"\n"caption;
   form_wid._set_foreground_window();
}

static int CompareSections(_str file1,int start_line_number1,int end_line_number1,
                           _str file2,int start_line_number2,int end_line_number2,
                           bool &sections_matched)
{
   sections_matched=false;

   int status;
   int temp_view_id1,orig_view_id;
   status=_open_temp_view(file1,temp_view_id1,orig_view_id);
   if (status) return(status);

   p_window_id=orig_view_id;
   int temp_view_id2;
   status=_open_temp_view(file2,temp_view_id2,orig_view_id);
   if (status) return(status);

   p_window_id=orig_view_id;

   _str ImaginaryLineCaption=null;
   int OutputBufId;

   DIFF_INFO info;
   info.iViewID1 = temp_view_id1;
   info.iViewID2 = temp_view_id2;
   info.iOptions = def_diff_flags|DIFF_NO_BUFFER_SETUP;
   info.iNumDiffOutputs = 0;
   info.iIsSourceDiff = false;
   info.loadOptions = def_load_options;
   info.iGaugeWID = 0;
   info.iMaxFastFileSize = def_max_fast_diff_size;
   info.lineRange1 = start_line_number1'-'end_line_number1;
   info.lineRange2 = start_line_number2'-'end_line_number2;
   info.iSmartDiffLimit = def_smart_diff_limit;
   info.imaginaryText = ImaginaryLineCaption;
   info.tokenExclusionMappings = null;
   status=Diff(info,0);

   _delete_temp_view(temp_view_id1);
   _delete_temp_view(temp_view_id2);

   sections_matched=DiffFilesMatched()!=0;

   return(status);
}

static _str GetFilenameFromDialog(_str parse_str=CVS_QUERY_CAPTION_PREFIX)
{
   if ( _no_child_windows() ) return('');
   filename := "";
   parse p_active_form.p_caption with (parse_str) filename;
   return(filename);
}

void ctllist_symbols.lbutton_up()
{
   _str Filename,FunctionName,TagInfo;
   int StartLineNumber,EndLineNumber,CommentLineNumber;
   Filename=GetFilenameFromDialog();
   int status=GetSymbolInfo(Filename,FunctionName,
                            StartLineNumber,EndLineNumber,CommentLineNumber,TagInfo,
                            null);
   if (!status) {
      p_prev.p_text=FunctionName;
      ctlok._set_focus();
   }
}

defeventtab _cvs_query_output_form;

static void SetInfoPane(bool by_date,bool by_user,bool symbol_changed,
                        _str start_date,_str end_date,_str user_name,_str html_friendly_tag_caption)
{
   info_text := "";
   if ( by_date ) {
      if ( start_date!='' ) {
         info_text='Versions commited on or after <B>'start_date'</B>';
      }
      if ( end_date!='' ) {
         if ( info_text!='' ) info_text :+= ' AND ';
         info_text :+= 'Versions commited on or before <B>'end_date'</B>';
      }
   }
   if ( by_user ) {
      if ( info_text!='' ) info_text :+= '<P><B>AND</B><P>';
      info_text :+= 'Versions commited by user <B>'user_name'</B>';
   }
   if ( symbol_changed ) {
      if ( info_text!='' ) info_text :+= '<P><B>AND</B><P>';
      info_text :+= 'Versions where the symbol <B>'html_friendly_tag_caption'</B> changed';
   }
   ctlinfo.p_text=info_text;
}

void ctlstop.on_create()
{
   // Have to make sure that these always match
   ctlstop.p_caption=STOP_CAPTION;
   ctlminihtml1._minihtml_UseDialogFont();
   ctlminihtml1.p_backcolor=0x80000022;
   ctlinfo.p_backcolor=0x80000022;
}

void ctlstop.lbutton_up()
{
   if (p_caption==STOP_CAPTION) {
      gCancel=true;
   }else if (p_caption==CLOSE_CAPTION) {
      p_active_form._delete_window();
   }
}

void _cvs_query_output_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_active_form.p_client_height);

   int xbuffer=ctlminihtml1.p_x;
   int ybuffer=ctlminihtml1.p_y;

   ctlminihtml1.p_width=client_width-(2*xbuffer);
   int height_available=(client_height-ctlstop.p_height)-(4*ybuffer);
   ctlminihtml1.p_height=((height_available * 3) intdiv 4);
   ctlinfo.p_y=ctlminihtml1.p_y_extent+ybuffer;
   ctlinfo.p_width=ctlminihtml1.p_width;
   ctlinfo.p_height=(height_available intdiv 4);

   ctlstop.p_y=ctlinfo.p_y_extent+ybuffer;
   ctlstop.p_x=(client_width-ctlstop.p_width) intdiv 2;
}

void ctlminihtml1.on_change(int reason,_str hrefText)
{
   active_form_wid := p_active_form;
   if ( reason==CHANGE_CLICKED_ON_HTML_LINK ) {
      OLD_VERSION_SYMBOL_INFO version_info:[];
      version_info=QUERY_VERSION_INFO();
      _str info=hrefText;
      _str version1,version2;
      version1=parse_file(info);

      whole_file := false;
      if (version1=='-all') {
         whole_file=true;
         version1=parse_file(info);
      }else if (version1=='-viewhist') {
         version1=parse_file(info);
         cvs_history(GetFilenameFromDialog(CVS_QUERY_OUTPUT_CAPTION_PREFIX),false,version1);
         /*version1=parse_file(info);
         OLD_VERSION_SYMBOL_INFO *pversion1_info=&(version_info:[version1]);
         if ( pversion1_info->filename==null ) {
            _str temp_dir='',ErrorFilename=mktemp();
            _CVSCreateTempFile(ErrorFilename);
            temp_dir=mktemp();
            int status=_CVSCheckout(pversion1_info->CVSPath,temp_dir,'',ErrorFilename);
            if ( status ) {
               _CVSDisplayErrorOutputFromFile(ErrorFilename,status);
               return;
            }
            delete_file(ErrorFilename);
            pversion1_info->filename=temp_dir;
            _maybe_append_filesep(pversion1_info->filename);
            pversion1_info->filename=pversion1_info->filename:+strip_filename(pversion1_info->CVSPath,'P');
            QUERY_VERSION_INFO(version_info);
         }
         _DiffShowFile(pversion1_info->filename,pversion1_info->CVSPath' (Version 'version1')');*/
         return;
      }
      version2=parse_file(info);

      OLD_VERSION_SYMBOL_INFO *pversion1_info=&(version_info:[version1]);
      OLD_VERSION_SYMBOL_INFO *pversion2_info=&(version_info:[version2]);

      _str diff_command_line='-r1 -r2 -nomapping -file1title "'pversion1_info->CVSPath' (Version 'version1' - Remote)" -file2title "'pversion2_info->CVSPath' (Version 'version2' - Remote)"';
      if (!whole_file) {
         diff_command_line :+= ' -range1:'pversion1_info->StartLine','pversion1_info->EndLine' -range2:'pversion2_info->StartLine','pversion2_info->EndLine;
      }
      diff_command_line :+= ' '_maybe_quote_filename(pversion1_info->filename)' '_maybe_quote_filename(pversion2_info->filename);
      _DiffModal(diff_command_line);
   }

   int wid=_find_formobj('_cvs_query_output_form','N');
   if (wid) {
      wid._set_foreground_window();
      p_window_id=wid;
   }
}

void ctlstop.on_destroy()
{
   OLD_VERSION_SYMBOL_INFO version_info:[];
   version_info=QUERY_VERSION_INFO();
   if ( version_info==null || version_info._varformat()!=VF_HASHTAB ) {
      return;
   }
   typeless i;
   for (i._makeempty();;) {
      version_info._nextel(i);
      if (i._isempty()) break;
      _str cur_filename=version_info:[i].filename;
      if ( cur_filename!='' && cur_filename!=null) {
         _DelTree(_file_path(version_info:[i].filename),true);
      }
   }
}

static const JANUARY=    1;
static const FEBRUARY=   2;
static const MARCH=      3;
static const APRIL=      4;
static const MAY=        5;
static const JUNE=       6;
static const JULY=       7;
static const AUGUST=     8;
static const SEPTEMBER=  9;
static const OCTOBER=   10;
static const NOVEMBER=  11;
static const DECEMBER=  12;

static int NumDayTable[]={0,31,28,31,30,31,30,
                          31,31,30,31,30,31};

static int GetRealYear(int year)
{
   if (length(year)==2) {
      if (year>79) {
         year=(int)('19':+(_str)year);
      }else{
         year=(int)('20':+(_str)year);
      }
   }
   return(year);
}

/**
 * Returns the number of days that the specified date is since Jan 1, 1980
 *
 * @param month  Month of specified date, 1-12
 * @param day    Day of date specified
 * @param year   Year of date specified
 *
 * @return number of days that the specified date is since Jan 1, 1980
 */
int _days_since_ny1980(int month,int day,int year)
{
   year=GetRealYear(year);
   int numyears=year-1980;
   numdays := 0;
   int i;
   for (i=1980;i<=year;++i) {
      int finishmonth;
      if (i==year) {
         finishmonth=month-1;
      }else{
         finishmonth=12;
      }
      int j;
      for (j=0;j<=finishmonth;++j) {
         if (j==FEBRUARY && !(i%4)) {
            numdays+=NumDayTable[j]+1;
         }else{
            numdays+=NumDayTable[j];
         }
      }
   }
   numdays+=day;
   return(numdays);
}

static int parse_date(_str datein,_str &month='',_str &day='',_str &year='')
{
   month=day=year='';

   parse datein with month '/' day '/' year;
   if ( month=='' ) {
      parse datein with month '-' day '-' year;
   }
   if ( !isinteger(month) || month<1 || month>31 ) {
      return(1);
   }
   if ( !isinteger(day) || day<1 || day>31 ) {
      return(1);
   }
   if ( !isinteger(year) || year<0 ) {
      return(1);
   }
   year=(_str)GetRealYear((int)year);
   return(0);
}
