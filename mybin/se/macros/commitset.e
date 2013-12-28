////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48969 $
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
#include "subversion.sh"
#include "cvs.sh"
#include "xml.sh"
#import "cvs.e"
#import "cvsutil.e"
#import "diff.e"
#import "fileman.e"
#import "guiopen.e"
#import "main.e"
#import "mprompt.e"
#import "put.e"
#import "savecfg.e"
#import "sellist.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "svc.e"
#import "treeview.e"
#import "vc.e"
#endregion

static void LoadCSTreeCallback(int xml_handle,int xml_index,int tree_index);

defeventtab _cvs_commit_sets_form;

#define CUR_SET_INDEX_INDEX   0
#define PAST_SET_INDEX_INDEX  1
#define LAST_FILE_INDEX_INDEX 2
#define MODIFIED_FILES_INDEX  3
#define MISC_TABLE_INDEX      4

void ctlok.on_create()
{
   int wid=p_window_id;
   _nocheck _control ctltree1;
   p_window_id=ctltree1;
   int cur_set_index=_TreeAddItem(TREE_ROOT_INDEX,"Current commit sets",TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
   int past_set_index=_TreeAddItem(TREE_ROOT_INDEX,"Past commit sets",TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1);
   _SetDialogInfo(CUR_SET_INDEX_INDEX,cur_set_index);
   _SetDialogInfo(PAST_SET_INDEX_INDEX,past_set_index);
   CSEnableButtons(_TreeCurIndex());

   _str filename=GetCSFilename();

   int status;
   int xml_handle=_xmlcfg_open(filename,status);
   if ( xml_handle>-1 ) {
      int xml_index=_xmlcfg_find_simple(xml_handle,stranslate(_TreeGetCaption(cur_set_index),'',' '));
      if ( xml_index>-1 ) {
         _TreeLoadDataXML(xml_handle,xml_index,cur_set_index,LoadCSTreeCallback);
      }
      xml_index=_xmlcfg_find_simple(xml_handle,stranslate(_TreeGetCaption(past_set_index),'',' '));
      if ( xml_index>-1 ) {
         _TreeLoadDataXML(xml_handle,xml_index,past_set_index,LoadCSTreeCallback);
      }
   }
   ctltree1.SetCSTreeBitmaps(cur_set_index);

   p_active_form.p_caption=_GetVCSystemName():+" Commit Sets";

   p_window_id=wid;
}

/**
 * Callback for _TreeLoadDataXML (adding items in the commitset .xml file to the tree)
 * @param xml_handle Handle of the xml file from _xmlcfg_open
 * @param xml_index Node index for this xml node
 * @param tree_index Node index for this tree node
 */
static void LoadCSTreeCallback(int xml_handle,int xml_index,int tree_index)
{
   int xml_cindex=_xmlcfg_find_child_with_name(xml_handle,xml_index,"CSData");
   if ( xml_cindex<0 ) {
      return;
   }
   _str set_name=GetCommitSetNameFromDialog(tree_index);

   CVS_COMMIT_SET info=null;
   typeless xml_file_indexes[]=null;
   _xmlcfg_find_simple_array(xml_handle,"Files/File",xml_file_indexes,xml_cindex);
   int len=xml_file_indexes._length();
   int i;
   for ( i=0;i<len;++i ) {
      info.Files[i]=_xmlcfg_get_attribute(xml_handle,xml_file_indexes[i],"N");
   }

   int xml_tag_index=_xmlcfg_find_simple(xml_handle,"Tag",xml_cindex);
   if ( xml_tag_index>0 ) {
      info.Tag=_xmlcfg_get_attribute(xml_handle,xml_tag_index,"Name");
   }
   typeless xml_comment_indexes[]=null;
   _xmlcfg_find_simple_array(xml_handle,"Comment",xml_comment_indexes,xml_cindex);
   len=xml_comment_indexes._length();
   for ( i=0;i<len;++i ) {
      _str cur_comment_name=_xmlcfg_get_attribute(xml_handle,xml_comment_indexes[i],"Name");
      _str (*parray)[]=null;
      if ( cur_comment_name=='All' ) {
         parray=&(info.CommentAll);
      } else {
         parray=&(info.CommentFiles:[cur_comment_name]);
      }
      typeless xml_comment_line_indexes[]=null;
      _xmlcfg_find_simple_array(xml_handle,"CommentLine",xml_comment_line_indexes,xml_comment_indexes[i]);
      int jlen=xml_comment_line_indexes._length();
      int j;
      for ( j=0;j<jlen;++j ) {
         parray->[j]=_xmlcfg_get_attribute(xml_handle,xml_comment_line_indexes[j],"Value");
      }
   }
   typeless xml_time_indexes[]=null;
   _xmlcfg_find_simple_array(xml_handle,"CommittedTimes/Time",xml_time_indexes,xml_cindex);
   len=xml_time_indexes._length();
   for ( i=0;i<len;++i ) {
      info.TimesCommittedList[i]=_xmlcfg_get_attribute(xml_handle,xml_time_indexes[i],"Value");
   }
   SetDialogInfoHash(set_name,info);
}

/**
 * Like _SetDialogInfo, but takes an arbitrary name (used for commit set names)
 * 
 * @param name Name to store data under
 * @param data data to store
 */
static void SetDialogInfoHash(_str name,typeless data)
{
   typeless AllData=ctlok.p_user;
   AllData:[name]=data;
   ctlok.p_user=AllData;
}

/**
 * Like _SetDialogInfo, but takes an arbitrary name (used for commit set names)
 * 
 * @param name Name to get stored data for
 * 
 * @return typeless
 */
static typeless GetDialogInfoHash(_str name)
{
   typeless AllData=ctlok.p_user;
   return(AllData:[name]);
}

int _OnUpdate_commit_set_add(CMDUI &cmdui,int target_wid,_str command)
{
   _str xml_filename=GetCSFilename();
   if ( !file_exists(xml_filename) ) {
      return(MF_GRAYED);
   }
   return(0);
}

/**
 * Adds <b>filename</b> to the current default commit set
 * @param filename file to add to the current commit set.  If this is 
 *        '', uses the current buffer.  If there is no window open, it will 
 *        display an open file dialog
 * 
 * @return int 0 if successful
 */
_command int commit_set_add,cvs_add_to_current_commit_set(_str filename='') name_info(FILE_ARG'*,')
{
   int ncw=_no_child_windows();
   if ( ncw && (filename=='' || filename=='.process') ) {
      _str result=_OpenDialog('-modal',
                              'Select file to add to commit set',// Dialog Box Title
                              '',                   // Initial Wild Cards
                              def_file_types,       // File Type List
                              OFN_FILEMUSTEXIST,
                              '',
                              ''
                             );
      if ( result=='' ) return(COMMAND_CANCELLED_RC);
      filename=result;
   } else if ( filename=='' ) {
      filename=p_buf_name;
      if (filename=='') {
         // We already know p_buf_name is blank, if p_DocumentName is not, we
         // can base an error message on that.
         _str docname=p_DocumentName;
         _str msg='';
         if (docname=='') {
            msg=nls("Cannot add this buffer to the current commit set because it does not have a name");
         }else{
            msg=nls(msg"Cannot add this buffer to the current commit set because it does not exist on disk");
         }
         _message_box(msg);
         return(1);
      }
   }
   _str xml_filename=GetCSFilename();
   int status;
   int xml_handle=_xmlcfg_open(xml_filename,status);
   if ( xml_handle<0 ) {
      _message_box(nls("Could not open file '%s'.  You may not have any commit sets.",xml_filename));
      return(FILE_NOT_FOUND_RC);
   }

   // Can't completely use xpath, because we have to check flags&TREENODE_BOLD,
   // not flags==TREENODE_BOLD
   typeless indexes[]=null;
   _xmlcfg_find_simple_array(xml_handle,'//TreeNode',indexes);
   int len=indexes._length();
   boolean found=false;
   int i;
   for ( i=0;i<len;++i ) {
      int curflags=_xmlcfg_get_attribute(xml_handle,indexes[i],"Flags",0);
      if ( curflags&TREENODE_BOLD ) {
         found=true;break;
      }
   }
   if ( !found ) {
      _message_box(nls("You do not have a current commit set."));
      cvs_commit_sets();
      return(1);
   }
   int commitset_index=indexes[i];
   int csdata_index=_xmlcfg_find_simple(xml_handle,"CSData",commitset_index);
   if ( csdata_index<0 ) {
      csdata_index=_xmlcfg_add(xml_handle,commitset_index,"CSData",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      if ( csdata_index<0 ) {
         return(1);
      }
   }
   int files_index=_xmlcfg_find_simple(xml_handle,"Files",csdata_index);

   if ( files_index<0 ) {
      files_index=_xmlcfg_add(xml_handle,csdata_index,"Files",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      if ( files_index<0 ) {
         return(1);
      }
   }
   commitset_index=files_index;
   int existing_index=_xmlcfg_find_simple(xml_handle,"File/@N[file-eq(.,'"filename"')]",files_index);
   if ( existing_index>-1 ) {
      _xmlcfg_close(xml_handle);
      message(nls("File %s already in current commit set",filename));
      return(0);
   }

   int new_index=_xmlcfg_add(xml_handle,commitset_index,"File",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(xml_handle,new_index,"N",filename);
   _xmlcfg_sort_on_attribute(xml_handle,commitset_index,"N",'F'_fpos_case);

   status=_xmlcfg_save(xml_handle,-1,VSXMLCFG_SAVE_ALL_ON_ONE_LINE);

   if ( status ) {
      _message_box(nls("Could not save file '%s'.\n\n%s",xml_filename,get_message(status)));
   }

   _xmlcfg_close(xml_handle);

   return(status);
}


/**
 * Shows the commit set dialog
 */
_command void commit_sets,cvs_commit_sets()
{
   show('-modal _cvs_commit_sets_form');
}


/**
 * Setup the bitmap for each commit set according to whether or not there are
 * any files in it
 * @param parent_index index to check children under
 */
static void SetCSTreeBitmaps(int parent_index)
{
   int cindex=_TreeGetFirstChildIndex(parent_index);
   for ( ;cindex>0; ) {
      _str cur_name=_TreeGetCaption(cindex);
      int state,bm1,bm2;
      _TreeGetInfo(cindex,state,bm1,bm2);
      if ( GetDialogInfoHash(GetCommitSetNameFromDialog(cindex))==null ) {
         _TreeSetInfo(cindex,state,_pic_filed,_pic_filed);
      } else {
         _TreeSetInfo(cindex,state,_pic_file,_pic_file);
      }
      cindex=_TreeGetNextSiblingIndex(cindex);
   }
}

/**
 * Callback func passed to _TreeSaveDataXML
 * @param xml_handle Handle to the XML file
 * @param xml_index Current node index in xml file
 * @param tree_index Current node index in tree
 */
void SaveCSTreeCallback(int xml_handle,int xml_index,int tree_index)
{
   CVS_COMMIT_SET info=GetDialogInfoHash(GetCommitSetNameFromDialog(tree_index));
   if ( info==null ) {
      return;
   }

   if ( xml_handle<0 || xml_index<0 || tree_index<0 ) {
      return;
   }
   int new_xml_node=_xmlcfg_add(xml_handle,xml_index,"CSData",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   int xml_files_index=_xmlcfg_add(xml_handle,new_xml_node,"Files",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

   int len=info.Files._length();
   int i;
   for ( i=0;i<len;++i ) {
      int cur_file_index=_xmlcfg_add(xml_handle,xml_files_index,"File",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(xml_handle,cur_file_index,"N",info.Files[i]);
   }
   WriteComment(xml_handle,new_xml_node,'All',info.CommentAll);
   typeless j;
   for ( j._makeempty();; ) {
      info.CommentFiles._nextel(j);
      if ( j==null ) break;
      WriteComment(xml_handle,new_xml_node,j,info.CommentFiles:[j]);
   }
   int xml_tag_index=_xmlcfg_add(xml_handle,new_xml_node,"Tag",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_add_attribute(xml_handle,xml_tag_index,"Name",info.Tag);
   WriteArray(xml_handle,new_xml_node,'',info.TimesCommittedList,"CommittedTimes","","Time","Value");
}

static void WriteArray(int xml_handle,int xml_parent_index,_str name_attr,_str (&array)[],
                       _str ParentElName,_str ParentAttrName,
                       _str ChildElName,_str ChildAttrName)
{
   int xml_comment_index=_xmlcfg_add(xml_handle,xml_parent_index,ParentElName,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   if ( ParentAttrName!='' ) {
      _xmlcfg_add_attribute(xml_handle,xml_comment_index,ParentAttrName,name_attr);
   }

   int len=array._length(),i;
   for ( i=0;i<len;++i ) {
      int cur_line_index=_xmlcfg_add(xml_handle,xml_comment_index,ChildElName,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_add_attribute(xml_handle,cur_line_index,ChildAttrName,array[i]);
   }
}

static void WriteComment(int xml_handle,int xml_parent_index,_str name_attr,_str (&comment)[])
{
   WriteArray(xml_handle,xml_parent_index,name_attr,comment,"Comment","Name","CommentLine","Value");
}

/**
 * Save the commit sets from the dialog
 */
static void SaveCommitSets()
{
   _str filename=GetCSFilename();

   int status;
   int xml_handle=_xmlcfg_open(filename,status);
   if ( xml_handle<0 && status ) {
      // If we could not open the file, create it
      xml_handle=_xmlcfg_create(filename,VSENCODING_UTF8);
      if ( xml_handle<0 ) {
         _message_box(nls("Cannot open '%s' to save commit sets",filename));
         return;
      }
   }
   int cur_set_index=_GetDialogInfo(CUR_SET_INDEX_INDEX);
   SaveCommitSet2(cur_set_index,xml_handle);
   int past_set_index=_GetDialogInfo(PAST_SET_INDEX_INDEX);
   SaveCommitSet2(past_set_index,xml_handle);
   _xmlcfg_close(xml_handle);
}

/**
 * Save a folder from the dialog into the xml file
 * 
 * @param tree_parent_index Folder index on tree to start saving from
 * @param xml_handle Handle of xml file to save into
 * 
 * @return int 0 if successful
 */
static int SaveCommitSet2(int tree_parent_index,int xml_handle)
{
   _str cap=stranslate(ctltree1._TreeGetCaption(tree_parent_index),'',' ');

   int xml_index=_xmlcfg_find_simple(xml_handle,cap);
   if ( xml_index<0 ) {
      // If this did not exist previously, create it
      xml_index=_xmlcfg_add(xml_handle,TREE_ROOT_INDEX,cap,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
      if ( xml_index<0 ) {
         _message_box(nls("Cannot create xml node to save data"));
         return(1);
      }
   } else {
      _xmlcfg_delete(xml_handle,xml_index,true);
   }
   ctltree1._TreeSaveDataXML(xml_handle,tree_parent_index,xml_index,SaveCSTreeCallback);
   return(0);
}

void ctlok.lbutton_up()
{
   SaveCommitSets();
   p_active_form._delete_window(0);
}

void ctlcancel.lbutton_up()
{
   boolean cancel=false;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for ( ;index>-1; ) {
      if ( _TreeGetUserInfo(index)==1 ) {
         int result=prompt_for_save(nls("At least one commit set has been changed.\n\nSave changes?"));
         if ( result==IDCANCEL ) {
            cancel=true;break;
         } else if ( result==IDYES ) {
            SaveCommitSets();break;
         }
      }
      index=_TreeGetNextIndex(index);
   }
   p_window_id=wid;
   if ( cancel ) {
      return;
   }
   p_active_form._delete_window();
}

void ctltree1.on_change(int reason, int index)
{
   if ( reason==CHANGE_SELECTED ) {
      CSEnableButtons(index);
   }
}

/**
 * Get the filename of the commit set filename for this system
 * 
 * @return _str commit set filename for this system
 */
static _str GetCSFilename()
{
   _str vcs=lowcase(_GetVCSystemName());
   switch ( vcs ) {
   case 'subversion':
      return(_ConfigPath():+'svncommitsets.xml');
   default:
      return(_ConfigPath():+'commitsets.xml');
   }
}

/**
 * Enables/disables buttons based on <b>index</b> in the tree control
 * @param index current node in the tree
 */
static void CSEnableButtons(int index)
{
   int cur_set_index=_GetDialogInfo(CUR_SET_INDEX_INDEX);
   int past_set_index=_GetDialogInfo(PAST_SET_INDEX_INDEX);
   if ( index==cur_set_index ||
        _TreeGetParentIndex(index)==cur_set_index ) {
      ctladd.p_enabled=1;
   } else {
      ctladd.p_enabled=0;
   }
   int state,bm1,bm2;
   _TreeGetInfo(index,state,bm1,bm2);
   boolean val=false;
   if ( bm1!=_pic_filed ) {
      if ( bm1==_pic_file ) {
         val=true;
      } else if ( bm1==_pic_fldopen ) {
         val=false;
      }
      ctlremove.p_enabled=val;
      ctledit.p_enabled=val;
      ctlcommit.p_enabled=val;
      ctlreview.p_enabled=val;
      ctlset_default.p_enabled=val;
      ctlrename.p_enabled=val;
   } else {
      ctlremove.p_enabled=true;
      ctledit.p_enabled=true;
      ctlcommit.p_enabled=false;
      ctlreview.p_enabled=false;
      ctlset_default.p_enabled=true;
      ctlrename.p_enabled=true;
   }
}

/**
 * Returns false if <b>name</b> is a valid commit set name.  This is used as a
 * callback to _textbox_form, and these have to return 0 on success
 * @param name name of the commit set from the dialog
 * @param treewid window id of the tree control.  We have to search this to be sure
 *        that this name does not exist already
 * 
 * @return int 0 if successful
 */
int _cvs_valid_cs_name(_str name,int treewid)
{
   if ( pos('.',name) ) {
      _message_box(nls("A commit set name may not contain a '.'"));
      return(1);
   }
   // We use the 'T' option to search the whole tree because we don't want
   // the user to name a commit set the same as an old commit set name
   int index=treewid._TreeSearch(TREE_ROOT_INDEX,name,'TI');
   if ( index>-1 ) {
      _message_box(nls("A commit set named '%s' already exists",name));
      return(1);
   }
   return(0);
}

void ctladd.lbutton_up()
{
   _param1='';
   _str result = show('-modal _textbox_form',
                      'New Commit Set ', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'new_commit_set', //Retrieve Name
                      '-e _cvs_valid_cs_name:'ctltree1' New Commit Set Name:'
                     );

   if ( result=='' ) {
      return;
   }
   _str cap=strip(_param1);
   int cur_set_index=_GetDialogInfo(CUR_SET_INDEX_INDEX);
   int wid=p_window_id;
   p_window_id=ctltree1;
   int new_set_index=_TreeAddItem(cur_set_index,cap,TREE_ADD_AS_CHILD|TREE_ADD_SORTED_CI,_pic_filed,_pic_filed,-1);
   _TreeSetCurIndex(new_set_index);
   if (NoCurrentCommitSetInTree()) {
      int state,bm1,bm2,flags;
      _TreeGetInfo(new_set_index,state,bm1,bm2,flags);
      _TreeSetInfo(new_set_index,state,bm1,bm2,flags|TREENODE_BOLD);
   }
   _set_focus();
   p_window_id=wid;
}

/**
 * @return boolean Returns true if there is no current (default) commit set in the
 *         tree
 */
static boolean NoCurrentCommitSetInTree()
{
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   boolean found_bold=false;
   for (;;) {
      if (index<0) break;
      int state,bm1,bm2,flags;
      _TreeGetInfo(index,state,bm1,bm2,flags);
      if (flags&TREENODE_BOLD) {
         found_bold=true;break;
      }
      index=_TreeGetNextIndex(index);
   }
   return(!found_bold);
}

/**
 * Removes the commit set at the current tree node
 */
static void CSRemove()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   _str cap=_TreeGetCaption(index);
   int result=_message_box(nls("Remove commit set '%s'?",cap),'',MB_YESNOCANCEL);
   if ( result==IDYES ) {
      _TreeDelete(index);
   }
   p_window_id=wid;
}

void ctltree1.del()
{
   int index=_TreeCurIndex();
   int state,bm1,bm2;
   _TreeGetInfo(index,state,bm1,bm2);
   if ( bm1==_pic_file||bm1==_pic_filed ) {
      CSRemove();
   }
}

void ctlremove.lbutton_up()
{
   CSRemove();
}

/**
 * Gets a name from the current commit set
 * @param index index to get the commit name for.  If this is -1, uses current index
 * 
 * @return _str Name of the appropriate commit set
 */
static _str GetCommitSetNameFromDialog(int &index=-1)
{
   _str cap='';
   int wid=p_window_id;
   p_window_id=ctltree1;
   if ( index<0 ) {
      index=_TreeCurIndex();
   }
   int state,bm1;
   _TreeGetInfo(index,state,bm1);
   if ( bm1!=_pic_file && bm1!=_pic_filed ) {
      return('');
   }
   int parent_index=_TreeGetParentIndex(index);
   cap=_TreeGetCaption(parent_index)'.'_TreeGetCaption(index);
   p_window_id=wid;
   return(cap);
}

void ctledit.lbutton_up()
{
   _str commit_set_name=GetCommitSetNameFromDialog();
   boolean changed_commit_set=EditCommitSet(commit_set_name);
   int index=ctltree1._TreeCurIndex();
   if ( changed_commit_set ) {
      ctltree1._TreeSetUserInfo(index,1);
   }
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(commit_set_name);
   if ( cur_commit_set.Files!=null ) {
      ctltree1._TreeSetInfo(index,-1,_pic_file,_pic_file);
   }else{
      ctltree1._TreeSetInfo(index,-1,_pic_filed,_pic_filed);
   }
}

/**
 * Edits the commit set named <b>commit_set_name</B>
 * @param commit_set_name name of the commit set to edit
 * 
 * @return true if commit set changed
 */
static boolean EditCommitSet(_str commit_set_name)
{
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(commit_set_name);
   _param1=null;
   boolean changed=false;
   _str result=show('-modal _cvs_current_commit_set_form',cur_commit_set);
   if ( result!='' ) {
      CVS_COMMIT_SET new_commit_set=_param1;
      if ( new_commit_set!=null &&
           new_commit_set!=cur_commit_set ) {
         SetDialogInfoHash(commit_set_name,new_commit_set);
         changed=true;
      }
   }
   return(changed);
}

/**
 * Allows the user to review a commit set in the _cvs_commit_set_review_form dialog
 * @param cur_commit_set commit set to review
 * @param CommitSetName Name of the commit set
 * @param default_filename If not "", show this as the active node in the tree on the
 *        review dialog (probably because it is out of date)
 */
static void CVSReviewCommitSet(CVS_COMMIT_SET &cur_commit_set,_str CommitSetName,_str default_filename='')
{
   CVS_LOG_INFO cvs_file_info[]=null;
   int IndexHTab:[]=null;
   CVSGetVerboseFileInfo2(cur_commit_set.Files,cvs_file_info,IndexHTab);
   // Set this to null.  The review dialog can pass a hashtable of files back
   // in this variable.
   _param1=null;

   int formid=show('_cvs_commit_set_review_form');
   formid.CVSCommitSetFormOnCreate(cvs_file_info,cur_commit_set.Files,IndexHTab,CommitSetName,default_filename);
   _modal_wait(formid);

   int i;
   if ( _param1!=null ) {
      // A hashtable of files was passed back from the review dialog.
      _str files_table:[]=_param1;
      int del_indexes[]=null;

      int len=cur_commit_set.Files._length();
      for ( i=0;i<len;++i ) {
         _str cur=cur_commit_set.Files[i];
         if ( !files_table._indexin(_file_case(cur)) ) {
            del_indexes[del_indexes._length()]=i;
         }
      }
      for ( i=del_indexes._length()-1;i>-1;--i ) {
         cur_commit_set.Files._deleteel(del_indexes[i]);
      }
   }
}

int ctlreview.lbutton_up()
{
   int status=COMMAND_NOT_FOUND_RC;
   int index=_SVCGetProcIndex('commit_set_review_button');
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}

/**
 * Callback for the "Review" button on the commit set dialog
 * 
 * @return int
 */
int _cvs_commit_set_review_button()
{
   _str CommitSetName=GetCommitSetNameFromDialog();
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(CommitSetName);

   CVSReviewCommitSet(cur_commit_set,CommitSetName);

   SetDialogInfoHash(CommitSetName,cur_commit_set);
   return(0);
}

#define COMMITSET_GENERAL_FAILURE 1
#define COMMITSET_EDIT_FAILURE    2
#define COMMITSET_NO_FILES_MODIFIED 3

int ctlcommit.lbutton_up()
{
   int status=COMMAND_NOT_FOUND_RC;
   int index=_SVCGetProcIndex('commit_set_commit_button');
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);

}


/**
 * Callback for the "Commit" button on the commit set dialog
 * 
 * @return int
 */
int _cvs_commit_set_commit_button()
{
   int commit_set_tree_index=-1;
   _str CommitSetName=GetCommitSetNameFromDialog(commit_set_tree_index);
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(CommitSetName);
   if ( cur_commit_set==null ||
        cur_commit_set.Files==null ) {
      // This should not happen, buttons should be disabled
      return(1);
   }

   int status=_SVCListModified(cur_commit_set.Files);
   if (status) {
      return(1);
   }

   int IndexHTab:[]=null;
   CVS_LOG_INFO cvs_file_info[]=null;
   CVSGetVerboseFileInfo2(cur_commit_set.Files,cvs_file_info,IndexHTab);
   status=CVSCommitSetFailsChecks(CommitSetName,cvs_file_info,cur_commit_set);
   if ( status==COMMITSET_GENERAL_FAILURE ) {
      return(1);;
   } else if ( status==COMMITSET_NO_FILES_MODIFIED ) {
      _message_box(nls("No modifications have been detected by %s",_GetVCSystemName()));
      return(1);
   } else if ( status==COMMITSET_EDIT_FAILURE ) {
      EditCommitSet(CommitSetName);
      return(0);
   }else if (status) {
      return(0);
   }
   status=CommitCommitSet(cur_commit_set);
   if ( !status ) {
      ctltree1._TreeSetInfo(commit_set_tree_index,1);
      MoveToPastCommitSets(CommitSetName,cur_commit_set,commit_set_tree_index);
   }
   return(0);
}

void ctlset_default.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   int state,bm1,bm2,flags;
   _TreeGetInfo(index,state,bm1,bm2,flags);
   if ( flags&TREENODE_BOLD ) {
      // This is already current
      return;
   }
   if ( bm1==_pic_fldopen ) {
      // This is a folder.  This should never happen, but we have all of the info
      // to make this check
      return;
   }
   _TreeSetAllFlags(0,TREENODE_BOLD);
   _TreeSetInfo(index,state,bm1,bm2,flags|TREENODE_BOLD);
   p_window_id=wid;
}

/**
 * @param newName name to check for uniquness
 * @param treeWID WID of the tree control to search in
 * 
 * @return boolean 0 if <B>newName</B> is unique
 */
static boolean nameIsUnique(_str newName,int treeWID)
{
   // The tree isn't going to be that large, and the folders in it have names
   // people are not bound to use for a commit set... just search the whole tree
   // for newName
   index := treeWID._TreeSearch(TREE_ROOT_INDEX,newName,'ti');
   if ( index>-1 ) {
      _message_box(nls("A commit set named '%s' already exists",newName));
   }
   return index>-1;
}

void ctlrename.lbutton_up()
{
   // this button is not active unless we are on a commit set node
   status := textBoxDialog("Rename Commit Set",
                           0,
                           0,
                           "",
                           "",
                           "",
                           "-e ":+nameIsUnique:+':':+ctltree1:+" New name:"
                           );
   if ( status==1 ) {
      // We save the commit sets based on the tree, so we only have to set the 
      // caption
      newCommitSetCaption := _param1;
      int wid=p_window_id;
      p_window_id=ctltree1;

      // newCommitSetCaption and newCommitSetName are different.  
      // newCommitSetCaption is the caption used the the treeview, 
      // newCommitSetName is the name used in the hashtable that stores 
      // the commit sets

      index := _TreeCurIndex();
      oldCommitSetName := GetCommitSetNameFromDialog();
      _TreeSetCaption(index,newCommitSetCaption);

      parent_index := _TreeGetParentIndex(index);
      newCommitSetName := _TreeGetCaption(parent_index)'.'_TreeGetCaption(index);

      // Get the old stuff out of the hash table
      CVS_COMMIT_SET oldCommitSet=GetDialogInfoHash(oldCommitSetName);
      // Put it back in with the new name
      SetDialogInfoHash(newCommitSetName,oldCommitSet);
      // Set the values for the old name to null
      SetDialogInfoHash(oldCommitSetName,null);
      
      // Set the modify flag in the treeview
      _TreeSetUserInfo(index,1);

      p_window_id=wid;
   }
}

/**
 * Move commit set <b>CommitSetName</B> to the Past commit sets
 * @param CommitSetName name of Commmit set to move
 * @param cur_commit_set info for Commmit set to move
 * @param commit_set_tree_index tree index of commit set
 * 
 * @return int 0 if successful
 */
static int MoveToPastCommitSets(_str CommitSetName,CVS_COMMIT_SET cur_commit_set,
                                int commit_set_tree_index)
{
   int wid=p_window_id;
   p_window_id=ctltree1;

   int cur_set_index=_GetDialogInfo(CUR_SET_INDEX_INDEX);
   int past_set_index=_GetDialogInfo(PAST_SET_INDEX_INDEX);

   _str old_caption=_TreeGetCaption(commit_set_tree_index);
   int state,bm1,bm2;
   _TreeGetInfo(commit_set_tree_index,state,bm1,bm2);

   int new_index=_TreeAddItem(past_set_index,old_caption,TREE_ADD_AS_CHILD|TREE_ADD_SORTED_CI,bm1,bm2,-1);
   // Mark this item as changed so that it gets saved
   _TreeSetUserInfo(new_index,_TreeGetUserInfo(commit_set_tree_index));

   _TreeDelete(commit_set_tree_index);

   // Get the new name(whole name with parent name on it)
   _str new_commit_set_name=GetCommitSetNameFromDialog(new_index);
   // Put the new stuff in
   SetDialogInfoHash(new_commit_set_name,cur_commit_set);
   // Delete the old stuff
   if (new_commit_set_name!=CommitSetName) {
      SetDialogInfoHash(CommitSetName,null);
   }
   _TreeSetCurIndex(new_index);
   p_window_id=wid;
   return(0);
}

/**
 * Commits <b>cur_commit_set</B>
 * @param cur_commit_set Commit set to commit
 * 
 * @return int 0 if successful
 */
static int CommitCommitSet(CVS_COMMIT_SET &cur_commit_set)
{
   int status=0;

   int index=_SVCGetProcIndex('maybe_warn_multifile_comments');
   if ( index>0 ) {
      status=call_index(cur_commit_set,index);
      if (status) {
         ctledit.call_event(ctledit,LBUTTON_UP);
         return(1);
      }
   }

   _str file_list[]=cur_commit_set.Files;
   _str OutputFilename='';

   // First pull out all of the things that have their own comments
   typeless i;
   for ( i._makeempty();; ) {
      cur_commit_set.CommentFiles._nextel(i);
      if ( i==null ) break;
      _str cur_comment_filename='';
      status=BuildCommentFile(cur_commit_set.CommentAll,cur_commit_set.CommentFiles:[i],cur_comment_filename);
      if ( status ) {
         _message_box(nls("Could not save comment file for %s\n\n%s",i,get_message(status)));
         return(status);
      }
      _str temp[]=null;
      temp[0]=i;
      status=_SVCCommit(temp,cur_comment_filename,OutputFilename,true,'',true);
      if ( status ) {
         _message_box(nls("An error occured while committing %s",i));
         break;
      }
      if ( cur_commit_set.Tag!='' ) {
         temp._makeempty();
         temp[0]=i;
         if ( cur_commit_set.Tag!='' ) {
            _SVCTag(temp,OutputFilename,cur_commit_set.Tag,true,null,false);
         }
      }
      RemoveFilenameFromArray(i,file_list);
      delete_file(cur_comment_filename);
   }
   if ( status ) {
      _SVCDisplayErrorOutputFromFile(OutputFilename,status);
      return(status);
   }

   // Now put in all of the files that only have the "All files comment"
   // These are the only files left in the list
   if ( file_list._length() ) {
      _str cur_comment_filename='';
      status=BuildCommentFile(cur_commit_set.CommentAll,null,cur_comment_filename);
      if ( status ) {
         _message_box(nls("Could not save comment file for %s\n\n%s",i,get_message(status)));
         return(status);
      }
      _str list='';
      int len=file_list._length();
      for ( i=0;i<len;++i ) {
         list=list' 'maybe_quote_filename(file_list[i]);
      }
      status=_SVCCommit(file_list,cur_comment_filename,OutputFilename,true,'',true);
      if ( status ) {
         _message_box(nls("An error occured while committing these files\n\n%s",list));
      } else {
         if ( cur_commit_set.Tag!='' ) {
            _SVCTag(file_list,OutputFilename,cur_commit_set.Tag,true,null,false);
         }
      }
      delete_file(cur_comment_filename);
   }
   if ( !status ) {
      cur_commit_set.TimesCommittedList[cur_commit_set.TimesCommittedList._length()]=_time()' '_date();
   }
   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   delete_file(OutputFilename);
   return(status);
}

/**
 * Removes <b>filename</B> from <b>file_array</B>
 * @param filename filename to remove
 * @param file_array array to remove file from
 * 
 * @return true if an item is deleted
 */
static boolean RemoveFilenameFromArray(_str filename,_str (&file_array)[])
{
   int len=file_array._length(),i;
   for ( i=0;i<len;++i ) {
      if ( file_eq(filename,file_array[i]) ) {
         file_array._deleteel(i);break;
      }
   }
   return(len!=file_array._length());
}

/**
 * Builds a temp file with the comment for all files, and for the current file
 * @param all_files_comment Comment for all files
 * @param cur_file_comment Comment for one file
 * @param cur_comment_filename A temp filename is returned here
 * 
 * @return int 0 if successful
 */
static int BuildCommentFile(_str (&all_files_comment)[],_str (&cur_file_comment)[],_str &cur_comment_filename)
{
   cur_comment_filename=mktemp();
   if ( cur_comment_filename=='' ) {
      return(1);
   }
   int temp_view_id;
   int orig_view_id=_create_temp_view(temp_view_id);

   InsertArrayIntoCurView(all_files_comment);
   InsertArrayIntoCurView(cur_file_comment);

   int status=_save_config_file(cur_comment_filename);

   p_window_id=orig_view_id;
   return(status);
}

/**
 * Inserts the elements in an array into the current buffer as lines
 * @param line_array array to dump into buffer
 */
static void InsertArrayIntoCurView(_str (&line_array)[],boolean clear_first=false)
{
   if ( clear_first ) {
      delete_all();
   }
   if ( line_array._varformat()!=VF_ARRAY ) {
      return;
   }
   int len=line_array._length(),i;
   for ( i=0;i<len;++i ) {
      insert_line(line_array[i]);
   }
   top();
}

/**
 * Checks to be sure that all items in a CVS commit set:
 * <UL>
 *    <LI>Are up to date</LI>
 *    <LI>Have been added to version contro</LI>
 *    <LI>Do not contain conflict markers, or the user acknowledges that they still have conflict markers</LI>
 * </UL>
 * 
 * 
 * @param CommitSetName Name of commmit set to commit
 * @param cvs_file_info Info from _CVSGetVerboseFileInfo so we can tell that the file is up to date etc
 * @param cur_commit_set Information about the commit set that we are commiting
 * 
 * @return int 0 if successful
 */
static int CVSCommitSetFailsChecks(_str CommitSetName,CVS_LOG_INFO (&cvs_file_info)[],CVS_COMMIT_SET &cur_commit_set)
{
   if ( cvs_file_info==null ) {
      return(COMMITSET_NO_FILES_MODIFIED);
   }
   int i;
   int len=cvs_file_info._length();
   for ( i=0;i<len;++i ) {
      CVS_LOG_INFO *pcur=&(cvs_file_info[i]);
      if ( pcur->LocalVersion!=pcur->Head ) {
         int result=_message_box(nls("File '%s' is out of date\n\nReview this commit set now?",cvs_file_info[i].WorkingFile),'',MB_YESNOCANCEL);
         if ( result==IDYES ) {
            CVSReviewCommitSet(cur_commit_set,CommitSetName,cvs_file_info[i].WorkingFile);
         }
         return(COMMITSET_GENERAL_FAILURE);
      } else if ( pcur->Description=='?' ) {
         int result=_message_box(nls("The file '%s' has not been added\n\nAdd thie file to CVS now?",cvs_file_info[i].WorkingFile),'',MB_YESNOCANCEL);
         if ( result==IDYES ) {
            _str temp[]=null;
            temp[0]=pcur->WorkingFile;
            _str output_file='';
            int status=_SVCAdd(temp,output_file);
            _SVCDisplayErrorOutputFromFile(output_file,status,p_active_form);
            if ( status ) {
               return(COMMITSET_GENERAL_FAILURE);
            }
         }
         return(COMMITSET_GENERAL_FAILURE);
      }
      boolean conflict_marker=false;
      int status=FileHasConflictMarkers(pcur->WorkingFile,conflict_marker);
      if ( status && status!=FILE_NOT_FOUND_RC ) {
         _message_box(nls("Could not open file '%s' to look for conflict markers\n\n%s",pcur->WorkingFile,get_message(status)));
         return(COMMITSET_GENERAL_FAILURE);
      }
      if ( conflict_marker ) {
         _message_box(nls("The file '%s' still contains conflict markers.  Please remove them before committing.",pcur->WorkingFile));
         return(COMMITSET_GENERAL_FAILURE);
      }
   }

   boolean file_wo_comment_found=false;
   if ( cur_commit_set.CommentAll==null ||
        (cur_commit_set.CommentAll._length()==1 && cur_commit_set.CommentAll[0]=='') ) {
      // Could be individual comment for each, don't gripe at the user yet
      int count=0;
      typeless j;
      for ( j._makeempty();;++count ) {
         cur_commit_set.CommentFiles._nextel(j);
         if ( j==null ) break;
      }
      if ( count!=cur_commit_set.Files._length() ) {
         // The number of comments did not match the number of files
         int result=_message_box(nls("One or more files have no comment.\n\nCommit anyway?"),'',MB_YESNOCANCEL);
         if ( result!=IDYES ) {
            return(COMMITSET_EDIT_FAILURE);
         }
      }
   }
   return(0);
}

/**
 * Checks to be sure that all items in a SVN commit set:
 * <UL>
 *    <LI>Are up to date</LI>
 *    <LI>Have been added to version contro</LI>
 *    <LI>Do not contain conflict markers, or the user acknowledges that they still have conflict markers</LI>
 * </UL>
 * 
 * 
 * @param CommitSetName Name of commmit set to commit
 * @param svn_file_info Info from _SVNGetVerboseFileInfo so we can tell that the file is up to date etc
 * @param cur_commit_set Information about the commit set that we are commiting
 * 
 * @return int 0 if successful
 */
static int SVNCommitSetFailsChecks(_str CommitSetName,SVN_STATUS_INFO (&svn_file_info)[],CVS_COMMIT_SET &cur_commit_set)
{
   if ( svn_file_info==null ) {
      return(COMMITSET_NO_FILES_MODIFIED);
   }
   int i;
   int len=svn_file_info._length();
   int status=0;
   for ( i=0;i<len;++i ) {
      SVN_STATUS_INFO *pcur=&(svn_file_info[i]);
      if ( pcur->status_flags&SVN_STATUS_NEWER_REVISION_EXISTS ) {
         int result=_message_box(nls("File '%s' is out of date\n\nReview this commit set now?",svn_file_info[i].local_filename),'',MB_YESNOCANCEL);
         if ( result==IDYES ) {
            SVNReviewCommitSet(cur_commit_set,CommitSetName,svn_file_info[i].local_filename);
         }
         return(COMMITSET_GENERAL_FAILURE);
      } else if ( pcur->status_flags&SVN_STATUS_NOT_CONTROLED ) {
         int result=_message_box(nls("The file '%s' has not been added\n\nAdd thie file to %s now?",svn_file_info[i].local_filename,_GetVCSystemName()),'',MB_YESNOCANCEL);
         if ( result==IDYES ) {
            _str temp[]=null;
            temp[0]=pcur->local_filename;
            _str output_file='';
            status=_SVCAdd(temp,output_file);
            _SVCDisplayErrorOutputFromFile(output_file,status,p_active_form);
            if ( status ) {
               return(COMMITSET_GENERAL_FAILURE);
            }
         }
         return(COMMITSET_GENERAL_FAILURE);
      }
      boolean conflict_marker;
      if ( last_char(pcur->local_filename)!=FILESEP ) {
         status=FileHasConflictMarkers(pcur->local_filename,conflict_marker);
         if ( status && status!=FILE_NOT_FOUND_RC ) {
            _message_box(nls("Could not open file '%s' to look for conflict markers\n\n%s",pcur->local_filename,get_message(status)));
            return(COMMITSET_GENERAL_FAILURE);
         }
         if ( conflict_marker ) {
            _message_box(nls("The file '%s' still contains conflict markers.  Please remove them before committing.",pcur->local_filename));
            return(COMMITSET_GENERAL_FAILURE);
         }
      }
   }

   boolean file_wo_comment_found=false;
   if ( cur_commit_set.CommentAll==null ||
        (cur_commit_set.CommentAll._length()==1 && cur_commit_set.CommentAll[0]=='') ) {
      // Could be individual comment for each, don't gripe at the user yet
      int count=0;
      typeless j;
      for ( j._makeempty();;++count ) {
         cur_commit_set.CommentFiles._nextel(j);
         if ( j==null ) break;
      }
      if ( count!=cur_commit_set.Files._length() ) {
         // The number of comments did not match the number of files
         int result=_message_box(nls("One or more files have no comment.\n\nCommit anyway?"),'',MB_YESNOCANCEL);
         if ( result==IDNO ) {
            return(COMMITSET_EDIT_FAILURE);
         }
      }
   }
   return(0);
}

/**
 * Checks to see if file <b>filename</B> contains CVS style conflict markes
 * @param filename File to check for conflict markers
 * @param conflict_marker is set to true if a conflict marker is found
 * 
 * @return int 0 if the successful.  This applies to operating on the file, not
 *         finding conflict markers
 */
static int FileHasConflictMarkers(_str filename,boolean &conflict_marker)
{
   int temp_view_id,orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id);
   if ( status ) {
      return(status);
   }
   conflict_marker=false;
   top();up();

   status=search('^<<<<<<< ','@rh');
   if ( status ) {
      status=search('^======= ','@rh');
      if ( status ) {
         status=search('^>>>>>>> ','@rh');
      }
   }
   if ( !status ) {
      conflict_marker=true;
   }

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

defeventtab _cvs_current_commit_set_form;
void _cvs_current_commit_set_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   int first_label_wid=ctltree1.p_prev;
   int xbuffer=ctltree1.p_x;
   int ybuffer=first_label_wid.p_y;

   int control_area_x=client_width-(xbuffer*3);
   ctltree1.p_width=control_area_x intdiv 3;
   ctlcomment_all.p_width=(control_area_x intdiv 3)*2;
   ctlcomment_file.p_width=ctlcomment_all.p_width;

   ctlcomment_all.p_x=ctltree1.p_x+ctltree1.p_width+xbuffer;
   ctlcomment_all.p_prev.p_x=ctlcomment_all.p_x;

   ctlcomment_file.p_x=ctlcomment_all.p_x;
   ctlcomment_file.p_prev.p_x=ctlcomment_file.p_x;

   ctltag.p_prev.p_x=ctlcomment_file.p_x;
   ctltag.p_x=ctltag.p_prev.p_x+ctltag.p_prev.p_width;
   ctltag.p_width=ctlcomment_all.p_width-ctltag.p_prev.p_width;

   int control_area_y=client_height-(ybuffer*4);
   ctltree1.p_y=first_label_wid.p_y+first_label_wid.p_height+ybuffer;
   ctltree1.p_height=(control_area_y-ctlok.p_height)-first_label_wid.p_height;

   ctlok.p_y=ctltree1.p_y+ctltree1.p_height+ybuffer;
   ctlcancel.p_y=ctladd.p_y=ctldelete.p_y=ctldiff.p_y=ctlreview.p_y=ctlcommit_file.p_y=ctlok.p_y;

   int editor_height=ctltree1.p_height-max(ctltag.p_height,ctltag.p_prev.p_height);
   editor_height=editor_height intdiv 2;

   editor_height-=ctlcomment_file.p_prev.p_height;
   ctlcomment_all.p_height=ctlcomment_file.p_height=editor_height;

   int comment_file_label_wid=ctlcomment_file.p_prev;
   comment_file_label_wid.p_y=ctlcomment_all.p_y+ctlcomment_all.p_height+ybuffer;

   ctlcomment_file.p_y=comment_file_label_wid.p_y+comment_file_label_wid.p_height+ybuffer;
   ctltag.p_y=ctlcomment_file.p_y+ctlcomment_file.p_height+ybuffer;
   ctltag.p_prev.p_y=ctltag.p_y;
}

void ctlok.on_create(CVS_COMMIT_SET &info)
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int len=info.Files._length(),i;
   for ( i=0;i<len;++i ) {
      _str cur_filename=info.Files[i];
      cur_filename=maybe_quote_filename(cur_filename);
      AddFileToCSTree(cur_filename,info.CommentFiles:[cur_filename]);
   }
   _TreeSortCaption(TREE_ROOT_INDEX,_fpos_case);
   _TreeSizeColumnToContents(0);
   if ( info!=null ) {
      if ( info.Tag!=null ) ctltag.p_text=info.Tag;

      if ( info.CommentAll!=null ) ctlcomment_all.InsertArrayIntoCurView(info.CommentAll,true);

      int index=_TreeCurIndex();
      if ( index>-1 ) {
         ShowFileComment(index);
      }
   }
   ctlcomment_all.p_SoftWrap=1;
   ctlcomment_all.p_SoftWrapOnWord=1;
   ctlcomment_file.p_SoftWrap=1;
   ctlcomment_file.p_SoftWrapOnWord=1;
   p_window_id=wid;
}


static int AddFileToCSTree(_str filelist,_str (&comment)[]=null)
{
   int index=-1;
   for ( ;; ) {
      _str filename=parse_file(filelist);
      if ( filename=='' ) break;
      filename=strip(filename,'B','"');
      _str name=_strip_filename(filename,'P');
      index=ctltree1._TreeAddItem(TREE_ROOT_INDEX,name"\t"filename,TREE_ADD_AS_CHILD,_pic_file,_pic_file,-1);
      if ( comment!=null ) {
         _TreeSetUserInfo(index,comment);
      }
   }
   return(index);
}

void ctladd.lbutton_up()
{
   _str result=_OpenDialog('-modal',
                           'Add file to commit set',// Dialog Box Title
                           '',                   // Initial Wild Cards
                           def_file_types,       // File Type List
                           OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT);
   if ( result=='' ) {
      return;
   }
   _str filename=result;
   //_str dirlist_to_add[]=null;
   //int status=GetPathsToAdd(filename,dirlist_to_add);
   //if ( status ) {
   //   return;
   //}
   //int len=dirlist_to_add._length();
   //if ( len ) {
   //   result=_message_box(nls("One or more directories will have to be added to add this file to the commit set.  Add them now?"),'',MB_YESNOCANCEL);
   //   if ( result!=IDYES ) {
   //      return;
   //   }
   //   _str OutputFilename='';
   //   status=_SVCAdd(dirlist_to_add,OutputFilename,true);
   //   _SVCDisplayErrorOutputFromFile(OutputFilename,status);
   //}
   AddFileToCSTree(filename);
   int wid=p_window_id;
   p_window_id=ctltree1;
   _TreeSortCaption(TREE_ROOT_INDEX,_fpos_case);
   _TreeSizeColumnToContents(0);
   call_event(CHANGE_SELECTED,_TreeCurIndex(),ctltree1,ON_CHANGE,'W');
   p_window_id=wid;
}

/**
 * For a given file, gets an array full of all the parent directories that will
 * have to be added in order to add this file.
 *
 * @param filename filename that will be added
 * @param dirlist_to_add
 *                 array that gets filled in with paths
 *
 * @return 0 if succesful
 */
static int GetPathsToAdd(_str filelist,_str (&dirlist_to_add)[])
{
   for ( ;; ) {
      _str filename=parse_file(filelist);
      if ( filename=='' ) {
         break;
      }
      _str path=_file_path(filename);
      if ( isdirectory(path:+CVS_CHILD_DIR_NAME) ) {
         break;
      }
      dirlist_to_add[dirlist_to_add._length()]=path;

      path=_GetParentDirectory(path);
      boolean path_is_root;
#if __UNIX__
      path_is_root=file_eq(path,FILESEP);
#else
      path_is_root=length(path)==3 && substr(path,2,2)==':'FILESEP;
#endif
      if ( path_is_root ) {
         _message_box(nls("Files added to a commit set must come from a directory that is checked out from CVS"));
         return(1);
      }
   }
   dirlist_to_add._sort('F'_fpos_case);
   return(0);
}

void ctldiff.lbutton_up()
{
   int index=ctltree1._TreeCurIndex();
   if ( index<0 ) {
      return;
   }
   _str filename=ctltree1._TreeGetCaption(index);
   parse filename with . "\t" filename;
   svc_diff_with_tip(filename);
}

/**
 * Remove the commit set currently selected in the tree
 */
static void CurrentCSRemove()
{
   int wid=p_window_id;
   p_window_id=ctltree1;

   num := _TreeGetNumSelectedItems();
   int last_selected_file_index=_GetDialogInfo(LAST_FILE_INDEX_INDEX);
   if ( !num ) {
      int index=_TreeCurIndex();
      if ( index>0 ) {
         if ( last_selected_file_index==index ) {
            _SetDialogInfo(LAST_FILE_INDEX_INDEX,null);
         }
         _TreeDelete(index);
      }
   } else {
      int del_indexes[]=null;
      int info;
      for ( ff:=1;;ff=0 ) {
         int index=_TreeGetNextSelectedIndex(ff,info);
         if ( index<0 ) break;
         del_indexes[del_indexes._length()]=index;
      }
      int len=del_indexes._length();
      int i;
      for ( i=0;i<len;++i ) {
         if ( _GetDialogInfo(LAST_FILE_INDEX_INDEX)==del_indexes[i] ) {
            _SetDialogInfo(LAST_FILE_INDEX_INDEX,null);
         }
         _TreeDelete(del_indexes[i]);
      }
   }

   p_window_id=wid;
}

void ctldelete.lbutton_up()
{
   CurrentCSRemove();
}

void ctltree1.del()
{
   CurrentCSRemove();
}

void ctlcommit_file.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   if ( index<0 ) return;
   _str cap=_TreeGetCaption(index);
   _str filename;
   parse cap with . "\t" filename;
   p_window_id=wid;

   _str temp_file_list[]=null;
   temp_file_list[0]=filename;
   _str comment_filename=mktemp();
   p_window_id=ctlcomment_all;
   select_all();
   int put_status=put(comment_filename);
   deselect();
   p_window_id=wid;

   boolean append_file_comment=true;
   if ( ctlcomment_file.p_Noflines ) {
      if ( ctlcomment_file.p_Noflines==1 ) {
         _str line;
         ctlcomment_file.get_line(line);
         if ( line=='' ) append_file_comment=false;
      }
   }
   if ( append_file_comment ) {
      p_window_id=ctlcomment_file;
      select_all();
      append(comment_filename);
      deselect();
      p_window_id=wid;
   }
   if ( rc ) clear_message();

   if (!_SVCCheckLocalFilesForConflicts(temp_file_list)) {
      int status=_SVCListModified(temp_file_list);
      if (!status) {
         _str output_file='';
         status=_SVCCommit(temp_file_list,comment_filename,output_file,true);

         _SVCDisplayErrorOutputFromFile(output_file,status,p_active_form);
         delete_file(output_file);
      }
   }

   delete_file(comment_filename);
}

/**
 * Returns true if <b>string</B> contains non printable characters
 * @param string string to check for non printable characters
 * 
 * @return boolean true if <b>string</B> contains non printable characters 
 *  
 * @categories String_Functions
 */
static boolean HasNonPrintChars(_str string)
{
   int len=length(string);
   int i;
   for ( i=1;i<=len;++i ) {
      _str ch=substr(string,i,1);
      if ( !isprint(ch) ) {
         return(true);
      }
   }
   return(false);
}

/**
 * Checks to be sure that a whitespace delimited list of tags are valid
 * @param taglist list of tags
 * @param text_box_wid window id of textbox that has the tags list.  If this is 0
 *        this function searches for a control called "ctltag".  If that is not
 *        found it uses _message_box instead of _text_box_error
 * 
 * @return boolean
 */
boolean _CVSTagCheckFails(_str taglist,int text_box_wid=0)
{
   taglist=strip(taglist);
   if ( !text_box_wid ) {
      text_box_wid=_find_control('ctltag');
   }
   for (;;) {
      _str cur_tag=parse_file(taglist);
      if (cur_tag=='') break;
      cur_tag=strip(cur_tag,'B','"');
      while (substr(cur_tag,1,1)=='-') {
         if (cur_tag=='') break;
         _str option=parse_file(cur_tag);
      }

      cur_tag=strip(cur_tag);
      if ( cur_tag=='' ) {
         return(false);
      }
      _str ch=first_char(cur_tag);
      if ( !isalpha(ch) ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names must start with a letter",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names must start with a letter",cur_tag));
         }
         return(true);
      }
      if ( pos(' |\t',cur_tag,1,'r') ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names may not contain whitespace",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names may not contain whitespace",cur_tag));
         }
         return(true);
      }
      if ( HasNonPrintChars(cur_tag) ) {
         if ( text_box_wid ) {
            text_box_wid._text_box_error(nls("'%s' is not a valid tag name.\n\nTag names may not contain graphics characters",cur_tag));
         }else{
            _message_box(nls("'%s' is not a valid tag name.\n\nTag names may not contain graphics characters",cur_tag));
         }
         return(true);
      }
   }
   return(false);
}

void ctlok.lbutton_up()
{
   CVS_COMMIT_SET info=null;

   _str tag=ctltag.p_text;
   if ( _CVSTagCheckFails(tag) ) {
      return;
   }
   info.Tag=tag;

   int wid=p_window_id;
   p_window_id=ctltree1;

   // This makes sure that the current file comment is saved
   ShowFileComment(_TreeCurIndex());

   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   for ( ;index>-1; ) {
      _str cur_filename=_TreeGetCaption(index);
      parse cur_filename with . "\t" cur_filename;
      int len=info.Files._length();
      info.Files[len]=cur_filename;
      _str comment[]=_TreeGetUserInfo(index);
      if ( comment._varformat()==VF_ARRAY ) {
         info.CommentFiles:[cur_filename]=comment;
      }
      index=_TreeGetNextSiblingIndex(index);
   }

   // Get the "all files" comment
   ctlcomment_all.GetLineArrayFromBuffer(info.CommentAll);

   _param1=info;
   p_window_id=wid;
   p_active_form._delete_window(0);
}

/**
 * Gets each line from the buffer as an array element.  line 1 -> <b>comment[0]</b>
 * @param comment
 */
static void GetLineArrayFromBuffer(_str (&comment)[])
{
   top();up();
   while ( !down() ) {
      get_line(auto line);
      // It is ok to use p_line here because the whole file is definitely in
      // memory
      line=strip(line);
      if ( p_Noflines==1 && line=='' ) break;
      comment[p_line-1]=line;
   }
}

/**
 * Tree must be active
 * 
 * @param index  Tree index
 */
static void ShowFileComment(int index)
{
   if (index<0) return;
   _str cap=_TreeGetCaption(index),filename='';
   parse cap with . "\t" filename;
   ctlcomment_file.p_prev.p_caption='&Comment for 'filename;
   int last_selected_file_index=_GetDialogInfo(LAST_FILE_INDEX_INDEX);

   _str comment[]=null;
   if ( last_selected_file_index!=null &&
        last_selected_file_index>-1 ) {
      ctlcomment_file.GetLineArrayFromBuffer(comment);
      _TreeSetUserInfo(last_selected_file_index,comment);
   }
   comment=_TreeGetUserInfo(index);
   int wid=p_window_id;
   p_window_id=ctlcomment_file;
   InsertArrayIntoCurView(comment,true);
   if ( ctltree1._TreeGetFirstChildIndex(TREE_ROOT_INDEX)<0 ) {
      p_enabled=false;
      p_prev.p_enabled=false;
   } else {
      p_enabled=true;
      p_prev.p_enabled=true;
   }
   p_window_id=wid;
   _SetDialogInfo(LAST_FILE_INDEX_INDEX,index);
}

void ctltree1.on_change(int reason,int index)
{
   if ( reason==CHANGE_SELECTED ) {
      ShowFileComment(index);
   }
}

/**
 *
 * @param path    Path to get information for
 * @param Files   Caller should initialize this variable so that multiple
 *                calls to this function can append to the end of the
 *                array
 * @param recurse Recurse subdirectories.  Defaults to true.
 *
 * @return 0 if succesful
 */
static int CVSGetVerboseFileInfo2(_str (&filelist)[],CVS_LOG_INFO (&Files)[],
                                  int (&IndexHTab):[]=null,
                                  typeless *pfnPreShellCallback=null,
                                  typeless *pfnPostShellCallback=null,
                                  typeless *pData=null)
{
   filelist._sort('F'_fpos_case);
   int len=filelist._length();
   _str lastdir='';

   _str list='';
   _str orig_dir=getcwd();
   int i;
   for ( i=0;i<len;++i ) {
      if ( lastdir=='' ) {
         lastdir=_file_path(filelist[i]);
         list=maybe_quote_filename(_SVCRelative(filelist[i],lastdir));
      } else {
         _str curdir=_file_path(filelist[i]);
         _str cur=maybe_quote_filename(_SVCRelative(filelist[i],lastdir));
         int curlen=length(cur);
         if ( length(list)+curlen>=MAX_COMMAND_LINE_LENGTH ||
              !file_eq(lastdir,substr( curdir,1,length(lastdir))) ) {
            --i;
            _str module_name='';
            int status=_SVCGetVerboseFileInfo(list,Files,module_name,true,lastdir,false,pfnPreShellCallback,pfnPostShellCallback,pData,IndexHTab);
            if ( status ) {
               return(status);
            }
            lastdir='';
            continue;
         }
         list=list' 'cur;
      }
   }
   int status=0;
   if ( list!='' ) {
      _str module_name='';
      status=_SVCGetVerboseFileInfo(list,Files,module_name,true,lastdir,false,pfnPreShellCallback,pfnPostShellCallback,pData,IndexHTab);
   }
   chdir(orig_dir,1);
   return(status);
}

defeventtab _cvs_commit_set_review_form;

int CVSCommitSetFormOnCreate(CVS_LOG_INFO (&cvs_info)[],_str (&files)[],int (&IndexHTab):[],
                             _str CommitSetName,_str default_filename)
{
   p_active_form.p_caption=CommitSetName;
   int i;
   int len=files._length();

   int wid=p_window_id;
   p_window_id=ctltree1;
   for ( i=0;i<len;++i ) {
      int index=IndexHTab:[_file_case(files[i])];
      int newindex=-1;
      int set_default=0;
      if ( default_filename!='' && set_default>-1 && file_eq(default_filename,files[i] ) ) {
         set_default=1;
      }
      int new_index;
      if ( index!=null ) {
         int bitmap_index;
         _CVSGetFileBitmap(cvs_info[index],bitmap_index);
         if ( bitmap_index>-1 ) {
            new_index=_TreeAddItem(TREE_ROOT_INDEX,cvs_info[index].WorkingFile,TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME,bitmap_index,bitmap_index,-1);
         }
      } else {
         new_index=_TreeAddItem(TREE_ROOT_INDEX,files[i],TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME,_pic_file,_pic_file,-1);
      }
      if ( set_default==1 ) {
         if ( new_index>-1 ) {
            _TreeSetCurIndex(new_index);
            set_default=-1;
         }
      }
   }
   CSReviewEnableButtons();
   p_window_id=wid;
   return(0);
}

#define ControlExtentY(a) (a.p_y+a.p_height)
#define ControlExtentX(a) (a.p_x+a.p_width)

void _cvs_commit_set_review_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   int label_wid=ctltree1.p_prev;
   int xbuffer=label_wid.p_x;
   int ybuffer=label_wid.p_y;

   int control_area_y=(client_height-(ybuffer*4))-label_wid.p_height;
   ctltree1.p_height=control_area_y-ctlok.p_height;
   ctlok.p_y=ControlExtentY(ctltree1)+ybuffer;
   ctltree1.p_width=client_width-(2*xbuffer);
   ctlcancel.p_y=ctldiff.p_y=ctlupdate.p_y=ctlremove.p_y=ctlok.p_y;
}

void ctlok.lbutton_up()
{
   int modified_files=_GetDialogInfo(MODIFIED_FILES_INDEX);

   if ( modified_files==1 ) {
      int wid=p_window_id;
      p_window_id=ctltree1;
      _str files:[]=null;
      int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for ( ;index>-1; ) {
         _str cur=_TreeGetCaption(index);
         files:[_file_case(cur)]=cur;
         index=_TreeGetNextSiblingIndex(index);
      }
      p_window_id=wid;
      _param1=files;
   } else {
      //Be sure _param1 is set to null if no modified files.
      _param1 = null;
   }
   p_active_form._delete_window();
}

/**
 * Tree control must be active
 *
 * @param index  Tree index
 */
static void CSReviewEnableButtons(int index=-1)
{
   if ( index==-1 ) {
      index=_TreeCurIndex();
      if ( index<0 ) {
         ctldiff.p_enabled=false;
         ctlupdate.p_enabled=false;
         ctlremove.p_enabled=false;
         return;
      }
   }
   int state,bm1,bm2;
   _TreeGetInfo(index,state,bm1,bm2);
   int wid=p_window_id;
   p_window_id=ctlupdate;
   if ( bm1==_pic_file_old
        ||bm1==_pic_file_old_mod ) {
      p_enabled=true;
      p_caption=UPDATE_CAPTION_UPDATE;
      ctldiff.p_enabled=true;
   } else if ( bm1==_pic_cvs_file_qm ) {
      p_enabled=true;
      p_caption=UPDATE_CAPTION_ADD;
      ctldiff.p_enabled=false;
   } else if ( bm1==_pic_cvs_filep ) {
      p_enabled=false;
      ctldiff.p_enabled=false;
   } else if ( bm1==_pic_cvs_filem ) {
      p_enabled=false;
      ctldiff.p_enabled=false;
   } else {
      p_enabled=false;
      ctldiff.p_enabled=true;
   }
   p_window_id=wid;
}

void ctltree1.on_change(int reason,int index)
{
   if ( reason==CHANGE_SELECTED ) {
      CSReviewEnableButtons(index);
   }
}

void ctldiff.lbutton_up()
{
   int index=ctltree1._TreeCurIndex();
   if ( index<0 ) {
      return;
   }
   int wid=p_window_id;
   p_window_id=ctltree1;
   _str filename=_TreeGetCaption(index);
   svc_diff_with_tip(maybe_quote_filename(filename));

   index=_TreeGetNextIndex(index);
   if ( index>-1 ) {
      _TreeSetCurIndex(index);
   }
   p_window_id=wid;
}

int ctlupdate.lbutton_up()
{
   int status=COMMAND_NOT_FOUND_RC;
   int index=_SVCGetProcIndex('commit_set_update_button');
   if ( index>0 ) {
      status=call_index(index);
   }
   return(status);
}

int _cvs_commit_set_update_button()
{
   _str button_caption=p_caption;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   _str filename=_TreeGetCaption(index);

   _str temp[]=null;
   temp[0]=filename;
   _str output_file='';
   int status=0;
   if ( button_caption==UPDATE_CAPTION_UPDATE ) {
      status=_SVCUpdate(temp,output_file);
   } else if ( button_caption==UPDATE_CAPTION_ADD ) {
      status=_SVCAdd(temp,output_file);
   }
   _SVCDisplayErrorOutputFromFile(output_file,status);
   if ( !status ) {
      int state,bm1,bm2;
      _TreeGetInfo(index,state,bm1,bm2);
      CVS_LOG_INFO cvs_info[]=null;
      _str module_name;
      _SVCGetVerboseFileInfo(filename,cvs_info,module_name);
      int new_bitmap_index;
      if ( cvs_info._length() ) {
         _CVSGetFileBitmap(cvs_info[0],new_bitmap_index);
      } else {
         new_bitmap_index=_pic_file;
      }
      _TreeSetInfo(index,state,new_bitmap_index,new_bitmap_index);
   }
   CSReviewEnableButtons(index);

   p_window_id=wid;
   return(0);
}

int _svn_commit_set_update_button()
{
   _str button_caption=p_caption;
   int wid=p_window_id;
   p_window_id=ctltree1;
   int index=_TreeCurIndex();
   _str filename=_TreeGetCaption(index);

   _str temp[]=null;
   temp[0]=filename;
   _str output_file='';
   int status=0;
   if ( button_caption==UPDATE_CAPTION_UPDATE ) {
      status=_SVCUpdate(temp,output_file);
   } else if ( button_caption==UPDATE_CAPTION_ADD ) {
      status=_SVCAdd(temp,output_file);
   }
   _SVCDisplayErrorOutputFromFile(output_file,status);
   if ( !status ) {
      int state,bm1,bm2;
      _TreeGetInfo(index,state,bm1,bm2);
      SVN_STATUS_INFO svn_info[]=null;
      _str module_name;
      _SVCGetVerboseFileInfo(filename,svn_info,module_name);
      int new_bitmap_index;
      if ( svn_info._length() ) {
         _SVNGetFileBitmap(svn_info[0],new_bitmap_index);
      } else {
         new_bitmap_index=_pic_file;
      }
      _TreeSetInfo(index,state,new_bitmap_index,new_bitmap_index);
   }
   CSReviewEnableButtons(index);

   p_window_id=wid;
   return(0);
}

void ctltree1.del()
{
   CSReviewRemove();
}

void ctlremove.lbutton_up()
{
   CSReviewRemove();
}

static void CSReviewRemove()
{
   int wid=p_window_id;
   p_window_id=ctltree1;

   int index=_TreeCurIndex();
   _TreeDelete(index);
   _SetDialogInfo(MODIFIED_FILES_INDEX,1);

   p_window_id=wid;
}


int _svn_commit_set_review_button()
{
   _str CommitSetName=GetCommitSetNameFromDialog();
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(CommitSetName);

   SVNReviewCommitSet(cur_commit_set,CommitSetName);

   SetDialogInfoHash(CommitSetName,cur_commit_set);
   return(0);
}

int _svn_commit_set_commit_button()
{
   int commit_set_tree_index=-1;
   _str CommitSetName=GetCommitSetNameFromDialog(commit_set_tree_index);
   CVS_COMMIT_SET cur_commit_set=GetDialogInfoHash(CommitSetName);
   if ( cur_commit_set==null ||
        cur_commit_set.Files==null ) {
      // This should not happen, buttons should be disabled
      return(1);
   }

   int status=_SVCListModified(cur_commit_set.Files);
   if (status) {
      return(1);
   }

   int IndexHTab:[]=null;
   SVN_STATUS_INFO svn_file_info[]=null;
   int len=cur_commit_set.Files._length();
   int i;
   for (i=0;i<len;++i) {
      _SVNGetVerboseFileInfo(cur_commit_set.Files[i],svn_file_info,'',true,'',true,null,null,null,IndexHTab);
   }
   status=SVNCommitSetFailsChecks(CommitSetName,svn_file_info,cur_commit_set);
   if ( status==COMMITSET_GENERAL_FAILURE ) {
      return(1);
   } else if ( status==COMMITSET_NO_FILES_MODIFIED ) {
      _message_box(nls("No modifications have been detected by %s",_GetVCSystemName()));
      return(1);
   } else if ( status==COMMITSET_EDIT_FAILURE ) {
      EditCommitSet(CommitSetName);
   }
   status=CommitCommitSet(cur_commit_set);
   if ( !status ) {
      ctltree1._TreeSetInfo(commit_set_tree_index,1);
      MoveToPastCommitSets(CommitSetName,cur_commit_set,commit_set_tree_index);
   }
   return(0);
}

int _svn_maybe_warn_multifile_comments(CVS_COMMIT_SET &cur_commit_set)
{
   if ( cur_commit_set.CommentFiles!=null && lowcase(_GetVCSystemName())=="subversion" ) {
      int result=_message_box(nls("One or more files have individual file comments.\nThis will cause those items to be committed separately.\n\nCommit anyway?"),'',MB_YESNO);
      if ( result!=IDYES ) {
         return(COMMITSET_EDIT_FAILURE);
      }
   }
   return(0);
}

static void SVNReviewCommitSet(CVS_COMMIT_SET &cur_commit_set,_str CommitSetName,_str default_filename='')
{
   SVN_STATUS_INFO svn_file_info[]=null;
   int IndexHTab:[]=null;
   int len=cur_commit_set.Files._length();
   int i;
   for (i=0;i<len;++i) {
      _SVNGetVerboseFileInfo(cur_commit_set.Files[i],svn_file_info,'',true,'',false,null,null,null,IndexHTab,false);
   }
   // Set this to null.  The review dialog can pass a hashtable of files back
   // in this variable.
   _param1=null;

   int formid=show('_cvs_commit_set_review_form');
   formid.SVNCommitSetFormOnCreate(svn_file_info,cur_commit_set.Files,IndexHTab,CommitSetName,default_filename);
   _modal_wait(formid);

   if ( _param1!=null && _param1._varformat()==VF_HASHTAB) {
      // A hashtable of files was passed back from the review dialog.
      _str files_table:[]=_param1;
      int del_indexes[]=null;

      len=cur_commit_set.Files._length();
      for ( i=0;i<len;++i ) {
         _str cur=cur_commit_set.Files[i];
         if ( cur != null && !files_table._indexin(_file_case(cur)) ) {
            del_indexes[del_indexes._length()]=i;
         }
      }
      for ( i=del_indexes._length()-1;i>-1;--i ) {
         cur_commit_set.Files._deleteel(del_indexes[i]);
      }
   }
}

int SVNCommitSetFormOnCreate(SVN_STATUS_INFO (&svn_info)[],_str (&files)[],int (&IndexHTab):[],
                             _str CommitSetName,_str default_filename)
{
   p_active_form.p_caption=CommitSetName;
   int i;
   int len=files._length();

   int wid=p_window_id;
   p_window_id=ctltree1;
   for ( i=0;i<len;++i ) {
      int index=IndexHTab:[_file_case(files[i])];
      int newindex=-1;
      int set_default=0;
      if ( default_filename!='' && set_default>-1 && file_eq(default_filename,files[i] ) ) {
         set_default=1;
      }
      int new_index;
      if ( index!=null ) {
         int bitmap_index;
         _SVNGetFileBitmap(svn_info[index],bitmap_index);
         if ( bitmap_index>-1 ) {
            new_index=_TreeAddItem(TREE_ROOT_INDEX,svn_info[index].local_filename,TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME,bitmap_index,bitmap_index,-1);
         }
      } else {
         new_index=_TreeAddItem(TREE_ROOT_INDEX,files[i],TREE_ADD_AS_CHILD|TREE_ADD_SORTED_FILENAME,_pic_file,_pic_file,-1);
      }
      if ( set_default==1 ) {
         if ( new_index>-1 ) {
            _TreeSetCurIndex(new_index);
            set_default=-1;
         }
      }
   }
   CSReviewEnableButtons();
   p_window_id=wid;
   return(0);
}
