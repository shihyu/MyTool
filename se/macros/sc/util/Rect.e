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
#require "sc/lang/IToString.e"
#import "main.e"
#import "stdprocs.e"
#endregion

/**
 * The "sc.util" namespace contains interfaces and classes that 
 * serve as utilies/tools. 
 */

namespace sc.util;

/**
 * A rectangle described by location, width, and height. 
 *
 * <p>
 *
 * Note that rightX() returns x()+width(), and bottomY() returns
 * y()+height(). 
 */
class Rect : sc.lang.IToString {

   //
   // Private data
   //

   private int m_x1;
   private int m_y1;
   private int m_x2;
   private int m_y2;

   Rect(int x=0, int y=0, int width=0, int height=0) {
      m_x1 = x;
      m_y1 = y;
      m_x2 = x + width;
      m_y2 = y + height;
   }
   ~Rect() {
   }

   public void setRect(int x, int y, int width, int height) {
      m_x1 = x;
      m_y1 = y;
      m_x2 = x + width;
      m_y2 = y + height;
   }

   /**
    * Returns true if rectangle is null.
    *
    * <p>
    *
    * A null rectangle has 0 width and height (x() == x()+width(),
    * and y() == y()+height()). 
    * 
    * @return true if rectangle is null.
    */
   public bool isNull() {
      return ( m_x1 == m_x2 || m_y1 == m_y2 );
   }

   /**
    * Returns true if rectangle is valid.
    *
    * <p>
    *
    * A valid rectangle has x() &lt;= x()+width(), and y() &lt;=
    * y()+height(). Note that a null rectangle is also a valid 
    * rectangle. 
    * 
    * @return true if rectangle is valid.
    */
   public bool isValid() {
      return ( m_x1 < m_x2 && m_y1 < m_y2 );
   }

   /**
    * @return x-coordinate of left-edge.
    */
   public int x() {
      return m_x1;
   }
   /**
    * @return y-coordinate of top edge.
    */
   public int y() {
      return m_y1;
   }

   /**
    * @return x()+width().
    */
   public int rightX() {
      return m_x2;
   }
   /**
    * @return y()+height().
    */
   public int bottomY() {
      return m_y2;
   }

   /**
    * Return the width of the rectangle. Equivalent to 
    * rightX()-x(). 
    * 
    * @return Width of rectangle.
    */
   public int width() {
      return ( m_x2 - m_x1 );
   }
   /**
    * Return the height of the rectangle. Equivalent to 
    * bottomY()-y(). 
    * 
    * @return Height of rectangle.
    */
   public int height() {
      return ( m_y2 - m_y1 );
   }

   /**
    * Set x-coordinate of left-edge. Width may be affected, but 
    * right-edge is not changed. 
    * 
    * @param x
    */
   public void setX(int x) {
      m_x1 = x;
   }
   /**
    * Set y-coordinate of top-edge. Height may be affected, but 
    * bottom-edge is not changed. 
    * 
    * @param y
    */
   public void setY(int y) {
      m_y1 = y;
   }

   /**
    * Set x-coordinate of right-edge. Width may be affected, but 
    * left-edge is not changed. 
    * 
    * @param x 
    */
   public void setRightX(int x) {
      m_x2 = x;
   }
   /**
    * Set y-coordinate of bottom-edge. Height may be affected, but 
    * top-edge is not changed. 
    * 
    * @param y
    */
   public void setBottomY(int y) {
      m_y2 = y;
   }

   /**
    * Set width of rectangle. Left-edge is not changed. 
    * 
    * @param width 
    */
   public void setWidth(int width) {
      m_x2 = m_x1 + width;
   }
   /**
    * Set height of rectangle. Top-edge is not changed. 
    * 
    * @param height 
    */
   public void setHeight(int height) {
      m_y2 = m_y1 + height;
   }

   /**
    * Set size of rectangle. The top-left corner is unchanged. 
    * 
    * @param width 
    * @param height 
    */
   public void setSize(int width, int height) {
      m_x2 = m_x1 + width;
      m_y2 = m_y1 + height;
   }

   /**
    * Move rectangle horizontally, leaving left-edge at specified 
    * x-coordinate. Rectangle width is not changed. 
    * 
    * @param x 
    */
   public void moveLeft(int x) {
      m_x2 += x - m_x1;
      m_x1 = x;
   }
   /**
    * Move rectangle vertically, leaving top-edge at specified 
    * y-coordinate. Rectangle height is not changed. 
    * 
    * @param y 
    */
   public void moveTop(int y) {
      m_y2 += y - m_y1;
      m_y1 = y;
   }

   /**
    * Move rectangle horizontally, leaving right-edge at specified 
    * x-coordinate. Rectangle width is not changed. 
    * 
    * @param x 
    */
   public void moveRight(int x) {
      m_x1 += x - m_x2;
      m_x2 = x;
   }
   /**
    * Move rectangle vertically, leaving bottom-edge at specified 
    * y-coordinate. Rectangle height is not changed. 
    * 
    * @param y 
    */
   public void moveBottom(int y) {
       m_y1 += y - m_y2;
       m_y2 = y;
   }

   /**
    * Move the rectangle, leaving the top-left corner at specified 
    * (x,y) position. 
    * 
    * @param x 
    * @param y 
    */
   public void move(int x, int y) {
      m_x2 += x - m_x1;
      m_x1 = x;
      m_y2 += y - m_y1;
      m_y1 = y;
   }

   /**
    * Return true if point <code>(x, y)</code> is contained by this 
    * rectangle. 
    * 
    * @param x 
    * @param y 
    * 
    * @return bool
    */
   bool contains(int x, int y) {
      return ( x >= m_x1 && x < m_x2 && y >= m_y1 && y < m_y2 );
   }

   /**
    * Construct a Rect from geometry of window <code>wid</code>. 
    * Map coordinates to window <code>toWid</code> in scale-mode 
    * <code>scale_mode</code>. Set <code>toWid=0</code> to get 
    * global coordinates. 
    * 
    * @param wid 
    * @param toWid 
    * @param scale_mode 
    * 
    * @return Rect 
    */
   static Rect mapFromWid(int wid, int toWid=0, int scale_mode=SM_PIXEL) {
      Rect result;
      if ( wid == 0 ) {
         int x1, y1, x2, y2;
         int w, h;
         _GetVisibleScreen(x1, y1, w, h);
         _dxy2lxy(scale_mode, x1, y1);
         _dxy2lxy(scale_mode, w, h);
         x2 = x1 + w;
         y2 = y1 + h;
         result.m_x1 = x1;
         result.m_y1 = y1;
         result.m_x2 = x2;
         result.m_y2 = y2;
      } else if( wid > 0 && _iswindow_valid(wid) ) {
         int x1, y1, x2, y2;
         int w, h;
         wid._get_window(x1, y1, w, h);
         _lxy2lxy(wid.p_xyscale_mode, scale_mode, x1, y1);
         _lxy2lxy(wid.p_xyscale_mode, scale_mode, w, h);
         x2 = x1 + w;
         y2 = y1 + h;
         _map_xy(wid.p_xyparent, toWid, x1, y1, scale_mode);
         _map_xy(wid.p_xyparent, toWid, x2, y2, scale_mode);
         result.m_x1 = x1;
         result.m_y1 = y1;
         result.m_x2 = x2;
         result.m_y2 = y2;
      }
      return result;
   }

   /**
    * (x,y)-(width,height)
    *
    * @return Generate a string representing this object. 
    */
   _str toString() {
      return nls('(%s,%s)-(%s,%s)',x(),y(),width(),height());
   }

};
