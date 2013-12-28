////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#include "os390.sh"
#import "listbox.e"
#import "main.e"
#import "sellist.e"
#import "stdprocs.e"
#import "treeview.e"
#endregion

/**
 * Generate a unique file name from a base file name.
 *
 * @param baseName base file name
 * @return unique file name
 */
static _str uniqueFilename(_str baseName, _str secondary="")
{
   // Generate the temp file name to hold the output.
   _str newName = "/tmp/":+baseName:+".jobutil.":+getpid();

   // For Linux/390, generate preset output files.
#if __TESTS390__
   // Create a temp view for the sample output.
   int temp_view_id, orig_view_id;
   orig_view_id = _create_temp_view(temp_view_id);
   p_buf_name = newName;
   delete_all();

   // Write the simulated output.
   if (baseName == "joboutput") {
      insert_line("      J E S 2  J O B  L O G  --  S Y S T E M  P 3 9 0  --  N O D E  N 1");
      insert_line("");
      insert_line("15.46.54 JOB00456 ---- FRIDAY,    14 APR 2000 ----");
      insert_line("15.46.54 JOB00456  IRR010I  USERID TAN      IS ASSIGNED TO THIS JOB.");
      insert_line("15.46.57 JOB00456  ICH70001I TAN      LAST ACCESS AT 15:46:53 ON FRIDAY, APRIL 14, 2000");
      insert_line("15.46.57 JOB00456  $HASP373 TANJOB   STARTED - INIT 3    - CLASS A - SYS P390");
      insert_line("15.46.57 JOB00456  IEF403I TANJOB - STARTED - TIME=15.46.57");
      insert_line("15.46.59 JOB00456  IEF404I TANJOB - ENDED - TIME=15.46.59");
      insert_line("15.46.59 JOB00456  $HASP395 TANJOB   ENDED");
      insert_line("------ JES2 JOB STATISTICS ------");
      insert_line("14 APR 2000 JOB EXECUTION DATE");
      insert_line("6 CARDS READ");
      insert_line("37 SYSOUT PRINT RECORDS");
      insert_line("0 SYSOUT PUNCH RECORDS");
      insert_line("2 SYSOUT SPOOL KBYTES");
      insert_line("0.03 MINUTES EXECUTION TIME");
      insert_line("1 //TANJOB    JOB  1,TAN,MSGCLASS=X                                       JOB00456");
      insert_line("2 //          EXEC  PGM=IEBGENER");
      insert_line("3 //SYSPRINT  DD   DUMMY");
      insert_line("4 //SYSIN     DD   DUMMY");
      insert_line("5 //SYSUT1    DD   DSN=TAN.VSLICK.MISC(TT1),DISP=SHR");
      insert_line("6 //SYSUT2    DD   DSN=TAN.VSLICK.MISC(TT2),DISP=OLD");
      insert_line("ICH70001I TAN      LAST ACCESS AT 15:46:53 ON FRIDAY, APRIL 14, 2000");
      insert_line("IEF236I ALLOC. FOR TANJOB");
      insert_line("IEF237I DMY  ALLOCATED TO SYSPRINT");
      insert_line("IEF237I DMY  ALLOCATED TO SYSIN");
      insert_line("IEF237I 0A87 ALLOCATED TO SYSUT1");
      insert_line("IEF237I 0A87 ALLOCATED TO SYSUT2");
      insert_line("IEF142I TANJOB - STEP WAS EXECUTED - COND CODE 0000");
      insert_line("IEF285I   TAN.VSLICK.MISC                              KEPT");
      insert_line("IEF285I   VOL SER NOS= TANMVS.");
      insert_line("IEF285I   TAN.VSLICK.MISC                              KEPT");
      insert_line("IEF285I   VOL SER NOS= TANMVS.");
      insert_line("IEF373I STEP/        /START 2000105.1546");
      insert_line("IEF374I STEP/        /STOP  2000105.1546 CPU    0MIN 00.22SEC SRB    0MIN 00.02SEC VIRT   216K SYS   296K EXT       4K SYS    9552K");
      insert_line("IEF375I  JOB/TANJOB  /START 2000105.1546");
      insert_line("IEF376I  JOB/TANJOB  /STOP  2000105.1546 CPU    0MIN 00.22SEC SRB    0MIN 00.02SEC");
   } else if (baseName == "jobddoutput") {
      if (secondary == "JESMSGLG") {
         insert_line("      J E S 2  J O B  L O G  --  S Y S T E M  P 3 9 0  --  N O D E  N 1");
         insert_line("");
         insert_line("15.46.54 JOB00456 ---- FRIDAY,    14 APR 2000 ----");
         insert_line("15.46.54 JOB00456  IRR010I  USERID TAN      IS ASSIGNED TO THIS JOB.");
         insert_line("15.46.57 JOB00456  ICH70001I TAN      LAST ACCESS AT 15:46:53 ON FRIDAY, APRIL 14, 2000");
         insert_line("15.46.57 JOB00456  $HASP373 TANJOB   STARTED - INIT 3    - CLASS A - SYS P390");
         insert_line("15.46.57 JOB00456  IEF403I TANJOB - STARTED - TIME=15.46.57");
         insert_line("15.46.59 JOB00456  IEF404I TANJOB - ENDED - TIME=15.46.59");
         insert_line("15.46.59 JOB00456  $HASP395 TANJOB   ENDED");
         insert_line("------ JES2 JOB STATISTICS ------");
         insert_line("14 APR 2000 JOB EXECUTION DATE");
         insert_line("6 CARDS READ");
         insert_line("37 SYSOUT PRINT RECORDS");
         insert_line("0 SYSOUT PUNCH RECORDS");
         insert_line("2 SYSOUT SPOOL KBYTES");
         insert_line("0.03 MINUTES EXECUTION TIME");
      } else if (secondary == "JESJCL") {
         insert_line("1 //TANJOB    JOB  1,TAN,MSGCLASS=X                                       JOB00456");
         insert_line("2 //          EXEC  PGM=IEBGENER");
         insert_line("3 //SYSPRINT  DD   DUMMY");
         insert_line("4 //SYSIN     DD   DUMMY");
         insert_line("5 //SYSUT1    DD   DSN=TAN.VSLICK.MISC(TT1),DISP=SHR");
         insert_line("6 //SYSUT2    DD   DSN=TAN.VSLICK.MISC(TT2),DISP=OLD");
      } else {
         insert_line("ICH70001I TAN      LAST ACCESS AT 15:46:53 ON FRIDAY, APRIL 14, 2000");
         insert_line("IEF236I ALLOC. FOR TANJOB");
         insert_line("IEF237I DMY  ALLOCATED TO SYSPRINT");
         insert_line("IEF237I DMY  ALLOCATED TO SYSIN");
         insert_line("IEF237I 0A87 ALLOCATED TO SYSUT1");
         insert_line("IEF237I 0A87 ALLOCATED TO SYSUT2");
         insert_line("IEF142I TANJOB - STEP WAS EXECUTED - COND CODE 0000");
         insert_line("IEF285I   TAN.VSLICK.MISC                              KEPT");
         insert_line("IEF285I   VOL SER NOS= TANMVS.");
         insert_line("IEF285I   TAN.VSLICK.MISC                              KEPT");
         insert_line("IEF285I   VOL SER NOS= TANMVS.");
         insert_line("IEF373I STEP/        /START 2000105.1546");
         insert_line("IEF374I STEP/        /STOP  2000105.1546 CPU    0MIN 00.22SEC SRB    0MIN 00.02SEC VIRT   216K SYS   296K EXT       4K SYS    9552K");
         insert_line("IEF375I  JOB/TANJOB  /START 2000105.1546");
         insert_line("IEF376I  JOB/TANJOB  /STOP  2000105.1546 CPU    0MIN 00.22SEC SRB    0MIN 00.02SEC");
      }
   } else if (baseName == "list") {
      if (secondary == "DA") {
         insert_line(" NP   JOBNAME  STEPNAME PROCSTEP JOBID    OWNER    C POS DP PGN REAL PAGING    SIO   CPU% ASID ASIDX  EXCP-CNT   CPU-TIME SR DMN STATUS SYSNAME  SPAG SCPU%  ECPU-TIME  ECPU%\0");
         insert_line("      TAN      STEP1             STC00391 TAN        IN  21   1 1267   0.00   0.00   0.00   50  0032     3,322      33.33      5 PROT   P390        0    89      33.33   0.00");
         insert_line("      TAN7     STEP1             STC00482 TAN        IN  20   1  691   0.00   0.00  64.08   52  0034       132       1.28      5 PROT   P390        0    89       1.28  64.08");
      } else if (secondary == "I") {
         insert_line(" NP   JOBNAME  JOBID    OWNER    PRTY C ODISP DEST                 TOT-REC  TOT-PAGE FORMS    FCB  STATUS           UCS  WTR      FLASH BURST PRMODE   RMT  NODE SECLABEL O-GRP-N  OGID1 OGID2 JP CRDATE     OHR OUTPUT-HOLD-TEXT                      DEVICE   SYSID MAX-RC ");
         insert_line("      TANJOB   JOB00456 TAN       144 X HOLD  LOCAL                     37           STD      ****                  ****          ****  NO    LINE             1          1            1     1  1 04/14/2000                                                          CC 0000");
      } else if (secondary == "O") {
         insert_line(" NP   JOBNAME  JOBID    OWNER    PRTY C ODISP DEST                 TOT-REC  TOT-PAGE FORMS    FCB  STATUS           UCS  WTR      FLASH BURST PRMODE   RMT  NODE SECLABEL O-GRP-N  OGID1 OGID2 JP CRDATE     OHR OUTPUT-HOLD-TEXT                      DEVICE   SYSID MAX-RC ");
         insert_line("      TANJOB   JOB00456 TAN       144 X HOLD  LOCAL                     37           STD      ****                  ****          ****  NO    LINE             1          1            1     1  1 04/14/2000                                                          CC 0000");
         insert_line("      TANJOB   JOB00460 TAN       144 X HOLD  LOCAL                     37           STD      ****                  ****          ****  NO    LINE             1          1            1     1  1 04/14/2000                                                          CC 0000");
      } else if (secondary == "H") {
         insert_line(" NP   JOBNAME  JOBID    OWNER    PRTY C ODISP DEST                 TOT-REC  TOT-PAGE FORMS    FCB  STATUS           UCS  WTR      FLASH BURST PRMODE   RMT  NODE SECLABEL O-GRP-N  OGID1 OGID2 JP CRDATE     OHR OUTPUT-HOLD-TEXT                      DEVICE   SYSID MAX-RC ");
         insert_line("      TANJOB   JOB00456 TAN       144 X HOLD  LOCAL                     37           STD      ****                  ****          ****  NO    LINE             1          1            1     1  1 04/14/2000                                                          CC 0000");
         insert_line("      TANJOB   JOB00458 TAN       144 X HOLD  LOCAL                     37           STD      ****                  ****          ****  NO    LINE             1          1            1     1  1 04/14/2000                                                          CC 0000");
      } else {
         insert_line(" NP   JOBNAME  JOBID    OWNER    PRTY QUEUE      C  POS  SAFF  ASYS STATUS            PRTDEST            SECLABEL TGNUM  TGPCT ORIGNODE EXECNODE DEVICE   MAX-RC     MODE\0");
         insert_line("      TANJOB   JOB00456 TAN         1 PRINT      A     9                              LOCAL                           1   0.26 LOCAL    LOCAL             CC 0000");
         insert_line("      TANJOB   JOB00458 TAN         1 PRINT      A    10                              LOCAL                           1   0.26 LOCAL    LOCAL             CC 0000");
         insert_line("      TAN      TSU00404 TAN         1 PRINT           11                              LOCAL                           1   0.26 LOCAL    LOCAL             ABEND S522");
         insert_line("      TAN      TSU00469 TAN         1 PRINT           12                              LOCAL                           1   0.26 LOCAL    LOCAL             ABEND S522");
      }
   } else if (baseName == "jobdds") {
      insert_line(" NP   DDNAME   STEPNAME PROCSTEP DSID OWNER    C DEST               REC-CNT PAGE-CNT BYTE-CNT CC RMT  NODE O-GRP-N  SECLABEL PRMODE   BURST CRDATE-CRTIME       FORMS    FCB  UCS  WTR      FLASH FLASHC SEGID DSNAME                                       CHARS                CPYMOD CPYMODFT PAGEDEF FOR");
      insert_line("      JESMSGLG JES2                 2 TAN      X LOCAL                   16               853  1         1 1                 LINE     NO    04/14/2000 15:46:53 STD      **** ****          ****     255       TAN.TANJOB.JOB00456.D0000002.JESMSGLG        ****,****,****,****  ****");
      insert_line("      JESJCL   JES2                 3 TAN      X LOCAL                    6               332  1         1 1                 LINE     NO    04/14/2000 15:46:53 STD      **** ****          ****     255       TAN.TANJOB.JOB00456.D0000003.JESJCL          ****,****,****,****  ****");
      insert_line("      JESYSMSG JES2                 4 TAN      X LOCAL                   15               804  1         1 1                 LINE     NO    04/14/2000 15:46:53 STD      **** ****          ****     255       TAN.TANJOB.JOB00456.D0000004.JESYSMSG        ****,****,****,****  ****");
   }

   // Save the file.
   _save_file('+o');
   p_window_id = orig_view_id;
   _delete_temp_view(temp_view_id);
#endif

   return(newName);
}

static int readList(_str filename, _str (&jobList)[])
{
   int status;
   jobList._makeempty();
   int temp_view_id, orig_view_id;
   status = _open_temp_view(filename, temp_view_id, orig_view_id);
   if (status) return(0); // empty list
   top(); up();
   _str line;
   int count = 0;
   while (1) {
      if (down()) break;
      get_line(line);
      jobList[count] = substr(line, 7);
      count++;
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Delete temp file.
   delete_file(filename);
   return(0);
}

/**
 * Get the output from a file and insert it into the specified editor control.
 *
 * @param filename  file to read
 * @param editorWid editor control
 * @return 0 OK, !0 error
 */
static int readOutput(_str filename, int editorWid)
{
   int status;
   editorWid.delete_all();
   int temp_view_id, orig_view_id;
   status = _open_temp_view(filename, temp_view_id, orig_view_id);
   if (status) return(0); // empty list
   top(); up();
   _str line;
   int count = 0;
   boolean origRO = editorWid.p_readonly_mode;
   editorWid.p_readonly_mode = false;
   while (1) {
      if (down()) break;
      get_line(line);
      editorWid.insert_line(line);
      count++;
   }
   editorWid.p_readonly_mode = origRO;
   editorWid.top();
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Delete temp file.
   delete_file(filename);
   return(0);
}

/**
 * Execute a command using the persistent shell pipe.
 *
 * @return 0 OK, !0 error
 */
static int execCmd(_str cmdArgs)
{
   int status = 0;
   _str pgm = get_env("VSLICKBIN1"):+"sdsfcmd.rexx";
   mou_hour_glass(1);
#if !__TESTS390__
   status = _os390ExecRexx(pgm, cmdArgs);
#endif
   mou_hour_glass(0);
   return(status);
}

//----------------------------------------------------------------------
defeventtab _jobutil_form;
/**
 * Read a job's DD output and show the output in the Output tab of the Output
 * Toolbar. Optionally show the content in a browse dialog.
 *
 * @return 0 OK, !0 error
 */
static int readAndShowDDOutput(_str jobname, _str jobid, _str owner, _str source, _str jobDDName, _str sourceText, boolean outputToTabOnly)
{
   typeless status=0;
   if (outputToTabOnly) {
      // Access the editor control in the Output tab of the Output toolbar.
      // Do nothing is Output toolbar is not visible.
      int editorTBWid = 0;
      int outputTB = _find_object('_tboutputwin_form','n');
      if (outputTB) editorTBWid = outputTB._find_control("ctloutput");
      if (!editorTBWid) return(0);

      // Get and display the output.
      _str cmd, tmpFile;
      if (jobDDName == "") {
         tmpFile = uniqueFilename("joboutput");
         cmd = "joboutput "jobname" "owner" "source" "jobid" "tmpFile;
      } else {
         tmpFile = uniqueFilename("jobddoutput", jobDDName);
         cmd = "jobddoutput "jobname" "owner" "source" "jobid" "jobDDName" "tmpFile;
      }
      status = execCmd(cmd);
      if (status) return(status);
      readOutput(tmpFile, editorTBWid);
      return(0);
   }

   // Show or update the browser plus output to tab.
   int browserForm = _find_object('_jobutilBrowse_form','n');
   if (browserForm) {
      status = browserForm.updateOutputBrowser(jobname, jobid, owner, source, jobDDName, sourceText);
      if (status) return(status);
   } else {
      show("-app -xy _jobutilBrowse_form", jobname, jobid, owner, source, jobDDName, sourceText);
   }
   return(0);
}

/**
 * Get and fill the job list.
 *
 * @param cmd
 * @param tmpFile
 * @param treeWid
 * @return
 */
static int fillJobList(_str cmd, _str tmpFile, int treeWid)
{
   // Get the job list into a temp file.
   int status = execCmd(cmd);
   if (status) return(status);

   // Read the job list.
   _str jobList[];
   status = readList(tmpFile, jobList);
   if (status) return(status);

   // Erase all lines in the job tree.
   int child = treeWid._TreeGetFirstChildIndex(0);
   while (child > 0) {
      int sibling = treeWid._TreeGetNextSiblingIndex(child);
      treeWid._TreeDelete(child);
      child = sibling;
   }

   // Fill the job list.
   int maxlen = 0;
   int i;
   for (i=0; i<jobList._length(); i++) {
      if (maxlen < length(jobList[i])) maxlen = length(jobList[i]);
   }
   _str sep = "==============================";
   while (length(sep) < maxlen) {
      sep = sep :+ sep;
   }
   sep = substr(sep, 1, maxlen);
   for (i=0; i<jobList._length(); i++) {
      if (i == 1) treeWid._TreeAddItem(0, sep, TREE_ADD_AS_CHILD,-1,-1,-1);
      if (i < 1) {
         treeWid._TreeAddItem(0, jobList[i], TREE_ADD_AS_CHILD,-1,-1,-1);
      } else {
         treeWid._TreeAddItem(0, jobList[i], TREE_ADD_AS_CHILD,_pic_job,_pic_job,0);
      }
   }
   return(0);
}

/**
 * Get and fill a job's DD list
 *
 * @param cmd
 * @param tmpFile
 * @param treeWid
 * @param jobi
 * @return
 */
static int fillDDList(_str cmd, _str tmpFile, int treeWid, int jobi)
{
   // Get the job list into a temp file.
   int status = execCmd(cmd);
   if (status) return(status);

   // Read the job list.
   _str jobList[];
   status = readList(tmpFile, jobList);
   if (status) return(status);
   if (!jobList._length()) return(0);

   // Fill the job list.
   int maxlen = 0;
   int i;
   for (i=0; i<jobList._length(); i++) {
      if (maxlen < length(jobList[i])) maxlen = length(jobList[i]);
   }
   _str sep = "==============================";
   while (length(sep) < maxlen) sep = sep :+ sep;
   sep = substr(sep, 1, maxlen);
   treeWid._TreeAddItem(jobi, sep, TREE_ADD_AS_CHILD,-1,-1,-1);
   for (i=0; i<jobList._length(); i++) {
      if (i == 1) treeWid._TreeAddItem(jobi, sep, TREE_ADD_AS_CHILD,-1,-1,-1);
      if (i < 1) {
         treeWid._TreeAddItem(jobi, jobList[i], TREE_ADD_AS_CHILD,-1,-1,-1);
      } else {
         treeWid._TreeAddItem(jobi, jobList[i], TREE_ADD_AS_CHILD,_pic_jobdd,_pic_jobdd,-1);
      }
   }
   sep = "------------------------------";
   while (length(sep) < maxlen) sep = sep :+ sep;
   sep = substr(sep, 1, maxlen);
   treeWid._TreeAddItem(jobi, sep, TREE_ADD_AS_CHILD,-1,-1,-1);
   return(0);
}

/**
 * Check to see if the selected line in the job list is on one
 * of the top lines that should not be selected.
 *
 * @param jobi   line index
 * @return Flag: 1 when a top line is selected, 0 not
 */
static boolean isInTopLines(int jobi)
{
   _str jobname="";
   _str jobid="";
   _str owner="";
   _str caption = ctlJobList._TreeGetCaption(jobi);
   if (caption == "") return(true);
   parse caption with jobname jobid owner .;
   if (jobname == "" || jobid == "" || owner == "") return(true);
   if (jobname == "JOBNAME" && jobid == "JOBID" && owner == "OWNER") return(true);
   if (jobname == "DDNAME" && jobid == "STEPNAME" && owner == "PROCSTEP") return(true);
   if (substr(caption,1,10) == "----------") return(true);
   return(false);
}

static void updateButtons()
{
   // Special case for nothing selected.
   int selCount = ctlJobList._TreeGetNumSelectedItems();
   if (!selCount) {
      ctlBrowse.p_enabled = false;
      ctlPurge.p_enabled = false;
      return;
   }

   // If selecting a job DD.
   int info;
   int jobi = ctlJobList._TreeGetNextSelectedIndex(1,info);
   if (ctlJobList._TreeGetDepth(jobi) > 1) {
      if (isInTopLines(jobi)) {
         ctlBrowse.p_enabled = false;
      } else {
         if (selCount > 1) {
            ctlBrowse.p_enabled = false;
         } else {
            ctlBrowse.p_enabled = true;
         }
      }
      ctlPurge.p_enabled = false;
      return;
   }

   // If selecting an invalid line.
   if (isInTopLines(jobi)) {
      ctlBrowse.p_enabled = false;
      ctlPurge.p_enabled = false;
      return;
   }

   // If line already has job DD expanded...
   ctlPurge.p_enabled = true;
   if (selCount > 1) {
      ctlBrowse.p_enabled = false;
   } else {
      ctlBrowse.p_enabled = true;
   }
}

/**
 * Update the job list
 *
 * @return 0 OK, !0 error
 */
static int updateJobList()
{
   // Get the prefix, owner, source.
   _str prefix, owner, source;
   prefix = upcase(ctlPrefix.p_text);
   if (prefix == "") prefix = "~";
   owner = upcase(ctlOwner.p_text);
   if (owner == "") owner = "~";
   parse upcase(ctlListType.p_text) with . '('source')';

   // Fill the list.
   _str tmpFile = uniqueFilename("list", source);
   _str cmd = "list "prefix" "owner" "source" "tmpFile;
   int status = fillJobList(cmd, tmpFile, ctlJobList.p_window_id);
   if (status) {
      _message_box(nls("Unable to get job listing.\nReason:\n\n"):+get_message(status));
   }
   return(status);
}

/**
 * Get the job DDs and add them to the job parent line.
 *
 * @param jobi   job line index
 */
static void fillJobDDs(int jobi)
{
   // Get and insert job DD list.
   // Get the jobname, jobid, and owner.
   _str jobname="";
   _str jobid="";
   _str owner="";
   if (jobi < 0) return;
   if (isInTopLines(jobi)) return;
   _str source="";
   parse ctlListType.p_text with . '('source')';
   _str caption = ctlJobList._TreeGetCaption(jobi);
   if (source == "DA") {
      // "JOBNAME  STEPNAME PROCSTEP JOBID    OWNER ..."
      // Can't use parse here because some field may be blank.
      jobname = strip(substr(caption,1,8));
      jobid = strip(substr(caption,28,8));
      owner = strip(substr(caption,37,8));
   } else {
      // "JOBNAME  JOBID    OWNER    PRTY ..."
      // Can't use parse here because some field may be blank.
      jobname = strip(substr(caption,1,8));
      jobid = strip(substr(caption,10,8));
      owner = strip(substr(caption,19,8));
   }
   if (jobname == "" || jobid == "" || owner == "") return;

   // Get the job DD list.
   int status;
   _str tmpFile = uniqueFilename("jobdds");
   _str cmd = "jobdds "jobname" "owner" "source" "jobid" "tmpFile;
   status = fillDDList(cmd, tmpFile, ctlJobList.p_window_id, jobi);
   if (status) {
      _message_box(nls("Unable to get job DDs listing.\nReason:\n\n"):+get_message(status));
   }
   ctlJobList._set_focus();

   // Update buttons.
   updateButtons();
}

void ctlClose.on_create()
{
   // Fill in the list types.
   int listWid = ctlListType.p_window_id;
   listWid._lbadd_item("Active Users (DA)");
   listWid._lbadd_item("Input Queue (I)");
   listWid._lbadd_item("Output Queue (O)");
   listWid._lbadd_item("Held Output Queue (H)");
   listWid._lbadd_item("Job Status (ST)");

   // For the first time, initialize the prefix and owner text.
   // For subsequent times, use the last values using dialog
   // retrieval.
   _str oldText;
   oldText = _retrieve_value("_jobutil_form.prefix");
   if (oldText == "") {
      _userName(oldText);
      oldText = oldText :+ "*";
   }
   ctlPrefix.p_text = oldText;
   oldText = _retrieve_value("_jobutil_form.owner");
   if (oldText == "") oldText = "*";
   ctlOwner.p_text = oldText;
   ctlOutputToTab._retrieve_value();

   // For the first time, set the queue type to ST. Otherwise,
   // reset to last type using dialog retrieval.
   oldText = _retrieve_value("_jobutil_form.listType");
   if (oldText == "") oldText = "Job Status (ST)";
   ctlListType.p_text = oldText;

   // Update buttons.
   updateButtons();
}

void ctlClose.lbutton_up()
{
   _append_retrieve(0, ctlListType.p_text, "_jobutil_form.listType");
   _append_retrieve(0, ctlPrefix.p_text, "_jobutil_form.prefix");
   _append_retrieve(0, ctlOwner.p_text, "_jobutil_form.owner");
   _append_retrieve(ctlOutputToTab, ctlOutputToTab.p_value);
   p_active_form._delete_window(1);
}

void ctlListType.on_change(int reason)
{
   updateJobList();
}

void ctlJobList.on_change(int reason, int jobi)
{
   if (reason == CHANGE_SELECTED) {
      updateButtons();
   } else if (reason == CHANGE_EXPANDED) {
      ctlJobList._TreeSelectLine(jobi, true);
      if (!ctlJobList._TreeGetNumChildren(jobi)) {
         fillJobDDs(jobi);
      }
      ctlJobList._TreeSetCurIndex(jobi);
   } else if (reason == CHANGE_COLLAPSED) {
      ctlJobList._TreeSelectLine(jobi, true);
      ctlJobList._TreeSetCurIndex(jobi);
   } else if (reason == CHANGE_LEAF_ENTER) {
      ctlBrowse.call_event(ctlBrowse,LBUTTON_UP,'W');
   }
}

void ctlBrowse.lbutton_up()
{
   // Determine browsing a job output or a job's DD output.
   int info;
   int jobi = ctlJobList._TreeGetNextSelectedIndex(1,info);
   if (jobi < 0) return;
   _str jobDDName = "";
   if (ctlJobList._TreeGetDepth(jobi) <= 1) {
      // Browse the job's output
      if (isInTopLines(jobi)) return;
   } else {
      // Browse a job's DD output.
      int jobddi = jobi;
      jobi = ctlJobList._TreeGetParentIndex(jobddi);
      _str ddcaption = ctlJobList._TreeGetCaption(jobddi);
      parse ddcaption with jobDDName .;
      if (jobDDName == "") return;
   }

   // Get the jobname, jobid, and owner.
   _str jobname="";
   _str jobid="";
   _str owner="";
   _str caption = ctlJobList._TreeGetCaption(jobi);
   parse caption with jobname jobid owner .;
   if (jobname == "" || jobid == "" || owner == "") return;

   // Get the source.
   _str source;
   parse ctlListType.p_text with . '('source')';

   // Show the output.
   int status = readAndShowDDOutput(jobname, jobid, owner, source, jobDDName
                                ,ctlListType.p_text
                                ,ctlOutputToTab.p_value?true:false);
   if (status) {
      _message_box(nls("Unable to get job output.\nReason:\n\n"):+get_message(status));
   }
   ctlJobList._set_focus();
}


void ctlPurge.lbutton_up()
{
   // If there is nothing selected, do nothing.
   selCount := ctlJobList._TreeGetNumSelectedItems();
   if (!selCount) return;

   // Build a list of jobs to be purged.
   _str jobname="";
   _str jobid="";
   _str owner="";
   int jobilist[];
   _str caption;
   _str jobList = "";
   int count = 0;
   jobilist._makeempty();
   int info;
   int jobi = ctlJobList._TreeGetNextSelectedIndex(1,info);
   while (jobi >= 0) {
      if (ctlJobList._TreeGetDepth(jobi) == 1) {
         caption = ctlJobList._TreeGetCaption(jobi);
         parse caption with jobname jobid owner .;
         if (jobList != "") jobList = jobList :+ "\n";
         jobList = jobList :+ "   " :+ jobname :+ "(":+jobid:+")";
         jobilist[count] = jobi;
         count++;
      }
      jobi = ctlJobList._TreeGetNextSelectedIndex(0,info);
   }

   // Get confirmation from user.
   int result = _message_box(nls("Purge the following job(s)?\n":+jobList), '', MB_YESNO);
   if (result != IDYES) return;

   // Loop and purge all selected jobs.
   _str source="";
   int purgedCount = 0;
   parse ctlListType.p_text with . '('source')';
   int i;
   for (i=0; i<jobilist._length(); i++) {
      // Get the jobname, jobid, and owner.
      jobi = jobilist[i];
      if (isInTopLines(jobi)) continue;
      caption = ctlJobList._TreeGetCaption(jobi);
      parse caption with jobname jobid owner .;
      if (jobname == "" || jobid == "" || owner == "") continue;

      // Purge job.
      int status;
      _str cmd = "purge "jobname" "owner" "source" "jobid;
      status = execCmd(cmd);
      if (status) {
         _message_box(nls("Unable to purge job.\nReason:\n\n"):+get_message(status));
         return;
      }
      purgedCount++;
   }

   // Loop thru again and delete the selected jobs.
   // Pick a next sibling after the last selected job. If a sibling is
   // not available, pick one previous.
   int siblingi = -1;
   for (i=0; i<jobilist._length(); i++) {
      jobi = jobilist[i];
      siblingi = ctlJobList._TreeGetNextSiblingIndex(jobi);
      if (siblingi < 0) siblingi = ctlJobList._TreeGetPrevSiblingIndex(jobi);
      ctlJobList._TreeDelete(jobi);
   }
   if (siblingi >= 0) {
      ctlJobList._TreeSelectLine(siblingi,true);
   }
   ctlJobList._set_focus();
   _str msgText = purgedCount :+ " jobs purged.";
   if (purgedCount < 2) {
      msgText = purgedCount :+ " job purged.";
   }
   message(msgText);

   // Update buttons.
   updateButtons();
}

void _jobutil_form.on_resize()
{
   // Move the buttons at the bottom.
   int gap = ctlListType.p_y;
   ctlClose.p_y = p_active_form.p_height - gap - ctlClose.p_height;
   ctlBrowse.p_y = ctlClose.p_y;
   ctlPurge.p_y = ctlClose.p_y;
   ctlRefresh.p_y = ctlClose.p_y;
   ctlOutputToTab.p_y = ctlClose.p_y + gap;

   // Size the job list.
   int newH = ctlClose.p_y - gap - ctlJobList.p_y;
   if (newH > _dy2ly(SM_TWIP,70)) {
      ctlJobList.p_height = newH;
   }
   int newW = p_active_form.p_width - gap - ctlJobList.p_x;
   if (newW > _dx2lx(SM_TWIP,350)) {
      ctlJobList.p_width = newW;
   }
}

void ctlRefresh.lbutton_up()
{
   updateJobList();
   ctlJobList._set_focus();
}

void ctlPrefix.'enter'()
{
   ctlRefresh.call_event(ctlRefresh,LBUTTON_UP,'W');
}

void ctlOwner.'enter'()
{
   ctlRefresh.call_event(ctlRefresh,LBUTTON_UP,'W');
}

void ctlJobList.'enter'()
{
   ctlBrowse.call_event(ctlBrowse,LBUTTON_UP,'W');
}


//----------------------------------------------------------------------
defeventtab _jobutilBrowse_form;
static int updateOutputBrowser(_str jobname, _str jobid, _str owner, _str source, _str jobDDName, _str sourceText)
{
   // Set the labels.
   ctlJobName.p_caption = jobname;
   ctlJobDDName.p_caption = jobDDName;
   ctlJobID.p_caption = jobid;
   ctlOwner.p_caption = owner;
   ctlSource.p_caption = sourceText;

   // Get the entire job output.
   _str cmd, tmpFile;
   if (jobDDName == "") {
      tmpFile = uniqueFilename("joboutput");
      cmd = "joboutput "jobname" "owner" "source" "jobid" "tmpFile;
   } else {
      tmpFile = uniqueFilename("jobddoutput", jobDDName);
      cmd = "jobddoutput "jobname" "owner" "source" "jobid" "jobDDName" "tmpFile;
   }
   int status = execCmd(cmd);
   if (status) return(status);

   // Access the editor controls.
   int browserWid = ctlOutput.p_window_id;
   int outputWid = 0;
   int outputTB = _find_object('_tboutputwin_form','n');
   if (outputTB) outputWid = outputTB._find_control("ctloutput");

   // Clear the old content.
   browserWid.delete_all();
   if (outputWid) outputWid.delete_all();

   // Read output and put it in the output window and the Output tab in the Output toolbar.
   int temp_view_id, orig_view_id;
   status = _open_temp_view(tmpFile, temp_view_id, orig_view_id);
   if (status) return(status);
   top(); up();
   _str line;
   int count = 0;
   boolean origBrowserRO = browserWid.p_readonly_mode;
   browserWid.p_readonly_mode = false;
   boolean origOutputRO;
   if (outputWid) {
      origOutputRO = outputWid.p_readonly_mode;
      outputWid.p_readonly_mode = false;
   }
   while (1) {
      if (down()) break;
      get_line(line);
      browserWid.insert_line(line);
      if (outputWid) outputWid.insert_line(line);
      count++;
   }
   browserWid.p_readonly_mode = origBrowserRO;
   browserWid.top();
   if (outputWid) {
      outputWid.p_readonly_mode = origOutputRO;
      outputWid.top();
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);

   // Internals.
   ctlOutput.p_readonly_mode = true;
   return(0);
}

void ctlClose.on_create(_str jobname, _str jobid, _str owner, _str source, _str jobDDName, _str sourceText)
{
   int status;
   status = updateOutputBrowser(jobname, jobid, owner, source, jobDDName, sourceText);
   if (status) {
      _message_box(nls("Unable to get job output.\nReason:\n\n"):+get_message(status));
   }
}

void _jobutilBrowse_form.on_resize()
{
   int gap = ctlOutput.p_x;
   int newW = p_active_form.p_width - 2 * gap;
   if (newW > _dx2lx(SM_TWIP,400)) ctlOutput.p_width = newW;
   int newH = p_active_form.p_height - gap - ctlOutput.p_y;
   if (newH > _dy2ly(SM_TWIP,150)) ctlOutput.p_height = newH;
   ctlClose.p_x = p_active_form.p_width - gap - ctlClose.p_width;
   _set_zorder(ctlClose.p_window_id);
}
_command listjobs,listjob() name_info(FILE_ARG'*,'VSARG2_REQUIRES_MDI)
{
   show("-app -xy _jobutil_form");
}
