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
/**
 * Starts a new set of undo steps and gives the set a
 * title that can be retrieved with _MFUndoGetTitle().  After
 * starting a new set of undo steps, you must call either
 * _MFUndoEnd() or _MFUndoCancel() to cancel.
 *
 * @param Title
 *                 Title for set of undo steps
 *
 */
extern void _MFUndoBegin(_str Title);
/**
 * Terminates the current set of undo steps.  Currently,
 * this function does nothing.
 *
 * @return Returns 0 if successful.
 */
extern int _MFUndoEnd();
/**
 * Adds a file that will be modified to the current undo set
 * of undo steps.  This generates undo information but no redo
 * information.  Redo information is generated when
 * _MFUndoEndStep() is called.  If you call this function and
 * specify the same file, nothing will happen and 0 is returned.
 *
 * @param Filename
 *               Name of file that will be modified.
 *
 * @return Returns 0 if successful.  Common returns codes are FILE_NOT_FOUND_RC
 *         and ACCESS_DENIED_RC.
 */
extern int _MFUndoBeginStep(_str Filename);
/**
 * Stores the redo information for the current step.  You must call this
 * function after calling _MFUndoBeginStep().
 *
 * @param Filename  Name of file to end step for.
 *
 * @return Returns 0 if successful.  Common returns codes are FILE_NOT_FOUND_RC
 *         and ACCESS_DENIED_RC.
 */
extern int _MFUndoEndStep(_str szFilename);
extern int _MFUndoCancelStep(_str pszFilename);
/**
 * Performs undo or redo for the current set of undo steps.  Files contents and date are restored.  To
 * add (push) another undo set, call the _MFUndoBegin() function.
 *
 * @param redo   A non-zero value specifies a redo operation.
 *
 * @return Returns 0 if successful.  If the undo fails, a non-zero
 *         status for the first error is returned.  You may query
 *         the individual undo steps to find out which files
 *         could not be restored.
 * @example <code>
 * <pre>
 *
 * boolean redo=false;
 * // IF we have an undo/redo set that can be executed
 * if (!_MFUndoGetStatus(redo)) {
 *    // Check if any of the files that will be restored
 *    // have been modified since a multi-file operation
 *    // occurred.
 *    int count=_MFUndoGetStepCount(redo);
 *    int i;
 *    for (i=0;i<count;++i) {
 *       _str filename=_MFUndoGetStepFilename(i,redo);
 *       _str CurFileDate;
 *       _MFUndoGetStepFileDate(i,redo,CurFileDate,true);
 *       if (CurFileDate!=_file_date(filename,'B')) {
 *          say(nls("Date mismatch.  File '%s1' may have been modified after this multi-file operation completed",filename));
 *       }
 *    }
 * }
 * int RedoCount=_MFUndoGetRedoCount();
 * int status=_MFUndo(redo);
 * // IF there was a file I/O error
 * if (status && RedoCount!=_MFUndoGetRedoCount()) {
 *    NewRedoCount=_MFUndoGetRedoCount();
 *    // Restore the current undo/redo set
 *    _MFUndoSetRedoCount(RedoCount);
 *    // List the files that failed.
 *    int count=_MFUndoGetStepCount(redo);
 *    int i;
 *    for (i=0;i<count;++i) {
 *       say(nls("undo failed for '%s1' status=%s2",
 *               _MFUndoGetStepFilename(i,redo),
 *               _MFUndoGetStepStatus(i,redo)));
 *    }
 *    // Go to next undo/redo set even though
 *    // this failed.  More complete code might
 *    // display a dialog which lists the files
 *    // that failed and give the user a chance to try again.
 *    _MFUndoSetRedoCount(NewRedoCount);
 *
 * }
 * </pre>
 * </code>
 */
extern int _MFUndo(boolean redo);
/**
 * Cursors to the next undo or redo set.  This function is typically called
 * when an error is returned from _MFUndo(). See {@link _MFUndo()}
 *
 * @param redo  Non-zero specifies next redo set (cursor to top of stack).
 *
 */
extern void _MFUndoNextSet(boolean redo);
/**
 * Undoes the current set undo steps and removes
 * the undo set from the stack.  This function calls
 * _MFUndo() and then pops the undo set.  Call this
 * function after calling _MFUndo() to abort a multi-file
 * operation and restore the files that have been modified.
 *
 * @return Returns 0 if successful.
 */
extern int _MFUndoCancel();
/**
 * Retrieves the number of steps in the current undo/redo set.
 *
 * @param redo   true specifies redo information.
 *
 * @return Returns the number of steps in the current undo/redo set.
 */
extern int _MFUndoGetStepCount(boolean redo);
/**
 * Retrieves the title of the current undo or redo set.
 *
 * @param redo   true specifies redo information.
 *
 * @return Returns title of the current undo or redo set.
 */
extern _str _MFUndoGetTitle(boolean redo);
/**
 * Retrieves the status for the current undo/redo set.  Call this function to determine the enable/disable
 * state for multi-file undo/redo.
 *
 * @param redo   true specifies redo information.
 *
 * @return Returns enabled/disable status for undo or redo.  0 indicates that undo or redo is available.
 */
extern int _MFUndoGetStatus(boolean redo);
/**
 * Retrieves an undo or redo step filename.
 *
 * @param i      Index of the step.
 * @param redo   true specifies redo information.
 *
 *
 * @return Returns the undo or redo step filename or 0.
 */
extern _str _MFUndoGetStepFilename(int i,boolean redo);
/**
 * Retrieves the backup filename for either undo or redo.  Use this function
 * to diff the contents of the original file with the new file.
 *
 * @param i      Index of the step.
 * @param redo   true specifies redo information.
 * @param CheckCurrent   true specifies retrieving the backup file which
 *                should contain the same contents as the current file.  This allows you to verify
 *                whether a file has been modified since the multi-file operation
 *                was performed or can be used to diff the before and after files.
 *
 * @return Returns the backup step filename or 0.
 */
extern _str _MFUndoGetStepBackup(int i,boolean redo,boolean CheckCurrent);
/**
 * Retrieves the step status for either undo or redo.  The status for a step
 * is set by _MFUndo() or _MFUndoCancel().  The status will always
 * be zero unless one of these functions returns an error.  Use this function
 * to query which files failed to be restored.
 *
 * @param i      Index of the step.
 * @param redo   true specifies redo information.
 *
 *
 * @return Returns the step status for the last _MFUndo() or
 * _MFUndoCancel().
 */
extern int _MFUndoGetStepStatus(int i,boolean redo);
/**
 * Retrieves a step date for either undo or redo.
 *
 * @param i         Index of the step.
 * @param redo      true specifies redo information.
 * @param FileDate Receives the date in binary string comparison form.
 * @param CheckCurrent   true specifies retrieving the date that
 *                the file should currently have.  This allows you to verify
 *                whether a file has been modified since the multi-file operation
 *                was performed.
 *
 */
extern void _MFUndoGetStepFileDate(int i,boolean redo,_str &FileDate,boolean CheckCurrent);
/**
 * Retrieves the number of redo steps left.  This value is
 * incremented on undo and decremented on redo.
 *
 * @return Returns the number of redo steps.
 * @see _MFUndoSetRedoCount
 */
extern int _MFUndoGetRedoCount();
/**
 * Sets the number of redo steps left.  This effects the current
 * undo or redo set.
 *
 * @param count  New value for the redo count
 *
 */
extern void _MFUndoSetRedoCount(int count);

