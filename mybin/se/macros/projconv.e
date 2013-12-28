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
#include "project.sh"
#include "unittest.sh"
#include "xml.sh"
#import "cjava.e"
#import "complete.e"
#import "compile.e"
#import "files.e"
#import "gnucopts.e"
#import "ini.e"
#import "main.e"
#import "makefile.e"
#import "mprompt.e"
#import "picture.e"
#import "project.e"
#import "projutil.e"
#import "refactor.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "util.e"
#import "vc.e"
#import "xcode.e"
#import "xmlcfg.e"
#import "wkspace.e"
#require "se/lang/api/LanguageSettings.e"
#require "se/options/DialogExporter.e"
#endregion

using se.lang.api.LanguageSettings;

struct NEWFOLDERINFO {
   _str FolderName;
   _str Filters;
};

static NEWFOLDERINFO NewFolderInfo[]={
   {"Source Files", "*.c;*.C;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.prg;*.pas;*.dpr;*.asm;*.s;*.bas;*.java;*.cs;*.sc;*.e;*.cob;*.html;*.rc;*.tcl;*.py;*.pl;*.d;*.m;*.mm;*.go"},
   {"Header Files", "*.h;*.H;*.hh;*.hpp;*.hxx;*.inc;*.sh;*.cpy;*.if"},
   {"Resource Files","*.ico;*.cur;*.dlg"},
   {"Bitmaps","*.bmp"},
   {"Other Files",""},
};

static _str filterDefaultName[];

// Note: We have to use a hash table for pattern, app command, and file association
//       because the user project file may have the filter names in a different order
//       from what we default here. These hash tables are keyed on the lowcased
//       filter names.
static _str filterDefaultPattern:[]= {
#if __UNIX__
   "source files"   => "*.c;*.C;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.C++;*.prg;*.pas;*.dpr;*.asm;*.s;*.bas;*.java;*.sc;*.e;*.cob;*.html;*.rc;*.tcl;*.py;*.pl;*.d;*.go"
   ,"header files"  => "*.h;*.H;*.hh;*.hpp;*.hxx;*.inc;*.sh;*.cpy;*.if"
   ,"resource files"=> "*.ico;*.cur;*.dlg"
   ,"bitmaps"       => "*.bmp;*.xpm;*.xbm"
   ,"other files"   => ALLFILES_RE
#else
   "source files"   => "*.c;*.cc;*.cpp;*.cp;*.cxx;*.c++;*.prg;*.pas;*.dpr;*.asm;*.bas;*.java;*.cs;*.sc;*.e;*.cob;*.html;*.rc;*.tcl;*.py;*.pl;*.vb;*.d;*.go"
   ,"header files"  => "*.h;*.hh;*.hpp;*.hxx;*.inc;*.sh;*.cpy;*.if"
   ,"resource files"=> "*.ico;*.cur;*.dlg"
   ,"bitmaps"       => "*.bmp"
   ,"other files"   => ALLFILES_RE
#endif
};
static int filterDefaultFileAssociation:[]= {
#if __UNIX__
   "source files"   => 0
   ,"header files"  => 0
   ,"resource files"=> 0
   ,"bitmaps"       => 0
   ,"other files"   => 0
#else
   "source files"   => 0
   ,"header files"  => 0
   ,"resource files"=> 1
   ,"bitmaps"       => 1
   ,"other files"   => 0
#endif
};
static _str filterDefaultAppCommand:[]= {
   "source files"   => ""
   ,"header files"  => ""
   ,"resource files"=> ""
#if __UNIX__
   ,"bitmaps"       => "xv %f"
#else
   ,"bitmaps"       => ""
#endif
   ,"other files"   => ""
};

_str _NormalizeFile(_str filename,boolean doNormalizeFile=true)
{
   if (!doNormalizeFile) {
      return(filename);
   }
   return(translate(filename,'/','\'));
}

static void AddFiles(int handle,_str ProjectFilename,_str ConfigList[])
{
   if (_DataSetSupport()) {
      filterDefaultPattern:['data sets']=ALLFILES_RE;
      filterDefaultFileAssociation:['data sets']=0;
      filterDefaultAppCommand:['data sets']="";
   } else {
      filterDefaultPattern._deleteel('data sets');
      filterDefaultFileAssociation._deleteel('data sets');
      filterDefaultAppCommand._deleteel('data sets');
   }
   filterDefaultName._makeempty();
   filterDefaultName[filterDefaultName._length()]="Source Files";
   filterDefaultName[filterDefaultName._length()]="Header Files";
   filterDefaultName[filterDefaultName._length()]="Resource Files";
   filterDefaultName[filterDefaultName._length()]="Bitmaps";
   if (_DataSetSupport()) {
      filterDefaultName[filterDefaultName._length()]="Data Sets";
   }
   filterDefaultName[filterDefaultName._length()]="Other Files";


   int orig_wid=p_window_id;
   int form_wid=_create_window(OI_FORM,_desktop,'Temp Form',0,0,400*15,400*15,CW_PARENT|CW_HIDDEN,BDS_DIALOG_BOX);
   int tree_wid=_create_window(OI_TREE_VIEW,form_wid,'',5,5,300*15,300*15,CW_CHILD,BDS_SUNKEN);
   tree_wid.p_eventtab2=defeventtab _ul2_tree;
   toolbarBuildFilterList2(ProjectFilename,ConfigList,tree_wid,handle);
   form_wid._delete_window();
}
static _str SaveIndexToString(int index)
{
   if (index== SAVECURRENT) {
      return(VPJ_SAVEOPTION_SAVECURRENT);
   } else if (index== SAVEALL) {
      return(VPJ_SAVEOPTION_SAVEALL);
   } else if (index== SAVEMODIFIED) {
      return(VPJ_SAVEOPTION_SAVEMODIFIED);
   } else if (index== SAVENONE) {
      return(VPJ_SAVEOPTION_SAVENONE);
   } else if (index== SAVEWORKSPACEFILES) {
      return(VPJ_SAVEOPTION_SAVEWORKSPACEFILES);
   }
   return('');
}
static boolean isPredefinedTool(_str key,_str &name,_str &caption,boolean &isPredefined)
{
   if (pos(APPTOOLNAMEKEYPREFIX, key, 1, "I")==1) {
      //say('key='key);
      parse key with '_' key '_';
   }
   name='';
   caption='';
   isPredefined=false;
   switch (key) {
   case 'compile':
      name='Compile';
      caption='&Compile';
      isPredefined=true;
      return(isPredefined);
   case 'link':
      name='Link';
      caption='&Link';
      isPredefined=true;
      return(isPredefined);
   case 'make':
      name='Build';
      caption='&Build';
      isPredefined=true;
      return(isPredefined);
   case 'rebuild':
      name='Rebuild';
      caption='&Rebuild';
      isPredefined=true;
      return(isPredefined);
   case 'debug':
      name='Debug';
      caption='&Debug';
      isPredefined=true;
      return(isPredefined);
   case 'execute':
      name='Execute';
      caption='E&xecute';
      isPredefined=true;
      return(isPredefined);
   case 'clean':
      name='Clean';
      caption='Clean';
      isPredefined=true;
      return(isPredefined);
   case 'user1':
      name='User 1';
      caption='User 1';
      isPredefined=true;
      return(isPredefined);
   case 'user2':
      name='User 2';
      caption='User 2';
      isPredefined=true;
      return(isPredefined);
   case 'usertool_view_javadoc':
      name='View Javadoc';
      caption='&View Javadoc';
      isPredefined=true;
      return(isPredefined);
   case 'usertool_javadoc_all':
      name='Javadoc All';
      caption='Javadoc All';
      isPredefined=true;
      return(isPredefined);
   case 'usertool_make_jar':
      name='Make Jar';
      caption='Make &Jar';
      isPredefined=true;
      return(isPredefined);
   case 'usertool_java_options':
      name='Java Options';
      caption='Java &Options';
      isPredefined=true;
      return(isPredefined);
   }
   return(isPredefined);
}

////////////////////////////////////////////////////////////////////////////////
//11:09am 7/7/1999
//This is the fix for the problem where project files can have two includedirs
//lines.
static void _fix_project_file(_str ProjectName=_project_name)
{
   _str include_line='%(include)';
   int orig_view_id;
   int temp_view_id;
   get_window_id(orig_view_id);
   int status=_ini_get_section(ProjectName, "COMPILER", temp_view_id);
   if (status) {
      return;
   }

   activate_window(temp_view_id);
   top(); up();
   status=search('INCLUDEDIRS=','i@h');
   if (status) {
      //this should not happen, no includedirs line
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return;
   }
   status=repeat_search();
   if (status) {
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return;
   }
   _delete_line();

   activate_window(orig_view_id);
   status=_ini_put_section(ProjectName, "COMPILER", temp_view_id);
   if (!status) {
      _WorkspacePutProjectDate(ProjectName);
   }
}

/**
 * Only use this when converting NON-XML projects!!
 * In v6 we do not call _parse_project_command for the Open macro, so users may
 * have Open macros on Windows that use %ENVVAR%.  These should be converted to
 * %(ENVVAR) because _parse_projecTheZt_command will misinterpret them otherwise
 *
 * @param cmd Command to convert
 */
static void ConvertEnvVars(_str &cmd)
{
#if __UNIX__
#else 
   _str temp='';
   for (;;) {
      int p=pos("\\%{?@}\\%",cmd,1,'r');
      if (!p) break;

      if (p>1) {
         temp=substr(cmd,1,p-1);
      }
      int match_start=pos('s0');
      int match_len=pos('0');
      temp=temp:+'%(':+ substr(cmd,match_start,match_len):+')':+substr(cmd,match_start+match_len+1);
      cmd=temp;
   }
#endif 
}

int _ProjectConvert70ToXML(_str ProjectFilename,boolean isExtensionFile=false, boolean isUserPacksFile=false)
{
   /*
      Sections
      CONFIGURATIONS
      GLOBAL
      COMPILER
      COMPILER.<Config>
      FILES
      FILES.<Config>
      ASSOCIATION

   */
   _str error_msg=nls("Failed to convert Project '%s' to new project format.\n\n",ProjectFilename);
   if (!file_exists(ProjectFilename)) {
      _message_box(error_msg:+get_message(FILE_NOT_FOUND_RC));
      return(FILE_NOT_FOUND_RC);
   }
   if (!isExtensionFile && !isUserPacksFile) {
      _fix_project_file(ProjectFilename);
      //_convert_to_relative_project_file(_project_name);
      _UpdateProjectFile(ProjectFilename);
   }

   int orig_view_id;
   typeless temp_view_id;
   get_window_id(orig_view_id);
   int status=_ini_get_section(ProjectFilename,"CONFIGURATIONS",temp_view_id);
   if (status) {
      temp_view_id='';
      //_message_box(error_msg:+'CONFIGURATIONS section not found');
      //return(status);
   }
   _str DebugCallbackName='';
   _ini_get_value(ProjectFilename,'GLOBAL','DebugCallbackName',DebugCallbackName);
   _str Type;
   _ini_get_value(ProjectFilename,'GLOBAL','packtype',Type);
   _str packname='';
   if (Type=='') {
      _ini_get_value(ProjectFilename,'GLOBAL','packname',packname);
      if (substr(lowcase(packname),1,4)=='java') {
         Type='java';
      } else {
         parse packname with packname .;
         if(packname == "GNU") {
            Type='gnuc';
         } else {
            _str config;
            _ini_get_value(ProjectFilename,'CONFIGURATIONS','config',config,'Debug');
            config=strip(config,'B',',');

            _str compile_information;
            _ini_get_value(ProjectFilename,'COMPILER.'config,'compile',compile_information);

            if (pos('dialog:_gnuc_options_form',compile_information)) {
               Type='gnuc';
            }
         }
      }
   }

   _str AppTypeList;
   _ini_get_value(ProjectFilename,'GLOBAL','app_type_list',AppTypeList);

   int handle=0;
   if (isUserPacksFile) {
      handle=_ProjectCreateUserTemplates(ProjectFilename);
   } else {
      handle=_ProjectCreate(ProjectFilename);
   }

   _str cmd='';
   _str ConfigList[];
   _str WorkingDir='';
   _ini_get_value(ProjectFilename,'GLOBAL','workingdir',WorkingDir);
   if (WorkingDir!='') {
      _xmlcfg_set_path(handle,VPJX_PROJECT,'WorkingDir',_NormalizeFile(WorkingDir));
   }

   _str Macro='';
   _ini_get_value(ProjectFilename,'GLOBAL','macro',Macro);
   if (Macro!='') {
      Macro=_ini_xlat_multiline(Macro);
      for (;;) {
         if (Macro=='') break;
         parse Macro with cmd (_chr(13)) Macro;
         if (cmd!='') {
            ConvertEnvVars(cmd);
            _xmlcfg_set_path2(handle,VPJX_MACRO,VPJTAG_EXECMACRO,'CmdLine',cmd);
         }
      }
   }
   _str vcsproject="";
   _str vcslocalpath="";
   _str vcsauxpath="";

   _ini_get_value(ProjectFilename,"GLOBAL","vcsproject",vcsproject);
   if (vcsproject!='') {
      _ProjectSet_VCSProject(handle,vcsproject);
   }
   _ini_get_value(ProjectFilename,"GLOBAL","vcslocalpath",vcslocalpath);
   if (vcslocalpath!='') {
      _ProjectSet_VCSLocalPath(handle,vcslocalpath);
   }
   _ini_get_value(ProjectFilename,"GLOBAL","vcsauxpath",vcsauxpath);
   if (vcsauxpath!='') {
      _ProjectSet_VCSAuxPath(handle,vcsauxpath);
   }

   _str MakeFile='';
   _ini_get_value(ProjectFilename,'ASSOCIATION','makefile',MakeFile);
   if (MakeFile!='') {
      _xmlcfg_set_path(handle,VPJX_PROJECT,'AssociatedFile',_NormalizeFile(MakeFile));
   }
   _str MakeFileType='';
   _ini_get_value(ProjectFilename,'ASSOCIATION','makefiletype',MakeFileType);
   if (MakeFileType!='') {
      _xmlcfg_set_path(handle,VPJX_PROJECT,'AssociatedFileType',MakeFileType);
   }
   _str info='';
   _ini_get_value(ProjectFilename,'GLOBAL','TagFileExt',info);
   if (info!='') _xmlcfg_set_path(handle,VPJX_PROJECT,'TagFileExt',info);
   _ini_get_value(ProjectFilename,'GLOBAL','OnSetActiveMacro',info);
   if (info!='') _xmlcfg_set_path(handle,VPJX_PROJECT,'OnSetActiveMacro',info);

   _str ConfigPrefix='COMPILER.';
   if (isExtensionFile) ConfigPrefix='.';
   if (isUserPacksFile) ConfigPrefix='';

   _ini_get_sections_list(ProjectFilename,ConfigList,ConfigPrefix);
   _str BuildSystem;_ini_get_value(ProjectFilename,'GLOBAL','BuildSystem',BuildSystem);
   if (BuildSystem!='') _xmlcfg_set_path(handle,VPJX_PROJECT,'BuildSystem',BuildSystem);
   _str BuildMakeFile;_ini_get_value(ProjectFilename,'GLOBAL','MakeFile',BuildMakeFile);
   if (BuildMakeFile!='') _xmlcfg_set_path(handle,VPJX_PROJECT,'BuildMakeFile',BuildMakeFile);

   _str versionText='';
   if (isExtensionFile) {
      _ini_get_value(ProjectFilename,'GLOBAL','version',versionText,0);
      if (versionText<6) {
         int i;
         for (i=0; i<ConfigList._length(); i++) {
            _convert_to_new_commandstr_format(ProjectFilename,ConfigList[i]);//Have to do this one first...
         }
         _ini_set_value(ProjectFilename,'GLOBAL','version',PROJECT_FILE_VERSION);
      }
   } else if (isUserPacksFile) {
      _ini_get_value(ProjectFilename,'.GLOBAL','version',versionText,0);
      if (versionText<6) {
         int i;
         for (i=0; i<ConfigList._length(); i++) {
            _convert_to_new_commandstr_format(ProjectFilename,ConfigList[i]);//Have to do this one first...
         }
         _ini_set_value(ProjectFilename,'.GLOBAL','version',PROJECT_FILE_VERSION);
      }
   }

   int i=0;
   int NodeIndex=0;
   _str TemplateName='';
   _str config='';
   if (isUserPacksFile) {
      for (i=0;i<ConfigList._length();++i) {
         if ( substr( ConfigList[i],length(ConfigList[i])-6,7 )==".GLOBAL"  ) {
            ConfigList._deleteel(i);
            --i;
            continue;
         }
         if (strieq(ConfigList[i],'.GLOBAL')) {
            ConfigList._deleteel(i);
            --i;
            continue;
         }
         parse ConfigList[i] with TemplateName ';' config;
         if (config=='') config='Release';

         // see if this template has already been added
         NodeIndex = _xmlcfg_find_simple(handle, VPTX_TEMPLATE :+ XPATH_STRIEQ("Name", TemplateName));
         if(NodeIndex < 0) {
            // not found so add it
            NodeIndex=_xmlcfg_set_path2(handle,VPTX_TEMPLATES,'Template','Name',TemplateName);
         }
         NodeIndex=_xmlcfg_add(handle,NodeIndex,VPJTAG_CONFIG,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,NodeIndex,'Name',config);

         if (Type!='') _xmlcfg_set_attribute(handle,NodeIndex,'Type',Type);
         if (AppTypeList!='') _xmlcfg_set_attribute(handle,NodeIndex,'AppTypeList',AppTypeList);
         if (DebugCallbackName!='') _xmlcfg_set_attribute(handle,NodeIndex,'DebugCallbackName',DebugCallbackName);
      }
   } else {
      for (i=0;i<ConfigList._length();++i) {
         if (!isExtensionFile) {
            parse ConfigList[i] with '.' config;
            ConfigList[i]=config;
         }

         // if the config name has quotes inside it (not counting surrounding quotes), ignore
         // it here because it will be ignored later
         if(pos('"', strip(ConfigList[i],'B','"'))) {
            continue;
         }

         NodeIndex=_xmlcfg_find_simple(handle,VPJX_PROJECT);
         NodeIndex=_xmlcfg_add(handle,NodeIndex,VPJTAG_CONFIG,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
         _xmlcfg_set_attribute(handle,NodeIndex,'Name',strip(ConfigList[i],'B','"'));

         if (Type!='') _xmlcfg_set_attribute(handle,NodeIndex,'Type',Type);
         if (AppTypeList!='') _xmlcfg_set_attribute(handle,NodeIndex,'AppTypeList',AppTypeList);
         if (DebugCallbackName!='') _xmlcfg_set_attribute(handle,NodeIndex,'DebugCallbackName',DebugCallbackName);
      }
   }

   _str line='';
   _str name='';
   _str ObjDir='';
   _str Name='';
   if (temp_view_id!='') {
      activate_window(temp_view_id);
      top();up();

      for (;;) {
         if (down()) break;
         get_line(line);
         parse line with name'=' ObjDir ',' Name;
         if (strieq(name,'config')) {
            if (ObjDir!='') {
                NodeIndex=_xmlcfg_find_simple(handle,VPJX_CONFIG'[strieq(@Name,"'Name'")]');
                if (NodeIndex>=0) {
                   _xmlcfg_set_attribute(handle,NodeIndex,'ObjectDir',_NormalizeFile(ObjDir));
                }
            }
         }
      }

      _delete_temp_view(temp_view_id);
   }

   int index=0;
   boolean isPredefined=false;
   typeless value='';
   _str dir='';
   _str key='';
   _str prefixkey='';
   _str dialogName='';
   _str pathsep=PATHSEP;
   _str params='';
   _str InputExts='';
   typeless temp_view_id2=0;
   activate_window(orig_view_id);
   for (i=0;i<ConfigList._length();++i) {
      if (strieq(ConfigList[i],'.global')) {
         continue;
      }
      _str ConfigAppType='';
      if (isExtensionFile) {
         _ini_get_section(ProjectFilename,ConfigList[i],temp_view_id2);
      } else {
         _ini_get_section(ProjectFilename,ConfigPrefix:+ConfigList[i],temp_view_id2);
         _ini_get_value(ProjectFilename,ConfigPrefix:+ConfigList[i],'app_type',ConfigAppType);
      }
      ConfigList[i]=strip(ConfigList[i],'B','"');  // Remove double quotes from configs of VC++ associated projects
      pathsep=PATHSEP;
      if (!isExtensionFile && !isUserPacksFile && strieq(substr(ConfigList[i],1,4),'Unix')) {
         pathsep=':';
      }

      // if this config contains quotes, skip it
      // NOTE: the only configs we should encounter with quotes in them are from visual
      //       studio associated projects.  we have seen various forms of config names like:
      //
      //         "CFG=Debug"
      //         "PLATFORM=1" "CFG=Debug"
      //
      //       since we would consider these to both be "Debug", we can ignore the one
      //       with extra quotes inside it since we do not support quotes in config names
      if(pos('"', ConfigList[i])) {
         continue;
      }

      activate_window(temp_view_id2);
      top();up();
      _str ConfigXPath=VPJX_CONFIG'[strieq(@Name,"'ConfigList[i]'")]';
      for (;;) {
         if (down()) break;
         get_line(line);
         parse line with key'='info;
         key=lowcase(key);
         //say('key='key);
         if (isUserPacksFile) {
            parse ConfigList[i] with TemplateName ';' config;
            if (config=='') config='Release';
            ConfigXPath=VPTX_TEMPLATE'[strieq(@Name,"'TemplateName'")]/'VPJTAG_CONFIG'[strieq(@Name,"'config'")]';
         }
         _str caption;
         if (key=='includedirs') {
            if (info!='') {
               //say('info='info);
               for (;;) {
                  if (info=='') break;
                  parse info with dir (pathsep) info;
                  //say('dir='dir);say('info='info);
                  _xmlcfg_set_path2(handle,ConfigXPath'/'VPJTAG_INCLUDES,VPJTAG_INCLUDE,'Dir',_NormalizeFile(dir));
               }
            }
         } else if (key=='sysincludedirs') {
            if (info!='') {
               for (;;) {
                  if (info=='') break;
                  parse info with dir (pathsep) info;
                  _xmlcfg_set_path2(handle,ConfigXPath'/'VPJTAG_SYSINCLUDES,VPJTAG_INCLUDE,'Dir',_NormalizeFile(dir));
               }
            }
         } else if (key=='libs') {
            if (info!='') {
               for (;;) {
                  if (info=='') break;
                  dir=parse_file(info,false);
                  _xmlcfg_set_path2(handle,ConfigXPath'/Libs','Lib','File',_NormalizeFile(dir));
               }
            }
         } else if (key=='reffile') {
            if (info!='') {
               _xmlcfg_set_path(handle,ConfigXPath,'RefFile',_NormalizeFile(info));
            }
         } else if (key=='outputfile') {
            if (info!='') {
               // adjust for new gnuc project %o handling
               if(Type == "gnuc") {
                  // prefix output file with %bd
                  info = "%bd" info;
               }
               _xmlcfg_set_path(handle,ConfigXPath,'OutputFile',_NormalizeFile(info));
            }
         } else if (key=='prebuildcmds') {
            _ini_get_value(ProjectFilename,'GLOBALS','stoponprebuilderrors',value);
            if (!isinteger(value)) value=0;
            if (info!='') {
               if (info!='') {
                  for (;;) {
                     if (info=='') break;
                     parse info with dir (\1) info;
                     if (dir!='') {
                        _xmlcfg_set_path2(handle,ConfigXPath'/'VPJTAG_PREBUILDCOMMANDS,VPJTAG_EXEC,'CmdLine',dir);
                        _xmlcfg_set_path(handle,ConfigXPath'/'VPJTAG_PREBUILDCOMMANDS,'StopOnError',value);
                     }
                  }
               }
            }
         } else if (key=='app_type') {
            _xmlcfg_set_path(handle,ConfigXPath,'AppType',info);
         } else if (key=='packver') {
            _xmlcfg_set_path(handle,ConfigXPath,'Version',info);
         } else if (key=='postbuildcmds') {
            _ini_get_value(ProjectFilename,'GLOBALS','stoponpostbuilderrors',value);
            if (!isinteger(value)) value=0;
            //say('config='ConfigList[i]);
            if (info!='') {
               if (info!='') {
                  for (;;) {
                     if (info=='') break;
                     parse info with dir (\1) info;
                     if (dir!='') {
                        //say('cmd='dir);
                        _xmlcfg_set_path2(handle,ConfigXPath'/'VPJTAG_POSTBUILDCOMMANDS,VPJTAG_EXEC,'CmdLine',dir);
                        //_showxml(handle,TREE_ROOT_INDEX,-1);
                        //trace();
                        _xmlcfg_set_path(handle,ConfigXPath'/'VPJTAG_POSTBUILDCOMMANDS,'StopOnError',value);
                        //say('node name='_xmlcfg_get_name(handle,NodeIndex));
                        //_showxml(handle,TREE_ROOT_INDEX,-1);
                     }
                  }
               }
            }
         } else if (key=='stoponprebuilderrors' || key=='stoponpostbuilderrors') {
         } else if (key=='classpath') {
            if (info!='') {
               for (;;) {
                  if (info=='') break;
                  parse info with dir (pathsep) info;
                  _xmlcfg_set_path2(handle,ConfigXPath'/'VPJTAG_CLASSPATH,VPJTAG_CLASSPATHELEMENT,'Value',_NormalizeFile(dir));
               }
            }
         } else if (isPredefinedTool(key,name,caption,isPredefined) ||
                    pos(TOOLNAMEKEYPREFIX, key, 1, "I")==1 ||
                    pos(APPTOOLNAMEKEYPREFIX, key, 1, "I")==1 ||
                    pos(EXT_SPECIFIC_COMPILE_REGEX, key, 1, "U")==1) {
            if (info=='') continue;

            _str otherOptions,appletClass;
            _str outputExtension,optionsText,preMacro,clearProcessBuf;
            _str useVsBuild;   // This option has been dropped
            _str buildFirst,saveOptions,explicitSave;
            _str LinkObject,verbose,beep,runInXterm;
            _str ShowOnMenu,optionsDialog,CommandsReadOnly;
            _str enableCaptureOutput,changeDir,EnableBuildFirst;
            _str outputConcur,captureOutput;
            _str enableVSBuildOptions;

            parse key with prefixkey '(';
            //say('key='key' isP='isPredefined' n='name);
            if (!isPredefined) {
               _str menu=_ProjectGetStr(info,"menu");
               parse menu with name ':' caption;
               if (name=='') {
                  // This should never happen.
                  if (key=='make') {
                     name=caption='Build';
                  } else {
                     name=caption=upcase(substr(prefixkey,1,1)):+substr(prefixkey,2);
                  }
               }
            }
            cmd=_ProjectGetStr2(info,"cmd");
            if (key=='make' || key=='rebuild' || key=='compile') {
               _str temp=cmd;
               _str pgm=parse_file(temp,false);
               pgm=_strip_filename(pgm,'P');
               if (strieq('msdev',pgm)) {
                  i=pos('%bn',cmd);
                  if (i>1 && substr(cmd,i-1,1)!='"') {
                     cmd=substr(cmd,1,i-1):+'"%bn"'substr(cmd,i+3);
                  }
               }
               if (strieq('nmake',pgm) ||
                   strieq('devenv',pgm)
                   ) {
                  i=pos('%b ',cmd);
                  if (i) {
                     cmd=substr(cmd,1,i-1):+'"%b"'substr(cmd,i+2);
                  }
               }
            }

            // adjust for new gnuc project %o handling
            if(Type == "gnuc" &&
               (strieq(key, "link") || strieq(key, "debug") || strieq(key, "execute"))) {
               // replace %bd%o with just %o
               cmd = stranslate(cmd, "%o", "%bd%o");
            }

            name= name;
            caption= caption;
            otherOptions= _ProjectGetStr(info,"otheropts");
            appletClass= _ProjectGetStr(info,"appletclass");
            outputExtension= _ProjectGetStr(info,"outputext");


            optionsText=_ProjectGetStr(info,"copts");
            if (pos('premacro:', optionsText)) {
               _str beforeOptions = "";
               _str afterOptions = "";
               _str macroName = "";
               parse optionsText with beforeOptions 'premacro:' macroName '|' afterOptions;
               preMacro= macroName;

               // rebuild optionsText without premacro
               optionsText = beforeOptions :+ afterOptions;
            } else {
               preMacro = "";
            }

            if (key== "compile" || key== "make" || key== "rebuild") {
               outputConcur= (int)(info=='' || pos('concur', optionsText));
               captureOutput= (int)(info=='' || pos('capture', optionsText));
            } else {
               outputConcur= pos('concur', optionsText)?1:0;
               captureOutput= pos('capture', optionsText)?1:0;
            }
            //enableSaveOption=(key!='execute' && key!='clean' && key!='debug' && key!='link');
            //enableVSBuildOptions=(key=='rebuild' || key=='make');
            clearProcessBuf= pos('clear', optionsText)?1:0;
            useVsBuild= pos('vsbuild', optionsText)?1:0;
            buildFirst= pos('buildfirst', optionsText)?1:0;
            if (strieq(name,"Make Jar")) {
               buildFirst=1;
            }
            saveOptions= VPJ_SAVEOPTION_SAVENONE;
            explicitSave= 0;
            LinkObject= pos('nolink', optionsText)?0:1;
            verbose= pos('verbose', optionsText)?1:0;
            beep= pos('beep', optionsText)?1:0;
            runInXterm= pos('xterm', optionsText)?1:0;
            saveOptions='SaveNone';
            if (pos('savecurrent', optionsText)) {
               saveOptions= VPJ_SAVEOPTION_SAVECURRENT;
            } else if (pos('saveall', optionsText)) {
               saveOptions= VPJ_SAVEOPTION_SAVEALL;
            } else if (pos('savemodified', optionsText)) {
               saveOptions= VPJ_SAVEOPTION_SAVEMODIFIED;
            } else if (pos('savenone', optionsText)) {
               saveOptions= VPJ_SAVEOPTION_SAVENONE;
            } else if (pos('saveworkspacefiles', optionsText)) {
               saveOptions= VPJ_SAVEOPTION_SAVEWORKSPACEFILES;
            } else {
               // Can't find any new "save*" options. Check the def_save_on_compile for
               // tools with command with %f, %p,... specifying a file.
               _str tOption;
               if (pos("(%f)|(%p)|(%n)|(%e)",cmd,1,"RI")) {
                  parse def_save_on_compile with tOption .;
                  saveOptions= SaveIndexToString((int)tOption);
               } else if (key== "make" || key== "rebuild") {
                  parse def_save_on_compile with . tOption;
                  saveOptions= SaveIndexToString((int)tOption);
               }
            }

            if(pos('hide', optionsText)) {
               ShowOnMenu =  VPJ_SHOWONMENU_HIDEIFNOCMDLINE;
            } else if(pos('nevershow', optionsText)) {
               ShowOnMenu = VPJ_SHOWONMENU_NEVER;  //HIDEALWAYS;
            } else {
               ShowOnMenu = VPJ_SHOWONMENU_ALWAYS; //HIDENEVER;
            }

            if (pos('dialog:', optionsText)) {
               parse optionsText with 'dialog:' dialogName '|' .;
               optionsDialog=dialogName;
            } else {
               optionsDialog= "";
            }

            CommandsReadOnly=pos('readonly', optionsText)?'1':'0';
            enableCaptureOutput=pos('disablecapoutput', optionsText)?'0':'1';
            changeDir= (int)!pos('nochangedir', optionsText);
            EnableBuildFirst=(key!='make' && key!='rebuild' && prefixkey!='compile');
            boolean Deletable=true;
            switch (Type) {
            case 'java':
               switch (key) {
               case 'compile':
               case 'make':
               case 'rebuild':
               case 'debug':
               case 'execute':
               case 'usertool_view_javadoc':
               case 'usertool_make_jar':
               case 'usertool_javadoc_all':
               case 'usertool_java_options':
                  Deletable=false;
               }
            case 'gnuc':
               switch (key) {
               case 'compile':
               case 'link':
               case 'make':
               case 'rebuild':
               case 'debug':
               case 'execute':
               case 'usertool_gnu_c_options':
                  Deletable=false;
               }
            case 'vcpp':
               switch (key) {
               case 'compile':
               case 'make':
               case 'rebuild':
               case 'debug':
               case 'execute':
               case 'usertool_resource_editor':
               case 'usertool_build_solution':
               case 'usertool_clean_solution':
               case 'usertool_clean_project':
                  Deletable=false;
               }
            }

            // Adjust a few things for correctness. If we are not capturing the output,
            // we should not output to concur buffer or clear buffer. Likewise, if we
            // are capturing output, we must disable "run in xterm".
            if (!captureOutput) {
               outputConcur= 0;
               clearProcessBuf= 0;
            } else {
               //runInXterm = 0;
            }
            _str AppType='';
            _str TargetTagName=VPJTAG_TARGET;
            if (pos(EXT_SPECIFIC_COMPILE_REGEX, key, 1, "U")==1) {
               NodeIndex=_xmlcfg_set_path(handle,ConfigXPath'/'VPJTAG_RULES);
               _xmlcfg_set_attribute(handle,NodeIndex,'Name','Compile');
               TargetTagName=VPJTAG_RULE;
            } else if (pos(APPTOOLNAMEKEYPREFIX, key, 1, "I")==1) {
               NodeIndex=_ProjectGet_AppTypeTargets(handle,ConfigList[i],name,true);
               //NodeIndex=_xmlcfg_set_path(handle,ConfigXPath'/'VPJTAG_APPTYPETARGETS);
               parse key with '_' . '_' AppType;
               if (strieq(AppType,ConfigAppType)) {
                  continue;
               }
               TargetTagName=VPJTAG_APPTYPETARGET;
               switch (lowcase(name)) {
               case 'compile':
               case 'make':
               case 'rebuild':
               case 'debug':
               case 'execute':
                  Deletable=false;
               }
#if 0
               parse name with apptool'_' name2 '_' AppType2;
               if (strieq(AppType2,AppType)) {
                  name=name2;
                  MenuCaption=
               }
               say('key='key' name='name' 2='AppType2' 1='AppType);
#endif
            } else {
               NodeIndex=_xmlcfg_set_path(handle,ConfigXPath'/Menu');
            }

            boolean bool=strieq(ShowOnMenu,'hideifnocmdline') && cmd=='' && (caption=='User 1' || caption=='User 2');
            if (bool) continue;

            if(NodeIndex < 0) {
               continue;
            }
            NodeIndex=_xmlcfg_add(handle,NodeIndex,TargetTagName,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);

            /*_str name,caption,otherOptions,appletClass;
            _str outputExtension,optionsText,preMacro,clearProcessBuf;
            _str useVsBuild,buildFirst,saveOptions,explicitSave;
            _str LinkObject,verbose,beep,runInXterm;
            _str ShowOnMenu,optionsDialog,CommandsReadOnly;
            _str enableCaptureOutput,changeDir,EnableBuildFirst;
            _str outputConcur,captureOutput;
            */
            if (TargetTagName!=VPJTAG_APPTYPETARGET && TargetTagName!=VPJTAG_RULE) {
               _xmlcfg_set_attribute(handle,NodeIndex,'Name',name);
            }
            if(caption!='' && TargetTagName!=VPJTAG_RULE) _xmlcfg_set_attribute(handle,NodeIndex,'MenuCaption',caption);
            int ExecIndex=_xmlcfg_add(handle,NodeIndex,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
            if(otherOptions!='' ) _xmlcfg_set_attribute(handle,ExecIndex,'OtherOptions',otherOptions);
            if (pos(EXT_SPECIFIC_COMPILE_REGEX, key, 1, "U")==1) {
               parse key with '(' InputExts ')';
               InputExts=stranslate(strip(InputExts),'*.','.');
               InputExts=stranslate(InputExts,' ','  ');  // Translate 2 spaces to 1 just in case
               InputExts=stranslate(InputExts,';',' ');
               _xmlcfg_set_attribute(handle,NodeIndex,'InputExts',InputExts);
            }
            if (outputExtension!='') {
               _xmlcfg_set_attribute(handle,NodeIndex,'OutputExts','*'outputExtension);
            }
            if (LinkObject==0) {
               _xmlcfg_set_attribute(handle,NodeIndex,'LinkObject',LinkObject);
            }
            if(preMacro!="") _xmlcfg_set_attribute(handle,NodeIndex,'PreMacro',preMacro);
            if(clearProcessBuf) _xmlcfg_set_attribute(handle,NodeIndex,'ClearProcessBuffer',clearProcessBuf);
            // Options only supported by build and rebuild
            if (key=='make' || key=='rebuild') {
               if (verbose) _xmlcfg_set_attribute(handle,NodeIndex,'Verbose',verbose);
               if (beep) _xmlcfg_set_attribute(handle,NodeIndex,'Beep',beep);
            }
            if (runInXterm) _xmlcfg_set_attribute(handle,NodeIndex,'RunInXterm',runInXterm);
            if (!strieq(ShowOnMenu,'always') && TargetTagName!=VPJTAG_RULE) {
               _xmlcfg_set_attribute(handle,NodeIndex,'ShowOnMenu',ShowOnMenu);
            }
            if (optionsDialog!='') {
               parse optionsDialog with optionsDialog ':' params;
               _xmlcfg_set_attribute(handle,NodeIndex,'Dialog',strip(optionsDialog' 'params));
            }
            if (CommandsReadOnly && optionsDialog=='' && cmd!='javaoptions' && cmd!='gnucoptions') _xmlcfg_set_attribute(handle,NodeIndex,'CommandsReadOnly',CommandsReadOnly);
            if (changeDir) _xmlcfg_set_attribute(handle,NodeIndex,'RunFromDir','%rw');
            if (!EnableBuildFirst) {
               if (key!='make' && key!='rebuild' && key!='compile') {
                  _xmlcfg_set_attribute(handle,NodeIndex,'EnableBuildFirst',EnableBuildFirst);
               }
            } else {
               if (buildFirst) _xmlcfg_set_attribute(handle,NodeIndex,'BuildFirst',buildFirst);
            }
            if (cmd!='') {
               _xmlcfg_set_attribute(handle,ExecIndex,'CmdLine',cmd);
               if (!outputConcur && !captureOutput) {
                  //if (!enableCaptureOutput) _xmlcfg_set_attribute(handle,NodeIndex,'EnableCaptureOutput',enableCaptureOutput);
                  _str temp=cmd;
                  _str pgmname=parse_file(temp);
                  index=find_index(pgmname,COMMAND_TYPE);
                  if (index) {
                     _xmlcfg_set_attribute(handle,ExecIndex,'Type','Slick-C');
                  }

               }


            }
            if (outputConcur) {
               _xmlcfg_set_attribute(handle,NodeIndex,'CaptureOutputWith',VPJ_CAPTUREOUTPUTWITH_PROCESSBUFFER);
            } else if (captureOutput) {
               _xmlcfg_set_attribute(handle,NodeIndex,'CaptureOutputWith',VPJ_CAPTUREOUTPUTWITH_REDIRECTION);
            }
            //if (!enableSaveOption) {
            //   _xmlcfg_set_attribute(handle,NodeIndex,'EnableSaveOption',enableSaveOption);
            //} else {
               if (!strieq(saveOptions,VPJ_SAVEOPTION_SAVENONE)) {
                  _xmlcfg_set_attribute(handle,NodeIndex,'SaveOption',saveOptions);
               }
            //}
            /*if (enableVSBuildOptions) {
               _xmlcfg_set_attribute(handle,NodeIndex,'EnableVSBuildOptions',enableVSBuildOptions);
            } */
            /*if (key=='make' || key=='rebuild') {
               _xmlcfg_set_attribute(handle,NodeIndex,"DependsRef","Build");
            } */
            if (appletClass!='') {
               _xmlcfg_set_attribute(handle,NodeIndex,"AppletClass",appletClass);
            }
            if (!Deletable) {
               _xmlcfg_set_attribute(handle,NodeIndex,"Deletable",Deletable);
            }
            if (AppType!='') {
               _xmlcfg_set_attribute(handle,NodeIndex,"AppType",AppType);
            } else {
#if 0
               _ini_get_value(ProjectFilename,ConfigPrefix:+ConfigList[i],'app_type',AppType);
               if (AppType!='') {
                   //&& pos(APPTOOLNAMEKEYPREFIX, key, 1, "I")!=1
                  _ini_get_value(ProjectFilename,ConfigPrefix:+ConfigList[i],'apptool_'key'_'AppType,result);
                   if (result!='') {
                      _xmlcfg_set_attribute(handle,NodeIndex,"AppType",AppType);
                   }
               }
#endif
            }
         }
      }
      /*
         Pull GUI Builder until version 8.1

      */
      /*
      if (Type=='java') {
         int Node=_xmlcfg_find_simple(handle,ConfigXPath'/'VPJTAG_MENU'/'VPJTAG_TARGET:+XPATH_STRIEQ('Name','Javadoc All'));
         if (Node>=0) {
            Node=_xmlcfg_add(handle,Node,VPJTAG_TARGET,VSXMLCFG_NODE_ELEMENT_START_END,0);
            _xmlcfg_set_attribute(handle,Node,'Name','Activate GUI Builder');
            _xmlcfg_set_attribute(handle,Node,'MenuCaption','Activat&e GUI Builder');
            _xmlcfg_set_attribute(handle,Node,'Deletable','0');
            Node=_xmlcfg_add(handle,Node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(handle,Node,'CmdLine','jguiLaunch');
            _xmlcfg_set_attribute(handle,Node,'Type','Slick-C');
         }
      }
      */
      _delete_temp_view(temp_view_id2);
      activate_window(orig_view_id);
   }
   if (!isExtensionFile && !isUserPacksFile) {
      AddFiles(handle,ProjectFilename,ConfigList);
      if (strieq(Type,'java')) {
         _ProjectSet_AutoFolders(handle,VPJ_AUTOFOLDERS_PACKAGEVIEW,true);
      }
   }
   copy_file(ProjectFilename,_strip_filename(ProjectFilename,'E')'.bakvpj');
   status=_ProjectSave(handle,error_msg);
   _xmlcfg_close(handle);

   activate_window(orig_view_id);
   return(status);
}



/*
defmain()
{
#if 0
   filename='f:\public\test1.xml';
   //copy_file('f:\vslick80\slickedit.vpj',filename);
   copy_file('f:\public\test.vpj',filename);
   _ProjectConvert70ToXML(filename);
   edit(filename);
#endif
   filename='f:\public\vslick80\slickedit-win.xml';
   //copy_file('f:\vslick80\slickedit.vpj',filename);
   copy_file('f:\public\vslick80\slickedit-win.vpw',filename);
   copy_file('f:\vslick80\rt\slick\vst.vpj','f:\public\vslick80\rt\slick\vst.vpj');
   copy_file('f:\vslick80\rt\slick\vsu.vpj','f:\public\vslick80\rt\slick\vsu.vpj');
   _WorkspaceConvert70ToXML(filename);
   edit('f:\public\vslick80\rt\slick\vst.vpj');
   edit('f:\public\vslick80\rt\slick\vsu.vpj');
   edit(filename);
}
*/

int _ProjectConvert80To81(_str ProjectFilename, int handle = -1)
{
   // changes from project version 8.0 to 8.1
   //    ChangeDir attribute of the Target tag was replaced by RunFromDir
   //    added doctype

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectFilename, status);
      if(handle < 0) {
         _message_box(nls("Unable to convert 8.0 project '%s1' to 8.1", ProjectFilename));
         return handle;
      }
   }

   // add the doctype  <!DOCTYPE Project SYSTEM "http://www.slickedit.com/dtd/vse/8.1/vpj.dtd">
   int firstChildNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX);
   int doctypeNode = _xmlcfg_add(handle, firstChildNode, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", VPJTAG_PROJECT);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPJ_DTD_PATH81);

   // find all Target and AppTypeTarget nodes
   typeless array[] = null;
   _xmlcfg_find_simple_array(handle, "/Project//Target", array);
   _xmlcfg_find_simple_array(handle, "/Project//AppTypeTarget", array, TREE_ROOT_INDEX, VSXMLCFG_FIND_APPEND);
   int i;
   for(i = 0; i < array._length(); i++) {
      int targetNode = array[i];

      // ChangeDir defaulted to 1 if not found
      _str changeDir = _xmlcfg_get_attribute(handle, targetNode, "ChangeDir", "1");

      // default runFromDir to blank (do not change dir) if changedir is 0 or not found
      if(changeDir == "1") {
         // set the RunFromDir attribute
         _xmlcfg_set_attribute(handle, targetNode, "RunFromDir", "%rw");
      }

      // remove the changedir attribute
      _xmlcfg_delete_attribute(handle, targetNode, "ChangeDir");
   }

   // put the new version
   _xmlcfg_set_path(handle, VPJX_PROJECT, "Version", VPJ_FILE_VERSION81);

   // save the converted file
   status = _ProjectSave(handle);

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * ensures that all three parameters are integers
 *
 * @param major   major version number
 * @param minor   minor version number
 * @param sub     sub-minor version number or build number
 */
static void makeints(typeless&major,typeless&minor,typeless&sub)
{
   if (!isnumber(major)) {
      major='0';
   }
   if (!isnumber(minor)) {
      minor='0';
   }
   if (!isnumber(sub)) {
      sub='0';
   }
}

/**
 * extracts a version number from the compiler name and updates latestVersion
 *
 * @param config_name      the name of the compiler that is being checked
 * @param base_name        the base name of the compiler that is being checked (GCC, CC, LCC or Cygwin)
 * @param latest_version   the name of the latest compiler.  On the first call to this function set to ''.
 * @param shortVersion     used internally to speed up version checking.  On the first call to this
 *                         function set to ''.
 */
static void get_version(_str config_name,_str base_name,_str& latestVersion,_str& shortVersion)
{
   // found in /usr/include, always select this version instead of trying to find
   // one with a version number
   if (config_name:==base_name) {
      latestVersion=config_name;
      shortVersion='-';
   }

   if (shortVersion:=='-') {
      // /usr/include version has been found, use it
      return;
   }

   _str full_version;
   typeless major;
   typeless minor;
   typeless sub;
   typeless smajor;
   typeless sminor;
   typeless ssub;
   parse config_name with '-'full_version'-';
   full_version=strip(full_version);
   parse full_version with major '.' minor '.' sub .;
   makeints(major,minor,sub);
   parse shortVersion with smajor '.' sminor '.' ssub .;
   makeints(smajor,sminor,ssub);

   boolean later=false;
   if (major>smajor) {
      later=true;
   } else if (major==smajor) {
      if (minor>sminor) {
         later=true;
      } else if (minor==sminor) {
         if (sub>ssub) {
            later=true;
         }
      }
   }
   if (later) {
      latestVersion=config_name;
      shortVersion=major'.'minor'.'sub;
   }
}

/**
 * fills in a available_compilers structure from a list of compiler names
 */
void _evaluate_compilers(available_compilers& compilers, _str (&compiler_names)[])
{
   compilers.hasVC6=false;
   compilers.hasDotNET=false;
   compilers.hasDotNet2003=false;
   compilers.hasDotNet2005=false;
   compilers.hasDotNet2005Express=false;
   compilers.hasDotNet2008=false;
   compilers.hasDotNet2008Express=false;
   compilers.hasDotNet2010=false;
   compilers.hasDotNet2010Express=false;
   compilers.hasDotNet2012=false;
   compilers.hasDotNet2012Express=false;
   compilers.hasToolkit=false;
   compilers.hasPlatformSDK=false;
   compilers.hasBorland=false;
   compilers.latestMS='';
   compilers.latestCygwin='';
   compilers.latestLCC='';
   compilers.latestGCC='';
   compilers.latestCC='';
   compilers.latestDDK='';
   compilers.latestBorland='';
   _str gccVersion='';
   _str cygwinVersion='';
   _str ccVersion='';
   _str lccVersion='';
   _str ddkVersion='';

   int index;
   for (index=0;index<compiler_names._length();++index) {
      switch (compiler_names[index]) {
      case COMPILER_NAME_VS6:
         compilers.hasVC6=true;
         if (!compilers.hasDotNET &&
             !compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS6;
         }
         break;
      case COMPILER_NAME_VSDOTNET:
         compilers.hasDotNET=true;
         if (!compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VSDOTNET;
         }
         break;
      case COMPILER_NAME_VS2003:
         compilers.hasDotNet2003=true;
         if (!compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS2003;
         }
         break;
      case COMPILER_NAME_VS2005:
         compilers.hasDotNet2005=true;
         compilers.latestMS=COMPILER_NAME_VS2005;
         break;
      case COMPILER_NAME_VS2005_EXPRESS:
         compilers.hasDotNet2005Express=true;
         if (!compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS2005_EXPRESS;
         }
         break;
      case COMPILER_NAME_VS2008:
         compilers.hasDotNet2008=true;
         compilers.latestMS=COMPILER_NAME_VS2008;
         break;
      case COMPILER_NAME_VS2008_EXPRESS:
         compilers.hasDotNet2008Express=true;
         if (!compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS2008_EXPRESS;
         }
         break;
      case COMPILER_NAME_VS2010:
         compilers.hasDotNet2010=true;
         compilers.latestMS=COMPILER_NAME_VS2010;
         break;
      case COMPILER_NAME_VS2010_EXPRESS:
         compilers.hasDotNet2010Express=true;
         if (!compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS2010_EXPRESS;
         }
         break;
      case COMPILER_NAME_VS2012:
         compilers.hasDotNet2012=true;
         compilers.latestMS=COMPILER_NAME_VS2012;
         break;
      case COMPILER_NAME_VS2010_EXPRESS:
         compilers.hasDotNet2012Express=true;
         if (!compilers.hasDotNet2003 &&
             !compilers.hasDotNet2005 &&
             !compilers.hasDotNet2008 &&
             !compilers.hasDotNet2010 &&
             !compilers.hasDotNet2012
             ) {
            compilers.latestMS=COMPILER_NAME_VS2012_EXPRESS;
         }
         break;
      case COMPILER_NAME_VCPP_TOOLKIT2003:
         compilers.hasToolkit=true;
         break;
      case COMPILER_NAME_PLATFORM_SDK2003:
         compilers.hasPlatformSDK=true;
         break;
      case COMPILER_NAME_BORLAND:
      case COMPILER_NAME_BORLAND6:
         compilers.hasBorland=true;
         if (!compilers.hasBorland) {
            compilers.latestBorland=compiler_names[index];
         }
         break;
      case COMPILER_NAME_BORLANDX:
         compilers.hasBorland=true;
         compilers.latestBorland=COMPILER_NAME_BORLANDX;
         break;
      default:
         if (COMPILER_NAME_CYGWIN :== substr(compiler_names[index], 1, length(COMPILER_NAME_CYGWIN))) {
            get_version(compiler_names[index], COMPILER_NAME_CYGWIN, compilers.latestCygwin, cygwinVersion);
         } else if (COMPILER_NAME_LCC :== substr(compiler_names[index], 1, length(COMPILER_NAME_LCC))) {
            get_version(compiler_names[index], COMPILER_NAME_LCC, compilers.latestLCC, lccVersion);
         } else if (COMPILER_NAME_GCC:==substr(compiler_names[index], 1, length(COMPILER_NAME_GCC))) {
            get_version(compiler_names[index], COMPILER_NAME_GCC, compilers.latestGCC, gccVersion);
         } else if (COMPILER_NAME_CC:==substr(compiler_names[index], 1, length(COMPILER_NAME_CC))) {
            get_version(compiler_names[index], COMPILER_NAME_CC, compilers.latestCC, ccVersion);
         } else if (COMPILER_NAME_DDK:==substr(compiler_names[index], 1, length(COMPILER_NAME_DDK))) {
            get_version(compiler_names[index], COMPILER_NAME_DDK, compilers.latestDDK, ddkVersion);
         }
      }
   }
}

/**
 * finds the compiliers that are available on the users machine
 *
 * @param   compilers      filled in with all the compiler information
 */
void _find_compilers(available_compilers& compilers)
{
   _str compiler_names[];
   _str config_includes[];
   _str config_header_names[];
   compiler_names._makeempty();
   config_includes._makeempty();
   config_header_names._makeempty();

   getCppIncludeDirectories(compiler_names,config_includes,config_header_names);

   _evaluate_compilers(compilers, compiler_names);
}

/**
 * decides which compiler config to use for the specified project
 *
 * @param   compilers            compilers that are available on the user's machine set by {@link _find_compilers()}
 * @param   prjHandle            handle to a project
 * @param   vendorPrjFileName    if the project is associated, set this to the name of the associated project file
 * @param   cfgNode              the node index of the configuration inside of the SlickEdit project.
 *
 * @return  the name of the compiler configuration to use for this project.  May return '' if no configuration
 *          is specified
 */
_str determineCompilerConfigName(available_compilers& compilers,int prjHandle,_str vendorPrjFileName,int cfgNode=-1)
{
   _str configName='';

   _str vPrjExt=_get_extension(vendorPrjFileName,true);

   if (vPrjExt:==VISUAL_STUDIO_VCPP_PROJECT_EXT) {
      // .NET, .NET2003 or .NET2005
      // assume .NET and try open the file and see if it is .NET2003
      configName=COMPILER_NAME_VSDOTNET;
      // if they only have one version installed, use it
      if (!compilers.hasDotNET && compilers.hasDotNet2003 && !compilers.hasDotNet2005 &&
          !compilers.hasDotNet2008 && !compilers.hasDotNet2010
          ) {
         configName=COMPILER_NAME_VS2003;
      } else if (!compilers.hasDotNET && !compilers.hasDotNet2003 && compilers.hasDotNet2005 &&
                 !compilers.hasDotNet2008 && !compilers.hasDotNet2010
                 ) {
         configName=COMPILER_NAME_VS2005;
      } else if (!compilers.hasDotNET && !compilers.hasDotNet2003 && 
                 !compilers.hasDotNet2005 && compilers.hasDotNet2005Express &&
                 !compilers.hasDotNet2008 //&& !compilers.hasDotNet2008Express
                 ) {
         configName=COMPILER_NAME_VS2005_EXPRESS;
      } else if (!compilers.hasDotNET && !compilers.hasDotNet2003 && !compilers.hasDotNet2005 &&
                 compilers.hasDotNet2008
                 ) {
         configName=COMPILER_NAME_VS2008;
      } else if (!compilers.hasDotNET && !compilers.hasDotNet2003 && 
                 !compilers.hasDotNet2005 && //!compilers.hasDotNet2005Express &&
                 !compilers.hasDotNet2008 && compilers.hasDotNet2008Express
                 ) {
         configName=COMPILER_NAME_VS2008_EXPRESS;
      } else if (compilers.hasDotNet2003 || compilers.hasDotNet2005 ||
                 compilers.hasDotNet2008
                 ) {
         int status;
         int vendorHandle=_xmlcfg_open(vendorPrjFileName,status);
         if (!status) {
            int prjNode=_xmlcfg_find_simple(vendorHandle,'VisualStudioProject');
            if (prjNode>=0) {
               _str dotNetVersion=_xmlcfg_get_attribute(vendorHandle,prjNode,'Version','7.00');
               if (dotNetVersion=='7.10' && compilers.hasDotNet2003) {
                  configName=COMPILER_NAME_VS2003;
               } else if (dotNetVersion=='8.00' && compilers.hasDotNet2005) {
                  configName=COMPILER_NAME_VS2005;
               } else if (dotNetVersion=='9.00' && compilers.hasDotNet2008) {
                  configName=COMPILER_NAME_VS2008;
               } else if (dotNetVersion=='10.00' && compilers.hasDotNet2010) {
                  configName=COMPILER_NAME_VS2010;
               }
            }
            _xmlcfg_close(vendorHandle);
         }
      }
   } else if (vPrjExt:==VISUAL_STUDIO_VCX_PROJECT_EXT) {
      if (cfgNode < 0) {
         return ''; // can't determine compiler config without configuration
      }

      // default name
      cfgName := _xmlcfg_get_attribute(prjHandle, cfgNode, 'Name');
      if (cfgName != '') {
         int status;
         int vendorHandle = _xmlcfg_open(vendorPrjFileName, status, VSXMLCFG_OPEN_ADD_PCDATA);
         if (!status) {
            toolsetName := getVCXProjPropertyGroupConfiguration(vendorHandle, cfgName, "PlatformToolset");
            switch (toolsetName) {
            case 'v90':
               if (compilers.hasDotNet2008Express) {
                  configName = COMPILER_NAME_VS2008_EXPRESS;
               } else {
                  configName = COMPILER_NAME_VS2008;
               }
               break;

            case 'v110':
               if (compilers.hasDotNet2012Express) {
                  configName = COMPILER_NAME_VS2012_EXPRESS;
               } else {
                  configName = COMPILER_NAME_VS2012;
               }
               break;

            case 'v100':
            default:
               // set further below
               break;
            }
            _xmlcfg_close(vendorHandle);
         }
      }

      if (configName == '') {
         if (compilers.hasDotNet2010Express) {
            configName = COMPILER_NAME_VS2010_EXPRESS;
         } else {
            configName = COMPILER_NAME_VS2010;
         }
      }

   } else if (vPrjExt:==VCPP_PROJECT_FILE_EXT) {
      if (compilers.hasVC6) {
         configName=COMPILER_NAME_VS6;
      } else {
         configName=compilers.latestMS;
      }
   } else if (vPrjExt:==TORNADO_PROJECT_EXT) {
      // tornado is not supported by refactoring
      configName='';
   } else if (vPrjExt:==VCPP_EMBEDDED_PROJECT_FILE_EXT) {
      configName=compilers.latestMS;
   } else if (vPrjExt:==PRJ_FILE_EXT) {
      // Xcode vpj files are associated with themselves
      configName=COMPILER_NAME_LATEST;
   } else if (vPrjExt:!='') {
      // Associated project that is not Visual Studio or tornado, must be Borland (or VB or some other
      // non-C project), which is not supported by refactoring
      configName='';
   } else {
      // command line compiler, if this project is based on an old file, it may have a type
      // attribute with the config,
      if (cfgNode<0) {
         // return an empty string for now and try again later when this function is called
         // for each configuration
         configName='';
      } else {
         // check for a type attribute
         _str old_type=_xmlcfg_get_attribute(prjHandle,cfgNode,'Type');

         switch (old_type) {
         case 'java':
            configName=COMPILER_NAME_LATEST;
            break;
         case 'vcpp':
            configName=compilers.latestMS;
            break;
         case 'gnuc':
         case 'cpp':
            configName=COMPILER_NAME_LATEST;
            break;
         default:
            configName="";
            break;
         }
      }
   }
   return configName;
}

/**
 * sets the version number of a project
 *
 * @param   prjHandle      handle to the SlickEdit project file
 * @param   projectNode    set to the index of the 'Project' element within the project file
 * @param   projectVersion the version to set the project to
 * @param   projectDTD     the DTD path to use
 *
 * @return  true if the version number was updated successfully
 */
static boolean update_project_version(int prjHandle, int& projectNode, _str projectVersion, _str projectDTD)
{
   int doctypeNode=_xmlcfg_get_first_child(prjHandle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);

   if (doctypeNode>=0) {
      int ret_code=_xmlcfg_set_attribute(prjHandle, doctypeNode, "SYSTEM", projectDTD);
      if (!ret_code) {
         projectNode=_xmlcfg_find_simple(prjHandle,VPJTAG_PROJECT);
         if (projectNode>=0) {
            ret_code=_xmlcfg_set_attribute(prjHandle,projectNode,'Version',projectVersion);
            if (!ret_code) {
               return true;
            }
         }
      }
   }
   _message_box('Failed to set version number in project file');
   return false;
}

/**
 * updates a project to version 9.0
 *
 * @param   compilers         compilers that are available on the user's machine set by {@link _find_compilers()}
 * @param   prjFileName       the absolute filename of the project file to update
 * @param   prjHandle         the handle for the project file
 */
static void update_project90(available_compilers& compilers, _str prjFileName, int prjHandle)
{
   int projectNode;
   if (update_project_version(prjHandle,projectNode,VPJ_FILE_VERSION90,VPJ_DTD_PATH90)) {
      _str vPrjFileName=_strip_filename(prjFileName,'N'):+_xmlcfg_get_attribute(prjHandle,projectNode,'AssociatedFile');
      _str compilerConfigName=determineCompilerConfigName(compilers,prjHandle,vPrjFileName);
      typeless nodes[];
      nodes._makeempty();
      _xmlcfg_find_simple_array(prjHandle,'/Project/Config',nodes);

      typeless cfgIndex;
      for (cfgIndex._makeempty();;) {
         nodes._nextel(cfgIndex);
         if (cfgIndex._isempty()) break;

         // set the CompilerConfigName attribute of the project configuration if it is not already set
         _str configName=_xmlcfg_get_attribute(prjHandle,nodes[cfgIndex],'Name');
         if (''==_ProjectGet_CompilerConfigName(prjHandle,configName)) {
            if (compilerConfigName!='') {
               _ProjectSet_CompilerConfigName(prjHandle,compilerConfigName,configName);
            } else {
               _ProjectSet_CompilerConfigName(prjHandle,determineCompilerConfigName(compilers,prjHandle,vPrjFileName,nodes[cfgIndex]),configName);
            }
         }
      }
   }
}

/**
 * updates a project file to version 9.0
 *
 * @param   ProjectFilename   absolute name of the project file
 * @param   handle            handle to the project if it has already been opened
 */
int _ProjectConvert81To90(_str ProjectFilename, int handle = -1)
{
   // changes from project version 8.1 to 9.0
   //    added CompilerConfigName to each configuration

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectFilename, status);
      openedFile = true;
      if(handle < 0) {
         _message_box(nls("Unable to convert 8.1 project '%s1' to 9.0", ProjectFilename));
         return handle;
      }
   }

   int projectNode=_xmlcfg_find_simple(handle,'Project');
   if (projectNode>=0) {
      _str associatedFile=_xmlcfg_get_attribute(handle,projectNode,"AssociatedFile");

      if (file_eq(_get_extension(associatedFile,true),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
         // recreate all project data to correct the mistakes of the past
         // the primary mistake was in the creatation of config names
         // where the platform was stripped off
         _xmlcfg_delete(handle,projectNode,true);
         _ProjectGet_AssociatedHandle(handle,status);
      } else {
         available_compilers compilers;
         _find_compilers(compilers);

         update_project90(compilers, ProjectFilename, handle);
      }

      // save the converted file
      status = _ProjectSave(handle);
   } else {
      // project file does not have a project node?
      _message_box(nls("Unable to convert 8.1 project '%s1' to 9.0", ProjectFilename));
   }

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * updates a project template file to version 9.0
 *
 * @param   ProjectTemplateFilename    absolute name of the project template file
 * @param   handle                     handle to the project template fiel if it has already been opened
 */
int _ProjectTemplatesConvert81To90(_str ProjectTemplateFilename, int handle=-1)
{
   // changes from project template version 8.1 to 9.0
   //   version number only - changed to be consistent with project file

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectTemplateFilename, status);
      if(handle < 0) {
         _message_box(nls("Unable to convert 8.1 project template file '%s1' to 9.0", ProjectTemplateFilename));
         return handle;
      }
   }

   // update the DOCTYPE
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   if (doctypeNode>=0) {
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH90);
   } else {
      // doesn't have a DOCTYPE, add one
      int firstChildNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX);
      doctypeNode = _xmlcfg_add(handle, firstChildNode, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
      _xmlcfg_set_attribute(handle, doctypeNode, "root", VPTTAG_TEMPLATES);
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH90);
   }

   // put the new version
   _xmlcfg_set_path(handle, VPTTAG_TEMPLATES, "Version", VPT_FILE_VERSION90);

   // save the converted file
   status = _ProjectTemplatesSave(handle);

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * updates a project file to version 9.1
 *
 * @param   ProjectFilename   absolute name of the project file
 * @param   handle            handle to the project if it has already been opened
 */
int _ProjectConvert90To91(_str ProjectFilename, int handle = -1)
{
   // changes from project version 9.0 to 9.1
   //    change DTD
   //    insert forward compatibility node

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectFilename, status);
      openedFile = true;
      if(handle < 0) {
         _message_box(nls("Unable to convert 9.0 project '%s1' to 9.1", ProjectFilename));
         return handle;
      }
   }

   int projectNode;
   update_project_version(handle,projectNode,VPJ_FILE_VERSION91,VPJ_DTD_PATH91);

   if (projectNode >= 0) {
      // insert forward compatibility node
      int compatNode=_xmlcfg_set_path2(handle, VPJX_COMPATIBLEVERSIONS, VPJTAG_PREVVERSION, "VersionNumber", VPJ_FILE_VERSION90);
   
      if (compatNode >= 0) {
         // save the converted file
         status = _ProjectSave(handle);
      } else {
         _message_box(nls("Unable to convert 9.0 project '%s1' to 9.1", ProjectFilename));
      }
   } else {
      _message_box(nls("Unable to convert 9.0 project '%s1' to 9.1", ProjectFilename));
   }

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * updates a project template file to version 9.1
 *
 * @param   ProjectTemplateFilename    absolute name of the project template file
 * @param   handle                     handle to the project template fiel if it has already been opened
 */
int _ProjectTemplatesConvert90To91(_str ProjectTemplateFilename, int handle=-1)
{
   // changes from project template version 9.0 to 9.1
   //   version number only - changed to be consistent with project file

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectTemplateFilename, status);
      if(handle < 0) {
         _message_box(nls("Unable to convert 9.0 project template file '%s1' to 9.1", ProjectTemplateFilename));
         return handle;
      }
   }

   // update the DOCTYPE
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   if (doctypeNode>=0) {
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH91);
   } else {
      // doesn't have a DOCTYPE, add one
      int firstChildNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX);
      doctypeNode = _xmlcfg_add(handle, firstChildNode, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
      _xmlcfg_set_attribute(handle, doctypeNode, "root", VPTTAG_TEMPLATES);
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH91);
   }

   // put the new version
   _xmlcfg_set_path(handle, VPTTAG_TEMPLATES, "Version", VPT_FILE_VERSION91);

   // save the converted file
   status = _ProjectTemplatesSave(handle);

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * updates a project file to version 10.0
 *
 * @param   ProjectFilename   absolute name of the project file
 * @param   handle            handle to the project if it has already been opened
 */
int _ProjectConvert91To100(_str ProjectFilename, int handle = -1)
{
   // changes from project version 9.1 to 10.0
   //    change DTD
   //    move dependencies from project to config level

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectFilename, status);
      openedFile = true;
      if(handle < 0) {
         _message_box(nls("Unable to convert 9.1 project '%s1' to 10.0", ProjectFilename));
         return handle;
      }
   }

   int projectNode;
   update_project_version(handle,projectNode,VPJ_FILE_VERSION100,VPJ_DTD_PATH100);

   // insert forward compatibility node
   _xmlcfg_set_path2(handle, VPJX_COMPATIBLEVERSIONS, VPJTAG_PREVVERSION, "VersionNumber", VPJ_FILE_VERSION91);

   if (projectNode >= 0) {
      // move dependencies from project to config level.  the cleanest way
      // to do this is to loop over all configs and check to see if the
      // 'Build', 'Rebuild', or 'Clean' target (in that order) have a
      // DependsRef attribute set.  if so, copy the entire dependency set
      // with that name into the config's dependency set.
      _str configList[];
      _ProjectGet_ConfigNames(handle, configList);
      int i, numConfigs = configList._length();
      for(i = 0; i < numConfigs; i++) {
         _str configName = configList[i];
         if(configName == "") continue;

         _str type = _ProjectGet_Type(handle, configList[i]);
         if (type == 'java') {
            // We want to add the UnitTest target to this config. Add it right
            // after the Execute target
            int configNode = _ProjectGet_ConfigNode(handle, configList[i]);
            if (configNode >= 0) {
               int node = _xmlcfg_find_simple(handle, VPJTAG_MENU'/'VPJTAG_TARGET:+XPATH_STRIEQ('Name', 'Execute'), configNode);
               if (node >= 0) {
                  node = _xmlcfg_add(handle, node, VPJTAG_TARGET, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AFTER);
                  _xmlcfg_set_attribute(handle, node, 'Name', 'UnitTest');
                  _xmlcfg_set_attribute(handle, node, 'MenuCaption', 'Unit Test');
                  _xmlcfg_set_attribute(handle, node, 'ShowOnMenu', 'Never');
                  _xmlcfg_set_attribute(handle, node, 'Dialog', '');
                  _xmlcfg_set_attribute(handle, node, 'BuildFirst', '1');
                  _xmlcfg_set_attribute(handle, node, 'Deletable', '0');
                  _xmlcfg_set_attribute(handle, node, 'CaptureOutputWith', 'ProcessBuffer');
                  _xmlcfg_set_attribute(handle, node, 'PreMacro', 'unittest_pre_build');
                  _xmlcfg_set_attribute(handle, node, 'PostMacro', 'unittest_post_build');
                  _xmlcfg_set_attribute(handle, node, 'RunFromDir', '%rw');
                  node = _xmlcfg_add(handle, node, VPJTAG_EXEC, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
                  _xmlcfg_set_attribute(handle, node, 'CmdLine', 'java %cp ' VS_UNITTEST_JUNITCORE);
               }
            }
         }

         // check for build, rebuild, and clean targets
         int buildTargetNode = _ProjectGet_TargetNode(handle, "Build", configName);
         int rebuildTargetNode = _ProjectGet_TargetNode(handle, "Rebuild", configName);
         int cleanTargetNode = _ProjectGet_TargetNode(handle, "Clean", configName);

         // if no build target found, this configuration should not have dependencies
         if(buildTargetNode < 0) {
            continue;
         }

         // get the name of the dependency set that this target depends on
         _str dependsRef = _ProjectGet_TargetDependsRef(handle, buildTargetNode);
         if(dependsRef == "") {
            // if the DependsRef attribute is empty, then a global dependency
            // set named 'Build' is implied so check for it
            dependsRef = "Build";
         }

         // find that dependency set
         int depProjectNodes[] = null;
         _ProjectGet_DependencyProjectNodesForRef(handle, configName, dependsRef, depProjectNodes);

         // if there are dependencies, reset the DependsRef attribute for
         // build, rebuild, and clean targets.  if there are no dependencies,
         // remove the DependsRef attribute
         int numDepProjects = depProjectNodes._length();
         if(buildTargetNode >= 0) {
            _ProjectSet_TargetDependsRef(handle, buildTargetNode, numDepProjects > 0 ? configName : "");
         }
         if(rebuildTargetNode >= 0) {
            _ProjectSet_TargetDependsRef(handle, rebuildTargetNode, numDepProjects > 0 ? configName : "");
         }
         if(cleanTargetNode >= 0) {
            _ProjectSet_TargetDependsRef(handle, cleanTargetNode, numDepProjects > 0 ? configName : "");
         }

         // if there are no dependencies, there is nothing else to do
         if(numDepProjects <= 0) {
            continue;
         }

         // get the dependency set for this config
         int newDependenciesNode = _ProjectGet_DependenciesNode(handle, configName, true);
         if(newDependenciesNode < 0) {
            _message_box(nls("Unable to convert 9.1 project '%s1' to 10.0", ProjectFilename));
            break;
         }

         int d;
         for(d = 0; d < numDepProjects; d++) {
            int depProjectNode = depProjectNodes[d];
            if(depProjectNode < 0) continue;

            // copy the dependency to the config level dependencies container
            _xmlcfg_copy(handle, newDependenciesNode, handle, depProjectNode, VSXMLCFG_COPY_AS_CHILD);
         }
      }

      // NOTE: this is where global dependency sets from previous versions would
      //       be removed, but in an effort to keep as much backwards compatibility
      //       as possible, they will be left.  this is harmless because they will
      //       be ignored by the 10.0 project system.
      
      // save the converted file
      status = _ProjectSave(handle);

   } else {
      _message_box(nls("Unable to convert 9.1 project '%s1' to 10.0", ProjectFilename));
   }

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * updates a project template file to version 10.0
 *
 * @param   ProjectTemplateFilename    absolute name of the project template file
 * @param   handle                     handle to the project template fiel if it has already been opened
 */
int _ProjectTemplatesConvert91To100(_str ProjectTemplateFilename, int handle=-1)
{
   // changes from project template version 9.1 to 10.0
   //   version number only - changed to be consistent with project file

   int status = 0;

   // open the file if necessary
   boolean openedFile = false;
   if(handle < 0) {
      handle = _xmlcfg_open(ProjectTemplateFilename, status);
      if(handle < 0) {
         _message_box(nls("Unable to convert 9.1 project template file '%s1' to 10.0", ProjectTemplateFilename));
         return handle;
      }
   }

   // update the DOCTYPE
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   if (doctypeNode>=0) {
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH100);
   } else {
      // doesn't have a DOCTYPE, add one
      int firstChildNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX);
      doctypeNode = _xmlcfg_add(handle, firstChildNode, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_BEFORE);
      _xmlcfg_set_attribute(handle, doctypeNode, "root", VPTTAG_TEMPLATES);
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH100);
   }

   // put the new version
   _xmlcfg_set_path(handle, VPTTAG_TEMPLATES, "Version", VPT_FILE_VERSION100);

   // save the converted file
   status = _ProjectTemplatesSave(handle);

   // close the file if we opened it
   if(openedFile) {
      _xmlcfg_close(handle);
   }

   return status;
}

/**
 * Gets the specified section from the current view
 * and copies it into temp_view_id.
 *
 * Leaves temp_view_id active.
 *
 * @param section_name
 *               Name of section to get
 *
 * @param temp_view_id
 *               View id to put section data into.
 *
 * @return returns 0 if successfule
 */
static int my_ini_get_section3(_str section_name,int &temp_view_id)
{
   int ini_view_id;
   get_window_id(ini_view_id);
   int status=_ini_find_section(section_name);
   if (status) {
      return(status);
   }
   down();
   _str line='';
   get_line(line);
   if (substr(line,1,1)=='[') {
      return(0);// Nothing was in the section, but I guess we were still technically
   }            // succesful.
   typeless mark_id=_alloc_selection();
   _select_line(mark_id);
   if (_ini_find_section('')) {
      bottom();
   } else {
      up();
   }
   _select_line(mark_id);
   activate_window(temp_view_id);
   _copy_to_cursor(mark_id);
   p_line=1;
   _free_selection(mark_id);

   // Remove blank lines:
   top();
   up();
   while (!down()) {
      get_line(line);
      if (line=="") {
         _delete_line();
         up();
      }
   }
   p_line=1;

   return(0);
}

//Appends sections from current view to OutputViewId if SectionNamePrefix matches
static void AppendSectionsToView(_str SectionNamePrefix,int OutputViewId,boolean listboxFormat=false)
{
   int orig_view_id=p_window_id;
   save_pos(auto p);
   top();up();
   int status=0;
   int markid=_alloc_selection();
   for (;;) {
      status=search('^\['_escape_re_chars(SectionNamePrefix)'?@\]','@rih');
      if (status) {
         break;
      }
      if (down()) break;
      if (get_text()!='[') {
         _deselect(markid);
         _select_line(markid);
         status=search('^\[?@\]$','@rh');
         if (status) {
            bottom();
         } else {
            up();
         }
         status=_select_line(markid);
         if (status) {
            clear_message();
         }
         if (status!=TEXT_NOT_SELECTED_RC) {
            p_window_id=OutputViewId;
            bottom();
            _copy_to_cursor(markid);
            if (listboxFormat) {
               _shift_selection_right(markid);
               //_showbuf(p_buf_id);
            }
            p_window_id=orig_view_id;
         }
      }
   }
   p_window_id=orig_view_id;
   restore_pos(p);
   _free_selection(markid);
}
static int GetProjectFiles70(_str ProjectFilename,int &FileListViewId,
                    _str MakefileIndicator="",
                    _str Makefilename=null,// null means get makefile and type from project file.
                    // Anything else means already
                    // have Makefilename and MakeFileType
                    _str MakefileType="",
                    boolean CreateFilesView=true,
                    boolean ConvertFilesToAbsolute=true,
                    boolean listboxFormat=false,
                    boolean removeDuplicates=false
                    )
{
   _str ch=MakefileIndicator;
   _str ProjectDir=_strip_filename(ProjectFilename,'N');


   int orig_view_id=0;
   int temp_view_id=0;
   if (CreateFilesView) {
      orig_view_id=_create_temp_view(FileListViewId);
      activate_window(orig_view_id);
   }
   int status=_open_temp_view(ProjectFilename,temp_view_id,orig_view_id);
   if (!status) {//if status, want to hit status case below...

      //In this case, we were passed in a view id to fill(see if above)
      p_window_id=FileListViewId;
      bottom();
      int append_after_ln=p_line;
      p_window_id=temp_view_id;//Activate ProjectFile view

      //Get the files section from the current view, and put
      //it in FileListViewId.  Leaves FileListViewId active.
      status=my_ini_get_section3("FILES",FileListViewId);

      if (!status) {//if status, want to hit status case below...
         if (listboxFormat) {
            p_window_id=FileListViewId;
            p_line=append_after_ln;_end_line();
            search('^','Rh@',' ');bottom();
            p_window_id=temp_view_id;//Activate ProjectFile view
         }
         p_window_id=temp_view_id;//Activate ProjectFile view

         //Append the other Files sections to the vielw
         AppendSectionsToView("Files.",FileListViewId,listboxFormat);
         if (ConvertFilesToAbsolute) {
            _ConvertViewToAbsolute(FileListViewId,ProjectDir,append_after_ln,listboxFormat);
         }
         activate_window(FileListViewId);
         p_line=append_after_ln;_end_line();
         search(FILESEP2,'@h',FILESEP);

         p_window_id=orig_view_id;
         _delete_temp_view(temp_view_id);
      } else {
         //Doesn't matter....
         _delete_temp_view(temp_view_id);
         status=0;
      }
   }
   activate_window(orig_view_id);
   //MaybeAddFilesFromMakefile(ProjectFilename,Makefilename,MakefileType,FileListViewId,ConvertFilesToAbsolute,MakefileIndicator,listboxFormat);
   if (removeDuplicates) {
      p_window_id=FileListViewId;
      typeless markid=_alloc_selection();
      top();_select_line(markid);
      bottom();
      status=_select_line(markid);
      if (status) clear_message();
      if (!status) {
         int Noflines=_sort_selection(_fpos_case'-F',markid);
         _delete_selection(markid);
      }
      _free_selection(markid);
      _remove_duplicates(_fpos_case);
      p_window_id=orig_view_id;
   }
   return(0);
}
static int getProjectFileList70(_str projectName, _str (&fileList)[])
{
   fileList._makeempty();

   int view_id;
   get_window_id(view_id);
   //11:45am 8/18/1997
   //Dan changed for makefile support
   //status=_ini_get_section(projectName, "FILES", ini_view_id);
   //status=GetProjectFiles(projectName, ini_view_id,'',null,'',true,false);
   int ini_view_id=0;
   int status=GetProjectFiles70(projectName, ini_view_id,'',null,'',true,true,false,true);
   if (status) {
      activate_window(view_id);
      return(1);
   }
   activate_window(ini_view_id);
   if (p_Noflines+10>_default_option(VSOPTION_WARNING_ARRAY_SIZE)) {
      _default_option(VSOPTION_WARNING_ARRAY_SIZE,p_Noflines+10);
   }

   _str olddir='';
   if (_workspace_filename!='') {
      olddir=getcwd();
      chdir(_GetWorkspaceDir(),1);
   }
   _str line;
   top();
   up();
   int i;
   i= 0;
   while (!down()) {
      get_line(line);
      if (line!='') {
         fileList[i]= /*relative(*/line/*)*/;
         ++i;
      }
   }
   if (_workspace_filename!='') {
      chdir(olddir,1);
   }
   _delete_temp_view(ini_view_id);
   activate_window(view_id);
   return(0);
}
// Desc: Get a list of filter names, their patterns, the associate types flags,
//       and the application command.
static int _getFilterList(_str projectName, _str (&nameList)[]
                   ,_str (&patternList)[], int (&assocTypeList)[]
                   ,_str (&appCommandList)[])
{
   _str result;
   int rc;

   nameList._makeempty();
   patternList._makeempty();
   assocTypeList._makeempty();
   appCommandList._makeempty();

   // Get filter name list:
   int iiCount;
   iiCount= 0;
   rc= _ini_get_value(projectName,"GLOBAL","FILTERNAME",result);
   if (rc) {
      // If the section is not defined for this project, use the default filters:
      int i;
      for (i=0; i<filterDefaultName._length(); i++) {
         nameList[i]= filterDefaultName[i];
      }
      iiCount= filterDefaultName._length();
   } else {
      result= _ini_xlat_multiline(result);
      int i;
      for (i=0;;i++) {
         if (result=='') break;
         nameList[i]= _parse_line(result);
         iiCount++;
      }
   }

   // Get filter pattern list:
   _str tKey, tValue;
   rc= _ini_get_value(projectName,"GLOBAL","FILTERPATTERN",result);
   if (rc) {
      // If the section is not defined for this project, use the default filters:
      int i;
      for (i=0; i<iiCount; i++) {
         tKey= lowcase(nameList[i]);
         tValue= "";
         if (filterDefaultPattern._indexin(tKey)) {
            tValue= filterDefaultPattern:[tKey];
         }
         patternList[i]= tValue;
      }
   } else {
      result= _ini_xlat_multiline(result);
      int i;
      for (i=0; i<iiCount ;i++) {
         if (result=='') {
            patternList[i]= "";
         } else {
            patternList[i]= _parse_line(result);
         }
      }
   }

   // Get filter application command list:
   rc= _ini_get_value(projectName,"GLOBAL","FILTERAPPCOMMAND",result);
   if (rc) {
      // If the section is not defined for this project, use the default filters:
      int i;
      for (i=0; i<iiCount; i++) {
         tKey= lowcase(nameList[i]);
         tValue= "";
         if (filterDefaultAppCommand._indexin(tKey)) {
            tValue= filterDefaultAppCommand:[tKey];
         }
         appCommandList[i]= tValue;
      }
   } else {
      result= _ini_xlat_multiline(result);
      int i;
      for (i=0; i<iiCount ;i++) {
         if (result=='') {
            appCommandList[i]= "";
         } else {
            appCommandList[i]= _parse_line(result);
         }
      }
   }

   // Get associate file types list:
   typeless atype='';
   rc= _ini_get_value(projectName,"GLOBAL","FILTERASSOCIATEFILETYPES",result);
   if (rc) {
      // If the section is not defined for this project, use the default filters:
      int i;
      for (i=0; i<iiCount; i++) {
         tKey= lowcase(nameList[i]);
         if (filterDefaultFileAssociation._indexin(tKey)) {
            tValue= filterDefaultFileAssociation:[tKey];
            assocTypeList[i]= (int)tValue;
         } else {
            assocTypeList[i]= 0;
         }
      }
   } else {
      int i;
      for (i=0; i<iiCount; i++) {
         if (result != "") {
            parse result with atype result;
         } else {
            atype= "";
         }
         if (atype== "") {
            assocTypeList[i]= 0;
         } else {
            assocTypeList[i]= atype;
         }
      }
   }

   return(0);
}
static int toolbarBuildFilterList2(_str projectName,_str ConfigList[],int tree_wid,int handle)
{
   _str nameList[];
   _str patternList[];
   _str appCommandList[];
   _str fileList[];
   int assocTypeList[];

   if (projectName== "") return(0);
   _str oldext=_get_extension(projectName);
   _getFilterList(projectName, nameList, patternList, assocTypeList, appCommandList);

   /*
      Make sure the following are true for the patterns
        *  Only one folder can match a specific pattern.
           For example, can't have two folders with *.c

        *  All pattern are of the form "*.<Extension>" where
           Extension has no wildcards.

        *  "*.*" and "*" are convert to the current platform ALLFILES_RE.

        *  Folders with ALLFILES_RE may NOT contain any other patterns.  If
           they do, the ALLFILES_RE folder is removed.

   */
   boolean ExtHashTable:[];
   int i;
   _str list='';
   _str result='';
   _str pattern='';
   _str rest='';
   for (i=0;i<patternList._length();++i) {
      list=patternList[i];
      result='';
      for (;;) {
         if (list=='') break;
         parse list with pattern ';' list;
         if (pattern=='*' || pattern=='*.*') {
            // If ALLFILES_RE is the only pattern in this list
            if (patternList[i]==pattern && !ExtHashTable._indexin(ALLFILES_RE)) {
               ExtHashTable:[ALLFILES_RE]=true;

               result=ALLFILES_RE;
               break;
            }
            continue;
         }
         parse pattern with "*." rest;
         if (substr(pattern,1,2)=='*.' &&
             !iswildcard_for_any_platform(rest) &&
             rest!='' && !ExtHashTable._indexin(lowcase(rest))) {
            ExtHashTable:[lowcase(rest)]=true;
            if (result=='') {
               result=pattern;
            } else {
               result=result';'pattern;
            }
         }
      }
      if (result=='') {
         nameList._deleteel(i);
         patternList._deleteel(i);
         assocTypeList._deleteel(i);
         appCommandList._deleteel(i);
         --i;
      } else {
         patternList[i]=result;
      }
   }
   getProjectFileList70(projectName, fileList);
   //debugvar(nameList,'namelist');
   //debugvar(patternList,'patternlist');
   //debugvar(fileList,'fileList');
   if (nameList._isempty() || nameList._length()== 0) return(0);
   /*
        If there are more than 1000 files in the project,
        don't fill in the extensions
        return(0);
   */

   // Show project name in root node:
   tree_wid._TreeSetInfo(TREE_ROOT_INDEX,0,_pic_workspace,_pic_workspace);

   //_SetProjTreeColWidth();

   int doneCount;
   doneCount= 0;
   int FileStatus[];
   FileStatus._makeempty();
   //This code was dead.
   tree_wid._TreeSetInfo(TREE_ROOT_INDEX, 1);
   int BitmapIndexList[];
   BitmapIndexList[0]=_pic_doc_w;
   BitmapIndexList[1]=_pic_doc_r;
   BitmapIndexList[2]=_pic_vc_co_user_w;
   BitmapIndexList[3]=_pic_vc_co_user_r;
   BitmapIndexList[4]=_pic_vc_co_other_x_w;
   BitmapIndexList[5]=_pic_vc_co_other_x_r;
   BitmapIndexList[6]=_pic_vc_co_other_m_w;
   BitmapIndexList[7]=_pic_vc_co_other_m_r;
   BitmapIndexList[8]=_pic_vc_available_w;
   BitmapIndexList[9]=_pic_vc_available_r;
   mou_hour_glass(1);

   int orig_wid=p_window_id;
   p_window_id=tree_wid;
   /*
      Convert old folder stuff to new XML folders
   */
   int TempHandle=_ProjectCreate('');
   for (i=0;i<patternList._length();++i) {
      int NodeIndex=_xmlcfg_set_path2(TempHandle,VPJX_FILES,VPJTAG_FOLDER,'Name',nameList[i]);
      if (patternList[i]=='*.*' || patternList[i]=='*') {
         _xmlcfg_set_attribute(TempHandle,NodeIndex,'Filters','');
      } else {
         _xmlcfg_set_attribute(TempHandle,NodeIndex,'Filters',patternList[i]);
      }
   }
   int Node=_ProjectGet_FilesNode(TempHandle);
   int ExtToNodeHashTab:[];
   fileList._sort('2');
   _CreateProjectFilterTree(tree_wid,TREE_ROOT_INDEX,TempHandle,Node,ExtToNodeHashTab);
   int status= _InsertProjectFileList(fileList,
                                  ExtToNodeHashTab,//assocTypeList,
                                  //patternList,
                                  BitmapIndexList,
                                  (typeless)editor_name('P'),
                                  MAXINT,
                                  0,
                                  0);
   _xmlcfg_close(TempHandle);

   //tree_wid.p_active_form.p_visible=1;stop();
   mou_hour_glass(0);
   //4:16pm 5/3/1999
   //Might be able to get rid of this
   p_window_id=tree_wid;
   int child=0;
   int index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);
   _str filename='';
   boolean done=false;
   for (i=0;;++i) {
      if (index<0) break;
      //_TreeSortCaption(index,'I'  /*_fpos_case*/);

      int FileIndex;
      int flags=VSXMLCFG_ADD_AS_CHILD;

      if (i>=nameList._length()) {
         // We got files out side a folder.  The all files folder was missing.
         done=true;
         child=index;
         FileIndex=_xmlcfg_set_path(handle,VPJX_FILES);
      } else {
         int NodeIndex=_xmlcfg_set_path2(handle,VPJX_FILES,VPJTAG_FOLDER,'Name',nameList[i]);
         if (patternList[i]=='*.*' || patternList[i]=='*') {
            _xmlcfg_set_attribute(handle,NodeIndex,'Filters','');
         } else {
            _xmlcfg_set_attribute(handle,NodeIndex,'Filters',patternList[i]);
         }
         FileIndex=NodeIndex;
         child=_TreeGetFirstChildIndex(index);
      }
      for (;;) {
         if (child<0) break;
         parse _TreeGetCaption(child) with "\t" filename;
         FileIndex=_xmlcfg_add(handle,FileIndex,VPJTAG_F,VSXMLCFG_NODE_ELEMENT_START_END,flags);
         _xmlcfg_set_attribute(handle,FileIndex,'N',_NormalizeFile(_RelativeToProject(filename,projectName)));

         // if this is an ant build file, set the Type attribute
         if (_IsAntBuildFile(filename)) {
            _xmlcfg_set_attribute(handle, FileIndex, "Type", "Ant");
         } else if (_IsNAntBuildFile(filename)) {
            // if this is a NAnt build file, set the Type attribute
            _xmlcfg_set_attribute(handle, FileIndex, "Type", "NAnt");
         } else if (_IsMakefile(filename)) {
            // if this is a makefile, set the Type attribute
            _xmlcfg_set_attribute(handle, FileIndex, "Type", "Makefile");
         }

         child=_TreeGetNextSiblingIndex(child);
         flags=0;
      }
      if (done) break;
      index=_TreeGetNextSiblingIndex(index);
   }
   int orig_view_id=0;
   int temp_view_id=0;
   _str line='';
   int NodeIndex=0;
   for (i=0;i<ConfigList._length();++i) {
      get_window_id(orig_view_id);
      status=_ini_get_section(projectName,'FILES.'ConfigList[i],temp_view_id);
      if (status) {
         //say(projectName);
         //say('not found FILES.'ConfigList[i]);
         continue;
      }
      //say('temp_view_id='temp_view_id);
      activate_window(temp_view_id);
      top();up();

      for (;;) {
         if (down()) {
            break;
         }
         get_line(line);
         if (line!='') {
            line=_NormalizeFile(line);
            pattern=VPJX_FILES'//'VPJTAG_F'[file-eq(@N,"'line'")]';
            NodeIndex=_xmlcfg_find_simple(handle,pattern);
            if (NodeIndex>=0) {
               //say('found 'line);
               _str configs=_xmlcfg_get_attribute(handle,NodeIndex,'C');
               if (configs=='') {
                  configs='"'ConfigList[i]'"';
               } else {
                  configs=configs:+' "'ConfigList[i]'"';
               }
               _xmlcfg_set_attribute(handle,NodeIndex,'C',configs);
            }
         }
      }
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
   }
   p_window_id=orig_wid;
   return(status);
}
int _WorkspaceConvert70ToXML(_str WorkspaceFilename)
{
/*
[ASSOCIATION]
workspacefile=cpp.dsw
workspacetype=microsoft visual c++
<Workspace Version="1.0" AssociatedFile="cpp.dsw" AssociatedFileType="microsoft visual c++">
    <Projects>
        <Project Name="abc.vpj" />
    </Projects>
    <Environment>
        <Set Name="VERSION" Value="%xe%wp%-1" />
    </Environment>
</Workspace>
*/
   if (!file_exists(WorkspaceFilename)) {
      return(FILE_NOT_FOUND_RC);
   }
   {
      int orig_view_id;
      int temp_view_id;
      int status=_open_temp_view(WorkspaceFilename,temp_view_id,orig_view_id);
      if (!status) {
         top();
         status=search('[\[<]','@rh');
         _str ch=get_text();
         _delete_temp_view(temp_view_id);
         activate_window(orig_view_id);
         // IF this file has not been converted yet.
         if (status || ch!='[') {
            _message_box(nls("Workspace '%s' is not recognized as valid and can't be converted",WorkspaceFilename));
            return(1);
         }
      }
   }


   int handle=_WorkspaceCreate(WorkspaceFilename);
   _str AssociatedWorkspaceFile='';
   _str AssociationType='';
   _ini_get_value(WorkspaceFilename,'ASSOCIATION','workspacefile',AssociatedWorkspaceFile);
   _ini_get_value(WorkspaceFilename,'ASSOCIATION','workspacetype',AssociationType);
   if (AssociatedWorkspaceFile!='') {
      _xmlcfg_set_path(handle,VPWX_WORKSPACE,'AssociatedFile',_NormalizeFile(AssociatedWorkspaceFile));
   }
   if (AssociationType!='') {
      _xmlcfg_set_path(handle,VPWX_WORKSPACE,'AssociatedFileType',AssociationType);
   }

   _str ch='';
   _str ProjectFilename='';
   int orig_view_id=0;
   int temp_view_id=0;
   get_window_id(orig_view_id);
   int status=_ini_get_section(WorkspaceFilename,"ProjectFiles",temp_view_id);
   if (!status) {
      activate_window(temp_view_id);
      top();up();
      for (;;) {
         if (down()) break;
         get_line(ProjectFilename);
         if (ProjectFilename!='') {
            ProjectFilename=translate(ProjectFilename,FILESEP,FILESEP2);
            _xmlcfg_set_path2(handle,VPWX_PROJECTS,VPWTAG_PROJECT,'File',_NormalizeFile(ProjectFilename));
            ProjectFilename=_AbsoluteToWorkspace(ProjectFilename,WorkspaceFilename);
            //say('ProjectFilename='ProjectFilename);
            /*
               Check if the this project file has already been converted.
            */
            int orig_view_id2;
            int temp_view_id2;
            status=_open_temp_view(ProjectFilename,temp_view_id2,orig_view_id2,"+d");
            if (!status) {
               top();
               status=search('[\[<]','@rh');
               ch=get_text();
               _delete_temp_view(temp_view_id2);
               activate_window(orig_view_id2);
               // IF this file has not been converted yet.
               if (!status && ch=='[') {
                  //say('h1 code not finished yet');
                  //say('convert 'ProjectFilename);
                  message(nls("Converting project '%s'",ProjectFilename));
                  status=_ProjectConvert70ToXML(ProjectFilename);
                  p_window_id._WorkspacePutProjectDate(ProjectFilename,WorkspaceFilename);
                  clear_message();
                  //say('status='status);
                  if (status) {
                     _message_box(nls("Workspace was not converted.  Correct problem with project file and try again."));
                     _delete_temp_view(temp_view_id);
                     _xmlcfg_close(handle);
                     activate_window(orig_view_id);
                     return(status);
                  }
                  //_str old= _workspace_filename; _workspace_filename=WorkspaceFilename;
                  p_window_id._WorkspacePutProjectDate(ProjectFilename,WorkspaceFilename);
                  //_workspace_filename=old;
               }
            }
         }
      }
      _delete_temp_view(temp_view_id);
   }
   int ProjectsNode=_WorkspaceGet_ProjectsNode(handle);
   if (ProjectsNode>=0) {
      _xmlcfg_sort_on_attribute(handle,ProjectsNode,'File','2');
   }

   _str line='';
   _str Name='';
   _str Value='';
   status=_ini_get_section(WorkspaceFilename,"Environment",temp_view_id);
   if (!status) {
      activate_window(temp_view_id);
      top();up();
      for (;;) {
         if (down()) break;
         get_line(line);
         if(first_char(line) == ';') continue;
         parse line with Name'='Value;
         if (Name!='') {
            int NodeIndex=_xmlcfg_set_path2(handle,VPWX_ENVIRONMENT,VPWTAG_SET,'Name',Name);
            _xmlcfg_set_attribute(handle,NodeIndex,'Value',Value);
         }
      }
      _delete_temp_view(temp_view_id);
   }

   _str DepFileNames='';
   _str AbsProjectFilename='';
   int project_handle=0;
   int NodeIndex=0;
   _str DepFile='';
   status=_ini_get_section(WorkspaceFilename,"Dependencies",temp_view_id);
   if (!status) {
      activate_window(temp_view_id);
      top();up();
      for (;;) {
         if (down()) break;
         get_line(line);
         if(first_char(line) == ';') continue;
         parse line with ProjectFilename'='DepFileNames;
         if (ProjectFilename!='') {
            ProjectFilename=translate(ProjectFilename,FILESEP,FILESEP2);
            AbsProjectFilename= _AbsoluteToWorkspace(strip(ProjectFilename,'B','"'),WorkspaceFilename);
            project_handle=_xmlcfg_open(AbsProjectFilename,status);
            //say('dep for 'ProjectFilename' H='project_handle' s='get_message(status));
            if (project_handle>=0) {
               //_showxml(project_handle,TREE_ROOT_INDEX,-1);
               NodeIndex=_xmlcfg_find_simple(project_handle,VPJX_DEPENDENCIES_DEPRECATED);
               //say('NodeIndex='NodeIndex);
               boolean doSave=true;
               if (NodeIndex>=0) {
                  _xmlcfg_delete(handle,NodeIndex,true);
               }
               for (;;) {
                  DepFile=parse_file(DepFileNames,false);
                  if (DepFile=="") break;
                  //say('DepFile='DepFile);
                  DepFile=translate(DepFile,FILESEP,FILESEP2);
                  DepFile=_AbsoluteToWorkspace(DepFile,WorkspaceFilename);
                  DepFile=_RelativeToProject(DepFile,AbsProjectFilename);
                  _xmlcfg_set_path(project_handle,VPJX_DEPENDENCIES_DEPRECATED,'Name','Build');
                  _xmlcfg_set_path2(project_handle,VPJX_DEPENDENCIES_DEPRECATED,VPJTAG_DEPENDENCY,'Project',_NormalizeFile(DepFile));
                  doSave=true;
                  //say('save status='status);
               }
               if (doSave) {
                  int Node=_xmlcfg_find_simple(project_handle,VPJX_DEPENDENCIES_DEPRECATED);
                  if (Node>=0) {
                     _xmlcfg_sort_on_attribute(project_handle,Node,'Project','2');
                  }
                  //_message_box('got here');
                  status=_ProjectSave(project_handle);
                  p_window_id._WorkspacePutProjectDate(AbsProjectFilename,WorkspaceFilename);
                  if (status) {
                     _message_box(nls("Unable to write dependencies to project '%s'\n\n",AbsProjectFilename):+get_message(status)"\n\n"nls("Workspace was not converted.  Correct problem with project file"));
                     _delete_temp_view(temp_view_id);
                     _xmlcfg_close(handle);
                     activate_window(orig_view_id);
                     return(status);
                  }
               }
               _xmlcfg_close(project_handle);
            }
         }
      }
      _delete_temp_view(temp_view_id);
   }


   copy_file(WorkspaceFilename,_strip_filename(WorkspaceFilename,'E')'.bakvpw');
   status=_WorkspaceSave(handle);
   _xmlcfg_close(handle);
   activate_window(orig_view_id);
   return(0);
}

_str _ProjectGet_DebugCallbackName(int handle,_str config=GetCurrentConfigName())
{
   return(_xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]","DebugCallbackName"));
}
void _ProjectSet_DebugCallbackName(int handle,_str DebugCallbackName,_str config=GetCurrentConfigName())
{
   _xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]","DebugCallbackName",DebugCallbackName);
}
_str _ProjectGet_WorkingDir(int handle)
{
   return(translate(_xmlcfg_get_path(handle,VPJX_PROJECT,"WorkingDir"),FILESEP,FILESEP2));
}
_str _ProjectSet_WorkingDir(int handle,_str WorkingDir)
{
   return(_xmlcfg_set_path(handle,VPJX_PROJECT,"WorkingDir",_NormalizeFile(WorkingDir)));
}
_str _ProjectGet_BuildSystem(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"BuildSystem"));
}
void _ProjectSet_BuildSystem(int handle,_str BuildSystem)
{
   _xmlcfg_set_path(handle,VPJX_PROJECT,"BuildSystem",BuildSystem);
}
_str _ProjectGet_BuildMakeFile(int handle)
{
   return(translate(_xmlcfg_get_path(handle,VPJX_PROJECT,"BuildMakeFile"),FILESEP,FILESEP2));
}
void _ProjectSet_BuildMakeFile(int handle,_str BuildMakeFile)
{
   _xmlcfg_set_path(handle,VPJX_PROJECT,"BuildMakeFile",_NormalizeFile(BuildMakeFile));
}
_str _ProjectGet_TagFileExt(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"TagFileExt"));
}
_str _ProjectGet_OnSetActiveMacro(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"OnSetActiveMacro"));
}
void _ProjectGet_Macro(int handle,_str (&MacroCmdLines)[])
{
   _xmlcfg_find_simple_array(handle,VPJX_EXECMACRO"/@CmdLine",MacroCmdLines,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
}
_str _ProjectGet_MacroList(int handle)
{
   typeless array[];
   _str list='';
   int i;
   _xmlcfg_find_simple_array(handle,VPJX_EXECMACRO,array);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,"\1");
      }
      strappend(list,_xmlcfg_get_attribute(handle,array[i],'CmdLine'));
   }
   return(list);
}
void _ProjectSet_MacroList(int handle,_str list)
{
   int Node=_xmlcfg_set_path(handle,VPJX_MACRO);
   _str item='';
   _xmlcfg_delete(handle,Node,true);
   for (;;) {
      parse list with item "\1" list;
      if (item=="" && list=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_MACRO,VPJTAG_EXECMACRO,'CmdLine',item);
   }
}

/**
 * Get array of config names from project
 *
 * @param handle
 * @param array
 */
void _ProjectGet_ConfigNames(int handle,_str (&array)[])
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"/@Name",array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
}
void _ProjectGet_Configs(int handle,typeless (&array)[])
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG,array,TREE_ROOT_INDEX);
}

_str _ProjectGet_OutputFile(int handle, _str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return("");
   }
   return(translate(_xmlcfg_get_attribute(handle,Node,'OutputFile'),FILESEP,FILESEP2));
}
void _ProjectSet_OutputFile(int handle, _str value,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return;
   }
   _xmlcfg_set_attribute(handle,Node,'OutputFile',_NormalizeFile(value));
}
void _ProjectSet_ConfigType(int handle, _str value,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return;
   }
   _xmlcfg_set_attribute(handle,Node,'Type',_NormalizeFile(value));
}
void _ProjectGet_Rules(int handle,typeless (&array)[], _str RuleName, _str config=gActiveConfigName)
{
   // search first in config container
   int node = _xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_RULES:+XPATH_STRIEQ('Name',RuleName), TREE_ROOT_INDEX);
   if(node < 0) {
      // if not found, search in project container
      node = _xmlcfg_find_simple(handle,VPJX_PROJECT"/"VPJTAG_RULES:+XPATH_STRIEQ('Name',RuleName), TREE_ROOT_INDEX);
   }

   if(node >= 0) {
      _xmlcfg_find_simple_array(handle,VPJTAG_RULE,array,node);
   }
}

/**
 * Finds all the target nodes (build tools).
 *
 * @param handle           handle to project file
 * @param array            array in which to store the targets
 * @param config           configuration to search (send '' to
 *                         look for all configs)
 * @param getNames         true to get the names of the nodes,
 *                         false to get the nodes themselves
 */
void _ProjectGet_Targets(int handle,_str (&array)[],_str config=gActiveConfigName, boolean getNames = false)
{
   flags := 0;
   nameQuery := '';
   if (getNames) {
      flags = VSXMLCFG_FIND_VALUES;
      nameQuery = '/@Name';
   }

   if (config == '') {
      // no config, so search for any old config
      _xmlcfg_find_simple_array(handle, VPJX_CONFIG"/"VPJTAG_MENU:+"//"VPJTAG_TARGET :+ nameQuery, array, TREE_ROOT_INDEX, flags);
   } else {
      // specific config
      _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_MENU:+"//"VPJTAG_TARGET :+ nameQuery,array, TREE_ROOT_INDEX, flags);
   }
}
int _ProjectGet_PreBuildCommandsNode(int handle,_str config=gActiveConfigName)
{
   return(_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS));
}
int _ProjectGet_PostBuildCommandsNode(int handle,_str config=gActiveConfigName)
{
   return(_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS));
}
_str _ProjectGet_PostBuildCommandsList(int handle,_str config=gActiveConfigName)
{
   typeless array[];
   _str list='';
   int i;
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS"/"VPJTAG_EXEC,array);
   list='';
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,"\1");
      }
      strappend(list,_xmlcfg_get_attribute(handle,array[i],'CmdLine'));
   }
   return(list);
}
void _ProjectSet_PostBuildCommandsList(int handle,_str list,_str config=gActiveConfigName)
{
   _str item='';
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS);
   _xmlcfg_delete(handle,Node,(list=='')?false:true);
   for (;;) {
      parse list with item "\1" list;
      if (item=="" && list=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS,VPJTAG_EXEC,'CmdLine',item);
   }
}
_str _ProjectGet_PreBuildCommandsList(int handle,_str config=gActiveConfigName)
{
   typeless array[];
   _str list='';
   int i;
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS"/"VPJTAG_EXEC,array);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,"\1");
      }
      strappend(list,_xmlcfg_get_attribute(handle,array[i],'CmdLine'));
   }
   return(list);
}
void _ProjectSet_PreBuildCommandsList(int handle,_str list,_str config=gActiveConfigName)
{
   _str item='';
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS);
   _xmlcfg_delete(handle,Node,(list=='')?false:true);
   for (;;) {
      parse list with item "\1" list;
      if (item=="" && list=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS,VPJTAG_EXEC,'CmdLine',item);
   }
}
boolean _ProjectGet_StopOnPostBuildError(int handle,_str config=GetCurrentConfigName())
{
   return(_xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS,'StopOnError',0) != 0);
}
void _ProjectSet_StopOnPostBuildError(int handle,int value,_str config=gActiveConfigName)
{
   _xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_POSTBUILDCOMMANDS,'StopOnError',value);
}
boolean _ProjectGet_StopOnPreBuildError(int handle,_str config=GetCurrentConfigName())
{
   return(_xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS,'StopOnError',0) != 0);
}
void _ProjectSet_StopOnPreBuildError(int handle,int value,_str config=gActiveConfigName)
{
   _xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_PREBUILDCOMMANDS,'StopOnError',value);
}

_str _ProjectGet_AppType(int handle,_str config=GetCurrentConfigName())
{
   return(_xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]",'AppType'));
}
int _ProjectSet_AppType(int handle,_str config=GetCurrentConfigName(), _str appType='')
{
   return(_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]",'AppType',appType));
}
_str _ProjectGet_AppTypeList(int handle,_str config=GetCurrentConfigName())
{
   return(_xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]",'AppTypeList'));
}
int _ProjectGet_AppTypeTargets(int handle,_str config,_str Target,boolean forceCreate)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG:+XPATH_STRIEQ('Name',config):+'/'VPJTAG_APPTYPETARGETS:+XPATH_STRIEQ('Name',Target));
   if (Node<0) {
      if (!forceCreate) {
         return(Node);
      }
      Node=_xmlcfg_set_path2(handle,VPJX_CONFIG:+XPATH_STRIEQ('Name',config),VPJTAG_APPTYPETARGETS,'Name',Target);
   }
   return(Node);

}
int _ProjectGet_AppTypeTargetNode(int handle,_str Target,_str AppType,_str config=GetCurrentConfigName())
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_APPTYPETARGETS:+XPATH_STRIEQ('Name',Target):+"/"VPJTAG_APPTYPETARGET:+
                              XPATH_STRIEQ('AppType',AppType)
                            );
   if (Node>=0) {
      return(Node);
   }
   _str ConfigAppType=_ProjectGet_AppType(handle,config);
   int TargetNode;
   if (strieq(ConfigAppType,AppType)) {
      Node=_ProjectGet_TargetNode(handle,Target,config);
   }
   return(Node);
}

/**
 * Locates the target node with the given name.  A target is a
 * project-specific build tool.
 *
 * @param handle           handle to project file
 * @param Target           target name
 * @param config           configuration to search.  To use the
 *                         current configuration, do not send
 *                         this argument.  To find a target in
 *                         any configuration, send an empty
 *                         string.
 *
 * @return int             target node, -1 if not found
 *
 * @categories Project_Functions
 */
int _ProjectGet_TargetNode(int handle,_str Target,_str config=GetCurrentConfigName())
{
   targetSection := VPJTAG_TARGET"[strieq(@Name,'"Target"')]";
   // if there is an apostrophe, then we need to use double quotes
   if (pos("'", Target) > 0) {
      targetSection = VPJTAG_TARGET'[strieq(@Name,"'Target'")]';
   }

   configSection := VPJX_CONFIG;
   if (config != '') {
      // check for apostrophe
      if (pos("'", config) > 0) {
         configSection = VPJX_CONFIG'[strieq(@Name,"'config'")]';
      } else {
         configSection = VPJX_CONFIG"[strieq(@Name,'"config"')]";
      }
   }
   // now that we've got it all set up, find the right node
   return(_xmlcfg_find_simple(handle,configSection"/"VPJTAG_MENU"/"targetSection));
}

int _ProjectGet_RuleNode(int handle,_str ruleName, _str inputExts,_str config=GetCurrentConfigName())
{
   // search first in config container
   int node = _xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_RULES:+XPATH_STRIEQ('Name',ruleName)"/"VPJTAG_RULE:+XPATH_STRIEQ("InputExts", inputExts), TREE_ROOT_INDEX);
   if(node < 0) {
      // if not found, search in project container
      node = _xmlcfg_find_simple(handle,VPJX_PROJECT"/"VPJTAG_RULES:+XPATH_STRIEQ('Name',ruleName)"/"VPJTAG_RULE:+XPATH_STRIEQ("InputExts", inputExts), TREE_ROOT_INDEX);
   }

   return node;
}

_str _ProjectGet_TargetCmdLine(int handle,int Node,boolean replaceOtherOpts=false)
{
   if (Node<0) {
      return('');
   }
   Node=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
   if (Node<0) {
      return('');
   }
   _str cmdline = _xmlcfg_get_attribute(handle,Node,'CmdLine');

   if(replaceOtherOpts) {
      // check for %~other placeholder
      int offset = pos('(^|[~%])\%\~other',cmdline,1,'r');
      if(offset > 0) {
         // placeholder found so replace it
         _str newcmdline = "";
         if(offset > 1) {
            newcmdline = substr(cmdline,1,offset);
            offset++;
         }
         newcmdline = newcmdline :+ _xmlcfg_get_attribute(handle,Node,'OtherOptions') :+ substr(cmdline, offset + 7);
         cmdline = newcmdline;
      }
   }

   return cmdline;
}

// gets all CallTarget and Set nodes
void _ProjectGet_TargetAdvCmd(int handle,int Node,_str (&cmds)[])
{
   if (Node<0) {
      return;
   }

   cmds._makeempty();

   Node=_xmlcfg_get_first_child(handle,Node);

   while (Node>=0) {
      switch (_xmlcfg_get_name(handle,Node)) {
      case VPJTAG_CALLTARGET:
         {
            _str config=_xmlcfg_get_attribute(handle,Node,'Config');
            _str target=_xmlcfg_get_attribute(handle,Node,'Target');
   
            int cmd_index=cmds._length();
   
            if (config:!='') {
               cmds[cmd_index]='run_tool Config='config' Tool='target;
            } else {
               cmds[cmd_index]='run_tool Tool='target;
            }

            break;
         }
      case VPJTAG_SET:
         {
            _str name=_xmlcfg_get_attribute(handle,Node,'Name');
            _str value=_xmlcfg_get_attribute(handle,Node,'Value');
   
            int cmd_index=cmds._length();
   
            cmds[cmd_index]='Set 'name'='value;
   
            break;
         }
      }

      Node=_xmlcfg_get_next_sibling(handle,Node);
   }
}

_str _ProjectGet_TargetName(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'Name'));
}
_str _ProjectGet_TargetType(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   Node=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'Type'));
}
_str _ProjectGet_TargetDependsRef(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'DependsRef'));
}
void _ProjectSet_TargetDependsRef(int handle,int Node,_str dependsRef)
{
   if (Node<0) {
      return;
   }
   if(dependsRef == "") {
      _xmlcfg_delete_attribute(handle, Node, "DependsRef");
   } else {
      _xmlcfg_set_attribute(handle, Node, "DependsRef", dependsRef);
   }
}
_str _ProjectGet_TargetOtherOptions(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   Node=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'OtherOptions'));
}

_str _ProjectGet_TargetAppletClass(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'AppletClass'));
}
void _ProjectSet_TargetAppletClass(int handle,int Node,_str value)
{
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'AppletClass');
   } else {
      _xmlcfg_set_attribute(handle,Node,'AppletClass',value);
   }
}
_str _ProjectGet_TargetPreMacro(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'PreMacro'));
}
void _ProjectSet_TargetPreMacro(int handle,int Node,_str preMacro, _str attribName = 'PreMacro')
{
   if (Node<0) {
      return;
   }
   if(preMacro == '') {
      _xmlcfg_delete_attribute(handle, Node, attribName);
   } else {
      _xmlcfg_set_attribute(handle, Node, attribName, preMacro);
   }
}
_str _ProjectGet_TargetPostMacro(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'PostMacro'));
}
void _ProjectSet_TargetPostMacro(int handle,int Node,_str postMacro,)
{
   _ProjectSet_TargetPreMacro(handle, Node, postMacro, 'PostMacro');
}
_str _ProjectGet_TargetSaveOption(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'SaveOption',VPJ_SAVEOPTION_SAVENONE));
}
void _ProjectSet_TargetSaveOption(int handle,int Node,_str value)
{
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'SaveOption');
   } else {
      _xmlcfg_set_attribute(handle,Node,'SaveOption',value);
   }
}
_str _ProjectGet_TargetShowOnMenu(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'ShowOnMenu',VPJ_SHOWONMENU_ALWAYS));
}
void _ProjectSet_TargetShowOnMenu(int handle,int Node,_str value)
{
   if (Node<0) {
      return;
   }
   if (strieq(value,VPJ_SHOWONMENU_ALWAYS)) {
      _xmlcfg_delete_attribute(handle,Node,'ShowOnMenu');
   } else {
      _xmlcfg_set_attribute(handle,Node,'ShowOnMenu',value);
   }
}
_str _ProjectGet_TargetDialog(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'Dialog'));
}
void _ProjectSet_TargetDialog(int handle,int Node,_str Dialog)
{
   if (Node<0) {
      return;
   }
   if (Dialog=='') {
      _xmlcfg_delete_attribute(handle,Node,'Dialog');
   } else {
      _xmlcfg_set_attribute(handle,Node,'Dialog',Dialog);
   }
}
_str _ProjectGet_TargetInputExts(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'InputExts'));
}
void _ProjectSet_TargetInputExts(int handle, int Node, _str inputExts)
{
   if (Node<0) {
      return;
   }
   _xmlcfg_set_attribute(handle, Node, "InputExts", inputExts);
}
_str _ProjectGet_TargetMenuCaption(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'MenuCaption'));
}
_str _ProjectGet_TargetCaptureOutputWith(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'CaptureOutputWith'));
}
void _ProjectSet_TargetCaptureOutputWith(int handle,int Node,_str CaptureOutputWith)
{
   if (Node<0) {
      return;
   }
   if (CaptureOutputWith=='') {
      _xmlcfg_delete_attribute(handle,Node,'CaptureOutputWith');
   } else {
      _xmlcfg_set_attribute(handle,Node,'CaptureOutputWith',CaptureOutputWith);
   }
}
void _ProjectSet_TargetMenuCaption(int handle,int Node,_str MenuCaption)
{
   if (Node<0) {
      return;
   }
   if(MenuCaption == '') {
      _xmlcfg_delete_attribute(handle,Node,'MenuCaption');
   } else {
      _xmlcfg_set_attribute(handle,Node,'MenuCaption',MenuCaption);
   }
}
boolean _ProjectGet_TargetBeep(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return (_xmlcfg_get_attribute(handle,Node,'Beep',0) != 0);
}
boolean _ProjectGet_TargetNoPassthru(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return (_xmlcfg_get_attribute(handle,Node,'NoVSBUILD',0) != 0);
}

void _ProjectSet_TargetBeep(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (!value) {
      _xmlcfg_delete_attribute(handle,Node,'Beep');
   } else {
      _xmlcfg_set_attribute(handle,Node,'Beep',value);
   }
}
boolean _ProjectGet_TargetVerbose(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return(_xmlcfg_get_attribute(handle,Node,'Verbose',0) != 0);
}
void _ProjectSet_TargetVerbose(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (!value) {
      _xmlcfg_delete_attribute(handle,Node,'Verbose');
   } else {
      _xmlcfg_set_attribute(handle,Node,'Verbose',value);
   }
}
boolean _ProjectGet_TargetClearProcessBuffer(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return(_xmlcfg_get_attribute(handle,Node,'ClearProcessBuffer',0) != 0);
}
void _ProjectSet_TargetClearProcessBuffer(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (value==0) {
      _xmlcfg_delete_attribute(handle,Node,'ClearProcessBuffer');
   } else {
      _xmlcfg_set_attribute(handle,Node,'ClearProcessBuffer',value);
   }
}
boolean _ProjectGet_TargetBuildFirst(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return(_xmlcfg_get_attribute(handle,Node,'BuildFirst',0) != 0);
}
boolean _ProjectGet_TargetEnableBuildFirst(int handle,int Node)
{
   if (Node<0) {
      return(1);
   }
   _str Name=_xmlcfg_get_attribute(handle,Node,'Name');
   if (strieq(Name,'compile') ||
       strieq(Name,'build') ||
       strieq(Name,'rebuild')
       ) {
      return(0);
   }
   return(_xmlcfg_get_attribute(handle,Node,'EnableBuildFirst',1) != 0);
}
void _ProjectSet_TargetBuildFirst(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (!value) {
      _xmlcfg_delete_attribute(handle,Node,'BuildFirst');
   } else {
      _xmlcfg_set_attribute(handle,Node,'BuildFirst',value);
   }
}

/**
 * This has been deprecated.  Use _ProjectGet_TargetRunFromDir
 */
boolean _ProjectGet_TargetChangeDir(int handle,int Node)
{
   if (Node<0) {
      return(1);
   }
   return(_xmlcfg_get_attribute(handle,Node,'ChangeDir',1) != 0);
}
/**
 * This has been deprecated.  Use _ProjectSet_TargetRunFromDir
 */
void _ProjectSet_TargetChangeDir(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (value) {
      _xmlcfg_delete_attribute(handle,Node,'ChangeDir');
   } else {
      _xmlcfg_set_attribute(handle,Node,'ChangeDir',value);
   }
}

_str _ProjectGet_TargetRunFromDir(int handle,int Node)
{
   if (Node<0) {
      return("");
   }
   return(_xmlcfg_get_attribute(handle,Node,'RunFromDir',''));
}
void _ProjectSet_TargetRunFromDir(int handle,int Node,_str value)
{
   if (Node<0) {
      return;
   }
   if (value == "") {
      _xmlcfg_delete_attribute(handle,Node,'RunFromDir');
   } else {
      _xmlcfg_set_attribute(handle,Node,'RunFromDir',value);
   }
}
boolean _ProjectGet_TargetDeletable(int handle,int Node)
{
   if (Node<0) {
      return(1);
   }
   return(_xmlcfg_get_attribute(handle,Node,'Deletable',1) != 0);
}
boolean _ProjectGet_TargetRunInXterm(int handle,int Node)
{
   if (Node<0) {
      return(0);
   }
   return(_xmlcfg_get_attribute(handle,Node,'RunInXterm',0) != 0);
}
void _ProjectSet_TargetRunInXterm(int handle,int Node,boolean value)
{
   if (Node<0) {
      return;
   }
   if (!value) {
      _xmlcfg_delete_attribute(handle,Node,'RunInXterm');
   } else {
      _xmlcfg_set_attribute(handle,Node,'RunInXterm',value);
   }
}

_str _ProjectGet_TargetOutputExts(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'OutputExts'));
}
_str _ProjectGet_TargetLinkObject(int handle,int Node)
{
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'LinkObject'));
}
void _ProjectSet_TargetType(int handle,int Node,_str value)
{
   if (Node<0) {
      return;
   }
   int ExecNode=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
   if (ExecNode<0) {
      ExecNode=_xmlcfg_add(handle,Node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,ExecNode,'Type');
   } else {
      _xmlcfg_set_attribute(handle,ExecNode,'Type',value);
   }
}
void _ProjectSet_TargetCmdLine(int handle,int Node,_str CmdLine=null,_str Type=null,_str OtherOptions=null)
{
   if (Node<0) {
      return;
   }
   int ExecNode=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
   if (ExecNode<0) {
      ExecNode=_xmlcfg_add(handle,Node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   }
   if (CmdLine!=null) {
      _xmlcfg_set_attribute(handle,ExecNode,'CmdLine',CmdLine);
   }
   if (Type!=null) {
      if (Type=='') {
         _xmlcfg_delete_attribute(handle,ExecNode,'Type');
      } else {
         _xmlcfg_set_attribute(handle,ExecNode,'Type',Type);
      }
   }
   if (OtherOptions!=null) {
      if (OtherOptions=='') {
         _xmlcfg_delete_attribute(handle,ExecNode,'OtherOptions');
      } else {
         _xmlcfg_set_attribute(handle,ExecNode,'OtherOptions',OtherOptions);
      }
   }
}

static int add_advanced_command_node(_str node_type,int handle,int config_node)
{
   int node=_xmlcfg_get_first_child(handle,config_node);
   if (node<0) {
      return _xmlcfg_add(handle,config_node,node_type,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   }
   return _xmlcfg_add(handle,node,node_type,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_BEFORE);
}

void _ProjectSet_TargetAdvCmd(int handle,int Node,_str (&cmds)[])
{
   if (Node<0) {
      return;
   }

   // save a copy
   int config_node=Node;

   // first remove all existing advanced commands
   int nodes[];
   Node=_xmlcfg_get_first_child(handle,Node);

   while (Node>=0) {
      switch (_xmlcfg_get_name(handle,Node)) {
      case VPJTAG_CALLTARGET:
      case VPJTAG_SET:
         {
            nodes[nodes._length()]=Node;
         }
      }

      Node=_xmlcfg_get_next_sibling(handle,Node);
   }

   int node_index;
   for (node_index=0;node_index<nodes._length();++node_index) {
      _xmlcfg_delete(handle,nodes[node_index]);
   }

   // now add the new commands
   int cmd_index=cmds._length()-1;
   _str full_cmd;
   _str cmd_type;
   _str options;
   while (cmd_index>=0) {
      full_cmd=cmds[cmd_index];

      parse full_cmd with cmd_type ' ' options;

      if (strieq(cmd_type,'run_tool')) {
         _str config;
         _str tool;

         parse options with 'config=','I' config ' ' .;
         parse options with 'tool=','I' tool ' ' .;

         Node=add_advanced_command_node(VPJTAG_CALLTARGET,handle,config_node);
         if (Node>=0) {
            if (config:!='') {
               _xmlcfg_set_attribute(handle,Node,'Config',config);
            }
            _xmlcfg_set_attribute(handle,Node,'Target',tool);
         }
      } else if (strieq(cmd_type,'set')) {
         _str name;
         _str value;

         parse options with name'='value;

         Node=add_advanced_command_node(VPJTAG_SET,handle,config_node);
         if (Node>=0) {
            _xmlcfg_set_attribute(handle,Node,'Name',strip(name));
            _xmlcfg_set_attribute(handle,Node,'Value',strip(value));
         }
      }

      --cmd_index;
   }
}

int _ProjectTemplatesGet_TemplateNode(int handle,_str TemplateName,boolean forceCreate=false)
{
   int Node=_xmlcfg_find_simple(handle,VPTX_TEMPLATE"[strieq(@Name,'"TemplateName"')]");
   if (forceCreate && Node<0) {
      Node=_xmlcfg_set_path2(handle,VPTX_TEMPLATES,VPTTAG_TEMPLATE,'Name',TemplateName);
   }
   return(Node);
}
int _ProjectTemplatesGet_TemplateConfigNode(int handle,int TemplateNode,_str config)
{
   return(_xmlcfg_find_simple(handle,VPJTAG_CONFIG:+XPATH_STRIEQ("Name",config),TemplateNode));
}
void _ProjectTemplatesGet_TemplateNodes(int handle,typeless (&array)[])
{
   _xmlcfg_find_simple_array(handle,VPTX_TEMPLATE,array);
}
int _ProjectGet_ConfigNode(int handle,_str config, boolean CreateIfDoesNotExist=false)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0 && CreateIfDoesNotExist) {
      Node=_xmlcfg_set_path2(handle,VPJX_PROJECT,VPJTAG_CONFIG,'Name',config);
   }
   return(Node);
}
void _ProjectGet_ActiveConfigOrExt(_str ProjectName,int &handle,_str &config)
{
   if (ProjectName=='') {
      handle=gProjectExtHandle;
      config='.'_mdi.p_child.p_LangId;
   } else {
      handle=_ProjectHandle(ProjectName);
      config=GetCurrentConfigName(ProjectName);
   }
}
_str _ProjectGet_ActiveType()
{
   int handle = _ProjectHandle();
   _str config = '';
   if (handle) {
      _ProjectGet_ActiveConfigOrExt(_project_name, handle, config);
      return(_ProjectGet_Type(handle,config));
   }
   return '';
}

_str _ProjectGet_TemplateName(int handle)
{
   if (handle >= 0) {
      return _xmlcfg_get_path(handle,VPJX_PROJECT,'TemplateName');
   }

   return '';
}

boolean _ProjectGet_IsCustomizedProjectType(int handle)
{
   if (handle >= 0) {
      return (_xmlcfg_get_path(handle,VPJX_PROJECT,'Customized') == "1");
   }

   return false;
}

_str _ProjectGet_ObjectDir(int handle,_str config)
{
   int Node=_ProjectGet_ConfigNode(handle,config);
   if (Node<0) {
      return('');
   }
   return(translate(_xmlcfg_get_attribute(handle,Node,'ObjectDir'),FILESEP,FILESEP2));
}
void _ProjectSet_ObjectDir(int handle,_str value,_str config)
{
   int Node=_ProjectGet_ConfigNode(handle,config);
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'ObjectDir');
   } else {
      _xmlcfg_set_attribute(handle,Node,'ObjectDir',_NormalizeFile(value));
   }
}
int _ProjectGet_FirstTarget(int handle,_str config)
{
   return(_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_MENU"/"VPJTAG_TARGET));
}
int _ProjectGet_NextTarget(int handle,int TargetNode)
{
   return(_xmlcfg_get_next_sibling(handle,TargetNode));
}
_str _ProjectGet_AssociatedFileType(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,'AssociatedFileType'));
}
_str _ProjectGet_AssociatedFile(int handle)
{
   return(translate(_xmlcfg_get_path(handle,VPJX_PROJECT,'AssociatedFile'),FILESEP,FILESEP2));
}
void _ProjectSet_AssociatedFile(int handle,_str AssociatedFile)
{
   int Node=_xmlcfg_set_path(handle,VPJX_PROJECT,'AssociatedFile',_NormalizeFile(AssociatedFile));
   if (AssociatedFile=='') {
      _xmlcfg_delete_attribute(handle,Node,'AssociatedFile');
   }
}
void _ProjectSet_AssociatedFileType(int handle,_str AssociatedFileType)
{
   int Node=_xmlcfg_set_path(handle,VPJX_PROJECT,'AssociatedFileType',AssociatedFileType);
   if (AssociatedFileType=='') {
      _xmlcfg_delete_attribute(handle,Node,'AssociatedFileType');
   }
}
void _ProjectGet_FileNamesInsert(int project_handle, _str ConfigName="")
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(project_handle,xmlv);

   int append_after_ln=p_line;
   if (ConfigName=="") {
      _xmlcfg_find_simple_insert(project_handle, xmlv.vpjx_files "//" xmlv.vpjtag_f "/@" xmlv.vpjattr_n);
   } else {
      _xmlcfg_find_simple_insert(project_handle, xmlv.vpjx_files "//" xmlv.vpjtag_f "[not(@C)]/@" xmlv.vpjattr_n);
      if (ConfigName!=ALL_CONFIGS) {
         _xmlcfg_find_simple_insert(project_handle, xmlv.vpjx_files "//" xmlv.vpjtag_f XPATH_CONTAINS('C',always_quote_filename(ConfigName),'i') "/@" xmlv.vpjattr_n);
      }
   }
   //_xmlcfg_find_simple_insert(project_handle,VPJX_FILES"//"VPJTAG_F"/@N");
   p_line=append_after_ln;_end_line();
   search(FILESEP2,'@h',FILESEP);bottom();
}
int _ProjectGet_FilesNode(int handle,boolean forceCreate=false)
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);
   if (forceCreate) {
      return(_xmlcfg_set_path(handle,xmlv.vpjx_files));
   }
   return(_xmlcfg_find_simple(handle,xmlv.vpjx_files));
}
void _cbsave_project()
{
   if (file_eq(_get_extension(p_buf_name,true),PRJ_FILE_EXT) && _workspace_filename!='') {
      if (!_xmlcfg_buffer_is_valid()) return;
      _ProjectCache_Update(p_buf_name);
      toolbarUpdateFilterList(p_buf_name);
      call_list('_prjupdate_');
   } else if (_workspace_filename!='' && file_eq(p_buf_name,_workspace_filename)) {
      if (!_xmlcfg_buffer_is_valid()) return;
      _WorkspaceCache_Update();
      toolbarUpdateWorkspaceList();
   }
}
int _ProjectSave(int handle,_str error_msg='',_str filename=null)
{
   boolean is_vcproj=false;
   boolean is_jbuilder=false;
   boolean is_flash=false;
   _str ext=_get_extension(_xmlcfg_get_filename(handle),true);
   is_vcproj=file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT);
   is_jbuilder=file_eq(ext,JBUILDER_PROJECT_EXT);
   is_flash=file_eq(ext,MACROMEDIA_FLASH_PROJECT_EXT);
   _str ProjectName=_xmlcfg_get_filename(handle);
   if(ProjectName=='') return(0);
   vc_make_file_writable(ProjectName);
   _clearProjectFileListCache(_workspace_filename, ProjectName);

   int status = 0;
   if (is_vcproj) {
      status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_DOS_EOL|VSXMLCFG_SAVE_ESCAPE_NL_ON_ATTR_VALUE);
   } else if(is_jbuilder) {
      // convert the modified xml back to jbuilder format
      _convertJBuilderXML(handle, false);
      status=_xmlcfg_save(handle, 2, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   } else if (is_flash) {
      status = _xmlcfg_save(handle, 4, VSXMLCFG_SAVE_ALL_ON_ONE_LINE);
   } else {
      int indent=-1;
      if (LanguageSettings.getIndentWithTabs('vpj')) {
         indent= -1;  // Save XML using tabs.
      } else {
         indent = LanguageSettings.getSyntaxIndent('vpj');
      }
      //say('indent='indent);
      status=_xmlcfg_save(handle,indent,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR,filename);
   }
   if (status) {
      if (error_msg=='') {
         error_msg=nls("Failed to save project file '%s'\n\n",ProjectName);
      }
      _message_box(error_msg:+get_message(status)"\n\nMake sure the file can be written to.");
   }
   if (_workspace_filename!='') {
      int Node=_WorkspaceGet_ProjectNode(gWorkspaceHandle,_RelativeToWorkspace(ProjectName));
      if (Node>=0 || is_vcproj) {
         p_window_id._WorkspacePutProjectDate(ProjectName);
      }
   }
   return(status);
}
int _ProjectTemplatesSave(int handle,_str error_msg='', boolean quiet = false)
{
   _str ProjectName=_xmlcfg_get_filename(handle);
   if(ProjectName=='') return(0);
   int status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR);
   if (status && !quiet) {
      if (error_msg=='') {
         error_msg=nls("Failed to save project templates to '%s'\n\n",ProjectName);
      }
      _message_box(error_msg:+get_message(status)"\n\nMake sure the file can be written to.");
   }
   return(status);
}
/**
 *
 * @param createdInMemory
 *               Set to true if the file was actually created in memory
 *
 * @return If successful returns handle>=0 to XMLCFG file
 */
int _ProjectOpenUserTemplates(boolean &createdInMemory=false)
{
   createdInMemory=false;
   _str user_file=usercfg_path_search(VSCFGFILE_USER_PRJTEMPLATES);
   _str old_user_file='';
   int status=0;
   int handle=_xmlcfg_open(absolute(user_file),status);
   if (handle<0) {
      if (!file_exists(user_file)) {
         user_file=_ConfigPath():+VSCFGFILE_USER_PRJTEMPLATES;
         old_user_file=usercfg_path_search('usrpacks.slk');
         if (_ini_is_valid(old_user_file)) {
            copy_file(old_user_file,user_file);
            _ProjectConvert70ToXML(user_file,false,true);
            handle=_xmlcfg_open(user_file,status);
         }
      }
      if (handle<0) {
         handle=_ProjectCreateUserTemplates(user_file);
         createdInMemory=true;
      }
   }
   if (!strieq(_xmlcfg_get_path(handle,VPTX_TEMPLATES,"VendorName"),'SlickEdit')) {
      _message_box(nls("Template file '%s' is not recognized as valid.  VendorName attribute not set to SlickEdit",user_file));
      return(-1);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION81) {
      _ProjectTemplatesConvert81To90(absolute(user_file),handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION90) {
      _ProjectTemplatesConvert90To91(absolute(user_file),handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION91) {
      _ProjectTemplatesConvert91To100(absolute(user_file),handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")!=VPT_FILE_VERSION) {
      _message_box(nls("Template file '%s' is not recognized as valid.  Incorect version",user_file));
      return(-1);
   }
   return(handle);
}
/**
 *
 * @return If successful returns handle>=0 to XMLCFG file
 */
int _ProjectOpenTemplates()
{
   _str prjtemplates_file=get_env("VSROOT"):+VSCFGFILE_PRJTEMPLATES;
   int status=0;
   int handle=_xmlcfg_open(prjtemplates_file,status);
   if (handle<0) {
      if (!file_exists(prjtemplates_file)) {
         _message_box(nls("Project template file '%s' not found",prjtemplates_file));
         return(FILE_NOT_FOUND_RC);
      }
      _message_box(nls("Failed to open project template file '%s'.\n\n"get_message(handle),prjtemplates_file));
      return(handle);
   }
   if (!strieq(_xmlcfg_get_path(handle,VPTX_TEMPLATES,"VendorName"),'SlickEdit')) {
      _message_box(nls("Template file '%s' is not recognized as valid.  VendorName attribute not set to SlickEdit",prjtemplates_file));
      return(-1);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION81) {
      _ProjectTemplatesConvert81To90(prjtemplates_file,handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION90) {
      _ProjectTemplatesConvert90To91(prjtemplates_file,handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")==VPT_FILE_VERSION91) {
      _ProjectTemplatesConvert91To100(prjtemplates_file,handle);
   }
   if (_xmlcfg_get_path(handle,VPTX_TEMPLATES,"Version")!=VPT_FILE_VERSION) {
      _message_box(nls("Template file '%s' is not recognized as valid.  Incorrect version",prjtemplates_file));
      _xmlcfg_close(handle);
      return(-1);
   }
   OverlayOEMTemplates(handle);
   return(handle);
}

/**
 * Overlay entries from the oem.vpt file on top of the system file
 * 
 * @param handle of xml file to overlay
 * 
 * @return 0 if successful
 */
static int OverlayOEMTemplates(int project_template_handle)
{
   if ( project_template_handle<0 ) {
      // If the handle is invalid, it is probably an error code
      return(project_template_handle);
   }
   int status=0;
   _str oemtemplates_file=get_env("VSROOT"):+VSCFGFILE_OEMTEMPLATES;
   int oem_template_handle=_xmlcfg_open(oemtemplates_file,status);
   if (oem_template_handle<0) {
      if (!file_exists(oemtemplates_file)) {
         // Keep this quiet. If the file isn't there, it is probably just a full
         // version
         return(FILE_NOT_FOUND_RC);
      }
      _message_box(nls("Failed to open oem project template file '%s'.\n\n",oemtemplates_file));
      return(oem_template_handle);
   }
   _str attrs_to_match[];
   attrs_to_match[0]='Name';
   attrs_to_match[1]='Platforms';
   status=OverlayXMLFile(project_template_handle,oem_template_handle,'Templates/Template',attrs_to_match);
   return(status);
}

/**
 * Overlay an open xml file with the contents of another.  Specify the xpath path
 * for the "search level", and the attributes that must be matched to overlay.
 * 
 * If an item does not already exist, it will be added
 * @param dest_handle handle to overlay into
 * @param src_handle handle to copy from
 * @param overlay_src_path Level to replace at, for example 'Templates/Template',
 *        will compare those items, and only replace thos
 * @param attrs_to_match Names of attributes that must match for an overlay to occur
 */
static int OverlayXMLFile(int dest_handle,int src_handle,_str overlay_src_path,
                          _str (&attrs_to_match)[])
{
   if ( !attrs_to_match._length() ) {
      return(1);
   }

   // Find the items to overlay in the dest file
   typeless src_index_array[];
   int status=_xmlcfg_find_simple_array(src_handle,overlay_src_path,src_index_array);
   if ( status ) {
      return(status);
   }
   // Find the items that could be overlayed in the dest file.  We only do this
   // so that we know what the "last" item is
   int last_dest_node_index=-1;
   typeless dest_index_array[];
   status=_xmlcfg_find_simple_array(dest_handle,overlay_src_path,dest_index_array);
   if ( status ) {
      return(status);
   }
   last_dest_node_index=dest_index_array[dest_index_array._length()-1];

   int src_index_array_len=src_index_array._length();
   int i;
   for (i=0;i<src_index_array_len;++i) {
      // Build the a match string for this node, including the attributes
      _str attr_match_str=BuildAttrMatchStr(attrs_to_match,src_handle,src_index_array[i]);
      _str dest_match_path=overlay_src_path:+attr_match_str;

      int dest_index=_xmlcfg_find_simple(dest_handle,dest_match_path);
      if ( dest_index>=0 ) {
         // Found a match to overlay
         int new_index=_xmlcfg_copy(dest_handle,dest_index,src_handle,src_index_array[i],0);
         if ( new_index>=0 ) {
            status=_xmlcfg_delete(dest_handle,dest_index);
         }
      }else{
         // Just copy this as a sibling of the last thing in the file
         int new_index=_xmlcfg_copy(dest_handle,last_dest_node_index,src_handle,src_index_array[i],0);
         // Set this new index to be tha last index now
         last_dest_node_index=new_index;
      }
   }
   return(0);
}

/**
 * Builds a match string for this node's attributes (xpath style)
 * @param attrs_to_match array of attribute names to match
 * @param xml_handle handle of xml file that the node is in
 * @param xml_node_index index to the node
 */
static _str BuildAttrMatchStr(_str (&attrs_to_match)[],int xml_handle,int xml_node_index)
{
   int i;
   _str attr_match_str='';
   int attrs_to_match_length=attrs_to_match._length();

   // For each attr in the list, add a [@<attr>='<attrval>'], so we can search
   // for this in the destfile
   for (i=0;i<attrs_to_match_length;++i) {
      _str attr_value=_xmlcfg_get_attribute(xml_handle,xml_node_index,attrs_to_match[i]);
      if (attrs_to_match[i]!="Platforms" || attr_value!="") {
         attr_match_str=attr_match_str:+"[@"attrs_to_match[i]"='"attr_value"']";
      }
   }
   return(attr_match_str);
}

int _ProjectOpen(_str ProjectName)
{
   int status=0;
   int handle=_ProjectHandle(ProjectName,status);
   if (status) return(status);

   // get the config name for the project that is being opened
   // NOTE: this must be done *before* the _project_name global
   //       variable is set because GetCurrentConfigName() will
   //       only reset the gActiveConfigName global variable if
   //       ProjectName != _project_name
   gActiveConfigName=GetCurrentConfigName(ProjectName);

   // set the global project name
   _project_name=ProjectName;
   call_list('_prjconfig_');  // Active config changed
   return(0);
}
int _ProjectCopy_Config(int dest_handle,int src_handle,int Node)
{
   int array[];
   _ProjectGet_Configs(dest_handle,array);
   if (array._length()) {
      Node=_xmlcfg_copy(dest_handle,array[array._length()-1],src_handle,Node,0);
   } else {
      int DestNode=_xmlcfg_set_path(dest_handle,VPJX_PROJECT);
      Node=_xmlcfg_copy(dest_handle,DestNode,src_handle,Node,VSXMLCFG_COPY_AS_CHILD);
   }
   return(Node);
}

void _ProjectAdd_DefaultFolders(int handle)
{
   int i;
   int Node=_xmlcfg_set_path(handle,VPJX_FILES);
   _xmlcfg_delete(handle,Node,true);
   for (i=0;i<NewFolderInfo._length();++i) {
      Node=_xmlcfg_set_path2(handle,VPJX_FILES,VPJTAG_FOLDER,"Name",NewFolderInfo[i].FolderName);
      _xmlcfg_set_attribute(handle,Node,"Filters",NewFolderInfo[i].Filters);
   }

}
void _ProjectSetAppType(int handle,_str NewAppType,_str config='')
{
   int i=0,j=0;
   typeless ConfigNodeList[];
   if (config=='') {
      _xmlcfg_find_simple_array(handle,VPJX_CONFIG,ConfigNodeList);
   } else {
      ConfigNodeList[0]=_xmlcfg_find_simple(handle,VPJX_CONFIG:+XPATH_STRIEQ('Name',config));
   }
   //say('count='ConfigNodeList._length()'*********************************');
   _str OldAppType='';
   typeless NewAppTypeNodes;
   for (i=0;i<ConfigNodeList._length();++i) {
      //say('N='_xmlcfg_get_attribute(handle,ConfigNodeList[i],'Name'));
       OldAppType=_xmlcfg_get_attribute(handle,ConfigNodeList[i],'AppType');
       if (strieq(OldAppType,NewAppType) || OldAppType=='') {
          continue;
       }

       _xmlcfg_find_simple_array(handle,VPJTAG_APPTYPETARGETS:+"/":+VPJTAG_APPTYPETARGET:+XPATH_STRIEQ('AppType',NewAppType),NewAppTypeNodes,ConfigNodeList[i]);
       //say('len='NewAppTypeNodes._length()' N='NewAppType);
       for (j=0;j<NewAppTypeNodes._length();++j) {
          _str Name=_xmlcfg_get_attribute(handle,_xmlcfg_get_parent(handle,NewAppTypeNodes[j]),"Name");
          if (Name!='') {
             int Node=_xmlcfg_find_simple(handle,"//"VPJTAG_TARGET:+XPATH_STRIEQ('Name',Name),ConfigNodeList[i]);
             //say('orig n='Node' n='_xmlcfg_get_attribute(handle,ConfigNodeList[i],'Name'));
             if (Node>=0) {
                int NewNode=_xmlcfg_copy(handle,Node,handle,NewAppTypeNodes[j],0);
                _xmlcfg_delete_attribute(handle,NewNode,"AppType");
                _xmlcfg_set_attribute(handle,NewNode,'Name',Name);
                _xmlcfg_set_name(handle,NewNode,VPJTAG_TARGET);

                int NewAppTypeTargetNode=_xmlcfg_copy(handle,NewAppTypeNodes[j],handle,Node,0);
                _xmlcfg_set_attribute(handle,NewAppTypeTargetNode,'AppType',OldAppType);
                _xmlcfg_delete_attribute(handle,NewAppTypeTargetNode,'Name');
                _xmlcfg_set_name(handle,NewAppTypeTargetNode,VPJTAG_APPTYPETARGET);

                _xmlcfg_delete(handle,Node);
                _xmlcfg_delete(handle,NewAppTypeNodes[j]);
             }
          }
       }
       _xmlcfg_set_attribute(handle,ConfigNodeList[i],'AppType',NewAppType);
   }
}
void _ProjectSet_DependencyProjectsList(int handle,_str deplist)
{
   int OldNode=_xmlcfg_find_simple(handle,VPJX_DEPENDENCIES_DEPRECATED);
   if (OldNode>=0) {
      _xmlcfg_set_name(handle,OldNode,'old');
   }
   //Node=_xmlcfg_set_path(handle,VPJX_DEPENDENCIES);
   for (;;) {
      _str Project=parse_file(deplist,false);
      if (Project=='') {
         break;
      }
      Project=_AbsoluteToWorkspace(translate(Project,'/','\'),_workspace_filename);
      Project=_RelativeToProject(Project,_xmlcfg_get_filename(handle));
      if (OldNode>=0) {
         int SrcNode=_xmlcfg_find_simple(handle,VPJTAG_DEPENDENCIES'/'VPJTAG_DEPENDENCY'[file-eq(@Project,"'Project'")]',OldNode);
         if (SrcNode>=0) {
            _xmlcfg_copy(handle,OldNode,handle,SrcNode,VSXMLCFG_COPY_AS_CHILD);
            continue;
         }
      }
      _xmlcfg_set_path2(handle,VPJX_DEPENDENCIES_DEPRECATED,VPJTAG_DEPENDENCY,'Project',_NormalizeFile(Project));
   }

   int Node=_xmlcfg_find_simple(handle,VPJX_DEPENDENCIES_DEPRECATED);
   if (Node>=0) {
      _xmlcfg_set_attribute(handle,Node,'Name','Build');
      _xmlcfg_sort_on_attribute(handle,Node,'Project','2');
   }

   if(OldNode >= 0) {
      _xmlcfg_delete(handle,OldNode);
   }
}

void _ProjectGet_Includes(int handle,_str (&array)[],_str config=gActiveConfigName)
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_INCLUDES'/'VPJTAG_INCLUDE'/@Dir',array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<array._length();++i) {
      array[i]=translate(array[i],FILESEP,FILESEP2);
   }
}
_str _ProjectGet_IncludesList(int handle,_str config=gActiveConfigName)
{
   _str array[];
   _str list='';
   int i;
   _ProjectGet_Includes(handle,array,config);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,PATHSEP);
      }
      strappend(list,array[i]);
   }
   return(list);
}

void _ProjectSet_Includes(int handle,_str (&array)[],_str config=gActiveConfigName)
{
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_INCLUDES);
   _xmlcfg_delete(handle,Node,true);

   int i;
   for (i=0;i<array._length();++i) {
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_INCLUDES,VPJTAG_INCLUDE,'Dir',_NormalizeFile(array[i]));
   }
}

void _ProjectSet_IncludesList(int handle,_str list,_str config=gActiveConfigName)
{
   _str item='';
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_INCLUDES);
   if (Node > 0) _xmlcfg_delete(handle,Node,true);
   for (;;) {
      parse list with item (PATHSEP) list;
      if (item=="" && list=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_INCLUDES,VPJTAG_INCLUDE,'Dir',_NormalizeFile(item));
   }
}
void _ProjectGet_SysIncludes(int handle,_str (&array)[],_str Config=gActiveConfigName)
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"Config"')]/"VPJTAG_SYSINCLUDES'/'VPJTAG_SYSINCLUDE'/@Dir',array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<array._length();++i) {
      array[i]=translate(array[i],FILESEP,FILESEP2);
   }
}
void _ProjectSet_SysIncludesList(int handle,_str list,_str config=gActiveConfigName)
{
   _str item='';
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_SYSINCLUDES);
   if (Node > 0) _xmlcfg_delete(handle,Node,true);
   for (;;) {
      parse list with item (PATHSEP) list;
      if (item=="" && list=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_SYSINCLUDES,VPJTAG_INCLUDE,'Dir',_NormalizeFile(item));
   }
}
_str _ProjectGet_SysIncludesList(int handle,_str config=gActiveConfigName)
{
   int i=0;
   _str list='';
   _str array[];
   _ProjectGet_SysIncludes(handle,array,config);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,PATHSEP);
      }
      strappend(list,array[i]);
   }
   return(list);
}
_str _ProjectGet_RefFile(int handle, _str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return("");
   }
   return(translate(_xmlcfg_get_attribute(handle,Node,'RefFile'),FILESEP,FILESEP2));
}
void _ProjectSet_RefFile(int handle, _str value,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'RefFile');
   } else {
      _xmlcfg_set_attribute(handle,Node,'RefFile',_NormalizeFile(value));
   }
}
void _ProjectGet_Libs(int handle,_str (&array)[],_str Config)
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"Config"')]/"VPJTAG_LIBS'/'VPJTAG_LIB'/@File',array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<array._length();++i) {
      array[i]=translate(array[i],FILESEP,FILESEP2);
   }
}
_str _ProjectGet_LibsList(int handle,_str config)
{
   _str array[];
   _str list='';
   int i;
   _ProjectGet_Libs(handle,array,config);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,' ');
      }
      strappend(list,translate(maybe_quote_filename(array[i]),FILESEP,FILESEP2));
   }
   return(list);
}
void _ProjectSet_LibsList(int handle,_str list,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_LIBS);
   if (Node > 0) _xmlcfg_delete(handle,Node,true);
   for (;;) {
      _str item=parse_file(list,0);
      if (item=="") {
         break;
      }
      _xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_LIBS,VPJTAG_LIB,'File',_NormalizeFile(item));
   }
}

_str _ProjectGet_PreObjectLibs(int handle,_str config)
{
   return _xmlcfg_get_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_LIBS,'PreObjects',0);
}

void _ProjectSet_PreObjectLibs(int handle,int preObject,_str config)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_LIBS);

   if (Node>=0) {
      _xmlcfg_set_attribute(handle,Node,'PreObjects',preObject);
   }
}

void _ProjectGet_ClassPath(int handle,_str (&array)[],_str Config)
{
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"Config"')]/"VPJTAG_CLASSPATH'/'VPJTAG_CLASSPATHELEMENT'/@Value',array,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<array._length();++i) {
      array[i]=translate(array[i],FILESEP,FILESEP2);
   }
}
_str _ProjectGet_ClassPathList(int handle,_str config)
{
   _str array[];
   _str list='';
   int i;
   _ProjectGet_ClassPath(handle,array,config);
   for (i=0;i<array._length();++i) {
      if (list!='') {
         strappend(list,PATHSEP);
      }
      strappend(list,array[i]);
   }
   return(list);
}

void _ProjectSet_ClassPathList(int handle,_str list,_str config)
{
   int Node=_xmlcfg_set_path(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_CLASSPATH);
   _xmlcfg_delete(handle,Node,true);
   for (;;) {
      if (list=="") {
         break;
      }
      _str item='';
      parse list with item (PATHSEP) list;
      int Temp=_xmlcfg_add(handle,Node,VPJTAG_CLASSPATHELEMENT,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle,Temp,'Value',_NormalizeFile(item));
   }
}


/**
 * Get array of project dependencies for the specified
 * dependsRef.  The specified config container is searched
 * first and if not found then the project container is
 * searched.
 *
 * @param handle     Handle to the project
 * @param config     Name of the desired config
 * @param dependsRef Name of the desired dependency reference
 * @param DependencyProjects
 *                   Array of project dependencies (out)
 *
 * @see _ProjectGet_DependencyProjectNodesForRef
 */
void _ProjectGet_DependencyProjectsForRef(int handle, _str config, _str dependsRef, _str (&DependencyProjects)[])
{
   DependencyProjects = null;

   // look first in config
   int node = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES(config, dependsRef), TREE_ROOT_INDEX);
   if(node < 0) {
      // look globally
      node = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES_DEPRECATED "[strieq(@Name,'" dependsRef "')]", TREE_ROOT_INDEX);
      if(node < 0) return;
   }

   // get list of dependencies
   _xmlcfg_find_simple_array(handle, VPJTAG_DEPENDENCY "/@Project", DependencyProjects, node, VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<DependencyProjects._length();++i) {
      DependencyProjects[i]=translate(DependencyProjects[i],FILESEP,FILESEP2);
   }
}

/**
 * Get array of project dependency nodes for the specified
 * dependsRef.  The specified config container is searched
 * first and if not found then the project container is
 * searched.
 *
 * @param handle     Handle to the project
 * @param config     Name of the desired config
 * @param dependsRef Name of the desired dependency reference
 * @param dependencyProjects
 *                   Array of project dependency nodes (out)
 */
void _ProjectGet_DependencyProjectNodesForRef(int handle, _str config, _str dependsRef, typeless (&dependencyProjectNodes)[])
{
   dependencyProjectNodes = null;

   // look first in config
   int node = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES(config, dependsRef), TREE_ROOT_INDEX);
   if(node < 0) {
      // look globally
      node = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES_DEPRECATED "[strieq(@Name,'" dependsRef "')]", TREE_ROOT_INDEX);
      if(node < 0) return;
   }

   // get list of dependency nodes
   _xmlcfg_find_simple_array(handle, VPJTAG_DEPENDENCY, dependencyProjectNodes, node);
}

_str _ProjectGet_DependencyProjectsList(int handle, _str config = "")
{
   _str DependencyProjects[];
   _str deplist='';
   int i;
   _ProjectGet_DependencyProjects(handle,DependencyProjects,config);
   for (i=0;i<DependencyProjects._length();++i) {
      if (deplist!='') {
         strappend(deplist,' ');
      }
      strappend(deplist,'"'DependencyProjects[i]'"');
   }
   return(deplist);
}
void _ProjectGet_DependencyProjects(int handle,_str (&DependencyProjects)[],_str config = "")
{
   // if config is empty, default to current config
   if(config == "") {
      config = GetCurrentConfigName(_xmlcfg_get_filename(handle));
   }

   _xmlcfg_find_simple_array(handle,VPJX_DEPENDENCY(config,config)"/@Project",DependencyProjects,TREE_ROOT_INDEX,VSXMLCFG_FIND_VALUES);
   int i;
   for (i=0;i<DependencyProjects._length();++i) {
      _str CurFile=translate(DependencyProjects[i],FILESEP,FILESEP2);
      CurFile=_parse_project_command(CurFile,"","","");
      DependencyProjects[i]=
         _RelativeToWorkspace(
            _AbsoluteToProject(
               CurFile,
               _xmlcfg_get_filename(handle)
               )
         );
   }
}
int _ProjectGet_DependencyProjectNodes(int handle,typeless (&dependencyProjectNodes)[],_str config = "")
{
   // if config is empty, default to current config
   if(config == "") {
      config = GetCurrentConfigName(_xmlcfg_get_filename(handle));
   }

   // get the dependencies
   return _xmlcfg_find_simple_array(handle, VPJX_DEPENDENCY(config,config), dependencyProjectNodes);
}

/**
 * Get the dependencies node for the specified config
 *
 * @param handle Project handle
 * @param config Config to get dependencies from
 * @param create Create the dependencies container if not found
 */
int _ProjectGet_DependenciesNode(int handle, _str config = "", boolean create = false)
{
   // if config is empty, default to current config
   if(config == "") {
      config = GetCurrentConfigName(_xmlcfg_get_filename(handle));
   }

   // get the dependencies node
   int dependenciesNode = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES(config, config));
   if(dependenciesNode >= 0) {
      // found so just return it
      return dependenciesNode;
   }

   // not found, so create it if requested
   if(create) {
      // find the config node
      int configNode = _xmlcfg_find_simple(handle, VPJX_CONFIG "[strieq(@Name,'" config "')]");
      if(configNode < 0) return STRING_NOT_FOUND_RC;

      // dependencies not found so create the container
      dependenciesNode = _xmlcfg_add(handle, configNode, VPJTAG_DEPENDENCIES, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if(dependenciesNode < 0) return STRING_NOT_FOUND_RC;

      // set its name to match the config
      _xmlcfg_set_attribute(handle, dependenciesNode, "Name", config);

      // return the new container
      return dependenciesNode;
   }

   // failure
   return dependenciesNode;
}

/**
 * Add a dependency on the specified project/config/target
 * combination.  If only a project name is provided, the config and
 * target will be inferred from the current project at runtime.
 *
 * @param handle    Project handle
 * @param depProjectName
 *                  Project name, relative to the workspace
 * @param depConfig Config name (may be left blank)
 * @param depTarget Target name (may be left blank)
 * @param config    Config of this project to add the dependency to
 */
int _ProjectAdd_Dependency(int handle, _str depProjectName, _str depConfig = "",
                           _str depTarget = "", _str config = "")
{
   // if config is empty, default to current config
   if(config == "") {
      config = GetCurrentConfigName(_xmlcfg_get_filename(handle));
   }

   // find the specified configuration
   int configNode = _xmlcfg_find_simple(handle, VPJX_CONFIG "[strieq(@Name,'" config "')]");
   if(configNode < 0) return STRING_NOT_FOUND_RC;

   // find the dependencies node for the specified configuration
   int dependenciesNode = _xmlcfg_find_simple(handle, VPJTAG_DEPENDENCIES "[strieq(@Name,'" config "')]", configNode);
   if(dependenciesNode < 0) {
      // not found so create it
      dependenciesNode = _xmlcfg_add(handle, configNode, VPJTAG_DEPENDENCIES, VSXMLCFG_NODE_ELEMENT_START, VSXMLCFG_ADD_AS_CHILD);
      if(dependenciesNode < 0) return STRING_NOT_FOUND_RC;

      // set its name to match the config
      _xmlcfg_set_attribute(handle, dependenciesNode, "Name", config);
   }

   // convert the project to be relative to this project instead of the workspace
   depProjectName = _AbsoluteToWorkspace(depProjectName);
   depProjectName = _RelativeToProject(depProjectName, _xmlcfg_get_filename(handle));

   // add the dependency
   int depNode = _xmlcfg_add(handle, dependenciesNode, VPJTAG_DEPENDENCY, VSXMLCFG_NODE_ELEMENT_START_END, VSXMLCFG_ADD_AS_CHILD);
   if(depNode >= 0) {
      _xmlcfg_set_attribute(handle, depNode, "Project", _NormalizeFile(depProjectName));
      if(depConfig != "") {
         _xmlcfg_set_attribute(handle, depNode, "Config", depConfig);
      }
      if(depTarget != "") {
         _xmlcfg_set_attribute(handle, depNode, "Target", depTarget);
      }
   }

   return 0;
}

/**
 * Remove the dependency on the specified project/config/target
 * combination.  To remove a specific dependency, provide the project,
 * config, and target.  To remove all dependencies on a project,
 * only the project name should be provided.
 *
 * @param handle Project handle
 * @param depProjectName
 *               Dependent project name, relative to the workspace
 * @param depConfig Dependent config name (may be left blank)
 * @param depTarget Dependent Target name (may be left blank)
 * @param config    Current config name (defaults to current config if blank)
 */
int _ProjectRemove_Dependency(int handle,_str depProjectName,_str depConfig = "",
                               _str depTarget = "",_str config = "",boolean removeAllForProject = false)
{
   // if config is empty, default to current config
   if(config == "") {
      config = GetCurrentConfigName(_xmlcfg_get_filename(handle));
   }

   // find the specified configuration
   int configNode = _xmlcfg_find_simple(handle, VPJX_CONFIG "[strieq(@Name,'" config "')]");
   if(configNode < 0) return STRING_NOT_FOUND_RC;

   // find the dependencies node for the specified configuration
   int dependenciesNode = _xmlcfg_find_simple(handle, VPJX_DEPENDENCIES(config, config));
   if(dependenciesNode < 0) return 0;

   // make the dependent project relative to the current project
   depProjectName=_AbsoluteToWorkspace(depProjectName);
   depProjectName=_RelativeToProject(depProjectName,_xmlcfg_get_filename(handle));
   depProjectName=translate(depProjectName,'/','\');

   // get all the dependency nodes for the config
   int dependencyNodes[] = null;
   _ProjectGet_DependencyProjectNodes(handle,dependencyNodes,config);

   // iterate over all dependency nodes, looking for a match
   int i;
   _str depNodeFile, depNodeConfig, depNodeTarget;
   for (i=0;i<dependencyNodes._length();++i) {
      // get all information about a dependency
      int depNode = dependencyNodes[i];
      depNodeFile=_xmlcfg_get_attribute(handle, depNode, 'Project');
      depNodeFile=_NormalizeFile(depNodeFile);
      depNodeConfig = _xmlcfg_get_attribute(handle, depNode, 'Config');
      depNodeTarget = _xmlcfg_get_attribute(handle, depNode, 'Target');

      // project must match
      if(!file_eq(depNodeFile,depProjectName)) {
         continue;
      }

      // config must match if it was specified
      //
      // NOTE: if removeAllForProject is true, the config and target
      //       are not used and all dependencies for the project will
      //       be removed
      if(!removeAllForProject && !strieq(depNodeConfig, depConfig)) {
         continue;
      }

      // target must match if it was specified
      //
      // NOTE: if removeAllForProject is true, the config and target
      //       are not used and all dependencies for the project will
      //       be removed
      if(!removeAllForProject && !strieq(depNodeTarget, depTarget)) {
         continue;
      }

      // everything matches so delete the node
      _xmlcfg_delete(handle,depNode);
   }

   // if there are no dependencies left, remove the dependencies container
   _ProjectGet_DependencyProjectNodes(handle, dependencyNodes, config);
   if(dependencyNodes._length() <= 0) {
      _xmlcfg_delete(handle, dependenciesNode);
   }

   return 0;
}
_str _ProjectGet_Type(int handle,_str config)
{
   int Node=_ProjectGet_ConfigNode(handle,config);
   if (Node<0) {
      return('');
   }
   return(_xmlcfg_get_attribute(handle,Node,'Type'));
}
int _ProjectAdd_Target(int handle, _str name, _str cmd, _str caption, _str cfg, _str showOnMenu, _str cmdOpts)
{
   int node=_xmlcfg_set_path2(handle,"/"VPJX_CONFIG"[strieq(@Name,'" cfg"')]/"VPJTAG_MENU,VPJTAG_TARGET,
                              'Name',name);
   if (node < 0) {
      return node;
   }
   _xmlcfg_add_attribute(handle,node,'MenuCaption',caption);
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveCurrent');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   _xmlcfg_add_attribute(handle,node,'ShowOnMenu',showOnMenu);
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if(node >= 0 && cmd !="" ) {
      _xmlcfg_add_attribute(handle,node,'CmdLine',cmd);
      if (cmdOpts != '') {
         _xmlcfg_add_attribute(handle,node,'Type',cmdOpts);
      }
   }
   return node;
}
int _ProjectCreateFromTemplate(_str ProjectName,_str TemplateName,_str &InitMacro,boolean doSetAppType=true,boolean SetDefaultFilters=true)
{
   // first we want to try and get the template from the user templates
   templates_handle := _ProjectOpenUserTemplates();
   usingUserTemplate := true;

   // try and find the template name in this xml file
   TemplateNode := _ProjectTemplatesGet_TemplateNode(templates_handle,TemplateName);
   if (TemplateNode<0) {
      // it's not there!  try the system templates
      _xmlcfg_close(templates_handle);

      templates_handle = _xmlcfg_open(get_env("VSROOT"):+VSCFGFILE_PRJTEMPLATES, auto status);
      OverlayOEMTemplates(templates_handle);
      TemplateNode = _ProjectTemplatesGet_TemplateNode(templates_handle,TemplateName);
      usingUserTemplate = false;
   }

   // create the new project file
   int project_handle=_xmlcfg_create(ProjectName,VSENCODING_UTF8);

   // add the doctype
   int doctypeNode = _xmlcfg_add(project_handle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(project_handle, doctypeNode, "root", VPJTAG_PROJECT);
   _xmlcfg_set_attribute(project_handle, doctypeNode, "SYSTEM", VPJ_DTD_PATH);

   // copy the template over
   int NewNode=_xmlcfg_copy(project_handle,TREE_ROOT_INDEX,templates_handle,TemplateNode,VSXMLCFG_COPY_AS_CHILD);
   _xmlcfg_set_name(project_handle,NewNode,VPJTAG_PROJECT);
   int Node=_xmlcfg_set_path(project_handle,VPJX_PROJECT);

   // we want to keep the template name, so we can send it to PIP
   name := _xmlcfg_get_attribute(project_handle, Node, 'Name');

   // remove these attributes, they are not relevant here
   _xmlcfg_delete_attribute(project_handle,Node,'Name');
   _xmlcfg_delete_attribute(project_handle,Node,'Platforms');
   _xmlcfg_delete_attribute(project_handle,Node,'ShowOnMenu');

   InitMacro=_xmlcfg_get_attribute(project_handle,Node,'InitMacro');
   _xmlcfg_delete_attribute(project_handle,Node,'InitMacro');

   _ProjectAddCreateAttributes(project_handle);

   // bug 11566, 1.4.11, sg
   // save the template name and whether this is a customized project 
   // type - this is useful PIP info.  If the project type is customized,
   // we do not send the name, only that it is custom.
   _xmlcfg_set_attribute(project_handle, Node, "TemplateName", name);
   if (usingUserTemplate) {
      _xmlcfg_set_attribute(project_handle, Node, "Customized", "1");
   }

   _ProjectTemplateExpand(templates_handle,project_handle,doSetAppType,SetDefaultFilters);

   // and done!
   return(project_handle);
}
int _ProjectCreate(_str ProjectName)
{
   int handle=_xmlcfg_create(ProjectName,VSENCODING_UTF8);

   // add the doctype
   int doctypeNode = _xmlcfg_add(handle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", VPJTAG_PROJECT);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPJ_DTD_PATH);

   _ProjectAddCreateAttributes(handle);
   return(handle);
}
int _ProjectAddCreateAttributes(int handle)
{
   _xmlcfg_set_path(handle,VPJX_PROJECT,'Version',VPJ_FILE_VERSION);
   _xmlcfg_set_path(handle,VPJX_PROJECT,'VendorName','SlickEdit');
   return(handle);
}
int _ProjectCreateUserTemplates(_str ProjectName)
{
   int handle=_xmlcfg_create(ProjectName,VSENCODING_UTF8);
   // add the doctype
   int doctypeNode = _xmlcfg_add(handle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
   _xmlcfg_set_attribute(handle, doctypeNode, "root", VPTTAG_TEMPLATES);
   _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH);

   _xmlcfg_set_path(handle,VPTX_TEMPLATES,'Version',VPT_FILE_VERSION);
   _xmlcfg_set_path(handle,VPTX_TEMPLATES,'VendorName','SlickEdit');
   return(handle);
}
void _ProjectCreateLangSpecificConfig(int handle, _str langName)
{
   _str initmacro='';
   int temp_handle=_ProjectCreateFromTemplate('','(other)',initmacro,true,false);
   int Node=_ProjectGet_ConfigNode(temp_handle,'Release');
   if (Node<0) {
      _str array[];
      _ProjectGet_ConfigNames(temp_handle,array);
      Node=_ProjectGet_ConfigNode(temp_handle,array[0]);
   }

   int ProjectNode=_xmlcfg_set_path(handle,"/"VPJTAG_PROJECT);
   _xmlcfg_copy(handle,ProjectNode,temp_handle,Node,VSXMLCFG_COPY_AS_CHILD);
   _xmlcfg_close(temp_handle);
   _xmlcfg_set_attribute(handle,_xmlcfg_get_last_child(handle,ProjectNode),'Name',langName);
   _xmlcfg_set_modify(handle,0);

   // gProjectHandle is now an ext-specific project so find the doctype
   // and change the dtd location
   int doctypeNode = _xmlcfg_get_first_child(handle, TREE_ROOT_INDEX, VSXMLCFG_NODE_DOCTYPE);
   while(doctypeNode >= 0) {
      // check the name
      if(_xmlcfg_get_name(handle, doctypeNode) == "DOCTYPE") {
         // change the SYTEM attribute
         _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPE_DTD_PATH);
         break;
      }

      // step next
      doctypeNode = _xmlcfg_get_next_sibling(handle, doctypeNode);
   }
}
int _ProjectCreateUserLangSpecificConfigFile(_str filename)
{
   // we copy the system lang-specific projects over to start with
   sysProjFile := get_env("VSROOT") :+ VSCFGFILE_SYS_EXTPROJECTS;
   if (!file_exists(sysProjFile)) {
      // well, that's no good.  just create a new project file
      return _ProjectCreate(filename);
   }

   if (copy_file(sysProjFile, filename)) {
      // bad, we'll but roll with it
      return _ProjectCreate(filename);
   }

   // open the file!
   handle := _xmlcfg_open(filename, auto status);

   // set the system project version, so we won't try and upgrade
   _ProjectSet_SysProjectVersion(handle);

   // return the handle
   return handle;

}

/**
 * Sets the version when this project file of lang-specific 
 * projects was last updated. 
 *  
 * Only for use with the lang-specific projects file - 
 * project.vpe (uproject.vpe on UNIX) or sysproject.vpe.
 * 
 * @param handle 
 */
void _ProjectSet_SysProjectVersion(int handle)
{
   _xmlcfg_set_path(handle, VPJX_PROJECT, VPWTAG_SYSVPEVERSION, _version());
}

_str _ProjectGet_SysProjectVersion(int handle)
{
   return _xmlcfg_get_path(handle, VPJX_PROJECT, VPWTAG_SYSVPEVERSION);
}

void _ProjectMaybeUpdateLangSpecificConfigs(int handle)
{
   // get the version and compare it to the current product version
   userFileVersion := _ProjectGet_SysProjectVersion(handle);
   if (_version_compare(userFileVersion, _version()) >= 0) return;

   // compare it to the sysproject.vpe file
   sysProjFile := get_env("VSROOT") :+ VSCFGFILE_SYS_EXTPROJECTS;
   sysFileHandle := _xmlcfg_open(sysProjFile, auto status);
   if (sysFileHandle < 0) {
      // not sure what to do here, it's a problem
      return;
   }

   sysFileVersion := _ProjectGet_SysProjectVersion(sysFileHandle);
   if (_version_compare(userFileVersion, sysFileVersion) < 0) {
      // this file needs to be updated!  we are just the ones to do it!
      userProjNode := _xmlcfg_set_path(handle,"/"VPJTAG_PROJECT);

      // get all the configs out of the system file
      int configNodes[];
      _ProjectGet_Configs(sysFileHandle, configNodes);

      // make sure each system config is in the user file
      for (i := 0; i < configNodes._length(); i++) {
         configName := _xmlcfg_get_attribute(sysFileHandle, configNodes[i], 'Name');
         if (_ProjectGet_ConfigNode(handle, configName) < 0) {
            // user file does not have this one - add it
            _xmlcfg_copy(handle, userProjNode, sysFileHandle, configNodes[i], VSXMLCFG_COPY_AS_CHILD);
         }
      }

   } // else it's up to date with the latest changes to the system file

   // update the version to the current product version so we can avoid this check in the future
   _ProjectSet_SysProjectVersion(handle);

   // save all that hard work
   _ProjectSave(handle);
}

void _ProjectGet_ConfigInfo(int handle,PROJECT_CONFIG_INFO &info,int ConfigNode)
{
   // empty config info
   info._makeempty();

   // general information
   info.Name=_xmlcfg_get_attribute(handle,ConfigNode,'Name');
   _str config=info.Name;
   info.Type=_xmlcfg_get_attribute(handle,ConfigNode,'Type');
   info.AppType=_xmlcfg_get_attribute(handle,ConfigNode,'AppType');
   info.AppTypeList=_xmlcfg_get_attribute(handle,ConfigNode,'AppTypeList');
   info.RefFile=_xmlcfg_get_attribute(handle,ConfigNode,'RefFile');
   info.OutputFile=_xmlcfg_get_attribute(handle,ConfigNode,'OutputFile');
   info.DebugCallbackName=_xmlcfg_get_attribute(handle,ConfigNode,'DebugCallbackName');
   info.ObjectDir=_xmlcfg_get_attribute(handle,ConfigNode,'ObjectDir');

   // libraries
   info.Libs=_ProjectGet_DisplayLibsList(handle,config);

   // includes
   if (_ProjectGet_Type(handle, config ) :!= "java") {
      info.Includes=_ProjectGet_IncludesList(handle,config);
      info.AssociatedIncludes=_ProjectGet_AssociatedIncludes(handle,false,config);
   } else {
      info.Includes = '';
      info.AssociatedIncludes = '';
   }

   // pre and post build commands
   info.StopOnPreBuildError=(int)_ProjectGet_StopOnPreBuildError(handle,config);
   info.PreBuildCommands=_ProjectGet_PreBuildCommandsList(handle,config);
   info.StopOnPostBuildError=(int)_ProjectGet_StopOnPostBuildError(handle,config);
   info.PostBuildCommands=_ProjectGet_PostBuildCommandsList(handle,config);

   info.ClassPath=_ProjectGet_ClassPathList(handle,config);
   info.CompilerConfigName=_ProjectGet_CompilerConfigName(handle,config);

   info.Defines=_ProjectGet_Defines(handle,config);

   _str assoc_file = _ProjectGet_AssociatedFile(handle);
   if (assoc_file!='') {
      info.AssociatedDefines=_ProjectGet_AssociatedDefines('',handle,config,assoc_file,false);
   } else {
      info.AssociatedDefines='';
   }

   // loop over all targets in this config
   typeless array[];
   _xmlcfg_find_simple_array(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_MENU"//"VPJTAG_TARGET,array);
   int i;
   info.TargetList='';
   for (i=0;i<array._length();++i) {
      PROJECT_TARGET_INFO *pt;
      int Node=array[i];
      _str Name=_xmlcfg_get_attribute(handle,Node,'Name');
      if (info.TargetList!='') {
         strappend(info.TargetList,"\1");
      }
      strappend(info.TargetList,Name);
      pt=&info.TargetInfo:[lowcase(Name)];
      pt->Name=Name;
      pt->MenuCaption=_xmlcfg_get_attribute(handle,Node,'MenuCaption');
      pt->OutputExts=_xmlcfg_get_attribute(handle,Node,'OutputExts');
      pt->LinkObject=_xmlcfg_get_attribute(handle,Node,'LinkObject',1);
      pt->BuildFirst=_xmlcfg_get_attribute(handle,Node,'BuildFirst',0);
      pt->Verbose=_xmlcfg_get_attribute(handle,Node,'Verbose',0);
      pt->Beep=_xmlcfg_get_attribute(handle,Node,'Beep',0);
      pt->SaveOption=_xmlcfg_get_attribute(handle,Node,'SaveOption',VPJ_SAVEOPTION_SAVENONE);
      pt->Dialog=_xmlcfg_get_attribute(handle,Node,'Dialog');
      pt->Deletable=_xmlcfg_get_attribute(handle,Node,'Deletable',1);
      pt->ShowOnMenu=_xmlcfg_get_attribute(handle,Node,'ShowOnMenu',VPJ_SHOWONMENU_ALWAYS);
      if (strieq(Name,'compile') ||
          strieq(Name,'build') ||
          strieq(Name,'rebuild')
          ) {
         pt->EnableBuildFirst=0; //_xmlcfg_get_attribute(handle,Node,'EnableBuildFirst',);
      } else {
         pt->EnableBuildFirst=_xmlcfg_get_attribute(handle,Node,'EnableBuildFirst',1);
      }
      pt->CaptureOutputWith=_xmlcfg_get_attribute(handle,Node,'CaptureOutputWith');
      pt->ClearProcessBuffer=_xmlcfg_get_attribute(handle,Node,'ClearProcessBuffer',0);
      pt->RunInXterm=_xmlcfg_get_attribute(handle,Node,'RunInXterm',0);
      pt->PreMacro=_xmlcfg_get_attribute(handle,Node,'PreMacro');
      pt->RunFromDir=_xmlcfg_get_attribute(handle,Node,'RunFromDir');
      pt->AppletClass=_xmlcfg_get_attribute(handle,Node,'AppletClass');
      Node=_xmlcfg_find_simple(handle,VPJTAG_EXEC,Node);
      if (Node>=0) {
         pt->Exec_CmdLine=_xmlcfg_get_attribute(handle,Node,'CmdLine');
         pt->Exec_Type=_xmlcfg_get_attribute(handle,Node,'Type');
         pt->Exec_OtherOptions=_xmlcfg_get_attribute(handle,Node,'OtherOptions');
      } else {
         pt->Exec_CmdLine='';
         pt->Exec_Type='';
         pt->Exec_OtherOptions='';
      }

      // look for rules for this target
      int ruleArray[] = null;
      _ProjectGet_Rules(handle, ruleArray, Name, config);
      int ruleIndex;
      for(ruleIndex = 0; ruleIndex < ruleArray._length(); ruleIndex++) {
         int ruleNode = ruleArray[ruleIndex];
         _str inputExts = _xmlcfg_get_attribute(handle, ruleNode, 'InputExts');
         PROJECT_RULE_INFO* pr = &pt->Rules:[lowcase(inputExts)];
         pr->InputExts            = _xmlcfg_get_attribute(handle, ruleNode, "InputExts");
         pr->OutputExts           = _xmlcfg_get_attribute(handle, ruleNode, "OutputExts");
         pr->LinkObject           = _xmlcfg_get_attribute(handle, ruleNode, "LinkObject", 1);
         pr->Dialog               = _xmlcfg_get_attribute(handle, ruleNode, "Dialog");
         pr->Deletable            = _xmlcfg_get_attribute(handle, ruleNode, "Deletable", 1);
         pr->RunFromDir           = _xmlcfg_get_attribute(handle, ruleNode, "RunFromDir");

         int ruleExecNode = _xmlcfg_find_simple(handle, VPJTAG_EXEC, ruleNode);
         if(ruleExecNode >= 0) {
            pr->Exec_CmdLine      = _xmlcfg_get_attribute(handle, ruleExecNode, "CmdLine");
            pr->Exec_Type         = _xmlcfg_get_attribute(handle, ruleExecNode, "Type");
            pr->Exec_OtherOptions = _xmlcfg_get_attribute(handle, ruleExecNode, "OtherOptions");
         } else {
            pr->Exec_CmdLine      = "";
            pr->Exec_Type         = "";
            pr->Exec_OtherOptions = "";
         }
      }
   }

   // check for dependencies for this target
   //
   // NOTE: the project GUI always stores dependencies for a config in a
   //       <Dependencies> set with the same name as the config
   int depNodes[] = null;
   _ProjectGet_DependencyProjectNodesForRef(handle, info.Name, info.Name, depNodes);

   int depIndex, depCount = depNodes._length();
   for(depIndex = 0; depIndex < depCount; depIndex++) {
      int depNode = depNodes[depIndex];
      if(depNode < 0) continue;

      _str depProject = _xmlcfg_get_attribute(handle, depNode, "Project");
      _str depConfig = _xmlcfg_get_attribute(handle, depNode, "Config");
      //_str depTarget = _xmlcfg_get_attribute(handle, depNode, "Target");

      PROJECT_DEPENDENCY_INFO* pd = &info.DependencyInfo:[lowcase(depProject "/" depConfig "/" /*depTarget*/)];
      pd->Project = depProject;
      pd->Config  = depConfig;
      //pd->Target  = depTarget;
   }
}
int _ProjectAddTool(int handle,_str TargetName,_str config)
{
   int Node=_xmlcfg_set_path2(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_MENU,VPJTAG_TARGET,'Name',TargetName);
   _xmlcfg_set_attribute(handle,Node,'MenuCaption','&'TargetName);

   return Node;
}

/**
 * Determines whether a target with the given name exists in the
 * project.  You can check a specific configuration or check all
 * configs.
 *
 * @param handle
 * @param targetName
 * @param config
 *
 * @return boolean
 */
boolean _ProjectDoes_TargetExist(int handle, _str targetName, _str config = '')
{
   node := 0;
   if (config == '') {
      node = _xmlcfg_find_simple(handle, VPJX_CONFIG"/"VPJTAG_MENU:+"//"VPJTAG_TARGET"[strieq(@Name,'"targetName"')]");
   } else {
      node = _xmlcfg_find_simple(handle, VPJX_CONFIG"[strieq(@Name,'"config"')]/"VPJTAG_MENU:+"//"VPJTAG_TARGET"[strieq(@Name,'"targetName"')]");
   }

   return (node > 0);
}

int _ProjectGet_FolderNode(int handle,_str FolderName)
{
   _str AutoFolders=_ProjectGet_AutoFolders(handle);
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      XMLVARIATIONS xmlv;
      _ProjectGet_XMLVariations(handle,xmlv);
      return(_xmlcfg_find_simple(handle,xmlv.vpjx_files"//"xmlv.vpjtag_folder:+XPATH_STRIEQ(xmlv.vpjattr_folderName,FolderName)));
      //return(_xmlcfg_find_simple(handle,VPJX_FILES"//"VPJTAG_FOLDER:+XPATH_STRIEQ('Name',FolderName)));
   }
   return(_xmlcfg_find_simple(handle,VPJX_FILES"//"VPJTAG_FOLDER:+XPATH_STRIEQ('Name',_NormalizeFile(FolderName))));
}
void _ProjectGet_Folders(int handle,typeless (&array)[])
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   _xmlcfg_find_simple_array(handle,xmlv.vpjx_files"//"xmlv.vpjtag_folder,array);
}
int _ProjectRemove_File(int handle,_str RelFilename)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_FILES"//"VPJTAG_F:+XPATH_FILEEQ('N',_NormalizeFile(RelFilename)));
   if (Node>=0) {
      _xmlcfg_delete(handle,Node);
      return(1);
   }
   return(0);
}

_str _ProjectGet_VCSProject(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"VCSProject"));
}
void _ProjectSet_VCSProject(int handle,_str value)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_PROJECT);
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'VCSProject');
      return;
   }
   _xmlcfg_set_attribute(handle,Node,"VCSProject",value);
}
void _ProjectSet_VCSLocalPath(int handle,_str value)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_PROJECT);
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'VCSLocalPath');
      return;
   }
   _xmlcfg_set_attribute(handle,Node,"VCSLocalPath",value);
}
_str _ProjectGet_VCSLocalPath(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"VCSLocalPath"));
}
void _ProjectSet_VCSAuxPath(int handle,_str value)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_PROJECT);
   if (Node<0) {
      return;
   }
   if (value=='') {
      _xmlcfg_delete_attribute(handle,Node,'VCSAuxPath');
      return;
   }
   _xmlcfg_set_attribute(handle,Node,"VCSAuxPath",value);
}
_str _ProjectGet_VCSAuxPath(int handle)
{
   return(_xmlcfg_get_path(handle,VPJX_PROJECT,"VCSAuxPath"));
}
int _ProjectGet_FileNode(int handle, _str RelFilename)
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);
   return(_xmlcfg_find_simple(handle,xmlv.vpjx_files"//"xmlv.vpjtag_f:+XPATH_FILEEQ(xmlv.vpjattr_n,_NormalizeFile(RelFilename,xmlv.doNormalizeFile))));
}
static int AddNestedDirectories(int DestHandle,int Node,_str path,int (&PathToNodeHashTab):[])
{
   _str cpath='';
   _str path_part='';
#if __PCDOS__
   // IF this is a UNC name
   if (substr(path,1,2)=='\\') {
      int i=pos(FILESEP'[~\\]+\\[~\\]+\\\c',path,3);
      if (!i) {
         i=2;
      }
      path_part=substr(path,1,i-1);
      path=substr(path,i+1);
   } else if (substr(path,1,1)==FILESEP) {
      int i=pos(FILESEP,path,2);
      path_part=substr(path,1,i-1);
      path=substr(path,i+1);
   } else if (isdrive(substr(path,1,2))) {
      path_part=substr(path,1,3);
      path=substr(path,4);
   } else {
      path_part='';
   }
#else
   if (substr(path,1,1)==FILESEP) {
      int i=pos(FILESEP,path,2);
      path_part=substr(path,1,i-1);
      path=substr(path,i);
   } else {
      path_part='';
   }
#endif


   for (;;) {
      if (path_part!='') {
         /*
             add all ../../.. stuff
         */
         while (last_char(path_part)=='.' || substr(path,1,1)=='.' && path!='') {
            int i=pos(FILESEP,path);
            path_part=path_part:+FILESEP:+substr(path,1,i-1);
            path=substr(path,i+1);
         }
         cpath=cpath:+_file_case(path_part):+FILESEP;
         int *pnode=PathToNodeHashTab._indexin(cpath);
         if (!pnode) {
            Node=_xmlcfg_add(DestHandle,Node,VPJTAG_FOLDER,VSXMLCFG_NODE_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
            _xmlcfg_set_attribute(DestHandle,Node,'Name',_NormalizeFile(path_part));
            PathToNodeHashTab:[cpath]=Node;
         } else {
            Node=*pnode;
         }
      }
      if (path=='') {
         break;
      }
      int i=pos(FILESEP,path);
      path_part=substr(path,1,i-1);
      path=substr(path,i+1);

   }
   return(Node);
}
void _ProjectSortFolderNodesInHashTable(int handle, int (&PathToNodeHashTab):[],boolean SortFolders=false,_str FolderSortOption='')
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);
   if (FolderSortOption=='') {
      FolderSortOption='2P';
   }
   boolean HitNode:[];
   typeless t;
   for (t._makeempty();;) {
      int Node=PathToNodeHashTab._nextel(t);
      if (t._isempty()) {
         break;
      }
      if (HitNode._indexin(Node)) {
         continue;
      }
      //_message_box('N='_xmlcfg_get_attribute(handle,Node,'Name'));
      if (SortFolders) {
         _xmlcfg_sort_on_attribute(handle,Node,xmlv.vpjattr_n,'2P',xmlv.vpjtag_folder,xmlv.vpjattr_folderName,FolderSortOption);
      } else {
         _xmlcfg_sort_on_attribute(handle,Node,xmlv.vpjattr_n,'2P',xmlv.vpjtag_folder);
      }
      HitNode:[Node]=true;
   }
}
_str FindPackage(_str file,boolean ReadFileDataForPackage)
{
   if (ReadFileDataForPackage) {
      int status,temp_view_id,orig_view_id;
      status=_open_temp_view(file,temp_view_id,orig_view_id);
      if (status) {
         return('');
      }
      _str packageName=getPackageName();
      _delete_temp_view(temp_view_id);
      activate_window(orig_view_id);
      return(packageName);
   }
   _str tag_name='';
   _str type_name='';
   _str file_name='';
   int line_no=0;
   _str class_name='';
   int tag_flags=0;
   int status=tag_find_in_file(file);
   _str longest_package = '';
   while (!status) {
      tag_get_info(tag_name,type_name,file_name,line_no,class_name,tag_flags);
      if (type_name=='package') {
         if (class_name != '') {
            class_name = stranslate(class_name,'.',VS_TAGSEPARATOR_package);
         }
         _str package = class_name;
         if (package != '') {
            package :+= '.';
         }
         package :+= tag_name;
         if (length(package) > length(longest_package)) {
            longest_package = package;
         }
      } else if (type_name == 'import' || tag_tree_type_is_func(type_name) || tag_tree_type_is_class(type_name)) {
         tag_reset_find_in_file();
         return longest_package;
      }
      status=tag_next_in_file();
   }
   tag_reset_find_in_file();
   return longest_package;
}
void _ProjectAutoFolders(int dest_handle,int src_handle= -1, int SrcFilesNode=-1, _str AutoFolders=null,boolean ReadFileDataForPackage=false)
{
   if (src_handle== -1) src_handle=dest_handle;
   if (SrcFilesNode<0) {
      SrcFilesNode=_ProjectGet_FilesNode(src_handle,false);
      if (SrcFilesNode<0) {
         return;
      }
   }
   boolean doDeleteSrcFilesNode= (src_handle==dest_handle) && _xmlcfg_get_name(src_handle,SrcFilesNode)!=VPJTAG_CUSTOMFOLDERS;
   if (AutoFolders==null) {
      AutoFolders=_ProjectGet_AutoFolders(src_handle);
   }
   if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      return;
   }
   if (src_handle==dest_handle && doDeleteSrcFilesNode) {
      _xmlcfg_set_name(src_handle,SrcFilesNode,'old');
   }
   int old_array_size=_default_option(VSOPTION_WARNING_ARRAY_SIZE);
   _default_option(VSOPTION_WARNING_ARRAY_SIZE,MAXINT);
   typeless array[];
   _xmlcfg_find_simple_array(src_handle,'//'VPJTAG_F,array,SrcFilesNode);

   _default_option(VSOPTION_WARNING_ARRAY_SIZE,old_array_size);


   int DestFilesNode=_ProjectGet_FilesNode(dest_handle,true);
   _xmlcfg_set_attribute(dest_handle,DestFilesNode,'AutoFolders',AutoFolders);
   int PathToNodeHashTab:[];
   int FolderFlags=VSXMLCFG_ADD_AS_CHILD;
   int FolderNode=DestFilesNode;
   int LastParentNode=-1;
   int LastNode= -1;
   int i;
   _str path='';
   _str cpath='';

   for (i=0;i<array._length();++i) {
      _str RelFilename=translate(_xmlcfg_get_attribute(src_handle,array[i],'N'),FILESEP,FILESEP2);
      path=_strip_filename(RelFilename,'N');
      cpath=_file_case(path);
      int *pnode=PathToNodeHashTab._indexin(cpath);
      if (!pnode) {
         if (cpath=='') {
            PathToNodeHashTab:[cpath]=DestFilesNode;
            pnode=PathToNodeHashTab._indexin(cpath);
         } else {
            if (strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW)) {
               FolderNode=_xmlcfg_add(dest_handle,FolderNode,VPJTAG_FOLDER,VSXMLCFG_NODE_ELEMENT_START_END,FolderFlags);
               PathToNodeHashTab:[cpath]=FolderNode;
               pnode=PathToNodeHashTab._indexin(cpath);
               FolderFlags=0;
               if (last_char(path)==FILESEP && path!=FILESEP) {
                  path=substr(path,1,length(path)-1);
               }
               _str FolderName=_NormalizeFile(path);
               /*if (!pos('.',FolderName,1)) {
                  FolderName=translate(FolderName,'.','/');
               } */
               _xmlcfg_set_attribute(dest_handle,FolderNode,'Name',FolderName);
            } else {
               FolderNode=AddNestedDirectories(dest_handle,DestFilesNode,path,PathToNodeHashTab);
               PathToNodeHashTab:[cpath]=FolderNode;
               pnode=PathToNodeHashTab._indexin(cpath);
            }
         }
      }
      if (LastParentNode!=*pnode) {
         LastParentNode=*pnode;
         LastNode=_xmlcfg_copy(dest_handle,LastParentNode,src_handle,array[i],VSXMLCFG_COPY_AS_CHILD);
      } else {
         LastNode=_xmlcfg_copy(dest_handle,LastNode,src_handle,array[i],0);
         if (LastParentNode>=0) {
            _xmlcfg_sort_on_attribute(dest_handle,LastParentNode,'N','BP');
         }
      }
   }
   PathToNodeHashTab:['']=DestFilesNode;
   if (src_handle==dest_handle && doDeleteSrcFilesNode) {
      _xmlcfg_delete(src_handle,SrcFilesNode);
   }
   typeless t='';
   int status=0;
   _str workspace_tag_file = _GetWorkspaceTagsFilename();
   if (ReadFileDataForPackage) {
      status=0;
   } else {
      status=tag_read_db(_GetWorkspaceTagsFilename());
   }
   if (status >= 0) {
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW)) {
         _str ProjectPath=_strip_filename(_xmlcfg_get_filename(dest_handle),'N');
         int PackageNameHashTab:[];   // Hash package name to know we already have it.
         for (t._makeempty();;) {
            int Node=PathToNodeHashTab._nextel(t);
            if (t._isempty()) {
               break;
            }
            // Find the first .java file in this folder and get the package
            int FileNode=_xmlcfg_find_simple(dest_handle,VPJTAG_F:+XPATH_CONTAINS('N','(.java|.jav)$','R'_fpos_case),Node);
            if (FileNode>=0) {
               _str absfile=translate(_xmlcfg_get_attribute(dest_handle,FileNode,'N'),FILESEP,FILESEP2);
               _str packageName = _ProjectFind_JavaPackageFromDir(absfile,dest_handle,FileNode,true);
               if (packageName!='') {
                  int *pnode=PackageNameHashTab._indexin(packageName);
                  //IF we have a node for this package
                  if (pnode) {
                     // Move this one level directory to the same package folder
                     _xmlcfg_copy_children_with_name(dest_handle,Node,*pnode,VPJTAG_F,true);
                     if (t!='') {
                        // Delete the empty one level directory node
                        _xmlcfg_delete(dest_handle,Node);
                     }
                  } else {
                     if (t=='') {
                        // Move files out of root of project to folder
                        Node=_xmlcfg_add(dest_handle,DestFilesNode,VPJTAG_FOLDER,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
                        //PathToNodeHashTab:[_chr(1) /* something unique! */]=Node;
                        _xmlcfg_copy_children_with_name(dest_handle,DestFilesNode,Node,VPJTAG_F,true);
                     }
                     PackageNameHashTab:[packageName]=Node;
                     _xmlcfg_set_attribute(dest_handle,Node,'Name',packageName);
                     _xmlcfg_set_attribute(dest_handle,Node,'Type','Package');
                  }
               } else {

                  // Don't move a file to root. If a file does not have a package then
                  // it might be a newly created file that the user just added that will
                  // become part of the package. Leave the file where it is. Also moving
                  // a file up to root seems to completely hose the project from then on
                  // until the moved file is removed from the project completely.

                  // IF the files are not already in the root folder
//                  if (t!='') {
//                     // Move the files to the root
//                     _xmlcfg_copy_children_with_name(dest_handle,Node,DestFilesNode,VPJTAG_F,true);
//                     // Delete the empty one level directory node
//                     _xmlcfg_delete(dest_handle,Node);
//                  }
               }
            }
         }
         if (!ReadFileDataForPackage) tag_close_db(null,true);

         PackageNameHashTab:['']=DestFilesNode;

         PathToNodeHashTab=PackageNameHashTab;
      }
   }
   _ProjectSortFolderNodesInHashTable(dest_handle,PathToNodeHashTab,true,
                                      strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW)?'BP':'2P'
                                      );
}

/**
 * Attempts to place the Java files of a directory into a package, when
 * using the Package view in the Projects tool window. First checks for
 * the 'default' package, and then checks for package statements which
 * make sense based on the directory structure.
 *
 * @param file first Jave file in the directory
 * @param handle XML file handle
 * @param node index of file in handle
 * @param read_file boolean for FindPackage
 *
 * @return _str the package name or '' if no suitable package is found
 */
_str _ProjectFind_JavaPackageFromDir(_str file, int handle, int node, boolean read_file){
   if (file :!= '') {
      _str path=_strip_filename(file,'N');
      // if the file is in the root of the project and has no package statement
      // then throw it in the 'default' package
      file = _AbsoluteToProject(file);
      _str packageName=FindPackage(file,read_file);
      if (path :== '' && packageName :== '') {
         return '(default package)';
      } else {
         if (handle >= 0 && node >= 0) {
            int sibling=node;
            // check all the Java files in the directory for package statements
            while (sibling >= 0) {
               _str absfile=translate(_xmlcfg_get_attribute(handle,sibling,'N'),FILESEP,FILESEP2);
               absfile= _AbsoluteToProject(absfile);
               if (packageName :!= '') {
                  _str abs_dir=translate(_strip_filename(absfile, 'N'), '.', FILESEP);
                  if (length(abs_dir) > length(packageName)) {
                     _str abs_dir_tail=substr(abs_dir, length(abs_dir)-length(packageName));
                     // check the tail of the directory for the existence of the package name
                     if (pos(packageName, abs_dir_tail) > 0) {
                           return packageName;
                     }
                  }
               }
               sibling=_xmlcfg_get_next_sibling(handle, sibling);
            }
            // file is in some subdirectory of the project, and none of the files in the dir
            // have suitable package statements...so just create a folder
            return('');
//            return(translate(substr(path,1,length(path)-1),'.',FILESEP));
         }
      }
   }
   return '';
}

_str _ProjectGet_AutoFolders(int handle)
{
   int Node=_ProjectGet_FilesNode(handle);
   if (Node<0) {
      return(VPJ_AUTOFOLDERS_CUSTOMVIEW);
   }
   return(_xmlcfg_get_attribute(handle,Node,'AutoFolders',VPJ_AUTOFOLDERS_CUSTOMVIEW));
}

void _ProjectSet_AutoFolders(int handle,_str AutoFolders,boolean ReadFileDataForPackage=false)
{
   _str OldAutoFolders=_ProjectGet_AutoFolders(handle);
   if (strieq(OldAutoFolders,AutoFolders)) {
      return;
   }
   int FilesNode=_ProjectGet_FilesNode(handle,true);


   // IF this is an associated workspace
   if (_ProjectGet_AssociatedFile(handle)!='') {
      if (strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
         _xmlcfg_delete_attribute(handle,FilesNode,'AutoFolders');
      } else {
         _xmlcfg_set_attribute(handle,FilesNode,'AutoFolders',AutoFolders);
      }
      return;
   }

   if (strieq(OldAutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      // We are switching from CustomView to PackageView or DirectoryView
      // Save the folder settings
      int Node=_xmlcfg_find_simple(handle,VPJX_PROJECT:+'/':+VPJTAG_CUSTOMFOLDERS);
      if (Node>=0) {
         _xmlcfg_delete(handle,Node);
      }
      _xmlcfg_set_name(handle,FilesNode,VPJTAG_CUSTOMFOLDERS);
      _ProjectAutoFolders(handle,handle,FilesNode,AutoFolders,ReadFileDataForPackage);

      _xmlcfg_delete_children_with_name(handle,FilesNode,VPJTAG_F);
      return;
   }
   if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      _ProjectAutoFolders(handle,handle,FilesNode,AutoFolders,ReadFileDataForPackage);
      return;
   }
   _xmlcfg_set_name(handle,FilesNode,'old');
   boolean doDelete=false;
   int DestFilesNode=_xmlcfg_find_simple(handle,VPJX_PROJECT:+'/':+VPJTAG_CUSTOMFOLDERS);
   if (DestFilesNode<0) {
      // The old settings are missing
      // Use default settings
      _ProjectAdd_DefaultFolders(handle);
      DestFilesNode=_ProjectGet_FilesNode(handle,true);
   } else {
      doDelete=true;
      _xmlcfg_set_name(handle,DestFilesNode,VPJTAG_FILES);
   }

   typeless array[];
   _xmlcfg_find_simple_array(handle,'//'VPJTAG_F,array,FilesNode);

   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(handle,ExtToNodeHashTab);
   _str lastext=null;
   int count=array._length();
   int Node= -1;
   int i;
   for (i=0;i<count;++i) {
       _str file=translate(_xmlcfg_get_attribute(handle,array[i],'N'),FILESEP,FILESEP2);
       _str ext=lowcase(_get_extension(file));
       if (ext==lastext) {
          Node=_xmlcfg_copy(handle,Node,handle,array[i],0);
       } else {
          _str *pnode=ExtToNodeHashTab._indexin(ext);
          // IF there is not a folder for this
          if (!pnode) {
             ext='';
             pnode=ExtToNodeHashTab._indexin('');
          }
          if (ext==lastext) {
             Node=_xmlcfg_copy(handle,Node,handle,array[i],0);
          } else {
             lastext=ext;
             Node=_xmlcfg_copy(handle,(typeless)*pnode,handle,array[i],VSXMLCFG_ADD_AS_CHILD);
          }
       }
   }
   _ProjectSortFolderNodesInHashTable(handle,ExtToNodeHashTab);
   if (doDelete) {
      _xmlcfg_delete(handle,FilesNode);
   }
}
void _ProjectAdd_FilteredFiles(int handle,_str RelFilename,
                               int (&FileToNode):[],
                               int (&ExtToNodeHashTab):[],
                               _str &lastext=null,
                               int &Node= -1,
                               int (&SortNodes):[]=null)
{
   _str ext=lowcase(_get_extension(RelFilename));
   if (ext==lastext) {
      Node=_xmlcfg_add(handle,Node,'F',VSXMLCFG_NODE_ELEMENT_START_END,0);
   } else {
      int *pnode=ExtToNodeHashTab._indexin(ext);
      // IF there is not a folder for this
      if (!pnode) {
         ext='';
         pnode=ExtToNodeHashTab._indexin('');
      }
      if (ext==lastext) {
         Node=_xmlcfg_add(handle,Node,'F',VSXMLCFG_NODE_ELEMENT_START_END,0);
      } else {
         lastext=ext;
         SortNodes:[*pnode]= *pnode;
         Node=_xmlcfg_add(handle,*pnode,'F',VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
      }
   }
   _xmlcfg_set_attribute(handle,Node,'N',_NormalizeFile(RelFilename));
   FileToNode:[_file_case(RelFilename)]=Node;

   // if this is an ant build file, set the Type attribute
   if(_IsAntBuildFile(_AbsoluteToProject(RelFilename))) {
      _xmlcfg_set_attribute(handle, Node, "Type", "Ant");
   } else if(_IsNAntBuildFile(_AbsoluteToProject(RelFilename))) {
      // if this is a NAnt build file, set the Type attribute
      _xmlcfg_set_attribute(handle, Node, "Type", "NAnt");
   } else if(_IsMakefile(_AbsoluteToProject(RelFilename))) {
      // if this is a makefile, set the Type attribute
      _xmlcfg_set_attribute(handle, Node, "Type", "Makefile");
   }
}
static void _ProjectAdd_FilteredFilesArray(int handle,_str (NewFilesList)[],int (&FileToNode):[], int (&ExtToNodeHashTab):[]=null,boolean doSort=true)
{
   if (ExtToNodeHashTab==null) {
      _ProjectGet_ExtToNode(handle,ExtToNodeHashTab);
   }

   _str lastext=null;
   int SortNodes:[];
   int count=NewFilesList._length();
   int Node;
   int i;
   for (i=0;i<count;++i) {
      _ProjectAdd_FilteredFiles(handle,NewFilesList[i],FileToNode,ExtToNodeHashTab,lastext,Node,SortNodes);
   }
   if (doSort) {
      _ProjectSortFolderNodesInHashTable(handle,SortNodes);
   }
}
void _ProjectRefilter(int handle)
{
   int ExtToNodeHashTab:[];
   _ProjectGet_ExtToNode(handle,ExtToNodeHashTab);

   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   typeless array[];
   _xmlcfg_find_simple_array(handle,xmlv.vpjx_files'//'xmlv.vpjtag_f,array);

   _str lastext=null;
   int SortNodes:[];
   int count=array._length();
   int Node=0;
   int i;
   for (i=0;i<count;++i) {
      _str RelFilename=_xmlcfg_get_attribute(handle,array[i],xmlv.vpjattr_n);
       _str ext=lowcase(_get_extension(RelFilename));
       if (ext==lastext) {
          Node=_xmlcfg_copy(handle,Node,handle,array[i],0);
       } else {
          int *pnode=ExtToNodeHashTab._indexin(ext);
          // IF there is no a folder for this
          if (!pnode) {
             ext='';
             pnode=ExtToNodeHashTab._indexin('');
          }
          if (ext==lastext) {
             Node=_xmlcfg_copy(handle,Node,handle,array[i],0);
          } else {
             lastext=ext;
             SortNodes:[*pnode]=*pnode;
             Node=_xmlcfg_copy(handle,*pnode,handle,array[i],VSXMLCFG_ADD_AS_CHILD);
          }
       }
       _xmlcfg_delete(handle,array[i]);
   }
   _ProjectSortFolderNodesInHashTable(handle,SortNodes);
}

void _ProjectAdd_Wildcard(int handle,_str newWildcard, _str excludes = "", boolean recurse = false, boolean deprecated = false)
{
   int fileToNode:[];

   // add the wildcard as a file
   _str wildcardList[];
   wildcardList[wildcardList._length()] = newWildcard;
   _ProjectAdd_Files(handle, wildcardList, fileToNode);

   // set the attributes for that wildcard
   int node = fileToNode:[_file_case(newWildcard)];
   if(node >= 0) {
      _xmlcfg_set_attribute(handle, node, "Recurse", recurse);
      _xmlcfg_set_attribute(handle, node, "Excludes", _NormalizeFile(excludes));
   }
}

void _ProjectAdd_Files(int handle,_str (&NewFilesList)[],int (&FileToNode):[]=null,int FilesNode=-1,_str AutoFolders=null,int (&ExtToNodeHashTab):[]=null,boolean doSort=true)
{
   if(AutoFolders==null) {
      AutoFolders=VPJ_AUTOFOLDERS_CUSTOMVIEW;
      FilesNode=_ProjectGet_FilesNode(handle,true);
      if (FilesNode>=0) {
         AutoFolders=_ProjectGet_AutoFolders(handle);
      }
   } else {
      FilesNode=_ProjectGet_FilesNode(handle,true);
      if (FilesNode>=0) {
         AutoFolders=_ProjectGet_AutoFolders(handle);
      }
   }

   if (!strieq(AutoFolders,VPJ_AUTOFOLDERS_CUSTOMVIEW)) {
      if (FilesNode<0) {
         FilesNode=_ProjectGet_FilesNode(handle,true);
      }
      int flags=VSXMLCFG_ADD_AS_CHILD;
      int count=NewFilesList._length();
      int Node=FilesNode;
      int i;
      for (i=0;i<count;++i) {
         Node=_xmlcfg_add(handle,Node,'F',VSXMLCFG_NODE_ELEMENT_START_END,flags);
         _str RelFilename=NewFilesList[i];
         FileToNode:[_file_case(RelFilename)]=Node;
         _xmlcfg_set_attribute(handle,Node,'N',_NormalizeFile(RelFilename));
         flags=VSXMLCFG_ADD_AFTER;

         // if this is an ant build file, set the Type attribute
         if(_IsAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Ant");
            // if this is an ant build file, set the Type attribute
         } else if(_IsNAntBuildFile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "NAnt");
         // if this is a makefile, set the Type attribute
         }else if(_IsMakefile(_AbsoluteToProject(RelFilename))) {
            _xmlcfg_set_attribute(handle, Node, "Type", "Makefile");
         }
      }
      if (doSort) {
         _ProjectAutoFolders(handle);

         // _ProjectAutoFolders() may rearrange the nodes when in package view, so
         // rebuild the FileToNode hash table.  yes this takes a little time,
         // but if a sort has been done then the time to do this is not going
         // to extend it much.
         if(strieq(AutoFolders,VPJ_AUTOFOLDERS_PACKAGEVIEW)) {
            _ProjectGet_FileToNodeHashTab(handle, FileToNode);
         }
      }
   } else {
      _ProjectAdd_FilteredFilesArray(handle,NewFilesList,FileToNode,ExtToNodeHashTab,doSort);
   }
}
void _ProjectGet_FileToNodeHashTab(int handle,int (&FileToNode):[])
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   typeless array[];
   FileToNode._makeempty();
   _xmlcfg_find_simple_array(handle,xmlv.vpjx_files"//"xmlv.vpjtag_f,array);
   int i,count=array._length();
   for (i=0;i<count;++i) {
      _str file=_xmlcfg_get_attribute(handle,array[i],xmlv.vpjattr_n);
      FileToNode:[_file_case(translate(file,FILESEP,FILESEP2))]=array[i];
   }
}

void _csprojGet_FileToNodeHashTab(int handle,_str AppName,int (&FileToNode):[])
{
   typeless array[];
   FileToNode._makeempty();
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/"AppName"/Files/Include/File",array);
   int i,count=array._length();
   for (i=0;i<count;++i) {
      _str file=_xmlcfg_get_attribute(handle,array[i],'RelPath');
      FileToNode:[_file_case(file)]=array[i];
   }
}

int _csproj2005Get_FileToNodeHashTab(int handle,int (&FileToNode):[])
{
   FileToNode._makeempty();
   int firstItemGroupWithFiles = -1;
   // First, get the list of all <ItemGroup>s
   typeless arrItemGroups;
   _xmlcfg_find_simple_array(handle, '/Project/ItemGroup', arrItemGroups);
   int groupIdx,numGroups = arrItemGroups._length();
   // Walk the list of item groups
   for (groupIdx=0;groupIdx<numGroups;++groupIdx)
   {
      // Walk the list of children underneath this ItemGroup
      int groupNode = (int)arrItemGroups[groupIdx];

      int childItem = _xmlcfg_get_first_child(handle, groupNode);
      while(childItem > 0)
      {
         // We'll skip Reference nodes
         _str childName = _xmlcfg_get_name(handle, childItem);
         if(childName != 'Reference')
         {
            _str file=_xmlcfg_get_attribute(handle,childItem,'Include');
            if(file != '')
            {
               if(firstItemGroupWithFiles < 0)
                  firstItemGroupWithFiles = groupNode;
               FileToNode:[_file_case(file)]=childItem;
            }
         }
         childItem = _xmlcfg_get_next_sibling(handle, childItem);
      }
   }

   return firstItemGroupWithFiles;
}

void _vcprojGet_FileToNodeHashTab(int handle,int (&FileToNode):[])
{
   typeless array[];
   FileToNode._makeempty();
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/Files//File",array);
   int i,count=array._length();
   for (i=0;i<count;++i) {
      _str file=_xmlcfg_get_attribute(handle,array[i],'RelativePath');
      FileToNode:[_file_case(file)]=array[i];
   }
}
int _vcprojGet_FilesNode(int handle,boolean forceCreate=false)
{
   if (forceCreate) {
      return(_xmlcfg_set_path(handle,"/VisualStudioProject/Files"));
   }
   return(_xmlcfg_find_simple(handle,"/VisualStudioProject/Files"));
}
void _vcprojGet_Folders(int handle,typeless (&array)[])
{
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/Files//Filter",array);
}
boolean _ProjectIs_vcproj(int handle)
{
   _str makefile=_ProjectGet_AssociatedFile(handle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) ||
          file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT) ) {
         return(true);
      }
   }
   return(false);
}
boolean _ProjectIs_vcxproj(int handle)
{
   _str makefile=_ProjectGet_AssociatedFile(handle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (file_eq(ext,VISUAL_STUDIO_VCX_PROJECT_EXT)) {
         return(true);
      }
   }
   return(false);
}
boolean _ProjectIs_jbuilder(int handle)
{
   _str makefile=_ProjectGet_AssociatedFile(handle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (file_eq(ext,JBUILDER_PROJECT_EXT)) {
         return(true);
      }
   }
   return(false);
}
boolean _ProjectIs_flash(int handle)
{
   _str makefile=_ProjectGet_AssociatedFile(handle);
   if (makefile!='') {
      _str ext=_get_extension(makefile,true);
      if (file_eq(ext,MACROMEDIA_FLASH_PROJECT_EXT)) {
         return(true);
      }
   }
   return(false);
}

boolean _ProjectIs_SupportedXMLVariation(int handle)
{
   if (_ProjectIs_vcproj(handle)) {
      return(true);
   } else if(_ProjectIs_jbuilder(handle)) {
      return(true);
   } else if (_ProjectIs_flash(handle)) {
      return(true);
   }
   return(false);
}
void _ProjectGet_XMLVariations(int handle,XMLVARIATIONS &xmlv)
{
   _str ext=_get_extension(_xmlcfg_get_filename(handle),true);
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT) || file_eq(ext,VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      xmlv.vpjx_files='/VisualStudioProject/Files';
      xmlv.vpjtag_folder='Filter';
      xmlv.vpjattr_folderName='Name';
      xmlv.vpjattr_filters='Filter';
      xmlv.vpjtag_f='File';
      xmlv.vpjattr_n='RelativePath';
      xmlv.doNormalizeFile=false;
      return;
   } else if(file_eq(ext, JBUILDER_PROJECT_EXT)) {
      xmlv.vpjx_files='/project';
      xmlv.vpjtag_folder=VPJTAG_FOLDER;//'node';
      xmlv.vpjattr_folderName='Name';//'name';
      xmlv.vpjattr_filters='';
      xmlv.vpjtag_f=VPJTAG_F;//'file';
      xmlv.vpjattr_n='N';//'path';
      xmlv.doNormalizeFile=true;
      return;
   } else if(file_eq(ext, MACROMEDIA_FLASH_PROJECT_EXT)) {
      xmlv.vpjx_files='/flash_project';
      xmlv.vpjtag_folder='project_folder';
      xmlv.vpjattr_folderName='name';
      xmlv.vpjattr_filters='';
      xmlv.vpjtag_f='project_file';
      xmlv.vpjattr_n='path';
      xmlv.doNormalizeFile=true;
      return;
   }
   xmlv.vpjtag_folder=VPJTAG_FOLDER;
   xmlv.vpjattr_folderName='Name';
   xmlv.vpjattr_filters='Filters';
   xmlv.vpjx_files=VPJX_FILES;
   xmlv.vpjtag_f=VPJTAG_F;
   xmlv.vpjattr_n='N';
   xmlv.doNormalizeFile=true;
}
void _ProjectSet_FolderFiltersAttr(int handle,int Node,_str filters)
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);
   if(xmlv.vpjattr_filters != "") {
      _str ext=_get_extension(_xmlcfg_get_filename(handle),true);
      if (filters=='*' || filters=='*.*') {
         filters='';
      }
      if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
         filters=stranslate(filters,'','*.');
      }
      _xmlcfg_set_attribute(handle,Node,xmlv.vpjattr_filters,filters);
   }
}
_str _ProjectGet_FolderFiltersAttr(int handle,int Node)
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);
   _str filters=_xmlcfg_get_attribute(handle,Node,xmlv.vpjattr_filters);

   _str ext=_get_extension(_xmlcfg_get_filename(handle),true);
   if (file_eq(ext,VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      _str result='';
      for (;;) {
         if (filters:=='') {
            break;
         }
         parse filters with ext ';' filters;
         if (ext!='') {
            if (result:=='') {
               result='*.'ext;
            } else {
               strappend(result,';*.'ext);
            }
         }
      }
      return(result);
   }
   return(filters);
}
void _ProjectGet_ObjectFileInfo(int handle,int (&ObjectInfo):[],_str (&ConfigInfo)[])
{
   ObjectInfo=null;
   ConfigInfo=null;

   if (!file_eq(_get_extension(_xmlcfg_get_filename(handle),true),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      return;
   }
   typeless array[];
   _xmlcfg_find_simple_array(handle,"VisualStudioProject/Files//File/FileConfiguration/Tool/@ObjectFile",array);
   int i;
   for (i=0;i<array._length();++i) {
      int index=_xmlcfg_get_parent(handle,_xmlcfg_get_parent(handle,array[i]));
      index=_xmlcfg_get_parent(handle,index);
      _str path=_xmlcfg_get_attribute(handle,index,"RelativePath");
      //_message_box('name='_xmlcfg_get_name(handle,index)' p='path);
      if (FileProducesVCPPObject(path)) {
         // If this is a file that produces a .obj file, we need to be
         // sure there is not a name collison.
         int cindex=array[i];
         //int cindex=_xmlcfg_get_first_child(handle,index);
         _str curfile=_strip_filename(path,'PE');
         _str val=_xmlcfg_get_value(handle,cindex);
         if (val!='') {
            typeless numinfo;
            parse val with '$(IntDir)/$(InputName)' numinfo '.obj';
            if (!ObjectInfo._indexin(curfile)) {
               ObjectInfo:[curfile]=numinfo;
            }else if (numinfo>ObjectInfo:[curfile]) {
               ObjectInfo:[curfile]=numinfo;
            }
         }
      }
   }
   typeless ConfigurationIndexes[]=null;
   // Get the tree indexes of Configurations
   _xmlcfg_find_simple_array(handle,"/VisualStudioProject/Configurations/Configuration",ConfigurationIndexes);

   for (i=0;i<ConfigurationIndexes._length();++i) {
      ConfigInfo[ConfigInfo._length()]=_xmlcfg_get_attribute(handle,ConfigurationIndexes[i],"Name");
   }
}
/**
 * Returns true if <B>filename</B> will produce a
 * VC++ obj file
 *
 * @param filename File to test
 *
 * @return
 *         Returns true if <B>filename</B> will produce a
 *         VC++ obj file
 */
static boolean FileProducesVCPPObject(_str filename)
{
   _str ext=_get_extension(filename);

   return(file_eq(ext,'c') ||
          file_eq(ext,'cpp') ||
          file_eq(ext,'cxx'));
}

void _ProjectSet_ObjectFileInfo(int handle,int (&ObjectInfo):[],_str (&ConfigInfo)[], int newindex,_str &RelFilename)
{
   if (!file_eq(_get_extension(_xmlcfg_get_filename(handle),true),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      return;
   }
   typeless array[];
   int i,j;
   if (FileProducesVCPPObject(RelFilename)) {
      _str just_curfilename=_strip_filename(RelFilename,'PE');
      if (ObjectInfo._indexin(just_curfilename)) {
         int DollarNum=ObjectInfo:[just_curfilename];
         ++DollarNum;
         for (j=0;j<ConfigInfo._length();++j) {
            int fc_index=_xmlcfg_find_simple(handle,"FileConfiguration":+XPATH_STRIEQ('Name',ConfigInfo[j]),newindex);
            if (fc_index<0) {
               fc_index=_xmlcfg_add(handle,newindex,"FileConfiguration",VSXMLCFG_ELEMENT_START,VSXMLCFG_ADD_AS_CHILD);
            }
            _xmlcfg_set_attribute(handle,fc_index,"Name",ConfigInfo[j]);
            int tool_index=_xmlcfg_find_simple(handle,"Tool",fc_index);
            if (tool_index<0) {
               tool_index=_xmlcfg_add(handle,fc_index,"Tool",VSXMLCFG_ELEMENT_END,VSXMLCFG_ADD_AS_CHILD);
            }
            _xmlcfg_set_attribute(handle,tool_index,"Name","VCCLCompilerTool");
            _xmlcfg_set_attribute(handle,tool_index,"ObjectFile","$(IntDir)/$(InputName)"DollarNum".obj");
         }
         ObjectInfo:[just_curfilename]=DollarNum;
      }else{
         int fc_index=_xmlcfg_find_simple_array(handle,"FileConfiguration/Tool",array,newindex);
         for (i=0;i<array._length();++i) {
            _xmlcfg_delete_attribute(handle,array[i],'ObjectFile');
         }

         ObjectInfo:[just_curfilename]=0;
      }
   }
}

/**
 * Check to see if at least one F tag exists in the config of
 * the specified project.  If no config is provided, check all
 * configs.
 *
 * @param handle Handle to project
 * @param config Name of config to check.  Blank implies any config.
 *
 * @return T if at least one F tag exists, F otherwise
 */
boolean _ProjectContains_Files(int handle, _str config = "")
{
   XMLVARIATIONS xmlv;
   _ProjectGet_XMLVariations(handle,xmlv);

   int node = 0;
   if(config != "") {
      node = _xmlcfg_find_simple(handle, xmlv.vpjx_files "//" xmlv.vpjtag_f "[contains(@C,'\"" config "\"','I')]");
   } else {
      node = _xmlcfg_find_simple(handle, xmlv.vpjx_files "//" xmlv.vpjtag_f);
   }

   // if node found, files exist in this project
   if(node >= 0) return true;

   // default to return false
   return false;
}

/**
 * Create a new project template in filename with targets initialized to
 * those passed in. This is a very simple api for adding a skeleton project
 * template programatically. If TemplateFilename does not exists, then it is
 * created by default. Set CreateIfNotExist to change this behavior. If the
 * template filename already exists, then it is updated. If the template being
 * created already exists, then it is replaced. Use the _xmlcfg_* api to create
 * more complex project templates. OEMs that need to know how to use the
 * _xmlcfg_* api to create/modify their own templates should start here.
 *
 * @param TemplateName   Name of new project template. If it already exists,
 *                       then it is replaced.
 * @param CompileCmdline Compile tool command line
 * @param BuildCmdline   Build tool command line (e.g. 'make')
 * @param RebuildCmdline Rebuild tool command line (e.g. 'make /A')
 * @param DebugCmdline   Debug tool command line
 * @param ExecuteCmdline Execute tool command line
 * @param ConfigName     Name of the configuration for target tool command
 *                       lines. Set to "Release" by default.
 * @param TemplateFilename Name of template file to create/update. By default
 *                         this is set to the user project template filename.
 * @param CreateFileIfNotExist true=Create template file if it does not already
 *                             exists; otherwise fail and return error. Default
 *                             is true.
 *
 * @return 0 on success, non-zero on error.
 */
int _ProjectTemplateCreate(_str TemplateName,_str CompileCmdline="",_str BuildCmdline="",_str RebuildCmdline="",_str DebugCmdline="",_str ExecuteCmdline="",_str ConfigName="Release",_str TemplateFilename=VSCFGFILE_USER_PRJTEMPLATES,boolean CreateFileIfNotExist=true)
{
   int status;
   int handle;
   int node;

   if( TemplateName=="" ) {
      return(INVALID_ARGUMENT_RC);
   }
   if( ConfigName=="" ) {
      return(INVALID_ARGUMENT_RC);
   }
   if( !file_exists(TemplateFilename) ) {
      if( !CreateFileIfNotExist ) {
         return(FILE_NOT_FOUND_RC);
      }
      // Create it
      handle=_xmlcfg_create(TemplateFilename,VSENCODING_UTF8);
      // add the doctype
      int doctypeNode = _xmlcfg_add(handle, TREE_ROOT_INDEX, "DOCTYPE", VSXMLCFG_NODE_DOCTYPE, VSXMLCFG_ADD_AS_CHILD);
      _xmlcfg_set_attribute(handle, doctypeNode, "root", VPTTAG_TEMPLATES);
      _xmlcfg_set_attribute(handle, doctypeNode, "SYSTEM", VPT_DTD_PATH);
      _xmlcfg_set_path(handle,VPTX_TEMPLATES,'Version',VPT_FILE_VERSION);
      _xmlcfg_set_path(handle,VPTX_TEMPLATES,'VendorName','SlickEdit');
   } else {
      // Open existing
      handle=_xmlcfg_open(TemplateFilename,status);
   }
   if( handle<0 ) {
      // Error
      return(handle);
   }
   _xmlcfg_set_path(handle,VPTX_TEMPLATE,'Name',TemplateName);
   _xmlcfg_set_path(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG,'Name',ConfigName);
   _xmlcfg_set_path(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU);

   // Targets
   //
   // Target: Compile
   node=_xmlcfg_set_path2(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU,VPJTAG_TARGET,'Name','Compile');
   _xmlcfg_add_attribute(handle,node,'MenuCaption','&Compile');
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveCurrent');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if( CompileCmdline!="" ) {
      _xmlcfg_add_attribute(handle,node,'Cmdline',CompileCmdline);
   }
   // Target: Build
   node=_xmlcfg_set_path2(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU,VPJTAG_TARGET,'Name','Build');
   _xmlcfg_add_attribute(handle,node,'MenuCaption','&Build');
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveWorkspaceFiles');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if( BuildCmdline!="" ) {
      _xmlcfg_add_attribute(handle,node,'Cmdline',CompileCmdline);
   }
   // Target: Rebuild
   node=_xmlcfg_set_path2(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU,VPJTAG_TARGET,'Name','Rebuild');
   _xmlcfg_add_attribute(handle,node,'MenuCaption','&Rebuild');
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveWorkspaceFiles');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if( RebuildCmdline!="" ) {
      _xmlcfg_add_attribute(handle,node,'Cmdline',CompileCmdline);
   }
   // Target: Debug
   node=_xmlcfg_set_path2(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU,VPJTAG_TARGET,'Name','Debug');
   _xmlcfg_add_attribute(handle,node,'MenuCaption','&Debug');
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveNone');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if( DebugCmdline!="" ) {
      _xmlcfg_add_attribute(handle,node,'Cmdline',CompileCmdline);
   }
   // Target: Execute
   node=_xmlcfg_set_path2(handle,VPTX_TEMPLATE"/"VPJTAG_CONFIG"/"VPJTAG_MENU,VPJTAG_TARGET,'Name','Execute');
   _xmlcfg_add_attribute(handle,node,'MenuCaption','E&xecute');
   _xmlcfg_add_attribute(handle,node,'CaptureOutputWith','ProcessBuffer');
   _xmlcfg_add_attribute(handle,node,'SaveOption','SaveNone');
   _xmlcfg_add_attribute(handle,node,'RunFromDir','%rw');
   node=_xmlcfg_add(handle,node,VPJTAG_EXEC,VSXMLCFG_NODE_ELEMENT_START_END,VSXMLCFG_ADD_AS_CHILD);
   if( ExecuteCmdline!="" ) {
      _xmlcfg_add_attribute(handle,node,'Cmdline',CompileCmdline);
   }

   status=_xmlcfg_save(handle,-1,VSXMLCFG_SAVE_ONE_LINE_IF_ONE_ATTR);
   _xmlcfg_close(handle);
   return(status);
}

/**
 * Get the project filename from its handle
 *
 * @param handle Handle to the project
 *
 * @return Filename of the project
 */
_str _ProjectGet_Filename(int handle)
{
   return _xmlcfg_get_filename(handle);
}

/**
 * cache of the latest compiler found on the users machine
 */
static _str gLatestCompiler='not found';

/**
 * cache of the latest compiler found on the users machine
 */
static _str gLatestJDK='not found';

/**
 * similar to {@link get_version} but only compares version numbers without checking
 * the compiler name
 *
 * @param   version     the version number to check
 * @param   major       the major version number of the latest version. Set to zero before calling the first time
 * @param   minor       the minor version number of the latest version. Set to zero before calling the first time
 * @param   sub         the sub-minor or build number of the latest version. Set to zero before calling the first time
 * @param   foundUsrBin set to true if a compiler was found in /usr/bin which is always considered
 *                      to be the latest version.  Set to false before calling the first time
 * @return  true if version was set as the latest version
 */
static boolean CheckLatest(_str version,int &major,int &minor,int &sub,boolean &foundUsrBin)
{
   if (foundUsrBin) {
      return false;
   }

   if (version=='') {
      foundUsrBin=true;
      return true;
   }

   typeless cmajor;
   typeless cminor;
   typeless csub;
   parse version with cmajor '.' cminor '.' csub .;
   makeints(cmajor,cminor,csub);

   if ( (major>cmajor) ||
        (
            (major==cmajor) &&
            (
               (minor>cminor) ||
               (
                  (minor==cminor) &&
                  (sub>=csub)
               )
            )
        )
      )
   {
      return false;
   }

   major=cmajor;
   minor=cminor;
   sub=csub;
   return true;
}

/**
 * similar to {@link get_version} but only compares version numbers without checking
 * the compiler name
 *
 * @param   version     the version number to check
 * @param   major       the major version number of the latest version. Set to zero
 *                      before calling the first time
 * @param   minor       the minor version number of the latest version. Set to zero
 *                      before calling the first time
 * @param   sub         the sub-minor the latest version. Set to
 *                      zero before calling the first time
 * @param   subsub      the sub-sub-minor of the latest version.
 *                      Set to zero before calling the first time
 * @return  true if version was set as the latest version
 */
static boolean CheckLatestJDK(_str version,int &major,int &minor,int &sub, int& subsub){
   int cmajor = isinteger(substr(version, 1, 1)) ? (int)(substr(version, 1, 1)): 0;
   int cminor = isinteger(substr(version, 3, 1)) ? (int)(substr(version, 3, 1)): 0;
   int csub= isinteger(substr(version, 5, 1)) ? (int)(substr(version, 5, 1)): 0;
   int csubsub = isinteger(substr(version, 7, 2)) ? (int)substr(version,7,2):
                                 isinteger(substr(version,8,1)) ? (int)substr(version,8,1) : 0;
   if ( (major>cmajor) ||
        (
            (major==cmajor) &&
            (
               (minor>cminor) ||
               (
                  (minor==cminor) &&
                  (
                     (sub > csub) ||
                        (subsub >= csubsub)
                  )
               )
            )
        )
      )
   {
      return false;
   }
   major=cmajor;
   minor=cminor;
   sub=csub;
   subsub=csubsub;
   return true;
}
/**  finds the name of the latest compiler avaible to the user
 *
 * @param checkAll this function keeps a cache of the latest
 * compiler, when checkAll is true, the cache is ingored
 * and all compilers are scanned again.
 *
 * @return  the name of the latest compiler avaible to the user
 */
_str _GetLatestCompiler(boolean checkAll=false)
{
   if ((checkAll)||(gLatestCompiler=='not found'||(gLatestCompiler==''))) {
      _str version;
      int major=0;
      int minor=0;
      int sub=0;
      boolean foundUsrBin=false;

      gLatestCompiler='';

      available_compilers compilers;
      _str c_compiler_names[];
      _str java_compiler_names[];
      refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);
      _evaluate_compilers(compilers,c_compiler_names);

      if (compilers.latestCygwin!='') {
         parse compilers.latestCygwin with '-' version '-';
         if (CheckLatest(version,major,minor,sub,foundUsrBin)) {
            gLatestCompiler=compilers.latestCygwin;
         }
      }
      if (compilers.latestGCC!='') {
         parse compilers.latestGCC with '-' version '-';
         if (CheckLatest(version,major,minor,sub,foundUsrBin)) {
            gLatestCompiler=compilers.latestGCC;
         }
      }
      if (compilers.latestCC!='') {
         parse compilers.latestCC with '-' version '-';
         if (CheckLatest(version,major,minor,sub,foundUsrBin)) {
            gLatestCompiler=compilers.latestCC;
         }
      }
      if (compilers.latestLCC!='') {
         parse compilers.latestLCC with '-' version '-';
         if (CheckLatest(version,major,minor,sub,foundUsrBin)) {
            gLatestCompiler=compilers.latestLCC;
         }
      }
   }

   return gLatestCompiler;
}

/**  finds the name of the latest Sun JDK available to the user
 *
 * @param checkAll this function keeps a cache of the latest
 * compiler, when checkAll is true, the cache is ingored
 * and all compilers are scanned again.
 *
 * @return  the name of the latest compiler avaible to the user
 */
_str _GetLatestJDK(boolean checkAll=false)
{
   if ((checkAll)||(gLatestJDK=='not found')||(gLatestJDK=='')) {
      gLatestJDK='';

      _str c_compiler_names[];
      _str java_compiler_names[];
      refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);
      int i = 0;
      int max_major = 0, max_minor = 0, max_sub = 0, max_subsub= 0;
      for (i; i < java_compiler_names._length(); i++) {
         _str name = java_compiler_names[i];
         if (pos(COMPILER_NAME_SUN, name) > 0) {
            _str version = '';
            parse name with COMPILER_NAME_SUN " " version;
            if (CheckLatestJDK(version, max_major, max_minor, max_sub, max_subsub)) {
               gLatestJDK=name;
            }
         }
      }
   }
   return gLatestJDK;
}
/**
 * Determines the compiler config to use
 *
 * This could be different from what is stored in the prject file
 * in three cases:
 *
 * <ol type=1>
 *    <li>The file lists the CompilerConfigName as 'Latest Version'</li>
 *    <li>The file lists the CompilerConfigName as 'Default Compiler'</li>
 *    <li>The user does not have the compiler listed in the project file installed</li>
 * </ol>
 *
 * @param   handle   the project handle to use
 * @param   config   the name of the configuration to check
 *
 * @return  the name of the compiler that should be used for the specified configuration
 */
_str _ProjectGet_ActualCompilerConfigName(int handle,_str config=gActiveConfigName)
{
   _str compiler_config = _ProjectGet_CompilerConfigName(handle,config);
   _str project_type = _ProjectGet_Type(handle, config);
   if (project_type :!= "java") {
      if (compiler_config:==COMPILER_NAME_LATEST) {
         return _GetLatestCompiler();
      } else if (compiler_config:==COMPILER_NAME_DEFAULT) {
         return def_refactor_active_config;
      } else if (compiler_config=='') {
         return compiler_config;
      }
   } else {
      if (compiler_config:==COMPILER_NAME_LATEST) {
         return _GetLatestJDK();
      } else if (compiler_config:==COMPILER_NAME_DEFAULT) {
         return def_active_java_config;
      } else if (compiler_config=='') {
         return compiler_config;
      }
   }

   // check if the user has the listed compiler
   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;

   refactor_config_open( filename );

   if( refactor_config_count() <= 0 ) {
      generate_default_configs();
   }

   _str compiler_name='';
   int i,n = refactor_config_count();
   for (i=0; i<n; ++i) {
      refactor_config_get_name(i, compiler_name);
      if (compiler_name:==compiler_config) {
         return compiler_name;
      }
   }

   // user does not have the compiler, if it has a version number
   // try to match that
   parse compiler_config with '-' version '-';

   if (version!='') {
      typeless major;
      typeless minor;
      typeless sub;
      parse version with major '.' minor '.' sub .;
      makeints(major,minor,sub);

      for (i=0; i<n; ++i) {
         refactor_config_get_name(i, compiler_name);
         parse compiler_name with '-' version '-';
         if (version!='') {
            typeless cmajor;
            typeless cminor;
            typeless csub;
            parse version with cmajor '.' cminor '.' csub .;
            makeints(cmajor,cminor,csub);
            if ((cmajor==major)&&(cminor==minor)) {
               return compiler_name;
            }
         }
      }
   }

   // couldn't match a compiler with the same version number
   // just get the latest
   if (project_type :!= "java") {
      return _GetLatestCompiler();
   } else {
      return _GetLatestJDK();
   }
}

_str _ProjectGet_CompilerConfigName(int handle, _str config=gActiveConfigName)
{
   // try to handle the extension specific projects
   if (config=='') {
      int editorctl_wid=p_window_id;
      if (!_isEditorCtl()) {
         if (_no_child_windows()) {
            // code lifted from project.e, this shouldn't happen here
//            _message_box(nls("There must be a window to set up extension specific project information."));
            return '';
         }
         editorctl_wid=_mdi.p_child;
      }
      config='.'editorctl_wid.p_LangId;
   }
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return("");
   }
   return _xmlcfg_get_attribute(handle,Node,'CompilerConfigName','');
}

void _ProjectSet_CompilerConfigName(int handle, _str value,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return;
   }
   _xmlcfg_set_attribute(handle,Node,'CompilerConfigName',value);
}

_str _ProjectGet_Defines(int handle, _str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return("");
   }
   return _xmlcfg_get_attribute(handle,Node,'Defines','');
}

void _ProjectSet_Defines(int handle, _str value,_str config=gActiveConfigName)
{
   int Node=_xmlcfg_find_simple(handle,VPJX_CONFIG"[strieq(@Name,'"config"')]");
   if (Node<0) {
      return;
   }
   _xmlcfg_set_attribute(handle,Node,'Defines',value);
}

/**
 * Extract a string of #defines and #undefs from the compile
 * command of the active configuration
 *
 * @param filename Filename to retrieve deflist for
 * @param handle   Project handle
 * @param config   Configuration name
 *
 * @return Space-delimited list of -D and -U options
 */
_str _ProjectGet_DefinesFromCompileCommand(_str filename, int handle, _str config)
{
   _str defines = "";

   // get the compile command
   _str compileCommand = "";
   if(!getExtSpecificCompileInfo(filename, handle, config, compileCommand)) {
      // parse any %vars
      compileCommand = _parse_project_command(compileCommand, filename, _ProjectGet_Filename(handle), "");

      _str parameter = parse_next_option(compileCommand);
      while(parameter != "") {
         // check for other supported parameters
         _str prefix = substr(parameter, 1, 2);
         if(prefix == "-D" || prefix == "/D" || prefix == "-U" || prefix == "/U") {
            // extract the define following the -D
            if(defines == "") {
               defines = parameter;
            } else {
               defines = defines " " parameter;
            }
         }

         // get the next parameter
         parameter = parse_next_option(compileCommand);
      }
   }

   return defines;
}

/**
 * combines a string of defines and a string of defines into a single string
 *
 * @param   defines     the defines.  Each define is prefixed with /D
 * @param   undefines   the undefines.  Each undefine is prefixed with /U
 * @param   commaDelim  allow commas to separate the defines and undefines.
 *                      by default only semi-colons are used
 *
 * @return  the concatination of the defines and undefines with their prefixes
 */
static _str build_defines_string(_str defines,_str undefines,boolean commaDelim)
{
   _str output='';
   _str define;
   _str undef;

   // handle the defines
   while (defines!='') {
      if (commaDelim) {
         parse defines with define '[;,]','r' defines;
      } else {
         parse defines with define ';' defines;
      }
      if (output!='') {
         strappend(output,' ');
      }
      strappend(output,'/D');
      strappend(output,define);
   }

   // and do the undefines
   while (undefines!='') {
      if (commaDelim) {
         parse undefines with undef '[;,]','r' undefines;
      } else {
         parse undefines with undef ';' undefines;
      }
      if (output!='') {
         strappend(output,' ');
      }
      strappend(output,'/U');
      strappend(output,undef);
   }

   return output;
}

void GetVCPPToolInfo(int handle,int CurConfigIndex,_str ToolName,_str (&OptionValues):[])
{
   int ChildIndex=_xmlcfg_get_first_child(handle,CurConfigIndex);
   for (;ChildIndex>=0;) {
      _str CurTagName='',CurToolName='';
      CurTagName=_xmlcfg_get_name(handle,ChildIndex);
      if (CurTagName=='Tool') {
         CurToolName=_xmlcfg_get_attribute(handle,ChildIndex,"Name");
         if (CurToolName==ToolName) {
            int NodeIndex=ChildIndex;
            for (;;) {
               NodeIndex=_xmlcfg_get_next_attribute(handle,NodeIndex);
               if (NodeIndex<0) {
                  break;
               }
               _str CurOptionName;
               _str CurOptionVal;
               CurOptionName=_xmlcfg_get_name(handle,NodeIndex);
               CurOptionVal=_xmlcfg_get_value(handle,NodeIndex);
               if (CurOptionVal!=null) {
                  OptionValues:[CurOptionName]=CurOptionVal;
               }
            }
            break;
         }
      }
      ChildIndex=_xmlcfg_get_next_sibling(handle,ChildIndex);
   }
}

int GetVCPPPropertySheetsOptions(_str filename, _str (&OptionValues):[])
{
   int status=0;
   int handle=_xmlcfg_open(filename, status);
   if (handle<0) {
      return(status);
   }
   int index=_xmlcfg_find_child_with_name(handle,TREE_ROOT_INDEX,"VisualStudioPropertySheet");
   if (index<0) {
      _xmlcfg_close(handle);
      return(1);
   }
   GetVCPPToolInfo(handle, index, "VCCLCompilerTool", OptionValues);
   if (status) {
      _xmlcfg_close(handle);
      return(status);
   }
   _xmlcfg_close(handle);
   return(0);
}

/**
 * Extracts defines and undefines from a Visual Studio .NET or .NET 2003 project file
 *
 * @param   filename       the file in the project for which to get the defines and undefines.
 *                         Set to '' for project level defines
 * @param   handle         the project handle to the project file (.vpj or .vcproj)
 * @param   config         the configuration name for which to get the defines and undefines
 * @param   assoc_file     the name of the .NET project file as stored in the project file (.vpj)
 *                         This is only needed if handle is a .vpj handle
 * @param   expand_aliases if true, any visual studio macros will be expanded
 *
 * @return  all defines and undefines that should be used when compiling the file in the project
 */
static _str GetNETDefines(_str filename, int handle, _str config, _str assoc_file, boolean expand_aliases)
{
   _str defines='';
   _str output='';
   int recurseLimit=32;
   int cfgNode=-1;
   int toolNode=-1;
   int status;
   int vPrjHandle=handle;
   _str vFileName=_xmlcfg_get_filename(vPrjHandle);
   boolean closeFile=false;
   if (!file_eq(_get_extension(vFileName,true),VISUAL_STUDIO_VCPP_PROJECT_EXT)) {
      _str prjFileName=_ProjectGet_Filename(handle);
      vFileName=_strip_filename(prjFileName,'N'):+assoc_file;
      vPrjHandle=_xmlcfg_open(vFileName,status);
      closeFile=true;
      if (status) {
         return '';
      }
   }

   // don't assume the compiler config name is set correctly
   _str version=COMPILER_NAME_VSDOTNET;
   _str dotNetVersion=_xmlcfg_get_path(vPrjHandle,'VisualStudioProject','Version');
   if (dotNetVersion:=='7.10') {
      version=COMPILER_NAME_VS2003;
   } else if (dotNetVersion:=='8.00') {
      version=COMPILER_NAME_VS2005;
   } else if (dotNetVersion:=='9.00') {
      version=COMPILER_NAME_VS2008;
   } else if (dotNetVersion:=='10.00') {
      version=COMPILER_NAME_VS2010;
   }

   if (filename!='') {
      _str projectDir=_strip_filename(vFileName,'N');
      _str relFileName=relative(filename,projectDir);
      relFileName=ConvertToVCPPRelFilename(relFileName,projectDir);
      int pathNode=_xmlcfg_find_simple(vPrjHandle,"//File/@RelativePath[file-eq(.,'"relFileName"')]");
      if (pathNode>=0) {
         int fileNode=_xmlcfg_get_parent(vPrjHandle,pathNode);

         cfgNode=_xmlcfg_find_simple(vPrjHandle,"FileConfiguration[@Name='"config"']",fileNode);
      }
   } else {
      cfgNode=_xmlcfg_find_simple(vPrjHandle,"//Configuration[@Name='"config"']");
   }

   _str charset='';

   if (cfgNode>=0) {
      charset=_xmlcfg_get_attribute(vPrjHandle,cfgNode,'CharacterSet');
      defines = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCCLCompilerTool','PreprocessorDefinitions');
      _str undefines = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCCLCompilerTool','UndefinePreprocessorDefinitions');
      defines=build_defines_string(defines,undefines,true);
   }

   // always look for $(Inherit) and $(NoInherit)
   // maybe expand any other macros
   boolean ignoreProject=false;

   while (defines!='') {
      _str in_define=parse_next_option(defines,false);
      _str out_define='';
      while (in_define!='') {
         _str leading;
         _str macro;
         parse in_define with leading '$(' macro ')' in_define;
         strappend(out_define,leading);
         if (macro!='') {
            // always set markInherits so that the leading /D or /U can be
            // removed as well
            _str expanded_macro=_expand_vs_macro(version,macro,vPrjHandle,cfgNode,filename,true);
            if (substr(expanded_macro,1,3):=='$$(') {
               // order of defines is inconsequental so $(Inherit) is ignored
               if (substr(expanded_macro,4,1):=='N') {
                  ignoreProject=true;
               }
               // don't actually append anything
               out_define='';
               // stop parsing
               in_define='';
            } else {
               if (expand_aliases) {
                  in_define=expanded_macro:+in_define;
               } else {
                  strappend(out_define, '$('macro')');
               }
            }
         }
      }
      // if this was not a INHERIT or NOINHERIT
      if (out_define!='') {
         if (output!='') {
            strappend(output,' ');
         }
         strappend(output, '"'out_define'"');
      }
   }
   if (closeFile) {
      _xmlcfg_close(vPrjHandle);
   }

   if (!ignoreProject) {
      _str projectDefines='';
      if (filename:=='') {
         if (charset:=='1') {
            projectDefines='/D_UNICODE /DUNICODE';
         }else if (charset:=='2') {
            projectDefines='/D_MBCS';
         }
      } else {
         projectDefines=GetNETDefines('',handle,config,assoc_file,expand_aliases);
      }
      if (output!='') {
         strappend(output,' ');
      }
      strappend(output,projectDefines);
   }

   return output;
}

/**
 * Extracts defines and undefines from a Visual C++ 6 project file
 *
 * @param   filename    the file in the project for which to get the defines and undefines.
 *                      Set to '' for project level defines
 * @param   handle      the project handle to the project file (.vpj)
 * @param   config      the configuration name for which to get the defines and undefines
 * @param   assoc_file  the name of the VC6 project file as stored in the project file (.vpj)
 *
 * @return  all defines and undefines that should be used when compiling the file in the project
 */
static _str GetVC6Defines(_str filename, int handle, _str config, _str assoc_file)
{
   _str prjFileName=_ProjectGet_Filename(handle);
   _str vFileName=_strip_filename(prjFileName,'N'):+assoc_file;
   int temp_view_id;
   int orig_view_id;
   _open_temp_view(vFileName,temp_view_id,orig_view_id);
   activate_window(temp_view_id);

   _str file_includes;
   _str file_defines;
   boolean ignoreProjectIncludes;
   boolean ignoreProjectDefines;
   _str otherOptions;
   parse_vs6_project(file_includes,file_defines,config,ignoreProjectIncludes,ignoreProjectDefines,otherOptions,filename);

   if ((filename!='')&&(!ignoreProjectDefines)) {
      _str project_includes;
      _str project_defines;
      parse_vs6_project(project_includes,project_defines,config,ignoreProjectIncludes,ignoreProjectDefines,otherOptions,'');
      if (file_defines!='') {
         strappend(file_defines,' ');
      }
      strappend(file_defines,project_defines);
   }

   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   return file_defines;
}

/**
 * Gets all defines and undefines for any project that is associated with either a Visual C++ 6
 * or Visual Studio .NET project
 *
 * @param   filename    the file in the project for which to get the defines and undefines.
 *                      Set to '' for project level defines
 * @param   handle      the project handle to the project file (.vpj)
 * @param   config      the configuration name for which to get the defines and undefines
 * @param   assoc_file  the name of the associated project file as stored in the project file (.vpj)
 *
 * @return  all defines and undefines that should be used when compiling the file in the project
 */
_str _ProjectGet_AssociatedDefines(_str filename, int handle, _str config, _str assoc_file, boolean expand_aliases)
{
   _str assoc_ext = _get_extension(assoc_file, true);
   if (file_eq(assoc_ext, VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      assoc_file = getICProjAssociatedProjectFile(assoc_file);
      assoc_ext = _get_extension(assoc_file, true);
   }
   if (assoc_ext:==VISUAL_STUDIO_VCPP_PROJECT_EXT) {
      return GetNETDefines(filename, handle, config, assoc_file, expand_aliases);
   } else if (assoc_ext:==VCPP_PROJECT_FILE_EXT) {
      return GetVC6Defines(filename, handle, config, assoc_file);
   }
   return '';
}

/**
 * Get all the project defines for this file, including
 * the defines set up in "Project Properties..." -> "Directories",
 * and the defines set in their command line.
 */
_str _ProjectGet_AllDefines(_str filename, int handle, _str config)
{
   _str all_defines='';

   _str assoc_file = _ProjectGet_AssociatedFile(handle);
   if (assoc_file!='') {
      all_defines = _ProjectGet_AssociatedDefines(filename,handle,config,assoc_file,true);
   } else {
      // get the #defines from the command line
      all_defines = _ProjectGet_DefinesFromCompileCommand(filename, handle, config);
   }

   // now get the defines from the configuration
   strappend(all_defines, ' ');
   strappend(all_defines, _ProjectGet_Defines(handle, config));

   all_defines = strip(all_defines);

   // now remove duplicates
   _str return_defines = '';
   _str found_defines:[];  found_defines._makeempty();
   _str cpp_define = parse_next_option(all_defines, false);
   while (cpp_define != '') {
      if (!found_defines._indexin(cpp_define)) {
         if (return_defines!='') strappend(return_defines, ' ');
         strappend(return_defines,  '"'cpp_define'"');
         found_defines:[cpp_define]='';
      }
      cpp_define = parse_next_option(all_defines, false);
   }

   // finally, return the result
   return return_defines;
}

/**
 * Gets the include directories from the refactoring compiler configuration for
 * the project
 *
 * @param   handle      the project handle
 * @param   config      the configuration name to check
 *
 * @return the include directories as a PATHSEP delimited string
 */
_str _ProjectGet_SystemIncludes(int handle, _str config=gActiveConfigName)
{
   _str compiler_name=_ProjectGet_ActualCompilerConfigName(handle,config);

   _str sys_includes='';
   refactor_config_open(_ConfigPath():+COMPILER_CONFIG_FILENAME);
   int num_includes=refactor_config_count_includes(compiler_name);

   int k;
   for(k=0;k<num_includes;++k) {
      _str include_string='';
      refactor_config_get_include(compiler_name,k,include_string);
      if (include_string!='') {  // sometimes refactor_config_get_include returns empty strings
         if(sys_includes!='') {
            strappend(sys_includes,PATHSEP);
         }
         strappend(sys_includes,include_string);
      }
   }
   refactor_config_close();

   return sys_includes;
}

/**
 * Gets the compiler header file for refactoring based on the compiler
 * configuration in the project
 *
 * @param   handle      the project handle
 * @param   config      the configuration name to check
 *
 * @return the name of the system header file
 */
_str _ProjectGet_SystemHeader(int handle, _str config=gActiveConfigName)
{
   _str compiler_name=_ProjectGet_ActualCompilerConfigName(handle,config);

   _str sys_header='';

   _str filename=_ConfigPath():+COMPILER_CONFIG_FILENAME;
   refactor_config_open( filename );

   if(refactor_config_get_header(compiler_name,sys_header)){
      sys_header='';
   }
   refactor_config_close();

   return sys_header;
}

/**
 * used by {@link expand_vs_macro} for some macros.
 *
 * @return  the name of the solution file
 */
static _str getSolutionFileName()
{
   // while there is no guarantee that the associated project is in the appropriate
   // associated workspace and that the workspace is open, but there isn't much else
   // that can be done here
   if (_workspace_filename!="") {
      // workspace already cached
      return _AbsoluteToWorkspace(_WorkspaceGet_AssociatedFile(gWorkspaceHandle));
   }
   return '';
}

static _str getVCXProjGlobalPropertyGroup(int projectHandle, _str item) 
{
   _str retVal = '';
   _str queryString = '/Project/PropertyGroup[@Label="Globals"]/'item;
   // try to find the value in the normal project file
   int index = _xmlcfg_find_simple(projectHandle, queryString);
   if (index >= 0) {
      int data = _xmlcfg_get_first_child(projectHandle, index, VSXMLCFG_NODE_PCDATA);
      if (data >= 0) {
         retVal = _xmlcfg_get_value(projectHandle, data);
         if (retVal != '') {
            return retVal;
         }
      }
   }
   // if we found nothing, return nothing
   return '';
}

static _str getVCXProjPropertyGroup(int projectHandle, _str config, _str item) 
{
   _str retVal = '';
   int index = _xmlcfg_find_simple(projectHandle, "/Project/PropertyGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]/"item);
   if (index >= 0) {
      int data = _xmlcfg_get_first_child(projectHandle, index, VSXMLCFG_NODE_PCDATA);
      if (data >= 0) {
         retVal = _xmlcfg_get_value(projectHandle, data);
         if (retVal != '') {
            return retVal;
         }
      }
   }
   // if we found nothing, so see if there's a property sheet for this value
   return getVCXProjPropertySheetValue(projectHandle, config, item);
}

/**
 * Looks for any associated property pages to see if they have 
 * the configuration value we are looking for. 
 */
static _str getVCXProjPropertySheetValue(int projectHandle, _str config, _str item) 
{
   _str retVal = '';
   int propGroupIndex = _xmlcfg_find_simple(projectHandle, "/Project/PropertyGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"][@Label='Configuration']");
   int propConfigIndex = _xmlcfg_find_simple(projectHandle, "/Project/ItemGroup/ProjectConfiguration[@Include=\""config"\"]");
   int importGroupIndex = _xmlcfg_find_simple(projectHandle, "/Project/ImportGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"][@Label='PropertySheets']");
   if (importGroupIndex >= 0) {
      _str importIndexes[];
      int status = _xmlcfg_find_simple_array(projectHandle, "Import", importIndexes, importGroupIndex);
      if (status == 0) {
         int i = 0;
         for (i = 0; i < importIndexes._length(); i++) {
            int importNode = (int)importIndexes[i];
            _str importProjectVal = _xmlcfg_get_attribute(projectHandle, importNode, 'Project', '');
            _str propSheetFilename = _expand_all_vs_macros(COMPILER_NAME_VS2010, importProjectVal, projectHandle, propConfigIndex);
            if (file_exists(propSheetFilename)) {
               int propSheetHandle = _xmlcfg_open(propSheetFilename, status, VSXMLCFG_OPEN_ADD_PCDATA);
               _str value = getVCXProjPropertySheetConfiguration(propSheetHandle, item);
               if (value != '') {
                  retVal = _expand_all_vs_macros(COMPILER_NAME_VS2010, value, projectHandle, propConfigIndex);
                  return retVal;
               }
            }
         }
      }
   }
   return '';
}

static _str getVCXProjPropertyGroupConfiguration(int projectHandle, _str config, _str item) 
{
   _str retVal = '';
   int groupIndex = _xmlcfg_find_simple(projectHandle, "/Project/PropertyGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"][@Label='Configuration']");
   if (groupIndex >= 0) {
      int index = _xmlcfg_find_simple(projectHandle, item, groupIndex);
      if (index >= 0) {
         int data = _xmlcfg_get_first_child(projectHandle, index, VSXMLCFG_NODE_PCDATA);
         if (data >= 0) {
             retVal = _xmlcfg_get_value(projectHandle, data);
             if (retVal != '') {
                return retVal;
             }
         }
      }
   }
   // if we found nothing, so see if there's a property sheet for this value
   return getVCXProjPropertySheetValue(projectHandle, config, item);
}

/**
 * Gets a specific value out of a VS2010 vcxproj property sheet 
 * that is loaded with handle 'projectHandle' 
 */
static _str getVCXProjPropertySheetConfiguration(int projectHandle, _str item) 
{
   typeless array[] = null;
   _xmlcfg_find_simple_array(projectHandle, "/Project/PropertyGroup", array);

   int i;
   for(i = 0; i < array._length(); i++) {
      int groupIndex = array[i];
      if (groupIndex < 0) {
         continue;
      }
      int index = _xmlcfg_find_simple(projectHandle, item, groupIndex);
      if (index < 0) {
         continue;
      }
      int data = _xmlcfg_get_first_child(projectHandle, index, VSXMLCFG_NODE_PCDATA);
      if (data < 0) {
         continue;
      }
      return _xmlcfg_get_value(projectHandle, data);
   }
   return '';
}

static _str getVCXProjItemDefinitionGroup(int projectHandle, _str config, _str item) 
{
   _str retVal = '';
   int itemGroup = _xmlcfg_find_simple(projectHandle, "/Project/ItemDefinitionGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]");
   if (itemGroup >= 0) {
      int index = _xmlcfg_find_simple(projectHandle, item, itemGroup);
      if (index >= 0) {
         int data = _xmlcfg_get_first_child(projectHandle, index, VSXMLCFG_NODE_PCDATA);
         if (data < 0) {
            retVal = _xmlcfg_get_value(projectHandle, data);
            if (retVal != '') {
               return retVal;
            }
         }
      }
   }
   return '';
}

_str getICProjAssociatedProjectFile(_str projectName)
{
   int status;
   int handle=_xmlcfg_open(projectName, status);
   if (handle < 0) {
      return '';
   }
   vcprojName := '';
   node := _xmlcfg_find_simple(handle, '/VisualStudioProject');
   if (node > 0) {
      vcprojName = _xmlcfg_get_attribute(handle, node, 'VCNestedProjectFileName');
   }
   _xmlcfg_close(handle);
   return vcprojName;
}

/**
 * used by {@link expand_vs_macro} for some macros
 *
 * @param   vPrjHandle     handle to the Visual Studio project file opened by {@link _xmlcfg_open}
 * @param   inputFileName  the name of the file for which the macro is being evaluated
 * @param   fileSpecified  set to true for a source file, false for the project file
 *
 * @return  The name of the immediate parent of the file in the file view of the
 *          Visual Studio project.  If the file is not in a folder the project
 *          name is returned
 */
static _str getParentName(int vPrjHandle, _str inputFileName, boolean fileSpecified)
{
   if (fileSpecified) {
      // individual file, find out what folder, if any it is in
      _str projectDir=_strip_filename(_xmlcfg_get_filename(vPrjHandle),'N');
      _str relFileName=relative(inputFileName,projectDir);
      relFileName=ConvertToVCPPRelFilename(relFileName,projectDir);
      int node=_xmlcfg_find_simple(vPrjHandle,"//File/@RelativePath[file-eq(.,'"relFileName"')]");
      while (node>=0) {
         if (_xmlcfg_get_name(vPrjHandle,node)=='Filter') {
            return _xmlcfg_get_attribute(vPrjHandle,node,'Name');
         }
         node=_xmlcfg_get_parent(vPrjHandle,node);
      }
   }

   // project file (or file node not found or file not in a folder), use the project name
   return _xmlcfg_get_path(vPrjHandle,'VisualStudioProject','Name');
}

/**
 * used by {@link expand_vs_macro} for some macros<br>
 * <br>
 * this function can call back into expand_vs_macros
 *
 * @param   studio_version set to COMPILER_NAME_VSDOTNET or COMPILER_NAME_VS2003
 * @param   vPrjHandle     handle to the Visual Studio project file opened by {@link _xmlcfg_open}
 * @param   cfgNode        the index of the project configuration node
 * @param   inputFileName  the name of the file for which the macro is being expanded
 *
 * @return  the name of the file created by the linker
 */
static _str getTargetFileName(_str studio_version,int vPrjHandle,_str config,int cfgNode,_str inputFileName)
{
   _str outputFile = '';
   // look for the linker node
   if (studio_version == COMPILER_NAME_VS2010) {
      // $(OutDir)$(TargetName)$(TargetExt)
      _str outDir = getVCXProjPropertyGroup(vPrjHandle, config, 'OutDir');
      _str targetName = getVCXProjPropertyGroup(vPrjHandle, config, 'TargetName');
      _str targetExt = getVCXProjPropertyGroup(vPrjHandle, config, 'TargetExt');
      if (targetExt :== '') {
         _str configType = getVCXProjPropertyGroupConfiguration(vPrjHandle, config, 'ConfigurationType');
         switch (configType) {
         case 'Application':
            targetExt = '.exe';
            break;
         case 'StaticLibrary':
            targetExt = '.lib';
            break;
         case 'DynamicLibrary':
            targetExt = '.dll';
            break;
         }
      }
      outputFile = (outDir :== '') ? '$(SolutionDir)$(Configuration)\' : outDir;
      outputFile :+= (targetName :== '') ? '$(ProjectName)' : targetName;
      outputFile :+= (targetExt :== '') ? '.exe' : targetExt;
   } else {
      _str temp = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCLinkerTool','OutputFile');
      if (temp == '') {
         temp = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCLibrarianTool','OutputFile');
      }
      if (temp == '') {
         temp = DEFAULT_VCPP_OUTPUT_FILENAME;
      }
      outputFile = temp;
   }

   _str result = _expand_all_vs_macros(studio_version,outputFile,vPrjHandle,cfgNode,inputFileName);
   result = absolute(result,_strip_filename(_xmlcfg_get_filename(vPrjHandle),'N'));
   return result;
}

/**
 * translates a visual studio macro.<br>
 * <br>
 * In most cases, this function will not recurse so the results could contain
 * more visual studio macros.  However, TargetDir, TargetPath,TargetName,
 * TargetFileName, and TargetExt will cause this function to recurse since the
 * results are parsed before they are returned and therefore must be fully
 * expanded.<br>
 * <br>
 * Some parameters are only used with certain macros.<br>
 * <br>
 * RemoteMachine, WebDeployRoot and WebDeployPath are not supported
 *
 * @param   studio_version    set to COMPILER_NAME_VSDOTNET or COMPILER_NAME_VS2003
 * @param   macro             name of the macro to expand without the $( and )
 * @param   vPrjHandle        handle of the <b>visual studio project file</b> (.vcproj) opened with _xmlcfg_open
 * @param   cfgNode           index of the configuration element in the project element <b>-or-</b> the index of the FileConfiguration element inside of the File element if inputFileName is set
 * @param   inputFileName     if expanding macros for a particular file in the project, specify the absolute filename
 * @param   markInherits      if true, $(Inherit) and $(NoInherit) are returned as $$(Inherit) and $$(NoInherit)
 *                            <br>if false, $(Inherit) and $(NoInherit) are expanded to an empty string
 */
_str _expand_vs_macro(_str studio_version,_str macro,int vPrjHandle,int cfgNode,_str inputFileName='',boolean markInherits=false)
{
   if (macro=='') {
      return '';
   }
   _str result='';

   _str vs_version='7.0';
   _str net_version='';
   _str studio_name='VisualStudio';
   _str config_name='';

   if (studio_version==COMPILER_NAME_VS2003) {
      vs_version='7.1';
      net_version='v1.1';
   } else if (studio_version==COMPILER_NAME_VS2005) {
      vs_version='8.0';
      net_version='v2.0';
   } else if (studio_version==COMPILER_NAME_VS2005_EXPRESS) {
      studio_name='VCExpress';
      vs_version='8.0';
      net_version='v2.0';
   } else if (studio_version==COMPILER_NAME_VS2008) {
      vs_version='9.0';
      net_version='v2.0';
   } else if (studio_version==COMPILER_NAME_VS2010) {
      vs_version='10.0';
      net_version='v2.0';
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         config_name=_xmlcfg_get_attribute(vPrjHandle,cfgNode,'Include');
      }
   } else if (studio_version==COMPILER_NAME_VS2008_EXPRESS) {
      studio_name='VCExpress';
      vs_version='9.0';
      net_version='v2.0';
   } else if (studio_version==COMPILER_NAME_VS2010_EXPRESS) {
      studio_name='VCExpress';
      vs_version='10.0';
      net_version='v2.0';
   }

   boolean fileSpecified=true;
   if (inputFileName=='') {
      if (vPrjHandle>=0) {
         inputFileName=_xmlcfg_get_filename(vPrjHandle);
      }
      fileSpecified=false;
   }

   // see Visual C++ Concepts: Building a C/C++ Program -- Macros for Build Commands and Properties
   // in the .NET help system
   switch (upcase(macro)) {
   case 'REMOTEMACHINE':
      // not supported
      // value is stored in the .suo file
      break;
   case 'CONFIGURATIONNAME':
         if ((vPrjHandle>=0)&&(cfgNode>=0)) {
            if(studio_version==COMPILER_NAME_VS2010) {
               parse config_name with result '|' .;
            } else {
               parse _xmlcfg_get_attribute(vPrjHandle,cfgNode,'Name') with result '|' .;
            }
         }
      break;
   case 'PLATFORMNAME':
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         if(studio_version==COMPILER_NAME_VS2010) {
            parse config_name with . '|' result;
         } else {
            parse _xmlcfg_get_attribute(vPrjHandle,cfgNode,'Name') with . '|' result;
         }
      }
      break;
   case 'CONFIGURATION':
      if (config_name != '') {
         parse config_name with result '|' .;
      }
      break;
   case 'PLATFORM':
      if (config_name != '') {
         parse config_name with . '|' result;
      }
      break;
   case 'PLATFORMARCHITECTURE':
      if (config_name != '') {
         parse config_name with . '|' result;
         switch (result) {
         case 'x64':
         case 'Itanium':
            result = '64';
            break;
         case 'Win32':
            result = '32';
            break;
         default:
            result = '';
            break;
         }
      }
      break;
   case 'INHERIT':
      if (markInherits) {
         result='$$(Inherit)';
      } else {
         result='';
      }
      break;
   case 'NOINHERIT':
      if (markInherits) {
         result='$$(NoInherit)';
      } else {
         result='';
      }
      break;
   case 'PARENTNAME':
      if (vPrjHandle>=0) {
         result=getParentName(vPrjHandle, inputFileName, fileSpecified);
      }
      break;
   case 'ROOTNAMESPACE':
      // .NET 2003 only??
      if (vPrjHandle>=0) {
         if(studio_version==COMPILER_NAME_VS2010) {
            result = getVCXProjGlobalPropertyGroup(vPrjHandle, 'RootNamespace');
         } else{
            result=_xmlcfg_get_path(vPrjHandle,'VisualStudioProject','RootNamespace');
         }
      }
      break;
   case 'INTDIR':
      if(studio_version==COMPILER_NAME_VS2010) {
         result = getVCXProjPropertyGroup(vPrjHandle, config_name, 'IntDir');
         if (result :== '') {
            result = '$(Configuration)\';
         }
      } else {
         if ((vPrjHandle>=0)&&(cfgNode>=0)) {
            result = getProjectCfgValue(vPrjHandle,cfgNode,'IntermediateDirectory');
         }
      }
      break;
   case 'OUTDIR':
      if(studio_version==COMPILER_NAME_VS2010) {
         result = getVCXProjPropertyGroup(vPrjHandle, config_name, 'OutDir');
         if (result :== '') {
            parse config_name with auto Configuration '|' auto Platform;
            if (Platform == "Win32") {
               result = '$(SolutionDir)$(Configuration)\';
            } else {
               result = '$(SolutionDir)$(Platform)\$(Configuration)\';
            }
         } else {
            _maybe_append_filesep(result);
         }

      } else {
         if ((vPrjHandle>=0)&&(cfgNode>=0)) {
            result = getProjectCfgValue(vPrjHandle,cfgNode,'OutputDirectory');
         }
      }
      break;
   case 'DEVENVDIR':
      result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\'studio_name'\'vs_version,'', 'InstallDir');
      break;
   case 'INPUTDIR':
      result=_strip_filename(inputFileName,'N');
      break;
   case 'INPUTPATH':
      result=inputFileName;
      break;
   case 'INPUTNAME':
      result=_strip_filename(inputFileName,'PE');
      break;
   case 'INPUTFILENAME':
      result=_strip_filename(inputFileName,'P');
      break;
   case 'INPUTEXT':
      result=_get_extension(inputFileName,true);
      break;
   case 'PROJECTDIR':
      if (vPrjHandle>=0) {
         _str projectFileName=_xmlcfg_get_filename(vPrjHandle);
         result=_strip_filename(projectFileName,'N');
      }
      break;
   case 'PROJECTPATH':
      if (vPrjHandle>=0) {
         result=_xmlcfg_get_filename(vPrjHandle);
      }
      break;
   case 'PROJECTNAME':
      if (vPrjHandle>=0) {
         if(studio_version==COMPILER_NAME_VS2010) {
            result = getVCXProjGlobalPropertyGroup(vPrjHandle, 'ProjectName');
            if (result == '') {
               _str projectFileName=_xmlcfg_get_filename(vPrjHandle);
               result=_strip_filename(projectFileName,'PE');
            }
         } else {
            result=_xmlcfg_get_path(vPrjHandle,'VisualStudioProject','Name');
         }
      }
      break;
   case 'PROJECTFILENAME':
      if (vPrjHandle>=0) {
         _str projectFileName=_xmlcfg_get_filename(vPrjHandle);
         result=_strip_filename(projectFileName,'P');
      }
      break;
   case 'PROJECTEXT':
      if(studio_version==COMPILER_NAME_VS2010) {
         result=VISUAL_STUDIO_VCX_PROJECT_EXT;
      } else {
         result=VISUAL_STUDIO_VCPP_PROJECT_EXT;
      }
      break;
   case 'SOLUTIONDIR':
      {
         _str solutionFileName=getSolutionFileName();
         result=_strip_filename(solutionFileName,'N');
      }
      break;
   case 'SOLUTIONPATH':
      result=getSolutionFileName();
      break;
   case 'SOLUTIONNAME':
      {
         // the solution name is not stored in the solution file,
         // it is simply the name of the solution file
         _str solutionFileName=getSolutionFileName();
         result=_strip_filename(solutionFileName,'PE');
      }
      break;
   case 'SOLUTIONFILENAME':
      {
         _str solutionFileName=getSolutionFileName();
         result=_strip_filename(solutionFileName,'P');
      }
      break;
   case 'SOLUTIONEXT':
      result=VISUAL_STUDIO_SOLUTION_EXT;
      break;
   case 'TARGETDIR':
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         _str outputFileName=getTargetFileName(studio_version,vPrjHandle,config_name,cfgNode,inputFileName);
         result=_strip_filename(outputFileName,'N');
      }
      break;
   case 'TARGETPATH':
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         result=getTargetFileName(studio_version,vPrjHandle,config_name,cfgNode,inputFileName);
      }
      break;
   case 'TARGETNAME':
      {
         if ((vPrjHandle>=0)&&(cfgNode>=0)) {
            _str outputFileName=getTargetFileName(studio_version,vPrjHandle,config_name,cfgNode,inputFileName);
            result=_strip_filename(outputFileName,'PE');
         }
      }
      break;
   case 'TARGETFILENAME':
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         _str outputFileName=getTargetFileName(studio_version,vPrjHandle,config_name,cfgNode,inputFileName);
         result=_strip_filename(outputFileName,'P');
      }
      break;
   case 'TARGETEXT':
      if ((vPrjHandle>=0)&&(cfgNode>=0)) {
         _str outputFileName=getTargetFileName(studio_version,vPrjHandle,config_name,cfgNode,inputFileName);
         result=_get_extension(outputFileName,true);
      }
      break;
   case 'VSINSTALLDIR':
      result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\'studio_name'\'vs_version'\Setup\VS','','ProductDir');
      break;
   case 'VCINSTALLDIR':
      result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\'studio_name'\'vs_version'\Setup\VC','','ProductDir');
      break;
   case 'FRAMEWORKDIR':
      result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework','','InstallRoot');
      break;
   case 'FRAMEWORKVERSION':
      if (net_version:=='') {
         result='v1.0.3705'; // could not find out to get this (easily) from the registry
      } else {
         result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\'studio_name'\'vs_version,'','CLR Version');
      }
      break;
   case 'FRAMEWORKSDKDIR':
      if (vs_version>='9.0') {
         if (vs_version=='9.0') { // Visual Studio 2008
            result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v6.0A","","InstallationFolder");
         } else if (vs_version=='10.0') { // Visual Studio 2010
            result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.0A","","InstallationFolder");
         } else if (vs_version>'10.0') {
            _message_box('function _expand_vs_macro, case FRAMEWORKSDKDIR needs to be updated');
         }
      } else {
         result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Microsoft\.NETFramework','','sdkInstallRoot'net_version);
      }
      break;
   case 'WEBDEPLOYPATH':
      // not supported
      break;
   case 'WEBDEPLOYROOT':
      // not supported
      break;
   case 'SAFEPARENTNAME':
      {
         if (vPrjHandle>=0) {
            _str parentName=getParentName(vPrjHandle,inputFileName,fileSpecified);
            result=stranslate(parentName,'','[ \t/$\\.\(\)]','r');
         }
      }
      break;
   case 'SAFEINPUTNAME':
      result=stranslate(_strip_filename(inputFileName,'PE'),'','[ \t/$\\.\(\)]','r');
      break;
   case 'WINDOWSSDKDIR':
      // New in Visual Studio 2008
      // Eventually this will need to be version specific.
      if(vs_version=='9.0') { // Visual Studio 2008
         result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v6.0A","","InstallationFolder");
      }
      else if(vs_version=='10.0') { // Visual Studio 2010
         result=_ntRegQueryValue(HKEY_LOCAL_MACHINE,"SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.0A","","InstallationFolder");
      } else if (vs_version>'10.0') {
         _message_box('function _expand_vs_macro, case FRAMEWORKSDKDIR needs to be updated');
      }
      break;
   default:
      {
         // environment variable
         result=get_env(macro);
      }
      break;
   }

   return result;
}

/**
 * This function is for VS2008 and gets the config value that is 
 * asked for.  This function will also check for any inherited 
 * property sheets and get the value from there if necessary. 
 */
_str getProjectCfgValue(int projHandle, int projCfgIndex, _str item, _str defaultValue='', boolean combine=true)
{
   _str retVal = defaultValue;

   // don't work with non-existent handles
   if ((projHandle < 0) || (projCfgIndex < 0)) {
      return retVal;
   }

   // check to see if we have an inherited property sheet to overlay
   int propSheetHandle = -1;
   int propSheetCfgIndex = -1;
   int status = 0;
   _str propSheetFilename =_xmlcfg_get_attribute(projHandle,projCfgIndex,'InheritedPropertySheets');
   if (propSheetFilename != '') {
      propSheetFilename = _expand_all_vs_macros(COMPILER_NAME_VS2008, propSheetFilename, projHandle, projCfgIndex);
      propSheetHandle = _xmlcfg_open(propSheetFilename, status);
      if (propSheetHandle >= 0) {
         propSheetCfgIndex = _xmlcfg_find_simple(propSheetHandle, "VisualStudioPropertySheet");
      }
   }
   // get the value
   _str cfgVal = _xmlcfg_get_attribute(projHandle,projCfgIndex,item,'');
   if (cfgVal != '') {
      retVal = cfgVal;
   }
   if ((propSheetHandle >= 0) && (propSheetCfgIndex >= 0)) {
      _str propSheetVal = _xmlcfg_get_attribute(propSheetHandle,propSheetCfgIndex,item,'');
      if (propSheetVal != '') {
         retVal = propSheetVal;
      }
      // close the property sheet xml
      _xmlcfg_close(propSheetHandle);
   }
   return retVal;
}

/**
 * This function is for VS2008 and gets the config value that is 
 * asked for.  This function will also check for any inherited 
 * property sheets and get the value from there if necessary. 
 */
_str getProjectCfgToolValue(int projHandle, int projCfgIndex, _str toolName, _str item, _str defaultValue='', boolean combine=true)
{
   _str retVal = defaultValue;

   // don't work with non-existent handles
   if ((projHandle < 0) || (projCfgIndex < 0)) {
      return retVal;
   }
   // check to see if we have an inherited property sheet to overlay
   int propSheetHandle = -1;
   int propSheetCfgIndex = -1;
   int status = 0;
   _str propSheetFilename =_xmlcfg_get_attribute(projHandle,projCfgIndex,'InheritedPropertySheets');
   if (propSheetFilename != '') {
      propSheetFilename = _expand_all_vs_macros(COMPILER_NAME_VS2008, propSheetFilename, projHandle, projCfgIndex);
      propSheetHandle = _xmlcfg_open(propSheetFilename, status);
      if (propSheetHandle >= 0) {
         propSheetCfgIndex = _xmlcfg_find_simple(propSheetHandle, "VisualStudioPropertySheet");
      }
   }
   // get the value
   int toolIndex = _xmlcfg_find_simple(projHandle,"Tool[@Name='"toolName"']",projCfgIndex);
   if (toolIndex >= 0) {
      _str cfgVal = _xmlcfg_get_attribute(projHandle,toolIndex,item,'');
      if (cfgVal != '') {
         retVal = cfgVal;
      }
   }
   if ((propSheetHandle >= 0) && (propSheetCfgIndex >= 0)) {
      toolIndex = _xmlcfg_find_simple(propSheetHandle,"Tool[@Name='"toolName"']",propSheetCfgIndex);
      if (toolIndex >= 0) {
         _str propSheetVal = _xmlcfg_get_attribute(propSheetHandle,toolIndex,propSheetCfgIndex,'');
         if (propSheetVal != '') {
            retVal = propSheetVal;
         }
      }
      // close the property sheet xml
      _xmlcfg_close(propSheetHandle);
   }
   return retVal;
}

_str _expand_all_vs_macros(_str studio_version,
                           _str input_str,
                           int vPrjHandle,
                           int cfgNode,
                           _str inputFileName='',
                           boolean markInherits=false,
                           int recurseLimit=16,
                           boolean firstExpansion=true)
{
   if (recurseLimit<=0) {
      return input_str;
   }

   if (!firstExpansion) {
      if (markInherits) {
         if (strieq(input_str,'INHERIT')||strieq(input_str,'NOINHERIT')) {
            return '$$('input_str')';
         }
      }
      input_str=_expand_vs_macro(studio_version,input_str,vPrjHandle,cfgNode,inputFileName,markInherits);
   }

   _str macro='';
   _str output_str='';
   int macro_position;

   while (input_str:!='') {
      macro_position=pos('\$\({?+}\){?@}',input_str,1,'r');

      if (macro_position>0) {
         strappend(output_str,substr(input_str,1,macro_position-1));
         macro=substr(input_str,pos('S0'),pos('0'));
         input_str=substr(input_str,pos('S1'),pos('1'));

         macro=_expand_all_vs_macros(studio_version,macro,vPrjHandle,cfgNode,inputFileName,
                                     markInherits,recurseLimit-1,false);

         strappend(output_str,macro);
      } else {
         strappend(output_str,input_str);
         input_str='';
      }
   }

   return output_str;
}

static _str removeInheritsMarks(_str input_str,boolean &hasInherit,boolean &hasNoInherit)
{
   hasInherit=false;
   hasNoInherit=false;

   _str marker='';
   _str output_str='';
   int marker_position;

   while (input_str:!='') {
      marker_position=pos('\$\$\({?+}\){?@}',input_str,1,'r');

      if (marker_position>0) {
         strappend(output_str,substr(input_str,1,marker_position-1));
         marker=substr(input_str,pos('S0'),pos('0'));
         input_str=substr(input_str,pos('S1'),pos('1'));

         if (strieq(first_char(marker),'N')) {
            hasNoInherit=true;
         } else {
            hasInherit=true;
         }
      } else {
         strappend(output_str,input_str);
         input_str='';
      }
   }
   return output_str;
}

/**
 * takes the include directories from a .NET project file (extra_dirs) and adds them to all_includes
 * after conditionally expanding all macros<br>
 * <br>
 * only set checkInherits for a file, not a project
 *
 * @param   studio_version    set to COMPILER_NAME_VSDOTNET or COMPILER_NAME_VS2003
 * @param   all_includes      existing include directories
 * @param   extra_dirs        include directories found in a .NET project file
 * @param   expand_aliases    when true, this function will evaluate all .NET macros in extra_dirs before appending them to all_includes
 * @param   vPrjHandle        handle of the <b>visual studio project file</b> (.vcproj) opened with _xmlcfg_open
 * @param   cfgNode           index of the configuration element in the project element <b>-or-</b> the index of the FileConfiguration element inside of the File element if inputFileName is set
 * @param   inputFileName     if expanding macros for a particular file in the project, specify the absolute filename
 * @param   checkInherits     when set, any $(Inherit) or $(NoInherit) macros found will be processed
 * @param   projectHandle     handle of the project file
 * @param   config_name       the name of the configuration that is being evaluated
 */
static void append_net_directories(_str studio_version,_str& all_includes,_str extra_dirs,boolean expand_aliases,int vPrjHandle,int cfgNode,_str inputFileName='',boolean checkInherits=false,int projectHandle=-1,_str config_name='')
{
   boolean hasNoInherit=false;
   boolean hasInherit=false;
   boolean doneInherit=false;

   if (expand_aliases) {

      while (extra_dirs!='') {
         _str cur_dir;
         parse extra_dirs with cur_dir PATHSEP extra_dirs;

         cur_dir=strip(cur_dir,'B','"');
         cur_dir=_expand_all_vs_macros(studio_version,cur_dir,vPrjHandle,cfgNode,inputFileName,checkInherits);
         cur_dir=removeInheritsMarks(cur_dir,hasInherit,hasNoInherit);

         if (all_includes!='') {
            strappend(all_includes,PATHSEP);
         }
         strappend(all_includes,cur_dir);

         if ((hasInherit)&&(!doneInherit)) {
            doneInherit=true;
            _str project_dirs = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCCLCompilerTool','AdditionalIncludeDirectories');
            project_dirs=fix_dotNET_includes(project_dirs);
            _str new_includes='';
            append_net_directories(studio_version,new_includes,project_dirs,expand_aliases,vPrjHandle,cfgNode,inputFileName,false,projectHandle,config_name);
            if (new_includes!='') {
               if (extra_dirs!='') {
                  extra_dirs=new_includes:+PATHSEP:+extra_dirs;
               } else {
                  extra_dirs=new_includes;
               }
            }
         }
      }
   } else {
      if (all_includes!='') {
         strappend(all_includes,PATHSEP);
      }
      strappend(all_includes,extra_dirs);
   }

   // add the project level directories if this is a file
   // and there are no Inherit or NoIherit macros already
   if ((checkInherits)&&(!hasInherit)&&(!hasNoInherit)) {
      // cfgNode here is the config element under the current file, not the project config node
      // which is what we need. so go find it
      cfgNode=_xmlcfg_find_simple(vPrjHandle,"//Configuration[@Name='"config_name"']");
      if (cfgNode>=0) {
         _str project_dirs = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCCLCompilerTool','AdditionalIncludeDirectories');
         if (project_dirs != '') {
            project_dirs=fix_dotNET_includes(project_dirs);
            append_net_directories(studio_version,all_includes,project_dirs,expand_aliases,vPrjHandle,cfgNode,inputFileName,false,projectHandle,config_name);
         }
      }
   }
}

/**
 * Similar to append_net_directories, but accounts for the project file being in 
 * MSBUILD format 
 * 
 * @param studio_version 
 * @param all_includes 
 * @param extra_dirs 
 * @param expand_aliases 
 * @param vPrjHandle 
 * @param cfgNode 
 * @param inputFileName 
 * @param checkInherits 
 * @param projectHandle 
 * @param config_name 
 */
static void append_VS2010_directories(_str studio_version,_str& all_includes,_str extra_dirs,boolean expand_aliases,int vPrjHandle,int cfgNode,_str inputFileName='',boolean checkInherits=false,int projectHandle=-1,_str config_name='')
{
   boolean hasNoInherit=false;
   boolean hasInherit=false;
   boolean doneInherit=false;

   if (expand_aliases) {

      while (extra_dirs!='') {
         _str cur_dir;
         parse extra_dirs with cur_dir PATHSEP extra_dirs;

         cur_dir=strip(cur_dir,'B','"');
         cur_dir=_expand_all_vs_macros(studio_version,cur_dir,vPrjHandle,cfgNode,inputFileName,checkInherits);
         cur_dir=removeInheritsMarks(cur_dir,hasInherit,hasNoInherit);

         if (all_includes!='') {
            strappend(all_includes,PATHSEP);
         }
         strappend(all_includes,cur_dir);

         if ((hasInherit)&&(!doneInherit)) {
            doneInherit=true;
            _str project_dirs = getProjectCfgToolValue(vPrjHandle,cfgNode,'VCCLCompilerTool','AdditionalIncludeDirectories');
            if (project_dirs == '') {
               project_dirs=fix_dotNET_includes(project_dirs);
               _str new_includes='';
               append_net_directories(studio_version,new_includes,project_dirs,expand_aliases,vPrjHandle,cfgNode,inputFileName,false,projectHandle,config_name);
               if (new_includes!='') {
                  if (extra_dirs!='') {
                     extra_dirs=new_includes:+PATHSEP:+extra_dirs;
                  } else {
                     extra_dirs=new_includes;
                  }
               }
            }
         }
      }
   } else {
      if (all_includes!='') {
         strappend(all_includes,PATHSEP);
      }
      strappend(all_includes,extra_dirs);
   }

   
}

/**
 * finds include directories and defines and undefines from a VS6 project file in the current view
 *
 * @param   includes                set to a list of PATHSEP delimited include directories
 * @param   defines                 set to a list of space delimited defines and undefines
 * @param   config_name             the name of the configuration that is being evaluated
 * @param   ignoreProjectIncludes   set to true if the specifed file does not inherit the project includes
 * @param   ignoreProjectDefines    set to true if the specifed file does not inherit the project defines
 * @param   otherOptions            set to all other options
 * @param   inputFileName           the project relative file name of the file to be evaluated.  If no name is specified, only project level defines and includes are found
 */
static void parse_vs6_project(_str &includes,_str &defines,_str config_name,boolean &ignoreProjectIncludes,boolean &ignoreProjectDefines,_str &otherOptions,_str inputFileName='')
{
   int ifdepth=0;
   // stack corresponding to each level of control (!IF) found indicating
   // if the condition passed or failed.  skipping is set to true if the
   // condition failed
   boolean skipping[];
   skipping._makeempty();

   skipping[ifdepth]=(inputFileName!=''); // skip project stuff for a file

   // simplify the config name
   if (substr(config_name,1,4):=='CFG=') {
      config_name=substr(config_name,5);
   }

   // we've found nothing ... yet
   includes='';
   defines='';
   ignoreProjectIncludes=false;
   ignoreProjectDefines=false;

   // the current line
   _str line;
   // the current command
   _str cmd;
   // all remaining options for the current command
   _str options;
   // the individual option that is being evaluated
   _str opt;

   // used while parsing #ADD lines.
   // set to true if the next option is an include, define or undefine
   boolean next_include;
   boolean next_define;
   boolean next_undefine;

   top();up();
   while (!down()) {
      get_line(line);
      first_char=substr(line,1,1);
      if (first_char:=='#') {
         parse line with '#' cmd options;
         if (cmd:=='ADD') {
            if (!skipping[ifdepth]) {
               opt=parse_next_option(options,false);
               if (opt:=='CPP') {
                  next_include=false;
                  next_define=false;
                  next_undefine=false;
                  while (opt!='') {
                     if (next_include) {
                        next_include=false;
                        if (includes!='') {
                           strappend(includes,PATHSEP);
                        }
                        strappend(includes,strip(opt,'B','"'));
                     } else if (next_define) {
                        next_define=false;
                        if (defines!='') {
                           strappend(defines,' ');
                        }
                        strappend(defines, '"/D'opt'"');
                     } else if (next_undefine) {
                        next_undefine=false;
                        if (defines!='') {
                           strappend(defines,' ');
                        }
                        strappend(defines, '"/U'opt'"');
                     } else {
                        next_include=false;
                        next_define=false;
                        next_undefine=false;

                        if (opt:=='/I') {
                           next_include=true;
                        } else if (opt:=='/D') {
                           next_define=true;
                        } else if (opt:=='/U') {
                           next_undefine=true;
                        } else if (opt:=='/X') {
                           ignoreProjectIncludes=true;
                        } else if (opt:=='/u') {
                           ignoreProjectDefines=true;
                        } else {
                           if (otherOptions!='') {
                              strappend(otherOptions,' ');
                           }
                           strappend(otherOptions,opt);
                        }
                     }
                     opt=parse_next_option(options,false);
                  }
               }
            }
         } else if (line:=='# Begin Source File') {
            ++ifdepth;
            skipping[ifdepth]=skipping[ifdepth-1];
         } else if (line:=='# End Source File') {
            --ifdepth;
         }
      } else if (first_char:=='!') {
         parse line with cmd options;
         if (cmd:=='!IF') {
            ++ifdepth;
            skipping[ifdepth]=skipping[ifdepth-1];
            _str cur_config;
            parse options with '"$(CFG)" ==' cur_config;
            cur_config=strip(strip(cur_config),'B','"');
            if (cur_config!=config_name) {
               skipping[ifdepth]=true;
            }
         } else if (cmd:=='!ELSEIF') {
            // don't push the stack
            skipping[ifdepth]=skipping[ifdepth-1];
            _str cur_config;
            parse options with '"$(CFG)" ==' cur_config;
            cur_config=strip(strip(cur_config),'B','"');
            if (cur_config!=config_name) {
               skipping[ifdepth]=true;
            }
         } else if (cmd:=='!ENDIF') {
            --ifdepth;
         }
      } else {
         _str file;
         parse line with 'SOURCE=' file;
         if (file:!='') {
            // if checking for the project or a different file
            skipping[ifdepth]=(inputFileName:!=file);
         }
      }
   }
}

/**
 * finds include directories from a VS6 project file in the current view and adds them to all_includes
 *
 * @param   all_includes      the include directories for the current file
 * @param   config_name       the name of the configuration that is being used
 * @param   inputFileName     the project relative file that is being checked.  If no file is specified,
 *                            project level include directories are found
 * @param   projectHandle     the handle for the project that is being checked
 */
static void append_vs6_directories(_str& all_includes,_str config_name,_str inputFileName='',int projectHandle=-1)
{
   _str file_includes;
   _str file_defines;
   boolean ignoreProjectIncludes;
   boolean ignoreProjectDefines;
   _str otherOptions;
   parse_vs6_project(file_includes,file_defines,config_name,ignoreProjectIncludes,ignoreProjectDefines,otherOptions,inputFileName);
   if (file_includes!='') {
      if (all_includes!='') {
         strappend(all_includes,PATHSEP);
      }
      strappend(all_includes,file_includes);
   }
   if ((inputFileName!='')&&(!ignoreProjectIncludes)) {
      _str projectIncludes=_ProjectGet_AssociatedIncludes(projectHandle,false,config_name);
      if (projectIncludes!='') {
         if (all_includes!='') {
            strappend(all_includes,PATHSEP);
         }
         strappend(all_includes,projectIncludes);
      }
   }
}

/**
 * The %(INCLUDE) variable was added to associated projects as a stop-gap for associated
 * projects in a previous version.  It can now be safely ignored and this function
 * removes it from the project includes list
 *
 * @param   prj_includes   the list of project include directories
 */
static void remove_includes_envvar(_str& prj_includes)
{
   _str bad_envvar='%(INCLUDE)';  // this was put in as a hack and is not necessary anymore
   int envvar_pos=pos(bad_envvar,prj_includes);

   if (!envvar_pos) {
      return;
   }

   // if start of string
   if (envvar_pos==1) {
      prj_includes=substr(prj_includes,length(bad_envvar)+2); // +1 for the right position and +1 for the PATHSEP
   } else {
      // remove %(INCLUDE) and the PATHSEP in front of it
      _str trailing_includes;
      parse prj_includes with prj_includes (PATHSEP:+bad_envvar) trailing_includes;
      strappend(prj_includes, trailing_includes);
   }
}

/**
 * Finds include directories for an associated project.  This is both the ones specified in the
 * project and those that are part of the compiler configuration.<br>
 * <br>
 * Can find directories from:
 * <ol>
 *    <li>refactoring compiler configuration</li>
 *    <li>directories listed in associated project files</li>
 * </ol>
 *
 * @param   handle            handle for the project
 * @param   expand_aliases    if true and the project is associated with a Visual Studio project, the
 *                            Visual Studio macros will be expanded
 * @param   config            the name of the configuration to be used
 *
 * @return  a PATHSEP delimited list of include directories
 */
_str _ProjectGet_AssociatedIncludes(int handle, boolean expand_aliases=false, _str config=gActiveConfigName)
{
   _str all_includes='';

   _str prjFileName=_ProjectGet_Filename(handle);
   _str aFileName=_ProjectGet_AssociatedFile(handle);
   if (file_eq(_get_extension(aFileName,true), VISUAL_STUDIO_INTEL_CPP_PROJECT_EXT)) {
      aFileName = getICProjAssociatedProjectFile(aFileName);
   }

   // Visual Studio .NET project
   if (_get_extension(aFileName,true):==VISUAL_STUDIO_VCPP_PROJECT_EXT) {
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int status;
      int vPrjHandle=_xmlcfg_open(vFileName,status);

      if (!status) {
         int cfgNode=_xmlcfg_find_simple(vPrjHandle,"//Configuration[@Name='"config"']");
         if (cfgNode>=0) {
            int toolNode=_xmlcfg_find_simple(vPrjHandle,"Tool[@Name='VCCLCompilerTool']",cfgNode);
            if(toolNode>=0) {
               // don't assume the compiler config name is set correctly
               _str compiler_name=COMPILER_NAME_VSDOTNET;
               _str dotNetVersion=_xmlcfg_get_path(vPrjHandle,'VisualStudioProject','Version');
               if (dotNetVersion:=='7.10') {
                  compiler_name=COMPILER_NAME_VS2003;
               } else if (dotNetVersion:=='8.00') {
                  compiler_name=COMPILER_NAME_VS2005;
               } else if (dotNetVersion:=='9.00') {
                  compiler_name=COMPILER_NAME_VS2008;
               } else if (dotNetVersion:=='10.00') {
                  compiler_name=COMPILER_NAME_VS2010;
               }
               _str extra_dirs=_xmlcfg_get_attribute(vPrjHandle,toolNode,'AdditionalIncludeDirectories','');
               extra_dirs=fix_dotNET_includes(extra_dirs);
               append_net_directories(compiler_name,all_includes,extra_dirs,expand_aliases,vPrjHandle,cfgNode);
            }
         }
         _xmlcfg_close(vPrjHandle);
      }
   }
   // Visual Studio 2010 C++ .vcxproj 
   else if (_get_extension(aFileName,true):==VISUAL_STUDIO_VCX_PROJECT_EXT) {

      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int status;
      int vPrjHandle=_xmlcfg_open(vFileName,status,VSXMLCFG_OPEN_ADD_PCDATA);

      if (!status) {
         // Look for <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
         //             <IncludePath>.....</IncludePath>
         _str extraDirsPropGroup = '';
         // TODO: There can be more than one property group that satisfies this condition...
         int cfgNode=_xmlcfg_find_simple(vPrjHandle,"//PropertyGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]");
         if (cfgNode>=0) {
            int includePathNode = _xmlcfg_find_simple(vPrjHandle,"IncludePath",cfgNode);
            if(includePathNode>=0) {
               int includeNodeTextNode = _xmlcfg_get_first_child(vPrjHandle, includePathNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
               if(includeNodeTextNode>0) {
                  extraDirsPropGroup = _xmlcfg_get_value(vPrjHandle, includeNodeTextNode);
               }
            }
         }

         // And also <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">
         //             <AdditionalIncludeDirectories>.....</IncludePath>
         _str extraDirsItemDefGroup = '';
         cfgNode=_xmlcfg_find_simple(vPrjHandle,"//ItemDefinitionGroup[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]");
         if (cfgNode>=0) {
            int additionalIncludesNode = _xmlcfg_find_simple(vPrjHandle,"AdditionalIncludeDirectories",cfgNode);
            if(additionalIncludesNode>=0) {
               int includeNodeTextNode = _xmlcfg_get_first_child(vPrjHandle, additionalIncludesNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
               if(includeNodeTextNode>0) {
                  extraDirsItemDefGroup = _xmlcfg_get_value(vPrjHandle, includeNodeTextNode);
               }
            }
         }

         
         _str extraDirs = extraDirsPropGroup;
         if(extraDirs != '') {
            if(extraDirsItemDefGroup != '') {
               extraDirs :+= (";"extraDirsItemDefGroup);
            }
         } else {
            extraDirs = extraDirsItemDefGroup;
         }
         extraDirs=fix_dotNET_includes(extraDirs);
         append_VS2010_directories(COMPILER_NAME_VS2010,all_includes,extraDirs,expand_aliases,vPrjHandle,cfgNode);

         _xmlcfg_close(vPrjHandle);
      }
   }
   // Visual C++ 6 project
   else if (_get_extension(aFileName,true):==VCPP_PROJECT_FILE_EXT) {
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int temp_view_id;
      int orig_view_id;
      _open_temp_view(vFileName,temp_view_id,orig_view_id);
      activate_window(temp_view_id);
      append_vs6_directories(all_includes,config);
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   } else if (_get_extension(aFileName,true):==PRJ_FILE_EXT) {
      // Xcode projects are associated with themselves since Xcode
      // does not maintain separate project files
      all_includes=_xcode_get_include_dirs(aFileName);
   }

   _str sys_includes=_ProjectGet_SystemIncludes(handle,config);
   if (sys_includes!='') {
      if (all_includes!='') {
         strappend(all_includes,PATHSEP);
      }
      strappend(all_includes,sys_includes);
   }

   return all_includes;
}

/**
 * helper function for {@link fix_dotNET_includes}.
 */
static _str parse_next_include(_str &includes)
{
   int split_pos=length(includes)+1;

   int comma_pos=pos(',',includes);
   int path_pos=pos(PATHSEP,includes);

   // have these default to the end of the string if they are not found
   if (comma_pos==0) {
      comma_pos=split_pos;
   }

   if (path_pos==0) {
      path_pos=split_pos;
   }

   if (path_pos<=comma_pos) {
      //easy case
      split_pos=path_pos;
   } else {
      //check if the comma is in quotes before using it as the split position
      int q1_pos=pos('"',includes);

      if (q1_pos==0) {
         // there are no quotes, the comma position is good
         split_pos=comma_pos;
      } else {
         // find out where the quotes end
         int q2_pos=pos('"',includes,q1_pos+1);
         if (q2_pos==0) {
            // unterminated string return the whole thing
            // split_pos already set to the length of the string
         } else if (q2_pos<comma_pos) {
            // string ends before the comma, it is a valid split
            split_pos=comma_pos;
         } else {
            // comma is in the string, use the PATHSEP
            split_pos=path_pos;
         }
      }
   }

   _str ret_value=substr(includes,1,split_pos-1);
   includes=substr(includes,split_pos+1);
   return ret_value;
}

/**
 * .NET allows comma delimited include directories, so convert any that are in
 * here to PATHSEP
 */
static _str fix_dotNET_includes(_str includes)
{
   // This whole function is a little hokey to begin with because comma
   // is a valid character for filenames.  Therefore only split on commas
   // that are not in quotes.

   _str out_includes='';

   while (includes:!='') {
      if (out_includes:!='') {
         strappend(out_includes,PATHSEP);
      }
      strappend(out_includes,parse_next_include(includes));
   }

   return out_includes;
}

/**
 * Finds all include directories for a file in a project.<br>
 * <br>
 * Can find directories from:
 * <ol>
 *    <li>refactoring compiler configuration</li>
 *    <li>directories listed in associated project files</li>
 *    <li>directories listed in the project file</li>
 * </ol>
 *
 * @param   handle            handle for the project
 * @param   filename          the name of the file to be used
 * @param   expand_aliases    if true and the project is associated with a Visual Studio project, the
 *                            Visual Studio macros will be expanded
 * @param   config            the name of the configuration to be used
 *
 * @return  a PATHSEP delimited list of include directories
 */
_str _ProjectGet_IncludesForFile(int handle,_str filename,boolean expand_aliases=false,_str config=gActiveConfigName)
{
   _str all_includes='';

   _str prjFileName=_ProjectGet_Filename(handle);
   _str aFileName=_ProjectGet_AssociatedFile(handle);

   _str extra_dirs='';

   // Visual Studio .NET project
   if (_get_extension(aFileName,true):==VISUAL_STUDIO_VCPP_PROJECT_EXT) {
      _str compiler_name=COMPILER_NAME_VSDOTNET;
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int status;
      int vPrjHandle=_xmlcfg_open(vFileName,status);

      if (!status) {
         int cfgNode=_xmlcfg_find_simple(vPrjHandle,"//Configuration[@Name='"config"']");
         if (cfgNode>=0) {
            _str projectDir=_strip_filename(_xmlcfg_get_filename(vPrjHandle),'N');
            _str relFileName=relative(filename,projectDir);
            relFileName=ConvertToVCPPRelFilename(relFileName,projectDir);
            int pathNode=_xmlcfg_find_simple(vPrjHandle,"//File/@RelativePath[file-eq(.,'"relFileName"')]");
            if (pathNode < 0 && substr(relFileName,1,2)==".\\") {
               relFileName = substr(relFileName,3);
               pathNode=_xmlcfg_find_simple(vPrjHandle,"//File/@RelativePath[file-eq(.,'"relFileName"')]");
            }
            if (pathNode>=0) {
               int fileNode=_xmlcfg_get_parent(vPrjHandle,pathNode);

               int fileConfigNode=_xmlcfg_find_simple(vPrjHandle,"FileConfiguration[@Name='"config"']",fileNode);
               if (fileConfigNode>=0) {
                  // don't assume the compiler config name is set correctly
                  _str dotNetVersion=_xmlcfg_get_path(vPrjHandle,'VisualStudioProject','Version');
                  if (dotNetVersion:=='7.10') {
                     compiler_name=COMPILER_NAME_VS2003;
                  } else if (dotNetVersion:=='8.00') {
                     compiler_name=COMPILER_NAME_VS2005;
                  } else if (dotNetVersion:=='9.00') {
                     compiler_name=COMPILER_NAME_VS2008;
                  } else if (dotNetVersion:=='10.00') {
                     compiler_name=COMPILER_NAME_VS2010;
                  }
                  extra_dirs = getProjectCfgToolValue(vPrjHandle,fileConfigNode,'VCCLCompilerTool','AdditionalIncludeDirectories');
                  extra_dirs=fix_dotNET_includes(extra_dirs);
               }
            }
            append_net_directories(compiler_name,all_includes,extra_dirs,expand_aliases,vPrjHandle,cfgNode,filename,true,handle,config);
         }
         _xmlcfg_close(vPrjHandle);
      }

   }
   // Visual Studio 2010 .vcxproj
   else if (_get_extension(aFileName,true):==VISUAL_STUDIO_VCX_PROJECT_EXT) {

      _str compiler_name=COMPILER_NAME_VS2010;
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int status;
      int vPrjHandle=_xmlcfg_open(vFileName,status);

      if (!status) {

         _str projectDir=_strip_filename(_xmlcfg_get_filename(vPrjHandle),'N');
         _str relFileName=relative(filename,projectDir);

         /* Look for
            <ClCompile Include="ChildFrm.cpp">
               <AdditionalIncludeDirectories Condition="'$(Configuration)|$(Platform)'=='Debug|Win32'">....</AdditionalIncludeDirectories>
            </ClCompile>
         */
         _str extraDirs = '';
         int fileNode=_xmlcfg_find_simple(vPrjHandle,"//ClCompile[@Include='"relFileName"']");
         if (fileNode>=0) {
           int additionalIncludesNode =_xmlcfg_find_simple(vPrjHandle,"AdditionalIncludeDirectories[@Condition=\"'$(Configuration)|$(Platform)'=='"config"'\"]", fileNode);
           if(additionalIncludesNode>=0) {
               int includeNodeTextNode = _xmlcfg_get_first_child(vPrjHandle, additionalIncludesNode, VSXMLCFG_NODE_ELEMENT_START|VSXMLCFG_NODE_ELEMENT_START_END);
               if(includeNodeTextNode>0) {
                  extraDirs = _xmlcfg_get_value(vPrjHandle, includeNodeTextNode);
                  extraDirs=fix_dotNET_includes(extraDirs);
                  append_VS2010_directories(COMPILER_NAME_VS2010,all_includes,extraDirs,expand_aliases,vPrjHandle,-1);
               }
            }
         }
         _xmlcfg_close(vPrjHandle);
      }
   }
   // Visual C++ 6 project
   else if (_get_extension(aFileName,true):==VCPP_PROJECT_FILE_EXT) {
      if (0!=pos(':',filename)) {
         // absoulte filename, make it relative to the project
         _str prjFilePath=_strip_filename(prjFileName,'N');
         filename=relative(filename,prjFilePath);
         filename=ConvertToVCPPRelFilename(filename,prjFilePath);
      }
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int temp_view_id;
      int orig_view_id;
      _open_temp_view(vFileName,temp_view_id,orig_view_id);
      activate_window(temp_view_id);
      append_vs6_directories(all_includes,config,filename,handle);
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
   } else if (_get_extension(aFileName,true):==PRJ_FILE_EXT) {
      // Xcode projects are associated with themselves since Xcode
      // does not maintain separate project files
      all_includes=_xcode_get_include_dirs(aFileName);
   }

   // VSE project (or anything added directly into our project properties dialog)
   if(all_includes != "") {
      all_includes = all_includes :+ PATHSEP;
   }
   all_includes = all_includes :+ _ProjectGet_IncludesList(handle, config);

   return all_includes;
}

boolean _ProjectGet_Option(int handle, int option,_str config=gActiveConfigName)
{
   _str net_name='';
   _str net_tool='VCCLCompilerTool';
   _str net_default='FALSE';
   _str vc6_name='';
   _str vse_name='';

   boolean ret_value=false;

   _str prjFileName=_ProjectGet_Filename(handle);
   _str aFileName=_ProjectGet_AssociatedFile(handle);

   boolean isDotNet=_get_extension(aFileName,true):==VISUAL_STUDIO_VCPP_PROJECT_EXT;
   boolean isVC6=_get_extension(aFileName,true):==VCPP_PROJECT_FILE_EXT;

   if (option==PROJ_OPT_WCHAR_NATIVE) {
      net_name='TreatWChar_tAsBuiltInType';
      vc6_name='/Zc:wchar_t';
      vse_name='/Zc:wchar_t';
   } else if (option==PROJ_OPT_VC6_RULES) {
      return isVC6;
   } else {
      return false;
   }

   if (isDotNet) {
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int status;
      int vPrjHandle=_xmlcfg_open(vFileName,status);

      if (!status) {
         int cfgNode=_xmlcfg_find_simple(vPrjHandle,"//Configuration[@Name='"config"']");
         if (cfgNode>=0) {
            _str attribValue = getProjectCfgToolValue(vPrjHandle,cfgNode,net_tool,net_name,net_default);
            if (upcase(attribValue)=='TRUE') {
               ret_value=true;
            } else {
               ret_value=false;
            }
         }
         _xmlcfg_close(vPrjHandle);
      }
   } else if (isVC6) {
      _str vFileName=_strip_filename(prjFileName,'N'):+aFileName;
      int temp_view_id;
      int orig_view_id;
      _open_temp_view(vFileName,temp_view_id,orig_view_id);
      activate_window(temp_view_id);
      _str includes;
      _str defines;
      boolean ignoreProjectIncludes;
      boolean ignoreProjectDefines;
      _str otherOptions;
      parse_vs6_project(includes,defines,config,ignoreProjectIncludes,ignoreProjectDefines,otherOptions);
      if (pos(vc6_name,otherOptions)) {
         ret_value=true;
      }
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);

   } else {
      // VSE project
      _str compileCommand = "";
      if(!getExtSpecificCompileInfo('dummy.cpp', handle, config, compileCommand)) {
         // parse any %vars
         compileCommand = _parse_project_command(compileCommand, 'dummy.cpp', _ProjectGet_Filename(handle), "");

         _str parameter = parse_next_option(compileCommand);
         while(parameter != "") {
            if (parameter==vse_name) {
               ret_value=true;
               break;
            }
            // get the next parameter
            parameter = parse_next_option(compileCommand);
         }
      }
   }

   return ret_value;
}

defeventtab _filter_form;

#define FILTER_FORM_FILTER_NAMES    (0)
#define FILTER_FORM_FILTER_VALUES   (1)
#define FILTER_FORM_CURRENT_FILTER  (2)

#region Options Dialog Helper Functions

void  _filter_form_init_for_options()
{
   ctlok.p_visible = false;
   ctlcancel.p_visible = false;

   initialize_file_filters(def_file_types);
}

boolean _filter_form_is_modified()
{
   current := compile_filter_string();
   return (current != def_file_types);
}

boolean _filter_form_apply()
{
   def_file_types = compile_filter_string();

   return true;
}

_str _filter_form_build_export_summary(PropertySheetItem (&summary)[])
{
   _str cur_filter_name;
   _str cur_filter_value;

   filters := def_file_types;
   while (filters:!='') {
      parse filters with cur_filter_name '(' cur_filter_value ')' . ',' filters;

      PropertySheetItem psi;
      psi.Caption = strip(cur_filter_name);
      psi.Value = strip(cur_filter_value);

      summary[summary._length()] = psi;
   }

   return '';
}

_str _filter_form_import_summary(PropertySheetItem (&summary)[])
{
   newFilter := '';
   PropertySheetItem psi;
   foreach (psi in summary) {

      strappend(newFilter,psi.Caption);
      strappend(newFilter,' (');
      strappend(newFilter,psi.Value);
      strappend(newFilter,'),');
   }

   def_file_types = newFilter;

   return '';
}

#endregion Options Dialog Helper Functions

void _filter_form.on_resize()
{
   // available width and height
   width := _dx2lx(SM_TWIP,p_active_form.p_client_width);
   height := _dy2ly(SM_TWIP,p_active_form.p_client_height);

   // label should stretch across bottom of screen
   widthDiff := (width - 240) - ctlFilterValue.p_width;

   // make these longer
   ctlFilterValue.p_width += widthDiff;
   ctlFilterList.p_width += widthDiff;

   // move these over
   ctlFilterNew.p_x += widthDiff;
   ctlFilterUp.p_x += widthDiff;
   ctlFilterDown.p_x += widthDiff;
   ctlFilterRemove.p_x += widthDiff;

   // button should be only a little ways up from the bottom of the form
   heightDiff := (height - 120);
   if (ctlok.p_visible) {
      heightDiff -= (ctlok.p_y + ctlok.p_height);
   } else {
      heightDiff -= (ctlFilterValue.p_y + ctlFilterValue.p_height);
   }

   // move these down
   ctlok.p_y += heightDiff;
   ctlcancel.p_y += heightDiff;
   ctlFilterValue.p_y += heightDiff;
   ctlLabelValue.p_y += heightDiff;

   // make this longer
   ctlFilterList.p_height += heightDiff;
}

void ctlok.on_create(_str filters = '', boolean use_folders=false)
{
   _param1 = '';

   initialize_file_filters(filters, use_folders);
   _filter_form_initial_alignment();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _filter_form_initial_alignment()
{
   rightAlign := ctlFilterValue.p_x + ctlFilterValue.p_width;
   alignUpDownListButtons(ctlFilterList, rightAlign, ctlFilterNew, ctlFilterUp, ctlFilterDown, ctlFilterRemove);
}

void initialize_file_filters(_str filters, boolean use_folders = false)
{
   _str filter_names[];
   _str filter_values[];

   _str cur_filter_name;
   _str cur_filter_value;

   while (filters:!='') {
      parse filters with cur_filter_name '(' cur_filter_value ')' . ',' filters;

      filter_names[filter_names._length()]=strip(cur_filter_name);
      filter_values[filter_values._length()]=cur_filter_value;
   }

   _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,0);

   if (use_folders) {
      p_active_form.p_caption='Folders';
      ctlLabelName.p_caption='Folder name:';
      ctlLabelValue.p_caption='File filter:';
   }

   update_filters();
}

static void update_filters()
{
   int target_index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

   ctlFilterList._TreeDelete(TREE_ROOT_INDEX,'C');

   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   int filter_nodes[];

   int index;

   for (index=0;index<filter_names._length();++index) {
      filter_nodes[index]=ctlFilterList._TreeAddItem(TREE_ROOT_INDEX,filter_names[index],TREE_ADD_AS_CHILD,0,0,-1);
   }

   index=target_index;
   if (index<0) {
      index=0;
   } else if (index>=filter_names._length()) {
      index=filter_names._length()-1;
   }
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);

   if (filter_names._length()==0) {
      ctlFilterDown.p_enabled=false;
      ctlFilterUp.p_enabled=false;
      ctlFilterRemove.p_enabled=false;
      ctlFilterValue.p_text='';
   } else {
      ctlFilterList._TreeSetCurIndex(filter_nodes[index]);
      ctlFilterRemove.p_enabled=true;
      update_value();
   }
}

static void update_value()
{
   // deselect the value
   ctlFilterValue._set_sel(1);

   int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);

   ctlFilterValue.p_text=filter_values[index];

   ctlFilterDown.p_enabled=((index+1)<filter_values._length());
   ctlFilterUp.p_enabled=(index>0);
}

void ctlFilterList.on_change(int reason)
{
   if (reason==CHANGE_CLINE || reason==CHANGE_SELECTED) {
      int cur_node=_TreeCurIndex();

      int index=0;
      int node_index=_TreeGetFirstChildIndex(TREE_ROOT_INDEX);

      while (node_index>=0 && node_index!=cur_node) {
         ++index;
         node_index=_TreeGetNextIndex(node_index);
      }

      _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);
      if (index<filter_values._length()) {
         _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);
         update_value();
      }
   } else if (reason==CHANGE_EDIT_CLOSE && arg(4):!='') {
      _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
      int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

      filter_names[index]=arg(4);

      _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   }
}

void ctlFilterNew.lbutton_up()
{
   _str promptResult = show("-modal _textbox_form",
                            "Add New Filter",            // title of dialog box
                            0,                           // flags
                            "",                          // text box width
                            "Add New Filter dialog",     // help item
                            "",                          // button and caption list
                            "",                          // retrieve name
                            "Filter name:" "");          // prompt

   if (promptResult:=='') {
      return;
   }

   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);

   int index=filter_names._length();
   filter_names[index]=_param1;
   filter_values[index]=ALLFILES_RE;

   _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);

   update_filters();
}

static void move_filter_up()
{
   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);
   int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

   if (index==0) {
      return;
   }

   _str temp_name=filter_names[index-1];
   _str temp_value=filter_values[index-1];
   filter_names[index-1]=filter_names[index];
   filter_values[index-1]=filter_values[index];
   filter_names[index]=temp_name;
   filter_values[index]=temp_value;
   --index;

   _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);

   update_filters();
}

void ctlFilterUp.lbutton_up()
{
   p_active_form._set_focus();
   move_filter_up();
}

void ctlFilterList.'C-UP'()
{
   move_filter_up();
}

static void move_filter_down()
{
   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);
   int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

   if ((index+1)>=filter_names._length()) {
      return;
   }

   _str temp_name=filter_names[index+1];
   _str temp_value=filter_values[index+1];
   filter_names[index+1]=filter_names[index];
   filter_values[index+1]=filter_values[index];
   filter_names[index]=temp_name;
   filter_values[index]=temp_value;
   ++index;

   _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);

   update_filters();
}

void ctlFilterDown.lbutton_up()
{
   p_active_form._set_focus();
   move_filter_down();
}

void ctlFilterList.'C-DOWN'()
{
   move_filter_down();
}

static void remove_filter()
{
   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);
   int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

   filter_names._deleteel(index);
   filter_values._deleteel(index);
   if (index==filter_names._length()) {
      --index;
   }

   _SetDialogInfo(FILTER_FORM_FILTER_NAMES,filter_names);
   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
   _SetDialogInfo(FILTER_FORM_CURRENT_FILTER,index);

   update_filters();
}

void ctlFilterRemove.lbutton_up()
{
   p_active_form._set_focus();
   remove_filter();
}

ctlFilterList.'DEL'()
{
   remove_filter();
}

ctlFilterValue.on_lost_focus()
{
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);
   int index=_GetDialogInfo(FILTER_FORM_CURRENT_FILTER);

   filter_values[index]=p_text;

   _SetDialogInfo(FILTER_FORM_FILTER_VALUES,filter_values);
}

_str compile_filter_string()
{
   _str filter_names[]=_GetDialogInfo(FILTER_FORM_FILTER_NAMES);
   _str filter_values[]=_GetDialogInfo(FILTER_FORM_FILTER_VALUES);

   result := '';

   int index;
   for (index=0; index < filter_names._length(); ++index) {
      if (result :!= '') {
         strappend(result,',');
      }
      strappend(result,filter_names[index]);
      strappend(result,' (');
      strappend(result,filter_values[index]);
      strappend(result,')');
   }

   return result;
}

void ctlok.lbutton_up()
{
   _param1=compile_filter_string();
   p_active_form._delete_window('1');
}

_str _edit_folder_filters(_str & filters)
{
   boolean generated_default=false;

   if (filters:=='') {
      generated_default=true;

      int index;
      for (index=0;index<NewFolderInfo._length();++index) {
         if(index>0) {
            strappend(filters,',');
         }
         strappend(filters,NewFolderInfo[index].FolderName:+'('NewFolderInfo[index].Filters:+')');
      }
   }

   // display form
   _str result=show('-modal _filter_form',
                    filters,
                    true);      // use_folders


   if (result:=='') {
      // don't return the defaults that will be automatically generated
      // if the user doesn't modify them
      if (generated_default) {
         filters='';
      }
   } else {
      // don't return the defaults that will be automatically generated
      // if the user doesn't modify them
      if (generated_default && (_param1:==filters)) {
         filters='';
      } else {
         filters=_param1;
      }
   }

   return result;
}
