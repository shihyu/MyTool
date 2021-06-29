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
#include "debug.sh"
#include "rte.sh"
#include "xml.sh"
#import "android.e"
#import "applet.e"
#import "cjava.e"
#import "compile.e"
#import "diff.e"
#import "guicd.e"
#import "guiopen.e"
#import "gwt.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "pipe.e"
#import "projconv.e"
#import "rte.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "vc.e"
#import "tags.e"
#import "wkspace.e"
#import "project.e"
#import "xmlcfg.e"
#import "sstab.e"
#endregion

static const OTHER_OPTIONS_MACRO= '%~other';

static _str gConfigList[];
static int gProjectHandle;
static bool gIsProjectTemplate;

defeventtab _java_options_form;

static _str ComplianceStrings[] = {
 "JDK1_1",
 "JDK1_2",
 "JDK1_3",
 "JDK1_4",
 "JDK1_4_2",
 "JDK1_5"
};

static _str ComplianceStringsJavac[] = {
 "None",
 "1.2",
 "1.3",
 "1.4",
 "5",
 "6",
 "7",
 "8",
 "9",
};



static const JAVAOPTS_FORM_HEIGHT=    8275;
static const JAVAOPTS_FORM_WIDTH=    7900 ;

//CONVENTION: Struct types end in _OPTIONS, and the #defines for p_user
//            variables that hold that data end in _INFO


//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllJavacOpts()
struct JAVAC_OPTIONS {
//use: javac [-g][-O][-debug][-depend][-nowarn][-verbose][-classpath path][-nowrite]
//[-deprecation][-d dir][-J<runtime flag>] file.java...
   bool OptimizeOutput;//-O
   bool NoWarnings;//-nowarn
   bool Verbose;//-verbose
   bool Deprecation;//-deprecation
   bool GenerateDebug;//-g
   _str    CompilerName;
   _str    OutputDirectory;//-d
   _str    ClassPath;//-classpath
   _str    OtherOptions;
   _str    FileStr;
   _str    SourceComplianceLevel;//-source
   _str    TargetComplianceLevel;//-target   
   _str    BootClasspath;//-bootclasspath
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllJavaDocOpts()
struct JAVADOC_OPTIONS {
/*
javadoc: No packages or classes specified.
usage: javadoc [options] [packagenames] [sourcefiles] [@files]
* -d <directory>            Destination directory for output files
* -version                  Include @version paragraphs
* -author                   Include @author paragraphs
* -nodeprecated             Do not include @deprecated information
* -notree                   Do not generate class hierarchy
* -noindex                  Do not generate index
*/
  bool Version;//* -version                  Include @version paragraphs
  bool Author;//* -author                   Include @author paragraphs
  bool NoDeprecated;//-nodeprecated             Do not include @deprecated information
  bool NoClassHierarchy;//* -notree                   Do not generate class hierarchy
  bool NoGenerateIndex;//* -noindex                  Do not generate index
  _str CompilerName;
  _str OutputDirectory;//* -d <directory>            Destination directory for output files
  _str OtherOptions;
  //_str FileStr;
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllJarOpts()
struct JAVAJAR_OPTIONS {
   bool NoCompression;     // -0
   bool VerboseOutput;     // -v
   _str OtherOptions;
   _str ArchiveFilename;
   _str AdditionalClassFiles[];  //-C
   _str CompilerName;//This is the appname, just calling it CompilerName for consitency w/ other structs
   _str ManifestFilename;
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllClassPath()
struct CLASSPATH_OPTIONS {
   _str ClassPath;
   //bool AppendClassPathEnvVar;
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllInterpreterOpts()
struct INTERPRETER_OPTIONS {
   _str MainClass;
   _str Arguments;
   bool VerboseOutput;     //-verbose
   bool ShowVersion;       //-showversion
   _str OtherOptions;
   _str InterpreterName;

   bool ClassicVM;         //-classic
   bool NoClassGC;         //-Xnoclassgc
   bool IncrementalGC;     //-Xincgc
   bool ReduceSignals;     //-Xrs
   bool InterpretedOnly;   //-Xint
   bool MixedMode;         //-Xmixed
   _str InitialMemory;        //-Xms<n>
   _str MaxMemory;            //-Xmx<n>
   _str DeviceType;           //-Xdevice
};

//IF YOU CHANGE THIS STRUCT, YOU MUST ALSO CHANGE GetAllAppletviewerOpts()
struct APPLETVIEWER_OPTIONS {
   _str OtherOptions;
   _str URL;
   bool Tempfile;
   _str AppletViewerName;
   _str AppletClass;

   // JDWP built-in debug related options
   bool JDWPDebuggingOn;    // -J-Xdebug -J-Xrunjdwp:...
   int DebugPort;              //    port=8000
};

// these options are stored in the manifest file and there
// is only one set
struct j2me_options {
   _str name;
   _str description;
   _str version;
   _str vendor;
   _str classname;
   _str icon;
};

struct gwt_options{
   _str gwtLoc;
   _str appEngineLoc;
   _str appID;
   _str appVersion;
};

struct android_options{
   _str androidLoc;
   _str ndkLoc;
   _str target;
};


// Struct types end in _OPTIONS, and the #defines for p_user variables
// that hold that data end in _INFO.  There are some local variables that end

// If you add a p_user variable, be sure that it gets saved/restored in
// ReplaceTabControl.

static JAVAC_OPTIONS JAVAC_INFO(...):[] {
   if (arg()) ctlssjavac.p_user=arg(1);
   return ctlssjavac.p_user;
}
static JAVADOC_OPTIONS JAVADOC_INFO(...):[] {
   if (arg()) ctlssjavadoc.p_user=arg(1);
   return ctlssjavadoc.p_user;
}
static JAVAJAR_OPTIONS JAR_INFO(...):[] {
   if (arg()) ctlssjar.p_user=arg(1);
   return ctlssjar.p_user;
}
static CLASSPATH_OPTIONS CLASS_PATH_INFO(...):[] {
   if (arg()) ctlcp_pathlist.p_user=arg(1);
   return ctlcp_pathlist.p_user;
}
//I tried to keep all of these on the tab that they represent.  However, the
//Interpreter, Appletviewer, and Debugger tab can be deleted.
static INTERPRETER_OPTIONS JAVAC_APP_INFO(...):[] {
   if (arg()) ctljavac_no_warnings.p_user=arg(1);
   return ctljavac_no_warnings.p_user;
}
static APPLETVIEWER_OPTIONS JAVAC_APPLETVIEWER_INFO(...):[] {
   if (arg()) ctljavac_verbose.p_user=arg(1);
   return ctljavac_verbose.p_user;
}
static typeless JAVAC_DEBUGGER_INFO(...) {
   if (arg()) ctljavac_other_options.p_user=arg(1);
   return ctljavac_other_options.p_user;
}

static _str JAVAC_LAST_CONFIG(...) {
   if (arg()) ctlCurConfig.p_user=arg(1);
   return ctlCurConfig.p_user;
}
static int JAVAC_CHANGING_CONFIGURATION(...) {
   if (arg()) ctllabel6.p_user=arg(1);
   return ctllabel6.p_user;
}
static _str JAVAC_PROJECT_NAME(...) {
   if (arg()) ctljavadoc_index.p_user=arg(1);
   return ctljavadoc_index.p_user;
}

static j2me_options J2ME_OPTIONS(...) {
   if (arg()) ctllabel35.p_user=arg(1);
   return ctllabel35.p_user;
}

static gwt_options GWT_OPTIONS(...) {
   if (arg()) ctlJDKInstallDirLabel.p_user=arg(1);
   return ctlJDKInstallDirLabel.p_user;
}

static android_options ANDROID_OPTIONS(...) {
   if (arg()) ctlAntInstallDirLabel.p_user=arg(1);
   return ctlAntInstallDirLabel.p_user;
}

static const JAVAC_TAB_CONTROL_XPOS= 180;
static const JAVAC_TAB_CONTROL_YPOS= 930;

static const LIVE_ERRORS_CAPTION=      "Live Errors";
static const INTERPRETER_TAB_CAPTION=  "JRE";
static const APPLETVIEWER_TAB_CAPTION= "Appletviewer";
static const DEBUGGER_TAB_CAPTION=     "Debugger";
static const J2ME_TAB_CAPTION=         "J2ME";
static const GWT_TAB_CAPTION=          "Google";
static const ANDROID_TAB_CAPTION=      "Android";

void ctlok.on_create(int ProjectHandle,_str TabName='',
                     _str CurConfig='',_str ProjectFilename=_project_name,
                     bool IsProjectTemplate=false
                    )
{
   gProjectHandle=ProjectHandle;
   gIsProjectTemplate=IsProjectTemplate;

   _java_options_form_initial_alignment();

   JAVAC_PROJECT_NAME(ProjectFilename);
   ctlProjLabel.p_caption = ctlProjLabel._ShrinkFilename(JAVAC_PROJECT_NAME(), ctlProjLabel.p_width);
   ctlJDKInstallDir.p_text=def_jdk_install_dir;
   ctlJDKInstallDir._retrieve_list();
   //ctljar_additional_file_list._col_width(0,1500);
   ctlAntInstallDir.p_text=def_ant_install_dir;
   ctlAntInstallDir._retrieve_list();
   wid := p_window_id;
   isJ2ME := false;
   isGWT := false;
   isAndroid := false;
   j2me_options jOptions;
   gwt_options gOptions;
   android_options aOptions;
   jOptions.name='';
   J2ME_OPTIONS(jOptions);
   GWT_OPTIONS(gOptions);
   ANDROID_OPTIONS(aOptions);
   p_window_id=ctlCurConfig.p_window_id;
   _ProjectGet_ConfigNames(gProjectHandle,gConfigList);
   int i;
   for (i=0;i<gConfigList._length();++i) {
      if (_ProjectGet_AppType(gProjectHandle,gConfigList[i])==APPTYPE_J2ME) {
         isJ2ME=true;
      }
      if (_ProjectGet_AppType(gProjectHandle,gConfigList[i])==APPTYPE_GWT) {
         isGWT=true;
      }
      if (_ProjectGet_AppType(gProjectHandle,gConfigList[i])==APPTYPE_ANDROID) {
         isAndroid=true;
      }
      if (strieq(_ProjectGet_Type(gProjectHandle,gConfigList[i]),'java')) {
         _lbadd_item(gConfigList[i]);
         continue;
      }
      gConfigList._deleteel(i);--i;
   }
   _lbadd_item(PROJ_ALL_CONFIGS);
   _lbtop();
   if (_lbfind_and_select_item(CurConfig)) {
      _lbfind_and_select_item(PROJ_ALL_CONFIGS, '', true);
   }
   p_window_id=wid;


   JAVAC_OPTIONS JavacOpts:[]=null;
   JAVADOC_OPTIONS JavaDocOpts:[];
   JAVAJAR_OPTIONS JarOpts:[];
   CLASSPATH_OPTIONS ClassPath:[];
   INTERPRETER_OPTIONS JavaAppOpts:[];
   APPLETVIEWER_OPTIONS AppletOpts:[];

   GetJavacOptions("compile",JavacOpts);
   GetJavacOptions("javadoc all",JavaDocOpts);

   GetJavacOptions("make jar",JarOpts);   
   GetClasspath(ClassPath);
   if (isJ2ME) {
      GetJavacOptionsAppType("execute",JavaAppOpts,'j2me');
   } else if (isGWT) {
      GetJavacOptionsAppType("execute",JavaAppOpts,'gwt');
   } else if (isAndroid) {
      GetJavacOptionsAppType("execute",JavaAppOpts,'android');
   } else {
      GetJavacOptionsAppType("execute",JavaAppOpts,'application');
   }
   GetJavacOptionsAppType("applet",AppletOpts,'applet');

   GetJavacOptionsAppType("debug",AppletOpts,'applet');

   JAVAC_INFO(JavacOpts);
   JAVADOC_INFO(JavaDocOpts);
   CLASS_PATH_INFO(ClassPath);
   JAR_INFO(JarOpts);
   JAVAC_APP_INFO(JavaAppOpts);
   JAVAC_APPLETVIEWER_INFO(AppletOpts);

   ctlCurConfig.call_event(CHANGE_CLINE,ctlCurConfig,ON_CHANGE,'W');

   if (TabName=='') {
      ctlss_main_tab._retrieve_value();
   } else {
      // older projects might have "Interpreter" instead of JRE
      if (TabName == "Interpreter" || TabName=="Debugger") {
         TabName = "JRE";
      }
      //Select the proper tab
      ctlss_main_tab.sstActivateTabByCaption(TabName);
   }

   if (_haveRealTimeErrors()) {
      JavaLiveErrors_SetupTab();
      JavaLiveErrors_SetGUIValuesFromDefVars();
   }

   EnableClassPathButtons();
}

void ctljavabrowse.lbutton_up(){
   wid := p_window_id;
   _str init_dir=wid.p_prev.p_text;
   if (init_dir!= "" && !isdirectory(init_dir)) {
      init_dir= "";
   }
   if (init_dir=="") {
      if (_isWindows())   init_dir = 'C:\Program Files\Java\';
      else if (_isMac())  init_dir = "/Library/Java/JavaVirtualMachines/";
      else if (_isUnix()) init_dir = "/usr/java/";
   }
   if (init_dir!= "" && !isdirectory(init_dir)) {
      init_dir= "";
   }
   _str result = _ChooseDirDialog('',init_dir);
   if( result=='' ) {
      return;
   }
   wid.p_prev.p_text=result;
   wid.p_prev.end_line();
   wid.p_prev._set_focus();
   return;
}

void ctlandroidbrowse.lbutton_up(){
   wid := p_window_id;
   _str init_dir=wid.p_prev.p_text;
   if (init_dir!= "" && !isdirectory(init_dir)) {
      init_dir= "";
   }
   _str result = _ChooseDirDialog('',init_dir);
   if( result=='' ) {
      return;
   }
   wid.p_prev.p_text=result;
   wid.p_prev.end_line();
   android_options aOptions=ANDROID_OPTIONS();
   aOptions.androidLoc=result;
   ANDROID_OPTIONS(aOptions);
   if (init_dir != result) {
      int status = _android_getTargetsFromSDK(result, auto targets);
      if (!status) {
         ctltargetchooser._lbclear();
         i := 0;
         for (i = 0; i < targets._length(); i++) {
            ctltargetchooser._lbadd_item(strip(targets[i]));
         }

         // Update our data to match what's selected now.
         aOptions.target = strip(ctltargetchooser.p_text);
         ANDROID_OPTIONS(aOptions);
      }
   }
   wid.p_prev._set_focus();
   return;
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _java_options_form_initial_alignment()
{
   tabWidth := ctlss_main_tab.p_child.p_width;
   padding := ctllabel1.p_x;

   // form
   rightAlign := ctlss_main_tab.p_x_extent;
   sizeBrowseButtonToTextBox(ctlJDKInstallDir.p_window_id, ctlBrowseJDKInstallDir.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlAntInstallDir.p_window_id, ctlBrowseAntInstallDir.p_window_id, 0, rightAlign);

   // compiler tab
   sizeBrowseButtonToTextBox(ctljavac_compiler_name.p_window_id, ctlFindapp.p_window_id);
   sizeBrowseButtonToTextBox(ctljavac_output_directory.p_window_id, ctlFindpath.p_window_id);

   // javadoc tab
   sizeBrowseButtonToTextBox(ctljavadoc_appname.p_window_id, ctlFindJavadocApp.p_window_id);
   sizeBrowseButtonToTextBox(ctljavadoc_output_directory.p_window_id, ctlFindJavadocOutdir.p_window_id);

   // jar tab
   rightAlign = ctljar_archive_filename.p_x_extent;
   sizeBrowseButtonToTextBox(ctljar_appname.p_window_id, ctlFindJarApp.p_window_id, 0, rightAlign);

   // jre tab
   rightAlign = ctlint_main.p_x_extent;
   sizeBrowseButtonToTextBox(ctlint_interpreter.p_window_id, ctlFindInterpreter.p_window_id, 0, rightAlign);

   // appletviewer tab
   rightAlign = ctlapplet_applet_class.p_x_extent;
   sizeBrowseButtonToTextBox(ctlapplet_other_filename.p_window_id, ctlFindFileURL.p_window_id, 0, rightAlign);
   rightAlign = ctlapplet_other_options.p_x_extent;
   sizeBrowseButtonToTextBox(ctlapplet_viewername.p_window_id, ctlFindAppletViewer.p_window_id, 0, rightAlign);

   // live errors tab
   rightAlign = ctljvmtuningframe.p_x_extent;
   sizeBrowseButtonToTextBox(ctlliveerrors_path_to_jdk.p_window_id, ctlliveerrors_browse.p_window_id, 0, rightAlign);

   // j2me
   rightAlign = tabWidth - padding;
   sizeBrowseButtonToTextBox(ctlj2me_icon.p_window_id, ctlj2me_iconBrowse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlj2me_phone.p_window_id, ctlj2me_newphone.p_window_id, 0, rightAlign);
   ctlj2me_appName.p_width = ctlj2me_description.p_width = ctlj2me_version.p_width =
      ctlj2me_vendor.p_width = ctlj2me_class.p_width = ctlj2me_bootclasspath.p_width = ctlj2me_icon.p_width;

   // google
   rightAlign = gwtFrame.p_width - padding;
   sizeBrowseButtonToTextBox(gwtLocBox.p_window_id, gwtLocBrowse.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(appLocBox.p_window_id, appLocBrowse.p_window_id, 0, rightAlign);
   appVersionBox.p_width = appIdBox.p_width = (appLocBox.p_x_extent) - appIdBox.p_x;

   // android 
   rightAlign = tabWidth - padding;
   sizeBrowseButtonToTextBox(ctlandroid_sdk_loc.p_window_id, androidSdkBrowse.p_window_id, 0, rightAlign);
   ctlandroid_sdk_loc.p_width = ctlandroid_sdk_loc.p_width;
   sizeBrowseButtonToTextBox(ctlandroid_ndk_loc.p_window_id, androidNdkBrowse.p_window_id, 0, rightAlign);
   ctlandroid_ndk_loc.p_width = ctlandroid_ndk_loc.p_width;
}

void _java_options_form.on_resize(int move, bool fromReplaceTabControl = false)
{
   // was this a move only?
   if (move) return;

   // enforce a minimum size
   // if the minimum width has not been set, it will return 0
   if (!_minimum_width()) {
      _set_minimum_size(JAVAOPTS_FORM_WIDTH, JAVAOPTS_FORM_HEIGHT);
   }

   // loop thru tabs to see which ones are there and which arent
   hasInterpreterTab := false;
   hasAppletViewerTab := false;
   hasDebuggerTab := false;
   hasJ2METab := false;
   hasGWTTab := false;
   hasAndroidTab := false;
   
   _str tabNames[] = null;
   ctlss_main_tab.sstGetAllTabCaptions(tabNames);
   int i;
   for(i = 0; i < tabNames._length(); i++) {
      if(strieq(tabNames[i], INTERPRETER_TAB_CAPTION)) {
         hasInterpreterTab = true;
      } else if(strieq(tabNames[i], APPLETVIEWER_TAB_CAPTION)) {
         hasAppletViewerTab = true;
      } else if(strieq(tabNames[i], DEBUGGER_TAB_CAPTION)) {
         hasDebuggerTab = true;
      } else if (strieq(tabNames[i], J2ME_TAB_CAPTION)) {
         hasJ2METab = true;
      } else if (strieq(tabNames[i], GWT_TAB_CAPTION)) {
         hasGWTTab = true;
      } else if (strieq(tabNames[i], ANDROID_TAB_CAPTION)) {
         hasAndroidTab = true;
      }
   }

   // calculate deltas based on the width and height of the main tab
   // control relative to the width and height of the forms client
   // area.
   int deltax = p_width - (2 * ctlss_main_tab.p_x + ctlss_main_tab.p_width);
   int deltay = p_height - (ctlok.p_y_extent + 60);

   // the entire tab control is deleted and restored when the configuration
   // is changed.  when that happens, the tab control and all of its contents
   // are reloaded at their default size.  to work around this, the resize
   // handler has to be called from the ReplaceTabControl() function.  in
   // this special case, any controls that are not redrawn as part of the
   // tab control should *not* be moved because they are already in their
   // proper places
   if(!fromReplaceTabControl) {

      // project label
      ctlProjLabel.p_width += deltax;
      ctlProjLabel.p_caption = ctlProjLabel._ShrinkFilename(JAVAC_PROJECT_NAME(), ctlProjLabel.p_width);

      // handle current config
      ctlCurConfig.p_width += deltax;

      // handle the ok and cancel buttons
      ctlok.p_y += deltay;
      ctlcancel.p_y += deltay;

      // handle the jdk and ant install dir boxes and buttons
      ctlJDKInstallDirLabel.p_y += deltay;
      ctlJDKInstallDir.p_y += deltay;
      ctlJDKInstallDir.p_width += deltax;
      ctlBrowseJDKInstallDir.p_x += deltax;
      ctlBrowseJDKInstallDir.p_y += deltay;

      ctlAntInstallDirLabel.p_y += deltay;
      ctlAntInstallDir.p_y += deltay;
      ctlAntInstallDir.p_width += deltax;
      ctlBrowseAntInstallDir.p_x += deltax;
      ctlBrowseAntInstallDir.p_y += deltay;

      // handle the main tab control
      ctlss_main_tab.p_width += deltax;
      ctlss_main_tab.p_height += deltay;
   }

   // handle compiler tab
   ctljavac_compiler_name.p_width += deltax;
   ctlFindapp.p_x += deltax;
   ctljavac_output_directory.p_width += deltax;
   ctlFindpath.p_x += deltax;
   ctljavac_other_options.p_width += deltax;

   // handle javadoc tab
   ctljavadoc_appname.p_width += deltax;
   ctlFindJavadocApp.p_x += deltax;
   ctljavadoc_output_directory.p_width += deltax;
   ctlFindJavadocOutdir.p_x += deltax;
   ctljavadoc_other_options.p_width += deltax;

   // handle jar tab
   ctljar_archive_filename.p_width += deltax;
   ctljar_manifest_filename.p_width += deltax;
   ctljar_appname.p_width += deltax;
   ctlFindJarApp.p_x += deltax;
   ctljar_other.p_width += deltax;
   ctljar_additional_file_list.p_width += deltax;
   ctljar_additional_file_list.p_height += deltay;
   ctljar_add_file.p_x += deltax;
   ctljar_add_path.p_x += deltax;
   ctljar_remove.p_x += deltax;

   // handle classpath tab
   ctlcp_pathlist.p_width += deltax;
   ctlcp_pathlist.p_height += deltay;
   ctlcp_add_path.p_x += deltax;
   ctlcp_add_jar_file.p_x += deltax;
   ctlcp_add_jar_wildcard.p_x += deltax;
   ctlcp_add_classpath.p_x += deltax;
   ctlcp_edit.p_x += deltax;
   ctlcp_delete.p_x += deltax;
   ctlcp_up.p_x += deltax;
   ctlcp_down.p_x += deltax;
   ctlantmake_use_classpath.p_y += deltay;

   // handle interpreter tab
   if(hasInterpreterTab) {
      ctlint_main.p_width += deltax;
      ctlint_args.p_width += deltax;
      ctlint_other.p_width += deltax;
      ctlint_interpreter.p_width += deltax;
      ctlFindInterpreter.p_x += deltax;
   }

   // handle appletviewer tab
   if(hasAppletViewerTab) {
      ctlAppletURLFrame.p_width += deltax;
      ctlapplet_applet_class.p_width += deltax;
      ctlapplet_other_filename.p_width += deltax;
      ctlFindFileURL.p_x += deltax;
      ctlAppletPortFrame.p_width += deltax;
      ctlapplet_other_options.p_width += deltax;
      ctlapplet_viewername.p_width += deltax;
      ctlFindAppletViewer.p_x += deltax;
   }

   // handle the J2ME tab
   if (hasJ2METab) {
      ctlj2me_appName.p_width += deltax;
      ctlj2me_description.p_width += deltax;
      ctlj2me_version.p_width += deltax;
      ctlj2me_vendor.p_width += deltax;
      ctlj2me_class.p_width += deltax;
      ctlj2me_icon.p_width += deltax;
      ctlj2me_iconBrowse.p_x += deltax;
      ctlj2me_phone.p_width += deltax;
      ctlj2me_newphone.p_x += deltax;
      ctlj2me_bootclasspath.p_width += deltax;
   }

   // handle the Google tab
   if (hasGWTTab) {
      gwtFrame.p_width += deltax;
      appFrame.p_width += deltax;
      gwtLocBox.p_width += deltax;
      gwtLocBrowse.p_x += deltax;
      appLocBox.p_width += deltax;
      appLocBrowse.p_x += deltax;
      appIdBox.p_width += deltax;
      appVersionBox.p_width += deltax;
      gwtNoticeLabel.p_width += deltax;
   }

   // handle the Android tab
   if (hasAndroidTab) {
      ctlandroid_sdk_loc.p_width += deltax;
      androidSdkBrowse.p_x += deltax;
      ctlandroid_ndk_loc.p_width += deltax;
      androidNdkBrowse.p_x += deltax;
   }
}

static void EnableExecuteTabs()
{
   haveApplet := haveApplication := haveJ2ME := haveGWT := haveAndroid := false;
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      int i;
      for (i=0;i<gConfigList._length();++i) {
         _str AppType=_ProjectGet_AppType(gProjectHandle,gConfigList[i]);
         if (strieq(AppType,APPTYPE_APPLET)) {
            haveApplet=true;
         }else if (strieq(AppType,APPTYPE_APPLICATION)) {
            haveApplication=true;
         }else if (strieq(AppType,APPTYPE_J2ME)) {
            haveJ2ME=true;
            haveApplication=true;
         }else if (strieq(AppType,APPTYPE_GWT)) {
            haveGWT=true;
            haveApplication=true;
         }else if (strieq(AppType,APPTYPE_ANDROID)) {
            haveAndroid=true;
            haveApplication=true;
         }
         if (haveApplet && haveApplication && haveJ2ME && haveGWT && haveAndroid) {
            return;
         }
      }
   }else{
      _str AppType=_ProjectGet_AppType(gProjectHandle,ctlCurConfig.p_text);
      if (strieq(AppType,APPTYPE_APPLET)) {
         haveApplet=true;
      }else if (strieq(AppType,APPTYPE_APPLICATION)) {
         haveApplication=true;
      }else if (strieq(AppType,APPTYPE_J2ME)) {
         haveJ2ME=true;
         haveApplication=true;
      }else if (strieq(AppType,APPTYPE_GWT)) {
         haveGWT=true;
         haveApplication=true;
      }else if (strieq(AppType,APPTYPE_ANDROID)) {
         haveAndroid=true;
         haveApplication=true;
      }
   }
   _str TabNames[]=null;
   wid := p_window_id;
   p_window_id=ctlss_main_tab;
   sstGetAllTabCaptions(TabNames);
   int i;
   for (i=TabNames._length()-1;i>-1;--i) {
      if ( (strieq(INTERPRETER_TAB_CAPTION,TabNames[i]) && !haveApplication) ||
           (strieq(APPLETVIEWER_TAB_CAPTION,TabNames[i]) && !haveApplet) ||
           (strieq(DEBUGGER_TAB_CAPTION,TabNames[i]) && !haveApplication) ||
           (strieq(J2ME_TAB_CAPTION,TabNames[i]) && !haveJ2ME) ||
           (strieq(LIVE_ERRORS_CAPTION,TabNames[i]) && !_haveRealTimeErrors()) ||
           (strieq(GWT_TAB_CAPTION,TabNames[i]) && !haveGWT) ||
           (strieq(ANDROID_TAB_CAPTION,TabNames[i]) && !haveAndroid)
          ) {
         OldActiveTab := p_ActiveTab;
         p_ActiveTab=i;
         _deleteActive();
         p_window_id=p_parent;
         if (i!=OldActiveTab) {
            p_ActiveTab=OldActiveTab;
         }
      }
   }
   p_window_id=wid;
}

void ctlappletusejdwp.lbutton_up()
{
   debugging_on := ctlappletusejdwp.p_value? true:false;
   ctlappletdebugport.p_enabled=debugging_on;
}
void ctlok.on_destroy()
{
   int value = ctlss_main_tab.p_ActiveTab;
   ctlss_main_tab._append_retrieve( ctlss_main_tab.p_window_id, value );
}
bool _isJavaInstallDirKaffe(_str install_dir)
{
   if (install_dir!='') {
      _maybe_append_filesep(install_dir);
      // Could check for '/usr/share/libgcj.jar' as well.
      return(_file_eq(install_dir,'/usr/share/'));
   }
   _str javaPath = path_search("javac");
   if (javaPath == "") return(false);
   //javaPath = absolute(javaPath);  // resolve symbollic links
   javaPath = _strip_filename(javaPath, "N");
   if (javaPath=='/usr/bin/') {
      if (file_exists('/usr/share/libgcj.jar')) {
         return(true);
      }
   }
   return(false);
}
int _check_java_installdir(_str &install_dir, bool check_for_jvm_lib = false)
{
   if (_isUnix()) {
      if (_isJavaInstallDirKaffe(install_dir)) {
         _maybe_append_filesep(install_dir);
         return(0);
      }
   }
   install_dir=absolute(install_dir);
   _maybe_strip_filesep(install_dir);
   if (!isdirectory(install_dir)) {
      //ctlJDKInstallDir._text_box_error("The JDK installation directory is not valid.  Please correct or clear this field.");
      return(1);
   }
   if (_strip_filename(install_dir,'p')=='bin') {
      install_dir=_strip_filename(install_dir,'n');
      install_dir=substr(install_dir,1,length(install_dir)-1);
   }
   _str maybeJavaCPath;
   if (_isMac()) {
      if (file_exists(install_dir) && file_exists(install_dir:+FILESEP:+"Contents")) {
         _maybe_append_filesep(install_dir);
         install_dir :+= "Contents";
      }
      if (file_exists(install_dir) && file_exists(install_dir:+FILESEP:+"Home")) {
         _maybe_append_filesep(install_dir);
         install_dir :+= "Home";
      }
      maybeJavaCPath= install_dir:+FILESEP:+'bin':+FILESEP:+'javac';
      if (!file_exists(maybeJavaCPath:+EXTENSION_EXE)) {
         maybeJavaCPath= install_dir:+FILESEP:+'Versions/Current/Commands':+FILESEP:+'javac';
      }
   } else {
      maybeJavaCPath= install_dir:+FILESEP:+'bin':+FILESEP:+'javac';
   }
   if (!file_exists(maybeJavaCPath:+EXTENSION_EXE)) {
      //ctlJDKInstallDir._text_box_error("The JDK installation directory specified does not contain the javac program.  Please correct or clear this field.");
      return(2);
   }
   if (check_for_jvm_lib) {
      // check for jre root dir in jdk installation
      jdk_dir := install_dir:+FILESEP;
      jre_dir := install_dir:+FILESEP:+'jre':+FILESEP;
      jli_dir := install_dir:+FILESEP:+'lib/jli':+FILESEP;
      mac_java_vm := '/System/Library/Frameworks/JavaVM.framework/JavaVM';
      if (_isMac() && !file_exists(jre_dir) /*&& !file_exists(jli_dir)*/) {
         // On the Mac, the Apple-provided JDK does NOT have a jre subdir under
         // the HOME location. So see if the backup location at
         // /System/Library/Frameworks/JavaVM.framework/JavaVM exists.
         if (!file_exists(mac_java_vm)) {
             return(3);
         } else {
             def_java_live_errors_jvm_lib = mac_java_vm;
             _config_modify_flags(CFGMODIFY_DEFVAR);
         }
      }
      // find everything under the jre directory, looking for jvm.dll or libjvm.so
      // doing it this way because depending on architecture it can be in different places
      // file_match should always find libraries in client before server
      if (_isMac()) {
         // See if we can find libjvm.dylib under the jre directory. If not, then
         // fall back to the system provided library. Note: There *is* an Apple-made
         // libjvm.dylib (under a different directory), but that cannot be used as it
         // does not expose the JNI_CreateJavaVM funtion.
         file := file_match(_maybe_quote_filename(jli_dir:+FILESEP:+"libjli.dylib")' +T',1);
         if (file == "") {
            file = file_match(_maybe_quote_filename(jre_dir:+FILESEP:+"libjli.dylib")' +T',1);
         }

         if (file == "") {
            file = file_match(_maybe_quote_filename(jre_dir:+FILESEP:+"libjvm.dylib")' +T',1);
         }
         if (file == "") {
            file = file_match(_maybe_quote_filename(jdk_dir:+FILESEP:+"libjvm.dylib")' +T',1);
         }
         if (file == "") {
            file = file_match(_maybe_quote_filename(jdk_dir:+FILESEP:+"libjvm.dylib")' +T',1);
         }
         for (;;) {
            if (file == '') {
               // Unable to find libjvm.dylib under the HOME/jre/lib directory.
               // So use the default system provided JavaVM
               if (file_exists(mac_java_vm)) {
                  def_java_live_errors_jvm_lib = mac_java_vm;
                  _config_modify_flags(CFGMODIFY_DEFVAR);
               } else {
                  return(4);
               }
               break;
            }
            if (_strip_filename(file, 'P') == 'libjvm.dylib') {
               def_java_live_errors_jvm_lib = file;
               _config_modify_flags(CFGMODIFY_DEFVAR);
               break;
            }
            if (_strip_filename(file, 'P') == 'libjli.dylib') {
               def_java_live_errors_jvm_lib = file;
               _config_modify_flags(CFGMODIFY_DEFVAR);
               break;
            }
            file = file_match(file, 0);
         }
      } else if (_isUnix()) {
         file := file_match(_maybe_quote_filename(jre_dir:+'lib':+FILESEP:+"*.so")' +T',1);
         if ( file == "" ) {
            file = file_match(_maybe_quote_filename(jdk_dir:+'lib':+FILESEP:+"*.so")' +T',1);
         }
         for (;;) {
            if (file == '') {
               return(4);
            }
            if (_strip_filename(file, 'P') == 'libjvm.so') {
               def_java_live_errors_jvm_lib = file;
               _config_modify_flags(CFGMODIFY_DEFVAR);
               break;
            }
            file = file_match(file, 0);
         }
      } else {
         file := file_match(_maybe_quote_filename(jre_dir:+"*.dll")' +T',1);
         if ( file == "" ) {
            file = file_match(_maybe_quote_filename(jdk_dir:+"*.dll")' +T',1);
         }
         for (;;) {
            if (file == '') {
               return(4);
            }
            if (_strip_filename(file, 'P') == 'jvm.dll') {
               def_java_live_errors_jvm_lib = file;
               _config_modify_flags(CFGMODIFY_DEFVAR);
               break;
            }
            file = file_match(file, 0);
         }
      }
   }
   _maybe_append_filesep(install_dir);
   return(0);
}
void ctlok.lbutton_up()
{
   // Shouldn't do this here before error checking
//   JavaLiveErrors_SetDefVarsFromGUI();

   _str j2me_name;
   _str j2me_image;
   _str j2me_class;
   _str j2me_vendor;

   if (ctljar_appname.p_text=='') {
      ctljar_appname.p_text='jar';
      ctljar_appname._text_box_error("You must specify a jar program");
      return;
   }
   typeless status=0;
   install_dir := ctlJDKInstallDir.p_text;
   if (install_dir!='') {
      status=_check_java_installdir(install_dir);
      if (status==1) {
         ctlJDKInstallDir._text_box_error("The JDK installation directory is not valid.  Please correct or clear this field.");
         return;
      }
      if (status) {
         ctlJDKInstallDir._text_box_error("The JDK installation directory specified does not contain the javac program.  Please correct or clear this field.");
         return;
      }
   }
   if (!_file_eq(def_jdk_install_dir,install_dir)) {
      def_jdk_install_dir=install_dir;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      if (_project_DebugCallbackName!='') {
         dbg_clear_sourcedirs();
      }
   }
   _append_retrieve(ctlJDKInstallDir,def_jdk_install_dir);

   ant_install_dir := ctlAntInstallDir.p_text;
   if (!_file_eq(def_ant_install_dir,ant_install_dir)) {
      def_ant_install_dir=ant_install_dir;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   _append_retrieve(ctlAntInstallDir,def_ant_install_dir);
   
   closeDialog := true;
   if (_haveRealTimeErrors()) {
      dir_from_gui := "";
      // if live errors are enabled, check the jdk 6 field to make sure this is valid
      if (ctlliveerrors_enable_live_errors.p_value == 1) {
         def_java_live_errors_errored = 0;
         // check if it's empty...
         if (ctlliveerrors_path_to_jdk.p_text == "") {
            _message_box("Path to JDK 1.6 or later must be specified in order to use Live Errors."); 
            return;
         }
         // check if it's a valid jdk root...
         dir_from_gui = ctlliveerrors_path_to_jdk.p_text;
         // this checks if the dir exists, and if there is javac under the bin
         // modified to check for jvm lib which live errors needs to find
         int res = _check_java_installdir(dir_from_gui, true);
         //check specific error code here
         if (res != 0) {
            _message_box("Path to JDK 1.6 or later must be valid in order to use Live Errors."); 
            return;
         }
         if (dir_from_gui != def_java_live_errors_jdk_6_dir) {
            _maybe_append_filesep(dir_from_gui);
            java_name :=  dir_from_gui :+ 'bin' :+ FILESEP :+ 'java';
            java_name :+= EXTENSION_EXE;
            _str version = get_jdk_version_from_exe(_maybe_quote_filename(java_name));
            if (version == "") {
               _message_box("Path to JDK 1.6 or later must be valid in order to use Live Errors."); 
               return;
            }
            result := check_for_jdk_6(version);
            if (!result) {
               _message_box("Path to JDK 1.6 or later must be 1.6 or later."); 
               return;
            }
            rteStop();
         }
      }
      int result = JavaLiveErrors_SetDefVarsFromGUI(closeDialog);
      if (result != 0) {
         rte_abort(result);
         return;
      }
   }

   ctlCurConfig.call_event(CHANGE_CLINE,ctlCurConfig,ON_CHANGE,'W');

   haveInterpreterTab := ctlss_main_tab.sstTabExists(INTERPRETER_TAB_CAPTION);
   haveAppletviewerTab := ctlss_main_tab.sstTabExists(APPLETVIEWER_TAB_CAPTION);
   haveDebuggerTab := haveInterpreterTab;
   haveJ2METab := ctlss_main_tab.sstTabExists(J2ME_TAB_CAPTION);
   haveGWTTab := ctlss_main_tab.sstTabExists(GWT_TAB_CAPTION);
   haveAndroidTab := ctlss_main_tab.sstTabExists(ANDROID_TAB_CAPTION);

   JAVAC_OPTIONS AllJavacOpts:[];
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   CLASSPATH_OPTIONS AllClassPath:[];
   JAVAJAR_OPTIONS AllJarInfo:[];
   INTERPRETER_OPTIONS AllAppInfo:[];
   APPLETVIEWER_OPTIONS AllAppletOptions:[];
   j2me_options jOptions;
   gwt_options gOptions;
   android_options aOptions;

   AllJavacOpts=JAVAC_INFO();
   AllJavaDocOpts=JAVADOC_INFO();
   AllClassPath=CLASS_PATH_INFO();
   AllJarInfo=JAR_INFO();
   if (haveInterpreterTab) AllAppInfo=JAVAC_APP_INFO();
   if (haveAppletviewerTab) AllAppletOptions=JAVAC_APPLETVIEWER_INFO();
   if (haveJ2METab) jOptions=J2ME_OPTIONS();
   if (haveGWTTab) gOptions=GWT_OPTIONS();
   if (haveAndroidTab) aOptions=ANDROID_OPTIONS();

   if (haveGWTTab) {
      closeDialog = WriteGWTValues(gOptions, AllClassPath);
   }

   if (haveAndroidTab) {
      closeDialog = WriteAndroidValues(aOptions, AllClassPath);
   }

   // get the configurations for the project and remember the active config
   ProjectConfig configList[] = null;
   int j;
   typeless i=0;
   for (j=0;j<gConfigList._length();++j) {
      i=gConfigList[j];

      //There are some double checks in here for the type.  This way if
      //we get an older project file, we are ok.

      if (AllJavacOpts._varformat()==VF_HASHTAB) {
         SetCompilerCommand(i,AllJavacOpts,AllClassPath);
      }

      if (AllJavaDocOpts._varformat()==VF_HASHTAB) {
         SetJavaDocCommand(i,AllJavaDocOpts,AllClassPath);
      }

      if (AllJarInfo._varformat()==VF_HASHTAB) {
         SetJarCommand(i,AllJarInfo);
      }

      if (haveInterpreterTab && AllAppInfo._varformat()==VF_HASHTAB) {
         SetInterpreterOptions(i,AllAppInfo,AllClassPath);
      }

      if (haveAppletviewerTab && AllAppletOptions._varformat()==VF_HASHTAB) {
         SetAppletOptions(i,AllAppletOptions, AllClassPath);
      }

      SetJDWPDebuggerOptions(i,AllAppInfo);

      // find the configuration that is being set and update its output directory
      _ProjectSet_ObjectDir(gProjectHandle,AllJavacOpts:[i].OutputDirectory,i);
      // set the output directory for the rte project handle
      if (def_java_live_errors_enabled && _java_live_errors_supported()) {
         int rte_Project = get_rte_project_handle();
         _ProjectSet_ObjectDir(rte_Project,AllJavacOpts:[i].OutputDirectory,i);
      }
   }

   if (haveJ2METab) {
      int orig_wid;
      int temp_wid;
      status=_open_temp_view(AllJarInfo:[gConfigList[0]].ManifestFilename,temp_wid,orig_wid);
      if (!status) {
         top();
         up();

         if (!status) {
            top();
            up();
            while (!down()) {
               get_line(auto line);

               _str key;

               parse line with key ':' .;
               key=strip(key);

               switch (key) {
               case 'MIDlet-1':
                  replace_line('MIDlet-1: 'jOptions.name', 'jOptions.icon', 'jOptions.classname);
                  break;
               case 'MIDlet-Vendor':
                  replace_line('MIDlet-Vendor: 'jOptions.vendor);
                  break;
               case 'MIDlet-Name':
                  replace_line('MIDlet-Name: 'jOptions.name);
                  break;
               case 'MIDlet-Description':
                  replace_line('MIDlet-Description: 'jOptions.description);
                  break;
               case 'MIDlet-Version':
                  replace_line('MIDlet-Version: 'jOptions.version);
                  break;
               }
            }
            save();
            p_window_id=orig_wid;
            _delete_temp_view(temp_wid);
         }
      }
   }

   if (def_java_live_errors_enabled && _java_live_errors_supported()) {
      other_opts := "";
      if(ctlCurConfig.p_text == PROJ_ALL_CONFIGS) {
         // Pick one any one.
         typeless firstElement;
         firstElement._makeempty();
         AllJavacOpts._nextel(firstElement);
         if(!firstElement._isempty()) {
            rteSetSourceComplianceLevel(AllJavacOpts:[firstElement].SourceComplianceLevel);
            other_opts = AllJavacOpts:[firstElement].OtherOptions;
         }
      } else {
         rteSetSourceComplianceLevel(AllJavacOpts:[ctlCurConfig.p_text].SourceComplianceLevel);
         other_opts = AllJavacOpts:[ctlCurConfig.p_text].OtherOptions;
      }
      if (def_java_live_errors_other_options) {
         _str sp_from_other = rte_strip_sourcepath_from_other_options(other_opts);
         rteMaybeAddToSourcePath(get_rte_project_handle(),sp_from_other);
         rteSetOtherOptions(other_opts);
      } else {
         rteSetOtherOptions("");
      }
      _workspace_opened_rte();
   }

   if (closeDialog) {
      p_active_form._delete_window(0);
   }
}

bool check_for_jdk_6(_str version){
   _str major, minor, rest;
   parse version with major '.' minor '.' rest;
   return((minor >= 6)||(major>=2));
}

static void _adjustClassPath(_str projectName,_str &orig_classPath,_str output_dir)
{
   _str classPath=orig_classPath;
   if (projectName=='') return;
   if (classPath!='') {
      classPath=_replace_envvars2(classPath);
   }
   classPath=stranslate(classPath,FILESEP,'/');
   toDir := _strip_filename(projectName,'N');
   if (classPath=='') {
      classPath=get_env("CLASSPATH");
      if (classPath=='') {
         classPath='.';
      }
   }
   // Make sure the output directory is in the classpath
   if (output_dir=='') {
      output_dir='.';
   }
   _maybe_append_filesep(output_dir);
   output_dir=absolute(output_dir,toDir);

   filename := "";
   for (;;) {
      parse classPath with filename (PARSE_PATHSEP_RE),'r' classPath;
      if (filename=='' && classPath=='') {
         break;
      }
      if (filename=='') continue;
      _maybe_append_filesep(filename);
      filename=absolute(filename,toDir);
      if (_file_eq(output_dir,filename)) {
         return;
      }
   }
   classPath=orig_classPath;

   //Make the outputdir relative
   outputdir := relative(output_dir,toDir);
   if (outputdir!='') {
      //We have to be sure that output dir is not ''.
      //If it is, we don't want to put a PATHSEP at the beginning.
      outputdir :+= PATHSEP;
   }
   if (classPath=='') {
      classPath=outputdir:+'%(CLASSPATH)';
   } else {
      // When checking for outputdir in classPath, only put a PATHSEP on the
      // beginning, there is one on the end from a couple of lines above.
      if (outputdir!='' &&
          !pos(PATHSEP:+outputdir,PATHSEP:+classPath:+PATHSEP,1,_fpos_case)) {
         classPath=outputdir:+classPath;
      }
   }
   orig_classPath=classPath;
}
static void SetCompilerCommand(_str CurConfig,
                              JAVAC_OPTIONS AllJavacOpts:[],
                              CLASSPATH_OPTIONS AllClassPath:[]
                              )
{
   Cmd := _maybe_quote_filename(AllJavacOpts:[CurConfig].CompilerName);

   // check for bmj because it works better with unix paths
   if(_file_eq(_strip_filename(AllJavacOpts:[CurConfig].CompilerName, "PE"), "bmj")) {
      Cmd :+= " %xup";
   }

   _str Other=AllJavacOpts:[CurConfig].OtherOptions;
   if (Other!='') {
      Cmd :+= ' 'OTHER_OPTIONS_MACRO;
   }

   if (AllJavacOpts:[CurConfig].Deprecation) {
      Cmd :+= ' -deprecation';
   }
   if (AllJavacOpts:[CurConfig].OptimizeOutput) {
      Cmd :+= ' -O';
   }
   if (AllJavacOpts:[CurConfig].NoWarnings) {
      Cmd :+= ' -nowarn';
   }
   if (AllJavacOpts:[CurConfig].Verbose) {
      Cmd :+= ' -verbose';
   }
   if (AllJavacOpts:[CurConfig].GenerateDebug) {
      Cmd :+= ' -g';
   }

   // *always* add the output directory now, even if it will be resolved to the current dir.
   // if the dir is not empty, the -d will automatically be prepended
   Cmd :+= ' %jbd';

   if (AllJavacOpts:[CurConfig].ClassPath!='') {
      Cmd :+= ' -c '_maybe_quote_filename(AllJavacOpts:[CurConfig].ClassPath);
   }
   _str classpath=AllClassPath:[CurConfig].ClassPath;

   // *always* add the classpath because it will include the output directory.  the classpath
   // is no longer adjusted for the output directory since _parse_project_command will now add
   // the output directory to the classpath automatically.  if there is no defined classpath
   // and no defined output directory, the classpath option will not be inserted
   Cmd :+= ' %cp';

   // Need to add -source and any other options after any macro substitutions(%cp) but before the file.
   if(AllJavacOpts:[CurConfig].SourceComplianceLevel != '' && AllJavacOpts:[CurConfig].SourceComplianceLevel != 'None') {
      Cmd :+= ' -source ';
      Cmd :+= AllJavacOpts:[CurConfig].SourceComplianceLevel;
   }

   // Need to add -source and any other options after any macro substitutions(%cp) but before the file.
   if(AllJavacOpts:[CurConfig].TargetComplianceLevel != '' && AllJavacOpts:[CurConfig].TargetComplianceLevel != 'None') {
      Cmd :+= ' -target ';
      Cmd :+= AllJavacOpts:[CurConfig].TargetComplianceLevel;
   }

   if (AllJavacOpts:[CurConfig].BootClasspath != '') {
      Cmd :+= ' -bootclasspath ';
      Cmd :+= _maybe_quote_filename(AllJavacOpts:[CurConfig].BootClasspath);
   }


   _ProjectSet_ClassPathList(gProjectHandle,classpath,CurConfig);
   if (AllJavacOpts:[CurConfig].FileStr != null) {
      Cmd :+= ' 'AllJavacOpts:[CurConfig].FileStr;
   }

   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_TargetNode(gProjectHandle,'compile',CurConfig),
                              Cmd,null,Other);
   // set classpath and target command line for rte_project handle
   if (def_java_live_errors_enabled && _java_live_errors_supported()) {
      int rte_Project = get_rte_project_handle();
      _ProjectSet_ClassPathList(rte_Project,classpath,CurConfig);
      _ProjectSet_TargetCmdLine(rte_Project,
                                 _ProjectGet_TargetNode(rte_Project,'compile',CurConfig),
                                 Cmd,null,Other);
   }
   //(*pProjectInfo):[CurConfig].ToolInfo[COMPILE_INDEX].cmd=Cmd;
   //(*pProjectInfo):[CurConfig].ToolInfo[COMPILE_INDEX].otherOptions=Other;
}
static int get_rte_project_handle(){
   _str _fullPath = _AbsoluteToWorkspace(_project_name);
   return(_ProjectHandle(_fullPath));
}

static void SetJavaDocCommand(_str CurConfig,
                              JAVADOC_OPTIONS AllJavaDocOpts:[],
                              CLASSPATH_OPTIONS AllClassPath:[]
                              )
{
   Cmd := "javamakedoc ";
   Cmd :+= _maybe_quote_filename(AllJavaDocOpts:[CurConfig].CompilerName);

   if (AllJavaDocOpts:[CurConfig].Author) {
      Cmd :+= ' -author';
   }
   if (AllJavaDocOpts:[CurConfig].Version) {
      Cmd :+= ' -version';
   }
   if (AllJavaDocOpts:[CurConfig].NoClassHierarchy) {
      Cmd :+= ' -notree';
   }
   if (AllJavaDocOpts:[CurConfig].NoDeprecated) {
      Cmd :+= ' -nodeprecated';
   }
   if (AllJavaDocOpts:[CurConfig].NoGenerateIndex) {
      Cmd :+= ' -noindex';
   }
   if (AllJavaDocOpts:[CurConfig].OutputDirectory!='') {
      Cmd :+= ' -d '_maybe_quote_filename(AllJavaDocOpts:[CurConfig].OutputDirectory);
   }
   //if (AllClassPath:[CurConfig].ClassPath!='') {
      Cmd :+= ' %cp';
   //}
   _str Other=AllJavaDocOpts:[CurConfig].OtherOptions;
   if (Other!='') {
      Cmd :+= ' 'OTHER_OPTIONS_MACRO;
   }

   // We used to put single quotes around the %{*.java} option for the 
   // __UNIX__ platforms but it actually made "javadoc all" to break on 
   // UNIX.  So that code was removed.  I tested it on Linux and Solaris 
   // platform to make sure it works on those platforms. --Kohei
   Cmd :+= " %{*.java}";

   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_TargetNode(gProjectHandle,'javadoc all',CurConfig),
                              Cmd,null,Other);
   //(*pProjectInfo):[CurConfig].ToolInfo[JAVADOC_INDEX].cmd=Cmd;
   //(*pProjectInfo):[CurConfig].ToolInfo[JAVADOC_INDEX].otherOptions=Other;
}

static void SetJarCommand(_str CurConfig,
                          JAVAJAR_OPTIONS AllJarInfo:[]
                          )
{
   _str Cmd='javamakejar '_maybe_quote_filename(AllJarInfo:[CurConfig].CompilerName)' c';
   if (AllJarInfo:[CurConfig].VerboseOutput) Cmd :+= 'v';
   Cmd :+= 'f';
   if (AllJarInfo:[CurConfig].ManifestFilename!='') Cmd :+= 'm';
   if (AllJarInfo:[CurConfig].NoCompression) Cmd :+= '0';
   lastParam := "%{*}";
   Cmd :+= ' '_maybe_quote_filename(AllJarInfo:[CurConfig].ArchiveFilename)' '_maybe_quote_filename(AllJarInfo:[CurConfig].ManifestFilename)' 'lastParam;
   int j;
   for (j=0;j<AllJarInfo:[CurConfig].AdditionalClassFiles._length();++j) {
      _str Cur=AllJarInfo:[CurConfig].AdditionalClassFiles[j];
      if (_last_char(Cur)==FILESEP) {
         // !!!!Don't end path with backslash.  NT shell screws up when
         // there is a backslash before a double quote.
         Cmd :+= ' -C '_maybe_quote_filename(substr(Cur,1,length(Cur)-1))' .';
      } else {
         //Cmd=Cmd' -C . '_maybe_quote_filename(Cur);
         path := _strip_filename(Cur,'N');
         if (path!='') {
            Cmd :+= ' -C '_maybe_quote_filename(path)' '_maybe_quote_filename(_strip_filename(Cur,'P'));
         }else{
            Cmd :+= ' -C . '_maybe_quote_filename(Cur);
         }
      }
   }
   Cmd :+= ' 'OTHER_OPTIONS_MACRO;

   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_TargetNode(gProjectHandle,'make jar',CurConfig),
                              Cmd,null,AllJarInfo:[CurConfig].OtherOptions);
}


static void SetInterpreterOptions(_str CurConfig,
                                   INTERPRETER_OPTIONS AllAppInfo:[],
                                   CLASSPATH_OPTIONS AllClassPath:[])
{
   appType := "application";
   if (_ProjectGet_AppType(gProjectHandle,CurConfig):=='j2me') {
      appType='j2me';
   }

   Cmd := _maybe_quote_filename(AllAppInfo:[CurConfig].InterpreterName);

   if (AllAppInfo:[CurConfig].ClassicVM) {
      Cmd :+= ' -classic';
   }
   if (AllAppInfo:[CurConfig].VerboseOutput) {
      Cmd :+= ' -verbose';
   }
   if (AllAppInfo:[CurConfig].ShowVersion) {
      // -version only displays interpreter version and exits,
      // -showversion actually runs the program also
      Cmd :+= ' -showversion';
   }
   // Advanced Interpreter options
   if (AllAppInfo:[CurConfig].NoClassGC) {
      Cmd :+= ' -Xnoclassgc';
   }
   if (AllAppInfo:[CurConfig].IncrementalGC) {
      Cmd :+= ' -Xincgc';
   }
   if (AllAppInfo:[CurConfig].ReduceSignals) {
      Cmd :+= ' -Xrs';
   }
   if (AllAppInfo:[CurConfig].InterpretedOnly) {
      Cmd :+= ' -Xint';
   }
   if (AllAppInfo:[CurConfig].MixedMode) {
      Cmd :+= ' -Xmixed';
   }
   if (AllAppInfo:[CurConfig].InitialMemory!='') {
      Cmd :+= ' -Xms':+AllAppInfo:[CurConfig].InitialMemory;
   }
   if (AllAppInfo:[CurConfig].MaxMemory!='') {
      Cmd :+= ' -Xmx':+AllAppInfo:[CurConfig].MaxMemory;
   }
   //if (AllClassPath:[CurConfig].ClassPath!='') {
      Cmd :+= ' %cp';
   //}
   if (AllAppInfo:[CurConfig].OtherOptions!='') {
      Cmd :+= ' 'OTHER_OPTIONS_MACRO;
   }
   if (appType:!='j2me') {
      if (AllAppInfo:[CurConfig].MainClass!='') {
         Cmd :+= ' 'AllAppInfo:[CurConfig].MainClass;
      } else {
         //If the mainclass is blank, we have to put an invalid mainclass as a
         //place holder so that when we fill in the dialog we do not take the
         //first word of the arguments.
         Cmd :+= ' .';
      }
      Cmd :+= ' 'AllAppInfo:[CurConfig].Arguments;
   }

   if (AllAppInfo:[CurConfig].DeviceType!='') {
      Cmd :+= ' -Xdevice:':+AllAppInfo:[CurConfig].DeviceType;
      Cmd :+= ' -Xdescriptor:'_strip_filename(_xmlcfg_get_filename(gProjectHandle),'E')'.jad';
   }

   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_AppTypeTargetNode(gProjectHandle,'execute',appType,CurConfig),
                              Cmd,null,AllAppInfo:[CurConfig].OtherOptions);
   //(*pProjectInfo):[CurConfig].ToolInfo[EXECUTE_INDEX].apptoolHashtab:['application'].cmd=Cmd;
   //(*pProjectInfo):[CurConfig].ToolInfo[EXECUTE_INDEX].apptoolHashtab:['application'].otherOptions=AllAppInfo:[CurConfig].OtherOptions;
}

static void SetJDWPDebuggerOptions(_str CurConfig, INTERPRETER_OPTIONS AllInterpreterOptions:[])
{
   appType := "application";
   if (_ProjectGet_AppType(gProjectHandle,CurConfig):=='j2me') {
      appType='j2me';
   }

   Cmd := _maybe_quote_filename(AllInterpreterOptions:[CurConfig].InterpreterName);
   if (AllInterpreterOptions:[CurConfig].VerboseOutput) {
      Cmd :+= ' -verbose';
   }
   if (AllInterpreterOptions:[CurConfig].ShowVersion) {
      // -version only displays interpreter version and exits,
      // -showversion actually runs the program also
      Cmd :+= ' -showversion';
   }
   // Advanced Interpreter options
   if (AllInterpreterOptions:[CurConfig].NoClassGC) {
      Cmd :+= ' -Xnoclassgc';
   }
   if (AllInterpreterOptions:[CurConfig].IncrementalGC) {
      Cmd :+= ' -Xincgc';
   }
   if (AllInterpreterOptions:[CurConfig].ReduceSignals) {
      Cmd :+= ' -Xrs';
   }
   if (AllInterpreterOptions:[CurConfig].InterpretedOnly) {
      Cmd :+= ' -Xint';
   }
   if (AllInterpreterOptions:[CurConfig].MixedMode) {
      Cmd :+= ' -Xmixed';
   }
   if (AllInterpreterOptions:[CurConfig].InitialMemory!='') {
      Cmd :+= ' -Xms':+AllInterpreterOptions:[CurConfig].InitialMemory;
   }
   if (AllInterpreterOptions:[CurConfig].MaxMemory!='') {
      Cmd :+= ' -Xmx':+AllInterpreterOptions:[CurConfig].MaxMemory;
   }

   port := def_debug_vsdebugio_port;
   if (port == "") port = "8000";
   Cmd :+= ' -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,server=y';
   Cmd :+= ',suspend=y';
   Cmd :+= ',address=';
   Cmd :+= port;
   Cmd :+= ' %cp';
   Cmd :+= ' 'OTHER_OPTIONS_MACRO;

   if (appType:!='j2me') {
      if (AllInterpreterOptions:[CurConfig].MainClass!='') {
         Cmd :+= ' 'AllInterpreterOptions:[CurConfig].MainClass;
      } else {
         //If the mainclass is blank, we have to put an invalid mainclass as a
         //place holder so that when we fill in the dialog we do not take the
         //first word of the arguments.
         Cmd :+= ' .';
      }
      Cmd :+= ' 'AllInterpreterOptions:[CurConfig].Arguments;
   }
   if (AllInterpreterOptions:[CurConfig].DeviceType!='') {
      Cmd :+= ' -Xdevice:':+AllInterpreterOptions:[CurConfig].DeviceType;
      Cmd :+= ' -Xdescriptor:'_strip_filename(_xmlcfg_get_filename(gProjectHandle),'E')'.jad';
   }
   _ProjectSet_TargetCmdLine(gProjectHandle,
                             _ProjectGet_AppTypeTargetNode(gProjectHandle,'debug',appType,CurConfig),
                             Cmd, null,
                             AllInterpreterOptions:[CurConfig].OtherOptions);
}

static void SetAppletOptions(_str CurConfig,APPLETVIEWER_OPTIONS AllAppletInfo:[], 
                             CLASSPATH_OPTIONS AllClassPath:[])
{
   _str Cmd=AllAppletInfo:[CurConfig].AppletViewerName;
   if (AllAppletInfo:[CurConfig].OtherOptions:!='') {
      Cmd :+= ' 'OTHER_OPTIONS_MACRO;
   } else if(AllClassPath:[CurConfig].ClassPath && AllClassPath:[CurConfig].ClassPath != '') {
      Cmd :+= ' -J-classpath -J'AllClassPath:[CurConfig].ClassPath;
   }
   debugCommand := Cmd' -debug';
   if (AllAppletInfo:[CurConfig].JDWPDebuggingOn) {
      debugCommand=Cmd' -J-Xdebug -J-Xnoagent -J-Xrunjdwp:transport=dt_socket,server=y,suspend=y';
      debugCommand :+= ',address='AllAppletInfo:[CurConfig].DebugPort;
   }
   if (AllAppletInfo:[CurConfig].Tempfile) {
      Cmd :+= ' %h';
      debugCommand :+= ' %h';
   }else{
      Cmd :+= ' 'AllAppletInfo:[CurConfig].URL;
      debugCommand :+= ' 'AllAppletInfo:[CurConfig].URL;
   }
   //(*pProjectInfo):[CurConfig].ToolInfo[APPLET_INDEX].apptoolHashtab:['applet'].cmd=Cmd;
   //(*pProjectInfo):[CurConfig].ToolInfo[APPLET_INDEX].apptoolHashtab:['applet'].appletClass=AllAppletInfo:[CurConfig].AppletClass;
   //(*pProjectInfo):[CurConfig].ToolInfo[APPLET_INDEX].apptoolHashtab:['applet'].otherOptions=AllAppletInfo:[CurConfig].OtherOptions;


   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_AppTypeTargetNode(gProjectHandle,'execute','applet',CurConfig),
                              Cmd,null,AllAppletInfo:[CurConfig].OtherOptions);
   _ProjectSet_TargetAppletClass(gProjectHandle,
                                  _ProjectGet_AppTypeTargetNode(gProjectHandle,'execute','applet',CurConfig),
                                  AllAppletInfo:[CurConfig].AppletClass);


   _ProjectSet_TargetCmdLine(gProjectHandle,
                              _ProjectGet_AppTypeTargetNode(gProjectHandle,'debug','applet',CurConfig),
                              debugCommand,null,AllAppletInfo:[CurConfig].OtherOptions);
   _ProjectSet_TargetAppletClass(gProjectHandle,
                                  _ProjectGet_AppTypeTargetNode(gProjectHandle,'debug','applet',CurConfig),
                                  AllAppletInfo:[CurConfig].AppletClass);

   //(*pProjectInfo):[CurConfig].ToolInfo[DEBUG_INDEX].apptoolHashtab:['applet'].cmd=debugCommand;
   //(*pProjectInfo):[CurConfig].ToolInfo[DEBUG_INDEX].apptoolHashtab:['applet'].appletClass=AllAppletInfo:[CurConfig].AppletClass;
   //(*pProjectInfo):[CurConfig].ToolInfo[DEBUG_INDEX].apptoolHashtab:['applet'].otherOptions=AllAppletInfo:[CurConfig].OtherOptions;
}

static void SaveCheckBoxOptionsAll(_str ConfigName)
{
   if (ConfigName=='') return;

   JAVAC_OPTIONS AllJavacOpts:[];
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   CLASSPATH_OPTIONS AllClassPath:[];
   JAVAJAR_OPTIONS AllJarInfo:[];
   INTERPRETER_OPTIONS AllAppInfo:[];
   APPLETVIEWER_OPTIONS AllAppletInfo:[];

   haveInterpreterTab := ctlss_main_tab.sstTabExists(INTERPRETER_TAB_CAPTION);
   haveAppletviewerTab := ctlss_main_tab.sstTabExists(APPLETVIEWER_TAB_CAPTION);
   haveDebuggerTab := haveInterpreterTab;

   AllJavacOpts=JAVAC_INFO();
   AllJavaDocOpts=JAVADOC_INFO();
   AllClassPath=CLASS_PATH_INFO();
   AllJarInfo=JAR_INFO();
   if (haveInterpreterTab) AllAppInfo=JAVAC_APP_INFO();
   if (haveAppletviewerTab) AllAppletInfo=JAVAC_APPLETVIEWER_INFO();

   SaveCheckBoxOptionsCompiler(ConfigName,AllJavacOpts);

   SaveCheckBoxOptionsJavaDoc(ConfigName,AllJavaDocOpts);

   SaveCheckBoxOptionsJar(ConfigName,AllJarInfo);

   def_antmake_use_classpath = ctlantmake_use_classpath.p_value;
   _config_modify_flags(CFGMODIFY_DEFVAR);

   if (haveInterpreterTab) SaveCheckBoxOptionsInterpreter(ConfigName,AllAppInfo);

   if (haveAppletviewerTab) SaveCheckBoxOptionsAppletviewer(ConfigName,AllAppletInfo);

   JAVAC_INFO(AllJavacOpts);
   JAVADOC_INFO(AllJavaDocOpts);
   CLASS_PATH_INFO(AllClassPath);
   JAR_INFO(AllJarInfo);
   if (haveInterpreterTab) JAVAC_APP_INFO(AllAppInfo);
   if (haveAppletviewerTab) JAVAC_APPLETVIEWER_INFO(AllAppletInfo);
}

static void SaveCheckBoxOptionsAppletviewer(_str ConfigName,APPLETVIEWER_OPTIONS (&AllAppletInfo):[])
{
   if (ConfigName==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletInfo._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         if (ctlappletusejdwp.p_value!=2) {
            AllAppletInfo:[i].JDWPDebuggingOn=ctlappletusejdwp.p_value!=0;
         }
      }
   }else{
      AllAppletInfo:[ConfigName].JDWPDebuggingOn=ctlappletusejdwp.p_value!=0;
   }
}

static void SaveCheckBoxOptionsCompiler(_str ConfigName,JAVAC_OPTIONS (&AllJavacOpts):[])
{
   if (ConfigName==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         if (ctljavac_optimize.p_value!=2) {
            AllJavacOpts:[i].OptimizeOutput=ctljavac_optimize.p_value!=0;
         }
         if (ctljavac_no_warnings.p_value!=2) {
            AllJavacOpts:[i].NoWarnings=ctljavac_no_warnings.p_value!=0;
         }
         if (ctljavac_verbose.p_value!=2) {
            AllJavacOpts:[i].Verbose=ctljavac_verbose.p_value!=0;
         }
         if (ctljavac_notify_deprecated.p_value!=2) {
            AllJavacOpts:[i].Deprecation=ctljavac_notify_deprecated.p_value!=0;
         }
         if (ctljavac_debug.p_value!=2) {
            AllJavacOpts:[i].GenerateDebug=ctljavac_debug.p_value!=0;
         }
      }
   }else{
      AllJavacOpts:[ConfigName].OptimizeOutput=ctljavac_optimize.p_value!=0;
      AllJavacOpts:[ConfigName].NoWarnings=ctljavac_no_warnings.p_value!=0;
      AllJavacOpts:[ConfigName].Verbose=ctljavac_verbose.p_value!=0;
      AllJavacOpts:[ConfigName].Deprecation=ctljavac_notify_deprecated.p_value!=0;
      AllJavacOpts:[ConfigName].GenerateDebug=ctljavac_debug.p_value!=0;
   }
}

static void SaveCheckBoxOptionsJavaDoc(_str ConfigName,JAVADOC_OPTIONS (&AllJavaDocOpts):[])
{
   if (ConfigName==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavaDocOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;

         if (ctljavadoc_version.p_value!=2) {
            AllJavaDocOpts:[i].Version=ctljavadoc_version.p_value!=0;
         }
         if (ctljavadoc_author.p_value!=2) {
            AllJavaDocOpts:[i].Author=ctljavadoc_author.p_value!=0;
         }
         if (ctljavadoc_deprecated.p_value!=2) {
            AllJavaDocOpts:[i].NoDeprecated=ctljavadoc_deprecated.p_value!=0;
         }
         if (ctljavadoc_hierarchy.p_value!=2) {
            AllJavaDocOpts:[i].NoClassHierarchy=ctljavadoc_hierarchy.p_value!=0;
         }
         if (ctljavadoc_index.p_value!=2) {
            AllJavaDocOpts:[i].NoGenerateIndex=ctljavadoc_index.p_value!=0;
         }
      }
   }else{
      AllJavaDocOpts:[ConfigName].Version=ctljavadoc_version.p_value!=0;
      AllJavaDocOpts:[ConfigName].Author=ctljavadoc_author.p_value!=0;
      AllJavaDocOpts:[ConfigName].NoDeprecated=ctljavadoc_deprecated.p_value!=0;
      AllJavaDocOpts:[ConfigName].NoClassHierarchy=ctljavadoc_hierarchy.p_value!=0;
      AllJavaDocOpts:[ConfigName].NoGenerateIndex=ctljavadoc_index.p_value!=0;
   }
}

static void SaveCheckBoxOptionsJar(_str ConfigName,JAVAJAR_OPTIONS (&AllJarInfo):[])
{
   if (ConfigName==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarInfo._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;

         if (ctljar_nocompression.p_value!=2) {
            AllJarInfo:[i].NoCompression=ctljar_nocompression.p_value!=0;
         }
         if (ctljar_verbose.p_value!=2) {
            AllJarInfo:[i].VerboseOutput=ctljar_verbose.p_value!=0;
         }
      }
   }else{
      AllJarInfo:[ConfigName].NoCompression=ctljar_nocompression.p_value!=0;
      AllJarInfo:[ConfigName].VerboseOutput=ctljar_verbose.p_value!=0;
   }
}

static void SaveCheckBoxOptionsInterpreter(_str ConfigName,INTERPRETER_OPTIONS (&AllAppInfo):[])
{
   if (ConfigName==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppInfo._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;

         if (ctlint_verbose.p_value!=2) {
            AllAppInfo:[i].VerboseOutput=ctlint_verbose.p_value!=0;
         }
         if (ctlint_version.p_value!=2) {
            AllAppInfo:[i].ShowVersion=ctlint_version.p_value!=0;
         }
         if (ctlint_classic.p_value!=2) {
            AllAppInfo:[i].ClassicVM=ctlint_classic.p_value!=0;
         }
         if (ctlint_noclassgc.p_value!=2) {
            AllAppInfo:[i].NoClassGC=ctlint_noclassgc.p_value!=0;
         }
         if (ctlint_incgc.p_value!=2) {
            AllAppInfo:[i].IncrementalGC=ctlint_incgc.p_value!=0;
         }
         if (ctlint_rs.p_value!=2) {
            AllAppInfo:[i].ReduceSignals=ctlint_rs.p_value!=0;
         }
         if (ctlint_int.p_value!=2) {
            AllAppInfo:[i].InterpretedOnly=ctlint_int.p_value!=0;
         }
         if (ctlint_mixed.p_value!=2) {
            AllAppInfo:[i].MixedMode=ctlint_mixed.p_value!=0;
         }
      }
   }else{
      AllAppInfo:[ConfigName].VerboseOutput=ctlint_verbose.p_value!=0;
      AllAppInfo:[ConfigName].ShowVersion=ctlint_version.p_value!=0;
      AllAppInfo:[ConfigName].ClassicVM=ctlint_classic.p_value!=0;
      AllAppInfo:[ConfigName].NoClassGC=ctlint_noclassgc.p_value!=0;
      AllAppInfo:[ConfigName].IncrementalGC=ctlint_incgc.p_value!=0;
      AllAppInfo:[ConfigName].ReduceSignals=ctlint_rs.p_value!=0;
      AllAppInfo:[ConfigName].InterpretedOnly=ctlint_int.p_value!=0;
      AllAppInfo:[ConfigName].MixedMode=ctlint_mixed.p_value!=0;
   }
}

void ctljavac_compiler_name.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   text := p_text;
   if (text=='') text='javac';
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].CompilerName=text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].CompilerName=text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctljavac_output_directory.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].OutputDirectory=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].OutputDirectory=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctlclass_path.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].ClassPath=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].ClassPath=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctljavac_source_compliance_level.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].SourceComplianceLevel=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].SourceComplianceLevel=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctljavac_target_compliance_level.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].TargetComplianceLevel=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].TargetComplianceLevel=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctlbootclasspath.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].BootClasspath=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].BootClasspath=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}
void ctljavac_other_options.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAC_OPTIONS AllJavacOpts:[];
   AllJavacOpts=JAVAC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavacOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavacOpts:[i].OtherOptions=p_text;
      }
   }else{
      AllJavacOpts:[ctlCurConfig.p_text].OtherOptions=p_text;
   }

   JAVAC_INFO(AllJavacOpts);
}

void ctljavadoc_appname.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   AllJavaDocOpts=JAVADOC_INFO();

   text := p_text;
   if (text=='') text='javadoc';
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavaDocOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavaDocOpts:[i].CompilerName=text;
      }
   }else{
      AllJavaDocOpts:[ctlCurConfig.p_text].CompilerName=text;
   }

   JAVADOC_INFO(AllJavaDocOpts);
}

void ctljavadoc_output_directory.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   AllJavaDocOpts=JAVADOC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavaDocOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavaDocOpts:[i].OutputDirectory=p_text;
      }
   }else{
      AllJavaDocOpts:[ctlCurConfig.p_text].OutputDirectory=p_text;
   }

   JAVADOC_INFO(AllJavaDocOpts);
}

void ctljavadoc_other_options.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   AllJavaDocOpts=JAVADOC_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJavaDocOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJavaDocOpts:[i].OtherOptions=p_text;
      }
   }else{
      AllJavaDocOpts:[ctlCurConfig.p_text].OtherOptions=p_text;
   }

   JAVADOC_INFO(AllJavaDocOpts);
}

void ctljar_archive_filename.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAJAR_OPTIONS AllJarOpts:[];
   AllJarOpts=JAR_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJarOpts:[i].ArchiveFilename=p_text;
      }
   }else{
      AllJarOpts:[ctlCurConfig.p_text].ArchiveFilename=p_text;
   }

   JAR_INFO(AllJarOpts);
}

void ctljar_manifest_filename.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAJAR_OPTIONS AllJarOpts:[];
   AllJarOpts=JAR_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJarOpts:[i].ManifestFilename=p_text;
      }
   }else{
      AllJarOpts:[ctlCurConfig.p_text].ManifestFilename=p_text;
   }

   JAR_INFO(AllJarOpts);
}

void ctljar_appname.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAJAR_OPTIONS AllJarOpts:[];
   AllJarOpts=JAR_INFO();

   text := p_text;
   if (text=='') text='jar';
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJarOpts:[i].CompilerName=text;
      }
   }else{
      AllJarOpts:[ctlCurConfig.p_text].CompilerName=text;
   }

   JAR_INFO(AllJarOpts);
}

void ctljar_other.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   JAVAJAR_OPTIONS AllJarOpts:[];
   AllJarOpts=JAR_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllJarOpts:[i].OtherOptions=p_text;
      }
   }else{
      AllJarOpts:[ctlCurConfig.p_text].OtherOptions=p_text;
   }

   JAR_INFO(AllJarOpts);
}

static _RelativeToProject2(_str filename)
{
   if (gIsProjectTemplate) {
      return(filename);
   }
   return(_RelativeToProject(filename,JAVAC_PROJECT_NAME()));
}
void ctljar_add_file.lbutton_up()
{
   typeless result=_OpenDialog('-modal',
                      'Add Class File', '*.class',
                      "Class files (*.class),All Files ("ALLFILES_RE")",
                      OFN_FILEMUSTEXIST,
                      'class', // Default extensions
                      '',      // Initial filename
                      '',                    // Initial directory
                      '',             // Retrieve name
                      '' // Help item
                      );
   if (result=='') return;
   filename := strip(result,'B','"');
   wid := p_window_id;
   p_window_id=_control ctljar_additional_file_list;
   _lbadd_item(_RelativeToProject2(filename));
   _lbsort('-F'_fpos_case);
   UpdateAdditionalFilesFromListBox();
   p_window_id=wid;
}

void ctljar_add_path.lbutton_up()
{
   _str path = _ChooseDirDialog();
   if( path=='' ) {
      return;
   }

   wid := p_window_id;
   p_window_id=ctljar_additional_file_list;
   save_pos(auto p);
   top();
   int status=search('^?'_escape_re_chars(path)'$','@rh'_fpos_case);
   if (!status) {
      restore_pos(p);
      return;
   }
   path=_RelativeToProject2(path);
   if (path=='') {
      path='.':+FILESEP;
   }
   _lbadd_item(path);
   _lbsort('-f'_fpos_case);
   //_lbselect_line();
   p_window_id=wid;
   UpdateAdditionalFilesFromListBox();
}

void ctljar_remove.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctljar_additional_file_list;
   bool ff;
   for (ff=true;;ff=false) {
      typeless status=_lbfind_selected(ff);
      if (status) break;
      _lbdelete_item();_lbup();
   }
   UpdateAdditionalFilesFromListBox();
   p_window_id=wid;
}

void ctlCurConfig.on_change(int reason)
{
   if (!p_active_form.p_visible && reason==CHANGE_OTHER) {
      // We get 2 on_change events when before the dialog is visible.  One
      // happens when the textbox gets filled in(reason==CHANGE_OTHER), and the
      // other one we call ourselves.
      //
      // Since the one we call is later on(CHANGE_CLINE). Skip the first one
      return;
   }
   JAVAC_CHANGING_CONFIGURATION(1);

   // Order is important here:
   // SaveCheckBoxOptionsAll saves all of the check box options on the dialog.
   // (All other controls have on_change events that handle that, so their
   //  data is saved already).
   //
   // Next, we call ReplaceTabControl, which deletes the tab control, and
   // reloads it from the template.  It saves and restores all the p_user values
   // when it does this.
   //
   // Finally, we set all of the check box styles and start filling the dialog
   // in.

   SaveCheckBoxOptionsAll(JAVAC_LAST_CONFIG());

   ReplaceTabControl();

   EnableExecuteTabs();

   style := PSCH_AUTO2STATE;
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      style=PSCH_AUTO3STATEB;
   }
   p_active_form._set_all_check_box_styles(style);

   JAVAC_OPTIONS AllJavacOpts:[];
   JAVADOC_OPTIONS AllJavaDocOpts:[];
   CLASSPATH_OPTIONS AllClassPath:[];
   JAVAJAR_OPTIONS AllJarInfo:[];
   INTERPRETER_OPTIONS AllAppInfo:[];
   APPLETVIEWER_OPTIONS AllAppletInfo:[];

   AllJavacOpts=JAVAC_INFO();
   AllJavaDocOpts=JAVADOC_INFO();
   AllClassPath=CLASS_PATH_INFO();
   AllJarInfo=JAR_INFO();
   haveInterpreterTab := ctlss_main_tab.sstTabExists(INTERPRETER_TAB_CAPTION);
   haveAppletviewerTab := ctlss_main_tab.sstTabExists(APPLETVIEWER_TAB_CAPTION);
   haveDebuggerTab := haveInterpreterTab;
   haveJ2METab := ctlss_main_tab.sstTabExists(J2ME_TAB_CAPTION);
   haveGWTTab := ctlss_main_tab.sstTabExists(GWT_TAB_CAPTION);
   haveAndroidTab := ctlss_main_tab.sstTabExists(ANDROID_TAB_CAPTION);

   AllAppInfo=JAVAC_APP_INFO();
   AllAppletInfo=JAVAC_APPLETVIEWER_INFO();

   if (AllJavacOpts._varformat()!=VF_HASHTAB) {
      return;
   }

   JAVAC_OPTIONS CurrentJavaOpts=null;
   JAVADOC_OPTIONS CurrentJavaDocOpts=null;
   CLASSPATH_OPTIONS CurrentClassPath=null;
   JAVAJAR_OPTIONS CurrentJarOpts=null;
   INTERPRETER_OPTIONS CurrentInterpreterOpts=null;
   APPLETVIEWER_OPTIONS CurrentAppletviewerOpts=null;

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      CurrentJavaOpts=GetAllJavacOpts(AllJavacOpts);
      CurrentJavaDocOpts=GetAllJavaDocOpts(AllJavaDocOpts);
      CurrentClassPath=GetAllClassPath(AllClassPath);
      CurrentJarOpts=GetAllJarOpts(AllJarInfo);
      CurrentInterpreterOpts=GetAllInterpreterOpts(AllAppInfo);
      CurrentAppletviewerOpts=GetAllAppletviewerOpts(AllAppletInfo);
   }else{
      CurrentJavaOpts=AllJavacOpts:[ctlCurConfig.p_text];
      CurrentJavaDocOpts=AllJavaDocOpts:[ctlCurConfig.p_text];
      CurrentClassPath=AllClassPath:[ctlCurConfig.p_text];
      CurrentJarOpts=AllJarInfo:[ctlCurConfig.p_text];
      CurrentInterpreterOpts=AllAppInfo:[ctlCurConfig.p_text];
      CurrentAppletviewerOpts=AllAppletInfo:[ctlCurConfig.p_text];
   }

   SetClassPath(CurrentClassPath);
   SetJavacValues(CurrentJavaOpts);
   SetJavaDocValues(CurrentJavaDocOpts);
   SetJavaJarValues(CurrentJarOpts);
   if (VF_IS_STRUCT(CurrentInterpreterOpts)) {
      //This makes this more friendly with 6.0 beta project files
      //
      //Check to be sure that the tab exists first
      if (haveInterpreterTab) SetInterpreterValues(CurrentInterpreterOpts);
   }
   if (VF_IS_STRUCT(CurrentAppletviewerOpts)) {
      //This makes this more friendly with 6.0 beta project files
      //
      //Check to be sure that the tab exists first
      if (haveAppletviewerTab) SetAppletValues(CurrentAppletviewerOpts);
   }
   if (haveJ2METab) {
      SetJ2MEValues(CurrentJavaOpts,CurrentInterpreterOpts,CurrentJarOpts);
      fillInPhoneTypes();
   }
   if (haveGWTTab) {
      // read/set the values here
      SetGWTValues();
   }
   if (haveAndroidTab) {
      SetAndroidValues();
   }
   JAVAC_LAST_CONFIG(p_text);
   JAVAC_CHANGING_CONFIGURATION(0);

   if (_haveRealTimeErrors()) {
      JavaLiveErrors_SetupTab();
      JavaLiveErrors_SetGUIValuesFromDefVars();
   }
}

/**
 * Deletes and replaces the tab control.  This is so that the
 * unneeded controls can be deleted.
 *
 * Has to save and restore all p_user variables.
 */
static void ReplaceTabControl()
{
   typeless tempJAVAC_INFO=JAVAC_INFO();
   typeless tempJAVADOC_INFO=JAVADOC_INFO();
   typeless tempJAR_INFO=JAR_INFO();
   typeless tempCLASS_PATH_INFO=CLASS_PATH_INFO();
   typeless tempAPP_INFO=JAVAC_APP_INFO();
   typeless tempAPPLETVIEWER_INFO=JAVAC_APPLETVIEWER_INFO();
   typeless tempDEBUGGER_INFO=JAVAC_DEBUGGER_INFO;

   typeless tempLAST_CONFIG=JAVAC_LAST_CONFIG();
   typeless tempPROJECT_NAME=JAVAC_PROJECT_NAME();

   typeless tempJ2ME_OPTIONS=J2ME_OPTIONS();
   typeless tempGWT_OPTIONS=GWT_OPTIONS();
   typeless tempANDROID_OPTIONS=ANDROID_OPTIONS();

   int activeTab=ctlss_main_tab.p_ActiveTab;
   ctlss_main_tab._delete_window();
   int index=find_index('_java_options_form',oi2type(OI_FORM));
   int firstchild,child;
   if (index) {
      firstchild=child=index.p_child;
      for (;;) {
         if (child.p_name=='ctlss_main_tab') break;
         child=child.p_next;
         if (child==firstchild) break;
      }
      if (child.p_name=='ctlss_main_tab') {
         int tabid=_load_template(child,p_active_form,'H');
         if (tabid) {
            tabid.p_x=JAVAC_TAB_CONTROL_XPOS;
            tabid.p_y=JAVAC_TAB_CONTROL_YPOS;
            tabid.p_visible=true;
         }
      }
   }

   JAVAC_INFO(tempJAVAC_INFO);
   JAVADOC_INFO(tempJAVADOC_INFO);
   JAR_INFO(tempJAR_INFO);
   CLASS_PATH_INFO(tempCLASS_PATH_INFO);
   JAVAC_APP_INFO(tempAPP_INFO);
   JAVAC_APPLETVIEWER_INFO(tempAPPLETVIEWER_INFO);
   JAVAC_DEBUGGER_INFO=tempDEBUGGER_INFO;

   JAVAC_LAST_CONFIG(tempLAST_CONFIG);
   JAVAC_PROJECT_NAME(tempPROJECT_NAME);

   J2ME_OPTIONS(tempJ2ME_OPTIONS);
   GWT_OPTIONS(tempGWT_OPTIONS);
   ANDROID_OPTIONS(tempANDROID_OPTIONS);

   ctlss_main_tab.p_ActiveTab=activeTab;

   // all the tab controls were "restarted," so we need to do our alignment again
   _java_options_form_initial_alignment();

   // call restore handler to resize the tab to its previous size
   p_active_form.call_event(1, true, p_active_form, ON_RESIZE, "");
}

//These three could really be one function, but I kept one per tab just
//in case they ever needed to do something individual
void ctljavac_optimize.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (p_value==2) {
      p_value=0;
   }
}

void ctljavadoc_version.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (p_value==2) {
      p_value=0;
   }
}

void ctljar_nocompression.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (p_value==2) {
      p_value=0;
   }
}

void ctlusendk.lbutton_up()
{
   p_style=PSCH_AUTO2STATE;
   if (p_value==2) {
      p_value=0;
   }
   if (p_value == 0) {
      ctlandroid_ndk_loc.p_text = '';
   }
}

static void SetClassPath(CLASSPATH_OPTIONS Classpath)
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _lbclear();
   cur := "";
   _str Path=Classpath.ClassPath;
   for (;;) {
      parse Path with cur (PARSE_PATHSEP_RE),'r' Path;
      if (cur=='') break;
      _lbadd_item(cur);
   }
   _lbtop();
   if (!p_Noflines) {
      p_window_id=wid;
      return;
   }
   p_window_id=wid;
}

static void SetJavacValues(JAVAC_OPTIONS CurrentJavacOpts)
{
   ctljavac_optimize.p_value=(int)CurrentJavacOpts.OptimizeOutput;
   ctljavac_no_warnings.p_value=(int)CurrentJavacOpts.NoWarnings;
   ctljavac_verbose.p_value=(int)CurrentJavacOpts.Verbose;
   ctljavac_notify_deprecated.p_value=(int)CurrentJavacOpts.Deprecation;
   ctljavac_debug.p_value=(int)CurrentJavacOpts.GenerateDebug;
   ctljavac_compiler_name.p_text=CurrentJavacOpts.CompilerName;
   ctljavac_output_directory.p_text=CurrentJavacOpts.OutputDirectory;
   ctljavac_source_compliance_level.p_text=CurrentJavacOpts.SourceComplianceLevel;
   ctljavac_target_compliance_level.p_text=CurrentJavacOpts.TargetComplianceLevel;
   ctljavac_other_options.p_text=CurrentJavacOpts.OtherOptions;

   if (ctljavac_source_compliance_level.p_text == '') {
      ctljavac_source_compliance_level.p_text='13';
   }

   if (ctljavac_target_compliance_level.p_text == '') {
      ctljavac_target_compliance_level.p_text='13';
   }

   if (CurrentJavacOpts.FileStr!='' && CurrentJavacOpts.FileStr != null) {
      //If this is '', then we are in "ALLCONFIGS", and the configs
      //do not match.  Don't want to append anything.
      if (substr(CurrentJavacOpts.FileStr,1,1)!='"') {
         CurrentJavacOpts.FileStr='"'CurrentJavacOpts.FileStr;
      }
      if (_last_char(CurrentJavacOpts.FileStr)!='"') {
         CurrentJavacOpts.FileStr=CurrentJavacOpts.FileStr'"';
      }
   }
}

static void SetJavaDocValues(JAVADOC_OPTIONS CurrentJavaDocOpts)
{
   ctljavadoc_version.p_value=(int)CurrentJavaDocOpts.Version;
   ctljavadoc_author.p_value=(int)CurrentJavaDocOpts.Author;
   ctljavadoc_deprecated.p_value=(int)CurrentJavaDocOpts.NoDeprecated;
   ctljavadoc_hierarchy.p_value=(int)CurrentJavaDocOpts.NoClassHierarchy;
   ctljavadoc_index.p_value=(int)CurrentJavaDocOpts.NoGenerateIndex;
   ctljavadoc_appname.p_text=CurrentJavaDocOpts.CompilerName;
   ctljavadoc_output_directory.p_text=CurrentJavaDocOpts.OutputDirectory;
   ctljavadoc_other_options.p_text=CurrentJavaDocOpts.OtherOptions;
}

static void SetInterpreterValues(INTERPRETER_OPTIONS InterpreterOpts)
{
   ctlint_main.p_text=InterpreterOpts.MainClass;
   ctlint_verbose.p_value=(int)InterpreterOpts.VerboseOutput;
   ctlint_version.p_value=(int)InterpreterOpts.ShowVersion;
   ctlint_other.p_text=InterpreterOpts.OtherOptions;
   ctlint_args.p_text=InterpreterOpts.Arguments;
   ctlint_interpreter.p_text=InterpreterOpts.InterpreterName;
   ctlint_classic.p_value=(int)InterpreterOpts.ClassicVM;

   ctlint_noclassgc.p_value=(int)InterpreterOpts.NoClassGC;
   ctlint_incgc.p_value=(int)InterpreterOpts.IncrementalGC;
   ctlint_rs.p_value=(int)InterpreterOpts.ReduceSignals;
   ctlint_int.p_value=(int)InterpreterOpts.InterpretedOnly;
   ctlint_mixed.p_value=(int)InterpreterOpts.MixedMode;
   ctlint_inisize.p_text=InterpreterOpts.InitialMemory;
   ctlint_maxsize.p_text=InterpreterOpts.MaxMemory;
}

static void SetAppletValues(APPLETVIEWER_OPTIONS AppletOpts)
{
   if (AppletOpts.Tempfile==null) {
      ctlapplet_other_url.p_value=0;
      ctlapplet_tempfile.p_value=0;
      ctlapplet_other_filename.p_text='';
      ctlapplet_other_filename.p_enabled=true;
      ctlapplet_applet_class.p_enabled=false;
   }else if (AppletOpts.Tempfile) {
      ctlapplet_tempfile.p_value=1;
      ctlapplet_other_filename.p_enabled=false;
      ctlapplet_applet_class.p_enabled=true;
      ctlapplet_applet_class.p_text=AppletOpts.AppletClass;
   }else{
      ctlapplet_other_url.p_value=1;
      ctlapplet_other_filename.p_enabled=true;
      ctlapplet_applet_class.p_enabled=false;
      ctlapplet_other_filename.p_text=AppletOpts.URL;
   }

   ctlapplet_other_options.p_text=AppletOpts.OtherOptions;
   ctlapplet_viewername.p_text=AppletOpts.AppletViewerName;

   ctlappletusejdwp.p_value=AppletOpts.JDWPDebuggingOn? 1:0;
   ctlappletdebugport.p_text=AppletOpts.DebugPort;
   ctlappletdebugport.p_enabled=AppletOpts.JDWPDebuggingOn;
}

static void SetJavaJarValues(JAVAJAR_OPTIONS CurrentJarOpts)
{
   ctljar_nocompression.p_value=(int)CurrentJarOpts.NoCompression;
   ctljar_verbose.p_value=(int)CurrentJarOpts.VerboseOutput;
   ctljar_archive_filename.p_text=CurrentJarOpts.ArchiveFilename;
   ctljar_manifest_filename.p_text=CurrentJarOpts.ManifestFilename;
   ctljar_other.p_text=CurrentJarOpts.OtherOptions;
   ctljar_appname.p_text=CurrentJarOpts.CompilerName;

   wid := p_window_id;
   p_window_id=ctljar_additional_file_list;
   _lbclear();
   int i;
   for (i=0;i<CurrentJarOpts.AdditionalClassFiles._length();++i) {
      _lbadd_item(CurrentJarOpts.AdditionalClassFiles[i]);
   }
   p_window_id=wid;
}

static bool WriteGWTValues(gwt_options gOptions, CLASSPATH_OPTIONS (&AllClassPath):[])
{
   // validate dialog input
   if (!_gwt_isValidGwtLoc(gOptions.gwtLoc)) {
      return false;
   }
   if (!_gwt_isValidAppEngineLoc(gOptions.appEngineLoc)) {
      return false;
   }
   if (gOptions.appVersion != '' && (!isinteger(gOptions.appVersion) || gOptions.appVersion <= 0)) {
      _message_box('Application version must be a positive integer.');
      return false;
   }
   if (!is_valid_gwt_app_id(gOptions.appID)) {
      _message_box('Application ID must be between 6 and 30 characters long, and can only ':+
                   'contain lowercase letters, numbers, and hyphens.');
      return false;
   }
   _maybe_append_filesep(gOptions.gwtLoc);
   i := 0;
   for (i=0;i<gConfigList._length();++i) {
      // update or create the deploy command for each config based on the new app engine location
      _maybe_append_filesep(gOptions.appEngineLoc);
      deployScript := _maybe_quote_filename(gOptions.appEngineLoc:+'bin':+FILESEP:+'appcfg');
      if (_isUnix()) {
         deployScript :+= '.sh';
      }
      int deployNode = _ProjectGet_TargetNode(gProjectHandle,"DeployScript",gConfigList[i]);
      if (deployNode < 0 && gOptions.appEngineLoc != '') {
         _ProjectAdd_Target(gProjectHandle,'DeployScript',deployScript,'',gConfigList[i],"Never","");
         _ProjectSave(gProjectHandle);
      } else if (deployNode >= 0) {
         _ProjectSet_TargetCmdLine(gProjectHandle, deployNode, deployScript);
         _ProjectSave(gProjectHandle);
      }
   }
   _str project_dir =_ProjectGet_WorkingDir(gProjectHandle);
   project_dir=absolute(project_dir,_file_path(_project_name));
   _maybe_append_filesep(project_dir);
   // update the gwt.sdk property in the build.xml file
   if (gOptions.gwtLoc != '') {
      int handle = _xmlcfg_open(_maybe_quote_filename(project_dir :+ 'build.xml'),auto status,
                                 VSXMLCFG_OPEN_REFCOUNT);
      if(handle >= 0 && status >= 0) {
         int sdkNode = _xmlcfg_find_simple(handle, "/project/property[@name='gwt.sdk']");
         if (sdkNode >= 0) {
            _xmlcfg_set_attribute(handle, sdkNode, "location", gOptions.gwtLoc);
            _xmlcfg_save(handle,2,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
         }
         _xmlcfg_close(handle);
      }
   }
   // update the appengine-web.xml file to reflect the new properties from the dialog
   if (gOptions.appID != '') {
      appengineXmlFile :=  project_dir :+ 'war' :+ FILESEP :+ 'WEB-INF' :+ FILESEP :+ 'appengine-web.xml';
      appengineXmlFile = _maybe_quote_filename(appengineXmlFile);
      // if an appengine-web.xml file does not exist, create one
      if (!file_exists(appengineXmlFile)) {
         int version = isinteger(gOptions.appVersion) ? (int)gOptions.appVersion : 1;
         _gwt_createAppEngineXMLFile(appengineXmlFile, gOptions.appID, version); 
      } else {
         int handle = _xmlcfg_open(_maybe_quote_filename(appengineXmlFile),auto status,VSXMLCFG_OPEN_ADD_PCDATA);
         if(handle >= 0 && !status) {
            int appNode = _xmlcfg_find_simple(handle, "/appengine-web-app/application");
            if (appNode >= 0) {
               int dataNode = _xmlcfg_get_first_child(handle,appNode,VSXMLCFG_NODE_PCDATA);
               if (dataNode >= 0) {
                  _xmlcfg_set_value(handle, dataNode, gOptions.appID);
                  _xmlcfg_save(handle,2,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
               }
            }
            int versionNode = _xmlcfg_find_simple(handle, "/appengine-web-app/version");
            if (versionNode >= 0 && gOptions.appVersion != '') {
               int dataNode = _xmlcfg_get_first_child(handle,versionNode,VSXMLCFG_NODE_PCDATA);
               if (dataNode >= 0) {
                  _xmlcfg_set_value(handle, dataNode, gOptions.appVersion);
                  _xmlcfg_save(handle,2,VSXMLCFG_SAVE_ATTRS_ON_ONE_LINE|VSXMLCFG_SAVE_PCDATA_INLINE);
               }
            }
            _xmlcfg_close(handle);
         }
      }
   }
   return true;
}

// Given a list of targets from _android_getTargetsFromSDK, tries to 
// normalize 'target' to be of the form "id: N or SOME TARGET NAME".
static void normalize_target_details(_str (&targets)[], _str& target )
{
   int i;

   for (i = 0; i < targets._length(); i++) {
      if (pos(target, targets[i]) != 0) {
         target = targets[i];
      }
   }
}

static bool WriteAndroidValues(android_options aOptions, CLASSPATH_OPTIONS (&AllClassPath):[])
{
   _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg, false);
   if (aOptions.androidLoc == sdk && aOptions.ndkLoc == ndk && pos(trg, aOptions.target) > 0) {
      return true;
   }
   if (aOptions.androidLoc != "" && pos('"',aOptions.androidLoc)) {
      aOptions.androidLoc = stranslate(aOptions.androidLoc,'','"');
   }
   if (aOptions.ndkLoc != "" && pos('"',aOptions.ndkLoc)) {
      aOptions.ndkLoc = stranslate(aOptions.ndkLoc,'','"');
   }
   if (!_android_isValidSdkLoc(aOptions.androidLoc)) {
      return false;
   }
   if (!_android_isValidNdkLoc(aOptions.ndkLoc)) {
      return false;
   }
   diff_target := pos(trg, aOptions.target) <= 0;
   if (aOptions.ndkLoc != ndk) {
      _str new_ndk = aOptions.ndkLoc;
      _maybe_append_filesep(new_ndk);
      _str ndk_tool_name = new_ndk == '' ? '' : 'ndk-build'; 
      _ProjectSet_PreBuildCommandsList(gProjectHandle,new_ndk:+ndk_tool_name,'Debug');
      _ProjectSet_PreBuildCommandsList(gProjectHandle,new_ndk:+ndk_tool_name,'Release');
      _ProjectSave(gProjectHandle);
   }
   if (aOptions.androidLoc != sdk || diff_target) {
      _str new_trg = diff_target ? aOptions.target : trg;
      if (_android_getTargetsFromSDK(aOptions.androidLoc, auto all_targets) == 0) {
         normalize_target_details(all_targets, new_trg);
      }
      _android_getNumberFromTarget(new_trg);
      if (isinteger(new_trg)) {
         _str projectDir = _file_path(_project_name);
         _maybe_append_filesep(projectDir);
         projectDir = _maybe_quote_filename(projectDir);
         _maybe_append_filesep(aOptions.androidLoc);
         uCmd :=  aOptions.androidLoc'tools'FILESEP'android';
         if (_isWindows()) {
            uCmd :+= '.bat';
         }
         uCmd = _maybe_quote_filename(uCmd) :+ ' update project --target 'new_trg' --path 'projectDir;
         _str res = _PipeShellResult(uCmd, auto status,'ACH');
         _SccDisplayOutput(uCmd, true);
         _SccDisplayOutput(res);
      }
   }
   return true;
}

static void SetGWTValues()
{
   gwt_options gOptions=GWT_OPTIONS();
   //open up the build.xml file if we haven't already
   if (gOptions == null || gOptions.gwtLoc=='') {
      gOptions.appEngineLoc = '';
      gOptions.gwtLoc= '';
      gOptions.appID= '';
      gOptions.appVersion = '';
      _str project_dir =_ProjectGet_WorkingDir(gProjectHandle);
      project_dir=absolute(project_dir,_file_path(_project_name));
      _maybe_append_filesep(project_dir);
      int handle = _xmlcfg_open(_maybe_quote_filename(project_dir :+ 'build.xml'),auto status,
                                 VSXMLCFG_OPEN_REFCOUNT);
      if(handle < 0 || status < 0) {
         // return or keep going?
         return;
      }
      int sdkNode = _xmlcfg_find_simple(handle, "/project/property[@name='gwt.sdk']");
      if (sdkNode >= 0) {
         _str val = _xmlcfg_get_attribute(handle, sdkNode, "location");
         gOptions.gwtLoc = val;
      }
      _xmlcfg_close(handle);
      appengineXmlFile :=  project_dir :+ 'war' :+ FILESEP :+ 'WEB-INF' :+ FILESEP :+ 'appengine-web.xml';
      handle = _xmlcfg_open(_maybe_quote_filename(appengineXmlFile),status,VSXMLCFG_OPEN_ADD_PCDATA);
      if(handle >= 0 && !status) {
         int appNode = _xmlcfg_find_simple(handle, "/appengine-web-app/application");
         if (appNode >= 0) {
            int dataNode = _xmlcfg_get_first_child(handle,appNode,VSXMLCFG_NODE_PCDATA);
            if (dataNode >= 0) {
               _str val = _xmlcfg_get_value(handle, dataNode);
               gOptions.appID = val;
            }
         } 
         int versionNode = _xmlcfg_find_simple(handle, "/appengine-web-app/version");
         if (versionNode >= 0) {
            int dataNode = _xmlcfg_get_first_child(handle,versionNode,VSXMLCFG_NODE_PCDATA);
            if (dataNode >= 0) {
               _str val = _xmlcfg_get_value(handle, dataNode);
               gOptions.appVersion = val;
            }
         } 
         _xmlcfg_close(handle);
      }
      int deployNode = _ProjectGet_TargetNode(gProjectHandle,'DeployScript');
      if (deployNode >= 0) {
         _str deployScript = _ProjectGet_TargetCmdLine(gProjectHandle,deployNode);
         index := pos('bin':+FILESEP:+'appcfg',deployScript);
         if (index > 0) {
            gOptions.appEngineLoc = substr(deployScript,1,index-1);
            if (_isUnix()) {
               gOptions.appEngineLoc = substr(gOptions.appEngineLoc,4);
            }
            if (_charAt(gOptions.appEngineLoc,1) == '"') {
               gOptions.appEngineLoc = substr(gOptions.appEngineLoc,2);
            }
         }
      }
      GWT_OPTIONS(gOptions);
   }

   gwtLocBox.p_text=gOptions.gwtLoc;
   appLocBox.p_text=gOptions.appEngineLoc;
   appIdBox.p_text=gOptions.appID;
   appVersionBox.p_text=gOptions.appVersion;
}

static void SetAndroidValues()
{
   android_options aOptions=ANDROID_OPTIONS();
   if (aOptions == null || aOptions.androidLoc == '' || aOptions.target == '') {
      _android_getRunArgs(auto sdk, auto apk, auto pkg, auto act, auto ndk, auto trg, false);
      aOptions.androidLoc=sdk;
      aOptions.ndkLoc=ndk;
      aOptions.target=trg;
      ANDROID_OPTIONS(aOptions);
   }

   ctlandroid_sdk_loc.p_text=strip(aOptions.androidLoc,'B','"');
   ctlandroid_ndk_loc.p_text=aOptions.ndkLoc;
   ctlusendk.p_value=(strip(aOptions.ndkLoc) != '') ? 1 : 0; 
   int status = _android_getTargetsFromSDK(aOptions.androidLoc, auto targets);
   if (!status && aOptions.target != '') {
      int i;
      sel_index := -1;
      for (i = 0; i < targets._length(); i++) {
         temp_trg := strip(targets[i]);
         index := pos(aOptions.target,temp_trg);
         if (index > 0) {
            sel_index = i;
         }
         ctltargetchooser._lbadd_item(temp_trg);
      }
      if (sel_index > -1) {
         ctltargetchooser._lbfind_and_select_item(strip(targets[sel_index]));
      }
   }
}

static void SetJ2MEValues(JAVAC_OPTIONS CurrentJavaOpts,
                          INTERPRETER_OPTIONS CurrentInterpreterOpts,
                          JAVAJAR_OPTIONS CurrentJarOpts)
{
   ctlj2me_phone.p_text=CurrentInterpreterOpts.DeviceType;
   ctlj2me_bootclasspath.p_text=CurrentJavaOpts.BootClasspath;

   j2me_options jOptions=J2ME_OPTIONS();
   //open up the manifest file if we haven't already
   if (jOptions.name=='') {
      int temp_wid;
      int orig_wid;
      _str project_dir =_ProjectGet_WorkingDir(_ProjectHandle());
      project_dir=absolute(project_dir,_file_path(_project_name));
      int status=_open_temp_view(project_dir :+ CurrentJarOpts.ManifestFilename,temp_wid,orig_wid);
      if (!status) {
         top();
         up();
         while (!down()) {
            get_line(auto line);

            _str key;
            _str value;

            parse line with key ':' value;
            key=strip(key);
            value=strip(value);

            switch (key) {
            case 'MIDlet-1':
               parse value with jOptions.name ',' jOptions.icon ',' jOptions.classname;
               jOptions.name=strip(jOptions.name);
               jOptions.icon=strip(jOptions.icon);
               jOptions.classname=strip(jOptions.classname);
               break;
            case 'MIDlet-Vendor':
               jOptions.vendor=value;
               break;
            case 'MIDlet-Description':
               jOptions.description=value;
               break;
            case 'MIDlet-Version':
               jOptions.version=value;
               break;
            }
         }
         p_window_id=orig_wid;
         _delete_temp_view(temp_wid);

         J2ME_OPTIONS(jOptions);
      } else {
        _message_box("Error: Unable to open manifest file: " project_dir :+ CurrentJarOpts.ManifestFilename);
        return;
      }
   }

   ctlj2me_appName.p_text=jOptions.name;
   ctlj2me_description.p_text=jOptions.description;
   ctlj2me_version.p_text=jOptions.version;
   ctlj2me_vendor.p_text=jOptions.vendor;
   ctlj2me_class.p_text=jOptions.classname;
   ctlj2me_icon.p_text=jOptions.icon;
}

static JAVAC_OPTIONS GetAllJavacOpts(JAVAC_OPTIONS AllJavacOpts:[])
{
   // TODO:  There is a much easier way to do this now
   /* 
   AllJavacOpts._deleteel(PROJ_ALL_CONFIGS);
   return _get_matching_struct_values(AllJavacOpts);
   */
    
   JAVAC_OPTIONS AllJavacInfo=null;

   _str SectionsList[]=null;
   SectionsList=GetHashTabIndexes(AllJavacOpts);
   RemoveItemFromList(SectionsList,PROJ_ALL_CONFIGS);

   if (SectionsList._length()==1) {
      return(AllJavacOpts:[SectionsList[0]]);
   }

   AllJavacInfo.OptimizeOutput= GetMatchingValue(AllJavacOpts, 0,2);
   AllJavacInfo.NoWarnings=     GetMatchingValue(AllJavacOpts, 1,2);
   AllJavacInfo.Verbose=        GetMatchingValue(AllJavacOpts, 2,2);
   AllJavacInfo.Deprecation=    GetMatchingValue(AllJavacOpts, 3,2);
   AllJavacInfo.GenerateDebug=  GetMatchingValue(AllJavacOpts, 4,2);
   AllJavacInfo.CompilerName=   GetMatchingValue(AllJavacOpts, 5,'');
   AllJavacInfo.OutputDirectory=GetMatchingValue(AllJavacOpts, 6,'');
   AllJavacInfo.ClassPath=      GetMatchingValue(AllJavacOpts, 7,'');
   AllJavacInfo.OtherOptions=   GetMatchingValue(AllJavacOpts, 8,'');
   AllJavacInfo.FileStr=        GetMatchingValue(AllJavacOpts, 9,'');
   AllJavacInfo.SourceComplianceLevel = GetMatchingValue(AllJavacOpts, 10,'');
   AllJavacInfo.TargetComplianceLevel = GetMatchingValue(AllJavacOpts, 11,'');
   AllJavacInfo.BootClasspath = GetMatchingValue(AllJavacOpts, 12,'');

   return(AllJavacInfo);
}

static JAVADOC_OPTIONS GetAllJavaDocOpts(JAVADOC_OPTIONS AllJavaDocOpts:[])
{
   // TODO:  There is a much easier way to do this now:
   /* 
   AllJavaDocOpts._deleteel(PROJ_ALL_CONFIGS);
   return _get_matching_struct_values(AllJavaDocOpts);
   */
    
   JAVADOC_OPTIONS AllJavaDocInfo=null;

   _str SectionsList[]=null;
   SectionsList=GetHashTabIndexes(AllJavaDocOpts);
   RemoveItemFromList(SectionsList,PROJ_ALL_CONFIGS);

   if (SectionsList._length()==1) {
      return(AllJavaDocOpts:[SectionsList[0]]);
   }

   AllJavaDocInfo.Version=         GetMatchingValue((typeless)AllJavaDocOpts, 0,2);
   AllJavaDocInfo.Author=          GetMatchingValue((typeless)AllJavaDocOpts, 1,2);
   AllJavaDocInfo.NoDeprecated=    GetMatchingValue((typeless)AllJavaDocOpts, 2,2);
   AllJavaDocInfo.NoClassHierarchy=GetMatchingValue((typeless)AllJavaDocOpts, 3,2);
   AllJavaDocInfo.NoGenerateIndex= GetMatchingValue((typeless)AllJavaDocOpts, 4,2);
   AllJavaDocInfo.CompilerName=    GetMatchingValue((typeless)AllJavaDocOpts, 5,'');
   AllJavaDocInfo.OutputDirectory= GetMatchingValue((typeless)AllJavaDocOpts, 6,'');
   AllJavaDocInfo.OtherOptions=    GetMatchingValue((typeless)AllJavaDocOpts, 7,'');
   //AllJavaDocInfo.FileStr=         GetMatchingValue(AllJavaDocOpts, 8,'');
   return(AllJavaDocInfo);
}
static APPLETVIEWER_OPTIONS GetAllAppletviewerOpts(APPLETVIEWER_OPTIONS AllAppletviewerOpts:[])
{
   // TODO:  There is a much easier way to do this now:
   /* 
   AllAppletviewerOpts._deleteel(PROJ_ALL_CONFIGS);
   typeless specialCaseDefaults:[];
   specialCaseDefaults:["Tempfile"] = null;
   specialCaseDefaults:["JDWPDebuggingOn"] = true;
   specialCaseDefaults:["DebugPort"] = "8000";
   return _get_matching_struct_values(AllAppletviewerOpts, specialCaseDefaults);
   */ 

   _str SectionsList[]=null;
   SectionsList=GetHashTabIndexes(AllAppletviewerOpts);

   APPLETVIEWER_OPTIONS AllAppletviewerInfo=null;
   RemoveItemFromList(SectionsList,PROJ_ALL_CONFIGS);

   AllAppletviewerInfo.OtherOptions=    GetMatchingValue((typeless)AllAppletviewerOpts, 0,'');
   AllAppletviewerInfo.URL=             GetMatchingValue((typeless)AllAppletviewerOpts, 1,'');
   AllAppletviewerInfo.Tempfile=        GetMatchingValue((typeless)AllAppletviewerOpts, 2,null);
   AllAppletviewerInfo.AppletViewerName=GetMatchingValue((typeless)AllAppletviewerOpts, 3,'');
   AllAppletviewerInfo.AppletClass     =GetMatchingValue((typeless)AllAppletviewerOpts, 4,'');
   AllAppletviewerInfo.JDWPDebuggingOn =GetMatchingValue((typeless)AllAppletviewerOpts, 5,true);
   AllAppletviewerInfo.DebugPort       =GetMatchingValue((typeless)AllAppletviewerOpts, 6,'8000');
   return(AllAppletviewerInfo);
}
static INTERPRETER_OPTIONS GetAllInterpreterOpts(INTERPRETER_OPTIONS AllAppOpts:[])
{
   // TODO:  There is a much easier way to do this now:
   /* 
   AllInterpreterOpts._deleteel(PROJ_ALL_CONFIGS);
   return _get_matching_struct_values(AllInterpreterOpts);
   */ 

   _str SectionsList[]=null;
   SectionsList=GetHashTabIndexes(AllAppOpts);

   INTERPRETER_OPTIONS AllAppInfo=null;
   RemoveItemFromList(SectionsList,PROJ_ALL_CONFIGS);

   if (SectionsList._length()==1) {
      return(AllAppOpts:[SectionsList[0]]);
   }

   AllAppInfo.MainClass=      GetMatchingValue((typeless)AllAppOpts, 0,'');
   AllAppInfo.Arguments=      GetMatchingValue((typeless)AllAppOpts, 1,'');
   AllAppInfo.VerboseOutput=  GetMatchingValue((typeless)AllAppOpts, 2,2);
   AllAppInfo.ShowVersion=    GetMatchingValue((typeless)AllAppOpts, 3,2);
   AllAppInfo.OtherOptions=   GetMatchingValue((typeless)AllAppOpts, 4,'');
   AllAppInfo.InterpreterName=GetMatchingValue((typeless)AllAppOpts, 5,'');

   AllAppInfo.ClassicVM=      GetMatchingValue((typeless)AllAppOpts, 6,2);
   AllAppInfo.NoClassGC=      GetMatchingValue((typeless)AllAppOpts, 7,2);
   AllAppInfo.IncrementalGC=  GetMatchingValue((typeless)AllAppOpts, 8,2);
   AllAppInfo.ReduceSignals=  GetMatchingValue((typeless)AllAppOpts, 9,2);
   AllAppInfo.InterpretedOnly=GetMatchingValue((typeless)AllAppOpts,10,2);
   AllAppInfo.MixedMode=      GetMatchingValue((typeless)AllAppOpts,11,2);
   AllAppInfo.InitialMemory=  GetMatchingValue((typeless)AllAppOpts,12,'');
   AllAppInfo.MaxMemory=      GetMatchingValue((typeless)AllAppOpts,13,'');
   AllAppInfo.DeviceType=     GetMatchingValue((typeless)AllAppOpts,14,'');

   return(AllAppInfo);
}

static JAVAJAR_OPTIONS GetAllJarOpts(JAVAJAR_OPTIONS AllJarOpts:[])
{
   // TODO:  There is a much easier way to do most of this now:
   /* 
   AllJarOpts._deleteel(PROJ_ALL_CONFIGS);
   JAVAJAR_OPTIONS AllJarInfo;
   AllJarInfo = _get_matching_struct_values(AllJarOpts);
   */ 

   _str SectionsList[]=null;
   SectionsList=GetHashTabIndexes(AllJarOpts);

   JAVAJAR_OPTIONS AllJarInfo=null;
   RemoveItemFromList(SectionsList,PROJ_ALL_CONFIGS);

   if (SectionsList._length()==1) {
      return(AllJarOpts:[SectionsList[0]]);
   }

   AllJarInfo.NoCompression=   GetMatchingValue((typeless)AllJarOpts, 0,2);
   AllJarInfo.VerboseOutput=   GetMatchingValue((typeless)AllJarOpts, 1,2);
   AllJarInfo.OtherOptions=    GetMatchingValue((typeless)AllJarOpts, 2,'');
   AllJarInfo.ArchiveFilename= GetMatchingValue((typeless)AllJarOpts, 3,'');
   AllJarInfo.CompilerName=    GetMatchingValue((typeless)AllJarOpts, 5,'');
   AllJarInfo.ManifestFilename=GetMatchingValue((typeless)AllJarOpts, 6,'');

   _str Paths[]=null;
   first := "";
   AllJarOpts._nextel(first);
   if (!first._isempty()) {
      int i;
      for (i=0;i<AllJarOpts:[first].AdditionalClassFiles._length();++i) {
         _str cur=AllJarOpts:[first].AdditionalClassFiles[i];
         found := false;
         typeless j;
         for (j._makeempty();;) {
            AllJarOpts._nextel(j);
            if (j._isempty()) break;
            if (j==first) continue;
            int z;
            for (z=0;z<AllJarOpts:[j].AdditionalClassFiles._length();++z) {
               if (_file_eq(AllJarOpts:[j].AdditionalClassFiles[z],cur)) {
                  found=true;break;
               }
            }
         }
         if (found) {
            Paths[Paths._length()]=cur;
         }
      }
   }
   AllJarInfo.AdditionalClassFiles=Paths;
   return(AllJarInfo);
}

static CLASSPATH_OPTIONS GetAllClassPath(CLASSPATH_OPTIONS AllClassPath:[])
{
   SectionsList := _get_hashtab_keys(AllClassPath);
   ArrayRemove(SectionsList,PROJ_ALL_CONFIGS);

   if (SectionsList._length()==1) {
      return(AllClassPath:[SectionsList[0]]);
   }

   CLASSPATH_OPTIONS ClassPathIntersection;
   //ClassPathIntersection.AppendClassPathEnvVar=false;
   ClassPathIntersection.ClassPath='';

   _str PathList=AllClassPath:[SectionsList[0]].ClassPath;

   //The CLASSPATH in the project file may have a leading PATHSEP
   PathList=strip(PathList,'L',PATHSEP);

   // Use a hash table to store results
   // 1/4/07 - Changing hashtable to string in order to preserver order of jars/directories
   typeless i;
   Cur1 := "";
//   _str ClassPathIntersectionTab:[];
   ClassPathIntersectionString := "";
   for (;;) {
      parse PathList with Cur1 (PARSE_PATHSEP_RE),'r' PathList;
      if (Cur1=='') break;
      if (_last_char(Cur1)!=FILESEP && substr(Cur1,1,2)!='%(' &&
          (!_file_eq(_get_extension(Cur1),'jar') &&
           !_file_eq(_get_extension(Cur1),'zip')) ) {
         Cur1 :+= FILESEP;
      }
      for (i=1;i<SectionsList._length();++i) {
         //The CLASSPATH in the project file may have a leading PATHSEP
         Cur2 := strip(AllClassPath:[SectionsList[i]].ClassPath,'L',PATHSEP);
         Cur2=PutFILESEPOnAllPaths(Cur2);
         /*if (last_char(Cur2)!=FILESEP
             && substr(Cur2,1,2)!='%(') Cur2=Cur2:+FILESEP;*/
         if (pos(PATHSEP:+Cur1:+PATHSEP,
                 PATHSEP:+Cur2:+PATHSEP,
                 1,
                 _fpos_case) ) {
//            ClassPathIntersectionTab:[Cur1]=Cur1;
            if (substr(Cur1,1,1) == ';') {
               Cur1 = substr(Cur1,2);
            }
            ClassPathIntersectionString :+= Cur1 :+ PATHSEP;
         }
      }
   }
/*   for (i=null;;) {
      ClassPathIntersectionTab._nextel(i);
      if (i==null) break;
      if (substr(i,1,1)==';') {
         ClassPathIntersection.ClassPath=substr(ClassPathIntersection.ClassPath,2);
      }
      ClassPathIntersection.ClassPath=ClassPathIntersection.ClassPath:+PATHSEP:+i;
   }
   ClassPathIntersection.ClassPath=substr(ClassPathIntersection.ClassPath,2);*/
   ClassPathIntersection.ClassPath=ClassPathIntersectionString;

   return(ClassPathIntersection);
}

static _str PutFILESEPOnAllPaths(_str Path)
{
   Cur := "";
   NewPath := "";
   for (;;) {
      parse Path with Cur (PARSE_PATHSEP_RE),'r' Path;
      if (Cur=='') break;
      if (_last_char(Cur)!=FILESEP && substr(Cur,1,2)!='%(' &&
          (!_file_eq(_get_extension(Cur),'jar') &&
           !_file_eq(_get_extension(Cur),'zip')) ) {
         Cur :+= FILESEP;
      }
      NewPath :+= PATHSEP:+Cur;
   }
   return(substr(NewPath,2));
}

static typeless GetMatchingValue(JAVAC_OPTIONS AllJavaDocOpts:[],
                                int index,typeless DefaultValue)
{
   _str LastValue=DefaultValue;
   LastIndex := "";
   _str Indexes[]=GetHashTabIndexes(AllJavaDocOpts);
   if (Indexes._length()==1) {
      typeless tmp1=AllJavaDocOpts:[Indexes[0]];
      return(tmp1[index]);
   }
   typeless i;
   for (i._makeempty();;) {
      AllJavaDocOpts._nextel(i);
      if (i._isempty()) break;
      if (LastIndex!='') {
         typeless tmp1=AllJavaDocOpts:[LastIndex];
         typeless tmp2=AllJavaDocOpts:[i];
         if (index!=-1) {
            if (tmp1[index]!=tmp2[index]) {
               return(DefaultValue);
            }
            LastValue=tmp2[index];
         }else{
            if (tmp1!=tmp2) {
               return(DefaultValue);
            }
            LastValue=tmp2;
         }
      }
      LastIndex=i;
   }
   return(LastValue);
}

static void RemoveItemFromList(_str (&List)[],_str StringToRemove)
{
   typeless i;
   for (i=0;i<List._length();++i) {
      if (List[i]==StringToRemove) {
         List._deleteel(i);--i;
      }
   }
}

typeless GetHashTabIndexes(typeless Hashtab:[])
{
   if (Hashtab._varformat()!=VF_HASHTAB) {
      return(null);
   }
   _str IndexNames[]=null;
   typeless i;
   for (i._makeempty();;) {
      Hashtab._nextel(i);
      if (i._isempty()) break;
      IndexNames[IndexNames._length()]=i;
   }
   return(IndexNames);
}

static void GetClasspath(CLASSPATH_OPTIONS (&Classpath):[])
{
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str ConfigName=gConfigList[i];

      _str CurPath=_ProjectGet_ClassPathList(gProjectHandle,ConfigName);
      if (CurPath._isempty()) {
         CurPath='';
      }
      Classpath:[ConfigName].ClassPath=CurPath;
   }
}

static void GetJavacOptions(_str CommandNameKey,
                            typeless (&AllConfigInfo):[])
{
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str ConfigName=gConfigList[i];

      int TargetNode=_ProjectGet_TargetNode(gProjectHandle,CommandNameKey,ConfigName);
      _str cmd=_ProjectGet_TargetCmdLine(gProjectHandle,
                                          TargetNode
                                          );
      _str otherOptions=_ProjectGet_TargetOtherOptions(gProjectHandle,TargetNode);
      switch (lowcase(CommandNameKey)) {
      case 'compile' :
         GetJavacOptionsFromString(cmd,otherOptions,AllConfigInfo:[ConfigName],ConfigName);
         break;
      case 'javadoc all':
         GetJavaDocOptionsFromString(cmd,otherOptions,AllConfigInfo:[ConfigName]);
         break;
      case 'make jar' :
         GetJarOptionsFromString(cmd,otherOptions,AllConfigInfo:[ConfigName]);
         break;
      }
   }
}
static void GetJavacOptionsAppType(_str CommandNameKey,
                                  typeless (&AllConfigInfo):[],
                                   _str AppType)
{
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str ConfigName=gConfigList[i];

      typeless TargetNode=_ProjectGet_AppTypeTargetNode(gProjectHandle,CommandNameKey,AppType,ConfigName);
      //_message_box('TargetNode='TargetNode' n='_xmlcfg_get_name(gProjectHandle,TargetNode));

      _str cmd=_ProjectGet_TargetCmdLine(gProjectHandle,TargetNode);
      _str otherOptions=_ProjectGet_TargetOtherOptions(gProjectHandle,TargetNode);
      _str appletClass=_ProjectGet_TargetAppletClass(gProjectHandle,TargetNode);
      //_message_box('cmd='cmd' otherOptions='otherOptions' c='appletClass);
      //This is an apptool item, so we have to treat it a bit differntly
      if (strieq(AppType,'applet')) {
         GetAppletOptionsFromString(cmd,otherOptions,appletClass,AllConfigInfo:[ConfigName]);
      } else if (strieq(CommandNameKey,'execute')) {
         GetInterpreterOptionsFromString(cmd,otherOptions,AllConfigInfo:[ConfigName]);
      }
   }
}

_str _GetJavaMainFromCommandLine(_str cmd)
{
   INTERPRETER_OPTIONS Options;
   GetInterpreterOptionsFromString(cmd,'',Options);
   return(Options.MainClass);
}
_str _GetJavaArgumentsFromCommandLine(_str cmd)
{
   INTERPRETER_OPTIONS Options;
   GetInterpreterOptionsFromString(cmd,'',Options);
   return(Options.Arguments);
}
static void GetInterpreterOptionsFromString(_str cmd,_str OtherOptions,INTERPRETER_OPTIONS &Options)
{
   Options.Arguments='';
   Options.InterpreterName='';
   Options.MainClass='';
   Options.OtherOptions='';
   Options.ShowVersion=false;
   Options.VerboseOutput=false;

   Options.ClassicVM=false;
   Options.NoClassGC=false;
   Options.IncrementalGC=false;
   Options.ReduceSignals=false;
   Options.InterpretedOnly=false;
   Options.MixedMode=false;
   Options.InitialMemory='';
   Options.MaxMemory='';
   Options.DeviceType='';

   cur := "";
   cur=parse_file(cmd,false);
   if (cur!=OTHER_OPTIONS_MACRO && cur!='%cp') {
      //This can happen if everything but the other field or classpath is blank
      Options.InterpreterName=cur;
   }

   Options.OtherOptions=OtherOptions;

   for (;;) {
      cur=parse_file(cmd);
      if (cur=='') break;
      ch := substr(cur,1,1);
      //%cp is always there, so we just skip it, and put it back in.
      if (cur=='%cp' || cur==OTHER_OPTIONS_MACRO) continue;
      if (ch!='-') break;

      if (cur=='-verbose') {
         Options.VerboseOutput=true;
      }else if (cur=='-version') {
         Options.ShowVersion=true;
      }else if (cur=='-classic' || cur=='-tclassic') {
         Options.ClassicVM=true;
      }else if (cur=='-showversion') {
         Options.ShowVersion=true;
      }else if (cur=='-Xnoclassgc') {
         Options.NoClassGC=true;
      }else if (cur=='-Xincgc') {
         Options.IncrementalGC=true;
      }else if (cur=='-Xrs') {
         Options.ReduceSignals=true;
      }else if (cur=='-Xint') {
         Options.InterpretedOnly=true;
      }else if (cur=='-Xmixed') {
         Options.MixedMode=true;
      }else if (substr(cur,1,4)=='-Xms') {
         Options.InitialMemory=substr(cur,5);
      }else if (substr(cur,1,4)=='-Xmx') {
         Options.MaxMemory=substr(cur,5);
      }else if (substr(cur,1,8)=='-Xdevice') {
         Options.DeviceType=substr(cur,10);
      }else if (cur=='-classpath') {
         cur=parse_file(cmd);
      }else if (cur=='-launch') {
      }else if (cur=='-Xdebug') {
      }else if (substr(cur,1,10)=='-Xrunjdwp:') {
      }
   }
   if (cur!=OTHER_OPTIONS_MACRO && cur!='.') {
      //First thing after the options has to be the main class name
      //If it is a ".", that is just a place holder so that we can leave
      //the textbox blank.  Otherwise, we pick up the first word of the
      //argument.
      Options.MainClass=cur;
   }
   if (cmd!=OTHER_OPTIONS_MACRO) {
      //Whatever is left is arguments
      Options.Arguments=cmd;
   }
}

static void GetAppletOptionsFromString(_str cmd,_str OtherOptions,_str AppletClass,
                                       APPLETVIEWER_OPTIONS &Options)
{
   Options.AppletViewerName='';
   Options.OtherOptions=OtherOptions;
   Options.URL='';
   Options.Tempfile=false;
   Options.AppletClass=AppletClass;

   Options.JDWPDebuggingOn=true;
   Options.DebugPort=8000;

   cur := "";
   cur=parse_file(cmd,false);
   if (cur!=OTHER_OPTIONS_MACRO) {
      //This can happen if everything but the other field is blank
      Options.AppletViewerName=cur;
   }

   for (;;) {
      cur=parse_file(cmd,false);
      if (cur=='') break;
      //This can happen if everything but the other field is blank
      if (cur=='%h') {
         //%h is for a temporary VSE generated html file.
         Options.Tempfile=true;
         break;
      } else if (cur=='-debug') {
         Options.JDWPDebuggingOn=false;
      } else if (cur=='-J-Xnoagent') {
         // whatever
      } else if (cur=='-J-Xdebug') {
         Options.JDWPDebuggingOn=true;
      } else if (substr(cur,1,12)=='-J-Xrunjdwp:') {
         Options.JDWPDebuggingOn=true;
         cur=substr(cur,11);
         while (cur!='') {
            name := "";
            typeless value="";
            parse cur with name '=' value ',' cur;
            if (name=='address' && isinteger(value)) {
               Options.DebugPort=value;
            }
         }

      } else if (cur=='-J-classpath') {
         // skip past classpath option if specified, it can be recreated
         parse_file(cmd,false);

      } else if (substr(cur,1,2)=='-J') {
         // some Java option that should go in other options
         // these will be lost

      } else if (cur==OTHER_OPTIONS_MACRO) {
         break;

      } else {
         Options.URL=cur;
         break;
      }
   }
}
_str _GetJavaOutputDirectoryFromCommandLine(_str cmd)
{
   JAVAC_OPTIONS Options;
   GetJavacOptionsFromString(cmd,'',Options);
   return(Options.OutputDirectory);
}

static void GetJavacOptionsFromString(_str cmd,_str OtherOptions,JAVAC_OPTIONS &Options,_str configName ="")
{
   _str Version, CommandStr=cmd;
   Options.CompilerName=parse_file(CommandStr,false);

   int p=pos('{("|)(%f|%n)?@( |$)}',CommandStr,1,'ir');
   if (p) {
      MatchLength := pos('0');
      Options.FileStr=substr(CommandStr,pos('S0'),MatchLength);
      FirstPart := "";
      if (p>1) {
         FirstPart=substr(CommandStr,1,p-1);
      }
      CommandStr=FirstPart:+substr(CommandStr,p+MatchLength+1);
   }

   Options.OptimizeOutput=false;
   Options.NoWarnings=false;
   Options.Verbose=false;
   Options.Deprecation=false;
   Options.GenerateDebug=false;
   Options.ClassPath='';
   Options.OutputDirectory='';
   Options.OtherOptions=OtherOptions;
   Options.SourceComplianceLevel='None';
   Options.TargetComplianceLevel='None';
   Options.BootClasspath='';

   for (;;) {
      _str Cur=parse_file(CommandStr);
      if (Cur=='') break;
      // Java options are case sensitive
      switch (Cur) {
      case '-O':
         Options.OptimizeOutput=true;
         break;
      case '-nowarn':
         Options.NoWarnings=true;
         break;
      case '-verbose':
         Options.Verbose=true;
         break;
      case '-deprecation':
         Options.Deprecation=true;
         break;
      case '-classpath':
         Options.ClassPath=parse_file(CommandStr,false);
         break;
      case '-bootclasspath':
         Options.BootClasspath=parse_file(CommandStr,false);
         break;
      case '-source':
         Version=parse_file(CommandStr);
         Options.SourceComplianceLevel = Version;
         break;
      case '-target':
         Version=parse_file(CommandStr);
         Options.TargetComplianceLevel = Version;
         break;
      case '-d':
         // this should never be followed by anything but %bd, but check
         // it anyway just to play it safe.  if it is anything other than
         // %bd, keep that instead
         _str outputDir = parse_file(CommandStr,false);

         // strip whitespace and quotes
         outputDir = strip(outputDir, "B", "\"");
         outputDir = strip(outputDir, "B");

         if(strieq(outputDir, "%bd")) {
            ProjectConfig configList[]=null;
            getVSEProjectConfigs(gProjectHandle,configList);
            i := 0;
            for(i = 0; i < configList._length(); i++) {
               if(configList[i].config == configName) {
                  Options.OutputDirectory = configList[i].objdir;
               }
            }
         } else {
            Options.OutputDirectory = outputDir;
         }
         break;
      case '%jbd':
         ProjectConfig configList[]=null;
         getVSEProjectConfigs(gProjectHandle,configList);
         i := 0;
         for(i = 0; i < configList._length(); i++) {
            if(configList[i].config == configName) {
               Options.OutputDirectory = configList[i].objdir;
            }
         }
         break;
      default:
         before := "";
         after := "";
         parse Cur with before ':' after;
         if (before=='-g') {
            if (after=='' || pos('vars',after)) {
               Options.GenerateDebug=true;
            }
         }
      }
   }
}

static void GetJavaDocOptionsFromString(_str cmd,_str OtherOptions,JAVADOC_OPTIONS &Options)
{
   _str CommandStr;
   parse cmd with . CommandStr;
   Options.CompilerName=parse_file(CommandStr,false);

   p := pos('%\{?*\}',CommandStr,1,'ir');
   if (p) {
      int EndFirst=p-1;
      while (EndFirst>1 && substr(CommandStr,EndFirst,1)!=' ') {
         --EndFirst;
      }
      int StartSecond=p+1;
      while (StartSecond<=length(CommandStr) && substr(CommandStr,StartSecond,1)!=' ') {
         ++StartSecond;
      }
      //Options.FileStr=substr(CommandStr,EndFirst+1,StartSecond-EndFirst);
      //Options.FileStr=strip(Options.FileStr);
      CommandStr=substr(CommandStr,1,EndFirst):+substr(CommandStr,StartSecond);
   }

   Options.Version=false;
   Options.Author=false;
   Options.NoDeprecated=false;
   Options.NoClassHierarchy=false;
   Options.NoGenerateIndex=false;
   Options.OutputDirectory='';
   Options.OtherOptions=OtherOptions;

   //Options.OtherOptions='';
   for (;;) {
      _str Cur=parse_file(CommandStr);
      if (Cur=='') break;
      // Java options are case sensitive
      switch (Cur) {
      case '-version' :
         Options.Version=true;
         break;
      case '-author' :
         Options.Author=true;
         break;
      case '-nodeprecated' :
         Options.NoDeprecated=true;
         break;
      case '-notree' :
         Options.NoClassHierarchy=true;
         break;
      case '-noindex' :
         Options.NoGenerateIndex=true;
         break;
      case '-d':
         Options.OutputDirectory=parse_file(CommandStr,false);
         break;
      case OTHER_OPTIONS_MACRO:
      case '%cp':
         continue;
      default:
         Options.OtherOptions=Options.OtherOptions' 'Cur;
      }
   }

   Options.OtherOptions=strip(Options.OtherOptions);
}

_str parse_last_file(_str &String,bool returnQuotes=true,bool support_single_quote=false)
{
   String=strip(String,'t');
   lp := 0;
   lc := _last_char(String);
   if (lc=='"' || (lc=="'" && support_single_quote) ) {
      lp=lastpos(lc,substr(String,1,length(String)-1));
      if (!lp) {
         lp=1;
      }
      word := substr(String,lp,length(String)-(lp-1));
      String=substr(String,1,lp-1);
      String=strip(String);
      if (returnQuotes) {
         return(word);
      }
      return(strip(word,'b',lc));
   }
   lp=lastpos('( |\t)',String,'','r');
   if (!lp) {
      _str temp=String;
      String='';
      return(temp);
   }
   LastFile := substr(String,lp);
   LastFile=strip(LastFile);
   String=substr(String,1,lp-1);
   String=strip(String);
   return(LastFile);
}

static void GetJarOptionsFromString(_str cmd,_str OtherOptions,JAVAJAR_OPTIONS &Options)
{
   _str CommandStr=cmd;

   Options.AdditionalClassFiles=null;
   Options.ArchiveFilename='';
   Options.NoCompression=false;
   Options.OtherOptions='';
   Options.VerboseOutput=false;
   Options.CompilerName='';
   Options.ManifestFilename='';

   p := pos('-C',cmd);
   if (p) {
      FirstHalf := substr(cmd,1,p-1);
      rest := substr(cmd,p);
      for (;;) {
         _str cur=parse_file(rest);
         if (cur!='-C') {
            if (cur!='') rest=cur' 'rest;
            break;
         }
         _str dir=parse_file(rest,false);
         // IF a file was specified
         filename := "";
         if (dir=='.') {
            filename=parse_file(rest,false);
         } else {
            //filename=dir;
            _maybe_append_filesep(filename);
            // Remove .
            _str filepart=parse_file(rest,false);
            _maybe_append_filesep(dir);
            filename=dir:+filepart;
         }
         Options.AdditionalClassFiles[Options.AdditionalClassFiles._length()]=filename;
      }
      cmd=FirstHalf:+rest;
   }

   _str FileArg=parse_last_file(cmd);

   // check to see if filearg is actually the %~other placeholder.  if
   // it is, discard %~other and try again
   filearg := "";
   if(strieq(FileArg, OTHER_OPTIONS_MACRO)) {
      filearg = parse_last_file(cmd);
   }

   //Options.ArchiveFilename=parse_last_file(cmd,false);

   //parse cmd with 'javamakejar ' Options.CompilerName options;

   ///First pull off 'javamakejar'
   _str junk=parse_file(cmd);

   //Now get the jar application name
   Options.CompilerName=parse_file(cmd,false);

   //The rest of the line is to be parsed as options
   _str options=parse_file(cmd);

   manifest_op_pos := pos('m',options);
   file_op_pos := pos('f',options);
   if (manifest_op_pos && file_op_pos) {
      //If we have both of these, the order of the arguments is important
      if (file_op_pos<manifest_op_pos) {
         Options.ManifestFilename=parse_last_file(cmd,false);
         Options.ArchiveFilename=parse_last_file(cmd,false);
      }else{
         Options.ArchiveFilename=parse_last_file(cmd,false);
         Options.ManifestFilename=parse_last_file(cmd,false);
      }
   }else if (manifest_op_pos) {
      Options.ManifestFilename=parse_last_file(cmd,false);
   }else if (file_op_pos) {
      Options.ArchiveFilename=parse_last_file(cmd,false);
   }

   PickOut('c',options);
   PickOut('f',options);
   PickOut('m',options);

   if (pos('v',options,'')) {
      Options.VerboseOutput=true;
      PickOut('v',options);
   }
   if (pos('0',options,'')) {
      Options.NoCompression=true;
      PickOut('0',options);
   }
   //if (pos('u',options,'')) {
   //   Options.UpdateExisting=true;
   //   PickOut('u',options);
   //}
   Options.OtherOptions=OtherOptions' 'options;
}

static void PickOut(_str TakeOut,_str &options)
{
   p := pos(TakeOut,options);
   if (!p) return;
   First := "";
   if (p>1) {
      First=substr(options,1,p-1);
   }
   options=First:+substr(options,p+length(TakeOut));
}

static void EnableClassPathButtons()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   if (!p_Noflines) {
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=false;
      ctlcp_up.p_enabled=false;
      ctlcp_down.p_enabled=false;
   }else if (p_line==1) {
      ctlcp_up.p_enabled=false;
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_down.p_enabled=(p_Noflines>1);
   }else if (p_line==p_Noflines) {
      ctlcp_down.p_enabled=false;
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_delete.p_enabled=true;
      ctlcp_up.p_enabled=true;
   }else{
      ctlcp_add_path.p_enabled=true;
      ctlcp_edit.p_enabled=true;
      ctlcp_up.p_enabled=true;
      ctlcp_down.p_enabled=true;
   }
   ctlcp_delete.p_enabled= p_Noflines && (ctlcp_pathlist.p_Nofselected!=0);
   ctlantmake_use_classpath.p_value = def_antmake_use_classpath;
   p_window_id=wid;
}

void ctlcp_pathlist.on_change(int reason)
{
   EnableClassPathButtons();
}

static void add_tree_dirs(_str path)
{
   add_path(path);
   filespec := _maybe_quote_filename(path:+ALLFILES_RE);
   filename := file_match('-p +d +h +s +t +x -v 'filespec,1);
   for (;;) {
      if (filename=='') {
         break;
      }
      name := _strip_filename(substr(filename,1,length(filename)-1),'p');
      if (name!='.' && name!='..') {
         add_path(filename);
      }
      filename=file_match('-p +d +h +s +t +x -v 'filespec,0);
   }
}
static void add_path(_str path,bool SelectNewLine=true)
{
   save_pos(auto p);
   _lbtop();
   typeless status=_lbsearch(path,_fpos_case);
   if (!status) {
      _lbselect_line();
      return;
   }
   restore_pos(p);
   _lbadd_item(path);
   if (SelectNewLine) {
      _lbselect_line();
   }
}
void ctlcp_add_path.lbutton_up()
{
   typeless result = _ChooseDirDialog('','','',CDN_PATH_MUST_EXIST|CDN_SHOW_RECURSIVE); 
   if( result=='' ) {
      return;
   }
   options := "";
   _str path=strip_options(result,options,true);
   path=strip(path,'B','"');
   _maybe_append_filesep(path);
   wid := p_window_id;
   _control ctlcp_pathlist;
   p_window_id=ctlcp_pathlist;
   _lbdeselect_all();
   if (options=='+r') {
      add_tree_dirs(path);
   } else {
      add_path(path);
   }
   p_window_id=wid;
   UpdateClassPathFromListBox();
   EnableClassPathButtons();
}

void ctlcp_add_jar_file.lbutton_up()
{
   typeless result=_OpenDialog('-new -modal',
        'Add Jar File',
        '',      // Initial wildcards
        'Jar files(*.jar),'def_file_types,
        OFN_FILEMUSTEXIST|OFN_ALLOWMULTISELECT,
        '*.jar',      // Default extension
        '',      // Initial filename
        ''       // Initial directory
        );
   if (result=='') {
      return;
   }
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _lbdeselect_all();
   for (;;) {
      _str cur=parse_file(result,false);
      if (cur=='') break;
      //add_path(_RelativeToProject2(cur),false);
      // For now, make user use the Edit button to make a relative jar name
      add_path(cur,false);
   }
   _lbselect_line();
   p_window_id=wid;
   EnableClassPathButtons();
   UpdateClassPathFromListBox();
}

void ctlcp_add_jar_wildcard.lbutton_up()
{
   // use the add tree dialog for this
   typeless result=show('-modal -xy _project_add_tree_or_wildcard_form',
               'Add Jar Wildcards',    // title
               '*.jar',                // filespec
               true,                   // attempt retrieval
               false,                  // use exclude filespec
               '',                     // project file name
               false,                  // show wildcard option
               false);                 // allow ant paths

   // user cancelled
   if (result== "") return;

   // _param1 - trees to add (array of paths)
   // add our new path wildcards to the listbox
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _lbdeselect_all();
   for (i := 0; i < _param6._length(); i++) {
      file:=absolute(_param6[i],_param1);
      add_path(file, false);
   }
   _lbselect_line();
   p_window_id=wid;
   EnableClassPathButtons();
   UpdateClassPathFromListBox();
}

void ctlcp_add_classpath.lbutton_up()
{
   ctlcp_pathlist._lbdeselect_all();
   ctlcp_pathlist.add_path('%(CLASSPATH)');
   EnableClassPathButtons();
   UpdateClassPathFromListBox();
}

void ctlcp_pathlist.'C-A'()
{
   _lbselect_all();
}

void ctlcp_pathlist.del()
{
   ctlcp_delete.call_event(ctlcp_delete,LBUTTON_UP);
}

void ctlcp_delete.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   save_pos(auto p);
   top();up();
   bool ff;
   for (ff=true;;ff=false) {
      typeless status=_lbfind_selected(ff);
      if (status) break;
      _lbdelete_item();_lbup();
   }
   restore_pos(p);
   _lbselect_line();
   p_window_id=wid;
   UpdateClassPathFromListBox();
   EnableClassPathButtons();
}

void ctlcp_edit.lbutton_up()
{
   _str CurText=ctlcp_pathlist._lbget_text();
   typeless result=show('-modal _textbox_form',
               'Edit Path',
               0,
               '',           //tb width
               '',           //Help item
               '',           //Buttons and captions
               'editpath',      //retrieve
               'Edit Path:'CurText);//prompts
   if (result=='') {
      return;
   }
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   if (_last_char(_param1)!=FILESEP &&
       !_file_eq(_get_extension(_param1),'jar') &&
       !_file_eq(_get_extension(_param1),'zip') &&
       substr(_param1,1,2)!='%('
      ) {
      _param1 :+= FILESEP;
   }
   if (_param1=='') {
      _lbdelete_item();
   }else{
      _lbset_item(_param1);
   }
   //_lbselect_line();
   p_window_id=wid;
   UpdateClassPathFromListBox();
}

void ctlcp_up.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _str Text=_lbget_text();

   orig_linenum := p_line;
   _lbdelete_item();

   if (p_line==orig_linenum) {
      _lbup();
   }
   _lbup();//Be careful of order since the above compares line number then does an up

   _lbadd_item(Text);
   _lbselect_line();
   p_window_id=wid;
   UpdateClassPathFromListBox();
   EnableClassPathButtons();
}

void ctlcp_down.lbutton_up()
{
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   _str Text=_lbget_text();

   _lbdelete_item();

   _lbadd_item(Text);
   _lbselect_line();
   p_window_id=wid;
   UpdateClassPathFromListBox();
   EnableClassPathButtons();
}

static void UpdateClassPathFromListBox()
{
   Path := "";
   wid := p_window_id;
   p_window_id=ctlcp_pathlist;
   save_pos(auto p);
   _lbtop();_lbup();
   while (!_lbdown()) {
      Path :+= PATHSEP:+_lbget_text();
   }
   Path=substr(Path,2);
   restore_pos(p);
   //_lbselect_line();

   CLASSPATH_OPTIONS ClassPath:[];
   ClassPath=CLASS_PATH_INFO();
   SectionsList := _get_hashtab_keys(ClassPath);

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      int i;
      for (i=0;i<SectionsList._length();++i) {
         if (SectionsList[i]==PROJ_ALL_CONFIGS) continue;
         ClassPath:[SectionsList[i]].ClassPath=Path;
      }
   }else{
      ClassPath:[ctlCurConfig.p_text].ClassPath=Path;
   }
   CLASS_PATH_INFO(ClassPath);
   p_window_id=wid;
}

static void UpdateAdditionalFilesFromListBox()
{
   wid := p_window_id;
   p_window_id=ctljar_additional_file_list;

   _str Array[]=null;
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str line=_lbget_text();
      Array[Array._length()]=line;
   }

   p_window_id=wid;

   JAVAJAR_OPTIONS AllJarInfo:[];
   AllJarInfo=JAR_INFO();
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllJarInfo._nextel(i);
         if (i._isempty()) break;
         AllJarInfo:[i].AdditionalClassFiles=Array;
      }
   }else{
      AllJarInfo:[ctlCurConfig.p_text].AdditionalClassFiles=Array;
   }
   JAR_INFO(AllJarInfo);
}


/**
 * Sets hash table item when the "Main class:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 *
 * The four of these are very, very similar,
 * but because of the looping through the configurations
 * the only way I could think of to reuse one was to
 * use pass in an index to the struct member, and I
 * don't want to do that where it is not necessary.
 */
void ctlint_main.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   text := p_text;
   if (_get_extension(text,true)=='.class') {
      text=_strip_filename(text,'E');
   }

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].MainClass=text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].MainClass=text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 * Sets hash table item when the "Other Options:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlint_other.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].OtherOptions=p_text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].OtherOptions=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 * Sets hash table item when the "Initial memory size:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlint_inisize.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].InitialMemory=p_text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].InitialMemory=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 * Sets hash table item when the "Max memory size:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlint_maxsize.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].MaxMemory=p_text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].MaxMemory=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 * Sets hash table item when the "Phone type:" combobox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlj2me_phone.on_change(int reason)
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].DeviceType=p_text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].DeviceType=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 *
 * Sets hash table item when the "Arguments:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlint_args.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].Arguments=p_text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].Arguments=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}
/**
 *
 * Sets hash table item when the "Interpreter:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlint_interpreter.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   INTERPRETER_OPTIONS AllAppOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppOpts=JAVAC_APP_INFO();

   text := p_text;

   if (text=='') text='java';
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppOpts:[i].InterpreterName=text;
      }
   }else{
      AllAppOpts:[ctlCurConfig.p_text].InterpreterName=text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APP_INFO(AllAppOpts);
}

/**
 *
 * Sets hash table item when the "Port:" textbox
 * changes.  If the current configuration is ALL_CONFIGS
 * it loops through and sets it for all configurations.
 */
void ctlappletdebugport.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();

   text := p_text;
   if (text=='') {
      text='8000';
   }
   if (!isinteger(text)) {
      return;
   }
   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppletOpts:[i].DebugPort=(int)text;
      }
   }else{
      AllAppletOpts:[ctlCurConfig.p_text].DebugPort=(int)text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}

void ctlapplet_applet_class.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppletOpts:[i].AppletClass=p_text;
      }
   }else{
      AllAppletOpts:[ctlCurConfig.p_text].AppletClass=p_text;
   }

   if(hasAppletTab()==true) {
      ctlapplet_tempfile.p_value=1;
   }
   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}

void ctlapplet_other_filename.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppletOpts:[i].URL=p_text;
      }
   }else{
      AllAppletOpts:[ctlCurConfig.p_text].URL=p_text;
   }
   ctlapplet_other_url.p_value=1;
   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}

void ctlapplet_tempfile.lbutton_up()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;

   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();
   if (ctlapplet_tempfile.p_value) {
      if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
         typeless i;
         for (i._makeempty();;) {
            AllAppletOpts._nextel(i);
            if (i._isempty()) break;
            if (i==PROJ_ALL_CONFIGS) continue;
            AllAppletOpts:[i].Tempfile=true;
         }
      }else{
         AllAppletOpts:[ctlCurConfig.p_text].Tempfile=true;
      }
      JAVAC_CHANGING_CONFIGURATION(1);
      ctlapplet_other_filename.p_text='';
      JAVAC_CHANGING_CONFIGURATION(0);
      ctlapplet_other_filename.p_enabled=false;
      ctlapplet_applet_class.p_enabled=true;
   }else if (ctlapplet_other_url.p_value) {
      ctlapplet_other_filename.p_enabled=true;
      ctlapplet_applet_class.p_enabled=false;
      if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
         typeless i;
         for (i._makeempty();;) {
            AllAppletOpts._nextel(i);
            if (i._isempty()) break;
            if (i==PROJ_ALL_CONFIGS) continue;
            AllAppletOpts:[i].URL='';
            AllAppletOpts:[i].Tempfile=false;
         }
      }else{
         AllAppletOpts:[ctlCurConfig.p_text].URL='';
         AllAppletOpts:[ctlCurConfig.p_text].Tempfile=false;
      }
   }
   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}

void ctlapplet_other_options.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppletOpts:[i].OtherOptions=p_text;
      }
   }else{
      AllAppletOpts:[ctlCurConfig.p_text].OtherOptions=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}
void ctlapplet_viewername.on_change()
{
   if (JAVAC_CHANGING_CONFIGURATION()==1) return;
   APPLETVIEWER_OPTIONS AllAppletOpts:[];
   //If this is getting changed, the tab has to exist
   AllAppletOpts=JAVAC_APPLETVIEWER_INFO();

   if (ctlCurConfig.p_text==PROJ_ALL_CONFIGS) {
      typeless i;
      for (i._makeempty();;) {
         AllAppletOpts._nextel(i);
         if (i._isempty()) break;
         if (i==PROJ_ALL_CONFIGS) continue;
         AllAppletOpts:[i].AppletViewerName=p_text;
      }
   }else{
      AllAppletOpts:[ctlCurConfig.p_text].AppletViewerName=p_text;
   }

   //If this is getting changed, the tab has to exist
   JAVAC_APPLETVIEWER_INFO(AllAppletOpts);
}

void ctlFindapp.lbutton_up()
{
   wid := p_window_id;
   initial_directory := "";
   _str program=wid.p_prev.p_text;
   if (program!='') {
      _str filename=path_search(program,'','P');
      if (filename=='') {
         int status=set_java_environment(true);
         if (!status) {
            filename=path_search(program,'','P');
         }
      }
      if (filename=='') {
         _message_box(nls('Program %s not found',program));
      } else {
         filename=absolute(filename);
         initial_directory=_strip_filename(filename,'N');
      }
   }

   typeless result=_OpenDialog(
      '-modal',
       'Choose Application',
       '',
      def_debug_exe_extensions, // File Type List
      OFN_FILEMUSTEXIST,     // Flags
      '',
      '',
      initial_directory
      );

   result=strip(result,'B','"');
   if (result=='') {
      return;
   }
   p_window_id=wid.p_prev;
   p_text= result;
   end_line();
   _set_focus();
   return;
}
static const HTML_FILE_EXT="*.htm;*.html;*.shtml;*.asp;*.jsp;*.php3;*.php;*.rhtml";
void ctlFindFileURL.lbutton_up()
{
   wid := p_window_id;
   initial_directory := _strip_filename(JAVAC_PROJECT_NAME(),'N');
   _str program=wid.p_prev.p_text;
   if (program!='') {
      if (file_exists(program)) {
         program=absolute(program);
         initial_directory=_strip_filename(program,'N');
      } else {
         _message_box(nls('File %s not found',program));
      }
   }

   _str format_list='HTML Files('HTML_FILE_EXT'), All Files('ALLFILES_RE')';
   typeless result=_OpenDialog(
      '-modal',
      'Choose HTML File',
       '',
      format_list,  // file types
      OFN_FILEMUSTEXIST,     // Flags
      HTML_FILE_EXT,      // Default extensions
      '',
      initial_directory
      );

   result=strip(result,'B','"');
   if (result=='') {
      return;
   }
   p_window_id=wid.p_prev;
   p_text= relative(result,_strip_filename(JAVAC_PROJECT_NAME(),'N'));
   end_line();
   _set_focus();
   return;
}

int def_java_live_errors_deprecation_warning = 1;
int def_java_live_errors_other_options= 0;
int def_java_live_errors_no_warnings = 0;
int def_java_live_errors_incremental_compile = 0;
int def_java_live_errors_sleep_interval = 250;
int def_java_live_errors_init_heap_size= 0;
int def_java_live_errors_max_heap_size = 0;
int def_java_live_errors_stack_size= 0;

static void JavaLiveErrors_SetupTab()
{
   // Force the style to 2 state because code in config change forces all checkboxes
   // to 3 state when changing to all configs.
   ctlliveerrors_enable_live_errors.p_style     = PSCH_AUTO2STATE;
   ctlliveerrors_deprecation_warning.p_style    = PSCH_AUTO2STATE;
   ctlliveerrors_no_warnings.p_style            = PSCH_AUTO2STATE;
   ctlliveerrors_other_options.p_style          = PSCH_AUTO2STATE;
}

static void JavaLiveErrors_ClampDefVars()
{
   // Don't allow sleep intervals less then 150 milliseconds.
   if(def_java_live_errors_sleep_interval < 150) {
      def_java_live_errors_sleep_interval = 150;
   }
}

static void JavaLiveErrors_SetGUIValuesFromDefVars()
{
   if (!_haveRealTimeErrors()) return;
   JavaLiveErrors_ClampDefVars();

   ctlliveerrors_enable_live_errors.p_value     = (def_java_live_errors_enabled && _java_live_errors_supported())? 1:0;
   ctlliveerrors_deprecation_warning.p_value    = def_java_live_errors_deprecation_warning;
   ctlliveerrors_no_warnings.p_value            = def_java_live_errors_no_warnings;
   ctlliveerrors_sleep_interval.p_text          = def_java_live_errors_sleep_interval;
   ctlliveerrors_other_options.p_value          = def_java_live_errors_other_options;

   ctlliveerrors_init_heap.p_text               = def_java_live_errors_init_heap_size == 0 ? "" :
                                                   def_java_live_errors_init_heap_size;
   ctlliveerrors_max_heap.p_text                = def_java_live_errors_max_heap_size == 0 ? "" :
                                                   def_java_live_errors_max_heap_size;
   ctlliveerrors_stack.p_text                   = def_java_live_errors_stack_size == 0 ? "" :
                                                   def_java_live_errors_stack_size;

   java_get_jdk_classpath();
   ctlliveerrors_path_to_jdk.p_text = def_java_live_errors_jdk_6_dir;
}

static int JavaLiveErrors_SetDefVarsFromGUI(bool &closeDialog)
{
   if (!_haveRealTimeErrors()) return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   JavaLiveErrors_ClampDefVars();

   def_java_live_errors_enabled                 = ctlliveerrors_enable_live_errors.p_value!=0;
   def_java_live_errors_deprecation_warning     = ctlliveerrors_deprecation_warning.p_value;
   def_java_live_errors_no_warnings             = ctlliveerrors_no_warnings.p_value;
   def_java_live_errors_other_options           = ctlliveerrors_other_options.p_value;

   if(isinteger(ctlliveerrors_sleep_interval.p_text)) {
      def_java_live_errors_sleep_interval = (int)ctlliveerrors_sleep_interval.p_text;
   }
   def_java_live_errors_jdk_6_dir             = ctlliveerrors_path_to_jdk.p_text;

   int result = JavaLiveErrors_SetOptionsFromDefVars();
   jvm_tuning_changed := false;
   typeless new_stack = ctlliveerrors_stack.p_text;
   typeless new_init_heap = ctlliveerrors_init_heap.p_text;
   typeless new_max_heap = ctlliveerrors_max_heap.p_text;
   if ((new_stack != "" && !isinteger(new_stack))||(new_init_heap != "" && !isinteger(new_init_heap))||
       (new_max_heap != "" && !isinteger(new_max_heap))) {
      _message_box("JVM settings not applied.  Values must be integers.");
      closeDialog = false;
   } else if ((isinteger(new_stack) && ((int)new_stack <= 1 || (int)new_stack >= 10000000000))||
              (isinteger(new_init_heap) && ((int)new_init_heap <= 1 || (int)new_init_heap >= 10000000000))||
              (isinteger(new_max_heap) && ((int)new_max_heap <= 1 || (int)new_max_heap >= 10000000000))){
      _message_box("JVM settings not applied.  Values must be valid integers, greater than 1.");
      closeDialog = false;
   } else {
      int stack = new_stack == "" ? 0 : (int)new_stack;
      int initheap = new_init_heap == "" ? 0 : (int)new_init_heap;
      int maxheap = new_max_heap == "" ? 0 : (int)new_max_heap;
      if (stack != def_java_live_errors_stack_size) {
         jvm_tuning_changed = true;
         def_java_live_errors_stack_size = stack;
      }
      if (initheap != def_java_live_errors_init_heap_size) {
         jvm_tuning_changed = true;
         def_java_live_errors_init_heap_size = initheap; 
      }
      if (maxheap != def_java_live_errors_max_heap_size) {
         jvm_tuning_changed = true;
         def_java_live_errors_max_heap_size = maxheap;
      }
      if (jvm_tuning_changed) {
         _message_box("JVM settings will be applied after the next restart of SlickEdit.");
      }
   }

   _config_modify_flags(CFGMODIFY_DEFVAR);
   return(result);
}

int JavaLiveErrors_SetOptionsFromDefVars(bool full_shutdown = true)
{
   if (!_haveRealTimeErrors()) {
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }

   JavaLiveErrors_ClampDefVars();

   int result = rteSetEnableDeprecationWarnings(def_java_live_errors_deprecation_warning);
   result = rteSetNoWarnings(def_java_live_errors_no_warnings);
   result = rteSetSleepInterval(def_java_live_errors_sleep_interval);
   result = rteSetIncrementalCompile(def_java_live_errors_incremental_compile);

   if(def_java_live_errors_enabled && _java_live_errors_supported()) {
      result = rteSetEnableJavaLiveErrors(def_java_live_errors_enabled);
   } else {
      rteStop();
   }
   return(result);
}

static bool hasAppletTab()
{
   // loop thru tabs to see which ones are there and which arent
   haveApplet := false;
   
   int i;
   for (i=0;i<gConfigList._length();++i) {
      _str AppType=_ProjectGet_AppType(gProjectHandle,gConfigList[i]);
      if (strieq(AppType,APPTYPE_APPLET)) {
         haveApplet=true;
      }
   }

   return haveApplet;
}

// J2ME tab
static void fillInPhoneTypes()
{
   int old_cc=JAVAC_CHANGING_CONFIGURATION();
   JAVAC_CHANGING_CONFIGURATION(1);
   ctlj2me_phone._lbclear();

   _str phone_types=def_j2me_phone_types;

   while (phone_types:!='') {
      _str cur_phone;
      parse phone_types with cur_phone ';' phone_types;

      ctlj2me_phone._lbadd_item(cur_phone);
   }

   JAVAC_CHANGING_CONFIGURATION(old_cc);
}
ctlj2me_iconBrowse.lbutton_up()
{
   _str result=_OpenDialog('-modal',
                           'Choose File',        // Dialog Box Title
                           '',                   // Initial Wild Cards
                           "Image Files (*.png;*.bmp),All Files ("ALLFILES_RE")", // File Type List
                           OFN_FILEMUSTEXIST     // Flags
                          );
   result=strip(result,'B','"');
   if (result=='') {
      return('');
   }
   ctlj2me_icon.p_text= result;
}

void ctlj2me_newphone.lbutton_up()
{
   _str promptResult = show("-modal _textbox_form",
                            "Enter the name for the new phone type",
                            0,
                            "",
                            "",
                            "",
                            "",
                            "Phone type:" "" );
   if (promptResult:!= "") {
      def_j2me_phone_types=_param1';'def_j2me_phone_types;
      _config_modify_flags(CFGMODIFY_DEFVAR);

      fillInPhoneTypes();
   }
}

static void j2me_dialog_error(_str field)
{
   _message_box('Please specify the 'field);
}

void ctlj2me_appName.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'application name');
      _set_focus();
      ctlj2me_appName.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.name=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_appName.p_sel_length = 0;
}

void ctlj2me_description.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'application description');
      _set_focus();
      ctlj2me_description.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.description=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_description.p_sel_length = 0;
}

void ctlj2me_version.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'version');
      _set_focus();
      ctlj2me_version.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.version=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_version.p_sel_length = 0;
}

void ctlj2me_vendor.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'vendor');
      _set_focus();
      ctlj2me_vendor.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.vendor=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_vendor.p_sel_length = 0;
}

void ctlj2me_class.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'application class');
      _set_focus();
      ctlj2me_class.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.classname=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_class.p_sel_length = 0;
}

void ctlj2me_icon.on_lost_focus()
{
   value := strip(p_text);
   if (value:=='') {
      _post_call(j2me_dialog_error,'application icon');
      _set_focus();
      ctlj2me_icon.p_sel_length = 0;
      return;
   }

   j2me_options jOptions=J2ME_OPTIONS();
   jOptions.icon=value;
   J2ME_OPTIONS(jOptions);
   ctlj2me_icon.p_sel_length = 0;
}

// Google Tab
void gwtLocBox.on_lost_focus()
{
   value := strip(p_text);
// if (value:=='') {
//    _post_call(j2me_dialog_error,'application name');
//    _set_focus();
//    return;
// }

   gwt_options gOptions=GWT_OPTIONS();
   gOptions.gwtLoc=value;
   GWT_OPTIONS(gOptions);
   gwtLocBox.p_sel_length = 0;
}

void appLocBox.on_lost_focus()
{
   value := strip(p_text);
// if (value:=='') {
//    _post_call(j2me_dialog_error,'application name');
//    _set_focus();
//    return;
// }

   gwt_options gOptions=GWT_OPTIONS();
   gOptions.appEngineLoc=value;
   GWT_OPTIONS(gOptions);
   appLocBox.p_sel_length = 0;
}

void appVersionBox.on_lost_focus()
{
   value := strip(p_text);
// if (value:=='') {
//    _post_call(j2me_dialog_error,'application name');
//    _set_focus();
//    return;
// }

   gwt_options gOptions=GWT_OPTIONS();
   gOptions.appVersion=value;
   GWT_OPTIONS(gOptions);
   appVersionBox.p_sel_length = 0;
}

void appIdBox.on_lost_focus()
{
   value := strip(p_text);
// if (value:=='') {
//    _post_call(j2me_dialog_error,'application name');
//    _set_focus();
//    return;
// }

   gwt_options gOptions=GWT_OPTIONS();
   gOptions.appID=value;
   GWT_OPTIONS(gOptions);
   appIdBox.p_sel_length = 0;
}

void ctlandroid_ndk_loc.on_change()
{
   value := strip(p_text);
   android_options aOptions=ANDROID_OPTIONS();
   aOptions.ndkLoc=value;
   ANDROID_OPTIONS(aOptions);
   ctlandroid_ndk_loc.p_sel_length = 0;
}

void ctltargetchooser.on_lost_focus()
{
   value := strip(p_text);
   android_options aOptions=ANDROID_OPTIONS();
   aOptions.target=value;
   ANDROID_OPTIONS(aOptions);
}

_command void javaoptions(_str configName="") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }

   mou_hour_glass(true);
   //_convert_to_relative_project_file(_project_name);
   projectFilesNotNeeded(1);
   int project_prop_wid = show('-hidden -app -xy _project_form',_project_name,_ProjectHandle(_project_name));
   mou_hour_glass(false);
   if (configName == "") configName = GetCurrentConfigName();
   ctlbutton_wid := project_prop_wid._find_control('ctlcommand_options');
   typeless result = ctlbutton_wid.call_event('_java_options_form',configName,ctlbutton_wid,LBUTTON_UP,'W');
   ctltooltree_wid := project_prop_wid._find_control('ctlToolTree');
   status := ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'COMPILE', 'I');
   if( status < 0 ) {
      status = ctltooltree_wid._TreeSearch(TREE_ROOT_INDEX, 'BUILD', 'I');
   }
   if( status < 0 ) {
      _message_box('COMPILE or BUILD command not found');
   } else {
      if( result == '' ) {
         opencancel_wid := project_prop_wid._find_control('_opencancel');
         opencancel_wid.call_event(opencancel_wid,LBUTTON_UP,'W');
      } else {
         ok_wid := project_prop_wid._find_control('_ok');
         ok_wid.call_event(ok_wid,LBUTTON_UP,'W');
      }
   }
   projectFilesNotNeeded(0);
}
