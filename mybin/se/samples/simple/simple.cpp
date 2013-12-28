/*
 * simple
 *
 ****************************************************************************
 * Windows:
 * This example can be compiled with Visual C++ 6.0 or Visual Studio .NET:
 *
 * BUILD
 * Use 'nmake' to build the makefile included:
 *   nmake
 *
 ****************************************************************************
 * UNIX:
 * This example can be compiled with the GNU C++ compiler.
 *
 * BUILD
 * Use 'make' or 'gmake' to build the makefile for your platform. For example:
 *   make -f Makefile.linux
 *
 ****************************************************************************
 * LOAD
 * Load this shared library by typing "dload simple" on the Visual SlickEdit
 * command line.
 *
 * TEST
 * To execute the dllcommand command, type "dllcommand" on the
 * Visual SlickEdit command line.  Try executing "dllcommand Line1 2" to
 * pass arguments to this command.  The dllcommand command can be
 * bound to a key. The only way to call dllproc, is to write a
 * Slick-C macro which calls it.
 *
 * UNLOAD
 * The dunload command can be used to unload a DLL (UNIX: shared library).
 * This deletes all registered functions/commands.  If your DLL is already
 * loaded, you will not be able to rebuild it until you unload it.
 */

#include <stdio.h>
#include <stdlib.h>
// vsapi.h includes system dependent files
#include <vsapi.h>
#include <rc.h>


EXTERN_C_BEGIN

/*
  vsdllinit is called from dllmain.obj which is typically linked in
  your DLL.
  This entry point gets called no matter how the
  dll gets loaded.
*/
void VSAPI vsDllInit()
{
   // dllcommand can be bound to a key because it is a command
   // When a string parameter is not given, a string of length 0 is passed.
   // When a numeric parameter is not given, 0 is passed.
   vsDllExport("_command void dllcommand(VSPSZ,seSeekPos)",
               VSARG_FILE,  // Indicate completion on file names for first argument
               VSARG2_NCW|VSARG2_ICON|VSARG2_READ_ONLY
                            // Indicate this command is allowed when
                            // there are no MDI child windows, when the
                            // active MDI child window is iconized, and
                            // when the current buffer is read only.
               );
   // dllproc is not a command. It can only be called from a Slick-C macro
   // function or command
   vsDllExport("VSPSZ dllproc()",0,0);
}

/*
   You must export your functions here instead 
   of vsDllInit if you have dll's which share
   each other's functions.
*/
void VSAPI vsDllRegisterExports()
{
}

/*
  vsDllExit is called when your dll is unloaded. This function must be
  defined even if it does nothing.
*/
void VSAPI vsDllExit()
{
}

void VSAPI dllcommand(VSPSZ pszLine1,seSeekPos LineNum)
{
   long status;

   // Current object/window is mdi child
   status=vsExecute(0,"edit junk","");
   if (status && status!=NEW_FILE_RC) {
      vsMessageBox("dllcommand: Error loading file",0,VSMB_OK);
      return;
   }
   if (status==NEW_FILE_RC) {
      // Delete the blank line in the new file created
      vsDeleteLine(0);
   }
   vsInsertLine(0,pszLine1,-1);
   vsInsertLine(0,"this is line 2",-1);
   vsInsertLine(0,"this is line 3",-1);
   // Set the current line to LineNum
   vsPropSetI64(0,VSP_LINE,LineNum);
}

VSPSZ VSAPI dllproc()
{
   return("result string from dllproc");
}

EXTERN_C_END

