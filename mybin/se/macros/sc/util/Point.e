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
#endregion

/**
 * The "sc.util" namespace contains interfaces and classes that 
 * serve as utilies/tools. 
 */

namespace sc.util;

/**
 * A point described by (x,y) coordinate. 
 */
class Point {

   //
   // Private data
   //

   private int m_x;
   private int m_y;

   Point(int x=0, int y=0) {
      m_x = x;
      m_y = y;
   }
   ~Point() {
   }

   static Point create(int x, int y) {
      Point pt(x,y);
      return pt;
   }

   /**
    * Returns true if (x,y) = (0,0). 
    * 
    * @return true if point is null.
    */
   public boolean isNull() {
      return ( m_x == 0 && m_y == 0 );
   }

   /**
    * @return x-coordinate.
    */
   public int x() {
      return m_x;
   }
   /**
    * @return y-coordinate.
    */
   public int y() {
      return m_y;
   }
   public void getCoord(int& x, int& y) {
      x = m_x;
      y = m_y;
   }

   /**
    * Set x-coordinate. 
    * 
    * @param x
    */
   public void setX(int x) {
      m_x = x;
   }
   /**
    * Set y-coordinate. 
    * 
    * @param y
    */
   public void setY(int y) {
      m_y = y;
   }
   public void setCoord(int x, int y) {
      m_x = x;
      m_y = y;
   }

};
