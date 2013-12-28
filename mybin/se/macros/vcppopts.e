////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#import "applet.e"
#import "cjava.e"
#import "compile.e"
#import "files.e"
#import "guicd.e"
#import "gnucopts.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "projmake.e"
#import "projutil.e"
#import "refactor.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "wizard.e"
#import "wkspace.e"
#import "sstab.e"
#endregion


// project type
#define VCPP_WIZ_PTYPE_EXE    (0)
#define VCPP_WIZ_PTYPE_DLL    (1)

// application type
#define VCPP_WIZ_ATYPE_EMPTY  (0)
#define VCPP_WIZ_ATYPE_MAIN   (1)
#define VCPP_WIZ_ATYPE_WORLD  (2)

// build system
#define VCPP_WIZ_SYS_VSBUILD  (0)
#define VCPP_WIZ_SYS_MAKE     (1)
#define VCPP_WIZ_SYS_AUTO     (2)

struct VCPP_WIZARD_INFO
{
   typeless callback_table:[];
   int projectType;
   int appType;
   int buildSystem;
   _str makefile;
   _str toolkitDir;
   boolean isCPP;
   boolean isX64;

   //NEEDED
   /*
      PCH
      command line app (?)
   */
};

// global variable to store collected information from the wizard
VCPP_WIZARD_INFO gVCPPWizardInfo;

defeventtab _vcpp_wizard_form;

static int vcpp_slide0create()
{
   _str pName=_strip_filename(_project_name,'PE');

   ctls0_Executable.p_caption=      ctls0_Executable.p_caption' ('pName'.exe)';
   ctls0_DynamicLibrary.p_caption=  ctls0_DynamicLibrary.p_caption' ('pName'.dll)';

   return 0;
}

static int vcpp_slide0shown()
{
   switch (gVCPPWizardInfo.projectType) {
   case VCPP_WIZ_PTYPE_EXE:
      {
         ctls0_Executable.p_value=1;
      }
      break;
   case VCPP_WIZ_PTYPE_DLL:
      {
         ctls0_DynamicLibrary.p_value=1;
      }
      break;
   }

   if (gVCPPWizardInfo.isCPP) {
      ctls0_cpp.p_value=1;
   } else {
      ctls0_c.p_value=1;
   }

   return 0;
}

static int vcpp_slide0next()
{
   if (ctls0_Executable.p_value) {
      gVCPPWizardInfo.projectType=VCPP_WIZ_PTYPE_EXE;
   } else if (ctls0_DynamicLibrary.p_value) {
      gVCPPWizardInfo.projectType=VCPP_WIZ_PTYPE_DLL;
   }

   gVCPPWizardInfo.isCPP=(ctls0_cpp.p_value!=0);

   WIZARD_INFO* info=_WizardGetPointerToInfo();

   // this could be combined with the above if block, but
   // this is a little cleaner

   if (gVCPPWizardInfo.projectType==VCPP_WIZ_PTYPE_EXE) {
      info->callbackTable:['ctlslide1.skip']=null;
   } else {
      info->callbackTable:['ctlslide1.skip']=1;
   }

   return 0;
}

static int vcpp_slide1create()
{
   // NO-OP
   return 0;
}

static int vcpp_slide1shown()
{
   switch (gVCPPWizardInfo.appType) {
   case VCPP_WIZ_ATYPE_EMPTY:
      {
         ctls1_EmptyProject.p_value=1;
      }
      break;
   case VCPP_WIZ_ATYPE_MAIN:
      {
         ctls1_AppWithMain.p_value=1;
      }
      break;
   case VCPP_WIZ_ATYPE_WORLD:
      {
         ctls1_HelloWorldApp.p_value=1;
      }
      break;
   }

   return 0;
}

static int vcpp_slide1next()
{
   if (ctls1_EmptyProject.p_value) {
      gVCPPWizardInfo.appType=VCPP_WIZ_ATYPE_EMPTY;
   } else if (ctls1_AppWithMain.p_value) {
      gVCPPWizardInfo.appType=VCPP_WIZ_ATYPE_MAIN;
   } else if (ctls1_HelloWorldApp.p_value) {
      gVCPPWizardInfo.appType=VCPP_WIZ_ATYPE_WORLD;
   }

   return 0;
}

static int vcpp_slide1back()
{
   return vcpp_slide1next();
}

static int vcpp_slide2create()
{
   // NO-OP
   return 0;
}

static int vcpp_slide2shown()
{
   switch (gVCPPWizardInfo.buildSystem) {
   case VCPP_WIZ_SYS_VSBUILD:
      {
         ctls2_vsbuild.p_value=1;
      }
      break;
   case VCPP_WIZ_SYS_MAKE:
      {
         ctls2_Makefile.p_value=1;
      }
      break;
   case VCPP_WIZ_SYS_AUTO:
      {
         ctls2_AutoMakefile.p_value=1;
      }
      break;
   }

   ctlMakefile.p_text=gVCPPWizardInfo.makefile;

   return 0;
}

static int vcpp_slide2next()
{
   // store the build system
   if(ctls2_vsbuild.p_value) {
      gVCPPWizardInfo.buildSystem=VCPP_WIZ_SYS_VSBUILD;
   } else if(ctls2_Makefile.p_value) {
      gVCPPWizardInfo.buildSystem=VCPP_WIZ_SYS_MAKE;
   } else if (ctls2_AutoMakefile.p_value) {
      gVCPPWizardInfo.buildSystem=VCPP_WIZ_SYS_AUTO;
   }
   gVCPPWizardInfo.makefile=strip(ctlMakefile.p_text);

   if (gVCPPWizardInfo.makefile:=='') {
      gVCPPWizardInfo.makefile='%rp%rn.mak';
   }

   return 0;
}

static int vcpp_slide2back()
{
   return vcpp_slide2next();
}

void ctls2_vsbuild.lbutton_up()
{
   // disable the makefile textbox
   ctlMakefileExplanation.p_enabled=false;
   ctlMakefileLabel.p_enabled=false;
   ctlMakefile.p_enabled=false;
   ctlMakefileExpanded.p_enabled=false;
}

void ctls2_Makefile.lbutton_up()
{
   // disable the makefile textbox
   ctlMakefileExplanation.p_enabled=false;
   ctlMakefileLabel.p_enabled=false;
   ctlMakefile.p_enabled=false;
   ctlMakefileExpanded.p_enabled=false;
}

void ctls2_AutoMakefile.lbutton_up()
{
   // enable the makefile textbox
   ctlMakefileExplanation.p_enabled=true;
   ctlMakefileLabel.p_enabled=true;
   ctlMakefile.p_enabled=true;
   ctlMakefileExpanded.p_enabled=true;
}

static _str get_expanded_makefile()
{
   return _parse_project_command(ctlMakefile.p_text,'',_project_name,'');
}

void ctlMakefile.on_change()
{
   ctlMakefileExpanded.p_caption='('get_expanded_makefile()')';
}

static int vcpp_show_new_project_info()
{
   int status=0;

   _str line='';
   _add_line_to_html_caption(line,'<B>Project Type:</B>');
   switch (gVCPPWizardInfo.projectType) {
   case VCPP_WIZ_PTYPE_EXE:
      {
         _add_line_to_html_caption(line,ctls0_Executable.p_caption);
      }
      break;
   case VCPP_WIZ_PTYPE_DLL:
      {
         _add_line_to_html_caption(line,ctls0_DynamicLibrary.p_caption);
      }
      break;
   }
   _add_line_to_html_caption(line,'');

   if (gVCPPWizardInfo.projectType==VCPP_WIZ_PTYPE_EXE) {
      _add_line_to_html_caption(line,'<B>Application Type:</B>');
      switch (gVCPPWizardInfo.appType) {
      case VCPP_WIZ_ATYPE_EMPTY:
         {
            _add_line_to_html_caption(line,ctls1_EmptyProject.p_caption);
         }
         break;
      case VCPP_WIZ_ATYPE_MAIN:
         {
            _add_line_to_html_caption(line,ctls1_AppWithMain.p_caption);
         }
         break;
      case VCPP_WIZ_ATYPE_WORLD:
         {
            _add_line_to_html_caption(line,ctls1_HelloWorldApp.p_caption);
         }
         break;
      }
      _add_line_to_html_caption(line,'');
   }
   _add_line_to_html_caption(line,'<B>Build System:</B>');
   switch (gVCPPWizardInfo.buildSystem) {
   case VCPP_WIZ_SYS_VSBUILD:
      {
         _add_line_to_html_caption(line,ctls2_vsbuild.p_caption);
      }
      break;
   case VCPP_WIZ_SYS_MAKE:
      {
         _add_line_to_html_caption(line,ctls2_Makefile.p_caption);
      }
      break;
   case VCPP_WIZ_SYS_AUTO:
      {
         _add_line_to_html_caption(line,ctls2_AutoMakefile.p_caption);

         _str expanded_makefile=get_expanded_makefile();
         if (expanded_makefile:==gVCPPWizardInfo.makefile) {
            _add_line_to_html_caption(line,'Makefile: 'gVCPPWizardInfo.makefile);
         } else {
            _add_line_to_html_caption(line,'Makefile: 'gVCPPWizardInfo.makefile' ('expanded_makefile')');
         }
      }
      break;
   }

   status=show('-modal _new_project_info_form',
               "Visual C++ Toolkit wizard will create a skeleton project for you with\n":+
               'the following specifications:',
               line);
   if(status=='') {
      return COMMAND_CANCELLED_RC;
   }

   return status;
}

static int generate_cppmain(_str& filename,boolean useCOnly,boolean addHelloWorld)
{
   // build filename with appropriate extension
   filename=_strip_filename(_project_name,'E') :+ (useCOnly ? ".c" : ".cpp");

   // if the file already exists, see if it should be overwritten
   if (file_exists(filename)) {
      int result=_message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),'',MB_YESNOCANCEL);
      if(result==IDCANCEL) {
         return COMMAND_CANCELLED_RC;
      } else if(result==IDNO) {
         return 1;
      }
   }

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str helloWorldLine='';
   if (addHelloWorld) {
      if (useCOnly) {
         helloWorldLine='printf("Hello, World\n");';
      } else {
         helloWorldLine='cout << "Hello, World" << endl;';
      }
   }

   _str template_name='new_'(useCOnly ? 'c' : 'cpp')'_file';

   int status=expand_surround_with(helloWorldLine,true,template_name,false);

   if (status) {
      _message_box("The surround_with template \""template_name"\" could not be found.\n\nA default template will be used.");

      _str indentStr=indent_string(p_SyntaxIndent);

      if(useCOnly) {
         insert_line('#include <stdio.h>');
         insert_line('');
         insert_line('int main (int argc, char *argv[])');
         insert_line('{');
         if(addHelloWorld) {
            insert_line(indentStr:+helloWorldLine);
         }
         insert_line(indentStr'return(0);');
         insert_line('}');
         insert_line('');
      } else {
         insert_line('#include <iostream>');
         insert_line('');
         insert_line('using namespace std;');
         insert_line('');
         insert_line('int main (int argc, char *argv[])');
         insert_line('{');
         if(addHelloWorld) {
            insert_line(indentStr:+helloWorldLine);
         }
         insert_line(indentStr'return(0);');
         insert_line('}');
         insert_line('');
      }
   }

   status=_save_file('+o');
   _AddFileToProject(filename);

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return status;
}

static int vcpp_finish()
{
   // with the right series of pressing next and back it is possible
   // to have the project type not be EXE and application type not
   // be EMPTY.  vcpp_slide0next could check this but it is better
   // to always show slide two as the user left it.
   if (gVCPPWizardInfo.projectType!=VCPP_WIZ_PTYPE_EXE) {
      gVCPPWizardInfo.appType=VCPP_WIZ_ATYPE_EMPTY;
   }

   // show recap form
   int status=vcpp_show_new_project_info();
   if(status) return status;

   int orig_view_id=p_window_id;

   // check to see if anything should be generated
   if (gVCPPWizardInfo.appType!=VCPP_WIZ_ATYPE_EMPTY) {
      _str file_name='';
      status=generate_cppmain(file_name,!gVCPPWizardInfo.isCPP,gVCPPWizardInfo.appType==VCPP_WIZ_ATYPE_WORLD);
      // generate_cppmain can return 1, meaning the file already exists
      if (status<0) {
         p_window_id=orig_view_id;
         return status;
      }

      // edit the file that was just created
      status = edit(maybe_quote_filename(file_name));
   }

   // restore the view id
   p_window_id=orig_view_id;

   // collect compiler information.  Really only looking for compilers.hasToolkit
   available_compilers compilers;
   _str c_compiler_names[];
   _str java_compiler_names[];
   refactor_get_compiler_configurations(c_compiler_names, java_compiler_names);
   _evaluate_compilers(compilers,c_compiler_names);

   // load the configuration list from the project file
   
   int project_handle=_ProjectHandle();
   _str config_list[]=null;
   _ProjectGet_ConfigNames(project_handle,config_list);

   // update the project file to reflect the selections
   int i;
   for(i=0;i<config_list._length();++i) {
      // find the config node
      int config_node=_ProjectGet_ConfigNode(project_handle,config_list[i]);
      if(config_node<0) continue;

      if (gVCPPWizardInfo.isX64 && compilers.hasPlatformSDK) {
         _ProjectSet_CompilerConfigName(project_handle,COMPILER_NAME_PLATFORM_SDK2003,config_list[i]);
      } else if (compilers.hasToolkit) {
         _ProjectSet_CompilerConfigName(project_handle,COMPILER_NAME_VCPP_TOOLKIT2003,config_list[i]);
      }

      _str includeDirs[];
      if (compilers.hasToolkit) {
         _str dir = getVcppToolkitPath2003();
         if (dir != '') {
            _maybe_append_filesep(dir);
            includeDirs[includeDirs._length()] = dir'include';
         }
      }
      if (compilers.hasPlatformSDK) {
         _str dir = getVcppPlatformSDKPath2003();
         if (dir != '') {
            _maybe_append_filesep(dir);
            includeDirs[includeDirs._length()] = dir'include';
         }
      }
      if (includeDirs._length() > 0) {
         _ProjectSet_Includes(project_handle, includeDirs, config_list[i]);
      }

      // find the relevant target nodes
      int compile_target_node=_ProjectGet_TargetNode(project_handle,'compile',config_list[i]);
      int link_target_node=_ProjectGet_TargetNode(project_handle,'link',config_list[i]);
      int debug_target_node=_ProjectGet_TargetNode(project_handle,'debug',config_list[i]);
      int execute_target_node=_ProjectGet_TargetNode(project_handle,'execute',config_list[i]);
      int build_target_node=_ProjectGet_TargetNode(project_handle,'build',config_list[i]);
      int rebuild_target_node=_ProjectGet_TargetNode(project_handle,'rebuild',config_list[i]);
      boolean is_debug_target=(stricmp('Debug',config_list[i])==0);

      _str extra_compile_options='';

      _str sdkDir = '';
      if (gVCPPWizardInfo.isX64) {
         extra_compile_options='/EHsc ';
         sdkDir = gVCPPWizardInfo.toolkitDir;
         if (sdkDir != '') _maybe_append_filesep(sdkDir);
      } else if (gVCPPWizardInfo.isCPP) {
         extra_compile_options='/GX ';
      }

      if (sdkDir != '') {
         _str command=_ProjectGet_TargetCmdLine(project_handle,link_target_node);
         command = stranslate(command, sdkDir'bin\win64\', '%(VCTOOLKITINSTALLDIR)bin\');
         command = stranslate(command, sdkDir, "%(VCTOOLKITINSTALLDIR)");
         _ProjectSet_TargetCmdLine(project_handle,link_target_node,command);

         command=_ProjectGet_TargetCmdLine(project_handle,compile_target_node);
         command = stranslate(command, sdkDir'bin\win64\', '%(VCTOOLKITINSTALLDIR)bin\');
         command = stranslate(command, sdkDir, "%(VCTOOLKITINSTALLDIR)");
         _ProjectSet_TargetCmdLine(project_handle,compile_target_node,command);
      }

      // change the link command to build the appropriate type of output
      switch(gVCPPWizardInfo.projectType) {
         case VCPP_WIZ_PTYPE_DLL: {
            strappend(extra_compile_options,'/LD');

            // make sure the output filename ends with '.dll'
            _str output_file=_ProjectGet_OutputFile(project_handle,config_list[i]);
            if(pos('[.]dll$',output_file,1,'U') == 0) {
               strappend(output_file,'.dll');
               _ProjectSet_OutputFile(project_handle,output_file,config_list[i]);
            }

            // get the link command and add /DLL to it
            _str command=_ProjectGet_TargetCmdLine(project_handle,link_target_node);
            strappend(command,' /DLL');
            if (is_debug_target) {
               strappend(command,' /DEBUG /PDB:"':+_strip_filename(output_file,'E'):+'.pdb"');
            }
            _ProjectSet_TargetCmdLine(project_handle,link_target_node,command);

            // clear the debug and execute commands
            _ProjectSet_TargetCmdLine(project_handle,debug_target_node,'');
            _ProjectSet_TargetCmdLine(project_handle,execute_target_node,'');

            break;
         }

         case VCPP_WIZ_PTYPE_EXE: {
            strappend(extra_compile_options,'/ML');

            // make sure the executable ends with '.exe'
            _str output_file=_ProjectGet_OutputFile(project_handle,config_list[i]);
            if(pos('[.]exe$',output_file,1,'U')==0) {
               strappend(output_file,'.exe');
               _ProjectSet_OutputFile(project_handle, output_file, config_list[i]);
            }

            // get the link command and add /DEBUG and /PDB to it
            if (is_debug_target) {
               _str command=_ProjectGet_TargetCmdLine(project_handle,link_target_node);
               strappend(command,' /DEBUG /PDB:"':+_strip_filename(output_file,'E'):+'.pdb"');
               _ProjectSet_TargetCmdLine(project_handle,link_target_node,command);
            }
            break;
         }

         default:
            break;
      }

      // add the optimization option and default defines
      if (is_debug_target) {
         strappend(extra_compile_options,'d /Od /Zi /Fd"':+_strip_filename(_ProjectGet_OutputFile(project_handle,config_list[i]),'E'):+'.pdb"');
         _ProjectSet_Defines(project_handle,'/DWIN32 /D_DEBUG /D_MBCS',config_list[i]);
      } else {
         strappend(extra_compile_options,' /Ox');
         _ProjectSet_Defines(project_handle,'/DWIN32 /D_MBCS',config_list[i]);
      }
      _str command=_ProjectGet_TargetCmdLine(project_handle,compile_target_node);
      _str compiler = parse_file(command);
      _str opts = command;
      _ProjectSet_TargetCmdLine(project_handle,compile_target_node,compiler' 'extra_compile_options' 'opts,'','/nologo');

      if(status) return status;

      // change the make/rebuild commands to the appropriate build command
      switch(gVCPPWizardInfo.buildSystem) {
         case VCPP_WIZ_SYS_AUTO: {
            // add buildsystem and makefile to GLOBAL section, defaulting the value to '%rp%rn.mak'
            _ProjectSet_BuildSystem(project_handle,'automakefile');

            // add the makefile to the project
            // NOTE: this should be done *before* the 'makefile' value is set in the 'GLOBAL'
            //       section to avoid triggering the makefile regeneration when the makefile
            //       is added
            _AddFileToProject(_parse_project_command(gVCPPWizardInfo.makefile,'',_project_name,''));
            _ProjectSet_BuildMakeFile(project_handle,gVCPPWizardInfo.makefile);

            // replace build command with "make makefilename" and clear the dialog
            _str makeCommand=_findGNUMake():+' -f "':+gVCPPWizardInfo.makefile:+'" CFG=%b';
            _ProjectSet_TargetCmdLine(project_handle,build_target_node,makeCommand);
            _ProjectSet_TargetDialog(project_handle,build_target_node,'');

            // replace rebuild command with "make makefilename" and clear the dialog
            _str rebuildCommand=_findGNUMake():+' -f "':+gVCPPWizardInfo.makefile:+'" rebuild CFG=%b';
            _ProjectSet_TargetCmdLine(project_handle,rebuild_target_node,rebuildCommand);
            _ProjectSet_TargetDialog(project_handle,rebuild_target_node,'');
            break;
         }

         case VCPP_WIZ_SYS_MAKE: {
            // replace make command with "make makefilename" and clear the dialog
            _ProjectSet_TargetCmdLine(project_handle,build_target_node,'make');
            _ProjectSet_TargetDialog(project_handle,build_target_node,'');

            // clear the rebuild command
            _ProjectSet_TargetCmdLine(project_handle,rebuild_target_node,'');
            _ProjectSet_TargetDialog(project_handle,rebuild_target_node,'');
            break;
         }

         case VCPP_WIZ_SYS_VSBUILD:
            _ProjectSet_BuildSystem(project_handle,'vsbuild');
            break;

         default:
            break;
      }
   }

   // save the project file
   _ProjectSave(project_handle);

   // if this should have an autogenerated makefile, do it now
   if(gVCPPWizardInfo.buildSystem==VCPP_WIZ_SYS_AUTO) {
      generate_makefile(_project_name,'',false,false);
   }

   // if this was an empty project, open the project properties
   if (gVCPPWizardInfo.appType==VCPP_WIZ_ATYPE_EMPTY) {
      project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
   }

   return 0;
}

_command int vcpp_wizard(_str path='', _str isX64='')
{
   // Check if the Visual C++ Toolkit is installed
   _str toolkit_dir=get_env('VCTOOLKITINSTALLDIR');
   if (isX64 != '') {
      toolkit_dir = getVcppPlatformSDKPath2003();
   } else if (toolkit_dir=='') {
      toolkit_dir = getVcppToolkitPath2003();
      if (toolkit_dir != '' && file_exists(toolkit_dir)) {
         _message_box('The environment variable VCTOOLKITINSTALLDIR is not set.  This project might not build correctly.');
      }
   }
   if (toolkit_dir:=='') {
      if (isX64 != '') {
         _message_box('Can not find Visual C++ X64 Platform SDK. This project might not build correctly.');
      } else {
         _message_box('Can not find Visual C++ Toolkit. This project might not build correctly.');
      }
   }

   // setup callback table
   gVCPPWizardInfo.callback_table._makeempty();
   gVCPPWizardInfo.callback_table:['ctlslide0.create']=  vcpp_slide0create;
   gVCPPWizardInfo.callback_table:['ctlslide0.shown']=   vcpp_slide0shown;
   gVCPPWizardInfo.callback_table:['ctlslide0.next']=    vcpp_slide0next;
   gVCPPWizardInfo.callback_table:['ctlslide1.create']=  vcpp_slide1create;
   gVCPPWizardInfo.callback_table:['ctlslide1.shown']=   vcpp_slide1shown;
   gVCPPWizardInfo.callback_table:['ctlslide1.next']=    vcpp_slide1next;
   gVCPPWizardInfo.callback_table:['ctlslide1.back']=    vcpp_slide1back;
   gVCPPWizardInfo.callback_table:['ctlslide2.create']=  vcpp_slide2create;
   gVCPPWizardInfo.callback_table:['ctlslide2.shown']=   vcpp_slide2shown;
   gVCPPWizardInfo.callback_table:['ctlslide2.next']=    vcpp_slide2next;
   gVCPPWizardInfo.callback_table:['ctlslide2.back']=    vcpp_slide2back;
   gVCPPWizardInfo.callback_table:['finish']=            vcpp_finish;

   // setup other defaults
   gVCPPWizardInfo.projectType=VCPP_WIZ_PTYPE_EXE;
   gVCPPWizardInfo.appType=VCPP_WIZ_ATYPE_EMPTY;
   gVCPPWizardInfo.buildSystem=VCPP_WIZ_SYS_VSBUILD;
   gVCPPWizardInfo.makefile='%rp%rn.mak';
   gVCPPWizardInfo.isCPP=true;
   gVCPPWizardInfo.isX64=(isX64!='');
   gVCPPWizardInfo.toolkitDir=toolkit_dir;

   // setup wizard
   WIZARD_INFO info;
   info.callbackTable=gVCPPWizardInfo.callback_table;
   info.parentFormName='_vcpp_wizard_form';
   if (isX64 != '') {
      info.dialogCaption='Create Visual C++ X64 Platform SDK Project';
   } else {
      info.dialogCaption='Create Visual C++ Toolkit Project';
   }

   // start the wizard
   int status=_Wizard(&info);

   // free up some memory
   gVCPPWizardInfo.callback_table._makeempty();

   if(status=='') {
      return COMMAND_CANCELLED_RC;
   }

   return status;
}
_command int vcpp_wizard_x64(_str path='')
{
   return vcpp_wizard(path, 'x64');
}

//NOTE: If any of these values are changed, or if new
//values are added, setup_controls must also be updated
#define VCPP_COMPILE_AS_DEFAULT    (1)
#define VCPP_COMPILE_AS_C          (2)
#define VCPP_COMPILE_AS_CPP        (3)

#define VCPP_USE_PCH_NONE          (1)
#define VCPP_USE_PCH_CREATE        (2)
#define VCPP_USE_PCH_USE           (3)
#define VCPP_USE_PCH_AUTO          (4)

#define VCPP_DEBUG_FORMAT_NONE     (1)
#define VCPP_DEBUG_FORMAT_C7       (2)
#define VCPP_DEBUG_FORMAT_LINE_NUM (3)
#define VCPP_DEBUG_FORMAT_PDB      (4)
#define VCPP_DEBUG_FORMAT_EDIT     (5)

#define VCPP_TYPE_CHECK_DEFAULT    (1)
#define VCPP_TYPE_CHECK_FAST       (2)
#define VCPP_TYPE_CHECK_STACK      (3)
#define VCPP_TYPE_CHECK_LOCAL      (4)

#define VCPP_CONVENTION_CDECL      (1)
#define VCPP_CONVENTION_FASTCALL   (2)
#define VCPP_CONVENTION_STDCALL    (3)

#define VCPP_ENHANCED_INST_DEFAULT (1)
#define VCPP_ENHANCED_INST_SSE     (2)
#define VCPP_ENHANCED_INST_SSE2    (3)

#define VCPP_OPT_LEVEL_NONE        (1)
#define VCPP_OPT_LEVEL_SPACE       (2)
#define VCPP_OPT_LEVEL_SPEED       (3)
#define VCPP_OPT_LEVEL_MAX         (4)

#define VCPP_OPT_FAVOR_NONE        (1)
#define VCPP_OPT_FAVOR_SPACE       (2)
#define VCPP_OPT_FAVOR_SPEED       (3)

#define VCPP_INLINE_DEFAULT        (1)
#define VCPP_INLINE_ONLY           (2)
#define VCPP_INLINE_ANY            (3)

#define VCPP_PROCESSOR_386         (1)
#define VCPP_PROCESSOR_486         (2)
#define VCPP_PROCESSOR_PENT        (3)
#define VCPP_PROCESSOR_PPRO        (4)
#define VCPP_PROCESSOR_P4          (5)
#define VCPP_PROCESSOR_BLEND       (6)

#define VCPP_OUTPUT_EXE            (1)
#define VCPP_OUTPUT_DLL            (2)

#define VCPP_WARNING_LEVEL_0       (1)
#define VCPP_WARNING_LEVEL_1       (2)
#define VCPP_WARNING_LEVEL_2       (3)
#define VCPP_WARNING_LEVEL_3       (4)
#define VCPP_WARNING_LEVEL_4       (5)
#define VCPP_WARNING_LEVEL_ALL     (6)

struct VCPP_OPTIONS {
   // nodes in the project file
   int      compileTargetNode;
   int      linkTargetNode;
   int      debugTargetNode;
   int      executeTargetNode;

   // configuration settings
   _str     compiler;
   _str     otherCompileOptions;
   _str     defines;
   boolean  forScope;
   boolean  nativeWchar;
   boolean  unsignChar;
   int      compileAs;
   int      usePCH;
   _str     pchThrough;
   _str     pchFile;
   int      debugFormat;
   _str     pdbFile;
   int      typeChecks;
   boolean  smallTypeCheck;
   boolean  bufferCheck;
   int      convention;
   int      enhancedInstSet;
   boolean  functionLink;
   boolean  RTTI;
   boolean  exceptionHandling;
   boolean  minimalRebuild;
   int      optLevel;
   int      optFavor;
   int      inlineExpansion;
   int      optProcessor;
   boolean  optGlobal;
   boolean  optIntrinsic;
   boolean  optFiber;
   boolean  optFloat;
   boolean  optString;
   boolean  optWindows;
   boolean  optFrame;
   boolean  noDefaultLibs;
   boolean  incrementalLinking;
   boolean  linkDebug;
   boolean  linkMultiThread;
   int      outputType;
   _str     linker;
   _str     outputFile;
   _str     libraries;
   _str     objectLocation;
   _str     otherLinkOptions;
   boolean  ignoreStdInc;
   _str     includeDirs[];
   _str     libDirs[];
   int      warningLevel;
   boolean  warnAsErr;
   boolean  warn64bit;
   boolean  useCLR;
   boolean  noAssembly;
   _str     assemblies[];
   _str     assemblyDirs[];
   _str     arguments;
   boolean  useBuiltinDebug;
   _str     debugger;
   _str     debuggerOptions;
};

// constants to use with _SetDialogInfo and _GetDialogInfo
#define VCPP_OPTS_CHANGING_CONFIG      (0)
#define VCPP_OPTS_CONFIG_LIST          (1)
#define VCPP_OPTS_ALL_CONFIG_OPTIONS   (2)
#define VCPP_OPTS_ALL_CONFIGS_ACTIVE   (3)
#define VCPP_OPTS_PROJECT_NAME         (4)
#define VCPP_OPTS_PROJECT_HANDLE       (5)


defeventtab _vcpp_options_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _vcpp_options_form_initial_alignment()
{
   // this form is not sizable, but we need to do some alignment adjusting for auto-sized
   // buttons - this will happen when the form is first shown
   tabWidth := ctlMainTab.p_child.p_width;
   padding := ctlLanguageOptionsFrame.p_x;

   // compile tab
   sizeBrowseButtonToTextBox(ctlCompiler.p_window_id, ctlBrowseCompiler.p_window_id, 0, ctlframe1.p_x + ctlframe1.p_width);

   // link tab
   sizeBrowseButtonToTextBox(ctlLinker.p_window_id, ctlBrowseLinker.p_window_id, 0, ctlOutputType.p_x + ctlOutputType.p_width);
   sizeBrowseButtonToTextBox(ctlLibraries.p_window_id, ctlLinkOrder.p_window_id, 0, ctlOutputType.p_x + ctlOutputType.p_width);

   // directories tab
   // these labels are auto-sized, adjust for them
   newX := ctlIncDirLabel.p_x + ctlIncDirLabel.p_width;
   if (newX < (ctllabel20.p_x + ctllabel20.p_width)) {
      newX = ctllabel20.p_x + ctllabel20.p_width;
   }
   newX += 25;
   ctlLibDirs.p_x = ctlUserIncludesList.p_x = newX;

   rightAlign := tabWidth - (padding intdiv 2);
   alignUpDownListButtons(ctlUserIncludesList.p_window_id, rightAlign, ctlBrowseUserIncludes.p_window_id, ctlMoveUserIncludesUp.p_window_id,
                          ctlMoveUserIncludesDown.p_window_id, ctlRemoveInclude.p_window_id);
   alignUpDownListButtons(ctlLibDirs.p_window_id, rightAlign, ctlBrowseLibDirs.p_window_id, ctlMoveLibDirsUp.p_window_id,
                          ctlMoveLibDirsDown.p_window_id, ctlRemoveLibDir.p_window_id);

   // .net
   ctlBrowseAssemblies.p_x = tabWidth - padding - ctlBrowseAssemblies.p_width;
   ctlAssemblyDirs.p_width = ctlAssemblies.p_width = ctlBrowseAssemblies.p_x - 25 - ctlAssemblies.p_x;
   ctlMoveAssembliesUp.p_x = ctlMoveAssembliesDown.p_x = ctlRemoveAssembly.p_x = ctlBrowseAssemblyDirs.p_x = 
      ctlMoveAssemblyDirsUp.p_x = ctlMoveAssemblyDirsDown.p_x = ctlRemoveAssemblyDir.p_x = ctlBrowseAssemblies.p_x;
   alignUpDownListButtons(ctlAssemblies.p_window_id, ctlBrowseAssemblies.p_window_id,
                          ctlMoveAssembliesUp.p_window_id, ctlMoveAssembliesDown.p_window_id, ctlRemoveAssembly.p_window_id);
   alignUpDownListButtons(ctlAssemblyDirs.p_window_id, ctlBrowseAssemblyDirs.p_window_id, ctlMoveAssemblyDirsUp.p_window_id,
                          ctlMoveAssemblyDirsDown.p_window_id, ctlRemoveAssemblyDir.p_window_id);

   // run/debug
   sizeBrowseButtonToTextBox(ctldbgDebugger.p_window_id, ctldbgFindApp.p_window_id, 0, ctldbgOtherDebuggerOptions.p_x + ctldbgOtherDebuggerOptions.p_width);
}

static void select_cb_item(int index)
{
   _lbdeselect_all();
   p_line=index;
   _lbselect_line();
   p_text=_lbget_seltext();
}

static void set_listbox_items(typeless listbox,_str (&items)[])
{
   boolean was_changing_config=_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG);

   if (!was_changing_config) {
      _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,true);
   }

   listbox._TreeDelete(TREE_ROOT_INDEX,'C');

   int item_index;
   for (item_index=0;item_index<items._length();++item_index) {
      listbox._TreeAddItem(TREE_ROOT_INDEX,items[item_index],TREE_ADD_AS_CHILD,-1,-1,-1,0);
   }

   if (!was_changing_config) {
      _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,false);
   }
}

static void get_listbox_items(typeless listbox,_str (&items)[])
{
   items._makeempty();

   int index=listbox._TreeGetFirstChildIndex(TREE_ROOT_INDEX);

   while (index>0) {
      items[items._length()]=listbox._TreeGetCaption(index);
      index=listbox._TreeGetNextSiblingIndex(index);
   }
}

static void add_listbox_item(typeless listbox,_str item)
{
   listbox._TreeAddItem(TREE_ROOT_INDEX,item,TREE_ADD_AS_CHILD,-1,-1,-1,0);
   call_event(CHANGE_SELECTED,listbox._TreeCurIndex(),listbox,ON_CHANGE,'W');
}

static void move_listbox_item_up(typeless listbox)
{
   listbox._TreeMoveUp(listbox._TreeCurIndex());
   call_event(CHANGE_SELECTED,listbox._TreeCurIndex(),listbox,ON_CHANGE,'W');
}

static void move_listbox_item_down(typeless listbox)
{
   listbox._TreeMoveDown(listbox._TreeCurIndex());
   call_event(CHANGE_SELECTED,listbox._TreeCurIndex(),listbox,ON_CHANGE,'W');
}

static void remove_listbox_item(typeless listbox)
{
   listbox._TreeDelete(listbox._TreeCurIndex());
   call_event(CHANGE_SELECTED,listbox._TreeCurIndex(),listbox,ON_CHANGE,'W');
}

/*
Each control has on_change/lbutton_up implemented so that when
"All Configurations" is active, only the options that are changed by
the user are changed for all the configurations.

While the implementations are so similar, they could best be done as
a #define macro that takes the name of control and the name of field
of the options structure, some people object to that extensive use of
macros and so it is not done here. Instead there is lots of redundant
code.
*/

void ctlCompiler.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].compiler=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].compiler=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOtherCompileOptions.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].otherCompileOptions=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].otherCompileOptions=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlForScope.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].forScope=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].forScope=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlNativeWchar.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].nativeWchar=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].nativeWchar=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlUnsignedChar.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].unsignChar=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].unsignChar=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlCompileAs.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].compileAs=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].compileAs=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlPCHType.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   boolean potential_error=false;

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].usePCH=new_value;
         if (all_config_options:[configs[config_index]].useCLR) {
            potential_error=true;
         }
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].usePCH=new_value;
      if (all_config_options:[ctlCurConfig.p_text].useCLR) {
         potential_error=true;
      }
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

   if (potential_error &&
        (new_value==VCPP_USE_PCH_AUTO) ) {
      _message_box("CLR can not be used with automatic precompiled headers.");
   }
}

void ctlPCHThrough.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].pchThrough=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].pchThrough=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlPCHFile.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].pchFile=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].pchFile=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlDebugFormat.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   // check if CLR is active, then only some debug formats are valid
   boolean potential_error=false;
   
   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].debugFormat=new_value;
         if (all_config_options:[configs[config_index]].useCLR) {
            potential_error=true;
         }
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].debugFormat=new_value;
      if (all_config_options:[ctlCurConfig.p_text].useCLR) {
         potential_error=true;
      }
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

   if (potential_error) {
      if ((new_value==VCPP_DEBUG_FORMAT_C7)||
          (new_value==VCPP_DEBUG_FORMAT_LINE_NUM)) {
         _message_box("CLR can not be used with C7 or line number only formats.");
      }
   }
}

void ctlDebugFile.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].pdbFile=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].pdbFile=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlTypeCheck.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].typeChecks=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].typeChecks=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlSmallerType.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].smallTypeCheck=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].smallTypeCheck=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlSecurity.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].bufferCheck=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].bufferCheck=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlConvention.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].convention=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].convention=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlSSE.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].enhancedInstSet=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].enhancedInstSet=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlFunctionLinking.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].functionLink=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].functionLink=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlRTTI.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].RTTI=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].RTTI=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlException.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].exceptionHandling=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].exceptionHandling=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlMinimalRebuild.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].minimalRebuild=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].minimalRebuild=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptLevel.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optLevel=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optLevel=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptSizeSpeed.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optFavor=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optFavor=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptInline.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].inlineExpansion=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].inlineExpansion=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptProcessor.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optProcessor=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optProcessor=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptGlobal.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optGlobal=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optGlobal=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptIntrinsic.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optIntrinsic=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optIntrinsic=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptFiber.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optFiber=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optFiber=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptFloat.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optFloat=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optFloat=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptString.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optString=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optString=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptWindows.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optWindows=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optWindows=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOptFrame.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].optFrame=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].optFrame=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlNoDefaultLibs.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].noDefaultLibs=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].noDefaultLibs=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlIncrementalLink.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].incrementalLinking=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].incrementalLinking=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlLinkDebug.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].linkDebug=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].linkDebug=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

   update_output_type();
}


void ctlLinkMultiThread.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].linkMultiThread=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].linkMultiThread=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

   update_output_type();
}

void ctlOutputType.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].outputType=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].outputType=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlLinker.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].linker=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].linker=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOutputFile.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].outputFile=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].outputFile=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlObjectLocation.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].objectLocation=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].objectLocation=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlOtherLinkOptions.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].otherLinkOptions=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].otherLinkOptions=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlIgnoreStdInclude.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].ignoreStdInc=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_cb_text_box.p_text].ignoreStdInc=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlWarnLevel.on_change(int reason)
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   int new_value=p_line;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].warningLevel=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].warningLevel=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlWarnError.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].warnAsErr=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].warnAsErr=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlWarn64.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].warn64bit=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].warn64bit=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlCLR.lbutton_up()
{
   boolean new_value=p_value>0;
   ctlNoAssembly.p_enabled=new_value;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

// This was taken from MSDN:
//
// The following compiler options are not supported with /clr:
// /GL, /Zd, /ZI or /Z7, /ML and /MLd, /Gm, /YX, and /RTC. 

   _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
   int config_index;

   if (new_value) {
      // /GL - not exposed in dialog
   
      // /Zd, /Z7 - debug formats can use /Zi (pdb), /ZI (edit), or none
      // As there is more than one valid option, warn the user if there is a illegal setting.
      if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
         boolean bad_format=false;
         for (config_index=0;config_index<configs._length();++config_index) {
            if ((all_config_options:[configs[config_index]].debugFormat==VCPP_DEBUG_FORMAT_C7) ||
                (all_config_options:[configs[config_index]].debugFormat==VCPP_DEBUG_FORMAT_LINE_NUM) ) {
               bad_format=true;
            }
         }
         if (bad_format) {
            _message_box("One or more configurations are using an illegal debug format.\n\nCLR can not be used with C7 or line number only formats.");
         }
      } else if ((all_config_options:[ctlCurConfig.p_text].debugFormat==VCPP_DEBUG_FORMAT_C7) ||
                 (all_config_options:[ctlCurConfig.p_text].debugFormat==VCPP_DEBUG_FORMAT_C7)) {
         _message_box("This configuration is using an illegal debug format.\n\nCLR can not be used with C7 or line number only formats.");
      }

      // /ML and /MLd - Single threaded application libraries
      ctlLinkMultiThread.p_value=1;
      ctlLinkMultiThread.call_event(ctlLinkMultiThread,LBUTTON_UP);
      ctlLinkMultiThread.p_enabled=false;
   
      // /Gm - minimal rebuild
      ctlMinimalRebuild.p_value=0;
      ctlMinimalRebuild.call_event(ctlMinimalRebuild,LBUTTON_UP);
      ctlMinimalRebuild.p_enabled=false;
   
      // /YX - automatic PCH
      if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
         boolean bad_pch=false;
         for (config_index=0;config_index<configs._length();++config_index) {
            if (all_config_options:[configs[config_index]].usePCH==VCPP_USE_PCH_AUTO) {
               bad_pch=true;
            }
         }
         if (bad_pch) {
            _message_box("One or more configurations are using an illegal precompiled header setting.\n\nCLR can not be used with automatic precompiled headers.");
         }
      } else if (all_config_options:[ctlCurConfig.p_text].usePCH==VCPP_USE_PCH_AUTO) {
         _message_box("This configuration is using an illegal precompiled header setting.\n\nCLR can not be used with automatic precompiled headers.");
      }
   
      // /RTC(*) - runtime checks
      ctlTypeCheck.select_cb_item(VCPP_TYPE_CHECK_DEFAULT);
      ctlTypeCheck.call_event(CHANGE_OTHER,ctlTypeCheck,ON_CHANGE,"W");
      ctlTypeCheck.p_enabled=false;

      ctlSmallerType.p_value=0;
      ctlSmallerType.call_event(ctlSmallerType,LBUTTON_UP);
      ctlSmallerType.p_enabled=false;

      ctlNoAssembly.p_enabled=true;
      ctlAssembliesLabel.p_enabled=true;
      ctlAssemblies.p_enabled=true;
      ctlBrowseAssemblies.p_enabled=true;
      ctlMoveAssembliesUp.p_enabled=true;
      ctlMoveAssembliesDown.p_enabled=true;
      ctlRemoveAssembly.p_enabled=true;
      ctlAssemblyDirsLabel.p_enabled=true;
      ctlAssemblyDirs.p_enabled=true;
      ctlBrowseAssemblyDirs.p_enabled=true;
      ctlMoveAssemblyDirsUp.p_enabled=true;
      ctlMoveAssemblyDirsDown.p_enabled=true;
      ctlRemoveAssemblyDir.p_enabled=true;
   } else {
      ctlLinkMultiThread.p_enabled=true;
      ctlMinimalRebuild.p_enabled=true;
      ctlTypeCheck.p_enabled=true;
      ctlSmallerType.p_enabled=true;

      ctlNoAssembly.p_enabled=false;
      ctlAssembliesLabel.p_enabled=false;
      ctlAssemblies.p_enabled=false;
      ctlBrowseAssemblies.p_enabled=false;
      ctlMoveAssembliesUp.p_enabled=false;
      ctlMoveAssembliesDown.p_enabled=false;
      ctlRemoveAssembly.p_enabled=false;
      ctlAssemblyDirsLabel.p_enabled=false;
      ctlAssemblyDirs.p_enabled=false;
      ctlBrowseAssemblyDirs.p_enabled=false;
      ctlMoveAssemblyDirsUp.p_enabled=false;
      ctlMoveAssemblyDirsDown.p_enabled=false;
      ctlRemoveAssemblyDir.p_enabled=false;
   }

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].useCLR=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].useCLR=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlNoAssembly.lbutton_up()
{
   boolean new_value=p_value>0;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].noAssembly=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].noAssembly=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlPreprocessorDefines.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].defines=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].defines=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlLibraries.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].libraries=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].libraries=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

ctlLinkOrder.lbutton_up()
{
   _str libList = show('-modal _link_order_form',ctlLibraries.p_text);

   if (libList :!= '') {
      // pressing OK with no libraries will return
      // PROJECT_OBJECTS instead of ''
      //
      // This should invoke an on_change event which will copy
      // the new value into the options structure.
      if (libList :== PROJECT_OBJECTS) {
         ctlLibraries.p_text = '';
      } else {
         ctlLibraries.p_text = libList;
      }
   }
}

void ctlProgramArgs.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].arguments=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].arguments=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlUseCLRDebugger.lbutton_up()
{
   boolean new_value=p_value>0;

   ctldbgDebuggerLabel.p_enabled=!new_value;
   ctldbgDebugger.p_enabled=!new_value;
   ctldbgFindApp.p_enabled=!new_value;
   ctldbgDebuggerOtherLabel.p_enabled=!new_value;
   ctldbgOtherDebuggerOptions.p_enabled=!new_value;

   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].useBuiltinDebug=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].useBuiltinDebug=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlUseOtherDebugger.lbutton_up()
{
   boolean new_value=p_value>0;

   ctldbgDebuggerLabel.p_enabled=new_value;
   ctldbgDebugger.p_enabled=new_value;
   ctldbgFindApp.p_enabled=new_value;
   ctldbgDebuggerOtherLabel.p_enabled=new_value;
   ctldbgOtherDebuggerOptions.p_enabled=new_value;

   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].useBuiltinDebug=!new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].useBuiltinDebug=!new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctldbgDebugger.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].debugger=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].debugger=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctldbgOtherDebuggerOptions.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value=p_text;
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].debuggerOptions=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].debuggerOptions=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlAssemblies.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value[];
   get_listbox_items(ctlAssemblies,new_value);
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].assemblies=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].assemblies=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlBrowseAssemblies.lbutton_up()
{
   _str result=show('-modal _textbox_form',
               'Enter New Assembly Name',
               0,//Flags,
               '',//Tb width
               '',//help item
               '',//Buttons and captions
               '',//retrieve name
               'Assembly Name:');
   if ((result:=='')||(_param1:=='')) return;

   add_listbox_item(ctlAssemblies,_param1);
}

void ctlMoveAssembliesUp.lbutton_up()
{
   move_listbox_item_up(ctlAssemblies);
}

void ctlMoveAssembliesDown.lbutton_up()
{
   move_listbox_item_down(ctlAssemblies);
}

void ctlRemoveAssembly.lbutton_up()
{
   remove_listbox_item(ctlAssemblies);
}

void ctlAssemblyDirs.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value[];
   get_listbox_items(ctlAssemblyDirs,new_value);
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].assemblyDirs=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].assemblyDirs=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);
}

void ctlBrowseAssemblyDirs.lbutton_up()
{
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return;
   }

   add_listbox_item(ctlAssemblyDirs,result);
}

void ctlMoveAssemblyDirsUp.lbutton_up()
{
   move_listbox_item_up(ctlAssemblyDirs);
}

void ctlMoveAssemblyDirsDown.lbutton_up()
{
   move_listbox_item_down(ctlAssemblyDirs);
}

void ctlRemoveAssemblyDir.lbutton_up()
{
   remove_listbox_item(ctlAssemblyDirs);
}

void ctlUserIncludesList.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value[];
   get_listbox_items(ctlUserIncludesList,new_value);
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].includeDirs=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].includeDirs=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

}

void ctlBrowseUserIncludes.lbutton_up()
{
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return;
   }

   add_listbox_item(ctlUserIncludesList,result);
}

void ctlMoveUserIncludesUp.lbutton_up()
{
   move_listbox_item_up(ctlUserIncludesList);
}

void ctlMoveUserIncludesDown.lbutton_up()
{
   move_listbox_item_down(ctlUserIncludesList);
}
void ctlRemoveUserInclude.lbutton_up()
{
   remove_listbox_item(ctlUserIncludesList);
}

void ctlLibDirs.on_change()
{
   if (_GetDialogInfo(VCPP_OPTS_CHANGING_CONFIG)) {
      return;
   }

   _str new_value[];
   get_listbox_items(ctlLibDirs,new_value);
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   if (_GetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE)) {
      _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);
      int config_index;
      for (config_index=0;config_index<configs._length();++config_index) {
         all_config_options:[configs[config_index]].libDirs=new_value;
      }
   } else {
      all_config_options:[ctlCurConfig.p_text].libDirs=new_value;
   }

   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

}

void ctlBrowseLibDirs.lbutton_up()
{
   _str result = _ChooseDirDialog();
   if ( result=='' ) {
      return;
   }

   add_listbox_item(ctlLibDirs,result);
}

void ctlMoveLibDirsUp.lbutton_up()
{
   move_listbox_item_up(ctlLibDirs);
}

void ctlMoveLibDirsDown.lbutton_up()
{
   move_listbox_item_down(ctlLibDirs);
}
void ctlRemoveLibDir.lbutton_up()
{
   remove_listbox_item(ctlLibDirs);
}

static void update_output_type()
{
   boolean debug=ctlLinkDebug.p_value>0;
   boolean multi_thread=ctlLinkMultiThread.p_value>0;

   _str exe_line='Executable (';
   _str dll_line='Dynamic Link Library (';

   if (multi_thread) {
      strappend(exe_line,'/MT');
      strappend(dll_line,'/MD');
   } else {
      strappend(exe_line,'/ML');
      strappend(dll_line,'/LD');
   }

   if (debug) {
      strappend(exe_line,'d)');
      strappend(dll_line,'d)');
   } else {
      strappend(exe_line,')');
      strappend(dll_line,')');
   }

   int start_line=ctlOutputType.p_line;

   ctlOutputType._lbclear();
   ctlOutputType._lbadd_item(exe_line);
   ctlOutputType._lbadd_item(dll_line);

   ctlOutputType.select_cb_item(start_line);
}

static void setup_controls()
{
   _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,true);

   //NOTE: The order these items are added must match
   //the corresponding #defines for the values
   ctlCompileAs._lbadd_item('Default');
   ctlCompileAs._lbadd_item('C (/Tc)');
   ctlCompileAs._lbadd_item('C++ (/Tp)');

   ctlPCHType._lbadd_item('Do not use');
   ctlPCHType._lbadd_item('Create (/Yc)');
   ctlPCHType._lbadd_item('Use (/Yu)');
   ctlPCHType._lbadd_item('Automatic (/YX)');

   ctlDebugFormat._lbadd_item('None');
   ctlDebugFormat._lbadd_item('Old Style (/Z7)');
   ctlDebugFormat._lbadd_item('Line Number (/Zd)');
   ctlDebugFormat._lbadd_item('Program Database (/Zi)');
   ctlDebugFormat._lbadd_item('Edit and Continue (/ZI)');

   ctlTypeCheck._lbadd_item('Default');
   ctlTypeCheck._lbadd_item('Fast Checks (/RTC1)');
   ctlTypeCheck._lbadd_item('Stack Frame (/RTCs)');
   ctlTypeCheck._lbadd_item('Uninitialized local (/RTCu)');

   ctlConvention._lbadd_item('__cdecl (/Gd)');
   ctlConvention._lbadd_item('__fastcall (/Gr)');
   ctlConvention._lbadd_item('__stdcall (/Gz)');

   ctlSSE._lbadd_item('None');
   ctlSSE._lbadd_item('SSE (/arch:SSE)');
   ctlSSE._lbadd_item('SSE2 (/arch:SSE2)');

   ctlOptLevel._lbadd_item('None (/Od)');
   ctlOptLevel._lbadd_item('Minimize Space (/O1)');
   ctlOptLevel._lbadd_item('Maximize Speed (/O2)');
   ctlOptLevel._lbadd_item('Maximum Optimization (/Ox)');

   ctlOptSizeSpeed._lbadd_item('Neither');
   ctlOptSizeSpeed._lbadd_item('Space (/Os)');
   ctlOptSizeSpeed._lbadd_item('Speed (/Ot)');

   ctlOptInline._lbadd_item('Default (/Ob0)');
   ctlOptInline._lbadd_item('Only __inline (/Ob1)');
   ctlOptInline._lbadd_item('Any Suitable (/Ob2)');

   ctlOptProcessor._lbadd_item('80386 (/G3)');
   ctlOptProcessor._lbadd_item('80486 (/G4)');
   ctlOptProcessor._lbadd_item('Pentium (/G5)');
   ctlOptProcessor._lbadd_item('PPro, P-II, or P-III (/G6)');
   ctlOptProcessor._lbadd_item('Pentium 4 or Athlon (/G7)');
   ctlOptProcessor._lbadd_item('Blended (/GB)');

   ctlOutputType._lbadd_item('Executable');
   ctlOutputType._lbadd_item('Dynamic Link Library');

   ctlWarnLevel._lbadd_item('None (/W0)');
   ctlWarnLevel._lbadd_item('Level 1 (/W1)');
   ctlWarnLevel._lbadd_item('Level 2 (/W2)');
   ctlWarnLevel._lbadd_item('Level 3 (/W3)');
   ctlWarnLevel._lbadd_item('Level 4 (/W4)');
   ctlWarnLevel._lbadd_item('All (/Wall)');

   _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,false);
}

static _str parse_next_vcpp_option(_str & command,boolean return_quotes=true)
{
   _str output=parse_next_option(command);

   if ((pos('"',output)!=0) && (last_char(output):!='"')) {
      _str next_opt=parse_next_option(command);
      while (next_opt:!='' && last_char(next_opt):!='"') {
         strappend(output,' ':+next_opt);
         next_opt=parse_next_option(command);
      }
   }

   if (!return_quotes && first_char(output):=='"') {
      output=strip(output,'B','"');
   }

   return output;
}

static void setup_config(int project_handle,_str config_name,VCPP_OPTIONS & options)
{
   // set everything to default
   options.compiler='';
   options.otherCompileOptions='';
   options.defines='';
   options.forScope=false;
   options.nativeWchar=false;
   options.unsignChar=false;
   options.compileAs=VCPP_COMPILE_AS_DEFAULT;
   options.usePCH=VCPP_USE_PCH_NONE;
   options.pchThrough='';
   options.pchFile='';
   options.debugFormat=VCPP_DEBUG_FORMAT_NONE;
   options.pdbFile='';
   options.typeChecks=VCPP_TYPE_CHECK_DEFAULT;
   options.smallTypeCheck=false;
   options.bufferCheck=false;
   options.convention=VCPP_CONVENTION_CDECL;
   options.enhancedInstSet=VCPP_ENHANCED_INST_DEFAULT;
   options.functionLink=false;
   options.RTTI=false;
   options.exceptionHandling=false;
   options.minimalRebuild=false;
   options.optLevel=VCPP_OPT_LEVEL_NONE;
   options.optFavor=VCPP_OPT_FAVOR_NONE;
   options.inlineExpansion=VCPP_INLINE_DEFAULT;
   options.optProcessor=VCPP_PROCESSOR_BLEND;
   options.optGlobal=false;
   options.optIntrinsic=false;
   options.optFiber=false;
   options.optFloat=false;
   options.optString=false;
   options.optWindows=false;
   options.optFrame=false;
   options.noDefaultLibs=false;
   options.incrementalLinking=false;
   options.linkDebug=false;
   options.linkMultiThread=false;
   options.outputType=VCPP_OUTPUT_EXE;
   options.linker='';
   options.outputFile='';
   options.libraries='';
   options.objectLocation='';
   options.otherLinkOptions='';
   options.ignoreStdInc=false;
   options.includeDirs._makeempty();
   options.libDirs._makeempty();
   options.warningLevel=VCPP_WARNING_LEVEL_3;
   options.warnAsErr=false;
   options.warn64bit=false;
   options.useCLR=false;
   options.noAssembly=false;
   options.assemblies._makeempty();
   options.assemblyDirs._makeempty();
   options.arguments='';
   options.useBuiltinDebug=false;
   options.debugger='';
   options.debuggerOptions='';

   options.compileTargetNode=_ProjectGet_TargetNode(project_handle,'compile',config_name);
   options.linkTargetNode=_ProjectGet_TargetNode(project_handle,'link',config_name);
   options.debugTargetNode=_ProjectGet_TargetNode(project_handle,'debug',config_name);
   options.executeTargetNode=_ProjectGet_TargetNode(project_handle,'execute',config_name);

   // get defines
   options.defines='';
   _str full_defines=_ProjectGet_Defines(project_handle,config_name);
   _str define;
   _str prefix;
   while (full_defines:!='') {
      define=parse_next_option(full_defines,false);
      // remove a leading /D or -D for the dialog
      prefix=substr(define,1,2);
      if (prefix:=='/D'||prefix:=='-D') {
         define=substr(define,3);
      }
      strappend(options.defines,' ':+define);
   }
   options.defines=strip(options.defines);

   // get libraries
   options.libraries=_ProjectGet_DisplayLibsList(project_handle,config_name);

   // get includes
   _ProjectGet_Includes(project_handle,options.includeDirs,config_name);

   // parse the compile command
   _str command=_ProjectGet_TargetCmdLine(project_handle,options.compileTargetNode);
   _str option;
   _str opt3;  // first three characters of option

   options.otherCompileOptions=_ProjectGet_TargetOtherOptions(project_handle,options.compileTargetNode);
   options.objectLocation=_ProjectGet_ObjectDir(project_handle,config_name);
   options.outputFile=_ProjectGet_OutputFile(project_handle,config_name);

   options.compiler=parse_next_option(command,false);

   while (command:!='') {
      option=parse_next_vcpp_option(command,false);
      if (first_char(option):=='%') {
         continue;
      }

      opt3=substr(option,1,3);

      if ( (opt3=='/Yc')||
           (opt3=='/Yu')||
           (opt3=='/Yx') ) {
         options.pchThrough=strip(substr(option,4),'B','"');
         if (opt3=='/Yc') {
            options.usePCH=VCPP_USE_PCH_CREATE;
         } else if (opt3=='/Yu') {
            options.usePCH=VCPP_USE_PCH_USE;
         } else {
            options.usePCH=VCPP_USE_PCH_AUTO;
         }
      } else if (opt3=='/Fp') {
         options.pchFile=strip(substr(option,4),'B','"');
      } else if (opt3=='/Fd') {
         options.pdbFile=strip(substr(option,4),'B','"');
      } else if (opt3=='/FU') {
         options.assemblies[options.assemblies._length()]=strip(substr(option,4),'B','"');
      } else if (opt3=='/AI') {
         options.assemblyDirs[options.assemblyDirs._length()]=strip(substr(option,4),'B','"');
      } else if (opt3=='/Fo') {
         options.objectLocation=strip(substr(option,4),'B','"');
      } else {
         switch (option) {
         case '/Zc:forScope':
            options.forScope=true;
            break;
         case '/Zc:wchar_t':
            options.nativeWchar=true;
            break;
         case '/J':
            options.unsignChar=true;
            break;
         case '/Tc':
            options.compileAs=VCPP_COMPILE_AS_C;
            break;
         case '/Tp':
            options.compileAs=VCPP_COMPILE_AS_CPP;
            break;
         case '/Z7':
            options.debugFormat=VCPP_DEBUG_FORMAT_C7;
            break;
         case '/Zd':
            options.debugFormat=VCPP_DEBUG_FORMAT_LINE_NUM;
            break;
         case '/Zi':
            options.debugFormat=VCPP_DEBUG_FORMAT_PDB;
            break;
         case '/ZI':
            options.debugFormat=VCPP_DEBUG_FORMAT_EDIT;
            break;
         case '/RTC1':
            options.typeChecks=VCPP_TYPE_CHECK_FAST;
            break;
         case '/RTCs':
            options.typeChecks=VCPP_TYPE_CHECK_STACK;
            break;
         case '/RTCu':
            options.typeChecks=VCPP_TYPE_CHECK_LOCAL;
            break;
         case '/RTCc':
            options.smallTypeCheck=true;
            break;
         case '/GS':
            options.bufferCheck=true;
            break;
         case '/Gd':
            options.convention=VCPP_CONVENTION_CDECL;
            break;
         case '/Gr':
            options.convention=VCPP_CONVENTION_FASTCALL;
            break;
         case '/Gz':
            options.convention=VCPP_CONVENTION_STDCALL;
            break;
         case '/arch:SSE':
            options.enhancedInstSet=VCPP_ENHANCED_INST_SSE;
            break;
         case '/arch:SSE2':
            options.enhancedInstSet=VCPP_ENHANCED_INST_SSE2;
            break;
         case '/Gy':
            options.functionLink=true;
            break;
         case '/GR':
            options.RTTI=true;
            break;
         case '/EHsc':
         case '/GX':
            options.exceptionHandling=true;
            break;
         case '/Gm':
            options.minimalRebuild=true;
            break;
         case '/Od':
            options.optLevel=VCPP_OPT_LEVEL_NONE;
            break;
         case '/O1':
            options.optLevel=VCPP_OPT_LEVEL_SPACE;
            break;
         case '/O2':
            options.optLevel=VCPP_OPT_LEVEL_SPEED;
            break;
         case '/Ox':
            options.optLevel=VCPP_OPT_LEVEL_MAX;
            break;
         case '/Os':
            options.optFavor=VCPP_OPT_FAVOR_SPACE;
            break;
         case '/Ot':
            options.optFavor=VCPP_OPT_FAVOR_SPEED;
            break;
         case '/Ob0':
            options.inlineExpansion=VCPP_INLINE_DEFAULT;
            break;
         case '/Ob1':
            options.inlineExpansion=VCPP_INLINE_ONLY;
            break;
         case '/Ob2':
            options.inlineExpansion=VCPP_INLINE_ANY;
            break;
         case '/G3':
            options.optProcessor=VCPP_PROCESSOR_386;
            break;
         case '/G4':
            options.optProcessor=VCPP_PROCESSOR_486;
            break;
         case '/G5':
            options.optProcessor=VCPP_PROCESSOR_PENT;
            break;
         case '/G6':
            options.optProcessor=VCPP_PROCESSOR_PPRO;
            break;
         case '/G7':
            options.optProcessor=VCPP_PROCESSOR_P4;
            break;
         case '/GB':
            options.optProcessor=VCPP_PROCESSOR_BLEND;
            break;
         case '/Og':
            options.optGlobal=true;
            break;
         case '/Oi':
            options.optIntrinsic=true;
            break;
         case '/GT':
            options.optFiber=true;
            break;
         case '/Op':
            options.optFloat=true;
            break;
         case '/GF':
            options.optString=true;
            break;
         case '/GA':
            options.optWindows=true;
            break;
         case '/Oy':
            options.optFrame=true;
            break;
         case '/X':
            options.ignoreStdInc=true;
            break;
         case '/W0':
            options.warningLevel=VCPP_WARNING_LEVEL_0;
            break;
         case '/W1':
            options.warningLevel=VCPP_WARNING_LEVEL_1;
            break;
         case '/W2':
            options.warningLevel=VCPP_WARNING_LEVEL_2;
            break;
         case '/W3':
            options.warningLevel=VCPP_WARNING_LEVEL_3;
            break;
         case '/W4':
            options.warningLevel=VCPP_WARNING_LEVEL_4;
            break;
         case '/Wall':
            options.warningLevel=VCPP_WARNING_LEVEL_ALL;
            break;
         case '/WX':
            options.warnAsErr=true;
            break;
         case '/Wp64':
            options.warn64bit=true;
            break;
         case '/clr':
            options.useCLR=true;
            options.noAssembly=false;
            break;
         case '/clr:noAssembly':
            options.useCLR=true;
            options.noAssembly=true;
            break;
         case '/MD':
            options.linkDebug=false;
            options.linkMultiThread=true;
            options.outputType=VCPP_OUTPUT_DLL;
            break;
         case '/MDd':
            options.linkDebug=true;
            options.linkMultiThread=true;
            options.outputType=VCPP_OUTPUT_DLL;
            break;
         case '/ML':
            options.linkDebug=false;
            options.linkMultiThread=false;
            options.outputType=VCPP_OUTPUT_EXE;
            break;
         case '/MLd':
            options.linkDebug=true;
            options.linkMultiThread=false;
            options.outputType=VCPP_OUTPUT_EXE;
            break;
         case '/MT':
            options.linkDebug=false;
            options.linkMultiThread=true;
            options.outputType=VCPP_OUTPUT_EXE;
            break;
         case '/MTd':
            options.linkDebug=true;
            options.linkMultiThread=true;
            options.outputType=VCPP_OUTPUT_EXE;
            break;
         case '/LD':
            options.linkDebug=false;
            options.linkMultiThread=false;
            options.outputType=VCPP_OUTPUT_DLL;
            break;
         case '/LDd':
            options.linkDebug=true;
            options.linkMultiThread=false;
            options.outputType=VCPP_OUTPUT_DLL;
            break;
         }
      }
   }

   // parse the link command
   command=_ProjectGet_TargetCmdLine(project_handle,options.linkTargetNode);
   options.linker=parse_next_option(command,false);

   options.otherLinkOptions=_ProjectGet_TargetOtherOptions(project_handle,options.linkTargetNode);

   while (command:!='') {
      option=parse_next_vcpp_option(command,false);
      if (first_char(option):=='%') {
         continue;
      }

      switch (option) {
      case '/NODEFAULTLIB':
         options.noDefaultLibs=true;
         break;
      case '/INCREMENTAL':
         options.incrementalLinking=true;
         break;
      default:
         {
            _str opt_name;
            _str opt_value;
            parse option with opt_name ':' opt_value;

            // this switch statement is excessive with only one case, but others
            // may be added later
            switch (opt_name) {
            case '/LIBPATH':
               options.libDirs[options.libDirs._length()]=strip(opt_value,'B','"');
            }
         }
      }
   }

   // parse debug command
   command=_ProjectGet_TargetCmdLine(project_handle,options.debugTargetNode);
   options.debugger=parse_next_option(command,false);

   parse command with options.debuggerOptions '%~other';

   options.arguments=_ProjectGet_TargetOtherOptions(project_handle,options.debugTargetNode);

   // DJB 03-18-2008
   // Integrated .NET debugging is no longer available as of SlickEdit 2008
   //options.useBuiltinDebug=(options.debugger:=='vsclrdebug')&&(options.debuggerOptions:=='');
   options.useBuiltinDebug = false;

   // parse execute command
   // not really anything to do here
}

static void set_commands(int project_handle,_str config_name,VCPP_OPTIONS & options)
{
   // do the reverse of the above function

   _str compile_command='"'options.compiler'" /c %defs %~other ';

   _str raw_defines=options.defines;
   _str all_defines='';

   while (raw_defines!='') {
      _str define=parse_next_option(raw_defines,false);
      _checkDefine(define);
      if (define:!='') {
         if (all_defines:!='') {
            strappend(all_defines,' ');
         }
         strappend(all_defines,'"'define'"');
      }
   }

   _ProjectSet_Defines(project_handle,all_defines,config_name);

   _ProjectSet_DisplayLibsList(project_handle,config_name,options.libraries);

   _ProjectSet_Includes(project_handle,options.includeDirs,config_name);

   switch (options.usePCH) {
   case VCPP_USE_PCH_CREATE:
      strappend(compile_command,'/Yc"'options.pchThrough'" ');
      break;
   case VCPP_USE_PCH_USE:
      strappend(compile_command,'/Yu"'options.pchThrough'" ');
      break;
   case VCPP_USE_PCH_AUTO:
      strappend(compile_command,'/Yx"'options.pchThrough'" ');
      break;
   }

   int option_index;

   for (option_index=0;option_index<options.assemblies._length();++option_index) {
      strappend(compile_command,'/FU"'options.assemblies[option_index]'" ');
   }

   for (option_index=0;option_index<options.assemblyDirs._length();++option_index) {
      strappend(compile_command,'/AI"'options.assemblyDirs[option_index]'" ');
   }

   if (options.pchFile:!='') {
      strappend(compile_command,'/Fp"'options.pchFile'" ');
   }

   if (options.pdbFile:!='') {
      strappend(compile_command,'/Fd"'options.pdbFile'" ');
   }

   if (options.forScope) {
      strappend(compile_command,'/Zc:forScope ');
   }

   if (options.nativeWchar) {
      strappend(compile_command,'/Zc:wchar_t ');
   }

   if (options.unsignChar) {
      strappend(compile_command,'/J ');
   }

   switch (options.compileAs) {
   case VCPP_COMPILE_AS_C:
      strappend(compile_command,'/Tc ');
      break;
   case VCPP_COMPILE_AS_CPP:
      strappend(compile_command,'/Tp ');
      break;
   }

   switch (options.debugFormat) {
   case VCPP_DEBUG_FORMAT_C7:
      strappend(compile_command,'/Z7 ');
      break;
   case VCPP_DEBUG_FORMAT_LINE_NUM:
      strappend(compile_command,'/Zd ');
      break;
   case VCPP_DEBUG_FORMAT_PDB:
      strappend(compile_command,'/Zi ');
      break;
   case VCPP_DEBUG_FORMAT_EDIT:
      strappend(compile_command,'/ZI ');
      break;
   }

   switch (options.typeChecks) {
   case VCPP_TYPE_CHECK_FAST:
      strappend(compile_command,'/RTC1 ');
      break;
   case VCPP_TYPE_CHECK_STACK:
      strappend(compile_command,'/RTCs ');
      break;
   case VCPP_TYPE_CHECK_LOCAL:
      strappend(compile_command,'/RTCu ');
      break;
   }

   if (options.smallTypeCheck) {
      strappend(compile_command,'/RTCc ');
   }

   if (options.bufferCheck) {
      strappend(compile_command,'/GS ');
   }

   switch (options.convention) {
   case VCPP_CONVENTION_CDECL:
      strappend(compile_command,'/Gd ');
      break;
   case VCPP_CONVENTION_FASTCALL:
      strappend(compile_command,'/Gr ');
      break;
   case VCPP_CONVENTION_STDCALL:
      strappend(compile_command,'/Gz ');
      break;
   }

   switch (options.enhancedInstSet) {
   case VCPP_ENHANCED_INST_SSE:
      strappend(compile_command,'/arch:SSE ');
      break;
   case VCPP_ENHANCED_INST_SSE2:
      strappend(compile_command,'/arch:SSE2 ');
      break;
   }

   if (options.functionLink) {
      strappend(compile_command,'/Gy ');
   }

   if (options.RTTI) {
      strappend(compile_command,'/GR ');
   }

   if (options.exceptionHandling) {
      strappend(compile_command,'/GX ');
   }

   if (options.minimalRebuild) {
      strappend(compile_command,'/Gm ');
   }

   switch (options.optLevel) {
   case VCPP_OPT_LEVEL_NONE:
      strappend(compile_command,'/Od ');
      break;
   case VCPP_OPT_LEVEL_SPACE:
      strappend(compile_command,'/O1 ');
      break;
   case VCPP_OPT_LEVEL_SPEED:
      strappend(compile_command,'/O2 ');
      break;
   case VCPP_OPT_LEVEL_MAX:
      strappend(compile_command,'/Ox ');
      break;
   }

   switch (options.optFavor) {
   case VCPP_OPT_FAVOR_SPACE:
      strappend(compile_command,'/Os ');
      break;
   case VCPP_OPT_FAVOR_SPEED:
      strappend(compile_command,'/Ot ');
      break;
   }

   switch (options.inlineExpansion) {
   case VCPP_INLINE_DEFAULT:
      strappend(compile_command,'/Ob0 ');
      break;
   case VCPP_INLINE_ONLY:
      strappend(compile_command,'/Ob1 ');
      break;
   case VCPP_INLINE_ANY:
      strappend(compile_command,'/Ob2 ');
      break;
   }

   switch (options.optProcessor) {
   case VCPP_PROCESSOR_386:
      strappend(compile_command,'/G3 ');
      break;
   case VCPP_PROCESSOR_486:
      strappend(compile_command,'/G4 ');
      break;
   case VCPP_PROCESSOR_PENT:
      strappend(compile_command,'/G5 ');
      break;
   case VCPP_PROCESSOR_PPRO:
      strappend(compile_command,'/G6 ');
      break;
   case VCPP_PROCESSOR_P4:
      strappend(compile_command,'/G7 ');
      break;
   case VCPP_PROCESSOR_BLEND:
      strappend(compile_command,'/GB ');
      break;
   }

   if (options.optGlobal) {
      strappend(compile_command,'/Og ');
   }

   if (options.optIntrinsic) {
      strappend(compile_command,'/Oi ');
   }

   if (options.optFiber) {
      strappend(compile_command,'/GT ');
   }

   if (options.optFloat) {
      strappend(compile_command,'/Op ');
   }

   if (options.optString) {
      strappend(compile_command,'/GF ');
   }

   if (options.optWindows) {
      strappend(compile_command,'/GA ');
   }

   if (options.optFrame) {
      strappend(compile_command,'/Oy ');
   }

   if (options.ignoreStdInc) {
      strappend(compile_command,'/X ');
   }

   switch (options.warningLevel) {
   case VCPP_WARNING_LEVEL_0:
      strappend(compile_command,'/W0 ');
      break;
   case VCPP_WARNING_LEVEL_1:
      strappend(compile_command,'/W1 ');
      break;
   case VCPP_WARNING_LEVEL_2:
      strappend(compile_command,'/W2 ');
      break;
   case VCPP_WARNING_LEVEL_3:
      strappend(compile_command,'/W3 ');
      break;
   case VCPP_WARNING_LEVEL_4:
      strappend(compile_command,'/W4 ');
      break;
   case VCPP_WARNING_LEVEL_ALL:
      strappend(compile_command,'/Wall ');
      break;
   }

   if (options.warnAsErr) {
      strappend(compile_command,'/WX ');
   }

   if (options.warn64bit) {
      strappend(compile_command,'/Wp64 ');
   }

   if (options.useCLR) {
      if (options.noAssembly) {
         strappend(compile_command,'/clr:noAssembly ');
      } else {
         strappend(compile_command,'/clr ');
      }
   }

   if (!options.useCLR) {
      switch (options.outputType) {
      case VCPP_OUTPUT_EXE:
         if (options.linkDebug) {
            if (options.linkMultiThread) {
               strappend(compile_command,'/MTd ');
            } else {
               strappend(compile_command,'/MLd ');
            }
         } else {
            if (options.linkMultiThread) {
               strappend(compile_command,'/MT ');
            } else {
               strappend(compile_command,'/ML ');
            }
         }
         break;
      case VCPP_OUTPUT_DLL:
         if (options.linkDebug) {
            if (options.linkMultiThread) {
               strappend(compile_command,'/MDd ');
            } else {
               strappend(compile_command,'/LDd ');
            }
         } else {
            if (options.linkMultiThread) {
               strappend(compile_command,'/MD ');
            } else {
               strappend(compile_command,'/LD ');
            }
         }
         break;
      default:
         break;
      }
   }

   strappend(compile_command,'/Fo"'options.objectLocation'" ');
   // finish the compile command
   strappend(compile_command,'%i "%f"');
   _ProjectSet_TargetCmdLine(project_handle,options.compileTargetNode,compile_command,'',options.otherCompileOptions);

   // link command
   _str link_command='"'options.linker'"  %~other';

   int libdir_index;
   for (libdir_index=0;libdir_index<options.libDirs._length();++libdir_index) {
      strappend(link_command,' /LIBPATH:"'options.libDirs[libdir_index]'"');
   }

   if (options.debugFormat==VCPP_DEBUG_FORMAT_PDB) {
      if (options.useCLR && !options.noAssembly) {
         strappend(link_command,' /DEBUG /ASSEMBLYDEBUG /PDB:"'options.pdbFile'"');
      } else {
         strappend(link_command,' /DEBUG /PDB:"'options.pdbFile'"');
      }
   }

   strappend(link_command,' /OUT:"%o" %f %libs');

   _ProjectSet_TargetCmdLine(project_handle,options.linkTargetNode,link_command,'',options.otherLinkOptions);
   // debug command
   _str debug_command=options.debugger:+' ':+options.debuggerOptions:+' %~other';

   // DJB 03-18-2008
   // Integrated .NET debugging is no longer available as of SlickEdit 2008
   //if (options.useBuiltinDebug) {
   //   debug_command='vsclrdebug';
   //}

   _ProjectSet_TargetCmdLine(project_handle,options.debugTargetNode,debug_command,'',options.arguments);

   // execute command
   // still not much to do here
}

static void set_all_controls(VCPP_OPTIONS & options)
{
   _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,true);

   ctlCompiler.p_text=options.compiler;
   ctlOtherCompileOptions.p_text=options.otherCompileOptions;
   ctlPreprocessorDefines.p_text=options.defines;
   ctlForScope.p_value=(int)options.forScope;
   ctlNativeWchar.p_value=(int)options.nativeWchar;
   ctlUnsignedChar.p_value=(int)options.unsignChar;
   ctlCompileAs.select_cb_item(options.compileAs);
   ctlPCHType.select_cb_item(options.usePCH);
   ctlPCHThrough.p_text=options.pchThrough;
   ctlPCHThrough.p_enabled=(options.usePCH==VCPP_USE_PCH_CREATE||options.usePCH==VCPP_USE_PCH_USE);
   ctlPCHFile.p_text=options.pchFile;
   ctlPCHFile.p_enabled=(options.usePCH!=VCPP_USE_PCH_NONE);
   ctlDebugFormat.select_cb_item(options.debugFormat);
   ctlDebugFile.p_text=options.pdbFile;
   ctlTypeCheck.select_cb_item(options.typeChecks);
   ctlSmallerType.p_value=(int)options.smallTypeCheck;
   ctlSecurity.p_value=(int)options.bufferCheck;
   ctlConvention.select_cb_item(options.convention);
   ctlSSE.select_cb_item(options.enhancedInstSet);
   ctlFunctionLinking.p_value=(int)options.functionLink;
   ctlRTTI.p_value=(int)options.RTTI;
   ctlException.p_value=(int)options.exceptionHandling;
   ctlMinimalRebuild.p_value=(int)options.minimalRebuild;
   ctlOptLevel.select_cb_item(options.optLevel);
   ctlOptSizeSpeed.select_cb_item(options.optFavor);
   ctlOptInline.select_cb_item(options.inlineExpansion);
   ctlOptProcessor.select_cb_item(options.optProcessor);
   ctlOptGlobal.p_value=(int)options.optGlobal;
   ctlOptIntrinsic.p_value=(int)options.optIntrinsic;
   ctlOptFiber.p_value=(int)options.optFiber;
   ctlOptFloat.p_value=(int)options.optFloat;
   ctlOptString.p_value=(int)options.optString;
   ctlOptWindows.p_value=(int)options.optWindows;
   ctlOptFrame.p_value=(int)options.optFrame;
   ctlNoDefaultLibs.p_value=(int)options.noDefaultLibs;
   ctlIncrementalLink.p_value=(int)options.incrementalLinking;
   ctlLinkDebug.p_value=(int)options.linkDebug;
   ctlLinkMultiThread.p_value=(int)options.linkMultiThread;
   ctlOutputType.select_cb_item(options.outputType);
   ctlLinker.p_text=options.linker;
   ctlOutputFile.p_text=options.outputFile;
   ctlLibraries.p_text=options.libraries;
   ctlObjectLocation.p_text=options.objectLocation;
   ctlOtherLinkOptions.p_text=options.otherLinkOptions;
   ctlIgnoreStdInclude.p_value=(int)options.ignoreStdInc;
   set_listbox_items(ctlUserIncludesList,options.includeDirs);
   set_listbox_items(ctlLibDirs,options.libDirs);
   ctlWarnLevel.select_cb_item(options.warningLevel);
   ctlWarnError.p_value=(int)options.warnAsErr;
   ctlWarn64.p_value=(int)options.warn64bit;
   ctlCLR.p_value=(int)options.useCLR;
   ctlNoAssembly.p_value=(int)options.noAssembly;
   ctlNoAssembly.p_enabled=options.useCLR;
   ctlAssembliesLabel.p_enabled=options.useCLR;
   set_listbox_items(ctlAssemblies,options.assemblies);
   ctlAssemblies.p_enabled=options.useCLR;
   ctlBrowseAssemblies.p_enabled=options.useCLR;
   ctlMoveAssembliesUp.p_enabled=options.useCLR;
   ctlMoveAssembliesDown.p_enabled=options.useCLR;
   ctlRemoveAssembly.p_enabled=options.useCLR;
   ctlAssemblyDirsLabel.p_enabled=options.useCLR;
   set_listbox_items(ctlAssemblyDirs,options.assemblyDirs);
   ctlAssemblyDirs.p_enabled=options.useCLR;
   ctlBrowseAssemblyDirs.p_enabled=options.useCLR;
   ctlMoveAssemblyDirsUp.p_enabled=options.useCLR;
   ctlMoveAssemblyDirsDown.p_enabled=options.useCLR;
   ctlRemoveAssemblyDir.p_enabled=options.useCLR;

   ctlProgramArgs.p_text=options.arguments;
   ctldbgDebugger.p_text=options.debugger;
   ctldbgOtherDebuggerOptions.p_text=options.debuggerOptions;
   // DJB 03-18-2008
   // Integrated .NET debugging is no longer available in SlickEdit 2008
   if (false && options.useBuiltinDebug) {
      ctlUseCLRDebugger.p_value=1;
      ctlUseOtherDebugger.p_value=0;
      ctldbgDebuggerLabel.p_enabled=false;
      ctldbgDebugger.p_enabled=false;
      ctldbgFindApp.p_enabled=false;
      ctldbgDebuggerOtherLabel.p_enabled=false;
      ctldbgOtherDebuggerOptions.p_enabled=false;
   } else {
      ctlUseCLRDebugger.p_value=0;
      ctlUseOtherDebugger.p_value=1;
      ctldbgDebuggerLabel.p_enabled=true;
      ctldbgDebugger.p_enabled=true;
      ctldbgFindApp.p_enabled=true;
      ctldbgDebuggerOtherLabel.p_enabled=true;
      ctldbgOtherDebuggerOptions.p_enabled=true;
   }

   _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,false);
}

void ctlCurConfig.on_change(int reason)
{
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);

   // this must be set before set_all_controls is called so that the appropirate warning
   // messages will be used when the controls are set.
   boolean all_configs_active=ctlCurConfig.p_text:==ALL_CONFIGS;
   _SetDialogInfo(VCPP_OPTS_ALL_CONFIGS_ACTIVE,all_configs_active);

   _str config_to_use=ctlCurConfig.p_text;

   if (all_configs_active) {
      // pick the first config to setup values
      int start_line=ctlCurConfig.p_line;
      ctlCurConfig._lbtop();
      config_to_use=ctlCurConfig._lbget_text();
      ctlCurConfig.p_line=start_line;
   }

   if (all_config_options._indexin(config_to_use)) {
      set_all_controls(all_config_options:[config_to_use]);
   }

   update_output_type();
}

void ctlok.on_create(int project_handle,_str options="",_str cur_config="",
                     _str project_filename=_project_name)
{
   // split the options passed in to the form
   _str tab_name='';
   _str compile_input_ext='';
   parse options with tab_name ' ' compile_input_ext;

   _vcpp_options_form_initial_alignment();
   setup_controls();

   // when set true, the various controls on the dialog will ignore
   // on_change events
   _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,false);

   _SetDialogInfo(VCPP_OPTS_PROJECT_NAME,project_filename);
   _SetDialogInfo(VCPP_OPTS_PROJECT_HANDLE,project_handle);

   _str temp_config_list[];
   _str config_list[];
   _str temp_config;

   temp_config_list._makeempty();
   config_list._makeempty();

   _ProjectGet_ConfigNames(project_handle,temp_config_list);

   VCPP_OPTIONS all_config_options:[];

   int i;
   for(i=0;i<temp_config_list._length();++i) {
      // if this is a vcpp config, keep it
      temp_config=temp_config_list[i];
      if(strieq(_ProjectGet_Type(project_handle,temp_config),'vcpp')) {
         _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,true);
         ctlCurConfig._lbadd_item(temp_config);
         _SetDialogInfo(VCPP_OPTS_CHANGING_CONFIG,false);
         config_list[config_list._length()]=temp_config;

         setup_config(project_handle,temp_config,all_config_options:[temp_config]);
      }
   }

   _SetDialogInfo(VCPP_OPTS_CONFIG_LIST,config_list);
   _SetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS,all_config_options);

   // add "All Configurations" to list
   ctlCurConfig._lbadd_item(ALL_CONFIGS);
   ctlCurConfig._lbtop();

   // select the appropriate configuration
   if(ctlCurConfig._lbfind_and_select_item(cur_config)) {
      // if the current config is not in the list, default to 'all configurations'
      ctlCurConfig._lbfind_and_select_item(ALL_CONFIGS, '', true);
   }

   // make the appropriate tab the active one
   if(tab_name:=='') {
      ctlMainTab._retrieve_value();
   } else {
      ctlMainTab.sstActivateTabByCaption(tab_name);
   }
}

ctlok.lbutton_up()
{
   // save all options
   int project_handle=_GetDialogInfo(VCPP_OPTS_PROJECT_HANDLE);
   VCPP_OPTIONS all_config_options:[]=_GetDialogInfo(VCPP_OPTS_ALL_CONFIG_OPTIONS);
   _str configs[]=_GetDialogInfo(VCPP_OPTS_CONFIG_LIST);

   _str config_name;
   int i;

   for(i=0;i<configs._length();++i) {
      config_name=configs[i];

      set_commands(project_handle,config_name,all_config_options:[config_name]);
   }

   // close the options dialog
   p_active_form._delete_window(0);
}

_command void vcppoptions()
{
   mou_hour_glass(1);
   //_convert_to_relative_project_file(_project_name);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(0);
   int ctlbutton_wid = project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_vcpp_options_form',ctlbutton_wid,LBUTTON_UP,'W');
   int ctltooltree_wid = project_prop_wid._find_control('ctlToolTree');
   int status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      _message_box('COMPILE command not found');
   } else {
      if( result == '' ) {
         int opencancel_wid = project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         int ok_wid = project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}
