////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47272 $
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
#import "eclipse.e"
#import "files.e"
#import "listbox.e"
#import "qtoolbar.e"
#import "stdprocs.e"
#import "tbautohide.e"
#import "tbpanel.e"
#import "tbtabgroup.e"
#import "toolbar.e"
#import "dockchannel.e"
#endregion

_TOOLBAR def_toolbartab[];

// View containing full screen layout auto-restore information
static int _tbfullscreen_layout_view_id;
// View containing standard toolbar auto-restore information
static int _tbstandard_layout_view_id;
// View containing full screen debug toolbar auto-restore information
static int _tbfullscreen_debug_layout_view_id;
// View containing debug toolbar auto-restore information
static int _tbdebug_layout_view_id;
// View containing full screen slick-c debug toolbar auto-restore information
static int _tbfullscreen_slickc_debug_layout_view_id;
// View containing slick-c debug toolbar auto-restore information
static int _tbslickc_debug_layout_view_id;
// Indicates whether the current toolbars settings are for the debug toolbars
boolean _tbdebug_mode;
// Indicates whether the current toolbars settings are for the slick-c debug toolbars
boolean _tbslickc_debug_mode;
// Indicates whether we are using the full screen toolbars
boolean _tbfullscreen_mode;

struct _RECYCLETOOLBAR {

   // As of 10.0 wid is more a boolean indicator that we need to look
   // for the original form. The wid is not necessarily valid.
   // Explanation:
   // 10.0 introduced tab-linked tool windows. When the next-to-last
   // tool window is closed in a tabgroup, the tab control is destroyed
   // and the remaining tool window is recreated inside a panel, which
   // changes the wid. In that case, the stored wid in ptb->wid is no
   // longer valid.
   // Note:
   // The above explanation probably will not matter because we will
   // disallow tab-linked tool windows from being held open when switching
   // layouts (e.g. Debug, Full Screen).
   int wid;

   boolean restore_docked;

   // Initialized only if restore_docked==true
   int docked_area;
};

// Used to hold open (recycle) tool windows during restore (e.g. autorestore,
// fullscreen, etc.) that would just have been recreated any way. Save a little time.
static _RECYCLETOOLBAR gRecycleToolbar:[];

// Sides that are not refreshed as tool windows are deleted
static boolean gRestoreNoDockedRefresh:[];

definit()
{
   gRecycleToolbar._makeempty();
   gRestoreNoDockedRefresh._makeempty();

   if( arg(1)!='L' ) {
      // Editor initialization case

      // Indicate we are not in debug mode
      _tbDebugSetMode(false);

      // Indicate we are not in full screen mode.
      _tbFullScreenSetMode(false);
   }

   // Indicated that we don't have a view containing 
   // standard toolbar auto-restore information
   _tbstandard_layout_view_id=0;
   int window_group_view_id;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   int status=find_view('._tbstandard_layout');
   if( status==0 ) {
      get_window_id(_tbstandard_layout_view_id);
   }

   // Indicated that we don't have a view containing 
   // debug toolbar auto-restore information
   _tbdebug_layout_view_id=0;
   status=find_view('._tbdebug_layout');
   if( status==0 ) {
      get_window_id(_tbdebug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we don't have a view containing 
   // slickc debug toolbar auto-restore information
   _tbslickc_debug_layout_view_id=0;
   status=find_view('._tbslickc_debug_layout');
   if( status==0 ) {
      get_window_id(_tbslickc_debug_layout_view_id);
   }
   _safe_hidden_window();
   activate_window(window_group_view_id);

   // Indicated that we don't have a view containing 
   // full screen toolbar auto-restore information
   _tbfullscreen_layout_view_id=0;
   get_window_id(window_group_view_id);
   activate_window(VSWID_HIDDEN);
   status=find_view('._tbfullscreen_layout');
   if( status==0 ) {
      get_window_id(_tbfullscreen_layout_view_id);
   }

   // Indicated that we don't have a view containing
   // full screen debug toolbar auto-restore information
   _tbfullscreen_debug_layout_view_id=0;
   status=find_view('._tbfullscreen_debug_layout');
   if( status==0 ) {
      get_window_id(_tbfullscreen_debug_layout_view_id);
   }

   // Indicated that we don't have a view containing
   // full screen slickc debug toolbar auto-restore information
   _tbfullscreen_slickc_debug_layout_view_id=0;
   status=find_view('._tbfullscreen_slickc_debug_layout');
   if( status==0 ) {
      get_window_id(_tbfullscreen_slickc_debug_layout_view_id);
   }
}

// List of the "big" toolbars.
static _str bigToolbarList[] = {
   "_tbFTPClient_form"
};

/**
 * Check to see if the specified tool window is considered to be a "big"
 * toolbar.
 * 
 * @param tbname Name of tool window form.
 * 
 * @return true if tbname is a big toolbar, otherwise false.
 */
static boolean isABigToolbar(_str tbname)
{
   int i;
   for( i=0;i<bigToolbarList._length();i++ ) {
      if( tbname==bigToolbarList[i] ) {
         return(1);
      }
   }
   return(0);
}

/**
 * Is tool window with name formName currently being recycled?
 * 
 * @param formName
 * 
 * @return true if form is currently being recycled.
 */
boolean _tbIsRecyclable(_str formName)
{
   _RECYCLETOOLBAR* ptb = gRecycleToolbar._indexin(formName);
   // ptb->wid has to be valid in order to be recyclable
   if( ptb && ptb->wid > 0 && _iswindow_valid(ptb->wid) ) {
      if( ptb->restore_docked && ptb->wid.p_DockingArea != 0 && ptb->wid.p_DockingArea == ptb->docked_area ) {
         return true;
      } else if( !ptb->restore_docked && ptb->wid.p_DockingArea == 0 ) {
         return true;
      }
   }
   // Form is not being recycled or cannot be recycled
   return false;
}

/**
 * Determine if area is not to be refreshed. This is used during
 * restore when tool windows are being destroyed to save time.
 * 
 * @param area
 * 
 * @return true if area is not to be refreshed.
 */
boolean _tbIsNoRefreshArea(DockingArea area)
{
   if( gRestoreNoDockedRefresh._indexin((int)area) ) {
      return true;
   }
   return false;
}

static void _tbDockChanSaveAutoRestoreInfoCallback(DockingArea area,_str sid, int pic, _str caption, boolean active, typeless extra)
{
   // Note:
   // sid could be "" to represent a space/gap between groups of items in the dock channel,
   // so replace "" with something that cannot be a form name.
   if( sid=="" ) {
      sid="-";
   }
   _str line = area' 'sid' 'active;
   insert_line(line);
   //say('_tbDockChanSaveAutoRestoreInfoCallback: autorestore - saving: line='line);
}

_form _tbstub_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_SIZABLE;
   p_caption='';
   p_CaptionClick=true;
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=900;
   p_tool_window=true;
   p_width=2000;
   p_x=0;
   p_y=0;
   p_eventtab2=_toolbar_etab2;
   p_visible=false;
}

static int autorestore_toolbars(_str option, _str info='', _str restoreName='')
{
   _tbNewVersion();
   option=lowcase(option);

   int focus_wid = 0;
   int index = 0;
   _str line = '';
   _str form_name = '';
   typeless Noftoolbars;
   typeless bbdockNoflines;
   typeless tbrestoreNoflines;
   typeless dockchanNoflines;
   typeless qtoolbarNoflines;
   typeless MaximizeWindow;
   typeless fullscreen_mode;
   typeless restore_docked;
   typeless show_x;
   typeless show_y;
   typeless show_width;
   typeless show_height;
   typeless docked_area;
   typeless docked_row;
   typeless docked_x;
   typeless docked_y;
   typeless docked_width;
   typeless docked_height;
   typeless tabgroup;
   typeless tabOrder;
   typeless auto_width;
   typeless auto_height;
   typeless x,y,width,height;
   typeless error;
   typeless old_area;
   typeless area;
   typeless i;
   typeless FormNameOrIntInfo;
   typeless twspace;
   typeless tbflags;
   typeless activeTab;
   typeless area_wid;

   if( option=='r' || option=='n' ) {
      // Get the S/390 optimizations. Even though this was designed for
      // the S/390, the optimization can be used on any platform.
      _str s390Opt = get_env(S390OPTENVVAR);
      int showBigToolbars = ((pos('-t', s390Opt)) ? 0 : 1);
      parse info with . version Noftoolbars bbdockNoflines tbrestoreNoflines dockchanNoflines MaximizeWindow fullscreen_mode qtoolbarNoflines;

      if( restoreName=='TOOLBARS5' && fullscreen_mode!='' ) {
         _tbFullScreenSetMode(fullscreen_mode!=0);
      }
      
      focus_wid=_get_focus();
      int max_restore_row=0;
      while( Noftoolbars-- ) {
         down();
         get_line(line);
         parse line with form_name x y width height;
         if( showBigToolbars || !isABigToolbar(form_name) ) {
            _RECYCLETOOLBAR *ptb = gRecycleToolbar._indexin(form_name);
            if( ptb && ptb->wid!=0 ) {
               // Explanation:
               // 10.0 introduced tab-linked tool windows. When the next-to-last
               // tool window is closed in a tabgroup, the tab control is destroyed
               // and the remaining tool window is recreated inside a panel, which
               // changes the wid. In that case, the stored wid in ptb->wid is no
               // longer valid.
               ptb->wid=_find_formobj(form_name,'n');
               if( ptb->wid!=0 ) {
                  ptb->wid._move_window(x,y,width,height);
               }

            } else {
               int orig_view_id=p_window_id;
               wid := _tbShow(form_name,x,y,width,height);
               typeless state = _GetDialogInfoHt("tbState.":+form_name, _mdi);
               wid._tbRestoreState(state,false);
               if( state != null ) {
                  _SetDialogInfoHt("tbState.":+form_name, null, _mdi);
               }
               p_window_id=orig_view_id;
            }

         } else {
            _TOOLBAR *ptb;
            ptb=_tbFind(form_name);
            ptb->restore_docked=false;
            ptb->show_x=x;
            ptb->show_y=y;
            ptb->show_width=width;
            ptb->show_height=height;
         }
      }
      if( !_tbIsDockingAllowed() ) {
         if( tbrestoreNoflines!="" ) {
            down(tbrestoreNoflines);
         }
         down(bbdockNoflines);
         if( focus_wid!=0 ) {
            focus_wid._set_focus();
         }
         return 0;
      }
      if( tbrestoreNoflines!="" ) {
         while( tbrestoreNoflines-- ) {
            down();
            get_line(line);
            parse line with form_name restore_docked show_x show_y show_width show_height docked_area docked_row docked_x docked_y docked_width docked_height tabgroup tabOrder auto_width auto_height.;
            _TOOLBAR *ptb = _tbFind(form_name);
            if( ptb ) {
               ptb->restore_docked=restore_docked;
               ptb->show_x=show_x;
               ptb->show_y=show_y;
               ptb->show_width=show_width;
               ptb->show_height=show_height;
               ptb->docked_area=docked_area;
               ptb->docked_row=docked_row;
               ptb->docked_x=docked_x;
               ptb->docked_y=docked_y;
               ptb->docked_width=docked_width;
               ptb->docked_height=docked_height;
               ptb->tabgroup=tabgroup;
               ptb->tabOrder=tabOrder;
               ptb->auto_width=auto_width;
               ptb->auto_height=auto_height;
               if( docked_area!=0 && docked_row>max_restore_row ) {
                  max_restore_row=docked_row;
               }
            }
         }
      }
      //say('START*********************************************');
      //say('bbdockNoflines='bbdockNoflines);
      error=0;
      gbbdockinfo._makeempty();
      old_area=0;

      // Hash table of tabgroup active tabs indexed by tabgroup number.
      // Used to restore active tab in a tabgroup.
      int htActiveTab:[];
      htActiveTab._makeempty();

      // (16.1.0) Need placeholders for old toolbars)
      int stubToolbars[];
      _str restoreToolbars[];

      while( bbdockNoflines-- ) {
         down();
         get_line(line);
         if( error!=0 ) {
            continue;
         }
         parse line with area i FormNameOrIntInfo twspace tbflags width height docked_row tabgroup tabOrder activeTab auto_width auto_height .;
         // Skip showing the "big" toolbars.
         if( !showBigToolbars && !isinteger(FormNameOrIntInfo) ) {
            if( isABigToolbar(FormNameOrIntInfo) ) {
               _TOOLBAR *ptb = _tbFind(FormNameOrIntInfo);
               ptb->restore_docked=true;
               ptb->docked_area=area;
               ptb->docked_row=docked_row;
               ptb->docked_x=0;
               ptb->docked_y=0;
               ptb->docked_width=width;
               ptb->docked_height=height;
               ptb->tabgroup=tabgroup;
               ptb->tabOrder=tabOrder;
               ptb->auto_width=auto_width;
               ptb->auto_height=auto_height;

               // Skip over the following line as well
               bbdockNoflines--;
               down();
               get_line(line);
               continue;
            }
         }
         if( old_area!=area && old_area!=0 ) {
            _mdi._bbdockAdjustRowBreaks(old_area);
            _mdi._bbdockAddRemoveSizeBars(old_area);
            int save_view_id=p_window_id;
            _mdi._bbdockRefresh(old_area);
            p_window_id=save_view_id;
         }

         // (16.1.0) Check for old toolbars, use stub placeholder instead
         if (version == '1') {
            _TOOLBAR *ptb = _tbFind(FormNameOrIntInfo);
            if (ptb) {
               if (0 == (ptb->tbflags & TBFLAG_SIZEBARS)) {
                  restoreToolbars[restoreToolbars._length()] = FormNameOrIntInfo;
                  FormNameOrIntInfo = '_tbstub_form';
                  tbflags |= TBFLAG_SIZEBARS;
               }
            }
         }

         old_area=area;
         BBDOCKINFO *pbbdockinfo;
         area_wid=_mdi._bbdockPaletteGet(area);
         //say('area='area' w='area_wid);
         // If the _dock_palette_form has not been loaded for this side
         if( area_wid==0 ) {
            index=find_index("_dock_palette_form",oi2type(OI_FORM));
            area_wid=_paletteCreateSide(area);
         }
         if( isinteger(FormNameOrIntInfo) ) {
            pbbdockinfo=&gbbdockinfo[area][i];
            pbbdockinfo->wid=FormNameOrIntInfo;
            if( BBDOCKINFO_ROWBREAK==pbbdockinfo->wid && docked_row>max_restore_row ) {
               max_restore_row=docked_row;
            }
            twspace=0;  //Zap window id

         } else {
            int resource_index=find_index(FormNameOrIntInfo,oi2type(OI_FORM));
            if( resource_index==0 ) {
               error=1;
               continue;
            }
            pbbdockinfo=&gbbdockinfo[area][i];
            //messageNwait("resource="name_name(resource_index)" bo="area_wid.p_object" options="'HP':+NoBorder);
            _RECYCLETOOLBAR *ptb = gRecycleToolbar._indexin(FormNameOrIntInfo);
            int wid = 0;
            //say('look for 'form_name);
            if( ptb && ptb->wid!=0 ) {
               //ptb->wid=_find_formobj(FormNameOrIntInfo,'n');
               wid=ptb->wid;

            } else {
               int parent_wid = area_wid;
               boolean tabLink = ( tabgroup>0 );
               if( tabLink ) {
                  int found_area, first_i, last_i;
                  if( _bbdockFindTabGroup(tabgroup,found_area,first_i,last_i,area) ) {
                     int tabgroup_wid = _tbTabGroupWidFromWid(gbbdockinfo[area][first_i].wid);
                     if( tabgroup_wid>0 ) {
                        // Tab-link this tool window into a tabgroup
                        parent_wid=tabgroup_wid;
                     }
                  }
               }
               wid=_tbSmartLoadTemplate(tbflags,resource_index,parent_wid,tabLink);
               //wid=_tbLoadTemplate(tbflags,resource_index,area_wid);
            }
            if( wid!=0 ) {
               typeless state = _GetDialogInfoHt("tbState.":+wid.p_active_form.p_name, _mdi);
               wid._tbRestoreState(state,true);
               if( state != null ) {
                  _SetDialogInfoHt("tbState.":+wid.p_active_form.p_name, null, _mdi);
               }

            }
            pbbdockinfo->wid=wid;
            if( 0!=(tbflags & TBFLAG_SIZEBARS) ) {
               // Sizeable
               int container_wid = _tbContainerFromWid(wid);
               container_wid.p_width=width;
               container_wid.p_height=height;
            }
         }
         pbbdockinfo->twspace=twspace;
         pbbdockinfo->sizebarAfterWid=0;
         pbbdockinfo->tbflags=tbflags;
         pbbdockinfo->docked_row=docked_row;
         pbbdockinfo->tabgroup=tabgroup;
         pbbdockinfo->tabOrder=tabOrder;

         // (16.1.0) track placeholder toolbars
         if (FormNameOrIntInfo == '_tbstub_form') {
            stubToolbars[stubToolbars._length()] = pbbdockinfo->wid;
         }

         if( tabgroup>0 && activeTab!="0" && tabOrder>=0 ) {
            // This tool window was the active tab of this tabgroup,
            // remember that for later when we restore the active tab.
            htActiveTab:[tabgroup]=tabOrder;
         }
      }
      if( error!=0 ) {
         tbResetAll();

      } else {
         if( old_area!=0 ) {
            _mdi._bbdockAdjustRowBreaks(old_area);
            _mdi._bbdockAddRemoveSizeBars(old_area);
            _mdi._bbdockRefresh(old_area);
         }
         // IF the docked_row numbers are getting large
         //_message_box('max_restore_row='max_restore_row);
         if( max_restore_row>1000 ) {
            _tbShrinkRestoreRowNumbers();
         }

         // Now restore the active tab for each tabgroup
         for( tabgroup._makeempty();; ) {
            htActiveTab._nextel(tabgroup);
            if( tabgroup._isempty() ) {
               // All done
               break;
            }
            // Force active order of SSTab control to match
            // gbbdockinfo[][].
            _bbdockSortTabGroup(tabgroup,old_area);
            tabOrder=htActiveTab:[tabgroup];
            if( !_bbdockActivateTabGroupTabOrder(tabgroup,tabOrder) ) {
               // We did not find the tab, so set active tab to first
               _bbdockActivateTabGroupTabOrder(tabgroup,0);
            }
         }
      }

      // Dock channel
      //say('autorestore_toolbars: dockchanNoflines='dockchanNoflines);
      if( error==0 && isinteger(dockchanNoflines) && dockchanNoflines>0 ) {
         while( dockchanNoflines-- ) {
            down();
            get_line(line);
            _str sid='';
            _str active_str='';
            parse line with area sid active_str;
            if( sid=="-" ) {
               // Space
               // true=delay refresh so that trailing space is not stripped off
               dockchanAdd(area,"",0,"",null,null,false,true);
            } else {
               _TOOLBAR* ptb = _tbFind(sid);
               if( ptb ) {
                  index = find_index(sid,oi2type(OI_FORM));
                  if( index>0 ) {
                     int pic = index.p_picture;
                     _str caption = index.p_caption;
                     boolean active = ( isinteger(active_str) && active_str!=0 );
                     dockchanAdd(area,sid,pic,caption,_tbDockChanMouseInCallback,_tbDockChanMouseOutCallback,false,false);
                     if( active ) {
                        dockchanSetActive(sid,true);
                     }
                  }
               }
            }
         }
         // Refresh all sides...now!
         dockchanRefresh();
      }

      // restoring from old version
      if (version == '1') {
         // (16.1.0) remove stub toolbar
         if (stubToolbars._length() != 0) {
            int n = stubToolbars._length();
            for (i = 0; i < n; ++i) {
               int wid = stubToolbars[i];
               _tbClose(wid);
            }
         }

         // (16.1.0) restore stubbed toolbars as new toolbar
         if (restoreToolbars._length() != 0) {
            int n = restoreToolbars._length();
            for (i = 0; i < n; ++i) {
               _str name = restoreToolbars[i];
#if __MACOSX__
               if (restoreName == 'TOOLBARS5') {
                  if (name == '_tbstandard_form') {
                     // replace standard toolbar here
                     name = '_tbunified_form';
                  }
                  if (name == '_tbcontext_form') { 
                     // combined in unified toolbar
                     continue; 
                  }
               }
#endif
               _tbLoadQToolbarName(name);
            }

         }
      }

      // (16.1.0) new toolbar restore method
      if (qtoolbarNoflines != '' && isinteger(qtoolbarNoflines)) {
         autorestore_qtoolbars(option, qtoolbarNoflines);
      }

      //_message_box('h2 max_restore_row='max_restore_row);
      //say('END*****************************************');

      if( focus_wid!=0 ) {
         focus_wid._set_focus();
      }

   } else {
      save_pos(auto p);

      Noftoolbars = 0;
      for( i=0;i<def_toolbartab._length();++i ) {
         if (0 == (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS)) {
            continue;
         }
         int wid = _find_formobj(def_toolbartab[i].FormName,'n');
         if( wid!=0 && wid.p_DockingArea==0 && !_tbIsAutoWid(wid) ) {
            ++Noftoolbars;
            _tbContainerFromWid(wid)._get_window(x,y,width,height);
            insert_line(def_toolbartab[i].FormName" "x" "y" "width" "height);
         }
      }

      tbrestoreNoflines = 0;
      for( i=0; i<def_toolbartab._length(); ++i ) {
         _TOOLBAR *ptb = &def_toolbartab[i];
         if (0 == (ptb->tbflags & TBFLAG_SIZEBARS)) {
            continue;
         }
         ++tbrestoreNoflines;
         insert_line(ptb->FormName" "ptb->restore_docked" ":+
                     ptb->show_x" "ptb->show_y" "ptb->show_width" "ptb->show_height" ":+
                     ptb->docked_area" "ptb->docked_row" ":+
                     ptb->docked_x" "ptb->docked_y" "ptb->docked_width" "ptb->docked_height" ":+
                     ptb->tabgroup" "ptb->tabOrder" "ptb->auto_width" "ptb->auto_height);
      }

      bbdockNoflines = 0;
      for( area=DOCKINGAREA_FIRST; area<=_bbdockPaletteLastIndex(); ++area ) {
         typeless wid = _mdi._bbdockPaletteGet(area);
         if( wid!=0 ) {
            // Maintain a hash table of active tab tool windows
            // indexed by tabgroup number. This prevents us from
            // having to look up active tab for every autorestored
            // tool window that is part of a tabgroup.
            int htActiveTab:[];
            htActiveTab._makeempty();

            for( i=0; i<_bbdockPaletteLength(area); ++i ) {
               BBDOCKINFO *pbbdockinfo;
               pbbdockinfo=&gbbdockinfo[area][i];
               wid=pbbdockinfo->wid;
               if( wid>0 ) {
                  int container_wid = _bbdockContainer(pbbdockinfo);
                  width=container_wid.p_width;
                  height=container_wid.p_height;
                  wid=wid.p_name;
                  tbflags=pbbdockinfo->tbflags;
                  twspace=pbbdockinfo->twspace;
                  docked_row=0;
                  tabgroup=pbbdockinfo->tabgroup;
                  tabOrder=pbbdockinfo->tabOrder;
                  activeTab=0;
                  if( tabgroup>0 ) {
                     int activeWid = 0;

                     // Do we already know the active tab for this tabgroup?
                     if( htActiveTab._indexin(tabgroup) ) {
                        activeWid=htActiveTab:[tabgroup];

                     } else {
                        int tabgroupWid = _bbdockTabGroupWid(pbbdockinfo);
                        if( tabgroupWid>0 ) {

                           if( tabgroupWid.p_object==OI_SSTAB ) {
                              activeWid=tabgroupWid._tabgroupFindActiveForm();
                           }
                           // Save this information so we do not have to
                           // do this lookup again.
                           htActiveTab:[tabgroup]=activeWid;
                        }
                     }
                     if( activeWid==pbbdockinfo->wid ) {
                        // This is the active tab
                        activeTab=1;
                     }
                  }

               } else {
                  tbflags=0;
                  twspace=0;
                  width=height=0;
                  if( wid==BBDOCKINFO_ROWBREAK ) {
                     docked_row=pbbdockinfo->docked_row;
                  }
                  tabgroup=0;
                  tabOrder=0;
                  activeTab=0;
               }
               ++bbdockNoflines;
               insert_line(area" "i" "wid" "twspace" "tbflags" "width" "height" "docked_row" "tabgroup" "tabOrder" "activeTab);
            }
         }
      }

      dockchanNoflines = 0;
      for( area=DOCKINGAREA_FIRST; area<=DOCKINGAREA_LAST; ++area ) {
         int old_line = p_line;
         dockchanEnumerate(area,_tbDockChanSaveAutoRestoreInfoCallback,true);
         dockchanNoflines += p_line - old_line;
      }

      // qtoolbar
      qtoolbarNoflines = 0;
      autorestore_qtoolbars(option, qtoolbarNoflines);

      //if( Noftoolbars!=0 || bbdockNoflines!=0 ) {
         int orig_line=p_line;
         restore_pos(p);
         //messageNwait('tbrestoreNoflines='tbrestoreNoflines);
         insert_line(restoreName': '(Noftoolbars+bbdockNoflines+tbrestoreNoflines+dockchanNoflines+qtoolbarNoflines)" 2 "Noftoolbars" "bbdockNoflines" "tbrestoreNoflines' 'dockchanNoflines' '_mdi.p_window_state' '_tbFullScreenQMode()' 'qtoolbarNoflines);
         p_line=orig_line+1;
      //}
   }
   return 0;
}

/**
 * Is the given form name allowed in this debug mode?
 *
 * @param form_name     form name of toolbar to check
 *
 * @return true if it is supported, false otherwise.
 */
static boolean _tbDebugShowToolbar(_str form_name)
{
   int ToolbarSupported_index=find_index('_'_project_DebugCallbackName'_ToolbarSupported',PROC_TYPE);
   if (ToolbarSupported_index && !call_index(form_name,ToolbarSupported_index)) {
      return(false);
   }
   return(true);
}

int _srg_toolbars5(_str option='',_str info='')
{
   option=lowcase(option);
   if (option=='r'||option=='n') {
      autorestore_toolbars(option,info,'TOOLBARS5');
   } else {
      if (!_tbDebugQMode()) {
         // Write the toolbar info
         autorestore_toolbars('','','TOOLBARS5');
      } else {
         // Copy the toolbar settings from the temp view if there is one
         if (_tbstandard_layout_view_id) {
            int NoflinesCopied=0;
            _copy_from_view(_tbstandard_layout_view_id,NoflinesCopied);
            down(NoflinesCopied-1);
         }
      }
   }
   return(0);
}

static int autorestore_toolbar_layout(_str view_name,int &view_id,boolean isCurrentToolbarLayout,
                        _str option='',_str info='')
{
   option=lowcase(option);
   if (option=='r'||option=='n') {
      typeless Noflines;
      parse info with Noflines .;
      // Copy the toolbar settings from our view if there is one
      _copy_into_view(view_name,view_id,Noflines+1,false);
      down(Noflines);
   } else {
      if (isCurrentToolbarLayout) {
         // Write the toolbar debug info
         _str name='';
         parse view_name with '._tb' name '_layout';
         autorestore_toolbars('','',upcase(name)'_TOOLBARS');
      } else {
         // Copy the toolbar settings from the temp view if there is one
         if (view_id) {
            typeless NoflinesCopied;
            _copy_from_view(view_id,NoflinesCopied);
            down(NoflinesCopied-1);
         }
      }
   }
   return(0);
}

int _srg_fullscreen_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_layout',
                                      _tbfullscreen_layout_view_id,
                                      !_tbDebugQMode() && _tbFullScreenQMode(),
                                      option,info));
}


int _srg_standard_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbstandard_layout',_tbstandard_layout_view_id,
                                      !_tbDebugQMode() && !_tbFullScreenQMode(),
                                      option,info));
}

int _srg_debug_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbdebug_layout',_tbdebug_layout_view_id,
                                      _tbDebugQMode() && !_tbFullScreenQMode() && !_tbDebugQSlickCMode(),
                                      option,info));
}

int _srg_fullscreen_debug_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_debug_layout',
                                      _tbfullscreen_debug_layout_view_id,
                                      _tbDebugQMode() && _tbFullScreenQMode() && !_tbDebugQSlickCMode(),
                                      option,info));
}

int _srg_slickc_debug_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbslickc_debug_layout',_tbslickc_debug_layout_view_id,
                                      _tbDebugQMode() && !_tbFullScreenQMode() && _tbDebugQSlickCMode(),
                                      option,info));
}

int _srg_fullscreen_slickc_debug_toolbars(_str option='',_str info='')
{
   return (autorestore_toolbar_layout('._tbfullscreen_slickc_debug_layout',
                                      _tbfullscreen_slickc_debug_layout_view_id,
                                      _tbDebugQMode() && _tbFullScreenQMode() && _tbDebugQSlickCMode(),
                                      option,info));
}

static void _tbSaveAutoRestoreInfoInView(_str view_buf_name,int &temp_view_id,_str restoreName)
{
   int orig_view_id;
   get_window_id(orig_view_id);
   // Save current toolbar settings
   if (temp_view_id) {
      activate_window(temp_view_id);
      _lbclear();
   } else {
      _create_temp_view(temp_view_id);
      p_buf_name=view_buf_name;
   }
   autorestore_toolbars('','',restoreName);
   activate_window(orig_view_id);
}

static void _tbAutoRestoreFromView(int temp_view_id, boolean restoreWindowState)
{
#if __UNIX__
   int focus_wid=_get_focus();
   if( focus_wid==0 && !_no_child_windows() ) {
      // This is a bit of Kludge
      // We need this for when the user selects Stop debugging from the menu and
      // the focus most likely came from the MDI child.
      // I think the root of the problem is that focus events are dispatched
      // when you destroy windows even if the windows did not have focus.
      focus_wid=_mdi.p_child;
   }
#endif
   int orig_view_id;
   get_window_id(orig_view_id);

   // Clear all dock channels
   dockchanResetAll();
   // Clear all toolbars
   //_tbDeleteAllQToolbars();

   _str line = '';
   _str rtype = '';
   _str info = '';
   typeless Noftoolbars;
   typeless bbdockNoflines;
   typeless tbrestoreNoflines;
   typeless dockchanNoflines;
   typeless qtoolbarNoflines;
   typeless MaximizeWindow;
   typeless fullscreen_mode;
   int max_restore_row = 0;
   _str form_name = '';
   typeless x,y,width,height;
   typeless area;
   typeless i;
   typeless FormNameOrIntInfo;
   typeless twspace;
   typeless tbflags;
   typeless docked_row;
   _str name = '';

   // Hash toolbars that need to visible.  This hashtable allows to
   // avoid some create and destroy performances problems.  The Project toolbar
   // is slow to bring up because of the initialization code so try to keep
   // it displayed.
   gRecycleToolbar._makeempty();
   gRestoreNoDockedRefresh._makeempty();
   if( temp_view_id!=0 ) {
      activate_window(temp_view_id);top();
      get_line(line);
      parse line with rtype info;
      _str s390Opt = get_env(S390OPTENVVAR);
      int showBigToolbars = ((pos('-t', s390Opt)) ? 0:1);
      parse info with . version Noftoolbars bbdockNoflines tbrestoreNoflines dockchanNoflines MaximizeWindow fullscreen_mode qtoolbarNoflines;
      //say('bbdockNoflines='bbdockNoflines);
      //say('Noftoolbars='Noftoolbars);
      max_restore_row=0;
      while( Noftoolbars-- ) {
         down();
         get_line(line);
         parse line with form_name x y width height;
         if( showBigToolbars || !isABigToolbar(form_name) ) {
            _RECYCLETOOLBAR *ptb = &gRecycleToolbar:[form_name];
            ptb->restore_docked=false;
            ptb->wid=0;
         }
      }
      if( !_tbIsDockingAllowed() ) {
         if( tbrestoreNoflines!="" ) {
            down(tbrestoreNoflines);
         }
         down(bbdockNoflines);

      } else {

         if( tbrestoreNoflines!="" ) {
            down(tbrestoreNoflines);
         }
         while( bbdockNoflines-- ) {
            down();
            get_line(line);
            parse line with area i FormNameOrIntInfo twspace tbflags width height docked_row .;
            // Skip showing the "big" toolbars.
            if( !showBigToolbars && !isinteger(FormNameOrIntInfo) ) {

               if( isABigToolbar(FormNameOrIntInfo) ) {
                  // Skip over the following line as well.
                  bbdockNoflines--;
                  down();
                  get_line(line);
                  continue;
               }
            }
            if( isinteger(FormNameOrIntInfo) ) {
               // Do nothing
            } else {
               _RECYCLETOOLBAR *ptb = &gRecycleToolbar:[FormNameOrIntInfo];
               ptb->restore_docked=true;
               ptb->docked_area=area;
               ptb->wid=0;
            }
         }
      }
      if( MaximizeWindow!="" && restoreWindowState ) {
         parse p_buf_name with '._tb' name '_layout';
         if( name=='fullscreen' ) {
            //_mdi.p_window_state='M';
         } else {
            if( MaximizeWindow!='M' && MaximizeWindow!='N' ) {
               _mdi.p_window_state='N';
            } else {
               _mdi.p_window_state=MaximizeWindow;
            }
         }
      }
   }

   // Set wid for toolbars which should not be closed
   for( i=0; i<def_toolbartab._length(); ++i) {
      if (0 == (def_toolbartab[i].tbflags & TBFLAG_SIZEBARS)) {
         continue;
      }

      form_name = def_toolbartab[i].FormName;
      int wid = _find_formobj(form_name,"n");
      // 1. Do not allow tab-linked tool windows to be held open.
      // Explanation:
      // Tool windows in the restored view are restored _before_
      // gbbdockinfo[][] knows anything about the tool windows
      // in gRecycleToolbar:[], that means that a tabgroup is
      // created as tool windows from the view are restored in
      // addition to the tool window that was held open!
      // 9/20/2005 - RB
      // #2 currently precludes this check, but we might want to
      // allow toolbars (rows/columns of buttons) inside a tabgroup
      // in future (doubtful but you never know), so leave the check
      // in.
      //
      // 2. Do not allow tab-linkable tool windows to be held open.
      // Example:
      // A single tool window open in fullscreen mode (without
      // a tabgroup number). User goes out of fullscreen mode and
      // same tool window is restored as part of a tabgroup. But since
      // the tool window was not part of a tabgroup (tabgroup number=0),
      // it was held open when it should have been closed to become part
      // of the non-fullscreen autorestore layout where it was part of
      // a tabgroup.
      //
      // 3. Do not allow auto shown/hidden windows to be held open.
      tbflags = def_toolbartab[i].tbflags;
      if( wid!=0 &&
          ( 0!=(tbflags & (TBFLAG_NO_TABLINK|TBFLAG_NO_CAPTION)) ||
            0==(tbflags & TBFLAG_SIZEBARS) ||
            isNoTabLinkToolbar(form_name) ) &&
          _tbTabGroupFromWid(wid)==0 &&
          !_tbIsAutoWid(wid) ) {
         _RECYCLETOOLBAR *ptb = gRecycleToolbar._indexin(form_name);
         if( ptb ) {
            if( ptb->restore_docked && wid.p_DockingArea!=0 &&
                wid.p_DockingArea==ptb->docked_area ) {

               gRestoreNoDockedRefresh:[ptb->docked_area]=1;
               wid.p_visible=0;
               ptb->wid=wid;

            } else if( !ptb->restore_docked && wid.p_DockingArea==0 ) {
               ptb->wid=wid;
            }
         }
      }
   }
   //say('close START*********************************************');
   // Close all visible toolbars
   for( i=0; i<def_toolbartab._length(); ++i ) {
      form_name = def_toolbartab[i].FormName;
      int wid = _find_formobj(form_name,'n');
      if( wid!=0 ) {
         // Note:
         // _tbClose is aware of gRecycleToolbar hash table.
         // _tbClose will not close tool window that is in gRecycleToolbar
         // hash table.
         typeless state = null;
         wid._tbSaveState(state,false);
         if( state != null ) {
            _SetDialogInfoHt("tbState.":+form_name, state, _mdi);
         }

         if (!_IsQToolbar(wid)) {
            _tbClose(wid);
         }
      }
   }
   //say('close END*********************************************');
   activate_window(orig_view_id);
   get_window_id(orig_view_id);
   if( temp_view_id==0 ) {
      _bbdockReset();
#if __UNIX__
      if( focus_wid!=0 && _iswindow_valid(focus_wid) ) {
         focus_wid._set_focus();
      }
#endif
      gRecycleToolbar._makeempty();
      gRestoreNoDockedRefresh._makeempty();
      return;
   }
   activate_window(temp_view_id);top();
   get_line(line);
   parse line with rtype info;
   //_srg_toolbars5('r',info);
   parse p_buf_name with '._tb' name '_layout';
   autorestore_toolbars('r',info,upcase(name)'_TOOLBARS');
   activate_window(orig_view_id);
#if __UNIX__
   if( focus_wid!=0 && _iswindow_valid(focus_wid) ) {
      focus_wid._set_focus();
   }
#endif
   if( _tbFullScreenQMode() ) {
      _tbcommon_fullscreen_settings();
   } else {
      _mdi.p_border_style=BDS_SIZABLE;
   }
   gRecycleToolbar._makeempty();
   gRestoreNoDockedRefresh._makeempty();

   _tbpanelUpdateAllPanels();
}
#if __MACOSX__
int macLionFullscreenMode();
#endif

int _OnUpdate_fullscreen(CMDUI &cmdui,int target_wid,_str command)
{
#if __MACOSX__
   if (macLionFullscreenMode()) {
      return (MF_GRAYED);
   }
#endif
   if (_tbFullScreenQMode()) {
      return(MF_CHECKED|MF_ENABLED);
   }
   return(MF_ENABLED|MF_UNCHECKED);
}

static int gfsrestore_x,gfsrestore_y,gfsrestore_width,gfsrestore_height;

/**
 * Should fullscreen mode show the MDI menu?
 * Set to false to hide the MDI menu in fullscreen mode.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_fullscreen_show_mdimenu=true;
/**
 * Should fullscreen mode maximize the editor to use the
 * entire screen?  If disabled, fullscreen just swaps in the
 * fullscreen toolbars, but the editor maintains the same
 * size and position.
 * <p>
 * NOTE:  On Unix, maximize is not guaranteed to work since
 * the window manager controls sizing.
 * 
 * @default true
 * @categories Configuration_Variables
 */
boolean def_fullscreen_maximize_mdi=true;

void _tbcommon_fullscreen_settings()
{
   //_mdi.p_window_state='N';
   //_message_box('h1');
#if __UNIX__
   _mdi.p_window_state='F';
#if 0
   _mdi.p_window_state='R';
   _mdi._get_window(gfsrestore_x,gfsrestore_y,gfsrestore_width,gfsrestore_height);
   caption_height=0;
   screen_x=0;screen_y=0;screen_width=_screen_width();
   screen_height=_screen_height();
   _mdi._move_window(screen_x,screen_y-caption_height,screen_width,screen_height+caption_height);
#endif
#else
   if( def_fullscreen_maximize_mdi ) {

      // Note:
      // Maximizing does not work if the border style is none.  We still need to tell windows
      // we are maximized even though we reconfigure the window afterwards.
      _mdi.p_window_state='R';

      _mdi._get_window(gfsrestore_x,gfsrestore_y,gfsrestore_width,gfsrestore_height);
      _mdi.p_border_style=BDS_NONE;
      int screen_x, screen_y, screen_width, screen_height;
      _mdi._GetScreen(screen_x,screen_y,screen_width,screen_height);
      int caption_height=GetSystemMetrics(VSM_CYMENU);
      if( def_fullscreen_show_mdimenu ) {
         caption_height=0;
      }
      _mdi._move_window(screen_x,screen_y-caption_height,screen_width,screen_height+caption_height);
   }
#endif
}

_command void fullscreen(_str onoff='')
{
   if (isEclipsePlugin()) {
      _eclipse_full_screen();
      return;
   }
   if (!isinteger(onoff)) {
      onoff=!_tbFullScreenQMode();
   }
   if (!onoff) {
      if (!_tbFullScreenQMode()) return;
      _tbFullScreenSetMode(false);
#if !__UNIX__
      if (def_fullscreen_maximize_mdi) {
         _mdi.p_window_state='N';
         _mdi._move_window(gfsrestore_x,gfsrestore_y,gfsrestore_width,gfsrestore_height);
      }
#endif
     if (_tbDebugQMode()) {
        if (_tbDebugQSlickCMode()) {
           _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_slickc_debug_layout',_tbfullscreen_slickc_debug_layout_view_id,'FULLSCREEN_SLICKC_DEBUG_TOOLBARS');
        } else {
           _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_debug_layout',_tbfullscreen_debug_layout_view_id,'FULLSCREEN_DEBUG_TOOLBARS');
        }
     } else {
        _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_layout',_tbfullscreen_layout_view_id,'FULLSCREEN_TOOLBARS');
     }

      if (_tbDebugQMode()) {
         if (_tbDebugQSlickCMode()) {
            _mdi._tbAutoRestoreFromView(_tbslickc_debug_layout_view_id,true);
         } else {
            _mdi._tbAutoRestoreFromView(_tbdebug_layout_view_id,true);
         }
      } else {
         _mdi._tbAutoRestoreFromView(_tbstandard_layout_view_id,true);
      }
      return;
   }
   if (_tbFullScreenQMode()) return;
   if (_tbDebugQMode()) {
      if (_tbDebugQSlickCMode()) {
         _mdi._tbSaveAutoRestoreInfoInView('._tbslickc_debug_layout',_tbslickc_debug_layout_view_id,'SLICKC_DEBUG_TOOLBARS');
      } else {
         _mdi._tbSaveAutoRestoreInfoInView('._tbdebug_layout',_tbdebug_layout_view_id,'DEBUG_TOOLBARS');
      }
   } else {
      _mdi._tbSaveAutoRestoreInfoInView('._tbstandard_layout',_tbstandard_layout_view_id,'STANDARD_TOOLBARS');
   }
   _tbFullScreenSetMode(true);
   if (_tbDebugQMode()) {
      if (_tbDebugQSlickCMode()) {
         _mdi._tbAutoRestoreFromView(_tbfullscreen_slickc_debug_layout_view_id,true);
      } else {
         _mdi._tbAutoRestoreFromView(_tbfullscreen_debug_layout_view_id,true);
      }
   } else {
      _mdi._tbAutoRestoreFromView(_tbfullscreen_layout_view_id,true);
   }
}

/**
 * Restores the MDI window to its size before being iconized.
 * 
 * @categories Window_Functions
 * 
 */ 
_command void restore_mdi() name_info(','VSARG2_REQUIRES_MDI|VSARG2_REQUIRES_MINMAXRESTOREICONIZE_WINDOW)
{
   if (_tbFullScreenQMode()) return;
   _mdi.p_window_state='N';
}

boolean _tbFullScreenQMode()
{
   return(_tbfullscreen_mode);
}

static void _tbFullScreenSetMode(boolean onoff)
{
   _tbfullscreen_mode=onoff;
}

boolean _tbDebugQMode()
{
   return(_tbdebug_mode);
}

boolean _tbDebugQSlickCMode()
{
   return(_tbslickc_debug_mode);
}

void _tbDebugSetMode(boolean onoff, boolean slickc=false)
{
   _tbdebug_mode=onoff;
   _tbslickc_debug_mode=slickc;
}

void tbDebugSwitchMode(boolean onoff, boolean slickc=false)
{
   if (!isinteger(onoff)) {
      onoff=!_tbDebugQMode();
   }
   boolean restoreWindowState=_tbfullscreen_mode;
   if (onoff) {
      if (_tbDebugQMode()) {
         // we are already in debug mode
         return;
      }
      if (_tbFullScreenQMode()) {
         _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_layout',_tbfullscreen_layout_view_id,'FULLSCREEN_TOOLBARS');
      } else {
         _mdi._tbSaveAutoRestoreInfoInView('._tbstandard_layout',_tbstandard_layout_view_id,'STANDARD_TOOLBARS');
      }
      _tbDebugSetMode(true,slickc);
      if (_tbFullScreenQMode()) {
         if (_tbDebugQSlickCMode()) {
            _mdi._tbAutoRestoreFromView(_tbfullscreen_slickc_debug_layout_view_id,restoreWindowState);
         } else {
            _mdi._tbAutoRestoreFromView(_tbfullscreen_debug_layout_view_id,restoreWindowState);
         }
      } else {
         if (_tbDebugQSlickCMode()) {
            _mdi._tbAutoRestoreFromView(_tbslickc_debug_layout_view_id,restoreWindowState);
         } else {
            _mdi._tbAutoRestoreFromView(_tbdebug_layout_view_id,restoreWindowState);
         }
      }
      return;
   }
   if (!_tbDebugQMode()) {
      // Currently, we are not in debug mode
      return;
   }
   if (_tbFullScreenQMode()) {
      if (_tbDebugQSlickCMode()) {
         _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_slickc_debug_layout',_tbfullscreen_slickc_debug_layout_view_id,'FULLSCREEN_SLICKC_DEBUG_TOOLBARS');
      } else {
         _mdi._tbSaveAutoRestoreInfoInView('._tbfullscreen_debug_layout',_tbfullscreen_debug_layout_view_id,'FULLSCREEN_DEBUG_TOOLBARS');
      }
   } else {
      if (_tbDebugQSlickCMode()) {
         _mdi._tbSaveAutoRestoreInfoInView('._tbslickc_debug_layout',_tbslickc_debug_layout_view_id,'SLICKC_DEBUG_TOOLBARS');
      } else {
         _mdi._tbSaveAutoRestoreInfoInView('._tbdebug_layout',_tbdebug_layout_view_id,'DEBUG_TOOLBARS');
      }
   }
   _tbDebugSetMode(false,false);
   if (_tbFullScreenQMode()) {
      _mdi._tbAutoRestoreFromView(_tbfullscreen_layout_view_id,restoreWindowState);
   } else {
      _mdi._tbAutoRestoreFromView(_tbstandard_layout_view_id,restoreWindowState);
   }
}

_str _toolbar_layout_export_settings(_str &path)
{
   error := '';

   // first create a temp view where we can stash our info
   tempView := 0;
   origView := _create_temp_view(tempView);
   if (origView == '') {
      return 'Error creating temp view.';
   }

   _srg_standard_toolbars();
   _srg_fullscreen_toolbars();
   _srg_debug_toolbars();
   _srg_fullscreen_debug_toolbars();

   // save the file
   filename := 'tbLayout.slk';
   status := save_as(maybe_quote_filename(path:+filename));
   if (!status) {
      path = filename;
   } else {
      error = 'Error saving toolbar layout file 'path :+ filename'.  Error code = 'status'.';
   }

   // delete the temp view, we are done with it
   _delete_temp_view(tempView);
   p_window_id = origView;

   return error;
}

_str _toolbar_layout_import_settings(_str &file)
{
   error := '';

   // open up our file
   tempView := 0;
   origView := 0;
   status := _open_temp_view(file, tempView, origView);
   if (status) {
      return 'Error opening layout file 'file'.  Error code = 'status'.';
   }

   typeless count = 0;
   typeless line = "";
   _str type = "";
   for (;;) {
      // get the line - it will tell us what this section is for
      get_line(line);
      parse line with type line;

      name := '_srg_' :+ strip(lowcase(type), '', ':');
      index := find_index(name, PROC_TYPE);

      // IF there is a callable function
      if (index_callable(index)) {

         // just call the callback for this one
         status = call_index('R', line, index);

         if (status) {
            error = 'Error applying layout type 'type'.  Error code = 'status'.';
            break;
         }
      } else {
         error = 'No callback to apply layout type 'type'.' :+ OPTIONS_ERROR_DELIMITER;
         // we can't process these lines, so skip 'em
         parse line with count .;
         if (isnumber(count)) {
            down(count);
         }
      }

      activate_window(tempView);
      if ( down()) {
         break;
      }
   }


   // at last, let's see some results!
   if (_tbfullscreen_mode) {
      _mdi._tbAutoRestoreFromView(_tbfullscreen_layout_view_id,true);
   } else {
      _mdi._tbAutoRestoreFromView(_tbstandard_layout_view_id,false);
   }

   // delete the temp view
   _delete_temp_view(tempView);
   p_window_id = origView;

   return error;
}
