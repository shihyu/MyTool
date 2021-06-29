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
#include "tagsdb.sh"
#include "minihtml.sh"
#import "applet.e"
#import "backtag.e"
#import "cjava.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "diff.e"
#import "fileman.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "projconv.e"
#import "project.e"
#import "projutil.e"
#import "saveload.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tagform.e"
#import "tags.e"
#import "wizard.e"
#import "wkspace.e"
#import "se/tags/TaggingGuard.e"
#import "se/util/MousePointerGuard.e"
#endregion

defeventtab _applet_form;

static typeless OKBUTTON_CALLBACK(...) {
   if (arg()) ctlclassname_label.p_user=arg(1);
   return ctlclassname_label.p_user;
}

/**
 * Shows the "One item wizard" that we run for
 * AWT Applet, AWT Application, JFC Applet,
 * JFC Application.
 *
 * @param pfnOkButton
 *               OK button callback.  Should return nonzero to keep dialog from proceeding.
 *
 *               prototype for acceptable callback:
 *
 *               <B>int OKCallback(_str ClassName);</B>
 * @param DialogCaption
 *               Caption for wizard dialog
 * @param LabelCaption
 *               Caption for text box label
 */
void ctlok.on_create(typeless *pfnOkButton,
                     _str DialogCaption="Create AWT Applet",
                     _str LabelCaption="Applet class:")
{
   OKBUTTON_CALLBACK(pfnOkButton);
   p_active_form.p_caption=DialogCaption;
   ctlclassname_label.p_caption=_chr(1)"<B>"LabelCaption:+_chr(1)"</B>";
   ctlclassname.p_text=GetClassName(_project_name);
}

void ctlok.lbutton_up()
{
   caption := "";
   if (ctlclassname.p_text=="") {
      parse ctlclassname_label.p_caption with "<B>" caption ":";
      ctlclassname._text_box_error(nls("You must fill in %s1",caption));
      return;
   }
   ctlclassname.p_text=stranslate(ctlclassname.p_text,"_"," ");
   //If there are spaces, just convert them to underscores
   if (!isid_valid(ctlclassname.p_text)) {
      //Clean up the caption so we can use it in the caption
      captionName := ctlclassname_label.p_caption;
      _str ch1=_chr(1);
      parse captionName with (ch1) "<B>" captionName (ch1) "</B>";
      _maybe_strip(captionName, ":");

      ctlclassname._text_box_error(nls("%s1 must be a valid identifier",captionName));
      return;
   }
   typeless *pfnOkButton=OKBUTTON_CALLBACK();
   int status=(*pfnOkButton)(strip(ctlclassname.p_text));
   if (!status || status==COMMAND_CANCELLED_RC) {
      p_active_form._delete_window(status);
   }
}

static _str GetClassName(_str Filename)
{
   className := _strip_filename(Filename,"PE");
   className=stranslate(className,"_"," ");

   /*  name must consist of valid identifier characters. */
   className=stranslate(className,"_","[~A-Za-z0-9_$]","r");
   /*  First character must not be number. */
   if (isinteger(substr(className,1,1))) {
      className="_"className;
   }

   return(className);
}

static int GenerateAWTAppletFile(_str AppletClass)
{
   _str projectDir=_file_path(_project_name);
   filename := projectDir:+AppletClass".java";
   if (file_exists(filename)) {
      int result=_message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),"",MB_YESNOCANCEL);
      if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }else if (result==IDNO) {
         return(1);
      }
   }

   className := GetClassName(filename);

   classFilename := className".class";
   classFilename=_RelativeToProject(classFilename);

   //Put together our HTML for the information dialog
   HTMLOutput := "";
   _add_line_to_html_caption(HTMLOutput,"A standard AWT Applet will be generated for you.");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"Applet Class:");
   _add_line_to_html_caption(HTMLOutput,"<LI>"classFilename"</LI>");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"These files will be added to the project "_strip_filename(_project_name,'P'));
   typeless status=show("-modal _new_project_info_form",
               "The AWT Applet wizard will create a skeleton project for you with the following\nspecifications:",
               HTMLOutput);
   if (status) {
      if (status=="") return(1);
      return(status);
   }

   _str array[];
   int handle=_ProjectHandle();
   _ProjectGet_ConfigNames(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      int TargetNode=_ProjectGet_AppTypeTargetNode(handle,"execute","applet",array[i]);
      _ProjectSet_TargetAppletClass(handle,TargetNode,classFilename);
   }
   status=_ProjectSave(handle);
   if (status) {
      _message_box(nls("Could not update project file '%s'\n%s",_project_name,get_message(status)));
      return(status);
   }

   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();
   insert_line("import java.awt.*;");
   insert_line("import java.applet.*;");
   insert_line("");
   insert_line("");
   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   _str indentStrX3=indent_string(p_SyntaxIndent*3);
   insert_line("public class "AppletClass" extends Applet");
   insert_line("{");
   insert_line(indentStr"public void init()");
   insert_line(indentStr"{");
   insert_line(indentStrX2:+"setLayout(null);");
   insert_line(indentStrX2:+"setSize(400,300);");
   insert_line(indentStr"}");
   insert_line("}");
   status=_save_file("+o");
   if (status) {
      _message_box(nls("Could not save file '%s1'\n'%s2'",p_buf_name,get_message(status)));
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return(status);
   }
   _AddFileToProject(filename);
   _param1=filename;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

static int GenerateJFCAppletFile(_str AppletClass)
{
   _str projectDir=_file_path(_project_name);
   filename := projectDir:+AppletClass".java";
   if (file_exists(filename)) {
      int result=_message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),"",MB_YESNOCANCEL);
      if (result==IDCANCEL) {
         return(COMMAND_CANCELLED_RC);
      }else if (result==IDNO) {
         return(1);
      }
   }

   classFilename := _strip_filename(filename,'E')".class";
   classFilename=_RelativeToProject(classFilename);

   //Put together our HTML for the information dialog
   HTMLOutput := "";
   _add_line_to_html_caption(HTMLOutput,"A standard JFC Applet will be generated for you.");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"Applet Class:");
   _add_line_to_html_caption(HTMLOutput,"<LI>"classFilename"</LI>");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"These files will be added to the project "_strip_filename(_project_name,'P'));
   typeless status=show("-modal _new_project_info_form",
               "The JFC Applet wizard will create a skeleton project for you with the following\nspecifications:",
               HTMLOutput);
   if (status) {
      if (status=="") return(1);
      return(status);
   }


   _str array[];
   int handle=_ProjectHandle();
   _ProjectGet_ConfigNames(handle,array);
   int i;
   for (i=0;i<array._length();++i) {
      int TargetNode=_ProjectGet_AppTypeTargetNode(handle,"execute","applet",array[i]);
      _ProjectSet_TargetAppletClass(handle,TargetNode,classFilename);
   }
   status=_ProjectSave(handle);
   if (status) {
      _message_box(nls("Could not update project file '%s'\n%s",_project_name,get_message(status)));
      return(status);
   }

   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();
   insert_line("import java.awt.*;");
   insert_line("import javax.swing.*;");
   insert_line("");
   insert_line("");
   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   _str indentStrX3=indent_string(p_SyntaxIndent*3);
   insert_line("public class "AppletClass" extends JApplet");
   insert_line("{");
   insert_line(indentStr"public void init()");
   insert_line(indentStr"{");
   insert_line(indentStrX2:+"getContentPane().setLayout(null);");
   insert_line(indentStrX2:+"setSize(400,300);");
   insert_line(indentStr"}");
   insert_line("}");
   status=_save_file("+o");
   if (status) {
      _message_box(nls("Could not save file '%s1'\n'%s2'",p_buf_name,get_message(status)));
      p_window_id=orig_view_id;
      _delete_temp_view(temp_view_id);
      return(status);
   }
   _AddFileToProject(filename);
   _param1=filename;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

_command int awt_applet_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status=show("-modal _applet_form",GenerateAWTAppletFile);
   if (status) {
      if (status=="") {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }
   edit(_maybe_quote_filename(_param1));
   return(0);
}

_command jfc_applet_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status=show("-modal _applet_form",GenerateJFCAppletFile,"Create JFC Applet");
   if (status) {
      if (status=="") {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }
   edit(_maybe_quote_filename(_param1));
   return(0);
}

static int generate_java_with_main2(_str ClassName)
{
   _str projectDir=_file_path(_project_name);
   filename := projectDir:+ClassName".java";
   if (file_exists(filename)) {
      int result=_message_box(nls("A file named '%s1' already exists.\n\nGenerate file anyway?",filename),"",MB_YESNOCANCEL);
      if (result==IDCANCEL) {
            return(COMMAND_CANCELLED_RC);
      }else if (result==IDNO) {
         return(1);
      }
   }
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=filename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();

   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);

   insert_line("public class "ClassName" {");
   insert_line(indentStr"public static void main(String args[]) {");
   insert_line(indentStrX2);
   insert_line(indentStr"}");
   insert_line("}");
   int status=_save_file("+o");

   _AddFileToProject(filename);
   _param1=filename;
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   return(0);
}

_command int java_with_main_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   mainClassName := GetClassName(_project_name);
   int status=generate_java_with_main2(mainClassName);
   if (status) {
      if (status=="") {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }
   status=edit(_maybe_quote_filename(_param1));
   if (!status) {
      top();down();down();
      end_line();
   }
   return(0);
}

static const AWTAPP_MAIN_FILENAME=        "awtapp.java";
static const AWTAPP_ABOUTDIALOG_FILENAME= "AboutDialog.java";
static const AWTAPP_EXITDIALOG_FILENAME=  "ExitDialog.java";

static int GenerateAWTApplicationFiles(_str ClassName)
{
   _str sourcePath=_getSlickEditInstallPath():+"wizards":+FILESEP"java"FILESEP"awtapp"FILESEP;
   _str destPath=_file_path(_project_name);

   //Get together the filenames of the files that we will be copying
   aboutFilename := destPath:+AWTAPP_ABOUTDIALOG_FILENAME;
   exitFilename := destPath:+AWTAPP_EXITDIALOG_FILENAME;
   _str mainAppFilename=_file_path(_project_name):+ClassName".java";

   //Put together our HTML for the information dialog
   HTMLOutput := "";
   _add_line_to_html_caption(HTMLOutput,"A standard AWT Application will be generated for you.");
   _add_line_to_html_caption(HTMLOutput,"");

   _add_line_to_html_caption(HTMLOutput,"Main class:");
   _add_line_to_html_caption(HTMLOutput,"<LI>"_strip_filename(mainAppFilename,'P')"</LI>");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"Other Source Files:");
   _add_line_to_html_caption(HTMLOutput,"<LI>"_strip_filename(aboutFilename,'P')"</LI>");
   _add_line_to_html_caption(HTMLOutput,"<LI>"_strip_filename(exitFilename,'P')"</LI>");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"These files will be added to the project "_strip_filename(_project_name,'P'));

   typeless status=show("-modal _new_project_info_form",
               "The AWT Application wizard will create a skeleton project for you with the following\nspecifications:",
               HTMLOutput);
   if (status) {
      if (status=="") return(1);
      return(status);
   }

   status=copy_file(sourcePath:+AWTAPP_ABOUTDIALOG_FILENAME,aboutFilename);
   if (status) {
      _message_box(nls("Could not write file '%s1'\n%s2",aboutFilename,get_message(status)));
      return(status);
   }
   _str newProjectFiles[]=null;
   newProjectFiles[newProjectFiles._length()]=destPath:+AWTAPP_ABOUTDIALOG_FILENAME;

   status=copy_file(sourcePath:+AWTAPP_EXITDIALOG_FILENAME,exitFilename);
   if (status) {
      _message_box(nls("Could not write file '%s1'\n%s2",exitFilename,get_message(status)));
      return(status);
   }
   newProjectFiles[newProjectFiles._length()]=destPath:+AWTAPP_EXITDIALOG_FILENAME;

   status=copy_file(sourcePath:+AWTAPP_MAIN_FILENAME,mainAppFilename);
   if (status) {
      _message_box(nls("Could not write file '%s1'\n%s2",mainAppFilename,get_message(status)));
      return(status);
   }
   temp_view_id := 0;
   orig_view_id := 0;
   status=_open_temp_view(mainAppFilename,temp_view_id,orig_view_id);
   if (status) {
      _message_box(nls("Could not open file '%s1'\n%s2",mainAppFilename,get_message(status)));
      return(status);
   }
   top();
   status=search('\1CLASSNAME\1','@r',ClassName);//Number of changes should be 8,
   _save_file("+o");
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;
   newProjectFiles[newProjectFiles._length()]=mainAppFilename;
   //Only call _AddFileToProject once, so user is only prompted to add the files
   //to version control once
   _AddFileToProject(newProjectFiles);

   _param1=mainAppFilename;

   return(0);
}

static const AWTAPP_JFC_FILENAME= "jfcapp.java";
static const IMAGES_DIR_NAME= "images";

static int GenerateJFCApplicationFiles(_str ClassName)
{
   _str sourcePath=_getSlickEditInstallPath():+"wizards":+FILESEP"java"FILESEP"jfcapp"FILESEP;
   _str destPath=_file_path(_project_name);
   destFilename := destPath:+ClassName".java";

   // Build a path name where the image files are
   imageSourcePath := sourcePath:+IMAGES_DIR_NAME:+FILESEP;
   imageDestPath := destPath:+IMAGES_DIR_NAME:+FILESEP;
   _str imageFilenames[]=null;

   HTMLOutput := "";
   _add_line_to_html_caption(HTMLOutput,"A standard JFC Application will be generated for you.");
   _add_line_to_html_caption(HTMLOutput,"");

   _add_line_to_html_caption(HTMLOutput,"Main class:");
   _add_line_to_html_caption(HTMLOutput,"<LI>"_strip_filename(destFilename,'P')"</LI>");
   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"Resource Files:");

   // Get the names of all the image files first
   int ff;
   for (ff=1;;ff=0) {
      curFilename := file_match("-d "_maybe_quote_filename(imageSourcePath:+ALLFILES_RE),ff);
      if (curFilename=="") break;
      if (_last_char(curFilename)==FILESEP) continue;
      imageFilenames[imageFilenames._length()]=curFilename;
      _add_line_to_html_caption(HTMLOutput,"<LI>"IMAGES_DIR_NAME:+FILESEP:+_strip_filename(curFilename,'P')"</LI>");
   }

   _add_line_to_html_caption(HTMLOutput,"");
   _add_line_to_html_caption(HTMLOutput,"These files will be added to the project "_strip_filename(_project_name,'P'));

   typeless status=show("-modal _new_project_info_form",
               "The JFC Application wizard will create a skeleton project for you with the following\nspecifications:",
               HTMLOutput);
   if (status) {
      if (status=="") return(1);
      return(status);
   }

   status=copy_file(sourcePath:+AWTAPP_JFC_FILENAME,destFilename);
   if (status) {
      _message_box(nls("Could not write file '%s1'\n%s2",destFilename,get_message(status)));
      return(status);
   }
   _str newProjectFiles[]=null;
   newProjectFiles[newProjectFiles._length()]=destFilename;

   temp_view_id := 0;
   orig_view_id := 0;
   status=_open_temp_view(destFilename,temp_view_id,orig_view_id);
   if (status) {
      _message_box(nls("Could not open file '%s1'\n%s2",destFilename,get_message(status)));
      return(status);
   }
   top();
   numchanges := 0;
   status=search('\1CLASSNAME\1','r@',ClassName,numchanges);//Number of changes should be 9,
   _save_file("+o");
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   mkdir(imageDestPath);
   // Don't check status, because a status likely means the directory exists, and
   // that would be ok.

   // Copy all the files in now
   int i,j;
   for (i=0;i<imageFilenames._length();++i) {
      curDestFilename := imageDestPath:+_strip_filename(imageFilenames[i],'P');
      if (file_exists(curDestFilename)) {
         int result=_message_box(nls("Overwrite file '%s1'?",curDestFilename),"",MB_YESNO);
         if (result==IDNO) {
            // Mark this file as being one that we will not delete if we wind up
            // in a cleanup scenario
            imageFilenames[i]=_chr(1):+imageFilenames[i];
            newProjectFiles[newProjectFiles._length()]=curDestFilename;
            continue;
         }
      }
      status=copy_file(imageFilenames[i],curDestFilename);
      if (status) {
         _message_box(nls("Could not write file '%s1'\n%s2",curDestFilename,get_message(status)));

         // Delete the source file that we put in here
         delete_file(destFilename);

         // Delete all the image files that we have copied in so far
         for (j=0;j<i;++j) {
            if (substr(imageFilenames[j],1,1)!=_chr(1)) {
               curDestFilenameJ := imageDestPath:+_strip_filename(imageFilenames[j],'P');
               delete_file(curDestFilenameJ);
            }
         }
         return(status);
      }
      newProjectFiles[newProjectFiles._length()]=curDestFilename;
   }

   //Only call _AddFileToProject once, so user is only prompted to add the files
   //to version control once
   _AddFileToProject(newProjectFiles);

   _param1=destFilename;

   return(0);
}

_command int jfc_app_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status=show("-modal _applet_form",GenerateJFCApplicationFiles,"Create JFC Application","Class name:");
   if (status) {
      if (status=="") {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }
   edit(_maybe_quote_filename(_param1));
   return(0);
}

_command int awt_app_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   int status=show("-modal _applet_form",GenerateAWTApplicationFiles,"Create AWT Application","Class name:");
   if (status) {
      if (status=="") {
         return(COMMAND_CANCELLED_RC);
      }else{
         return(status);
      }
   }
   edit(_maybe_quote_filename(_param1));
   return(0);
}

/******************************************************************************/
struct BEAN_PROPERTIES {
   _str Name;
   _str Type;
   bool ReadOnly;
};
struct JAVABEAN_INFO {
   _str Name;
   _str PackageName;
   _str ExtendingClass;
   _str ImplementingClass;
   _str OverrideMethods[];
   BEAN_PROPERTIES Properties[];
   bool AddToProject;
};

JAVABEAN_INFO gBeanInfo;


static int javabean_slide0create()
{
   _nocheck _control ctls0_name;
   _nocheck _control ctls0_extends;
   _nocheck _control ctls0_implements;
   ctls0_name.p_text=stranslate(_strip_filename(_project_name,"PE"),"_"," ");
   ctls0_extends.p_text="Canvas";
   ctls0_implements.p_text="Serializable";
   return(0);
}

static int javabean_slide0shown()
{
   _nocheck _control ctls0_name;

   wid := p_window_id;
   p_window_id=ctls0_name;
   _set_sel(1,length(p_text)+1);
   _set_focus();
   p_window_id=wid;
   return(0);
}

static int javabean_slide0next()
{
   _nocheck _control ctls0_name;
   _nocheck _control ctls0_pkg_name;
   _nocheck _control ctls0_extends;
   _nocheck _control ctls0_implements;
   gBeanInfo.Name=stranslate(ctls0_name.p_text,"_"," ");
   if (gBeanInfo.Name=="") {
      ctls0_name._text_box_error("You must fill in a bean name");
      return(1);
   }
   if (!isid_valid(gBeanInfo.Name)) {
      ctls0_name._text_box_error("Bean name must be a valid identfier");
      return(1);
   }
   gBeanInfo.PackageName=ctls0_pkg_name.p_text;
   gBeanInfo.ExtendingClass=ctls0_extends.p_text;
   gBeanInfo.ImplementingClass=ctls0_implements.p_text;
   return(0);
}

static int javabean_slide1create()
{
   se.util.MousePointerGuard hour_glass;
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=gBeanInfo.Name".java";
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();
   if (gBeanInfo.PackageName!="") {
      insert_line("package "gBeanInfo.PackageName";");
      insert_line("");
   }
   insert_line("public class "gBeanInfo.Name" extends "gBeanInfo.ExtendingClass" implements "gBeanInfo.ImplementingClass" {");
   insert_line("}");
   up();
   _end_line();

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(true);
   _UpdateContext(true);
   tag_clear_matches();

   selection_indexes := "";
   int num_matches= _do_default_get_virtuals("",
                                             gBeanInfo.Name,
                                             selection_indexes,
                                             false, true, p_LangCaseSensitive,true);

   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   wid := p_window_id;
   _nocheck _control ctls1_list1;
   p_window_id=ctls1_list1;
   VS_TAG_BROWSE_INFO cm;
   VS_TAG_BROWSE_INFO taginfo[]; taginfo._makeempty();
   int i;
   for (i=1; i<=num_matches; i++) {
      tag_get_match_info(i, cm);
      taginfo[i-1]=cm;
   }
   TextWidth := 0;
   for (i=0;i<taginfo._length();++i) {
      insert_line(" "taginfo[i].class_name"::"taginfo[i].member_name);
      CurWidth := _text_width(taginfo[i].class_name"::"taginfo[i].member_name);
      if (CurWidth>TextWidth) {
         TextWidth=CurWidth;
      }
   }
   _lbtop();
   _set_focus();
   p_window_id=wid;
   return(0);
}

static int javabean_slide1next()
{
   wid := p_window_id;
   _nocheck _control ctls1_list1;
   p_window_id=ctls1_list1;
   save_pos(auto p);
   gBeanInfo.OverrideMethods=null;
   gBeanInfo.OverrideMethods[0]=gBeanInfo.ExtendingClass;
   gBeanInfo.OverrideMethods[1]=gBeanInfo.ImplementingClass;
   top();up();
   line := "";
   while (!down()) {
      get_line(line);
      gBeanInfo.OverrideMethods[gBeanInfo.OverrideMethods._length()]=line;
   }
   restore_pos(p);
   p_window_id=wid;
   return(0);
}

static void GetProperties(BEAN_PROPERTIES (&Properties)[])
{
   Name := "";
   Type := "";
   Properties=null;
   wid := p_window_id;
   _nocheck _control ctls2_Attributes;
   p_window_id=ctls2_Attributes;
   _lbtop();_lbup();
   while (!_lbdown()) {
      _str text=_lbget_text();
      parse text with Name "\t" Type;
      len := Properties._length();
      Properties[len].Name=Name;
      Properties[len].Type=Type;
   }
   p_window_id=wid;
}

static int javabean_slide2create()
{
   _nocheck _control ctls2_Attributes;
   wid := p_window_id;
   p_window_id=ctls2_Attributes;
   _col_width(0,p_width intdiv 2);
   _col_width(1,p_width intdiv 2);
   p_window_id=wid;
   return(0);
}

static int javabean_slide2next()
{
   GetProperties(gBeanInfo.Properties);
   return(javabean_show_new_project_info());
}


static int GetBeanFilename2(_str NamePrefix,_str ProjectPath,_str &OutFilename,
                            bool CheckForExistingFiles=true)
{
   Filename := absolute(NamePrefix,ProjectPath);
   if (CheckForExistingFiles) {
      if (file_exists(Filename)) {
         int result=_message_box(nls("A file '%s1' already exists.\n\nReplace existing file?",Filename),"",MB_YESNOCANCEL);
         if (result!=IDYES) return(1);
      }
   }
   OutFilename=Filename;
   return(0);
}

void _add_line_to_html_caption(_str &line,_str more)
{
   more=stranslate(more,"        ","\t");
   strappend(line,more"\n");
}

static int javabean_show_new_project_info()
{
   line := "";
   _add_line_to_html_caption(line,"<B>Bean name:</B>");
   _add_line_to_html_caption(line,"\t"gBeanInfo.Name);
   if (gBeanInfo.PackageName!="") {
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"<B>Package name:</B>");
      _add_line_to_html_caption(line,"\t"gBeanInfo.PackageName);
   }else{
      _add_line_to_html_caption(line,"");
      _add_line_to_html_caption(line,"No package specified");
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Extending class:</B>");
   _add_line_to_html_caption(line,"\t"gBeanInfo.ExtendingClass);
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Implementing class:</B>");
   _add_line_to_html_caption(line,"\t"gBeanInfo.ImplementingClass);
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Overriden methods:</B>");
   found := false;
   int i;
   for (i=0;i<gBeanInfo.OverrideMethods._length();++i) {
      if (substr(gBeanInfo.OverrideMethods[i],1,1)==">") {
         _add_line_to_html_caption(line,"\t"substr(gBeanInfo.OverrideMethods[i],2));
         found=true;
      }
   }
   if (!found) {
      //No overridden methods selected
      _add_line_to_html_caption(line,"\tNone");
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Properties:</B>");
   if (gBeanInfo.Properties._length()) {
      for (i=0;i<gBeanInfo.Properties._length();++i) {
         _add_line_to_html_caption(line,"\t"gBeanInfo.Properties[i].Type" "gBeanInfo.Properties[i].Name);
      }
   }
   _add_line_to_html_caption(line,"");
   _add_line_to_html_caption(line,"<B>Files generated:</B>");
   BeanFilename := BeanInfoFilename := "";
   int status=GetBeanFilename2(gBeanInfo.Name".java",gBeanInfo.PackageName,BeanFilename,false);
   status=GetBeanFilename2(gBeanInfo.Name"BeanInfo.java",gBeanInfo.PackageName,BeanInfoFilename,false);
   _add_line_to_html_caption(line,"\t"BeanFilename);
   _add_line_to_html_caption(line,"\t"BeanInfoFilename);

   status=show("-modal _new_project_info_form",
               "The JavaBean wizard will create a skeleton project for you with the following\nspecifications:",
               line);
   if (status=="") {
      return(COMMAND_CANCELLED_RC);
   }
   return(status);
}

/**
 * Returns PropertyName cased like a variable for a Javabean.
 * The convention for this is to lowcase the first character
 * in the variable name.
 *
 * @param PropertyName
 *               Name of property to return "cased" name for.
 *
 * @return Returns PropertyName with the first character lowcased.
 */
static _str GetCasedPropertyVariable(_str PropertyName)
{
   return(lowcase(substr(PropertyName,1,1)):+substr(PropertyName,2));
}

static int CreateJavaBeanInfoFile(_str BeanInfoFilename,JAVABEAN_INFO info)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=BeanInfoFilename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();//Have to do this so that p_SyntaxIndent works

   if (info.PackageName!="") {
      insert_line("package "info.PackageName";");
   }
   insert_line("import java.beans.*;");
   insert_line("");insert_line("");
   insert_line("public class "info.Name"BeanInfo extends SimpleBeanInfo {");
   insert_line("");
   _str indentStr=indent_string(p_SyntaxIndent);
   _str indentStrX2=indent_string(p_SyntaxIndent*2);
   insert_line(indentStr"public BeanDescriptor getBeanDescriptor() {");
   insert_line(indentStrX2"BeanDescriptor bd;");
   insert_line(indentStrX2"bd = new BeanDescriptor(beanClass);");
   insert_line(indentStrX2"return(bd);");
   insert_line(indentStr"}");
   insert_line("");
   insert_line(indentStr"public java.awt.Image getIcon(int Icon)");
   insert_line(indentStr"{");
   insert_line(indentStrX2"java.awt.Image img = null;");
   insert_line(indentStrX2"return(img);");
   insert_line(indentStr"}");

   insert_line(indentStr"private final Class beanClass = "info.Name".class;");
   insert_line("}");


   int status=_save_file("+o");
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   if (status) {
      _message_box(nls("Could not save file '%s1'\n%s2",BeanInfoFilename,get_message(status)));
   }
   return(status);
}

static int CreateJavaBeanFile(_str BeanFilename,JAVABEAN_INFO info)
{
   temp_view_id := 0;
   int orig_view_id=_create_temp_view(temp_view_id);
   p_buf_name=BeanFilename;
   p_UTF8=_load_option_UTF8(p_buf_name);
   _SetEditorLanguage();//Have to do this so that p_SyntaxIndent works

   if (info.PackageName!="") {
      insert_line("package "info.PackageName";");
   }
   insert_line("import java.awt.*;");
   if (info.ImplementingClass=="Serializable") {
      insert_line("import java.io.Serializable;");
   }
   insert_line("");insert_line("");
   FirstLine := "public class "info.Name;
   if (info.ExtendingClass!="") {
      FirstLine :+= " extends "info.ExtendingClass;
      if (info.ImplementingClass!="") FirstLine :+= " ";
   }
   if (info.ImplementingClass!="") {
      FirstLine :+= "implements "info.ImplementingClass" {";
   }
   insert_line(FirstLine);
   insert_line("");
   _str indentString=indent_string(p_SyntaxIndent);
   _str indentStringX2=indent_string(p_SyntaxIndent*2);
   _str indentStringX3=indent_string(p_SyntaxIndent*3);
   i := 0;
   status := 0;

   {
      int MatchList[]=null;
      if (info.OverrideMethods._varformat()==VF_ARRAY) {
         //First two entries are taken
         for (i=2;i<info.OverrideMethods._length();++i) {
            if (substr(info.OverrideMethods[i],1,1)==">") {
               MatchList[MatchList._length()]=i-2;
            }
         }
      }
      insert_line("");
      insert_line(indentString"public "gBeanInfo.Name"() {");
      insert_line(indentString"}");
      insert_line("");
      for (i=0;i<MatchList._length();++i) {
         status=tag_get_match_info(MatchList[i]+1, auto cm);

         if (!status) {
            // Can't we get source comments?
            _str header_list[];header_list._makeempty();
            int indent_col=p_SyntaxIndent;
            status=_ExtractTagComments(header_list,2000,cm.member_name,cm.file_name,cm.line_no,
                                       cm.type_name, cm.class_name, indent_col);
            // generate the match signature for this function, not a prototype
            brace_indent := 0;
            c_access_flags := 0;
            int akpos=_java_generate_function(cm,c_access_flags,header_list,null,
                                                  indent_col,brace_indent,false);
            insert_line("");
         }
      }
      for (i=0;i<info.Properties._length();++i) {
         insert_line(indentString"//This variable should be initialized");
         insert_line(indentString"private "info.Properties[i].Type" "GetCasedPropertyVariable(info.Properties[i].Name)";");
      }
      insert_line("");
      for (i=0;i<info.Properties._length();++i) {
         insert_line(indentString"public "info.Properties[i].Type" get"info.Properties[i].Name"() {");
         insert_line(indentStringX2"return(this."GetCasedPropertyVariable(info.Properties[i].Name)");");
         insert_line(indentString"}");
         insert_line("");
         insert_line(indentString"public void set"info.Properties[i].Name"("info.Properties[i].Type" "GetCasedPropertyVariable(info.Properties[i].Name)") {");
         insert_line(indentStringX2"this."GetCasedPropertyVariable(info.Properties[i].Name)" = "GetCasedPropertyVariable(info.Properties[i].Name)";");
         insert_line(indentString"}");
         insert_line("");
      }
      insert_line("");
      insert_line(indentString"public static void main(String args[]) {");
      insert_line(indentString"}");
   }

   insert_line("}");


   status=_save_file("+o");
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);
   if (status) {
      _message_box(nls("Could not save file '%s1'\n%s2",BeanFilename,get_message(status)));
   }
   return(status);
}

static _str GetPackagePath(_str ProjectPath,_str PackageName)
{
   _maybe_append_filesep(ProjectPath);
   packagePath := "";
   packagePath=ProjectPath:+stranslate(PackageName,FILESEP,".");
   _maybe_append_filesep(packagePath);
   return(packagePath);
}

static int javabean_finish()
{
   BeanFilename := BeanInfoFilename := "";

   _str packagePath=GetPackagePath(_file_path(_project_name),gBeanInfo.PackageName);
   //We check about creating this directory below.  We don't want to do it here
   //because the user could cancel if they are prompted because the file already
   //exists.

   int status=GetBeanFilename2(gBeanInfo.Name".java",packagePath,BeanFilename);
   if (status) {
      return(1);
   }
   status=GetBeanFilename2(gBeanInfo.Name"BeanInfo.java",packagePath,BeanInfoFilename);
   if (status) {
      return(1);
   }
   if (!file_exists(packagePath".")) {
      make_path(packagePath);
   }
   _str ProjectPath;
   if (_project_name!="") {
      ProjectPath=_file_path(_project_name);
   }else{
      ProjectPath=getcwd();
   }

   if (!file_exists(packagePath".")) {
      //Check to see if the packagePath exists
      //
      //Call make_path because the user could have specified something with
      //multiple directory names
      make_path(packagePath);
   }
   CreateJavaBeanFile(BeanFilename,gBeanInfo);
   CreateJavaBeanInfoFile(BeanInfoFilename,gBeanInfo);

   if (gBeanInfo.AddToProject) {

      _str newProjectFiles[]=null;
      newProjectFiles[newProjectFiles._length()]=BeanFilename;
      newProjectFiles[newProjectFiles._length()]=BeanInfoFilename;

      //Only call _AddFileToProject once, so user is only prompted to add the files
      //to version control once
      _AddFileToProject(newProjectFiles);

   }
   //Change the project file to reflect the package that the class files
   //will be in
   classFilename := _strip_filename(_project_name,"E")".class";
   classFilename=_RelativeToProject(classFilename);

   _str pkgName=gBeanInfo.PackageName;
   if (pkgName!="") {
      //If there is a package name, we need to add it on to the execute lines in
      //the project file

      if (_last_char(gBeanInfo.PackageName)!=".") {
         pkgName=gBeanInfo.PackageName".";
      }
      _str array[];
      int handle=_ProjectHandle();
      _ProjectGet_ConfigNames(handle,array);
      int i;
      for (i=0;i<array._length();++i) {
         int TargetNode=_ProjectGet_AppTypeTargetNode(handle,"execute","application",array[i]);
         _ProjectSet_TargetCmdLine(handle,TargetNode,"java "pkgName:+gBeanInfo.Name);
      }
      status=_ProjectSave(handle);
      if (status) {
         _message_box(nls("Could not update project file '%s'\n%s",_project_name,get_message(status)));
         return(status);
      }
   }


   orig_view_id := p_window_id;
   edit(_maybe_quote_filename(BeanFilename));
   p_window_id=orig_view_id;
   return(0);
}

/**
 * Runs the JavaBean wizard.  See the big comment in
 * wizard.e to help understand this.
 *
 * @return 0 if successful, COMMAND_CANCELLED_RC if cancelled by user
 */
_command int javabean_wizard() name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveBuild()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Build support");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   gBeanInfo._makeempty();
   typeless javabean_callback_table:[] ;
   javabean_callback_table:["ctlslide0.create"]=javabean_slide0create;
   javabean_callback_table:["ctlslide0.shown"]=javabean_slide0shown;
   javabean_callback_table:["ctlslide0.next"]=javabean_slide0next;
   javabean_callback_table:["ctlslide1.create"]=javabean_slide1create;
   javabean_callback_table:["ctlslide1.next"]=javabean_slide1next;
   javabean_callback_table:["ctlslide2.create"]=javabean_slide2create;
   javabean_callback_table:["ctlslide2.next"]=javabean_slide2next;
   //javabean_callback_table:["ctlslide3.create"]=javabean_slide3create;
   //javabean_callback_table:["ctlslide3.shown"]=javabean_slide3shown;
   //javabean_callback_table:["ctlslide3.next"]=javabean_slide3next;
   javabean_callback_table:["finish"]=javabean_finish;

   WIZARD_INFO info;
   info.callbackTable=javabean_callback_table;
   info.parentFormName="_javabean_frames_form";
   info.dialogCaption="Create JavaBean";
   gBeanInfo.AddToProject=true;
   int status=_Wizard(&info);
   return(status);
}

defeventtab _javabean_frames_form;
//These are buttons and keys that are actually on _javabean_frames_form
//that we cannot catch with the callback table.

void ctls2_AttributeAdd.lbutton_up()
{
   int status=show("-modal _java_bean_property_form");
   if (!status) {
      ctls2_Attributes._lbadd_item(_param2 :+ "\t"  :+ _param1);
      ctls2_Attributes._lbsort();
   }
}

void ctls2_AttributeRemove.lbutton_up()
{
   ctls2_Attributes._lbdelete_item();
}

//This is for when the edit window has focus and some one hits "Alt+F" for the
//Finish button
void ctls3_edit.enter,A_F()
{
   _nocheck _control ctlnext;
   ctlnext.call_event(ctlnext,LBUTTON_UP);
}

//This is for when the edit window has focus and some one hits "Alt+B" for the
//Back button
void ctls3_edit.A_B()
{
   _nocheck _control ctlback;
   ctlback.call_event(ctlback,LBUTTON_UP);
}

defeventtab _java_bean_property_form;

static void FillInAttributeType()
{
   p_text = "String";
   _lbclear();
   _lbadd_item("String");
   _lbadd_item("int");
   _lbadd_item("long");
   _lbadd_item("boolean");
   _lbadd_item("byte");
   _lbadd_item("char");
   _lbadd_item("float");
   _lbadd_item("double");
   _lbtop();
}

void ctlok.on_create()
{
   ctlPropType.FillInAttributeType();
}

int ctlok.lbutton_up()
{
   PropName := ctlPropName.p_text;
   if (PropName=="") {
      ctlPropName._text_box_error("Property must have a name");
      return(1);
   }
   if (pos(" ",PropName)) {
      ctlPropName._text_box_error("Property name may not have spaces");
      return(1);
   }
   if (!isid_valid(PropName)) {
      ctlPropName._text_box_error("Property name must be a vaild identifier");
      return(1);
   }
   if (PropName=="") {
      ctlPropType._text_box_error("Property must have a type");
      return(1);
   }
   if (pos(" ",PropName)) {
      ctlPropType._text_box_error("Property type may not have spaces");
      return(1);
   }
   if (!isid_valid(PropName)) {
      ctlPropType._text_box_error("Property type must be a vaild identifier");
      return(1);
   }
    _nocheck _control ctls2_Attributes;
   wid := p_window_id;
   p_window_id=p_active_form.p_parent.ctls2_Attributes;
   save_pos(auto p);
   top();up();
   if (!search("^?"_escape_re_chars(PropName)"\t?@$","@r")) {
      p_window_id=wid;
      ctlPropName._text_box_error(nls("A property named '%s1' already exists",PropName));
      return(1);
   }
   restore_pos(p);
   p_window_id=wid;
   _param1=ctlPropType.p_text;
   _param2=PropName;
   p_active_form._delete_window(0);
   return(0);
}

/**
 * Adds a single filename or array of filenames to
 * the current project
 *
 * @param Filenames If Filenames is a string, one filename is added.
 *                  If it is an array, all elements in the array are
 *                  added.
 *
 * @param ProjectFilename
 *                  Name of project file to add fielname(s) to.
 *                  Defaults to _project_name
 *
 * @param projHandle 
 *                  Handle to project if _ProjectHandle() should not
 *                  be used.
 *
 * @return returns 0 if successful.
 */
int _AddFileToProject(typeless Filenames, _str ProjectFilename = _project_name, int projHandle = -1)
{
   se.util.MousePointerGuard hour_glass;

   _str FilenameList[];
   if (Filenames._varformat()==VF_LSTR) {
      FilenameList[0]=Filenames;
   }else if (Filenames._varformat()==VF_ARRAY) {
      FilenameList=Filenames;
   }
   int handle;
   if (projHandle <= 0) {
      handle=_ProjectHandle(ProjectFilename);
   } else {
      handle= projHandle;
   }
   _str RelFiles[];
   RelFilename := "";
   int i;
   for (i=0;i<FilenameList._length();++i) {
      RelFilename=_RelativeToProject(FilenameList[i]);
      int Node=_ProjectGet_FileNode(handle,RelFilename);
      if (Node<0) {
         RelFiles[RelFiles._length()]=RelFilename;
      } else {
         FilenameList._deleteel(i);
         --i;
      }
   }
   _ProjectAdd_Files(handle,RelFiles);
   int status=_ProjectSave(handle);
   if (status) {
      _message_box(nls("Could not update project file '%s'\n%s",ProjectFilename,get_message(status)));
      return(status);
   }
   if (!_IsWorkspaceAssociated(_workspace_filename)) {
      status=_WorkspacePutProjectDate();
      if (status) {
         _message_box(nls("Could not update project file '%s'\n%s",ProjectFilename,get_message(status)));
         return(status);
      }
   }
   #if __VERSION__ >=6.0
   _MaybeAddFilesToVC(FilenameList);
   #endif
   useThread := _is_background_tagging_enabled(AUTOTAG_WORKSPACE_NO_THREADS);
   AddFilesToTagFile(FilenameList, null, useThread);
   toolbarUpdateFilterList(ProjectFilename);
   call_list("_prjupdate_");
   return(0);
}

defeventtab _new_project_info_form;

void ctlok.on_create(_str HeaderInfo,_str HTMLInfo,
                     _str DialogCaption="",
                     bool HideProjectInfo=false)
{
   int oldHeight=ctltitle_label.p_height;
   ctltitle_label.p_caption=HeaderInfo;
   int newHeight=ctltitle_label.p_height;
   ctlproject_dir.p_y+=newHeight-oldHeight;
   ctlminihtml1.p_y+=newHeight-oldHeight;
   ctlproject_dir.p_caption="Project Directory:\n"_file_path(_project_name);
   if (HideProjectInfo) {
      ctlproject_dir.p_visible=false;
      int diff=(ctlproject_dir.p_y_extent)-(ctlminihtml1.p_y_extent);
      ctlminihtml1.p_height+=diff;
   }
   if (DialogCaption!="") {
      p_active_form.p_caption=DialogCaption;
   }
   ctlminihtml1._minihtml_UseDialogFont();
   ctlminihtml1.p_backcolor=0x80000022;
   ctlminihtml1.p_text="<nobr>"stranslate(HTMLInfo,"<br>","\n")"</nobr>";
}

ctlok.lbutton_up()
{
   p_active_form._delete_window(0);
}
