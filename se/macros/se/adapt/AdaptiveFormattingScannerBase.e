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
#import "stdprocs.e"
#import "main.e"
#import "markfilt.e"
#import "setupext.e"
#import "stdcmds.e"
#endregion Imports

int def_adaptive_formatting_min_indent_total=2;
int def_adaptive_formatting_min_confidence=66;

namespace se.adapt;  
#define ADAPTIVEFORMATING_DEBUG 0


/**
 * Return codes used by adaptive formatting.
 */
enum AdaptiveFormattingRC {
   AF_RC_SUCCESS = 0,
   AF_RC_UNAVAILABLE = -1,
   AF_RC_ERROR = -2,
};

/** 
 * Holds the indent settings used by adaptive formatting.
 * These are stored together since they are inferred together.
 * 
 */
struct AFIndentSettings {
   int SyntaxIndent;
   int IndentWithTabs;
   _str Tabs;
};

/** 
 * Holds the parenthesis settings used by adaptive formatting.
 * These are stored together since they are inferred together.
 * 
 */
struct AFParenSettings {
   int NoSpaceBeforeParen;
   int PadParens;
};

/** 
 * Base class for the Adaptive Formatter.  This class is not
 * meant to be used directly, but only as a base class.
 * 
 */
class AdaptiveFormattingScannerBase {
   /*
     Beware of slow "edit *.cpp" performance. 
     Performance under windows for "edit c:\f\vslick13\macros\*.e" 
     needs to be less than 10 seconds!
   */
   const MAX_SCAN= 20;

   // keeps track of the extension of the file we're working with 
   protected _str m_language;
   // keeps track of the tallies while scanning for setting examples
   protected int m_tallies:[];
   protected int m_tally_BEStyle1;
   protected int m_tally_BEStyle2;
   protected int m_tally_BEStyle3;
   protected int m_tally_Probably_Indent4_Tabs8;
   protected int m_tally_Probably_Not_Indent4_Tabs8;
   protected int m_tally_Indent4_Tabs8;
   protected int m_tally_Indent_Tabs;
   protected int m_tally_Indent_Spaces;
   protected int m_tally_Space_Before_Paren;
   protected int m_tally_No_Space_Before_Paren;
   protected int m_tally_Pad_Parens;
   protected int m_tally_No_Pad_Parens;
   protected int m_tally_Indent_Case;
   protected int m_tally_No_Indent_Case;
   protected int m_tally_Keyword_Casing_Upper;
   protected int m_tally_Keyword_Casing_Lower;
   protected int m_tally_Keyword_Casing_Preserve;
   protected int m_tally_Keyword_Casing_Cap;
   protected int m_tally_Tag_Casing_Upper;
   protected int m_tally_Tag_Casing_Lower;
   protected int m_tally_Tag_Casing_Preserve;
   protected int m_tally_Tag_Casing_Cap;
   protected int m_tally_Attribute_Casing_Upper;
   protected int m_tally_Attribute_Casing_Lower;
   protected int m_tally_Attribute_Casing_Preserve;
   protected int m_tally_Attribute_Casing_Cap;
   protected int m_tally_Value_Casing_Upper;
   protected int m_tally_Value_Casing_Lower;
   protected int m_tally_Value_Casing_Preserve;
   protected int m_tally_Value_Casing_Cap;
   protected int m_tally_Hex_Value_Casing_Upper;
   protected int m_tally_Hex_Value_Casing_Lower;
   protected int m_tally_Hex_Value_Casing_Preserve;
   protected int m_tally_Hex_Value_Casing_Cap;
   // keeps track of the formatting options available for this particular 
   // scanner (extension)
   protected int m_available;

   /** 
    * Constructor.  Note that Indent Settings are always ORed into 
    * the value, as all extensions support having their indent 
    * settings inferred. 
    * 
    * @param available        available flags (a combination of 
    *                         AdaptiveFormattingFlags)
    * 
    */
   AdaptiveFormattingScannerBase(int available = 0, _str lang = '')
   {
      if (lang=='') lang=_mdi.p_child.p_LangId;
      m_language = lang;
      m_available = available;
      m_available |= (AFF_INDENT_WITH_TABS | AFF_TABS | AFF_SYNTAX_INDENT);

      m_tally_BEStyle1=0;
      m_tally_BEStyle2=0;
      m_tally_BEStyle3=0;
      m_tally_Probably_Indent4_Tabs8=0;
      m_tally_Probably_Not_Indent4_Tabs8=0;
      m_tally_Indent4_Tabs8=0;
      m_tally_Indent_Tabs=0;
      m_tally_Indent_Spaces=0;
      m_tally_Space_Before_Paren=0;
      m_tally_No_Space_Before_Paren=0;
      m_tally_Pad_Parens=0;
      m_tally_No_Pad_Parens=0;
      m_tally_Indent_Case=0;
      m_tally_No_Indent_Case=0;
      m_tally_Keyword_Casing_Upper=0;
      m_tally_Keyword_Casing_Lower=0;
      m_tally_Keyword_Casing_Preserve=0;
      m_tally_Keyword_Casing_Cap=0;
      m_tally_Tag_Casing_Upper=0;
      m_tally_Tag_Casing_Lower=0;
      m_tally_Tag_Casing_Preserve=0;
      m_tally_Tag_Casing_Cap=0;
      m_tally_Attribute_Casing_Upper=0;
      m_tally_Attribute_Casing_Lower=0;
      m_tally_Attribute_Casing_Preserve=0;
      m_tally_Attribute_Casing_Cap=0;
      m_tally_Value_Casing_Upper=0;
      m_tally_Value_Casing_Lower=0;
      m_tally_Value_Casing_Preserve=0;
      m_tally_Value_Casing_Cap=0;
      m_tally_Hex_Value_Casing_Upper=0;
      m_tally_Hex_Value_Casing_Lower=0;
      m_tally_Hex_Value_Casing_Preserve=0;
      m_tally_Hex_Value_Casing_Cap=0;
   }
   _str getLangId() {
      return(m_language);
   }

   /** 
    * Initializes the tallies with the keys that will be used by
    * the scanner.
    * 
    */
   protected void initTallies()
   {
      m_tallies._makeempty();
      m_tally_BEStyle1=0;
      m_tally_BEStyle2=0;
      m_tally_BEStyle3=0;
      m_tally_Probably_Indent4_Tabs8=0;
      m_tally_Probably_Not_Indent4_Tabs8=0;
      m_tally_Indent4_Tabs8=0;
      m_tally_Indent_Tabs=0;
      m_tally_Indent_Spaces=0;
      m_tally_Space_Before_Paren=0;
      m_tally_No_Space_Before_Paren=0;
      m_tally_Pad_Parens=0;
      m_tally_No_Pad_Parens=0;
      m_tally_Indent_Case=0;
      m_tally_No_Indent_Case=0;
      m_tally_Keyword_Casing_Upper=0;
      m_tally_Keyword_Casing_Lower=0;
      m_tally_Keyword_Casing_Preserve=0;
      m_tally_Keyword_Casing_Cap=0;
      m_tally_Tag_Casing_Upper=0;
      m_tally_Tag_Casing_Lower=0;
      m_tally_Tag_Casing_Preserve=0;
      m_tally_Tag_Casing_Cap=0;
      m_tally_Attribute_Casing_Upper=0;
      m_tally_Attribute_Casing_Lower=0;
      m_tally_Attribute_Casing_Preserve=0;
      m_tally_Attribute_Casing_Cap=0;
      m_tally_Value_Casing_Upper=0;
      m_tally_Value_Casing_Lower=0;
      m_tally_Value_Casing_Preserve=0;
      m_tally_Value_Casing_Cap=0;
      m_tally_Hex_Value_Casing_Upper=0;
      m_tally_Hex_Value_Casing_Lower=0;
      m_tally_Hex_Value_Casing_Preserve=0;
      m_tally_Hex_Value_Casing_Cap=0;
   }
   /** 
    * Given that the cursor is on a keyword, examines whether it is 
    * uppercase, lowercase, capitalized, or something ca-razy. 
    * Resulting case is added to tallies table. 
    * 
    * @return int             total examples we found
    */
   protected int examineKeywordCasing(_str curWord,_str wordType = 'K')
   {
      if (curWord=='') return(0);
      switch (upcase(wordType)) {
      case 'T':
         if (curWord == lowcase(curWord)) {
            ++m_tally_Tag_Casing_Lower;
         } else if (curWord == upcase(curWord)) {
            ++m_tally_Tag_Casing_Upper;
         } else if (curWord == _cap_word(curWord)) {
            ++m_tally_Tag_Casing_Cap;
         } else {
            ++m_tally_Tag_Casing_Preserve;
         }
         return(1);
      case 'A':
         if (curWord == lowcase(curWord)) {
            ++m_tally_Attribute_Casing_Lower;
         } else if (curWord == upcase(curWord)) {
            ++m_tally_Attribute_Casing_Upper;
         } else if (curWord == _cap_word(curWord)) {
            ++m_tally_Attribute_Casing_Cap;
         } else {
            ++m_tally_Attribute_Casing_Preserve;
         }
         return(1);
      case 'V':
         if (curWord == lowcase(curWord)) {
            ++m_tally_Value_Casing_Lower;
         } else if (curWord == upcase(curWord)) {
            ++m_tally_Value_Casing_Upper;
         } else if (curWord == _cap_word(curWord)) {
            ++m_tally_Value_Casing_Cap;
         } else {
            ++m_tally_Value_Casing_Preserve;
         }
         return(1);
      case 'H':
         if (curWord == lowcase(curWord)) {
            ++m_tally_Hex_Value_Casing_Lower;
         } else if (curWord == upcase(curWord)) {
            ++m_tally_Hex_Value_Casing_Upper;
         } else if (curWord == _cap_word(curWord)) {
            ++m_tally_Hex_Value_Casing_Cap;
         } else {
            ++m_tally_Hex_Value_Casing_Preserve;
         }
         return(1);
      }
      if (curWord == lowcase(curWord)) {
         ++m_tally_Keyword_Casing_Lower;
      } else if (curWord == upcase(curWord)) {
         ++m_tally_Keyword_Casing_Upper;
      } else if (curWord == _cap_word(curWord)) {
         ++m_tally_Keyword_Casing_Cap;
      } else {
         ++m_tally_Keyword_Casing_Preserve;
      }
      return 1;
   }

   /** 
    * Returns whether a given setting is available to be inferred 
    * by the current scanner. 
    * 
    * @param f             flag to check for
    * 
    * @return bool         whether setting is available
    */
   public bool isSettingAvailable(AdaptiveFormattingFlags f)
   {
      return((m_available & f) != 0);
   }

   /** 
    * Makes sure that the embedded name of the current line is the 
    * same as the one where the cursor was when we started 
    * scanning.  Jumps to where the embedded names match or breaks 
    * if there are no more matches in this file. 
    * 
    * @param embedLex         name of embedded lexer to look for
    */
   protected int findNextEmbeddedRegion(_str embedLex)
   {
      for (;;) {
         int status;
         if (embedLex=='') {
            // Search for non-embedded text
            status = _clex_find(0, 'S');
            if (status) return(status);
         } else {
            // Search for embedded text
            status = _clex_find(0, 'E');
            if (status) return(status);
         }
         // make sure first character of this line is not in embedded text.
         orig_col := p_col;
         p_col=1;
         if (p_EmbeddedLexerName==embedLex) {
            p_col=orig_col;
            return(0);
         }
         status=down();
         if (status) return(status);
      }
   }

   /** 
    * Override this method.  Do it now. 
    *  
    * In child classes, this method will be the main worker bee for 
    * this class. 
    * 
    * @param flags         flags to scan for
    * @param cap           maximum number of examples to find
    */
   protected void scan(int flags, int cap = MAX_SCAN)
   {
      say("This method has not yet been implemented");
   }

   /** 
    * Runs a manual scan of the current buffer and then displays
    * the results.  Scans for all settings supported by this
    * scanner.
    * 
    */
   public void manualAdaptiveFormattingScan()
   {
      // scan for all settings, with no cap
      scan(m_available);
      show("_adaptive_format_results", &this, m_available);
   }

   /** 
    * Runs an "automatic" scan for the current buffer and flags.
    * 
    * @param flags      flags to scan for
    */
   public void automaticAdaptiveFormattingScan(int flags)
   {
      scan(flags, MAX_SCAN);
   }

   public int getAvailableSettings()
   {
      return m_available;
   }

   /*
      These methods can be overridden if you need special fuzzy 
      math for your scanner.
   */
#region Calculate Results Methods

   /** 
    * Calculates the brace style from the tallies.  Note that a 
    * scan must have been run prior to using this or you'll get 
    * nothing good.  
    * 
    * @param braceStyle       winning brace style
    * 
    * @return int             0 for success, 1 for error
    */
   protected int calculateBraceStyle(int &braceStyle)
   {
      // find out who had the most hits
      braceStyle = 0;
      int most = m_tally_BEStyle1;
      if (m_tally_BEStyle2 > most) {
         braceStyle = BES_BEGIN_END_STYLE_2;
         most = m_tally_BEStyle2;
      }
      if (m_tally_BEStyle3 > most) {
         braceStyle = BES_BEGIN_END_STYLE_3;
         most = m_tally_BEStyle3;
      }
      int total=m_tally_BEStyle1+m_tally_BEStyle2+m_tally_BEStyle3;
      int incidence=most;
      if ( !total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence) {
         //_message_box('not confident incidence='incidence' total='total' r='((incidence / total)*100));
         return(AF_RC_ERROR);
      }
      if (most > 0) {
         return AF_RC_SUCCESS;
      } else {
         return AF_RC_ERROR;
      }
   }

   /** 
    * Calculates the indent settings from the tallies.  Note that a 
    * scan must have been run prior to using this or you'll get 
    * nothing good.  
    * 
    * @param is         indent settings
    * 
    * @return int       0 for success, 1 for error
    */
   protected int calculateIndentSettings(AFIndentSettings &is)
   {
      bool error;
      int indent = AF_RC_ERROR, incidence = 0;
      total := 0;

      // find the highest incidence
      typeless i;
      for (i._makeempty();;) {
         m_tallies._nextel(i);
         if (i._isempty()) break;
         if (pos('Indent = [0-9]#$', i, 1, 'r')) {
            total+=m_tallies:[i];
#if ADAPTIVEFORMATING_DEBUG
            _message_box(i' count='m_tallies:[i]', total now equals 'total);
#endif
            if (m_tallies:[i] > incidence) {
               _str strIndent;
               parse i with 'Indent = 'strIndent;
               indent=(int)strIndent;
               incidence = m_tallies:[i];
            } else if (m_tallies:[i]==incidence) {
               _str strIndent;
               parse i with 'Indent = 'strIndent;
               int newIndent=(int)strIndent;
               if (newIndent<indent) {
                  indent=newIndent;
                  incidence = m_tallies:[i];
               }
            }
         }
      }
      if (total<def_adaptive_formatting_min_indent_total) {
         //_message_box("not enough changes in indent total="total);
         indent=AF_RC_ERROR;
      } else if ( !total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence) {
         //_message_box('not confident incidence='incidence' total='total' r='((incidence / total)*100));
         indent=AF_RC_ERROR;
      }
      error = (indent == AF_RC_ERROR);
      is.SyntaxIndent = indent;

      /*
         Can't support setting tab stops or syntax indent for Fortran
         or COBOL because it has complex tab stops.
      */
      VS_LANGUAGE_OPTIONS langOptions;
      _GetDefaultLanguageOptions(m_language, langOptions);
      if (langOptions != null ) {
         szTabs:=_LangOptionsGetProperty(langOptions,VSLANGPROPNAME_TABS);
         parse szTabs with auto n1 auto n2 auto rest;
         if (!(rest=='' && isinteger(n1) && isinteger(n2))) {
            parse szTabs with n1 '+' n2 rest;
            if (!(rest=='' && n1=='' && isinteger(n2))) {
               error=true;
            }
         }
      }

      // set our tabs - this may change later
      if (!error) {
         is.Tabs= '+'indent;
      } else {
         is.Tabs= '';
      }

      if (m_tally_Indent_Tabs || m_tally_Indent_Spaces) {
         int space = m_tally_Indent_Spaces;
#if ADAPTIVEFORMATING_DEBUG
         _message_box('indent with tabs='m_tally_Indent_Tabs);
#endif
         // set indent with tabs
         tab_space_error := false;

         int tab_space_total=m_tally_Indent_Tabs+space;
         int tab_space_incidence=(m_tally_Indent_Tabs>space)?m_tally_Indent_Tabs:space;
         if (tab_space_total<def_adaptive_formatting_min_indent_total) {
            tab_space_error=true;
         } else if ( !tab_space_total || (tab_space_incidence*100 intdiv tab_space_total) < def_adaptive_formatting_min_confidence) {
            tab_space_error=true;
         }
         if (tab_space_error) {
            is.IndentWithTabs = AF_RC_ERROR;
         } else {
            is.IndentWithTabs=(m_tally_Indent_Tabs > space)?1:0;
         }
#if ADAPTIVEFORMATING_DEBUG
         _message_box('m_tally_Indent_Tabs='m_tally_Indent_Tabs' m_tally_Indent_Spaces='m_tally_Indent_Spaces);
         _message_box('h1 probably='m_tally_Probably_Indent4_Tabs8' probably not='m_tally_Probably_Not_Indent4_Tabs8);
#endif
         /*
            NOTE: This is does not use a confidence level.  This means that 
            IndentWithTabs could be -2 and the user setting for indent
            with tabs could be off and we will changes the tabs to +8.  We might need
            to use some kind of confidence level in the future.
         */
         if (indent==4 && m_tally_Probably_Indent4_Tabs8>=2 && 
             m_tally_Probably_Indent4_Tabs8>m_tally_Probably_Not_Indent4_Tabs8
            ) {
#if ADAPTIVEFORMATING_DEBUG
            _message_box('set indent=4 tabs +8 error='error);
#endif
            // IF we didn't get an error calculating p_indent
            if (!error) {
               is.Tabs = '+8';
            }
         } else if (indent == 4 && is.IndentWithTabs && is.Tabs == "+4") {
            // we synthetically got +4 for tabs by setting p_tabs = +4.  So if we got here, 
            // we don't really know what's going on.  Use the default settings if we can.
            // by setting these to ERROR, we'll know that we couldn't figure anything out 
            // and just use the defaults
            is.SyntaxIndent = AF_RC_ERROR;
            is.Tabs = '';
         }
#if ADAPTIVEFORMATING_DEBUG
         _message_box('is.Tabs='is.Tabs);
#endif

      } else {       // set the values equal to error codes
         is.SyntaxIndent=AF_RC_ERROR;
         is.IndentWithTabs = AF_RC_ERROR;
         is.Tabs = '';

         // only return ERROR if all settings were screwy
         if (error) return AF_RC_ERROR;
      }

      if (is.SyntaxIndent == AF_RC_ERROR && is.IndentWithTabs == AF_RC_ERROR && (is.Tabs == '' || is.Tabs == AF_RC_ERROR)) {
         return AF_RC_ERROR;
      }

      return AF_RC_SUCCESS;
   }

   /** 
    * Calculates the parenthesis-based settings based on the 
    * tallies.  Note that a scan must have been run prior to using 
    * this or you'll get nothing good.  
    * 
    * @param ps            parenthesis settings
    * 
    * @return int          0 for success, 1 for error
    */
   protected int calculateParenSettings(AFParenSettings &ps)
   {
      // spaces before parens
      int total=m_tally_Space_Before_Paren+m_tally_No_Space_Before_Paren;
      int incidence=(m_tally_Space_Before_Paren>=m_tally_No_Space_Before_Paren)?m_tally_Space_Before_Paren:m_tally_No_Space_Before_Paren;
      error := (!total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence);
      if (!error) {
         if (m_tally_Space_Before_Paren > m_tally_No_Space_Before_Paren) {
            ps.NoSpaceBeforeParen = 0;
         } else {
            ps.NoSpaceBeforeParen = 1;
         }
      } else {
         ps.NoSpaceBeforeParen = AF_RC_ERROR;
         error = true;
      }

      // padding between parens
      total=m_tally_Pad_Parens+m_tally_No_Pad_Parens;
      incidence=(m_tally_Pad_Parens>=m_tally_No_Pad_Parens)?m_tally_Pad_Parens:m_tally_No_Pad_Parens;
      error2 := (!total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence);
      if (!error2) {
         if (m_tally_Pad_Parens > m_tally_No_Pad_Parens) {
            ps.PadParens = 1;
         } else {
            ps.PadParens = 0;
         }
      } else {
         ps.PadParens = AF_RC_ERROR;

         // only return error code if both settings were screwy
         if (error) return AF_RC_ERROR;
      }

      return AF_RC_SUCCESS;
   }

   /** 
    * Calculates whether to indent case from switch based on the
    * tallies.  Note that a scan must have been run prior to using 
    * this or you'll get nothing good.  
    * 
    * @param indentCase          1 to indent case, 0 to not
    * 
    * @return int                0 for success, 1 for error
    */
   protected int calculateIndentCaseFromSwitch(int &indentCase)
   {
      // indenting case from switch
      if (m_tally_Indent_Case || m_tally_No_Indent_Case) {
         if (m_tally_Indent_Case > m_tally_No_Indent_Case) {
            indentCase = 1;
         } else {
            indentCase = 0;
         }
         int total=m_tally_Indent_Case+m_tally_No_Indent_Case;
         int incidence=(indentCase)?m_tally_Indent_Case:m_tally_No_Indent_Case;
         if ( !total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence) {
            //_message_box('not confident incidence='incidence' total='total' r='((incidence / total)*100));
            return(AF_RC_ERROR);
         }
         return AF_RC_SUCCESS;
      }
      return AF_RC_ERROR;
   }

   /** 
    * Retrieves the keys for this particular branch of casing. 
    * (Branches are keyword, tag, attribute, value, or hex value) 
    * 
    * @param lower            lowercase key
    * @param upper            uppercase key
    * @param cap              capitalize key
    * @param preserve         preserve case key
    * @param wordType         the branch that we want:  'T' for 
    *                         tag, 'A' for attribute, 'V' for
    *                         value, 'H' for hex value, 'K'
    *                         (default) for keyword.
    */
   protected void getCasingKeys(int &lower, _str &lowerMsg,
                                int &upper,_str &upperMsg,
                                int &cap, _str &capMsg,
                                int &preserve,_str &preserveMsg,
                                _str wordType = 'K') 
   {
      switch (upcase(wordType)) {
      case 'T':
         lower=m_tally_Tag_Casing_Lower;
         lowerMsg="Lowercase tags";
         upper=m_tally_Tag_Casing_Upper;
         upperMsg="Uppercase tags";
         cap=m_tally_Tag_Casing_Cap;
         capMsg="Capitalize tags";
         preserve=m_tally_Tag_Casing_Preserve;
         preserveMsg="Preserve case of tags";
         return;
      case 'A':
         lower=m_tally_Attribute_Casing_Lower;
         lowerMsg="Lowercase attributes";
         upper=m_tally_Attribute_Casing_Upper;
         upperMsg="Uppercase attributes";
         cap=m_tally_Attribute_Casing_Cap;
         capMsg="Capitalize attributes";
         preserve=m_tally_Attribute_Casing_Preserve;
         preserveMsg="Preserve case of attributes";
         return;
      case 'V':
         lower=m_tally_Value_Casing_Lower;
         lowerMsg="Lowercase values";
         upper=m_tally_Value_Casing_Upper;
         upperMsg="Uppercase values";
         cap=m_tally_Value_Casing_Cap;
         capMsg="Capitalize values";
         preserve=m_tally_Value_Casing_Preserve;
         preserveMsg="Preserve case of values";
         return;
      case 'H':
         lower=m_tally_Hex_Value_Casing_Lower;
         lowerMsg="Lowercase hex values";
         upper=m_tally_Hex_Value_Casing_Upper;
         upperMsg="Uppercase hex values";
         cap=m_tally_Hex_Value_Casing_Cap;
         capMsg="Capitalize hex values";
         preserve=m_tally_Hex_Value_Casing_Preserve;
         preserveMsg="Preserve case of hex values";
         return;
      }
      lower=m_tally_Keyword_Casing_Lower;
      lowerMsg="Lowercase keywords";
      upper=m_tally_Keyword_Casing_Upper;
      upperMsg="Uppercase keywords";
      cap=m_tally_Keyword_Casing_Cap;
      capMsg="Capitalize keywords";
      preserve=m_tally_Keyword_Casing_Preserve;
      preserveMsg="Preserve case of keywords";
      return;
   }

   /** 
    * Calculates the keyword casing settings based on the tallies. 
    * Note that a scan must have been run prior to using this or 
    * you'll get nothing good.  
    * 
    * @param indentCase          keyword casing setting, see 
    *                            WORDCASE_???
    * 
    * @return int                0 for success, 1 for error
    */
   protected int calculateKeywordCasing(int &keywordCasing, _str wordType = 'K')
   {
      // figure out our word type
      int lower, upper, cap, preserve;
      _str lowerMsg, upperMsg, capMsg, preserveMsg;
      getCasingKeys(lower, lowerMsg, upper, upperMsg, cap, capMsg, preserve, preserveMsg,wordType);

      // find out who had the most hits
      // set to lower case
      keywordCasing = WORDCASE_LOWER;
      int most = lower;

      // check for upper case
      if (upper > most) {
         keywordCasing = WORDCASE_UPPER;
         most = upper;
      }

      // check for capitalize
      if (cap > most) {
         keywordCasing = WORDCASE_CAPITALIZE;
         most = cap;
      }

      // if this was the most, it means this file is craziness 
      // and we weren't able to figure much of anything out
      if (preserve > most) {
         keywordCasing = WORDCASE_PRESERVE;
         most = preserve;
         // No language supports the preserve option.
         // May need to change this later.
         return AF_RC_ERROR;
      }
      int total=lower+upper+cap+preserve;
      int incidence=most;
      if ( !total || (incidence*100 intdiv total) < def_adaptive_formatting_min_confidence) {
         //_message_box('not confident incidence='incidence' total='total' r='((incidence / total)*100));
         return(AF_RC_ERROR);
      }
      if (most > 0) {
         return AF_RC_SUCCESS;
      } else {
         return AF_RC_ERROR;
      }
   }

#endregion Calculate Results Methods

   /*
      These methods return the value of a specific setting.  Can be 
      called to perform the scan before returning to to rely upon a previous scan.
   */
#region Get Setting Methods

   /** 
    * Returns the brace style.
    * 
    * @param braceStyle    brace style
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getBraceStyle(int &braceStyle, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_BEGIN_END_STYLE)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_BEGIN_END_STYLE, MAX_SCAN);
      }

      return calculateBraceStyle(braceStyle);
   }

   /** 
    * Returns the indent settings (syntax indent, indent with tabs, 
    * tabs). 
    * 
    * @param is            indent settings
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getIndentSettings(AFIndentSettings &is, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_SYNTAX_INDENT | AFF_TABS | AFF_INDENT_WITH_TABS, MAX_SCAN);
      }

      return calculateIndentSettings(is);
   }

   /** 
    * Returns the parenthesis settings (No space before paren and 
    * pad parens). 
    * 
    * @param ps            paren settings
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getParenSettings(AFParenSettings &ps, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_NO_SPACE_BEFORE_PAREN | AFF_PAD_PARENS, MAX_SCAN);
      }

      return calculateParenSettings(ps);
   }

   /** 
    * Returns whether to indent case from switch 
    * 
    * @param ps            1 to indent case, 0 to not
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getIndentCaseFromSwitch(int &indentCase, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_INDENT_CASE)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_INDENT_CASE, MAX_SCAN);
      }

      return calculateIndentCaseFromSwitch(indentCase);
   } 


   /** 
    * Returns the keyword casing setting (see WORDCASE_???).
    * 
    * @param casing        keyword casing
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getKeywordCasing(int &casing, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_KEYWORD_CASING)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_KEYWORD_CASING, MAX_SCAN);
      }

      return calculateKeywordCasing(casing);
   }


   /** 
    * Returns the tag casing setting (see WORDCASE_???).
    * 
    * @param casing        tag casing
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getTagCasing(int &casing, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_TAG_CASING)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_TAG_CASING, MAX_SCAN);
      }

      return calculateKeywordCasing(casing, 'T');
   }


   /** 
    * Returns the attribute casing setting (see WORDCASE_???).
    * 
    * @param casing        attribute casing
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getAttributeCasing(int &casing, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_ATTRIBUTE_CASING)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_ATTRIBUTE_CASING, MAX_SCAN);
      }

      return calculateKeywordCasing(casing, 'A');
   }


   /** 
    * Returns the value casing setting (see WORDCASE_???).
    * 
    * @param casing        value casing
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getValueCasing(int &casing, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_VALUE_CASING)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_VALUE_CASING, MAX_SCAN);
      }

      return calculateKeywordCasing(casing, 'V');
   }


   /** 
    * Returns the hex value casing setting (see WORDCASE_???).
    * 
    * @param casing        hex value casing
    * @param doScan        whether to scan now or use existing scan 
    *                      results.  If a scan was not previously
    *                      performed and this is false, error is
    *                      returned.  If this value is true, a
    *                      limited scan will be performed.
    * 
    * @return int          -2 - error, 0 - success, -1 - not 
    *                      available for extension
    */
   public int getHexValueCasing(int &casing, bool doScan = true)
   {
      // make sure this setting is available
      if (!isSettingAvailable(AFF_HEX_VALUE_CASING)) return AF_RC_UNAVAILABLE;

      // limit the amount of scanning we do
      if (doScan) {
         scan(AFF_HEX_VALUE_CASING, MAX_SCAN);
      }

      return calculateKeywordCasing(casing, 'H');
   }

#region Statistics

   /** 
    * Compiles a string that constitutes a statistic.  String 
    * consists of the caption of the value, the actual count of the 
    * value, and the percentage of the whole.  These parts are 
    * returned tabbed delimited for use in a tree with columns. 
    * 
    * @param value         count for statistics
    * @param total         total count for all values
    * @param caption       caption for this value
    * 
    * @return _str         compile string
    */
   private _str compileStat(double value, int total, _str caption)
   {
      // get the percentage
      percent := round(value / (double)total * 100);

      // format to #.## 
      _str strPer = percent;
      decPos := pos('.', strPer);
      if (!decPos) {
         strPer :+= '.' :+ substr('', 1, 2, '0');
      } else if (strPer._length() - decPos < 2) {
         strPer :+= substr('', 1, strPer._length() - decPos, '0');
      }

      // put it together now
      return caption\tvalue\t''strPer'%';
   }

   /** 
    * Gets the statistics for one branch of casing.
    * 
    * @param stats            array for stats to go into
    * @param wordType         type of casing stats wanted - 'T' for 
    *                         tag, 'A' for attribute, 'V' for
    *                         value, 'H' for hex value, 'K'
    *                         (default) for keyword.
    */
   private void getCasingStatistics(_str (&stats)[], _str wordType = 'K')
   {
      int lower, upper, cap, preserve;
      _str lowerMsg, upperMsg, capMsg, preserveMsg;
      getCasingKeys(lower, lowerMsg, upper, upperMsg, cap, capMsg, preserve, preserveMsg,wordType);
      // No language supports the preserve option.

      total := lower + upper + cap+ preserve;
      if (total) {
         // add the group heading
         switch (upcase(wordType)) {
         case 'T':
            stats[stats._length()] = "Tag Casing";
            break;
         case 'A':
            stats[stats._length()] = "Attribute Casing";
            break;
         case 'V':
            stats[stats._length()] = "Value Casing";
            break;
         case 'H':
            stats[stats._length()] = "Hex Value Casing";
            break;
         default:
            stats[stats._length()] = "Keyword Casing";
            break;
         }

         // tallies
         stats[stats._length()] = compileStat(lower, total, lowerMsg);
         stats[stats._length()] = compileStat(upper, total, upperMsg);
         stats[stats._length()] = compileStat(cap, total, capMsg);
         stats[stats._length()] = compileStat(preserve, total, preserveMsg);

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }
   }

   /** 
    * Creates a list of statistics about the scanner's most recent 
    * run.  Statistics are created to put straight into a tree for 
    * the user's viewing pleasure. 
    *  
    * Group headings are simple strings, while stats have tab 
    * characters in them to separate their columns.  All stats 
    * between a pair of group headings in the array will go under 
    * the previous group heading. 
    *  
    * If no examples a particular setting were found, then it is 
    * left out of the statistics altogether. 
    * 
    * @param stats         array of stats
    */
   public void getStatistics(_str (&stats)[])
   {
      total := 0;
      stats._makeempty();

      // syntax indent
      // go through first time and get total
      foreach (auto i => auto tally in m_tallies) {
         if (pos('Indent = [0-9]#', i, 1, 'R')) {
             total += tally;
         }
      }
      if (total) {

         // sort the keys and combine ones with small totals
         int keys[];
         other := 0;
         foreach (i => tally in m_tallies) {
            if (pos('Indent = [0-9]#', i, 1, 'R')) {
               if (100*tally intdiv total < 5) {
                  other += tally;
               } else {
                  keys[keys._length()] = i;
               }
            }
         }

         keys._sort();

         // add the group heading
         stats[stats._length()] = "Syntax Indent";

         // tallies
         for (i = 0; i < keys._length(); i++) {
            stats[stats._length()] = compileStat(m_tallies:[keys[i]], total, keys[i]);
         }
         if (other) {
            stats[stats._length()] = compileStat(other, total, "Other");
         }

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // add the probably tallies
      total = m_tally_Probably_Indent4_Tabs8 + m_tally_Probably_Not_Indent4_Tabs8;
      if (total) {
          // add the group heading
          stats[stats._length()] = "Tabs";
    
          // tallies
          stats[stats._length()] = compileStat(m_tally_Probably_Indent4_Tabs8, total, "Indent = 4, Tabs = +8");
          stats[stats._length()] = compileStat(m_tally_Probably_Not_Indent4_Tabs8, total, "Tabs = Syntax Indent");
    
          // and total
          stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // indent with tabs
      total = m_tally_Indent_Tabs + m_tally_Indent_Spaces;
      if (total) {
         // add the group heading
         stats[stats._length()] = "Indent with Tabs";

         // tallies
         stats[stats._length()] = compileStat(m_tally_Indent_Tabs, total, "Indent with tabs");
         stats[stats._length()] = compileStat(m_tally_Indent_Spaces, total, "Indent with spaces");

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // keyword casing
      getCasingStatistics(stats);
      getCasingStatistics(stats, 'T');
      getCasingStatistics(stats, 'A');
      getCasingStatistics(stats, 'V');
      getCasingStatistics(stats, 'H');

      // indent case from switch
      total = m_tally_Indent_Case + m_tally_No_Indent_Case;
      if (total) {
         // add the group heading
         stats[stats._length()] = "Indent Case From Switch";

         // tallies
         stats[stats._length()] = compileStat(m_tally_Indent_Case, total, "Indent case from switch");
         stats[stats._length()] = compileStat(m_tally_No_Indent_Case, total, "Do not indent case from switch");

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // padded parens
      total = m_tally_Pad_Parens + m_tally_No_Pad_Parens;
      if (total) {
         // add the group heading
         stats[stats._length()] = "Pad Parenthesis";

         // tallies
         stats[stats._length()] = compileStat(m_tally_Pad_Parens, total, "Pad parens");
         stats[stats._length()] = compileStat(m_tally_No_Pad_Parens, total, "Non-padded parens");

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // space before parens
      total = m_tally_Space_Before_Paren + m_tally_No_Space_Before_Paren;
      if (total) {
         // add the group heading
         stats[stats._length()] = "Space Before Parenthesis";

         // tallies
         stats[stats._length()] = compileStat(m_tally_Space_Before_Paren, total, "Space before paren");
         stats[stats._length()] = compileStat(m_tally_No_Space_Before_Paren, total, "No space before paren");

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

      // brace style
      total = m_tally_BEStyle1 + m_tally_BEStyle2 + m_tally_BEStyle3;
      if (total) {
         // add the group heading
         stats[stats._length()] = "Brace Style";

         // tallies
         stats[stats._length()] = compileStat(m_tally_BEStyle1, total, "Style 1");
         stats[stats._length()] = compileStat(m_tally_BEStyle2, total, "Style 2");
         stats[stats._length()] = compileStat(m_tally_BEStyle3, total, "Style 3");

         // and total
         stats[stats._length()] = "Total"\ttotal\t"100.00%";
      }

   }

#endregion Statistics
}
