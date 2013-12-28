////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47140 $
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
#import "diff.e"
#import "files.e"
#import "guiopen.e"
#import "main.e"
#import "sellist2.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

int def_deltasave_flags=0;
int def_deltasave_versions=DELTASAVE_DEFAULT_NUMVERSIONS;
int def_deltasave_timeout=DELTASAVE_DEFAULT_TIMEOUT;
int def_deltasave_use_timeout=1;
_str def_deltasave_exclusions="";

defeventtab _deltasave_versions_dialog;

_nocheck _control ctltree1;

int ctlclose.on_create(_str filename='')
{
   if ( filename=='' ) {
      if ( _no_child_windows() ) {
         _message_box(get_message(MISSING_FILENAME_RC));
         p_active_form._delete_window(MISSING_FILENAME_RC);
         return(MISSING_FILENAME_RC);
      }
      filename=_mdi.p_child.p_buf_name;
   }
   p_active_form.p_caption='Versions of 'filename' available';
   int wid=p_window_id;
   p_window_id=ctltree1;

   _TreeSetColButtonInfo(0,2000,TREE_BUTTON_AL_RIGHT|TREE_BUTTON_PUSHBUTTON|TREE_BUTTON_SORT_NUMBERS|TREE_BUTTON_SORT_DESCENDING,0,"Version");
   _TreeSetColButtonInfo(1,2000,TREE_BUTTON_AL_RIGHT|TREE_BUTTON_PUSHBUTTON,0,"Date");
   _TreeSetColButtonInfo(2,2000,TREE_BUTTON_AL_RIGHT|TREE_BUTTON_PUSHBUTTON,0,"Time");

   _str versionList[]=null;
   DSListVersions(filename,versionList);

   int len=versionList._length();
   int i;
   for (i=0;i<len;++i) {
      _TreeAddItem(TREE_ROOT_INDEX,versionList[i],TREE_ADD_AS_CHILD,0,0,-1);
   }
   _TreeSortCol(0,'ND');
   _TreeTop();
   _TreeAdjustColumnWidths();

   p_window_id=wid;
   return(0);
}

void ctltree1.on_change(int reason,int index,int col=-1)
{
   if ( reason==CHANGE_BUTTON_PRESS && col > 0) {
      int width,flags,state,caption;
      _str sort_options='N';
      _TreeGetColButtonInfo(0,width,flags,state,caption);

      if ( !(flags&TREE_BUTTON_SORT_DESCENDING) ) sort_options=sort_options'D';
      _TreeSortCol(0,sort_options);
      if ( flags&TREE_BUTTON_SORT_DESCENDING ) {
         _TreeSetColButtonInfo(0,width,flags&~TREE_BUTTON_SORT_DESCENDING,state,caption);
      }else{
         _TreeSetColButtonInfo(0,width,flags|TREE_BUTTON_SORT_DESCENDING,state,caption);
      }
   }
}

_deltasave_versions_dialog.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_active_form.p_client_height);

   int button_buffer_x=ctldiff.p_x-(ctlclose.p_x+ctlclose.p_width);

   int tree_buffer_x=ctltree1.p_x;
   int tree_buffer_y=ctltree1.p_y;

   ctltree1.p_width=client_width-(2*tree_buffer_x);

   int tree_height=client_height-(ctlclose.p_height+(3*tree_buffer_y));

   ctltree1.p_height=tree_height;

   int button_y=ctltree1.p_y+ctltree1.p_height+tree_buffer_y;

   ctlclose.p_y=ctldiff.p_y=ctlview.p_y=ctlsave_as.p_y=button_y;
}

int _OnUpdate_deltasave_list_versions(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   if (!pos("+DD", def_save_options) && !DSBackupVersionExists(target_wid.p_buf_name)) {
      return(MF_GRAYED);
   }

   return(MF_ENABLED);
}
_command void deltasave_list_versions(_str filename='') name_info(','VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_READ_ONLY)
{
   show('-modal -xy _deltasave_versions_dialog',filename);
}

#define VERSIONS_DIALOG_INFO_INDEXES 0

int ctlview.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;

   int index=_TreeCurIndex();
   if ( index<0 ) return(INVALID_ARGUMENT_RC);

   _str versionInfoFromTree=_TreeGetCaption(index);

   _str filename='';
   parse p_active_form.p_caption with 'Versions of 'filename ' available';

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;

   int status=0;
   int curVersionViewId=GetSelectedVersionViewId(filename,curVersion,status);

   if ( !curVersionViewId ) {
      return(status);
   }

   int orig_view_id=p_window_id;
   p_window_id=curVersionViewId;
   read_only_mode();
   p_window_id=orig_view_id;

   _showbuf(curVersionViewId.p_buf_id,true,'-new -modal -xy',filename' (Version 'curVersion')','S',false);

   p_window_id=wid;
   ctltree1._set_focus();
   return(0);
}

int ctldiff.lbutton_up()
{
   int wid=p_window_id;
   p_window_id=ctltree1;

   int index=_TreeCurIndex();
   if ( index<0 ) return(INVALID_ARGUMENT_RC);

   _str versionInfoFromTree=_TreeGetCaption(index);

   _str filename='';
   parse p_active_form.p_caption with 'Versions of 'filename ' available';

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;

   int status=0;
   int curVersionViewId=GetSelectedVersionViewId(filename,curVersion,status);

   if ( !curVersionViewId ) {
      return(status);
   }

   diff('-modal -r2 -viewid2 -file2title "'filename' (Version 'curVersion')" 'maybe_quote_filename(filename)' 'curVersionViewId);

   p_window_id=wid;
   ctltree1._set_focus();
   return(0);
}

int ctlsave_as.lbutton_up()
{
   _str filename='';
   parse p_active_form.p_caption with 'Versions of 'filename ' available';

   _str format_list='Current Format,DOS Format,UNIX Format,Macintosh Format';
   if (!__UNIX__) {
      format_list=def_file_types;
   }
   int unixflags=0;
#if __UNIX__
   _str attrs=file_list_field(filename,DIR_ATTR_COL,DIR_ATTR_WIDTH);
   _str w=pos('w',attrs,'','i');
   if (!w && attrs!='') {
      unixflags=OFN_READONLY;
   }
#endif
   _str init_filename;
   if (_FileQType(filename)==VSFILETYPE_NORMAL_FILE) {
      init_filename=maybe_quote_filename(filename);
   } else {
      init_filename=maybe_quote_filename(_strip_filename(filename,'P'));
   }
   _str result=_OpenDialog('-new -mdi -modal',
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
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str new_filename=result;

   int wid=p_window_id;
   p_window_id=ctltree1;

   int index=_TreeCurIndex();
   if ( index<0 ) return(INVALID_ARGUMENT_RC);

   _str versionInfoFromTree=_TreeGetCaption(index);

   typeless curVersion;
   parse versionInfoFromTree with curVersion "\t" .;

   int status=0;
   int curVersionViewId=GetSelectedVersionViewId(filename,curVersion,status);

   if ( !curVersionViewId ) {
      return(status);
   }
   int orig_view_id=p_window_id;
   p_window_id=curVersionViewId;

   status=save_as(new_filename,SV_RETRYSAVE|SV_OVERWRITE);

   p_window_id=orig_view_id;

   p_window_id=wid;
   ctltree1._set_focus();
   return(status);
}

static int GetSelectedVersionViewId(_str filename,int version,int &status)
{
   int versionViewTable:[]=_GetDialogInfo(VERSIONS_DIALOG_INFO_INDEXES);

   int newViewId=0;
   newViewId=versionViewTable:[version];
   if ( newViewId==null ) {
      status=0;
      newViewId=DSExtractVersion(filename,version,status);
      if ( status ) {
         _message_box(nls("Could not extract version %s of '%s'\n%s",version,filename,get_message(status)));
         return(0);
      }
      versionViewTable:[version]=newViewId;
      _SetDialogInfo(VERSIONS_DIALOG_INFO_INDEXES,versionViewTable);
   }
   return(newViewId);
}

void ctlview.on_destroy()
{
   int versionViewTable:[]=_GetDialogInfo(VERSIONS_DIALOG_INFO_INDEXES);
   if ( versionViewTable!=null ) {
      typeless i;
      for (i._makeempty();;) {
         versionViewTable._nextel(i);
         if ( i._isempty() ) break;
         _delete_temp_view(versionViewTable:[i]);
      }
   }
}

//void _init_menu_delta_save(int menu_handle,int no_child_windows)
//{
//   int output_handle,item_pos;
//   int status=_menu_find(menu_handle,"deltasavecreate",output_handle,item_pos,'C');
//   if ( status ) {
//      status=_menu_find(menu_handle,"deltasave-list-versions",output_handle,item_pos,'M');
//   }
//
//   if ( !status ) {
//      status=_menu_set_state(output_handle,item_pos,MF_ENABLED,'P','&Backup history for 'p_buf_name'...',"deltasave-list-versions "maybe_quote_filename(p_buf_name),'deltasavecreate');
//   }
//   _menu_info(output_handle,'R');   // Redraw menu bar
//}
