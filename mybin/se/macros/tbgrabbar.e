////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44719 $
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
#import "dlgman.e"
#import "stdprocs.e"
#endregion


//
// _bbgrabbar_form
//

defeventtab _bbgrabbar_form;

/**
 * Operates on active _bbgrabbar_form wid.
 */
int _bbgrabbarChildForm()
{
   int formwid = 0;
   int first_child = p_child;
   int child = first_child;
   while( child!=0 ) {
      if( child.p_object==OI_FORM ) {
         formwid=child;
         break;
      }
      child=child.p_next;
      if( child==first_child ) {
         break;
      }
   }
   return formwid;
}

void _bbgrabbar_form.on_destroy()
{
   //say('_bbgrabbar_form.ON_DESTROY: in');
   // The ON_DESTROY event is not called for child forms (p_object==OI_FORM)
   // when the parent form (_tbpanel_form) is _delete_window()'ed, so we
   // must call it explicity for the child tool window so that docking state, etc.
   // is saved in def_toolbartab.
   int wid = p_active_form._bbgrabbarChildForm();
   if( wid>0 ) {
      wid.call_event(wid,ON_DESTROY,'W');
   }
}

void _bbgrabbar_form.on_close()
{
   int wid = p_active_form._bbgrabbarChildForm();
   if( wid>0 ) {
      // Some OEMs rely on ON_CLOSE being called in order to save data
      // associated with their tool window, so call it.
      // IMPORTANT:
      // We use _event_handler() to check for the existence of an
      // ON_CLOSE event handler because the default handler will
      // destroy the form. We do not want that to happen if we can
      // avoid it, since WE want to be the one to dispose of the
      // form.
      _str handler = wid._event_handler(on_close);
      if( handler!=0 ) {
         // Window ids are reused a lot, so it is not enough to check the wid
         _str FormName = wid.p_name;
         // false=not docking
         wid.call_event(false,wid,on_close,'w');
      }
   }
   p_active_form._delete_window();
}

/**
 * Acts on the active window which must be a _bbgrabbar_form.
 */
void _bbgrabbarUpdate(int formwid=0)
{
   if( formwid==0 ) {
      // Find the child form
      formwid=_bbgrabbarChildForm();
   }
   if( formwid>0 ) {
      _str caption = formwid.p_caption;
      if( !formwid.p_enabled ) {
         // Form is disabled, so set caption so it is obvious
         caption=caption" (disabled)";
      }
      if( p_caption!=caption ) {
         p_caption=caption;
      }
   }
}

_bbgrabbar_form.on_resize()
{
   int clientW = _dx2lx(p_active_form.p_xyscale_mode,p_active_form.p_client_width);
   int clientH = _dy2ly(p_active_form.p_xyscale_mode,p_active_form.p_client_height);

   // Adjust grabbar height
   ctl_grabbar1.p_height=clientH;
   ctl_grabbar2.p_height=clientH;

   // Position child form to the right of grabbar
   int formwid = p_active_form._bbgrabbarChildForm();
   if( formwid>0 ) {

      // Not really the right place to do this, but it saves
      // us from having to make a separate event just to update
      // the caption.
      _bbgrabbarUpdate(formwid);

      formwid.p_visible=false;
      // This is arbitrary, but looks nice
      int new_x = ctl_grabbar2.p_x + 7*_twips_per_pixel_x();
      if( new_x!=formwid.p_x ) {
         formwid.p_x = new_x;
      }
      int new_y = 0;
      if( new_y!=formwid.p_y ) {
         formwid.p_y=new_y;
      }
      int new_width = clientW - formwid.p_x;
      if( new_width!=formwid.p_width ) {
         formwid.p_width=new_width;
      }
      int new_height = clientH;
      if( new_height!=formwid.p_height ) {
         formwid.p_height=new_height;
      }
      formwid.p_visible=true;
   }
}

// Relay mouse events to child/hosted form

void _bbgrabbar_form.lbutton_double_click()
{
   int formwid = p_active_form._bbgrabbarChildForm();
   formwid.call_event(formwid,LBUTTON_DOUBLE_CLICK);
}
void _bbgrabbar_form.lbutton_down()
{
   //say('_bbgrabbar_form.lbutton_down: in');
   int formwid = p_active_form._bbgrabbarChildForm();
   formwid.call_event(formwid,LBUTTON_DOWN);
}
void _bbgrabbar_form.lbutton_up()
{
   int formwid = p_active_form._bbgrabbarChildForm();
   formwid.call_event(formwid,LBUTTON_UP);
}
void _bbgrabbar_form.rbutton_up()
{
   int formwid = p_active_form._bbgrabbarChildForm();
   formwid.call_event(formwid,RBUTTON_UP);
}

boolean _bbgrabbarIsGrabbarForm(int wid)
{
   if( wid>0 && wid.p_name=="_bbgrabbar_form" ) {
      return true;
   }
   return false;
}
// Ctrl+Shift+Space will edit the grabbar form when what we really want to
// edit is the tool window inside.
void _bbgrabbar_form."c-s- "()
{
   int grabbar_wid = p_active_form;
   int formwid = p_active_form._bbgrabbarChildForm();
   _str formName = "";
   if ( formwid > 0 ) {
      p_window_id=formwid;
      formName=formwid.p_name;
   }
   // Call automatic inheritance handler
   call_event(defeventtab _ainh_dlg_manager,name2event('C-S- '),'e');
   // _ainh_dlg_manager.'c-s- ' may have done nothing, so check to be
   // sure the form was actually destroyed inside the grabbar form.
   if( formwid > 0 && grabbar_wid._bbgrabbarChildForm() == 0 ) {
      // Now destroy the empty grabbar form
      grabbar_wid._delete_window();
   }
}
