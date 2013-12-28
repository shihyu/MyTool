////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49779 $
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
#include "svc.sh"
#include "diff.sh"
#include "tagsdb.sh"
#import "codehelp.e"
#import "context.e"
#import "diffmf.e"
#import "guiopen.e"
#import "listproc.e"
#import "mprompt.e"
#import "stdprocs.e"
#import "svchistory.e"
#import "treeview.e"
#import "se/tags/TaggingGuard.e"
#endregion

struct DIFF_TAG_CALLBACK_INFO {
   typeless pfnAlternate;
   typeless CallbackData;
};

struct DIFF_TAG_LIST_INFO {
   _str Filename;
   int Flags;
};

static int BuildTagTable(_str filename,int &view_id,
                         int treewid,_str load_options,
                         _str &real_filename=null,
                         _str alt_language='')
{
   _str LineNumFromNames:[]=null;
   if (pos(' +bi ',' 'load_options' ',1,'i')) {
      load_options=load_options' 'filename;
      filename='';
   }
   int temp_view_id=0;
   int orig_view_id=0;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,load_options,true,false,true);
   if (status) return(status);

   real_filename=p_buf_name;
   _str lang = p_LangId;
   if (alt_language!='') {
      lang = alt_language;
   }
   if (!_istagging_supported(lang)) {
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return(1);
   }

   top();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int i, n=tag_get_num_of_context();
   // Have to use p_buf_name here, because there are places where filename is
   // really a buffer id
   int sln=0;
   int eln=0;
   int unused=0;
   _str type_name='';
   int start_seekpos=0;
   _str Keyname=_DiffTagInfoGetIndex(treewid,real_filename);
   case_sensitive := p_EmbeddedCaseSensitive;
   _DiffTagInitKey(Keyname,case_sensitive);
   for (i=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,i,start_seekpos);

      _GoToROffset(start_seekpos);
      status=_do_default_get_tag_header_comments(sln,unused);

      if (sln=='' || status) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,sln);
      }
      tag_get_detail2(VS_TAGDETAIL_context_end_linenum,i,eln);
      _str name=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false):+' ':+type_name;
      _str ciname = case_sensitive? name:upcase(name);

      _DiffTagStoreInfo(Keyname,name,sln,eln,p_Noflines,case_sensitive);
   }
   p_window_id=orig_view_id;
   view_id=temp_view_id;
   return(0);
}

static void BuildOneTable(_str Key1,_str Key2,_str (&OneTable):[],
                          boolean TryToResolveDifferentSignatures=true)
{
   typeless i;
   int tagindex2=0;

   _str DelTable1:[]=null;
   _str DelTable2:[]=null;

   for (i=0;;++i) {
      _str curtag='';
      int status=_DiffTagGetTagName(Key1,i,curtag);
      if (status) break;

      _DiffTagTagExists(Key2,curtag,tagindex2);
      if (tagindex2>-1) {
         OneTable:[curtag]='';
         DelTable2:[curtag]=i;
         DelTable1:[curtag]=i;
      }
   }

   struct CHANGED_NAME_INFO {
      int count;
      _str RealName;
   };
   CHANGED_NAME_INFO JustNames1:[]=null,JustNames2:[]=null;

   typeless type='';
   _str name='';
   for (i=0;;++i) {
      _str curtag='';
      int status=_DiffTagGetTagName(Key1,i,curtag);
      if (status) break;
      if (DelTable1._indexin(curtag)) continue;
      OneTable:[curtag]='-';
      parse curtag with (_chr(1)) type;
      parse curtag with name '(' .;
      name=name' 'type;
      if (!JustNames1._indexin(name)) {
         JustNames1:[name].count=1;
         JustNames1:[name].RealName=curtag;
      }else{
         ++JustNames1:[name].count;
      }
   }
   for (i=0;;++i) {
      _str curtag='';
      int status=_DiffTagGetTagName(Key2,i,curtag);
      if (status) break;
      if (DelTable2._indexin(curtag)) continue;
      OneTable:[curtag]='+';
      parse curtag with (_chr(1)) type;
      parse curtag with name '(' .;
      name=name' 'type;
      if (!JustNames2._indexin(name)) {
         JustNames2:[name].count=1;
         JustNames2:[name].RealName=curtag;
      }else{
         ++JustNames2:[name].count;
      }
   }
   if (TryToResolveDifferentSignatures) {
      for (i._makeempty();;) {
         JustNames1._nextel(i);
         if (i._isempty()) break;
         if ( JustNames1:[i]==null ) continue;
         if (JustNames2._indexin(i) &&
             JustNames1:[i].count==1 &&
             JustNames2:[i].count==1) {
            OneTable:[JustNames1:[i].RealName]='Different'_chr(1):+JustNames2:[i].RealName;
            OneTable._deleteel(JustNames2:[i].RealName);
         }
      }
   }
}

_str _DiffTagInfoGetIndex(int TreeWID,_str Filename)
{
   return(TreeWID:+_chr(1):+Filename);
}

// These constants have to match the ones in vs.h

#define DIFF_TAG_STATUS_MATCH     0
#define DIFF_TAG_STATUS_PATH1     1
#define DIFF_TAG_STATUS_PATH2     2
#define DIFF_TAG_STATUS_DIFFERENT 3
#define DIFF_TAG_STATUS_MOVED     4

int _DiffExpandTags2(_str filename1,_str filename2,int ParentIndex1,int ParentIndex2,
                     _str load_options1='',_str load_options2='',
                     DIFF_TAG_CALLBACK_INFO *pAlternateInfo=null,
                     boolean TryToResolveDifferentSignatures=true,
                     int wid1=-1,int wid2=-1,int treeFlags=GMFDiffViewOptions,
                     _str alternate_ext1='',_str alternate_ext2='')
{
   mou_hour_glass(1);
   if (wid1<0) {
      wid1=_find_control('tree1');
   }
   if (wid2<0) {
      wid2=_find_control('tree2');
   }
   //_control wid1,wid2;
   _str AlternateMatchName='';
   int viewid1=0,viewid2=0;
   _str real_filename1='';
   _str real_filename2='';
   int status=BuildTagTable(filename1,viewid1,wid1,load_options1,real_filename1,alternate_ext1);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }

   status=BuildTagTable(filename2,viewid2,wid2,load_options2,real_filename2,alternate_ext2);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }
   if (!viewid1||!viewid2) {
      // This should not happen, but is just a little double check.  If one
      // of these is null, we're going to get a billion individual
      // "Invalid Argument" errors
      return(1);
   }

   typeless junk='';
   typeless r1='';
   typeless r2='';
   int orig_view_id=p_window_id;
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   Diff(viewid1,
        viewid2
        ,DIFF_NO_BUFFER_SETUP|def_diff_options,
        0,0,0,def_load_options,0,junk,800,1,1,0,null);
   p_window_id=orig_view_id;

   _str OneTable:[]=null;
   _str key1=_DiffTagInfoGetIndex(wid1,real_filename1);
   _str key2=_DiffTagInfoGetIndex(wid2,real_filename2);
   BuildOneTable(key1,key2,OneTable,TryToResolveDifferentSignatures);

   int ff;
   _str name='';
   typeless DifferentList[]=null;
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(1,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key1,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(2,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key2,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   typeless exists1=0;
   typeless exists2=0;
   _str name1='';
   _str name2='';
   int startline1=0;
   int startline2=0;
   int endline1=0;
   int endline2=0;
   typeless i;
   _str asc1=_chr(1);
   for (i=0;i<DifferentList._length();++i) {
      _DiffTagTagExists(key1,DifferentList[i],exists1);
      _DiffTagTagExists(key2,DifferentList[i],exists2);

      _DiffTagGetTagName(key1,DifferentList[i],name1);
      _DiffTagGetTagName(key1,DifferentList[i],name2);

      if (exists1>-1 && exists2>-1 ) {
         _str cur_name=DifferentList[i];
         _DiffTagGetLineInfo(key1,cur_name,startline1,endline1);
         _DiffTagGetLineInfo(key2,cur_name,startline2,endline2);
         r1=startline1'-'endline1;
         r2=startline2'-'endline2;
         status=Diff(viewid1,
                     viewid2,
                     DIFF_OUTPUT_BOOLEAN|DIFF_NO_BUFFER_SETUP,
                     0,0,0,def_load_options,0,junk,800,
                     r1,r2,
                     0/*def_smart_diff_limit*/,null);
         if (!status) {
            OneTable:[DifferentList[i]]='Moved';
         }
      }
   }
   _str OneList[]=null;
   for (i._makeempty();;) {
      OneTable._nextel(i);
      if (i._isempty()) break;
      if ( OneTable:[i]==null ) continue;
      OneList[OneList._length()]=i;
   }
   OneList._sort('i');

   // Have to quit the views this way because the buffer may need to stay
   // in memory, but not be in an editor- so _delete_temp_view will close it
   // anyway.
   DiffTagsDeleteTempView(viewid1,load_options1);
   DiffTagsDeleteTempView(viewid2,load_options2);

   boolean NeedToSetCur=false;


   int diff_tags_callback_index=find_index("_diff_tags_callback1",PROC_TYPE);
   int SibDepth=0;
   if (ParentIndex1>-1) {
      int wid=p_window_id;
      p_window_id=wid1;
      SibDepth=GetCurIndexSiblingDepth();
      int Tree1CurIndex=_TreeCurIndex();
      if (!pAlternateInfo) _TreeDelete(ParentIndex1,'C');
      if (Tree1CurIndex!=_TreeCurIndex()) {
         NeedToSetCur=true;
      }

      if (pAlternateInfo) {
         (pAlternateInfo->pfnAlternate)('','',0,0,pAlternateInfo->CallbackData,1);
      }

      p_window_id=wid;
   }
   if (!pAlternateInfo && ParentIndex2>-1) wid2._TreeDelete(ParentIndex2,'C');
   int tagstate=-1;
   int state=0;
   for (i=0;i<OneList._length();++i) {
      int bm1,bm2;
      _str cur=OneList[i];
      _str type=OneTable:[cur];
      parse type with type (_chr(1)) .;
      if (type=='+') {
         bm1=_pic_symbolm;
         bm2=_pic_symbolp;
         state=DIFF_TAG_STATUS_PATH2;
      }else if (type=='-') {
         bm1=_pic_symbolp;
         bm2=_pic_symbolm;
         state=DIFF_TAG_STATUS_PATH1;
      }else if (type=="\t") {
         bm1=_pic_symbol;
         bm2=_pic_symbol;
         state=DIFF_TAG_STATUS_MATCH;
      }else if (type=='Different') {
         bm1=_pic_symbold;
         bm2=_pic_symbold;
         state=DIFF_TAG_STATUS_DIFFERENT;
      }else if (type=='Moved') {
         bm1=_pic_symbolmoved;
         bm2=_pic_symbolmoved;
         state=DIFF_TAG_STATUS_MOVED;
      }
      int moreflags=0;
      if ((type=='Different') &&
          !(treeFlags&DIFF_VIEW_DIFFERENT_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=="\t" &&
                !(treeFlags&DIFF_VIEW_MATCHING_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=='+' &&
                !(treeFlags&DIFF_VIEW_MISSING_SYMBOLS1)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=='-' &&
                !(treeFlags&DIFF_VIEW_MISSING_SYMBOLS2)) {
         moreflags=TREENODE_HIDDEN;
      }else if ((type=='Moved') &&
                !(treeFlags&DIFF_VIEW_MOVED_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }
      _str cap2=cur;
      parse OneTable:[cur] with type (_chr(1)) AlternateMatchName;
      if (AlternateMatchName!='') {
         cap2=AlternateMatchName;
         bm1=bm2=_pic_symbold;
      }
      status=_DiffTagGetLineInfo(key1,cur,startline1,endline1);
      if (!status) {
         r1=startline1','endline1;
      }else{
         r1=null;
      }
      if (cur==cap2) {
         status=_DiffTagGetLineInfo(key2,cur,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }else{
         status=_DiffTagGetLineInfo(key2,cap2,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }
      int newindex=-1;
      if (!pAlternateInfo) {
         if (ParentIndex1>-1) {
            wid1._TreeGetInfo(TREE_ROOT_INDEX,state);
            newindex=wid1._TreeAddItem(ParentIndex1,
                                       cur,
                                       TREE_ADD_AS_CHILD,
                                       bm1,bm1,-1,moreflags,r1);
         }
         if (ParentIndex2>-1) {
            int newindex2=wid2._TreeAddItem(ParentIndex2,
                                        cap2,
                                        TREE_ADD_AS_CHILD,
                                        bm2,bm2,-1,moreflags,r2);
         }
      }else{
         (pAlternateInfo->pfnAlternate)(cur,cap2,bm1,bm2,&(pAlternateInfo->CallbackData),0);
      }
      if (diff_tags_callback_index) {
         call_index(cur,state,diff_tags_callback_index);
      }
   }
   if (pAlternateInfo) {
      (pAlternateInfo->pfnAlternate)('','',0,0,&(pAlternateInfo->CallbackData),-1);
   }
   if (diff_tags_callback_index) {
      call_index('',-1,diff_tags_callback_index);
   }
   if (NeedToSetCur && ParentIndex1>-1) {
      int wid=p_window_id;
      p_window_id=wid1;
      SetCurIndexSiblingDepth(SibDepth);
      p_window_id=wid;
   }
   if (ParentIndex1>-1) {
      wid1._TreeRefresh();
   }
   if (ParentIndex2>-1) {
      wid2._TreeRefresh();
   }

   mou_hour_glass(0);
   return(0);
}

static int BuildTagTableFromWID(int iWID,_str versionNum,_str filename)
{
   orig_view_id := p_window_id;
   p_window_id = iWID;
   _str LineNumFromNames:[]=null;

   _str lang = p_LangId;
   if (!_istagging_supported(lang)) {
      p_window_id=orig_view_id;
      return 1;
   }

   top();
   _UpdateContext(true);

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   int i, n=tag_get_num_of_context();
   // Have to use p_buf_name here, because there are places where filename is
   // really a buffer id
   int sln=0;
   int eln=0;
   int unused=0;
   _str type_name='';
   int start_seekpos=0;
   _str Keyname=_DiffTagInfoGetIndex(p_window_id,filename' 'versionNum);
   case_sensitive := p_EmbeddedCaseSensitive;
   _DiffTagInitKey(Keyname,case_sensitive);
   for (i=1; i<=n; i++) {
      // is this a function, procedure, or prototype?
      tag_get_detail2(VS_TAGDETAIL_context_type,i,type_name);
      tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,i,start_seekpos);

      _GoToROffset(start_seekpos);
      status:=_do_default_get_tag_header_comments(sln,unused);

      if (sln=='' || status) {
         tag_get_detail2(VS_TAGDETAIL_context_start_linenum,i,sln);
      }
      tag_get_detail2(VS_TAGDETAIL_context_end_linenum,i,eln);
      _str name=tag_tree_make_caption_fast(VS_TAGMATCH_context,i,true,true,false):+' ':+type_name;
      _str ciname = case_sensitive? name:upcase(name);

      _DiffTagStoreInfo(Keyname,name,sln,eln,p_Noflines,case_sensitive);
   }
   p_window_id=orig_view_id;
   return 0;
}

#if 0 //9:05am 3/4/2013
// Very specific to _svc_history_form.  Currently not used
int _DiffExpandTagsForSVCHistory(int WID1,int WID2,int parentIndex,_str filename,
                                 _str ver1,_str ver2)
{
   int orig_view_id=p_window_id;
   boolean TryToResolveDifferentSignatures=true;
   mou_hour_glass(1);
   int status=BuildTagTableFromWID(WID1,ver1,filename);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }

   status=BuildTagTableFromWID(WID2,ver2,filename);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }
   if (!WID1||!WID2) {
      // This should not happen, but is just a little double check.  If one
      // of these is null, we're going to get a billion individual
      // "Invalid Argument" errors
      return(1);
   }

   typeless junk='';
   typeless r1='';
   typeless r2='';
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   Diff(WID1,
        WID2
        ,DIFF_NO_BUFFER_SETUP|def_diff_options,
        0,0,0,def_load_options,0,junk,800,1,1,0,null);
   p_window_id=orig_view_id;

   _str OneTable:[]=null;
   _str key1=_DiffTagInfoGetIndex(WID1,filename' 'ver1);
   _str key2=_DiffTagInfoGetIndex(WID2,filename' 'ver2);
   BuildOneTable(key1,key2,OneTable,TryToResolveDifferentSignatures);

   int ff;
   _str name='';
   typeless DifferentList[]=null;
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(1,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key1,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(2,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key2,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   typeless exists1=0;
   typeless exists2=0;
   _str name1='';
   _str name2='';
   int startline1=0;
   int startline2=0;
   int endline1=0;
   int endline2=0;
   typeless i;
   _str asc1=_chr(1);
   for (i=0;i<DifferentList._length();++i) {
      _DiffTagTagExists(key1,DifferentList[i],exists1);
      _DiffTagTagExists(key2,DifferentList[i],exists2);

      _DiffTagGetTagName(key1,DifferentList[i],name1);
      _DiffTagGetTagName(key1,DifferentList[i],name2);

      if (exists1>-1 && exists2>-1 ) {
         _str cur_name=DifferentList[i];
         _DiffTagGetLineInfo(key1,cur_name,startline1,endline1);
         _DiffTagGetLineInfo(key2,cur_name,startline2,endline2);
         r1=startline1'-'endline1;
         r2=startline2'-'endline2;
         status=Diff(WID1,
                     WID2,
                     DIFF_OUTPUT_BOOLEAN|DIFF_NO_BUFFER_SETUP,
                     0,0,0,def_load_options,0,junk,800,
                     r1,r2,
                     0/*def_smart_diff_limit*/,null);
         if (!status) {
            OneTable:[DifferentList[i]]='Moved';
         }
      }
   }
   _str OneList[]=null;
   for (i._makeempty();;) {
      OneTable._nextel(i);
      if (i._isempty()) break;
      if ( OneTable:[i]==null ) continue;
      OneList[OneList._length()]=i;
   }
   OneList._sort('i');

   // Have to quit the views this way because the buffer may need to stay
   // in memory, but not be in an editor- so _delete_temp_view will close it
   // anyway.
   boolean NeedToSetCur=false;


   int diff_tags_callback_index=find_index("_diff_tags_callback1",PROC_TYPE);
   int SibDepth=0;
   if (parentIndex>-1) {
      SibDepth=GetCurIndexSiblingDepth();
      int Tree1CurIndex=_TreeCurIndex();
      if (Tree1CurIndex!=_TreeCurIndex()) {
         NeedToSetCur=true;
      }
   }
   int tagstate=-1;
   int state=0;
   treeFlags := DIFF_VIEW_DIFFERENT_SYMBOLS|
      DIFF_VIEW_MATCHING_SYMBOLS|
      DIFF_VIEW_MISSING_SYMBOLS1|
      DIFF_VIEW_MISSING_SYMBOLS2|
      DIFF_VIEW_MOVED_SYMBOLS;

   _str AlternateMatchName='';
   for (i=0;i<OneList._length();++i) {
      int bm1,bm2;
      _str cur=OneList[i];
      _str type=OneTable:[cur];
      parse type with type (_chr(1)) .;
      if (type=='+') {
         bm1=_pic_symbolm;
         bm2=_pic_symbolp;
         state=DIFF_TAG_STATUS_PATH2;
      }else if (type=='-') {
         bm1=_pic_symbolp;
         bm2=_pic_symbolm;
         state=DIFF_TAG_STATUS_PATH1;
      }else if (type=="\t") {
         continue;
//         bm1=_pic_symbol;
//         bm2=_pic_symbol;
//         state=DIFF_TAG_STATUS_MATCH;
      }else if (type=='Different') {
         bm1=_pic_symbold;
         bm2=_pic_symbold;
         state=DIFF_TAG_STATUS_DIFFERENT;
      }else if (type=='Moved') {
         bm1=_pic_symbolmoved;
         bm2=_pic_symbolmoved;
         state=DIFF_TAG_STATUS_MOVED;
      }
      int moreflags=0;
      if ((type=='Different') &&
          !(treeFlags&DIFF_VIEW_DIFFERENT_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=="\t" &&
                !(treeFlags&DIFF_VIEW_MATCHING_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=='+' &&
                !(treeFlags&DIFF_VIEW_MISSING_SYMBOLS1)) {
         moreflags=TREENODE_HIDDEN;
      }else if (type=='-' &&
                !(treeFlags&DIFF_VIEW_MISSING_SYMBOLS2)) {
         moreflags=TREENODE_HIDDEN;
      }else if ((type=='Moved') &&
                !(treeFlags&DIFF_VIEW_MOVED_SYMBOLS)) {
         moreflags=TREENODE_HIDDEN;
      }
      _str cap2=cur;
      parse OneTable:[cur] with type (_chr(1)) AlternateMatchName;
      if (AlternateMatchName!='') {
         cap2=AlternateMatchName;
         bm1=bm2=_pic_symbold;
      }
      status=_DiffTagGetLineInfo(key1,cur,startline1,endline1);
      if (!status) {
         r1=startline1','endline1;
      }else{
         r1=null;
      }
      if (cur==cap2) {
         status=_DiffTagGetLineInfo(key2,cur,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }else{
         status=_DiffTagGetLineInfo(key2,cap2,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }
      int newindex=-1;
      if (parentIndex>-1) {
         _TreeGetInfo(TREE_ROOT_INDEX,state);
         newindex=_TreeAddItem(parentIndex,
                               cur,
                               TREE_ADD_AS_CHILD,
                               bm1,bm1,-1,moreflags,r1);
      }
      if (diff_tags_callback_index) {
         call_index(cur,state,diff_tags_callback_index);
      }
   }
   if (NeedToSetCur && parentIndex>-1) {
      SetCurIndexSiblingDepth(SibDepth);
   }
   if (parentIndex>-1) {
      _TreeRefresh();
   }

   mou_hour_glass(0);
   return(0);
}
#endif

// Very specific to _svc_history_form
int _DiffExpandTagsForSVCHistoryHTML(int WID1,int WID2,int parentIndex,_str filename,
                                     _str ver1,_str ver2)
{
   int orig_view_id=p_window_id;
   boolean TryToResolveDifferentSignatures=true;
   mou_hour_glass(1);
   int status=BuildTagTableFromWID(WID1,ver1,filename);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }

   status=BuildTagTableFromWID(WID2,ver2,filename);
   if (status) {
      mou_hour_glass(0);
      return(status);
   }
   if (!WID1||!WID2) {
      // This should not happen, but is just a little double check.  If one
      // of these is null, we're going to get a billion individual
      // "Invalid Argument" errors
      return(1);
   }

   typeless junk='';
   typeless r1='';
   typeless r2='';
   p_window_id=VSWID_HIDDEN;
   _safe_hidden_window();
   Diff(WID1,
        WID2
        ,DIFF_NO_BUFFER_SETUP|def_diff_options,
        0,0,0,def_load_options,0,junk,800,1,1,0,null);
   p_window_id=orig_view_id;

   _str OneTable:[]=null;
   _str key1=_DiffTagInfoGetIndex(WID1,filename' 'ver1);
   _str key2=_DiffTagInfoGetIndex(WID2,filename' 'ver2);
   BuildOneTable(key1,key2,OneTable,TryToResolveDifferentSignatures);

   int ff;
   _str name='';
   typeless DifferentList[]=null;
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(1,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key1,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   for (ff=1;;ff=0) {
      int diffnum=DiffGetNextDifference(2,ff);
      if (diffnum<0) break;
      status=_DiffTagGetTagNameFromLineNumber(key2,diffnum,name);
      if (!status) {
         if (OneTable:[name]=='') {
            OneTable:[name]='Different';
            DifferentList[DifferentList._length()]=name;
         }
      }
   }
   typeless exists1=0;
   typeless exists2=0;
   _str name1='';
   _str name2='';
   int startline1=0;
   int startline2=0;
   int endline1=0;
   int endline2=0;
   typeless i;
   _str asc1=_chr(1);
   for (i=0;i<DifferentList._length();++i) {
      _DiffTagTagExists(key1,DifferentList[i],exists1);
      _DiffTagTagExists(key2,DifferentList[i],exists2);

      _DiffTagGetTagName(key1,DifferentList[i],name1);
      _DiffTagGetTagName(key1,DifferentList[i],name2);

      if (exists1>-1 && exists2>-1 ) {
         _str cur_name=DifferentList[i];
         _DiffTagGetLineInfo(key1,cur_name,startline1,endline1);
         _DiffTagGetLineInfo(key2,cur_name,startline2,endline2);
         r1=startline1'-'endline1;
         r2=startline2'-'endline2;
         status=Diff(WID1,
                     WID2,
                     DIFF_OUTPUT_BOOLEAN|DIFF_NO_BUFFER_SETUP,
                     0,0,0,def_load_options,0,junk,800,
                     r1,r2,
                     0/*def_smart_diff_limit*/,null);
         if (!status) {
            OneTable:[DifferentList[i]]='Moved';
         }
      }
   }
   _str OneList[]=null;
   for (i._makeempty();;) {
      OneTable._nextel(i);
      if (i._isempty()) break;
      if ( OneTable:[i]==null ) continue;
      OneList[OneList._length()]=i;
   }
   OneList._sort('i');

   // Have to quit the views this way because the buffer may need to stay
   // in memory, but not be in an editor- so _delete_temp_view will close it
   // anyway.
   boolean NeedToSetCur=false;


   int diff_tags_callback_index=find_index("_diff_tags_callback1",PROC_TYPE);
   int tagstate=-1;
   int state=0;
   treeFlags := DIFF_VIEW_DIFFERENT_SYMBOLS|
      DIFF_VIEW_MATCHING_SYMBOLS|
      DIFF_VIEW_MISSING_SYMBOLS1|
      DIFF_VIEW_MISSING_SYMBOLS2|
      DIFF_VIEW_MOVED_SYMBOLS;

   _str AlternateMatchName='';
   HISTORY_USER_INFO info = ctltree1._TreeGetUserInfo(_TreeCurIndex());
   info.lineArray._deleteel(info.lineArray._length()-1);
   len := info.lineArray._length();
   infoStr := "";
   for ( i=0;i<len;++i ) {
      infoStr = infoStr:+info.lineArray[i];
   }
   infoStr = infoStr "<br><B>Changed Symbols:</B>\n<font size=2><UL>";


   addedSymbolInfo := false;
   for (i=0;i<OneList._length();++i) {
      int bm1,bm2;
      bmname := "";
      _str cur=OneList[i];
      _str type=OneTable:[cur];
      parse type with type (_chr(1)) .;
      if (type=='+') {
         bm1=_pic_symbolm;
         bm2=_pic_symbolp;
         bmname = "<img src=vslick://_symbolp.ico>";
         state=DIFF_TAG_STATUS_PATH2;
      }else if (type=='-') {
         bm1=_pic_symbolp;
         bm2=_pic_symbolm;
         bmname = "<img src=vslick://_symbolm.ico>";
         state=DIFF_TAG_STATUS_PATH1;
      }else if (type=="\t") {
         continue;
      }else if (type=='Different') {
         bm1=_pic_symbold;
         bm2=_pic_symbold;
         bmname = "<img src=vslick://_symbold.ico>";
         state=DIFF_TAG_STATUS_DIFFERENT;
      }else if (type=='Moved') {
         bm1=_pic_symbolmoved;
         bm2=_pic_symbolmoved;
         bmname = "<img src=vslick://_diffmoved.ico>";
         state=DIFF_TAG_STATUS_MOVED;
      }
      int moreflags=0;
      _str cap2=cur;
      parse OneTable:[cur] with type (_chr(1)) AlternateMatchName;
      if (AlternateMatchName!='') {
         cap2=AlternateMatchName;
         bm1=bm2=_pic_symbold;
      }
      status=_DiffTagGetLineInfo(key1,cur,startline1,endline1);
      if (!status) {
         r1=startline1','endline1;
      }else{
         r1=null;
      }
      if (cur==cap2) {
         status=_DiffTagGetLineInfo(key2,cur,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }else{
         status=_DiffTagGetLineInfo(key2,cap2,startline2,endline2);
         if (!status) {
            r2=startline2','endline2;
         }else{
            r2=null;
         }
      }
      int newindex=-1;
      if ( type=='Different' ) {
         infoStr = infoStr"<A href='diff("WID1","WID2","r1","r2")'><LI>":+bmname:+'(modified) 'cur"</LI></A><BR>";
         addedSymbolInfo = true;
      } else if ( type=='+' ) {
         infoStr = infoStr"<A href='view("WID2","r2",added)'><LI>":+bmname:+'(added) 'cur"</LI></A><BR>";
         addedSymbolInfo = true;
      } else if ( type=='-' ) {
         infoStr = infoStr"<A href='view("WID1","r1",removed)'><LI>":+bmname:+'(removed) 'cur"</LI></A><BR>";
         addedSymbolInfo = true;
      }
      if (diff_tags_callback_index) {
         call_index(cur,state,diff_tags_callback_index);
      }
   }
   if ( !addedSymbolInfo ) {
      infoStr = infoStr"No symbol changes detected";
   }
   _control ctlminihtml2;
   infoStr = infoStr"</font></ul>";
   _TextBrowserSetHtml(ctlminihtml2,infoStr);

   index := ctltree1._TreeCurIndex();
   index=_svcGetVersionIndex(index,true);
   info.lineArray = null;
   info.lineArray[0] = infoStr;
   ctltree1._TreeSetUserInfo(index,info);

   mou_hour_glass(0);
   return(0);
}

static int GetCurIndexSiblingDepth()
{
   int CurIndex=_TreeCurIndex();

   int SibDepth=0;

   for (;CurIndex>=0;++SibDepth) {
      CurIndex=_TreeGetPrevSiblingIndex(CurIndex);
   }
   return(SibDepth);
}

static void SetCurIndexSiblingDepth(int SibDepth)
{
   int ChildIndex=_TreeGetFirstChildIndex(_TreeCurIndex());
   int LastIndex=-1;

   int i;
   for (i=1;i<=SibDepth;++i) {
      if (ChildIndex<0) break;

      LastIndex=ChildIndex;
      ChildIndex=_TreeGetNextSiblingIndex(ChildIndex);
   }
   if (LastIndex>=0) {
      _TreeSetCurIndex(LastIndex);
      if (_TreeCurIndex()!=LastIndex) {
         _TreeUp();
      }
   }
   _TreeDeselectAll();
   _TreeSelectLine(_TreeCurIndex());
}

static void DiffTagsDeleteTempView(int viewid,_str load_options)
{
   if (!pos(' 'load_options' ',' +b ') &&
       !pos(' 'load_options' ',' +bi ')) {
      _delete_temp_view(viewid);
   }else{
      int orig_view_id=p_window_id;
      p_window_id=viewid;
      _delete_window();
      p_window_id=orig_view_id;
   }
}

#define DIFF_TAG_PATH1_SYMBOL          0x1
#define DIFF_TAG_PATH2_SYMBOL          0x2
#define DIFF_TAG_DIFFERENT_SYMBOL      0x4
#define DIFF_TAG_MOVED_MATCHING_SYMBOL 0x8
#define DIFF_TAG_MATCHING_SYMBOL       0x10

int _DiffExpandTaggingInformation(int TreeIndex1,int TreeIndex2,
                                  DIFF_TAG_CALLBACK_INFO *pAlternateInfo=null,
                                  boolean TryToResolveDifferentSignatures=true)
{
   mou_hour_glass(1);
   _str cap1=tree1._TreeGetCaption(TreeIndex1);
   _str cap2=tree2._TreeGetCaption(TreeIndex2);

   _str filename1=tree1._TreeGetCaption(tree1._TreeGetParentIndex(TreeIndex1)):+cap1;
   _str filename2=tree2._TreeGetCaption(tree2._TreeGetParentIndex(TreeIndex2)):+cap2;

   int status=_DiffExpandTags2(filename1,filename2,TreeIndex1,TreeIndex2,'','',pAlternateInfo,TryToResolveDifferentSignatures);

   mou_hour_glass(0);
   return(status);
}

static int DiffGetFileIndex(int index)
{
   if (_IsFunctionIndex(index)) {
      index=_TreeGetParentIndex(index);
   }else{
      int state=0;
      int bm1=0;
      _TreeGetInfo(index,state,bm1);
      if (bm1==_pic_symbold ||
          bm1==_pic_symbold2) {
      }else if (index==_pic_fldopen) {
         _message_box("Cannot write list for a folder, please select a file");
         return(-1);
      }
   }
   return(index);
}

static int WriteListCallback(_str FuncName1,_str FuncName2,
                             int bmindex1,int bmindex2,
                             DIFF_TAG_LIST_INFO *pListInfo,int OpenClose=0)
{
   static int OutputViewId;
   typeless status=0;
   if (OpenClose==1) {
      int orig_view_id=_create_temp_view(OutputViewId);
      p_DocumentName='Diff Write Function List Temp Buffer';
      p_window_id=orig_view_id;
      return(0);
   }else if (OpenClose==-1) {
      int orig_view_id=p_window_id;
      p_window_id=OutputViewId;
      status=_save_file('+o 'pListInfo->Filename);
      p_window_id=orig_view_id;
      _delete_temp_view(OutputViewId);
      return(status);
   }

   _str ch='';
   if (bmindex1==_pic_symbol) {
      ch='M';
   }else if (bmindex1==_pic_symbolp) {
      ch='-';
   }else if (bmindex1==_pic_symbolm) {
      ch='+';
   }else if (bmindex1==_pic_symbold ||
             bmindex1==_pic_symbold2) {
      ch='D';
   }else if (bmindex1==_pic_symbolmoved) {
      ch='Moved';
   }
   typeless type='';
   int orig_view_id=p_window_id;
   p_window_id=OutputViewId;
   int lp=lastpos(' ',FuncName1);
   if (lp) {
      parse FuncName1 with FuncName1 (_chr(1)) type;
      type=substr(FuncName1,lp+1);
      FuncName1=substr(FuncName1,1,lp-1);
   }
   if (ch=='M' && pListInfo->Flags&DIFF_TAG_MATCHING_SYMBOL) {
      insert_line(ch"\t"FuncName1"\t"type);
   }else if (ch=='+' && pListInfo->Flags&DIFF_TAG_PATH2_SYMBOL) {
      insert_line(ch"\t"FuncName1"\t"type);
   }else if (ch=='-' && pListInfo->Flags&DIFF_TAG_PATH1_SYMBOL) {
      insert_line(ch"\t"FuncName1"\t"type);
   }else if (ch=='D' && pListInfo->Flags&DIFF_TAG_DIFFERENT_SYMBOL) {
      insert_line(ch"\t"FuncName1"\t"type);
   }else if (ch=='Moved' && pListInfo->Flags&DIFF_TAG_MOVED_MATCHING_SYMBOL) {
      insert_line(ch"\t"FuncName1"\t"type);
   }
   p_window_id=orig_view_id;
   return(0);
}

_command void diff_list_tag_info()
{
   if ( (p_name!='tree1' && p_name!='tree2') ||
         p_parent.p_name!='_difftree_output_form' ) {
      return;
   }

   int index1=tree1._TreeCurIndex();
   index1=DiffGetFileIndex(index1);
   if (index1<0) return;

   int index2=tree2._TreeCurIndex();
   index2=DiffGetFileIndex(index2);
   if (index2<0) return;

   _str Captions[];
   Captions[Captions._length()]='List symbols only in path &1';
   Captions[Captions._length()]='List symbols only in path &2';
   Captions[Captions._length()]='List &different symbols';
   Captions[Captions._length()]='List matching symbols that moved';
   Captions[Captions._length()]='List &matching symbols';
   static int giCheckBoxFlags;
   int flags=CheckBoxes("Tags to list",Captions,giCheckBoxFlags);
   if (!flags) {
      return;
   }
   giCheckBoxFlags=flags;
   typeless result=_OpenDialog('-modal',
                      'Save symbol list', // Dialog Box Title
                      '',                   // Initial Wild Cards
                      'Text Files (*.txt)',       // File Type List
                      OFN_SAVEAS,        // Flags
                      DIFF_STATEFILE_EXT
                      );
   if (result=='') return;
   _str OutputFilename=result;

   DIFF_TAG_CALLBACK_INFO AlternateInfo;
   DIFF_TAG_LIST_INFO ListInfo;

   ListInfo.Filename=OutputFilename;
   ListInfo.Flags=giCheckBoxFlags;

   AlternateInfo.CallbackData=ListInfo;
   AlternateInfo.pfnAlternate=WriteListCallback;

   _DiffExpandTaggingInformation(index1,index2,&AlternateInfo,false);
}

static _str GetCurFilenameFromTree(int index)
{
   if (_IsFunctionIndex(index)) {
      index=_TreeGetParentIndex(index);
   }
   int pindex=_TreeGetParentIndex(index);
   return(_TreeGetCaption(pindex):+_TreeGetCaption(index));
}
