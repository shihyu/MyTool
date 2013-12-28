////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50291 $
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
#import "cvs.e"
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "project.e"
#import "rte.e"
#import "stdprocs.e"
#import "toolbar.e"
#import "treeview.e"
#import "historydiff.e"
#import "xmlwrapgui.e"
#endregion

/**
* @todo Coordinate things with the Tools->Options->File Options...->Backup tab.
*
* @todo Be able to look at backup history of a file not in the current buffer.
*
* @todo do away with deltasave-list-versions
*
*/

static enum BH_nodeTYpe {
   BH_NODE_DELTA, BH_NODE_PROJECT_TAG, BH_NODE_WORKSPACE_TAG, BH_NODE_VC_UPDATE, BH_NODE_VC_COMMIT
};
class BH_nodeInfo {
   _str        m_fullComment = '';
   _str        m_htmlComment = '';
   _str        m_version     = '';
   _str        m_date        = '';
   _str        m_time        = '';
   boolean     m_virtual     = false;
   BH_nodeTYpe m_nodeType    = BH_NODE_DELTA;
   
   BH_nodeInfo(_str versionListRow = '', BH_nodeTYpe nodeType = BH_NODE_DELTA) {
      parse versionListRow with m_version "\t" m_date "\t" m_time "\t" m_fullComment;
      if (m_version == "disk") {
         m_virtual = true;
         m_version = '0';
      }
      makeHtmlComment();
      m_nodeType    = nodeType;
   }

   _str getTreeRowString() {
      return translate(m_version :+ "\t"/*:+ m_date*/ :+ "\t"/* :+ m_time*/ :+ "\t" :+ m_fullComment, ' ', "\n");
   }
   
   private void makeHtmlComment() {
      m_htmlComment = '<FONT face="Helvetica" size="3"><b>Version:</b>  ' :+ m_version :+ '<br>';
      m_htmlComment = m_htmlComment :+ '<b>Date:</b>  ' :+ m_date :+ '<br>';
      m_htmlComment = m_htmlComment :+ '<b>Time:</b>  ' :+ m_time :+ '<br>';
      m_htmlComment = m_htmlComment :+ '<b>Comment:</b><br>' :+ stranslate(stranslate(m_fullComment,'<br>',"\n"), '&#160;', " ") :+ '<br></FONT>';
   }
};

#define BACKUP_HISTORY_POSTFIX "(Backup)"
#define DS_MOST_RECENT_VERSION "-1"
//#define GRAB_BAR_V_POS          1

defload()
{
   if (_pic_bh_cvs_commit<=0) {
      _pic_bh_cvs_commit=_update_picture(-1,'_bh_vccommit.ico');
      if (_pic_bh_cvs_commit>0) {
         set_name_info(_pic_bh_cvs_commit,"Version committed to source control.");
      }
   }
   if (_pic_bh_cvs_update<=0) {
      _pic_bh_cvs_update=_update_picture(-1,'_bh_vcupdate.ico');
      if (_pic_bh_cvs_update>0) {
         set_name_info(_pic_bh_cvs_update,"Version updated from source control.");
      }
   }
   if (_pic_bh_project_tag<=0) {
      _pic_bh_project_tag=_update_picture(-1,'_bh_project.ico');
      if (_pic_bh_project_tag>0) {
         set_name_info(_pic_bh_project_tag,"Project tag.");
      }
   }
   if (_pic_bh_workspace_tag<=0) {
      _pic_bh_workspace_tag=_update_picture(-1,'_bh_workspace.ico');
      if (_pic_bh_workspace_tag>0) {
         set_name_info(_pic_bh_workspace_tag,"Workspace tag.");
      }
   }
   rc=0;
}

defeventtab _tbdeltasave_form;

static void getSelectedItems(INTARRAY &selectedItems)
{
   int info;
   for ( ff:=1;;ff=0 ) {
      nextIndex := _TreeGetNextSelectedIndex(ff,info);
      if ( nextIndex<0 ) break;

      selectedItems[selectedItems._length()] = nextIndex;
   }
}

static void deselectFirstSelectedItem()
{
   INTARRAY selectedItems;
   getSelectedItems(selectedItems);

   while ( selectedItems._length()>2 ) {
      _TreeDeselectLine(selectedItems[0]);
      selectedItems._deleteel(0);
   }
}

void ctltree1.on_change(int reason, int index)
{
   if ( reason==CHANGE_SELECTED && index > -1 ) {
      numSelected := _TreeGetNumSelectedItems();
      if ( numSelected>2 ) {
         deselectFirstSelectedItem();
      }
   } else if ( reason==CHANGE_LEAF_ENTER && index>-1 ) {
      diffWithCurrent();
      _TreeGetInfo(index,auto state);
   }
}

static _str actualFileName (_str bufName, _str documentName)
{
   if (bufName != '') {
      return bufName;
   } else if (documentName != '') {
      int i = lastpos('_', documentName);
      int j = lastpos('.', documentName);
      int k = lastpos(' ', documentName);
      _str extension = "";
      if (j) {
         extension = "."substr(documentName, j+1, k-j-1);
      }

      return(substr(documentName, 1, i-1)""extension);
   }
   return('');
}


static _str actualFileVersion (_str bufName, _str documentName)
{
   if (bufName != '') {
      return(-1);
   } else if (documentName != '') {
      int i = lastpos('_', documentName);
      int j = lastpos('.', documentName);
      int k = lastpos(' ', documentName);
      _str version = "";
      if (j) {
         version = substr(documentName, i+1, j-i-1);
      } else {
         version = substr(documentName, i+1, k-i-1);
      }

      return(version);
   }
   return(-1);
}

void _tbdeltasave_form.on_load()
{  
   //ctltree1.p_CollapsePicture = _pic_bh_cvs_update;
   //ctltree1.p_ExpandPicture = _pic_bh_cvs_commit;
   updateBackupHistoryDisplay();
}


void _tbdeltasave_form.on_resize()
{
   do_resize();
}
static void do_resize()
{
   int containerW      = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int containerH      = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);
   if (_grabbar_horz.p_user) return;
   
   _grabbar_horz.p_user = true;
   
   ctlopen.p_x         = ctlsave_as.p_x + ctlsave_as.p_width + 2;
   ctldiff.p_x         = ctlopen.p_x + ctlopen.p_width + 2;
   ctlrevert.p_x       = ctldiff.p_x + ctldiff.p_width + 2;
   ctlcomment.p_x      = ctlrevert.p_x + ctlrevert.p_width + 2;
   ctlhistory_diff.p_x      = ctlcomment.p_x + ctlcomment.p_width + 2;

   ctllabel1.p_y       = ctlsave_as.p_height + 60;

   hPad := ctlsave_as.p_x;
   vPad := ctlsave_as.p_y;
   int availW = containerW - 2 * hPad;
   int availH = containerH - 2 * vPad;

   int grabBarVPos = 0;
   if (_grabbar_horz.p_user2) {
      grabBarVPos = ctltree1.p_y + (((availH - ctltree1.p_y) * 4) intdiv 5);
      _grabbar_horz.p_user2 = false;
   } else {
      grabBarVPos = _grabbar_horz.p_y;
   }
   
   ctltree1.p_y        = ctllabel1.p_y + ctllabel1.p_height + 60;
   ctltree1.p_width    = availW;
   ctltree1.p_height   = grabBarVPos - ctltree1.p_y;
   

   _grabbar_horz.p_width = availW;
   _grabbar_horz.p_x = hPad;
   _grabbar_horz.p_y = grabBarVPos;
   _grabbar_horz.p_visible = true;
   _grabbar_horz.p_height = 40;
   
   ctl_BH_comment_note.p_visible = false;
   ctl_BH_comment_note2.p_width = availW;
   ctl_BH_comment_note2.p_x = hPad;
   ctl_BH_comment_note2.p_height = availH - _grabbar_horz.p_y - _grabbar_horz.p_height;
   ctl_BH_comment_note2.p_y = _grabbar_horz.p_y + _grabbar_horz.p_height;
   
   _grabbar_horz.p_user = false;
}

void _tbdeltasave_form.on_destroy()
{
   // save the grabbar position
   _append_retrieve(_grabbar_horz, _grabbar_horz.p_y, "_tbdeltasave_form._grabbar_horz" );

   // Call user-level2 ON_DESTROY so that tool window docking info is saved
   call_event(p_window_id, ON_DESTROY, '2');
}

void _tbdeltasave_form.on_create()
{
   //retrieveValue := _retrieve_value("_tbdeltasave_form._grabbar_horz");
   retrieveValue := _grabbar_horz._retrieve_value();
   _grabbar_horz.p_user = false;
   _grabbar_horz.p_user2 = false;
   if (!(retrieveValue != null && isinteger(retrieveValue) && retrieveValue >=0)){
      _grabbar_horz.p_user2 = true;
   } else {
      _grabbar_horz.p_y = retrieveValue intdiv 1;
   }
}

void ctltree1.on_create()
{
   _TreeSetColButtonInfo(0,2000,TREE_BUTTON_AL_RIGHT|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT_DESCENDING,0,"Version");
   _TreeSetColButtonInfo(1,2000,TREE_BUTTON_AL_CENTER|TREE_BUTTON_PUSHBUTTON,0,"Date");
   _TreeSetColButtonInfo(2,2000,TREE_BUTTON_AL_CENTER|TREE_BUTTON_PUSHBUTTON,0,"Time");
   _TreeSetColButtonInfo(3,2000,TREE_BUTTON_PUSHBUTTON,0,"Comments");
}

static _str prevDisplayedFile = "";
static void updateBackupHistoryDisplay(boolean fromSwitch = false)
{
   int tbFormWID = _find_formobj("_tbdeltasave_form", 'n');
   if (tbFormWID) {
      if ( _GetDialogInfoHt("inDiffWithCurrent", tbFormWID.ctltree1)==1 ) {
         return;
      }
      int wid=p_window_id;
      p_window_id=tbFormWID;
      
      boolean deltaSavesAvailable = false;
      //whether we are showing symbolic reference to file on disk
      boolean deltaSymbolicReference = false;

      ctltree1._TreeDelete(TREE_ROOT_INDEX,"C");
      if (!_no_child_windows()) {
         //if (wid._grabbar_horz.p_user2) {
         //   do_resize();
         //}
         _str filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);
         boolean fileExists = file_exists(filename);
         _str versionList[] = null;
         int status = DSListVersions(filename, versionList);
         int len = versionList._length();
         p_window_id = ctltree1;
         if (!status && len > 0) {
            int i;
            int index = -1;
            _str theXML = "";
            _TreeSortCol(-1);
            for (i=0; i<len; ++i) {
               BH_nodeInfo _nodeInfo(versionList[i]);
               deltaSymbolicReference = deltaSymbolicReference || _nodeInfo.m_virtual;
               index = _TreeAddItem(TREE_ROOT_INDEX, _nodeInfo.getTreeRowString(), TREE_ADD_AS_CHILD, 0, 0, -1, 0, _nodeInfo);
               setDateTimeForNode(index,_nodeInfo.m_date,_nodeInfo.m_time);
               theXML = _nodeInfo.m_htmlComment;
            }
            if (index != -1 && ((_mdi.p_child.p_buf_name != prevDisplayedFile && fromSwitch) || !fromSwitch)) {
               loadCommentPane(tbFormWID, index, theXML);
            }
            _TreeSortCol(0,'ND');
            _TreeSizeColumnToContents(-1);
            _TreeTop();

            deltaSavesAvailable = true;

         } else {
            loadCommentPane(tbFormWID, 0, "");
         }
         p_window_id = tbFormWID;
         prevDisplayedFile = _mdi.p_child.p_buf_name;
         _str CaptionName = ctllabel1._ShrinkFilename(filename, ctltree1.p_width);
         if (CaptionName != ctllabel1.p_caption) {
            ctllabel1.p_caption = CaptionName;
         }
      } else {
         loadCommentPane(tbFormWID, 0, "");
         ctllabel1.p_caption = 'No open files';
      }
      ctlsave_as.p_enabled = deltaSavesAvailable;
      ctlopen.p_enabled = deltaSavesAvailable && (!deltaSymbolicReference);
      ctldiff.p_enabled = deltaSavesAvailable;
      ctlrevert.p_enabled = deltaSavesAvailable;
      ctlcomment.p_enabled = deltaSavesAvailable;
      ctllabel1.p_visible = (ctllabel1.p_caption != '');
      p_window_id=wid;
   }
}

static void setDateTimeForNode(int index,_str date,_str m_time)
{
   parse date with auto year '/' auto month '/' auto day;
   parse m_time with auto hour ':' auto minute ':' auto seconds;

   _TreeSetDateTime(index,1,(int)year,(int)month,(int)day);
   _TreeSetDateTime(index,2,-1,-1,-1,(int)hour,(int)minute,(int)seconds);
}

void _grabbar_horz.lbutton_down()
{
   // figure out orientation
   min := ctltree1.p_y + 450;
   max := _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   _ul2_image_sizebar_handler(min, max);
   
   //_SetDialogInfo(GRAB_BAR_V_POS, _grabbar_horz.p_y);
}

_document_renamed_BackupHistory(int buf_id, _str old_bufname, _str new_bufname, int buf_flags)
{
   updateBackupHistoryDisplay();
}


_buffer_renamed_BackupHistory(int buf_id, _str old_bufname, _str new_bufname, int buf_flags)
{
   updateBackupHistoryDisplay();
}


_cbquit_BackupHistory(int buffid, _str name, _str docname= '', int flags = 0)
{
   updateBackupHistoryDisplay();
}


_switchbuf_BackupHistory()
{
   updateBackupHistoryDisplay(true);
}


void _buffer_add_BackupHistory(int newbuffid, _str name, int flags = 0)
{
   if (flags & VSBUFFLAG_HIDDEN) return;
   updateBackupHistoryDisplay();
}


_cbmdibuffer_hidden_BackupHistory()
{
   updateBackupHistoryDisplay();
}

_cbsave_BackupHistory()
{
   updateBackupHistoryDisplay();
}


int ctlsave_as.lbutton_up()
{
   int status = 0;
   int wid = p_window_id;

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   _str format_list = 'Current Format,DOS Format,UNIX Format,Macintosh Format';
   if (!__UNIX__) {
      format_list = def_file_types;
   }
   int unixflags = 0;
#if __UNIX__
   _str attrs = file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   _str w = pos('w',attrs,'','i');
   if (!w && (attrs != '')) {
      unixflags = OFN_READONLY;
   }
#endif
   _str init_filename;
   if (_FileQType(filename) == VSFILETYPE_NORMAL_FILE) {
      init_filename = maybe_quote_filename(filename);
   } else {
      init_filename = maybe_quote_filename(_strip_filename(filename,'P'));
   }
 
   int index = ctltree1._TreeCurIndex();
   if (index < 0) {
      return(INVALID_ARGUMENT_RC);
   }

   _str versionInfoFromTree = ctltree1._TreeGetCaption(index);

   _str result = _OpenDialog('-new -mdi -modal',
                             'Save As',
                             '',     // Initial wildcards
                             format_list,  // file types
                             OFN_SAVEAS|OFN_SAVEAS_FORMAT|OFN_KEEPOLDFILE|OFN_PREFIXFLAGS|unixflags,
                             def_ext,      // Default extensions
                             init_filename, // Initial filename
                             '',      // Initial directory
                             '',      // Reserved
                             "Save As dialog box"
                            );
   if (result == '') {
      return(COMMAND_CANCELLED_RC);
   }
   _str new_filename = result;

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;
   boolean readFromDisk = false;
   //If virtual delta node pointing to file on disk, read from disk
   BH_nodeInfo nodeInfo = ctltree1._TreeGetUserInfo(index);
   if (nodeInfo.m_virtual) {
      readFromDisk = true;
   }

   int curVersionViewId = GetSelectedVersionViewId(filename, curVersion, status, readFromDisk);

   if (!curVersionViewId) {
      return(status);
   }
   p_window_id = curVersionViewId;

   status = save_as(new_filename,SV_RETRYSAVE|SV_OVERWRITE);

   p_window_id = wid;
   _delete_temp_view(curVersionViewId);
   ctltree1._TreeSetCurIndex(index);

   return(status);
}

_command void TBD_saveBackupAs() 
{
   ctlsave_as.call_event(ctlsave_as, LBUTTON_UP);
}

static int loadBackupVersion()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   int index = _TreeCurIndex();
   if (index <= 0) {
      return(INVALID_ARGUMENT_RC);
   }

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   _str versionInfoFromTree = _TreeGetCaption(index);

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;

   boolean readFromDisk = false;
   //If virtual delta node pointing to file on disk, read from disk
   BH_nodeInfo nodeInfo = ctltree1._TreeGetUserInfo(index);
   if (nodeInfo.m_virtual) {
      readFromDisk = true;
   }

   int status = 0;
   int curVersionViewId = GetSelectedVersionViewId(filename, curVersion, status, readFromDisk);
   //This should be the only place we want to edit a brand new copy of a 
   //previous Backup History version, only set p_undo_steps here.
   curVersionViewId.p_undo_steps = 32000;

   if (!curVersionViewId) {
      return(status);
   }

   int orig_view_id = p_window_id;
   p_window_id = curVersionViewId;

   _mdi.p_child.edit('+bi 'curVersionViewId.p_buf_id);

   int i = lastpos('.', filename);
   _str extension = "";
   if (i) {
      extension = "."substr(filename, i+1);
   }

   _str newDocumentName = _strip_filename(filename, "E")"_"curVersion""extension" "BACKUP_HISTORY_POSTFIX;
   docname(newDocumentName);

   updateBackupHistoryDisplay();

   return(0);
}

int ctlopen.lbutton_up()
{
   return(loadBackupVersion());
}

_command int TBD_loadBackupVersion() {
   return(loadBackupVersion());
}

int _OnUpdate_TBD_setBackupComment(CMDUI &cmdui,int target_wid,_str command)
{
   return TBD_setBackupComment_OnUpdateHelper();
}

static int TBD_setBackupComment_OnUpdateHelper()
{
   //say('TBD_setBackupComment_OnUpdateHelper');
   return(MF_ENABLED);
}

//_command int TBD_setBackupComment() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL|VSARG2_LINEHEX)
_command int TBD_setBackupComment()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   int index = _TreeCurIndex();
   if (index <= 0) {
      return(INVALID_ARGUMENT_RC);
   }

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   _str versionInfoFromTree = _TreeGetCaption(index);
   BH_nodeInfo nodeInfo = _TreeGetUserInfo(index);
   _str comments = nodeInfo.m_fullComment;

   typeless curVersion;
   parse versionInfoFromTree with curVersion .;

   int status = 0;

   int result=show('-modal -xy _tbdeltacomments_form',filename,comments,curVersion);
   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   //remove only trailing whitespace around comment
   _str label = strip(_param1, 'T');
   if (label != null) {
      //If virtual delta node pointing to file on disk, first create a delta
      if (nodeInfo.m_virtual) {
         status = DS_CreateDelta(filename, 0);
      }
      if (status) {
         return(COMMAND_CANCELLED_RC);
      }
      status = DS_SetVersionComment(filename, curVersion, label);
   }
   updateBackupHistoryDisplay();
   p_window_id = wid;
   ctltree1._set_focus();
   ctltree1._TreeSelectLine(index);
   ctltree1._TreeSetCurIndex(index);
   return(0);
}
_command int TBD_viewCVSHistory()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   int index = _TreeCurIndex();
   if (index <= 0) {
      return(INVALID_ARGUMENT_RC);
   }

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   if (file_exists(filename)) {
      cvs_history(filename);
   }
   
   return(0);
}

static int DS_SetVersionComment(_str filename, int curVersion, _str label) {
   int status = DSSetVersionComment(filename, curVersion, label);
   updateBackupHistoryDisplay();
   return status;
}

int DS_CreateDelta(_str Filename, int doCurBufnameCheck = 1) {
   if (doCurBufnameCheck) {
      return DSCreateDelta(Filename);
   }
   return DSCreateDelta2(Filename);
}

static int DS_SetProjectTag(_str filename, int curVersion, _str PWTag) {
   //0 for project
   int status = DSSetPWTag(filename, curVersion, PWTag, 0);
   updateBackupHistoryDisplay();
   return status;
}

static int DS_SetWorkspaceTag(_str filename, int curVersion, _str PWTag) {
   //1 for workspace
   int status = DSSetPWTag(filename, curVersion, PWTag, 1);
   updateBackupHistoryDisplay();
   return status;
}

int DS_SetMostRecentComment(_str filename, _str label) {
   int status = DSSetVersionComment(filename, (int)DS_MOST_RECENT_VERSION, label);
   updateBackupHistoryDisplay();
   return status;
}

int ctlcomment.lbutton_up()
{
   return (TBD_setBackupComment());
}

void ctlhistory_diff.lbutton_up()
{
   _str filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);
   //say('ctlhistory_diff.lbutton_up filename='filename);
   history_diff_machine(filename);
}


int ctltree1.A_D()
{
   return ctltree1.call_event(ctltree1,LBUTTON_DOUBLE_CLICK,'W');
}


void ctltree1.rbutton_down() {
   ctltree1.call_event(ctltree1, LBUTTON_DOWN);
}

void ctltree1.rbutton_up(int x=-1, int y=-1) {
   XW_showContextMenu("_tbdelta_menu",x,y);
}

int ctldiff.lbutton_up()
{
   if ( ctltree1._TreeGetNumSelectedItems()<2 ) {
      return(diffWithCurrent());
   } else {
      return(diffAB());
   }
}

_command int TBD_diffWithCurrent() {
   return diffWithCurrent();
}

static int loadCommentPane(int form_wid, int rowIndex, _str theXML) {
   int wid2 = p_window_id;
   p_window_id = form_wid.ctl_BH_comment_note2.p_window_id;
   p_text = theXML;
   p_window_id=wid2;
   return 0;
}

static int diffWithCurrent()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   status := 0;
   numItems := _TreeGetNumChildren(TREE_ROOT_INDEX);
   int index = _TreeCurIndex();
   _SetDialogInfoHt("inDiffWithCurrent", 1, ctltree1);
   if ( numItems>1 ) {
      if (index <= 0) {
         _SetDialogInfoHt("inDiffWithCurrent", 0, ctltree1);
         return(INVALID_ARGUMENT_RC);
      }
      curCaption := ctltree1._TreeGetCaption(index);

      _str filename = '';
      filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);
      typeless currentVersionNumber = actualFileVersion(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

      _str versionInfoFromTree = _TreeGetCaption(index);
      parse versionInfoFromTree with auto versionNum auto date auto time .;

      _HistoryDiffBackupHistoryFile(filename,versionNum);

   }else{
      _str filename = '';
      filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);
      typeless currentVersionNumber = actualFileVersion(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);
      curCaption := ctltree1._TreeGetCaption(index);
      _str versionInfoFromTree = _TreeGetCaption(index);
      typeless versionB;
      parse versionInfoFromTree with versionB "\t" .;

      do {
         //If virtual delta node pointing to file on disk, do a diff against disk
         BH_nodeInfo nodeInfo = _TreeGetUserInfo(index);
         if (nodeInfo.m_virtual) {
            origWID := p_window_id;
            status = _DiffModal('-r2 -d2 -file2title "'filename' (disk)" 'maybe_quote_filename(filename)' 'maybe_quote_filename(filename),
                                "backuphistory");
            p_window_id = origWID;
            break;
         }

         int versionBViewId = GetSelectedVersionViewId(filename, versionB, status);
         if (!versionBViewId) {
            break;
         }


         _str codeDiffOption = "";
         if (currentVersionNumber == "-1") {
            status = _DiffModal('-r2 -viewid2 -file2title "'filename' (Version 'versionB')" 'maybe_quote_filename(filename)' 'versionBViewId,
                                "backuphistory");
         } else { //this is the case when the current buffer is showing a backup version of the file.
            int versionAViewId = GetSelectedVersionViewId(filename, currentVersionNumber, status);
            if (!versionAViewId) {
               break;
            }
            status = _DiffModal('-r1 -r2 -viewid1 -viewid2 -file1title "'filename' (Version 'currentVersionNumber')" -file2title "'filename' (Version 'versionB')" 'versionAViewId' 'versionBViewId,
                                "backuphistory");
         }

         p_window_id = wid;
         ctltree1._set_focus();

         parse curCaption with curCaption "\t" .;
         searchIndex := ctltree1._TreeSearch(TREE_ROOT_INDEX,curCaption,'P');
         if ( searchIndex>=0 ) {
            ctltree1._TreeSelectLine(searchIndex);
            ctltree1._TreeSetCurIndex(searchIndex);
         }
         
         _delete_temp_view(versionBViewId);
      } while ( false );
   }
   _SetDialogInfoHt("inDiffWithCurrent", 0, ctltree1);
   return status;
}


static int diffAB()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   getSelectedItems(auto selectedItems);
   if ( selectedItems._length()!=2 ) {
      return 1;
   }

   _str versionInfoForA = _TreeGetCaption(selectedItems[0]);
   _str versionInfoForB = _TreeGetCaption(selectedItems[1]);

   typeless versionA;
   typeless versionB;
   parse versionInfoForA with versionA "\t" .;
   parse versionInfoForB with versionB "\t" .;

   int status = 0;

   int versionAViewId = GetSelectedVersionViewId(filename, versionA, status);
   if (!versionAViewId) {
      return(status);
   }
   int versionBViewId = GetSelectedVersionViewId(filename, versionB, status);
   if (!versionBViewId) {
      return(status);
   }

   _SetDialogInfoHt("inDiffWithCurrent", 1, ctltree1);
   beforeDiffWID := p_window_id;
   _DiffModal('-r1 -r2 -viewid1 -viewid2 -file1title "'filename' (Version 'versionB')" -file2title "'filename' (Version 'versionA')" 'versionBViewId' 'versionAViewId);
   p_window_id = beforeDiffWID;
   _SetDialogInfoHt("inDiffWithCurrent", 0, ctltree1);

   p_window_id = wid;
   ctltree1._set_focus();

   return(0);
}


int ctlrevert.lbutton_up()
{
   int wid = p_window_id;
   p_window_id = ctltree1;

   int index = _TreeCurIndex();
   if (index <= 0) {
      return(INVALID_ARGUMENT_RC);
   }

   _str filename = '';
   filename = actualFileName(_mdi.p_child.p_buf_name, _mdi.p_child.p_DocumentName);

   _str versionInfoFromTree = _TreeGetCaption(index);

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;
   boolean readFromDisk = false;
   //If virtual delta node pointing to file on disk, read from disk
   BH_nodeInfo nodeInfo = ctltree1._TreeGetUserInfo(index);
   if (nodeInfo.m_virtual) {
      readFromDisk = true;
   }
   int status = 0;
   int curVersionViewId = GetSelectedVersionViewId(filename, curVersion, status, readFromDisk);

   if (!curVersionViewId) {
      return(status);
   }

   int orig_view_id = p_window_id;
   p_window_id = curVersionViewId;

   int markIDOldVersion = _alloc_selection();
   if (markIDOldVersion < 0) {
      message(get_message(markIDOldVersion));
      return(markIDOldVersion);
   }
   top();
   _select_line(markIDOldVersion);
   bottom();
   _select_line(markIDOldVersion);

   p_window_id = _mdi.p_child;
   _lbclear();
   _copy_to_cursor(markIDOldVersion);
   _free_selection(markIDOldVersion);

   p_window_id = wid;
   _delete_temp_view(curVersionViewId);
   return(0);
}

_command void TBD_revertBackup() 
{
   ctlrevert.call_event(ctlrevert, LBUTTON_UP);
}

static int GetSelectedVersionViewId(_str filename, int version, int &status, boolean forceReadFromDisk = false)
{
   int newViewId = 0;

   status = 0;
   if (forceReadFromDisk) {
      int orig_view_id=p_window_id;
      status=_open_temp_view(filename, newViewId, orig_view_id, '+d');
      if (!status) {
         p_window_id = orig_view_id;
      }

   } else {
      newViewId = DSExtractVersion(filename,version,status);
   }
   if (status) {
      _message_box(nls("Could not extract version %s of '%s'\n%s", version, filename, get_message(status)));
      return(0);
   }

   return(newViewId);
}


void _init_menu_delta_save(int menu_handle, int no_child_windows)
{
   int output_handle,item_pos;
   int status=_menu_find(menu_handle,"deltasavecreate",output_handle,item_pos,'C');
   if ( status ) {
      status=_menu_find(menu_handle,"activate-deltasave",output_handle,item_pos,'M');
   }

   if ( !status ) {
      _str filename = '';
      filename = actualFileName(p_buf_name, p_DocumentName);
      status=_menu_set_state(output_handle,item_pos,MF_ENABLED,'P','&Backup history for 'filename'...',"activate-deltasave "maybe_quote_filename(filename),'deltasavecreate');
      _menu_info(output_handle,'R');   // Redraw menu bar
   }
}


int _OnUpdate_activate_deltasave(CMDUI cmdui, int target_wid, _str command)
{
   if ( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   _str filename = '';
   filename = actualFileName(target_wid.p_buf_name, target_wid.p_DocumentName);
   if (!pos("+DD", def_save_options) && !DSBackupVersionExists(filename)) {
      return(MF_GRAYED);
   }

   return(MF_ENABLED);
}


_command activate_deltasave() name_info(','VSARG2_EDITORCTL)
{
   return activate_toolbar('_tbdeltasave_form', 'ctltree1');
}


boolean _isDSBuffer(_str name)
{
   int BackupHistoryPos = lastpos(BACKUP_HISTORY_POSTFIX, name);
   if (BackupHistoryPos > 0) {
      int postFixPos = length(name) - length(BACKUP_HISTORY_POSTFIX) + 1;
      return(postFixPos == BackupHistoryPos);
   }
   return false;
}

defeventtab _tbdeltacomments_form;

void _tbdeltacomments_form.on_resize()
{
   int xbuffer=ctledit1.p_x;
   int label_wid=ctledit1.p_prev;
   int ybuffer=label_wid.p_y;

   int client_width=_dx2lx(SM_TWIP,p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_client_height);

   ctledit1.p_width=client_width-(2*xbuffer);

   int lastwid=0;
   ctledit1.p_height=((client_height-ctlok.p_height)-label_wid.p_height)-(7*ybuffer);

   ctlok.p_y=ctlok.p_next.p_y=(ctledit1.p_y+ctledit1.p_height)+ybuffer;
   
   ctledit1.p_prev.p_caption = '  ( Version ':+ctledit1.p_user2:+')';
   int fileNamewidth = ctledit1.p_width - ctledit1.p_prev.p_width;
   _str CaptionName = ctledit1.p_prev._ShrinkFilename(ctledit1.p_user, fileNamewidth);
   ctledit1.p_prev.p_caption = CaptionName :+ ctledit1.p_prev.p_caption;
}

void ctlok.on_create(_str file_being_commented='', typeless curComments='', typeless curVersion='')
{
   ctledit1.p_SoftWrap=1;
   ctledit1.p_SoftWrapOnWord=1;
   ctledit1.p_user  = file_being_commented;
   ctledit1.p_user2 = curVersion;
   ctledit1._insert_text(curComments);
}

void ctlok.lbutton_up() {
   int orig_view_id=p_window_id;
   p_window_id = ctledit1.p_window_id;
   _str comments = "";
   top();
   _str line;
   do {
      get_line_raw(line);
      comments = comments :+ strip(line, 'T') :+ "\n";
   } while (!down());
   _param1 = strip(comments, 'B', "\n\r");

   p_window_id = orig_view_id;
   p_active_form._delete_window(0);
}


