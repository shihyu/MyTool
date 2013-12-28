////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
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
#include "slick.sh"
#include "pipe.sh"
#endregion


/**
 * Read 1 line from pipe. A line ends in a newline (\n or \r\n).
 * If a whole line is not available, then data is left on pipe.
 * 
 * @param line   (output). Line read from pipe.
 * @param handle Input pipe handle.
 * 
 * @return 0 on success, <0 on error. See _PipeRead for common return
 * codes.
 * 
 * @see _PipeRead
 * @see _PipeCreate
 * @see _PipeIsReadable
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 */
int _PipeReadLine(_str& line, int hin)
{
   int status = 0;
   _str buf = "";

   line="";
   // Peek for a line
   status=_PipeRead(hin,buf,0,1);
   if( !status ) {
      if( buf!="" ) {
         int i = pos('\10',buf,1,'er');
         if( i>0 ) {
            // Read the line
            status=_PipeRead(hin,buf,i,0);
            if( !status ) {
               line=buf;
               line=strip(line,'T',"\n");
               line=strip(line,'T',"\r");
            }
         }
      }
   }

   return status;
}

/**
 * Execute cmdline and return output from stdout.
 * <p>
 * <b>IMPORTANT:</b>
 * If the process never exits, then you will have to
 * break the Slick-C&reg; macro (Ctrl+Alt+Shift+F2). 
 * <p>
 * Note: <br>
 * Only stdout is read. If the process only outputs on stderr,
 * you will get an empty string back.
 * 
 * @param cmdline Command line to execute.
 * @param status  Status/exit code of shelled process.
 * @param options (optional). Options are:
 *                'A' = Asynchronous (do not wait for execution
 *                to complete). 'C' = Execute in a
 *                console window. 'H' = Hide application window.
 *                Defaults to "".
 * 
 * @return _str output from stdout of shelled process.
 * 
 * @example _PipeShellResult("cd", status) returns
 * the current working directory as reported
 * by the operating system shell.
 */
_str _PipeShellResult(_str cmdline, int& status, _str options="")
{
   boolean async = ( 0 != pos('A',upcase(options),1,'e') );
   boolean console = ( 0 != pos('C',upcase(options),1,'e') );
   boolean hide = ( 0 != pos('H',upcase(options),1,'e') );

   int hin, hout, herr;
   _str opt = '';
   if( console ) {
      opt = opt'C';
   }
   if( hide ) {
      opt = opt'H';
   }
   int hprocess = _PipeProcess(cmdline,hin,hout,herr,opt);
   if( hprocess<0 ) {
      // Error
      status=hprocess;
      return "";
   }
   boolean exited = false;
   _str line = "";
   _str next = "";
   for(;;) {
      status=_PipeReadLine(line,hin);
      exited=_PipeIsProcessExited(hprocess)!=0;
      if( status<0 || line!="" || exited ) {
         break;
      }
      delay(1);
   }
   // Wait for process to exit before attempting to read any more
   while( !async && !exited ) {
      exited=_PipeIsProcessExited(hprocess);
      delay(1);
   }
   while( !async && status==0 ) {
      status=_PipeReadLine(next,hin);
      if (!status && next=="") {
         if( line != "" ) line :+= "\n";
         status=_PipeReadLine(next,hin);
      }
      if( !status ) {
         if( line != "" ) line :+= "\n";
         line :+= next;
      }
      if( next=="" && exited ) {
         break;
      }
      delay(1);
   }
   int exit_status = _PipeEndProcess(hprocess);;
   _PipeClose(hin);
   _PipeClose(hout);
   _PipeClose(herr);
   // Favor earlier errors over the exit code of the process
   if( !async && status==0 ) {
      status=exit_status;
   }
   return line;
}
