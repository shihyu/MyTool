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
#include "codetemplate.sh"
#include "dirlist.sh"
#import "codetemplate.e"
#import "dirlist.e"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion


defeventtab _ctCategoryTree_etab _inherit _ul2_dirtree;

static bool isVersionControlDirectory(_str dir)
{
   _maybe_strip_filesep(dir);
   foldername := substr(dir,pathlen(dir)+1);
   if( foldername=="CVS" || foldername==".svn" ) {
      return true;
   }
   // Not a version control directory
   return false;
}

/**
 * @return true if there exists at least one non-template
 * subdirectory under path.
 */
static bool haveAtleastOneChildDirectory(_str path)
{
   _maybe_append_filesep(path);
   result := file_match(_maybe_quote_filename(path:+ALLFILES_RE)' +X +D +S -P -V',1);
   foundAnything := false;
   while( result!="" ) {
      if( _last_char(result)==FILESEP && result!=".":+FILESEP && result!="..":+FILESEP ) {
         result=substr(result,1,length(result)-1);
         result=substr(result,lastpos(FILESEP,result)+1);
         if( result!="." && result!=".." && !isVersionControlDirectory(result) ) {
            // We have a subdirectory.
            // If it is a template directory, then do not count it as a child directory.
            if( !_ctIsTemplateDirectory(path:+result) ) {
               // This is a non-template directory, so we have our minimum case of at least one directory
               foundAnything = true;
               break;
            }
         }
      }
      result = file_match(_maybe_quote_filename(path:+ALLFILES_RE)' +X +D +S -P -V',0);
   }
   // No non-template child directories
   return foundAnything;
}

// Note:
// It is expected that fullPath is NOT quoted.
static bool cbAddChildItem(_str item, int itemType, _str fullPath)
{
   if( _ctIsTemplateDirectory(fullPath) || isVersionControlDirectory(fullPath) ) {
      // Template directories do not belong in the category tree
      return false;
   }
   // IF attempting to add a non-leaf directory AND directory has no non-template subdirectories
   if( itemType!=DLITEMTYPE_LEAF && !haveAtleastOneChildDirectory(fullPath) ) {
      // Override to a leaf directory
      itemType=DLITEMTYPE_LEAF;
   }
   pfnDLViewAddChildItem_t pfn = null;
   if( _dlGetTreeData("base::cbAddChildItem",pfn) && pfn ) {
      return ( (*pfn)(item,itemType,fullPath) );
   }
   // Should never get here
   _message_box("cbAddChildItem: Missing base::cbAddChildItem");
   return false;
}

// Note:
// It is expected that fullPath is NOT quoted.
static bool cbAddSiblingItem(_str item, int itemType, _str fullPath)
{
   if( _ctIsTemplateDirectory(fullPath) || isVersionControlDirectory(fullPath) ) {
      // Template directories do not belong in the category tree
      return false;
   }
   // IF attempting to add a non-leaf directory AND directory has no non-template subdirectories
   if( itemType!=DLITEMTYPE_LEAF && !haveAtleastOneChildDirectory(fullPath) ) {
      // Override to a leaf directory
      itemType=DLITEMTYPE_LEAF;
   }
   pfnDLViewAddSiblingItem_t pfn = null;
   if( _dlGetTreeData("base::cbAddSiblingItem",pfn) && pfn ) {
      return ( (*pfn)(item,itemType,fullPath) );
   }
   // Should never get here
   _message_box("cbAddChildItem: Missing base::cbAddSiblingItem");
   return false;
}

/**
 * Fill categories tree with system template folders.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param initToDir (optional). Category folders are populated
 *                  from this directory. If "", then default system
 *                  templates/ItemTemplates directory is used. If
 *                  relative-path, then it is relative to system
 *                  templates/ItemTemplates directory.
 *                  Defaults to "".
 */
static void initSysCategories(_str initToDir="")
{
   _str sysTemplateDir = _ctGetSysItemTemplatesDir();
   if( initToDir!="" ) {
      sysTemplateDir=absolute(initToDir,sysTemplateDir);
   }
   _dlSetTreeData("sysTemplateDir",sysTemplateDir);
   // Set userinfo to root sysTemplateDir to make it easy to assemble a real
   // path from a selected node.
   int index = TREE_ROOT_INDEX;
   index=_TreeAddItem(index,CT_SYS_ITEM_CAT_CAPTION,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1,0,sysTemplateDir);
   // Set tree data with root-category-to-directory mapping to make it easy
   // to tell if a category path is a system category path.
   _dlSetTreeData("root:":+CT_SYS_ITEM_CAT_CAPTION,sysTemplateDir);
   // _dlPathChildren() requires the parent to be the current tree node
   _TreeSetCurIndex(index);
   _dlpathChildren(sysTemplateDir);
}

/**
 * Fill categories tree with user template folders.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param initToDir (optional). Category folders are populated
 *                  from this directory. If "", then default user
 *                  templates/ItemTemplates directory is used. If
 *                  relative-path, then it is relative to user
 *                  templates/ItemTemplates directory.
 *                  Defaults to "".
 */
static void initUserCategories(_str initToDir="")
{
   _str userTemplateDir = _ctGetUserItemTemplatesDir();
   if( initToDir!="" ) {
      userTemplateDir=absolute(initToDir,userTemplateDir);
   }
   _dlSetTreeData("userTemplateDir",userTemplateDir);
   // Set userinfo to root userTemplateDir to make it easy to assemble a real path from a selected node
   int index=TREE_ROOT_INDEX;
   index=_TreeAddItem(index,CT_USER_ITEM_CAT_CAPTION,TREE_ADD_AS_CHILD,_pic_fldopen,_pic_fldopen,1,0,userTemplateDir);
   // Set tree data with root-category-to-directory mapping to make it easy
   // to tell if a category path is a user category path.
   _dlSetTreeData("root:":+CT_USER_ITEM_CAT_CAPTION,userTemplateDir);
   // _dlPathChildren() requires the parent to be the current tree node
   _TreeSetCurIndex(index);
   _dlpathChildren(userTemplateDir);
}

/**
 * Initialize category tree control.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param initToSysPath  Path to system templates directory. If "", then defaults
 *                       to %VSROOT%/sysconfig/templates/ItemTemplates/. If null,
 *                       then system templates are not shown.
 * @param initToUserPath Path to user templates directory. If "", then defaults
 *                       to %SLICKEDITCONFIGVERSION%/templates/ItemTemplates/. If null,
 *                       then user templates not shown.
 */
void _ctCategoryInit(_str initToSysPath="", _str initToUserPath="")
{
   // Override some of the DirectoryListObject callbacks with our code template callbacks.
   // ON_CREATE2 event has already been called at this point, so this is safe to do now.
   DirListObject_t dlo = _dlGetDirListObject();
   // Save existing "base" callbacks so our code template callbacks can fall through to them
   pfnDLViewAddChildItem_t pfnBaseAddChildItem = dlo.pfnViewAddChildItem;
   pfnDLViewAddSiblingItem_t pfnBaseAddSiblingItem = dlo.pfnViewAddSiblingItem;
   dlo.pfnViewAddChildItem=cbAddChildItem;
   dlo.pfnViewAddSiblingItem=cbAddSiblingItem;
   _dlSetDirListObject(dlo);
   _dlSetTreeData("base::cbAddChildItem",pfnBaseAddChildItem);
   _dlSetTreeData("base::cbAddSiblingItem",pfnBaseAddSiblingItem);

   // _ul2_dirtree.on_create2 defaults the directory list to the current working directory.
   // Now we must clear that and insert our own custom list. Inefficient?...yes.
   old_inOnChange := _dlInOnChange(1);
   _TreeDelete(TREE_ROOT_INDEX,'C');
   if( initToSysPath!=null ) {
      initSysCategories(initToSysPath);
   }
   if( initToUserPath!=null ) {
      initUserCategories(initToUserPath);
   }
   _TreeTop();
   _dlInOnChange((int)old_inOnChange);
}

/**
 * _ctCategoryTree_etab.ON_CREATE
 * <p>
 * Set the p_eventtab for your form to _ctCategoryTree_etab (or eventtable that
 * inherits from _ctCategoryTree_etab) in order for this to get called
 * automatically.
 * 
 * @param initToSysPath  Path to system templates directory. If "", then defaults
 *                       to %VSROOT%/sysconfig/templates/ItemTemplates/.
 * @param initToUserPath Path to user templates directory. If "", then defaults
 *                       to %SLICKEDITCONFIGVERSION%/templates/ItemTemplates/.
 */
void _ctCategoryTree_etab.on_create(_str initToSysPath="", _str initToUserPath="")
{
   _ctCategoryInit(initToSysPath,initToUserPath);
}

/**
 * @param path Category path to test.
 * @param relativePath (optional) (output). If provided, set to the relative-path
 *                     with the category root stripped off (if 'path' is a system category path of course). <br>
 *                     Example: path="Installed Templates/Java/Database", relativePath="Java/Database"
 * 
 * @return true if category path is a system category path (e.g. under "Installed Templates/").
 */
static bool isSysCategoryPath(_str path, _str& relativePath=null)
{
   path=translate(path,FILESEP,FILESEP2);
   _maybe_strip(path, FILESEP, stripFromFront:true);
   rootCategory := "";
   rel_path := "";
   parse path with rootCategory (FILESEP) rel_path;
   if( rootCategory == CT_SYS_ITEM_CAT_CAPTION ) {
      if( relativePath!=null ) {
         relativePath=rel_path;
      }
      return true;
   }
   // Not a system category path
   return false;
}

/**
 * @param path Category path to test.
 * @param relativePath (optional) (output). If provided, set to the relative-path
 *                     with the category root stripped off (if 'path' is a user category path of course). <br>
 *                     Example: path="User Templates/Java/Database", relativePath="Java/Database"
 * 
 * @return true if category path is a user category path (e.g. under "Installed Templates/").
 */
static bool isUserCategoryPath(_str path, _str& relativePath=null)
{
   path=translate(path,FILESEP,FILESEP2);
   _maybe_strip(path, FILESEP, stripFromFront:true);
   rootCategory := "";
   rel_path := "";
   parse path with rootCategory (FILESEP) rel_path;
   if( rootCategory == CT_USER_ITEM_CAT_CAPTION ) {
      if( relativePath!=null ) {
         relativePath=rel_path;
      }
      return true;
   }
   // Not a user category path
   return false;
}

/**
 * Assemble an absolute system template path from the relative path
 * passed in.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param relPath Relative path to append to root system template path.
 * 
 * @example relPath="C++/Database => "c:\SlickEdit\sysconfig\templates\ItemTemplates\C++\Database"
 */
static _str buildSysTemplatePath(_str relPath)
{
   path := "";
   _str rootPath;
   _dlGetTreeData("sysTemplateDir",rootPath);
   _maybe_strip_filesep(rootPath);
   path=rootPath:+FILESEP:+relPath;
   return path;
}

/**
 * Assemble an absolute user template path from the relative path
 * passed in.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param relPath Relative path to append to root user template path.
 * 
 * @example relPath="C++/Database => "c:\Documents and Settings\...\My SlickEdit Config\...\templates\ItemTemplates\C++\Database"
 */
static _str buildUserTemplatePath(_str relPath)
{
   path := "";
   _str rootPath;
   _dlGetTreeData("userTemplateDir",rootPath);
   _maybe_strip_filesep(rootPath);
   path=rootPath:+FILESEP:+relPath;
   return path;
}

/**
 * Translate the category path (the path in the Category tree) to a
 * template path (a path on disk).
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param categoryPath (optional). Category path, folders separated by '/', to translate.
 *                     If set to null, then the current category is used.
 *                     Defaults to null.
 * 
 * @return Template path that category path maps to.
 * 
 * @example categoryPath="Installed Templates/C++/DesignPatterns" => "C:\SlickEdit\sysconfig\templates\ItemTemplates\C++\DesignPatterns"
 */
_str _ctCategoryToTemplatePath(_str categoryPath=null)
{
   path := "";
   if( categoryPath==null ) {
      categoryPath=_ctCategoryGetCategoryPath();
   }

   categoryPath=translate(categoryPath,FILESEP,FILESEP2);
   _maybe_strip(categoryPath, FILESEP, stripFromFront:true);
   _str rootCategory, relPath;
   parse categoryPath with rootCategory (FILESEP) relPath;
   rootDir := "";
   if( _dlGetTreeData("root:":+rootCategory,rootDir) ) {
      path=rootDir:+FILESEP:+relPath;
   }
   return path;
}

/**
 * _ctCategoryTree_etab.ON_CHANGE
 * 
 * @param reason    Reason for ON_CHANGE event. See CHANGE_* constants.
 * @param nodeIndex Index of tree node affected.
 * @param force     Force action even if already in an ON_CHANGE event.
 *                  Default to false.
 */
void _ctCategoryTree_etab.on_change(int reason, int nodeIndex, bool force=false)
{
   if( !force && _dlInOnChange() ) {
      // Recursion not allowed!
      return;
   }

   old_inOnChange := _dlInOnChange(1);
   switch( reason ) {
   case CHANGE_SELECTED:
      call_event(reason,nodeIndex,force,defeventtab _ul2_dirtree,ON_CHANGE,'e');
      break;
   case CHANGE_EXPANDED:
      {
         mou_hour_glass(true);
         // The node expanded is not necessarily the current node, so we
         // must temporarily set it current so that _dlBuildSelectedPath()
         // will work, then set it back.
         oldIndex := _TreeCurIndex();
         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(nodeIndex);
         }
         _str catPath = _dlBuildSelectedPath();
         _str templatePath = _ctCategoryToTemplatePath(catPath);
         if( templatePath!="" ) {
            _dlpathChildren(templatePath);
         }
         if( oldIndex!=nodeIndex ) {
            _TreeSetCurIndex(oldIndex);
         }
         mou_hour_glass(false);
      }
      break;
   case CHANGE_COLLAPSED:
      call_event(reason,nodeIndex,force,defeventtab _ul2_dirtree,ON_CHANGE,'e');
      break;
   case CHANGE_LEAF_ENTER:
      call_event(reason,nodeIndex,force,defeventtab _ul2_dirtree,ON_CHANGE,'e');
      break;
   default:
      // Note:
      // last_index('','k') is NOT reliable, so you cannot walk the inheritance
      // chain with eventtab_inherit() to find out the next eventtable in the
      // chain of inheritance.
      call_event(reason,nodeIndex,force,defeventtab _ul2_dirtree,ON_CHANGE,'e');
   }
   _dlInOnChange((int)old_inOnChange);
}

/**
 * Calls ON_CHANGE event with CHANGE_SELECTED reason and current node index.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 */
void _ctCategoryOnChangeSelected()
{
   call_event(CHANGE_SELECTED,_TreeCurIndex(),p_window_id,ON_CHANGE,'w');
}

/**
 * Assemble a path representing the current category. Directories are
 * the tree node captions and children are separated by '/'.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @return Category path.
 * 
 * @example
 * <pre>
 * If the category tree looks like this:
 * + Installed Templates
 *   + C++
 *       Database
 * </pre>
 * then "Installed Templates/C++/Database" would be returned.
 */
_str _ctCategoryGetCategoryPath()
{
   path := "";
   index := _TreeCurIndex();
   while( index>0 ) {
      if( path=="" ) {
         path=_TreeGetCaption(index);
      } else {
         path=_TreeGetCaption(index):+"/":+path;
      }
      index=_TreeGetParentIndex(index);
   }
   return path;
}

/**
 * Find the child node in category tree that matches path.
 * If found, category is set current.
 * <p>
 * IMPORTANT: <br>
 * Active window must be tree control.
 * 
 * @param path Category path (see example). Pass "" if you want to set top category.
 * @param refreshTree Set to true if you do not want the
 *                    tree refreshed after setting path.
 *                    Defaults to true.
 * 
 * @return true on success. false if path not found or error.
 * 
 * @example
 * If the path is "Installed Templates/C++/Database", then
 * the category tree's current node would be:
 * + Installed Templates
 *   + C++
 *       Database (current node)
 */
bool _ctCategorySetCategoryPath(_str path, bool refreshTree=true)
{
   bstatus := false;
   old_InOnChange := _dlInOnChange();
   if( !refreshTree ) {
      _dlInOnChange(1);
   }
   do {

      if( path==null || path=="" ) {
         _TreeTop();
         bstatus=true;
         break;
      }
      int index = TREE_ROOT_INDEX;
      while( path!="" && index>=0 ) {
         _str dir;
         parse path with dir'/'path;
         index=_TreeSearch(index,dir);
      }
      if( index>0 ) {
         _TreeSetCurIndex(index);
         // Have to refresh the tree immediately for some reason when
         // setting the current index programatically.
         _TreeRefresh();
         bstatus=true;
         break;
      }

   } while( false );
   _dlInOnChange((int)old_InOnChange);

   return bstatus;
}
