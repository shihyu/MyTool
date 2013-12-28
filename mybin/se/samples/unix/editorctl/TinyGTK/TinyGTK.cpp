#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include "vsapi.h"

#define TINYAPPNAME "TinyGTK"

static char * gXEventNameList[] =
{
   "noEvent",
   "noEvent",
   "KeyPress",
   "KeyRelease",
   "ButtonPress",
   "ButtonRelease",
   "MotionNotify",
   "EnterNotify",
   "LeaveNotify",
   "FocusIn",
   "FocusOut",
   "KeymapNotify",
   "Expose",
   "GraphicsExpose",
   "NoExpose",
   "VisibilityNotify",
   "CreateNotify",
   "DestroyNotify",
   "UnmapNotify",
   "MapNotify",
   "MapRequest",
   "ReparentNotify",
   "ConfigureNotify",
   "ConfigureRequest",
   "GravityNotify",
   "ResizeRequest",
   "CirculateNotify",
   "CirculateRequest",
   "PropertyNotify",
   "SelectionClear",
   "SelectionRequest",
   "SelectionNotify",
   "ColormapNotify",
   "ClientMessage",
   "MappingNotify"
};

enum
{
   cAppWidth = 400,
   cAppHeight = 400,
   cButtonHeight = 30,
   cAppMarginX = 10,
   cAppMarginY = 10,
   cGapY = 5
};

static Display * gXDisplay = 0; // X server connection
static GC gGC = 0; // graphics context
static GtkWidget * gToplevel = 0; // top level application window
static GtkWidget * gAppContainer = 0; // top level application container
static GtkWidget * gButton = 0; // test button
static GtkWidget * gEditorContainer = 0; // editor control container
static unsigned char gMainLoopDone = 0; // Flag: 1 indicates main loop exitting, 0 indicates loop still running
static int gEditorID = 0; // editor control ID (from VSAPI)

//----------------------------------------------------------------------
/**
 * Get the name associated with this X event.
 * 
 * @param event  X event
 * 
 * @return name
 */
static const char * xEventInfo(XEvent * event)
{
   static char nameBuf[64];
   int eventType = event->type;
   if (eventType < LASTEvent) {
      sprintf(nameBuf, "%s[%08x]", gXEventNameList[eventType], event->xany.window);
   } else {
      sprintf(nameBuf, "%d[%08x]", eventType, event->xany.window);
   }
   return(nameBuf);
}

/**
 * Print the X event name.
 * 
 * @param prefix prefix text
 * @param event  event
 */
static void printXEventName(const char * prefix, XEvent * event)
{
   static unsigned int lineNum = 1;
   int eventType = event->type;
   if (eventType == MotionNotify) return;
   if (eventType == ClientMessage) return;
   printf("%s%s\n", prefix, xEventInfo(event));
   lineNum++;
}

/**
 * Encapsulate a saved X event
 */
struct FreeSavedXEventInfo
{
   XEvent _event; // associated X event
   FreeSavedXEventInfo * _next; // points to next event in saved queue or freed list
};
static FreeSavedXEventInfo * gSkippedXEventFreeList = 0; // X event freed list
static FreeSavedXEventInfo * gSkippedXEventStack = 0; // X event saved stack

/**
 * Save the specified X event
 * 
 * @param event  X event
 * 
 * @return 0 OK, !0 error
 */
static int saveXEvent(XEvent * event)
{
   // Allocate an X event wrapper.
   FreeSavedXEventInfo * evInfo;
   if (gSkippedXEventFreeList) {
      evInfo = gSkippedXEventFreeList;
      gSkippedXEventFreeList = evInfo->_next;
   } else {
      evInfo = new FreeSavedXEventInfo;
      if (!evInfo) return(INSUFFICIENT_MEMORY_RC);
   }

   // Copy the X event.
   memcpy(&(evInfo->_event), event, sizeof(XEvent));

   // Add it to the saved stack to be put back at a later time.
   evInfo->_next = gSkippedXEventStack;
   gSkippedXEventStack = evInfo;
   return(0);
}

/**
 * Put back the previously saved X event.
 */
static void putBackSkippedXEvents()
{
   FreeSavedXEventInfo * tmp;
   FreeSavedXEventInfo * evInfo = gSkippedXEventStack;
   while (evInfo) {
      // Put the X event back onto the event queue.
      XPutBackEvent(gXDisplay, &(evInfo->_event));
      tmp = evInfo;
      evInfo = evInfo->_next;

      // Add the event wrapper to the free list.
      tmp->_next = gSkippedXEventFreeList;
      gSkippedXEventFreeList = tmp;
   }
   gSkippedXEventStack = 0;
}

/**
 * Print the full content of the X event queue.
 */
static void printEventQueue()
{
   XEvent event;
   unsigned int count = 0;
   char text[32*1024];
   text[0] = 0;
   while (XPending(gXDisplay)) {
      XNextEvent(gXDisplay, &event);
      strcat(text, xEventInfo(&event));
      strcat(text, " ");
      saveXEvent(&event);
      count++;
   }
   putBackSkippedXEvents();
   printf("****** X QUEUE count=%d %s\n",count,text);
}

/**
 * Test code used to access the editor control container X window.
 * 
 * @param xw     X window
 */
static void test1(Window xw)
{
   // Create the GC, if needed.
   if (!gGC) {
      XGCValues gcValues;
      unsigned long mask = GCGraphicsExposures|GCFunction|GCForeground;
      gcValues.graphics_exposures = False;
      gcValues.function = GXcopy;
      gcValues.foreground = 0xff0000;
      gGC = XCreateGC(gXDisplay, GDK_WINDOW_XID(gToplevel->window), mask, &gcValues);
   }

   // Do something visual to show that we really have access to the
   // X window of the edit view. Here we just fill the X window with red.
   XWindowAttributes attr;
   XGetWindowAttributes(gXDisplay, xw, &attr);
   XFillRectangle(gXDisplay, xw, gGC, 0, 0, attr.width, attr.height);
}

/**
 * Handle editor control container focus change.
 * 
 * @param widget editor control container
 * @param event  event
 * @param data   call data
 * 
 * @return TRUE to indicate that event has been consumed, FALSE to continue processing the event like normal
 */
static gboolean containerCB(GtkWidget * widget, GdkEvent * event, gpointer data)
{
   GdkWindow * gdkTextWin = gtk_text_view_get_window((GtkTextView *)widget, GTK_TEXT_WINDOW_TEXT);
   Window xw = GDK_WINDOW_XID(gdkTextWin);
   if (event->type == GDK_FOCUS_CHANGE) {
      GdkEventFocus * focusEvent = (GdkEventFocus *)event;
      //printf("containerCB GDK_FOCUS_CHANGE XW=%08x focus in=%d\n",xw,focusEvent->in);
      if (focusEvent->in) {
         printf("containerCB FOCUSIN +++++++++++++++++++\n");
         vsSetFocus(gEditorID);
      } else {
         printf("containerCB FOCUSOUT ------------------\n");
         vsKillFocus(gEditorID);
      }
   }
   return(TRUE);
}

/**
 * Handle XYWH changes of the application window.
 * 
 * @param widget
 * @param event
 * @param data
 * 
 * @return TRUE to indicate that event has been consumed, FALSE to continue processing the event like normal
 */
static gboolean toplevelResizeCB(GtkWidget *widget, GdkEvent *event, gpointer data)
{
   GdkWindow * gdkTextWin = gtk_text_view_get_window((GtkTextView *)gEditorContainer, GTK_TEXT_WINDOW_TEXT);
   Window xw = GDK_WINDOW_XID(gdkTextWin);
   XWindowAttributes attr;
   XGetWindowAttributes(gXDisplay, xw, &attr);
   printf("toplevelResizeCB text WH=%d,%d\n",attr.width,attr.height);
   XGetWindowAttributes(gXDisplay, GDK_WINDOW_XID(gToplevel->window), &attr);
   printf("toplevelResizeCB gToplevel WH=%d,%d\n",attr.width,attr.height);
   test1(xw);
   return(FALSE);
}

/**
 * Exit main loop.
 */
static void appExit()
{
   gMainLoopDone = 1;
   gtk_main_quit();
}

/**
 * Destroy the application window.
 * 
 * @param widget
 * @param data
 */
static void destroy(GtkWidget *widget, gpointer data)
{
   appExit();
}

/**
 * Handle the delete_window event from the window manager.
 * 
 * @param widget
 * @param event
 * @param data
 * 
 * @return TRUE to indicate that event has been consumed, FALSE to continue processing the event like normal
 */
static gboolean delete_event(GtkWidget *widget, GdkEvent *event, gpointer data)
{
   appExit();
   return(TRUE);
}

//----------------------------------------------------------------------
/**
 * Callback from Slick-C when user requests exiting.
 */
static void VSAPI CallbackAppExit()
{
   // Save the auto-restore information
   // Here we want dialog box retrieval, command retrieval,
   // and clipboards
   vsExecute(VSWID_MDI,"save_window_config");

   // Tell Visual SlickEdit not to send events
   vsPrepareForTerminate();

   // Do your own application cleanup here.
   // ...

   // Free fonts, bitmaps, and all other graphics resources
   vsTerminate();

   // Exit the application
   //exit(0);
   appExit();
}

/**
 * Go to sleep and free up the CPU. Wake up when the specified amount of time
 * in msec has reached or when there are some input activity on the
 * specified file descriptor.
 * 
 * @param msec   wait time out (msec)
 * @param fd     read file descriptor
 * 
 * @return 0 for timed-out, 1 for early exit due to data presence, 2 for error
 */
static int smartNap(unsigned long msec, int fd)
{
   fd_set rfds;
   struct timeval tv;
   int status;

   FD_ZERO(&rfds);
   FD_SET(fd, &rfds);
   if (msec >= 1000) {
      tv.tv_sec = (time_t)(msec / 1000);
      tv.tv_usec = (msec % 1000) * 1000;
   } else {
      tv.tv_sec = 0;
      tv.tv_usec = msec * 1000;
   }
   status = select(fd + 1, &rfds, NULL, NULL, &tv);
   if (status > 0) {
      //printf("smartNap GOT DATA\n");
      return(1);
   } else if (!status) {
      //printf("smartNap TIMED-OUT\n");
      return(0);
   }
   // select() error.
   return(2);
}

/**
 * Initialize the editor engine.
 * 
 * @param execPath full path to the executable directory. Example: /s/vslick900/bin/
 * @param argc     command line argument count
 * @param argv     command line arguments
 * 
 * @return 0 OK, !0 error
 */
static int initVSAPI(char * execPath, int argc, char ** argv)
{
   char path[1024];
   VSINIT init;
   int status;

   // Initalize the VSAPI initialization fields.
   memset(&init, 0, sizeof(VSINIT));
   init.ApiVersion = VSAPIVERSION;
   init.pszExecutablePath = execPath;
   init.hinstance = gXDisplay;
   init.argc = argc - 1;
   init.argv = argv + 1;
   char * envHome = getenv("HOME");
   if (!envHome || !*envHome) {
      init.pszConfigDir = "/tmp/.vslick"TINYAPPNAME;
   } else {
      if (*envHome == '/' && *(envHome+1) == 0) {
         strcpy(path, "/.vslick"TINYAPPNAME);
      } else {
         sprintf(path, "%s/.vslick"TINYAPPNAME, envHome);
      }
      init.pszConfigDir = path;
   }
   printf("initVSAPI init.pszConfigDir='%s'\n",init.pszConfigDir);
   init.pszApplicationName = TINYAPPNAME;
   init.ppEnv = (char **)0;

   // Initialize VSAPI, the editor core.
   status = vsInit(&init);
   if (status) {
      printf(TINYAPPNAME": Failed to initialize VSAPI. Error code=%d.\n",status);
      return(status);
   }

   // Register a VSE command for application exit.
   //
   // There is already a safe_exit() command which is bound to different
   // keys depending on the emulation. By registering this command, the
   // default safe_exit command is replaced and all key bindings for
   // safe_exit() will call the CallbackAppExit() callback.
   vsLibExport("_command void safe_exit()", 0,
               VSARG2_READ_ONLY|VSARG2_EDITORCTL,
               (void *)CallbackAppExit);
   printf(TINYAPPNAME": VSAPI initialized.\n");
   return(0);
}

/**
 * Create the actual editor control in the GTK container.
 * 
 * @return 0 OK, !0 error
 */
static int createEditorControl()
{
   // Access the container X window.
   GdkWindow * gdkTextWin = gtk_text_view_get_window((GtkTextView *)gEditorContainer, GTK_TEXT_WINDOW_TEXT);
   Window xw = GDK_WINDOW_XID(gdkTextWin);

   // Get the container dimension.
   XWindowAttributes attr;
   XGetWindowAttributes(gXDisplay, xw, &attr);
   int x = 0;
   int y = 0;
   int width = attr.width;
   int height = attr.height;

   // This sample code will load a file from disk. Since the
   // IgnoreNotFound is 1, this buffer gets created even if junk.cpp is
   // not found.
   int buf_id;
   buf_id = vsBufEdit("junk.cpp");
   if (buf_id < 0) return(-1);

   // Create the editor control.
   gEditorID = vsCreateEditorCtl(0,
                                 (VSSYSHWND)xw, // parent X window
                                 x, y, width, height,
                                 VSBDS_FIXED_SINGLE,
                                 1, // visible
                                 buf_id, // Buffer id
                                 0,
                                 0);

   // Wrap the editor control X window inside a GDK window.
   Window editorXW = vsXWIDToXWindow(gEditorID);
   GdkWindow * gdkEditorWin = gdk_window_foreign_new((GdkNativeWindow)editorXW);
   printf("createEditorControl ************* gEditorID=%d editorXW=%08x gdkEditorWin=%08x\n",gEditorID,editorXW,gdkEditorWin);

   // Now we insert some data into the control. Turn off undo while
   // inserting text.
   int old_undo_steps = vsPropGetI(gEditorID, VSP_UNDOSTEPS);
   vsPropSetI(gEditorID, VSP_UNDOSTEPS, 0);

   // If no file was loaded, this only deletes one line.  We probably
   // would not want delete all the lines in a file we just loaded but
   // this makes this sample code always give the same result.
   vsDeleteAll(gEditorID);

   vsInsertLine(gEditorID,"void main (int argc, char *argv[])");
   vsInsertLine(gEditorID,"{");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"   Hello there");
   vsInsertLine(gEditorID,"}");

   // Restore undo.
   vsPropSetI(gEditorID, VSP_UNDOSTEPS, old_undo_steps);
   vsPropSetI(gEditorID, VSP_ALLOWSAVE, 1);

   // Allow source recording.
   vsPropSetI(gEditorID, VSP_SOURCERECORDING, 1);

   // Clear the buffer modified flag.
   vsPropSetI(gEditorID, VSP_MODIFY, 0);

   // Refresh editor window.
   vsRefresh();
   printf(TINYAPPNAME": Created editor control. ID=%d\n",gEditorID);
   return(0);
}

//----------------------------------------------------------------------
int main (int argc, char *argv[])
{
   // Initialize GTK.
   gtk_init(&argc, &argv);

   // Get the X server connection (display).
   gXDisplay = GDK_DISPLAY();

   // Create the application top level window.
   gToplevel = gtk_window_new(GTK_WINDOW_TOPLEVEL);
   gtk_container_set_border_width(GTK_CONTAINER(gToplevel), 0);
   gtk_window_resize((GtkWindow *)gToplevel, cAppWidth, cAppHeight);

   // Add callback to handle application window closing.
   g_signal_connect(G_OBJECT(gToplevel), "delete_event", G_CALLBACK(delete_event), NULL);

   // Add callback to handle application window XYWH changing.
   g_signal_connect(G_OBJECT(gToplevel), "configure_event", G_CALLBACK(toplevelResizeCB), NULL);

   // Add callback to close the applicationl.
   g_signal_connect(G_OBJECT(gToplevel), "destroy", G_CALLBACK(destroy), NULL);

   // Create the container for the button and edit view.
   gAppContainer = gtk_fixed_new();
   gtk_widget_set_uposition(gAppContainer, 0, 0);
   gtk_widget_set_size_request(gAppContainer, cAppWidth, cAppHeight);

   // Create the button and editor view controls.
   gButton = gtk_button_new_with_label("Click to exit");
   gtk_widget_set_uposition(gButton, 0, 0);
   gtk_widget_set_size_request(gButton, cAppWidth, cButtonHeight);
   gEditorContainer = gtk_text_view_new();
   gtk_widget_set_uposition(gEditorContainer, 0, cButtonHeight);
   gtk_widget_set_size_request(gEditorContainer, cAppWidth, cAppHeight-cButtonHeight);
   gtk_text_view_set_wrap_mode((GtkTextView *)gEditorContainer, GTK_WRAP_WORD);
   gtk_text_view_set_editable((GtkTextView *)gEditorContainer, FALSE);
   gtk_text_view_set_cursor_visible((GtkTextView *)gEditorContainer, FALSE);

   // Add callbacks.
   g_signal_connect(G_OBJECT(gEditorContainer), "focus_in_event", G_CALLBACK(containerCB), NULL);
   g_signal_connect(G_OBJECT(gEditorContainer), "focus_out_event", G_CALLBACK(containerCB), NULL);
   g_signal_connect_swapped(G_OBJECT(gButton), "clicked", G_CALLBACK(gtk_widget_destroy), G_OBJECT(gToplevel));

   // Add the top level container to the top level window.
   gtk_container_add(GTK_CONTAINER(gToplevel), gAppContainer);

   // Add the controls to the top level container.
   //gtk_container_add(GTK_CONTAINER(gAppContainer), gButton);
   //gtk_container_add(GTK_CONTAINER(gAppContainer), gEditorContainer);
   gtk_fixed_put((GtkFixed *)gAppContainer, gButton, 0, cAppMarginY);
   gtk_fixed_put((GtkFixed *)gAppContainer, gEditorContainer, 0, cAppMarginY+cButtonHeight+cGapY);

   // Show everything.
   gtk_widget_show(gButton);
   gtk_widget_show(gEditorContainer);
   gtk_widget_show(gAppContainer);
   gtk_widget_show(gToplevel);

   {  // Testing/Tracing...
      Window toplevelXW = GDK_WINDOW_XID(gToplevel->window);
      Window buttonXW = GDK_WINDOW_XID(gButton->window);
      printf("main gToplevel=%08x toplevelXW=%08x buttonXW=%08x parent=%08x\n",gToplevel,toplevelXW,buttonXW,gButton->parent);
      printf("   gToplevel->window=%08x xw=%08x\n",(unsigned int)gToplevel->window,GDK_WINDOW_XID(gToplevel->window));
      printf("   gButton->window=%08x xw=%08x\n",(unsigned int)gButton->window,GDK_WINDOW_XID(gButton->window));
      printf("   gEditorContainer->window=%08x xw=%08x\n",(unsigned int)gEditorContainer->window,GDK_WINDOW_XID(gEditorContainer->window));
      GdkWindow * gdkTextWin = gtk_text_view_get_window((GtkTextView *)gEditorContainer, GTK_TEXT_WINDOW_TEXT);
      printf("   gdkTextWin=%08x xw=%08x\n",gdkTextWin,GDK_WINDOW_XID(gdkTextWin));
   }

   // Initialize the editor control engine.
   //
   // Note that here I cheated by hard coding a relative path to the
   // bin directory from the <VSROOT>/samples/unix/editorctl/TinyGTK/
   // directory.
   //
   // For the OEM customer, this path should be pointed to directory
   // containing libvsapi.so. All other needed directories will be
   // derived relative to this path.
   initVSAPI("../../../../linux_gtk/", argc, argv);

   // Create the editor control.
   createEditorControl();

#if 0
   // This code path does not solve our problem with getting and processing
   // X events from the GTK/GDK. We can break all the loops we want but,
   // in modal loops and within the Eclipse framework, we have no control
   // over the receiving and routing of the events.
   //
   /* There are two issues:
   
      1. How can VSAPI receive the X events intended for its X windows?
         These X windows include that of the editor control, the Slick-C
         dialogs,... We can break the event loop (like I have done below)
         but that will not work for GTK's modal loops since we have no
         control over it.
         
      2. In our Slick-C modal event loop, how can VSAPI dispatch or
         redirect the GTK's X events to its widgets?
         
      Unlike our Motif editor control which uses Xt, GTK does not have
      a low-level hook where we can insert our X event dispatch
      functions and be able to receive X events from any event loop.
      
      I think we have a few options:
      
      A. Modify the v-layer to accept native controls. This is not good
         because of the estimated 2-product cycle effort.
         
      B. Create the editor control using the GTK's drawing area widgets
      
      C. Implement a GTK widget for the editor control
      
      gdk_window_lookup() to look up a GdkWindow from an X window
      gdk_event_put() to put a GdkEvent at the front of the Gdk event queue
   */

   // Main event loop.
   //
   // The editor control needs access to all raw X events. The GTK main
   // loop, gtk_main(), cannot be used. Below is a modified main event
   // loop that gives the editor control a chance to examine and process
   // raw X events.
   GdkEvent * gEvent;
   int napStatus;
   XEvent event;
   int continueToDispatch;
   int xfd = XConnectionNumber(gXDisplay);
   while (!gMainLoopDone) {
      // Get the next X event and let the editor control examine it first.
      if (XPending(gXDisplay)) {
         printEventQueue();
         XNextEvent(gXDisplay, &event);
         printXEventName("   ", &event);
         continueToDispatch = vsXDispatchXEvent(&event);
         if (!continueToDispatch) continue;

         // The editor control did not process the X event. Put it back
         // the event queue and let GDK/GTK process it as normal.
         XPutBackEvent(gXDisplay, &event);
      }

      // Process GDK events like normal.
      //gtk_main_do_event();
      if (gtk_events_pending()) {
         gtk_main_iteration();
         continue;
      }

      // Nothing to do... Go to sleep but immediately wake up whenever
      // an event appears on the queue.
      napStatus = smartNap(50, xfd);
      if (!napStatus) vsXIdleProcessing();
   }
#endif

   // Main event loop.
   gtk_main();

   // All done.
   return(0);
}
