////////////////////////////////////////////////////////////////////////////////////
// $Revision:  $
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
#require "sc/util/Point.e"
#import "stdprocs.e"
// for nls()
#import "main.e"
#endregion

/**
 * The "sc.controls" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language's
 * form editor system and editor control.  It also contains
 * class wrappers for composite controls.
 */

namespace sc.controls;

/**
 * A rectangular window used to indicate a bounded area. 
 *
 * <p>
 *
 * Note that all coordinates are in the parent scale-mode. 
 *
 * <p>
 *
 * <b>Note:</b> We do not implement 
 * <code>sc.lang.IControlID</code> because we do not want the 
 * window to become active (e.g. when setting p_visible=true). 
 * This would interfere with drag-drop operations for tool 
 * windows, etc. 
 */
class RubberBand {

#define RUBBERBAND_MAKE_NAME(wid) 'RUBBERBAND_'##wid

   extern int createImpl(int parent);
   boolean create(int parent);
   boolean isValid();
   extern int setMaskFromPolygonImpl(sc.util.Point (&pts)[]);
   extern void clearMaskImpl();
   public void destroy();

   // Window id of the rubber-band window
   private int m_wid = 0;
   // Parent window id of the rubber-band window
   private int m_parent = 0;

   RubberBand(int parent=0) {
      this.create(parent);
   }
   ~RubberBand() {
      this.destroy();
   }

   /**
    * Create the rubber-band window. Window is initially hidden. 
    * Use <code>setVisible</code> to show.
    * 
    * @param parent Parent window id. Set to 0 for no parent.
    * 
    * @return True if rubber-band window created successfully.
    */
   public boolean create(int parent) {
      if( isValid() ) {
         // Already have a window
         return true;
      }
      m_wid = createImpl(parent);
      if( m_wid > 0 ) {
         m_wid.p_name = RUBBERBAND_MAKE_NAME(m_wid);
         m_parent = (parent > 0) ? parent : _desktop;
      }
      return ( m_wid > 0 );
   }

   /**
    * Destroy rubber-band window. Use <code>create</code> to
    * recreate the window.
    */
   public void destroy() {
      if( m_wid > 0 ) {
         m_wid._delete_window();
         m_wid = 0;
         m_parent = 0;
      }
   }

   public boolean isVisible() {
      return m_wid.p_visible;
   }

   public void setVisible(boolean visible) {
      if( m_wid > 0 && m_wid.p_visible != visible ) {
         int orig_wid = p_window_id;
         m_wid.p_visible = visible;
         p_window_id = orig_wid;
      }
   }

   /**
    * Test if rubber-band window is created. This test is cheap and 
    * fast, but not full-proof. If you need to test whether the 
    * window is valid, then use <code>isValid</code> instead. 
    * 
    * @return True if rubber-band window is created.
    */
   public boolean isCreated() {
      return ( m_wid > 0 );
   }

   /**
    * Test if rubber-band window is valid. This test is more 
    * expensive than <code>isCreated</code> since it tests if the 
    * underlying window id is still valid. 
    * 
    * @return True if the rubber-band window is valid.
    */
   public boolean isValid() {
      return ( _iswindow_valid(m_wid) && m_wid.p_name == RUBBERBAND_MAKE_NAME(m_wid) );
   }

   public void getWindow(int& x, int& y, int& width, int& height) {
      m_wid._get_window(x,y,width,height);
      // Since rubber-band window is a registered window, all values
      // are in pixels. Be nice and convert to parent scale-mode.
      _dxy2lxy(m_parent.p_xyscale_mode,x,y);
      _dxy2lxy(m_parent.p_xyscale_mode,width,height);
   }
   public void setWindow(int x, int y, int width, int height) {
      // Since rubber-band window is a registered window, all values
      // are expected to be in pixels. Convert from parent scale-mode.
      _lxy2dxy(m_parent.p_xyscale_mode,x,y);
      _lxy2dxy(m_parent.p_xyscale_mode,width,height);
      //say(nls('setWindow : (%s,%s)-(%s,%s)',x,y,width,height));
      m_wid._move_window(x,y,width,height);
   }
   public void move(int x, int y) {
      // Since rubber-band window is a registered window, all values
      // are expected to be in pixels. Convert from parent scale-mode.
      _lxy2dxy(m_parent.p_xyscale_mode,x,y);
      m_wid._move_window(x,y,m_wid.p_width,m_wid.p_height);
   }
   public void resize(int width, int height) {
      // Since rubber-band window is a registered window, all values
      // are expected to be in pixels. Convert from parent scale-mode.
      _lxy2dxy(m_parent.p_xyscale_mode,width,height);
      m_wid._move_window(m_wid.p_x,m_wid.p_y,width,height);
   }
   public int x() {
      // Since rubber-band window is a registered window, all values
      // are in pixels. Be nice and convert to parent scale-mode.
      return _dx2lx(m_parent.p_xyscale_mode,m_wid.p_x);
   }
   public int y() {
      // Since rubber-band window is a registered window, all values
      // are in pixels. Be nice and convert to parent scale-mode.
      return _dy2ly(m_parent.p_xyscale_mode,m_wid.p_y);
   }
   public int width() {
      // Since rubber-band window is a registered window, all values
      // are in pixels. Be nice and convert to parent scale-mode.
      return _dx2lx(m_parent.p_xyscale_mode,m_wid.p_width);
   }
   public int height() {
      // Since rubber-band window is a registered window, all values
      // are in pixels. Be nice and convert to parent scale-mode.
      return _dy2ly(m_parent.p_xyscale_mode,m_wid.p_height);
   }

   public int mouseCursor() {
      return m_wid.p_mouse_pointer;
   }
   public void setMouseCursor(int cursor) {
      m_wid.p_mouse_pointer = cursor;
   }

   public int setMaskFromPolygon(sc.util.Point (&pts)[]) {
      return this.setMaskFromPolygonImpl(pts);
   }

   public void clearMask() {
      this.clearMaskImpl();
   }

};
