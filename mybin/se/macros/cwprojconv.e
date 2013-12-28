////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49978 $
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
#include "xml.sh"
#import "guiopen.e"
#import "ini.e"
#import "main.e"
#import "projconv.e"
#import "stdprocs.e"
#import "xmlcfg.e"
#import "wkspace.e"
#endregion

/**
 * 
 * Usage: &lt;path&gt;cwprojconv [options] [CWWorkspaceFilename]
 * 
 * Options:
 *    -q
 *    --quiet - Do not prompt user
 * 
 *    -o
 *    --open-on-success - If conversion succeeds, open workspace
 * 
 * If CWWorkspaceFilename not specified you will be prompted
 * with an open file dialog.
 * 
 * For the .psp (CW workspace) file a .vpw file will be created.
 * 
 * For each .pjt (CW project) file a .vpj file will be created.
 * The .vpj file will have the Build, Rebuild, Debug and Execute
 * command from the CW project file.
 * 
 * Custom tools for each project will be brought over.  Since
 * these items were not per configuration orginally, they will
 * be added to each configuration.
 * 
 * Limitations:
 *    * Compile commands are not brought over - single file
 *      compiles are not terribly useful, and CW's build system
 *      was never setup to have build call the compile command,
 *      so it was not worthwhile.
 * 
 *    * Currently, all flags for build items are not converted.
 *      Right now we only convert "Save current file" and "Save
 *      all".
 */

/**
 * Get list of project files from a CW workspace file
 * @param cwWorkspaceFilename Name of workspace file
 * @param projectFileList Array that the will be filled in with
 *                        the project filenames
 * @param absoluteToWorkspace if true filenames are absolute to
 *                            workspace.  Otherwise they are
 *                            relative to the workspace.
 * 
 * @return int 0 if successful
 */
static int CWGetProjectFiles(_str cwWorkspaceFilename,_str (&projectFileList)[],boolean absoluteToWorkspace=false)
{
   // Get the project list from the CWorkspace file
   int status=_ini_get_sections_list(cwWorkspaceFilename,projectFileList,"Project.");
   int i,len=projectFileList._length();
   _str workspacePath=_file_path(cwWorkspaceFilename);

   for (i=0;i<len;++i) {
      // Loop through the project names.  They are stored as section headings as
      // "Project.<projectFilename>", strip the prefix
      _str cur=projectFileList[i];
      cur=substr(cur,9 /*length of "Project."*/);

      // Strip the quotes
      cur=strip(cur,'B','"');

      // Either strip the leading ".\", or convert to absolute depending on the
      // value of absoluteToWorkspace
      if ( absoluteToWorkspace ) {
         cur=absolute(cur,workspacePath);
      }else{
         if ( substr(cur,1,2)==".":+FILESEP ) {
            cur=substr(cur,3);
         }
      }

      // Save in list
      projectFileList[i]=cur;
   }
   return status;
}

// These are the defaults filters - if there are no filters set in the 
static _str gCWDefaultFilters:[]={
   "Source Files"=>"*.c;*.cs;*.cpp;*.cxx;*.hxx;*.prg;*.pas;*.asm;*.bas;*.sc;*.jav*;*.go",
   "Header Files"=>"*.h;*.hpp;*.inc",
   "Web Files"=>"*.htm;*.html;*.shtm;*.asp;*.css",
   "XML Files"=>"*.xml;*.xsl;*.dtd;*.xhtml;*.xdr;*.dcd",
   "Resources"=>"*.rc;*.bmp;*.ico;*.cur;*.dlg",
   "Other Files"=>"*.*"
};

/**
 * Get the file filters from a CW project file
 * If there are not filters, it uses the default ones that CW
 * would use in that case (stored in gCWDefaultFilters)
 * @param cwProjectFilename Filename of CW project
 * @param projectFilters Hashtab that gets the filters - Index
 *                       is the name of the filters, and the
 *                       value is a semi-colon delimited list of
 *                       filters
 * 
 * @return int 0 if successful
 */
static int CWGetFilters(_str cwProjectFilename,_str (&projectFilters):[])
{
   _str projectFiltersFromFile[]=null;
   int status=_ini_get_all_values(cwProjectFilename,"Editor","FilterProjAdd",projectFiltersFromFile);
   if ( status ) {
      projectFilters=gCWDefaultFilters;
      status=0;
   }else{
      int i,len=projectFiltersFromFile._length();
      for (i=0;i<len;++i) {
          _str htindex,value;
         parse projectFiltersFromFile[i] with "'"htindex"','" value "'";
         projectFilters:[htindex]=value;
      }
   }
   return status;
}

/**
 * Copy the list of filters from a CW project files into a
 * SlickEdit project file
 * @param seProjectHandle Handle to SlickEdit destination file
 * @param cwProjectFilename Filename of CW project
 * 
 * @return int
 */
static int copyFiltersToSEProject(int seProjectHandle,_str cwProjectFilename)
{
   int status=0;
   do {
      //Get Filters from CW project
      _str projectFilters:[]=null;
      status=CWGetFilters(cwProjectFilename,projectFilters);
      break;
   
      // Loop through hashtab returned by CWGetFilters, and add each filter to the 
      // SlickEdit project file
      typeless i;
      for (i._makeempty();;) {
         projectFilters._nextel(i);
         if ( i==null ) break;
         //  First add name node
         int nodeIndex=_xmlcfg_set_path2(seProjectHandle,VPJX_FILES,VPJTAG_FOLDER,"Name",i);
         // Set "Filters" attribute
         _xmlcfg_set_attribute(seProjectHandle,nodeIndex,"Filters",projectFilters:[i]);
      }
   } while ( false );

   return status;
}

/**
 * Copy the list of files from a CW project files into a
 * SlickEdit project file. 
 *
 * @param seProjectHandle Handle to SlickEdit destination file
 * @param cwProjectFilename Filename of CW project
 * 
 * @return 0 on success, <0 on error.
 */
static int copyFilesToSEProject(int seProjectHandle, _str cwProjectFilename)
{
   // Get Files from CW project file
   _str projectFileList[] = null;
   int status = _ini_get_section_array(cwProjectFilename,"Files",projectFileList);

   if( 0 == status ) {
      // Strip off any relative './'
      int i, n=projectFileList._length();
      for( i=0; i < n; ++i ) {
         if( substr(projectFileList[i],1,2) == ".":+FILESEP ) {
            projectFileList[i] = substr(projectFileList[i],3);
         }
      }
      // Add files to SlickEdit project
      _ProjectAdd_Files(seProjectHandle,projectFileList);
   }
   return status;
}

// Has the command and CW's flags for each command
struct CWCOMMAND {
   _str commandTitle;
   _str command;
   int commandFlags;
};
struct COMMANDSET {
   _str configName;
   CWCOMMAND buildCommand;
   CWCOMMAND rebuildCommand;
   CWCOMMAND debugCommand;
   CWCOMMAND executeCommand;
};

/**
 * Get all of the commands from the CW project file
 * @param seProjectHandle Handle to SlickEdit destination file
 * @param cwProjectFilename Filename of CW project
 * @param commandSet Receives all of the command info for each
 *                   config
 * 
 * @return int
 */
static int CWGetCommands(int seProjectHandle,_str cwProjectFilename,COMMANDSET (&commandSet)[])
{
   // Get Files from CW project file
   _str projectCommandsFromFile[]=null;
   int status=_ini_get_all_values(cwProjectFilename,"Compiler","CompilerAddCmdEx",projectCommandsFromFile);

   if ( !status ) {
      // Add files to SlickEdit project
      int i,len=projectCommandsFromFile._length();
      for (i=0;i<len;++i) {
         int commandSetLen=commandSet._length();
         _str curConfig=projectCommandsFromFile[i];

         _str curConfigName=parse_comma(curConfig);
         curConfigName=strip(curConfigName,'B',"'");
         parse curConfigName with curConfigName "|" .;

         _str junk=parse_comma(curConfig);  // Throw away
         junk=parse_comma(curConfig);       // Throw away
         junk=parse_comma(curConfig);       // Throw away
         junk=parse_comma(curConfig);       // Throw away

         _str buildCommand=parse_comma(curConfig);
         _str buildCommandFlags=parse_comma(curConfig);
         parse_comma(curConfig);  // Throw away - I think this is the build command default
         parse_comma(curConfig);  // Throw away
         
         _str rebuildCommand=parse_comma(curConfig);
         _str rebuildCommandFlags=parse_comma(curConfig);
         parse_comma(curConfig);  // Throw away - I think this is the rebuild command default
         parse_comma(curConfig);  // Throw away

         _str debugCommand=parse_comma(curConfig);
         _str debugCommandFlags=parse_comma(curConfig);

         _str executeCommand=parse_comma(curConfig);
         _str executeCommandFlags=parse_comma(curConfig);

         commandSet[commandSetLen].configName=curConfigName;
         commandSet[commandSetLen].buildCommand.command=buildCommand;
         commandSet[commandSetLen].buildCommand.commandFlags=(int)buildCommandFlags;
         commandSet[commandSetLen].rebuildCommand.command=rebuildCommand;
         commandSet[commandSetLen].rebuildCommand.commandFlags=(int)rebuildCommandFlags;
         commandSet[commandSetLen].debugCommand.command=debugCommand;
         commandSet[commandSetLen].debugCommand.commandFlags=(int)debugCommandFlags;
         commandSet[commandSetLen].executeCommand.command=executeCommand;
         commandSet[commandSetLen].executeCommand.commandFlags=(int)executeCommandFlags;
      }
   }
   return status;
}

/**
 * Get the user created tools from the CW project file
 * @param seProjectHandle Handle to SlickEdit destination file
 * @param cwProjectFilename Filename of CW project
 * @param commandSet Receives all of the command info for each
 *                   custom tool
 * 
 * @return int 0 if successful
 */
static int CWGetTools(int seProjectHandle,_str cwProjectFilename,CWCOMMAND (&commandSet)[])
{
   // Get Files from CW project file
   _str projectToolsFromFile[]=null;
   int status=_ini_get_all_values(cwProjectFilename,"Tools","ToolAddCmd",projectToolsFromFile);

   if ( !status ) {
      int i,len=projectToolsFromFile._length();
      for (i=0;i<len;++i) {
         _str cur=projectToolsFromFile[i];
         parse_comma(cur);  // Throw away
         _str title=parse_comma(cur);
         title=strip(title,'B',"'");
         int commandSetLen=commandSet._length();
         commandSet[commandSetLen].commandTitle=title;

         parse_comma(cur);  // Throw away
         _str command=parse_comma(cur);
         command=strip(command,'B',"'");
         commandSet[commandSetLen].command=command;
         commandSet[commandSetLen].commandFlags=0;
      }
   }
   return status;
}

/**
 * Copy the list of files from a CW project files into a
 * SlickEdit project file
 * @param seProjectHandle Handle to SlickEdit destination file
 * @param cwProjectFilename Filename of CW project
 * 
 * @return int 0 if successful
 */
static int copyCommandsToProject(int seProjectHandle,_str cwProjectFilename,_str (&configList)[]=null)
{
   COMMANDSET commandSet[];
   int status=CWGetCommands(seProjectHandle,cwProjectFilename,commandSet);
   if ( status ) {
      return status;
   }
   int commandSetLen=commandSet._length();

   CWCOMMAND toolsSet[];
   CWGetTools(seProjectHandle,cwProjectFilename,toolsSet);
   int toolsSetLen=toolsSet._length();

   int i;
   for (i=0;i<commandSetLen;++i) {
      configList[configList._length()]=commandSet[i].configName;
      int nodeIndex=_xmlcfg_set_path2(seProjectHandle,VPJX_PROJECT,VPJTAG_CONFIG,"Name",commandSet[i].configName);

      int menuIndex=_xmlcfg_add(seProjectHandle,nodeIndex,"Menu",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

      AddTarget(seProjectHandle,menuIndex,commandSet[i].buildCommand,"Build","&Build");
      AddTarget(seProjectHandle,menuIndex,commandSet[i].rebuildCommand,"Rebuild","&Rebuild");
      AddTarget(seProjectHandle,menuIndex,commandSet[i].debugCommand,"Debug","&Debug");
      AddTarget(seProjectHandle,menuIndex,commandSet[i].executeCommand,"Execute","&Execute");
      
      int j;
      for (j=0;j<toolsSetLen;++j) {
         AddTarget(seProjectHandle,menuIndex,toolsSet[j],toolsSet[j].commandTitle,toolsSet[j].commandTitle);
      }
   }
   return status;
}

/**
 * Add a target to the SE project file
 * @param seProjectHandle handle to SE Project file
 * @param menuIndex index of Menu tag in SE Project file
 * @param targetCommand Structure for this command in CW
 * @param TargetName Name of this command
 * @param MenuCaption Menu caption for this command
 */
static void AddTarget(int seProjectHandle,int menuIndex,CWCOMMAND targetCommand,_str TargetName,_str MenuCaption)
{
   int buildTargetIndex=_xmlcfg_add(seProjectHandle,menuIndex,"Target",VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(seProjectHandle,buildTargetIndex,"Name",TargetName);
   _xmlcfg_set_attribute(seProjectHandle,buildTargetIndex,"MenuCaption",MenuCaption);
   _xmlcfg_set_attribute(seProjectHandle,buildTargetIndex,"CaptureOutputWith","ProcessBuffer");
   _xmlcfg_set_attribute(seProjectHandle,buildTargetIndex,"Deleteable",0);
   _str saveOption="SaveNone";

   if ( targetCommand.commandFlags&128 ) {
      // CW save all
      saveOption="SaveAll";
   }else if ( targetCommand.commandFlags&64 ) {
      // CW save cur
      saveOption="SaveCurrent";
   }
   _xmlcfg_set_attribute(seProjectHandle,buildTargetIndex,"SaveOption",saveOption);

   int buildTargetExecIndex=_xmlcfg_add(seProjectHandle,buildTargetIndex,"Exec",VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   _str command=targetCommand.command;
   command=strip(command,'B',"'");
   _xmlcfg_set_attribute(seProjectHandle,buildTargetExecIndex,"CmdLine",command);
}

/**
 * Parses Comment delimited piece from string.
 * 
 * @param line line to parse comma delimited section from.
 *             Section will be removed from this variable
 * 
 * @return First comma delimited section
 * 
 */ 
static _str parse_comma(var line)
{
   line=strip(line,'B');
   if ( line=="" ) {
      return "";
   }
   _str word="";

   int i=1;
   for (;;++i) {
      _str ch=substr(line,i,1);
      if ( ch==',' || i>length(line)) {
         word=substr(line,1,i-1);
         line=substr(line,i+1);
         break;
      }else if ( ch=="'" || ch=='"' ) {
         int p=pos(ch,line,i+1);
         if ( p ) {
            i=p;
         }else{
            word=line;
            line="";
            break;
         }
      }
   }
   return word;
}

/**
 * Loads a CW project and exports a SlickEdit project
 * 
 * @param cwProjectFilename Filename of CW project
 * 
 * @return int 0 if project successfully exported
 */
static int ExportSEProject(_str cwProjectFilename)
{
   int status=0;
   // Calcluate project name
   _str seProjectFilename=_strip_filename(cwProjectFilename,'E'):+PRJ_FILE_EXT;
   seProjectFilename=absolute(seProjectFilename,_file_path(cwProjectFilename));

   do {
      // Create the project
      int seProjectHandle=_ProjectCreate(seProjectFilename);
      if ( seProjectHandle<0 ) break;

      // Create filters, then add files
      status=copyFiltersToSEProject(seProjectHandle,cwProjectFilename);
      if ( status ) break;

      status=copyFilesToSEProject(seProjectHandle,cwProjectFilename);
      // Project does not necessarily have files
      if ( status && status!=STRING_NOT_FOUND_RC ) break;

      _str configList[]=null;
      status=copyCommandsToProject(seProjectHandle,cwProjectFilename,configList);
      if ( status ) break;

      // Save and close
      status=_ProjectSave(seProjectHandle);
      _xmlcfg_close(seProjectHandle);
      if ( status ) break;

   } while ( false );

   return status;
}

/**
 * Loads cwWorkspaceFilename and exports a SlickEdit workspace
 * file for that, and SlickEdit project files for each CW
 * project file
 * @param cwProjectFilename Filename of CW workspace
 * 
 * @return int 0 if successful
 */
static int ExportSEWorkspace(_str cwWorkspaceFilename,_str &seWorkspaceFilename="")
{
   seWorkspaceFilename=_strip_filename(cwWorkspaceFilename,'E'):+WORKSPACE_FILE_EXT;
   int status=0;
   do {
      int workspaceHandle=_WorkspaceCreate(seWorkspaceFilename);
      if ( workspaceHandle<0) break;

      _str projectFileList[];
      status=CWGetProjectFiles(cwWorkspaceFilename,projectFileList);
      if ( status ) break;

      int i,len=projectFileList._length();
      for (i=0;i<len;++i) {
         _WorkspaceAdd_Project(workspaceHandle,_strip_filename(projectFileList[i],'E'):+PRJ_FILE_EXT,true);
      }
      status=_WorkspaceSave(workspaceHandle);
      _xmlcfg_close(workspaceHandle);

      for (i=0;i<len;++i) {
         status=ExportSEProject(absolute(projectFileList[i],_file_path(strip(seWorkspaceFilename,'B','"'))));
         if ( status ) {
            //_message_box(nls("Could not export SlickEdit project file for %s\n\n%s",projectFileList[i],get_message(status)));
            break;
         }
      }
   } while ( false );
   return status;
}

/**
 * Converts codewright workspace and all of its projects.  Puts
 * .vpw and .vpj files in the same directory as their CW
 * counterparts
 * @param cwProjectFilename Filename of CW workspace
 * 
 * @return int 0 if successful
 */
int ConvertCWWorkspace(_str cwWorkspaceFilename,_str &seWorkspaceFilename="")
{
   int status=0;

   if ( cwWorkspaceFilename=="" ) {
      cwWorkspaceFilename=_OpenDialog('-new -mdi -modal',
                                      'Convert CodeWright Workspace',
                                      '*.psp',     // Initial wildcards
                                      "CodeWright Workspace Files (*.psp)",  // file types
                                      OFN_FILEMUSTEXIST,
                                      WORKSPACE_FILE_EXT,      // Default extensions
                                      '',      // Initial filename
                                      '',      // Initial directory
                                      '',      // Reserved
                                      "Standard Open dialog box"
                                      );
      if ( cwWorkspaceFilename=="" ) {
         return COMMAND_CANCELLED_RC;
      }
   }
   status=ExportSEWorkspace(cwWorkspaceFilename,seWorkspaceFilename);
   if ( status ) {
      //_message_box(nls("Could not export SlickEdit workspace file\n\n%s",get_message(status)));
      return status;
   }
   return status;
}

/**
 * Get options and workspace filename from the command line that
 * was passed in
 * 
 * @param commandLine Command line passed in from defmain
 * @param cwWorkspaceFilename Will receive the workspace
 *                            filename parsed of of the command
 *                            line
 * @param quiet   true if the command line contains "-q" or
 *                "--quiet"
 * @param openOnSuccess true if command line contains "-o" or
 *                      "--open-on-success"
 * 
 * @return int
 */
static int getOptions(_str commandLine,_str &cwWorkspaceFilename,boolean &quiet,
                      boolean &openOnSuccess)
{
   quiet=false;
   openOnSuccess=false;
   _str cur="";
   for (;;) {
      cur=parse_file(commandLine);
      if ( cur=="" || substr(cur,1,1)!='-' ) break;
      switch (lowcase(cur)) {
      case "-q":
      case "--quiet":
         quiet=true;break;
      case "-o":
      case "--open-on-success":
         openOnSuccess=true;break;
      default:
         _message_box(nls("Unkown option '%s'",cur));
         return INVALID_ARGUMENT_RC;
      }
   }
   cwWorkspaceFilename=strip(cur);
   return 0;
}

/**
 * When 12.0 ships, we could make this a command instead.  Try
 * to keep this pretty small.
 */
defmain()
{
   boolean quiet=false;
   boolean openOnSuccess=false;
   _str cwWorkspaceFilename="";

   int status=getOptions(arg(1),cwWorkspaceFilename,quiet,openOnSuccess);
   if ( status ) {
      return status;
   }

   _str seWorkspaceFilename="";
   status=ConvertCWWorkspace(cwWorkspaceFilename,seWorkspaceFilename);
   if ( !status ) {
      int result=0;
      if ( !quiet && !openOnSuccess ) {
         result=_message_box(nls("The workspace '%s' has been generated, do you wish to open it now?",seWorkspaceFilename),"",MB_YESNO);
      }
      if ( openOnSuccess || result==IDYES ) {
         status=workspace_open(seWorkspaceFilename);
      }
   }else{
      if ( !quiet ) {
         _message_box(nls("Could not export workspace\n\n%s",get_message(status)));
      }
   }
   return status;
}
