#pragma option(pedantic,on)
#include "slick.sh"
namespace se.util;

/**
 * A mouse-pointer sentry to save, set, and restore the
 * mouse-pointer for the application or a specific window. Old
 * mouse-pointer is saved, new mouse-pointer is set on
 * initialization. Old mouse-pointer is restored on destruction.
 * 
 * <p>
 *
 * <ol>
 * <li>Global mouse-pointer is set by passing a window-id of 0
 * in the constructor. Typical usage in this case is to display
 * a temporary hour glass until some operation is finished.
 * <li>Mouse-pointer for a specific window is set by passing the
 * window-id in the constructor.
 * </ol>
 */
class MousePointerGuard {

   //
   // Private data
   //

   private int m_mousePointer = MP_DEFAULT;
   private int m_wid = 0;
   private int m_oldMousePointer = MP_DEFAULT;

   //
   // Forward declarations
   //

   public void setMousePointer(int mousePointer=MP_HOUR_GLASS);

   /**
    * Constructor sets the mouse-pointer to the specified value 
    * <code>mousePointer</code> for the specified window 
    * <code>wid</code>. 
    *  
    * <p>
    *
    * Note that you can specify MP_DEFAULT and then call
    * setMousePointer to set the mouse pointer later.
    *
    * @param mousePointer  One of MP_* constants. Defaults to 
    *                      MP_HOUR_GLASS.
    * @param wid           Set to 0 to override the application 
    *                      mouse-pointer. Set to a valid window id
    *                      to only override mouse-pointer for that
    *                      particular window. Defaults to 0.
    */
   public MousePointerGuard(int mousePointer=MP_HOUR_GLASS, int wid=0) {
      if( wid > 0 ) {

         // Note that if this window-id is invalid, and assuming it stays invalid,
         // then we will never follow the application-mouse-pointer code path for
         // subsequent calls to setMousePointer() and on destruction.
         m_wid = wid;
         if( _iswindow_valid(m_wid) ) {
            // Override window mouse-pointer
            m_oldMousePointer = m_wid.p_mouse_pointer;
            m_wid.p_mouse_pointer = mousePointer;
         }

      } else {

         // Override application mouse-pointer
         m_wid = 0;
         m_oldMousePointer = MP_DEFAULT;
         setMousePointer(mousePointer);

      }
   }

   /**
    * Set the mouse-pointer to specified value 
    * <code>mousePointer</code>. Note that you can only specify the
    * window in the constructor. 
    * 
    * @param mousePointer 
    */
   public void setMousePointer(int mousePointer=MP_HOUR_GLASS) {
      if( m_wid > 0 ) {

         if( _iswindow_valid(m_wid) ) {
            // Override window mouse-pointer
            m_oldMousePointer = m_wid.p_mouse_pointer;
            m_wid.p_mouse_pointer = mousePointer;
         }

      } else {

         // Override application mouse-pointer
         if( m_mousePointer != MP_DEFAULT ) {
            mou_set_pointer(MP_DEFAULT);
         }
         m_mousePointer = mousePointer;
         if( mousePointer != MP_DEFAULT ) {
            mou_set_pointer(mousePointer);
         }

      }
   }

   public ~MousePointerGuard() {
      if( m_wid > 0 ) {

         if( _iswindow_valid(m_wid) ) {
            m_wid.p_mouse_pointer = m_oldMousePointer;
            m_wid = 0;
         }

      } else {

         // Application mouse-pointer
         if( m_mousePointer != MP_DEFAULT ) {
            mou_set_pointer(MP_DEFAULT);
         }

      }
   }
};
