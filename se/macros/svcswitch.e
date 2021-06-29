#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "combobox.e"
#import "listbox.e"
#import "markfilt.e"
#import "picture.e"
#import "stdprocs.e"
#import "svc.e"
#import "svcautodetect.e"
#import "svcpushpull.e"
#import "main.e"
#endregion

using se.vc.IVersionControl;

defeventtab _git_switch_form;
void ctlcreate_path_from_branch_name.lbutton_up()
{
   path := _GetDialogInfoHt("path");
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box("Could not get interface for version control system '"path"'.\n\nSet up version control from Tools>Version Control>Setup");
      return;
   }
}
void ctlshow_all_branches.lbutton_up()
{
   xbuffer := ctlpath_label.p_x;
   path := _GetDialogInfoHt("path");
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box("Could not get interface for version control system '"path"'.\n\nSet up version control from Tools>Version Control>Setup");
      return;
   }
   _str *pPullRepositoryName = _GetDialogInfoHt("pRemoteName");

   biggestWidth := 0;
   svc_fill_in_branch_list(pInterface,path,pPullRepositoryName,auto curBranch,biggestWidth:biggestWidth);
   ctlshow_all_branches.p_x = ctlbranch_list.p_x_extent+xbuffer;  // ctlpath_label.p_x same as xbuffer

   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   diff := ctlshow_all_branches.p_x_extent-client_width+xbuffer;
   if ( diff>0 ) {
      p_active_form.p_width += diff;
   }
}


void ctlok.on_create(_str path="",_str *pBranchName=null,_str *pRemoteName=null,_str *pCreateNewBranch=null) {
   xbuffer := ctlpath_label.p_x;
   _SetDialogInfoHt("path",path);
   _SetDialogInfoHt("pBranchName",pBranchName);
   _SetDialogInfoHt("pRemoteName",pRemoteName);
   _SetDialogInfoHt("pCreateNewBranch",pCreateNewBranch);

   ctlbranch_list.p_x = ctlpath_label.p_x_extent;
   ctlshow_all_branches.p_x = ctlbranch_list.p_x_extent+xbuffer;

   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box("Could not get interface for version control system '"path"'.\n\nSet up version control from Tools>Version Control>Setup");
      return;
   }

   svc_fill_in_branch_list(pInterface,path,pRemoteName,auto curBranch,ctlpath_label);

   ctlbranch_list.p_text = curBranch;
   ctlbranch_list._set_sel(1,length(ctlbranch_list.p_text)+1);
   ctlpath.p_caption = "Path:":+path;

   _SetDialogInfoHt("path",path);

   _retrieve_prev_form();
}

void ctlbranch_list.on_change(int reason){
   path := _GetDialogInfoHt("path");
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      _message_box("Could not get interface for version control system '"path"'.\n\nSet up version control from Tools>Version Control>Setup");
      return;
   }
   status := _cbi_search();
   origTextLength := length(p_text);
   if ( origTextLength==0 ) return;
   if ( !status ) {
      _lbselect_line();
   }
}

void ctlok.lbutton_up()
{
#if 0 //15:31pm 2/25/2021
   lastBranch := _GetDialogInfoHt("lastBranch");
   if ( ctlnew_branch.p_value && lastBranch!=null ) {
      _message_box(nls("A branch named '%s' already exists.",lastBranch));
      return;
   }
#endif

   _str *pBranchName = _GetDialogInfoHt("pBranchName");
   if ( ctlbranch_list._lbget_text() != ctlbranch_list.p_text ) {
      // If the textbox doesn't match the value in the 
      if ( ctlnew_branch.p_value ) {
         *pBranchName = ctlbranch_list.p_text;
      } else {
         result := _message_box(nls("Checkout branch '%s'?",ctlbranch_list._lbget_text()),"",MB_YESNO);
         if ( result==IDYES ) {
            *pBranchName = ctlbranch_list._lbget_text();
         } else {
            return;
         }
      }
   } else {
      *pBranchName = ctlbranch_list.p_text;
   }
   pCreateNewBranch := _GetDialogInfoHt("pCreateNewBranch");
   *pCreateNewBranch = ctlnew_branch.p_value;
   
   p_active_form._delete_window(0);
}
