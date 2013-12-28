////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38278 $
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
#include "slick.sh"
#import "stdprocs.e"
#import "files.e"
#import "sellist.e"
#import "diffprog.e"

namespace se.lang.cpp;


struct TokenNamePair {
   _str token;
   _str name;
};

/**
 * This class is used internally for generating a fast C++ lexical analyzer 
 * based on a supplied set of keywords.  It assumes the availablity of some 
 * proprietary SlickEdit C++ class libraries for handling tokens and lookahead. 
 *  
 * The primary output of this class is a "parse" function which switches 
 * character by character or in multi-character chunks in order to quickly 
 * identify the next token in the file being parsed. 
 *  
 * The code generated could be best described as a hard-coded character trie. 
 * Input is consumed character by character and switched upon depending on the 
 * set of tokens that match the prefix so far.  Instead of generating a table 
 * based lexer, this creates a much faster lexer which is purely a state 
 * machine for the language encoded in one function with callouts for more 
 * difficult syntactic constructs such as comments and strings. 
 */
class CPPLexerGenerator {

   /**
    * This is the name of the lexer class which the parsing function will belong 
    * to.  The class must expect to have a parameterless "parse" function which 
    * will return an integer value, typically an enumerated type (see below) 
    * representing the kind of token or keyword that was recognized.  The only 
    * responsibility of the parse function is to advance the cursor.  The contents 
    * of the token is extracted generically by the base lexer class which this 
    * lexer derives from. 
    */
   _str m_lexerClassName   = "CPPLexer";
   /**
    * This is the name of the header file to #include for the lexer class definition.
    */
   _str m_lexerClassInclude = "";
   /**
    * This is the class used to represent a token.  The lexer should produce 
    * a stream of tokens of this class type. 
    */
   _str m_tokenClassName   = "CPPToken";
   /**
    * This is the name of the header file to #include for the token class definition. 
    */
   _str m_tokenClassInclude = "";
   /**
    * This the enumerated type for identifying keywords, operators, punctuation, 
    * and other special tokens for the language being parsed. 
    */
   _str m_tokenEnumName    = "CPPTokenType";
   /**
    * This is the name of the header file to #include for the token enum definition. 
    */
   _str m_tokenEnumInclude = "";
   /**
    * This is the name of the constant in the above enumerated type which 
    * represents a simple identifier in the language's syntax. 
    */
   _str m_tokenIdentifier  = "CPP_TOKEN_IDENTIFIER";
   /**
    * This is a regular expression representing what character patterns are 
    * allowed for identifiers in the language's syntax. 
    */
   _str m_identifierRegex  = "^[a-zA-Z_][a-zA-Z0-9_$]*$";
   /**
    * Are all characters over ASCII 128 to be considered as identifier 
    * characters? 
    */
   boolean m_extendedIdentifierChars = false;
   /**
    * This is the name of the function to call to parse an identifier.
    */
   _str m_parseIdentifier = "parseIdentifier";
   /**
    * This is the name of the function to call to parse a garbage charcter.
    */
   _str m_parseGarbageChar = "parseGarbageChar";
      
   /**
    * Any code snippet you wish to have inserted in the parse 
    * function before the switch statement.  At the point this code 
    * is inserted, there is already a local int named 'ch' primed 
    * with the currentChar() 
    */
   _str m_parseFunctionProlog = "";

   /**
    * In order to generate faster code, separate keyword tokens out 
    * by length.  The way we can parse identifiers quickly, then look 
    * up matches for keywords pivoting on the length of the keyword. 
    * Note that this setting will be automatically turned off 
    * if the lexer generator detects that the grammer contains tokens 
    * which contain identifier characters as well as non-identifier characters. 
    */
   boolean m_separateKeyordsByLength = true;

   /**
    * This method tests whether a given string is a valid identifier, abiding 
    * by the identifier regular expression specified above. 
    * 
    * @param s    character string to test 
    * 
    * @return Returns 'true' for valid identifiers, false otherwise. 
    */
   protected boolean isIdentifier(_str s) 
   {
      if (pos(m_identifierRegex,s,1,'r')) {
         return true;
      }
      if (length(s)==1 && _asc(s) >= 0x80 && m_extendedIdentifierChars) {
         return true;
      }
      return false;
   }
   
   /**
    * This function is used to escape special characters (using standard 
    * C++ string escape sequences). 
    * 
    * @param ch   character to escape
    * 
    * @return escaped sequence string
    */
   protected _str escapeChars(_str ch) 
   {
      switch (ch) {
      case "\t":     return "\\t";
      case "\0":     return "\\0";
      case "\1":     return "\\1";
      case "\n":     return "\\n";
      case "\f":     return "\\f";
      case "\r":     return "\\r";
      case "\r\n":   return "\\r\\n";
      case "\v":     return "\\v";
      case "\"":     return "\\\"";
      case "\'":     return "\\'";
      case "\\":     return "\\\\";
      case "\n":     return "\\n";
      case "\\ ":    return "\\\\ ";
      case "\\\t":   return "\\\\\\t";
      case "\\\v":   return "\\\\\\v";
      case "\\\f":   return "\\\\\\f";
      case "\\\n":   return "\\\\\\n";
      case "\\\r":   return "\\\\\\r";
      case "\\\r\n": return "\\\\\\r\\n";
      case " \t":    return " \\t";
      case " \f":    return " \\f";
      case " \v":    return " \\v";
      case "\x1a":   return "\\x1a";
      }
      return ch;
   }
   
   /**
    * This function is used to generate a switch statement to handle the 
    * different possibilities for completing the current token. 
    * 
    * @param prefix           The token seen thus far
    * @param posn             Our position within the token so far
    * @param defaultTokenCase The default token to return
    * @param tokenTable       The tokenization table
    * @param caseSensitive    Are identifiers and keywords case-sensitive?
    */
   void generateSwitchStatement(_str prefix, int posn,
                                TokenNamePair defaultTokenCase,
                                TokenNamePair (&tokenTable)[],
                                boolean caseSensitive=true, 
                                int wid=0, _str switchIndent="",
                                boolean doNotGenerateDefault=false,
                                boolean onlyGenerateCases = false,
                                boolean keywordLeadChars[] = null) 
   {
      indent1 := switchIndent:+substr('',1,posn*p_SyntaxIndent);
      indent2 := switchIndent:+substr('',1,posn*p_SyntaxIndent+p_SyntaxIndent);
      indent3 := switchIndent:+substr('',1,posn*p_SyntaxIndent+p_SyntaxIndent+p_SyntaxIndent);
   
      _str id_chars[];
      boolean id_chars_used:[];
   
      _str case_array[];
      _str token_array[];
   
      int num_cases=0;
      int i,j;
      for (i=0; i<0x80; ++i) {
         case_array[i]='';
         token_array[i]='';
         if (!caseSensitive && islower(_chr(i))) {
            continue;
         }
         for (j=0; j<tokenTable._length(); ++j) {
            if (tokenTable[j].name==null) {
               continue;
            }
            if (posn <= length(tokenTable[j].token) &&
                (( caseSensitive &&
                   substr(tokenTable[j].token,1,posn-1) :== prefix &&
                   substr(tokenTable[j].token,posn,1) :== _chr(i))
                 ||
                 ( !caseSensitive &&
                   strieq(substr(tokenTable[j].token,1,posn-1), prefix) &&
                   strieq(substr(tokenTable[j].token,posn,1), _chr(i))))) {
               case_array[i] = tokenTable[j].name;
               token_array[i] :+= tokenTable[j].token;
            }
         }
         if (case_array[i] != '') {
            num_cases++;
         }
      }
   
      // use a switch statement if we are generating more than 5 cases
      // or if we are generating the top level switch, not for keywords.
      use_switch := (num_cases >= 5 || onlyGenerateCases);
      found_exact_match := false;
      num_cases = 0;
   
      for (i=0; i<0x80; ++i) {
   
         // skip cases which have already been generated by keyword switch
         if (keywordLeadChars != null && keywordLeadChars[i] != null && keywordLeadChars[i] == true) {
            continue;
         }

         int match_count=0;
         int match_pos=0;
         int exact_match=-1;
         _str match_names='';
         _str match_chars[]; match_chars._makeempty();
         if (caseSensitive || !islower(_chr(i))) {
            for (j=0; j<tokenTable._length(); ++j) {
               if (tokenTable[j].name==null) {
                  continue;
               }
               if (posn <= length(tokenTable[j].token) &&
                   (( caseSensitive && 
                      substr(tokenTable[j].token,1,posn-1) :== prefix &&
                      substr(tokenTable[j].token,posn,1) :== _chr(i)) ||
                    ( !caseSensitive &&
                      strieq(substr(tokenTable[j].token,1,posn-1), prefix) &&
                      strieq(substr(tokenTable[j].token,posn,1), _chr(i))))) {
                  match_pos=j;
                  match_count++;
                  match_names = match_names :+ " '" :+ escapeChars(tokenTable[j].token) :+ "'";
                  if (posn==length(tokenTable[j].token)) {
                     exact_match=j;
                  } else if (caseSensitive && !_inarray(substr(tokenTable[j].token,posn+1,1),match_chars)) {
                     match_chars[match_chars._length()]=substr(tokenTable[j].token,posn+1,1);
                  } else if (!caseSensitive && !_inarray(lowcase(substr(tokenTable[j].token,posn+1,1)),match_chars)) {
                     match_chars[match_chars._length()]=lowcase(substr(tokenTable[j].token,posn+1,1));
                  }
               }
            }
         }
   
         if (match_count > 0 && num_cases==0 && use_switch && !onlyGenerateCases) {
            insert_line(indent1:+"switch (ch) {");
         }
   
         if (match_names != '') {
            insert_line(indent1:+"//":+match_names);
         }
   
         if (match_count==0 && isIdentifier(prefix:+_chr(i)) && !id_chars_used._indexin(_chr(i))) {
            id_chars[id_chars._length()]=_chr(i);
            continue;
         }
   
         if (match_count > 0) {
            if (!caseSensitive) {
               id_chars_used:[upcase(_chr(i))] = true;
               id_chars_used:[lowcase(_chr(i))] = true;
            } else {
               id_chars_used:[_chr(i)] = true;
            }
            if (num_cases==0) {
               if (use_switch) {
                  if (!caseSensitive && isalpha(_chr(i))) {
                     insert_line(indent1:+"case '"escapeChars(upcase(_chr(i)))"':");
                     insert_line(indent1:+"case '"escapeChars(lowcase(_chr(i)))"':");
                  } else {
                     insert_line(indent1:+"case '"escapeChars(_chr(i))"':");
                  }
               } else {
                  if (!caseSensitive && isalpha(_chr(i))) {
                     insert_line(indent1:+"if (ch == '"escapeChars(upcase(_chr(i)))"' || ch == '"escapeChars(lowcase(_chr(i)))"') {");
                  } else {
                     insert_line(indent1:+"if (ch == '"escapeChars(_chr(i))"') {");
                  }
               }
            } else {
               if (use_switch) {
                  if (!caseSensitive && isalpha(_chr(i))) {
                     insert_line(indent1:+"case '"escapeChars(lowcase(_chr(i)))"':");
                     insert_line(indent1:+"case '"escapeChars(upcase(_chr(i)))"':");
                  } else {
                     insert_line(indent1:+"case '"escapeChars(_chr(i))"':");
                  }
               } else {
                  if (isalpha(_chr(i)) && !caseSensitive) {
                     insert_line(indent1:+"} else if (ch == '"escapeChars(lowcase(_chr(i)))"' || ch == '"escapeChars(upcase(_chr(i)))"') {");
                  } else {
                     insert_line(indent1:+"} else if (ch == '"escapeChars(_chr(i))"') {");
                  }
               }
            }
            num_cases++;
         }
   
         int next_i = i+1;
         while (next_i < 127 && case_array[next_i]=='') next_i++;
         if (use_switch && match_count==1 && i < 127 && 
             case_array[i]:==case_array[next_i] && 
             posn==length(token_array[i]) &&
             posn==length(token_array[next_i]) &&
             isIdentifier(token_array[i]) == isIdentifier(token_array[next_i])) {
            continue;
         }
   
         insertedMatch := false;
         if (match_count == 1) {
            boolean needNextChar = true;
            boolean needIDCheck = true;
            for (j=posn+1; j<=length(tokenTable[match_pos].token); ++j) {
   
               _str suffix = substr(tokenTable[match_pos].token,j);
               if (!isIdentifier(suffix) && !isIdentifier(prefix) && defaultTokenCase!=null && j==posn+1) {
                  insert_line(indent2:+"ch = peekCharUnchecked();");
                  if (isalpha(_chr(i)) && !caseSensitive) {
                     insert_line(indent2:+"if (ch != '"escapeChars(lowcase(substr(tokenTable[match_pos].token,j,1)))"' && ch != '"escapeChars(upcase(substr(tokenTable[match_pos].token,j,1)))"') {");
                  } else {
                     insert_line(indent2:+"if (ch != '"escapeChars(substr(tokenTable[match_pos].token,j,1))"') {");
                  }
                  insert_line(indent3:+"return ":+defaultTokenCase.name';');
                  insert_line(indent2:+"}");
                  insert_line(indent2:+"ch = nextCharUnchecked();");
                  if (wid != 0) progress_increment(wid);
               } else {
                  int skipChars = 0;
                  if (isIdentifier(suffix) && j <= length(tokenTable[match_pos].token)) {
                     ji := 0;
                     kw := "";
                     kwSuffix := "";
                     if (j > 0) kw = escapeChars(substr(tokenTable[match_pos].token,j-1,1));
                     for (ji=0; j+ji<=length(tokenTable[match_pos].token); ji++) {
                        kwSuffix :+= escapeChars(substr(tokenTable[match_pos].token,j+ji,1));
                     }
                     kw :+= kwSuffix;

                     if (length(kw) <= 1 && doNotGenerateDefault) {
                        insert_line(indent2:+"skipCharUnchecked();");
                        insert_line(indent2:+"return ":+tokenTable[match_pos].name';');
                        if (wid != 0) progress_increment(wid);
                     } else if (length(kw) == 2 && doNotGenerateDefault) {
                        if (caseSensitive) {
                           insert_line(indent2:+"if (peekCharUnchecked() == \'":+kwSuffix:+"\') {");
                        } else {
                           insert_line(indent2:+"if (peekCharLowcase() == \'":+lowcase(kwSuffix):+"\') {");
                        }
                        insert_line(indent3:+"skipCharUnchecked(2);");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
#if 0
                     // multi-char stuff causes wanings with GCC
                     } else if (length(kw) == 3 && doNotGenerateDefault) {
                        if (caseSensitive) {
                           insert_line(indent2:+"if (peekChar2() == \'":+kwSuffix:+"\') {");
                        } else {
                           insert_line(indent2:+"if (peekChar2Lowcase() == \'":+lowcase(kwSuffix):+"\') {");
                        }
                        insert_line(indent3:+"skipCharUnchecked(3);");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
                     } else if (length(kw) == 4 && doNotGenerateDefault) {
                        if (caseSensitive) {
                           insert_line(indent2:+"if (peekChar3() == \'":+kwSuffix:+"\') {");
                        } else {
                           insert_line(indent2:+"if (peekChar3Lowcase() == \'":+lowcase(kwSuffix):+"\') {");
                        }
                        insert_line(indent3:+"skipCharUnchecked(4);");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
                     } else if (length(kw) == 5 && doNotGenerateDefault && caseSensitive) {
                        if (caseSensitive) {
                           insert_line(indent2:+"if (peekChar4() == \'":+kwSuffix:+"\') {");
                        } else {
                           insert_line(indent2:+"if (peekChar4Lowcase() == \'":+lowcase(kwSuffix):+"\') {");
                        }
                        insert_line(indent3:+"skipCharUnchecked(5);");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
#endif
                     } else if (caseSensitive && doNotGenerateDefault) {
                        insert_line(indent2:+"if (memcmp(currentBuffer()+1, \"":+kwSuffix:+"\",":+ji:+")==0) {");
                        insert_line(indent3:+"skipCharUnchecked("length(kw)");");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
                     } else if (caseSensitive) {
                        insert_line(indent2:+"if (matchKeyword(\"":+kw:+"\",":+ji+1:+")) {");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
                     } else {
                        insert_line(indent2:+"if (matchKeywordLowcase(\"":+lowcase(kw):+"\",":+ji+1:+")) {");
                        insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                        insert_line(indent2:+"}");
                        if (wid != 0) progress_increment(wid);
                     }
                     if (!doNotGenerateDefault) {
                        if (defaultTokenCase != null && !isIdentifier(prefix)) {
                           insert_line(indent2:+"return ":+defaultTokenCase.name';');
                           if (wid != 0) progress_increment(wid);
                        } else if (isIdentifier(prefix:+_chr(i))) {
                           insert_line(indent2:+"return ":+m_parseIdentifier:+"();");
                        } else if (isIdentifier(prefix)) {
                           insert_line(indent2:+"return ":+m_tokenIdentifier:+";");
                        } else {
                           if (prefix=='') insert_line(indent2:+"ch = nextChar();");
                           insert_line(indent2:+"return ":+m_parseGarbageChar:+"();");
                        }
                     }
                     skipChars=0;//ji;
                     j+=ji;
                     needNextChar = false;
                     needIDCheck = false;
                     insertedMatch = true;

                  } else if (caseSensitive && j+1 <= length(tokenTable[match_pos].token)) {
                     ji := 0;
                     kw := "";
                     if (j > 0) {
                        kw = escapeChars(substr(tokenTable[match_pos].token,j-1,1));
                     }
                     for (ji=0; j+ji<=length(tokenTable[match_pos].token); ji++) {
                        kw :+= escapeChars(substr(tokenTable[match_pos].token,j+ji,1));
                     }
                     insert_line(indent2:+"if (matchString(\"":+kw:+"\",":+ji+1:+")) {");
                     insert_line(indent3:+"return ":+tokenTable[match_pos].name';');
                     insert_line(indent2:+"}");
                     needNextChar = false;
                     needIDCheck = false;
                     skipChars=0;//ji;
                     insertedMatch = true;
                     j+=ji;

                  } else {
                     insert_line(indent2:+"ch = nextCharUnchecked();");
                     if (!caseSensitive && isalpha(substr(tokenTable[match_pos].token,j,1))) {
                        insert_line(indent2:+"if (ch != '"escapeChars(lowcase(substr(tokenTable[match_pos].token,j,1)))"' && ch != '"escapeChars(upcase(substr(tokenTable[match_pos].token,j,1)))"') {");
                     } else {
                        insert_line(indent2:+"if (ch != '"escapeChars(substr(tokenTable[match_pos].token,j,1))"') {");
                     }
                  }
                  if (!insertedMatch) {
                     //if (!doNotGenerateDefault) {
                        if (isIdentifier(prefix:+_chr(i))) {
                           insert_line(indent3:+"return ":+m_parseIdentifier:+"();");
                        } else if (isIdentifier(prefix)) {
                           insert_line(indent3:+"return ":+m_tokenIdentifier:+";");
                        } else {
                           insert_line(indent3:+"return ":+m_parseGarbageChar:+"();");
                        }
                     //}
                     insert_line(indent2:+"}");
                  }
                  switch (skipChars) {
                  case 0:
                     break;
                  case 1:
                     if (j < length(tokenTable[match_pos].token)) {
                        insert_line(indent2:+"skipCharUnchecked();");
                     } else {
                        insert_line(indent2:+"skipChar2Unchecked();");
                        insert_line(indent2:+"ch = currentChar();");
                        needNextChar = false;
                     }
                     break;
                  case 2:
                     if (j < length(tokenTable[match_pos].token)) {
                        insert_line(indent2:+"skipChar2Unchecked();");
                     } else {
                        insert_line(indent2:+"skipChar3Unchecked();");
                        insert_line(indent2:+"ch = currentChar();");
                        needNextChar = false;
                     }
                     break;
                  case 3:
                     if (j < length(tokenTable[match_pos].token)) {
                        insert_line(indent2:+"skipChar3Unchecked();");
                     } else {
                        insert_line(indent2:+"skipChar4Unchecked();");
                        insert_line(indent2:+"ch = currentChar();");
                        needNextChar = false;
                     }
                     break;
                  case 4:
                     insert_line(indent2:+"skipChar4Unchecked();");
                     break;
                  default:
                     if (j < length(tokenTable[match_pos].token)) {
                        insert_line(indent2:+"skipCharUnchecked("skipChars");");
                     } else {
                        insert_line(indent2:+"skipCharUnchecked("skipChars+1");");
                        insert_line(indent2:+"ch = currentChar();");
                        needNextChar = false;
                     }
                     break;
                  }
               }
            }
            identifierSuffix := substr(tokenTable[match_pos].token,2);
            if (needNextChar && tokenTable[match_pos].name != "parseEOF()") {
               insert_line(indent2:+"ch = nextCharUnchecked();");
               if (needIDCheck && identifierSuffix=="" &&
                   !isIdentifier(prefix:+_chr(i):+identifierSuffix) &&
                   isIdentifier(prefix:+_chr(i):+'a')) {
                  identifierSuffix = "a";
               }
            }
            if (!doNotGenerateDefault && needIDCheck && 
                isIdentifier(prefix:+_chr(i):+identifierSuffix) && 
                !isnumber(prefix:+_chr(i))) {
               insert_line(indent2:+"if (ch < 0 || ch >= 0x80 || isIdChar[ch]) {");
               insert_line(indent3:+"return ":+m_parseIdentifier:+"();");
               insert_line(indent2:+"}");
            }
            found_exact_match=true;
            if (!insertedMatch) {
               insert_line(indent2:+"return "tokenTable[match_pos].name";");
               if (wid != 0) progress_increment(wid);
            }
            if (use_switch) {
               if (insertedMatch && doNotGenerateDefault) {
                  insert_line(indent2:+"break;");
               } else {
                  insert_line("");
               }
            }
            tokenTable[match_pos].name=null;
            continue;
         }
   
         if (match_count >= 2) {
   
            if (!isIdentifier(prefix) && defaultTokenCase!=null && exact_match<0) {
               insert_line(indent2:+"ch = peekCharUnchecked();");
               if (match_chars._length()==1) {
                  if (!caseSensitive && isalpha(substr(tokenTable[match_pos].token,posn+1,1))) {
                     insert_line(indent2:+"if (ch != '"escapeChars(lowcase(substr(tokenTable[match_pos].token,posn+1,1)))"' && ch != '"escapeChars(upcase(substr(tokenTable[match_pos].token,posn+1,1)))"') {");
                  } else {
                     insert_line(indent2:+"if (ch != '"escapeChars(substr(tokenTable[match_pos].token,posn+1,1))"') {");
                  }
               } else {
                  insert_line(indent2:+"switch (ch) {");
                  for (j=0; j<match_chars._length(); ++j) {
                     if (!caseSensitive && isalpha(match_chars[j])) {
                        insert_line(indent2:+"case '"escapeChars(lowcase(match_chars[j]))"':");
                        insert_line(indent2:+"case '"escapeChars(upcase(match_chars[j]))"':");
                        id_chars_used:[lowcase(match_chars[j])] = true;
                        id_chars_used:[upcase(match_chars[j])] = true;
                     } else {
                        insert_line(indent2:+"case '"escapeChars(match_chars[j])"':");
                        id_chars_used:[match_chars[j]] = true;
                     }
                  }
                  insert_line(indent3:+"break;");
                  insert_line(indent2:+"default:");
               }
               insert_line(indent3:+"return ":+defaultTokenCase.name';');
               insert_line(indent2:+"}");
               if (wid != 0) progress_increment(wid);
            }
   
            insert_line(indent2:+"ch = nextCharUnchecked();");
            if (exact_match >= 0) {
               generateSwitchStatement(prefix:+_chr(i), posn+1,
                                       tokenTable[exact_match], 
                                       tokenTable, caseSensitive,
                                       wid, switchIndent, false);
               tokenTable[exact_match].name=null;
            } else {
               generateSwitchStatement(prefix:+_chr(i), posn+1, null, 
                                       tokenTable, caseSensitive,
                                       wid, switchIndent, doNotGenerateDefault);
            }
            if (use_switch) {
               insert_line(indent2:+'break;');
               insert_line('');
            }
            continue;
         }
      }
   
      if (id_chars._length() > 0 && !doNotGenerateDefault) {
         if (use_switch) {
            for (i=0; i<id_chars._length(); ++i) {
               if (!id_chars_used._indexin(id_chars[i])) {
                  a := _asc(id_chars[i]);
                  if (keywordLeadChars != null && keywordLeadChars[a] != null && keywordLeadChars[a] == true) {
                     continue;
                  }
                  insert_line(indent1:+"case '"escapeChars(id_chars[i])"':");
               }
            }
            insert_line(indent2:+"return ":+m_parseIdentifier:+"();");
            insert_line('');
         } else if (num_cases==0) {
            insert_line(indent1:+"if (ch < 0 || ch >= 0x80 || isIdChar[ch]) {");
            insert_line(indent2:+"return ":+m_parseIdentifier:+"();");
         } else {
            insert_line(indent1:+"} else if (ch < 0 || ch >= 0x80 || isIdChar[ch]) {");
            insert_line(indent2:+"return ":+m_parseIdentifier:+"();");
         }
      }
   
      if (defaultTokenCase != null && !doNotGenerateDefault) {
         insert_line(indent1:+"// '":+escapeChars(defaultTokenCase.token)"'");
      }
      if (!doNotGenerateDefault) {
         if (use_switch) {
            insert_line(indent1:+"default:");
         } else {
            insert_line(indent1:+"} else {");
         }
      }
   
      if (!doNotGenerateDefault) {
         if (defaultTokenCase != null) {
            insert_line(indent2:+"return ":+defaultTokenCase.name";");
            if (wid != 0) progress_increment(wid);
         } else if (isIdentifier(prefix)) {
            insert_line(indent2:+"return "m_tokenIdentifier";");
         } else {
            if (m_extendedIdentifierChars) {
               insert_line(indent2:+"if (ch < 0 || ch >= 0x80 ) {");
               insert_line(indent3:+"return ":+m_parseIdentifier:+"();");
               insert_line(indent2:+"}");
            }
            if (prefix=='') {
               insert_line(indent2:+"ch = nextChar();");
            }
            insert_line(indent2:+"return ":+m_parseGarbageChar:+"();");
         }
      }
   
      insert_line(indent1:+"}");
   }
   
   /**
    * Separate the tokens from the token table out into groups by length 
    * for keywords and a separate group for non-keyword tokens. 
    * 
    * @param tokenTable        (input)  complete token table 
    * @param caseSensitive     (input)  case sensitive keyword match?
    * @param keywordsByLength  (output) array of arrays of keyword tokens by length 
    * @param nonKeywordTokens  (output) array of non-keyword tokens 
    * @param keywordLeadChars  (output) bit set of character values which are
    *                                   leading characters of keywords
    */
   void separateKeywordTokensByLength(TokenNamePair (&tokenTable)[], 
                                      boolean caseSensitive, 
                                      TokenNamePair (&keywordsByLength)[][],
                                      TokenNamePair (&nonKeywordTokens)[], 
                                      boolean (&keywordLeadChars)[] )
   {
      keywordLeadChars = null;
      for (i:=0; i<tokenTable._length(); i++) {
         TokenNamePair tk = tokenTable[i];
         if (isinteger(substr(tk.token, 1, 1))) {
            nonKeywordTokens[nonKeywordTokens._length()] = tk;
         } else if (isIdentifier(tk.token)) {
            tokLength := length(tk.token);
            nextIndex := keywordsByLength[tokLength]._length();
            keywordsByLength[tokLength][nextIndex] = tk;
            if (caseSensitive) {
               keywordLeadChars[_asc(first_char(tk.token))] = true;
            } else {
               keywordLeadChars[_asc(lowcase(first_char(tk.token)))] = true;
               keywordLeadChars[_asc(upcase(first_char(tk.token)))] = true;
            }
         } else if (isIdentifier(first_char(tk.token))) {
            startOfToken := tk.token;
            while (!isIdentifier(startOfToken)) {
               startOfToken = substr(startOfToken, 1, length(startOfToken)-1);
            }
            tokLength := length(startOfToken);
            nextIndex := keywordsByLength[tokLength]._length();
            keywordsByLength[tokLength][nextIndex] = tk;
            if (caseSensitive) {
               keywordLeadChars[_asc(first_char(tk.token))] = true;
            } else {
               keywordLeadChars[_asc(lowcase(first_char(tk.token)))] = true;
               keywordLeadChars[_asc(upcase(first_char(tk.token)))] = true;
            }
         } else if (isIdentifier(first_char(tk.token))) {
            m_separateKeyordsByLength = false;
            nonKeywordTokens[nonKeywordTokens._length()] = tk;
         //} else if (isIdentifier(last_char(tk.token))) {
            //say("FAIL LAST token="tk.token);
            //m_separateKeyordsByLength = false;
            //nonKeywordTokens[nonKeywordTokens._length()] = tk;
         } else {
            nonKeywordTokens[nonKeywordTokens._length()] = tk;
         }
      }
   }
   
   /**
    * Generate a function to test if the given character is an ID character 
    * or not. 
    */
   void generateIsIdFunction(_str functionName = "isIdentifierChar")
   {
      _str indent1 = substr('',1,1*p_SyntaxIndent);

      _str isIdCharString[];
      for (i:=0; i<4; i++) {
         isIdCharString[i] = "";
         for (j:=0; j<32; j++) {
            k := i*32 + j;
            if (k >= 0x80) {
               if (m_extendedIdentifierChars) {
                  strappend(isIdCharString[i], "1,");
               } else {
                  strappend(isIdCharString[i], "0,");
               }
            } else if (isIdentifier("a":+_chr(k)) || isIdentifier("A":+_chr(k)) ||
                       isIdentifier(_chr(k):+"a") || isIdentifier(_chr(k):+"A")) {
               strappend(isIdCharString[i], "'"escapeChars(_chr(k))"',");
            } else {
               strappend(isIdCharString[i], "0,");
            }
         }
      }
      isIdCharString[3] = strip(isIdCharString[3], "T", ",");

      insert_line('/**');
      insert_line(' * This table was generated using CPPLexerGenerator.e, DO NOT EDIT.');
      insert_line(' */');
      insert_line("static const char isIdChar[] = {");
      for (i=0; i<4; i++) {
         insert_line(indent1:+isIdCharString[i]);
      }
      insert_line("};");
      insert_line("");

      if (functionName != "") {
         insert_line('/**');
         insert_line(' * This function was generated using CPPLexerGenerator.e, DO NOT EDIT.');
         insert_line(' */');
         insert_line("bool "m_lexerClassName"::"functionName"(int ch) const");
         insert_line("{");
         if (m_extendedIdentifierChars) {
            insert_line(indent1:+"return (ch < 0 || ch >= 0x80 || isIdChar[ch]);");
         } else {
            insert_line(indent1:+"return (ch >= 0 && ch < 0x80 && isIdChar[ch]);");
         }
         insert_line("}");
         insert_line("");
      }
   }
      
   /**
    * Generate the entire parse function for this lexer.
    * 
    * @param tokenTable    Table of tokens to recognize 
    * @param caseSensitive Are keywords and identifiers case sensitive?
    * @param functionName  What should the function be named (default is "parse")
    */
   void generateParseFunction(TokenNamePair (&tokenTable)[], 
                              boolean caseSensitive=true,
                              _str functionName = "parse")
   {
      int wid = progress_show("Generating "m_lexerClassName"::"functionName"()", tokenTable._length());

      _str indent1 = substr('',1,1*p_SyntaxIndent);
      _str indent2 = substr('',1,2*p_SyntaxIndent);
      _str indent3 = substr('',1,3*p_SyntaxIndent);
      _str indent4 = substr('',1,4*p_SyntaxIndent);

      insert_line('/**');
      insert_line(' * This function was generated using CPPLexerGenerator.e, DO NOT EDIT.');
      insert_line(' */');
      insert_line(m_tokenEnumName" "m_lexerClassName"::"functionName"()");
      insert_line("{");
      insert_line(indent1:+"// get the current character from the input");
      insert_line(indent1:+"int ch=currentChar();");
      if (m_parseFunctionProlog != "") insert_line(indent1:+m_parseFunctionProlog);

      TokenNamePair nonKeywordTokens[];
      TokenNamePair keywordTokensByLength[][];
      boolean keywordLeadChars[];
      boolean onlyGenerateCases = false;
      separateKeywordTokensByLength(tokenTable, 
                                    caseSensitive,
                                    keywordTokensByLength,
                                    nonKeywordTokens, 
                                    keywordLeadChars );

      if (m_separateKeyordsByLength && keywordTokensByLength._length() > 0) {
         // if we are generating a pre-screen for keywords, then reduce
         // the token table to just non-keyword tokens.
         tokenTable = nonKeywordTokens;
         onlyGenerateCases = true;

         // now we generate a switch to pre-screen lead characters for identfiers
         insert_line(indent1:+"switch(ch) {");
         for (i:=0; i<keywordLeadChars._length(); i++) {
            if (keywordLeadChars[i] != null && keywordLeadChars[i] == true) {
               insert_line(indent1:+"case '":+escapeChars(_chr(i))"':");
            }
         }

         // and then parse to the end of the identifier
         insert_line(indent2:+"{");
         insert_line(indent3:+"const char *startPos = currentBuffer();");
         insert_line(indent3:+"const char *endPos = startPos;");
         insert_line(indent3:+"while (isIdChar[(unsigned char)*(++endPos)]);");
         insert_line(indent3:+"size_t identifierLength = (endPos - startPos);");

         // and then switch on the leng of the identifier, and then
         // generate a switch on the keywords of that length
         insert_line(indent3:+"switch (identifierLength) {");
         for (i=1; i < keywordTokensByLength._length(); i++) {
            keywordTokens := keywordTokensByLength[i];
            if (keywordTokens != null && keywordTokens._length() > 0) {
               insert_line(indent3:+"case "i":");
               generateSwitchStatement('',1,null,keywordTokens,caseSensitive,wid,indent3,true);
               insert_line(indent4:+"break;");
               insert_line("");
            }
         }

         // unrecognized length, skip to last char and
         // parse the rest of the identifier
         insert_line(indent3:+"default:");
         insert_line(indent4:+"// skip to end of identifier");
         insert_line(indent4:+"skipCharUnchecked(identifierLength);");
         insert_line(indent4:+"return ":+m_tokenIdentifier:+";");

         // end of identifier length switch
         insert_line(indent3:+"}");

         // generate code to parse the rest of the identifier
         insert_line(indent3:+"// skip to end of identifier");
         insert_line(indent3:+"skipCharUnchecked(endPos - currentBuffer());");
         insert_line(indent3:+"return ":+m_tokenIdentifier:+";");

         // end of lead character case statement block
         insert_line(indent2:+"}");
         insert_line("");
      } else {
         keywordLeadChars = null;
         m_separateKeyordsByLength = false;
      }

      // now generate a switch for the remaining tokens.
      generateSwitchStatement('',1,null,
                              tokenTable,caseSensitive, 
                              wid,'',false, 
                              onlyGenerateCases, keywordLeadChars);

      // end of function
      insert_line("}");
      insert_line("");
      progress_close(wid);
   }

   /**
    * Open a fresh new file for generating the parse function.
    * 
    * @param origLine   (output only) original line position in file 
    * 
    * @return int       0 on success, <0 on error 
    */
   int startLexerFile(int &origLine)
   {
      // open the file name
      fileName := m_lexerClassName:+"Gen.cpp";
      int status = edit(maybe_quote_filename(fileName));
      if (status && status!=NEW_FILE_RC) {
         message(get_message(status));
         return(status);
      }
   
      origLine=p_RLine;
      delete_all();

      if (m_lexerClassInclude == "") {
         m_lexerClassInclude = m_lexerClassName:+".h";
      }
      if (m_tokenClassInclude == "") {
         m_tokenClassInclude = m_tokenClassName:+".h";
      }
      if (m_tokenEnumInclude == "") {
         m_tokenEnumInclude = m_tokenEnumName:+".h";
      }

      insert_line("#include \"":+m_lexerClassInclude:+"\"");
      insert_line("#include \"":+m_tokenClassInclude:+"\"");
      if (m_tokenEnumInclude != m_tokenClassInclude) {
         insert_line("#include \"":+m_tokenEnumInclude:+"\"");
      }
      insert_line('');

#if 0
      // This doesn't work with GCC 4.4.2
      insert_line("#if __GCC__");
      insert_line("#pragma GCC diagnostic ignored \"-Wno-multichar\"");
      insert_line("#endif");
      insert_line('');
#endif

      return 0;
   }

   /**
    * Finish working with the lexer file, restore the line position 
    * to the given line. 
    * 
    * @param origLine   Original current line before building new file
    */
   void finishLexerFile(int origLine)
   {
      p_RLine=origLine;
   }

   /**
    * Simple generic function to generate a complete lexer file. 
    * The generated file will be left open as the current active buffer. 
    * 
    * @param tokenTable    Table of tokens to recognize 
    * @param caseSensitive Are keywords and identifiers case sensitive?
    */
   void generateLexer(TokenNamePair (&tokenTable)[], boolean caseSensitive=true)
   {
      if (startLexerFile(auto origLine=0)) return;
      generateIsIdFunction();
      generateParseFunction(tokenTable, caseSensitive);
      finishLexerFile(origLine);
   }

};

