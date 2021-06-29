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
#import "cvsutil.e"
#import "diff.e"
#import "dlgman.e"
#import "fileman.e"
#import "help.e"
#import "main.e"
#import "picture.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "subversion.e"
#import "subversionutil.e"
#import "svc.e"
#import "se/vc/IVersionControl.e"
#import "sc/lang/String.e"
#endregion

using se.vc.IVersionControl;
using sc.lang.String;

//http://svn.orcaware.com:8000/repos
defeventtab _subversion_browser_form;

struct SVN_BROWSE_INFO {
   int timer_handle;
};
SVN_BROWSE_INFO gBrowseInfo;

definit()
{
   gBrowseInfo=null;
}


static const BROWSE_INFO_POINTER_INDEX= 0;

void ctltree1.on_create()
{
   _SetDialogInfo(BROWSE_INFO_POINTER_INDEX,&gBrowseInfo);


   _str URL_list_filename=_ConfigPath():+SUBVERSION_INFO_FILENAME;
   int status;
   int xml_handle=_xmlcfg_open(URL_list_filename,status);

   if ( !status ) {
      int open_repositories_index=_xmlcfg_find_simple(xml_handle,"/OpenRepositories");
      if ( open_repositories_index>-1 ) {
         int xml_child_index=_xmlcfg_get_first_child(xml_handle,open_repositories_index);
         for (;;) {
            if ( xml_child_index<0 ) break;
            _str URL=_xmlcfg_get_attribute(xml_handle,xml_child_index,"Name");
            int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,URL,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
            _TreeSetInfo(new_node_index,0);
            xml_child_index=_xmlcfg_get_next_sibling(xml_handle,xml_child_index);
         }
      }
   }
}

//////////////////////////////////////////////////////////////////////////////
// handle resizing form, moving vertical divider between tag files
// on the left and source files on the left.
//
int ctldivider.lbutton_down()
{
   mou_mode(1);
   mou_release();mou_capture();
   done := false;
   xpos := 0;
   int orig_wid;
   int selected_wid=orig_wid=p_window_id;
   p_window_id=selected_wid.p_parent;

#ifdef not_finished
   _str draw_setup;
   _save_draw_setup(draw_setup);

   p_fill_style=PSFS_TRANSPARENT;
   p_draw_width=1;
   p_draw_style=PSDS_SOLID;
   p_draw_mode=PSDM_XORPEN;
   _str color=_rgb(0x80,0x80,0x80);  /* Gray */
   rectangle_drawn := false;
#endif

   int morig_x=mou_last_x('M');
   int morig_y=mou_last_y('M');

   morig_x=selected_wid.p_x+100;//selected_wid.p_width;
   morig_y=selected_wid.p_y_extent;
   done=false;

   int orig_x,orig_y,orig_width,orig_height;
   selected_wid._get_window(orig_x,orig_y,orig_width,orig_height);

   orig_width=ctldivider.p_width;//Hack

   int x1=orig_x;
   int y1=orig_y;
   int x2=x1+orig_width;
   int y2=y1+orig_height;
   int orig_x1=x1;
   int orig_y1=y1;
   int orig_x2=x2;
   int orig_y2=y2;
   int smallest_width=_HANDLE_WIDTH*2;
   int smallest_height=_HANDLE_HEIGHT*2;

   _lxy2lxy(SM_TWIP,p_scale_mode,smallest_width,smallest_height);
   for (;;) {
      _str event=get_event();
      switch (event) {
      case MOUSE_MOVE:
         int new_x1=x1;
         int new_y1=y1;
         int new_x2=x2;
         int new_y2=y2;
         new_x1=mou_last_x('M');
         new_x2=new_x1+60;
         if (new_y2-new_y1<smallest_height) {
            new_y1=y1;new_y2=y2;
         }
#ifdef not_finished
         if (rectangle_drawn) {

            if (x1==new_x1 && y1==new_y1 && x2==new_x2 &&y2==new_y2) {
               break;
            }
            /* Erase the rectangle. */
            _draw_rect(x1,y1,x2,y2,(int)color,0,'e');
         }
#endif
         x1=new_x1;y1=new_y1;x2=new_x2;y2=new_y2;
#ifdef not_finished
         rectangle_drawn=1;
         _draw_rect(x1,y1,x2,y2,(int)color,0,'e');
#endif
         break;
      case LBUTTON_UP:
         int x_pos=mou_last_x('m');
         mou_mode(0);
         mou_release();
#ifdef not_finished
         if (rectangle_drawn) {
            /* Erase the rectangle. */
            _draw_rect(x1,y1,x2,y2,(int)color,0,'e');
         }
         _restore_draw_setup(draw_setup);
#endif
         if (x_pos>=ctltree1.p_x&&x_pos<=ctlfile_tree.p_x_extent) {
            ctldivider.p_x=x_pos;
            ctlfile_tree.p_x=ctldivider.p_x_extent;
            ctltree1.p_x_extent = ctldivider.p_x;
            ctlfile_tree.p_width=_dx2lx(SM_TWIP,p_active_form.p_client_width)-ctlfile_tree.p_x;
         }
         return(0);
      }
   }
   return(0);
}

//////////////////////////////////////////////////////////////////////////////
// Handle form resizing
//
_subversion_browser_form.on_resize()
{
   int client_width=_dx2lx(SM_TWIP,p_active_form.p_client_width);
   int client_height=_dy2ly(SM_TWIP,p_active_form.p_client_height);
   int ybuffer=ctltree1.p_y;
   int xbuffer=ctltree1.p_x;
   int tree_height=client_height-(2*ybuffer);
   tree_height-=ctladd_to_list.p_height+(ybuffer);
   ctltree1.p_height=tree_height;
   //ctlfile_tree.p_height=ctldivider.p_height=ctltree1.p_height;
   ctltree1.p_width=client_width-(2*xbuffer);

   ctladd_to_list.p_y=ctltree1.p_y_extent+ybuffer;
   ctlremove_from_list.p_y=ctlclose.p_y=ctlcheckout.p_y=ctladd_to_list.p_y;
}

void ctladd_to_list.lbutton_up()
{
   ctltree1.svn_browser_add_repository();
}

void ctlremove_from_list.lbutton_up()
{
   removeCurrentItemFromTree();
}

void ctladd_to_list.lbutton_up()
{
   ctltree1.svn_browser_add_repository();
}

struct SVN_CHECKOUT_INFO {
   _str URL;
   _str local_path;
   _str created_path;
};

int ctlcheckout.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctltree1;
   tree_index := _TreeCurIndex();
   status := 0;

   SVN_CHECKOUT_INFO co_info;
   co_info.local_path='';
   co_info.URL='';
   co_info.created_path='';

   if ( tree_index>-1 ) {
      _str URL=SVNBrowseBuildURL(tree_index);
      status=show('-modal _subversion_checkout_form',URL,&co_info);
   }
   p_window_id=wid;

   if ( !status ) {
      OutputFilename := "";
      //status=_SVNCheckout(co_info.URL,co_info.local_path,'',OutputFilename);
      IVersionControl *pVCI = svcGetInterface("subversion");
      if (pVCI) {
         status = pVCI->checkout("",co_info.local_path);
      }
      if ( status==COMMAND_CANCELLED_RC ) {
         del_path := co_info.created_path!=''?co_info.created_path:co_info.local_path;
         int result=_message_box(nls("Delete path '%s' and all files under it?",del_path),'',MB_OKCANCEL);
         if ( result==IDOK ) {
            status=_DelTree(del_path,true);
         }
      }else if ( status ) {
         _SVCDisplayErrorOutputFromFile(OutputFilename);
      }
      delete_file(OutputFilename);
   }
   if ( !status ) {
      p_active_form._delete_window(status);
   }
   return(status);
}

void ctltree1.rbutton_up()
{
   ctltree1.call_event(ctltree1,LBUTTON_DOWN);
   int index=find_index("_subversion_tree_menu",oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'P');
   index=ctltree1._TreeCurIndex();
   int x,y;
   mou_get_xy(x,y);
   int status=_menu_show(menu_handle,VPM_RIGHTBUTTON,x-1,y-1);
   _menu_destroy(menu_handle);
}

_command int svn_browser_add_repository() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   if ( p_active_form.p_name!='_subversion_browser_form' ) {
      // Do not want to run this from the command line, etc.
      return(COMMAND_CANCELLED_RC);
   }
   _param1='';
   _str result = show('-modal _textbox_form',
                      'Add Subversion Repository', // Form caption
                      0,  //flags
                      '', //use default textbox width
                      '', //Help item.
                      '', //Buttons and captions
                      'svn add repository', //Retrieve Name
                      'URL:'
                     );

   if ( result=='' ) {
      return(COMMAND_CANCELLED_RC);
   }
   _str URL=_param1;
   if ( URL=="" ) {
      return 0;
   }
   int index=_TreeSearch(TREE_ROOT_INDEX,URL);
   if ( index>=0 ) {
      _message_box(nls("'%s' is already in the browser"));
      _TreeSetCurIndex(index);
      return(0);
   }
   int new_node_index=_TreeAddItem(TREE_ROOT_INDEX,URL,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen);
   ctltree1.call_event(CHANGE_EXPANDED,new_node_index,ctltree1,ON_CHANGE,'W');
   return(0);
}

_command svn_browse() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   show('_subversion_browser_form');
}

static _str SVNBrowseBuildURL(int index)
{
   URL := "";
   for (;;) {
      cur_caption := _TreeGetCaption(index);
      _maybe_append(cur_caption,'/');
      URL=cur_caption:+URL;
      index=_TreeGetParentIndex(index);
      if ( index<=0 ) break;
   }
   return(URL);
}

/**
 * Calls svn ls for <i>remote_path</i> and stores the results in <i>info</i>.
 * Used primarily to identify subdirectories that only exist remotely.
 *
 * @param remote_path remote path (URL) to run "ls" on
 * @param info structure to fill results into
 *
 * @return int 0 if successful
 */
static int _SVNLs(_str remote_path,SVN_SUBDIR_INFO &info=null,_str &lsCommand="")
{
   _str ErrorFilename=mktemp();
   String StdOutData,StdErrData;
   int status=_CVSPipeProcess(_SVNGetExeAndOptions()' --non-interactive ls  '_maybe_quote_filename(remote_path),'','P'def_cvs_shell_options,StdOutData,StdErrData,
                              false,null,null,null,-1,false,false);
   lsCommand = _SVNGetExeAndOptions()' --non-interactive ls '_maybe_quote_filename(remote_path);
   if ( status ) {
      return(status);
   }
   int temp_view_id;
   int orig_wid=_create_temp_view(temp_view_id);
   _insert_text(StdErrData.get());
   _insert_text(StdOutData.get());
   top();up();
   while ( !down() ) {
      get_line(auto cur_line);
      if ( cur_line=='svn: URL non-existent in that revision' ) {
         // Just something invalid so we know that we looked up this path
         info.SubdirHT:[remote_path][0]=FILESEP:+FILESEP:+FILESEP;
         break;
      }
      int cur_len=info.SubdirHT:[remote_path]._length();
      info.SubdirHT:[remote_path][cur_len]=cur_line;
   }
   p_window_id=orig_wid;
   _delete_temp_view(temp_view_id);

   // Signify that we really have run the ls for this path.  We could fill in
   // info.SubdirHT based on some optimizations
   info.PathsLSWascalledFor:[remote_path]='';
   return(0);
}

static int SVNBrowseExpandItem(_str TreeInfo)
{
   _str formwid_str,index_str;
   parse TreeInfo with formwid_str index_str;
   int formwid=(int)formwid_str;
   int index=(int)index_str;
   wid := p_window_id;
   p_window_id=formwid.ctltree1;
   SVN_BROWSE_INFO *pBrowseInfo=formwid.SVNBrowseGetInfoPtr();
   //_kill_timer(pBrowseInfo->timer_handle);

   status := 0;
   _str URL=SVNBrowseBuildURL(index);
   SVN_SUBDIR_INFO info;
   if ( _TreeGetFirstChildIndex(index)<0 ) {
      mou_hour_glass(true);
      status=_SVNLs(URL,info);
      if ( status ) {
         _message_box(nls("Could not get information for '%s'",URL));
         _TreeSetInfo(index,0,_pic_fldopenm,_pic_fldopenm);
         return(status);
      }
      int len,i;
      len=info.SubdirHT:[URL]._length();
      _TreeSetInfo(index,1);
      if ( len>0 ) {
         for (i=0;i<len;++i) {
            _str cur_cap=info.SubdirHT:[URL][i];
            if ( _last_char(cur_cap)=='/' ) {
               // Only add the directories
               cur_cap=substr(cur_cap,1,length(cur_cap)-1);
               _TreeAddItem(index,cur_cap,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,0);
            }
         }
         _TreeRefresh();
      }else{
         _TreeSetInfo(index,-1);
      }
      mou_hour_glass(false);
   }
   p_window_id=wid;
   return(status);
}

SVN_BROWSE_INFO *SVNBrowseGetInfoPtr()
{
   SVN_BROWSE_INFO *pinfo=_GetDialogInfo(BROWSE_INFO_POINTER_INDEX);
   return(pinfo);
}

static int SVNBrowseDeferTreeCall(SVN_BROWSE_INFO *pBrowseInfo,int interval,typeless *pfnCallback,int tree_node_index)
{
   if ( pBrowseInfo!=null && pBrowseInfo->timer_handle!=null &&
        pBrowseInfo->timer_handle>=0 ) {
      _kill_timer(pBrowseInfo->timer_handle);
      pBrowseInfo->timer_handle=-1;
   }
   pBrowseInfo->timer_handle=_set_timer(interval,pfnCallback,p_active_form' 'tree_node_index);
   return(pBrowseInfo->timer_handle);
}

void ctltree1.on_change(int reason,int index)
{
   SVN_BROWSE_INFO *pBrowseInfo=SVNBrowseGetInfoPtr();
   switch (reason) {
   case CHANGE_EXPANDED:
      if ( index>-1 ) {
         // If the index that was passed in is good

         child_index := _TreeGetFirstChildIndex(index);
         if ( child_index<0 ) {
            // If there are no children already
            //SVNBrowseDeferTreeCall(SVNBrowseGetInfoPtr(),250,SVNBrowseExpandItem,index);
           int status=SVNBrowseExpandItem(p_active_form' 'index);
         }
      }
      break;
   default:
   }
}

static void removeCurrentItemFromTree()
{
   wid := p_window_id;
   p_window_id = ctltree1;
   tree_index := _TreeCurIndex();

   if ( _TreeGetDepth(tree_index)==1 ) {
      // This is a repository level item

      _TreeDelete(tree_index);
   }
   p_window_id = wid;
}

void ctltree1.del()
{
   removeCurrentItemFromTree();
}

void _subversion_browser_form.on_destroy()
{
   _str URL_list_filename=_ConfigPath():+SUBVERSION_INFO_FILENAME;
   int status;
   int xml_handle=_xmlcfg_open(URL_list_filename,status);
   if ( status ) {
      xml_handle=_xmlcfg_create(URL_list_filename,VSENCODING_UTF8);
      _xmlcfg_add(xml_handle,TREE_ROOT_INDEX,"OpenRepositories",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   }
   int open_repositories_index=_xmlcfg_find_simple(xml_handle,"/OpenRepositories");
   if ( open_repositories_index>-1 ) {
      // Delete all of the child nodes
      _xmlcfg_delete(xml_handle,open_repositories_index,true);
      wid := p_window_id;
      p_window_id=ctltree1;
      tree_index := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
      for (;;) {
         if ( tree_index<0 ) break;

         cur_repository_name := _TreeGetCaption(tree_index);

         int node_index=_xmlcfg_add(xml_handle,open_repositories_index,"OpenRepository",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_add_attribute(xml_handle,node_index,"Name",cur_repository_name,0);

         tree_index=_TreeGetNextSiblingIndex(tree_index);
      }
      p_window_id=wid;
   }
   _xmlcfg_save(xml_handle,-1,0);
   _xmlcfg_close(xml_handle);
}

static const CO_INFO_POINTER= 0;

defeventtab _subversion_checkout_form;
void ctlpath.on_change()
{
   path := p_text;
   URL := ctlURL.p_text;
   ctlshow_path.p_caption="Will checkout to ":+SVNGetCheckoutPath(path,URL,ctlpreserve_url.p_value!=0);
}

void ctlpreserve_url.lbutton_up()
{
   ctlpath.call_event(CHANGE_OTHER,ctlpath,ON_CHANGE,"W");
}

static _str SVNGetCheckoutPath(_str local_path,_str URL,bool preserveURL)
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

void ctlok.on_create(_str URL='',SVN_CHECKOUT_INFO *pco_info=null)
{
   ctlURL.p_text=URL;
   ctlpath.p_text=getcwd();
   _SetDialogInfo(CO_INFO_POINTER,pco_info);

   _subversion_checkout_form_initial_alignment();
}

static int SVNVerifyCheckoutPath(_str path,_str &created_path)
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
      svn_subdir :+= SUBVERSION_CHILD_DIR_NAME;

      // Build the sub-path that would be in 'path' if this contained a cvs checkout
      _str cvs_subdir=path;
      _maybe_append_filesep(cvs_subdir);
      cvs_subdir :+= CVS_CHILD_DIR_NAME;

      if ( isdirectory(svn_subdir) || isdirectory(cvs_subdir) ) {
         ctlpath._text_box_error("A version is already checked out here");
         return(1);
      }
   }
   return(status);
}

int ctlok.lbutton_up()
{
   SVN_CHECKOUT_INFO *pco_info=_GetDialogInfo(CO_INFO_POINTER);
   if ( pco_info ) {
      pco_info->URL=ctlURL.p_text;
      _str local_path=SVNGetCheckoutPath(ctlpath.p_text,pco_info->URL,ctlpreserve_url.p_value!=0);
      created_path := "";
      int status=SVNVerifyCheckoutPath(local_path,created_path);
      if ( status ) {
         return(status);
      }
      pco_info->local_path=local_path;
      pco_info->created_path=created_path;
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
