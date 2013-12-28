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
#import "clipbd.e"
#import "eclipse.e"
#import "files.e"
#import "ini.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "stdprocs.e"
#import "util.e"
#endregion

/*
  Fix COBOL diff tab and backspace keys
  Define popup callback for menu messages
  Define form callback for menu messages
*/

#define DS_FILECOUNTWARNING 20
#define DS_FILESOPENEDWARNING 100

static _str gbuttonlist[]={
   "ctlback"
   ,"ctlopen"
   ,"ctlbrowse"
   ,"ctlallocate"
   ,"ctlcopy"
   ,"ctldelete"
   ,"ctlrename"
   ,"ctlsubmit"
};
static _str gbuttonlist2[]={
   "ctlcompress"
   ,"ctlcatalog"
   ,"ctluncatalog"
   ,"ctlfree"
   ,"ctlinfo"
   ,"ctlRefresh"
   ,"ctlRegister"
};

//#define GOBACK "<<back"
#define FLSTATE_EMPTYLIST  0
#define FLSTATE_PDS        1
#define FLSTATE_SDS_OR_MEMBER 2
//#define FLSTATE_GOBACK     3
#define FLSTATE  get_flstate()

struct COMBOUSERDATA
{
   //_str name_part;
   _str last_data;
};

struct DSINFO
{
   boolean isDS;
   _str name;
   _str volser;
   _str dsorg;
   _str recfm;
   int reclen;
   int blkSize;
};


//---------------------------------------------------------------
/**
 * Get the current job statement defined by the user.
 *
 * @param line   returning 4 lines of the job statement
 * @return Flag: true if statement previously defined, false if statement not defined
 */
boolean dsuGetJobStatement(_str (&line)[])
{
   _str inifile = _ConfigPath() :+ _INI_FILE;
   boolean statementDefined = false;
   if (file_exists(inifile)) {
      int viewid;
      int orig_view_id = p_window_id;
      int status = _ini_get_section(inifile, "JobStatement", viewid);
      if (!status) {
         p_window_id = viewid;
         top();
         get_line(line[0]);
         down();
         get_line(line[1]);
         down();
         get_line(line[2]);
         down();
         get_line(line[3]);
         statementDefined = true;
         _delete_temp_view(viewid);
      }
      p_window_id = orig_view_id;
   }

   // Use a vanilla statement.
   if (!statementDefined) {
      line[0] = "//USERID   JOB  (ACCOUNT),'NAME',MSGCLASS=X";
      line[1] = "//*";
      line[2] = "//*";
      line[3] = "//*";
   }
   return(statementDefined);
}

/**
 * Get the data set statistics.
 *
 * @param dsname    data set name
 * @param isFixed   returning flag: 1 for fixed-length record
 * @param isPDS     returning flag: 1 if data set is PDS
 * @param isBlocked returning flag: 1 for blocked-records
 * @param reclen    returning record length
 * @param blkSize   returning block size
 * @return 0 OK, !0 error code
 */
int dsuGetDSInfo(_str dsname
                 ,boolean & isFixed
                 ,boolean & isPDS
                 ,boolean & isBlocked
                 ,boolean & isUndef
                 ,int & reclen
                 ,int & blkSize
                 )
{
   // Get data set info.
   _str infoText;
   _str volser, devtype, dsorg, recfm, reclenText, blkSizeText;
   isPDS = false;
   isFixed = false;
   isBlocked = false;
   isUndef = true;
   reclen = 0;
   blkSize = 0;
   int status = _os390DSInfo2(dsname, infoText);
   if (status) return(status);
   if (pos(",,,,,", infoText) == 1) return(FILE_NOT_FOUND_RC);

   // Parse data set info.
   // volser,devtype,dsorg,recfm,reclen,blksize,1st_extent,secondary_alloc,allocted,allocated_extent,dir_block,used,used_extents,used_dir_blocks,member_count,creation_date,reference_date,expiration_date
   //say(infoText);
   parse infoText with volser","devtype","dsorg","recfm","reclenText","blkSizeText",".;
   if (pos("PO", dsorg) == 1) isPDS = true;
   if (pos("F", recfm)) {
      isFixed = true;
      isUndef = false;
   } else if (pos("V", recfm)) {
      isFixed = false;
      isUndef = false;
   }
   if (pos("B", recfm)) isBlocked = true;
   if (reclenText != "") reclen = (int)reclenText;
   if (blkSizeText != "") blkSize = (int)blkSizeText;
   return(0);
}

/**
 * Copy one data set. Both the source and the destination data sets
 * must already allocated.
 *
 * @param sourceDS source data set or PDS member
 * @param destDS   dest data set or PDS member
 * @return 0 OK, !0 error code
 */
int dsuCopyOneDS(_str sourceDS, _str destDS)
{
   int temp_view, orig_view;
   int status = _open_temp_view(sourceDS, temp_view, orig_view);
   if (status) {
      _message_box(nls("Can't read source data set %s.\nReason: %s",sourceDS,get_message(status)));
      return(status);
   }
   p_buf_name = destDS;
   status = _save_file('+o');
   if (status) {
      activate_window(orig_view);
      _delete_temp_view(temp_view);
      _message_box(nls("Can't write destination data set %s.\nReason: %s",destDS,get_message(status)));
      return(status);
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   return(0);
}

/**
 * Copy the source data set or PDS member to the specified data set or PDS member. The
 * following combination are allowed:
 *
 * Case 1: PS to PS
 * Case 2: PS to PDS member
 * Case 3: PDS member to PS
 * Case 4: PDS member to PDS member
 * Case 5: PDS to PDS
 *
 * @param sourceDS source data set
 * @param destDS   destination data set
 * @param volser   volume serial
 * @param allocIfNeeded
 *                 Flag: 1 to allocate the data set if needed
 * @param checkForDestBeingPS
 *                 Flag: 1 to check for destination data set already exist and is a sequential data set
 * @return 0 OK, !0 error code
 */
int dsuCopyDS(_str sourceDS, _str destDS, _str volser,
              boolean allocIfNeeded, boolean checkForDestBeingPS)
{
   // Sanity check for source and destination being the same.
   if (sourceDS == destDS) {
      _message_box(nls("Source and destination data set '%s' are the same.",sourceDS));
      return(UNSUPPORTED_DATASET_OPERATION_RC);
   }

   // Separate the data set names from the member names.
   //say("copyDS '"sourceDS"' to '"destDS"'");
   _str sourceNameOnly = _DataSetNameOnly(sourceDS);
   _str sourceMember = _DataSetMemberOnly(sourceDS);
   _str destNameOnly = _DataSetNameOnly(destDS);
   _str destMember = _DataSetMemberOnly(destDS);

   // Access the source data set information.
   boolean sourceIsFixed, sourceIsPDS, sourceIsBlocked, sourceIsUndef;
   boolean destIsFixed, destIsPDS, destIsBlocked, destIsUndef;
   int sourceRecLen, sourceBlkSize, destRecLen, destBlkSize;
   int status = dsuGetDSInfo(DATASET_ROOT:+sourceNameOnly, sourceIsFixed, sourceIsPDS,
                      sourceIsBlocked, sourceIsUndef, sourceRecLen, sourceBlkSize);
   if (status) {
      _message_box(nls("Can't get information on source data set %s.\nReason: %s",sourceNameOnly,get_message(status)));
      return(status);
   }
   //say(nls("   source: isFixed=%s isPDS=%s isBlocked=%s reclen=%s blkSize=%s",sourceIsFixed, sourceIsPDS, sourceIsBlocked, sourceRecLen, sourceBlkSize));
   if (sourceIsUndef) {
      _message_box(nls("Unsupported source data set type.",sourceNameOnly));
      return(UNSUPPORTED_DATASET_TYPE_RC);
   }

   // Access destination data set information, if data set exists.
   boolean destExists = false;
   int deststatus;
   deststatus = dsuGetDSInfo(DATASET_ROOT:+destNameOnly, destIsFixed, destIsPDS,
                             destIsBlocked, destIsUndef, destRecLen, destBlkSize);
   if (deststatus && deststatus != FILE_NOT_FOUND_RC) {
      _message_box(nls("Can't get information on destination data set %s.\nReason: %s",destNameOnly,get_message(deststatus)));
      return(status);
   }
   if (!deststatus) destExists = true;
   //say(nls("   dest: isFixed=%s isPDS=%s isBlocked=%s reclen=%s blkSize=%s",destIsFixed, destIsPDS, destIsBlocked, destRecLen, destBlkSize));
   if (destExists && destIsUndef) {
      _message_box(nls("Unsupported destination data set type.",destNameOnly));
      return(UNSUPPORTED_DATASET_TYPE_RC);
   }

   // If destination data set exists and is a PDS and source member is specified but
   // destination is not, make the destination member the same as the source member.
   // This effectively changes the copy so that we are copying PDS member to another PDS
   // keeping the member name the same.
   int newRecfm, newRecLen, newBlkSize;
   if (destExists
       && sourceIsPDS && sourceMember != ""
       && destIsPDS && destMember == "") {
      destMember = sourceMember;
      destDS = DATASET_ROOT:+destNameOnly:+FILESEP:+destMember;
   }

   // If destination already exists and is a sequential data set and
   // a check is requested, treat the destination as a sequential
   // data set and ignore the specified member. This member name was
   // tagged on by the caller code to support repeatedly copying PDS
   // members.
   if (checkForDestBeingPS && destExists && !destIsPDS) {
      destMember = "";
      destDS = DATASET_ROOT:+destNameOnly;
   }

   // Case 2: PS to PDS member.
   if (sourceMember == "" && destMember != "") {
      // Verify that source data set is PS.
      if (sourceIsPDS) {
         _message_box(nls("Source data set is not sequential.",sourceNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination already exists, make sure it is a PDS.
      if (destExists && !destIsPDS) {
         _message_box(nls("Destination data set '%s' is not a PDS.",destNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination data set does not exist, create it if requested.
      // Otherwise, consider an error if destination data set does
      // not exist.
      if (!destExists) {
         if (!allocIfNeeded) {
            _message_box(nls("Destination data set '%s' does not exist.",destNameOnly));
            return(FILE_NOT_FOUND_RC);
         }
         newRecfm = RECFM_FB;
         if (sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_F;
         else if (!sourceIsFixed && sourceIsBlocked) newRecfm = RECFM_VB;
         else if (!sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_V;
         newRecLen = sourceRecLen;
         newBlkSize = sourceBlkSize;
         status = _os390NewDS(DATASET_ROOT:+destNameOnly
                              ,volser // volser
                              ,"" // unit
                              ,SPACEUNIT_CYLS // allocate in cylinder
                              ,1 // primary quantity
                              ,1 // secondary quantity
                              ,20 // directory blocks
                              ,newRecfm // record format
                              ,newRecLen // record length
                              ,newBlkSize // block size
                              ,DSORG_PO // PDS
                              );
         if (status) {
            _message_box(nls("Can't allocate destination data set '%s'.\nReason: %s",destNameOnly,get_message(status)));
            return(status);
         }
      }

      // Copy file.
      status = dsuCopyOneDS(sourceDS, destDS);
      return(status);
   }

   // Case 3: PDS member to PS.
   if (sourceMember != "" && destMember == "") {
      // Verify that source data set is PDS and destination data set,
      // if it exists, is PS.
      if (!sourceIsPDS) {
         _message_box(nls("Source data set '%s' is not a PDS.",sourceNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination already exists, make sure it is a PS.
      if (destExists && destIsPDS) {
         _message_box(nls("Destination data set '%s' is not sequential.",destNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination data set does not exist, create it.
      if (!destExists) {
         if (!allocIfNeeded) {
            _message_box(nls("Destination data set '%s' does not exist.",destNameOnly));
            return(FILE_NOT_FOUND_RC);
         }
         newRecfm = RECFM_FB;
         if (sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_F;
         else if (!sourceIsFixed && sourceIsBlocked) newRecfm = RECFM_VB;
         else if (!sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_V;
         newRecLen = sourceRecLen;
         newBlkSize = sourceBlkSize;
         status = _os390NewDS(DATASET_ROOT:+destNameOnly
                              ,volser // volser
                              ,"" // unit
                              ,SPACEUNIT_CYLS // allocate in cylinder
                              ,1 // primary quantity
                              ,1 // secondary quantity
                              ,0 // directory blocks
                              ,newRecfm // record format
                              ,newRecLen // record length
                              ,newBlkSize // block size
                              ,DSORG_PS // PS
                              );
         if (status) {
            _message_box(nls("Can't allocate destination data set '%s'.\nReason: %s",destNameOnly,get_message(status)));
            return(status);
         }
      }

      // Copy file.
      status = dsuCopyOneDS(sourceDS, destDS);
      return(status);
   }

   // Case 4: PDS member to PDS member.
   if (sourceMember != "" && destMember != "") {
      // Verify that source data set is PDS.
      if (!sourceIsPDS) {
         _message_box(nls("Source data set '%s' is not a PDS.",sourceNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination already exists, make sure it is a PDS.
      if (destExists && !destIsPDS) {
         _message_box(nls("Destination data set '%s' is not a PDS.",destNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }

      // If destination data set does not exist, create it if requested.
      // Otherwise, consider an error if destination data set does
      // not exist.
      if (!destExists) {
         if (!allocIfNeeded) {
            _message_box(nls("Destination data set '%s' does not exist.",destNameOnly));
            return(FILE_NOT_FOUND_RC);
         }
         newRecfm = RECFM_FB;
         if (sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_F;
         else if (!sourceIsFixed && sourceIsBlocked) newRecfm = RECFM_VB;
         else if (!sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_V;
         newRecLen = sourceRecLen;
         newBlkSize = sourceBlkSize;
         status = _os390NewDS(DATASET_ROOT:+destNameOnly
                              ,volser // volser
                              ,"" // unit
                              ,SPACEUNIT_CYLS // allocate in cylinder
                              ,1 // primary quantity
                              ,1 // secondary quantity
                              ,20 // directory blocks
                              ,newRecfm // record format
                              ,newRecLen // record length
                              ,newBlkSize // block size
                              ,DSORG_PO // PDS
                              );
         if (status) {
            _message_box(nls("Can't allocate destination data set '%s'.\nReason: %s",destNameOnly,get_message(status)));
            return(status);
         }
      }
      status = dsuCopyOneDS(sourceDS, destDS);
      return(status);
   }

   // Case 1: PS to PS.
   if (!sourceIsPDS) {
      if (deststatus && deststatus != FILE_NOT_FOUND_RC) {
         _message_box(nls("Can't get information on destination data set %s.\nReason: %s",destNameOnly,get_message(deststatus)));
         return(status);
      }
      // Verify that source data set is PS.
      if (sourceIsPDS) {
         _message_box(nls("Source data set '%s' is not sequential.",sourceNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }
      // If destination already exists, make sure it is a PS.
      if (destExists && destIsPDS) {
         _message_box(nls("Destination data set '%s' is not sequential.",destNameOnly));
         return(UNSUPPORTED_DATASET_OPERATION_RC);
      }
      // If destination data set does not exist, create it.
      if (!destExists) {
         if (!allocIfNeeded) {
            _message_box(nls("Destination data set '%s' does not exist.",destNameOnly));
            return(FILE_NOT_FOUND_RC);
         }
         newRecfm = RECFM_FB;
         if (sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_F;
         else if (!sourceIsFixed && sourceIsBlocked) newRecfm = RECFM_VB;
         else if (!sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_V;
         newRecLen = sourceRecLen;
         newBlkSize = sourceBlkSize;
         status = _os390NewDS(DATASET_ROOT:+destNameOnly
                              ,volser // volser
                              ,"" // unit
                              ,SPACEUNIT_CYLS // allocate in cylinder
                              ,1 // primary quantity
                              ,1 // secondary quantity
                              ,0 // directory blocks
                              ,newRecfm // record format
                              ,newRecLen // record length
                              ,newBlkSize // block size
                              ,DSORG_PS // PS
                              );
         if (status) {
            _message_box(nls("Can't allocate destination data set '%s'.\nReason: %s",destNameOnly,get_message(status)));
            return(status);
         }
      }

      // Copy file.
      status = dsuCopyOneDS(sourceDS, destDS);
      return(status);
   }

   // Case 5: PDS to PDS.
   //
   // Verify that source data set is PDS.
   if (!sourceIsPDS) {
      _message_box(nls("Source data set '%s' is not a PDS.",sourceNameOnly));
      return(UNSUPPORTED_DATASET_OPERATION_RC);
   }

   // If destination already exists, make sure it is a PDS.
   if (destExists && !destIsPDS) {
      _message_box(nls("Destination data set '%s' is not a PDS.",destNameOnly));
      return(UNSUPPORTED_DATASET_OPERATION_RC);
   }

   // Get a member list from the source PDS.
   message("Getting "sourceNameOnly" member list ...");
   int memberCount = 0;
   _str memberList[];
   memberList._makeempty();
   _str sourcePath = DATASET_ROOT:+sourceNameOnly:+FILESEP;
   _str member = file_match(sourcePath:+"*", 1);
   while (member != "") {
      memberList[memberCount] = _DataSetMemberOnly(member);
      memberCount++;
      member = file_match(sourcePath:+"*", 0);
   }

   // Prompt user for confirmation if the member count is large.
   int answer;
   if (memberCount > 50) {
      answer = _message_box(nls("About to copy %s members... Continue?"
                                ,memberCount)
                            ,''
                            ,MB_YESNO);
      if (answer != IDYES) return(0);
   }

   // If destination data set does not exist, create it if requested.
   // Otherwise, consider an error if destination data set does
   // not exist.
   if (!destExists) {
      if (!allocIfNeeded) {
         _message_box(nls("Destination data set '%s' does not exist.",destNameOnly));
         return(FILE_NOT_FOUND_RC);
      }
      newRecfm = RECFM_FB;
      if (sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_F;
      else if (!sourceIsFixed && sourceIsBlocked) newRecfm = RECFM_VB;
      else if (!sourceIsFixed && !sourceIsBlocked) newRecfm = RECFM_V;
      newRecLen = sourceRecLen;
      newBlkSize = sourceBlkSize;
      status = _os390NewDS(DATASET_ROOT:+destNameOnly
                           ,volser // volser
                           ,"" // unit
                           ,SPACEUNIT_CYLS // allocate in cylinder
                           ,1 // primary quantity
                           ,1 // secondary quantity
                           ,20 // directory blocks
                           ,newRecfm // record format
                           ,newRecLen // record length
                           ,newBlkSize // block size
                           ,DSORG_PO // PDS
                           );
      if (status) {
         _message_box(nls("Can't allocate destination data set '%s'.\nReason: %s",destNameOnly,get_message(status)));
         return(status);
      }
   }

   // Copy the members.
   int i;
   for (i=0; i<memberCount; i++) {
      message("Copying "sourcePath:+memberList[i]" ...");
      status = dsuCopyOneDS(sourcePath:+memberList[i],
                            DATASET_ROOT:+destNameOnly:+FILESEP:+memberList[i]);
      if (status) {
         answer = _message_box(nls("Can't copy member '%s' from '%s' to '%s'.\nReason: %s\n\nContinue?"
                                   ,memberList[i],sourceNameOnly,destNameOnly,get_message(status))
                               ,"SlickEdit"
                               ,MB_YESNO);
         if (answer != IDYES) return(status);
         // Ignore all errors... and continue to copy the
         // remaining members.
      }
   }
   return(0);
}

/**
 * Compress the specified PDS.
 *
 * @param dsname data set name
 * @return 0 OK, !0 error code
 */
int dsuCompressDS(_str dsname)
{
   // Extract data set name.
   _str dsNameOnly = _DataSetNameOnly(dsname);

   // Build temporary flag and output file.
   _str userName;
   _userName(userName);
   _str outputDoneFlagFile = "/tmp/vsdscompress." :+ userName;
   delete_file(outputDoneFlagFile);

   // Build JCL to use IEBCOPY to do the compress.
   int i;
   mou_hour_glass(1);
   _str jclText = "";
   _str jobStatement[];
   boolean cardDefined = dsuGetJobStatement(jobStatement);
   if (!cardDefined) {
      jclText = jclText :+ "//":+substr(userName:+"1",1,8):+" JOB  1,":+userName:+",MSGCLASS=X\n";
   } else {
      for (i=0; i<jobStatement._length(); i++) {
         jclText = jclText :+ jobStatement[i] :+ "\n";
      }
   }
   //jclText = jclText :+ "//FORM1    OUTPUT DEFAULT=YES,OUTDISP=(PURGE,PURGE),JESDS=ALL\n";
   jclText = jclText :+ "//STEP10   EXEC PGM=IEBCOPY\n";
   jclText = jclText :+ "//SYSPRINT DD SYSOUT=*\n";
   jclText = jclText :+ "//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))\n";
   jclText = jclText :+ "//DDCOMP   DD DSN="dsNameOnly",DISP=OLD\n";
   jclText = jclText :+ "//SYSIN    DD *\n";
   jclText = jclText :+ " COPY INDD=DDCOMP,OUTDD=DDCOMP\n";
   jclText = jclText :+ "/*\n";
   // Signal the completion.
   jclText = jclText :+ "//STEP20   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD PATH='":+outputDoneFlagFile:+"',\n";
   jclText = jclText :+ "//         PATHDISP=(KEEP,KEEP),\n";
   jclText = jclText :+ "//         PATHOPTS=(OWRONLY,OCREAT),\n";
   jclText = jclText :+ "//         PATHMODE=(SIRWXU)\n";
   _os390SubmitJCL(jclText);

   // Wait the JCL to complete.
   // Apply a 30 seconds time-out waiting for the completion flag.
   int totalWait = 0;
   int maxWait = 30;
   while (!file_exists(outputDoneFlagFile)) {
      delay(10); // sleep 1 second
      totalWait++;
      if (totalWait > maxWait) {
         mou_hour_glass(0);
         _message_box(nls("Timed-out waiting for PDS to finish compression.\nPlease check JES status queue for errors."));
         return(DATASET_IO_RC);
      }
   }
   delete_file(outputDoneFlagFile);
   mou_hour_glass(0);
   return(0);
}

int dsuDeletePDSMembers(_str (&dslist)[])
{
   // If deleting a PDS, make sure that no member is opened for read/write.
   int openedCount;
   _str dsNameOnly, memberOnly, qualifiedName;
   dsNameOnly = _DataSetNameOnly(dslist[0]);
   dsNameOnly = upcase(dsNameOnly);
   if (isMemberOpenedForRW(DATASET_ROOT:+dsNameOnly, openedCount)) {
      _message_box(nls("Can't delete %s.\n%s %s opened for read/write.\nPlease close %s and retry."
                       ,dsNameOnly
                       ,openedCount
                       ,(openedCount > 1) ? "members are":"member is"
                       ,(openedCount > 1) ? "those buffers":"the buffer"
                       )
                   );
      return(0);
   }

   // Build temporary flag and output file.
   _str userName;
   _userName(userName);
   _str outputDoneFlagFile = "/tmp/vsmemdelete." :+ userName;
   _str outputDS = userName :+ VSTMPOUTPUTDATASETSUFFIX;
   delete_file(outputDoneFlagFile);

   // Build JCL to use TSO DELETE to do the delete.
   int i;
   mou_hour_glass(1);
   _str jclText = "";
   _str jobStatement[];
   boolean cardDefined = dsuGetJobStatement(jobStatement);
   if (!cardDefined) {
      jclText = jclText :+ "//":+substr(userName:+"1",1,8):+" JOB  1,":+userName:+",MSGCLASS=X\n";
   } else {
      for (i=0; i<jobStatement._length(); i++) {
         jclText = jclText :+ jobStatement[i] :+ "\n";
      }
   }
   jclText = jclText :+ "//FORM1    OUTPUT DEFAULT=YES,OUTDISP=(PURGE,PURGE),JESDS=ALL\n";
   // First step deletes the old output data set, if needed.
   jclText = jclText :+ "//STEP10   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(MOD,DELETE,DELETE),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   // Use TSO DELETE to delete the members.
   jclText = jclText :+ "//STEP20   EXEC PGM=IKJEFT01\n";
   jclText = jclText :+ "//SYSTSPRT DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(NEW,CATLG),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   jclText = jclText :+ "//SYSPRINT DD SYSOUT=*\n";
   jclText = jclText :+ "//SYSUADS  DD DSN=SYS1.UADS,DISP=SHR\n";
   jclText = jclText :+ "//SYSLBC   DD DSN=SYS1.BRODCAST,DISP=SHR\n";
   jclText = jclText :+ "//SYSTSIN  DD *\n";
   for (i=0; i<dslist._length(); i++) {
      memberOnly = _DataSetMemberOnly(dslist[i]);
      memberOnly = upcase(memberOnly);
      qualifiedName = dsNameOnly:+"(":+memberOnly:+")";
      jclText = jclText :+ "DELETE '"qualifiedName"'\n";
   }
   jclText = jclText :+ "/*\n";
   // Signal the completion.
   jclText = jclText :+ "//STEP30   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD PATH='":+outputDoneFlagFile:+"',\n";
   jclText = jclText :+ "//         PATHDISP=(KEEP,KEEP),\n";
   jclText = jclText :+ "//         PATHOPTS=(OWRONLY,OCREAT),\n";
   jclText = jclText :+ "//         PATHMODE=(SIRWXU)\n";
   _os390SubmitJCL(jclText);

   // Wait the JCL to complete.
   // Apply a 20 seconds time-out waiting for the completion flag
   // plus 1 second for each member.
   int totalWait = 0;
   int maxWait = 20 + dslist._length();
   while (!file_exists(outputDoneFlagFile)) {
      delay(10); // sleep 1 second
      totalWait++;
      if (totalWait > maxWait) {
         mou_hour_glass(0);
         _message_box(nls("Timed-out waiting for members to be deleted.\nPlease check JES status queue for errors."));
         return(DATASET_IO_RC);
      }
   }
   mou_hour_glass(0);
   delete_file(outputDoneFlagFile);

   // Parse the output to ensure that members are really deleted.
   /* Sample output.
         READY
         DELETE 'ETPRPIN.TMP.PDS(DSINFO)'
         IDC0549I MEMBER DSINFO DELETED
         READY
         DELETE 'ETPRPIN.TMP.PDS(DUMBCOPY)'
         IDC0549I MEMBER DUMBCOPY DELETED
         READY
         DELETE 'ETPRPIN.TMP.PDS(ENV)'
         IDC0549I MEMBER ENV DELETED
         READY
         END
   */
   int delCount = 0;
   _str delMemberList[];
   delMemberList._makeempty();
   int temp_view, orig_view;
   int status = _open_temp_view(DATASET_ROOT:+outputDS, temp_view, orig_view);
   if (status) {
      _message_box(nls("Can't open and parse delete status output %s.\nReason: %s",outputDS,get_message(status)));
      return(status);
   }
   top(); up();
   _str line, infoCode, text1, text2, deletedMember;
   while (!down()) {
      get_line(line);
      parse line with infoCode text1 deletedMember text2 .;
      if (infoCode == "IDC0549I" && text1 == "MEMBER" && text2 == "DELETED") {
         delMemberList[delCount] = deletedMember;
         delCount++;
      }
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   if (!delCount) {
      _message_box(nls("Can't delete any member.\nPlease check '%s' for reason.",outputDS));
      return(DATASET_IO_RC);
   }
   _message_box(nls("%s %s deleted.",delCount,(delCount > 1) ? "members":"member"));

   // Unregister the deleted member.
   status = _os390UnregisterPDSMemberList(DATASET_ROOT:+dsNameOnly, delMemberList);
   if (status) {
      _message_box(nls("Can't unregister PDS members.\nReason: %s",get_message(status)));
      return(status);
   }

   // Update list.
   doRefresh();
   return(0);
}

/**
 * Submit the specified sequential data set or PDS member to the
 * JES queue.
 *
 * @param dsname     data set name or PDS member name
 * @param deleteDS   Flag: true to delete the JCL data set after submitted
 * @param submitName submit name
 * @return 0 OK, !0 error code
 */
int dsuSubmitDS(_str dsname, boolean deleteDS=false, _str submitName="")
{
   _str nameOnly = _DataSetNameOnly(dsname);
   _str memberOnly = _DataSetMemberOnly(dsname);
   boolean isFixed, isPDS, isBlocked, isUndef;
   int recLen, blkSize;
   int status = dsuGetDSInfo(DATASET_ROOT:+nameOnly, isFixed, isPDS,
                         isBlocked, isUndef, recLen, blkSize);
   if (status) {
      _message_box(nls("Can't get information on data set %s.\nReason: %s",nameOnly,get_message(status)));
      return(status);
   }
   if (isUndef || !recLen || !blkSize) {
      _message_box(nls("Unsupported data set type.",nameOnly));
      return(UNSUPPORTED_DATASET_TYPE_RC);
   }
   _str qualifiedName = upcase(nameOnly);
   if (memberOnly != "") qualifiedName = qualifiedName:+"(":+upcase(memberOnly):+")";

   // Sanity check.
   if (memberOnly == "" && isPDS) {
      _message_box(nls("A PDS cannot be submitted.",nameOnly));
      return(UNSUPPORTED_DATASET_OPERATION_RC);
   }
   if (memberOnly != "" && !isPDS) {
      _message_box(nls("Data set '%s' is a PDS.",nameOnly));
      return(UNSUPPORTED_DATASET_OPERATION_RC);
   }

   // Build temporary flag and output file.
   _str userName;
   _userName(userName);
   _str outputDoneFlagFile = "/tmp/vsdssubmit." :+ userName;
   _str outputDS = userName :+ VSTMPOUTPUTDATASETSUFFIX;
   delete_file(outputDoneFlagFile);

   // Build JCL to use TMP do submit.
   int i;
   mou_hour_glass(1);
   _str jclText = "";
   _str jobStatement[];
   boolean cardDefined = dsuGetJobStatement(jobStatement);
   if (!cardDefined) {
      jclText = jclText :+ "//":+substr(userName:+"1",1,8):+" JOB  1,":+userName:+",MSGCLASS=X\n";
   } else {
      for (i=0; i<jobStatement._length(); i++) {
         jclText = jclText :+ jobStatement[i] :+ "\n";
      }
   }
   jclText = jclText :+ "//FORM1    OUTPUT DEFAULT=YES,OUTDISP=(PURGE,PURGE),JESDS=ALL\n";
   // First step deletes the old output data set, if needed.
   jclText = jclText :+ "//STEP10   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(MOD,DELETE,DELETE),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   // Use TSO DELETE to delete the members.
   jclText = jclText :+ "//STEP20   EXEC PGM=IKJEFT01\n";
   jclText = jclText :+ "//SYSTSPRT DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(NEW,CATLG),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   jclText = jclText :+ "//SYSPRINT DD SYSOUT=*\n";
   jclText = jclText :+ "//SYSUADS  DD DSN=SYS1.UADS,DISP=SHR\n";
   jclText = jclText :+ "//SYSLBC   DD DSN=SYS1.BRODCAST,DISP=SHR\n";
   jclText = jclText :+ "//SYSTSIN  DD *\n";
   jclText = jclText :+ "SUBMIT '"qualifiedName"'\n";
   jclText = jclText :+ "/*\n";
   // Signal the completion.
   jclText = jclText :+ "//STEP30   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD PATH='":+outputDoneFlagFile:+"',\n";
   jclText = jclText :+ "//         PATHDISP=(KEEP,KEEP),\n";
   jclText = jclText :+ "//         PATHOPTS=(OWRONLY,OCREAT),\n";
   jclText = jclText :+ "//         PATHMODE=(SIRWXU)\n";
   // Add a step to delete the JCL data set, if requested.
   if (deleteDS) {
      jclText = jclText :+ "//STEP50   EXEC PGM=IEFBR14\n";
      jclText = jclText :+ "//OUTDD    DD DSNAME=":+qualifiedName:+",\n";
      jclText = jclText :+ "//         DISP=(OLD,DELETE,DELETE)\n";
   }
   _os390SubmitJCL(jclText);

   // Wait the JCL to complete.
   // Apply a 20 seconds time-out waiting for the completion flag.
   int totalWait = 0;
   int maxWait = 20;
   while (!file_exists(outputDoneFlagFile)) {
      delay(10); // sleep 1 second
      totalWait++;
      if (totalWait > maxWait) {
         mou_hour_glass(0);
         _message_box(nls("Timed-out waiting for data set to be submitted.\nPlease check JES status queue for errors."));
         return(DATASET_IO_RC);
      }
   }
   mou_hour_glass(0);
   delete_file(outputDoneFlagFile);

   // Parse the output to get the jobID.
   /* Sample output.
         READY
         SUBMIT 'ETPRPIN.VSLICK.MISC(NOOPJCL)'
         IKJ56250I JOB ETPRPIN1(JOB00225) SUBMITTED
         READY
         END
   */
   int temp_view, orig_view;
   status = _open_temp_view(DATASET_ROOT:+outputDS, temp_view, orig_view);
   if (status) {
      _message_box(nls("Can't open and parse submit status output %s.\nReason: %s",outputDS,get_message(status)));
      return(status);
   }
   top(); up();
   _str line, infoCode, text1, text2, jobname, jobid;
   boolean found = false;
   while (!down()) {
      get_line(line);
      parse line with infoCode text1 jobname"("jobid")" text2 .;
      if (infoCode == "IKJ56250I" && text1 == "JOB" && text2 == "SUBMITTED") {
         found = true;
         break;
      }
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   if (!found) {
      _message_box(nls("Can't determine submitted job ID.\nPlease check JES status queue for errors."));
      return(DATASET_IO_RC);
   }
   if (submitName == "") submitName = qualifiedName;
   _message_box(nls("Submitted %s.\nJob ID is %s.",submitName,jobid));
   return(0);
}

/**
 * Execute a TSO command and put the result in the Output tab
 * on the Output toolbar.
 *
 * @return 0 OK, !0 error code
 */
_command tsocmd(_str cmdText='') name_info(','VSARG2_REQUIRES_MDI)
{
   if (isEclipsePlugin()){
      eclipse_show_disabled_msg("tsocmd");
      return 0;
   }
   // Get the command.
   if (cmdText == "") return(0);

   // Check to make sure the Output toolbar is visible. Delete
   // the old toolbar content.
   int outputWid = 0;
   int outputTB = _find_object('_tboutputwin_form','n');
   if (!outputTB) {
      _message_box(nls("Output toolbar is not visible.\nThe Output tab on the toolbar is required to receive the TSO command output.\nUse View->Toolbars... to make the Output toolbar visible."));
      return(0);
   }
   outputWid = outputTB._find_control("ctloutput");

   // Build temporary flag and output file.
   _str userName;
   _userName(userName);
   _str outputDoneFlagFile = "/tmp/vstso." :+ userName;
   _str outputDS = userName :+ VSTMPOUTPUTDATASETSUFFIX;
   delete_file(outputDoneFlagFile);

   // Build JCL to use TMP to execute the TSO command.
   int i;
   mou_hour_glass(1);
   _str jclText = "";
   _str jobStatement[];
   boolean cardDefined = dsuGetJobStatement(jobStatement);
   if (!cardDefined) {
      jclText = jclText :+ "//":+substr(userName:+"1",1,8):+" JOB  1,":+userName:+",MSGCLASS=X\n";
   } else {
      for (i=0; i<jobStatement._length(); i++) {
         jclText = jclText :+ jobStatement[i] :+ "\n";
      }
   }
   jclText = jclText :+ "//FORM1    OUTPUT DEFAULT=YES,OUTDISP=(PURGE,PURGE),JESDS=ALL\n";
   // First step deletes the old output data set, if needed.
   jclText = jclText :+ "//STEP10   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(MOD,DELETE,DELETE),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   // Use TMP to execute the command.
   jclText = jclText :+ "//STEP20   EXEC PGM=IKJEFT01\n";
   jclText = jclText :+ "//SYSTSPRT DD DSNAME=":+outputDS:+",\n";
   jclText = jclText :+ "//         DISP=(NEW,CATLG),\n";
   jclText = jclText :+ "//         SPACE=(TRK,(1,1)),\n";
   jclText = jclText :+ "//         DCB=(RECFM=FB,LRECL=150,BLKSIZE=1500,DSORG=PS)\n";
   jclText = jclText :+ "//SYSPRINT DD SYSOUT=*\n";
   jclText = jclText :+ "//SYSUADS  DD DSN=SYS1.UADS,DISP=SHR\n";
   jclText = jclText :+ "//SYSLBC   DD DSN=SYS1.BRODCAST,DISP=SHR\n";
   jclText = jclText :+ "//SYSTSIN  DD *\n";
   jclText = jclText :+ cmdText :+ "\n";
   jclText = jclText :+ "/*\n";
   // Signal the completion.
   jclText = jclText :+ "//STEP30   EXEC PGM=IEFBR14\n";
   jclText = jclText :+ "//OUTDD    DD PATH='":+outputDoneFlagFile:+"',\n";
   jclText = jclText :+ "//         PATHDISP=(KEEP,KEEP),\n";
   jclText = jclText :+ "//         PATHOPTS=(OWRONLY,OCREAT),\n";
   jclText = jclText :+ "//         PATHMODE=(SIRWXU)\n";
   _os390SubmitJCL(jclText);

   // Wait the JCL to complete.
   // Apply a 60 seconds time-out waiting for the completion flag.
   int totalWait = 0;
   int maxWait = 60;
   while (!file_exists(outputDoneFlagFile)) {
      delay(10); // sleep 1 second
      totalWait++;
      if (totalWait > maxWait) {
         mou_hour_glass(0);
         _message_box(nls("Timed-out waiting for command to be executed.\nPlease check JES status queue for errors."));
         return(DATASET_IO_RC);
      }
   }
   mou_hour_glass(0);
   delete_file(outputDoneFlagFile);

   // Parse for the output and append new output at the bottom.
   outputWid.bottom();
   int temp_view, orig_view;
   int status = _open_temp_view(DATASET_ROOT:+outputDS, temp_view, orig_view);
   if (status) {
      _message_box(nls("Can't read command output from %s.\nReason: %s",outputDS,get_message(status)));
      return(status);
   }
   top(); up();
   boolean firstREADY = true;
   _str word = "";
   _str line = "";
   while (!down()) {
      get_line(line);
      parse line with word .;
      if (word == "READY" && firstREADY) { // strip the first "READY"
         firstREADY = false;
         continue;
      }
      if (word == "END") continue; // strip the ending "END"
      if (outputWid) outputWid.insert_line(strip(line,'T',' '));
   }
   activate_window(orig_view);
   _delete_temp_view(temp_view, true);
   outputWid.bottom();
   outputWid.center_line();

   // Make the Output tab active.
   int sstabWid = outputTB._find_control("_output_sstab");
   sstabWid.p_ActiveTab = OUTPUTTOOLTAB_OUTPUT;
   //_message_box(nls("Command completed.\nOutput is available in the Output tab of the Output toolbar."));
   return(0);
}

//---------------------------------------------------------------
defeventtab _datasetutil_form;
static void doAllocate()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   typeless status = show('-modal _dsalloc_form');
   if (!status) {
      doRefresh();
   }
}
void ctlallocate.lbutton_up()
{
   doAllocate();
}
void _datasetutil_form.'a-,'()
{
   do_goback();
}
void ctlback.lbutton_up()
{
   do_goback();
}
void _datasetutil_form.'f1'()
{
   help('Data Set Utilities dialog box');
}
static void do_isearch(int combo_wid,int list_wid)
{
   COMBOUSERDATA openfnuser;openfnuser=combo_wid.p_user;
   typeless last_data=openfnuser.last_data;
   if (last_data==null) {
      last_data='';
   }

   _str text=strip(p_text,'L');
   text=strip(text,'B','"');
   //text=_unix_expansion(text);

   int Nofselected=list_wid.p_Nofselected;
   if (list_wid.p_multi_select==MS_EXTENDED) {
      list_wid._lbdeselect_all();
   }
   typeless status=list_wid._lbi_search(last_data,text,'I' /*_fpos_case*/,'');
   /*if (Nofselected) {
      _opennofselected.p_caption=list.p_Nofselected' of 'list.p_Noflines' selected'
      //list.call_event(CHANGE_SELECTED,list,ON_CHANGE,'');
   } */
   //openfnuser.name_part=text;
   openfnuser.last_data=last_data;
   combo_wid.p_user=openfnuser;
   if (!status) {
      list_wid._lbselect_line();
   }
}
void ctlcombo1.on_change(int reason)
{
   if (reason==CHANGE_OTHER) {
      int combo_wid=_control ctlcombo1;
      int list_wid=_control ctllist1;
      do_isearch(combo_wid,list_wid);
   } else if (reason==CHANGE_CLINE) {
      combo1_enter();
   }
}
void ctlcombo2.on_change(int reason)
{
   if (reason==CHANGE_OTHER) {
      int combo_wid=_control ctlcombo2;
      int list_wid=_control ctllist2;
      do_isearch(combo_wid,list_wid);
   }
}
void ctllist2.on_change(int reason)
{
   ctllist1.call_event(reason,ctllist1,ON_CHANGE,'w');
}
void ctllist1.on_change(int reason)
{
   if (reason==CHANGE_SELECTED) {
      set_flstate();
   }
}
void ctlopen.lbutton_up()
{
   execute('datasetutilop open');
}
ctllist1.lbutton_double_click()
{
   ctlopen.call_event(ctlopen,LBUTTON_UP,'W');
}
void _datasetutil_form.f3,esc()
{
   if (ctlpicture2.p_visible) {
      do_goback();
   } else {
      if (ctlcombo1.p_text!=DATASET_ROOT'*') {
         _append_retrieve(0, ctlcombo1.p_text, "_datasetutil_form.ctlcombo1");
      }
      p_active_form._delete_window();
   }
}
ctllist2.lbutton_double_click()
{
   ctlopen.call_event(ctlopen,LBUTTON_UP,'W');
}
void _datasetutil_form.'a-o','c-o','enter'()
{
   int focus_wid=_get_focus();
   if (last_event():==ENTER) {
      if(focus_wid==_control ctlcombo1) {
         combo1_enter();
         return;
      } else if(focus_wid==_control ctlcombo2) {
         combo2_enter();
         return;
      }
   }
   ctlopen.call_event(ctlopen,LBUTTON_UP,'W');
}
void ctlbrowse.lbutton_up()
{
   execute('datasetutilop browse');
}
void _datasetutil_form.'a-b'()
{
   ctlbrowse.call_event(ctlbrowse,LBUTTON_UP,'W');
}
void ctldelete.lbutton_up()
{
   doDelete();
}
void _datasetutil_form.'a-d','del'()
{
   if (last_event():==DEL && (p_window_id==ctlcombo1 || p_window_id==ctlcombo2)) {
      _delete_char();
      return;
   }
   ctldelete.call_event(ctldelete,LBUTTON_UP,'W');
}

void _datasetutil_form.'c-a'()
{
   execute('datasetutil selectall');
}
void _datasetutil_form.'a-u'()
{
   if (ctlsubmit.p_enabled) {
      execute('datasetutilop submit');
   }
}
void _datasetutil_form.'a-r'()
{
   if (ctlrename.p_enabled) {
      execute('datasetutil rename');
   }
}
void _datasetutil_form.'a-c'()
{
   if (ctlcopy.p_enabled) {
      execute('datasetutil copy');
   }
}
void _datasetutil_form.'a-h'()
{
   if (ctlRefresh.p_enabled) {
      execute('datasetutil refresh');
   }
}
void _datasetutil_form.'a-a'()
{
   if (ctlallocate.p_enabled) {
      doAllocate();
   }
}
void _datasetutil_form.'a-p'()
{
   if (ctlcompress.p_enabled) {
      execute('datasetutilop compress');
   }
}
void _datasetutil_form.'a-l'()
{
   if (ctlcatalog.p_enabled) {
      doCatalog();
   }
}
void _datasetutil_form.'a-n'()
{
   if (ctluncatalog.p_enabled) {
      execute('datasetutilop uncatalog');
   }
}
void _datasetutil_form.'a-f'()
{
   if (ctlfree.p_enabled) {
      execute('datasetutilop free');
   }
}
void _datasetutil_form.'a-i'()
{
   if (ctlinfo.p_enabled) {
      execute('datasetutil info');
   }
}

void ctllist1.on_create(_str filename="")
{
   ctlback.p_enabled=false;
   ctlpicture2.p_visible=0;
   set_flstate();

   _str font=(_dbcs()?def_qt_jsellist_font:def_qt_sellist_font);
   ctllist1._font_string2props(font);
   ctllist2._font_string2props(font);
   ctlfields._font_string2props(font);

   p_active_form.call_event(p_active_form,ON_RESIZE,'W');
   int index=find_index('_datasetutil_menu',oi2type(OI_MENU));
   int menu_handle=p_active_form._menu_load(index,'M');
   p_active_form._menu_set(menu_handle);
   ctlcombo1._retrieve_list();
   ctlcombo2._retrieve_list();
   if (filename!='') {
      if (filename == DATASET_ROOT) filename = filename :+ "*";
   } else {
      // Try to restore previous value. If none found, use the
      // user's name as the top level qualifier.
      _str oldText = _retrieve_value("_datasetutil_form.ctlcombo1");
      if (oldText == "") {
         _str userName;
         _userName(userName);
         filename = DATASET_ROOT:+upcase(userName)".*";
      } else {
         filename = oldText;
      }
   }
   ctlcombo1.p_text=filename;
   combo1_enter();
}
void _datasetutil_form.on_resize()
{
   int list_width=p_active_form.p_client_width*_twips_per_pixel_x();
   int list_x=0;
   int x=list_x;
   int y=0;
   //use width and height of first button.
   //width=_find_control(gbuttonlist[0]).p_width;
   //height=_find_control(gbuttonlist[0]).p_height;

   // Find the widest button.
   int wid=0;
   int i,widest = 0;
   for (i=0;i<gbuttonlist._length();++i) {
      wid=_find_control(gbuttonlist[i]);
      if (widest < wid.p_width) {
         widest = wid.p_width;
      }
   }
   for (i=0;i<gbuttonlist2._length();++i) {
      wid=_find_control(gbuttonlist2[i]);
      if (widest < wid.p_width) {
         widest = wid.p_width;
      }
   }

   // Adjust the top row buttons
   int height=0;
   for (i=0;i<gbuttonlist._length();++i) {
      wid=_find_control(gbuttonlist[i]);
      height=wid.p_height;
      wid._move_window(x,y,widest,height);
      x+=widest;
   }
   // Adjust the bottom row buttons
   x=list_x;
   y+=height;
   for (i=0;i<gbuttonlist2._length();++i) {
      wid=_find_control(gbuttonlist2[i]);
      height=wid.p_height;
      wid._move_window(x,y,widest,height);
      x+=widest;
   }
   y+=height;
   int clientH = p_active_form.p_client_height;
   int picture_height=clientH*_twips_per_pixel_y()-y;
   if (picture_height<0) {
      picture_height=0;
   }
   ctlpicture1._move_window(list_x,y,list_width,picture_height);
   int list_height=picture_height-ctllist1.p_y;
   if (list_height<0) list_height=0;
   ctllist1._move_window(0,ctllist1.p_y,list_width,list_height);
   ctlpicture2._move_window(list_x,y,list_width,picture_height);
   list_height=picture_height-ctllist2.p_y;
   ctllist2.p_x=0;ctllist2.p_width=list_width;
   ctllist2._move_window(0,ctllist2.p_y,list_width,list_height);
}
static void set_flstate()
{
#if 0
   if (ctlpicture1.p_visible) {
      if (ctllist1.p_Noflines) {
         if (isdirectory(get_filename())) {
            state=FLSTATE_PDS;
         } else {
            state=FLSTATE_SDS_OR_MEMBER;
         }
      } else {
         state=FLSTATE_EMPTYLIST;
      }
   } else {
      if (ctllist2.p_line>1) {
         state=FLSTATE_SDS_OR_MEMBER;
      } else {
         state=FLSTATE_EMPTYLIST;
      }
   }
   FLSTATE=state;

   mf=_xOnUpdate_datasetutilop(null,0,". open");
   ctlopen.p_enabled=(mf==MF_ENABLED)?true:false;
   mf=_xOnUpdate_datasetutilop(null,0,". browse");
   ctlbrowse.p_enabled=(mf==MF_ENABLED)?true:false;
   mf=_xOnUpdate_datasetutilop(null,0,". delete");
   ctldelete.p_enabled=(mf==MF_ENABLED)?true:false;
#endif
}
static int get_flstate()
{
#if 0
   return(FLSTATE);
#else
   int state=0;
   if (ctlpicture1.p_visible) {
      if (ctllist1.p_Noflines) {
         if (isdirectory(get_filename())) {
            state=FLSTATE_PDS;
         } else {
            state=FLSTATE_SDS_OR_MEMBER;
         }
      } else {
         state=FLSTATE_EMPTYLIST;
      }
   } else {
      if (ctllist2.p_Noflines) {
         state=FLSTATE_SDS_OR_MEMBER;
      } else {
         state=FLSTATE_EMPTYLIST;
      }
   }
   return(state);
#endif
}

/**
 * Check to see if any member of the specified PDS is opened for read/write
 * in SlickEdit.
 *
 * @param filename PDS name
 * @param openedCount
 *                 returning count of the number of member opened for read/write
 * @return Flag: true for at least one member opened, false for none
 */
static boolean isMemberOpenedForRW(_str filename, int & openedCount)
{
   // Check all buffers to make sure that no member of this PDS are
   // being opened for read/write in SlickEdit.
   _str dsNameOnly = _DataSetNameOnly(filename);
   openedCount = 0;
   int temp_view_id;
   int orig_view_id = _create_temp_view(temp_view_id);
   int temp_buf_id = p_buf_id;
   _next_buffer("HR");
   while (p_buf_id != temp_buf_id) {
      if (_DataSetIsFile(p_buf_name)) {
         _str bufNameOnly = _DataSetNameOnly(p_buf_name);
         if (!p_readonly_mode && bufNameOnly == dsNameOnly) {
            openedCount++;
         }
      }
      _next_buffer( "HR" );
   }
   p_buf_id = temp_buf_id;
   _delete_temp_view(temp_view_id);
   activate_window(orig_view_id);
   return(openedCount ? true:false);
}

int _xOnUpdate_datasetutilop(CMDUI &cmdui,int target_wid,_str command)
{
   _str cmdname='';
   _str param='';
   parse command with cmdname param;
   boolean docurline=(!get_Nofselected() || (get_Nofselected()==1 && get_lbisline_selected()));
   switch (param) {
   case 'open':
      if (!docurline) return(MF_ENABLED);
      return((FLSTATE==FLSTATE_SDS_OR_MEMBER || FLSTATE==FLSTATE_PDS)?MF_ENABLED:MF_GRAYED);
   case 'browse':
      if (!docurline) return(MF_ENABLED);
      return((FLSTATE==FLSTATE_SDS_OR_MEMBER)?MF_ENABLED:MF_GRAYED);
   case 'delete':
      if (!docurline) return(MF_ENABLED);
      return((FLSTATE==FLSTATE_PDS || FLSTATE==FLSTATE_SDS_OR_MEMBER)?MF_ENABLED:MF_GRAYED);
   }
   return(MF_ENABLED);
}
static int doop(_str param,_str filename, DSINFO & dsi)
{
   int status = 0;
   int openedCount;
   int orig_wid=p_window_id;
   int hasmember = pos('/', filename, 3);
   switch (param) {
   case 'open':
      if (!isdirectory(filename)) {
         message("Opening "filename" ...");
         status = _mdi.edit("-^show_error_in_msgbox " :+ maybe_quote_filename(filename));
         if (!status) {
            _mdi._set_foreground_window();
            clear_message();
         }
      }
      break;
   case 'browse':
      if (!isdirectory(filename)) {
         status = _mdi.edit(maybe_quote_filename(filename)" -#read-only-mode");
         if (!status) _mdi._set_foreground_window();
      }
      break;
   case 'delete':
      // If deleting a PDS, make sure that no member is opened for read/write.
      if (isMemberOpenedForRW(filename, openedCount)) {
         _message_box(nls("Can't delete %s.\n%s %s opened for read/write.\nPlease close %s and retry."
                          ,filename
                          ,openedCount
                          ,(openedCount > 1) ? "members are":"member is"
                          ,(openedCount > 1) ? "those buffers":"the buffer"
                          )
                      );
         status = DATASET_IN_USE_RC;
         break;
      }
      mou_hour_glass(1);
      message("Deleting "filename" ...");
      status = _os390DeleteDS(filename);
      clear_message();
      mou_hour_glass(0);
      break;
   case 'submit':
      mou_hour_glass(1);
      message("Submitting "filename" ...");
      status = dsuSubmitDS(filename);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         _message_box("Unable to submit "filename".\n"get_message(status));
      }
      break;
   case 'compress':
      if (dsi.dsorg != "PO") {
         _message_box(nls("Only PDS can be compressed."));
         status = 1;
         break;
      }
      if (hasmember) {
         _message_box("Can't compress member "filename".\nOnly PDS is supported.");
         status = 1;
         break;
      }

      // Check all buffers to make sure that no member of this PDS are
      // being opened for read/write in SlickEdit.
      if (isMemberOpenedForRW(filename, openedCount)) {
         _message_box(nls("Can't compress %s.\n%s %s opened for read/write.\nPlease close %s and retry."
                          ,filename
                          ,openedCount
                          ,(openedCount > 1) ? "members are":"member is"
                          ,(openedCount > 1) ? "those buffers":"the buffer"
                          )
                      );
         status = DATASET_IN_USE_RC;
         break;
      }

      // Compress the PDS.
      mou_hour_glass(1);
      message("Compressing "filename" ...");
      status = dsuCompressDS(filename);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         _message_box(nls("Unable to compress %s.\nReason: %s",filename,get_message(status)));
      }
      break;
   case 'uncatalog':
      if (hasmember) {
         _message_box("Can't uncatalog member "filename".\nOnly data set is supported.");
         status = 1;
         break;
      }
      mou_hour_glass(1);
      message("Uncataloging "filename" ...");
      status = _os390UncatalogDS(filename);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         _message_box("Unable to uncatalog "filename".\n"get_message(status));
      }
      break;
   case 'free':
      if (hasmember) {
         _message_box("Can't free member "filename".\nOnly data set is supported.");
         status = 1;
         break;
      }
      mou_hour_glass(1);
      message("Freeing "filename" ...");
      status = _os390FreeDS(filename);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         _message_box("Unable to free "filename".\n"get_message(status));
      }
      break;
   }
   p_window_id=orig_wid;
   return(status);
}
static _str get_filename()
{
   _str dsname;
   if (ctlpicture1.p_visible) {
      parse ctllist1._lbget_text() with dsname" ".;
      return(dsname);
   }
   _str filename=ctllist2._lbget_text();
   _str member=ctllist2._lbget_text();
   member=strip(substr(member,1,8));
   parse ctllist1._lbget_text() with dsname" ".;
   return(dsname:+FILESEP:+member);
}
static _str getDSInfoFromList(DSINFO & dsi)
{
   // Get data set info.
   _str dsname, reclenText, blkSizeText;
   if (ctlpicture1.p_visible) {
      dsi.isDS = true;
      dsi.reclen = 0;
      dsi.blkSize = 0;
      parse ctllist1._lbget_text() with dsi.name dsi.volser dsi.dsorg dsi.recfm reclenText blkSizeText;
      if (isinteger(reclenText)) {
         dsi.reclen = (int)reclenText;
      }
      if (isinteger(blkSizeText)) {
         dsi.blkSize = (int)blkSizeText;
      }
      return(dsi.name);
   }

   // Get PDS member info.
   dsi.isDS = false;
   _str filename=ctllist2._lbget_text();
   _str member=ctllist2._lbget_text();
   member=strip(substr(member,1,8));
   parse ctllist1._lbget_text() with dsname" ".;
   dsi.name = dsname:+FILESEP:+member;
   return(dsi.name);
}
static int get_listwid()
{
   return((ctlpicture1.p_visible)? ctllist1:ctllist2);
}
static int get_Nofselected()
{
   int list_wid = get_listwid();
   if (!list_wid.p_Noflines) return(0);
   return(list_wid.p_Nofselected);
}
static boolean get_lbisline_selected()
{
   return(get_listwid()._lbisline_selected() != 0);
}
static void do_goback()
{
   //parse p_active_form.p_caption with caption '-';
   //caption=strip(caption);
   //p_active_form.p_caption=caption;
   ctlpicture2.p_visible=0;
   ctlpicture1.p_visible=1;ctllist1._set_focus();
   ctlcompress.p_enabled=true;
   set_flstate();
   ctlback.p_enabled=false;
   updateButtons(false);
}
static void refreshList()
{
   int list_wid = get_listwid();
   if (list_wid.p_name == "ctllist1") {
      combo1_enter();
   } else {
      combo2_enter();
   }
   list_wid._set_focus();
}
static void printstatus(_str param, int scount)
{
   _str dataset = scount :+ " data set";
   if (!scount) {
      dataset = "no data set";
   } else if (scount > 1) {
      dataset = dataset :+ "s";
   }
   switch (param) {
   case "submit":
      _message_box("Submitted "dataset".");
      break;
   case "compress":
      _message_box("Compressed "dataset".");
      break;
   case "uncatalog":
      _message_box("Uncataloged "dataset".");
      break;
   case "free":
      _message_box("Freed "dataset".");
      break;
   }
}
_command void datasetutilop(_str param='')
{
   int mf=_xOnUpdate_datasetutilop(null,0,". "param);
   if (mf!=MF_ENABLED) {
      _beep();
      return;
   }

   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   // Make something is selected in the list.
   int list_wid=formid.get_listwid();
   if (!list_wid.p_Noflines || !list_wid.p_Nofselected) return;
   boolean memberListVisible = false;
   if (list_wid == ctllist2) memberListVisible = true;

   typeless result=0;
   typeless docurline='';
   int refreshl = 0;
   DSINFO dsi;
   if (param=="delete") {
      docurline=(!get_Nofselected() || (get_Nofselected()==1 && get_lbisline_selected()));
      if (docurline) {
         result=_message_box(nls("Delete %s?",get_filename()),"",MB_YESNOCANCEL);
      } else {
         result=_message_box(nls("Are you sure you want to delete %s %s"
                                 ,get_Nofselected()
                                 ,memberListVisible ? "members":"data sets"
                                 )
                             ,"",MB_YESNOCANCEL);
      }
      if (result!=IDYES) {
         return;
      }
      refreshl = 1;
   }
   typeless status=0;
   _str filename='';
   int fileCount = get_Nofselected();
   if (!fileCount || (fileCount==1 && get_lbisline_selected())) {
      filename = getDSInfoFromList(dsi);
      if (param=='open' && isdirectory(filename)) {
         datasetutil('list');
         return;
      }
      status = doop(param,filename,dsi);
      if (refreshl) formid.refreshList();
      if (!status) {
         printstatus(param, 1);
      }
      return;
   }

   // If opening a lot of data sets, let the user know.
   int answer=0;
   _str fileTypeText = memberListVisible ? "members":"data sets";
   if ((param == "open" || param == "browse") && fileCount > DS_FILECOUNTWARNING) {
      answer = _message_box(nls("About to open %s %s.\n\nContinue?",fileCount,fileTypeText),"",MB_YESNO);
      if (answer != IDYES) return;
   }

   typeless p;
   list_wid=get_listwid();
   list_wid._save_pos2(p);
   status=list_wid._lbfind_selected(1);
   int scount = 0;
   int opstatus = 0;
   boolean filesOpenedPrompt = true;
   for (;;) {
      if (status) {
         break;
      }
      if ((param == "open" || param == "browse")) {
         if (filesOpenedPrompt && scount > DS_FILESOPENEDWARNING) {
            int remaining = fileCount - scount;
            if (remaining > DS_FILESOPENEDWARNING/4) {
               answer = _message_box(nls("Opened %s %s. %s remaining.\n\nContinue and open the remaining %s?\nYou will not be prompted again.",scount,fileTypeText,remaining,fileTypeText),"",MB_YESNO);
               if (answer != IDYES) break;
               filesOpenedPrompt = false;
            }
         }
      }
      filename = getDSInfoFromList(dsi);
      status = doop(param,filename,dsi);
      opstatus = status;
      if (!status) scount++;
      status=list_wid._lbfind_selected(0);
      if (opstatus && !status) {
         if (param == 'open' || param == 'browse') {
            answer = _message_box(nls("Continue with next data set?"),"",MB_YESNO);
            if (answer != IDYES) break;
         }
      }
   }
   if (refreshl) refreshList();
   list_wid._restore_pos2(p);
   printstatus(param, scount);
}
int _xOnUpdate_datasetutil(CMDUI &cmdui,int target_wid,_str command)
{
   _str cmdname='';
   _str param='';
   parse command with cmdname param;
   switch (param) {
   case 'list':
      return((FLSTATE==FLSTATE_PDS)?MF_ENABLED:MF_GRAYED);
   /*case 'search':
      return(MF_ENABLED);*/
   case 'selectall':
      return((FLSTATE!=FLSTATE_EMPTYLIST)?MF_ENABLED:MF_GRAYED);
   case 'invert':
      return((FLSTATE!=FLSTATE_EMPTYLIST)?MF_ENABLED:MF_GRAYED);
   case 'allocate':
      return(MF_ENABLED);
   }
   return(MF_ENABLED);
}
static void combo1_enter()
{
   _str text=ctlcombo1.p_text;
   _str member='';
   if (text=='') {
      return;
   }
#if __UNIX__
   if (substr(text,1,2) != '//') {
      text = "//" :+ text;
   }
   parse text with '//' text '/' member;
   if (substr(text,1,2)!='//') {
      text='//'text;
   }
#else
   if (substr(text,1,3) != '1:\') {
      text = '1:\' :+ text;
   }
   parse text with '1:\' text '\' member;
   if (substr(text,1,3)!='1:\') {
      text='1:\'text;
   }
#endif
   if (last_char(text)==FILESEP && length(text)>length(DATASET_ROOT)) {
      text=substr(text,1,length(text)-1);
   }
   typeless result=0;
   if (text == DATASET_ROOT) text = text :+ "*";
   if (text==DATASET_ROOT'*') {
      result=_message_box("No high level qualifier has been specified.  This search may take a very long time.\nWe recommend you specify a high level qualifier (example "DATASET_ROOT"sys.*).\n\nContinue search anyway?","",MB_YESNOCANCEL);
      if (result!=IDYES) {
         return;
      }
   }
   if (iswildcard(text)) {
      ctlcombo1.p_text = text;
      if (file_match('-p 'text,1)=='') {
         _message_box('File not found');
         return;
      }
   }
   ctllist1._lbclear();
   mou_hour_glass(1);
   ctlcombo1.p_text = text;
   //_message_box('text='text);
   int status=ctllist1.insert_file_list('-v +dpz 'maybe_quote_filename(text)); // +z gets the data set info
   //ctllist1.get_line(line);
   //_message_box('h2 l='line);
   mou_hour_glass(0);
   ctllist1._lbsort();
   ctllist1._lbtop();ctllist1._lbselect_line();
   ctllist1._set_focus();
   set_flstate();
   if (status) {
      //_message_box("No matching data set found.");
      if (ctlpicture1.p_visible) {
         ctlcombo1._set_focus();
      } else {
         ctlcombo2._set_focus();
      }
      return;
   }

   // Update the rest.
   int combo_wid=_control ctlcombo1;
   _append_retrieve(combo_wid,combo_wid.p_text);
   if (combo_wid._lbget_text()!=combo_wid.p_text) {
      combo_wid._lbtop();combo_wid._lbup();
      combo_wid._lbadd_item(combo_wid.p_text);
   }
   if (member!='') {
      ctlcombo2.p_text=member;
      combo2_enter();

      ctlpicture1.p_visible=0;
      ctlcompress.p_enabled=false;
      ctlback.p_enabled=true;
      ctlpicture2.p_visible=1;//ctllist2._set_focus();
      ctlpdsname.p_caption=upcase(text);
   }
   updateButtons(false);
}
void ctlcombo1.'enter'()
{
   combo1_enter();
}
static void setDataSetName(_str dsname)
{
   ctlDSName.p_caption = dsname;
}
static void combo2_enter()
{
   _str text=ctlcombo2.p_text;
   if (text=='') text='*'; //ALLFILES_RE;
   ctllist2._lbclear();
   mou_hour_glass(1);
   _str filepath = get_filename();
   setDataSetName(filepath);
   if (last_char(filepath) != FILESEP) {
      filepath = filepath :+ FILESEP;
   }
   filepath = filepath :+ text;
   int status=ctllist2.insert_file_list('-v -p +z +m +j 'maybe_quote_filename(filepath));
   mou_hour_glass(0);
   ctllist2._lbsort();
   ctllist2._lbtop();
   ctllist2._lbselect_line();
   ctllist2._set_focus();
   set_flstate();
   if (status) {
      //_message_box("No matches found");
      if (ctlpicture1.p_visible) {
         ctlcombo1._set_focus();
      } else {
         ctlcombo2._set_focus();
      }
   } else {
      int combo_wid=_control ctlcombo2;
      _append_retrieve(combo_wid,combo_wid.p_text);
      if (combo_wid._lbget_text()!=combo_wid.p_text) {
         combo_wid._lbtop();combo_wid._lbup();
         combo_wid._lbadd_item(combo_wid.p_text);
      }
   }
   updateButtons(true);
}
void ctlcombo2.'enter'()
{
   combo2_enter();
}
_command void datasetutil(_str param="")
{
   _str path='';
   _str filename='';
   switch (param) {
   case 'list':
      if (ctlpicture2.p_visible || get_flstate()!=FLSTATE_PDS) {
         _beep();
         return;
      }
      ctllist2._lbclear();
      path=get_filename();
      setDataSetName(path);
      filename=maybe_quote_filename(path:+FILESEP:+'*' /*ALLFILES_RE*/);
      mou_hour_glass(1);
      // On OS/390, +M tells directory listing to give the real PDS listing.
      // Note that the PDS directory header is read every time -- No caching.
      ctllist2.insert_file_list('-v -p +z +m +j 'filename);
      // No need to sort PDS member listing.  The returning list is always sorted.
      //ctllist2._lbsort('-f');
      mou_hour_glass(0);
      ctllist2._lbtop();
      ctllist2._lbselect_line();

      ctlpicture1.p_visible=0;
      ctlcompress.p_enabled=false;
      ctlback.p_enabled=true;
      ctlpicture2.p_visible=1;
      //ctllist2._set_focus();
      ctlcombo2._set_focus();
      ctlpdsname.p_caption=upcase(path);
      set_flstate();
      updateButtons(true);
      return;
   case 'selectall':
      get_listwid()._lbselect_all();
      return;
   case 'invert':
      get_listwid()._lbinvert();
      return;
   case 'allocate':
      doAllocate();
      return;
   case 'copy':
      doCopy();
      return;
   case 'catalog':
      doCatalog();
      return;
   case 'rename':
      doRename();
      return;
   case 'info':
      doDetailedInfo();
      return;
   case 'refresh':
      doRefresh();
      return;
   case 'register':
      doRegister();
      return;
   }
}
void _DataSetUtilList(_str filename)
{
   int index=find_index('_datasetutil_form',oi2type(OI_FORM));
   int wid=_isloaded(index,'N');
   if (!wid) {
      show('-app -xy _datasetutil_form',filename);
      return;
   }
   p_window_id=wid;
   wid._set_foreground_window();

   // If a file name is specified, update the listing.
   if (filename != "") {
      if(ctlpicture2.p_visible) {
         do_goback();
      }
      ctlcombo1.p_text=filename;
      combo1_enter();
   }
}
static void doCopy()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   int list_wid=formid.get_listwid();
   if (!list_wid.p_Noflines || !list_wid.p_Nofselected) {
      _beep();
      return;
   }

   // Determine whether we are working on data set list
   // or PDS member list.
   int dslist = 1;
   if (list_wid == ctllist2) dslist = 0;
   int turnoff = 0;
   if (dslist) {
      turnoff = turnoff | 0x010; // disable "dest is seq"
   }
   if (dslist || list_wid.p_Nofselected < 2) {
      turnoff = turnoff | 0x08;  // disable "No prompt"
   }

   int scount = 0;
   _str reusedataset = "";
   typeless p;
   list_wid._save_pos2(p);
   int status=list_wid._lbfind_selected(1);
   boolean allocIfNeeded;
   _str volser;
   _str sds, dds;
   for (;;) {
      if (status) break;
      // Get the destination data set or PDS member.
      _str filename=formid.get_filename();
      _str member;
      member = "";
      if (!dslist) {
         member=_DataSetMemberOnly(filename);
      }
      sds = filename;
      boolean checkForDestBeingPS;
      if (reusedataset == "") {
         typeless result = show('-modal _dscopy_form',turnoff,filename,"copy");
         if (result=='') break;
         allocIfNeeded = _param2 ? true:false;
         volser = _param4;
         dds = _param1;
         // If an explicit member was specified, use it.
         // Otherwise, use the source member, if there is one.
         if (_param3 != "") {
            dds = dds :+ FILESEP :+ _param3;
         } else {
            checkForDestBeingPS = false;
            if (member != "" && !_param6) {
               dds = dds :+ FILESEP :+ member;
               // Should check for destination already exists and is
               // a sequential data set. If it is so, treat destination
               // as a PS and not PDS eventhough the argument dds
               // seems to indicate otherwise.
               checkForDestBeingPS = true;
            }
         }
      } else {
         dds = reusedataset;
         // Use the source member.
         if (member != "") {
            dds = dds :+ FILESEP :+ member;
         }
      }
      mou_hour_glass(1);
      message("Copying "sds" to "dds" ...");
      status = dsuCopyDS(sds,dds,volser,allocIfNeeded,checkForDestBeingPS);
      mou_hour_glass(0);
      if (!status) scount++;
      if (reusedataset == "" && _param5 == 1) {  // reuse data set
         reusedataset = _param1;
      }
      status=list_wid._lbfind_selected(0);
   }
   clear_message();
   list_wid._restore_pos2(p);
   if (scount) {
      formid.refreshList();
   }
}
void ctlcopy.lbutton_up()
{
   doCopy();
}
static void doRename()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   int list_wid=formid.get_listwid();
   if (!list_wid.p_Noflines || !list_wid.p_Nofselected) {
      _beep();
      return;
   }

   // Determine whether we are working on data set list
   // or PDS member list.
   int dslist = 1;
   if (list_wid == ctllist2) dslist = 0;
   int turnoff = 0x01 | 0x04 | 0x08 | 0x10; // disable "volume" and "no prompt"
   if (dslist) {
      turnoff = turnoff | 0x02; // disable "to member"
   }

   int scount = 0;
   typeless p;
   list_wid._save_pos2(p);
   int status=list_wid._lbfind_selected(1);
   _str sds, dds;
   for (;;) {
      if (status) break;
      _str filename=formid.get_filename();
      _str member;
      member = "";
      if (!dslist) {
         member = _DataSetMemberOnly(filename);
      }
      sds = filename;
      typeless result = show('-modal _dscopy_form',turnoff,filename,"rename");
      if (result=='') break;
      dds = _param1;
      if (_param3 != "") {
         dds = dds :+ FILESEP :+ _param3;
      }
      //say("sds="sds" dds="dds);
      mou_hour_glass(1);
      message("Renaming "sds" to "dds" ...");
      status = _os390RenameDS(sds,dds);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         _message_box("Unable to rename "sds" to "dds".\n"get_message(status));
      } else {
         scount++;
      }
      status=list_wid._lbfind_selected(0);
   }
   list_wid._restore_pos2(p);
   if (scount) {
      formid.refreshList();
   }
}
void ctlrename.lbutton_up()
{
   doRename();
}
void ctlsubmit.lbutton_up()
{
   execute('datasetutilop submit');
}
void ctlcompress.lbutton_up()
{
   execute('datasetutilop compress');
}
static void doCatalog()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   // Determine whether we are working on data set list
   // or PDS member list.
   int list_wid=formid.get_listwid();
   if (list_wid == ctllist2) {
      _message_box("Can't catalog members.\nOnly data set is supported.");
      return;
   }

   // Get the data set and volume to catalog.
   typeless result = show('-modal _dscatalog_form');
   if (result=='') return;

   // Catalog data set.
   mou_hour_glass(1);
   _str dsname = DATASET_ROOT:+_param1;
   message("Cataloging "dsname" ...");
   typeless status = _os390CatalogDS(dsname, _param2);
   clear_message();
   mou_hour_glass(0);
   if (status) {
      _message_box(nls("Can't catalog %s.\nReason: %s",dsname,get_message(status)));
      return;
   } else {
      _message_box(nls("%s cataloged.",dsname));
   }
   doRefresh();
}
void ctlcatalog.lbutton_up()
{
   doCatalog();
}
void ctluncatalog.lbutton_up()
{
   execute('datasetutilop uncatalog');
}
void ctlfree.lbutton_up()
{
   execute('datasetutilop free');
}
static void doRefresh()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;
   formid.refreshList();
}
void ctlRefresh.lbutton_up()
{
   doRefresh();
}
static void doDetailedInfo()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   int list_wid=formid.get_listwid();
   if (!list_wid.p_Noflines || !list_wid.p_Nofselected) {
      _beep();
      return;
   }

   int viewingdslist = 1;
   int list2 = formid._find_control("ctllist2");
   if (list_wid == list2) viewingdslist = 0;
   if (!viewingdslist) {
      _message_box("Can't query info on PDS members.\nOnly data set is supported.");
      return;
   }

   typeless p;
   list_wid._save_pos2(p);
   int status=list_wid._lbfind_selected(1);
   _str dslist[];
   dslist._makeempty();
   int i = 0;
   for (;;) {
      if (status) break;
      _str filename=formid.get_filename();
      dslist[i] = filename;
      i++;
      status=list_wid._lbfind_selected(0);
   }
   list_wid._restore_pos2(p);
   typeless result = show('-modal -xy _dsinfo_form',dslist);
}
void ctlinfo.lbutton_up()
{
   doDetailedInfo();
}
static void doRegister()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;
   int list_wid=formid.get_listwid();

   // Check for PDS member list.
   int viewingdslist = 1;
   int list2 = formid._find_control("ctllist2");
   if (list_wid == list2) viewingdslist = 0;
   if (!viewingdslist) {
      _message_box("Can't register PDS members.\nOnly data sets can be registered from here.");
      return;
   }

   // Get a list of selected data sets.
   _str dsListText = "";
   typeless p;
   list_wid._save_pos2(p);
   int status=list_wid._lbfind_selected(1);
   for (;;) {
      if (status) break;
      _str filename=formid.get_filename();
      if (dsListText != "") dsListText = dsListText :+ " ";
      dsListText = dsListText :+ filename;
      status=list_wid._lbfind_selected(0);
   }
   list_wid._restore_pos2(p);

   // Show the register data set dialog.
   show('-modal _datasets_form', dsListText);
}
void ctlRegister.lbutton_up()
{
   doRegister();
}
static void updateButtons(boolean pdsListing)
{
   boolean state = pdsListing ? false:true;
   ctlallocate.p_enabled = state;
   ctlcompress.p_enabled = state;
   ctlcatalog.p_enabled = state;
   ctluncatalog.p_enabled = state;
   ctlfree.p_enabled = state;
   ctlinfo.p_enabled = state;
   ctlRegister.p_enabled = state;
}
static void doDelete()
{
   // Locate the form.
   int formid = _find_object("_datasetutil_form","N");
   if (!formid) return;

   int list_wid=formid.get_listwid();
   if (!list_wid.p_Noflines || !list_wid.p_Nofselected) {
      _beep();
      return;
   }

   // Determine which list is currently visible, the
   // data set list or the PDS member list.
   boolean deletingMembers = false;
   int list2 = formid._find_control("ctllist2");
   if (list_wid == list2) deletingMembers = true;

   // Build a list of data sets or PDS members to be deleted.
   _str dslist[];
   int fileCount = 0;
   typeless p;
   list_wid._save_pos2(p);
   int status = list_wid._lbfind_selected(1);
   dslist._makeempty();
   for (;;) {
      if (status) break;
      _str filename=formid.get_filename();
      dslist[fileCount] = filename;
      fileCount++;
      status = list_wid._lbfind_selected(0);
   }
   list_wid._restore_pos2(p);
   if (!fileCount) return;

   // Prompt for user confirmation.
   int answer;
   if (fileCount == 1) {
      answer = _message_box(nls("About to delete %s.\n\nContinue?"
                                ,dslist[0])
                            ,"",MB_YESNOCANCEL);
   } else {
      answer = _message_box(nls("About to delete %s %s.\n\nContinue?"
                                ,fileCount
                                ,deletingMembers ? "members":"data sets"
                                )
                            ,"",MB_YESNOCANCEL);
   }
   if (answer != IDYES) return;

   // For deleting a list of members, use JCL and TSO DELETE
   // command.
   int i;
   _str dsname;
   int delCount = 0;
   if (deletingMembers) {
#if __TESTS390__
      for (i=0; i<fileCount; i++) {
         status = _l390DeletePDSMember(dslist[i]);
         if (status) {
            answer = _message_box(nls("Can't delete '%s'.\nReason: %s\n\nContinue?",dslist[i],get_message(status))
                                  ,""
                                  ,MB_YESNO
                                  );
            if (answer != IDYES) break;
            continue;
         }
      }
      doRefresh();
#else
      status = dsuDeletePDSMembers(dslist);
#endif
      return;
   }

   // For deleting data sets, use SlickEdit interface.
   int openedCount;
   for (i=0; i<fileCount; i++) {
      // If deleting a PDS, make sure that no member is opened for read/write.
      dsname = dslist[i];
      if (isMemberOpenedForRW(dsname, openedCount)) {
         _message_box(nls("Can't delete %s.\n%s %s opened for read/write.\nPlease close %s and retry."
                          ,dsname
                          ,openedCount
                          ,(openedCount > 1) ? "members are":"member is"
                          ,(openedCount > 1) ? "those buffers":"the buffer"
                          )
                      );
         return;
      }
      mou_hour_glass(1);
      message("Deleting "dsname" ...");
      status = _os390DeleteDS(dsname);
      clear_message();
      mou_hour_glass(0);
      if (status) {
         answer = _message_box(nls("Can't delete '%s'.\nReason: %s\n\nContinue?",dsname,get_message(status))
                               ,""
                               ,MB_YESNO
                               );
         if (answer != IDYES) return;
         continue;
      }
      delCount++;
   }
   if (delCount) {
      _message_box(nls("%s deleted.",(delCount>1) ? "Data sets":"Data set"));
   }
   doRefresh();
}


//---------------------------------------------------------------
defeventtab _jobcard_form;

void ctlOK.on_create()
{
   _str line[];
   line._makeempty();
   dsuGetJobStatement(line);
   ctlStatement0.p_text = line[0];
   ctlStatement1.p_text = line[1];
   ctlStatement2.p_text = line[2];
   ctlStatement3.p_text = line[3];
}
int ctlOK.lbutton_up()
{
   // Access the job statement lines.
   _str line0 = ctlStatement0.p_text;
   _str line1 = ctlStatement1.p_text;
   _str line2 = ctlStatement2.p_text;
   _str line3 = ctlStatement3.p_text;

   // Create temp view to hold the statement.
   int oldViewID;
   int viewID;
   oldViewID = _create_temp_view(viewID);
   if (oldViewID == "") {
      _message_box(nls("Can't update user configuration.\n\nReason: Insufficient memory"));
      return(INSUFFICIENT_MEMORY_RC);
   }

   // Insert the job statement.
   insert_line(line0);
   insert_line(line1);
   insert_line(line2);
   insert_line(line3);
   activate_window(oldViewID);

   // Build path to user config file.
   // If user does not a local config file, make the user a personal
   // copy starting with the content of the global config file.
   _str filename;
   _str filenopath;
   _str section = "JobStatement";
   filenopath = _INI_FILE;
   filename = _ConfigPath():+filenopath;
   if (!file_exists(filename)) {
      _str global_filename = get_env("VSLICKBIN1"):+_INI_FILE;
      copy_file(global_filename, filename);
   }

   // Replace the section.
   typeless status = _ini_put_section(filename, section, viewID);
   if (status) {
      _message_box(nls("Unable to update user configuration %s.\n\nReason:%s",filename,get_message(status)));
      return(status);
   }
   p_active_form._delete_window(1);
   return(0);
}
int ctlCancel.lbutton_up()
{
   p_active_form._delete_window(1);
   return(0);
}
void ctlStatement0.on_change()
{
   // Prevent recursion.
   int noRecurse = 0;
   if (p_user != "") noRecurse = (int)p_user;
   if (noRecurse) return;

   // Check the text length
   _str text = p_text;
   if (length(text) > 72) {
      _beep();
      p_user = 1; // flag this to prevent infinite recursion
      p_text = substr(text, 1, 72);
      p_user = 0; // clear flag
      _set_sel(73); // reposition text cursor
   }
}
void _jobcard_form.on_resize()
{
   int form_width = p_active_form.p_client_width*_twips_per_pixel_x();
   int form_height = p_active_form.p_client_height*_twips_per_pixel_y();

   // New widths.
   int newW = form_width - 2*ctlStatement0.p_x;
   ctlStatement0.p_width = newW;
   ctlStatement1.p_width = newW;
   ctlStatement2.p_width = newW;
   ctlStatement3.p_width = newW;
}
