#include <stdio.h>
#include <stdlib.h>
#include <X11/keysym.h>
#include <X11/Xlocale.h>
#include <Xm/Xm.h>
#include <Xm/Form.h>
#include <Xm/RowColumn.h>
#include <Xm/PushB.h>
#include <Xm/PushBG.h>
#include <Xm/Label.h>
#include <Xm/SeparatoG.h>
#include <Xm/MainW.h>
#include <Xm/DrawingA.h>
#include <Xm/CascadeB.h>
#include <Xm/TextF.h>
#include <Xm/Text.h>
#include <Xm/BulletinB.h>
#include "vsapi.h"


//-------------------------------------------------------------------
const unsigned int messageLineHeight = 35;
const unsigned int commandLineHeight = 30;
const unsigned int controlAreaWidth = 100;


//-------------------------------------------------------------------
const int MaxRGBPixelCount = 256;
class RGBPixelInfo {
public:
   unsigned long rgb;
   Pixel pixel;
};
const int tinyCmdX = 60;


//-------------------------------------------------------------------
static Display * appDisplay;
static Screen * appScreen;
static Colormap appColormap;

static int rgbPixelCount = 0;
static RGBPixelInfo rgbPixelList[MaxRGBPixelCount];
static Pixel appBgColor, appFgColor, appTsColor, appBsColor, appSeColor;
static Window appRootWindow;
static GC * gcList = 0;
static unsigned int gcListSize = 0;
static unsigned int gcCount = 0;

static XtAppContext appContext;
static Widget shell, topform;
static Widget b1;
static Widget topDrawingArea, messageLineArea, controlPanelArea, appMenubar;
static Widget editArea, messageLineCmd;

static int messageLineCmdActive = 0;

static int editorctl_wid = 0;


//-------------------------------------------------------------------
#define TINYBUTTON_COMMAND "Command"
#define TINYBUTTON_SETFOCUS "Set Focus"
#define TINYBUTTON_DIFF "Diff"
#define TINYBUTTON_MISC "Misc"
#define TINYBUTTON_UNUSED "Unused"
#define TINYBUTTON_EXITTINY "Exit Tiny"
static char * buttonList[] = {
   TINYBUTTON_COMMAND
   ,TINYBUTTON_SETFOCUS
   ,TINYBUTTON_DIFF
   ,TINYBUTTON_MISC
   ,TINYBUTTON_EXITTINY
};
static void cpanelButtonCb(Widget w, XtPointer client_data,
                           XtPointer call_data);
static XtCallbackProc buttonListProc[] = {
   cpanelButtonCb
   ,cpanelButtonCb
   ,cpanelButtonCb
   ,cpanelButtonCb
   ,cpanelButtonCb
};


//-------------------------------------------------------------------
static GC createGC(Window xw = (Window)0);
static int appLoadFont(char * foundry = (char *)0, char * name = (char *)0,
                       int size = 10, int bold = 0, int italic = 0,
                       char * charset = (char *)0);
static void VSAPI CallbackAppExit();


//-------------------------------------------------------------------
static void printError(char * msg)
{
   int l = strlen(msg);
   if (!l) return;
   if (*(msg + l - 1) != '\n') {
      *(msg + l) = '\n';
      *(msg + l + 1) = 0;
   }
   printf("%s", msg);
}

// Desc:  Create a GC and keep this in a list for later removal.
//     We need to to this so that the X server won't run out of GC.
static GC createGC(Window xw)
{
   static XGCValues values;
   static unsigned long mask = GCGraphicsExposures;

   if (xw == (Window)0) xw = appRootWindow;
   values.graphics_exposures = False;
   GC gc = XCreateGC( appDisplay, xw, mask, &values );

   // Make sure there's enough space in GC list:
   if (gcCount >= gcListSize) {
      unsigned int newSize = gcListSize * 2;
      if (!newSize) newSize = 128;
      GC * newList = new GC[newSize];
      if (gcCount) {
         memcpy((void *)newList, (void *)gcList, gcCount*sizeof(GC));
         delete []gcList;
      }
      gcList = newList;
      gcListSize = newSize;
   }
   gcList[gcCount] = gc;
   gcCount++;
   return( gc );
}
void destroyGC( GC gc )
{
   XFreeGC( appDisplay, gc );
   int i;
   for (i=0; i<gcCount; i++) {
      if (gc != gcList[i]) continue;
      int ii;
      for (ii=i+1; ii<gcCount; ii++) {
         gcList[ii-1] = gcList[ii];
      }
      gcCount--;
      break;
   }
}
void destroyAllGC()
{
   int i;
   for (i=0; i<gcCount; i++) {
      XFreeGC(appDisplay, gcList[i]);
   }
   gcCount = 0;
}

// Desc:  Allocate a color cell in the colormap.
//     If the cell can not be allocated, try to find the closest one.  This
//     function must never come back with an error.  Some pixel value is
//     always returned.  In the case where an error occurred, pixel 1 (black)
//     is returned.
// Retn:  Always 1.
static int allocColor( Display * display, Colormap colormap, XColor * xc )
{
   // Try the mormal allocation routine:
   if ( XAllocColor( display, colormap, xc ) ) return( 1 );

   // Get the colormap:
   xc->pixel = 1;
   int nCells = CellsOfScreen( appScreen );
   XColor * xcList = (XColor *)malloc( nCells * sizeof(XColor) );
   if ( !xcList ) return( 1 );
   int i;
   for ( i = 0; i < nCells; i++ ) xcList[i].pixel = i;
   XQueryColors( display, colormap, xcList, nCells );

   // Try matching with the closest RGB value:
   int red = (int)(((int)(xc->red & 0xff00))>>8);
   int green = (int)(((int)(xc->green & 0xff00))>>8);
   int blue = (int)(((int)(xc->blue & 0xff00))>>8);
   int smallestDiff = 0x0fffffff;
   int closestPix = 0;
   for ( i = 0; i < nCells; i++ ) {
      XColor & xcc = xcList[i];
      int diffR = (int)(((int)(xcc.red & 0xff00))>>8) - red;
      int diffG = (int)(((int)(xcc.green & 0xff00))>>8) - green;
      int diffB = (int)(((int)(xcc.blue & 0xff00))>>8) - blue;
      if ( diffR < 0 ) diffR = -diffR;
      if ( diffG < 0 ) diffG = -diffG;
      if ( diffB < 0 ) diffB = -diffB;
      int totalDiff = diffR + diffG + diffB;
      if ( totalDiff < smallestDiff ) {
         smallestDiff = totalDiff;
         closestPix = i;
      }
   }
   xc->pixel = xcList[closestPix].pixel;
   xc->red = xcList[closestPix].red;
   xc->green = xcList[closestPix].green;
   xc->blue = xcList[closestPix].blue;
   free( xcList );

   return( 1 );
}

// Desc:  Convert RGB value to pixel value.
static Pixel rgbToPixel(unsigned long rgb)
{
   //xprintf( "rgbToPixel rgb=%x\n", rgb );
   // Fast lookup for existing rgb value:
   unsigned long wrgb = ((rgb&0xff0000)>>16) | (rgb&0xff00) | ((rgb&0xff)<<16);
   int i;
   for ( i = 0; i < rgbPixelCount; i++ ) {
      if ( wrgb == rgbPixelList[i].rgb ) return( rgbPixelList[i].pixel );
   }

   // New rgb value:
   XColor xc;
   xc.red = (unsigned short)((rgb&0xff0000)>>8);
   xc.green = (unsigned short)(rgb&0xff00);
   xc.blue = (unsigned short)((rgb&0xff)<<8);
   if ( allocColor(appDisplay, appColormap, &xc ) == 0) return( (Pixel)1 );

   // Add new rgb-pixel pair:
   if ( rgbPixelCount < MaxRGBPixelCount ) {
      rgbPixelList[rgbPixelCount].rgb = wrgb;
      rgbPixelList[rgbPixelCount].pixel = xc.pixel;
      rgbPixelCount++;
   }
   return( (Pixel)xc.pixel );
}

static void appExit()
{
   destroyAllGC();
   exit(0);
}

// Desc:  Given a set of font attributes, build a font name pattern.
// Para:  pattern            Returned font name pattern
//        faceName           Font name (ie. adobe-courier)
//        size               Point size
static void buildFontNamePattern(char * pattern, char * foundry, char * name,
        int size, int bold, int italic, char * fCharSet)
{
   char ptSizeText[32];
   strcpy(ptSizeText, "*");
   size = size * 10;
   if (size > 1000) size = 1000;
   else if (size < 80) size = 80;
   sprintf(ptSizeText, "%d", size);

   char weight[32];
   strcpy(weight, bold?"bold":"medium");

   char slant[32];
   strcpy(slant, italic?"o":"r");

   char foundryText[64];
   if (!foundry || *foundry == 0) strcpy(foundryText, "adobe");
   else strcpy(foundryText, foundry);

   char nameText[64];
   if (!name || *name == 0) strcpy(nameText, "helvetica");
   else strcpy(nameText, name);

   sprintf(pattern, "-%s-%s-%s-%s-*-*-*-%s", foundry, name, weight, slant, ptSizeText );

   int l = strlen( pattern );
   char widthText[32];
   strcpy( widthText, "*" );
   char charSetText[64];
   if ( !fCharSet || *fCharSet == 0 ) {
      strcpy( charSetText, "iso8859-1" );
   } else {
      strcpy( charSetText, fCharSet );
   }
   int fontres = 75;
   sprintf(&pattern[l], "-%d-%d-*-%s-%s", fontres, fontres, widthText, charSetText);
}
static int appLoadFont(char * foundry, char * name, int size, int bold,
                       int italic, char * charset,
                       Font & fontId, XFontStruct * & fontInfo)
{
   char fontName[1024];
   buildFontNamePattern(fontName, foundry, name, size, bold, italic, charset);
   fontId = XLoadFont(appDisplay, fontName);
   if (!fontId) {
      fontId = XLoadFont(appDisplay, "fixed");
   }
   if (!fontId) return(-1);
   fontInfo = XQueryFont(appDisplay, fontId);
   if (!fontInfo) return(-2);
   return(0);
}

static void writeMessageLine(char * msg)
{
   static GC gc = (GC)0;
   static Font fid;
   static XFontStruct * fs;
   static int fontHeight, baseLine;

   if (!gc) {
      gc = createGC();
      if (appLoadFont("adobe", "helvetica", 10, 'B', 0, 0, fid, fs)) {
         printError("Can't load font!");
         exit(-1);
      }
      XSetFont(appDisplay, gc, fid);
      fontHeight = fs->max_bounds.ascent + fs->max_bounds.descent;
      baseLine = fs->max_bounds.ascent;
   }
   Window xw = XtWindow(messageLineArea);
   if (!xw) return;
   if (!msg || *msg == 0) {
      XClearWindow(appDisplay, xw);
   } else {
      XWindowAttributes attr;
      XGetWindowAttributes(appDisplay, xw, &attr);
      int len = strlen(msg);
      int tx = 4;
      int ty = (attr.height - fontHeight) / 2 + baseLine;
      XDrawString(appDisplay, xw, gc, tx, ty, msg, len);
   }
   XFlush(appDisplay);
}
static void clearMessageLine()
{
   writeMessageLine(0);
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


static void appMenubarItemCb(Widget w, XtPointer client_data, XtPointer call_data)
{
   XmPushButtonCallbackStruct * cbd = (XmPushButtonCallbackStruct *)call_data;
   switch (cbd->reason) {
   case XmCR_ACTIVATE:
      CallbackAppExit();
      break;
   case XmCR_ARM:
   {
      char * name = XtName(w);
      if (!name || *name == 0) {
         writeMessageLine("No text");
      } else {
         writeMessageLine(name);
      }
      break;
   }
   case XmCR_DISARM:
      clearMessageLine();
      break;
   }
}

static void formResizeCb(Widget w, XtPointer client_data, XtPointer call_data)
{
   // Resize and reposition the children controls in the top drawing area:
   //printf("formResizeCb xw=%x\n",XtWindow(w));
   Window xw = XtWindow(w);
   XWindowAttributes attr;
   XGetWindowAttributes(appDisplay, xw, &attr);
   int width = attr.width;
   int height = attr.height;
   //printf("moving status line xywh=%d,%d,%d,%d\n",attr.x,attr.y,width,height);
   XMoveResizeWindow(appDisplay, XtWindow(messageLineArea)
                     ,0, (height - messageLineHeight), width, messageLineHeight);
   /*
   XtVaSetValues(messageLineArea
                 ,XmNx, 0
                 ,XmNy, (height - messageLineHeight)
                 ,XmNwidth, width
                 ,XmNheight, messageLineHeight
                 ,NULL
                 );
   */              
   //XMoveResizeWindow(appDisplay, XtWindow(messageLineCmd), 50, 3, (width-50), 24);
   XtVaSetValues(messageLineCmd
                 ,XmNwidth, (width-tinyCmdX-2)
                 ,NULL
                 );
   //XMoveResizeWindow(appDisplay, XtWindow(controlPanelArea), 0, 0, 100, (height - 30));
   XtVaSetValues(controlPanelArea
                 ,XmNx, 0
                 ,XmNy, 0
                 ,XmNwidth, controlAreaWidth
                 ,XmNheight, (height - messageLineHeight)
                 ,NULL
                 );
   //XMoveResizeWindow(appDisplay, XtWindow(editArea), 100, 0, (width - 100), (height - 30));
   XtVaSetValues(editArea
                 ,XmNx, 100
                 ,XmNy, 0
                 ,XmNwidth, (width - controlAreaWidth)
                 ,XmNheight, (height - messageLineHeight)
                 ,NULL
                 );
}
static void activateCommandLine()
{
   writeMessageLine("TinyCMD:");
   XtVaSetValues(messageLineCmd,XmNmappedWhenManaged, True,NULL);
   XmProcessTraversal(messageLineCmd, XmTRAVERSE_CURRENT);
}
static void tinyResetCursorProc(int editorID, // editor control ID
                                Cursor cursor
                                )
{
   //printf("tinyResetCursorProc %d %d\n",editorID,cursor);
   Widget shell = XtParent(editArea);
   while (shell) {
       if (!XtParent(shell)) break;
       shell = XtParent(shell);
   }
   Window xw = XtWindow(shell);
   XDefineCursor(appDisplay, xw, cursor);
   XFlush(appDisplay);
}
static void tinyShadowCalcProc(unsigned long bgRGB,
                               unsigned long * fgRGB, // return best foreground color for max contrast
                               unsigned long * tsRGB, // return top shadow
                               unsigned long * bsRGB, // return bottom shadow
                               unsigned long * seRGB  // return select/recessed color
                               )
{
   //printf("tinyShadowCalcProc\n");
   *fgRGB = 0x000000;
   *tsRGB = 0xff0000;
   *bsRGB = 0x0000ff;
   *seRGB = 0xffff00;
}
static int tinyAllocColor(unsigned long rrggbb,
                          int closest,
                          unsigned long * returnPixel,
                          unsigned long * returnActualRGB)
{
   //printf("tinyAllocColor\n");
   unsigned char val;
   XColor xc;
   xc.red = (unsigned short)((rrggbb & 0xff0000)>>8);
   xc.green = (unsigned short)(rrggbb & 0xff00);
   xc.blue = (unsigned short)((rrggbb & 0xff)<<8);
   xc.flags = DoRed | DoGreen | DoBlue;
   if (XAllocColor(appDisplay, appColormap, &xc)) {
      *returnPixel = xc.pixel;
      int red = (int)(((int)(xc.red & 0xff00))>>8);
      int green = (int)(((int)(xc.green & 0xff00))>>8);
      int blue = (int)(((int)(xc.blue & 0xff00))>>8);
      *returnActualRGB = (red << 16) | (green << 8) | blue;
      //printf("tinyAllocColor OK %06x return:%x %06x\n", rrggbb,*returnPixel,*returnActualRGB);
      return(0);
   }
   if (!closest) {
      //printf("tinyAllocColor ERROR %06x\n",rrggbb);
      return(1);
   }

   // Estimate closest pixel...

   // Get the colormap:
   xc.pixel = 1;
   int nCells = CellsOfScreen(appScreen);
   XColor * xcList = (XColor *)malloc( nCells * sizeof(XColor) );
   if (!xcList) return(0);
   int i;
   for (i=0; i<nCells; i++) xcList[i].pixel = i;
   XQueryColors(appDisplay, appColormap, xcList, nCells);

   // Try matching with the closest RGB value:
   int red = (int)(((int)(xc.red & 0xff00))>>8);
   int green = (int)(((int)(xc.green & 0xff00))>>8);
   int blue = (int)(((int)(xc.blue & 0xff00))>>8);
   int smallestDiff = 0x0fffffff;
   int closestPix = 0;
   for (i=0; i<nCells; i++) {
      XColor & xcc = xcList[i];
      int diffR = (int)(((int)(xcc.red & 0xff00))>>8) - red;
      int diffG = (int)(((int)(xcc.green & 0xff00))>>8) - green;
      int diffB = (int)(((int)(xcc.blue & 0xff00))>>8) - blue;
      if ( diffR < 0 ) diffR = -diffR;
      if ( diffG < 0 ) diffG = -diffG;
      if ( diffB < 0 ) diffB = -diffB;
      int totalDiff = diffR + diffG + diffB;
      if ( totalDiff < smallestDiff ) {
         smallestDiff = totalDiff;
         closestPix = i;
      }
   }
   xc.pixel = xcList[closestPix].pixel;
   xc.red = xcList[closestPix].red;
   xc.green = xcList[closestPix].green;
   xc.blue = xcList[closestPix].blue;
   free(xcList);

   *returnPixel = xc.pixel;
   red = (int)(((int)(xc.red & 0xff00))>>8);
   green = (int)(((int)(xc.green & 0xff00))>>8);
   blue = (int)(((int)(xc.blue & 0xff00))>>8);
   *returnActualRGB = (red << 16) | (green << 8) | blue;
   //printf("tinyAllocColor CLOSEST %06x return:%x %06x\n", rrggbb,*returnPixel,*returnActualRGB);
   return(0);
}
static int tinyDeallocColor(unsigned long pixel)
{
   return(0);
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
   
   // Change the editor colors and scrollbar width.
   vsXSetEditorColors(0, 0x00ffff, 0x000000);
   vsXSetScrollBarColors(0, 0xffff00,0x000000,0x00ff00,0xffffff,0xff0000,0x0000ff);
   vsXSetScrollBarSizes(0, 15, 2, 0, 0);
   vsXRegisterColorAllocProc(tinyAllocColor);
   vsXRegisterQueryShadowColors(tinyShadowCalcProc);
   vsXRegisterResetCursorProc(tinyResetCursorProc);

   // Create the editor control:
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
      }
   }
}
static void cpanelButtonCb(Widget w, XtPointer client_data, XtPointer call_data)
{
   XmPushButtonCallbackStruct * cbd = (XmPushButtonCallbackStruct *)call_data;
   char * name;
   switch (cbd->reason) {
   case XmCR_ACTIVATE:
      name = XtName(w);
      if (strcmp(name, TINYBUTTON_COMMAND) == 0) {
         activateCommandLine();
      } else if (strcmp(name, TINYBUTTON_SETFOCUS) == 0) {
         // There are two ways to do this.
         // -- Use Motif to set traversal focus to the widget containing
         //    the editor control
         // -- Call vsSetFocus() to force set focus to editor control
         XmProcessTraversal(editArea, XmTRAVERSE_CURRENT);
         //vsSetFocus(editorctl_wid);
      } else if (strcmp(name, TINYBUTTON_DIFF) == 0) {
         vsExecute(0,"diff /tmp/diff1.cc /tmp/diff2.cc");
      } else if (strcmp(name, TINYBUTTON_MISC) == 0) {
         /*
         vsSetEnv("TANJUNK", "This is TANJUNK");
         char * envVal = vsGetEnv("MAIL");
         printf("cpanelButtonCb MAIL=%s\n",envVal?envVal:"NULL");
         envVal = vsGetEnv("TANJUNK");
         printf("cpanelButtonCb TANJUNK=%s\n",envVal?envVal:"NULL");
         */
         printf("Destroying editor control\n");
         vsDestroyEditorCtl(editorctl_wid, 0);
      } else if (strcmp(name, TINYBUTTON_EXITTINY) == 0) {
         CallbackAppExit();
      }
      break;
   }
}
static void messageLineCmdCb(Widget w, XtPointer client_data, XtPointer call_data)
{
   char saveText[1024];
   char * text = XmTextFieldGetString(w);
   printf("TinyCMD = %s\n",text);
   strcpy(saveText, text);
   if (text && *text) XtFree(text);
   XmTextFieldSetString(w, "");
   clearMessageLine();
   XtVaSetValues(messageLineCmd,XmNmappedWhenManaged, False,NULL);
   XtVaSetValues(messageLineCmd, XmNuserData, 1, NULL);
   if (strcmp(saveText,"exit") == 0) {
      CallbackAppExit();
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
#define SOLARIS 1
#if SOLARIS
   extern char ** environ;
   init.ppEnv=(char **)environ;
#else
   extern char ** environ;
   init.ppEnv=(char **)__environ;
#endif


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

static void editorSetFocusCB(Widget w, XtPointer client_data, XtPointer call_data)
{
   XmAnyCallbackStruct * callInfo = (XmAnyCallbackStruct *)call_data;
   if (callInfo->reason == XmCR_FOCUS) {
      // Give focus to the editor control:
      vsSetFocus(editorctl_wid);
   } else if (callInfo->reason == XmCR_LOSING_FOCUS) {
      // Tell editor control that it no longer has focus:
      vsKillFocus(editorctl_wid);
   }
}

int main(int argc, char **argv)
{
   // Establish the locale:
   char * langname = getenv("LANG");
	if (setlocale(LC_ALL, langname) == NULL) {
      printf("Cannot set locale to %s.\n",langname);
		exit(1);
	}
   XtSetLanguageProc(NULL, NULL, NULL);

   // Create a toplevel shell to hold the application:
   shell = XtVaAppInitialize(&appContext, "mainW", NULL, 0,
  			 &argc, argv, NULL,
                         XmNx, 10,
                         XmNy, 10,
                         XmNwidth, 500,
                         XmNheight, 350,
                         NULL);

   // Create the X window for this widget. This is required so that by the
   // time the editor control is created, its parent X window is also
   // created.
   XtRealizeWidget(shell);

   // Default application resources:
   appDisplay = XtDisplay(shell);
   appScreen = DefaultScreenOfDisplay(appDisplay);
   appColormap = DefaultColormapOfScreen(appScreen);
   appRootWindow = DefaultRootWindow( appDisplay );
   
   // Init VSE editor control:
   do_vsInit("/vslick40c/isctl/tiny", argc, argv);

   // Tell VSE about the key combinations that VSE should ignore:
   // In this example, we tell the editor control to ignore Alt-e
   // and Alt-f, the two keys combination used to activate items
   // in the menubar.
   //
   // The 1st and 2nd arguments specify the start and end key
   // symbols for a range of keys. The editor control currently
   // supports keysyms between XK_exclam and XK_ydiaeresis,
   // and between XK_BackSpace and XK_Delete.
   //
   // The 3rd, 4th, and 5th arguments specify the modifier key
   // modes. The 3rd argument defines the mode for Shift. The 4th
   // argument defines the mode for Control. The 5th argument
   // defines the mode for Alt.
   //
   // Each modifier mode can have one of three values:
   //    0  -- "Don't care". The modifier key can be either pressed
   //          or released.
   //    1  -- "On". The modifier key must be pressed.
   //    2  -- "Off". The modifier key must be released.

   // Ignore Alt-e and Alt-f:
   vsXRegisterKeysToIgnore(XK_e, XK_e, 2, 2, 1);
   vsXRegisterKeysToIgnore(XK_f, XK_f, 2, 2, 1);

   // Ignore Tab and F10:
   // Just the Tab and F10. If any of the shift, control, or the
   // alt modifier is pressed, the editor control will keep the Tab
   // and F10 key.
   //vsXRegisterKeysToIgnore(XK_Tab, XK_Tab, 2, 2, 2);
   //vsXRegisterKeysToIgnore(XK_F10, XK_F10, 2, 2, 2);

   // Ignore key range Control-F1 to Control-F4:
   vsXRegisterKeysToIgnore(XK_F1, XK_F4, 0, 1, 0);

   // Ignore Control-Shift-Esc:
   vsXRegisterKeysToIgnore(XK_Escape, XK_Escape, 1, 1, 0);

   // Define an application wide background color and color scheme:
   appBgColor = rgbToPixel(0xc0c0c0);
   XmGetColors(appScreen, appColormap, appBgColor,
               &appFgColor, &appTsColor, &appBsColor, &appSeColor);

   // Create top form to hold everything:
   topform = XtVaCreateManagedWidget("topform", xmFormWidgetClass,
            shell,
            XmNbackground, appBgColor,
            NULL);

   // Create menubar and all its submenus:
   appMenubar = XmCreateMenuBar(topform,"menuBar",NULL,0);
   XtVaSetValues(appMenubar,
            XmNx, 0,
            XmNy, 0,
            XmNtopAttachment, XmATTACH_FORM,
            XmNbottomAttachment, XmATTACH_NONE,
            XmNleftAttachment, XmATTACH_FORM,
            XmNrightAttachment, XmATTACH_FORM,
            XmNbackground, appBgColor,
            XmNtopShadowColor, appTsColor,
            XmNbottomShadowColor, appBsColor,
            XmNshadowThickness, 1,
            XmNmarginWidth, 0,
            XmNmarginHeight, 0,
            NULL);
   Widget filepane = XmCreatePulldownMenu(appMenubar,"pane",NULL,0);
   XtVaSetValues(filepane,
            XmNbackground, appBgColor,
            XmNtopShadowColor, appTsColor,
            XmNbottomShadowColor, appBsColor,
            XmNshadowThickness, 1,
            XmNmarginWidth, 1,
            XmNmarginHeight, 1,
            NULL);
   XmString str = XmStringCreateSimple("File");
   Widget fileCascade = XtVaCreateManagedWidget("File",xmCascadeButtonWidgetClass,
            appMenubar,
            XmNsubMenuId, filepane,
            XmNlabelString, str,
            XmNmnemonic, XK_F,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   Widget fileNew = XtVaCreateManagedWidget("New",xmPushButtonGadgetClass,
            filepane,
            XmNmnemonic, XK_N,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(fileNew,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(fileNew,XmNdisarmCallback,appMenubarItemCb,0);
   Widget fileOpen = XtVaCreateManagedWidget("Open...",xmPushButtonGadgetClass,
            filepane,
            XmNmnemonic, XK_O,
            XmNacceleratorText, XmStringCreateSimple("F7"),
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(fileOpen,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(fileOpen,XmNdisarmCallback,appMenubarItemCb,0);
   Widget fileSave = XtVaCreateManagedWidget("Save...",xmPushButtonGadgetClass,
            filepane,
            XmNmnemonic, XK_S,
            XmNacceleratorText, XmStringCreateSimple("F2"),
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(fileSave,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(fileSave,XmNdisarmCallback,appMenubarItemCb,0);
   Widget fileSep1 = XtVaCreateManagedWidget("Sep1",xmSeparatorGadgetClass,
            filepane,
            XmNseparatorType, XmSINGLE_LINE,
            XmNbackground, appBgColor,
            XmNtopShadowColor, appTsColor,
            XmNbottomShadowColor, appBsColor,
            NULL);
   Widget fileExit = XtVaCreateManagedWidget("Exit",xmPushButtonGadgetClass,
            filepane,
            XmNmnemonic, XK_x,
            XmNaccelerator, "Alt<Key>X",
            XmNacceleratorText, XmStringCreateSimple("Alt+X"),
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(fileExit,XmNactivateCallback,appMenubarItemCb,0);
   XtAddCallback(fileExit,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(fileExit,XmNdisarmCallback,appMenubarItemCb,0);

   Widget editpane = XmCreatePulldownMenu(appMenubar,"pane",NULL,0);
   XtVaSetValues(editpane,
            XmNbackground, appBgColor,
            XmNtopShadowColor, appTsColor,
            XmNbottomShadowColor, appBsColor,
            XmNshadowThickness, 1,
            XmNmarginWidth, 1,
            XmNmarginHeight, 1,
            NULL);
   Widget editCascade = XtVaCreateManagedWidget("Edit",xmCascadeButtonWidgetClass,
            appMenubar,
            XmNsubMenuId, editpane,
            XmNlabelString, XmStringCreateSimple("Edit"),
            XmNmnemonic, XK_E,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   Widget editUndo = XtVaCreateManagedWidget("Undo",xmPushButtonGadgetClass,
            editpane,
            XmNmnemonic, XK_U,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(editUndo,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(editUndo,XmNdisarmCallback,appMenubarItemCb,0);
   Widget editRedo = XtVaCreateManagedWidget("Redo",xmPushButtonGadgetClass,
            editpane,
            XmNmnemonic, XK_R,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(editRedo,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(editRedo,XmNdisarmCallback,appMenubarItemCb,0);

   Widget helppane = XmCreatePulldownMenu(appMenubar,"pane",NULL,0);
   XtVaSetValues(helppane,
            XmNbackground, appBgColor,
            XmNtopShadowColor, appTsColor,
            XmNbottomShadowColor, appBsColor,
            XmNshadowThickness, 1,
            XmNmarginWidth, 1,
            XmNmarginHeight, 1,
            NULL);
   Widget helpCascade = XtVaCreateManagedWidget("Help",xmCascadeButtonWidgetClass,
            appMenubar,
            XmNsubMenuId, helppane,
            XmNlabelString, XmStringCreateSimple("Help"),
            XmNmnemonic, XK_H,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtVaSetValues(appMenubar,
            XmNmenuHelpWidget, helpCascade,
            NULL);
   Widget helpContents = XtVaCreateManagedWidget("Contents...",xmPushButtonGadgetClass,
            helppane,
            XmNmnemonic, XK_C,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(helpContents,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(helpContents,XmNdisarmCallback,appMenubarItemCb,0);
   Widget helpProgInfo = XtVaCreateManagedWidget("Program Information...",xmPushButtonGadgetClass,
            helppane,
            XmNmnemonic, XK_P,
            XmNbackground, appBgColor,
            XmNshadowThickness, 1,
            NULL);
   XtAddCallback(helpProgInfo,XmNarmCallback,appMenubarItemCb,0);
   XtAddCallback(helpProgInfo,XmNdisarmCallback,appMenubarItemCb,0);
   XtManageChild(appMenubar);

   // Create container to manage the editor control, the message line, and
   // the button panel.
   topDrawingArea = XtVaCreateManagedWidget("topDrawingArea", xmDrawingAreaWidgetClass,
            topform,
            XmNbackground, appBgColor,
            XmNtopAttachment, XmATTACH_WIDGET, XmNtopWidget, appMenubar,
            XmNbottomAttachment, XmATTACH_FORM,
            XmNleftAttachment, XmATTACH_FORM,
            XmNrightAttachment, XmATTACH_FORM,
            XmNmarginWidth, 0,
            XmNmarginHeight, 0,
            XmNresizePolicy, XmRESIZE_ANY,
            NULL);

   // Hook resize so that we can reposition and resize the buttons
   // control panel and the message/command line for Tiny.
   XtAddCallback(topDrawingArea,XmNresizeCallback,formResizeCb,0);

   // Hook the edit area's parent to monitor the creation of the
   // edit area. When the edit area is created, the editor control
   // is created.
   XtAddEventHandler(topDrawingArea, SubstructureNotifyMask,
                     False, formInputHandler, 0);

   // Create the parent widget containing the editor control:
   // Use the Label widget class.
   editArea = XtVaCreateManagedWidget("editArea",
            //xmLabelWidgetClass,
            xmTextWidgetClass,
            topDrawingArea,
            XmNx, 0,
            XmNy, 0,
            XmNwidth, 20,
            XmNheight, 20,
            XmNhighlightThickness, 2,
            XmNtraversalType, XmTAB_GROUP,
            XmNtraversalOn, True,
            XmNbackground, appBgColor,
            NULL);
   XtAddCallback(editArea, XmNfocusCallback, editorSetFocusCB, (XtPointer)0);
   XtAddCallback(editArea, XmNlosingFocusCallback, editorSetFocusCB, (XtPointer)0);

   // Create message line:
   messageLineArea = XtVaCreateManagedWidget("messageLineArea", xmFormWidgetClass,
            topDrawingArea,
            XmNx, 0,
            XmNy, 0,
            XmNwidth, 20,
            XmNheight, messageLineHeight,
            XmNbackground, appSeColor,
            XmNmarginWidth, 0,
            XmNmarginHeight, 0,
            NULL);
   messageLineCmd = XtVaCreateManagedWidget("messageLineCmd", xmTextFieldWidgetClass,
            messageLineArea,
            XmNx, tinyCmdX,
            XmNy, 2,
            XmNwidth, 300,
            XmNheight, commandLineHeight,
            XmNbackground, appBgColor,
            XmNmarginWidth, 2,
            XmNmarginHeight, 4,
            XmNhighlightThickness, 2,
            XmNshadowThickness, 1,
            XmNvalue, "",
            XmNmappedWhenManaged, True,
            NULL);
   XtAddCallback(messageLineCmd,XmNactivateCallback,messageLineCmdCb,0);
   controlPanelArea = XtVaCreateManagedWidget("controlPanelArea", xmFormWidgetClass,
            topDrawingArea,
            XmNx, 0,
            XmNy, 0,
            XmNwidth, controlAreaWidth,
            XmNheight, commandLineHeight,
            XmNbackground, appBgColor,
            XmNmarginWidth, 0,
            XmNmarginHeight, 0,
            NULL);
   int i;
   for (i=0; i<sizeof(buttonList)/sizeof(char *); i++) {
      Widget cpanelB = XtVaCreateManagedWidget(buttonList[i],xmPushButtonWidgetClass,
               controlPanelArea,
               XmNx, 10,
               XmNy, (24+4)*i + 4,
               XmNwidth, 80,
               XmNheight, 24,
               XmNmnemonic, XK_P,
               XmNbackground, appBgColor,
               XmNshadowThickness, 1,
               NULL);
      XtAddCallback(cpanelB, XmNactivateCallback,
                    buttonListProc[i], (XtPointer)i);
   }

   // Move the top drawing area's children into their proper position:
   formResizeCb(topDrawingArea, 0, 0);

   // Do the loop:
   while (1) {
      // Get the next X event:
      XEvent event;
      XtAppNextEvent(appContext, &event);

      //int eid = vsXWindowToEditorID(event.xany.window);
      //printf("main eid=%d\n",eid);

      // Got X event. Let the editor control take a look at it first.
      int continueToDispatch = vsXDispatchXEvent(&event);
      if (!continueToDispatch) continue;

      // The editor control did not process the X event. Let process it now.
      XtDispatchEvent(&event);
   }
   exit(0);
}
