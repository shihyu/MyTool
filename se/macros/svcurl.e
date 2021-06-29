////////////////////////////////////////////////////////////////////////////////////
// Copyright 2013 SlickEdit Inc. 
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
#include 'slick.sh'
#import "cvsutil.e"
#import "diff.e"
#import "dir.e"
#import "fileman.e"
#import "main.e"
#import "picture.e"
#import "stdprocs.e"
#import "svc.e"
#import "treeview.e"
#endregion Imports

using se.vc.IVersionControl;

defeventtab _svc_url_explorer_form;

void ctlclose.on_create()
{
   p_active_form.p_caption = "Version Control URL explorer";
   loadTree();
}

////////////////////////////////////////////////////////
// svcURL.xml is still used for auto restore information
//
static const TREE_INFO_FILENAME= 'svcURL.xml';

void loadTree()
{
   filename := _ConfigPath():+TREE_INFO_FILENAME;
   xmlhandle := _xmlcfg_open(filename,auto status=0);
   if ( xmlhandle>=0 ) {
      status = ctltree1._TreeLoadDataXML(xmlhandle,_xmlcfg_get_first_child(xmlhandle,TREE_ROOT_INDEX));
   }
   _xmlcfg_close(xmlhandle);
}

static void saveTree()
{
   filename := _ConfigPath():+TREE_INFO_FILENAME;
   xmlhandle := _xmlcfg_create(filename,VSENCODING_UTF8,VSXMLCFG_CREATE_IF_EXISTS_CLEAR);
   if ( xmlhandle>=0 ) {
      ctltree1._TreeSaveDataXML(xmlhandle);
   }
   _xmlcfg_close(xmlhandle);
}

void ctlclose.on_destroy()
{
   saveTree();
}

void _svc_url_explorer_form.on_resize()
{
   clientHeight := _dy2ly(SM_TWIP,p_client_height);
   clientWidth := _dy2ly(SM_TWIP,p_client_width);
   labelWID := ctltree1.p_prev;
   bufferY := labelWID.p_y;
   bufferX := labelWID.p_x;

   ctltree1.p_x = labelWID.p_x;
   ctltree1.p_y = labelWID.p_y_extent + bufferY;

   buttonRowHeight := ctlclose.p_height+(2*bufferY);

   ctltree1.p_height = clientHeight-(ctltree1.p_y)-buttonRowHeight;
   ctltree1.p_width = clientWidth-(2*bufferX);

   ctlclose.p_y = ctladd_url.p_y = ctlremove.p_y = ctlcheckout.p_y = ctltree1.p_y_extent+bufferY;
}

void ctladd_url.lbutton_up()
{
   _param1='';
   _str result = show('-modal _textbox_form',
                      'Add Version Control URL', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'svn add repository', //Retrieve Name
                      'URL:'
                     );

   if ( result=='' ) {
      return;
   }
   _str URL=_param1;
   if ( URL=="" ) {
      return;
   }
   origWID := p_window_id;
   p_window_id = ctltree1;
   int index=_TreeSearch(TREE_ROOT_INDEX,URL);
   if ( index>=0 ) {
      _message_box(nls("'%s' is already in the browser"));
      _TreeSetCurIndex(index);
      p_window_id = origWID;
      return;
   }
   int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,URL,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,TREE_NODE_COLLAPSED);
   p_window_id = origWID;
   return;
}

void ctltree1.on_change(int reason,int index)
{
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;
   switch ( reason ) {
   case CHANGE_EXPANDED:
      {
         if (_TreeGetFirstChildIndex(index)>=0) _TreeDelete(index,'C');
         url := parentURL(index);
         pInterface->getURLChildDirectories(url,auto paths);
         len := paths._length();
         for ( i:=0;i<len;++i ) {
            _TreeAddItem(index,paths[i],TREE_ADD_AS_CHILD,_pic_fldaop,_pic_fldaop,0);
         }
         _TreeSortCaption(index,_fpos_case'F');
      }
   case CHANGE_SELECTED:
      {
         if ( _TreeGetDepth(index)==1 ) {
            ctlremove.p_enabled = true;
         } else {
            ctlremove.p_enabled = false;
         }
      }
   }
}

void ctlremove.lbutton_up()
{
   removeCurItem();
}

void ctlcheckout.lbutton_up()
{
   checkoutCurItem();
}

static void checkoutCurItem()
{
   wid := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   URL := parentURL(index);
   IVersionControl *pInterface = svcGetInterface(def_vc_system);
   if ( pInterface==null ) return;

   SVC_CHECKOUT_INFO coInfo;
   coInfo.localPath='';
   coInfo.URL='';
   coInfo.createdPath='';

   if ( index<0 ) {
      return;
   }
   status := show('-modal _svc_checkout_form',URL,&coInfo);

   if ( status ) return;

   // switch to the proper local path
   local := coInfo.localPath;
   if ( coInfo.createdPath!="" ) {
      local = coInfo.createdPath;
   }
   pushd(local);

   // Now that we have switched to the path, set the local path to "" so that 
   // the URL is preserved
   if ( coInfo.preserveURL ) local = "";

   status = pInterface->checkout(URL,local);
   popd();

   p_window_id = wid;

   p_active_form._delete_window();
}

static void removeCurItem()
{
   wid := p_window_id;
   p_window_id = ctltree1;
   index := _TreeCurIndex();
   if ( index>=0 ) {
      _TreeDelete(index);
   }
   p_window_id = wid;
}

static _str parentURL(int index)
{
   URL := "";
   for (;;) {
      if ( index<=TREE_ROOT_INDEX ) break;
      cap := _TreeGetCaption(index);
      URL = cap'/'URL;
      index = _TreeGetParentIndex(index);
   }
   return URL;
}

defeventtab _svc_checkout_form;

void ctlpath.on_change()
{
   path := p_text;
   URL := ctlURL.p_text;
   if ( ctlrevision.p_text!="" ) {
      ctlshow_path.p_caption="Will checkout revision ":+ctlrevision.p_text:+" to ":+SVCGetCheckoutPath(path,URL,ctlpreserve_url.p_value!=0);
   } else {
      ctlshow_path.p_caption="Will checkout to ":+SVCGetCheckoutPath(path,URL,ctlpreserve_url.p_value!=0);
   }
}

void ctlpreserve_url.lbutton_up()
{
   ctlpath.call_event(CHANGE_OTHER,ctlpath,ON_CHANGE,"W");
}

static _str SVCGetCheckoutPath(_str local_path,_str URL,bool preserveURL)
{
   local_path=absolute(local_path);
   _maybe_append_filesep(local_path);
   if ( preserveURL ) {
      p := pos('/',URL,1,'r');
      if ( p ) {
         // Find the second slassh, this should be the end of xxx://
         p=pos('/',URL,p+1,'r');
         if ( p ) {
            // Find the second slassh, this should be the end of the host name
            p=pos('/',URL,p+1,'r');
            if ( p ) {
               //local_path=local_path:+substr(URL,p+1);
               p=pos('/',URL,p+1,'r');
               if ( p ) {
                  local_path :+= substr(URL,p+1);
               }
            }
         }
      }
   }
   local_path=stranslate(local_path,FILESEP,'/');
   return(local_path);
}

void _subversion_checkout_form.on_load()
{
   ctlpath._set_focus();
}

void ctlok.on_create(_str URL='',_str revision='',SVC_CHECKOUT_INFO *pco_info=null)
{
   ctlURL.p_text=URL;
   ctlpath.p_text=getcwd();
   ctlrevision.p_text=revision;
   _SetDialogInfoHt("coInfoPointer",pco_info);

   _subversion_checkout_form_initial_alignment();
}

static int SVCVerifyCheckoutPath(_str path,_str &created_path)
{
   created_path='';
   _str parent_dir=_GetParentDirectory(path);
   status := 0;
   if ( !isdirectory(parent_dir) ) {
      int result=_message_box(nls("Parent directory '%s' does not exist, create it now?",parent_dir),'',MB_OKCANCEL);
      if ( result==IDOK ) {
         status=make_path(parent_dir);
         created_path=parent_dir;
      }else{
         status=COMMAND_CANCELLED_RC;
      }
   }else{
      // Build the sub-path that would be in 'path' if this contained a subversion checkout
      _str svn_subdir=path;
      _maybe_append_filesep(svn_subdir);
      svn_subdir :+= ".svn";

      // Build the sub-path that would be in 'path' if this contained a cvs checkout
      _str cvs_subdir=path;
      _maybe_append_filesep(cvs_subdir);
      cvs_subdir :+= "CVS";

      if ( isdirectory(svn_subdir) || isdirectory(cvs_subdir) ) {
         ctlpath._text_box_error("A version is already checked out here");
         return(1);
      }
   }
   return(status);
}

int ctlok.lbutton_up()
{
   SVC_CHECKOUT_INFO *pcoInfo=_GetDialogInfoHt("coInfoPointer");
   if ( pcoInfo ) {
      pcoInfo->URL=ctlURL.p_text;
      localPath := SVCGetCheckoutPath(ctlpath.p_text,pcoInfo->URL,ctlpreserve_url.p_value!=0);
      createdPath := "";
      int status=SVCVerifyCheckoutPath(localPath,createdPath);
      if ( status ) {
         return(status);
      }
      pcoInfo->localPath   = localPath;
      pcoInfo->createdPath = createdPath;
      pcoInfo->preserveURL = ctlpreserve_url.p_value!=0;
      pcoInfo->revision    = ctlrevision.p_text;
   }
   p_active_form._delete_window(0);
   return(0);
}

int ctlcancel.lbutton_up()
{
   p_active_form._delete_window(COMMAND_CANCELLED_RC);
   return(COMMAND_CANCELLED_RC);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _subversion_checkout_form_initial_alignment()
{
   // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctlpath.p_window_id, _browsedir1.p_window_id, 0, ctlURL.p_x_extent);
}
