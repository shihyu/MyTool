#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "listbox.e"
#import "picture.e"
#import "stdprocs.e"
#import "svc.e"
#import "svcautodetect.e"
#import "main.e"
#endregion


defeventtab _git_pull_form;

using se.vc.IVersionControl;
void ctlshow_all_branches.lbutton_up()
{
   path := _GetDialogInfoHt("path");
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) return;
   _str *pPullRepositoryName = _GetDialogInfoHt("pRemoteName");

   _nocheck _control ctlrepository_label;
   svc_fill_in_branch_list(pInterface,path,pPullRepositoryName,auto curBranch,ctlrepository_label);
}

void ctlok.on_create(_str path="",_str *pBranchName=null,_str *pRemoteName=null,SVCPushFlags *pSVCPullFlags=null) {
   // svc_flags could be push or pull flags, so we have to check what we're 
   // doing before setting
   _SetDialogInfoHt("path",path);
   _SetDialogInfoHt("pBranchName",pBranchName);
   _SetDialogInfoHt("pRemoteName",pRemoteName);
   _SetDialogInfoHt("pSVCPullFlags",pSVCPullFlags);

   status := onCreatePull(path);
   if ( status ) {
      _delete_window(-1);
      return;
   }
   resizeDialogPull();
}

// This is the approximate with of a scrollbar in a combobox
const APPROX_VSCROLL_WIDTH = 400;

void svc_fill_in_branch_list(IVersionControl *pInterface,_str path,_str *pPullRepositoryName,_str &curBranch,int xbufferWID=0,int &biggestWidth=0)
{
   origWID := p_window_id;
   // Can't look for exact form name here because it could be for different 
   // systems
   activeFormCaption := p_active_form.p_caption;
   if ( pos("Pull ", activeFormCaption) ) {
      _nocheck _control ctlbranch_to_pull_from;                                                                                
      p_window_id  = ctlbranch_to_pull_from;
   } else if ( pos("Push ", activeFormCaption) ) {
      _nocheck _control ctlpush_to_branch;
      p_window_id = ctlpush_to_branch;
   } else if ( pos(" Checkout ", activeFormCaption) ) {
      _nocheck _control ctlbranch_list;
      p_window_id = ctlbranch_list;
   }
   xbuffer := xbufferWID==0?ctlpath_label.p_x:xbufferWID.p_x;
   _lbclear();
   curBranch = "";
   pInterface->getBranchNames(auto branchNames,curBranch, path,true, *pPullRepositoryName,ctlshow_all_branches.p_value?SVC_BRANCH_ALL:0);
   foreach (auto branch in branchNames) {
      _lbadd_item(branch);
      // Get the width from a text box
      biggestWidth = max(biggestWidth, _text_width(branch));
   }

   if ( p_width<biggestWidth ) {
      _nocheck _control ctlvscroll1;
      ctlshow_all_branches.p_x = p_x_extent+xbuffer;

      // Fudge a little becuase we cannot get the width
      // of the vertical scrollbar width and we do not
      // want a horizontal scrollbar
      p_width = biggestWidth+APPROX_VSCROLL_WIDTH;
      biggestWidth+=APPROX_VSCROLL_WIDTH;
   }
   p_window_id = origWID;
}

static int onCreatePull(_str path)
{
   xbuffer := ctlpath_label.p_x;
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      return 1;
   }
   if ( path==null ) path="";
   _str *pBranchName = _GetDialogInfoHt("pBranchName");
   _str *pPullRepositoryName = _GetDialogInfoHt("pRemoteName");
   ctlpath_label.p_caption = "Pull to:  "path;
   ctlrepository_label.p_caption = *pPullRepositoryName'/';
   _retrieve_prev_form();
   svc_fill_in_branch_list(pInterface,path,pPullRepositoryName,auto curBranch);
   ctlbranch_to_pull_from.p_x = ctlrepository_label.p_x_extent + (xbuffer intdiv 2);

   ctlbranch_to_pull_from._cbset_text(curBranch);
   ctlauto_stash.p_enabled = ctlrebase.p_value!=0;
   ctlspecify_branch.call_event(ctlspecify_branch,LBUTTON_UP);
   return 0;
}

static bool hasBasicChallengeError(_str buf) {
   p := pos("authorization failed: Could not authenticate to server: rejected Basic challenge",buf,1,'i');
   if ( p ) {
      return true;
   }
   return false;
}

void ctlrebase.lbutton_up()
{
   ctlauto_stash.p_enabled = p_value!=0;
}

void ctlspecify_branch.lbutton_up()
{
   ctlrepository_label.p_enabled = ctlshow_all_branches.p_enabled = ctlbranch_to_pull_from.p_enabled = ctlspecify_branch.p_value!=0;
}

static void resizeDialogPull()
{
   xbuffer := ctlpath_label.p_x;
   ybuffer := ctlpath_label.p_y;

   alignControlsVertical(xbuffer, (ctlpath_label.p_y_extent + 2*ybuffer), ybuffer, 
                         ctlno_commit.p_window_id, 
                         ctlverbose.p_window_id,
                         ctlrebase.p_window_id,
                         ctlauto_stash.p_window_id,
                         ctlspecify_branch.p_window_id,
                         ctlrepository_label.p_window_id
                         );
   alignControlsHorizontal(xbuffer+300, ctlrepository_label.p_y, xbuffer intdiv 3, 
                           ctlrepository_label.p_window_id,
                           ctlbranch_to_pull_from.p_window_id,
                           ctlshow_all_branches.p_window_id);

   // 4/8/2020
   // This is leftover from trying to use one form for push and pull.  Leaving
   // it in because one option can get very long and this ensures it will be
   // wide enough on all platforms
   biggestWidth := 0;
   biggestWidth = max(biggestWidth, ctlno_commit.p_width);
   biggestWidth = max(biggestWidth, ctlauto_stash.p_width);
   biggestWidth = max(biggestWidth, ctlrebase.p_width);
   p_active_form.p_width = max(p_active_form.p_width, biggestWidth+ctlno_commit.p_x+(2*xbuffer));

   ctlok.p_y = ctlok.p_next.p_y = ctlbranch_to_pull_from.p_y_extent+(ybuffer*3);
   ctlshow_all_branches.p_x = ctlbranch_to_pull_from.p_x_extent+xbuffer;
   p_active_form.p_height = ctlok.p_y_extent+ybuffer;
}

void ctlcancel.lbutton_up()
{
   p_active_form._delete_window();
}                                                                             

void ctlok.lbutton_up()
{
   _str *pBranchName = _GetDialogInfoHt("pBranchName");
   _str *pRemoteName = _GetDialogInfoHt("pRemoteName");
   SVCPullFlags  *pSVCPullFlags = _GetDialogInfoHt("pSVCPullFlags");

   *pSVCPullFlags=0;
   if ( ctlrebase.p_enabled && ctlrebase.p_value ) {
      (*pSVCPullFlags)|=SVC_PULL_REBASE;
   } else {
      (*pSVCPullFlags)&~SVC_PULL_REBASE;
   }
   if ( ctlno_commit.p_enabled && ctlno_commit.p_value ) {
      (*pSVCPullFlags)|=SVC_PULL_NOCOMMIT;
   } else {
      (*pSVCPullFlags)&=~SVC_PULL_NOCOMMIT;
   }
   if ( ctlverbose.p_enabled && ctlverbose.p_value ) {
      (*pSVCPullFlags)|=SVC_PULL_VERBOSE;
   } else {
      (*pSVCPullFlags)&=~SVC_PULL_VERBOSE;
   }
   if ( ctlauto_stash.p_enabled && ctlauto_stash.p_value ) {
      (*pSVCPullFlags)|=SVC_PULL_AUTOSTASH;
   } else {
      (*pSVCPullFlags)&=~SVC_PULL_AUTOSTASH;
   }
   if ( ctlspecify_branch.p_enabled && ctlspecify_branch.p_value ) {
      (*pSVCPullFlags)|=SVC_PULL_SPECIFY_BRANCH;
   } else {
      (*pSVCPullFlags)&=~SVC_PULL_SPECIFY_BRANCH;
   }
   *pBranchName = strip(ctlbranch_to_pull_from.p_text);
   parse ctlrepository_label.p_caption with auto remoteName '/' .;
   *pRemoteName = strip(remoteName);
   _save_form_response();
   p_active_form._delete_window(0);
}

defeventtab _git_push_form;

void ctlok.on_create(_str path,_str *pBranchName=null,_str *pRemoteName=null,int *pSVCPushFlags=null) {
   // svc_flags could be push or pull flags, so we have to check what we're 
   // doing before setting
   _SetDialogInfoHt("path",path);
   _SetDialogInfoHt("pBranchName",pBranchName);
   _SetDialogInfoHt("pRemoteName",pRemoteName);
   _SetDialogInfoHt("pSVCPushFlags",pSVCPushFlags);
   onCreatePush(path);
   resizeDialogPush();                            
}

static void resizeDialogPush()
{
   xbuffer := ctlpath_label.p_x;
   ybuffer := ctlpath_label.p_y;

   alignControlsVertical(ybuffer, (ctlpath_label.p_y_extent + 2*ybuffer), ybuffer, 
                         ctlall.p_window_id, 
                         ctltags.p_window_id,
                         ctlfollow_tags.p_window_id,
                         ctlset_upstream.p_window_id,
                         ctlverbose.p_window_id,
                         ctlspecify_branch.p_window_id,
                         ctlrepository_label.p_window_id);

   ctlpush_to_branch.p_y = ctlrepository_label.p_y - ybuffer;
   alignControlsHorizontal(xbuffer+300, ctlrepository_label.p_y, xbuffer intdiv 3, 
                           ctlrepository_label.p_window_id,
                           ctlpush_to_branch.p_window_id,
                           ctlshow_all_branches.p_window_id);

   biggestWidth := max(ctlall.p_width, ctltags.p_width, ctlspecify_branch.p_width, ctlset_upstream.p_width);

   ctlok.p_y = ctlok.p_next.p_y = ctlpush_to_branch.p_y_extent+(ybuffer*3);
   p_active_form.p_width = max(p_active_form.p_width, biggestWidth+ctlall.p_x+(2*xbuffer));
   p_active_form.p_height = ctlok.p_y_extent+ybuffer;
}

static int onCreatePush(_str path)
{
   xbuffer := ctlpath_label.p_x;                         
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      return 1;
   }
   ctlpath_label.p_caption = "Push from:  ":+path;
   _str *pRemoteName = _GetDialogInfoHt("pRemoteName");
   _str *pBranchName = _GetDialogInfoHt("pBranchName");

   ctlpath_label.p_caption = "Push to:  "path;
   ctlrepository_label.p_caption = *pRemoteName'/';
   origWID := p_window_id;
   _nocheck _control ctlpush_to_branch;
   p_window_id = ctlpush_to_branch;
   biggestWidth := p_width;
   pInterface->getBranchNames(auto branchNames,auto curBranch, path,true, *pRemoteName);
   // If we got a branch name before, we want to use that one
   if ( pBranchName && *pBranchName=="" ) {
      curBranch = *pBranchName;
   }
   foreach (auto branch in branchNames) {
      _lbadd_item(branch);
      biggestWidth = max(biggestWidth, _text_width(branch));
   }
   p_width = biggestWidth;
   //p_x = ctlrepository_label.p_x_extent + (xbuffer intdiv 2);
   p_window_id = origWID;

   SVCPushFlags *pSVCPushFlags = _GetDialogInfoHt("pSVCPushFlags");

   _retrieve_prev_form();
#if 0 //15:03pm 2/22/2021
   if ( curBranch == "" && ctlpush_to_branch.p_text != curBranch ) {
      ctlspecify_branch.p_value = 0;
      ctlpush_to_branch.p_enabled = false;
      ctlshow_all_branches.p_enabled = false;
   }
#endif
   ctlpush_to_branch._cbset_text(curBranch);
   ctlspecify_branch.call_event(ctlspecify_branch,LBUTTON_UP);
   return 0;
}

void ctlall.lbutton_up()
{
   ctlspecify_branch.p_enabled = !p_value;
   ctlspecify_branch.call_event(ctlspecify_branch,LBUTTON_UP);
}

void ctlspecify_branch.lbutton_up()
{
   ctlrepository_label.p_enabled = ctlpush_to_branch.p_enabled = ctlshow_all_branches.p_enabled = ctlspecify_branch.p_enabled!=false && ctlspecify_branch.p_value!=0;
}

void ctlok.lbutton_up()
{
   _str *pBranchName = _GetDialogInfoHt("pBranchName");
   _str *pRemoteName = _GetDialogInfoHt("pRemoteName");
   SVCPushFlags  *pSVCPushFlags = _GetDialogInfoHt("pSVCPushFlags");

   *pSVCPushFlags=0;
   if ( ctlall.p_enabled && ctlall.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_ALL;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_ALL;
   }
   if ( ctltags.p_enabled && ctltags.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_TAGS;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_TAGS;
   }
   if ( ctlfollow_tags.p_enabled && ctlfollow_tags.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_FOLLOW_TAGS;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_FOLLOW_TAGS;
   }
   if ( ctlset_upstream.p_enabled && ctlset_upstream.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_SET_UPSTREAM;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_SET_UPSTREAM;
   }
   if ( ctlverbose.p_enabled && ctlverbose.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_VERBOSE;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_VERBOSE;
   }
   if ( ctlspecify_branch.p_enabled && ctlspecify_branch.p_value ) {
      (*pSVCPushFlags)|=SVC_PUSH_SPECIFY_BRANCH;
   } else {
      (*pSVCPushFlags)&~SVC_PUSH_SPECIFY_BRANCH;
   }
   *pBranchName = strip(ctlpush_to_branch.p_text);
   parse ctlrepository_label.p_caption with auto remoteName '/' .;
   *pRemoteName = strip(remoteName);
   _save_form_response();
   p_active_form._delete_window(0);
}
