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
#include "toolwindow.sh"
#include "dockchannel.sh"
#include "toolbar.sh"
#import "optionsxml.e"
#import "stdprocs.e"
#import "listbox.e"
#import "main.e"
#import "mainwindow.e"
#import "qtoolbar.e"
#import "stdcmds.e"
#import "tbcontrols.e"
#import "tbprops.e"
#import "toolwindow.e"
#import "recmacro.e"
#import "tbview.e"
#endregion

//using namespace se.ui;

ToolWindowInfo g_toolwindowtab:[];

// Default millisecond delay to wait before hovered dock-channel Tab raises auto-hide window
static const DOCKCHANNEL_HOVER_DELAY= 500;


static int gIconSizes:[] = {
   "Extra Small" => 16,
   "Small"       => 20,
   "Medium"      => 24,
   "Large"       => 32,
   "Extra Large" => 48,
   "Jumbo"       => 64,
   "Huge"        => 64,
   "Gigantic"    => 96,
   "Colossal"    => 128,
};

static int gTreeIconSizes:[] = {
   "Extra Small" => 12,
   "Small"       => 14,
   "Medium"      => 16,
   "Large"       => 24,
   "Extra Large" => 32,
   "Huge"        => 48,
   "Gigantic"    => 64,
   "Colossal"    => 96,
};

static _str gIconStyles:[] = {
   "Default (Low-color)" => "",
   "Color"               => "3d",
   "Monochrome"          => "grey",
   "Green (Two-tone)"    => "green",
   "Blue (Two-tone)"     => "blue",
   "Orange (Two-tone)"   => "orange",
};

_command void customize_tool_windows(_str formName="0") name_info(',')
{
   // "0" shows the customize toolwindows form with the Toolwindows tab up
   config("_tool_windows_customization_form", 'D', formName);
}


//
// _tool_windows_customization_form
//

defeventtab _tool_windows_customization_form;

static void selectToolWindow(_str formName)
{
   int index = find_index(formName, oi2type(OI_FORM));
   if( index ) {
      if (!list1._lbsearch(index.p_caption)) {
         list1._lbselect_line();
      }
   }
}

void _tool_windows_customization_form_init_for_options(_str formNameOrTab = "")
{
   if ( formNameOrTab != "" ) {
      selectToolWindow(formNameOrTab);
   }
}

void _tool_windows_customization_form_save_settings(_str (&settings):[])
{
}

bool _tool_windows_customization_form_is_modified(_str settings:[])
{
   return false;
}

bool _tool_windows_customization_form_apply()
{
   return true;
}

_str _tool_windows_customization_form_export_settings(_str &path)
{
   return _current_layout_export_settings(path);
}

_str _tool_windows_customization_form_import_settings(_str &file)
{
   return _current_layout_import_settings(file);
}

void _tool_windows_customization_form.on_destroy()
{
   // Remember which tool-window was active in list
   item := list1._lbget_text();
   ToolWindowInfo* twinfo = tw_find_info_by_caption(item, auto index);
   _append_retrieve(0, index.p_name, p_active_form.p_name".list1");
}


static int _twprop_list_box_add_tool_windows(_str formName="")
{
   selectedLine := 0;
   ToolWindowInfo twinfo;
   foreach ( auto fn => twinfo in g_toolwindowtab ) {
      int index = find_index(fn, oi2type(OI_FORM));
      if ( index && tw_is_allowed(fn, &twinfo) && tw_is_supported_mode(fn, &twinfo) ) {
         _lbadd_item(index.p_caption);
         if ( fn == formName ) {
            selectedLine = p_line;
         }
      }
   }
   return selectedLine;
}

static void oncreateToolWindows(_str formName)
{
   if( !tw_is_docking_allowed() ) {
      ctlallowdocking.p_visible = false;
   }

   int selectedLine = list1._twprop_list_box_add_tool_windows(formName);
   if ( selectedLine > 0 ) {
      list1.p_line = selectedLine;
   } else {
      list1._lbtop();
   }
   list1._lbsort();
   list1._lbselect_line();
   list1.call_event(CHANGE_SELECTED, list1, ON_CHANGE, "");
}

void ctlvisible.on_create(_str selectedToolWindow="")
{
   tw_sanity();

   fid := p_active_form;
   if (selectedToolWindow == "") {
      selectedToolWindow = _retrieve_value(p_active_form.p_name".list1");
   }
   fid.oncreateToolWindows(selectedToolWindow);
}

// make the dialog resizable
void _tool_windows_customization_form.on_resize()
{
   // available width and height
   w := p_width;
   h := p_height;

   padding := list1.p_x;
   widthDiff := w - (ctl_esc_dismiss.p_x_extent + 2 * padding);
   heightDiff := h - (list1.p_y_extent + 2 * padding);

   if ( widthDiff ) {
      // Tool Windows tab
      list1.p_width += widthDiff;
      ctlvisible.p_x += widthDiff;
      ctlallowdocking.p_x = ctl_esc_dismiss.p_x = ctlvisible.p_x;
   }

   if( heightDiff ) {
      // toolwindows tab
      list1.p_height += heightDiff;
   }

   // make sure the scroll bar is visible
   list1.refresh();
}

static void setControlsForSelectedToolWindow(_str form_name, int twflags)
{
   int wid = tw_is_visible(form_name);
   if( wid > 0 ) {
      ctlvisible.p_value= 1;
   } else {
      ctlvisible.p_value = 0;
   }
   if ( 0 != (twflags & TWF_WHEN_DEBUGGER_STARTED_ONLY) && !_tbDebugQMode() ) {
      ctlvisible.p_enabled = false;
   } else {
      ctlvisible.p_enabled = true;
   }

   if( 0 != (twflags & TWF_NO_DOCKING) ) {
      ctlallowdocking.p_value = 0;
   } else {
      ctlallowdocking.p_value = 1;
   }
}

void list1.on_change(int reason)
{
   typeless ff;
   if ( reason == CHANGE_SELECTED ) {
      _str item = _lbget_text();
      index := 0;
      ToolWindowInfo* twinfo = tw_find_info_by_caption(item, index);
      if ( twinfo ) {
         // If this is a system dialog box
         ff = name_info(index);
         if( !isinteger(ff) ) {
            ff = 0;
         }

         if ( 0 != (twinfo->flags & TWF_DISMISS_LIKE_DIALOG) ) {
            ctl_esc_dismiss.p_value = 1;
         } else {
            ctl_esc_dismiss.p_value = 0;
         }

         setControlsForSelectedToolWindow(index.p_name, twinfo->flags);

      } else {
         message("Tool window not found?");
      }
   }
}

void ctlallowdocking.lbutton_up()
{
   _str caption = list1._lbget_text();
   int index;
   ToolWindowInfo* twinfo = tw_find_info_by_caption(caption, index);
   if( !twinfo ) {
      return;
   }

   // IMPORTANT toggle the visible tool-window BEFORE
   // you change the entry in g_toolwindowtab because
   // toggle_dockable_tool_window() checks it too.
   form_name := index.p_name;
   int wid = tw_is_visible(form_name);
   if( wid > 0 ) {
      toggle_dockable_tool_window(wid);
   }

   if( p_value == 0 ) {
      twinfo->flags |= TWF_NO_DOCKING;
   } else {
      twinfo->flags &= ~(TWF_NO_DOCKING);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}

void ctlvisible.lbutton_up()
{
   _str caption = list1._lbget_text();
   int index;
   ToolWindowInfo* twinfo = tw_find_info_by_caption(caption, index);
   if( !twinfo ) {
      return;
   }
   int wid = tw_is_visible(index.p_name);
   // Make form visible?
   if( p_value != 0 ) {

      if( wid == 0 ) {
         show_tool_window(index.p_name);
      }

   } else {

      while ( wid > 0 ) {
         hide_tool_window(wid);
         wid = tw_is_visible(index.p_name);
      }
   }
}

void ctl_esc_dismiss.lbutton_up()
{
   _str caption = list1._lbget_text();
   int index;
   ToolWindowInfo* twinfo = tw_find_info_by_caption(caption, index);
   if ( !twinfo ) {
      return;
   }
   if ( p_value != 0 ) {
      twinfo->flags |= TWF_DISMISS_LIKE_DIALOG;
   } else {
      twinfo->flags &= ~(TWF_DISMISS_LIKE_DIALOG);
   }
   _config_modify_flags(CFGMODIFY_DEFVAR);
}



//
// _tool_windows_prop_form
//

defeventtab _tool_windows_prop_form;

static int ORIGINAL_HIDE(...) {
   if (arg()) ctlhide.p_user=arg(1);
   return ctlhide.p_user;
}

static typeless ORIGINAL_SHOWTOOLTIPS(...) {
   if (arg()) ctltooltips.p_user=arg(1);
   return ctltooltips.p_user;
}
static _str ORIGINAL_TOOLTIPSDELAY(...) {
   if (arg()) ctltooltipdelay.p_user=arg(1);
   return ctltooltipdelay.p_user;
}
static int ORIGINAL_HIDETB(...) {
   if (arg()) ctlhidetoolbar.p_user=arg(1);
   return ctlhidetoolbar.p_user;
}

static bool gin_on_create = false;

void _tool_windows_prop_form_init_for_options(_str formNameOrTab = "")
{
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

   // icon sizes
   settings:["ctl_tab_icon_size.p_text"] = ctl_tab_icon_size.p_text;
   settings:["ctl_tree_icon_size.p_text"] = ctl_tree_icon_size.p_text;

   // toolbar button size
   settings:["ctl_button_size.p_text"] = ctl_button_size.p_text;
   settings:["ctl_button_style.p_text"] = ctl_button_style.p_text;
   settings:["ctl_button_hspace.p_text"] = ctl_button_hspace.p_text;

   // tool window menu toggles show/hide
   settings:["ctl_menu_tool_window_toggle.p_value"] = ctl_menu_tool_window_toggle.p_value;
}

bool _tool_windows_prop_form_is_modified(_str settings:[])
{
   if (ORIGINAL_HIDE()!=ctlhide.p_value) return true;

   // close button affects active tab
   if (settings:["ctl_close_active_tab.p_value"] != ctl_close_active_tab.p_value) return true;

   // auto hide delay
   if (settings:["ctl_auto_hide_delay.p_text"] != ctl_auto_hide_delay.p_text) return true;
   if (settings:["ctl_auto_hide_active_tab.p_value"] != ctl_auto_hide_active_tab.p_value) return true;

   // mouse over
   if (settings:["ctl_mouse_over_auto_shows.p_value"] != ctl_mouse_over_auto_shows.p_value) return true;
   if (settings:["ctl_auto_show_delay.p_text"] != ctl_auto_show_delay.p_text) return true;

   // icon sizes
   if (settings:["ctl_tab_icon_size.p_text"] != ctl_tab_icon_size.p_text) return true;
   if (settings:["ctl_tree_icon_size.p_text"] != ctl_tree_icon_size.p_text) return true;

   // tool window menu toggles show/hide
   if (settings:["ctl_menu_tool_window_toggle.p_value"] != ctl_menu_tool_window_toggle.p_value) return true;

   // tool tips stuff
   if (ORIGINAL_SHOWTOOLTIPS()!=ctltooltips.p_value) return true;
   if (ORIGINAL_TOOLTIPSDELAY() != ctltooltipdelay.p_text) return true;   
   if (ORIGINAL_HIDETB()!=ctlhidetoolbar.p_value) return true;

   // toolbar button size
   if (settings:["ctl_button_size.p_text"] != ctl_button_size.p_text) return true;

   // toolbar button style
   if (settings:["ctl_button_style.p_text"] != ctl_button_style.p_text) return true;

   // toolbar button spacing
   if (settings:["ctl_button_hspace.p_text"] != ctl_button_hspace.p_text) return true;

   return false;
}

bool _tool_windows_prop_form_apply()
{
   fid := p_active_form; 

   if ( ORIGINAL_HIDE() != ctlhide.p_value ) {
      def_hidetoolbars = ctlhide.p_value != 0;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   result := fid.okToolWindowOptions();
   if ( result ) {
      return false;
   }

   if (ORIGINAL_SHOWTOOLTIPS()!=ctltooltips.p_value) {
      _default_option(VSOPTION_SHOWTOOLTIPS,ctltooltips.p_value);
   }
   if (ORIGINAL_HIDETB()!=ctlhidetoolbar.p_value) {
      def_hidetoolbars=ctlhidetoolbar.p_value!=0;
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }
   if (ORIGINAL_TOOLTIPSDELAY() != ctltooltipdelay.p_text) {
      _default_option(VSOPTION_TOOLTIPDELAY,(int)ctltooltipdelay.p_text intdiv 100);
   }

   return true;
}

void _tool_windows_prop_form.on_destroy()
{
}

void ctlhide.on_create(_str selectedToolWindow="")
{
   tw_sanity();

   fid := p_active_form;
   fid.oncreateToolWindowOptions();
   fid.oncreateToolbarOptions();

   // ununifying toolbar can force mainwindow to come forward over options
   if (_get_focus() != fid) { 
      _post_call(_move_options_to_front);
   }
}

static void oncreateToolWindowOptions()
{
   ctl_close_active_tab.p_value = (int)( 0==(def_toolwindow_options & TWOPTION_CLOSE_TABGROUP) );
   ctl_auto_hide_active_tab.p_value = (int)( 0!=(def_toolwindow_options & TWOPTION_NO_AUTOHIDE_TABGROUP) );
   ctl_menu_tool_window_toggle.p_value = (int)( 0!=(def_toolwindow_options & TWOPTION_MENU_TOGGLE_SHOW_HIDE) );

   ctlhide.p_value = (int)def_hidetoolbars;
   ORIGINAL_HIDE(ctlhide.p_value);

   // Sanity
   int value = _default_option(VSOPTION_DOCKCHANNEL_HOVER_DELAY);
   if ( value < 100 || value > 5000 ) {
      value = DOCKCHANNEL_HOVER_DELAY;
   }
   // Milliseconds
   ctl_auto_show_delay.p_text = value;
   int flags = _default_option(VSOPTION_DOCKCHANNEL_FLAGS);
   ctl_mouse_over_auto_shows.p_value = (int)(0 != (flags & VSOPTION_DOCKCHANNEL_HOVER));
   ctl_mouse_over_auto_shows.call_event(ctl_mouse_over_auto_shows, LBUTTON_UP, 'w');
   // Sanity
   value = _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY);
   if( value < 100 || value > 10000 ) {
      value = TWAUTOHIDE_DELAY_DEFAULT;
   }
   ctl_auto_hide_delay.p_text = value;

   ctl_tab_icon_size._lbadd_item(CONFIG_AUTOMATIC);
   ctl_tab_icon_size._lbadd_item("Extra Small");
   ctl_tab_icon_size._lbadd_item("Small");
   ctl_tab_icon_size._lbadd_item("Medium");
   ctl_tab_icon_size._lbadd_item("Large");
   ctl_tab_icon_size._lbadd_item("Extra Large");
   ctl_tab_icon_size._lbadd_item("Huge");
   ctl_tab_icon_size._lbadd_item("Gigantic");
   ctl_tab_icon_size._lbadd_item("Colossal");
   if (def_toolbar_tab_pic_auto) {
      ctl_tab_icon_size.p_text = CONFIG_AUTOMATIC;
   } else {
      foreach ( auto sizeName => auto sizeSpec in gIconSizes ) {
         if ( sizeSpec == def_toolbar_tab_pic_size || sizeSpec:+"x":+sizeSpec == def_toolbar_tab_pic_size ) {
            ctl_tab_icon_size.p_text = sizeName;
         }
      }
   }

   ctl_tree_icon_size._lbadd_item(CONFIG_AUTOMATIC);
   ctl_tree_icon_size._lbadd_item("Extra Small");
   ctl_tree_icon_size._lbadd_item("Small");
   ctl_tree_icon_size._lbadd_item("Medium");
   ctl_tree_icon_size._lbadd_item("Large");
   ctl_tree_icon_size._lbadd_item("Extra Large");
   ctl_tree_icon_size._lbadd_item("Huge");
   ctl_tree_icon_size._lbadd_item("Gigantic");
   ctl_tree_icon_size._lbadd_item("Colossal");
   if (def_toolbar_tree_pic_auto) {
      ctl_tree_icon_size.p_text = CONFIG_AUTOMATIC;
   } else {
      foreach ( auto sizeName => auto sizeSpec in gTreeIconSizes ) {
         if ( sizeSpec == def_toolbar_tree_pic_size || pos("x":+sizeSpec, def_toolbar_tree_pic_size ) ) {
            ctl_tree_icon_size.p_text = sizeName;
         }
      }
   }

}

static int okToolWindowOptions()
{
   new_pic_auto := false;
   new_pic_size := "24";
   if ( ctl_button_size.p_text == CONFIG_AUTOMATIC) {
      new_pic_auto = true;
      new_pic_size = "auto";
   } else if ( gIconSizes._indexin(ctl_button_size.p_text) ) {
      new_pic_size = gIconSizes:[ctl_button_size.p_text];
   }

   // check their horizontal spacing value
   new_hspace := ctl_button_hspace.p_text;
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

   // check the toolbar button style
   new_pic_style := "";
   if ( gIconStyles._indexin(ctl_button_style.p_text) ) {
      new_pic_style = gIconStyles:[ctl_button_style.p_text];
   }

   // save the changes
   needToRefreshToolWindows := false;
   if (def_toolbar_pic_hspace != new_hspace) {
      def_toolbar_pic_hspace = (int) new_hspace;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      _macro_append("def_toolbar_pic_hspace="new_hspace);
      _macro_call('_config_modify_flags', CFGMODIFY_DEFVAR);
      _macro_call('_QToolbarSetSpacing', new_hspace);
      _QToolbarSetSpacing((int)new_hspace);
   }
   if (def_toolbar_pic_size != new_pic_size ||
       def_toolbar_pic_style != new_pic_style) {
      def_toolbar_pic_size = new_pic_size;
      def_toolbar_pic_style = new_pic_style;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      def_toolbar_pic_auto = new_pic_auto;
      tbReloadBitmaps(new_pic_size,new_pic_style,reloadSVGFromDisk:false);
      tbReloadTabBitmaps("",new_pic_style,reloadSVGFromDisk:false);
      _macro_append("def_toolbar_pic_auto="def_toolbar_pic_auto);
      _macro_append("def_toolbar_pic_size="def_toolbar_pic_size);
      _macro_append("def_toolbar_pic_style="new_pic_style);
      _macro_call('_config_modify_flags', CFGMODIFY_DEFVAR);
      _macro_call('tbReloadBitmaps',new_pic_size,new_pic_style,false);
      _macro_call('tbReloadTabBitmaps','',new_pic_style);
      needToRefreshToolWindows = true;

      // force resize/redraw of options form
      options_wid := getOptionsForm();
      if (options_wid > 0 && _iswindow_valid(options_wid)) {

         foreach (auto ctl_name in "_ctl_go_up _ctl_go_back _ctl_go_forward") {
            ctl_wid := options_wid._find_control(ctl_name);
            if (ctl_wid > 0) {
               ctl_wid.p_auto_size = false;
               ctl_wid.p_auto_size = true;
            }
         }
         options_wid.call_event(true, options_wid, ON_RESIZE, "w");
      }
   }

   // Check auto show delay (tenths of a second)
   min := 100;   // 100 ms
   max := 5000;  // 5000 ms
   new_dock_channel_delay := ctl_auto_show_delay.p_text;
   if ( !isinteger(new_dock_channel_delay) || new_dock_channel_delay < min || new_dock_channel_delay > max ) {
      if ( ctl_mouse_over_auto_shows.p_value == 0 ) {
         // Not important. Quietly fix it.
         new_dock_channel_delay = DOCKCHANNEL_HOVER_DELAY;
      } else {
         _str msg = "Auto Show delay must be between "min" and "max" ms";
         _message_box(msg, "", MB_OK | MB_ICONEXCLAMATION);
         p_window_id = ctl_auto_show_delay;
         _set_sel(1, length(p_text) + 1);
         _set_focus();
         return INVALID_NUMBER_ARGUMENT_RC;
      }
   }

   // Check auto hide delay (tenths of a second)
   min = 100;    // 100 ms
   max = 10000;  // 10,000 ms
   new_auto_hide_delay := ctl_auto_hide_delay.p_text;
   if ( !isinteger(new_auto_hide_delay) || new_auto_hide_delay < min || new_auto_hide_delay > max ) {
      _str msg = "Auto Hide delay must be between "min" and "max" ms";
      _message_box(msg, "", MB_OK | MB_ICONEXCLAMATION);
      p_window_id = ctl_auto_hide_delay;
      _set_sel(1, length(p_text) + 1);
      _set_focus();
      return INVALID_NUMBER_ARGUMENT_RC;
   }

   // Close button affects active tab only
   new_toolwindow_options := def_toolwindow_options;
   if ( ctl_close_active_tab.p_value == 0 ) {
      new_toolwindow_options |= TWOPTION_CLOSE_TABGROUP;
   } else {
      new_toolwindow_options &= ~TWOPTION_CLOSE_TABGROUP;
   }
   // Auto Hide button affects active tab only
   if ( ctl_auto_hide_active_tab.p_value != 0 ) {
      new_toolwindow_options |= TWOPTION_NO_AUTOHIDE_TABGROUP;
   } else {
      new_toolwindow_options &= ~TWOPTION_NO_AUTOHIDE_TABGROUP;
   }
   // tool window menu toggles show/hide
   if ( ctl_menu_tool_window_toggle.p_value != 0 ) {
      new_toolwindow_options |= TWOPTION_MENU_TOGGLE_SHOW_HIDE;
   } else {
      new_toolwindow_options &= ~TWOPTION_MENU_TOGGLE_SHOW_HIDE;
   }
   if ( new_toolwindow_options != def_toolwindow_options ) {
      def_toolwindow_options = new_toolwindow_options;
      _macro_append("def_toolwindow_options="new_toolwindow_options);
      _macro_call('_config_modify_flags', CFGMODIFY_DEFVAR);
      _config_modify_flags(CFGMODIFY_DEFVAR);
   }

   // Auto Show delay.
   // Convert to milliseconds
   int old_dock_channel_delay = _default_option(VSOPTION_DOCKCHANNEL_HOVER_DELAY);
   if ( new_dock_channel_delay != old_dock_channel_delay ) {
      _default_option(VSOPTION_DOCKCHANNEL_HOVER_DELAY, (int)new_dock_channel_delay);
   }
   // Auto Show tool window on mouse over
   int old_dock_channel_flags = _default_option(VSOPTION_DOCKCHANNEL_FLAGS);
   int new_dock_channel_flags = old_dock_channel_flags;
   if ( ctl_mouse_over_auto_shows.p_value == 0 ) {
      new_dock_channel_flags &= ~(VSOPTION_DOCKCHANNEL_HOVER);
   } else {
      new_dock_channel_flags |= VSOPTION_DOCKCHANNEL_HOVER;
   }

   if( new_dock_channel_flags != old_dock_channel_flags ) {
      _default_option(VSOPTION_DOCKCHANNEL_FLAGS, new_dock_channel_flags);
   }
   // Auto Hide delay.
   // Convert to milliseconds
   int old_auto_hide_delay = _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY);
   if ( new_auto_hide_delay != old_auto_hide_delay ) {
      _default_option(VSOPTION_TOOLWINDOW_AUTOHIDE_DELAY, (int)new_auto_hide_delay);
   }

   // handle the new tab pic size
   new_tab_pic_size := "20";
   new_tab_pic_auto := false;
   if ( ctl_tab_icon_size.p_text == CONFIG_AUTOMATIC) {
      new_tab_pic_auto = true;
      new_tab_pic_size = "auto";
   } else if ( gIconSizes._indexin(ctl_tab_icon_size.p_text) ) {
      new_tab_pic_size = gIconSizes:[ctl_tab_icon_size.p_text];
   }
   if (def_toolbar_tab_pic_size != new_tab_pic_size) {
      def_toolbar_tab_pic_auto = new_tab_pic_auto;
      needToRefreshToolWindows = true;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      tbReloadTabBitmaps(new_tab_pic_size, def_toolbar_pic_style, reloadSVGFromDisk:false);
      _macro_call('_config_modify_flags', CFGMODIFY_DEFVAR);
      _macro_append("def_toolbar_tab_pic_auto="def_toolbar_tab_pic_auto);
      _macro_append("def_toolbar_tab_pic_size="def_toolbar_tab_pic_size);
      _macro_call('tbReloadTabBitmaps',new_tab_pic_size, def_toolbar_pic_style, false);
   }

   new_tree_pic_size := "14";
   new_tree_pic_auto := false;
   if ( ctl_tree_icon_size.p_text == CONFIG_AUTOMATIC) {
      new_tree_pic_auto = true;
      new_tree_pic_size = "auto";
   } else if ( gTreeIconSizes._indexin(ctl_tree_icon_size.p_text) ) {
      new_tree_pic_size = gTreeIconSizes:[ctl_tree_icon_size.p_text];
   }
   if (def_toolbar_tree_pic_size != new_tree_pic_size) {
      def_toolbar_tree_pic_auto = new_tree_pic_auto;
      needToRefreshToolWindows = true;
      _config_modify_flags(CFGMODIFY_DEFVAR);
      tbReloadTreeBitmaps(new_tree_pic_size, def_toolbar_pic_style, reloadSVGFromDisk:false);
      _macro_append("def_toolbar_tree_pic_auto="def_toolbar_tree_pic_auto);
      _macro_append("def_toolbar_tree_pic_size="def_toolbar_tree_pic_size);
      _macro_call('_config_modify_flags', CFGMODIFY_DEFVAR);
      _macro_call('tbReloadTreeBitmaps',new_tree_pic_size, def_toolbar_pic_style, false);
   }

   if ( needToRefreshToolWindows ) {
      tw_refresh_all();
   }

   // that's all folks
   return 0;
}

// make the dialog resizable
void _tool_windows_prop_form.on_resize()
{
   // enforce minimum size - only if not embedded in options dialog
   // if we have not yet set the min sizes, _minimum_width will return 0
   if( !_minimum_width() ) {
      // come up with a good minimum size
      int min_width = ctl_toolbar_size_frame.p_x_extent + ctl_tool_window_options.p_x*2;
      int min_height = ctl_toolbar_size_frame.p_y_extent + ctl_tool_window_options.p_y*2;
      _set_minimum_size(min_width, min_height);
   }

}

bool auto_show_tw_mouseover(bool value = null)
{
   if (value == null) {
      value = (0 != (_default_option(VSOPTION_DOCKCHANNEL_FLAGS) & VSOPTION_DOCKCHANNEL_HOVER));
   } else {
      int old_dock_channel_flags = _default_option(VSOPTION_DOCKCHANNEL_FLAGS);
      int new_dock_channel_flags = old_dock_channel_flags;

      if ( value ) {
         new_dock_channel_flags |= VSOPTION_DOCKCHANNEL_HOVER;
      } else {
         new_dock_channel_flags &= ~(VSOPTION_DOCKCHANNEL_HOVER);
      }

      if( new_dock_channel_flags != old_dock_channel_flags ) {
         _default_option(VSOPTION_DOCKCHANNEL_FLAGS, new_dock_channel_flags);
      }
   }

   return value;
}

void ctl_mouse_over_auto_shows.lbutton_up()
{
   enabled := (p_value!=0);
   ctl_auto_show_delay_label.p_enabled=enabled;
   ctl_auto_show_delay.p_enabled=enabled;
   ctl_auto_show_delay_spinner.p_enabled=enabled;
}

void ctltooltips.lbutton_up()
{
   ctltooltipdelay.p_next.p_enabled=ctltooltipdelay.p_enabled=(ctltooltips.p_value!=0);
}

static void refresh_toolbar_button_preview()
{
   new_pic_size := 24;
   if ( gIconSizes._indexin(ctl_button_size.p_text) ) {
      new_pic_size = gIconSizes:[ctl_button_size.p_text];
   } else if (ctl_button_size.p_text == CONFIG_AUTOMATIC) {
      new_pic_size = tbGetAutomaticBitmapSize("bar");
   }

   // check their horizontal spacing value
   new_hspace := ctl_button_hspace.p_text;
   if (!isinteger(new_hspace)) {
      new_hspace = 4;
   }

   // check the toolbar button style
   new_style := "flat";
   if ( gIconStyles._indexin(ctl_button_style.p_text) ) {
      new_style = gIconStyles:[ctl_button_style.p_text];
      if ( new_style == "" ) new_style="flat";
   }

   // preview the changes to the toolbar icons
   new_filename1 := "bbcalculator.svg@":+new_style:+new_pic_size;
   new_filename2 := "bbcalendar.svg@":+new_style:+new_pic_size;
   new_filename3 := "bbopen.svg@":+new_style:+new_pic_size;
   new_picture1 := _find_or_add_picture(new_filename1);
   new_picture2 := _find_or_add_picture(new_filename2);
   new_picture3 := _find_or_add_picture(new_filename3);
   if (new_picture1 > 0) ctl_image1.p_picture = new_picture1;
   if (new_picture2 > 0) ctl_image2.p_picture = new_picture2;
   if (new_picture3 > 0) ctl_image3.p_picture = new_picture3;
   ctl_image1.refresh('w');
   ctl_image2.refresh('w');
   ctl_image3.refresh('w');
   ctl_image2.p_x = ctl_image1.p_x_extent + _dx2lx(SM_TWIP,(int)new_hspace);
   ctl_image3.p_x = ctl_image2.p_x_extent + _dx2lx(SM_TWIP,(int)new_hspace);
}

static void refresh_tool_window_tab_icon_preview()
{
   // check the toolbar button style
   new_style := "flat";
   if ( gIconStyles._indexin(ctl_button_style.p_text) ) {
      new_style = gIconStyles:[ctl_button_style.p_text];
      if ( new_style == "" ) new_style="flat";
   }

   // get new tab pic size
   new_tab_pic_size := 20;
   if ( gIconSizes._indexin(ctl_tab_icon_size.p_text) ) {
      new_tab_pic_size = gIconSizes:[ctl_tab_icon_size.p_text];
   } else if (ctl_tab_icon_size.p_text == CONFIG_AUTOMATIC) {
      new_tab_pic_size = tbGetAutomaticBitmapSize("tab");
   }
   
   // preview the changes to the tool window tab icons
   new_filename1 := "tbopen.svg@":+new_style:+new_tab_pic_size;
   new_filename2 := "tbfind.svg@":+new_style:+new_tab_pic_size;
   new_picture1 := _find_or_add_picture(new_filename1);
   new_picture2 := _find_or_add_picture(new_filename2);
   ctl_tab_sstab.p_height = _dy2ly(SM_TWIP, new_tab_pic_size+2);
   while (ctl_tab_sstab.p_NofTabs > 0) {
      ctl_tab_sstab.p_ActiveTab=0;
      ctl_tab_sstab._deleteActive();
   }
   if (new_picture1 > 0) {
      ctl_tab_sstab.p_NofTabs++;
      ctl_tab_sstab.p_ActiveTab=0;
      ctl_tab_sstab.p_ActivePicture=new_picture1;
      ctl_tab_sstab.p_ActiveCaption="Open";
   }
   if (new_picture2 > 0) {
      ctl_tab_sstab.p_NofTabs++;
      ctl_tab_sstab.p_ActiveTab=1;
      ctl_tab_sstab.p_ActivePicture=new_picture2;
      ctl_tab_sstab.p_ActiveCaption="Find";
   }

   // adjust the height of the sample tab control
   ctl_tab_sstab.p_ActiveTab=0;
   ctl_tab_sstab.refresh('w');
}

void ctl_tab_icon_size.on_change()
{
   if ( gin_on_create ) return;
   refresh_tool_window_tab_icon_preview();
}
void ctl_button_size.on_change()
{
   if ( gin_on_create ) return;
   refresh_toolbar_button_preview();
}
void ctl_button_hspace.on_change()
{
   if ( gin_on_create ) return;
   refresh_toolbar_button_preview();
}
void ctl_button_style.on_change()
{
   if ( gin_on_create ) return;
   refresh_toolbar_button_preview();
   refresh_tool_window_tab_icon_preview();
}

static void oncreateToolbarOptions()
{
   gin_on_create = true;
   if ( _find_control("ctltooltips") ) {
      ctltooltips.p_value = (int)(_default_option(VSOPTION_SHOWTOOLTIPS) != 0);
      ORIGINAL_SHOWTOOLTIPS(ctltooltips.p_value);

      ctltooltipdelay.p_next.p_enabled = ctltooltipdelay.p_enabled=(ctltooltips.p_value!=0);
      ctltooltipdelay.p_text = 100*_default_option(VSOPTION_TOOLTIPDELAY);
      ORIGINAL_TOOLTIPSDELAY(ctltooltipdelay.p_text);
   }
   ctlhidetoolbar.p_value = (int)def_hidetoolbars;
   ORIGINAL_HIDETB(ctlhidetoolbar.p_value);

   // populate the list of toolbar button sizes
   // skip Jumbo/64x64 until we decide to support it
   ctl_button_size._lbadd_item(CONFIG_AUTOMATIC);
   ctl_button_size._lbadd_item("Extra Small");
   ctl_button_size._lbadd_item("Small");
   ctl_button_size._lbadd_item("Medium");
   ctl_button_size._lbadd_item("Large");
   ctl_button_size._lbadd_item("Extra Large");
   ctl_button_size._lbadd_item("Huge");
   ctl_button_size._lbadd_item("Gigantic");
   ctl_button_size._lbadd_item("Colossal");
   if (def_toolbar_pic_auto) {
      ctl_button_size.p_text = CONFIG_AUTOMATIC;
   } else {
      foreach ( auto sizeName => auto sizeSpec in gIconSizes ) {
         if ( sizeSpec == def_toolbar_pic_size || sizeSpec:+"x":+sizeSpec == def_toolbar_pic_size ) {
            ctl_button_size.p_text = sizeName;
         }
      }
   }

   // populate the list of toolbar button styles
   ctl_button_style._lbadd_item("Default (Low-color)");
   ctl_button_style._lbadd_item("Color");
   ctl_button_style._lbadd_item("Monochrome");
   ctl_button_style._lbadd_item("Green (Two-tone)");
   ctl_button_style._lbadd_item("Blue (Two-tone)");
   ctl_button_style._lbadd_item("Orange (Two-tone)");
   foreach ( auto styleName => auto styleSpec in gIconStyles ) {
      if ( styleSpec == def_toolbar_pic_style ) {
         ctl_button_style.p_text = styleName;
      }
   }

   for (i:=0; i<10; i++) {
      ctl_button_hspace._lbadd_item(i);
   }
   ctl_button_hspace._cbset_text(def_toolbar_pic_hspace);

   gin_on_create = false;
   refresh_toolbar_button_preview();
   refresh_tool_window_tab_icon_preview();
}

