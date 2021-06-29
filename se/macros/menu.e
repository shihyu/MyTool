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
#import "fileproject.e"
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
#import "se/ui/mainwindow.e"
#endregion

static _str _disabled_icon_commands;
static _str _disabled_ncw_commands;
int gLRUWindowList[];
_str gMRUFileList[];
bool gMRUFileHash:[];
/* _menu_refresh_list */

// default to enabling the ant/makefile target menus
int def_show_makefile_target_menu=1;
static int gold_haveBuild;
static int gold_haveDebugging;
static int gold_haveBeautifiers;

static _str _open_menu_callback(int reason,var result,typeless key);

extern int _menu_set_item_icon(int handle, int position, int image);
definit()
{
   gold_haveBuild=gold_haveDebugging=gold_haveBeautifiers=-1;
   if ( arg(1)!='L' ) {
      gLRUWindowList._makeempty();
      gMRUFileList._makeempty();
      gMRUFileHash._makeempty();
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

const FILEHIST_HELP=  '';
const FILEHIST_MESSAGE= 'Opens file ';
const FILEHIST_CATEGORY= 'filehist';
const ALLFILESHIST_CATEGORY= 'allfilehist';
const WKSPHIST_CATEGORY= 'wkspchist';
const WINDHIST_CATEGORY= 'windowhist';

const ALLFILESHIST_CAPTION= 'More Files';
const ALLWORKSPACES_CAPTION= '&All Workspaces';
const ALLWINDOWS_CAPTION= '&Windows...';


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
   call_list("_MenuAddFileHist_");
   if (!def_max_filehist || !_mdi.p_menu_handle || !length(filename)) return;

   _menu_add_hist(filename,_mdi.p_menu_handle,0,FILEHIST_CATEGORY,'e','ncw',
                  FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
   _menu_add_allfilehist(filename);
}
void _menu_add_allfilehist(_str filename)
{
   if (!def_max_allfileshist || !_mdi.p_menu_handle || !length(filename)) return;

   // look for the filename in the MRU list, and move it to end
   count := gMRUFileList._length();
   if (gMRUFileHash._indexin(_file_case(filename))) {
      for (i:=count-1; i>=0; --i) {
         if (_file_eq(gMRUFileList[i], filename)) {
            if (i==count-1) return;
            gMRUFileList._deleteel(i);
            gMRUFileList[count-1]=filename;
            return;
         }
      }
      gMRUFileHash._deleteel(_file_case(filename));
   }

   // not in queue, if queue is full, remove oldest item(s), and add new item to end
   gMRUFileHash:[_file_case(filename)] = true;
   if (count >= def_max_allfileshist) {
      num_to_remove := count+1-def_max_allfileshist;
      for (i:=0; i<num_to_remove; i++) {
         gMRUFileHash._deleteel(_file_case(gMRUFileList[i]));
         _menu_remove_hist(gMRUFileList[i], _mdi.p_menu_handle, 0, 
                           ALLFILESHIST_CATEGORY,'e','ncw',
                           FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
      }
      gMRUFileList._deleteel(0, num_to_remove);
      gMRUFileList[def_max_allfileshist-1]=filename;
   } else {
      gMRUFileList[count]=filename;
   }

   // add this file to the All Files history list
   _menu_add_hist(filename,_mdi.p_menu_handle,0,ALLFILESHIST_CATEGORY,'e','ncw',
                  FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
}
// When a file is closed add it to the "All Files" submenu if it isn't already there.
void _cbquit_filehist(int buf_id,_str buf_name,_str DocumentName,int buf_flags)
{
   _menu_add_allfilehist(buf_name);
}

void _menu_remove_filehist(_str filename)
{
   call_list("_MenuRemoveFileHist_");

   if (!def_max_filehist || !_mdi.p_menu_handle || !length(filename)) return;

   _menu_remove_hist(filename, _mdi.p_menu_handle, 0,FILEHIST_CATEGORY,'e','ncw',
                     FILEHIST_HELP,FILEHIST_MESSAGE:+filename);
   _menu_remove_hist(filename, _mdi.p_menu_handle, 0,ALLFILESHIST_CATEGORY,'e','ncw',
                     FILEHIST_HELP,FILEHIST_MESSAGE:+filename);

   // look for the filename in the MRU list and remove it
   if (gMRUFileHash._indexin(_file_case(filename))) {
      gMRUFileHash._deleteel(_file_case(filename));
      count := gMRUFileList._length();
      for (i:=count-1; i>=0; --i) {
         if (_file_eq(gMRUFileList[i], filename)) {
            if (i==count-1) return;
            gMRUFileList._deleteel(i);
            return;
         }
      }
   }
}
void _menu_rename_filehist(_str old_dir,_str new_dir,bool isDirectory=false)
{
   if (!def_max_filehist || !_mdi.p_menu_handle || !length(old_dir) || !length(new_dir)) return;

   if (isDirectory) {
      _maybe_append_filesep(old_dir);
      _maybe_append_filesep(new_dir);
   }
   _menu_rename_hist(old_dir,new_dir, isDirectory,_mdi.p_menu_handle, 0,FILEHIST_CATEGORY,'e','ncw',
                     FILEHIST_HELP,FILEHIST_MESSAGE);
   _menu_rename_hist(old_dir,new_dir, isDirectory, _mdi.p_menu_handle, 0,ALLFILESHIST_CATEGORY,'e','ncw',
                     FILEHIST_HELP,FILEHIST_MESSAGE);
   // look for the filename in the MRU list and remove it
   count := gMRUFileList._length();
   for (i:=count-1; i>=0; --i) {
      old_filename:=gMRUFileList[i];
      if (isDirectory) {
         if (_file_eq(old_dir,substr(old_filename,1,length(old_dir)))) {
            gMRUFileHash._deleteel(_file_case(old_filename));
            new_filename:=new_dir:+substr(old_filename,length(old_dir)+1);
            gMRUFileHash:[_file_case(new_filename)] = true;
            gMRUFileList[i]=new_filename;
         }
      } else {
         if (_file_eq(old_dir,old_filename)) {
            gMRUFileHash._deleteel(_file_case(old_filename));
            new_filename:=new_dir;
            gMRUFileHash:[_file_case(new_filename)] = true;
            gMRUFileList[i]=new_filename;
            return;
         }
      }
   }
}
// Input filename must be absolute
static _str _reduce_filenamelen(_str filename,int len)
{
   _str value=filename;
   isHTTPFile := _isHTTPFile(value);
   if (isHTTPFile) {
      value=translate(value,FILESEP,FILESEP2);
   }

   start := "";
   server := "";
   share_name := "";
   rest := "";
   path := "";

   // shorten paths to files under the user's home directory on Unix
   if (_isUnix() && length(filename) > len) {
      home_path := _HomePath();
      _maybe_append_filesep(home_path);
      if (home_path != "" && length(filename) > length(home_path) && 
          _file_eq(substr(filename, 1, length(home_path)), home_path)) {
         value = "~" :+ substr(filename, length(home_path));
      }
   }

   for (;;){
      if (length(value)<=len) break;
      /* Remove a path */
      if (_isUnix()) {
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
      } else {
         if (substr(value,1,2)=='\\') {
            parse value with '\\' server '\' share_name '\' rest;
            start='\\' server '\' share_name;
            if (rest!='') {
               start :+= FILESEP;
            }
         } else if (isHTTPFile) {
            start=substr(value,1,5);
            rest=substr(value,6);
         } else {
            start=substr(value,1,3);
            rest=substr(value,4);
         }
      }
      // Just in case server share name is very long
      if (rest=='..' || rest=='') {   // Bug Fix
         rest = _strip_filename(strip(filename, 'T', FILESEP), 'P');
         value=start :+ ".." :+ FILESEP :+ rest :+ FILESEP;
         break;
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
   if (_isWindows()) {
      if (isHTTPFile) {
         value=translate(value,'/','\');
      }
   }
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

_str _make_fhist_caption(_str filename,_str dash_category,_str projectfilename="")
{
   filename = _prepare_filename_for_menu(filename);

   // strip off the "project.pbxproj" to make this a little easier to read
   // in the project menu
   if (dash_category:==WKSPHIST_CATEGORY) {
      if (_get_extension(filename,true):==XCODE_PROJECT_EXT) {
         filename=_strip_filename(filename,'N');
         _maybe_strip_filesep(filename);
      }
   }

   if (!(substr(filename,1,1)==FILESEP 
           || (_NAME_HAS_DRIVE && substr(filename,2,1)==':'))
       ) {
      name := name2 := temp := "";
      parse filename with name ' - ' name2 ' - ' temp;
      if (temp=='') {
         temp = name2;
         name2 = "";
      }
      if (temp!='') {
         if (!def_filehist_verbose) {
            temp = _strip_filename(temp,'N');
         }
         result := _reduce_filenamelen(temp,def_max_fhlen);
         if (name2 != "" && 
             !(def_workspace_flags & WORKSPACE_OPT_NO_PROJECT_HIST) && 
             !_file_eq(_strip_filename(name2,'E'),_strip_filename(name,'PE'))) {
            return(name' - 'name2" - "result);
         }
         return(name' - 'result);
      }
      //_str result=_reduce_filenamelen(filename,def_max_fhlen);
      //return(result);
   }

   name := _strip_filename(filename,'P');
   path := filename;
   if (!def_filehist_verbose) {
      path = _strip_filename(filename,'N');
   }
   result := _reduce_filenamelen(path,def_max_fhlen);
   if (path == "") {
      return(filename);
   }
   if (projectfilename != "") {
      name2 := _strip_filename(projectfilename,'P');
      if (name2 != "" && 
          !(def_workspace_flags & WORKSPACE_OPT_NO_PROJECT_HIST) &&
          !_file_eq(_strip_filename(name2,'E'),_strip_filename(name,'PE'))) {
         return(name' - 'name2" - "result);
      }
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
 * @param filename2   secondary file name argument to add to drop-down list.
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
void _menu_add_hist(_str filename,
                    int menu_handle,typeless submenu_pos,
                    _str dash_category,_str command,_str category,
                    _str help_command,_str help_message,_str filename2="")
{
   // Look for the menu files separator */
   mh := 0;
   dash_mh := 0;
   dash_pos := 0;
   mf_flags := 0;
   flags := 0;
   i := Nofitems := 0;
   item_text := "";
   typeless file_mh=0;

   quoted_filename2 := "";
   if (filename2 != "") {
      quoted_filename2 = " ":+_maybe_quote_filename(filename2);
   }

   if (isinteger(submenu_pos)) {
     _menu_get_state(menu_handle,submenu_pos,mf_flags,'p',item_text,file_mh);
   } else {
      // Find the submenu with caption matching submenu_pos
      mh=menu_handle;
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
        if (strieq(stranslate(item_text, '', '&'),stranslate(submenu_pos, '', '&'))) {
           break;
        }
      }
      if (i>=Nofitems) return;
   }
   int status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (dash_category==ALLFILESHIST_CATEGORY) {
      if (status) {
         /* Add the all-files menu item */
         _menu_insert(file_mh,-1,MF_ENABLED|MF_SUBMENU, ALLFILESHIST_CAPTION,'',dash_category);
         status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
      }
      _menu_get_state(dash_mh, dash_pos, 0, "P", "", file_mh, "", "", "");
      dash_pos = -1;
      if (status) {
         _menu_insert(file_mh,-1,MF_ENABLED,
                      _make_fhist_caption(filename,dash_category,filename2),  // caption
                      command' '_maybe_quote_filename(filename):+quoted_filename2, // command
                      category,             // categories.
                      help_command,
                      help_message
                      );
         return;
      }
   }
   if (status) {
      /* Add the menu files separator. */
      _menu_insert(file_mh,-1,MF_ENABLED,'-','',dash_category);
      _menu_insert(file_mh,-1,MF_ENABLED,
                   '&1 ':+_make_fhist_caption(filename,dash_category,filename2),  // caption
                   command' '_maybe_quote_filename(filename):+quoted_filename2, // command
                   category,             // categories.
                   help_command,
                   help_message
                   );
      return;
   }
   Nofitems=_menu_info(file_mh,'c');
   int maxf=def_max_filehist;
   if (dash_category == ALLFILESHIST_CATEGORY) {
      maxf=def_max_allfileshist;
   }
   caption := "";
   tcommand := "";
   categories := "";
   thelp_message := "";
   cmd := "";
   tfilename := "";
   tfilename2 := "";
   // Don't count the All Workspaces or All Files items.
   _menu_get_state(file_mh,Nofitems-1,flags,'p',caption,tcommand,categories,help_command,thelp_message);
   // submenu return index of menu for command
   if (isinteger(tcommand)) {
      --Nofitems;
   }
   if (dash_category==WKSPHIST_CATEGORY) {
      maxf=def_max_workspacehist;
   }
   insert_pos := -1;
   for (i=dash_pos+1;;++i) {
      if (i>=Nofitems) {
         if (Nofitems-dash_pos-1 >= maxf) {
            // Delete last item
            if (dash_category == FILEHIST_CATEGORY || dash_category == ALLFILESHIST_CATEGORY) {
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
      if (dash_category != ALLFILESHIST_CATEGORY) {
         parse caption with . caption ;
         n:=i-dash_pos+1;
         _str hotkey=(n<10)?'&'n:n;
         _menu_set_state(file_mh,i,flags,'p',hotkey' 'caption,tcommand,categories,help_command,thelp_message);
      }

      parse tcommand with cmd auto args;
      tfilename = parse_file(args,false);
      tfilename2 = parse_file(args,false);
      if (_file_eq(filename,tfilename)) {
         if (dash_category==WKSPHIST_CATEGORY && (def_workspace_flags & WORKSPACE_OPT_NO_PROJECT_HIST) ) {
            _menu_delete(file_mh,i);--i;
            Nofitems=_menu_info(file_mh,'c');
         } else {
            if (//(def_workspace_flags & WORKSPACE_OPT_NO_PROJECT_HIST) ||
                (_file_eq(filename2,tfilename2)) ||
                ((filename2!="") != (tfilename2!=""))) {
               _menu_delete(file_mh,i);
               break;
            }
         }
      } else if (dash_category == ALLFILESHIST_CATEGORY && insert_pos < 0) {
         filename_only := _strip_filename(filename, 'P');
         tfilename_only := _strip_filename(tfilename, 'P');
         status = stricmp(filename_only, tfilename_only);
         if (status == 0) status = stricmp(filename, tfilename);
         if (status < 0) {
            insert_pos = i;
         }
      }
   }
   if (insert_pos < 0 && dash_category != ALLFILESHIST_CATEGORY) insert_pos=dash_pos+1;
   hotkey := (dash_category != ALLFILESHIST_CATEGORY)? "&1 ":"";
   _menu_insert(file_mh,insert_pos,MF_ENABLED,
                hotkey:+_make_fhist_caption(filename,dash_category,filename2),
                command' '_maybe_quote_filename(filename):+quoted_filename2,
                category,help_command,help_message);

}
//
//  This function currently only supports add file history because
//  file case matching is performed and file names are place in
//  double quotes if the filename contains spaces.
//
void _menu_remove_hist(_str filename,int menu_handle,typeless submenu_pos,_str dash_category,_str command,_str category,_str help_command,_str help_message,_str abs_project_name='')
{
   // Look for the menu files separator */
   mh := 0;
   i := Nofitems := 0;
   dash_mh := 0;
   dash_pos := 0;
   mf_flags := 0;
   flags := 0;
   item_text := "";
   typeless file_mh=0;
   int status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (isinteger(submenu_pos)) {
     _menu_get_state(menu_handle,submenu_pos,mf_flags,'p',item_text,file_mh);
     if (!status && dash_category==ALLFILESHIST_CATEGORY) {
        _menu_get_state(dash_mh, dash_pos, 0, "P", "", file_mh);
        dash_pos = -1;
     }
   } else {
      // Find the submenu with caption matching submenu_pos
      mh=menu_handle;
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
        if (strieq(stranslate(item_text, '', '&'),stranslate(submenu_pos, '', '&'))) {
           break;
        }
      }
      if (i>=Nofitems) return;
   }
   if (status) {
      // Nothing to remove
      return;
   }
   caption := "";
   tcommand := "";
   categories := "";
   thelp_message := "";
   cmd := "";
   tfilename := "";
   tfilename2 := "";
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
      if (dash_category != ALLFILESHIST_CATEGORY) {
         parse caption with . caption;
         _menu_set_state(file_mh,i,flags,'p','&'(i-dash_pos)' 'caption,tcommand,categories,help_command,thelp_message);
      }

      parse tcommand with cmd auto rest;
      tfilename = parse_file(rest,false);
      if (_file_eq(filename,tfilename)) {
         if (abs_project_name!='') {
            tfilename2 = parse_file(rest,false);
            if (_file_eq(abs_project_name,tfilename2)) {
               _menu_delete(file_mh,i);
               --Nofitems;--i;
            }
         } else {
            _menu_delete(file_mh,i);
            --Nofitems;--i;
         }
      }
   }

}

void _menu_rename_hist(_str old_dir,_str new_dir, bool isDirectory,int menu_handle,typeless submenu_pos,_str dash_category,_str command,_str category,_str help_command,_str help_message) {
   // Look for the menu files separator */
   mh := 0;
   i := Nofitems := 0;
   dash_mh := 0;
   dash_pos := 0;
   mf_flags := 0;
   flags := 0;
   item_text := "";
   typeless file_mh=0;
   int status=_menu_find(menu_handle,dash_category,dash_mh,dash_pos,'c');
   if (isinteger(submenu_pos)) {
     _menu_get_state(menu_handle,submenu_pos,mf_flags,'p',item_text,file_mh);
     if (!status && dash_category==ALLFILESHIST_CATEGORY) {
        _menu_get_state(dash_mh, dash_pos, 0, "P", "", file_mh);
        dash_pos = -1;
     }
   } else {
      // Find the submenu with caption matching submenu_pos
      mh=menu_handle;
      Nofitems=_menu_info(mh,'c');
      for (i=0;i<Nofitems;++i) {
        _menu_get_state(mh,i,mf_flags,'p',item_text,file_mh);
        if (strieq(stranslate(item_text, '', '&'),stranslate(submenu_pos, '', '&'))) {
           break;
        }
      }
      if (i>=Nofitems) return;
   }
   if (status) {
      // Nothing to rename
      return;
   }
   caption := "";
   tcommand := "";
   categories := "";
   thelp_message := "";
   cmd := "";
   tfilename := "";
   tfilename2 := "";
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
      parse tcommand with cmd auto rest;
      //say(tcommand);
      //say(help_command);
      //say(thelp_message);
      //say('');
      tfilename = parse_file(rest,false);
      bool modified=false;
      if (isDirectory) {
         if (file_eq(old_dir,substr(tfilename,1,length(old_dir)))) {
            modified=true;
            tfilename=new_dir:+substr(tfilename,length(old_dir)+1);
         }
         tfilename2= parse_file(rest,false);
         if (tfilename2!='' && file_eq(old_dir,substr(tfilename2,1,length(old_dir)))) {
            modified=true;
            tfilename2=new_dir:+substr(tfilename2,length(old_dir)+1);
         }
      } else {
         if (file_eq(old_dir,tfilename)) {
            modified=true;
            tfilename=new_dir;
         }
         tfilename2= parse_file(rest,false);
         if (tfilename2!='' && file_eq(old_dir,tfilename2)) {
            modified=true;
            tfilename2=new_dir;
         }
      }
      if (modified) {
         if (dash_category == ALLFILESHIST_CATEGORY) {
            caption=_make_fhist_caption(tfilename,dash_category,tfilename2);
         } else {
            caption='&'(i-dash_pos)' '_make_fhist_caption(tfilename,dash_category,tfilename2);
         }
         tcommand=cmd' '_maybe_quote_filename(tfilename);
         if (tfilename2!='') {
            strappend(tcommand,' '_maybe_quote_filename(tfilename2));
         }
         thelp_message=help_message:+tfilename;
         //say(tcommand);
         //say(thelp_message);
         _menu_set_state(file_mh,i,flags,'p',caption,tcommand,categories,help_command,thelp_message);
      }
      //say(tfilename);
#if 0
      if (_file_eq(filename,tfilename)) {
         if (abs_project_name!='') {
            tfilename2 = parse_file(rest,false);
            if (_file_eq(abs_project_name,tfilename2)) {
               _menu_delete(file_mh,i);
               --Nofitems;--i;
            }
         } else {
            _menu_delete(file_mh,i);
            --Nofitems;--i;
         }
      }
#endif
   }

}

static int saveOrRestoreFileHistory(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null,_str filehist_category=FILEHIST_CATEGORY,int max_filehist=def_max_filehist)
{
   // find the menu item for this history category
   dash_mh := dash_pos := 0;
   status := _menu_find(_mdi.p_menu_handle,filehist_category,dash_mh,dash_pos,'c');

   // All Files is a submenu, so get it's submenu handle
   if (!status && filehist_category==ALLFILESHIST_CATEGORY) {
      _menu_get_state(dash_mh, dash_pos, 0, "P", "", dash_mh, "", "", "");
      dash_pos = -1;
   }

   // count the number of items, but don't count the All Files items.
   Nofitems := 0;
   flags := 0;
   caption := "";
   if (!status) {
      Nofitems=_menu_info(dash_mh,'c');
      tcommand:="";
      _menu_get_state(dash_mh,Nofitems-1,flags,'p',caption,tcommand);
      if (isinteger(tcommand)) {
         --Nofitems;
      }
   }

   if (option=='R' || option=='N') {
      // Restoring history, first delete the old menu history
      if (!status) {
         for (i:=Nofitems-1; i>=dash_pos+1 ;--i) {
            _menu_delete(dash_mh,i);
         }
      }
      if (filehist_category == ALLFILESHIST_CATEGORY) {
         gMRUFileList._makeempty();
         gMRUFileHash._makeempty();
      }
      // not tracking menu history?
      typeless Noffiles=0;
      parse info with Noffiles .;
      if (!max_filehist || !_mdi.p_menu_handle || !Noffiles) {
         down(Noffiles);
         return(0);
      }
      // get each item line-by-line and add it to the file history
      for (i:=1;i<=Noffiles;++i) {
         down();
         if (i<=max_filehist) {
            get_line(auto filename);
            if (filehist_category == ALLFILESHIST_CATEGORY) {
               _menu_add_allfilehist(_isHTTPFile(filename)?filename:absolute(filename,relativeToDir));
            } else {
               _menu_add_filehist(_isHTTPFile(filename)?filename:absolute(filename,relativeToDir));
            }
         }
      }

   } else {

      // saving file history, make sure there is something to save
      if (status || !max_filehist || !_mdi.p_menu_handle) {
         return(0);
      }

      // insert the number if items in the menu
      count := Nofitems-dash_pos-1;
      insert_line(upcase(filehist_category)': 'count);

      // go through menu items and insert them into the history
      for (i:=Nofitems-1; i>=dash_pos+1; --i) {
         typeless junk=0;
         _menu_get_state(dash_mh,i,flags,'p',caption,junk,junk,junk,auto help_message);
         parse help_message with . . auto filename;
         if (relativeToDir==null || _isHTTPFile(filename)) {
            insert_line(filename);
         } else {
            insert_line(relative(filename,relativeToDir));
         }
      }
   }
   return(0);
}
int _sr_filehist(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null)
{
   return saveOrRestoreFileHistory(option, info, restoreFromInvocation, relativeToDir, FILEHIST_CATEGORY, def_max_filehist);
}
int _sr_allfilehist(_str option='',_str info='',_str restoreFromInvocation='',_str relativeToDir=null)
{
   return saveOrRestoreFileHistory(option, info, restoreFromInvocation, relativeToDir, ALLFILESHIST_CATEGORY, def_max_allfileshist);
}
static void _menu_adjust_help()
{
   status := 0;
   mh := mpos := 0;
   mf_flags := 0;
   caption := "";

   int menu_handle=p_menu_handle;
   if (!menu_handle) return;
   if (_isUnix()) {
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
   } else {
      status=_menu_find(menu_handle,"help -using",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
      }
   }
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
   if (_isUnix()) {
      lastValidMh := -1;

      status=_menu_find(menu_handle,"configure_index_file",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
         lastValidMh = mh;
      }
      status=_menu_find(menu_handle,"help_index",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
         lastValidMh = mh;
      }
      status=_menu_find(menu_handle,"msdn_configure_collection",mh,mpos,'M');
      if (!status) {
         _menu_delete(mh,mpos);
         lastValidMh = mh;
      }
      if (lastValidMh != -1) {
         _menu_get_state(mh,mpos,mf_flags,"p",caption);
         if (caption=="-") {
            _menu_delete(mh,mpos);
         }
      }
      _menu_adjust_config(menu_handle);
   }
}
static void _menu_adjust_config(int menu_handle)
{
   if (_isUnix()) {
      mh := mpos := 0;
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
void _maybe_reload_mdi_menu(bool AlwaysUpdate=false) 
{
   if (gold_haveBuild==_haveBuild() && gold_haveDebugging==_haveDebugging() && gold_haveBeautifiers==_haveBeautifiers()) {
      return;
   }
   int menu_handle=_mdi.p_menu_handle;
   // IF we are not replacing the existing mdi menu
   if (!menu_handle) {
      return;
   }
   // If we need to remove the debug menu.
   debug_menu_visible := false;
   build_menu_visible := false;
   flags := 0;
   caption := "";
   int i,j=0,Nofitems=_menu_info(menu_handle);
   for (i=0;i<Nofitems;++i) {
      _menu_get_state(menu_handle,i,flags,"P",caption);
      // IF the selection character is on the V or I
      nohotkey_caption := stranslate(caption,"","&");
      if (strieq(nohotkey_caption,'debug')) {
         debug_menu_visible=true;
      }
      if (strieq(nohotkey_caption,'build')) {
         build_menu_visible=true;
      }
   }

   if (
       (debug_menu_visible && !_haveDebugging()) ||
       (!debug_menu_visible && _haveDebugging()) ||
       (build_menu_visible && !_haveBuild()) ||
       (!build_menu_visible && _haveBuild())
       ) {
      _load_mdi_menu();
   }
}
void _load_mdi_menu()
{
   if (!(_default_option(VSOPTION_APIFLAGS) & VSAPIFLAG_MDI_MENUS)) {
      return;
   }
   status := 0;
   if (_cur_mdi_menu!='') {
      if (!_haveDebugging() || !_haveBuild()) {
         _cur_mdi_menu='_mdi_menu';
      }
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
            gold_haveBuild=_haveBuild();
            gold_haveDebugging=_haveDebugging();
            gold_haveBeautifiers=_haveBeautifiers();
            if (!_haveDebugging() || !_haveBuild() || !_haveFTP()) {
               flags := 0;
               caption := "";
               int i,Nofitems=_menu_info(menu_handle);
               for (i=Nofitems-1;i>=0;--i) {
                  typeless menu_handle2;
                  _menu_get_state(menu_handle,i,flags,"P",caption,menu_handle2);
                   caption=stranslate(caption,"","&");
                   if (!_haveFTP() && strieq(caption,"file") && (flags & MF_SUBMENU)) {
                      int i2,Nofitems2=_menu_info(menu_handle2);
                      for (i2=Nofitems2-1;i2>=0;--i2) {
                         _menu_get_state(menu_handle2,i2,flags,"P",caption);
                          caption=stranslate(caption,"","&");
                          // Found FTP menu item
                          if (!_haveFTP() && strieq(caption,"ftp") && (flags & MF_SUBMENU)) {
                             _menu_delete(menu_handle2,i2);
                             // Not sure if we need this
                             //_menuRemoveExtraSeparators(menu_handle2,i2);
                             --Nofitems2;
                          }
                      }
                   } else if (!_haveDebugging() && strieq(caption,"debug")) {
                      _menu_delete(menu_handle,i);
                      --Nofitems;
                   } else if (!_haveBuild() && strieq(caption,"build") ) {
                      _menu_delete(menu_handle,i);
                      --Nofitems;
                   } else if (strieq(caption,"help") && _isCommunityEdition()) {
                      _menuRemoveItemByCaption(menu_handle2, "Licensing");
                   }
               }
            }
            int old_menu_handle=_mdi.p_menu_handle;
            _mdi._menu_set(menu_handle);
            if (old_menu_handle) {
               _menu_destroy(old_menu_handle);
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
                              int & foundpos, bool ignoreUserDashes = true)
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
static void initProjectTools(int menu_handle,_str lang,_str absFilename)
{
// say('initProjectTools 1');

   // Locate the project sub menu by finding the menu
   // item for the Project Tool Wizard
   int status;
   int project_menu_handle, endPos;
   if (_menu_find(menu_handle, "project-tool-wizard", project_menu_handle,
              endPos, "M")) {
      //say('---did not find it!');
      return;
   }
   --endPos;
   startPos:=0;

   // delete everything in the first section (except for
   // the project tool wizard), which should just be build
   // tools from the last time we populated this menu
   menupos := 0;
   for (menupos=endPos; menupos>=startPos; menupos--) {
      //_menu_get_state(project_menu_handle,menupos, auto flags, 'p', auto caption);
      //say('   deleting 'caption);
      _menu_delete(project_menu_handle,menupos);
   }

   _AddBuildMenuItems(project_menu_handle,startPos,lang,absFilename);

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
void _AddBuildMenuItems(int project_menu_handle, int startPos, _str extension, _str absFilename, int restrict=0, _str cmdPrefix='',_str ProjectName=_project_name)
{
   if ( !_haveBuild() ) {
      return;
   }

   // Get the tool list from the project code;
   _str toolNameList[];
   _str toolCaptionList[];
   _str toolMenuCmdList[];
   _str toolCmdList[];
   //say('initProjectTools 4');
   _projectToolGetList(toolNameList,toolCaptionList,
                       toolMenuCmdList,toolCmdList,extension,absFilename,ProjectName);

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
   command := "";
   tempCmdLine := "";
   int i,menupos = startPos;
   prevCaption := "";
   for (i=0; i<toolCaptionList._length(); ++i) {
      //say('initProjectTools here i='i);
      //say("inserting "menupos" "toolCaptionList[i]" "toolMenuCmdList[i]);
      _str helpMessage;
      helpMessage = "Runs " :+ toolNameList[i] :+" for the current project";
      int mf_flags;
      mf_flags = (toolCmdList[i]=="")?MF_GRAYED:MF_ENABLED;
      // tool caption can be blank. So don't insert it.
      if (toolCaptionList[i]!="") {
         b := true;
         if (restrict) {
            command=toolMenuCmdList[i];
            tempCmdLine=toolCmdList[i];
            tempCmdLine= stranslate(tempCmdLine,"","%%");
            b=command=='project-compile' ||
             pos("(%f)|(%p)|(%n)|(%e)|(%c[~p])",tempCmdLine,1,"RI");
            //say('tempCmdLine='tempCmdLine' u='toolMenuCmdList[i]);
            if (restrict==2) {
               b = !b;
            }
            if (tempCmdLine=='') {
               b = false;
            }
            if (toolCaptionList[i]=='-') {
               b = (prevCaption!='-');
            }
         }
         if (b) {
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
   if ( !_haveBuild() ) {
      return;
   }

   // if def_show_makefile_target_menu is 0 then this has been globally disabled by the user
   if( def_show_makefile_target_menu == 0 ) {
      return;
   }

   // add command to bring up target dialog
   switch (type) {
   case "ant":
      _menu_insert(menu_handle, index, 0, "Execute Ant Target(s)...", "ant_target_form " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
      break;
   case "nant":
      _menu_insert(menu_handle, index, 0, "Execute NAnt Target(s)...", "ant_target_form " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
      break;
   case "makefile":
      _menu_insert(menu_handle, index, 0, "Execute Makefile Target(s)...", "makefile_target_form " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
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
   cmdPrefix := "";
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
      _menu_insert(targets_menu_handle, i, 0, targetList[i], cmdPrefix " " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile) " " targetList[i], "", "", descriptionList[i]);
   }
}

int def_show_makefile_target_menu_timeout=500; // milliseconds
int def_show_makefile_target_menu_disable_mult=4; // def_show_makefile_target_menu_timeout
static bool show_makefile_target_timeout(typeless starttime) {

   typeless diff=((typeless)_time('b')-starttime);
   if (diff>def_show_makefile_target_menu_timeout) {
      if (diff>=def_show_makefile_target_menu_disable_mult*def_show_makefile_target_menu_timeout) {
         // This feature is too slow, just disable it everywhere.
         def_show_makefile_target_menu=0;
         _config_modify_flags(CFGMODIFY_DEFVAR);
      }
      return true;
   }
   return false;
}

// insert the ant target menu item and submenu, if it is not already inserted
void _addTargetSubmenu(int menu_handle, _str projectName = _project_name)
{
   if (projectName == '') return;
   // if def_show_makefile_target_menu is 0 then this has been globally disabled by the user
   if(def_show_makefile_target_menu == 0 || def_show_makefile_target_menu == 2) return;

   typeless starttime=_time('b');
   // this loop will be run thrice.  the first 2 iterations will check for ant/NAnt xml build files
   // and the third iteration will check for makefiles
   int t;
   for(t = 0; t < 3; t++) {
      type := "";
      submenuCategory := "";
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
      if (show_makefile_target_timeout(starttime)) {
         return;
      }

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
      hasNameCollisions := false;
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
         if (show_makefile_target_timeout(starttime)) {
            return;
         }
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
         if (show_makefile_target_timeout(starttime)) {
            return;
         }
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
            strippedFilename := "";
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
         dlgCmdPrefix := "";
         cmdPrefix := "";
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
         _menu_insert(target_menu_handle, 0, 0, "Select Multiple Targets...", dlgCmdPrefix " " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile), "", "", "Execute one or more targets and optionally provide arguments");
         _menu_insert(target_menu_handle, 1, 0, "-");

         // add targets to the submenu
         int m;
         for(m = 0; m < targetList._length(); m++) {
            status = _menu_insert(target_menu_handle, m + 2, 0, targetList[m], cmdPrefix " " _maybe_quote_filename(projectName) " " _maybe_quote_filename(makefile) " " targetList[m], "", "", descriptionList[m]);
         }
      }
   }
}

void _menu_set_icon(int menuHandle, _str commandName, _str imageName)
{
    if(isEclipsePlugin()) {
        submenu_handle := 0;
        submenu_pos := 0;
        int status=_menu_find(menuHandle,commandName,submenu_handle,submenu_pos,'M');
        if(status != 0) {
           status = _menu_find(menuHandle,commandName,submenu_handle,submenu_pos,'C');
        }
        if (!status) {
            int icoIndex = _find_or_add_picture(imageName);
            if(icoIndex > 0) {
                _menu_set_item_icon(submenu_handle, submenu_pos, icoIndex);
             }
         } /* else { say("Did not find command "commandName); } */
    }
}

void _on_popup_ext_menu_default(_str menu_name,int menu_handle)
{
   if (isEclipsePlugin()) {
      submenu_handle := 0;
      submenu_pos := 0;
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

   // remove Imports if we're not looking at a java or c# project
   if (!_isEditorCtl(false) || 
       (!(_LanguageInheritsFrom('java') || strieq(p_EmbeddedLexerName,"java")) &&
        !(_LanguageInheritsFrom('cs')   || strieq(p_EmbeddedLexerName,"csharp")) &&
        !(_LanguageInheritsFrom('e')) &&
        !(_LanguageInheritsFrom('c') && !(_LanguageInheritsFrom('d')        || 
                                          _LanguageInheritsFrom('swift')    || 
                                          _LanguageInheritsFrom('googlego') || 
                                          _LanguageInheritsFrom('rust'))))
      ) {
      submenu_handle := 0;
      submenu_pos := 0;
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

   #if 0
   if (0 && isEclipsePlugin()) {
      // Example code for setting menu item icons
       _menu_set_icon(menu_handle, 'copy-word', "_clsasn0.ico");
       _menu_set_icon(menu_handle, 'push-ref', "_clsasn0.ico");
       _menu_set_icon(menu_handle, 'paste', "_clsasn0.ico");
   }
   #endif
}

void _on_init_menu()
{
   //say('_on_init_menu');
   old_wid := p_window_id;
   p_window_id=_mdi._edit_window();
   int menu_handle=_mdi.p_menu_handle;
   int no_child_windows=_no_child_windows();
   // Initialize the project tools in the project menu:
   initProjectTools(menu_handle,
                    _no_child_windows()?"":_mdi.p_child.p_LangId,
                    _no_child_windows()?"":_mdi.p_child.p_buf_name
                    );
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
   targetNS := "";
   targetCmd := "";
   parse targetCmdLine with targetCmd .;
   dot_pos := lastpos('.',targetCmd);
   if (dot_pos > 0) {
      targetNS = substr(targetCmd,1,dot_pos);
      targetCmd = substr(targetCmd,dot_pos+1);
   }
   index := find_index(targetNS:+'_OnUpdate_':+targetCmd,PROC_TYPE);
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
   if (!_haveBuild()) {
      return(MF_GRAYED|MF_REQUIRES_PRO);
   }

   // if there is no project and no files open, then don't bother
   if (_project_name=='' && (_no_child_windows() || (_fileProjectHandle()<0))) {
      return(MF_GRAYED);
   }

   cmdname := "";
   name := "";
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
   i := 0;
   for (i=0; i<gtoolMenuCmdList._length(); ++i) {
      //say("inserting "menupos" "toolCaptionList[i]" "toolMenuCmdList[i]);
      if (lowcase(translate(gtoolMenuCmdList[i],'_','-'))==lowcase(command)) {
         /*if (cmdui.menu_handle) {
            return(0);
         } */
         /*if(command=='project_compile') {
            say('command='command' c='gtoolCmdList[i]);
         } */
         //if (debug && gtoolCmdList[i]!="") say('enable');
         //say('h1 '((gtoolCmdList[i]=="")?'grayed':'enabled'));
         return((gtoolCmdList[i]=="")?MF_GRAYED:MF_ENABLED);
      }
   }
   /*if (cmdui.menu_handle) {
      //say('h3 cmd='command);
      return(0);
   } */
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
                         gtoolMenuCmdList,gtoolCmdList,
                          (_no_child_windows()?"":_mdi.p_child.p_LangId),
                          (_no_child_windows()?"":_mdi.p_child.p_buf_name)
                          );
      /*for (i=0; i<toolCaptionList._length(); ++i) {
         say('n='toolNameList[i]' c='toolCaptionList[i]' mc='toolMenuCmdList[i]' cm='toolCmdList[i]);
      } */
   }

   orig_wid := 0;
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
}

int _OnUpdateDefault(CMDUI &cmdui,int target_wid,_str command)
{
   cmdname := "";
   parse command with cmdname .;  // strip arguments
   index := find_index(cmdname,COMMAND_TYPE);
   typeless flags=0;
   if (index) {
      parse name_info(index) with ',' flags;
      if (!isinteger(flags)) flags=0;
   }

   // if it is a menu item, we look for a check mark
   checked_flag := 0;
   if (cmdui.menu_handle) {
      temp_mf_flags := 0;
      _menu_get_state(cmdui.menu_handle,cmdui.menu_pos,temp_mf_flags,'P');
      checked_flag=temp_mf_flags&MF_CHECKED;
   }

   // if this command is not supported in Standard or Community edition
   if ((flags & VSARG2_REQUIRES_PRO_EDITION) && !_isProEdition()) {
      // remove it if it is on a menu
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      // disable it if it is on a button
      if (cmdui.button_wid) {
         return(MF_GRAYED|MF_REQUIRES_PRO|checked_flag);
      }
      // otherwise, just add the MF_REQURIES_PRO flag for informative purposes
      checked_flag |= MF_REQUIRES_PRO;
   }

   // if this command is not supported in Standard or Community edition
   if ((flags & VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION) && !_isProEdition() && !_isStandardEdition()) {
      // remove it if it is on a menu
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO;
      }
      // disable it if it is on a button
      if (cmdui.button_wid) {
         return(MF_GRAYED|MF_REQUIRES_PRO|checked_flag);
      }
      // otherwise, just add the MF_REQURIES_PRO flag for informative purposes
      checked_flag |= MF_REQUIRES_PRO;
   }

   // if this command is not supported in Community edition
   if ((flags & VSARG2_REQUIRES_PRO_OR_STANDARD_EDITION) && !_haveFTP()) {
      // remove it if it is on a menu
      if (cmdui.menu_handle) {
         _menu_delete(cmdui.menu_handle,cmdui.menu_pos);
         return MF_DELETED|MF_REQUIRES_PRO_OR_STANDARD;
      }
      // disable it if it is on a button
      if (cmdui.button_wid) {
         return(MF_GRAYED|MF_REQUIRES_PRO_OR_STANDARD|checked_flag);
      }
      // otherwise, just add the MF_REQURIES_PRO flag for informative purposes
      checked_flag |= MF_REQUIRES_PRO_OR_STANDARD;
   }

   // if we are on the command line
   if ((flags & (VSARG2_CMDLINE|VSARG2_TEXT_BOX)) && target_wid==_cmdline) {
      return(MF_ENABLED|checked_flag);
   }

   // these are our requirement flags for this command
   int req_flags=flags&VSARG2_REQUIRES;

   // some arguments require a file, so we need the editor window to have focus
   if (cmdui.button_wid) {
      tempCmdLine := stranslate(command,"","%%");
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
         start_sel := end_sel := 0;
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
   if (target_wid && ((req_flags & VSARG2_REQUIRES_MDI_EDITORCTL) &&
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
      if (!target_wid) {
         _mdi.p_child._menu_set_binding(cmdui.menu_handle,cmdui.menu_pos);
      } else if (target_wid.p_object==OI_EDITOR) {
         target_wid._menu_set_binding(cmdui.menu_handle,cmdui.menu_pos);
         //say('bind keys');
      } else {
         //say('No bind keys');
         //say('oi='target_wid.p_object' target_wid='target_wid' _cmdline='_cmdline);
      }
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
   Noficons := 0;
   first_window_id := p_window_id;
   for (;;) {
      _next_window('hr');
      if ( ! (p_window_flags & HIDE_WINDOW_OVERLAP) && p_window_state=='I' ) {
         Noficons++;
      }
      if ( p_window_id:==first_window_id ) {
         return(Noficons);
      }
   }

}
/** 
 * Returns the number of non-hidden buffers.  
 *  
 * @return Returns the number of non-hidden buffers. 
 *  
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
   buf_name := "";
   Nofbuffers:=0;
   for (buf_info=buf_match('',1,'v');;) {
      if (rc) {
         return(Nofbuffers);
      }
      parse buf_info with buf_id modify buf_flags buf_name;
      ++Nofbuffers;
      if (Nofbuffers>=maxcount) {
         return(Nofbuffers);
      }
      buf_info=buf_match('',0,'v');
   }
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
    file_spec=_maybe_quote_filename(absolute(file_spec));
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
   menu := "";
   option := "";
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
   text := "";
   if (reason==SL_ONSELECT) {
      text=strip(_sellistcombo.p_text);

      // we don't allow deletion of some menus
      if (name_eq(translate(_MDIMENU,'_','-'),text)) {
         b5.p_enabled=false;
      } else {
         b5.p_enabled=true;
      }

      // see if this menu can be reset to its original form
      installVerIndex := find_index(text :+ SE_ORIG_MENU_SUFFIX, oi2type(OI_MENU));
      b7.p_enabled = (installVerIndex > 0);
   }
   if (reason!=SL_ONUSERBUTTON) {
      return('');
   }
   menuname := "";
   linenum := 0;
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
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if (orig_view_id=='') return;
   _sr_filehist();
   _sr_allfilehist();
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
         line := "";
         get_line(line);
         _str orig_line=line;
         linenumber := p_line;
         rtype := "";
         parse line with rtype line;
         name := '_sr_'strip(lowcase(rtype),'',':');
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
      mf_flags := 0;
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
      mf_flags := 0;
      _menu_get_state(menu_handle,i,mf_flags,'p',item_text,submenu_handle);
      item_text=stranslate(item_text,'','&');
      if (strieq(item_text,caption)) {
         return(i);
      }
   }
   return(-1);
}
/**
 * Find a submenu by the prefix of a caption
 * 
 * @param menu_handle
 *                 Handle of parent menu to search
 * @param prefix   Prefix of caption to find
 * @param submenu_handle
 *                 (output) Handle to submenu
 * 
 * @return <0 if not found, submenu index if found
 */
int _menu_find_loaded_menu_caption_prefix(int menu_handle,_str prefix,int &submenu_handle=0)
{
   int i, Nofitems=_menu_info(menu_handle,'c');
   for (i=0;i<Nofitems;++i) {
      _str item_text;
      mf_flags := 0;
      _menu_get_state(menu_handle,i,mf_flags,'p',item_text,submenu_handle);
      item_text=stranslate(item_text,'','&');
      subCaption := substr(item_text,1,length(prefix));
      if (strieq(subCaption,prefix)) {
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
            item_text := stranslate(child.p_caption,'','&');
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
   submenu_handle := 0;
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
   at_bottom := true;
   cap_below := "";
   int nofitems = _menu_info(menu_handle);
   if( index<nofitems ) {
      at_bottom=false;
      mf_flags := 0;
      _menu_get_state(menu_handle,index,mf_flags,'P',cap_below);
   }
   at_top := true;
   cap_above := "";
   if( index>0 ) {
      at_top=false;
      mf_flags := 0;
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
   submenu_handle := 0;
   int index = _menu_find_loaded_menu_caption(menu_handle,from_caption,submenu_handle);
   if( index<0 ) {
      return;
   }
   mf_flags := 0;
   caption := command := category := help_command := help_message := "";
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

   submenu_handle := 0;
   caption := "";
   index := -1;

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
   doMRU := _default_option(VSOPTION_NEXTWINDOWSTYLE)!=0;
   count := gLRUWindowList._length();
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
   count := gLRUWindowList._length();
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
   submenu_pos := "&Window";
   status := 1;
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
   count := gLRUWindowList._length();

   for (i=0;i<def_max_windowhist && i<count;++i) {
      int j=count-i-1;
      _str filename=gLRUWindowList[j]._BufName2Caption();
      command := 'activate_wid 'gLRUWindowList[j];
      _menu_insert(file_mh,-1,MF_ENABLED,
                   (i+1<10?'&':''):+(i+1)' ':+_make_fhist_caption(filename,''),  // caption
                   command, // command,
                   WINDHIST_CATEGORY
                   );
   }
   _menu_insert(file_mh,-1,count?MF_ENABLED:MF_GRAYED,'&Windows...','on_more_windows');
}
//void _cbmdibuffer_unhidden_btabs()
//void _cbmdibuffer_hidden_btabs(...)
//void _cbquit_tabs(int buffid, _str name, _str docname= '', int flags = 0)
//void _switchbuf_tabs(_str oldbuffname, _str flag)
