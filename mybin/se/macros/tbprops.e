////////////////////////////////////////////////////////////////////////////////////
// $Revision: 49173 $
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
#include "toolbar.sh"
#include "dockchannel.sh"
#import "debug.sh"
#import "bind.e"
#import "complete.e"
#import "dlgman.e"
#import "guiopen.e"
#import "keybindings.e"
#import "listbox.e"
#import "main.e"
#import "options.e"
#import "optionsxml.e"
#import "picture.e"
#import "qtoolbar.e"
#import "recmacro.e"
#import "saveload.e"
#import "stdprocs.e"
#import "tbcontrols.e"
#import "tbview.e"
#import "toolbar.e"
#import "vlstobjs.e"
#endregion

_TOOLBAR def_toolbartab[];

#define USER_FORM_PREFIX "tbform"


/**
 * Callback used by options dialog to export toolbars created by this user.
 * 
 * @param file                path where export files are being saved.  If we 
 *                            write info to a file there, we will change this to
 *                            the name of the file (w/o path).
 * @param args                any arguments we want saved, in this case the 
 *                            toolbar flags for each user-created toolbar.
 * 
 * @return _str               any errors encountered
 */
_str _user_created_toolbars_export_settings(_str &file, _str &args)
{
   filenameOnly := 'userToolbars.e';
   error := '';
   args = '';

   // open up a temp view for this
   tempView := 0;
   origView := _create_temp_view(tempView);
   if (origView <= 0) {
      error = 'Unable to open temp view.';
   } else {
      // insert this at the top so it will run properly
      insert_line('#include "slick.sh"');
      insert_line('');

      // stick this at the bottom - we're making a batch macro, you know
      insert_line('defmain()');
      insert_line('{');
      insert_line('_config_modify_flags(CFGMODIFY_RESOURCE);');
      insert_line('}');
      insert_line('');

      // now insert the code for each user-created toolbar
      found := false;
      for (i := 0; i < def_toolbartab._length(); ++i) {
         _TOOLBAR *ptb = &def_toolbartab[i];
         index := find_index(ptb -> FormName, oi2type(OI_FORM));
      
         if (index) {
            typeless flags = name_info(index);
            if (!isinteger(flags)) flags = 0;
      
            // if this is not a system toolbar, then the user 
            // must have come up with it
            if ((flags & FF_SYSTEM) == 0) {
               found = true;
               list_objects(ptb -> FormName);

               // add these flags to the list of arguments
               args :+= ptb -> FormName'=' ptb -> tbflags',';
            }
      
         }
      }
      
      // did we write anything?  save it!
      if (found) {
         if (_save_file(maybe_quote_filename(file :+ filenameOnly)) < 0) error = 'Error saving objects file.';

         // change this argument to just the filename
         file = filenameOnly;
      } 
      
      p_window_id = origView;
      _delete_temp_view(tempView, true);
   }

   return error;
}

_str _user_created_toolbars_import_settings(_str file, _str args)
{
   error := importUserObjectsFile(file);

   if (error == '') {
      // then we need to make some updates to flags and such
      _str tbArray[];
      split(args, ',', tbArray);
   
      for (i := 0; i < tbArray._length(); i++) {
         typeless formName = '', tbflags = '';
         parse tbArray[i] with formName '=' tbflags;
         if (formName == '') continue;
   
         addNewToolbar(null, formName, tbflags);
      }
   }

   return error;
}

static int update_picture_for_control(int wid)
{
   switch (wid.p_object) {
   case OI_PICTURE_BOX:
   case OI_IMAGE:
      int pic_index = wid.p_picture;
      if (pic_index > 0) {
         _str filename = name_name(pic_index);
         if (filename != '') {
            _update_picture(pic_index, filename);
         }
      }
      break;
   case OI_SSTAB_CONTAINER:
      return 1;
   }
   return 0;
}

_command void tbReloadBitmaps(_str bitmap_size="") name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_LINEHEX/*|VSARG2_NOEXIT_SCROLL*/)
{
   // if they give default size option, use default setting
   if (bitmap_size == "") {
      bitmap_size = def_toolbar_pic_size;
   }

   // validate the bitmap size
   switch (bitmap_size) {
   case '16':
   case '24':
   case '32':
   case '48':
      bitmap_size = bitmap_size'x'bitmap_size;
      break;
   case '16x16':
   case '24x24':
   case '32x32':
   case '48x48':
      break;
   default:
      _message_box("Bitmaps must be 16x16, 24x24, or 32x32.");
      return;
   }
   if( bitmap_size!=def_toolbar_pic_size ) {
      def_toolbar_pic_size=bitmap_size;
   }

   // reload all toolbar button bitmaps
   mou_hour_glass(1);
   int pic_index = name_match("",1,PICTURE_TYPE);
   while( pic_index>0 ) {
      _str filename = name_name(pic_index);
      if( filename!="" && pos("bb",lowcase(filename))==1 ) {
         _update_picture(pic_index, filename);
      }
      pic_index=name_match("",0,PICTURE_TYPE);
   }

   // refresh the displayed toolbars
   int i, n=def_toolbartab._length();
   for( i=0;i<n;++i ) {
      int form_wid = _find_formobj(def_toolbartab[i].FormName,"n");
      if( form_wid>0 ) {
         _tbRedisplay(form_wid);
      }
   }
   mou_hour_glass(0);
}

/**
 * <p>Displays the Toolbar Customization dialog box.  This dialog box is 
 * used to add and remove buttons from a toolbar.  You can also create 
 * new toolbars and choose which toolbars you want visible.</p>
 * 
 * <p>The following toolbars are available:</p>
 * 
 * <dl>
 * <dt>Project</dt><dd>Default toolbar display at left of MDI frame.  Includes 
 * tabs for symbol browser, project files, buffers, and disk files.</dd>
 * 
 * <dt>Output</dt><dd>Default toolbar display at bottom of MDI frame.
 * Includes tabs for build output, multi-file search 
 * output, and tag symbols for word at th cursor.</dd>
 * 
 * <dt>Standard</dt><dd>Default toolbar displayed at top of MDI frame.  
 * Includes buttons for file open, file save, clipboard 
 * operations,  searching, help, version control, and 
 * displaying the current file in a web browser.</dd>
 * 
 * <dt>Tools</dt><dd>Includes buttons for the source code beautifier, 
 * difference editor, 3-way merge, find file, calculator, 
 * command prompt, spell checker, and hex mode 
 * toggle.</dd>
 * 
 * <dt>Edit</dt><dd>Includes buttons for uppercase, lowercase, shift 
 * selection left, shift selection right, indent, unindent, 
 * tabify selection, untabify selection, and match 
 * parenthesis.</dd>
 * 
 * <dt>Selective Display</dt><dd>   
 *    Includes selective display buttons for function 
 * headings, hide code block, selective display dialog 
 * box, hide selected lines, and show all.</dd>
 * </dl>
 * 
 * @categories Miscellaneous_Functions
 * 
 */ 
_command void toolbars(_str formName='1') name_info(OBJECT_ARG','MARK_ARG2|NCW_ARG2)
{
   // '1' shows the customize toolbars form with the Categories tab up
   config('_toolbars_prop_form', 'D', formName);
}

_command void customize_tool_windows(_str formName='0') name_info(',')
{
   // '0' shows the customize toolbars form with the Toolbars tab up
   config('_tool_windows_prop_form', 'D', formName);
}

_command void tbControlProperties(...) name_info(FORM_ARG',')
{
   int wid = arg(1);
   if( isinteger(wid) && _iswindow_valid(wid) ) {
      show("-modal _ToolBarProperties_form",wid);
   }
}

//
// _ToolBarProperties_form
//

#define PropertiesOfWid ctlok.p_user
#define OriginalCommand ctlcommandlabel.p_user
#define OriginalMessage ctlmessage.p_user
#define OriginalBitmap  ctlbitmap.p_user
#define OriginalCaption ctlcaption.p_user
#define PropertiesEditorCtl ctlbind.p_user

defeventtab _ToolBarProperties_form;
void ctlcommand.on_change(int reason)
{
   if( p_text=="" ) {
      _auto_enable.p_enabled=0;
      return;
   }
   boolean enabled;
   _str cmdname;
   _str args='';
   parse p_text with cmdname args;
   int index=find_index(cmdname,COMMAND_TYPE);
   if( index!=0 && 0==(name_type(index) & DLLCALL_TYPE) ) {
      enabled=true;
   } else {
      enabled=false;
   }
   if( enabled!=_auto_enable.p_enabled ) {
      _auto_enable.p_enabled=enabled;
   }

   if (!enabled) {
      _b2kbound_to.p_caption='';
      ctlbind.p_enabled=false;
   } else if (args!='') {
      _b2kbound_to.p_caption='Commands with arguments can not be bound to a key.';
      ctlbind.p_enabled=false;
   } else {
      _macro('m',0);
      _b2kbound_to.p_caption=PropertiesEditorCtl.where_is(cmdname,1);
      _macro('m',_macro('s'));
   }
}

void _auto_enable.lbutton_up()
{
   _str cmdname;
   parse ctlcommand.p_text with cmdname .;
   show('-modal _autoenable_form',cmdname);
}

void ctlbind.lbutton_up()
{
   _macro('m',0);
   _str cmdname;
   parse ctlcommand.p_text with cmdname .;
   gui_bind_command(cmdname);
   _b2kbound_to.p_caption=PropertiesEditorCtl.where_is(cmdname,1);
   _macro('m',_macro('s'));
}

void ctlcommand.on_drop_down(int reason)
{
   if( p_user=="" ) {
      _insert_name_list(COMMAND_TYPE);
      _lbtop();
      _lbsort('i');
      p_user=1;
   }
}

void ctlok.lbutton_up()
{
   int wid = PropertiesOfWid;

   // check for changes to this button
   if( OriginalCommand!=ctlcommand.p_text ||
       OriginalMessage!=ctlmessage.p_text ||
       (OriginalBitmap!=ctlbitmap.p_text && !(wid.p_object==OI_IMAGE &&wid.p_caption!=""))||
       (OriginalCaption!=ctlcaption.p_text && ctlcaption.p_enabled) ) {

      // load up the bitmap into the button
      _str name=strip(ctlbitmap.p_text,'B','"');
      if( !file_eq(name_name(ctlbitmappic.p_picture),name) ) {
         if(load_bitmap(name)) {
            return;
         }
      }

      // make sure our window is valid
      if( isinteger(wid) && _iswindow_valid(wid) ) {
         int child=wid.p_active_form.p_child;
         int first_child=child;
         int count=1;
         for( ;;++count ) {
            if( child==wid ) {
               break;
            }
            child=child.p_next;
            if( child==first_child ) {
               p_active_form._delete_window(0);
            }
         }

         int index=find_index(wid.p_active_form.p_name,oi2type(OI_FORM));
         if( index!=0 ) {
            first_child=child=index.p_child;
            while( --count ) {
               child=child.p_next;
               if( child==0 || child==first_child ) {
                  p_active_form._delete_window(0);
                  return;
               }
            }

            // make the changes
            child.p_command=ctlcommand.p_text;
            wid.p_command=ctlcommand.p_text;
            if( wid.p_object==OI_IMAGE ) {
               child.p_message=ctlmessage.p_text;
               wid.p_message=ctlmessage.p_text;
               if( wid.p_object==OI_IMAGE && wid.p_caption=="" ) {
                  child.p_picture=ctlbitmappic.p_picture;
                  wid.p_picture=ctlbitmappic.p_picture;

               } else if( ctlcaption.p_enabled ) {
                  child.p_caption=ctlcaption.p_text;
                  wid.p_caption=ctlcaption.p_text;
               }
               wid.p_active_form._tbResizeButtonBar(wid.p_DockingArea);
               if( wid.p_DockingArea!=0 ) {
                  _mdi._bbdockRefresh(wid.p_DockingArea);
               }
            }
            _set_object_modify(index);

            // see if the toolbar properties form is currently open
            index = _find_formobj('_toolbars_prop_form',  'n');
            if( !index ) {
               // if not, we are just changing properties of this button, 
               // which we need to make sure and save
               checkForChangesToToolbars();
            }

         }
      }
   }
   p_active_form._delete_window(0);
}

void ctlcaption.on_change()
{
   if( ctlcaption.p_enabled ) {
      ctlok.p_enabled=ctlcaption.p_text!="";
   }
}

void ctlok.on_create()
{
   _KillToolButtonTimer();
   PropertiesEditorCtl = (_no_child_windows())? VSWID_HIDDEN : _mdi.p_child;

   typeless wid = arg(1);
   PropertiesOfWid=wid;
   if( isinteger(wid) && _iswindow_valid(wid) ) {
      if( wid.p_object==OI_IMAGE ) {
         ctlcommand.p_text=wid.p_command;
         ctlmessage.p_text=wid.p_message;
         if( wid.p_caption!="" ) {
            ctlbitmapbrowse.p_enabled=ctlbitmap.p_enabled=ctlbitmaplabel.p_enabled=0;
            ctlcaptionlabel.p_enabled=ctlcaption.p_enabled=true;
            ctlcaption.p_text=wid.p_caption;

         } else {
            ctlbitmappic.p_picture=wid.p_picture;
            ctlbitmap.p_text=name_name(ctlbitmappic.p_picture);
         }

      } else {
         ctlmessage.p_enabled=ctlmessagelabel.p_enabled=0;
         ctlbitmapbrowse.p_enabled=ctlbitmap.p_enabled=ctlbitmaplabel.p_enabled=0;
      }
   }
   OriginalCommand=ctlcommand.p_text;
   OriginalMessage=ctlmessage.p_text;
   OriginalBitmap=ctlbitmap.p_text;
   OriginalCaption=ctlcaption.p_text;

   _ToolBarProperties_form_initial_alignment();
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ToolBarProperties_form_initial_alignment()
{
   rightAlign := ctlmessage.p_x + ctlmessage.p_width;
   sizeBrowseButtonToTextBox(ctlcommand.p_window_id, ctlcommand_menu.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(ctlbitmap.p_window_id, ctlbitmapbrowse.p_window_id, 0, rightAlign);
}

static int load_bitmap(_str result)
{
   result=strip(result,'B','"');
   /* Find existing picture. */
   int index= _update_picture(-1,result);
   if( index<0 ) {
      p_window_id=ctlbitmap;
      _set_sel(1,length(p_text)+1);_set_focus();
      if( index==FILE_NOT_FOUND_RC ) {
         _message_box(nls("File %s not found.\n\nBitmap file must be in search PATH",result));
         return 1;
      }
      _message_box(get_message(index));
      return 1;

   } else {
      ctlbitmappic.p_picture=index;
      ctlbitmap.p_text=name_name(index);
      ctlbitmap.p_selected=false;
   }
   return 0;
}

void ctlbitmap.on_change()
{
   _str name=strip(p_text,'B','"');
   ctlbitmappic.p_picture=find_index(name,PICTURE_TYPE);
}

void ctlbitmapbrowse.lbutton_up()
{
   // Open existing .bmp or .ico file
   typeless result=_OpenDialog('-modal',
                      'Open picture',
#if __UNIX__
                      '*.xpm;*.bmp;*.ico',
                      "Images (*.xpm;*.bmp;*.ico),Pixmaps (*.xpm),Bitmaps (*.bmp),Icons (*.ico),All Files ("ALLFILES_RE")",
#else
                      '*.bmp;*.ico',
                      "Images (*.bmp;*.ico),Bitmaps (*.bmp),Icons (*.ico),All Files ("ALLFILES_RE")",
#endif
                      OFN_FILEMUSTEXIST,
                      'bmp',      // Default extensions
                      '',         // Initial filename
                      '',         // Initial directory
                      'bmp'       // Retrieve name
                      );
   if( result!="" ) {
      load_bitmap(result);
   }
   return;
}

//
// _ToolBarNew_form
//

defeventtab _ToolBarNew_form;

void ctlformname.on_drop_down(int reason)
{
   if (p_user=='') {

      //match_fun_index=match_prefix2index(completion,match_flags,multi_select, last_arg2)
      _str match_name=_form_match('tb',1);
      for (;;) {
         if (match_name=='') {
            break;
         }
         _lbadd_item(match_name);
         match_name=_form_match('',0);
      }
      match_name=_form_match('_tb',1);
      for (;;) {
         if (match_name=='') {
            break;
         }
         _lbadd_item(match_name);
         match_name=_form_match('',0);
      }
      _lbsort('e');
      _UnderScoresToBottom();
      top();

      p_user=1;
   }
}
ctladvanced.lbutton_up()
{
   _dmmoreless();
}
void ctlok.on_create()
{
   _str caption='';
   int i,index;
   for (i=1;;++i) {
      caption="User Toolbox "i;
      if(!_tbFindCaption(caption,index)) {
         break;
      }
   }
   ctlname.p_text=caption;

   ctladvanced._dmless();
   int tbflags=(TBFLAG_NEW_TOOLBAR)&(TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED|TBFLAG_SIZEBARS);
   ctladdcontrols.p_value=(tbflags&TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED);
}
void ctlok.lbutton_up()
{
   _str formname=ctlformname.p_text;
   if (ctlname.p_text=="" && formname=="") {
      _message_box("No toolbar name specified");
      ctlname._set_focus();
      return;
   }
   int index=0;
   if (formname!="") {
      index=find_index(formname,oi2type(OI_FORM));
      if (!index) {
         _message_box("Form name not found");
         ctlformname._set_focus();
         return;
      }
      typeless ff=name_info(index);
      if (!isinteger(ff)) ff=0;
      if (ff & FF_SYSTEM) {
         // User can destroy a caption.
         // AND.  Ok and cancel may do weird stuff.
         // AND.  Who knows what might happen.
         _message_box("System dialog boxes are not allowed as toolbars");
         ctlformname._set_focus();
         return;
      }
   }
   _param1=ctlname.p_text;
   _param2=index;
   int tbflags=(TBFLAG_NEW_TOOLBAR);
   if (ctladdcontrols.p_value) {
      tbflags|=TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED;
   } else {
      tbflags&=~TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED;
   }
   _param3=tbflags;
   p_active_form._delete_window(1);
}

#define ORIGINAL_SHOWTOOLTIPS ctltooltips.p_user
#define ORIGINAL_TOOLTIPSDELAY ctltooltipdelay.p_user
#define ORIGINAL_HIDE ctlhide.p_user

defeventtab _toolbars_prop_form;

#region Options Dialog Helper Functions

void _toolbars_prop_form_init_for_options(_str formNameOrTab = '')
{
   ctlclose.p_visible = false;

   if( formNameOrTab != '' ) {
      if( isinteger(formNameOrTab) ) {
         _toolbars_prop_sstab.p_ActiveTab = (int)formNameOrTab;
      } else {
         selectToolbar(formNameOrTab);
      }
   }
}

void _toolbars_prop_form_save_settings(_str (&settings):[])
{
   // toolbar button size and spacing
   settings:["ctl_buttons_small.p_value"] = ctl_buttons_small.p_value;
   settings:["ctl_buttons_large.p_value"] = ctl_buttons_large.p_value;
   settings:["ctl_buttons_medium.p_value"] = ctl_buttons_medium.p_value;

   // spacing
   settings:["ctl_button_hspace.p_text"] = ctl_button_hspace.p_text;
}

boolean _toolbars_prop_form_is_modified(_str settings:[])
{
   // tool tips stuff
   if (ORIGINAL_SHOWTOOLTIPS!=ctltooltips.p_value) return true;
   if (ORIGINAL_TOOLTIPSDELAY != ctltooltipdelay.p_text) return true;   
   if (ORIGINAL_HIDE!=ctlhide.p_value) return true;
   if (ctlunified.p_value!=_tbLastUnifiedToolbarState()) return true;

   // toolbar button size and spacing
   if (settings:["ctl_buttons_small.p_value"] != ctl_buttons_small.p_value) return true;
   if (settings:["ctl_buttons_large.p_value"] != ctl_buttons_large.p_value) return true;
   if (settings:["ctl_buttons_medium.p_value"] != ctl_buttons_medium.p_value) return true;

   // spacing
   if (settings:["ctl_button_hspace.p_text"] != ctl_button_hspace.p_text) return true;

   return false;
}

boolean _toolbars_prop_form_apply()
{
   int fid = p_active_form; 

   fid._tbPropsShowControls( ctlcatlist.p_line - 1 ); 

   if (ORIGINAL_SHOWTOOLTIPS!=ctltooltips.p_value) {
      _default_option(VSOPTION_SHOWTOOLTIPS,ctltooltips.p_value);
      _config_modify_flags(CFGMODIFY_OPTION);
   }
   if (ORIGINAL_HIDE!=ctlhide.p_value) {
      def_hidetoolbars=ctlhide.p_value!=0;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (ORIGINAL_TOOLTIPSDELAY != ctltooltipdelay.p_text){
      _default_option(VSOPTION_TOOLTIPDELAY,(int)ctltooltipdelay.p_text intdiv 100);
      _config_modify_flags(CFGMODIFY_OPTION);
   }

   _tbLastUnifiedToolbarState(ctlunified.p_value);
  // _tbSetUnifiedToolbar(ctlunified.p_value); // leave for now

   result := fid.okToolbarButtonOptions();
   if (result) return false;

   return true;
}

#endregion Options Dialog Helper Functions

void _toolbars_prop_form.on_destroy()
{
   value := _toolbars_prop_sstab.p_ActiveTab;
   _append_retrieve( _toolbars_prop_sstab, value );

   // save which toolbar was active, so we can pick it again
   item := list1._lbget_text();
   _TOOLBAR *ptb = _tbFindCaption(item, auto index);
   _append_retrieve(0, ptb -> FormName, p_active_form.p_name'.list1');

   checkForChangesToToolbars();
   _tbPropsSetupToolbars(0);
}

void ctltooltips.lbutton_up()
{
   ctltooltipdelay.p_next.p_enabled=ctltooltipdelay.p_enabled=(ctltooltips.p_value!=0);
}

//Added this so that double clicking in the list will toggle a toolbar on/off
void list1.lbutton_double_click()
{
   ctlvisible.p_value=(int)(!ctlvisible.p_value);
   ctlvisible.call_event(ctlvisible,LBUTTON_UP);
}

void _tbResetToDefaults(_str FormName)
{
   int tbIndex;
   if ( !_TBDefaultsSupported(FormName) ) return;

   TBCONTROL tempList[];
   _tbGetDefaultToolbarControlList(FormName, tempList);
   _tbApplyControlList(FormName, tempList);

   // remove any changes from the xml file
   resetToolbarXMLChanges(FormName);
}


void ctlreset.lbutton_up()
{
   _str caption=list1._lbget_text();
   _TOOLBAR *ptb;
   int index;
   ptb=_tbFindCaption(caption,index);
   if (!ptb) return;
   _tbResetToDefaults(ptb->FormName);
}

void ctlrename.lbutton_up()
{
   typeless result = show('-modal _textbox_form',
                          'New Toolbar Name',   // Form caption
                          0,  //flags
                          '', //use default textbox width
                          '', //Help item.
                          '', //Buttons and captions
                          '', //Retrieve Name
                          'New Toolbar Name:'list1._lbget_text());
   if( result=="" ) {
      return;
   }
   _str newname=_param1;

   int index;
   if( _tbFindCaption(newname,index) ) {
      _message_box("This toolbar name already exists");
      return;
   }
   _TOOLBAR *ptb;
   _str caption=list1._lbget_text();
   ptb=_tbFindCaption(caption,index);
   if( !ptb ) return;
   int wid = _tbIsVisible(ptb->FormName);
   if( wid!=0 ) {
      wid.p_caption=newname;
   }
   index=find_index(ptb->FormName,oi2type(OI_FORM));
   if( index!=0 ) {
      index.p_caption=newname;
      _set_object_modify(index);
   }

   list1._lbset_item(newname);
   list1._lbselect_line();
}

void ctldelete.lbutton_up()
{
   _str caption=list1._lbget_text();
   int id=_message_box(nls("Are you sure you want to delete toolbar '%s'?",caption), '', MB_YESNOCANCEL|MB_ICONQUESTION);
   if (id!=IDYES) {
      return;
   }
   _TOOLBAR *ptb;

   int index;
   caption=list1._lbget_text();
   ptb=_tbFindCaption(caption,index);
   if (!ptb) return;
   int wid = _tbIsVisible(ptb->FormName);
   if (wid) {
      tbClose(wid);
   }
   if (substr(ptb->FormName,1,length(USER_FORM_PREFIX))==USER_FORM_PREFIX) {
      index=find_index(ptb->FormName,oi2type(OI_FORM));
      if (index) {
         delete_name(index);
      }
   }
   _config_modify_flags(CFGMODIFY_SYSRESOURCE|CFGMODIFY_RESOURCE);
   int i;
   _tbFind2(ptb->FormName,i);
   def_toolbartab._deleteel(i);
   list1._lbdelete_item();
   list1._lbselect_line();
   list1.call_event(CHANGE_SELECTED,list1,ON_CHANGE,'');
}
void ctlnew.lbutton_up()
{
   int orig_form_wid=p_active_form;
   typeless result=show("-modal _ToolBarNew_form");
   if (result!="") {

      int index=0;
      if (_param1!="") {
         // Make sure this title is not already used.
         if(_tbFindCaption(_param1,index)) {
            _message_box("This toolbar name already exists");
            return;
         }
      }
      typeless linenum;
      _str caption=_param1;
      _TOOLBAR *ptb=null;
      // Have index to form?
      _str FormName="";
      index=_param2;
      if (index) {
         FormName=_param2.p_name;
         ptb=_tbFind2(FormName,linenum);
         if (_param1!="") {
            index.p_caption=_param1;
         }
         caption=index.p_caption;
         index.p_tool_window=true;
         index.p_CaptionClick=true;
         index.p_border_style=BDS_SIZABLE;
         index.p_eventtab2=find_index("_qtoolbar_etab2",EVENTTAB_TYPE);
         _set_object_modify(index);
      }

      if (FormName=="") {
         int i;
         for (i=1;;++i) {
            FormName=USER_FORM_PREFIX:+i;
            index=find_index(FormName,oi2type(OI_FORM));
            if (!index) break;
         }
         
         int form_wid=_create_window(OI_FORM,orig_form_wid,"",0,0,2000,900,CW_PARENT|CW_HIDDEN,BDS_SIZABLE);
         form_wid.p_name=FormName;
         form_wid.p_caption=_param1;
         caption=form_wid.p_caption;
         form_wid.p_tool_window=true;
         form_wid.p_CaptionClick=true;
         form_wid.p_eventtab2=find_index("_qtoolbar_etab2",EVENTTAB_TYPE);
         int status=form_wid._update_template();
         form_wid._delete_window();
         _set_object_modify(status);
      }

      flags := _param3;
      if (ptb) {
         tbflags := ptb->tbflags&~(TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED|TBFLAG_SIZEBARS);
         flags |= tbflags;
      }
      addNewToolbar(ptb, FormName, flags);

      p_window_id=orig_form_wid;
      list1._lbclear();
      list1.tbListBoxAddToolbars(FormName, TBT_TOOLBAR);
      list1._lbsort();
      list1._lbsearch(caption);
      list1._lbselect_line();
      list1.call_event(CHANGE_SELECTED,list1,ON_CHANGE,'');
      ctlvisible.p_value=1;
      ctlvisible.call_event(ctlvisible,LBUTTON_UP);

   }
}

void addNewToolbar(_TOOLBAR *ptb, _str FormName, int flags)
{
   if (!ptb) {
      ptb=&def_toolbartab[def_toolbartab._length()];
      ptb->restore_docked=false;
      ptb->show_x=0;
      ptb->show_y=0;
      ptb->show_width=0;
      ptb->show_height=0;
   
      ptb->docked_area=0;
      ptb->docked_row=0;
      ptb->docked_x=0;
      ptb->docked_y=0;
      ptb->docked_width=0;
      ptb->docked_height=0;
   
      ptb->tabgroup=0;
      ptb->tabOrder= -1;
   
      ptb->auto_width=0;
      ptb->auto_height=0;  

      flags |= TBFLAG_NEW_TOOLBAR;
   }

   ptb->FormName=FormName;
   ptb->tbflags = flags;
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void ctlallowdocking.lbutton_up()
{
   _str caption = list1._lbget_text();
   int index;
   _TOOLBAR* ptb = _tbFindCaption(caption,index);
   if( !ptb ) {
      return;
   }

   // IMPORTANT toggle the visible tool window BEFORE
   // you change the entry in def_toolbartab because
   // tbDockableToggle checks it too.
   _str FormName = ptb->FormName;
   int wid = _find_formobj(FormName);
   if( wid>0 ) {
      tbDockableToggle(wid);
   }

   if( p_value!=0 ) {
      ptb->tbflags |= TBFLAG_ALLOW_DOCKING;
   } else {
      ptb->tbflags &= ~(TBFLAG_ALLOW_DOCKING);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void ctlontop.lbutton_up()
{
   _str caption=list1._lbget_text();
   _TOOLBAR *ptb;
   int index;
   ptb=_tbFindCaption(caption,index);
   if( !ptb ) {
      return;
   }
   if( p_value!=0 ) {
      ptb->tbflags |= TBFLAG_ALWAYS_ON_TOP;
   } else {
      ptb->tbflags &= ~TBFLAG_ALWAYS_ON_TOP;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
   int wid = _tbIsVisible(ptb->FormName);
   // Make form visible?
   if( wid!=0 && wid.p_DockingArea==0 ) {
      tbClose(wid);
      tbShow(ptb->FormName);
   }
}

void ctlvisible.lbutton_up()
{
   _str caption=list1._lbget_text();
   _TOOLBAR *ptb;
   int index;
   ptb=_tbFindCaption(caption,index);
   if( !ptb ) {
      return;
   }
   int wid = _tbIsVisible(ptb->FormName);
   // Make form visible?
   if( p_value!=0 ) {

      if( wid==0 ) {
         tbShow(ptb->FormName);
      }

   } else {

      if( wid!=0 ) {
         tbClose(wid);
      }
   }
}

void list1.on_change(int reason)
{
   typeless ff;
   if( reason==CHANGE_SELECTED ) {
      _str item = _lbget_text();
      int index = 0;
      _TOOLBAR *ptb = _tbFindCaption(item,index);
      if( ptb ) {
         // If this is a system dialog box
         ff=name_info(index);
         if( !isinteger(ff) ) {
            ff=0;
         }

         boolean enable = 0==(ff & FF_SYSTEM);
         ctldelete.p_enabled=ctlrename.p_enabled=enable;
         if( 0!=(ptb->tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED) ) {
            ctlreset.p_enabled=!enable;
         } else {
            ctlreset.p_enabled=0;
         }

         setControlsForSelectedToolBar(ptb);

      } else {
         message("Toolbar not found?");
      }
   }
}

static void setControlsForSelectedToolBar(_TOOLBAR * ptb)
{
   int wid = _tbIsVisible(ptb->FormName);
   if( wid!=0 ) {
      ctlvisible.p_value= (int)(wid!=0 && arg(2)=="");
   } else {
      ctlvisible.p_value=wid;
   }
   if( 0!=(ptb->tbflags & TBFLAG_WHEN_DEBUGGER_STARTED_ONLY) && !_tbDebugQMode() ) {
      ctlvisible.p_enabled=false;
   } else {
      ctlvisible.p_enabled=true;
   }

   if( 0!=(ptb->tbflags & TBFLAG_ALWAYS_ON_TOP) ) {
      ctlontop.p_value=1;
   } else {
      ctlontop.p_value=0;
   }
   if( 0!=(ptb->tbflags & TBFLAG_ALLOW_DOCKING) ) {
      ctlallowdocking.p_value=1;
   } else {
      ctlallowdocking.p_value=0;
   }
}

static int okToolbarButtonOptions()
{
   int min, max;

   _str new_pic_size;
   if (ctl_buttons_small.p_value) {
      new_pic_size='16x16';
   } else if (ctl_buttons_large.p_value) {
      new_pic_size='32x32';
   } else {
      new_pic_size='24x24';
   }

   // check their horizontal spacing value
   _str new_hspace = ctl_button_hspace.p_text;
   if (!isinteger(new_hspace)) {
      _message_box("Horizontal spacing must be an integer");
      ctl_button_hspace._set_focus();
      return INVALID_NUMBER_ARGUMENT_RC;
   }
   if ((int) new_hspace < 0 || (int) new_hspace > 50) {
      _message_box("Horizontal spacing must be between 0 and 50 pixels");
      ctl_button_hspace._set_focus();
      return INVALID_NUMBER_ARGUMENT_RC;
   }

   // save the changes
   if (def_toolbar_pic_size != new_pic_size ||
       def_toolbar_pic_hspace != new_hspace) {
      def_toolbar_pic_hspace = (int) new_hspace;
      tbReloadBitmaps(new_pic_size);
      _macro_append("def_toolbar_pic_size="new_pic_size);
      _macro_append("def_toolbar_pic_hspace="new_hspace);

      _QToolbarSetSpacing((int)new_hspace);
   }

   // that's all folks
   return 0;
}

boolean _tbDebugListToolbarForm(_str FormName)
{
   _TOOLBAR *ptb=_tbFind(FormName);
   if (!ptb) {
      return(true);
   }
   return(_tbDebugListToolbar(ptb));
}

boolean _tbDebugListToolbar(_TOOLBAR *ptb)
{
   int session_id = dbg_get_current_session();
   int ToolbarSupported_index=find_index('_'dbg_get_callback_name(session_id)'_ToolbarSupported',PROC_TYPE);
   if (ptb->tbflags&TBFLAG_WHEN_DEBUGGER_STARTED_ONLY) {
      if (!_tbDebugQMode()) {
         return(false);
      }
      if (ToolbarSupported_index &&
          !call_index(ptb->FormName,ToolbarSupported_index)) {
         return(false);
      }
   }
   if (ptb->tbflags&TBFLAG_WHEN_DEBUGGER_SUPPORTED_ONLY) {
      if (ToolbarSupported_index &&
          !call_index(ptb->FormName,ToolbarSupported_index)) {
         return(false);
      }
   }
   return(true);
}

boolean _tbIsDisabledToolbar(_TOOLBAR* ptb)
{
   //if( ptb->FormName == "_tbannotations_browser_form" ) {
   //   return true;
   //}
   return false;
}

static int tbListBoxAddToolbars(_str formName='', int tbTypes = TBT_TOOL_WINDOW | TBT_TOOLBAR)
{
   int i,selectedLine=0;
   for (i=0;i<def_toolbartab._length();++i) {
      _TOOLBAR *ptb;
      ptb= &def_toolbartab[i];
      int index=find_index(ptb->FormName,oi2type(OI_FORM));

      if (index && _tbDebugListToolbar(ptb) && doShowToolbar(ptb->tbflags, tbTypes)) {
         _lbadd_item(index.p_caption);
         if (ptb->FormName==formName) {
            selectedLine=p_line;
         }
      }
   }
   return selectedLine;
}

static boolean doShowToolbar(int tbflags, int tbTypes)
{
   return (((tbTypes & TBT_TOOLBAR) != 0 && isToolbar(tbflags)) || 
           ((tbTypes & TBT_TOOL_WINDOW) != 0 && !isToolbar(tbflags)));
}

static void selectToolbar(_str formName)
{
   int index = find_index(formName, oi2type(OI_FORM));
   if( index ) {
      if (!list1._lbsearch(index.p_caption)) {
         list1._lbselect_line();
      }
   }
}

static void oncreateToolbars(_str formName, int tbTypes)
{
   if( !_tbIsDockingAllowed() ) {
      ctlallowdocking.p_visible=false;
   }

   if( _find_control('ctltooltips') ) {
      ctltooltips.p_value=(int)(_default_option(VSOPTION_SHOWTOOLTIPS)!=0);
      ORIGINAL_SHOWTOOLTIPS=ctltooltips.p_value;

      ctltooltipdelay.p_next.p_enabled=ctltooltipdelay.p_enabled=(ctltooltips.p_value!=0);
      ctltooltipdelay.p_text=100*_default_option(VSOPTION_TOOLTIPDELAY);
      ORIGINAL_TOOLTIPSDELAY = ctltooltipdelay.p_text;
   }
   ctlhide.p_value=(int)def_hidetoolbars;
   ORIGINAL_HIDE=ctlhide.p_value;

   if (tbTypes == TBT_TOOLBAR) {
#if !__MACOSX__
      ctlunified.p_enabled = false;
      ctlunified.p_visible = false;
#endif
      ctlunified.p_value = _QToolbarGetUnifiedToolbar();
   }

   int selectedLine = list1.tbListBoxAddToolbars(formName, tbTypes);
   if (selectedLine > 0) {
      list1.p_line=selectedLine;
   } else {
      list1._lbtop();
   }
   list1._lbsort();
   list1._lbselect_line();
   list1.call_event(CHANGE_SELECTED,list1,ON_CHANGE,'');
}

static void oncreateToolbarOptions()
{
   switch (def_toolbar_pic_size) {
   case '16x16': 
      ctl_buttons_small.p_value=1;
      break;
   case '32x32': 
      ctl_buttons_large.p_value=1;
      break;
   default:
      ctl_buttons_medium.p_value=1;
      break;
   }

   ctl_button_hspace.p_text = def_toolbar_pic_hspace;
}

void ctlcatlist.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      _tbPropsShowControls( ctlcatlist.p_line - 1 );
   }
}

void ctlclose.lbutton_up()
{
   if( _toolbars_prop_form_apply() ) {
      p_active_form._delete_window();
   } else return;
}

void _move_options_to_front()
{
   int wid = _find_object('_options_config_tree_form',"n");
   if (wid) {
      wid._set_focus();
      wid._set_foreground_window();
   }
}

void ctlclose.on_create(_str selectedToolbar='')
{
   _tbNewVersion();
   //_retrieve_prev_form();
   _toolbars_prop_sstab._retrieve_value();

   if (selectedToolbar == '') {
      selectedToolbar = _retrieve_value(p_active_form.p_name'.list1');
   }

   int fid = p_active_form;
   fid.oncreateToolbars(selectedToolbar, TBT_TOOLBAR);
   fid._tbPropsInitCategories();
   fid.oncreateToolbarOptions();

   _tbPropsSetupToolbars(1);

   if (_get_focus() != fid) { // ununifying toolbar can force mainwindow to come forward over options
      _post_call(_move_options_to_front);
   }
}


#define DRAGDROP_MODE_FORM_STR "_toolbars_prop_form"
#define DRAGDROP_MODE_FORM      _toolbars_prop_form
boolean _tbInDragDropCtlMode()
{
   if (!_find_object(DRAGDROP_MODE_FORM_STR,"n")) {
      return(0);
   }
   _TOOLBAR *ptb;
   ptb=_tbFind(p_parent.p_name);
   if (!ptb || !(ptb->tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED)) {
      return(0);
   }
   return(1);
}

boolean _tbDragDropMode()
{
   return (_find_object(DRAGDROP_MODE_FORM_STR,"n") != 0);
}

void _tbDragDropCtl()
{
   call_event(defeventtab DRAGDROP_MODE_FORM.ctlpicture,LBUTTON_DOWN,'e');
}

static void _tbFindDropPosition(int &toolbar_wid,int &tab_index,
                                int x1,int y1,int x2,int y2
                                )
{
   int first_child=toolbar_wid.p_child;
   int child=first_child;
   if (!child) {
      tab_index=1;
      //toolbar_wid=0;
      return;
   }
   DockingArea area = _QToolbarGetDockArea(toolbar_wid);
   boolean vertical = ((area == DOCKINGAREA_LEFT) || (area == DOCKINGAREA_RIGHT));
   int mid = (vertical) ? ((x1+x2) intdiv 2) : ((y1+y2) intdiv 2);
   tab_index=1;
   boolean FoundOne=false;
   for(;;++tab_index) {
      int sx1,sy1,sx2,sy2, swidth,sheight;
      if (vertical) { // swap axis
         child._get_window(sy1,sx1,sheight,swidth);
         _lxy2dxy(child.p_xyscale_mode,sy1,sx1);
         _lxy2dxy(child.p_xyscale_mode,sheight,swidth);
         _map_xy(child.p_xyparent,0,sy1,sx1,SM_PIXEL);
         sx2=sx1+swidth;
         sy2=sy1+sheight;
      } else {
         child._get_window(sx1,sy1,swidth,sheight);
         _lxy2dxy(child.p_xyscale_mode,sx1,sy1);
         _lxy2dxy(child.p_xyscale_mode,swidth,sheight);
         _map_xy(child.p_xyparent,0,sx1,sy1,SM_PIXEL);
         sx2=sx1+swidth;
         sy2=sy1+sheight;
      }

      if (mid>=sy1 && mid<=sy2) {
         // IF left side of rect to left of this control
         if (x1<=sx1) {
            FoundOne=true;
            break;
         }
         // IF left side of rect inside this control
         if (x1>=sx1&& x1<sx2) {
            FoundOne=true;
            // Insert after last child
            ++tab_index;
            break;
         }
         // IF right side of rect of this rect inside this toolbar
         if ((x2>sx1&& x2<sx2)) {
            FoundOne=true;
            // Insert after last child
            ++tab_index;
            break;
         }
         child=child.p_next;
         if (child==first_child) {
            FoundOne=true;
            // Insert after last child
            ++tab_index;
            break;
         }
      } else {
         child=child.p_next;
         if (child==first_child) {
            break;
         }
      }
   }
   if (!FoundOne) {
      toolbar_wid=0;
   }
   //say("floating toolbar_wid "toolbar_wid" tab_index="tab_index);
}

void _tbDragDropControlEventLoop(int tid)
{
   boolean DraggingFromToolbar=false;
   if (tid.p_parent.p_object==OI_FORM && _tbFind(tid.p_parent.p_name)) {
      DraggingFromToolbar=true;
   }
   //say("DraggingFromToolbar="DraggingFromToolbar);
   int orig_wid=p_window_id;
   int selected_wid=tid;
   p_window_id=_desktop;

   _str DragOption="D";

   mou_mode(1);
   selected_wid.mou_capture();
   _KillToolButtonTimer();

   int old_mouse_pointer=selected_wid.p_mouse_pointer;
   int doCopy=_IsKeyDown(CTRL);

   /*mp=MP_LEFTARROW;
   mou_set_pointer(mp);selected_wid.p_mouse_pointer=mp;*/

   int mx=selected_wid.mou_last_x()+_lx2dx(selected_wid.p_xyscale_mode,selected_wid._left_width());
   int my=selected_wid.mou_last_y()+_ly2dy(selected_wid.p_xyscale_mode,selected_wid._top_height());
   int rectangle_drawn=0;
   //morig_x=mou_last_x('M');morig_y=mou_last_y('M');rectangle_drawn=0;
   int done=0;
   int orig_x,orig_y,orig_width,orig_height;
   selected_wid._get_window(orig_x,orig_y,orig_width,orig_height);
   _lxy2dxy(selected_wid.p_xyscale_mode,orig_x,orig_y);
   _lxy2dxy(selected_wid.p_xyscale_mode,orig_width,orig_height);
   _map_xy(selected_wid.p_xyparent,0,orig_x,orig_y,SM_PIXEL);
   int x1=orig_x;
   int y1=orig_y;
   int x2=x1+orig_width;
   int y2=y1+orig_height;
   int orig_x1=x1;
   int orig_y1=y1;
   int orig_x2=x2;
   int orig_y2=y2;
   typeless event=MOUSE_MOVE;
   int toolbar_wid=0;
   int new_x1=0;
   int new_y1=0;
   int new_x2=0;
   int new_y2=0;
   int x,y,i,j;
   int sx1,sy1,swidth,sheight;
   int sx2,sy2;
   int tab_index;
   for (;;) {
      switch (event) {
      case MOUSE_MOVE:
         toolbar_wid= 0;
         x=mou_last_x();y=mou_last_y();
         new_x1=x-mx;
         new_y1=y-my;
         new_x2=new_x1+(x2-x1);
         new_y2=new_y1+(y2-y1);
         {
            for (j=0;j<def_toolbartab._length();++j) {
               if (!(def_toolbartab[j].tbflags & TBFLAG_SIZEBARS) &&
                   (def_toolbartab[j].tbflags & TBFLAG_ALLOW_CONTROLS_TO_BE_ADDED)) {
                  int wid = _find_object(def_toolbartab[j].FormName,'n');
                  if (wid) {
                     wid._get_window(sx1,sy1,swidth,sheight);
                     _lxy2dxy(wid.p_xyscale_mode,sx1,sy1);
                     _lxy2dxy(wid.p_xyscale_mode,swidth,sheight);
                     _map_xy(_mdi,0,sx1,sy1,SM_PIXEL);
                     sy2=sy1+sheight;
                     sx2=sx1+swidth;

                     if (new_x1<sx2 && new_x2>sx1 && new_y1<sy2 && new_y2>sy1) {
                        toolbar_wid=wid;
                        _tbFindDropPosition(toolbar_wid,tab_index,
                                            new_x1,new_y1,new_x2,new_y2);
                        break;
                     }
                  }
               }
            }
         }

         typeless mp;
         if (toolbar_wid>0) {
            mp=(doCopy && DraggingFromToolbar)?MP_ALLOWCOPY:MP_ALLOWDROP;
         } else {
            mp=MP_NODROP; //LEFTARROW;
         }
         if (selected_wid.p_mouse_pointer!=mp) {
            mou_set_pointer(mp);selected_wid.p_mouse_pointer=mp;
         }
         if (rectangle_drawn) {
            if (x1==new_x1 && y1==new_y1 && x2==new_x2 && y2==new_y2) {
               break;
            }
         }
         rectangle_drawn=1;
         x1=new_x1;y1=new_y1;x2=new_x2;y2=new_y2;
         break;
      case ON_KEYSTATECHANGE:
         doCopy=_IsKeyDown(CTRL);
         event=MOUSE_MOVE;
         continue;
      case LBUTTON_UP:
      case ESC:
         done=1;
      }
      if(done) break;
      event=selected_wid.get_event();
   }
   mou_mode(0);
   mou_release();
   selected_wid.p_mouse_pointer=old_mouse_pointer;
   typeless status=0;
   if (rectangle_drawn) {
      /* Erase the rectangle. */
      //p_draw_width=draw_width;
      if (event!=ESC) {
         if (toolbar_wid>0) {
            // Insert the new control
            _tbAdjustTabIndexes(toolbar_wid,tab_index,1);
            int wid = _create_window(selected_wid.p_object,
                           toolbar_wid,"",0,0,0,0,
                           CW_HIDDEN|CW_CHILD,BDS_NONE /*selected_wid.p_border_style*/);
            wid.p_tab_index=tab_index;
            wid.p_width=selected_wid.p_width;
            wid.p_height=selected_wid.p_height;
            wid.p_name=selected_wid.p_name;
            switch (selected_wid.p_object) {
            case OI_IMAGE:
               wid.p_auto_size=true;
               wid.p_caption=selected_wid.p_caption;
               wid.p_picture=selected_wid.p_picture;
               if (wid.p_caption=="" && !wid.p_picture) {
                  wid.p_visible=1;
               }
               wid.p_command =selected_wid.p_command;
               wid.p_message=selected_wid.p_message;
               wid.p_style=selected_wid.p_style;
               wid.p_Nofstates=selected_wid.p_Nofstates;
               wid.p_eventtab=0;
               wid.p_eventtab2=defeventtab _ul2_picture;
               break;
            case OI_COMBO_BOX:
               _tbSetSpecialControl(wid, lowcase(selected_wid.p_name));
               break;
             }

            // If we are not inserting into the same toolbar
            //    we just deleted from
            if (doCopy || toolbar_wid!=selected_wid.p_parent) {
               status=toolbar_wid._update_template();
               _set_object_modify(status);
               _tbRedisplay(toolbar_wid);
            }
         }
         // If we are dragging this control from a toolbar
         if (DraggingFromToolbar && !doCopy) {
            toolbar_wid=selected_wid.p_parent;
            _tbAdjustTabIndexes(toolbar_wid,selected_wid.p_tab_index,-1);
            selected_wid._delete_window();
            status=toolbar_wid._update_template();
            _set_object_modify(status);
            _tbRedisplay(toolbar_wid);
         }
      }
   }
   if (_iswindow_valid(orig_wid)) {
      p_window_id=orig_wid;
   }
   int wid = _get_focus();
   if (wid && wid.p_DockingArea) {
      if (_mdi._no_child_windows()) {
         _cmdline._set_focus();
      } else {
         _mdi.p_child._set_focus();
      }
   }
}

void ctlpicture.lbutton_down()
{
   if (p_active_form.p_name==DRAGDROP_MODE_FORM_STR && p_name=='ctlpicture') {
      return;
   }
   _post_call(_tbDragDropControlEventLoop, p_window_id);
}

// make the dialog resizable
void _toolbars_prop_form.on_resize()
{
   // enforce minimum size - only if not embedded in options dialog
   // if we have not yet set the min sizes, _minimum_width will return 0
   if( !ctlclose.p_visible && !_minimum_width() ) {
      // come up with a good minimum size
      int min_width = ctl_toolbar_size_frame.p_width*1 + ctl_toolbar_size_frame.p_x*2 + _toolbars_prop_sstab.p_x*2;
      int min_height = ctl_toolbar_size_frame.p_y + ctl_toolbar_size_frame.p_height + ctlrename.p_height*4;

      _set_minimum_size(min_width, min_height);
   }


   // available width and height
   int w = p_width;
   int h = p_height;

   padding := _toolbars_prop_sstab.p_x;
   widthDiff := w - (_toolbars_prop_sstab.p_x + _toolbars_prop_sstab.p_width + 2 * padding);
   heightDiff := h - (_toolbars_prop_sstab.p_y + _toolbars_prop_sstab.p_height + 2 * padding);

   if( widthDiff ) {
      _toolbars_prop_sstab.p_width += widthDiff;

      // toolbars tab
      list1.p_width += widthDiff;
      ctlnew.p_x += widthDiff;
      ctlrename.p_x += widthDiff;

      ctldelete.p_x = ctlvisible.p_x = ctlontop.p_x = ctlallowdocking.p_x = ctlnew.p_x;

      ctlreset.p_x = ctlrename.p_x;

      // categories tab
      halfWidthDiff := widthDiff intdiv 2;
      ctlcatlist.p_width += halfWidthDiff;
      ctlcontrols.p_width += halfWidthDiff;
      ctlcontrols.p_x += halfWidthDiff;
      ctlpicture.p_width += halfWidthDiff;
      ctlhelp.p_width += widthDiff;

      // options tab - nothing to do
   }

   if( heightDiff ) {
      _toolbars_prop_sstab.p_height += heightDiff;
      ctlclose.p_y += heightDiff;

      // toolbars tab
      list1.p_height += heightDiff;

      // categories tab
      ctlcontrols.p_height += heightDiff;
      ctlcatlist.p_height = ctlcontrols.p_height - (ctlcatlabel.p_height);
      ctlpicture.p_height += heightDiff;
      ctlhelp.p_y += heightDiff;

      // options tab - nothing to do
   }

   // now reflow the buttons
   _tbPropsShowControls( ctlcatlist.p_line - 1 );

   // make sure the scroll bar is visible
   list1.refresh();
}

defeventtab _tool_windows_prop_form;

void _tool_windows_prop_form_init_for_options(_str formNameOrTab = '')
{
   if( formNameOrTab != '' ) {
      if( isinteger(formNameOrTab) ) {
         _toolbars_prop_sstab.p_ActiveTab = (int)formNameOrTab;
      } else {
         selectToolbar(formNameOrTab);
      }
   }
}

void _tool_windows_prop_form_save_settings(_str (&settings):[])
{
   // close button affects active tab
   settings:["ctl_close_active_tab.p_value"] = ctl_close_active_tab.p_value;

   // auto hide delay
   settings:["ctl_auto_hide_active_tab.p_value"] = ctl_auto_hide_active_tab.p_value;
   settings:["ctl_auto_hide_delay.p_text"] = ctl_auto_hide_delay.p_text;

   // mouse over
   settings:["ctl_mouse_over_auto_shows.p_value"] = ctl_mouse_over_auto_shows.p_value;
   settings:["ctl_auto_show_delay.p_text"] = ctl_auto_show_delay.p_text;
}

boolean _tool_windows_prop_form_is_modified(_str settings:[])
{
   if (ORIGINAL_HIDE!=ctlhide.p_value) return true;

   // close button affects active tab
   if (settings:["ctl_close_active_tab.p_value"] != ctl_close_active_tab.p_value) return true;

   // auto hide delay
   if (settings:["ctl_auto_hide_delay.p_text"] != ctl_auto_hide_delay.p_text) return true;
   if (settings:["ctl_auto_hide_active_tab.p_value"] != ctl_auto_hide_active_tab.p_value) return true;

   // mouse over
   if (settings:["ctl_mouse_over_auto_shows.p_value"] != ctl_mouse_over_auto_shows.p_value) return true;
   if (settings:["ctl_auto_show_delay.p_text"] != ctl_auto_show_delay.p_text) return true;

   return false;
}

boolean _tool_windows_prop_form_apply()
{
   int fid = p_active_form; 

   if (ORIGINAL_HIDE!=ctlhide.p_value) {
      def_hidetoolbars=ctlhide.p_value!=0;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   result := fid.okToolWindowOptions();
   if (result) return false;

   return true;
}

void _tool_windows_prop_form.on_destroy()
{
   // save which toolbar was active, so we can pick it again
   item := list1._lbget_text();
   _TOOLBAR *ptb = _tbFindCaption(item, auto index);
   _append_retrieve(0, ptb -> FormName, p_active_form.p_name'.list1');
}

void ctlvisible.on_create(_str selectedToolbar='')
{
   _tbNewVersion();

   _toolbars_prop_sstab._retrieve_value();
   int fid = p_active_form;

   if (selectedToolbar == '') {
      selectedToolbar = _retrieve_value(p_active_form.p_name'.list1');
   }
   fid.oncreateToolbars(selectedToolbar, TBT_TOOL_WINDOW);
   fid.oncreateToolWindowOptions();
}

static void oncreateToolWindowOptions()
{
   ctl_close_active_tab.p_value = (int)( 0==(def_toolbar_options & TBOPTION_CLOSE_TABGROUP) );
   ctl_auto_hide_active_tab.p_value = (int)( 0!=(def_toolbar_options & TBOPTION_NO_AUTOHIDE_TABGROUP) );

   // Sanity
   int value = def_dock_channel_delay;
   if( value<100 || value>5000 ) {
      value=DOCKCHANNEL_AUTO_DELAY;
   }
   ctl_auto_show_delay.p_text= value intdiv 100;
   ctl_mouse_over_auto_shows.p_value = (int)(0==(def_dock_channel_options & DOCKCHANNEL_OPT_NO_MOUSEOVER));
   ctl_mouse_over_auto_shows.call_event(ctl_mouse_over_auto_shows,LBUTTON_UP,'w');
   // Sanity
   value=def_toolbar_autohide_delay;
   if( value<100 || value>10000 ) {
      value=TBAUTOHIDE_DELAY_DEFAULT;
   }
   ctl_auto_hide_delay.p_text= value intdiv 100;
}

static int okToolWindowOptions()
{
   // Check auto show delay
   min := DOCKCHANNEL_TIMER_INTERVAL intdiv 100;
   max := 50;
   _str new_dock_channel_delay = ctl_auto_show_delay.p_text;
   if( !isinteger(new_dock_channel_delay) || new_dock_channel_delay<min || new_dock_channel_delay>max ) {
      if( ctl_mouse_over_auto_shows.p_value==0 ) {
         // Not important. Quietly fix it.
         new_dock_channel_delay= DOCKCHANNEL_AUTO_DELAY intdiv 100;
      } else {
         _str msg = "Auto Show delay must be between "min" and "max" tenths of a second";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_auto_show_delay;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return INVALID_NUMBER_ARGUMENT_RC;
      }
   }

   // Check auto hide delay
   min = TBAUTOHIDE_TIMER_INTERVAL intdiv 100;
   max = 10000 intdiv 100;
   _str new_auto_hide_delay = ctl_auto_hide_delay.p_text;
   if( !isinteger(new_auto_hide_delay) || new_auto_hide_delay<min || new_auto_hide_delay>max ) {
      _str msg = "Auto Hide delay must be between "min" and "max" tenths of a second";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctl_auto_hide_delay;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return INVALID_NUMBER_ARGUMENT_RC;
   }

   // Close button affects active tab only
   int new_toolbar_options = def_toolbar_options;
   if( ctl_close_active_tab.p_value==0 ) {
      new_toolbar_options |= TBOPTION_CLOSE_TABGROUP;
   } else {
      new_toolbar_options &= ~(TBOPTION_CLOSE_TABGROUP);
   }
   // Auto Hide button affects active tab only
   if( ctl_auto_hide_active_tab.p_value!=0 ) {
      new_toolbar_options |= TBOPTION_NO_AUTOHIDE_TABGROUP;
   } else {
      new_toolbar_options &= ~(TBOPTION_NO_AUTOHIDE_TABGROUP);
   }
   if( new_toolbar_options!=def_toolbar_options ) {
      def_toolbar_options=new_toolbar_options;
      _macro_append("def_toolbar_options="new_toolbar_options);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }

   // Auto Show delay.
   // Convert to milliseconds
   new_dock_channel_delay = (int)new_dock_channel_delay * 100;
   if( new_dock_channel_delay!=def_dock_channel_delay ) {
      def_dock_channel_delay=(int)new_dock_channel_delay;
      _macro_append("def_dock_channel_delay="new_dock_channel_delay);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   // Auto Show tool window on mouse over
   int new_dock_channel_options=def_dock_channel_options;
   if( ctl_mouse_over_auto_shows.p_value==0 ) {
      new_dock_channel_options |= DOCKCHANNEL_OPT_NO_MOUSEOVER;
   } else {
      new_dock_channel_options &= ~(DOCKCHANNEL_OPT_NO_MOUSEOVER);
   }
   if( new_dock_channel_options!=def_dock_channel_options ) {
      def_dock_channel_options=new_dock_channel_options;
      _macro_append("def_dock_channel_options="new_dock_channel_options);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }
   // Auto Hide delay.
   // Convert to milliseconds
   new_auto_hide_delay = (int)new_auto_hide_delay * 100;
   if( new_auto_hide_delay!=def_toolbar_autohide_delay ) {
      def_toolbar_autohide_delay=(int)new_auto_hide_delay;
      _macro_append("def_toolbar_autohide_delay="new_auto_hide_delay);
      _config_modify_flags(CFGMODIFY_DEFDATA);
   }

   // that's all folks
   return 0;
}

// make the dialog resizable
void _tool_windows_prop_form.on_resize()
{
   // available width and height
   int w = p_width;
   int h = p_height;

   padding := _toolbars_prop_sstab.p_x;
   widthDiff := w - (_toolbars_prop_sstab.p_x + _toolbars_prop_sstab.p_width + 2 * padding);
   heightDiff := h - (_toolbars_prop_sstab.p_y + _toolbars_prop_sstab.p_height + 2 * padding);

   if( widthDiff ) {
      _toolbars_prop_sstab.p_width += widthDiff;

      // toolbars tab
      list1.p_width += widthDiff;
      ctlvisible.p_x += widthDiff;
      ctl_esc_dismiss.p_width += widthDiff;

      ctlontop.p_x = ctlallowdocking.p_x = ctl_esc_dismiss.p_x = ctlvisible.p_x;

      // options tab - nothing to do
   }

   if( heightDiff ) {
      _toolbars_prop_sstab.p_height += heightDiff;

      // toolbars tab
      list1.p_height += heightDiff;

      // options tab - nothing to do
   }

   // make sure the scroll bar is visible
   list1.refresh();
}

void list1.on_change(int reason)
{
   typeless ff;
   if( reason==CHANGE_SELECTED ) {
      _str item = _lbget_text();
      int index = 0;
      _TOOLBAR *ptb = _tbFindCaption(item,index);
      if( ptb ) {
         // If this is a system dialog box
         ff=name_info(index);
         if( !isinteger(ff) ) {
            ff=0;
         }

         ctl_esc_dismiss.p_enabled = ( 0 != (ptb->tbflags & TBFLAG_SIZEBARS) );
         if( 0 != (ptb->tbflags & TBFLAG_DISMISS_LIKE_DIALOG) ) {
            ctl_esc_dismiss.p_value = 1;
         } else {
            ctl_esc_dismiss.p_value = 0;
         }

         setControlsForSelectedToolBar(ptb);

      } else {
         message("Toolbar not found?");
      }
   }
}

void ctlvisible.lbutton_up()
{
   _str caption=list1._lbget_text();
   _TOOLBAR *ptb;
   int index;
   ptb=_tbFindCaption(caption,index);
   if( !ptb ) {
      return;
   }
   int wid = _tbIsVisible(ptb->FormName);
   // Make form visible?
   if( p_value!=0 ) {

      if( wid==0 ) {
         tbShow(ptb->FormName);
      }

   } else {

      if( wid!=0 ) {
         tbClose(wid);
      }
   }
}

void ctl_mouse_over_auto_shows.lbutton_up()
{
   boolean enabled = (p_value!=0);
   ctl_auto_show_delay_label.p_enabled=enabled;
   ctl_auto_show_delay.p_enabled=enabled;
   ctl_auto_show_delay_spinner.p_enabled=enabled;
   ctl_auto_show_delay_label2.p_enabled=enabled;
}

void ctl_esc_dismiss.lbutton_up()
{
   _str caption = list1._lbget_text();
   int index;
   _TOOLBAR *ptb = _tbFindCaption(caption,index);
   if( !ptb ) {
      return;
   }
   if( p_value != 0 ) {
      ptb->tbflags |= TBFLAG_DISMISS_LIKE_DIALOG;
   } else {
      ptb->tbflags &= ~TBFLAG_DISMISS_LIKE_DIALOG;
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}
