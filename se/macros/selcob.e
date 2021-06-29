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
#import "c.e"
#import "main.e"
#import "seek.e"
#import "stdcmds.e"
#endregion


/**
 * Table of COBOL verbs. The hash value has the following format:
 *
 *    matchingEndVerb,canNest,imperativeStatementLeadKeywords,
 *
 * where matchingEndVerb is the matching end-verb,
 *       canNest is 1 for statement can be nested
 *       imperativeStatementLeadKeywords are words indicating an imperative (sub)statement in the statement. Words are separated by colon (:).
 */
static _str verbList:[]=
{
   "ACCEPT" => ",,," // only VAX COBOL has "END-ACCEPT". Not supported!
   ,"ADD" => "END-ADD,,ERROR,"
   ,"ALTER" => ",,,"
   ,"CALL" => "END-CALL,,EXCEPTION:OVERFLOW,"
   ,"CANCEL" => ",,,"
   ,"CLOSE" => ",,,"
   //,"COMMIT" => "END-COMMIT,,ERROR," // VAX COBOL. Not supported!
   ,"COMPUTE" => "END-COMPUTE,,ERROR,"
   ,"CONNECT" => "END-CONNECT,,ERROR,"
   ,"CONTINUE" => ",,,"
   ,"COPY" => ",,,"
   ,"DELETE" => "END-DELETE,,INVALID,"
   ,"DISABLE" => ",,,"
   //,"DISCONNECT" => "END-DISCONNECT,,ERROR," // VAX COBOL. Not supported!
   ,"DISPLAY" => ",,,"
   ,"DIVIDE" => "END-DIVIDE,,ERROR,"
   ,"ENABLE" => ",,,"
   ,"ENTRY" => ",,,"
   //,"ERASE" => "END-ERASE,,," // VAX COBOL. Not supported!
   ,"EVALUATE" => "END-EVALUATE,,WHEN,"
   ,"EXEC" => "END-EXEC,,,"
   //,"FETCH" => "END-FETCH,,END:ERROR," // VAX COBOL. Not supported!
   //,"FIND" => "END-FIND,,END:ERROR," // VAX COBOL. Not supported!
   //,"FREE" => "END-FREE,,ERROR," // VAX COBOL. Not supported!
   ,"GENERATE" => ",,,"
   //,"GET" => "END-GET,,ERROR," // VAX COBOL. Not supported!
   ,"GOBACK" => ",,,"
   ,"GO" => ",,,"
   ,"IF" => "END-IF,1,,"
   ,"INITIALIZE" => ",,,"
   ,"INITIATE" => ",,,"
   ,"INSPECT" => ",,,"
   //,"KEEP" => "END-KEEP,,ERROR," // VAX COBOL. Not supported!
   ,"MERGE" => ",,,"
   ,"MODIFY" => "END-MODIFY,,ERROR,"
   ,"MOVE" => ",,,"
   ,"MULTIPLY" => "END-MULTIPLY,,ERROR,"
   ,"OPEN" => ",,,"
   ,"PERFORM" => ",,,"
   ,"PURGE" => ",,,"
   ,"READ" => "END-READ,,END:INVALID,"
   ,"READY" => "END-READY,,ERROR,"
   ,"RECEIVE" => "END-RECEIVE,,DATA,"
   //,"RECONNECT" => "END-RECONNECT,,ERROR," // VAX COBOL. Not supported!
   ,"RELEASE" => ",,,"
   ,"RETURN" => "END-RETURN,,END,"
   ,"REWRITE" => "END-REWRITE,,INVALID,"
   //,"ROLLBACK" => "END-ROLLBACK,,ERROR," // VAX COBOL. Not supported!
   ,"SEARCH" => "END-SEARCH,,END:WHEN,"
   ,"SEND" => ",,,"
   ,"SET" => ",,,"
   ,"SORT" => ",,,"
   ,"START" => "END-START,,INVALID,"
   ,"STOP" => ",,,"
   //,"STORE" => "END-STORE,,ERROR," // VAX COBOL. Not supported!
   ,"STRING" => "END-STRING,,OVERFLOW,"
   ,"SUBTRACT" => "END-SUBTRACT,,ERROR,"
   ,"SUPPRESS" => ",,,"
   ,"TERMINATE" => ",,,"
   ,"UNLOCK" => ",,,"
   ,"UNSTRING" => "END-UNSTRING,,OVERFLOW,"
   ,"USE" => ",,,"
   ,"WRITE" => "END-WRITE,,INVALID,"
};

/**
 * Test to see if the specified text is a comment line.
 * COBOL comment has a character in column 7.
 *
 * @return Flag: true for comment line, false otherwise
 */
static bool isCommentLine(_str & line)
{
   if (substr(line, 7, 1) != " ") return(true);
   return(false);
}

/**
 * Check to see if the specified line is an empty line.
 * Columns 1-7 and 73 onward are ignored.
 *
 * @param line   line
 * @return Flag: true for empty line, false not
 */
static bool isEmptyLine(_str & line)
{
   // Line is too short.
   len := length(line);
   if (len <= 7) return(true);

   // First non-space does not exist or it in columns 73 onward.
   firstNonSpace := pos('[~ \t]', line, 1, 'ri');
   if (!firstNonSpace) return(true);
   if (firstNonSpace >= 73) return(true);

   // Line has something in it.
   return(false);
}

/**
 * Check to see if the specified word is a verb.
 *
 * @param word   word
 * @return Flag: true for verb, false not
 */
static bool isVerb(_str & word)
{
   if (!verbList._indexin(upcase(word))) return(false);
   return(true);
}

/**
 * Check to see if the specified word is an end-verb.
 *
 * @param word   word
 * @return Flag: true for end-verb, false otherwise
 */
static bool isEndVerb(_str & word)
{
   // Make sure word begins with "END-"
   if (pos("END-", word) != 1) return(false);

   // Look up the verb.
   verb := substr(word, 5);
   if (!isVerb(verb)) return(false);

   // Found matching verb.
   return(true);
}

/**
 * Get information associated with the specified verb.
 *
 * @param verb    verb
 * @param endVerb returning end-verb
 * @param canNest returning flag: 1 to indicate that verb can nest, 0 for cannot nest
 */
static void verbInfo(_str & verb, _str & endVerb,
                     bool & canNest, _str & imperativeKey)
{
   _str canNestText;
   _str infoText = verbList:[upcase(verb)];
   parse infoText with endVerb','canNestText','imperativeKey',';
   canNest = false;
   if (canNestText == "1") canNest = true;
}

/**
 * Get the verb at the cursor.
 *
 * @param verb    returning verb, "" for none found or word at cursor is not a supported verb
 * @param endVerb returning matching ending verb, if there is one associated with this verb
 * @param canNest returning flag: true for statements can nest, false for cannot
 * @param imperativeKey
 *                returning imperative statement leading key words
 * @return Flag: true for verb found, false for not found
 */
static bool verbUnderCursor(_str & verb,
                               _str & endVerb,
                               bool & canNest,
                               _str & imperativeKey
                               )
{
   // If the line is a comment line, no word.
   _str line;
   cursorCol := p_col;
   get_line(line);
   verb = "";
   if (isCommentLine(line) || isEmptyLine(line)) return(false);
   if (length(line) < cursorCol) return(false);

   // Special case for the cursor at the end of the word. Just
   // move the cursor back one character.
   // 
   // DJB 11-7-2007:  Do not need this any more, SymbolWord()
   //                 can handle the cursor at the end of the
   //                 identifier now.
   // 
   //if (substr(line, cursorCol, 1) == ' ') {
   //   if (cursorCol <= 8) return(false);
   //   p_col = cursorCol - 1;
   //}

   // Get the verb at the cursor and make sure it is one of the
   // supported verbs.
   verb = _SymbolWord();
   if (verb == "") return(false);
   if (!isVerb(verb)) return(false);

   // Parse the info associated with the verb.
   verbInfo(verb, endVerb, canNest, imperativeKey);
   return(true);
}

/**
 * Find the start of the specified line. All characters in
 * columns 1-7 are ignored. Columns 37 onward, if
 * exist, are also ignored.
 *
 * @param line   line
 * @return start column, 0 for emtpy line
 */
static int lineBeginColumn(_str & line)
{
   // Ignore everything in columns 1-7.
   if (length(line) <= 7) return(0);

   // Start from column 8, search forward for the first non-space
   // character.
   startPos := pos('[~ \t]', line, 8, 'ri');
   if (!startPos) return(0);

   // Ignore columns 73 onward.
   if (startPos >= 73) return(0);

   // Found the start.
   return(startPos);
}

/**
 * Check the specified line to see if it contains a statement
 * end period. The period, if it exists, must be the last
 * non-white space character on the line that is also not
 * in columns 1-7 or columns 73 onward.
 *
 * @param line   line
 * @return Flag: true for end period, false not
 */
static bool hasEndPeriod(_str & line)
{
   // Start from column 72, search backwards to check if the first
   // non-white space is a '.'

   // First locate the end of the line. If there are more than
   // 72 character, clip the search to start from column 72.
   startPos := length(line);
   if (startPos <= 7) return(false);
   if (startPos > 72) startPos = 72;

   // Search backwards for first non-white space character.
   _str cc;
   int charPos = startPos;
   while (charPos >= 8) {
      cc = substr(line, charPos, 1);
      if (cc != ' ' && cc != "\t") break;
      charPos--;
   }

   if (charPos < 8) return(false);
   if (substr(line, charPos, 1) != '.') return(false);

   // Found it.
   return(true);
}

/**
 * Get the first word on the line.
 *
 * @param line   line
 * @return word, "" for empty line
 */
static _str firstWordInLine(_str & line)
{
   // Special case for short line.
   if (length(line) <= 7) return("");

   // Look for the first non-space character.
   word_chars := _clex_identifier_chars();
   startPos := pos('['word_chars']', line, 8, 'ri');
   if (!startPos || startPos >= 73) return("");

   // Find the end of word.
   endPos := pos('[~'word_chars'$]', line, startPos, 'ri');
   if (!endPos) return(substr(line, startPos, 73-startPos));

   // Extract first word.
   if (endPos >= 73) endPos = 73;
   return(substr(line, startPos, endPos-startPos));
}

/**
 * Find the lines of a statement.
 */
static void findStatement(int & startLine, int & endLine)
{
   // Special case for the current line containing the statement
   // end period.
   get_line(auto line);
   startLine = p_line;
   if (hasEndPeriod(line)) {
      endLine = startLine;
      return;
   }

   // Find the start line's column.
   int startCol = lineBeginColumn(line);

   // Loop thru the following lines and pick up the ones that are
   // further indented to the right. Stop when:
   //    -- a following line begins on the same column as
   //       (or before) the start column, or
   //    -- when a statement end period (.) is found, or
   //    -- first word on line is a verb
   _str word;
   int lineStart;
   int lastNonEmptyLine = startLine;
   int savedSeek = _nrseek();
   while (!down()) {
      get_line(line);
      if (isEmptyLine(line)) continue;
      //messageNwait("findStatement>"line);
      lineStart = lineBeginColumn(line);
      if (!lineStart) continue; // Skip over empty line.

      // If line begins before the start column.
      if (lineStart < startCol) {
         up();
         lastNonEmptyLine = p_line;
         break;
      }

      // Reached another statement's verb or end-verb.
      word = firstWordInLine(line);
      if (isVerb(word) || isEndVerb(word)) {
         p_line = lastNonEmptyLine;
         break;
      }

      // Reached statement termination period.
      if (hasEndPeriod(line)) {
         lastNonEmptyLine = p_line;
         break;
      }

      // Remember the last non-empty line to enclose the selection.
      lastNonEmptyLine = p_line;
   }
   endLine = lastNonEmptyLine;
   _nrseek(savedSeek);
}

/**
 * Get the next word. Columns 1-7 and 73 onward are ignored.
 * If found the cursor is positioned at the beginning of the word.
 *
 * @param word       returning next word
 * @param reachedEOF returning flag: true for reached EOF
 * @param upcase     Flag: true to upcase the returning word
 */
static void cobNextWord(_str & word,
                        bool & reachedEOF,
                        bool upcaseWord=true)
{
   // Loop to find the beginning of a word.
   word = "";
   reachedEOF = false;
   word_chars := _clex_identifier_chars();
   while (true) {
      // Find end of current word.
      if (search('[~'word_chars']', 'r@iHXCS')) {
         reachedEOF = true;
         return;
      }

      // Find the beginning of next word.
      if (search('['word_chars']', 'r@iHXCS')) {
         reachedEOF = true;
         return;
      }

      // If word starts in columns 1-7 or 73 onward, ignore it and
      // look for the start of the next word.
      if (p_col <= 7 || p_col >= 73) continue;

      // Found it...
      break;
   }

   // Find the end of word.
   _str line;
   startCol := p_col;
   startLine := p_line;
   if (search('[~'word_chars']', 'r@iHXCS') || startLine < p_line) {
      // Get from start column to the end of the line.
      p_line = startLine;
      p_col = startCol;
      get_line(line);
      word = substr(line, startCol, 73 - startCol);
      if (upcaseWord) word = upcase(word);
      return;
   }

   // Extract the word.
   endCol := p_col;
   if (endCol >= 73) endCol = 73;
   get_line(line);
   word = substr(line, startCol, endCol - startCol);
   if (upcaseWord) word = upcase(word);
   p_col = startCol;
   return;
}

/**
 * Seek to the first word on the current line. Columns 1-7 and 73
 * onward are ignored. This function assumes that there is at
 * least one word on the current line.
 */
static void seekToFirstWordOnLine()
{
   startLine := p_line;
   p_col = 8;
   word_chars := _clex_identifier_chars();
   search('['word_chars']', 'r@iHXCS');
   if (startLine != p_line) {
      p_line = startLine;
      p_col = 8;
      return;
   }
   if (p_col >= 72) p_col = 8;
}

/**
 * Skip the WHEN of the EVALUATE verb block. The cursor is placed
 * on the last line of the WHEN block.
 */
static void skipWHENClause(bool & reachedEOF)
{
   // Loop to find the next WHEN.
   reachedEOF = false;
   _str line;
   _str word;
   while (!down()) {
      get_line(line);
      if (isEmptyLine(line) || isCommentLine(line)) continue;
      word = firstWordInLine(line);
      if (word == "") continue;

      // Reached the next WHEN or the matching end-verb.
      if (word == "WHEN" || word == "END-EVALUATE") {
         up();
         return;
      }

      // Reached terminating period.
      if (hasEndPeriod(line)) {
         return;
      }
   }

   // Reach EOF.
   reachedEOF = true;
}

/**
 * Locate the start of the next statement and then skip to end
 * of it. At the end of the skip, the cursor must be on the last
 * line of the imperative statement.
 *
 * @param imperativeKeyword
 *                   imperative leading keyword
 * @param reachedEOF returning flag: true for reached EOF
 */
static void skipNextStatement(_str & imperativeKeyword,
                              bool & reachedEOF,
                              )
{
   // Special case for "WHEN" imperative key.
   reachedEndStatement := false;
   if (imperativeKeyword == "WHEN") {
      skipWHENClause(reachedEOF);
      return;
   }

   // Start from the current line, locate the beginning of the next
   // verb. Except for the first imperative key, if we see a second
   // imperative key before the verb for the imperative statement,
   // the second key terminates the first imperative condition.
   _str word;
   firstVerbLine := p_line;
   startLine := p_line;
   reachedEOF = false;
   found := false;
   firstCondition := true;
   col := 8;
   p_col = col;
   while (true) {
      cobNextWord(word, reachedEOF);
      if (word == "") break;
      //messageNwait(">>"word"<<");

      // Track the imperative keyword. If the second imperative
      // keyword is reached before the imperative statement verb
      // is reached, this imperative keyword terminates the first one.
      //
      //    EVALUATE  ....
      //       WHEN CONDITION1
      //       WHEN CONTITION2
      //          PERFORM P1...
      //       WHEN CONTITION3
      //          PERFORM P2...
      //    END-EVALUATE
      //
      // In the example above, WHEN CONTITION2 is the second condition
      // and its terminates WHEN CONDITION1.
      if (word == imperativeKeyword) {
         if (firstCondition) {
            firstCondition = false;
         } else {
            up();
            end_line();
            return;
         }
      }

      // Verb found...
      if (isVerb(word)) {
         found = true;
         firstVerbLine = p_line;
         break;
      }

      // Found an end-verb. Reaching any end-verb indicates
      // the end of the statement.
      if (isEndVerb(word)) {
         up();
         return;
      }
   }
   //messageNwait("Found first verb");

   // If verb not found, current line must be the last line of the
   // statement.
   if (!found) {
      reachedEOF = true;
      return;
   }

   // Skip to the end of this statement. This is accomplished by
   // locating the next verb and then back up to the previous line.
   found = false;
   while (true) {
      cobNextWord(word, reachedEOF);
      if (word == "") break;
      if (isVerb(word)) {
         found = true;
         break;
      }

      // Found an end-verb. Reaching any end-verb indicates
      // the end of the statement.
      if (isEndVerb(word)) {
         //messageNwait("Found end-verb");
         up();
         return;
      }
   }
   //messageNwait("Found second verb");

   // If verb not found, current line must be the last line in the
   // file and, implicitly, the last line of the statement.
   if (!found) {
      reachedEOF = true;
      return;
   }

   // Next verb found. Now back up to the line containing the
   // previous verb.
   p_line = firstVerbLine;
   seekToFirstWordOnLine();
}

/**
 * Find the lines enclosed in a verb with possible nested
 * imperative statement.
 *
 * @param verb       verb
 * @param endVerb    expected end verb
 * @param canNest    Flag: true to indicate that verb block can contain other statements
 * @param imperativeKey
 *                   imperative statement leading key word
 * @param startLine  returning block start line
 * @param endLine    returning block end line
 * @param reachedEndStatement
 *                   returning flag: 1 for statement end (period) reached
 * @param reachedEOF returning flag: true for reached EOF
 */
static void findImperativeBlock(_str & verb,
                                _str & endVerb,
                                bool canNest,
                                _str & imperativeKey,
                                int & startLine,
                                int & endLine,
                                bool & reachedEndStatement,
                                bool & reachedEOF
                                )
{
   /* The search for the imperative leading keyword stops:

         -- when a leading keyword is found (see 1 below), or
         -- when the matching end-verb is reached, or
         -- when another verb is found, or
         -- when the statement end period is reached, or
         -- when another end-verb is found
         -- when a paragraph name is found

         all of the above, whichever comes first.

      1. If a leading keyword is found, skip the next statement.
      There can be more than one occurrence of the imperative
      leading keyword. For each occurrence, skip the associating
      (ie. next) statement. Search continues until one of the
      other criteria are met.
   */
   //messageNwait("findImperativeBlock>"endVerb","imperativeKey);
   startLine = p_line;
   endLine = p_line;
   reachedEndStatement = false;
   reachedEOF = false;

   // The imperative key string can contain more than one
   // keyword, each separated by ':'.
   // Extract the keywords into an array.
   _str impKeys[];
   _str keyword;
   impKeys._makeempty();
   keyCount := 0;
   _str keyText = imperativeKey;
   parse keyText with keyword':'keyText;
   while (keyword != "") {
      impKeys[keyCount] = keyword;
      keyCount++;
      parse keyText with keyword':'keyText;
   }

   // Imperative keyword may be on the same line. In this case,
   // we need to start searching for the imperative keyword
   // from the same line containing the verb.
   keyMaybeOnSameLine := true;

   // Loop line by line.
   int lastNonEmptyLine = endLine;
   int i;
   _str line;
   _str word;
   foundImperativeKey := false;
   while (keyMaybeOnSameLine || !down()) {
      get_line(line);
      if (isEmptyLine(line) || isCommentLine(line)) {
         keyMaybeOnSameLine = false;
         continue;
      }
      //messageNwait("findImperativeBlock>"line);

      // Reached end verb.
      word = firstWordInLine(line);
      word = upcase(word);
      if (word == endVerb) {
         endLine = p_line;
         return;
      }

      // Reached another statement's end verb or reached another
      // verb without first matched the imperative keywords.
      if (isEndVerb(word) || (!keyMaybeOnSameLine && isVerb(word))) {
         up();
         endLine = lastNonEmptyLine;
         return;
      }

      // Reached next paragraph.
      if (isParagraphName(line)) {
         up();
         endLine = lastNonEmptyLine;
         return;
      }

      // Reached statement ending period.
      if (hasEndPeriod(line)) {
         endLine = p_line;
         reachedEndStatement = true;
         return;
      }

      // Found imperative keyword in line.
      // The presence of the imperative keyword indicates that the
      // next statement is part of this statement and must be
      // included.
      foundImperativeKey = false;
      for (i=0; i<keyCount; i++) {
         // If a key is found, skip over the imperative statement
         // which is the next immediate statement.
         //messageNwait("matching..."impKeys[i]);
         if (pos(' 'impKeys[i]' ', line, 8)) {
            if (keyMaybeOnSameLine) {
               if (!down()) {
                  reachedEOF = true;
                  break;
               }
            }
            //messageNwait("Skipping next statement... start");
            skipNextStatement(impKeys[i], reachedEOF);
            //messageNwait("Skipping next statement... out");

            // Reached EOF... This implies the end of the imperative
            // statement and all other statements up to this line.
            if (reachedEOF) {
               endLine = p_line;
               return;
            }

            // Check if reached terminating period.
            get_line(line);
            if (hasEndPeriod(line)) {
               endLine = p_line;
               reachedEndStatement = true;
               return;
            }

            // Found and skipped over the imperative statement...
            foundImperativeKey = true;
            break;
         }
      }

      // More special cases...
      if (!foundImperativeKey) {
         // Special case for "WHEN" which indicates the end of the
         // statement.
         if (verb != "EVALUATE" && word == "WHEN") {
            up();
            endLine = p_line;
            return;
         } else if (verb != "IF" && word == "ELSE") {
            up();
            endLine = p_line;
            return;
         } else if (verb != "IF" && word == "END-IF") {
            up();
            endLine = p_line;
            return;
         }
      }

      // If gets to here, imperative key is not on the same line
      // as the verb.
      keyMaybeOnSameLine = false;

      // Track the last line non-empty line.
      lastNonEmptyLine = p_line;
   }

   // Reached EOF... Assume imperative block ends here.
   endLine = lastNonEmptyLine;
   reachedEOF = true;
}

/**
 * Find the lines enclosed in a verb...end-verb block.
 *
 * @param verb      verb
 * @param endVerb   expected end verb
 * @param canNest   Flag: true to indicate that verb block can contain other statements
 * @param imperativeKey
 *                  imperative statement leading key word
 * @param startLine returning block start line
 * @param endLine   returning block end line
 * @param reachedEndStatement
 *                  returning flag: 1 for statement end (period) reached
 * @param reachedEOF returning flag: true for reached EOF
 */
static void findVerbBlock(_str & verb,
                          _str & endVerb,
                          bool canNest,
                          _str & imperativeKey,
                          int & startLine,
                          int & endLine,
                          bool & reachedEndStatement,
                          bool & reachedEOF
                          )
{
   // Defaults.
   startLine = p_line;
   endLine = p_line;
   reachedEndStatement = false;
   reachedEOF = false;
   //messageNwait("findVerbBlock> verb="verb", endVerb=<"endVerb">");

   // Super easy case of having statement ending period on the same
   // line as the verb.
   get_line(auto line);
   if (hasEndPeriod(line)) {
      endLine = p_line;
      reachedEndStatement = true;
      return;
   }

   // If verb supports an imperative statement, search for the
   // imperative statement leading keyword. Verbs with imperative
   // statements are treated differently from those without.
   if (imperativeKey != "") {
      findImperativeBlock(verb, endVerb, canNest,
                          imperativeKey,
                          startLine, endLine, reachedEndStatement,
                          reachedEOF);
      return;
   }

   // Loop until we find the end verb or the statement terminating
   // period. Nested verb block can contain anything including
   // other nested verb block.
   _str word;
   _str nestedVerb, nestedEndVerb, nestedImperativeKey;
   bool nestedCanNest;
   elseReached := false;
   int blockStart = startLine;
   int blockEnd = endLine;
   while (!down()) {
      // Get the first word on the line.
      get_line(line);
      //messageNwait("findVerbBlock>"line);
      word = firstWordInLine(line);
      if (word == "") {
         // Line does not have any words but may still have
         // a statement termination period.
         if (hasEndPeriod(line)) {
            reachedEndStatement = true;
            endLine = p_line;
            return;
         }
         continue; // skip empty line
      }

      // Skip over comment line.
      if (isCommentLine(line)) continue;

      // If this is the matching end-verb, wrap up this verb block.
      word = upcase(word);
      if (word == endVerb) {
         endLine = p_line;
         return;
      }

      // If this is a matching end-verb for something else, that
      // end-verb implicitly terminates this verb block.
      if (isEndVerb(word)) {
         p_line = p_line - 1;
         endLine = p_line;
         return;
      }

      // Reached next paragraph.
      if (isParagraphName(line)) {
         up();
         endLine = p_line;
         return;
      }

      // Check to see if line has a statement termination period.
      if (hasEndPeriod(line)) {
         reachedEndStatement = true;
         endLine = p_line;
         return;
      }

      // Special case for IF verb.
      // The second ELSE in an IF is the ELSE for an outer IF.
      // This second ELSE terminates the current IF.
      if (verb == "IF" && word == "ELSE") {
         if (elseReached) {
            up();
            endLine = p_line;
            return;
         }
         elseReached = true;
      }

      // If first word is a verb with matching end-verb, recurse
      // to pick up the nested verb block.
      if (isVerb(word)) {
         nestedVerb = word;
         verbInfo(nestedVerb, nestedEndVerb, nestedCanNest,
                  nestedImperativeKey);
         //messageNwait("findVerbBlock>"nestedVerb","nestedEndVerb","nestedCanNest","nestedImperativeKey);
         if (nestedVerb == "PERFORM") {
            // Skip to first verb. The check to see if PERFORM is
            // a special case must begin from the word itself.
            seekToFirstWordOnLine();

            // The "PEFORM" verb has an optional following "UNTIL" which
            // causes the "PERFORM" block to have an optional "END-PERFORM".
            if (isSpecialCasePERFORM()) {
               nestedEndVerb = "END-PERFORM";
               nestedCanNest = true;
            }
         }
         if (nestedEndVerb != "") {
            // Recurse to find the nested verb block.
            //messageNwait("RECURSE>>>");
            findVerbBlock(nestedVerb, nestedEndVerb, nestedCanNest,
                          nestedImperativeKey, blockStart, blockEnd,
                          reachedEndStatement,
                          reachedEOF);

            // If terminating period has been reached, end all nested
            // block.
            if (reachedEndStatement || reachedEOF) {
               endLine = blockEnd;
               return;
            }

            // Start from the nested block end, continue looking for
            // the matching verb-end of the current nesting level.
            p_line = blockEnd;
            //messageNwait("<<<BACK FROM RECURSE");
            continue;
         }

         // Verb does not have a matching end-verb so continue...
         continue;
      }

      // Line must be a continuation from previous line. Skip it...
   }

   // Reached EOF without finding a matching end-verb or reaching
   // an appropriate statement termination. Consider this to be
   // the block end.
   endLine = p_line;
}

/**
 * Check to see if the PERFORM is a special PERFORM UNTIL
 * syntax.
 *
 * @return true for PERFORM UNTIL, false for single statement PERFORM
 */
static bool isSpecialCasePERFORM()
{
   // The "PEFORM" verb has an optional following "UNTIL" which
   // causes the "PERFORM" block to have an optional "END-PERFORM".
   // We need to determine if this PERFORM is one such special case.
   _str word;
   int savedSeek = _nrseek();
   reachedEOF := false;
   cobNextWord(word, reachedEOF);
   if (word != "WITH" && word != "TEST" && word != "UNTIL") return(false);

   // Syntax expected:  WITH TEST BEFORE|AFTER UNTIL
   if (word == "WITH") {
      cobNextWord(word, reachedEOF);
      if (word != "TEST") {
         _nrseek(savedSeek);
         return(false);
      }
      cobNextWord(word, reachedEOF);
      if (word != "BEFORE" && word != "AFTER") {
         _nrseek(savedSeek);
         return(false);
      }
      cobNextWord(word, reachedEOF);
      if (word != "UNTIL") {
         _nrseek(savedSeek);
         return(false);
      }
      _nrseek(savedSeek);
      return(true);
   }

   // Syntax expected: TEST BEFORE|AFTER UNTIL
   if (word == "TEST") {
      cobNextWord(word, reachedEOF);
      if (word != "BEFORE" && word != "AFTER") {
         _nrseek(savedSeek);
         return(false);
      }
      cobNextWord(word, reachedEOF);
      if (word != "UNTIL") {
         _nrseek(savedSeek);
         return(false);
      }
      _nrseek(savedSeek);
      return(true);
   }

   // Found PERFORM UNTIL
   _nrseek(savedSeek);
   return(true);
}

/**
 * Check to see if the specified line is a paragraph name.
 * The paragraph name must:
 *    -- be on its own line
 *    -- begin on column 8
 *    -- have an ending period
 *
 * @param line   line
 * @return Flag: true for paragraph name, false not
 */
static bool isParagraphName(_str & line)
{
   // Line too short.
   if (length(line) <= 7) return(false);

   // Skip over comment line.
   if (isCommentLine(line)) return(false);

   // First word not in column 8, 9, 10, or 11.
   word_chars := _clex_identifier_chars();
   position := pos('['word_chars']', line, 8, 'ri');
   if (position >= 12) return(false);

   // Look for the first period which should also be the last character
   // on the line.
   if (!pos('.', line, 8)) return(false); // no trailing period

   // Found paragraph name.
   return(true);
}

/**
 * Check to see the cursor is on a paragraph name.
 * The paragraph name must:
 *    -- be on its own line
 *    -- begin on columns 8-11
 *    -- have an ending period
 *
 * @return Flag: true for on paragraph name, false for not
 */
static bool isOnParagraphName()
{
   get_line(auto line);
   return(isParagraphName(line));
}

/**
 * Select the entire paragraph. The paragraph spans from the paragraph
 * name to the next paragraph name, excluding the next paragraph header
 * comment. If the paragraph has header comment, the comment lines
 * are selected.
 */
static void selectParagraph()
{
   _str line;
   int savedSeek = _nrseek();
   startLine := p_line;

   // Loop backwards for the header comment, if there is one.
   // The search for the first header comment line stops when:
   //    - Reach line with a verb or end-verb
   //    - Reach line with terminating period (including another paragraph name)
   _str word;
   hasComment := false;
   while (!up()) {
      get_line(line);
      if (isEmptyLine(line)) continue;
      if (isCommentLine(line)) {
         hasComment = true;
         startLine = p_line;
         continue;
      }

      // Reached terminating period.
      if (hasEndPeriod(line)) break;

      // Reached verb or end-verb.
      if (isVerb(word) || isEndVerb(word)) break;
   }

   // Restart from beginning.
   _nrseek(savedSeek);

   // Loop until we find the next paragraph name.
   endLine := p_line;
   while (!down()) {
      get_line(line);
      if (isEmptyLine(line)) continue;
      if (isCommentLine(line)) continue;
      if (isParagraphName(line)) {
         up();
         break;
      }
      endLine = p_line;
   }

   // Select the code block.
   mstyle := "EN";
   deselect();
   p_line = startLine;
   _select_line('', mstyle);
   p_line = endLine;
   _select_line('', mstyle);
   _nrseek(savedSeek);
}

int selectCodeBlock_cob()
{
   // Remember the seek position.
   int savedSeek = _nrseek();

   // Find verb at cursor.
   _str verb, endVerb, imperativeKey;
   bool canNest;
   if (!verbUnderCursor(verb, endVerb, canNest, imperativeKey)) {
      // Special case for paragraph name.
      if (isOnParagraphName()) {
         selectParagraph();
         return(0);
      }

      // Bad start.
      if (verb != "") {
         _message_box(nls("COBOL select code block must begin on a verb.\n'%s' is not a supported COBOL verb.",verb));
      } else {
         _message_box(nls("COBOL select code block must begin on a verb."));
      }
      return(1);
   }
   _nrseek(savedSeek);

   // Check for special case verbs.
   int startLine, endLine;
   bool reachedEndStatement, reachedEOF;
   if (verb == "PERFORM") {
      // The "PEFORM" verb has an optional following "UNTIL" which
      // causes the "PERFORM" block to have an optional "END-PERFORM".
      if (isSpecialCasePERFORM()) {
         endVerb = "END-PERFORM";
         canNest = true;
      }
      _nrseek(savedSeek);
   }

   // If there is a matching end-verb, search for it. Otherwise,
   // use indentation level to determine code block.
   //messageNwait("Main>"verb","endVerb","canNest","imperativeKey);
   if (endVerb != "") {
      findVerbBlock(verb, endVerb, canNest, imperativeKey,
                    startLine, endLine,
                    reachedEndStatement, reachedEOF);
   } else {
      findStatement(startLine, endLine);
   }

   // Select the code block.
   mstyle := "EN";
   deselect();
   p_line = startLine;
   _select_line('', mstyle);
   p_line = endLine;
   _select_line('', mstyle);
   _nrseek(savedSeek);
   return(0);
}
