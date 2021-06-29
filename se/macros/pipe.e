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
   status := 0;
   buf := "";

   line="";
   // Peek for a line
   status=_PipeRead(hin,buf,0,1);
   if( !status ) {
      if( buf!="" ) {
         i := pos('\10',buf,1,'er');
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
   async := ( 0 != pos('A',upcase(options),1,'e') );
   console := ( 0 != pos('C',upcase(options),1,'e') );
   hide := ( 0 != pos('H',upcase(options),1,'e') );

   int hin, hout, herr;
   opt := "";
   if( console ) {
      opt :+= 'C';
   }
   if( hide ) {
      opt :+= 'H';
   }
   int hprocess = _PipeProcess(cmdline,hin,hout,herr,opt);
   if( hprocess<0 ) {
      // Error
      status=hprocess;
      return "";
   }
   exited := false;
   line := "";
   next := "";
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
      exited=_PipeIsProcessExited(hprocess) != 0;
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

// Handles input and output for a piped command.  Meant to be called
// periodically in a loop.  When the loop should end, 'st.finished' will be
// set to true, with the 'st.result' being the final return code from the loop,
// <0 for failure.
void exec_handle_pipes(ExecState& st)
{
   if (st.finished) return;

   // Avoid pulling in dependencies for the progress bar.
   progress_increment_x := find_index('progress_increment', PROC_TYPE);
   progress_get_x := find_index('progress_get', PROC_TYPE);
   progress_set_x := find_index('progress_set', PROC_TYPE);

   bool ticked = true;
   for (;;) {
      // Update progress bar if one is passed in.
      if (!st.readProgresFromStdout && ticked && st.progress != -1 && st.progCount > 0) {
         st.progN -= 1;
         if (st.progN <= 0) {
            st.progCount -= 1;
            st.progStep += 2;  // Geometric backoff, since we don't know exactly how long the op will take.
            st.progN = st.progStep;
            if (progress_increment_x > 0) {
               call_index(st.progress, progress_increment_x);
            }
            refresh('W');
         }
         ticked = false;
      }

      cancel := false;
      process_events(cancel, 'T');
      if (cancel) {
         st.finished = true;
         st.result = COMMAND_CANCELLED_RC;
         break;
      }

      st.buf = '';
      if (_PipeIsReadable(st.procStderr)) {
         _PipeRead(st.procStderr, st.buf, 128, 0);
         st.outWindow._insert_text(st.buf);
         if (st.auxOutWindow >= 0) {
            st.auxOutWindow._insert_text(st.buf);
         }
         // We try to bunch up stderr output if possible, 
         // rather than have it mix in with stdout output.
         ticked = true;
         continue;
      }

      st.buf = '';
      if (_PipeIsReadable(st.procStdout)) {
         _PipeRead(st.procStdout, st.buf, 128, 0);
         st.outWindow._insert_text(st.buf);
         if (st.auxOutWindow >= 0) {
            st.auxOutWindow._insert_text(st.buf);
         }

         // If there's a recognizable progress message, recaption with it.
         // And use the percentage completion in the output, if we're allowed to.
         if (st.progress != -1) {
            rc := pos('([0-9]+)% (.*$)', st.buf, 1, 'L');
            if (rc > 0 && progress_get_x > 0 && progress_set_x > 0) {
               prog := substr(st.buf, pos('S1'), pos('1'));
               if (isinteger(prog)) {
                  pc := (int)prog;
                  if (pc > call_index(st.progress, progress_get_x)) {
                     call_index(st.progress, pc, progress_set_x);

                     title := substr(st.buf, pos('S2'), pos('2'));
                     if (title != '') {
                        st.progress.p_caption = title;
                     }
                  }
               }
            }
         }

         ticked = true;
         continue;
      }

      ppe := _PipeIsProcessExited(st.procHand);
      if (ppe < 0) {
         st.finished = true;
         st.result = ppe;
         break;
      }

      if (ppe) {
         st.finished = true;
         st.result = 0;
         break;
      }

      break;
   }
}

// Executes `cmdline`, directing stdout and sterr to `outWindow`.  (and `auxOutWindow` if specified).
// Returns <0 if not able to execuate the command for some reason.  Once `es` is initialized
// with the running program's information, exec_handle_pipes() can be called with it to process the 
// intput and output until `st.finished` is set to true to indicate that the program has finished.
//
// Once a command has finished, you have to call `exec_cleanup_piped_command(es)` to clean up any 
// OS handles used for the pipe.
int exec_piped_command(ExecState& st, _str cmdline, int outWindow, int auxOutWindow = -1, CTL_FORM progress = -1, int progCount = 0, bool useOutputProgress = false)
{
   st.outWindow = outWindow;
   st.auxOutWindow = auxOutWindow;
   st.progress = progress;
   st.progCount = progCount;
   st.curWin = p_window_id;
   st.finished = false;
   st.progStep = 10;
   st.progN = st.progStep;
   st.procStdin = -1;
   st.procStdout = -1;
   st.procStderr = -1;
   st.procHand = -1;
   st.readProgresFromStdout = useOutputProgress;

   if (auxOutWindow != -1) {
      auxOutWindow._insert_text("\nEXEC "cmdline"\n");
   } 
   rv := 0;
   st.procHand = _PipeProcess(cmdline, st.procStdout, st.procStdin, st.procStderr, '');
   if (st.procHand < 0) {
      st.finished = true;
      st.result = st.procHand;
      rv = st.procHand;
   }

   return rv;
}

// Should be called once ExecState::finished is true for a process created by
// exec_piped_command().
void exec_cleanup_piped_command(ExecState& st)
{
   if (st.procHand != -1) {
      _PipeCloseProcess(st.procHand);
      st.procHand = -1;
   }

   // Restore the initial view, in case it was change by a timer.
   p_window_id = st.curWin;
}

// Executes ``cmdline`` synchronously, directing stdout and
// stderr to ``outWindow``.
int exec_command_to_window(_str cmdline, int outWindow, int auxOutWindow = -1, CTL_FORM progress = -1, 
                           int progCount = 0)
{
   ExecState st;

   rv := exec_piped_command(st, cmdline, outWindow, auxOutWindow, progress, progCount);
   if (rv < 0) {
      return rv;
   }

   while (!st.finished) {
      delay(1);
      exec_handle_pipes(st);
   }
   exec_cleanup_piped_command(st);
   return st.result;
}
