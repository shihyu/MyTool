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
#include "minihtml.sh"
#import "deupdate.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "recmacro.e"
#import "savecfg.e"
#import "cfg.e"
#import "saveload.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbdefault.e"
#import "toolbar.e"
#endregion

static const OI2TYPENAME= (' 'OI_FORM'=_form':+\
               ' 'OI_TEXT_BOX'=_text_box':+\
               ' 'OI_CHECK_BOX'=_check_box':+\
               ' 'OI_COMMAND_BUTTON'=_command_button':+\
               ' 'OI_RADIO_BUTTON'=_radio_button':+\
               ' 'OI_FRAME'=_frame':+\
               ' 'OI_LABEL'=_label':+\
               ' 'OI_LIST_BOX'=_list_box':+\
               ' 'OI_EDITOR'=_editor':+\
               ' 'OI_HSCROLL_BAR'=_hscroll_bar':+\
               ' 'OI_VSCROLL_BAR'=_vscroll_bar':+\
               ' 'OI_COMBO_BOX'=_combo_box':+\
               ' 'OI_PICTURE_BOX'=_picture_box':+\
               ' 'OI_IMAGE'=_image':+\
               ' 'OI_GAUGE'=_gauge':+\
               ' 'OI_SPIN'=_spin':+\
               ' 'OI_SSTAB'=_sstab':+\
               ' 'OI_SSTAB_CONTAINER'=_sstab_container':+\
               ' 'OI_MINIHTML'=_minihtml':+\
               ' 'OI_TREE_VIEW'=_tree_view':+\
               ' 'OI_SWITCH'=_switch':+\
               ' 'OI_TEXTBROWSER'=_textbrowser':+\
               ' ');

/** 
 * Opens a new buffer called "vusrobjs.e" and inserts Slick-C&reg; source code for 
 * all dialog box templates (forms) created by the user.  System dialog box 
 * templates are not inserted.
 * 
 * @return Returns 0 if successful.  Returns 1 if no templates are defined.  
 * Other errors are non-zero.
 * 
 * @see list_usersys_objects
 * @see list_sys_objects
 * 
 * @categories Form_Functions
 * 
 */
_command list_objects(_str args='', ...) name_info(','VSARG2_REQUIRES_MDI)
{
   UseTempViewNSave := arg(4)!="";
   UseTempViewNSave = true;

   form_name := "";
   option := "";
   form_category := "";
   parse args with form_name ',' option','form_category',';

   quiet := arg(2)!='';
   eraseifempty := !arg(3);   // Not used if INSERT option specified
 
   system_only := false;
   int exclude_mask=FF_SYSTEM;
   modified_only := false;
   track_file_date:=true;
   form_category=lowcase(form_category);
   _str temp_file=USEROBJS_FILE;
   if (form_category=='usersys') {
      system_only=true;
      exclude_mask=0;
      modified_only=true;
      temp_file=_getUserSysFileName();
      track_file_date=true;
   } else if (form_category=='sys') {
      temp_file=SYSOBJS_FILE;
      system_only=true;
      exclude_mask=0;
      modified_only=true;
      track_file_date=false;
   }

   index := 0;
   _str orig_temp_file=temp_file;
   form_name=strip(form_name);
   if ( form_name!='' ) {
      /* Since a specific name was given, insert just this macro. */
      index=find_index(form_name,OBJECT_TYPE);
      if ( ! index ) {
         popup_message(nls("Can't find template object '%s'",form_name));
         return(1);
      }
      _insert_form(index,0,3,form_name);
      return(0);
   }

   // If want to insert into current buffer.
   status := 0;
   temp_name := "";
   temp_view_id := 0;
   orig_view_id := 0;
   path := "";
   if ( option!='' ) {
      if ( upcase(strip(option))!='INSERT' ) {
         message(nls('Expecting INSERT option'));
         return(1);
      }
      if(!quiet) message(nls('Inserting template definitions...'));
   } else {
     path= _macro_path(temp_file:+_macro_ext);
 
     temp_name=path:+temp_file:+_macro_ext;
     if (UseTempViewNSave) {
        status=_open_temp_view(temp_name,temp_view_id,orig_view_id);
        if ( status) {
           if (status==FILE_NOT_FOUND_RC) {
              orig_view_id=_create_temp_view(temp_view_id);
              p_buf_name=temp_name;
              p_UTF8=_load_option_UTF8(p_buf_name);
           } else {
              _message_box(nls("Unable to open '%s'.  "get_message(status),temp_name));
              return(status);
           }
        }
     } else {
        status=edit('+q '_maybe_quote_filename(temp_name),EDIT_NOADDHIST|EDIT_NOSETFOCUS);
        if (status && status!=NEW_FILE_RC) {
           _message_box(nls("Unable to open '%s'.  "get_message(status),temp_name));
           return(status);
        }
     }
     _lbclear();
     if(!quiet) message(nls('building template definition file...'));
   }

   typeless ff='';
   name := "";
   index=name_match('',1,OBJECT_TYPE);
   for (;;) {
      if ( ! index ) break;

      /* Don't list source code for forms marked as system forms. */
      ff=name_info(index);
      if (!isinteger(ff)) ff=0;
      name=name_name(index);
      if (substr(name,1,1)=='-') {
         ff|=FF_SYSTEM;
      }
      //  _temp(ddd)_form  don't list source
      if (substr(name,1,5)=="-temp") {
         number := "";
         parse name with "-temp" number"-form";
         if (number=="" || isinteger(number)) {
            index=name_match('',0,OBJECT_TYPE);
            continue;
         }
      }
      // Treat toolbars like user defineable stuff.
      if ((ff & FF_SYSTEM) && _tbIsCustomizeableToolbar(index)) {
         // DJB 08-22-2006
         // Only insert source for toolbars that user has modified
         // such that it no longer matches the default layout.
         if (_tbIsModifiedToolbar(name_name(index))) {
            ff&=~FF_SYSTEM;
         }
      }
      if ((!system_only || (ff & FF_SYSTEM)) && !(ff & exclude_mask) &&
          (!modified_only || (ff & FF_MODIFIED))) {
          form_name=stranslate(name,'_','-');
          if ( form_name != "_tbunified_form" || _isMac()) {
             if(!quiet) message('Inserting template source for 'form_name'...');
             _insert_form(index,0,3,form_name);
          }
      }
      index=name_match('',0,OBJECT_TYPE);
   }

   // IF created temp file
   if ( option=='' ) {
      if (!p_noflines) {
         p_modify=false;
         if (UseTempViewNSave) {
            _delete_temp_view(temp_view_id);
         } else {
            quit();
         }
         if(!quiet) message(nls('No templates defined'));
         if (eraseifempty) {
            delete_file(temp_name);
            // Delete Pcode file too
            delete_file(temp_name'x');
         }
         // Indicate that no file was created
         return(1);
      } else {
         insert_line("");
         insert_line("defmain()");
         insert_line("{");
         if (orig_temp_file==USEROBJS_FILE) {
            insert_line('   _config_modify_flags(CFGMODIFY_RESOURCE);');
         }
         insert_line("}");
         clear_message();
         top();up();
         insert_line("#include 'slick.sh'");
      }
   } else {
      if(!quiet) clear_message();
   }
   if (UseTempViewNSave) {
      status=_save_config_file();
      _str buf_name=p_buf_name;
      _delete_temp_view(temp_view_id);
      if (status) {
         _message_box(nls("Unable to save '%s'.  "get_message(status),buf_name));
         return(status);
      }
      if (track_file_date) {
         _config_file_dates:[_file_case(temp_name)]=_file_date(temp_name,'B');
      }
      return(0);
   }
   return(0);

}
void _insert_form(int index, int indent, int add_indent, _str form_name)
{
   form_name=translate(form_name,'_','-');
   if (!(index & 0xffff0000)) {
      index=index << 16;
   }
   if (index.p_object==OI_MENU) {
      _insert_menu_source(index,indent,add_indent,form_name);
      return;
   }
   int object=index.p_object;
   if (object==OI_LIST_BOX && index.p_multi_select==MS_EDIT_WINDOW) {
      object=OI_EDITOR;
   }
   _str type_name=eq_name2value(object,OI2TYPENAME);
   insert_line(substr('',1,indent):+type_name' 'index.p_name' {');
   _insert_properties(index,indent+add_indent,form_name);
   int child=index.p_child;
   if (child) {
      int first_child=child;
      for (;;) {
         _insert_form(child,indent+add_indent,add_indent,form_name);
         child=child.p_next;
         if (child==first_child) break;
      }
   }
   insert_line(substr('',1,indent)'}');
}
static void _insert_properties(int index, int indent, _str form_name)
{
   switch (index.p_object) {
   case OI_FORM:
      _insert_form_props(index,indent,form_name);
      break;
   case OI_TEXT_BOX:
      _insert_text_props(index,indent,form_name);
      break;
   case OI_COMMAND_BUTTON:
      _insert_command_props(index,indent,form_name);
      break;
   case OI_CHECK_BOX:
      _insert_check_props(index,indent,form_name);
      break;
   case OI_RADIO_BUTTON:
      _insert_radio_props(index,indent,form_name);
      break;
   case OI_FRAME:
      _insert_frame_props(index,indent,form_name);
      break;
   case OI_LABEL:
      _insert_label_props(index,indent,form_name);
      break;
   case OI_LIST_BOX:
      if (index.p_multi_select==MS_EDIT_WINDOW) {
         _insert_editor_props(index,indent,form_name);
      } else {
         _insert_list_props(index,indent,form_name);
      }
      break;
   case OI_EDITOR:
      _insert_editor_props(index,indent,form_name);
      break;
   case OI_TREE_VIEW:
      _insert_tree_props(index,indent,form_name);
      break;
   case OI_MINIHTML:
      _insert_minihtml_props(index,indent,form_name);
      break;
   case OI_COMBO_BOX:
      _insert_combo_props(index,indent,form_name);
      break;
   case OI_IMAGE:
      _insert_image_props(index,indent,form_name);
      break;
   case OI_PICTURE_BOX:
      _insert_picture_props(index,indent,form_name);
      break;
   case OI_HSCROLL_BAR:
      _insert_scroll_props(index,indent,form_name);
      break;
   case OI_VSCROLL_BAR:
      _insert_scroll_props(index,indent,form_name);
      break;
   case OI_GAUGE:
      _insert_gauge_props(index,indent,form_name);
      break;
   case OI_SPIN:
      _insert_spin_props(index,indent,form_name);
      break;
   case OI_SSTAB:
      _insert_sstab_props(index,indent,form_name);
      break;
   case OI_SSTAB_CONTAINER:
      _insert_sstab_container_props(index,indent,form_name);
      break;
   case OI_SWITCH:
      _insert_switch_props(index,indent,form_name);
      break;
   case OI_TEXTBROWSER:
      _insert_textbrowser_props(index,indent,form_name);
      break;
   }
}
