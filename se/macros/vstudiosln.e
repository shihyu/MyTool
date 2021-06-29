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
#include "project.sh"
#include "scc.sh"
#import "compile.e"
#import "fileman.e"
#import "guidgen.e"
#import "ini.e"
#import "makefile.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "ptoolbar.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "treeview.e"
#import "vc.e"
#import "wkspace.e"
#endregion 

_str gActiveSolutionConfig = '';

////////////////////////////////////////////////////////////////////
// Visual Studio 2003/2005 Solution (workspace) file support methods
// This functionality was relocated from wkspace.e
// VS2005 Website project TODO: listing
// 1) Create a menu like _projecttb_workspace_file (_projecttb_website_folder)
// 2) Menu items to 
//    a) Configure / Start the ASP.NET development server (WebDev.WebServer.exe /port:8080 /path:"C:\MyProject" /vpath:"/MyProject"
//    b) Launch the website in a browser (http://localhost:8080/MyProject)
// 3) Will need utility methods to find %SystemRoot%\Microsoft.NET\Framework\v2.0.XXXX\WebDev.WebServer.exe
// Found in reg key HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\InstallRoot
// Look for v2.XXXX folders
// Find WebDev.WebServer.exe
// 4) Need a new bitmap for the "virtual folders" under the website, so that 
//    the default context menu for folders isn't shown
//    a) Special bitmaps for App_Code and App_Data directories?
//    b) Other virtual dirs have a folder with an "earth dot"?
// 5) Read some of the properties from the .sln file, like the VWDPort setting
//    Debug.AspNetCompiler.VirtualPath = "/CSharpWebApp"
//    VWDPort = "1281"
static int _pic_website=0;
static int _pic_website_dir=0;
definit()
{
   _pic_website=0;
   _pic_website_dir=0;

   if (upcase(arg(1))!='L') {
      gActiveSolutionConfig='';
   }
}
// Creates a top-level folder for a Visual Studio 2005 Website folder
// pseudo-project. These are defined in the solution file (.sln) *without*
// any sort of project file (not even a .webproj...)
// They are inserted in a similar fashion to SolutionItem folders
void InsertWebsiteItems2005(_str WorkspaceName)
{
   // Read the Visual Studio .sln file for a project that matches
   // the the special type of "website" project. This special project
   // type doesn't contain any type of .proj file, it's just a declaration
   // of a name and a directory containing the website.
   // We'll insert the contents of the directory tree just like we
   // add top-level solution items
   int temp_view_id;
   int orig_view_id;
   
   int status=_open_temp_view(WorkspaceName,temp_view_id,orig_view_id);

   if (status) {
      return;
   }

   _str websiteFolders:[];
   websiteFolders._makeempty();

   activate_window(temp_view_id);

   top();
   up();
    
   // Project("{E24C65DC-7377-472B-9ABA-BC803B73C61A}") = "C:\...\CSharpWebApp\", "..\..\..\..\..\..\Lab\TestProjects\CSharpWebApp\", "{39F0053D-C602-415C-A64F-8B145337B754}"
   webProjRegex := 'Project\(\"\{E24C65DC\-7377\-472B\-9ABA\-BC803B73C61A\}\"\):b\=:b\"{#1:p\\*}\"\,:b\"{#2:p\\*}\"';
   // Group #1 is the display name for the website folder
   // Group #2 is the relative directory path where the website is contained
   searchOptions := "@Rh";
   foundFolder := search(webProjRegex, searchOptions);
   while(foundFolder == 0) {
      matchLen := match_length();
      startPos := match_length('S');
      webFolderName := "";
      webFolderDirectory := "";

      // Get the start and length for group #1, which is the folder name
      groupStart := match_length('S1');
      groupLen := match_length('1');
      if(groupStart >= 0 && groupLen > 0) {
         webFolderName = get_text(groupLen, groupStart);
      }

      // Get the start and length for group #3, which is the folder GUID
      groupStart = match_length('S2');
      groupLen = match_length('2');
      if(groupStart >= 0 && groupLen > 0) {
         webFolderDirectory = get_text(groupLen, groupStart);
      }
      if(webFolderName != '' && webFolderDirectory != '') {
         websiteFolders:[webFolderName] = webFolderDirectory;
      }

      // TODO: Search the next line for 
      // ProjectSection(WebsiteProperties) = preProject
      // Then down for 
      //    Debug.AspNetCompiler.VirtualPath = "/path"
      //    VWDPort = "1281"
      
      foundFolder = repeat_search(searchOptions);
   }

   // Re-activate the tree control
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Now take the list of website folders
   // and create top-level "solution item"-style folders
   // with the website name.
   _str hashIndex;
   hashIndex._makeempty();
   websiteFolders._nextel(hashIndex);
   while(!hashIndex._isempty()) {
      _str displayName = hashIndex;
      _str relativeDir = websiteFolders:[hashIndex];
      _str absoluteDir = _AbsoluteToWorkspace(relativeDir, WorkspaceName);
      // Create the solution item directory
      InsertWebsiteFolder(orig_view_id, displayName, absoluteDir);
      websiteFolders._nextel(hashIndex);
   }
}

// Recursively adds the directory contents (files and subdirectories) into the project tree
// from a special Website folder project in a Visual Studio 2005 solution file
static void InsertWebsiteFolder(int treeViewId, _str websiteName, _str websiteDirectory)
{
   if(_pic_website == 0)
      _pic_website = load_picture(-1,'_f_website.svg');
   if(_pic_website_dir == 0)
      _pic_website_dir = load_picture(-1,'_f_folder_website.svg');

   rootIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   int websiteTreeNode = treeViewId._TreeSearch(rootIndex, websiteName);
   if(websiteTreeNode > 0)
      _TreeDelete(websiteTreeNode);
   firstChildNode := treeViewId._TreeGetFirstChildIndex(rootIndex);
   // Create the new solution item virtual folder node
   if(firstChildNode > 0) {
      // There is another top-level folder in the tree, so insert this one before it
      websiteTreeNode = _TreeAddItem(firstChildNode,websiteName,TREE_ADD_BEFORE,_pic_website,_pic_website,0);
   } else {
      // There is no other top-level item, so just add the folder as a child
      websiteTreeNode = _TreeAddItem(rootIndex,websiteName,TREE_ADD_AS_CHILD,_pic_website,_pic_website,0);
   }
   
   // Get the list of all files under this directory and
   // add them to the new folder node
   InsertWebsiteFolderContents(treeViewId, websiteTreeNode, websiteDirectory);
}

// Adds the directory contents (just the files in a subdirectory) into the project tree
// from a special Website folder project in a Visual Studio 2005 solution file
static void InsertWebsiteFolderContents(int treeViewId, int parentNode, _str websiteDirectory)
{
   // Get a file listing of this directory, including subdirectories
   _str subDirectories[];
   _str childFiles[];
   childFiles._makeempty();
   subDirectories._makeempty();

   // Get a listing of all subdirectories
   // TODO: THis is returning way too many hits. Is +X not
   // working like I think it is?
   childDir := file_match(websiteDirectory' +D +X', 1);
   while(childDir != '=' && childDir != '') {
      subDirectories[subDirectories._length()] = childDir;
      childDir = file_match(childDir, 0);
   }

   // Get a listing of all child files
   childItem := file_match(websiteDirectory'*.* +P -D', 1);
   while(childItem != '=' && childItem != '') {
      childFiles[childFiles._length()] = childItem;
      childItem = file_match(childItem, 0);
   }
   
   // Add child directory folders
   if (subDirectories._length() > 0) {
      subdirIdx := 0;
      for (subdirIdx = 0; subdirIdx < subDirectories._length(); subdirIdx++) {
         // Skip the "dummy" entries dir\.\ and dir\..\
         // TODO: Should we also skip CVS directories?
         _str subDirName = subDirectories[subdirIdx];
         if (!pos('\\\.{1,2}\\$', subDirName, 1, 'U') && isdirectory(subDirName)) {
            // Now create a folder node for this particular directory
            subDirPlainName := strip(relative(subDirName, websiteDirectory, false), 'B', '\');
            int subDirNode = treeViewId._TreeAddItem(parentNode, subDirPlainName, TREE_ADD_AS_CHILD,_pic_website_dir,_pic_website_dir,0);
            InsertWebsiteFolderContents(treeViewId, subDirNode, subDirName);
         }
      }
   }

   // Add immediate file children
   if (childFiles._length() > 0) {
      int statusList[];
      usingSCC := _isscc();
      if (usingSCC) {
         int sccStatus=_SccQueryInfo2(childFiles, statusList, def_optimize_sccprjfiles);
         if (sccStatus) {
            usingSCC = false;
         }
      }
      
      fileIdx := 0;
      statusIndex := 0;
      for (fileIdx = 0; fileIdx < childFiles._length(); fileIdx++) {
         _projecttb_AddFile(treeViewId,parentNode,childFiles[fileIdx],statusIndex,statusList,usingSCC);
      }
   }
}

static void InsertVS2005WorkspaceNames(_str WorkspaceName=_workspace_filename,
                                        bool CallUpdateFilter=true,int formid=-1)
{
   // TODO: Make this public, and make it an override of InsertCurrentWorkspaceNames
   // from wkspace.e
}

// Inserts special files and folders from Visual Studio solution files
// This includes the SolutionItems folders in VS2002/2003/2005 solutions,
// as well as the "plain folder, no project" Website projects in VS2005
void InsertOtherWorkspaceFiles(_str WorkspaceName)
{
   _str ext=_get_extension(WorkspaceName,true);

   if (!stricmp(ext,VISUAL_STUDIO_SOLUTION_EXT)) {
      // Determine the version of the solution file
      // For file version 8.0 (VS2003 or earlier), use existing
      // InsertSolutionItems.
      // For file version 9.0 (VS2005), we need a new method
      _str appVersion = vstudio_application_version(WorkspaceName);
      if(isnumber(appVersion)) {
         double ver = (double)appVersion;
         if(ver >= 8.0) {
            InsertWebsiteItems2005(WorkspaceName);
            InsertSolutionItems2005(WorkspaceName);
            ReparentProjects2005(WorkspaceName);
         } else {
            InsertSolutionItems2003(WorkspaceName);
         }
      }
   }
}

// Populates the project tree control with the contents of the
// SolutionItems folder in a Visual Studio 2002/2003 solution file
static void InsertSolutionItems2003(_str WorkspaceName)
{
   //say("InsertSolutionItems: "WorkspaceName);
   // This code is for the Solution Items folder in Visual Studio 2002/2003
   // In Visual Studio 2005, there can be virtual folders
   // under "Solution Items" and this code doesn't handle it.
   // InsertSolutionItems2005 is called instead.
   int temp_view_id;
   int orig_view_id;

   int status=_open_temp_view(WorkspaceName,temp_view_id,orig_view_id);

   if (status) {
      return;
   }

   _str fileList[];
   fileList._makeempty();

   activate_window(temp_view_id);

   top();
   up();

   status=search('GlobalSection(SolutionItems)','@h');

   if (!status) {
      // lines for Solution Items are formated as:
      //
      //          <relative file name> = <relative file name>
      //
      // there is no hierachy to Solution Items, so just keep going until a line
      // is found that does not have an equals sign
      status=down();
      get_line(auto line);
      parse line with .'='line;     // take the second copy of the name so
                                    // that line will come back blank after
                                    // the last file has been found

      while (!status && line:!='') {
         fileList[fileList._length()]=_AbsoluteToWorkspace(strip(line),WorkspaceName);
         status=down();
         get_line(line);
         parse line with .'='line;
      }
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   if (fileList._length()==0) {
      return;
   }

   int statusList[];
   usingSCC := _isscc();

   if (usingSCC) {
      status=_SccQueryInfo2(fileList,statusList,def_optimize_sccprjfiles);
      if (status) {
         return;
      }
   }

   // remove the 'Solution Items' folder if there is one already
   // (project could be updated externally and is being refreshed, etc.)
   rootIndex := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   int solutionItemsNode=_TreeSearch(rootIndex,'Solution Items');
   if (solutionItemsNode>=0) {
      _TreeDelete(solutionItemsNode);
   }
   // add the 'Solution Items' folder
   solutionItemsNode=_TreeAddItem(rootIndex,'Solution Items',TREE_ADD_BEFORE,_pic_tfldclos,_pic_tfldopen,0);

   int fileIndex;
   statusIndex := 0;
   for (fileIndex=0;fileIndex<fileList._length();++fileIndex) {
      _projecttb_AddFile(orig_view_id,solutionItemsNode,fileList[fileIndex],statusIndex,statusList,usingSCC);
   }
}

// Populates the project tree control with the virtual folder structure of
// the top-level SolutionItems in a Visual Studio 2005 solution file
static void InsertSolutionItems2005(_str WorkspaceName)
{
   int temp_view_id;
   int orig_view_id;

   int status=_open_temp_view(WorkspaceName,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   VS2005SolutionItems solutionItems[];
   int solutionItemIndex:[];

   activate_window(temp_view_id);
   top();
   up();

   // Look for the special project-type GUID that denotes a top-level Solution item folder
   // EG: Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Solution Items", "Solution Items", "{E6F5945B-1E44-443D-8BA0-85418AAEB268}"
   // Regex  (SE syntax):  ^Project\(\"\{2150E333-8FDC-42A3-9474-1A3956D46DE8\}\"\):b\=:b\"{#1[^\"]+}\",:b\"{#2[^\"]+}\",:b\"\{{#3[A-Fa-f0-9-]?+}\}\"$
   userFolderRegex := '^Project\(\"\{2150E333-8FDC-42A3-9474-1A3956D46DE8\}\"\):b\=:b\"{#1[^\"]+}\",:b\"{#2[^\"]+}\",:b\"\{{#3[A-Fa-f0-9-]?+}\}\"$';
   searchOptions := "@Rh";
   foundFolder := search(userFolderRegex, searchOptions);
   while (foundFolder == 0) {
      // Get the start and length for group #1, which is the folder name
      folderName := "";
      groupStart := match_length('S1');
      groupLen := match_length('1');
      if (groupStart >= 0 && groupLen > 0) {
         folderName = get_text(groupLen, groupStart);
      }

      // Get the start and length for group #3, which is the folder GUID
      folderGuid := "";
      groupStart = match_length('S3');
      groupLen = match_length('3');
      if (groupStart >= 0 && groupLen > 0) {
         folderGuid = get_text(groupLen, groupStart);
      }

      // Put the folder name and guid into a VS2005SolutionItems structure
      sidx := solutionItems._length();
      solutionItems[sidx].FolderName = folderName;
      solutionItems[sidx].FolderGuid = folderGuid;
      solutionItems[sidx].ParentGuid = '';
      solutionItemIndex:[folderGuid] = sidx;

      // Go to the next line and see if it matches
      // ProjectSection(SolutionItems) = preProject
      //
      nextLine := "";
      status = down();
      while (!status) {
         get_line(nextLine);
         nextLine = strip(nextLine);
         if (nextLine :== 'EndProject') {
            break;
         }
         if (pos('ProjectSection(SolutionItems)', nextLine)) {
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  break;
               }
               // See if the next lines contain file paths, formatted like
               // ..\Misc\Integration.txt = ..\Misc\Integration.txt
               // Readme.txt = Readme.txt
               // These represent the relative paths to the files inside the virtual folder
               // Regex: ^:b*{#0:p}:b\=:b\g0$
               fileRegex := '^{#0?#}:b\=:b\g0$';
               if (pos(fileRegex, nextLine, 1, 'R') > 0) {
                  fileRelPath := substr(nextLine,pos('S0'),pos('0'));
                  if (FILESEP=='/') {
                     fileRelPath=translate(fileRelPath,'/','\');
                  }

                  _str fileAbsPath = _AbsoluteToWorkspace(fileRelPath, WorkspaceName);
                  int fileIdx = solutionItems[sidx].SolutionFiles._length();
                  solutionItems[sidx].SolutionFiles[fileIdx] = fileAbsPath;
               }
               status = down();
            }
            break;
         } else if (pos('ProjectSection', nextLine)) {
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  break;
               }
               status = down();
            }
         }
         status = down();
      }
      // Repeat search to look for another folder
      foundFolder = repeat_search(searchOptions);
   }

   // VS2005 solution item folders are virtual folders, and each folder is assigned a GUID. 
   // The parent/child relationship is defined as a relationship between 2 guids.
   // Search for a line that looks like 
   // {9C5226C2-F854-48D2-9868-F9E50526545D} = {FF7A150F-AB2A-44A8-9693-5942AE03D74E}
   //                       childFolderGuid  = parentFolderGuid

   top();
   status = search("GlobalSection(NestedProjects) = preSolution", "@");
   nestedProjectRegex := '\{{#0[0-9A-Fa-f]:8-([0-9A-Fa-f]:4-):3[0-9A-Fa-f]:12}\} = \{{#1[0-9A-Fa-f]:8-([0-9A-Fa-f]:4-):3[0-9A-Fa-f]:12}\}';
   line := "";
   while (!status) {
      down();
      get_line(line);
      line = strip(line);
      if (line :== '') {
         continue;
      }
      if (line :== 'EndGlobalSection') {
         break;
      }
      if (pos(nestedProjectRegex, line, 1, 'R')) {
         childGuid := substr(line,pos('S0'),pos('0'));
         parentGuid := substr(line,pos('S1'),pos('1'));
         if (parentGuid != '' && childGuid != '' && solutionItemIndex._indexin(childGuid)) {
            int idx = solutionItemIndex:[childGuid];
            solutionItems[idx].ParentGuid = parentGuid;
         }
      }
   }
   /*
   idx := 0;
   for (idx=0; idx < solutionItems._length(); ++idx) {
      top();
      up();
      // Build the regex for searching for a specific folder guid 
      // and finding  a parent folder (also ID-ed by guid)
      // GUID format regex: \{{#0:h:8-(:h:4-):3:h:12}\}
      // ^:b*\{guid\}:b\=:b\{{#0:h:8-(:h:4-):3:h:12}\}
      solutionItems[idx].ParentGuid = '';
      _str childGuid = solutionItems[idx].FolderGuid;
      parentGuidRegex :=  '^:b*\{' :+ childGuid :+ '\}:b\=:b\{{#0:h:8-(:h:4-):3:h:12}\}';

      // If we found a matching line, this virtual folder has a parent folder
      if (search(parentGuidRegex, '@RhI') == 0) {
         parentGuidStart := match_length('S0');
         parentGuidLen := match_length('0');
         if (parentGuidStart >= 0 && parentGuidLen > 0) {
            parentGuid := get_text(parentGuidLen, parentGuidStart);
            solutionItems[idx].ParentGuid = parentGuid;
         }
      }
   }
   */

   // Re-activate the tree control
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Add the virtual folder (and file) directory structure to the
   // project tree. We start with the top-level items that do not
   // have a .ParentGuid set.
   InsertSolutionItemTree(orig_view_id, _TreeGetFirstChildIndex(TREE_ROOT_INDEX), '', solutionItems);
   solutionItems._makeempty();
}

// Removes one file from a Visual Studio 2002/2003 or Visual Studio 2005 
// solution file's SolutionItems. Very flat one-folder structure for VS2002/2003, and
// a little more intricate for VS2005
void RemoveSolutionItem(int treeIndex)
{
   _str appVersion = vstudio_application_version(_workspace_filename);
   if (isnumber(appVersion)) {
      double ver = (double)appVersion;
      if (ver >= 8.0) {
         RemoveSolutionItem2005(treeIndex);
      } else {
         RemoveSolutionItem2003(treeIndex);
      }
   }
}

// Removes one file from a Visual Studio 2002/2003 solution file's listing
// one-and-only SolutionItems folder
static void RemoveSolutionItem2003(int treeIndex)
{
   caption := _TreeGetCaption(treeIndex);
   _str filename;
   parse caption with ."\t"filename;
   _str relFilename=_RelativeToWorkspace(filename);

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);

   if (status) {
      return;
   }

   _cbsave_project_callback_disabled = true;
   activate_window(temp_view_id);

   top();
   up();

   if (!search('GlobalSection(SolutionItems)','@h')) {
      top_line := p_line;
      if (!search('EndGlobalSection','@h')) {
         if (!search(relFilename' = 'relFilename,'-@h')) {
            _delete_line();
            save();
         }
      }
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   _cbsave_project_callback_disabled = false;
   // force the folder to expand
   node := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _TreeSetInfo(node,1);
}

// Removes one file from a Visual Studio 2005 solution file's listing
// of solution items.
static void RemoveSolutionItem2005(int treeIndex)
{
   if(treeIndex < 1)
      return;

   caption := _TreeGetCaption(treeIndex);
   _str fileToRemove;
   parse caption with ."\t"fileToRemove;

   // Get the parent node of this item. This will contain
   // the folder guid that we need to identify the correct section
   parentFolder := _TreeGetParentIndex(treeIndex);
   if(parentFolder < 1)
      return;
   typeless retVal = _TreeGetUserInfo(parentFolder);
   _str folderGuid = (_str)retVal;

   // Open a temp view to read the .sln file
   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   _cbsave_project_callback_disabled = true;
   activate_window(temp_view_id);
   top();
   up();

   // Create the regular expression for locating this parent folder
   nextLine := "";
   _str parentFolderRE = 'Project\(\"\{2150E333-8FDC-42A3-9474-1A3956D46DE8\}\"\)[^\{]+\{' :+ folderGuid :+ '\}\"';
   if (!search(parentFolderRE,'@RhI')) {
      status = down();
      while (!status) {
         get_line(nextLine);
         nextLine = strip(nextLine);
         if (nextLine :== 'EndProject') {
            break;
         }
         if (pos('ProjectSection(SolutionItems)', nextLine)) {
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  break;
               }
               fileRegex := '^{#0?#}:b\=:b\g0$';
               if (pos(fileRegex, nextLine, 1, 'R') > 0) {
                  fileRelPath := substr(nextLine,pos('S0'),pos('0'));
                  _str fileAbsPath = _AbsoluteToWorkspace(fileRelPath);
                  if (fileToRemove == fileAbsPath) {
                     // We've found the matching entry
                     // Delete the line, save the solution, and
                     // put in a dummy value to break the while loop
                     _delete_line();
                     save();
                     break;
                  }
               }
               status = down();
            }
            break;
         } else if (pos('ProjectSection', nextLine)) {
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  break;
               }
               status = down();
            }
         }
         status = down();
      }
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   _cbsave_project_callback_disabled = false;
   _TreeSetInfo(parentFolder,1);
}

// Removes a virtual Solution Items folder from a Visual Studio 2005 solution file
// The project tree is also then updated
void RemoveSolutionItemFolder2005(_str folderGuid)
{
   // Build a listing of any child folders
   // and recursively call this method.
   
   // Open a temp view to read the .sln file
   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   _str childGuids[];
   childGuids._makeempty();

   activate_window(temp_view_id);
   top();
   up();
   
   findChildrenRE :=  '\{{#1:h:8-(:h:4-):3:h:12}\}:b=:b\{'folderGuid'\}';
   // childGuid = parentGuid
   // \{{#0:h:8-(:h:4-):3:h:12}\}:b=:b\{275F73CF-B80B-4612-8F08-C2FBA7C03CCB\}
   foundChild := search(findChildrenRE, '@RhI');
   while(foundChild == 0) {
      // Pick out the child guid and place it in the array
      groupStart := match_length('S1');
      groupLen := match_length('1');
      if(groupStart >= 0 && groupLen > 0) {
         childFolderGuid := get_text(groupLen, groupStart);
         childGuids[childGuids._length()] = childFolderGuid;
      }
      foundChild = repeat_search('@RI');
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Loop through the array of child folders and recursively call
   // to delete them
   childIdx := 0;
   for(; childIdx < childGuids._length(); childIdx++) {
      RemoveSolutionItemFolder2005(childGuids[childIdx]);
   }

   // After the child folders are gone, remove this entire section
   _RemoveSolutionItemFolder2005(folderGuid);
}

// Removes a virtual Solution Items folder from a Visual Studio 2005 solution file
// The project tree is also then updated
static void _RemoveSolutionItemFolder2005(_str folderGuid)
{
   // Once we've gotten to this call, all child solution item
   // folders have been removed. So in here, we're removing the "Project" section
   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);
   if (status) {
      return;
   }

   _cbsave_project_callback_disabled = true;
   activate_window(temp_view_id);
   top();
   up();

   findSolutionFolderRE :=  '^Project\(\"\{{#1:h:8-(:h:4-):3:h:12}\}\"\)?+"\{'folderGuid'\}\"$';
   foundFolder := search(findSolutionFolderRE, '@RhI');
   if(foundFolder == 0) {
      // Delete lines until we find the 'EndProject' line
      // (NOT the EndProjectSection) line
      lastLineToDelete := false;
      do {
         _delete_line();
         nextLine := "";
         get_line(nextLine);
         nextLine = strip(nextLine);
         if(nextLine == 'EndProject') {
            _delete_line();
            lastLineToDelete = true;
         }
      } while (lastLineToDelete == false);

      // Go back to the top of the file and search for
      // the 'GlobalSection(NestedProjects)' solution file section
      // This is where the parent-child relationships between the virtual
      // folders are defined, so we'll remove dead entries when the parent
      // folder is removed.
      top();
      up();
      foundFolder = search('GlobalSection(NestedProjects)', '@h');
      if(foundFolder == 0) {
         // Deleting the childguid = parentguid section entries
         findChildrenRE :=  '\{'folderGuid'\}:b=:b\{{#1:h:8-(:h:4-):3:h:12}\}';

         down();
         nextLine := "";
         get_line(nextLine);
         nextLine = strip(nextLine);
         while(nextLine != 'EndGlobalSection') {
            if(pos(findChildrenRE, nextLine, 1, 'RI')) {
               _delete_line(); 
            } else {
               down();
            }
            get_line(nextLine);
            nextLine = strip(nextLine);
         }
      }
      // Finally, save all changes to the modified .sln file
      save();
   }
   // Re-activate the previous view, probably the project tree control
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   _cbsave_project_callback_disabled = false;
}

// Takes a listing of files from a Visual Studio 2005 solution file and inserts the
// virtual folder structure and relative file paths into the project tree
static void InsertSolutionItemTree(int treeViewId, int treeNode, _str parentGuid, VS2005SolutionItems (&solutionItems)[])
{
   // First, determine all of the index values where the 
   // ParentGuid is a match to parentGuid parameter
   // Make this into a "name:index" array
   _str foldersAtThisLevel[];
   foldersAtThisLevel._makeempty();

   int fidx = solutionItems._length() - 1;
   for (; fidx >= 0; --fidx) {
      if(solutionItems[fidx].ParentGuid == parentGuid) {
         toInsert :=  solutionItems[fidx].FolderName :+ '@@' :+ fidx;
         foldersAtThisLevel[foldersAtThisLevel._length()] = toInsert;
      }
   }

   // Now we've got all the folder names for this level
   // Sort them in REVERSE order (since we're adding them with TREE_ADD_BEFORE)
   foldersAtThisLevel._sort('D');

   // Walk the list of sorted folders and insert them
   ffix := 0;
   for (; ffix < foldersAtThisLevel._length(); ffix++) {
      _str toParse = foldersAtThisLevel[ffix];
      _str indexVal = 0;
      parse toParse with .'@@' indexVal;
      if(isnumber(indexVal)) {
         int idx = (int)indexVal;
         _str folderCaption = solutionItems[idx].FolderName;
         _str folderGuid = solutionItems[idx].FolderGuid;
         int solutionItemsNode = _TreeSearch(treeNode, folderCaption);
         if(solutionItemsNode > 0)
            _TreeDelete(solutionItemsNode);
         // Create the new solution item virtual folder node
         // This solution item folder doesn't have a parent GUID. So it is a
         // top-level virtual folder. (Just like the "classic" Solution Items folder is VS2003)
         siblingNode := _TreeGetFirstChildIndex(treeNode);
         if(siblingNode > 0) {
            solutionItemsNode = _TreeAddItem(siblingNode ,folderCaption,TREE_ADD_BEFORE,_pic_tfldclos,_pic_tfldopen,0,0,folderGuid);
         } else {
            solutionItemsNode = _TreeAddItem(treeNode ,folderCaption,TREE_ADD_AS_CHILD,_pic_tfldclos,_pic_tfldopen,0,0,folderGuid);
         }
                  
         // Find and add any child folders recursively
         InsertSolutionItemTree(treeViewId, solutionItemsNode, folderGuid, solutionItems);
  
         // And now insert this folder's contained files, if any
         if(solutionItems[idx].SolutionFiles._length() > 0) {
            int statusList[];
            usingSCC := _isscc();
            if (usingSCC) {
               int sccStatus=_SccQueryInfo2(solutionItems[idx].SolutionFiles, statusList, def_optimize_sccprjfiles);
               if (sccStatus) {
                  usingSCC = false;
               }
            }
   
            fileIdx := 0;
            statusIndex := 0;
            for(; fileIdx < solutionItems[idx].SolutionFiles._length(); ++fileIdx) {
               _str fileAbsPath = solutionItems[idx].SolutionFiles[fileIdx];
               _projecttb_AddFile(treeViewId,solutionItemsNode,fileAbsPath,statusIndex,statusList,usingSCC);
               //_projecttb_AddFile(treeViewId,solutionItemsNode,fileAbsPath,0,0,0);
            }
         }
      }
   }
}

// Add items to the top-level solution item folders in a Visual Studio .NET
// solution file. VS2002/2003 only have one SolutionItems folder, where VS2005
// can have an intricate virtual folder structure with many top-level folders.
void AddSolutionItems(_str newItems)
{
   _str appVersion = vstudio_application_version(_workspace_filename);
   if (isnumber(appVersion)) {
      double ver = (double)appVersion;
      if (ver >= 8.0) {
         AddSolutionItems2005(newItems);
      } else {
         AddSolutionItems2003(newItems);
      }
   }
}

// Adds files to the one-and-only SolutionItem folder in a VS2002/2003 solution file
static void AddSolutionItems2003(_str newItems)
{
   bool existingItems:[];

   solutionItemsNode := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   fileNode := _TreeGetFirstChildIndex(solutionItemsNode);
   _str caption;

   while (fileNode>=0) {
      caption=_TreeGetCaption(fileNode);
      parse caption with ."\t"caption;
      if (caption:!='') {
         existingItems:[_file_case(caption)]=true;
      }
      fileNode=_TreeGetNextSiblingIndex(fileNode);
   }

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);

   if (status) {
      return;
   }

   _cbsave_project_callback_disabled = true;
   activate_window(temp_view_id);

   top();
   up();

   if (!search('GlobalSection(SolutionItems)','@h')) {
      search('EndGlobalSection','@h');
      up();
      while (newItems:!='') {
         _str nextFile=parse_file(newItems,false);
         if (!existingItems._indexin(_file_case(nextFile))) {
            nextFile=_RelativeToWorkspace(nextFile);
            insert_line("\t\t"nextFile' = 'nextFile);
         }
      }

      save();
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   InsertOtherWorkspaceFiles(_workspace_filename);
   _cbsave_project_callback_disabled = false;
   // force the folder to expand
   node := _TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _TreeSetInfo(node,1);
}

// Adds files to a virtual SolutionItem folder in a VS2005 solution file
static void AddSolutionItems2005(_str newItems)
{
   // First, determine what node of the tree has focus
   // and try to find the user info defining the GUID
   folderGuid := "";
   typeless retVal = _TreeGetUserInfo(_TreeCurIndex());
   if (retVal != null) {
      folderGuid = (_str)retVal;
   }
   if (folderGuid == '') return;

   int temp_view_id;
   int orig_view_id;
   int status=_open_temp_view(_workspace_filename,temp_view_id,orig_view_id);

   if (status) {
      return;
   }

   _cbsave_project_callback_disabled = true;
   activate_window(temp_view_id);
   top();
   up();

   nextLine := "";
   _str folderSearchRE = 'Project\(\"\{2150E333-8FDC-42A3-9474-1A3956D46DE8\}\"\)[^\{]+\{' :+ folderGuid :+ '\}\"';
   if (!search(folderSearchRE,'@RhI')) {
      _str existingItems:[];
      existingItems._makeempty();

      status = down();
      while (!status) {
         get_line(nextLine);
         nextLine = strip(nextLine);
         if (nextLine :== 'EndProject') {
            // We don't yet have a ProjectSection(SolutionItems), so
            // we need to create it here.
            up();
            insert_line("\tProjectSection(SolutionItems) = preProject");
            insert_line("\tEndProjectSection");
            up();
            break;

         }
         if (pos('ProjectSection(SolutionItems)', nextLine)) {
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  up();
                  break;
               }
               fileRegex := '^{#0?#}:b\=:b\g0$';
               if (pos(fileRegex, nextLine, 1, 'RI')) {
                  // Get the text of the match, and add it
                  // to the existing items array
                  existingFile := substr(nextLine, pos('S0'), pos('0'));
                  existingItems:[_file_case(existingFile)] = 0;
               }
               status = down();
            }
            break;
         } else if (pos('ProjectSection', nextLine)) { // some other project section
            status = down();
            while (!status) {
               get_line(nextLine);
               nextLine = strip(nextLine);
               if (nextLine :== 'EndProjectSection') {
                  break;
               }
               status = down();
            }
         }
         status = down();
      }

      // Loop through each file in the items to be added
      while (newItems:!='') {
         _str nextFile = parse_file(newItems,false);
         nextFile = _RelativeToWorkspace(nextFile);
         // If the file is not already in the listing of files
         // already defined in the section, then insert_line with
         if (!existingItems._indexin(_file_case(nextFile))) {
            insert_line("\t\t"nextFile' = 'nextFile);
         }
      }
      save();
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Now that we've written out the new items into
   // the solution file, reload the solution items
   InsertSolutionItems2005(_workspace_filename);
   //InsertOtherWorkspaceFiles();

   _cbsave_project_callback_disabled = false;
}

static void SolutionSortFolders(int index=TREE_ROOT_INDEX)
{
   for ( ;; ) {
      _TreeSortCaption(index, 'FP');
      childindex := _TreeGetFirstChildIndex(index);
      if ((childindex > -1) && !_projecttbIsProjectNode(childindex)) {
         SolutionSortFolders(childindex);         
      }
      index = _TreeGetNextSiblingIndex(index);
      if (index < 0) break;
   }
}

static void ReparentProjects2005(_str WorkspaceName)
{
   // Read in the "nested projects" section and determine
   // if any projects need to be re-parented to be a child of
   // a solution item folder.
   // The ways things are working now, first all the projects are loaded
   // into the project tree at the root level. Then the virtual solution item
   // folder structure is created.
   // Now the last piece is to take the root-level projects and place them
   // down into the nested structure. So read all of the "non-solution-item"
   // project declarations, and then look for parent folders in the NestedProject
   // section.
   int temp_wid;
   int orig_wid;
   int status=_open_temp_view(WorkspaceName,temp_wid,orig_wid);
   if (status != 0)
      return;
   top();
   up();

   _str projectGuids:[];
   projectGuids._makeempty();

   // Search for all project that *aren't* Solution Item folders
   // Solution Item guid = 2150E333-8FDC-42A3-9474-1A3956D46DE8
   solutionItemGuid := "2150E333-8FDC-42A3-9474-1A3956D46DE8";
   userFolderRegex := '^Project\(\"\{{#0[A-Fa-f0-9-]?+}\}\"\):b\=:b\"{#1[^\"]+}\",:b\"{#2[^\"]+}\",:b\"\{{#3[A-Fa-f0-9-]?+}\}\"$';
   searchOptions := "@Rh";
   foundFolder := search(userFolderRegex, searchOptions);
   while (foundFolder == 0) {
      // Skip this if group #0 (the project type guid) matches
      // the guid that signals a solution item folder. We've already found those...
      groupStart := match_length('S0');
      groupLen := match_length('0');
      projTypeGuid := get_text(groupLen, groupStart);
      if(projTypeGuid != solutionItemGuid) {
         // Get the name for this project
         groupStart = match_length('S1');
         groupLen = match_length('1');
         projName := get_text(groupLen, groupStart);

         // Geth the relative path to the project file
         groupStart = match_length('S2');
         groupLen = match_length('2');
         projRelPath := get_text(groupLen, groupStart);
         if (FILESEP=='/') {
            projRelPath=translate(projRelPath,'/','\');
         }

         // Get the GUID for this project
         groupStart = match_length('S3');
         groupLen = match_length('3');
         projIdGuid := get_text(groupLen, groupStart);

         // Place the guid of the project and the relative path
         // into the hash table
         projectGuids:[projIdGuid] = projRelPath;
      }
      foundFolder = repeat_search(searchOptions);
   }

   // we need to find the global nested section, and record its location.
   // All of our searches will originate from this point, otherwise we risk
   // matching strings in the incorrect location.
   solutionHierarchyStart := -1;
   int foundSection = search("GlobalSection(NestedProjects) = preSolution", "@");
   if (!foundSection) {
      solutionHierarchyStart = match_length('S0') + match_length('0');
   }
   // if we didn't find this section, then we can't reparent the projects
   if (solutionHierarchyStart >= 0) {
      // Now loop through the array of project guids and
      // see if there is a section in the NestedProjects area
      // that defines a parent folder for this project's guid
      projectGuid := "";
      projectRelativePath := "";
      foreach (projectGuid => projectRelativePath in projectGuids) {
         // return to the top of the global section
         goto_point(solutionHierarchyStart);
         // Create the regular expression that looks for a parent of this guid
         // childGuid = parentGuid
         findParentRE :=  '\{' :+ projectGuid :+ '\}:b=:b\{{#0[A-Fa-f0-9-]?+}\}';
         if(search(findParentRE, '@RhI') == 0) {
            groupStart := match_length('S0');
            groupLen := match_length('0');
            parentGuid := get_text(groupLen, groupStart);
            ReparentProjectToSolutionFolder(orig_wid, WorkspaceName, projectRelativePath, parentGuid);
         }
      }
   }

   // Delete the temp view and set focus back to the project tree control
   activate_window(orig_wid);
   _delete_temp_view(temp_wid);
   if (_WorkspaceNameGet_Sort(WorkspaceName)) {
      orig_wid.SolutionSortFolders();
   }
   orig_wid._TreeRefresh();
}

static int ReparentProjectToSolutionFolder(int treeViewId, 
                                           _str WorkspacePath, 
                                           _str projectRelPath, 
                                           _str solutionFolderGuid)
{
   copiedNodeToDelete := -1;
   // Don't bother if the active window is not a tree control
   if(!_IsTreeControl(treeViewId))
      return -1;

   rootIndex := treeViewId._TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   // Find the solution folder by looking for its user info, which is the guid 
   int solutionFolderIndex = treeViewId._TreeSearch(rootIndex, "", 'IPT', solutionFolderGuid); 
   _str projectPath = projectRelPath;
   if (!def_project_show_relative_paths) {
      projectPath = _AbsoluteToWorkspace(projectRelPath, WorkspacePath);
   }
   // Look for the project (on the root level) via the caption
   capname := _strip_filename(projectRelPath,'p')"\t"projectPath;
   int projectIndex = treeViewId._TreeSearch(rootIndex,capname,'I');
 
   if(projectIndex <= 0 || solutionFolderIndex <= 0) {
      return -1;
   }

   // See if it already exists under the solution folder
   int copiedProjNode = treeViewId._TreeSearch(solutionFolderIndex, capname, 'I');
   if(copiedProjNode <= 0) {
      // Nope, not already found.
      // Copy the root level node and place the copy under the correct solution item folder
      copiedProjNode = _TreeCopy2(treeViewId, projectIndex, solutionFolderIndex);
      // delete the original
      copiedNodeToDelete = projectIndex;
   }
   // if we copied the node to it's correct project folder, then delete the original
   if (copiedNodeToDelete >= 0) {
       treeViewId._TreeDelete(copiedNodeToDelete);
   }
   return copiedProjNode;
}

void InsertVSWorkspaceFolder(_str WorkspaceName, _str folderName = '')
{
   // Read in the "nested projects" section and determine
   // if any projects need to be re-parented to be a child of
   // a solution item folder.
   // The ways things are working now, first all the projects are loaded
   // into the project tree at the root level. Then the virtual solution item
   // folder structure is created.
   // Now the last piece is to take the root-level projects and place them
   // down into the nested structure. So read all of the "non-solution-item"
   // project declarations, and then look for parent folders in the NestedProject
   // section.
   if (folderName=='') {
      typeless status=show('-modal _textbox_form',
                  'Add Folder',
                  0,  //TB_RETRIEVE_INIT, //Flags
                  '', //width
                  '', //help item
                  '', // "OK,Apply to &All,Cancel:_cancel\tCopy file '"SourceFilename"' to",//Button List
                  '', //retrieve name
                  'Folder Name'
                  );

      // did they cancel out?
      if (status=='' || _param1=='') {
         return;
      }
      folderName = _param1;
   }

   int subFolderNames:[];
   folderNode := _TreeCurIndex();
   int node = folderNode;
   if (node >= 0) {
      node = _TreeGetFirstChildIndex(node);
      while (node >= 0) {
         if (_projecttbIsFolderNode(node)) {
            caption := _TreeGetCaption(node);
            subFolderNames:[caption] = 1;
         }
         node=_TreeGetNextSiblingIndex(node);
      }
   }
   if (subFolderNames._indexin(_param1)) {
      _message_box('Folder name already exists: "'folderName'"');
      return;
   }

   int temp_wid;
   int orig_wid;
   int status=_open_temp_view(WorkspaceName,temp_wid,orig_wid);
   if (status != 0)
      return;
   top();
   up();

   old_indent_with_tabs:=p_indent_with_tabs;
   p_indent_with_tabs=true;

   _cbsave_project_callback_disabled = true;
   // Search for all project that *aren't* Solution Item folders
   // Solution Item guid = 2150E333-8FDC-42A3-9474-1A3956D46DE8
   solutionItemGuid := "2150E333-8FDC-42A3-9474-1A3956D46DE8";
   _str folderGuid = guid_create_string('G');
   folderGuidWithBraces :=  '{'folderGuid'}';
   foundprojectItem := search('Global', '@h');
   if (foundprojectItem == 0) {
      // insert the new debug line before the current line
      up();
      // get the indentation of the current line
      _first_non_blank();
      int indentCol = p_col - 1;
      // start building the new line of code
      _str lineText = indent_string(indentCol) :+ 'Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}")';
      lineText :+= ' = "'folderName'", "'folderName'", "'folderGuidWithBraces'"';
      insert_line(lineText);
      insert_line('EndProject');
   }

   // get the parent folder guid
   curTreeNode := orig_wid._TreeCurIndex();
   typeless curFolderGuid = orig_wid._TreeGetUserInfo(curTreeNode);
   // check if this is the workspace node.  If it is, then we don't have
   // to report a hieracrchy in the workspace file
   isWorkspaceNode := orig_wid._projecttbIsWorkspaceNode();
   if ((curFolderGuid != null) && (curFolderGuid != '') && (isWorkspaceNode == false)) {
      // now add the parent child relationship to the global nested section
      int foundSectionItem = search('GlobalSection(NestedProjects)', '@h');
      if (foundSectionItem == 0) {
         down();
         // get the indentation of the current line
         _first_non_blank();
         int indentCol = p_col - 1;
         up();
         // start building the new line of code
         _str lineText = indent_string(indentCol) :+ folderGuidWithBraces;
         lineText :+= ' = {'curFolderGuid'}';
         insert_line(lineText);
      }
   }

   // save the workspace file
   save();
   p_indent_with_tabs=old_indent_with_tabs;
   // Delete the temp view and set focus back to the project tree control
   activate_window(orig_wid);
   _delete_temp_view(temp_wid);

   _cbsave_project_callback_disabled = false;
   // add the item to the tree
   orig_wid._TreeAddItem(curTreeNode, folderName, TREE_ADD_AS_CHILD, _pic_tfldclos, _pic_tfldopen, 0, 0, folderGuid);
   orig_wid._TreeRefresh();
}

void InsertCsharpProjectFolder(_str ProjectName, _str folderName)
{
   retVal := 0;

   // let's create the folder path first
   folderRelPath :=  folderName :+ '\';
   // now we need to get the current tree index and walk backwards, taking the names
   // of the folders until we get to a project
   curTreeNode := _TreeCurIndex();
   int tempNode = curTreeNode;
   isProjectNode := false;
   do {
      isProjectNode = _projecttbIsProjectNode(tempNode);
      if (isProjectNode == false) {
         folderRelPath = _TreeGetCaption(tempNode) :+ '\' :+ folderRelPath;
         tempNode = _TreeGetParentIndex(tempNode);
      }
   } while (isProjectNode == false);
   int projectNode = tempNode;

   // now we have the relative path, so append that to the project path
   _str projectPath = _parent_path(ProjectName);
   projectFileName := _TreeGetCaption(projectNode);
   folderPath :=  projectPath :+ folderRelPath;
   relPath := "";
   parse projectFileName with projectFileName "\t" relPath;
   vsProjectFileName :=  projectPath :+ projectFileName;

   // next we need to make the directory (if it doesn't already exist)
   if (path_exists(folderPath) == false) {
      retVal = make_path(folderPath);
      // if that fails, warn the user
      if (retVal != 0) {
         _message_box('Unable to create folder 'folderPath'.  Error: 'retVal);
         return;
      }
   }

   // now, let's modify the Visual Studio project file.  
   int temp_wid;
   int orig_wid;
   int status=_open_temp_view(vsProjectFileName, temp_wid, orig_wid);
   if (status != 0) {
      return;
   }
   top();
   up();

   // Make sure there's not already a folder entry for this.
   foundFolderSection := search('<Folder Include="' :+ folderRelPath :+ '" />', '@');
   if (foundFolderSection != 0) {
      // don't forget the case where an item group for project folders doesn't exist
      foundFolderSection = search('<Folder Include=', '@');
      if (foundFolderSection == 0) {
         // get the indentation of the current line
         _first_non_blank();
         int indentCol = p_col - 1;
         // find the end of the item group (we know that we'll find this)
         search('</ItemGroup>', '@');
         // insert the new debug line before the current line
         up();
         // start building the new line of code
         _str lineText = indent_string(indentCol) :+ '<Folder Include="' :+ folderRelPath :+ '" />';
         insert_line(lineText);
      } else {
         // alright, it doesn't exist, so we have to add it ourselves.  The best
         // way to do this is to find the last </ItemGroup> and insert it there.  We'll
         // also have to include the <ItemGroup></ItemGroup> tag.
         bottom();
         foundFolderSection = search('</ItemGroup>', '@-');
         if (foundFolderSection == 0) {
            // get the indentation of the current line
            _first_non_blank();
            int indentCol = p_col - 1;
            // start building the new line of code
            _str lineText = indent_string(indentCol) :+ '<ItemGroup>';
            insert_line(lineText);
            lineText = indent_string(indentCol) :+ '  <Folder Include="' :+ folderRelPath :+ '" />';
            insert_line(lineText);
            lineText = indent_string(indentCol) :+ '</ItemGroup>';
            insert_line(lineText);
         }
      }
      // save the project file
      save();
   }

   // Delete the temp view and set focus back to the project tree control
   activate_window(orig_wid);
   _delete_temp_view(temp_wid);

   // add the item to the tree if it's not already there
   retVal = _TreeSearch(curTreeNode, folderName, 'I');
   if (retVal == -1) {
      orig_wid._TreeAddItem(curTreeNode, folderName, TREE_ADD_AS_CHILD, _pic_tfldclos, _pic_tfldopen, 0, 0, folderName);
   }
   orig_wid._TreeRefresh();
}

static _str VCXProjExtToTask:[] = {
   'cpp'    => 'ClCompile',       
   'cppm'   => 'ClCompile',       
   'c'      => 'ClCompile',       
   'cc'     => 'ClCompile',       
   'cxx'    => 'ClCompile',       
   'h'      => 'ClInclude',       
   'hpp'    => 'ClInclude',       
   'hxx'    => 'ClInclude',       
   'ixx'    => 'ClInclude',       
   'rc'     => 'ResourceCompile',
   'idl'    => 'Midl', 
   'resx'   => 'EmbeddedResource',
   'rdlc'   => 'EmbeddedResource',
   'xsd'    => 'Xsd'  
}; 

void InsertVCXProjFile(_str ProjectName, _str fullPath)
{
   if (fullPath == null || fullPath == '') {
      return;
   }
   filename := relative(fullPath, _strip_filename(ProjectName,'N'));
   if (filename == '') {
      return;
   }

   itemGroup := "None";
   _str ext = _get_extension(filename);
   if(VCXProjExtToTask._indexin(ext)) {
      itemGroup = VCXProjExtToTask:[ext];
   }

   treeNode := _TreeCurIndex();
   folderPath := "";
   if (_projecttbIsFolderNode(treeNode)) {
      folderPath = _TreeGetCaption(treeNode);
      node := _TreeGetParentIndex(treeNode);
      while (node > 0) {
         if (_projecttbIsProjectNode(node)) {
            break;
         }
         caption := _TreeGetCaption(node);
         folderPath = caption:+'\':+folderPath;
         node = _TreeGetParentIndex(node);
      }
   }

   _VCXProjectInsertFile(ProjectName, filename, itemGroup, folderPath);
}

int DeleteVCXProjFile(_str ProjectName, _str fullPath)
{
   filename := relative(fullPath,_strip_filename(ProjectName,'N'));
   if (filename == '') {
      return 0;
   }

   return _VCXProjectDeleteFile(ProjectName, filename);
}

void InsertVCXProjFolder(_str ProjectName, _str folderName = '')
{
   if (folderName=='') {
      typeless status=show('-modal _textbox_form',
                  'Add Folder',
                  0,  //TB_RETRIEVE_INIT, //Flags
                  '', //width
                  '', //help item
                  '', // "OK,Apply to &All,Cancel:_cancel\tCopy file '"SourceFilename"' to",//Button List
                  '', //retrieve name
                  'Folder Name',
                  'Filters (ex. cpp;c;h)'
                  );

      // did they cancel out?
      if (status=='' || _param1=='') {
         return;
      }
      folderName = _param1;
   }

   int subFolderNames:[];
   folderNode := _TreeCurIndex();
   int node = folderNode;
   if (node >= 0) {
      _TreeGetFirstChildIndex(node);
      while (node >= 0) {
         if (_projecttbIsFolderNode(node)) {
            caption := _TreeGetCaption(node);
            subFolderNames:[caption] = 1;
         }
         node=_TreeGetNextSiblingIndex(node);
      }
   }

   if (subFolderNames._indexin(_param1)) {
      _message_box('Folder name already exists: "'_param1'"');
      return;
   }

   _str folderPath = folderName;
   node = folderNode;
   if (node >= 0) {
      while (node > 0) {
         if (_projecttbIsProjectNode(node)) {
            break;
         }
         caption := _TreeGetCaption(node);
         folderPath = caption:+'\':+folderPath;
         node=_TreeGetParentIndex(node);
      }
   }
   _str extensions = _param2;
   folderGuid :=  '{':+guid_create_string('G'):+'}';
   int status = _VCXProjectInsertFolder(ProjectName, folderPath, extensions, folderGuid);
   if (!status) {
      _TreeAddItem(folderNode, folderName, TREE_ADD_AS_CHILD, _pic_tfldclos, _pic_tfldopen, 0, 0);
      _TreeRefresh();
   }
}

void DeleteVCXProjFolder(_str ProjectName)
{
   folderNode := _TreeCurIndex();
   if (!_projecttbIsFolderNode(folderNode)) {
      return;
   }
   folderName := _TreeGetCaption(folderNode);
   node := _TreeGetParentIndex(folderNode);
   _str folderPath = folderName;
   while (node > 0) {
      if (_projecttbIsProjectNode(node)) {
         break;
      }
      caption := _TreeGetCaption(node);
      folderPath = caption:+'\':+folderPath;
      node = _TreeGetParentIndex(node);
   }

   node = _TreeGetFirstChildIndex(folderNode);
   if (node > 0) {
      msg :=  'Delete "' :+ folderName :+ '" and all its contents?';
      int status = _message_box(msg, "", MB_YESNO);
      if (status == IDNO) {
         return;
      }
   }

   _VCXProjectDeleteFolder(ProjectName, folderPath, 1);
}

static bool _IsTreeControl(int treeViewId)
{
   return ( _iswindow_valid(treeViewId) && (treeViewId.p_object == OI_TREE_VIEW));
}

_str vstudio_application_version(_str SolutionFilePath)
{
   bool returned_visual_studio_version;
   _str solutionVer = GetVisualStudioSolutionVersion(SolutionFilePath,returned_visual_studio_version);
   if (returned_visual_studio_version) {
      return solutionVer;
   }
   return SolutionVersionToVStudioVersion(solutionVer);
}

// Opens the .sln file and reads in the version. This is the File version
// and not the Visual Studio (application) version
static _str GetVisualStudioSolutionVersion(_str solutionFile, bool &returned_visual_studio_version)
{
   returned_visual_studio_version=false;
   fileVersion := "";
   if (solutionFile:!='') {
      solutionFullPath := _maybe_quote_filename(solutionFile);
      int temp_wid;
      int orig_wid;
      int status=_open_temp_view(solutionFullPath,temp_wid,orig_wid);
      if (!status)  {
         _str line;
         top();
         //VisualStudioVersion = 12.0.30501.0
         status=search('^VisualStudioVersion *=','@rh');
         if (!status) {
            get_line(line);
            _str major;
            parse line with '=' major '.';
            major=strip(major);
            if (isinteger(major)) {
               returned_visual_studio_version=true;
               activate_window(orig_wid);
               _delete_temp_view(temp_wid);
               return major".0";
            }
         }

         top();
         get_line(line);
         // Sometimes the version # is not on the first line
         if(length(line) < 3) {
            down();
            get_line(line);
         }
         _str sln_version;
         parse line with . 'Version' sln_version .;
         // File format versions are 7.10, 9.0, 10.00, etc.
         // We need to return the version with any trailing
         // zeros stripped off (eg: 10.0)

         sln_version=strip(sln_version);
         // sln_version=substr(sln_version,1,3);
         dotVer := pos('.',sln_version);
         sln_version = substr(sln_version, 1, dotVer + 1);
         fileVersion = sln_version;
         activate_window(orig_wid);
         _delete_temp_view(temp_wid);
      }
   }
   return fileVersion;
}
/**
 * Provides mapping between Solution file (.sln) versions and the
 * Visual Studio (application) version which is used in the 
 * registry and directories.
 * 
 * @param solutionFileVersion
 * 
 * @return Returns Visual Studio register/directory version
 */
static _str SolutionVersionToVStudioVersion(_str solutionFileVersion)
{
   appVersion := "";
   switch (solutionFileVersion) {
   // Visual Studio .NET (2002)
   case '7.0':
      appVersion='7.0';
      break;
   // Visual Studio .NET 2003
   case '8.0':
      appVersion='7.1';
      break;
   // Visual Studio 2005
   case '9.0':
      appVersion='8.0';
      break;
   // Visual Studio 2008
   case '10.0':
      appVersion='9.0';
      break;
   // Visual Studio 2010
   case '11.0':
      appVersion='10.0';
      break;
   // Visual Studio 2012
   case '12.0':
      appVersion='11.0';
      break;
   }
   return appVersion;
}



bool initMenuSolutionConfigs(int menu_handle, _str ProjectFilename=_project_name)
{
   if (_workspace_filename == '' || !file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true))) {
      return false;
   }

   _str configList[];
   _SLNGetSolutionConfigs(_workspace_filename, configList);
   if (!configList._length()) {
      status := _menu_insert(menu_handle,
                             0, // first item
                             MF_GRAYED, // flags
                             "no configuration",  // tool name
                             'project_config_set_active ', // command to do nothing
                             "file",    // category
                             "",  // help command
                             ''       // help message
                             );
      return true;
   }
   activeConfig := gActiveSolutionConfig;
   
   // Insert configurations into the active configuration submenu.
   // Turn on the checkbox for the active configuration.
   for (i := 0; i < configList._length(); ++i) {
      _str configName = configList[i];
      flags := 0;
      // Put a check on the active configuration menu item. If there
      // is no active conguration, default to the first.
      if ((activeConfig == "" && i == 0) || strieq(configList[i], activeConfig)) {
         flags |= MF_CHECKED;
      }
      status:=_menu_insert(menu_handle,
                           i,
                           flags,       // flags
                           configName,  // tool name
                           'solution_config_set_active'  (_workspace_filename!=''?' -p '_maybe_quote_filename(ProjectFilename):'')' '_maybe_quote_filename(configName),   // command
                           "file",    // category
                           "",  // help command
                           ''       // help message
                           );
   }
   return true;
}

_command void solution_config_set_active(_str ConfigName='', _str ProjectFilename=_project_name) name_info(','VSARG2_REQUIRES_PROJECT_SUPPORT|VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      return;
   }

   if (ConfigName == "") return;

   // look for project specified on command line?
   _str cmd_line=ConfigName;
   cmd_arg := "";
   for (;;) {
      cmd_arg = parse_file(cmd_line,false);
      if (cmd_arg=='') break;
      if (cmd_arg=='-p') {
         ProjectFilename = parse_file(cmd_line,false);
      } else {
         ConfigName = cmd_arg;
         break;
      }
   }
   ProjectFilename=strip(ProjectFilename,'B','"');

   status := _GetAssociatedProjectInfo(ProjectFilename, auto VSProjectName);
   if (status) {
      return;
   }
   _SLNSolutionConfigToProjectConfig(_workspace_filename, VSProjectName, ConfigName, auto ProjectConfigName);

   status = -1;
   handle := _ProjectHandle(ProjectFilename);
   _ProjectGet_ConfigNames(handle, auto config_names);

   if (config_names._length() > 0) {
      for (i := 0; i < config_names._length(); ++i) {
         if (ProjectConfigName :== config_names[i]) {
            status = 0; break;
         }
      }

      if (status) {
         parse ProjectConfigName with auto cfgname "|" auto cfgplatform;
         // Check for platformless configs
         for (i = 0; i < config_names._length(); ++i) {
            if (cfgname :== config_names[i]) {
               ProjectConfigName = cfgname; status = 0; break;
            }
         }

         // Remove spaces from Platform (Any CPU => AnyCPU)
         if (status && pos(" ", cfgplatform)) {
            altCfgName := cfgname :+ "|" :+ stranslate(cfgplatform, "", " ");
            for (i = 0; i < config_names._length(); ++i) {
               if (altCfgName :== config_names[i]) {
                  ProjectConfigName = altCfgName; status = 0; break;
               }
            }
         }

         // default to first project config
         if (status) {
            ProjectConfigName = config_names[0];
            status = 0;
         }
      }
   }

   if (status) {
      return;
   }

   project_config_set_active(ProjectConfigName, ProjectFilename, true);

   gActiveSolutionConfig = ConfigName;
   _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename),
                  "Global",
                  "ActiveSolutionConfig",
                  ConfigName);
}

static _str _msbuild_parse_project_command(_str command)
{
   orig_cmd := command;
   pgmname := parse_file(orig_cmd);
   if (!_file_eq(pgmname, "msbuild") || gActiveSolutionConfig:=='') {
      return command;
   }

   parse gActiveSolutionConfig with auto SolutionConfigName '|' auto SolutionPlatformName;

   result := pgmname;
   for (;;) {
      cur := parse_file(orig_cmd);
      if (cur=='') break;

      switch(cur) {
      case '/p:Configuration="%bn"':
         cur = '/p:Configuration="':+SolutionConfigName:+'"';
         break;

      case '/p:Platform="%bp"':
      case '/p:Platform="%bpms"':
         if (SolutionPlatformName :== '') {
            cur = "";
            break;
         }
         cur = '/p:Platform="':+SolutionPlatformName:+'"';
         break;

      default:
         break;
      }

      if (cur != '') {
         result :+= ' 'cur;
      }
   }
   return result;
}

_str _vsproj_parse_project_command(_str command,_str buf_name,
                            _str project_name,_str cword,_str argline='',
                            _str ToolName='',_str ClassPath='', int* recursionStatus = null,
                            _str (*recursionMonitorHash):[] = null,
                            int handle=0,_str config='',
                            _str outputFile='', _str moreWordOptions='', _str moreParenOptions='')
{
   if (_workspace_filename == '' || !file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true))) {
      return _parse_project_command(command,buf_name,project_name,cword,argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash,handle,config,outputFile,moreWordOptions,moreParenOptions);
   }
   msbuild_command := _msbuild_parse_project_command(command);
   return _parse_project_command(msbuild_command,buf_name,project_name,cword,argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash,handle,config,outputFile,moreWordOptions,moreParenOptions);
}

_str _vcproj_parse_project_command(_str command,_str buf_name,
                            _str project_name,_str cword,_str argline='',
                            _str ToolName='',_str ClassPath='', int* recursionStatus = null,
                            _str (*recursionMonitorHash):[] = null,
                            int handle=0,_str config='',
                            _str outputFile='', _str moreWordOptions='', _str moreParenOptions='')
{
   if (_workspace_filename == '' || !file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true))) {
      return _parse_project_command(command,buf_name,project_name,cword,argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash,handle,config,outputFile,moreWordOptions,moreParenOptions);
   }
   msbuild_command := _msbuild_parse_project_command(command);
   return _parse_project_command(msbuild_command,buf_name,project_name,cword,argline,ToolName,ClassPath,recursionStatus,recursionMonitorHash,handle,config,outputFile,moreWordOptions,moreParenOptions);
}

void _workspace_opened_solution_config()
{
   gActiveSolutionConfig = '';
   if (_workspace_filename != '' && file_eq(VISUAL_STUDIO_SOLUTION_EXT, _get_extension(_workspace_filename,true))) {
      _SLNGetSolutionConfigs(_workspace_filename, auto config_names);
      int status = _ini_get_value(VSEWorkspaceStateFilename(_workspace_filename), "Global", "ActiveSolutionConfig", auto info);
      if (!status) {
         for (i := 0; i < config_names._length(); ++i) {
           if (info == config_names[i]) {
              gActiveSolutionConfig = info;
              return;
           }
         }
      }

      if (config_names._length() > 0) {
         gActiveSolutionConfig = config_names[0];
         solution_config_set_active(_maybe_quote_filename(gActiveSolutionConfig),_project_name);
         _ini_set_value(VSEWorkspaceStateFilename(_workspace_filename),
                        "Global",
                        "ActiveSolutionConfig",
                        gActiveSolutionConfig);
      }
   }
}

void _wkspace_close_solution_config() 
{
   gActiveSolutionConfig = '';
   _SLNSolutionConfigClose();
}
