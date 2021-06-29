#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "stdprocs.e"
#import "svc.e"
#import "svcautodetect.e"
#import "main.e"
#endregion


defeventtab _git_stash_form;

using se.vc.IVersionControl;

void _git_stash_form.on_resize()
{
   xbuffer := ctlpath_label.p_x;
   p_active_form.p_width = max(p_active_form.p_width, ctlpath_label.p_x_extent+(2*xbuffer));
}

void ctlok.on_create(_str path,SVCStashFlags *pSVCPullFlags=null) {
   autoVCSystem := svc_get_vc_system(path);
   IVersionControl *pInterface = svcGetInterface(autoVCSystem);
   if ( pInterface==null ) {
      return;
   }


   xbuffer := ctlpath_label.p_x;
   if ( path==null ) path="";
   path = pInterface->localRootPath(path);

   // svc_flags could be push or pull flags, so we have to check what we're 
   // doing before setting
   _SetDialogInfoHt("path",path);
   _SetDialogInfoHt("pSVCPullFlags",pSVCPullFlags);

   say('ctlok.on_create path='path);
   ctlpath_label.p_caption = "Stash files in: "path;

   _retrieve_prev_form();
}

void ctlok.lbutton_up()
{
   SVCStashFlags  *pSVCStashFlags = _GetDialogInfoHt("pSVCPullFlags");
   if ( ctlpop.p_enabled && ctlpop.p_value ) {
      (*pSVCStashFlags)|=SVC_STASH_POP;
   } else {
      (*pSVCStashFlags)&~SVC_STASH_POP;
   }
   p_active_form._delete_window(0);
}

