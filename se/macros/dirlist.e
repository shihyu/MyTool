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
#include "dirlist.sh"
#import "dirlistbox.e"
#import "dirtree.e"
#import "files.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

/**
 * This function is for SlickEdit internal use.
 */
void _dlDirListObjectInit(DirListObject_t& dlo)
{
   dlo._makeempty();
   dlo.path="";
   dlo.inOnChange=false;
   dlo.pfnViewAddChildItem=null;
   dlo.pfnViewAddSiblingItem=null;
   dlo.pfnViewSavePos=null;
   dlo.pfnViewRestorePos=null;
   dlo.pfnViewClear=null;
   dlo.pfnViewSelectItem=null;
   dlo.pfnViewDeselectItem=null;
   dlo.pfnViewDeselectAll=null;
   dlo.pfnViewSortChildren=null;
   dlo.pfnViewTop=null;
   dlo.pfnViewBottom=null;
   dlo.pfnViewGotoParent=null;
   dlo.pfnViewGotoFirstChild=null;
   dlo.pfnViewGotoNextSibling=null;
   dlo.pfnViewGetItem=null;
   dlo.pfnViewSetItem=null;
   dlo.pfnViewAdjustScroll=null;
}

/**
 * Retrieve a copy of the DirListObject for current instance of the directory list.
 * Use _dlSetDirListObject to set the DirListObject.
 * <p>
 * IMPORTANT: <br>
 * Current windows must be control used to display path (e.g. directory list, directory tree).
 *
 * @return Copy of DirListObject_t object stored for current instance of directory list.
 */
DirListObject_t _dlGetDirListObject()
{
   // Sanity!
   // Explanation:
   // Once upon a time, _ul2_dirlist (directory list box control) used p_user2
   // to store the current working directory. _ul2_dirlist.ON_CREATE would call
   // _dlpath() with the value stored in p_user2, EVEN BEFORE SETTING THE VALUE
   // FOR p_user2! We got away with this because p_user2 is automatically
   // initialized to "" which, it so happens, was just fine with _dlpath()
   // because it would then populate the directory list from the application's
   // working directory to start. Since we now use p_user2 to store the DirListObject_t
   // structure, the fact that p_user2 is automatically initialized can no
   // longer be used. We must initialize the DirListObject if not already
   // initialized.
   //DirListObject_t dlo = (DirListObject_t)p_user2;
   DirListObject_t dlo = (DirListObject_t)_GetDialogInfoHt("dlo",p_window_id,true);
   if( dlo.path._isempty() ) {
      // Not initialized!
      if( p_object==OI_LIST_BOX ) {
         _dirlistboxInit();
      } else {
         _dirtreeInit();
      }
      //dlo = (DirListObject_t)p_user2;
      dlo = (DirListObject_t)_GetDialogInfoHt("dlo",p_window_id,true);
      //_dlDirListObjectInit(dlo);
      //p_user2=dlo;
   }
   return dlo;
}

/**
 * Set DirListObject for this instance of the directory list.
 * Use _dlGetDirListObject to retrieve a copy of the DirListObject.
 * <p>
 * IMPORTANT: <br>
 * Current windows must be control used to display path (e.g. directory list, directory tree).
 *
 * @param dlo DirListObject_t object.
 */
void _dlSetDirListObject(DirListObject_t& dlo)
{
   //p_user2=dlo;
   _SetDialogInfoHt("dlo",dlo,p_window_id,true);
}

/**
 * IMPORTANT: <br>
 * Current window must be control used to display path (e.g. directory list, directory tree).
 *
 * @return current path for instance of directory list.
 */
_str _dlGetPath()
{
   DirListObject_t dlo = _dlGetDirListObject();
   return dlo.path;
}

/**
 * Set current path for instance of directory list. Depending on cdToDir,
 * will also change the product's current working directory.
 * <p>
 * IMPORTANT: <br>
 * Current windows must be control used to display path (e.g. directory list, directory tree).
 *
 * @param newPath  Path to set.
 * @param cdToDir  (optional). Set to false if you do not want the product's
 *                 current working directory changed to match newPath.
 *                 Defaults to true.
 */
void _dlSetPath(_str newPath, bool cdToDir=true)
{
   DirListObject_t dlo = _dlGetDirListObject();

   _str orig_path = dlo.path;
   name := "";
   path := "";
   new_path := "";
   old_path := "";
   if( newPath!="" ) {
      new_path=newPath;
      name=_strip_filename(new_path,'p');
      if( name=='.' || name=='..' ) {
         path=_strip_filename(absolute(new_path:+FILESEP:+'x'),'n');
      } else {
         path=absolute(new_path);
      }
      if( path!="") {
         new_path=path;
      }
      _maybe_append_filesep(new_path);
      if( _file_eq(orig_path,new_path) && !cdToDir ) {
         // Nothing has changed and we are not forcing a change
         // of the product's current working directory.
         return;
      }

      old_path=orig_path;
      dlo.path=new_path;
      // Just in case of recursion, we will set this now
      _dlSetDirListObject(dlo);
      //if( substr(new_path,1,2)!='\\' ) {
         _maybe_append_filesep(old_path);
         temppath := "";
         if( _DataSetIsFile(old_path) ) {
            // /DATASETS folder is active
            temppath=old_path;
         } else {
            temppath=getcwd();
         }
         _maybe_append_filesep(temppath);
         if( !_file_eq(new_path,temppath) && !_DataSetIsFile(new_path) ) {
            // Change drive and directory
            if (cdToDir) {
               chdir(new_path,1);
               call_list("_cd_",new_path);
            }
         }
      //}
   } else {
      dlo.path=getcwd();
      _maybe_append_filesep(dlo.path);
   }

   _dlSetDirListObject(dlo);
}

/**
 * Parse absolute input path into: <br>
 * On Windows: drive/share, path <br>
 * On UNIX: root of filesystem (/) and path
 * <p>
 * IMPORTANT: <br>
 * Current windows must be control used to display path (e.g. directory list, directory tree).
 *
 * @param absPath Absolute path to parse.
 * @param root    (output). Root part of input path.
 * @param relPath (output). Path part relative to root of input path.
 *
 * @example Windows: c:\foo\bar => root=c:\, relPath=foo\bar
 * @example Windows: \\server\sharename\foo\bar => root=\\server\sharename\, relPath=foo\bar
 * @example UNIX: /foo/bar => root=/, relPath=foo/bar
 */
void _dlParseParts(_str absPath, _str& root, _str& relPath)
{
   if (_NAME_HAS_DRIVE) {
      if (substr(absPath,1,2)=='\\') {
         server := "";
         share := "";
         parse absPath with '\\'server'\'share'\';
         root='\\'server'\'share;
         relPath=substr(absPath,length(root)+2);
         // Always return bare sharename with a trailing \
         root :+= FILESEP;
      } else {
         root=substr(absPath,1,3);
         // Grab everything after the backslash in 'd:\'
         relPath=substr(absPath,4);
         // Always return bare drive with a trailing \
         _maybe_append_filesep(root);
      }
   } else {
      root=substr(absPath,1,1);
      // Grab everything after the '/'
      relPath=substr(absPath,2);
   }
}

/**
 * Fill in the sibling children directories for the path passed in under the current item.
 * <p>
 * IMPORTANT: <br>
 * Current window must be directory list control (e.g. list box, tree).
 *
 * @param parentPath Parent directory to use when filling in the directory list
 *                   control with sibling children.
 * @param showDotFiles whether or not to show UNIX dot files.
 *
 */
void _dlpathChildren(_str parentPath, bool showDotFiles=true)
{
   DirListObject_t dlo = _dlGetDirListObject();
   _maybe_strip_filesep(parentPath);

   // Do a FILE-MATCH to get the directories under the current
   // working directory.
   match_dir :=  parentPath:+FILESEP;
   maybe_quoted_path := _maybe_quote_filename(match_dir:+ALLFILES_RE);
   _str flagDotFiles = showDotFiles ? '+U' : '-U';
   dir := file_match(maybe_quoted_path' 'flagDotFiles' +X +D -P -V',1);
   listingRootDir := ( maybe_quoted_path == FILESEP:+ALLFILES_RE );
   // Note:
   // We build a list of siblings, then add in case the callbacks want to do
   // find_first/find_next. Otherwise the callback's find_first/next would
   // stomp on our find_first/next.
   _str siblings[]; siblings._makeempty();
   for(;;) {
      if( dir=="" ) {
         break;
      }
      if( _last_char(dir)==FILESEP && dir!=".":+FILESEP && dir!="..":+FILESEP ) {
         dir=substr(dir,1,length(dir)-1);
         dir=substr(dir,lastpos(FILESEP,dir)+1);
         if( dir!="." && dir!=".." ) {
            siblings[siblings._length()]=dir;
         }
      }
      maybe_quoted_path=_maybe_quote_filename(match_dir:+ALLFILES_RE);
      dir=file_match(maybe_quoted_path' 'flagDotFiles' +X +D -P -V',0);
   }
   // Insert sibling children.
   // Save the position in the directory list because we will need to
   // sort the children under this node later.
   (*dlo.pfnViewSavePos)("parent");
   (*dlo.pfnViewDeleteChildren)();
   first_sib_added := false;
   int i;
   for( i=0; i<siblings._length(); ++i ) {
      sibPath := parentPath:+FILESEP:+siblings[i];
      if( !first_sib_added ) {
         first_sib_added=(*dlo.pfnViewAddChildItem)(siblings[i],DLITEMTYPE_FOLDER_CLOSED,sibPath);
      } else {
         (*dlo.pfnViewAddSiblingItem)(siblings[i],DLITEMTYPE_FOLDER_CLOSED,sibPath);
      }
   }
   (*dlo.pfnViewRestorePos)("parent");
   if( first_sib_added ) {
      // Sort all the children we just inserted
      (*dlo.pfnViewSortChildren)();
   } else {
      // No children added, so make this a leaf node instead
      _str item;
      (*dlo.pfnViewGetItem)(item);
      (*dlo.pfnViewSetItem)(item,DLITEMTYPE_LEAF);
   }
   (*dlo.pfnViewAdjustScroll)();
}

/**
 * Gets and optionally fills in the directory list control.
 * <p>
 * IMPORTANT: <br>
 * Current window must be directory list control (e.g. list box, tree).
 *
 * @appliesTo Directory_List_Box
 * @param newPath   Directory to use when filling in the directory list
 *                  control.  If this is <B>null</B>, the current
 *                  directory list settings are returned and the
 *                  directory list is not changed.
 * @param doRefresh Normally the directory list control is not
 *                  updated when you specify the same directory.  This
 *                  option skips this check.
 * @param filter390 Filter to used when listing OS/390 data sets. 
 * @param doCd      Change the current working directory to the 
 *                  path given by <code>newPath</code>. 
 *
 * @return current path
 * @example
 * <pre>
 * #include 'slick.sh'
 * defeventtab form1;
 * command1.lbutton_up()
 * {
 *     // list1 is the name of the directory list box.
 *     // Two backslashes are not required unless you use double quotes
 *     result=list1._dlpath("c:\\vslick");
 *     messageNwait('new path is 'result);
 * }
 * </pre>
 *
 * @categories Directory_List_Box_Methods
 */
_str _dlpath(_str newPath=null, 
             bool doRefresh=false, 
             bool show_dotfiles=true, 
             bool doCd=true)
{
   if( newPath==null ) {
      return ( _dlGetPath() );
   }

   //
   // Set path
   //

   typeless orig_path = _dlGetPath();
   _str param = newPath;
   if( param=="" ) {
      param=orig_path;
   }

   // Send CHANGE_PATH in an ON_CHANGE event if called with a specific path
   do_changepath := ( param != "" );
   if( !doRefresh ) doCd = false;
   _dlSetPath(param,doCd);
   if( _file_eq(_dlGetPath(),orig_path) && !doRefresh ) {
      return orig_path;
   }

   //
   // Parse parts of path for display
   //

   drive_or_root := "";
   path := "";
   _dlParseParts(_dlGetPath(),drive_or_root,path);

   //
   // Display path heierarchy
   //

   DirListObject_t dlo = _dlGetDirListObject();
   itemType := 0;
   if( _file_eq(drive_or_root,_dlGetPath())) {
      itemType=DLITEMTYPE_FOLDER_AOPEN;
   } else {
      itemType=DLITEMTYPE_FOLDER_OPEN;
   }
   // Keep track of the full path of the directory item being inserted.
   // This is needed by the AddChildItem and AddSiblingItem callbacks
   // so that they can determine whether to insert the child/sibling or
   // not (i.e. filtering).
   _str currentPath = drive_or_root;
   _maybe_strip_filesep(currentPath);
   (*dlo.pfnViewClear)();
   _str first_item = drive_or_root;
   if (_NAME_HAS_DRIVE) {
      if (substr(drive_or_root,1,2)=='\\') {
         // Special case of \\server\sharename\. We do not want the trailing
         // backslash displayed (looks ugly).
         first_item=substr(drive_or_root,1,length(drive_or_root)-1);
      }
   }
   (*dlo.pfnViewAddChildItem)(first_item,itemType,currentPath);
   item := "";
   dir := "";
   while( path!="" ) {

      parse path with dir (FILESEP) path;

      if( path=="" ) {
         itemType=DLITEMTYPE_FOLDER_AOPEN;;
      } else {
         itemType=DLITEMTYPE_FOLDER_OPEN;;
      }
      item=dir;
      currentPath :+= FILESEP:+dir;
      (*dlo.pfnViewAddChildItem)(item,itemType,currentPath);
   }

   //
   // Insert sibling children
   //

   _dlpathChildren(currentPath, show_dotfiles);

   //
   // Notify the directory list control that the current item has changed
   //

   if( do_changepath ) {
      call_event(CHANGE_PATH, 0, p_window_id,ON_CHANGE,'');
   }

   return ( _dlGetPath() );
}

/**
 * @return Full path of selected directory list item.
 */
_str _dlBuildSelectedPath()
{
   DirListObject_t dlo = _dlGetDirListObject();
   (*dlo.pfnViewSavePos)("_dlBuildSelectedPath");

   path := "";
   dir := "";
   for(;;) {
      (*dlo.pfnViewGetItem)(dir);
      if( !(*dlo.pfnViewGotoParent)() ) {
         // We have reached the root - strip off the '\'
         if( _last_char(dir)==FILESEP ) {
            path=substr(dir,1,length(dir)-1):+path;
         } else {
            path=substr(dir,1,length(dir)):+path;
         }
         if (_isUnix()) {
            if( path=="" ) {
               path=FILESEP;
            }
         } else {
            if( isdrive(path) ) {
               path :+= FILESEP;
            }
         }
         break;
      } else {
         path=FILESEP:+dir:+path;
      }
   }
   (*dlo.pfnViewRestorePos)("_dlBuildSelectedPath");
   return path;
}

/**
 * Store arbitrary data in hash table maintained by DirListObject in tree control.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 *
 * @param key
 * @param value
 */
void _dlSetTreeData(_str key, typeless value)
{
   DirListObject_t dlo = _dlGetDirListObject();
   dlo.ht:[key]=value;
   _dlSetDirListObject(dlo);
}

/**
 * Retrieve arbitrary data in hash table maintained by DirListObject in tree control.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 *
 * @param key
 * @param value
 *
 * @return true if key found in hash table; otherwise false.
 */
bool _dlGetTreeData(_str key, typeless& value)
{
   DirListObject_t dlo = _dlGetDirListObject();
   if( !dlo.ht._indexin(key) ) {
      return false;
   }
   value=dlo.ht:[key];
   return true;
}

/**
 * Indicate whether we are in the middle of an on_change event for the directory list.
 * Used to disallow recursion.
 *
 * @param onoff 0 = Not in an on_change event. <br>
 *              1 = In an on_change event. <br>
 *              -1 = Return current value without setting.
 *
 * @return Previous value. Current value if -1 specified.
 */
bool _dlInOnChange(int onoff=-1)
{
   DirListObject_t dlo = _dlGetDirListObject();
   old_onoff := dlo.inOnChange;
   if( onoff > -1 ) {
      dlo.inOnChange = ( onoff != 0 );
      _dlSetDirListObject(dlo);
   }
   return old_onoff;
}
