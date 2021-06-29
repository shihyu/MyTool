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
#import "fileman.e"
#import "files.e"
#import "guicd.e"
#import "guiopen.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "picture.e"
#import "projconv.e"
#import "project.e"
#import "put.e"
#import "rte.e"
#import "stdprocs.e"
#import "surround.e"
#import "util.e"
#import "wkspace.e"
#endregion


_str def_j2me_phone_types='DefaultColorPhone;DefaultGrayPhone;MediaControlSkin;QwertyDevice';

_command j2me_app_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status=show('-modal _j2me_form');
   if (status) {
      if (status=='') {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }

   //copy the options into variables with more meaningful names
   _str app_name=_param1;
   _str class_name=_param2;
   _str icon_name=_param3;
   _str location=_param4;
   _str phone_type=_param5;
   _str vendor_name=_param6;

   icon_name=_RelativeToProject(icon_name);
   _maybe_append_filesep(location);

   //generate a manifest file
   mf_name := _strip_filename(_project_name,'E'):+'.mf';
   jar_name := _strip_filename(_project_name,'E'):+'.jar';
   jad_name := _strip_filename(_project_name,'E'):+'.jad';

   int temp_wid;
   int orig_wid=_create_temp_view(temp_wid,'',mf_name);

   insert_line('MIDlet-1: ':+app_name:+', ':+icon_name:+', ':+class_name);
   insert_line('MIDlet-Description: ':+app_name);
   insert_line('MIDlet-Name: ':+app_name);
   insert_line('MIDlet-Vendor: ':+vendor_name);
   insert_line('MIDlet-Version: 1.0');
   insert_line('MicroEdition-Configuration: CLDC-1.0');
   insert_line('MicroEdition-Profile: MIDP-2.0');

   save();
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);

   _str ext=EXTENSION_EXE;
   //update some of the project settings
   int handle=_ProjectHandle();
   _str config_names[];
   _ProjectGet_ConfigNames(handle,config_names);

   int index;
   for (index=0;index<config_names._length();++index) {
      int config_node=_ProjectGet_ConfigNode(handle,config_names[index]);

      _ProjectSetAppType(handle,'j2me',config_names[index]);

      _ProjectSet_ObjectDir(handle,'tmpclasses',config_names[index]);

      // set classpath
      classpath := location:+'lib':+FILESEP:+'midpapi20.jar':+PATHSEP:+location:+'lib':+FILESEP:+'cldcapi10.jar';
      _ProjectSet_ClassPathList(handle,classpath,config_names[index]);

      // set bootclasspath in the "Compile" command
      int compile_node=_ProjectGet_TargetNode(handle,'Compile',config_names[index]);
      _ProjectSet_TargetCmdLine(handle,compile_node,'javac %~other -bootclasspath ':+classpath:+' %jbd %cp "%f"');

      // use the emulator in the "Execute" command
      int execute_node=_ProjectGet_TargetNode(handle,'Execute',config_names[index]);
      _ProjectSet_TargetCmdLine(handle,execute_node,_maybe_quote_filename(location:+'bin':+FILESEP:+'emulator':+ext):+' -Xdevice:':+phone_type:+' -Xdescriptor:'_RelativeToProject(jad_name));

      // use the emulator in the "Debug" command
      int debug_node=_ProjectGet_TargetNode(handle,'Debug',config_names[index]);
      _ProjectSet_TargetCmdLine(handle,debug_node,_maybe_quote_filename(location:+'bin':+FILESEP:+'emulator':+ext):+' -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8000 -Xdevice:':+phone_type:+' -Xdescriptor:':+_RelativeToProject(jad_name));

      // call preverify as a post build step
      _ProjectSet_PostBuildCommandsList(handle,_maybe_quote_filename(location:+'bin':+FILESEP:+'preverify':+ext):+' -cldc %cp -d classes tmpclasses',config_names[index]);

      // update the "Make Jar" tool to use the generated manifest file
      int makejar_node=_ProjectGet_TargetNode(handle,'Make Jar',config_names[index]);
      _ProjectSet_TargetCmdLine(handle,makejar_node,'javamakejar jar cvfm ':+_RelativeToProject(jar_name):+' ':+_RelativeToProject(mf_name):+' %{*} %~other');
   }

   // save the project file
   _ProjectSave(handle);

   // generate a "Hello, World" file
   package_name := "";
   last_dot_pos := lastpos('.',class_name);

   if (last_dot_pos) {
      package_name=substr(class_name,1,last_dot_pos-1);
      class_name=substr(class_name,last_dot_pos+1);
   }

   filename := _strip_filename(_project_name,'N'):+stranslate(package_name,FILESEP,'.');
   _maybe_append_filesep(filename);
   strappend(filename,class_name:+'.java');

   orig_wid=_create_temp_view(temp_wid,'',filename,true);
   if (orig_wid!=0) {
      if (package_name:!='') {
         insert_line('package 'package_name';');
         insert_line('');
      }

      status=expand_surround_with(class_name,true,'new_j2me_midlet',false);

      if (status) {
         _message_box("Failed to expand surround-with template \"new_j2me_midlet\"\n\nUsing default template");

         insert_line('import javax.microedition.lcdui.*;');
         insert_line('import javax.microedition.midlet.*;');
         insert_line('');
         insert_line('public class ':+class_name);
         insert_line('    extends MIDlet');
         insert_line('    implements CommandListener {');
         insert_line('  private Form mMainForm;');
         insert_line('');
         insert_line('  public ':+class_name:+'() {');
         insert_line('    mMainForm = new Form("HelloMIDlet");');
         insert_line('    mMainForm.append(new StringItem(null, "Hello, ':+class_name:+'"));');
         insert_line('    mMainForm.addCommand(new Command("Exit", Command.EXIT, 0));');
         insert_line('    mMainForm.setCommandListener(this);');
         insert_line('  }');
         insert_line('');
         insert_line('  public void startApp() {');
         insert_line('    Display.getDisplay(this).setCurrent(mMainForm);');
         insert_line('  }');
         insert_line('');
         insert_line('  public void pauseApp() {}');
         insert_line('');
         insert_line('  public void destroyApp(boolean unconditional) {}');
         insert_line('');
         insert_line('  public void commandAction(Command c, Displayable s) {');
         insert_line('    notifyDestroyed();');
         insert_line('  }');
         insert_line('}');
      }

      make_path(_strip_filename(filename,'N'));
      status=_save_file('+o');
      p_window_id=orig_wid;
      _delete_temp_view(temp_wid);

      // add the file to the project
      _AddFileToProject(filename);

      // make sure that Live Errors sees the changes that have been made
      _workspace_opened_rte();

      // open the file
      edit(_maybe_quote_filename(filename));
   } else {
      // make sure that Live Errors sees the changes that have been made
      _workspace_opened_rte();

      // could not create the file for some reason...
      // show the files tab of the project properties dialog
      project_edit(PROJECTPROPERTIES_TABINDEX_FILES);
   }


   return(0);
}

/**
 * This command is run after vsbuild creates a jar file.  If the
 * project is a J2ME project and requires a JAD file, it will
 * be created.
 */
_command void make_jad(_str prj_name='') name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build system");
      return;
   }
   if (prj_name:=='') {

      return;
   }

   if (pos('-signal', prj_name) !=0) {
      _str rest;
      parse prj_name with prj_name ' -signal' rest;
   }

   int handle=_ProjectHandle(prj_name);

   if (handle<0) {
      return;
   }

   _str app_type=_ProjectGet_AppType(handle);

   if (app_type:!='j2me') {
      return;
   }

   jad_name := _strip_filename(prj_name,'E'):+'.jad';
   jar_name := _strip_filename(prj_name,'E'):+'.jar';
   mf_name := _strip_filename(prj_name,'E'):+'.mf';

   int temp_wid;
   int orig_wid=_create_temp_view(temp_wid,'',jad_name);

   get(mf_name);
   bottom();

   insert_line('MIDlet-Jar-URL: ':+_RelativeToProject(jar_name,prj_name));
   insert_line('MIDlet-Jar-Size: '_filesize(jar_name));

   save();
   p_window_id=orig_wid;
   _delete_temp_view(temp_wid);
}

defeventtab _j2me_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _j2me_form_initial_alignment()
{
    // size the buttons to the textbox
   sizeBrowseButtonToTextBox(ctlicon.p_window_id, ctliconBrowse.p_window_id);
   sizeBrowseButtonToTextBox(ctllocation.p_window_id, ctllocationBrowse.p_window_id);
   sizeBrowseButtonToTextBox(ctlphone.p_window_id, ctlnewphone.p_window_id);
   ctlnewphone.p_x = ctliconBrowse.p_x;
}

static void fillInPhoneTypes()
{
   ctlphone._lbclear();

   _str phone_types=def_j2me_phone_types;

   while (phone_types:!='') {
      _str cur_phone;
      parse phone_types with cur_phone ';' phone_types;

      ctlphone._lbadd_item(cur_phone);
   }

   ctlphone.p_line=1;
   ctlphone._lbselect_line();
   ctlphone.p_text=ctlphone._lbget_text();
}

void ctlok.on_create()
{
   default_location := "";

   if (_isWindows()) {
      j2me_version := _ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Sun Microsystems, Inc.\J2ME Wireless Toolkit','','LatestVersion');

      if (j2me_version!='') {
         default_location=_ntRegQueryValue(HKEY_LOCAL_MACHINE,'SOFTWARE\Sun Microsystems, Inc.\J2ME Wireless Toolkit\'j2me_version,'','InstallDir');
      }
   }

   ctllocation.p_text=default_location;

   fillInPhoneTypes();
   _j2me_form_initial_alignment();
}

ctliconBrowse.lbutton_up()
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
   ctlicon.p_text= result;
}

void ctllocationBrowse.lbutton_up()
{
   _str result = _ChooseDirDialog('',ctllocation.p_text);
   if ( result:!='' ) {
      ctllocation.p_text=result;
   }
}

void ctlnewphone.lbutton_up()
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

void ctlok.lbutton_up()
{
   if (strip(ctlappName.p_text):=='') {
      _message_box('Please specify the application name');
      return;
   }
   if (strip(ctlclass.p_text):=='') {
      _message_box('Please specify the class name');
      return;
   }
   if (strip(ctlicon.p_text):=='') {
      _message_box('Please specify the icon');
      return;
   }

   if (strip(ctlvendor.p_text:=='')) {
      _message_box('Please specify a vendor name');
      return;
   }

   _param1=ctlappName.p_text;
   _param2=ctlclass.p_text;
   _param3=ctlicon.p_text;
   _param4=ctllocation.p_text;
   _param5=ctlphone.p_text;
   _param6=ctlvendor.p_text;

   p_active_form._delete_window(0);
}
