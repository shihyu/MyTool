/**
 * To build the tinyGTK sample project you need GNU C++ (g++)
 * This sample was built with GNU g++ 3.2.
 * 
 * Building from the makefile:
 * 
 * 1. Run 'make -f tinyGTK.mak'
 * 
 * Building from SlickEdit:
 * 
 * 1. Open the "tinyGTK/tinyGTK.vpw" workspace file from within SlickEdit.
 * 
 * 2. Select "Build" from the "Build" menu. 
 * 
 * For information about running this samnple, see readme.txt
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

#define VSUSE_GTK
#include "vsapi.h"
#include <gtkvseditor.h>

#include <gdk/gdkx.h>
#include <gtk/gtk.h>

   static GtkWidget *gtoplevel_window;
   static GtkWidget *gvseditor;
   static GtkWidget *gmessage_line;

   static GtkWidget *gbutton1;
   static GtkWidget *gentry1;

static void button1_clicked(GtkWidget *widget, gpointer data) {
   printf("clicked data=<%s>\n",(char *)data);fflush(stdout);
   gtk_window_set_focus(GTK_WINDOW(gtoplevel_window),gvseditor);
}
static void VSAPI CallbackMessage(int wid,const char *pszMsg,int Immediate)
{
   if (!gmessage_line) {
      return;
   }
   gtk_label_set_label(GTK_LABEL(gmessage_line),(const gchar *)pszMsg);
}
void safecpy(char *dest_p,const char *src_p,int dest_size)
{
   int len;
   len=strlen(src_p);
   if (len>dest_size-1) {
      len=(dest_size>0)? dest_size-1 : 0;
   }
   if (len>0) {
      memcpy(dest_p,src_p,len);
   }
   dest_p[len]=0;
}
static void VSAPI CallbackGetMessage(int wid,char *pszMsg,int MaxMsgLen, int *pMaxMsgLen)
{
   if (!gmessage_line) {
      if (pszMsg) strcpy(pszMsg,"");
      if (pMaxMsgLen) *pMaxMsgLen=0;
      return;
   }
   if (pszMsg) {
      safecpy(pszMsg,
              (char *)gtk_label_get_label(GTK_LABEL(gmessage_line)),
              MaxMsgLen);
   }
   if (pMaxMsgLen) {
      *pMaxMsgLen=strlen((char *)gtk_label_get_label(GTK_LABEL(gmessage_line)));
   }
}

static gboolean delete_event( GtkWidget *widget,
                              GdkEvent  *event,
                              gpointer   data )
{
    /* If you return FALSE in the "delete_event" signal handler,
     * GTK will emit the "destroy" signal. Returning TRUE means
     * you don't want the window to be destroyed.
     * This is useful for popping up 'are you sure you want to quit?'
     * type dialogs. */

    //g_print ("delete event occurred\n");

    /* Change TRUE to FALSE and the main window will be destroyed with
     * a "delete_event". */

    //return TRUE;
    return FALSE;
}

/* Another callback */
static void destroy( GtkWidget *widget,
                     gpointer   data )
{
    gtk_main_quit ();
}

static void VSAPI CallbackAppExit()
{
   // Save the auto-restore information
   // Here we want dialog box retrieval, command retrieval,
   // and clipboards
   vsExecute(VSWID_MDI,"save_window_config");

   // Tell SlickEdit not to send events
   vsPrepareForTerminate();

   // Do your own application cleanup here.
   // ...

   // Free fonts, bitmaps, and all other graphics resources
   vsTerminate();

   // Exit the application
   exit(0);
}

static int bgetpathlen2(const char *filename,int filenamelen)
{
   int pathlen;
   for (pathlen=filenamelen-1; pathlen>=0 && filename[pathlen]!='/'; --pathlen);
   return(pathlen+1);
}

static int zgetpathlen(const char *filename_p)
{
   return(bgetpathlen2(filename_p,strlen(filename_p)));
}

static int fileExists(char *filename)
{
   struct stat statbuf;
   if (stat(filename,&statbuf)) return(0);
   return(1);
}

static void do_vsInit(const char * pszExecutableName, int argc, char ** argv)
{
   VSINIT init;
   memset(&init,0,sizeof(VSINIT));
   init.ApiVersion=VSAPIVERSION;
   char ExecutablePath[1024];

   strcpy(ExecutablePath,pszExecutableName);
   // You will get an error message about not finding the message file (slickedit.vsm)
   // if you do not get this path right, so make sure we can find the executable (vs)
   // first. It exists in slickedit/bin/ directory, so we need to make sure that
   // we will be able to find it when we do vsInit(). We give a relative path
   // to the executable directory, so the path we set is very sensitive to
   // what directory you start in.
   if (!fileExists(ExecutablePath) && strncmp(ExecutablePath,"../",3)==0 ) {
      // The current directory is probably tinyX11/, not tinyX11/Debug/.
      // Try 1 directory up
      char temp[1024];
      strcpy(temp,&(ExecutablePath[3]));
      strcpy(ExecutablePath,temp);
   } else {
      // You will probably get an error because we cannot find slickedit/vslick.vsm
   }
   int pathlen;
   // Strip the exe name
   pathlen=zgetpathlen(pszExecutableName);
   ExecutablePath[pathlen]=0;
   init.pszExecutablePath=ExecutablePath;
   //printf("pszExecutablePath=<%s>\n",ExecutablePath);fflush(stdout);

   init.hinstance=GDK_DISPLAY();

   /* 
      A global message handler is recommended for features which
      don't operate on the current editor control.
   */
   init.pfnMessage=CallbackMessage;
   init.pfnGetMessage=CallbackGetMessage;

   init.argc=argc-1;
   init.argv=argv+1;
   /*
       Single user with one configuration.

           set this to <OEMproduct>/slickedit

       Multiple users where each has their own configurations.


           set this to $HOME/.slickedit/<OEMproduct>/

       Here for simplicity we are specifying a single user
       configuration case: $HOME/.slickeditTiny/
   */

   char path[1024];
   char * envHome = getenv("HOME");
   if (!envHome) {
      init.pszConfigDir=0;
   } else {
      if (*envHome == '/' && *(envHome+1) == 0) {
         strcpy(path, "/.slickeditTiny");
      } else {
         sprintf(path, "%s/.slickeditTiny", envHome);
      }
      init.pszConfigDir=path;
      //printf("init.pszConfigDir=%s\n",init.pszConfigDir);fflush(stdout);
   }
   init.pszApplicationName="TinyGTK";
   init.ppEnv=(char **)0;
   init.APIFlags=VSAPIFLAG_UTF8_SUPPORT|VSAPIFLAG_UNICODE_MESSAGE_LOOP;


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
static void do_InitEditorCtl(int editorctl_wid)
{
   /*
      Since this sample is not an MDI application and does not set the MDI callbacks,
      we can get better message handling if we set the window specific message callbacks.

      SlickEdit DOES NOT use this callback because it is MDI application and
      sets the MDI callbacks.
   */
   vsCallbackSet(editorctl_wid,VSCALLBACK_WIN_MESSAGE,(void *)CallbackMessage);
   vsCallbackSet(editorctl_wid,VSCALLBACK_WIN_GET_MESSAGE,(void *)CallbackGetMessage);

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
   vsInsertLine(editorctl_wid,"    struct stat stinfo;");
   vsInsertLine(editorctl_wid,"    stinfo.st_size = 700;");
   vsInsertLine(editorctl_wid,"    exit(0);");
   vsInsertLine(editorctl_wid,"    return(0);");
   vsInsertLine(editorctl_wid,"}");
   vsPropSetI(editorctl_wid,VSP_UNDOSTEPS,old_undo_steps);
   vsPropSetI(editorctl_wid,VSP_ALLOWSAVE,1);
   // Allow source recording
   vsPropSetI(editorctl_wid,VSP_SOURCERECORDING,1);

   // Indicate that the user has not modified this buffer
   vsPropSetI(editorctl_wid,VSP_MODIFY,0);

}

int main( int   argc,
          char *argv[] )
{
    /* GtkWidget is the storage type for widgets */
    GtkWidget *toplevel_window;

    /* This is called in all GTK applications. Arguments are parsed
     * from the command line and are returned to the application. */
    gtk_init(&argc, &argv);
    //do_vsInit("../../../../slickedit/bin/vs", argc, argv);
    do_vsInit("/home/cmaurer/f/se64/slickedit/linux64_ctlgtk_dbg/tinyGTK", argc, argv);

    gtoplevel_window=toplevel_window=gtk_window_new(GTK_WINDOW_TOPLEVEL);

    GtkWidget *vbox=gtk_vbox_new(0,0);
    gtk_container_add(GTK_CONTAINER(toplevel_window), vbox);
    gtk_widget_show(vbox);

    g_signal_connect(G_OBJECT(toplevel_window), "delete_event",
		      G_CALLBACK(delete_event), NULL);

    g_signal_connect(G_OBJECT(toplevel_window), "destroy",
		      G_CALLBACK(destroy), NULL);

    /* Sets the border width of the window. */
    gtk_container_set_border_width(GTK_CONTAINER (toplevel_window), 10);

    /* 
       Load a file from disk.
       Since the IgnoreNotFound is 1, this buffer
       gets created even if junk.cpp is not found.
    */
    int buf_id;
    buf_id=vsBufEdit("junk.cpp");
    if (buf_id<0) {
       return(1);
    }
    GtkWidget *vseditor;
    gvseditor=vseditor = gtk_vseditor_new(0,300,200,buf_id);

    gtk_box_pack_start(GTK_BOX(vbox), vseditor,1,1,0);
    gtk_widget_show(vseditor);

    GtkWidget *separator;
    separator=gtk_hseparator_new();
    gtk_widget_show(separator);
    gtk_box_pack_start(GTK_BOX(vbox), separator,0,0,4);


    gmessage_line= gtk_label_new("");
    gtk_widget_show(gmessage_line);
    //gtk_widget_set_size_request(label,0,-1);
    //gtk_widget_set_size_request(label,0,-1);
	gtk_misc_set_alignment (GTK_MISC (gmessage_line), 0, 0);

    gtk_box_pack_start(GTK_BOX(vbox),gmessage_line,0,0,0);

    gbutton1= gtk_button_new_with_label("Button 1");
    gtk_widget_show(gbutton1);
    //gtk_widget_set_size_request(label,0,-1);
    //gtk_widget_set_size_request(label,0,-1);
	//gtk_misc_set_alignment (GTK_MISC (gbutton1), 0, 0);

    gtk_signal_connect(GTK_OBJECT(gbutton1),"clicked",
                       GTK_SIGNAL_FUNC(button1_clicked),(gpointer)"button 1");


    gtk_box_pack_start(GTK_BOX(vbox),gbutton1,0,0,0);


    gentry1= gtk_entry_new();
    gtk_widget_show(gentry1);
    //gtk_widget_set_size_request(label,0,-1);
    //gtk_widget_set_size_request(label,0,-1);
	//gtk_misc_set_alignment (GTK_MISC (gentry1), 0, 0);

    //gtk_signal_connect(GTK_OBJECT(gentry1),"clicked",GTK_SIGNAL_FUNC(entry1_clicked),(gpointer)"button 1");


    gtk_box_pack_start(GTK_BOX(vbox),gentry1,0,0,0);



    gtk_widget_show(toplevel_window);

    /*
       The wid is 0 until the GTK editor control becomes visible (is realized).  This
       occurs after the call to show the toplevel_window above.
    */
    do_InitEditorCtl(gtk_vseditor_get_wid(GTK_VSEDITOR(gvseditor)));



    gtk_main ();

    return 0;
}
