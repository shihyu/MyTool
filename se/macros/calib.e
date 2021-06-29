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
#import "fileman.e"
#import "files.e"
#import "help.e"
#import "listbox.e"
#import "main.e"
#import "put.e"
#import "saveload.e"
#import "stdprocs.e"
#import "ini.e"
#import "cfg.e"
#endregion

/**
 * Encapsulates CA-LIBRARIAN info needed to do all its operations.
 */
struct CALIBInfo
{
   _str dsname; // source/dest data set name
   _str member; // source/dest PDS member
   _str libmaster; // LIBRARIAN master file
   _str libmember; // LIBRARIAN master file member
   _str archive; // checkout archive level
   _str password; // member password
   _str sequence; // sequence
   _str misc; // addition options
   _str mcd; // management code
   _str language; // source language
   _str programmer; // programmer name
   _str desc; // add/checkin description
   _str history[]; // history
   bool genJCLOnly; // Flag: true to generate JCL only and not submit
   bool waitForCompletion; // Flag: true to wait for JCL to complete
};

/**
 * Extract parts of a line before and after the specified key.
 *
 * @param line   line
 * @param key    key to match in line
 * @param p1     returning part before key
 * @param p2     returning part after key
 */
static void extractParts(_str line, _str key, _str & p1, _str & p2)
{
   p := pos(key,line);
   if (!p) {
      p1 = line;
      p2 = "";
      return;
   }
   p1 = substr(line, 1, p-1);
   if (p+length(key) >= length(line)) {
      p2 = "";
   } else {
      p2 = substr(line, p+length(key));
   }
}

/**
 * Parse the JCL template and substitute values.
 *
 * @param tmpJCL JCL file
 * @param info   CA-LIBRARIAN info
 * @param prefix returning job prefix. This the jobname from the JCL job statement
 * @return 0 OK, !0 error
 */
static int parseTemplate(_str tmpJCL, CALIBInfo info, _str & jobname)
{
   // Read the JCL file.
   int temp_view_id, orig_view_id;
   typeless status = _open_temp_view(tmpJCL, temp_view_id, orig_view_id);
   if (status) {
      _message_box(nls("Can't read template JCL file.",tmpJCL));
      return(1); // empty file
   }
   jobname = "";

   // Go thru the template JCL and substitute CA-LIBRARIAN params.
   int p;
   _str line, p1, p2, newtext;
   jobnameFound := false;
   top();
   while (1) {
      get_line(line);
      deleteLine := false;
      skipLine := false;
      while (1) {
         // Scan for jobname to be returned as the SDSF prefix.
         if (!jobnameFound && substr(line,1,2) == "//" && pos(" JOB ",line)) {
            p = pos(" JOB ",line);
            jobname = substr(line,3,p-3);
            jobname = strip(jobname);
            jobnameFound = true;
         }

         // Parse in the params.
         if (pos("%LIBMASTER",line)) {
            extractParts(line,"%LIBMASTER",p1,p2);
            line = p1 :+ info.libmaster :+ p2;
            continue;
         } else if (pos("%LIBMEMBER",line)) {
            extractParts(line,"%LIBMEMBER",p1,p2);
            line = p1 :+ info.libmember :+ p2;
            continue;
         } else if (pos("%OPTIONS",line)) {
            // Separate the parts.
            extractParts(line,"%OPTIONS",p1,p2);

            // Build the text to be inserted.
            newtext = "";
            if (info.password != "") {
               if (newtext != "") newtext :+= ",";
               newtext :+= "PSWD="info.password;
            }
            if (info.archive != "") {
               if (newtext != "") newtext :+= ",";
               newtext :+= "ARC="info.archive;
            }
            if (info.sequence != "") {
               if (newtext != "") newtext :+= ",";
               newtext :+= "SEQ="info.sequence;
            }
            if (info.misc != "") {
               if (newtext != "") newtext :+= ",";
               newtext :+= info.misc;
            }

            // Merge text, if any, into line.
            if (newtext != "") {
               line = p1 :+ newtext :+ p2;
            } else {
               // Since there was no options, try to remove the
               // preceeding ',' in the first part.
               // Example:
               //    "-ADD MEMBER,CCOPY,%ADDOPTS,NOVAR"
               //    where p1 is "-ADD MEMBER,CCOPY," and p2 is ",NOVAR"
               // We want the resulting line to be
               //    "-ADD MEMBER,CCOPY,NOVAR" and not "-ADD MEMBER,CCOPY,,NOVAR"
               if (_last_char(p1) == ',') {
                  p1 = substr(p1,1,length(p1)-1);
               } else if (substr(p2,1,1) == ',') {
                  p2 = substr(p2,2);
               }
               line = p1 :+ p2;
            }
            continue;
         } else if (pos("%DSNAME",line)) {
            extractParts(line,"%DSNAME",p1,p2);
            line = p1 :+ info.dsname :+ p2;
            continue;
         } else if (pos("%MEMBER",line)) {
            extractParts(line,"%MEMBER",p1,p2);
            line = p1 :+ info.member :+ p2;
            continue;
         } else if (pos("%MGMTCODE",line)) {
            if (info.mcd == "") {
               deleteLine = true;
            } else {
               line = "-MCD ":+info.mcd;
            }
            // -MCD stands alone on its own line...
         } else if (pos("%LANGUAGE",line)) {
            if (info.language == "") {
               deleteLine = true;
            } else {
               line = "-LANG ":+info.language;
            }
            // -LANG standa alone on its own line...
         } else if (pos("%PROGRAMMER",line)) {
            if (info.programmer == "") {
               deleteLine = true;
            } else {
               line = "-PGMR ":+info.programmer;
            }
            // -PMGR stands alone on its own line...
         } else if (pos("%DESCRIPTION",line)) {
            if (info.desc == "") {
               deleteLine = true;
            } else {
               line = "-DESC ":+info.desc;
            }
            // -DESC stands alone on its own line...
         } else if (pos("%HISTORY",line)) {
            if (!info.history._length()) {
               deleteLine = true;
            } else {
               _delete_line();
               up();
               for (i:=0; i<info.history._length(); i++) {
                  insert_line("-HST "info.history[i]);
               }
               skipLine = true;
            }
         } else if (pos("%DATARECORDS",line)) {
            // Set a special marker to indicate the end of the inserted file.
            replace_line("%%%%%%%SPECIALMARKER%%%%%%%");
            up();

            // Get the source data set.
            dsname :=  "//"info.dsname;
            if (info.member != "") dsname :+= "/"info.member;
            status = get(dsname);
            if (status) {
               if (status == NEW_FILE_RC) status = FILE_NOT_FOUND_RC;
               _message_box(nls("Can't read data set %s into JCL.\nReason:\n   %s",dsname,get_message(status)));
               activate_window(orig_view_id);
               _delete_temp_view(temp_view_id);
               return(3);
            }

            // Loop to skip to the marker and delete the marker.
            while (!down()) {
               get_line(line);
               line = strip(line,'T',' ');
               if (line == "%%%%%%%SPECIALMARKER%%%%%%%") {
                  _delete_line();
                  up();
                  insert_line("-END");
                  break;
               }
               replace_line(line);
            }
            skipLine = true;
         } else if (pos("%JOBSTATEMENT",line)) {
            // Get the current job statement.
            _str jobStatement[];
            jobStatement._makeempty();
            cardDefined := dsuGetJobStatement(jobStatement);
            if (!cardDefined) {
               _message_box(nls("Job statement has not been defined."));
               activate_window(orig_view_id);
               _delete_temp_view(temp_view_id);
               return(4);
            }

            // Insert job statement lines.
            replace_line(jobStatement[0]);
            insert_line(jobStatement[1]);
            insert_line(jobStatement[2]);
            insert_line(jobStatement[3]);
            up();
            up();
            up();

            // Continue... May need to parse JOB...
            get_line(line);
            continue;
         }

         // Verify line length.
         line = strip(line, 'T', ' ');
         if (length(line) > 72) {
            // Line length exceeded
            _message_box(nls("Parsed JCL line exceeded 72 characters. Line:\n%s",line));
            activate_window(orig_view_id);
            _delete_temp_view(temp_view_id);
            return(2);
         }

         // Done with this line. Try next one.
         break;
      }

      // Delete, replace, or skip line.
      if (deleteLine) {
         _delete_line();
      } else if (!skipLine) {
         replace_line(line);
         if (down()) break;
      }
   }

   // Udpate the JCL file.
   status = save_file(tmpJCL,"+o");
   if (status) {
      _message_box(nls("Can't update parsed JCL %s.\n\nReason:\n",tmpJCL,get_message(status)));
      activate_window(orig_view_id);
      _delete_temp_view(temp_view_id);
      return(5);
   }
   activate_window(orig_view_id);
   _delete_temp_view(temp_view_id);
   return(0);
}

//---------------------------------------------------------------
/**
 * Get the current job statement defined by the user.
 *
 * @param line   returning 4 lines of the job statement
 * @return Flag: true if statement previously defined, false if statement not defined
 */
bool dsuGetJobStatement(_str (&line)[])
{
   statementDefined:=false;
   value:=_plugin_get_property(VSCFGPACKAGE_MISC,VSCFGPROFILE_OPTIONS,'job_statement');
   if (value=='') {
      line[0] = "//USERID   JOB  (ACCOUNT),'NAME',MSGCLASS=X";
      line[1] = "//*";
      line[2] = "//*";
      line[3] = "//*";
      statementDefined=false;
   } else {
      statementDefined=true;
      line._makeempty();
      for (;;) {
         if (value=='') break;
         parse value with auto item "\n" value;
         if (item!='') {
            line[line._length()]=item;
         }
      }
   }
   return(statementDefined);
}

static int calib_op(_str op, _str arg1, int maxTimeOut, _str prefix, _str owner, _str queue)
{
   // Determine the source data set, if there is one.
   // If one is specified on the command line, use it.
   // If active edit window is available, use its file.
   sourceJCL := "";
   sourceds := "";
   lang := "";
   timeOutText := "";
   prefixText := "";
   ownerText := "";
   queueText := "";
   if (arg1 != "") {
      parse arg1 with sourceJCL sourceds timeOutText prefixText ownerText queueText;
      sourceds = strip(sourceds, 'B', '"');
      sourceds = strip(sourceds, 'B', "'");
      if (sourceds == "") {
         if (!_no_child_windows()) {
            sourceds = _mdi.p_child.p_buf_name;
            lang = _mdi.p_child.p_LangId;
         }
      }
      if (timeOutText != "" && isinteger(timeOutText)) {
         maxTimeOut = (int)timeOutText;
      }
      if (prefixText != "") prefix = prefixText;
      if (ownerText != "") owner = ownerText;
      if (queueText != "") queue = queueText;
   } else {
      if (!_no_child_windows()) {
         sourceds = _mdi.p_child.p_buf_name;
         lang = _mdi.p_child.p_LangId;
      }
   }
   sourceJCL = strip(sourceJCL, 'B', '"');
   sourceJCL = strip(sourceJCL, 'B', "'");
   if (sourceJCL == "") {
      _message_box(nls("Missing JCL template."));
      return(0);
   }
   sourceJCL = absolute(sourceJCL);
   if (!file_exists(sourceJCL)) {
      _message_box(nls("JCL template %s does not exist.",sourceJCL));
      return(0);
   }

   // Make sure file is a data set. If not, don't default to it.
   if (sourceds != "" && !_DataSetIsFile(sourceds)) {
      sourceds = "";
   }

   // Get more values from the user.
   int status;
   status = show("-modal -xy _calib_add_form", sourceds, lang, op);
   if (status) return(0); // dialog cancelled

   // Access info from dialog.
   CALIBInfo info = _param1;

   // Build the JCL needed to add the data set to CA-LIB.
   // First, copy the template JCL file.
   _str userName;
   _userName(userName);
   tmpJCL :=  "/tmp/"userName".calib.jcl";
   status = copy_file(sourceJCL, tmpJCL);
   if (status) {
      _message_box(nls("Can't copy source JCL file\n%s to %s.\nReason:\n   %s",sourceJCL,tmpJCL,get_message(status)));
      return(0);
   }
   chmod("u+r+w "tmpJCL);

   // Parse the JCL template
   _str jobname;
   status = parseTemplate(tmpJCL, info, jobname);
   if (status) {
      delete_file(tmpJCL);
      return(0);
   }

   // If a prefix is not specified on the command line or in
   // the arguments, use the jobname from the JCL.
   if (prefix == "") prefix = jobname;
   if (_last_char(prefix) != '*' && length(prefix) < 8) prefix = prefix"*";
   if (prefix == "") prefix = "*";

   // If owner is not specified, use the logname.
   if (owner == "") owner = userName;
   if (owner == "") owner = "*";

   // Submit the job and wait for it to complete.
   int waitForCompletion = info.waitForCompletion?1:0;
   owner = upcase(owner);
   pgm := get_env("VSLICKBIN1"):+"sdsfcmd.rexx";
   _str cmdArgs = 'SUBMITHFS "'prefix'" 'owner' 'queue' 'tmpJCL' 'waitForCompletion' 'maxTimeOut;

   // If only need to generate JCL, done.
   if (info.genJCLOnly) {
      edit(tmpJCL);
      _message_box(nls("Submit command:\n\n%s %s",pgm,cmdArgs));
      return(0);
   }
   say("Submitting "pgm" "cmdArgs);
   status = 0;
   if (status) {
      _message_box(nls("Can't submit job.\nReason:\n   %s",get_message(status)));
      delete_file(tmpJCL);
      return(0);
   }

   // Clean up.
   delete_file(tmpJCL);
   return(0);
}

/**
 * Add a data set or a PDS member into a CA-LIBRARIAN master file.<BR>
 * USAGE:<BR>
 *    calib_add libadd.jcl [//SOURCE.DS.NAME [maxTimeOut [prefix [owner [queue]]]]]<BR>
 * <UL>
 *          <LI>libadd.jcl     -- CA-LIBRARIAN job template to do add
 *          <LI>SOURCE.DS.NAME -- source data set
 *          <LI>maxTimeOut     -- max time out waiting for job to complete (seconds)
 *          <LI>prefix         -- prefix used in SDSF to locate job output
 *          <LI>owner          -- owner used in SDSF to locate job output
 *          <LI>queue          -- SDSF queue to look for job output: 'O'
 * </UL>
 * <BR>
 *    If these arguments are specified in both arg1 and in the command argument
 *    list, the ones in arg1 take precedence.
 *
 * @param arg1       argument if command executed from command line
 * @param maxTimeOut max time out in seconds
 * @param prefix     job prefix used in SDSF
 * @param owner      job owner used in SDSF
 * @param queue      which queue to look for job output: 'O'
 * @return 0 for OK, !0 error
 */
_command calib_add(_str arg1="", int maxTimeOut=120, _str prefix="", _str owner="", _str queue="O") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   calib_op("add", arg1, maxTimeOut, prefix, owner, queue);
}

/**
 * Check-in a data set (or PDS member) that contains a previously
 * checked out LIBRARIAN master file member.<BR>
 * USAGE:<BR>
 *    calib_checkin libcheckin.jcl [//SOURCE.DS.NAME [maxTimeOut [prefix [owner [queue]]]]]<BR>
 * <UL>
 *          <LI>libcheckin.jcl -- CA-LIBRARIAN job template to do check-in
 *          <LI>SOURCE.DS.NAME -- source data set <BR>
 *          <LI>maxTimeOut     -- max time out waiting for job to complete (seconds) <BR>
 *          <LI>prefix         -- prefix used in SDSF to locate job output <BR>
 *          <LI>owner          -- owner used in SDSF to locate job output <BR>
 *          <LI>queue          -- SDSF queue to look for job output: 'O' <BR>
 * </UL>
 * <BR>
 *    If these arguments are specified in both arg1 and in the command argument
 *    list, the ones in arg1 take precedence.
 *
 * @param arg1       argument if command executed from command line
 * @param maxTimeOut max time out in seconds
 * @param prefix     job prefix used in SDSF
 * @param owner      job owner used in SDSF
 * @param queue      which queue to look for job output: 'O'
 * @return 0 for OK, !0 error
 */
_command calib_checkin(_str arg1="", int maxTimeOut=120, _str prefix="", _str owner="", _str queue="O") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   calib_op("checkin", arg1, maxTimeOut, prefix, owner, queue);
}

/**
 * Check-out a LIBRARIAN master file member.<BR>
 * USAGE:<BR>
 *    calib_checkout libcheckout.jcl [//SOURCE.DS.NAME [maxTimeOut [prefix [owner [queue]]]]]<BR>
 * <UL>
 *          <LI>libcheckout.jcl -- CA-LIBRARIAN job template to do check-out
 *          <LI>SOURCE.DS.NAME -- source data set
 *          <LI>maxTimeOut     -- max time out waiting for job to complete (seconds)
 *          <LI>prefix         -- prefix used in SDSF to locate job output
 *          <LI>owner          -- owner used in SDSF to locate job output
 *          <LI>queue          -- SDSF queue to look for job output: 'O'
 * </UL>
 * <BR>
 *    If these arguments are specified in both arg1 and in the command argument
 *    list, the ones in arg1 take precedence.
 *
 * @param arg1       argument if command executed from command line
 * @param maxTimeOut max time out in seconds
 * @param prefix     job prefix used in SDSF
 * @param owner      job owner used in SDSF
 * @param queue      which queue to look for job output: 'O'
 * @return 0 for OK, !0 error
 */
_command calib_checkout(_str arg1="", int maxTimeOut=120, _str prefix="", _str owner="", _str queue="O") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
   calib_op("checkout", arg1, maxTimeOut, prefix, owner, queue);
}

/**
 * Do nothing command
 *
 * @param arg1
 * @param maxTimeOut
 * @param prefix
 * @param owner
 * @param queue
 * @return
 */
_command calib_noop(_str arg1="", int maxTimeOut=120, _str prefix="", _str owner="", _str queue="O") name_info(','VSARG2_REQUIRES_PRO_EDITION)
{
   if (!_haveVersionControl()) {
      popup_nls_message(VSRC_FEATURE_REQUIRES_PRO_EDITION_1ARG, "Version control");
      return VSRC_FEATURE_REQUIRES_PRO_EDITION;
   }
}


defeventtab _calib_add_form;
/**
 * Check and limit the text length.
 *
 * @param maxLength
 * @return Flag: 0 OK, 1 for recurse skipped, 2 for limit exceeded, 3 for illegal character, 4 for empty text
 */
static int checkAndLimit(int maxLength, bool allowSpace=false, bool upcasetext=false)
{
   // Check and prevent recursion.
   skipRecurse := 0;
   if (p_user != "") skipRecurse = (int)p_user;
   if (skipRecurse) return(1);

   // Limit length.
   text := p_text;
   if (text :== "") return(4);
   if (length(text) > maxLength) {
      p_user = 1;
      p_text = substr(text,1,maxLength);
      p_user = 0;
      _beep();
      _set_sel(maxLength+1); // reposition text cursor
      return(2);
   }

   // No spaces.
   if (!allowSpace) {
      int i;
      for (i=1; i<length(text)+1; i++) {
         cc := substr(text,i,1);
         if (cc :== " ") {
            p_user = 1;
            if (i == 1) {
               p_text = "";
            } else {
               p_text = substr(text,1,i-1);
            }
            p_user = 0;
            _beep();
            _set_sel(i); // reposition text cursor
            return(3);
         }
      }
   }

   // Upcase text.
   if (upcasetext) {
      p_user = 1;
      p_text = upcase(text);
      p_user = 0;
   }
   return(0);
}
/**
 * Check specified data set name for valid format.
 *
 * @param dsname
 * @param allowStar
 * @return 0 for valid, !0 not valid
 */
static int checkDSName(_str dsname, bool allowStar=false)
{
   // Total length can not be more than 44 chars, including '.'
   if (length(dsname) > 44) return(1);

   // The first character can not be *.
   if (allowStar && substr(dsname,1,1) == ALLFILES_RE) {
      return(5);
   }

   // Check individual qualifiers.
   hasStar := false;
   last := false;
   start := 1;
   _str qq;
   while (!last) {
      // If a wildcard has been typed, allow no more characters.
      if (allowStar && hasStar) return(5);

      // Extract qualifier.
      p := pos('.', dsname, start);
      if (!p) {
         qq = substr(dsname, start);
         last = true;
      } else {
         qq = substr(dsname, start, p-start);
         start = p+1;
      }
      //say("qq="qq);
      if (length(qq) > 8) return(2);
      if (length(qq) == 0 && last) return(3);
      if (length(qq) == 0) return(6);

      // First char must be A-Z or @#$ (or * for wildcard).
      firstChar := substr(qq, 1, 1);
      if (allowStar && firstChar == ALLFILES_RE) {
         hasStar = true;
      } else if (firstChar != '@' && firstChar != '$' && firstChar != '#'
          && !isalpha(firstChar)) {
         return(4);
      }

      // Subsequent chars must be A-Z0-9 or @#$- (or * for wildcard).
      int i;
      for (i=2; i<=length(qq); i++) {
         cc := substr(qq, i, 1);
         if (allowStar) {
            if (hasStar) return(5);
            if (cc == ALLFILES_RE) {
               if (i == length(qq)) {
                  hasStar = true;
                  break;
               }
               return(5);
            }
         }
         if (cc != '@' && cc != '$' && cc != '#' && cc != '-'
             && !isdigit(cc)
             && !isalpha(cc)) {
            return(5);
         }
      }
   }
   return(0);
}
/**
 * Check specified PDS member for valid format.
 *
 * @param text
 * @return 0 for valid, !0 not valid
 */
static int checkPDSMember(_str text)
{
   // Total length must be less than 8.
   if (length(text) > 8) return(1);

   // First char must be A-Z,@,$,#
   firstChar := substr(text, 1, 1);
   if (!isalpha(firstChar)
       && firstChar != '@'
       && firstChar != '$'
       && firstChar != '#') return(4);

   // Subsequent chars must be A-Z0-9,@,$,#
   int i;
   for (i=2; i<=length(text); i++) {
      cc := substr(text, i, 1);
      if (!isdigit(cc) && !isalpha(cc)
          && firstChar != '@'
          && firstChar != '$'
          && firstChar != '#') return(5);
   }
   return(0);
}
/**
 * Take a data set name in the formats:
 *    //ds.name
 *    //pds.name/member
 *    ds.name
 *    pds.name(member)
 *
 * and separate the name part from the member part.
 *
 * @param dsname
 * @param member
 */
static void reformatDSName(_str & dsname, _str & member)
{
   // Strip leading //
   _str name = dsname;
   member = "";
   if (substr(name,1,2) == "//") {
      name = substr(name,3);
   }

   // Locate member name, if there is one.
   p := pos("/",name);
   if (!p) p = pos("(",name);
   if (p) {
      member = upcase(substr(name,p+1));
      _maybe_strip(member, ')');
      name = substr(name,1,p-1);
   }
   dsname = upcase(name);

   // Verify valid name and member
   if (dsname != "" && checkDSName(dsname)) {
      dsname = "";
      member = "";
   }
   if (member != "" && checkPDSMember(member)) {
      dsname = "";
      member = "";
   }
}
static _str mapExtToLang(_str ext)
{
   uext := upcase(ext);
   if (uext == "ASM390") {
      return("ASM");
   }
   return(upcase(ext));
}
void ctlOK.on_create(_str sourceds="", _str lang="", _str mode="add")
{
   // Correct title.
   if (mode == "add") {
      p_active_form.p_caption = "CA-LIBRARIAN: Add Member";
   } else if (mode == "checkin") {
      p_active_form.p_caption = "CA-LIBRARIAN: Check-In";
   } else {
      p_active_form.p_caption = "CA-LIBRARIAN: Check-Out";
      ctlSourceDSLabel.p_caption = "De&st DS:";
   }

   // Fill in source data set or PDS member.
   sourceds = upcase(sourceds);
   if (sourceds != "") {
      ctlSourceDS.p_text = sourceds;
   } else {
      ctlSourceDS.p_text = "";
   }

   // Restore the source DS combo list.
   ctlSourceDS._retrieve_list();

   // Restore the master file combo list.
   ctlMaster._retrieve_list();
   ctlMaster._retrieve_value();

   // If the source data set name has a member compoment, use
   // it to fill in the member box.
   dsname := ctlSourceDS.p_text;
   if (dsname != "") {
      member := "";
      reformatDSName(dsname, member);
      if (member != "") {
         ctlMember.p_text = member;
      }
   }

   // Fill in default language combo list.
   if (lang != "") {
      ctlLanguage.p_text = mapExtToLang(lang);
   } else {
      _str oldText = _retrieve_value("_calib_add_form.lang");
      if (oldText != "") {
         ctlLanguage.p_text = oldText;
      }
   }
   int listWid = ctlLanguage.p_window_id;
   listWid._lbadd_item("ASM");
   listWid._lbadd_item("BAS");
   listWid._lbadd_item("CMD");
   listWid._lbadd_item("JCL");
   listWid._lbadd_item("COB");
   listWid._lbadd_item("DAT");
   listWid._lbadd_item("FOR");
   listWid._lbadd_item("FRG");
   listWid._lbadd_item("FRH");
   listWid._lbadd_item("GIS");
   listWid._lbadd_item("GOF");
   listWid._lbadd_item("MAC");
   listWid._lbadd_item("PLI");
   listWid._lbadd_item("RPG");
   listWid._lbadd_item("TXT");
   listWid._lbadd_item("VSB");
   ctlLanguage.p_enabled = (mode=="checkout")?false:true;

   // Restore last known programmer name.
   if (mode != "s") ctlProgrammer._retrieve_value();
   ctlProgrammer.p_enabled = (mode=="checkout")?false:true;

   // Add and Rep does not support Archive.
   ctlArchive.p_enabled = (mode=="checkout")?true:false;

   // Set the date
   _str today = _date();
   start := 1;
   month := substr(today, start, pos("/",today,1) - start);
   start = length(month) + 2;
   day := substr(today, start, pos("/", today, start) - start);
   if (length(month) < 2) month = "0"month;
   if (length(day) < 2) day = "0"day;
   ctlDate.p_caption = month"/"day;

   // Sequence.
   if (mode == "checkout") {
      ctlSeq.p_text = "";
      ctlSeq.p_enabled = false;
   } else {
      ctlSeq._retrieve_value();
   }

   // Generate JCL only.
   ctlGenerateJCLOnly._retrieve_value();

   // Wait for completion.
   ctlWait._retrieve_value();

   // Description.
   if (mode == "checkout") ctlDesc.p_enabled = false;

   // History.
   if (mode == "checkout") ctlHistory.p_enabled = false;
}
void ctlOK.lbutton_up()
{
   CALIBInfo info;

   // Check source data set
   sourceds := ctlSourceDS.p_text;
   sourcemem := "";
   reformatDSName(sourceds, sourcemem);
   if (sourceds == "") {
      _message_box(nls("Invalid source data set name."));
      ctlSourceDS._set_focus();
      return;
   }
   info.dsname = sourceds;
   info.member = sourcemem;

   // Check master file
   libmaster := ctlMaster.p_text;
   libmember := "";
   reformatDSName(libmaster, libmember);
   if (libmaster == "") {
      _message_box(nls("Invalid master file name."));
      ctlMaster._set_focus();
      return;
   }
   info.libmaster = libmaster;

   // If member is specified together with the master file,
   // make sure the member text box is not specified.
   if (libmember != "" && ctlMember.p_text != "") {
      _message_box(nls("Please specify member name either with the\nmaster file name or in the member\nbox but not both."));
      ctlMaster._set_focus();
      return;
   }
   if (libmember == "") libmember = ctlMember.p_text;

   // If member if not specified in master file name or the member box,
   // see if member is specified in the source data set and use it.
   if (libmember == "") libmember = sourcemem;
   if (libmember == "") {
      _message_box(nls("Please specify a master file member name."));
      ctlMember._set_focus();
      return;
   }
   info.libmember = libmember;

   // Check archive
   archive := ctlArchive.p_text;
   if (archive != "") {
      fc := substr(archive,1,1);
      if (isdigit(fc)) {
         // For format YYMMDDHHMMSS, length must be multiple of 2.
         if (length(archive) % 2) {
            _message_box(nls("Invalid archive date."));
            ctlArchive._set_focus();
            return;
         }
      }
   }

   // Check MCD. If specified, it must be 4 digits.
   info.mcd = upcase(ctlMCD.p_text);
   if (info.mcd != "" && length(info.mcd) != 4) {
      _message_box(nls("Invalid management code."));
      ctlMCD._set_focus();
      return;
   }

   // Check sequence.
   info.sequence = ctlSeq.p_text;
   cc := substr(info.sequence,1,1);
   if (cc == '/') {
      int p;
      sPart := lPart := iPart := vPart := "";
      start := 2;
      p = pos(',',info.sequence,start);
      if (p) {
         sPart = substr(info.sequence,start,p-start);
         start = p + 1;
         p = pos(',',info.sequence,start);
         if (p) {
            lPart = substr(info.sequence,start,p-start);
            start = p + 1;
            p = pos(',',info.sequence,start);
            if (p) {
               iPart = substr(info.sequence,start,p-start);
               vPart = substr(info.sequence, p+1);
               _maybe_strip(vPart, '/');
            } else {
               iPart = substr(info.sequence,start);
            }
         }
      }
      if (sPart == "" || lPart == "" || iPart == "") {
         _message_box(nls("Invalid sequence."));
         ctlSeq._set_focus();
         return;
      }
      if (!isinteger(sPart) || !isinteger(lPart) || !isinteger(iPart) || (vPart != "" && !isinteger(vPart))) {
         _message_box(nls("Invalid sequence."));
         ctlSeq._set_focus();
         return;
      }
      info.sequence = "/";
      info.sequence = info.sequence :+ sPart","lPart","iPart;
      if (vPart != "") info.sequence = info.sequence","vPart;
      _maybe_append(info.sequence, '/');
   } else if (info.sequence != "" && info.sequence != "COBOL") {
      _message_box(nls("Invalid sequence."));
      ctlSeq._set_focus();
      return;
   }

   // Others.
   info.misc = ctlMisc.p_text;
   info.archive = archive;
   info.password = ctlPassword.p_text;
   info.programmer = ctlProgrammer.p_text;
   info.language = upcase(ctlLanguage.p_text);
   info.desc = ctlDesc.p_text;

   // Reformat the history text into lines of max 75 characters
   _str line;
   info.history._makeempty();
   i := count := 0;
   ctlHistory.p_line = 1;
   for (i=0; i<ctlHistory.p_noflines; i++) {
      ctlHistory.get_line(line);
      line = strip(line);
      if (line == "") {
         ctlHistory.p_line = ctlHistory.p_line + 1;
         continue;
      }

      // Add short line to list.
      if (length(line) <= 75) {
         info.history[count] = line;
         count++;
         ctlHistory.p_line = ctlHistory.p_line + 1;
         continue;
      }

      // If line is longer than 75 characters, break line at the
      // space closest to the 75th position.
      _str subline;
      start := 1;
      lastSpace := 0;
      while (1) {
         p := pos(" ",line,start);
         if (!p || p > 75) {
            if (!lastSpace) {
               _message_box(nls("One or more history line is too long\nand is unbreakable.\n\nPlease shorten the line(s) to 75 characters."));
               ctlHistory._set_focus();
               return;
            }

            // Break the line at the last space.
            subline = substr(line,1,lastSpace-1);
            line = substr(line,lastSpace+1);
            info.history[count] = subline;
            count++;
            start = 1;

            // If the remaining can fit, done.
            if (length(line) <= 75) {
               info.history[count] = line;
               count++;
               break;
            }
         }
         lastSpace = p;
         start = p + 1;
      }

      // Next line
      ctlHistory.p_line = ctlHistory.p_line + 1;
   }

   // Generate JCL only.
   info.genJCLOnly = ctlGenerateJCLOnly.p_value?true:false;

   // Wait for completion
   info.waitForCompletion = ctlWait.p_value?true:false;

   // Pass data back
   /*say("sourceds="info.dsname);
   say("sourcemem="info.member);
   say("libmaster="info.libmaster);
   say("libmember="info.libmember);
   say("password="info.password);
   say("archive="info.archive);
   say("MCD="info.mcd);
   say("Language="info.language);
   say("programmer="info.programmer);
   say("desc="info.desc);
   say("history:");
   for (i=0; i<info.history._length(); i++) {
      say("  "info.history[i]);
   }*/
   _param1 = info;

   // Save the dialog values
   _append_retrieve(ctlSourceDS, ctlSourceDS.p_text);
   _append_retrieve(ctlMaster, ctlMaster.p_text);
   _append_retrieve(0, ctlLanguage.p_text, "_calib_add_form.lang");
   _append_retrieve(ctlProgrammer, ctlProgrammer.p_text);
   _append_retrieve(ctlSeq, ctlSeq.p_text);
   _append_retrieve(ctlGenerateJCLOnly, ctlGenerateJCLOnly.p_value);
   _append_retrieve(ctlWait, ctlWait.p_value);
   p_active_form._delete_window(0);
}
void ctlCancel.lbutton_up()
{
   p_active_form._delete_window(1);
}
void ctlMCD.on_change()
{
   if (checkAndLimit(4)) return;

   // Allow only digits.
   text := p_text;
   int i;
   for (i=1; i<length(text)+1; i++) {
      cc := substr(text,i,1);
      if (!isdigit(cc)) {
         p_user = 1;
         if (i == 1) {
            p_text = "";
         } else {
            p_text = substr(text,1,i-1);
         }
         p_user = 0;
         _beep();
         _set_sel(i); // reposition text cursor
         return;
      }
   }
}
void ctlMember.on_change()
{
   if (checkAndLimit(8,false,true)) return;

   // First char must be A-Z,@,$,#
   text := p_text;
   firstChar := substr(text, 1, 1);
   if (!isalpha(firstChar)
       && firstChar != '@'
       && firstChar != '$'
       && firstChar != '#') {
      p_user = 1;
      p_text = "";
      p_user = 0;
      _beep();
      _set_sel(1); // reposition text cursor
      return;
   }

   // Subsequent chars must be A-Z0-9,@,$,#
   int i;
   for (i=2; i<=length(text); i++) {
      cc := substr(text, i, 1);
      if (!isdigit(cc) && !isalpha(cc)
          && firstChar != '@'
          && firstChar != '$'
          && firstChar != '#') {
         p_user = 1;
         p_text = substr(text,1,i-1);
         p_user = 0;
         _beep();
         _set_sel(i); // reposition text cursor
         return;
      }
   }
}
void ctlPassword.on_change()
{
   checkAndLimit(4,false,true);
}
void ctlProgrammer.on_change()
{
   checkAndLimit(15,false,true);
}
void ctlArchive.on_change()
{
   if (checkAndLimit(12)) return;

   // From the first character, determine which format.
   text := p_text;
   fc := substr(text,1,1);
   maxLength := 0;

   // Must be Lx format, where x is 0,1,2,3,4
   if (upcase(fc) == 'L') {
      if (length(text) < 2) {
         p_user = 1;
         p_text = upcase(text);
         p_user = 0;
         return;
      }
      x := substr(text,2,1);
      if (x < '0' || x > '4') {
         p_user = 1;
         p_text = "L";
         p_user = 0;
         _beep();
         _set_sel(2); // reposition text cursor
         return;
      }
      maxLength = 2;
      if (length(text) > maxLength) {
         p_user = 1;
         p_text = substr(text,1,maxLength);
         p_user = 0;
         _beep();
         _set_sel(maxLength+1); // reposition text cursor
         return;
      }
      return;
   }

   // Must be format -y
   if (fc == '-') {
      if (length(text) < 2) return;
      y := substr(text,2,1);
      if (y < '0' || y > '4') {
         p_user = 1;
         p_text = "-";
         p_user = 0;
         _beep();
         _set_sel(2); // reposition text cursor
         return;
      }
      maxLength = 2;
      if (length(text) > maxLength) {
         p_user = 1;
         p_text = substr(text,1,maxLength);
         p_user = 0;
         _beep();
         _set_sel(maxLength+1); // reposition text cursor
         return;
      }
      return;
   }

   // Must be format YYMMDDHHMMSS.
   // Allow only digits.
   int i;
   for (i=1; i<length(text)+1; i++) {
      cc := substr(text,i,1);
      if (!isdigit(cc)) {
         p_user = 1;
         if (i == 1) {
            p_text = "";
         } else {
            p_text = substr(text,1,i-1);
         }
         p_user = 0;
         _beep();
         _set_sel(i); // reposition text cursor
         return;
      }
   }
}
void ctlDesc.on_change()
{
   checkAndLimit(30, true);
}
void ctlSourceDS.on_change(int reason)
{
   if (checkAndLimit(9999,false,true)) return;
}
void ctlSeq.on_change()
{
   checkAndLimit(32,false,true);
}
