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

/**
 * The "sc.lang" namespace contains interfaces and 
 * classes that are intrinisic to the Slick-C language.
 */
namespace sc.lang;

/** 
 * This interface is used to represent a class that serves as a 
 * wrapper for a Slick-C control or window ID.  You can use 
 * Slick-C control properties and methods directly with an 
 * instance of this class. 
 *  
 * @example 
 * <pre> 
 *    class StoplightForm : sc.lang.IControlID {
 *       private int m_wid;
 *       StoplightForm() {
 *          m_wid = show("stoplight_form");
 *       }
 *       ~StoplightForm() {
 *          _delete_window(m_wid);
 *       }
 *       int getWindowID() {
 *          return m_wid;
 *       }
 *    }
 *    defmain() {
 *       StoplightForm f;
 *       for (i:=0; i<256; i++) {
 *          f.p_backcolor = i*256 + 256-i;
 *          f.refresh();
 *          delay(1);
 *       }
 *    }
 *    _form stoplight_form {
 *       p_backcolor=0x80000005;
 *       p_border_style=BDS_DIALOG_BOX;
 *       p_caption='Stoplight Form';
 *       p_clip_controls=false;
 *       p_forecolor=0x80000008;
 *       p_height=5520;
 *       p_width=5910;
 *       p_x=2037;
 *       p_y=2925;
 *    }
 * </pre> 
 */
interface IControlID {

   /**
    * @return
    * Returns the window ID of this control or form. 
    */
   int getWindowID();

};


