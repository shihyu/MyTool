////////////////////////////////////////////////////////////////////////////////////
// $Revision: 43889 $
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
#ifndef DOCKCHANNEL_SH
#define DOCKCHANNEL_SH

#include "toolbar.sh"

/**
 * Called when the mouse enters the picture/caption area of a dock channel item.
 * <p>
 * IMPORTANT: <br>
 * It is a good idea to make this callback non-static so that its address does
 * not change when the module containing it is reloaded.
 * 
 * @param area  The area in which the mouse entered. See 
 *              DOCKINGAREA_* constants.
 * @param sid     Caller-defined. String identifer of item.
 * @param pic     Caller-defined. Picture index of item.
 * @param caption Caller-defined. Caption of item.
 * @param active  true if item is active.
 * @param clicked true if user clicked on item.
 * 
 * @return New active state of item. Usually you will want to return true to
 * indicate the item should be displayed active. Only 1 active item in a group
 * is allowed, so returning true will set all other items in the same group
 * in-active.
 */
typedef boolean (*pfnDockChanMouseInCallback)(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean clicked);

/**
 * Called when the mouse exits the picture/caption area of a dock channel item.
 * <p>
 * IMPORTANT: <br>
 * It is a good idea to make this callback non-static so that its address does
 * not change when the module containing it is reloaded.
 * 
 * @param area  The area in which the mouse exited. See 
 *              DOCKINGAREA_* constants.
 * @param sid     Caller-defined. String identifer of item.
 * @param pic     Caller-defined. Picture index of item.
 * @param caption Caller-defined. Caption of item.
 * @param active  true if item is active.
 * @param precedesMouseIn true if we are calling mouse-out callback because we are about to enter another item
 *                        which will cause the mouse-in callback to be called. The callback might want to take
 *                        action a little quicker in this case.
 * 
 * @return New active state of item. Usually you will want to return false to
 * indicate the item should be displayed in-active.
 */
typedef boolean (*pfnDockChanMouseOutCallback)(DockingArea area, _str sid, int pic, _str caption, boolean active, boolean precedesMouseIn);

/**
 * Caller-defined. Callback used by dockchanEnumerate and dockchanEnumerateGroup
 * when enumerating through dock channel items in a docking 
 * area. 
 * 
 * @param area    The area being enumerated. See DOCKINGAREA_* 
 *                constants.
 * @param sid     Caller-defined. String identifer of item.
 * @param pic     Caller-defined. Picture index of item.
 * @param caption Caller-defined. Caption of item.
 * @param active  true if item is active.
 * @param extra   Caller-defined data to be passed to callback.
 */
typedef void (*pfnDockChanEnumCallback)(DockingArea area, _str sid, int pic, _str caption, boolean active, typeless extra);

// Timer interval for checking whether to take action when mouse
// is over an image. This is how often to check if we have gone
// past value stored in def_dock_channel_delay.
#define DOCKCHANNEL_TIMER_INTERVAL 100

#define DOCKCHANNEL_AUTO_DELAY 500

/**
 * The delay in milliseconds before an action (e.g. mouse-in, mouse-out, lost-focus)
 * causes a dock channel item to be acted upon. Set this value to 0 to force user
 * to click on dock channel item to activate it.
 * 
 * @default 500
 * @categories Configuration_Variables
 */
int def_dock_channel_delay;

enum_flags DockChannelOptions {
/**
 * Mousing over a dock channel item does not activate it.
 * This option forces user to click on a dock channel item
 * to activate it.
 */

   DOCKCHANNEL_OPT_NO_MOUSEOVER  = 0x1
};

/**
 * Docking channel options. Bitset of DOCKCHANNEL_OPT_*.
 * <ul>
 * <li><b>DOCKCHANNEL_OPT_NO_MOUSEOVER</b> -- 
 * Mousing over a dock channel item does not activate it.
 * This option forces user to click on a dock channel item
 * to activate it.
 * </ul>
 * 
 * @default 0
 * @categories Configuration_Variables
 */
int def_dock_channel_options;

#endif
