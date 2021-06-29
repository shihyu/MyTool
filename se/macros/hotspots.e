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
#include "markers.sh"
#require "se/ui/HotspotMarkers.e"
#import "stdprocs.e"
#import "adaptiveformatting.e"
#import "seek.e"
#endregion

using se.ui.HotspotMarkers;

/**
 * If enabled, alias and syntax expansion can define hotspots
 * in order to have multiple cursor stops.
 * <p>
 * For example, if you have an alias such as:
 * <pre>
 *     if ( %\c) {
 *         %\c
 *     }
 * </pre>
 * <p>
 * Initially the cursor will be positioned at the first cursor
 * stops (%\c), when you hit Ctrl+[ (next_hotspot), the cursor
 * will jump to the next hotspot within the brace block.
 * 
 * @default true
 * @categories Configuration_Variables
 * 
 * @see expand_alias
 * @see c_space
 * @see next_hotspot
 * @see prev_hotspot
 */
bool def_hotspot_navigation=true;

static bool current_hotspot()
{
   return HotspotMarkers.active();
}

/**
 * Determine whether next/prev hotspot should be enabled.
 */
int _OnUpdate_next_hotspot(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || !target_wid._isEditorCtl()) {
      return MF_GRAYED;
   }
   if (_no_child_windows()) return MF_GRAYED;
   return (target_wid.current_hotspot()) ? MF_ENABLED : MF_GRAYED;
}

int _OnUpdate_prev_hotspot(CMDUI &cmdui,int target_wid,_str command)
{
   if (!target_wid || !target_wid._isEditorCtl()) {
      return MF_GRAYED;
   }
   if (_no_child_windows()) return MF_GRAYED;
   return (target_wid.current_hotspot()) ? MF_ENABLED : MF_GRAYED;
}

/**
 * Jump to the next or previous hotspot marker.
 * 
 * @param dir     + means forward, - means backwards
 * 
 * @return true if successful
 * 
 * @see add_hotspot
 * @see next_hotspot
 * @see prev_hotspot
 */
static bool nextprev_hotspot(_str dir)
{
   // ignore hotspot navigation?
   if (!def_hotspot_navigation) {
      return false;
   }
   // not an editor control?
   if (!_isEditorCtl()) {
      return false;
   }

   HotspotMarkers.nextPrevHotspot(dir == '+');
   return true;
}

/**
 * Navigate from the current hotspot to the previous hotspot.
 * 
 * @return true if we jumped to the hotspot, false otherwise
 * 
 * @see add_hotspot
 * @see next_hotspot
 * @see clear_hotspots
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Bookmark_Functions
 */
_command bool prev_hotspot() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_EDITORCTL)
{
   return nextprev_hotspot('-');
}

/**
 * Navigate from the current hotspot to the next hotspot.
 * 
 * @return true if we jumped to the hotspot, false otherwise
 * 
 * @see add_hotspot
 * @see prev_hotspot
 * @see clear_hotspots
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Bookmark_Functions
 */
_command bool next_hotspot() name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_EDITORCTL)
{
   return nextprev_hotspot('+');
}

/**
 * Clear all hotspot information.
 * 
 * @see expand_alias
 * @see add_hotspot
 * @see next_hotspot
 * @see prev_hotspot
 * 
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Bookmark_Functions
 */
_command void clear_hotspots()
{
   HotspotMarkers.clearHotspots();
}

/**
 * Add a hotspot at the current cursor location within the current
 * buffer.
 *  
 * @appliesTo  Edit_Window, Editor_Control
 * @categories Bookmark_Functions
 */
void add_hotspot()
{
   if (_MultiCursor()) return;
   // is this feature disabled?
   if (!def_hotspot_navigation) {
      return;
   }
   // pad out line?   marker needs a physical offset
   if (p_col >= _text_colc(0, 'E') + 1) {
      get_line(auto line);
      replace_line(line:+indent_string((p_col - 1) - _text_colc(0, 'E')));
   }
   HotspotMarkers.addHotspot(_QROffset());
}

void show_hotspots()
{
   if (_MultiCursor()) return;
   // is this feature disabled?
   if (!def_hotspot_navigation) {
      return;
   }
   HotspotMarkers.showHotspots();
}
