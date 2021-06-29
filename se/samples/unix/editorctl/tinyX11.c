/*
   Linking with vsX11.a, -lXt -lX11
*/
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <X11/keysym.h>
#include <X11/Intrinsic.h>

#include "vsapi.h"


//-------------------------------------------------------------------
const unsigned int appWidth = 500;
const unsigned int appHeight = 400;


//-------------------------------------------------------------------
static Display * appDisplay;
static Screen * appScreen;
static Window appRootWindow;
static Window shell, editArea;
static int editorctl_wid = 0;


//-------------------------------------------------------------------
static void VSAPI CallbackAppExit();


//-------------------------------------------------------------------
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

static int AddEditorControlToDialog(Window xw)
{
   // Get the dimension for the widget containing the editor control:
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
                                  (VSSYSHWND)xw,  // parent widget
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
   exit(0);
}

static void do_vsInit(char * pszExecutableName, int argc, char ** argv)
{
   VSINIT init;
   memset(&init,0,sizeof(VSINIT));
   init.ApiVersion=VSAPIVERSION;
   char ExecutablePath[1024];
   int pathlen;

   // Strip the exe name
   strcpy(ExecutablePath,pszExecutableName);
   pathlen=zgetpathlen(pszExecutableName);
   ExecutablePath[pathlen]=0;
   init.pszExecutablePath=ExecutablePath;
   init.hinstance=appDisplay;

   init.argc=argc-1;
   init.argv=argv+1;
   /*
       Single user with one configuration.

           set this to <OEMproduct>/vslick

       Multiple users where each has their own configurations.

           set this to $HOME/.vslick/<OEMproduct>/
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
   }
   init.pszApplicationName="TinyX11";
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

//-------------------------------------------------------------------
// Desc: Sleep a little bit. The implementation of this function may
//       vary a little between different platforms.
//       sleepDelay is in microseconds.
void takeNap(unsigned int sleepDelay)
{
   struct timeval timeout;
   timeout.tv_sec = 0;
   timeout.tv_usec = sleepDelay;
   select(0, 0, 0, 0, &timeout);
}

// Desc: If there is a pending X event, get it. If there is not, sleep and return
//       when sleep timer expires.
// Retn: 0 got X event, 1 no event
int tinyXNextEvent(XEvent * event)
{
   // Start out with small delay and work our way up. This yields
   // faster response time to X events when needed.
   unsigned int enoughSleep = 50000;
   unsigned int sleepDelay = 0;
   unsigned int totalSleep = 0;
   while (!XPending(appDisplay)) {
      sleepDelay = sleepDelay + 5000;
      takeNap(sleepDelay);
      totalSleep = totalSleep + sleepDelay;
      if (totalSleep > enoughSleep) return(1);
   }
   XNextEvent(appDisplay, event);
   return(0);
}

// Desc: Process an X event.
// Retn: 1 event dispatched, 0 event ignored
int tinyXDispatch(XEvent * event)
{
   //printf("tinyXDispatch %s xw=%x\n",xfiXEventNameList[event->type],event->xany.window);
   switch (event->type) {
   case ConfigureNotify:
      // Shell window was resized, resize the editor parent window:
      if (event->xconfigure.window == shell) {
         XResizeWindow(appDisplay, editArea
                       ,event->xconfigure.width
                       ,event->xconfigure.height);
         return(1);
      }
      break;
   }
   return(0);
}

int main(int argc, char **argv)
{
   // Open connection to X server:
   appDisplay = XOpenDisplay(NULL);
   appScreen = DefaultScreenOfDisplay(appDisplay);
   appRootWindow = DefaultRootWindow( appDisplay );

   // Create a toplevel shell to hold the app:
   unsigned long mask = 0;
   XSetWindowAttributes attr;
   shell = XCreateWindow(appDisplay, appRootWindow
                         ,0, 0, appWidth, appHeight, 0
                         ,CopyFromParent
                         ,InputOutput
                         ,CopyFromParent
                         ,mask
                         ,&attr
                         );
   XMapWindow(appDisplay, shell);

   // Need to tell the X server to dispatch FocusIn, FocusOut, and 
   // Enter and Leave events to every shell window. This can also be done
   // using XSelectInput().
   XSelectInput(appDisplay, shell
                ,FocusChangeMask|EnterWindowMask|LeaveWindowMask|StructureNotifyMask
                );
   
   // Init VSE editor control:
   do_vsInit(argv[0], argc, argv);

   // Tell VSE about your application shell windows. If your application uses
   // Motif or Xt, registering the shells is done automatically whenever an
   // editor control is created. In this case of a raw X11 application, you have
   // to tell VSE editor control about all shells that the application creates.
   // (A shell is a child of the root window.)
   vsRegisterWindow((VSSYSHWND)shell, (VSSYSHWND)shell, VSOI_FORM);

   // Register Tiny's X event dispatcher. The dispatcher is the procedure
   // that processes (or dispatches) all X events.
   vsXRegisterX11Dispatcher(tinyXDispatch);

   // Create a window to hold the editor control:
   editArea = XCreateWindow(appDisplay, shell
                           ,0, 0, appWidth, appHeight, 0
                           ,CopyFromParent
                           ,InputOutput
                           ,CopyFromParent
                           ,mask
                           ,&attr
                           );
   XSelectInput(appDisplay, editArea, StructureNotifyMask|ExposureMask);
   XMapWindow(appDisplay, editArea);

   // Create the editor control and set focus to it.
   // Focus can be removed from the editor control using vsKillFocus().
   editorctl_wid = AddEditorControlToDialog(editArea);
   vsSetFocus(editorctl_wid);

   // Do the loop.
   // Please note that unraveling the X event loop it only needed for raw
   // X application. If you are using Xt and X11R6, you can use XtAppMainLoop().
   while (1) {
      // Get the next X event or, if there is none, sleep a little and try again.
      XEvent event;
      int slept = tinyXNextEvent(&event);

      // Got some idle time. Let the editor control do its idle-time activities.
      if (slept) {
         vsXIdleProcessing();
         continue;
      }

      // Got X event. Let the editor control take a look at it first.
      int continueToDispatch = vsXDispatchXEvent(&event);
      if (!continueToDispatch) continue;

      // The editor control did not process the X event. Let process it now.
      // Process your application's X event here.
      // Need to call XFilterEvent to support internatialization and localization.
      if (XFilterEvent(&event, event.xany.window) == True) {
         continue;
      }
      tinyXDispatch(&event);
   }
   exit(0);
}
