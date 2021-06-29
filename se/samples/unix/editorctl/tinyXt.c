/*
   Link with vsXtR5.a on X11R5, -lXt -lX11
   Link with vsXtR6.a on X11R6, -lXt -lX11
*/
#include <stdio.h>
#include <stdlib.h>
#include <X11/keysym.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/Shell.h>

#include "vsapi.h"


//-------------------------------------------------------------------
const unsigned int appWidth = 500;
const unsigned int appHeight = 350;
const unsigned int messageLineHeight = 25;


//-------------------------------------------------------------------
static Display * appDisplay;
static Screen * appScreen;
static Window appRootWindow;

static XtAppContext appContext;
static Widget shell, topform, editArea, messageLineArea;

static int editorctl_wid = 0;


//-------------------------------------------------------------------
static void VSAPI CallbackAppExit();


//-------------------------------------------------------------------
static void appExit()
{
   exit(0);
}

static int bgetpathlen2(char *filename,int filenamelen)
{
   int pathlen;
   for (pathlen=filenamelen-1; pathlen>=0 && filename[pathlen]!='/'; --pathlen);
   return(pathlen+1);
}

static int zgetpathlen(char *filename_p)
{
   return(bgetpathlen2(filename_p,strlen(filename_p)));
}

static int AddEditorControlToDialog(Widget w)
{
   // Get the dimension for the widget containing the editor control:
   Window xw = XtWindow(w);
   XWindowAttributes attr;
   XGetWindowAttributes(appDisplay, xw, &attr);
   int x=0;
   int y=0;
   int width=attr.width;
   int height=attr.height;

   // This sample code will load a file from disk
   // Since the IgnoreNotFound is 1, this buffer
   // gets created even if junk.cpp is not found
   int buf_id;
   buf_id=vsBufEdit("junk.cpp");
   if (buf_id<0) {
      return(0);
   }

   // Create the editor control:
   int editorctl_wid;
   editorctl_wid=vsCreateEditorCtl(
                                  0,
                                  (VSSYSHWND)w,  // parent widget
                                  x,y,
                                  width,height,
                                  VSBDS_FIXED_SINGLE,
                                  1,        // visible
                                  buf_id,   // Buffer id
                                  0,
                                  0);
   // Here the BUFNAME property is already set and
   // the mode has already been selected.

   // Now we insert some data into the control
   // For efficiency, temporarily turn off undo
   int old_undo_steps;
   old_undo_steps=vsPropGetI(editorctl_wid,VSP_UNDOSTEPS);
   vsPropSetI(editorctl_wid,VSP_UNDOSTEPS,0);

   // If no file was loaded, this only deletes one line.  We
   // probably would not want delete all the lines in a file
   // we just loaded but this makes this sample code always
   // give the same result.
   vsDeleteAll(editorctl_wid);

   vsInsertLine(editorctl_wid,"void main (int argc, char *argv[])");
   vsInsertLine(editorctl_wid,"{");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"   Hello there");
   vsInsertLine(editorctl_wid,"}");
   vsPropSetI(editorctl_wid,VSP_UNDOSTEPS,old_undo_steps);
   vsPropSetI(editorctl_wid,VSP_ALLOWSAVE,1);
   // Allow source recording
   vsPropSetI(editorctl_wid,VSP_SOURCERECORDING,1);

   // Indicate that the user has not modified this buffer
   vsPropSetI(editorctl_wid,VSP_MODIFY,0);
   // Need to call refresh to update the editor scroll bars.
   vsRefresh();
   return(editorctl_wid);
}
static void formInputHandler(Widget w, XtPointer client_data, XEvent * event,
                             Boolean * continueToDispatch)
{
   *continueToDispatch = True;
   if (event->type == CreateNotify) {
      static int firstmap = 1;

      // Once the edit area has been created, create the editor control.
      // The edit area is the parent widget containing the editor control.
      if (firstmap && event->xcreatewindow.window == XtWindow(editArea)) {
         firstmap = 0;
         editorctl_wid = AddEditorControlToDialog(editArea);

         // Also set focus to the editor control:
         // Focus can be removed from the editor control using vsKillFocus().
         vsSetFocus(editorctl_wid);
      }
   } else if (event->type == ConfigureNotify) {
      if (event->xconfigure.window == XtWindow(topform)) {
         unsigned int newWidth = event->xconfigure.width;
         unsigned int newHeight = event->xconfigure.height;
         XMoveResizeWindow(appDisplay, XtWindow(editArea)
                           ,0, 0
                           ,newWidth, newHeight-messageLineHeight);
         XMoveResizeWindow(appDisplay, XtWindow(messageLineArea)
                           ,0, newHeight - messageLineHeight
                           ,newWidth, messageLineHeight);
      }
   }
}

static void VSAPI CallbackAppExit()
{
   // Save the auto-restore information
   // Here we want dialog box retrieval, command retrieval,
   // and clipboards
   vsExecute(VSWID_MDI,"save_window_config");
   // Tell Visual SlickEdit not to send events
   vsPrepareForTerminate();

   // Do your own application cleanup here.

   // Free fonts, bitmaps, and all other graphics resources
   vsTerminate();

   // Exit the application
   //exit(0);
   appExit();
}

static void do_vsInit(char * pszExecutableName, int argc, char ** argv)
{
   VSINIT init;
   memset(&init,0,sizeof(VSINIT));
   init.ApiVersion=VSAPIVERSION;
   char ExecutablePath[1024];

   strcpy(ExecutablePath,pszExecutableName);
   int pathlen;
   // Strip the exe name
   pathlen=zgetpathlen(pszExecutableName);
   ExecutablePath[pathlen]=0;
   //init.pszExecutablePath=ExecutablePath;
   init.pszExecutablePath="../../../bin/";
   init.hinstance=appDisplay;

   init.argc=argc-1;
   init.argv=argv+1;
   /*
       Single user with one configuration.

           set this to <OEMproduct>/vslick

       Multiple users where each has their own configurations.


           set this to $HOME/.vslick/<OEMproduct>/

       Here for simplicity we are specifying a single user
       configuration case: $HOME/.vslickTiny/
   */

   char path[1024];
   char * envHome = getenv("HOME");
   if (!envHome) {
      init.pszConfigDir=0;
   } else {
      if (*envHome == '/' && *(envHome+1) == 0) {
         strcpy(path, "/.vslickTiny");
      } else {
         sprintf(path, "%s/.vslickTiny", envHome);
      }
      init.pszConfigDir=path;
      printf("init.pszConfigDir=%s\n",init.pszConfigDir);
   }
   init.pszApplicationName="Tiny2";
   init.ppEnv=(char **)0;


   //init.pfnRefresh=CallbackRefresh;
   //init.pfnUseCurrentInstance=CallbackUseCurrentInstance;
   vsInit(&init);

   // register a VSE command for application exit

   // There is already a safe_exit exit command which is
   // bound to different keys depending on the emulation.
   // By registering this command, the default safe_exit command
   // is replaced and all key bindings for safe_exit will call the
   // CallbackAppExit() callback.
   vsLibExport("_command void safe_exit()",0,VSARG2_READ_ONLY|VSARG2_EDITORCTL,(void *)CallbackAppExit);
}

int main(int argc, char **argv)
{
   // Create a toplevel shell to hold the app:
   shell = XtVaAppInitialize(&appContext, "mainW", NULL, 0,
  			 &argc, argv, NULL,
                         XtNx, 10,
                         XtNy, 10,
                         XtNwidth, appWidth,
                         XtNheight, appHeight,
                         XtNinput, True,  // need this to get focus from window manager
                         NULL);

   // Create the X window for this widget. This is required so that by the
   // time the editor control is created, its parent X window is also
   // created.
   XtRealizeWidget(shell);

   // Need to tell the X server to dispatch FocusIn, FocusOut, and 
   // Enter and Leave events to every shell window. This can also be done
   // using XSelectInput().
   XtAddEventHandler(shell
                     ,FocusChangeMask|EnterWindowMask|LeaveWindowMask
                     ,True, formInputHandler, 0
                     );

   // Default application resources:
   appDisplay = XtDisplay(shell);
   appScreen = DefaultScreenOfDisplay(appDisplay);
   appRootWindow = DefaultRootWindow( appDisplay );
   
   // Init VSE editor control:
   do_vsInit("/vslick30/rt/slick/linux/tinyctl", argc, argv);

   // Create top form to hold everything:
   topform = XtVaCreateManagedWidget("topform", compositeWidgetClass
                                     ,shell
                                     ,XtNx, 0
                                     ,XtNy, 0
                                     ,XtNwidth, appWidth
                                     ,XtNheight, appHeight
                                     ,XtNborderWidth, 0
                                     ,NULL);
   XtAddEventHandler(topform, SubstructureNotifyMask|StructureNotifyMask
                     ,True, formInputHandler, 0);

   // Hook the edit area's parent to monitor the creation of the
   // edit area. When the edit area is created, the editor control
   // is created.
   XtAddEventHandler(topform, SubstructureNotifyMask,
                     False, formInputHandler, 0);

   // Create parent window to hold the editor control:
   editArea = XtVaCreateManagedWidget("topform", compositeWidgetClass
                                      ,topform
                                      ,XtNx, 0
                                      ,XtNy, 0
                                      ,XtNwidth, appWidth
                                      ,XtNheight, appHeight-messageLineHeight
                                      ,XtNborderWidth, 0
                                      ,NULL);

   // Create message line:
   messageLineArea = XtVaCreateManagedWidget("messageLineArea", compositeWidgetClass
                                             ,topform
                                             ,XtNx, 0
                                             ,XtNy, appHeight-messageLineHeight
                                             ,XtNwidth, appWidth
                                             ,XtNheight, messageLineHeight
                                             ,XtNborderWidth, 0
                                             ,NULL);

   // Do the loop:
   // If your version of Xt is R6 or after, you can just use XtAppMainLoop().
   // Otherwise, you need to unravel the event loop.
#if XTVERSION >= 6
   // Xt in X11R6 provides a hook into the Xt event handler. The editor control
   // hooks into the Xt event loop automatically.
   XtAppMainLoop(appContext);
#else
   // Xt in X11R5 does not support an event hook that the editor control
   // needs. You need to unravel the X event loop and let the editor control
   // take a look at every X event to the application before you can process
   // the X event.
   while (1) {
      // Get the next X event:
      XEvent event;
      XtAppNextEvent(appContext, &event);

      // Got X event. Let the editor control take a look at it first.
      int continueToDispatch = vsXDispatchXEvent(&event);
      if (!continueToDispatch) continue;

      // The editor control did not process the X event. Let process it now.
      XtDispatchEvent(&event);
   }
#endif 

   exit(0);
}
