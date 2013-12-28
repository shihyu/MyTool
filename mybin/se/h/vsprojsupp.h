////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38578 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc.
////////////////////////////////////////////////////////////////////////////////////
#ifndef VS_DEBUG_H
#define VS_DEBUG_H

// projsupp.h - Native code project support routines
#include "vsdecl.h"
#include "slickedit/SEString.h"
#include "slickedit/SEArray.h"

/**
 * Inserts the full Xcode project hierarchy into the project 
 * tool window's tree control 
 * 
 * @param projectPath 
 * @param treeID 
 * @param iParentIndex 
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _InsertXcodeProjectHierarchy(VSPSZ projectPath, int treeID, int iParentIndex);

/**
 * Inserts a flat list of all Xcode project files into a list 
 * control or editor view 
 * 
 * @param projectPath Full path to Xcode .pbxproj file
 * @param windowID List view or editor window ID
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _InsertXcodeProjectFileList(VSPSZ projectPath, int windowID, int absPaths);

/**
 * Gets all the "ConfigName|TargetName" values from an Xcode 
 * project.  
 * @remarks At some future date, this may be expanded to include 
 *              explicity SDK references, e.g.
 *              ConfigName|SDKName|TargetName
 * @param projectPath Full path to Xcode .pbxproj file
 * @param configNamesArrayRef Destintation array of _str values
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _GetXcodeProjectConfigurations(VSPSZ projectPath, VSHREFVAR configNamesArrayRef);

/**
 * Gets the Xcode project's build output filename (eg: 
 * ./build/Debug/MyApplication.app) 
 * 
 * @param projectPath Full path to Xcode .pbxproj file
 * @param configName Active configuration name
 * @param outputFilePath Return value to receive the file path
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _GetXcodeProjectOutputFilename(VSPSZ projectPath, VSPSZ configName, VSPSZ sdkName, VSHREFVAR outputFilePath);

/**
 * @param projectPath Full path to Xcode .pbxproj file
 * @param configName Active configuration name
 * @param sdkRoot Return value to sdkRoot value
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _GetXcodeProjectSDKRoot(VSPSZ projectPath, VSPSZ configName, VSHREFVAR sdkRoot);

/**
 * Returns the top-level project object's name
 * @param projectPath Full path to Xcode .pbxproj file
 * @param outputProjectName Return value ( _str reference)
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _GetXcodeProjectName(VSPSZ projectPath, VSHREFVAR outputProjectName);

/**
 * Returns all the schemes defined for an Xcode 
 * workspace/project. Only available on 
 * the Mac. No-op on other platforms. 
 * @param path Full path to .xcworkspace or .xcodeproj bundle
 * @param schemesArrayRef Destintation array of _str values
 * 
 * @return int 
 */
EXTERN_C int VSAPI _GetXcodeWorkspaceSchemes(VSPSZ workspacePath, VSHREFVAR schemesArrayRef);

/**
 * Ensures no 'stale' state is left behind when an Xcode project 
 * is closed. Called from the _wkspace_close_xcode callback
 * 
 * @return int VSAPI 
 */
EXTERN_C void VSAPI _XcodeProjectClosed();

slickedit::SEString vsXcodeGetProjectName(const slickedit::SEString &projectPath);

/**
 * Inserts the full Visual Studio .vcxproj project 
 * hierarchy into the project tool window's tree 
 * control 
 * 
 * @param projectPath Full path to .vcxproj project file
 * @param isFilterFile 
 * @param treeID 
 * @param iParentIndex 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _InsertVCXProjectHierarchy(VSPSZ projectFilePath, int isFilterFile, int treeID, int iParentIndex);


/**
 * Inserts a flat list of all project files in a Visual Studio 
 * .vcxproj file 
 * 
 * @param projectPath Full path to .vcxproj project file 
 * @param xmlHandle Handle to xmlcfg document to use 
 * @param viewListID List view or editor window ID 
 * @param indentSpace If true, prepend each line with a space 
 *                    character, for listbox formats
 * 
 * @return int Zero on success
 */
EXTERN_C int VSAPI _InsertVCXProjectFileList(VSPSZ projectFilePath, int xmlHandle, int viewListID, int absPaths, int indentSpace);

EXTERN_C int VSAPI _VCXProjectInsertFile(VSPSZ projectFilePath, VSPSZ filename, VSPSZ itemname, VSPSZ folderPath);
EXTERN_C int VSAPI _VCXProjectDeleteFile(VSPSZ projectFilePath, VSPSZ fileName);
EXTERN_C int VSAPI _VCXProjectInsertFolder(VSPSZ projectFilePath, VSPSZ folderPath, VSPSZ extensions, VSPSZ uuid);
EXTERN_C int VSAPI _VCXProjectDeleteFolder(VSPSZ projectFilePath, VSPSZ folderPath, int removeFiles);

/**
 * Handles exporting (vsLibExport) the Project Support 
 * routines needed by Slick-C 
 */
void projectSupport_initExports();


EXTERN_C
void VSAPI scClearWorkspaceFileListCache();

EXTERN_C
void VSAPI scOpenNewWorkspaceFileListCache(VSPSZ workspaceFile);

EXTERN_C
void VSAPI scClearProjectFileListCache(VSPSZ workspaceFile, VSPSZ projectFile);

EXTERN_C
int VSAPI scGetNumProjectFiles(VSPSZ workspaceFile, VSPSZ projectFile);

EXTERN_C
int VSAPI scIsProjectInfoCached(VSPSZ workspaceFile, VSPSZ projectFile);

EXTERN_C
int VSAPI scGetProjectFiles(VSPSZ workspaceFile, VSPSZ projectFile, VSHREFVAR filelist, int absolute, int projectHandle = -1);

EXTERN_C
void VSAPI scProjectMatchFile(VSPSZ workspaceFile, VSPSZ projectFile, VSPSZ file, VSHREFVAR filelist,int append);

EXTERN_C
VSPSZ VSAPI scProjectFindFile(VSPSZ workspaceFile, VSPSZ projectFile, VSPSZ file, 
                              int checkPath = 1, int returnAll = 0, int matchPathSuffix = 0);

EXTERN_C
int VSAPI scIsFileInProject(VSPSZ workspaceFile, VSPSZ projectFile, VSPSZ file);

EXTERN_C
int VSAPI scGetProjectFilesInWorkspace(VSPSZ workspaceFile, VSHREFVAR projFileList);

EXTERN_C
int VSAPI scGetWorkspaceFiles(VSPSZ workspaceFile, VSHREFVAR filelist);

EXTERN_C
int VSAPI scProjectBuildTree(VSPSZ workspaceFile, VSPSZ projectFile,
                             int handle,
                             int iMaxSccNum,
                             int iCurrentVCSIsScc,
                             int iParentIndex,
                             int NormalizeFolderNames,
                             int RefilterWildcards);

VSDLLEXPORT int SEGetNumProjectFiles(const slickedit::SEString &workspaceFile, 
                                        const slickedit::SEString &projectFile, 
                                        int projectHandle = -1);

VSDLLEXPORT int SEGetProjectFiles(const slickedit::SEString &workspaceFile, 
                                  const slickedit::SEString &projectFile,
                                  slickedit::SEArray<slickedit::SEString> &filelist, 
                                  bool absolute, int projectHandle = -1);

VSDLLEXPORT void SEProjectMatchFile(const slickedit::SEString &workspaceFile, const slickedit::SEString &projectFile,
                                    const slickedit::SEString &file, slickedit::SEArray<slickedit::SEString> &filelist);

VSDLLEXPORT slickedit::SEString SEProjectFindFile(const slickedit::SEString &workspaceFile, const slickedit::SEString &projectFile,
                                                  const slickedit::SEString &file, bool checkPath = true, bool returnAll = false, bool matchPathSuffix = false);

VSDLLEXPORT slickedit::SEString SEWorkspaceFindFile(const slickedit::SEString &workspaceFile, const slickedit::SEString &file, 
                                                    bool checkPath, bool returnAll, bool matchPathSuffix);

VSDLLEXPORT bool SEIsFileInProject(const slickedit::SEString &workspaceFile, 
                                   const slickedit::SEString &projectFile,
                                   const slickedit::SEString file);

VSDLLEXPORT int SEGetProjectFilesInWorkspace(const slickedit::SEString &workspaceFile, 
                                             slickedit::SEArray<slickedit::SEString> &projFileList);

VSDLLEXPORT int SEGetWorkspaceFiles(const slickedit::SEString &workspaceFile, 
                                    slickedit::SEArray<slickedit::SEString> &filelist);

struct SEWildcardInfo {
   slickedit::SEString m_wildcard;
   slickedit::SEString m_excludes;
   bool m_recursive;
};

VSDLLEXPORT int SEGetWildcardFiles(const slickedit::SEString &projectPath, 
                                   const slickedit::SEArray<SEWildcardInfo> &wildcards, 
                                   slickedit::SEArray<slickedit::SEString> &files);

EXTERN_C void VSAPI scProjectSetDependencyExtensions(VSPSZ dependencyExt);


EXTERN_C void VSAPI scSetVisualStudioMSBuildProjectExtensions(VSPSZ extensionlist);
#endif
