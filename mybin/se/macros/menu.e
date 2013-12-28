////////////////////////////////////////////////////////////////////////////////////
// $Revision: 50134 $
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
#include "license.sh"
#import "clipbd.e"
#import "complete.e"
#import "files.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "makefile.e"
#import "markfilt.e"
#import "menuedit.e"
#import "mouse.e"
#import "options.e"
#import "projconv.e"
#import "projutil.e"
#import "recmacro.e"
#import "refactor.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "unittest.e"
#import "wkspace.e"
#endregion

#define SPACES 2

_str old_search_string;
static _str _disabled_icon_commands;
static _str _disabled_ncw_commands;
int gLRUWindowList[];
/* _menu_refresh_list */

// default to enabling the ant/makefile target menus
int def_show_makefile_target_menu=1;

static _str _open_menu_callback(int reason,var result,typeless key);

definit()
{
   if ( arg(1)!='L' ) {
      gLRUWindowList._makeempty();
      /* Editor initialization case. */
      /* don't know where menu file is yet. */
      /* Don't know where help file is yet. */
      _help_file_spec='';
      _cur_mdi_menu=def_mdi_menu;
      _disabled_icon_commands=0;
      _disabled_ncw_commands=0;
   } else {
      _disabled_icon_commands=1;
      _disabled_ncw_commands=1;
   }
   /* _update_cl_menu_refresh() */
   rc=0;
   _origMdiMenuFont='';
}
#define FILEHIST_HELP  ''
#define FILEHIST_MESSAGE 'Opens file '
#define FILEHIST_CATEGORY 'filehist'

#define WKSPHIST_CATEGORY 'wkspchist'

/** 
 * Adds file history to end of File menu on the SlickEdit MDI menu 
 * bar.  The <i>filename</i> argument MUST be specified in absolute.  Use the 
 * absolute function to do this.  This requirement
 * is imposed so that unnecessary disk reads (during auto restore) do
 * not occur.  Calling the absolute function for floppy drives is slow.
 * 
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_hist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 * 
 * @categories Menu_Functions
 * 
 */
void _menu_add_filehist(_str filename)
{
   call_list("_MenuAddFileHist_",filename);
   if (!def_max_filehist || !_mdi.p_menu_handle || !length(filename)) return;

   _menu_add_hist(filename,_mdi.p_menu_handle,0,FILEHIST_CATEGORY,'e','ncw',
                  FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
}

void _menu_remove_filehist(_str filename)
{
   call_list("_MenuRemoveFileHist_", filename);

   if (!def_max_filehist || !_mdi.p_menu_handle || !length(filename)) return;

   _menu_remove_hist(filename, _mdi.p_menu_handle, 0,FILEHIST_CATEGORY,'e','ncw',
                     FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
}

// Input filename must be absolute
static _str _reduce_filenamelen(_str filename,int len)
{
   _str value=filename;
   int isHTTPFile=_isHTTPFile(value);
   if (isHTTPFile) {
      value=translate(value,FILESEP,FILESEP2);
   }

   _str start="";
   _str server="";
   _str share_name="";
   _str rest="";
   _str path="";

   for (;;){
      if (length(value)<=len) break;
      /* Remove a path */
#if __UNIX__
      //start=substr(value,1,1);
      //rest=substr(value,2);
      if (isHTTPFile) {
         start=substr(value,1,5);
         rest=substr(value,6);
      } else {
         parse value with 2 start '/','r' ;
         if (length(start)) {
            start='/'start:+'/';
         } else {
            start='/';
         }
         rest=substr(value,length(start)+1);
      }
#else
      if (substr(value,1,2)=='\\') {
         parse value with '\\' server '\' share_name '\' rest;
         start='\\' server '\' share_name;
         if (rest!='') {
            start=start:+FILESEP;
         }
      } else if (isHTTPFile) {
         start=substr(value,1,5);
         rest=substr(value,6);
      } else {
         start=substr(value,1,3);
         rest=substr(value,4);
      }
#endif
      // Just incase server share name is very long
      if (rest=='..' || rest=='') {   // Bug Fix
         value='';break;
      }
      for (;;) {
         parse rest with  path (FILESEP) rest;
         if (rest=='') {
            rest='..';
            break;
         }
         if (path!='..') {
            rest='..':+FILESEP:+rest;
            break;
         }
      }
      value=start :+ rest;
   }
#if !__UNIX__
   if (isHTTPFile) {
      value=translate(value,'/','\');
   }
#endif
   return(value);
}

/**
 * Doubles any ampersands in a filename so that the filename will show up 
 * properly in a menu. 
 * 
 * @param filename 
 * 
 * @return _str 
 */
_str _prepare_filename_for_menu(_str filename)
{
   // check for ampersands in the file names - double 
   // them or they will show up as hotkeys
   return stranslate(filename, '&&', '&');
}

_str _make_fhist_caption(_str filename,_str dash_category)
{
   filename = _prepare_filename_for_menu(filename);

   // strip off the "project.pbxproj" to make this a little easier to read
   // in the project menu
   if (dash_category:==WKSPHIST_CATEGORY) {
      if (_get_extension(filename,1):==XCODE_PROJECT_EXT) {
         filename=_strip_filename(filename,'N');
         if (last_char(filename):==FILESEP) {
            filename=substr(filename,1,length(filename)-1);
         }
      }
   }

   if (!(substr(filename,1,1)==FILESEP 
           || (_NAME_HAS_DRIVE && substr(filename,2,1)==':'))
       ) {
      _str name,temp;
      parse filename with name ' - ' temp;
      if (temp!='') {
         _str result=_reduce_filenamelen(temp,def_max_fhlen);
         return(name' - 'result);
      }
      //_str result=_reduce_filenamelen(filename,def_max_fhlen);
      //return(result);
   }
   //say('filename='filename);

   _str name=_strip_filename(filename,'P');
   _str result=_reduce_filenamelen(filename,def_max_fhlen);
   if (filename==name) {
      return(filename);
   }
   return(name' - 'result);
}
//
//This function currently only supports add file history because
//file case matching is performed and file names are place in
//double quotes if the filename contains spaces.
//

/**
 * General purpose function for adding files to a drop-down menu on a menu 
 * bar.  This function is limited to adding filenames and not arbitrary strings 
 * because it uses the file_eq function to compare filenames already added to 
 * the list.  The <i>filename</i> argument MUST be specified in absolute.  Use 
 * the <b>absolute</b> function to do this.
 * 
 * This function currently only supports add file history because
 * file case matching is performed and file names are place in
 * double quotes if the filename contains spaces.
 * 
 * @param filename Filename to add.
 * 
 * @param menu_handle Handle to loaded menu bar returned by p_menu_handle 
 * or <b>_menu_load</b>.
 * 
 * @param submenu_pos Integer position 
 * (0..<b>_menu_info</b>(<i>menu_handle</i>)-1) of drop-down menu.  If this is 
 * not a valid integer, this must be the caption of the drop-down menu (ex. 
 * &File or &Project).
 * 
 * @param dash_category Unique category for menu item line before files in 
 * drop-down menu.  This is how this function finds items in the existing list.  
 * You do not have to add the menu item line.  This function will add it for 
 * you.
 * 
 * @param command Command which will be given the <i>filename</i> argument to 
 * open the file.
 * 
 * @param category Category given to added menu items.
 * 
 * @param help_command Help command given to added menu item that is 
 * executed when F1 is pressed.
 * 
 * @param help_message Message given to added menu item that is displayed on 
 * the message line when the menu item is selected.
 * 
 * @see on_init_menu
 * @see _menu_add_filehist
 * @see _menu_add_workspace_hist
 * @see _menu_delete
 * @see _menu_delete
 * @see _menu_destroy
 * @see _menu_find
 * @see _menu_get_state
 * @see _menu_info
 * @see _menu_insert
 * @see _menu_load
 * @see _menu_match
 * @see _menu_move
 * @see _menu_set
 * @see _menu_set_state
 * @see _menu_show
 * @see alt_menu
 * @see insert_object
 * @see menu_mdi_bind_all
 * @see mou_show_menu
 * @see show
 * 
 * @categories Menu_Functions
 * 
 */
void _menu_add_hist(_str filename,int menu_handle,typeless submenu_pos,_str dash_category,_str command,_str category,_str help_command,_str help_message)
{
   // Look for the menu files separator */
   int mh=0;
   int dash_mh=0;
   int dash_pos=0;
   int mf_flags=0;
   int flags=0;
   int i=0,Nofitems=0;
   _str item_text="";
   typeless file_mh=0;
   int status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (isinteger(submenu_pos)) {
     _menu_get_state(menu_handle,submenu_pos,mf_flags,'p',item_text,file_mh);
   } else {
      // Find the submenu with caption matching submenu_pos
      mh=menu_handle;
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
        if (strieq(item_text,submenu_pos)) {
           break;
        }
      }
      if (i>=Nofitems) return;
   }
   if (status) {
      /* Add the menu files separator. */
      _menu_insert(file_mh,-1,MF_ENABLED,'-','',dash_category);
      _menu_insert(file_mh,-1,MF_ENABLED,
                   '&1 ':+_make_fhist_caption(filename,dash_category),  // caption
                   command' 'maybe_quote_filename(filename), // command
                   category,             // categories.
                   help_command,
                   help_message
                   );
      return;
   }
   Nofitems=_menu_info(file_mh,'c');
   int maxf=def_max_filehist;
   _str caption="";
   _str tcommand="";
   _str categories="";
   _str thelp_message="";
   _str cmd="";
   _str tfilename="";
   // Don't count the All Workspace item.
   if (dash_category==WKSPHIST_CATEGORY) {
      _menu_get_state(file_mh,Nofitems-1,flags,'p',caption,tcommand,categories,help_command,thelp_message);
      // submenu return index of menu for command
      if (isinteger(tcommand)) {
         --Nofitems;
      }
      maxf=def_max_workspacehist;
   }
   for (i=dash_pos+1;;++i) {
      if (i>=Nofitems) {
         if (Nofitems-dash_pos-1>=maxf) {
            // Delete last item
            if (dash_category == FILEHIST_CATEGORY) {
               _menu_get_state(file_mh,Nofitems-1,flags,'p',caption,tcommand);
               parse tcommand with . tfilename;
               call_list("_MenuRemoveFileHist_", tfilename);
            }
            _menu_delete(file_mh,Nofitems-1);
            break;
         }
         break;
      }
      _menu_get_state(file_mh,i,flags,'p',caption,tcommand,categories,help_command,thelp_message);
      parse caption with . caption ;
      _menu_set_state(file_mh,i,flags,'p','&'(i-dash_pos+1)' 'caption,tcommand,categories,help_command,thelp_message);

      parse tcommand with cmd tfilename ;
      if (file_eq(filename,strip(tfilename,'b','"'))) {
         _menu_delete(file_mh,i);
         break;
      }
   }
   _menu_insert(file_mh,dash_pos+1,MF_ENABLED,'&1 ':+_make_fhist_caption(filename,dash_category),
                command' 'maybe_quote_filename(filename),category,help_command,help_message);

}
//
//  This function currently only supports add file history because
//  file case matching is performed and file names are place in
//  double quotes if the filename contains spaces.
//
void _menu_remove_hist(_str filename,int menu_handle,typeless submenu_pos,_str dash_category,_str command,_str category,_str help_command,_str help_message)
{
   // Look for the menu files separator */
   int mh=0;
   int i=0, Nofitems=0;
   int dash_mh=0;
   int dash_pos=0;
   int mf_flags=0;
   int flags=0;
   _str item_text="";
   typeless file_mh=0;
   int status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (isinteger(submenu_pos)) {
     _menu_get_state(menu_handle,submenu_pos,mf_flags,'p',item_text,file_mh);
   } else {
      // Find the submenu with caption matching submenu_pos
      mh=menu_handle;
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
        if (strieq(item_text,submenu_pos)) {
           break;
        }
      }
      if (i>=Nofitems) return;
   }
   if (status) {
      // Nothing to remove
      return;
   }
   _str caption="";
   _str tcommand="";
   _str categories="";
   _str thelp_message="";
   _str cmd="";
   _str tfilename="";
   Nofitems=_menu_info(file_mh,'c');
   for (i=dash_pos+1;;++i) {
      if (i>=Nofitems) {
         break;
      }
      _menu_get_state(file_mh,i,flags,'p',caption,tcommand,categories,help_command,thelp_message);
      // If this is a submenu
      if (isinteger(tcommand)) {
         break;
      }
      parse caption with . caption;
      _menu_set_state(file_mh,i,flags,'p','&'(i-dash_pos)' 'caption,tcommand,categories,help_command,thelp_message);

      parse tcommand with cmd tfilename;
      if (file_eq(filename,strip(tfilename,'b','"'))) {
         _menu_delete(file_mh,i);
         --Nofitems;--i;
      }
   }

}
int _sr_filehist(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null)
{
   typeless junk=0;
   typeless status=0;
   typeless Noffiles=0;
   int flags=0;
   int count=0;
   int i=0,Nofitems=0;
   int dash_mh=0;
   int dash_pos=0;
   _str filename="";
   _str caption="";
   _str help_message="";

   if (option=='R' || option=='N') {
      parse info with Noffiles .;
      status=_menu_find(_mdi.p_menu_handle,FILEHIST_CATEGORY,dash_mh,dash_pos,'c');
      if (!status) {
         Nofitems=_menu_info(dash_mh,'c');
         for (i=Nofitems-1; i>=dash_pos+1 ;--i) {
            _menu_delete(dash_mh,i);
         }
      }
      if (!def_max_filehist || !_mdi.p_menu_handle || !Noffiles) {
         down(Noffiles);
         return(0);
      }
      for (i=1;i<=Noffiles;++i) {
         down();
         if (i<=def_max_filehist) {
            get_line(filename);
            _menu_add_filehist(_isHTTPFile(filename)?filename:absolute(filename,relativeToDir));
         }
      }
   } else {
      if (def_max_filehist && _mdi.p_menu_handle) {
         // Look for the menu files separator */
         status=_menu_find(_mdi.p_menu_handle,FILEHIST_CATEGORY,dash_mh,dash_pos,'c');
         if (status) return(0);
         Nofitems=_menu_info(dash_mh,'c');
         for (count=0,i=Nofitems-1; i>=dash_pos+1 ;++count,--i) {
            _menu_get_state(dash_mh,i,flags,'p',caption,junk,junk,junk,help_message);
            parse help_message with . . filename;
            if (relativeToDir==null || _isHTTPFile(filename)) {
               insert_line(filename);
            } else {
               insert_line(relative(filename,relativeToDir));
            }
         }
         up(count);
         insert_line(upcase(FILEHIST_CATEGORY)': 'count);
         down(count);
      }
   }
   return(0);
}
static void _menu_adjust_help()
{
   int status=0;
   int mh=0, mpos=0;
   int mf_flags=0;
   _str caption="";

   int menu_handle=p_menu_handle;
   if (!menu_handle) return;
#if __UNIX__
   _menu_set_state(menu_handle,'help -search',MF_ENABLED,'m',
             '&Search...');
                //'&Search Help &Index');
      //_menu_set_state(menu_handle,'help',MF_ENABLED,'m','&General Help');
   status=_menu_find(menu_handle,"help -using",mh,mpos,'M');
   if (!status) {
      _menu_delete(mh,mpos);
   }
   status=_menu_find(menu_handle,"printer-setup",mh,mpos,'M');
   if (!status) {
      _menu_delete(mh,mpos);
   }
#else
   status=_menu_find(menu_handle,"help -using",mh,mpos,'M');
   if (!status) {
      _menu_delete(mh,mpos);
   }
#endif
   if (!(
          machine()=='WINDOWS' &&
          (_win32s()==2 || _win32s()==0)
        )
      ) {
      // DemoShield not support here
      status=_menu_find(menu_handle,"demo",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
   if (__UNIX__) {
      status=_menu_find(menu_handle,"configure_index_file",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"help_index",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      status=_menu_find(menu_handle,"msdn_configure_collection",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
      _menu_get_state(mh,mpos,mf_flags,"p",caption);
      if (caption=="-") {
         _menu_delete(mh,mpos);
      }
      _menu_adjust_config(menu_handle);
   }
}
static void _menu_adjust_config(int menu_handle)
{
   if (__UNIX__) {
      int mh=0, mpos=0;
      int status=_menu_find(menu_handle,"assocft",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
}
#if 0 //__UNIX__
static maybe_delete_softbench_menu(mh)
{
   if (!_softbench_running()) {
      // Find the submenu with caption matching submenu_pos
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh)
        item_text=stranslate(item_text,'','&');
        if (strieq(item_text,'SBSHOW')) {
           break;
        }
      }
      if (i<Nofitems) {
         _menu_delete(mh,i);
      }
   }
}
#endif
void _load_mdi_menu()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_MENUS)) {
      return;
   }
   int status=0;
   if (_cur_mdi_menu!='') {
      int index=find_index(_cur_mdi_menu,oi2type(OI_MENU));
      if (!index) {
         _message_box(nls("MDI menu '%s' not found",_cur_mdi_menu));
      } else {
         int menu_handle=_mdi._menu_load(index);
#if 0 //__UNIX__
         maybe_delete_softbench_menu(menu_handle);
#endif
         if (menu_handle<0) {
            _message_box(nls("Unable to load MDI menu.  ")get_message(menu_handle));
         } else {
            int old_menu_handle=_mdi.p_menu_handle;
            _mdi._menu_set(menu_handle);
            if (old_menu_handle) {
               status=_menu_destroy(old_menu_handle);
            }
         }
      }
      _mdi._menu_adjust_help();
   }
}
#if 0
/* Could switch to different menu when different window is active. */
_str _on_activate_menu()
{
}
#endif

// Desc:  Find the first separator starting from the
//        specified position.  If found, return the
//        position of the separator.
// Retn:  0 for separator found, 1 for not found.
static int findFirstSeparator(int menu_handle, int startpos,
                              int & foundpos, boolean ignoreUserDashes = true)
{
   int itempos, mf_flags, total;
   _str caption, command;
   itempos = startpos;
   total = _menu_info(menu_handle);
   while (itempos < total) {
      _menu_get_state(menu_handle,itempos,mf_flags,"P",caption,command);
      if (caption == "-") {
         if(!ignoreUserDashes || (ignoreUserDashes && command=="-")) {
            foundpos = itempos;
            return(0);
         }
      }
      itempos++;
   }
   return(1);
}

// Desc:  Initialize the tools in the project menu.
static void initProjectTools(int menu_handle,_str lang)
{
// say('initProjectTools 1');

   // Locate the project sub menu by finding the menu
   // item for the Project Tool Wizard
   int status;
   int project_menu_handle, endPos;
   if (_menu_find(menu_handle, "project-tool-wizard", project_menu_handle,
              endPos, "M")) {
//    say('---did not find it!');
      return;
   }
   --endPos;
   startPos:=0;

   // delete everything in the first section (except for
   // the project tool wizard), which should just be build
   // tools from the last time we populated this menu
   int menupos=0;
   for (menupos=endPos; menupos>=startPos; menupos--) {
//    _menu_get_state(project_menu_handle,menupos, auto flags, 'p', auto caption);
//    say("   deleting "caption);
      _menu_delete(project_menu_handle,menupos);
   }

   _AddBuildMenuItems(project_menu_handle,startPos,lang);

   // add a submenu with all ant build file targets and/or makefile targets if any are found
   _addTargetSubmenu(project_menu_handle);

   // add a submenu for unit testing if it is enabled for this project
   _utAddBuildSubmenu(project_menu_handle);
}
/**
 *
 * @param project_menu_handle
 * @param startPos
 * @param extension
 * @param restrict  If restrict is 0, this parameter has no effect.
 *
 *                  <p>If restrict is 1, only commands which require a buffer
 *                  are inserted.
 *                  <p>If restrict is 2, only commands that don't require a buffer
 *                  are inserted.
 */
void _AddBuildMenuItems(int project_menu_handle,int startPos,_str extension, int restrict=0,_str cmdPrefix='',_str ProjectName=_project_name)
{
   // Get the tool list from the project code;
   _str toolNameList[];
   _str toolCaptionList[];
   _str toolMenuCmdList[];
   _str toolCmdList[];
   //say('initProjectTools 4');
   _projectToolGetList(toolNameList,toolCaptionList,
                       toolMenuCmdList,toolCmdList,extension,ProjectName);

   if (toolCaptionList._length() == 0) {
       _menu_insert(project_menu_handle,
                         startPos,
                         MF_GRAYED,       // flags
                         "No build tools available",  // tool name
                         "",   // command
                         "",   // category
                         "",   // help command
                         ""    // help message
                         );
       return;
   }

   //say('initProjectTools 5');
   /////////////////////////////////////////////////////////////////////////////
   //10:21am 6/28/1999
   //Changed for workspace stuff
   // Insert new tools into the menu:
   _str command="";
   _str tempCmdLine="";
   int i,menupos = startPos;
   _str prevCaption='';
   for (i=0; i<toolCaptionList._length(); ++i) {
      //say('initProjectTools here i='i);
      //say("inserting "menupos" "toolCaptionList[i]" "toolMenuCmdList[i]);
      _str helpMessage;
      helpMessage = "Runs " :+ toolNameList[i] :+" for the current project";
      int mf_flags;
      mf_flags = (toolCmdList[i]=="")?MF_GRAYED:MF_ENABLED;
      // tool caption can be blank. So don't insert it.
      if (toolCaptionList[i]!="") {
         boolean bool=true;
         if (restrict) {
            command=toolMenuCmdList[i];
            tempCmdLine=toolCmdList[i];
            tempCmdLine= stranslate(tempCmdLine,"","%%");
            bool=command=='project-compile' ||
             pos("(%f)|(%p)|(%n)|(%e)|(%c[~p])",tempCmdLine,1,"RI");
            //say('tempCmdLine='tempCmdLine' u='toolMenuCmdList[i]);
            if (restrict==2) {
               bool=!bool;
            }
            if (tempCmdLine=='') {
               bool=false;
            }
            if (toolCaptionList[i]=='-') {
               bool=(prevCaption!='-');
            }
         }
         if (bool) {
            _menu_insert(project_menu_handle,
                         menupos,
                         mf_flags,       // flags
                         toolCaptionList[i],  // tool name
                         strip(cmdPrefix' 'toolMenuCmdList[i]),   // command
                         "ncw",    // category
                         "help Build menu",  // help command
                         helpMessage       // help message
                         );
            menupos++;
            prevCaption=toolCaptionList[i];
         }
      }
   }
}

void _addTargetMenuItems(int menu_handle, int index, _str projectName, _str makefile, _str type)
{
   // if def_show_makefile_target_menu is 0 then this has been globally disabled by the user
   if(def_show_makefile_target_menu == 0) return;

   // add command to bring up target dialog
   switch (type) {
   case "ant":
      _menu_insert(menu_handle, index, 0, "Execute Ant Target(s)...", "ant_target_form " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
      break;
   case "nant":
      _menu_insert(menu_handle, index, 0, "Execute NAnt Target(s)...", "ant_target_form " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
      break;
   case "makefile":
      _menu_insert(menu_handle, index, 0, "Execute Makefile Target(s)...", "makefile_target_form " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
      break;
   }

   // add submenu for targets in this xml file
   int status, build_menu_handle, subIndex;
   switch(type) {
      case "ant":
         status = _menu_insert(menu_handle, index + 1, MF_SUBMENU, "Execute Single Ant Target", "", "targets", "", "Executes the specified ant target");
         break;
      case "nant":
         status = _menu_insert(menu_handle, index + 1, MF_SUBMENU, "Execute Single NAnt Target", "", "targets", "", "Executes the specified NAnt target");
         break;
      case "makefile":
         status = _menu_insert(menu_handle, index + 1, MF_SUBMENU, "Execute Single Makefile Target", "", "targets", "", "Executes the specified makefile target");
         break;
   }
   if(status < 0) return;

   // find the menu we just inserted
   if(_menu_find(menu_handle, "targets", build_menu_handle, subIndex, "C")) {
      return;
   }

   // get handle to targets submenu
   int targets_menu_handle;
   _menu_get_state(build_menu_handle, subIndex, 0, "P", "", targets_menu_handle, "", "", "");

   // get list of targets
   _str targetList[] = null;
   _str descriptionList[] = null;
   switch(type) {
      case "ant":
         _ant_GetTargetList(makefile, targetList, descriptionList);
         break;
      case "nant":
         _nant_GetTargetList(makefile, targetList, descriptionList);
         break;
      case "makefile":
         _makefile_GetTargetList(makefile, '', targetList, descriptionList);
         //makefile descriptions are blank, so might as well sort the target list
         targetList._sort();
         break;
   }

   // add build targets
   _str cmdPrefix = "";
   switch(type) {
      case "ant":
         cmdPrefix = "ant_execute_target";
         break;
      case "nant":
         cmdPrefix = "nant_execute_target";
         break;
      case "makefile":
         cmdPrefix = "makefile_execute_target";
         break;
   }
   int i;
   for(i = 0; i < targetList._length(); i++) {
      _menu_insert(targets_menu_handle, i, 0, targetList[i], cmdPrefix " " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile) " " targetList[i], "", "", descriptionList[i]);
   }
}

// insert the ant target menu item and submenu, if it is not already inserted
void _addTargetSubmenu(int menu_handle, _str projectName = _project_name)
{
   // if def_show_makefile_target_menu is 0 then this has been globally disabled by the user
   if(def_show_makefile_target_menu == 0 || def_show_makefile_target_menu == 2) return;

   // this loop will be run thrice.  the first 2 iterations will check for ant/NAnt xml build files
   // and the third iteration will check for makefiles
   int t;
   for(t = 0; t < 3; t++) {
      _str type = "";
      _str submenuCategory = "";
      switch(t) {
         case 0:
            type = "ant";
            submenuCategory = "ant targets";
            break;
         case 1:
            type = "nant";
            submenuCategory = "nant targets";
            break;
         case 2:
            type = "makefile";
            submenuCategory = "makefile targets";
            break;
      }

      // check to see if this project contains any files of the current type
      typeless nodeArray[] = null;
      _xmlcfg_find_simple_array(_ProjectHandle(projectName), VPJX_FILES "//F" XPATH_STRIEQ("Type", type), nodeArray);

      // if there are no files of this type, dont do anything else
      if(nodeArray._length() <= 0) continue;

      // locate the item handle and submenu handle for active configuration
      // if we added this before, delete it so it can be refreshed
      int status, build_menu_handle, index;
      if(!_menu_find(menu_handle, submenuCategory, build_menu_handle, index, "C")) {
         _menu_delete(build_menu_handle, index);
      }

      // insert just above the first separator
      int separatorIndex;
      status = findFirstSeparator(menu_handle, 0, separatorIndex, false);
      if(status) return;

      switch(type) {
         case "ant":
            status = _menu_insert(menu_handle, separatorIndex, MF_SUBMENU, "Execute Ant Target", "", submenuCategory, "", "Executes the specified ant target");
            break;
         case "nant":
            status = _menu_insert(menu_handle, separatorIndex, MF_SUBMENU, "Execute NAnt Target", "", submenuCategory, "", "Executes the specified ant target");
            break;
         case "makefile":
            status = _menu_insert(menu_handle, separatorIndex, MF_SUBMENU, "Execute Makefile Target", "", submenuCategory, "", "Executes the specified makefile target");
            break;
      }
      if(status < 0) return;

      // find the menu we just inserted
      if(_menu_find(menu_handle, submenuCategory, build_menu_handle, index, "C")) {
         return;
      }


      // get handle to targets submenu
      int targets_menu_handle;
      _menu_get_state(build_menu_handle, index, 0, "P", "", targets_menu_handle, "", "", "");


      // look for name collisions (files with the same name).  if there are name collisions,
      // the path relative to the project will be shown instead of just the filename
      boolean hasNameCollisions = false;
      int nameCollisionTable:[] = null;
      int i;
      for(i = 0; i < nodeArray._length() && i<def_max_makefile_menu; i++) {
         _str name = _xmlcfg_get_attribute(_ProjectHandle(projectName), nodeArray[i], "N");
         name = _strip_filename(name, "P");
         if(nameCollisionTable:[name] != null) {
            hasNameCollisions = true;
         }
         nameCollisionTable:[name] = 1;
      }

      // build array of files so they can be sorted
      _str makefileList[];
      int j;
      for(j = 0; j < nodeArray._length() && j<def_max_makefile_menu; j++) {
         // build path to the ant build file
         makefileList[makefileList._length()] = _RelativeToProject(_xmlcfg_get_attribute(_ProjectHandle(projectName), nodeArray[j], "N"));
      }

      // sort the array
      if(hasNameCollisions) {
         makefileList._sort("F"_fpos_case);
      } else {
         makefileList._sort("F2"_fpos_case);
      }

      int k;
      for(k = 0; k < makefileList._length(); k++) {
         _str makefile = _AbsoluteToProject(makefileList[k]);

         // get the list of targets
         _str targetList[] = null;
         _str descriptionList[] = null;
         switch(type) {
            case "ant":
               _ant_GetTargetList(makefile, targetList, descriptionList);
               break;
            case "nant":
               _nant_GetTargetList(makefile, targetList, descriptionList);
               break;
            case "makefile":
               _makefile_GetTargetList(makefile, '', targetList, descriptionList);
               //makefile descriptions are blank, so might as well sort the target list
               targetList._sort();
               break;
         }

         // if there is more than one file, add a submenu for each file
         int target_menu_handle = targets_menu_handle;
         if(nodeArray._length() > 1) {
            _str strippedFilename = "";
            if(hasNameCollisions) {
               strippedFilename = _RelativeToProject(makefile, projectName);
            } else {
               strippedFilename = _strip_filename(makefile, "P");
            }
            status = _menu_insert(targets_menu_handle, k, MF_SUBMENU, strippedFilename, "", "makefiles", "", "");
            if(status < 0) return;

            // get the handle of the submenu that we just inserted
            _menu_get_state(targets_menu_handle, k, 0, "P", "", target_menu_handle, "", "", "");
         }

         // add command to bring up target dialog and a separator
         _str dlgCmdPrefix = "";
         _str cmdPrefix = "";
         switch(type) {
            case "ant":
               dlgCmdPrefix = "ant_target_form";
               cmdPrefix = "ant_execute_target";
               break;
            case "nant":
               dlgCmdPrefix = "ant_target_form";
               cmdPrefix = "nant_execute_target";
               break;
            case "makefile":
               dlgCmdPrefix = "makefile_target_form";
               cmdPrefix = "makefile_execute_target";
               break;
         }
         _menu_insert(target_menu_handle, 0, 0, "Select Multiple Targets...", dlgCmdPrefix " " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
         _menu_insert(target_menu_handle, 1, 0, "-");

         // add targets to the submenu
         int m;
         for(m = 0; m < targetList._length(); m++) {
            status = _menu_insert(target_menu_handle, m + 2, 0, targetList[m], cmdPrefix " " maybe_quote_filename(projectName) " " maybe_quote_filename(makefile) " " targetList[m], "", "", descriptionList[m]);
         }
      }
   }
}

void _on_popup_ext_menu_default(_str menu_name,int menu_handle)
{
   if (isEclipsePlugin()) {
      int submenu_handle=0;
      int submenu_pos=0;
      int status=_menu_find(menu_handle,'version-control',submenu_handle,submenu_pos,'C');
      if (!status) {
         _menu_delete(submenu_handle,submenu_pos);
         if (submenu_pos<_menu_info(menu_handle)) {
            int mf_flags;
            _str caption;
            _menu_get_state(menu_handle,submenu_pos,mf_flags,'P',caption);
            if (caption=='-') {
               _menu_delete(menu_handle,submenu_pos);
            }
         }
      }
   }

   // remove Imports if we're not looking at a java project
   if(!_isEditorCtl(false) || !(_LanguageInheritsFrom('java') || strieq(p_EmbeddedLexerName,"java"))) {
      int submenu_handle=0;
      int submenu_pos=0;
      int status=_menu_find(menu_handle,'imports',submenu_handle,submenu_pos,'C');
      if (!status) {
         _menu_delete(submenu_handle,submenu_pos);
         if (submenu_pos<_menu_info(menu_handle)) {
            int mf_flags;
            _str caption;
            _menu_get_state(menu_handle,submenu_pos,mf_flags,'P',caption);
            if (caption=='-') {
               _menu_delete(menu_handle,submenu_pos);
            }
         }
      }
   }

   // populate refactoring submenu
   addRefactoringMenuItemsForCurrentSymbol(menu_handle);
}

void _on_init_menu()
{
   //say('_on_init_menu');
   int old_wid=p_window_id;
   p_window_id=_mdi._edit_window();
   int menu_handle=_mdi.p_menu_handle;
   int no_child_windows=_no_child_windows();
   // Initialize the project tools in the project menu:
   initProjectTools(menu_handle,_no_child_windows()?"":_mdi.p_child.p_LangId);
   call_list('-init-menu-',menu_handle,no_child_windows);

   /*status=_menu_get_state(menu_handle,'project-build',mf_flags,'M');
   if (!status) {
      say('build='(mf_flags&MF_GRAYED)' e='(mf_flags&MF_ENABLED));
   }
   */
   p_window_id=old_wid;
}

/** 
 * Find's the _OnUpdate_ hook function for the given command 
 * and returns it's callable names table index. 
 * <p> 
 * Parses the command out from the command line, and also 
 * will compensate for commands which are in namespaces. 
 * 
 * @param targetCmdLine    Slick-C command line string
 * 
 * @return index of _OnUpdate_ function, 0 if no such function 
 *         or if the function is not callable.
 */
int _findOnUpdateForCommand(_str targetCmdLine)
{
   _str targetNS="";
   _str targetCmd="";
   parse targetCmdLine with targetCmd .;
   int dot_pos = lastpos('.',targetCmd);
   if (dot_pos > 0) {
      targetNS = substr(targetCmd,1,dot_pos);
      targetCmd = substr(targetCmd,dot_pos+1);
   }
   int index=find_index(targetNS:+'_OnUpdate_':+targetCmd,PROC_TYPE);
   if (index_callable(index)) return index;
   return 0;
}
static  _str gtoolMenuCmdList[];
static _str gtoolCmdList[];
int _OnUpdateProjectCommand(CMDUI &cmdui,int target_wid,_str command)
{
   if(isEclipsePlugin()){
      return MF_ENABLED;
   }

   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_ALLOW_PROJECT_SUPPORT)) {
      return(MF_GRAYED);
   }

   // if there is no project and no files open, then don't bother
   if (_project_name=='' && _no_child_windows()) {
      return(MF_GRAYED);
   }

   _str cmdname="";
   _str name="";
   parse command with cmdname name;
   cmdname=translate(cmdname,'_','-');
   if (name!="") {
      if (cmdname:!='project_usertool') {
         // Not sure whats going on here
         if (cmdui.menu_handle) {
            return(0);
         }
         return(MF_ENABLED);
      }
      /* 
         IF this tool reference is a Slick-C&reg; tool, call the on update for
         the Slick-C&reg; command.  We need an interface for non-Slick-C
         commands to do this.   
         _OnUpdate_project_usertool__<tool name>_<type>
      */
      if (_project_name!='') {
         int handle=_ProjectHandle(_project_name);
         int targetNode=_ProjectGet_TargetNode(handle,name);
         _str type=_ProjectGet_TargetType(handle,targetNode);
         if (strieq(type,'Slick-C')) {
            _str targetCmdLine=_ProjectGet_TargetCmdLine(handle,targetNode,true);
            int index=_findOnUpdateForCommand(targetCmdLine);
            if (index_callable(index)) {
               return(call_index(cmdui,target_wid,targetCmdLine,index));
            }

         }
      }
   }
   command=translate(command,'_','-');
   int i=0;
   for (i=0; i<gtoolMenuCmdList._length(); ++i) {
      //say("inserting "menupos" "toolCaptionList[i]" "toolMenuCmdList[i]);
      if (lowcase(translate(gtoolMenuCmdList[i],'_','-'))==lowcase(command)) {
         if (cmdui.menu_handle) {
            return(0);
         }
         /*if(command=='project_compile') {
            say('command='command' c='gtoolCmdList[i]);
         } */
         //if (debug && gtoolCmdList[i]!="") say('enable');
         return((gtoolCmdList[i]=="")?MF_GRAYED:MF_ENABLED);
      }
   }
   if (cmdui.menu_handle) {
      //say('h3 cmd='command);
      return(0);
   }
   return(MF_GRAYED);
}
static int gRequireFlags;
static int GetRequireFlags(int req_flags)
{
   if (req_flags & VSARG2_REQUIRES_CLIPBOARD) {
      if ( _HaveClipboard() ) {
         gRequireFlags|=VSARG2_REQUIRES_CLIPBOARD;
      }
   }
   return(gRequireFlags);
}
void _OnUpdateInit(CMDUI &cmdui,int target_wid)
{
   if (cmdui.button_wid /*|| !cmdui.inMenuBar*/) {
      _str toolNameList[];
      _str toolCaptionList[];
      _projectToolGetList(toolNameList,toolCaptionList,
                         gtoolMenuCmdList,gtoolCmdList,_no_child_windows()?"":_mdi.p_child.p_LangId);
      /*for (i=0; i<toolCaptionList._length(); ++i) {
         say('n='toolNameList[i]' c='toolCaptionList[i]' mc='toolMenuCmdList[i]' cm='toolCmdList[i]);
      } */
   }

   int orig_wid=0;
   gRequireFlags=0;
   if (target_wid && target_wid._isEditorCtl()) {
      orig_wid=p_window_id;
      p_window_id=target_wid;

      gRequireFlags|=VSARG2_REQUIRES_MDI_EDITORCTL;
      if (select_active2()) {
         gRequireFlags|=VSARG2_REQUIRES_AB_SELECTION;
      }
      if (p_UTF8) {
         gRequireFlags|=VSARG2_REQUIRES_UNICODE_BUFFER;
      }
      if (p_LangId == "fileman") {
         gRequireFlags|=VSARG2_REQUIRES_FILEMAN_MODE;
      }
      if (_istagging_supported() ) {
         gRequireFlags|=VSARG2_REQUIRES_TAGGING;
      }
      p_window_id=orig_wid;
   }
   int seltype=_select_type();
   if ( seltype:=='BLOCK') {
      gRequireFlags|=VSARG2_REQUIRES_BLOCK_SELECTION;
   }
   if ( seltype ) {
      gRequireFlags|=VSARG2_REQUIRES_SELECTION;
   }
   int apiflags=_default_option(VSOPTION_APIFLAGS);
   if (apiflags & VSAPIFLAG_MDI_WINDOW) {
      gRequireFlags|=VSARG2_REQUIRES_MDI;
   }
   if (apiflags & VSAPIFLAG_ALLOW_PROJECT_SUPPORT) {
      gRequireFlags|=VSARG2_REQUIRES_PROJECT_SUPPORT;
   }
   if (apiflags & VSAPIFLAG_ALLOW_MINMAXRESTOREICONIZE_WINDOW) {
      gRequireFlags|=VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW;
   }
   if (apiflags & VSAPIFLAG_ALLOW_TILED_WINDOWING) {
      gRequireFlags|=VSARG2_REQUIRES_TILED_WINDOWING;
   }
   if (apiflags & VSAPIFLAG_ALLOW_JGUI_SUPPORT) {
      gRequireFlags|=VSARG2_REQUIRES_GUIBUILDER_SUPPORT;
   }
}

int _OnUpdateDefault(CMDUI &cmdui,int target_wid,_str command)
{
   _str cmdname="";
   parse command with cmdname .;  // strip arguments
   int index=find_index(cmdname,COMMAND_TYPE);
   typeless flags=0;
   if (index) {
      parse name_info(index) with ',' flags;
      if (!isinteger(flags)) flags=0;
   }

   // if it is a menu item, we look for a check mark
   int checked_flag=0;
   if (cmdui.menu_handle) {
      int temp_mf_flags=0;
      _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,temp_mf_flags,'P');
      checked_flag=temp_mf_flags&MF_CHECKED;
   }

   // if we are on the command line
   if ((flags & (VSARG2_CMDLINE|VSARG2_TEXT_BOX)) && target_wid==_cmdline) {
      return(MF_ENABLED|checked_flag);
   }

   // these are our requirement flags for this command
   int req_flags=flags&VSARG2_REQUIRES;

   // some arguments require a file, so we need the editor window to have focus
   if (cmdui.button_wid) {
      _str tempCmdLine = stranslate(command,"","%%");
      if(pos("(%f)|(%l)|(%c)",tempCmdLine,1,"RI")) {
         req_flags|=VSARG2_REQUIRES_MDI_EDITORCTL;
      }
   }

   // for text boxes only
   if (target_wid && target_wid.p_object==OI_TEXT_BOX && (flags & VSARG2_TEXT_BOX)) {
      if ((flags & VSARG2_REQUIRES_UNICODE_BUFFER) && !_UTF8()) {
         return(MF_GRAYED|checked_flag);
      }

      // do we have a selection?
      if (flags & VSARG2_REQUIRES_AB_SELECTION) {
         int start_sel=0, end_sel=0;
         target_wid._get_sel(start_sel,end_sel);
         if (start_sel==end_sel) {
            return(MF_GRAYED|checked_flag);
         }
      }

      // do we have a clipboard?
      if ((flags & VSARG2_REQUIRES_CLIPBOARD) &&
          !(GetRequireFlags(req_flags)& VSARG2_REQUIRES_CLIPBOARD)) {
         return(MF_GRAYED|checked_flag);
      }
      if (target_wid.p_ReadOnly && !(flags & VSARG2_READ_ONLY)) {
         return(MF_GRAYED|checked_flag);
      }

      // Could check for requires selection here
      return(MF_ENABLED|checked_flag);
   }

   // IF everything that is required isn't there
   if ((req_flags & GetRequireFlags(req_flags))!=req_flags){
      return(MF_GRAYED|checked_flag);
   }

   // IF an editor control is required
   if (((req_flags & VSARG2_REQUIRES_MDI_EDITORCTL) &&
         ( (target_wid.p_window_state=='I' && !(flags & VSARG2_ICON)) ||
           (target_wid._isEditorCtl() && target_wid._QReadOnly() && !(flags & VSARG2_READ_ONLY))
         )
        )
       ) {
      return(MF_GRAYED|checked_flag);
   }
   // IF any required flags were specified
   if (req_flags) {
      return(MF_ENABLED|checked_flag);
   }
   return(0);
}

int _OnUpdate(CMDUI &cmdui,int target_wid,_str command)
{
   // Special case for list boxes and combo boxes.
   if (target_wid) {
      if (target_wid.p_object == OI_LIST_BOX ||
          target_wid.p_object == OI_COMBO_BOX) {
         return(0);
      }
   }
   int index = _findOnUpdateForCommand(command);
   if (cmdui.menu_handle && cmdui.inMenuBar) {
      _menu_set_binding(cmdui.menu_handle,cmdui.menu_pos);
   }
   typeless status=0;
   if (index_callable(index)) {
      if (target_wid) {
         p_window_id=target_wid;
         status=call_index(cmdui,target_wid,command,index);
      } else {
         status=call_index(cmdui,target_wid,command,index);
      }
      return(status);
   }
   return(_OnUpdateDefault(cmdui,target_wid,command));
}
_str _Noficons()
{
   if (_no_child_windows()) {
      return(0);
   }
   int Noficons=0;
   int first_window_id=p_window_id;
   for (;;) {
      _next_window('hr');
      if ( ! (p_window_flags & HIDE_WINDOW_OVERLAP) && p_window_state=='I' ) {
         Noficons=Noficons+1;
      }
      if ( p_window_id:==first_window_id ) {
         return(Noficons);
      }
   }

}
/** 
 * @return Returns the number of non-hidden buffers.  The active MDI edit 
 * window buffer is always counted even if it is hidden.  This means 
 * this function will still return 1 for the number of buffers.  
 * Use _no_child_windows to check whether there are no child edit windows.
 * 
 * @categories Buffer_Functions
 * 
 */
int _Nofbuffers(int maxcount=MAXINT)
{
   typeless buf_flags=0;
   typeless buf_info=0;
   typeless buf_id=0;
   typeless modify=0;
   _str buf_name="";
   int orig_wid= p_window_id;
   p_window_id= _mdi.p_child;
   int Nofbuffers=1;   /* Always count active buffer.  Might be hidden buffer. */
   int first_buf_id=p_buf_id;
   for (buf_info=buf_match('',1,'v');;) {
      if (rc) {
         return(Nofbuffers);
      }
      parse buf_info with buf_id modify buf_flags buf_name;
      if (buf_id!=first_buf_id) {
         ++Nofbuffers;
         if (Nofbuffers>=maxcount) {
            return(Nofbuffers);
         }
      }
      buf_info=buf_match('',0,'v');
   }
   p_window_id=orig_wid;
}

/** 
 * If <i>file_spec</i> is null, a path search for <i>file_no_path</i> is 
 * performed and the result is stored in <i>file_spec</i>.
 * 
 * @return Returns 0 if successful.  Otherwise 1 is returned.
 * 
 * @categories File_Functions
 * 
 */
_str maybe_find_file(var file_spec,_str file_no_path)
{
  if ( file_spec=='' ) {
    file_spec=slick_path_search(file_no_path);
    if ( file_spec=='' ) {
      _message_box(nls("File '%s' not found",file_no_path)". ");
      return(1);
    }
    file_spec=maybe_quote_filename(absolute(file_spec));
  }
  return(0);
}

/**
 * If no parameters are specified, the <b>Open Menu dialog box</b> is 
 * displayed.  Existing menus may be edited and new menus may be created.  Use 
 * the <b>-show</b> option followed by the menu name to run a menu as a pop-up 
 * menu.  The <b>-new</b> option allows you to create a new menu and optional 
 * specify the name of the new menu.
 * 
 * @param cmdline is a  string in the format: [-show <i>menu_name</i>|
 * -new [<i>menu_name</i>]]
 * 
 * @categories Menu_Functions
 * 
 */
_command void open_menu(_str result="") name_info(MENU_ARG','VSARG2_EDITORCTL)
{
   int was_recording=_macro();
   if(result==''){
      result=_list_matches2(
                     'Open Menu',   // title
                     SL_VIEWID|SL_COMBO|SL_SELECTPREFIXMATCH|SL_DEFAULTCALLBACK|SL_MATCHCASE,        // flags
                     '&Open...,&New...,&Delete,&Show...,&Reset',                   // buttons
                     'open menu dialog box',   // help_item
                     '',       // font
                     _open_menu_callback, //callback
                     'open_menu',       // retrieve_name
                     MENU_ARG); // completion
      if (result=='') {
         return;
      }
   }
   _str menu="";
   _str option="";
   _macro('m',was_recording);
   _macro_delete_line();
   parse result with option menu ;
   if (lowcase(option)=='-show') {
      _macro_call('mou_show_menu',menu);
      show(menu);
      return;
   }
   _macro_call('show','-desktop _menu_editor_form',result);
   result=show('-desktop _menu_editor_form',result);
}
static _str _open_menu_callback(int reason,var result,typeless key)
{
   if (reason==SL_ONDEFAULT) {  // Enter key
      // Make sure that valid id characters are used.
      result=_sellist._lbget_seltext();
      if (result=='') {
         result=_sellistcombo.p_text;
      }
      if (!isid_valid(result)) {
         _message_box(nls('Invalid identifier'));
         return('');
      }
      result='-new 'result;
      return(1);
   }
   typeless status=0;
   if (reason==SL_ONINIT) {
      _sellist._lbtop();
      status=_sellist._lbsearch("*");
      if (!status) {
         _sellist._lbdelete_item();
         _sellist._lbtop();
      }
   }
   _str text="";
   if (reason==SL_ONSELECT) {
      text=strip(_sellistcombo.p_text);

      // we don't allow deletion of some menus
      if (name_eq(translate(_MDIMENU,'_','-'),text)) {
         b5.p_enabled=0;
      } else {
         b5.p_enabled=1;
      }

      // see if this menu can be reset to its original form
      installVerIndex := find_index(text :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU));
      b7.p_enabled = (installVerIndex > 0);
   }
   if (reason!=SL_ONUSERBUTTON) {
      return('');
   }
   _str menuname="";
   int linenum=0;
   switch (key) {
   case 4:  // New
      result='-new';
      return(1);
#if 0
      result=_sellistcombo.p_text;
      if (result!='' && !isid_valid(result)) {
         _message_box(nls('Invalid identifier'))
         return('');
      }
      result='-new 'result;
      return(1);
#endif
   case 5:  // Delete
      menuname=strip(_sellistcombo.p_text);
      // Don't want cursor y to change. _lbsearch changes cursor y
      typeless p;
      _sellist.save_pos(p);
      status=_sellist._lbsearch(menuname);
      if (status) {
         _message_box(nls('Menu not found'));
         return('');
      }
      result=_message_box(nls("Delete menu '%s'.  Are you sure? ",menuname),'',MB_ICONQUESTION|MB_YESNOCANCEL);
      if (result!=IDYES) {
         return('');
      }
      linenum=_sellist.p_line;
      _sellist.restore_pos(p);
      _sellist.p_line=linenum;
      _sellist._lbdelete_item();
      _macro('m',_macro('s'));
      _macro_append('index=find_index('_quote(menuname)',oi2type(OI_MENU));');
      _macro_append('if (index) delete_name(index);');
      _macro_append('_config_modify_flags(CFGMODIFY_SYSRESOURCE|CFGMODIFY_RESOURCE);');
      int index=find_index(menuname,oi2type(OI_MENU));
      if (index) {
         _set_object_modify(index);
         _config_modify_flags(CFGMODIFY_DELRESOURCE);
         delete_name(index);
      }
      return('');
      break;
   case 6:  // Show
      result=strip(_sellistcombo.p_text);
      _sellist.save_pos(p);
      status=_sellist._lbsearch(result);
      if (status) {
         _message_box(nls('Menu not found'));
         return('');
      }
      _sellist.restore_pos(p);
      result='-show 'result;
      return(1);
      break;
   case 7:  // Reset
      menuname = strip(_sellistcombo.p_text);
      reset_menu(menuname);  
      break;
   }
   return('');
}
void _menu_mdi_update()
{
   if (_cur_mdi_menu=="") {
      return;
   }
   //messageNwait('_menu_mdi_update');
   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return;
   _sr_filehist();
   _srg_workspace();

   int index=find_index(_cur_mdi_menu,oi2type(OI_MENU));
   if (index) {
      int menu_handle=_mdi._menu_load(index);
      if (menu_handle<0) {
         _message_box(nls("Unable to load MDI menu.  ")get_message(menu_handle));
         activate_window(orig_view_id);
         return;
      }
      int old_menu_handle=_mdi.p_menu_handle;
      //_mdi._menu_set(0);
      //if (old_menu_handle) _menu_destroy(old_menu_handle);
#if 0 //__UNIX__
      maybe_delete_softbench_menu(menu_handle);
#endif
      _mdi._menu_set(menu_handle);
      _mdi._menu_adjust_help();
      if (old_menu_handle) _menu_destroy(old_menu_handle);
      top();up();
      for (;;) {
         if (down()) break;
         _str line="";
         get_line(line);
         _str orig_line=line;
         int linenumber=p_line;
         _str rtype="";
         parse line with rtype line;
         _str name='_sr_'strip(lowcase(rtype),'',':');
         index=find_index(name,PROC_TYPE);
         if ( !index_callable(index) ) {
            name='_srg_'strip(lowcase(rtype),'',':');
            index=find_index(name,PROC_TYPE);
         }
         if ( index_callable(index) ) {
            typeless status=call_index('R',line,index);
            if ( status ) {
               _delete_temp_view();
               activate_window(orig_view_id);
               return;
            }
            activate_window(temp_view_id);
         } else {
            /* Skip over lines that can't be processed. */
            typeless count=0;
            parse line with count .;
            /*if (!isinteger(count) || count<0) {
               _message_box('orig_line='orig_line' linenumber='linenumber);
               _showbuf(p_window_id);

            } */
            down(count);
         }
      }

      menu_mdi_bind_all();
   }
   _delete_temp_view();
   activate_window(orig_view_id);
}

/**
 * Find a submenu by its category
 * 
 * @param menu_handle
 *                 Handle of parent menu to search
 * @param category Category of submenu to find
 * @param submenu_handle
 *                 (output) Handle to submenu
 * 
 * @return <0 if not found, submenu index if found
 */
int _menu_find_loaded_menu_category(int menu_handle,_str category,int &submenu_handle=0)
{
   int i, Nofitems=_menu_info(menu_handle,'c');
   for (i=0;i<Nofitems;++i) {
      _str item_cap, item_cat, item_cmd;
      int mf_flags=0;
      _menu_get_state(menu_handle,i,mf_flags,'p',item_cap,submenu_handle,item_cat,item_cmd);
      if (strieq(item_cat,category)) {
         return(i);
      }
   }
   return(-1);
}

/**
 * Find a submenu by its caption
 * 
 * @param menu_handle
 *                 Handle of parent menu to search
 * @param caption  Caption of submenu to find
 * @param submenu_handle
 *                 (output) Handle to submenu
 * 
 * @return <0 if not found, submenu index if found
 */
int _menu_find_loaded_menu_caption(int menu_handle,_str caption,int &submenu_handle=0)
{
   int i, Nofitems=_menu_info(menu_handle,'c');
   for (i=0;i<Nofitems;++i) {
      _str item_text;
      int mf_flags=0;
      _menu_get_state(menu_handle,i,mf_flags,'p',item_text,submenu_handle);
      item_text=stranslate(item_text,'','&');
      if (strieq(item_text,caption)) {
         return(i);
      }
   }
   return(-1);
}
int _menu_find_caption(int menu_index,_str menu_text)
{
   if (menu_index > 0) {
      int child=menu_index.p_child;
      if (child) {
         int firstchild=child;
         for (;;) {
            _str item_text=stranslate(child.p_caption,'','&');
            if (strieq(item_text,menu_text)) {
               return(child);
            }
            child=child.p_next;
            if (child==firstchild) {
               break;
            }
         }
      }
   }
   return(0);
}

// Add the EBCDIC table menu item into the Tools menu.
static void s390addEbcdicTable(int menu_handle, int no_child_windows)
{
   // Locate the Tools sub menu.
   int status;
   int tools_menu_handle, itempos;
   if (_menu_find(menu_handle, "ascii-table", tools_menu_handle,
                  itempos, "M")) {
      return;
   }

   // If there is already an item for EBCDIC table, do nothing.
   int foundPos;
   int tempMenu;
   if (!_menu_find(tools_menu_handle, "ebcdic-table", tempMenu,
                   foundPos, "M")) {
      return;
   }

   // Add "EBCDIC table" to the Tools menu, right after the ASCII table.
   if (_menu_find(tools_menu_handle, "ascii-table", tempMenu,
                  foundPos, "M")) {
      // Did not find the ASCII table item... Very odd.
      // So just hardcode the position.
      foundPos = 5;
   }
   _menu_insert(tools_menu_handle,
                foundPos + 1, // insert after the ASCII table item
                MF_ENABLED,  // flags
                "Ebcdic &Table",  // tool name
                "ebcdic-table",   // command
                "ncw",    // category
                "help Tools menu",  // help command
                "Opens EBCDIC table file"       // help message
                );
}

// Add the data set utilities to the menu.
static void s390addUtilities(int menu_handle, int no_child_windows)
{
   // Locate the File sub menu.
   int status;
   int file_menu_handle, itempos;
   if (_menu_find(menu_handle, "gui-write-selection", file_menu_handle,
                  itempos, "M")) {
      return;
   }

   // If there is already an item for data set utilities, do nothing.
   int foundPos;
   int tempMenu;
   if (!_menu_find(file_menu_handle, "show -app -xy _datasetutil_form", tempMenu,
                   foundPos, "M")) {
      return;
   }

   // Add new item the File menu, right after the "Write-selection".
   if (_menu_find(file_menu_handle, "gui-write-selection", tempMenu,
                  foundPos, "M")) {
      // Did not find the item... Very odd.
      // So just hardcode the position.
      foundPos = 13;
   }
   _menu_insert(file_menu_handle,
                foundPos + 1, // insert after the "Write selection"
                MF_ENABLED,  // flags
                "&Data Sets Utilities...",   // tool name
                "show -app -xy _datasetutil_form",   // command
                "ncw",    // category
                "help File menu",  // help command
                "Opens data set utilities"  // help message
                );
   _menu_insert(file_menu_handle,
                foundPos + 2, // insert after the "Write selection"
                MF_ENABLED,  // flags
                "&Job Utilities...",   // tool name
                "show -app -xy _jobutil_form",   // command
                "ncw",    // category
                "help File menu",  // help command
                "Opens job utilities"  // help message
                );
}

// Add the OS/390 Optimization menu item into the Configuration menu.
static void s390addOptimization2(int config_menu_handle)
{
   // If item is already there, do nothing more.
   int foundPos;
   int tempMenu;
   if (!_menu_find(config_menu_handle, "show -modal _s390opt_form",
                   tempMenu, foundPos, "M")) {
      return;
   }

   // Add the OS/390 Optimization menu item into the Config menu.
   _menu_insert(config_menu_handle,
                -1, // insert as the last menu item
                MF_ENABLED,  // flags
                "OS/&390 Optimizations...",  // tool name
                "show -modal _s390opt_form",   // command
                "ncw",    // category
                "help OS/390 Optimizations",  // help command
                "Lets you change OS/390 optimization options"       // help message
                );
}

/**
 * Add the OS/390 Job Statement menu item into the Configuration menu.
 *
 * @param config_menu_handle
 */
static void s390addJobcard2(int config_menu_handle)
{
   // If item is already there, do nothing more.
   int foundPos;
   int tempMenu;
   if (!_menu_find(config_menu_handle, "show -modal _jobcard_form",
                   tempMenu, foundPos, "M")) {
      return;
   }

   // Add the OS/390 Job Statement menu item into the Config menu.
   _menu_insert(config_menu_handle,
                -1, // insert as the last menu item
                MF_ENABLED,  // flags
                "JCL &Job Statement...",  // tool name
                "show -modal _jobcard_form",   // command
                "ncw",    // category
                "help OS/390 JCL Job Statement",  // help command
                "Changes your OS/390 Job Statement"       // help message
                );
}

/**
 * Add the OS/390 Job Statement menu item into the Configuration menu,
 * given the menubar handle.
 *
 * @param menu_handle
 * @param no_child_windows
 */
static void s390addJobcard(int menu_handle, int no_child_windows)
{
   // Locate the Configuration sub menu.
   int config_menu_handle, itempos;
   if (_menu_find(menu_handle, "config", config_menu_handle, itempos, "M")) {
      return;
   }

   // Add item into the Config menu
   s390addJobcard2(config_menu_handle);
}

// Add the OS/390 Optimization menu item into the Configuration menu.
static void s390addOptimization(int menu_handle, int no_child_windows)
{
   // Locate the Configuration sub menu.
   int config_menu_handle, itempos;
   if (_menu_find(menu_handle, "config", config_menu_handle, itempos, "M")) {
      return;
   }

   // Add item into the Config menu
   s390addOptimization2(config_menu_handle);
}

// Add/Remove certain menu items for OS/390 runtime environment.
void _init_menu_s390(int menu_handle, int no_child_windows)
{

#if __OS390__ || __TESTS390__
   // Add the EBCDIC table item.
   s390addEbcdicTable(menu_handle, no_child_windows);
   // Add the S/390 optimization item.
   s390addOptimization(menu_handle, no_child_windows);
#endif
   if (_DataSetSupport()) {
      // Add the OS/390 Job Statement item.
      s390addJobcard(menu_handle, no_child_windows);

      // Add the Data set utilities item.
      s390addUtilities(menu_handle, no_child_windows);
   }
}

/**
 * Look for the menu item with caption and, if found, remove it.
 * This works for submenus too, and will fix up the case where you
 * remove the last item in between menu separators (hyphens).
 * 
 * @param menu_handle Handle of menu to search. Use _menu_find or
 *                    _menu_find_loaded_menu_caption.
 * @param caption     Menu item caption to search for.
 */
void _menuRemoveItemByCaption(int menu_handle, _str caption)
{
   int submenu_handle=0;
   int index = _menu_find_loaded_menu_caption(menu_handle,caption,submenu_handle);
   if( index<0 ) {
      return;
   }
   _menu_delete(menu_handle,index);
   _menuRemoveExtraSeparators(menu_handle, index);
}

void _menuRemoveExtraSeparators(int menu_handle, int index)
{
   // If we just deleted the last item out of a section bracketed by separators,
   // then remove the extra separator.
   boolean at_bottom = true;
   _str cap_below = "";
   int nofitems = _menu_info(menu_handle);
   if( index<nofitems ) {
      at_bottom=false;
      int mf_flags=0;
      _menu_get_state(menu_handle,index,mf_flags,'P',cap_below);
   }
   boolean at_top = true;
   _str cap_above = "";
   if( index>0 ) {
      at_top=false;
      int mf_flags=0;
      _menu_get_state(menu_handle,index-1,mf_flags,'P',cap_above);
   }
   if( at_bottom && cap_above=="-" ) {
      // Do not want a lone separator at bottom of menu
      _menu_delete(menu_handle,index-1);
   } else if( at_top && cap_below=="-" ) {
      // Do not want a lone separator at top of menu
      _menu_delete(menu_handle,index);
   } else if( cap_below=="-" && cap_above=="-" ) {
      // Do not double separators in the middle of the menu,
      // delete the separator that was immediately below the
      // deleted item.
      int status = _menu_delete(menu_handle,index);
   }
}

/**
 * Look for the menu item with from_caption and, if found, rename
 * it to to_caption. This works for submenus too.
 * 
 * @param menu_handle  Handle of menu to search. Use _menu_find or
 *                     _menu_find_loaded_menu_caption.
 * @param from_caption Rename from menu item caption
 * @param to_caption   Rename to menu item caption
 */
void _menuRenameItemByCaption(int menu_handle, _str from_caption, _str to_caption)
{
   int submenu_handle=0;
   int index = _menu_find_loaded_menu_caption(menu_handle,from_caption,submenu_handle);
   if( index<0 ) {
      return;
   }
   int mf_flags = 0;
   _str caption="", command="", category="", help_command="", help_message="";
   _menu_get_state(menu_handle,index,mf_flags,'P',caption,command,category,help_command,help_message);
   _menu_set_state(menu_handle,index,mf_flags,'P',to_caption,command,category,help_command,help_message);
}


/**
 * Remove SlickEdit-specific items that OEMs do not want to see.
 * 
 * @param menu_handle
 * @param no_child_windows
 */
void _init_menu_oem(int menu_handle, int no_child_windows)
{
   concurrent := (_LicenseType() == LICENSE_TYPE_CONCURRENT);

   if( !(_OEM() || _trial() || concurrent) ) {
      // Not an OEM or trial, so bail
      return;
   }

   int submenu_handle = 0;
   _str caption = "";
   int index = -1;

   //
   // Help menu
   //

   caption="Help";
   index=_menu_find_loaded_menu_caption(menu_handle,caption,submenu_handle);
   if( index<0 ) {
      return;
   }

   // these things are disabled for all of them...
   if (!concurrent) {
      _menuRemoveItemByCaption(submenu_handle,"Register Product...");
   }

   _menuRemoveItemByCaption(submenu_handle,"Check Maintenance");

   // this if for OEMs only - we still want trial customers to have them
   if( _OEM()) {
      _menuRemoveItemByCaption(submenu_handle,"SlickEdit Support Web Site");
      _menuRemoveItemByCaption(submenu_handle,"License Manager...");
      _menuRemoveItemByCaption(submenu_handle,"Contact Product Support");
      _menuRemoveItemByCaption(submenu_handle,"Product Updates");
   } else {
      // we are keeping part of the product updates menu, but not all of it
      caption="Product Updates";
      index=_menu_find_loaded_menu_caption(submenu_handle,caption,submenu_handle);
      if( index<0 ) {
         return;
      }

      _menuRemoveItemByCaption(submenu_handle,"New Updates...");
      _menuRemoveItemByCaption(submenu_handle,"Options...");
   }

}

int _menu_insert_submenu(int menu_handle,int menu_pos,int index,_str caption,
                         _str categories,_str help_command,_str help_message )
{
   menu_handle=_menu_insert(menu_handle,menu_pos,MF_SUBMENU,caption,'',categories,help_command,help_message);

   int child=index.p_child;
   if (child) {
      int first_child=child;
      for (;;) {
         if (child.p_object==OI_MENU) {
            _menu_insert_submenu(menu_handle,-1,child,child.p_caption,child.p_categories,child.p_help,child.p_message);
         } else {
            _menu_insert(menu_handle,-1,0,
                         child.p_caption,
                         child.p_command,
                         child.p_categories,
                         child.p_help,
                         child.p_message
                        );
         }
         child=child.p_next;
         if (child==first_child) break;
      }
   }
   return(menu_handle);
}

void _menu_add_windowhist(int wid)
{
   //call_list("_MenuAddFileHist_",filename);
   if (!def_max_windowhist || !_mdi.p_menu_handle) return;
   //say('add wid='wid' 'wid._BufName2Caption());
   boolean doMRU=_default_option(VSOPTION_NEXTWINDOWSTYLE)!=0;
   int count=gLRUWindowList._length();
   int i;
   for (i=count-1;i>=0;--i) {
      if (gLRUWindowList[i]==wid) {
         if (doMRU) {
            if (i==count-1) return;
            for (;i<count-1;++i) {
               gLRUWindowList[i]=gLRUWindowList[i+1];
            }
            gLRUWindowList[count-1]=wid;
            return;
         }
         int n=count-i-1;
         if (n<def_max_windowhist) {
            return;
         }
         for (;i<count-1;++i) {
            gLRUWindowList[i]=gLRUWindowList[i+1];
         }
         --count;
         break;
      }
   }
   if (doMRU) {
      gLRUWindowList[count]=wid;
   } else {
      if (count<def_max_windowhist) {
         for (i=count;i>0;--i) {
            gLRUWindowList[i]=gLRUWindowList[i-1];
         }
         gLRUWindowList[0]=wid;
         return;
      }
      gLRUWindowList[count]=wid;
   }

   //say('add wid='wid' 'wid._BufName2Caption());
   //_menu_add_hist(wid._BufName2Caption(),_mdi.p_menu_handle,'&Window','','activate_wid 'wid,'ncw',
   //               '','',_default_option(VSOPTION_NEXTWINDOWSTYLE)!=0,wid,true);
}
void _menu_remove_windowhist(int wid) {
   if (!def_max_windowhist || !_mdi.p_menu_handle) return;
   //say('remove wid='wid);
   int count=gLRUWindowList._length();
   int i;
   for (i=count-1;i>=0;--i) {
      if (gLRUWindowList[i]==wid) {
         gLRUWindowList._deleteel(i);
         return;
      }
   }
   //_menu_remove_hist('',_mdi.p_menu_handle,'&Window','','activate_wid 'wid,'ncw',
   //               '','',wid,true);

}


void _init_menu_windowlist(int menu_handle,int no_child_windows)
{
   //gMRUWindowList;
   _str submenu_pos='&Window';
   int status=1;
   int mh=menu_handle;
   int mf_flags;
   _str item_text;
   int Nofitems=_menu_info(mh,'c');
   typeless file_mh=0;
   int i;
   for (i=0;i<Nofitems;++i) {
     _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
     if (strieq(item_text,submenu_pos)) {
        status=0;
        break;
     }
   }
   if (status) {
      return; // Couldn't find &Window menu
   }
   Nofitems=_menu_info(file_mh,'c');
   item_text='';
   for (i=Nofitems-1;i>=0;--i) {
      _str tcommand;
     _menu_get_state(file_mh,i,mf_flags,'p',item_text,tcommand);
     if (item_text=='-') break;
     _menu_delete(file_mh,i);
   }
   //int dash_pos=i;
   int count=gLRUWindowList._length();

   for (i=0;i<def_max_windowhist && i<count;++i) {
      int j=count-i-1;
      _str filename=gLRUWindowList[j]._BufName2Caption();
      _str command='activate_wid 'gLRUWindowList[j];
      _menu_insert(file_mh,-1,MF_ENABLED,
                   (i+1<10?'&':''):+(i+1)' ':+_make_fhist_caption(filename,''),  // caption
                   command // command
                   );
   }
   _menu_insert(file_mh,-1,count?MF_ENABLED:MF_GRAYED,'&Windows...','on_more_windows');
}
//void _cbmdibuffer_unhidden_btabs()
//void _cbmdibuffer_hidden_btabs(...)
//void _cbquit_tabs(int buffid, _str name, _str docname= '', int flags = 0)
//void _switchbuf_tabs(_str oldbuffname, _str flag)
