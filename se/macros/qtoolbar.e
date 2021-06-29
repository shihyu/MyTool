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
#import "main.e"
#import "menu.e"
#import "picture.e"
#import "tbcontrols.e"
#import "tbprops.e"
#import "tbview.e"
#import "toolbar.e"
#import "stdprocs.e"
#endregion

// Default tool bar forms converted to QToolbar
// _tbstandard_form
// _tbproject_tools_form
// _tbtools_form
// _tbedit_form
// _tbseldisp_form
// _tbxml_form
// _tbhtml_form
// _tbtagging_form
// _tbvc_form
// _tbdebugbb_form
// _tbcontext_form
// _tbdebug_sessions_form
// _tbunified_form

definit()
{
   _QToolbarSetSpacing(def_toolbar_pic_hspace);
}

void _tbResetDefaultQToolbars()
{
   form_name := "";
   hasStandardToolbar := true;

   if (_isMac()) {
      form_name="_tbunified_form";
      _tbLoadQToolbarName(form_name);
   } else {
      form_name="_tbstandard_form";
      _tbLoadQToolbarName(form_name);
      if (_haveCurrentContextToolBar()) {
         form_name="_tbcontext_form";
         _tbLoadQToolbarName(form_name);
      }
   }

   if( _tbDebugQMode() ) {
      if (hasStandardToolbar) {
         _QToolbarAddBreak(DOCKINGAREA_TOP);
      }
      form_name="_tbdebugbb_form";
      _tbLoadQToolbarName(form_name);
   }

}

_command void tbToggleMacUnifiedToolbar() name_info(',')
{
   int unified = _QToolbarGetUnifiedToolbar();
   int new_value = (unified != 0) ? 0 : 1;
   _QToolbarSetUnifiedToolbar(new_value);
}

void _tbSetUnifiedToolbar(int value)
{
   _QToolbarSetUnifiedToolbar((value != 0) ? 1 : 0);
}

int _tbLoadQToolbar(int resource_index, int tbflags, bool hidden = true, int area = -1)
{
   // check to see if eventab2 needs to be reset
   if (resource_index != 0 && resource_index.p_object == OI_FORM) {
      eventtab2 := find_index('_qtoolbar_etab2', EVENTTAB_TYPE);
      if (resource_index.p_eventtab2 != eventtab2) {
         resource_index.p_eventtab2 = eventtab2;
      }
   }

   wid := _load_template(resource_index, _mdi.p_window_id, 'THP');
   if (area < 0) {
      area = DOCKINGAREA_TOP;
   }
   if (wid) {
      _QToolbarAdd(wid, area);
      if (!hidden) {
         wid.p_visible = true;
      }
   }

   if (_tbDragDropMode()) {
      _tbPropsToolbarEdit(wid, 1);
   }
   return wid;
}

int _tbLoadQToolbarName(_str form_name, bool hidden = false, int area = -1)
{
   // refuse to bring up tool windows not supported by this edition
   switch (form_name) {
   case "_tbcontext_form":
      if (!_haveCurrentContextToolBar()) return 0;
      break;
   case "_tbdebugbb_form":
   case "_tbdebug_sessions_form":
      if (!_haveDebugging()) return 0;
      break;
   case "_tbvc_form":
      if (!_haveVersionControl()) return 0;
      break;
   case "_tbxml_form":
      if (!_haveXMLValidation()) return 0;
      break;
   case "_tbbufftabs_form":
      if (!_haveFileTabsWindow()) return 0;
      break;
   default:
      break;
   }

   _TOOLBAR* ptb = _tbFind(form_name);
   if (!ptb) {
      return 0;
   }

   int wid = _find_formobj(form_name, 'N');
   if (wid != 0) return wid;

   int index = find_index(form_name, oi2type(OI_FORM));
   if (!index) {
      return 0;
   }
   return _tbLoadQToolbar(index, ptb->tbflags, hidden, area);
}

void _tbDeleteAllQToolbars()
{
   _QToolbarRemoveAll();
   int i, n = def_toolbartab._length();
   for (i = 0; i < n; ++i) {
       int wid = _find_formobj(def_toolbartab[i].FormName,'N');
       if (wid != 0 && _IsQToolbar(wid)) wid._delete_window();
   }
}

void _tbDeleteQToolbar(int wid)
{
   if (wid && _iswindow_valid(wid)) {
      _QToolbarRemove(wid);
      wid._delete_window();
   }
}

void _tbQToolbarSetDockable(int wid, bool dockable)
{
   int wasFloating = _QToolbarGetFloating(wid);
   _QToolbarSetDockable(wid, !dockable ? 0 : 0xf);
   if (!dockable && !wasFloating) {
      _QToolbarSetFloating(wid, 1);
   }
}

int _tbQToolbarOnUpdateFloatingToggle(int wid)
{
   int wasFloating = _QToolbarGetFloating(wid);
   if (!wasFloating) {
      // Docked
      return(MF_ENABLED|MF_UNCHECKED);
   } else {
      // Floating
      return(MF_ENABLED|MF_CHECKED);
   }
}

void _tbQToolbarFloatingToggle(int wid)
{
   int wasFloating = _QToolbarGetFloating(wid);
   _QToolbarSetFloating(wid, !wasFloating ? 1 : 0);
}

int _tbQToolbarOnUpdateMovableToggle(int wid)
{
   int movable = _QToolbarGetMovable(wid);
   if (!movable) {
      return(MF_ENABLED|MF_UNCHECKED);
   } else {
      return(MF_ENABLED|MF_CHECKED);
   }
}

void _tbQToolbarMovableToggle(int wid)
{
   int movable = _QToolbarGetMovable(wid);
   _QToolbarSetMovable(wid, !movable ? 1 : 0);
}

void autorestore_qtoolbars(_str option, int& noflines)
{
   tbstate := "";
   if (option=='r' || option=='n') {
      down();
      get_line(auto line); --noflines;
      typeless noftoolbars;
      parse line with auto restore_name noftoolbars . .;

      if (restore_name != 'QTOOLBAR') {
         down(noflines);
         return;
      } else {
         down();
         get_line(tbstate); --noflines;
      }

      formName := "";
      typeless locked;
      int wid;
      int viewToolbars:[];
      int i, n = def_toolbartab._length();
      for (i = 0; i < n; ++i) {
         if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
            continue;
         }
         formName = def_toolbartab[i].FormName;
         //wid = _tbIsVisible(formName);
         wid = _tbGetWid(formName);
         if (wid != 0) {
            viewToolbars:[formName] = wid;
         }
      }
      
      _QToolbarSetUnifiedToolbar(0);

      ToolbarFeatures features;

      int loaded[];
      typeless movable[];
      while (noftoolbars-- > 0) {
         down();
         get_line(line);
         parse line with formName locked .;

         _TOOLBAR* ptb = _tbFind(formName);
         if (ptb && !isinteger(ptb->rflags)) ptb->rflags=0;
         if ( ptb && !(ptb->tbflags & TBFLAG_SIZEBARS) && features.testFlags(ptb->rflags) ) {
            if ( viewToolbars._indexin(formName) ) {
               viewToolbars._deleteel(formName);
               continue;
            }

            orig_wid := p_window_id;
            wid = _tbLoadQToolbarName(formName, true);
            if ( wid ) {
               loaded[loaded._length()] = wid;
               movable[movable._length()] = locked;
            }
            p_window_id = orig_wid;
         }
      }

      foreach ( formName => wid in viewToolbars ) {
         _tbDeleteQToolbar(wid);
      }

      if (tbstate != '') {
         _QToolbarSetState(tbstate);
      }

      // show loaded toolbars
      n = loaded._length();
      for (i = 0; i < n; ++i) {
         wid = loaded[i];
         wid.p_visible = true;

         if (movable[i] == '0') {
            _QToolbarSetMovable(wid, 0);
         }
      }

   } else {
      int wid;
      noflines = 0;
      save_pos(auto p);
      _QToolbarGetState(tbstate);
      insert_line(tbstate); ++noflines;
      
      ntoolbars := 0;
      int i, n = def_toolbartab._length();
      for (i = 0; i < n; ++i) {
         if (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS) {
            continue;
         }

         //wid = _tbIsVisible(def_toolbartab[i].FormName);
         wid = _find_formobj(def_toolbartab[i].FormName, 'n');
         if ( wid ) {
            int movable = _QToolbarGetMovable(wid);
            insert_line(def_toolbartab[i].FormName' 'movable); ++noflines; ++ntoolbars;
         }
      }

      orig_line := p_line;
      restore_pos(p);
      insert_line('QTOOLBAR 'ntoolbars' '0); ++noflines;
      p_line=orig_line + 1;
   }
}

defeventtab _qtoolbar_etab2;

void _qtoolbar_etab2.on_create()
{
   // Let the timers update the toolbars.
   // This new single file project code should work if we do this but we haven't even 
   // trestored he workspace or current file. Both are needed to know what build tools 
   // we have.
   //_tbSetToolbarEnable(p_window_id);
}

void _qtoolbar_etab2.on_destroy()
{
}

void _tbDismiss(int active_form)
{
   int child_wid = _MDICurrentChild(0);
   if ( child_wid ) {
      p_window_id = child_wid;
      _set_focus();
   } else if( !_QToolbarGetFloating(active_form) ) {
      _cmdline._set_focus();
   }
}

void _qtoolbar_etab2.ESC()
{
   _tbDismiss(p_active_form);
}

void _qtoolbar_etab2.rbutton_up()
{
   if (!isEclipsePlugin()) {
      list_toolbars := ( arg(1)=="" );
      args :=  list_toolbars','p_window_id;
      _post_call(_tbPostedContextMenu,args);
   }
}

void _qtoolbar_etab2.lbutton_double_click()
{
   if (p_window_id != p_active_form && !_ImageIsSpace()) {
      // Not a valid area to toggle from
      return;
   }

   int movable = _QToolbarGetMovable(p_active_form);
   if (movable) {
      tbFloatingToggle(p_active_form);
   }
}

