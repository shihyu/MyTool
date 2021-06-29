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
#pragma option(metadata,"pipe.e")

/**
 * State for a pipe that's used to process a command over 
 * several calls, possibly while interleaving other work. 
 * 
 * @see exec_command_to_window, exec_piped_command, 
 *      exec_cleanup_piped_command, exec_handle_pipes.
 */
struct ExecState
{
   // Exec parameters that need to be persisted between calls.
   int outWindow; 
   int auxOutWindow;
   CTL_FORM progress;
   int progCount;
   int curWin; // View id active when exec function is called.
   int procStdin;
   int procStdout;
   int procStderr;
   int procHand; // Handle from PipeProcess.
   bool readProgresFromStdout;  // Parse progress % from stdout.

   // "locals" of the handler loop for the piped process.
   int progStep;
   int progN;
   _str buf;

   // Final results.
   bool finished;  // True when the program has finished executing (or never started due to an error).
   int result;  // Result code for the program execution.
};


/**
 * Read data from pipe and store in editor variable.
 *
 * <p>
 * Note:<br>
 * When iStopLen>0, it is possible to read less than iStopLen. When this
 * happens it simply means that there was less than iStopLen of data
 * available on the pipe at the time of the read.
 * </p>
 *
 * @param handle   Handle to open pipe.
 * @param hvarBuf  Editor buffer variable to accept read data.
 * @param iStopLen Number of bytes at which to stop reading.
 * @param Peek     Non-zero=Do not remove the data from the pipe.
 *
 * @return 0 on success. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 */
extern int _PipeRead(int handle,_str &hvarBuf,int iStopLen,int Peek);

/**
 * Determine if there is data to read on an open pipe.
 *
 * @param handle  Handle to open pipe.
 *
 * @return 1 (true) if there is data to read, 0 if not data to read, &lt;0 on error.
 * @see _PipeIsWriteable
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 */
extern int _PipeIsReadable(int handle);

/**
 * Write ascii-z string to pipe.
 *
 * <p>
 * Note:<br>
 * The number of bytes written could be less than the length of
 * the string in the case of the pipe being full. If this occurs,
 * then the caller should try to write the rest of the string later.
 * </p>
 *
 * @param handle  Handle to open pipe.
 * @param buf     String.
 *
 * @return Number of bytes written on success. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeIsWriteable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeProcess
 */
extern int _PipeWrite(int handle,_str buf);

/**
 * Determine if a pipe can be written to.
 *
 * @param handle  Handle to open pipe.
 *
 * @return 1 (true) if the pipe is writeable, 0 if not writeable, &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 */
extern int _PipeIsWriteable(int handle);

/**
 * Close pipe.
 *
 * @param handle     Handle of pipe to close.
 *
 * @return 0 on success. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 */
extern int _PipeClose(int handle);

/**
 * Run a program and pipe stdin, stdout, and stderr.
 *
 * @param cmdline Program to run. This includes all switches and
 *                options that would normally be passed to program.
 * @param hvarIn  Set on return. Handle to input pipe (stdout of process).
 * @param hvarOut Set on return. Handle to output pipe (stdin of process).
 * @param hvarErr Set on return. Handle to error pipe (stderr of process).
 * @param options String of one or more options:
 *                <ul>
 *                <li>'C' - (Windows) Create a console for the spawned program.</li> 
 *                <li>'H' - (Windows) Show program hidden. Useful for console
 *                          applications that should be "heard but not seen."</li>
 *                <li>'H' - (Unix) Show program hidden and create new process group.</li>
 *                </ul>
 *
 * <p>
 * Use {@link _PipeRead} to read from the process'
 * stdout and stderr. Use {@link _PipeWrite} to write to stdin.
 * </p>
 *
 * @return Handle to process. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeWrite
 * @see _PipeGetProcessHandles
 * @see _PipeCloseProcess
 * @see _PipeTerminateProcess
 */
extern int _PipeProcess(_str pszCmdline,int &hvarIn,int &hvarOut,int &hvarErr,_str options);

/**
 * Get stdin, stdout, stderr handles for process represented by handle.
 * Use these handles to read from and write to a process.
 *
 * @param handle  Handle to running process.
 * @param hvarIn  Set on return. Handle to input pipe (stdout of process).
 * @param hvarOut Set on return. Handle to output pipe (stdin of process).
 * @param hvarErr Set on return. Handle to error pipe (stderr of process).
 *
 * @return 0 on success. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeWrite
 * @see _PipeCloseProcess
 * @see _PipeProcess
 * @see _PipeTerminateProcess
 */
extern int _PipeGetProcessHandles(int handle,int &hvarIn,int &hvarOut,int &hvarErr);

/**
 * End the process represented by handle. All pipes connected to the
 * process are left open. This is useful if there is still data to
 * read from the input or err pipes. Be sure to close the pipes with
 * _PipeClose.
 *
 * <p>
 * Use _PipeCloseProcess to end the process and close the pipes
 * connected to the process. Use _PipeGetProcessHandles to get
 * the input, output, and err pipes connected to the process <b>before</b>
 * calling this function.
 * </p>
 *
 * @param handle Handle to process.
 * @return Exit code of process. &lt;0 on internal error.
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeWrite
 * @see _PipeGetProcessHandles
 * @see _PipeProcess
 * @see _PipeCloseProcess
 * @see _PipeTerminateProcess
 */
extern int _PipeEndProcess(int handle);

/**
 * Close the process represented by handle, and close all open pipes
 * connected to process.
 *
 * <p>
 * Use _PipeEndProcess to end the process without closing the pipes
 * connected to the process.
 * </p>
 *
 * @param handle Handle to process.
 * @return 0 on success. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeWrite
 * @see _PipeGetProcessHandles
 * @see _PipeProcess
 * @see _PipeEndProcess
 * @see _PipeTerminateProcess
 */
extern int _PipeCloseProcess(int handle);

/**
 * Determine if a a process has exited.
 *
 * @param handle  Handle to open process.
 *
 * @return 1 (true) if the process is exited, 0 if not exited. &lt;0 on error.
 * @see _PipeIsReadable
 * @see _PipeWrite
 * @see _PipeClose
 * @see _PipeProcess
 * @see _PipeTerminateProcess
 */
extern int _PipeIsProcessExited(int handle);

/**
 * Attempt to terminate a process with prejudice. Use _PipeEndProcess to
 * get the return code of the process.
 *
 * <p>
 * IMPORTANT:<br>
 * You must still call _PipeEndProcess to close the process handle.
 * </p>
 *
 * <p>
 * Note:<br>
 * This may not work for processes that the user does not have
 * permission to terminate.
 * </p>
 *
 * @param handle Handle to process.
 *
 * @see _PipeIsReadable
 * @see _PipeRead
 * @see _PipeClose
 * @see _PipeWrite
 * @see _PipeGetProcessHandles
 * @see _PipeProcess
 * @see _PipeCloseProcess
 * @see _PipeEndProcess
 */
extern void _PipeTerminateProcess(int handle);

/**
 * Get process id (pid) from handle to process.
 *
 * @param handle Handle to running process.
 *
 * @return Process id. 0 if process not found.
 */
extern int _PipeGetProcessPid(int handle);

/**
 * Read data from pipe and store in an internal "blob". The blob
 * read position starts at current blob offset. Use _BlobSetOffset
 * to set a different offset from the beginning of the blob at which
 * to start reading. The blob offset is advanced by the number of bytes
 * read.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param hblob Handle to blob returned by _BlobAlloc.
 * @param hpipe Handle to open pipe.
 * @param iLen  Number of bytes to read into blob.
 * @param Peek  Non-zero=Do not remove the data from the pipe.
 *
 * @return Number of bytes read into blob on success. &lt;0 on error.
 */
extern int _PipeReadToBlob(int hblob,int hpipe,int iLen,int Peek);

/**
 * Write data from internal "blob" to pipe. Writing starts from the
 * current blob offset. The current blob offset is not changed.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param hblob Handle to blob returned by _BlobAlloc.
 * @param hpipe Handle to open pipe.
 * @param iLen  Number of bytes to write from blob.
 *
 * @return Number of bytes written from blob on success. &lt;0 on error.
 */
extern int _PipeWriteFromBlob(int hblob,int hpipe,int iLen);

