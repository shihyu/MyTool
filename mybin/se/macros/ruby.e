////////////////////////////////////////////////////////////////////////////////////
// $Revision: 48910 $
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
#include "tagsdb.sh"
#include "color.sh"
#require "se/lang/api/LanguageSettings.e"
#import "se/tags/TaggingGuard.e"
#import "adaptiveformatting.e"
#import "alias.e"
#import "alllanguages.e"
#import "autocomplete.e"
#import "c.e"
#import "codehelp.e"
#import "codehelputil.e"
#import "context.e"
#import "ccontext.e"
#import "csymbols.e"
#import "cutil.e"
#import "main.e"
#import "notifications.e"
#import "pmatch.e"
#import "setupext.e"
#import "slickc.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "surround.e"
#import "tags.e"
#import "util.e"
#endregion

using se.lang.api.LanguageSettings;

/*
  Options for Ruby syntax expansion/indenting may be accessed from the
  Extension Options dialog ("Other", "Configuration...",
  "File Extension Setup...").  

  The extension specific options is a string of five numbers separated
  with spaces with the following meaning:


    Position       Option
       1             Syntax indent amount
       2             expansion on/off.
       3             Minimum abbreviation.  Defaults to 1.  Specify large
                     value to avoid abbreviation expansion.
       4             Modifiers and line insert.  8 if the keywords (if, while, until, unless) are
                     to be treated as modifiers instead of expandable keywords.  4 if the user wants
                     a a blank line inserted between keyword and end. 12 for both functionalities.
       5             begin/end style.  Begin/end style may be 0 or 1
                     as show below.  Default is Style 0.  Add 4 to begin/end
                     style to place a blank line between keyword and 'end'.

                      Style 0
                          if 
                             ++i
                          end

                      Style 1
                          if ()
                             ++i
                          end


       6             Indent first level of code.  Default is 1.
                     Specify 0 if you want first level statements to
                     start in column 1.
       7             Used to signify whether or not a line is placed in 
                     between a keyword and end upon syntax expansion.

*/

enum_flags RubyOptions {
/**
 * Ruby style options -- insert blank line between keyword and end
 */
   VS_RUBY_OPTIONS_INSERT_LINE_FLAG                = 0x0004,
/**
 * Ruby style options -- treats if, unless, until, and while like modifiers instead
 * of expandable keywords
 */
   VS_RUBY_OPTIONS_MODIFIER_FLAG                   = 0x0008,
};


/**
 * Extension and Mode names for the Ruby Language
 */
#define RUBY_LANGUAGE_ID 'ruby'
#define RUBY_MODE_NAME   'Ruby'

#define RUBY_ENTER_WORDS (' if def while class module unless do begin':+\
                     ' until BEGIN case for ')
#define RUBY_END_WORDS (' if for def class do case begin unless module until while ')
#define RUBY_MODIFIER_WORDS (' if unless while until ')
#define RUBY_PAREN_WORDS (' if while for def ')//class? case? module? *Need to test for complete list

defeventtab ruby_keys;
def  ' '= ruby_space;
def  '('= auto_functionhelp_key;
def  '.'= auto_codehelp_key;
def  '{'= ruby_begin;
def  'ENTER'= ruby_enter;

defload()
{
   // Set the word chars for the new extension. For most programming languages,
   // these will be the word characters
   _str word_chars="A-Za-z0-9_$@";

   // The mode name is the name that will appear in the Select Mode dialog box
   _str setup_info="MN=":+RUBY_MODE_NAME;

   // Tabs - sets the p_tabs property for new buffers created with this mode.
   // "+4"  means tabs every for spaces.  For languages with 
   // Uneven tabs, you can specify the individual columns, and then +x at the
   // end. For example, for Cobol you would specify "1 8 250 +4", which means
   // a tab at column 1 and 8, and every 4 spaces until column 250.
   // For more info see help on "tabs" command
   setup_info=setup_info:+",TABS=+4";

   // Margins - sets the p_margins property for new buffers created with this mode.
   // Set the margins to "1 74 1".  Since word wrap is not on for most 
   // programming languages, this does not usually matter.  For more information
   // see help on the "margins" command
   setup_info=setup_info:+",MA=1 74 1";

   // Keytable (event table) - sets the p_eventtable property for new buffers created with this mode.
   // Set the keytable for this mode.  Since we are inheriting from C, we will
   // use the "c-keys" keytable.
   setup_info=setup_info:+",KEYTAB=":+RUBY_LANGUAGE_ID:+"-keys";

   // Word wrap - sets the p_word_wrap property for new buffers created with 
   // this mode.
   // Word wrap is off
   setup_info=setup_info:+",WW=0";

   // Indent with tabs.  Sets the p_indent_with_tabs property for new buffers 
   // in this mode.  When this is on, pressing the Tab key inserts a tab
   // character into the file.   If it is off, the appropriate number of spaces
   // are inserted.  For more, see help on the "indent_with_tabs" command.
   // In this case, we are shutting indent with tabs off.
   setup_info=setup_info:+",IWT=0";

   // Show tabs - this sets the p_show_tabs property for new buffers of this 
   // type, which is deprecated.
   setup_info=setup_info:+",ST="DEFAULT_SPECIAL_CHARS;

   // Indent style - this sets the p_indent_style for new buffers of this 
   // type.  
   // Set this to one of the following:
   //    INDENT_NONE        0
   //    INDENT_AUTO        1
   //    INDENT_SMART       2
   setup_info=setup_info:+",IN=":+INDENT_SMART;

   /*
   // Word chars - this sets the p_word_chars property for new buffers of this 
   // type
   setup_info=setup_info:+",WC=":+word_chars;


   // Lexer name - sets the p_lexer_name property for new buffers of this type
   setup_info=setup_info:+",LN=Ruby";

   // Color flags - sets the p_color_flags property for new buffers of this type
   // Set to one of the following:
   //    LANGUAGE_COLOR_FLAG    0x1
   //    MODIFY_COLOR_FLAG      0x2
   //    CLINE_COLOR_FLAG       0x4
   setup_info=setup_info:+",CF=":+LANGUAGE_COLOR_FLAG;

   // Line number length - sets the p_line_numbers_len property for new buffers
   // of this type.  Set to 0 to keep line numbers from being displayed.  For
   // more info see help on the p_line_numbers_len property.
   setup_info=setup_info:+",LNL=0";

   // Truncate length - sets the p_TruncateLength property for new buffers
   // of this type.  Set to -1 to shut this off.  For more info, see help on
   // the p_TruncateLength property.
   setup_info=setup_info:+",TL=-1";
   */

   // Compile info is deprecated
   _str compile_info='';
   _str begin_end_style = BES_BEGIN_END_STYLE_2;
   _str ruby_options = 0;
   _str syntax_info='4 1 1 ':+ruby_options:+' ':+begin_end_style:+' 0 0 0';
   _str be_info="(if),(while),(unless),(class),(do),(begin),(case),(module),(for),(until),(def)|(end)";

   //Creates the initialize extension and tags the rest to be treated like the original
   _CreateLanguage(RUBY_LANGUAGE_ID, RUBY_MODE_NAME,
                   setup_info, compile_info,
                   syntax_info, be_info, '', word_chars, RUBY_MODE_NAME);
   _CreateExtension('ruby' ,RUBY_LANGUAGE_ID);
   _CreateExtension('rby' ,RUBY_LANGUAGE_ID);
   _CreateExtension('rb' ,RUBY_LANGUAGE_ID);
}

/**
 * Switch to Ruby mode
 */
_command ruby_mode()  name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY|VSARG2_ICON)
{
   _SetEditorLanguage(RUBY_LANGUAGE_ID);
}

/**
 * Modal key binding for the ruby language.  If we are in a valid place in the 
 * file, 
 */
_command void ruby_enter() name_info(','VSARG2_CMDLINE|VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   generic_enter_handler(_ruby_expand_enter, true);
}

// Words to expand when the spacebar is pressed.
static SYNTAX_EXPANSION_INFO ruby_space_words:[] = {
   "if"       => { "if ... end" },
   "while"    => { "while ... end" },
   "require"  => { "require '...'" },
   "unless"   => { "unless ... end" },
   "class"    => { "class ... end" },
   "do"       => { "do ... end" },
   "begin"    => { "begin ... end" },
   "BEGIN"    => { "BEGIN { ... }" },
   "case"     => { "case ... end" },
   "module"   => { "module ... end" },
   "for"      => { "for ... end" },
   "until"    => { "until ... end" },
   "def"      => { "def ... end" },
};

/**
 * This command is run when the space bar is pressed
 */
_command void ruby_space() name_info(','VSARG2_CMDLINE|VSARG2_LASTKEY|VSARG2_REQUIRES_EDITORCTL)
{

   _str syntax_info=name_info(_edit_window().p_index);

   if (command_state() || ! doExpandSpace(p_LangId) || p_SyntaxIndent<0 || _in_comment() ||
       ruby_expand_space()) {
      // If we are on the command line, or syntax expansion is shut off,
      // or the syntax indent is -1, or we are in a comment, or 
      // ruby_expand_space fails.   Note:If ruby_expand_space returns 
      // 0, it handled the enter key successfully, so we will skip the root key 
      // binding
      //
      if (command_state()) {
         // If we are on the command line, call the root key binding for space
         call_root_key(' ');

      } else {
         // Otherwise (we are in a buffer) insert a space
         keyin(' ');
      }

   } else if (_argument=='') {
      // If the _argument global variable is set
      //
      // Start a new undo level
      _undo('S');
   }

}

int _ruby_get_syntax_completions(var words)
{
   return AutoCompleteGetSyntaxSpaceWords(words,ruby_space_words);
}

_command void ruby_begin() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   int cfg = 0;

   if (!command_state() && p_col>1) {
      left(); cfg=_clex_find(0,'g'); right();
   }
   if ( command_state() || _in_comment() ||
       ruby_expand_begin() ) {

       call_root_key('{');
      
   } 
   else if (_argument=='') {
     
      _undo('S');
   }

}

_command void ruby_bracket() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_CMDLINE)
{
   call_root_key('[');
}

static boolean ruby_expand_space()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT | AFF_BEGIN_END_STYLE);
   syntax_indent := p_SyntaxIndent;
   ruby_options := LanguageSettings.getRubyStyle(p_LangId);
   begin_end_style := p_begin_end_style;

   // Initialize status to 0
   int status=0;
   int command_flag = 0;

   // Initialize line to ''
   _str line='';
   _str TestLine='';
   _str rest='';
   _str keyword='';

   // Get the current line
   get_line(line);
   get_line(TestLine);



   // Strip the spaces from the end of the line
   line=strip(line,'T');

   // Make a copy of the line
   _str orig_word=strip(line);


   // Be sure we are at the end of the line.  The call to text_col gets the 
   // column position adjusted for tab characters
   if (p_col!=text_col(_rawText(TestLine))+1 || p_col!=text_col(_rawText(line))+1) {
      // Nothing was done
      return(1);
   }

   parse TestLine with rest keyword;

   if (ruby_space_words._indexin(keyword) && !ruby_space_words._indexin(rest)) {
      orig_word=keyword;
      command_flag = 1;
   } else if (rest == "class" || rest == "def") {
      orig_word = rest;
      command_flag = 1;
   } else if(ruby_space_words._indexin(orig_word)) {
      orig_word = orig_word;
      command_flag = 0;
   } else {
      return(1);
   }
   

   // Call min_abbrev2 to see what the word we have is.  If there is an 
   // ambiguity, this function will prompt the user which keyword they want
   // to expand.  Also, if there is not an ambiguity, this will give us the
   // "expanded" keyword ( "cl" will be come "class" ).  This will also check 
   // for a substitute expansion in an alias file.  From the file extension
   // setup dialog, a user can override expansion for any existing keyword.
   _str aliasfilename='';
   _str word=min_abbrev2(orig_word,ruby_space_words,name_info(p_index),aliasfilename);

   // can we expand an alias?
   if (!maybe_auto_expand_alias(orig_word, word, aliasfilename, auto expandResult)) {
      // if the function returned 0, that means it handled the space bar
      // however, we need to return whether the expansion was successful
      return (expandResult != 0);
   }

   // If you are adding your own syntax expansion and indenting 
   // for your own language you and you only want extension
   // specific aliases, just add a return(1) statement here.
   // return(1);

   if (word=='') {
      // If min_abbrev3 did not return us a specific word
      //
      // Set word back to orig_word
      word=orig_word;
   }

   // Take the piece of word that we are expanding off of the end of line
  

   int width = 0;

   //Beginning of Team 5 Code
   // 
   // Get the column that this keyword starts in
   if (command_flag == 1) {
      line = TestLine;
      int lenTestLine = text_col(_rawText(TestLine));
      int lenRest     = text_col(_rawText(rest));
      int lenKeyword  = text_col(_rawText(keyword));
      width = lenTestLine - lenRest - lenKeyword - 1;
   } else {
      line=substr(line,1,length(line)-length(orig_word)):+word;
      width=text_col(_rawText(line),_rawLength(line)-_rawLength(word)+1,'i')-1;
   }

   doNotify := true;
   if ((ruby_options == VS_RUBY_OPTIONS_MODIFIER_FLAG || ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG+VS_RUBY_OPTIONS_MODIFIER_FLAG) && pos(' 'word' ',RUBY_MODIFIER_WORDS)) {
      replace_line(line' ');
      _end_line();
      doNotify = false;
   } else if (pos(' 'word' ',RUBY_END_WORDS)) {
  
      // IF the current word is found in the ENTER WORDS list
      // 
      // Replace the current line with "if ()".  This is where word_case(...)
      // would be used for languages that are case insensitive.
      //replace_line(line' ()'maybe_ending_brace);

      set_surround_mode_start_line();
      if (pos(' 'word' ',RUBY_PAREN_WORDS) && (begin_end_style == BES_BEGIN_END_STYLE_3) && (ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG || ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG+VS_RUBY_OPTIONS_MODIFIER_FLAG)) {

         if( (rest == "def") ){

            if( _rawLength(keyword) != 0 ) {
            
               replace_line(line' ()');
               insert_line(indent_string(width));
               insert_line(indent_string(width)'end');
               up(2);
               p_col = _rawLength(line)+3;

               if (! _insert_state()) {
                  _insert_toggle();
               }
            } else {
               doNotify = false;
               status=1;
            }
         } else {
         
            replace_line(line' ()');
            insert_line(indent_string(width));
            insert_line(indent_string(width)'end');
            set_surround_mode_end_line();
            up(2);
            p_col = _rawLength(line)+3;

            if (! _insert_state()) {
               _insert_toggle();
            }
         }

      } else if (begin_end_style & BES_BEGIN_END_STYLE_2 && (ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG  || ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG+VS_RUBY_OPTIONS_MODIFIER_FLAG)) {

             if( rest == "class" || rest == "def" ) {
                width = width+1;
             }
             if( _rawLength(keyword) == 0 ) {

               replace_line(line' ');
               insert_line(indent_string(width));
               insert_line(indent_string(width)'end');
               set_surround_mode_end_line();
               up(2);
               p_col = _rawLength(line)+2;

               if (! _insert_state()) {
                  _insert_toggle();
               }
             } else {
                status = 1;
                doNotify = false;
             }
        

      } else if ( pos(' 'word' ',RUBY_PAREN_WORDS) && (begin_end_style == BES_BEGIN_END_STYLE_3 )) {


         if( (rest == "def") ) {

            if(_rawLength(keyword) != 0) {
         
               replace_line(line' ()');
               insert_line(indent_string(width)'end');
               up(1);
               p_col = _rawLength(line)+3;

               if (! _insert_state()) {
                  _insert_toggle();
               }
            } else {
               status=1;
               doNotify = false;
            }

         } else {

            replace_line(line' ()');
            insert_line(indent_string(width)'end');
            set_surround_mode_end_line();
            up(1);
            p_col = _rawLength(line)+3;

            if (! _insert_state()) {
               _insert_toggle();
            }
         }
      } else {

        if( rest == "class" || rest == "def" ) {
                width = width+1;
        }
        if( _rawLength(keyword) == 0 ) {

           replace_line(line' ');
           insert_line(indent_string(width)'end');
           set_surround_mode_end_line();
           up(1);
           p_col = text_col(_rawText(line)) + 2;

           if (! _insert_state()) {
              _insert_toggle();
           }
        } else {
           status = 1;
           doNotify = false;
        }

      }
      doNotify = !do_surround_mode_keys();

   } else if (word=='require') {
      // IF the current word is "require"
      // 
      //require '{cursor}'

      replace_line(line" ''");
      p_col = _rawLength(line) +3;

      if (! _insert_state()) {
         _insert_toggle();
      }
   } else if( word == "BEGIN" || word == "END") {
      replace_line(line'{');
      insert_line(indent_string(width));
      insert_line(indent_string(width)'}');
      up(1);
      p_col = syntax_indent;
   } else if (ruby_space_words._indexin(word)) {
      // If this word is in the list, but we have not handled it yet. 
      // (We want to expand the word, but there is no special code for it.)
      //
      // Replace the current line with the expanded word with a space at the end
      // and then move to the end of the line
      replace_line(indent_string(width):+word' ');
      _end_line();
      doNotify = false;
   } else {
      // Nothing was done
      status=1;
      doNotify = false;
   }

   if (doNotify) {
      // notify user that we did something unexpected
      notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
   }

   return(status!=0);
}

boolean _ruby_expand_enter()
{
   updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
   syntax_indent := p_SyntaxIndent;

   int status=0;
   _str line = '';
   _str first_word = '';
   _str second_word = '';
   _str rest = '';
   _str TestLine = '';
   int current_col=0;

      // Get the name of the command that the Enter key is bound to 
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      // If the key is bound to "nosplit-insert-line"
      //
      // Go to the end of the line to insure proper behavior
      _end_line();
   }

   get_line(line);


   if ( line=='' ) {
      return(1);
   }

   parse line with first_word second_word .;

   _str lower_first_word=lowcase(first_word);
   _str lower_second_word=lowcase(second_word);


   if ( (pos(' 'lower_first_word' ',RUBY_ENTER_WORDS) || pos(' 'lower_second_word' ', RUBY_ENTER_WORDS)) && ( p_col >= _rawLength(line)) ) {

      indent_on_enter(syntax_indent);

      if ((first_word == 'begin') && (lower_second_word == '') && ((_rawLength(line)) == _rawLength(TestLine))) {

         current_col = p_col;
         int width=text_col(_rawText(line),_rawLength(line)-_rawLength(lower_first_word)+1,'i')-1;

        

         insert_line(indent_string(width)'end');
         up(2);
         replace_line(line' ');
         down();
         p_col = current_col;

         // notify user that we did something unexpected
         notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);
      }
      
   } else {
      return(1);
   }

   return(status != 0);
}


static boolean ruby_expand_begin()
{
   int status = 0;

   expand := LanguageSettings.getAutoBracketEnabled(p_LangId, AUTO_BRACKET_BRACE);
   if (!expand) {
      return 1;
   }

   keyin("{}");
   p_col = p_col-1;

   // notify user that we did something unexpected
   notifyUserOfFeatureUse(NF_SYNTAX_EXPANSION);

   return(status != 0);
 
}

//########################################################################
//////////////////////////////////////////////////////////////////////////
// GLOBAL VARIABLES
//

/*
 needed for tokenizer for SKT language
 see ruby_next_sym() and ruby_prev_sym() below
*/
static _str gtkinfo;
static _str gtk;

/*
 ##SKELETON## -- regular expressions and strings
                 used for picking out ruby keywords
*/
#define RUBY_COMMON_END_OF_STATEMENT_RE 'if|while|switch|for|case|default|public|private|protected|static|class|break|continue|do|else|goto|return'
#define RUBY_MORE_END_OF_STATEMENT_RE 'extern|struct|typedef|delete|inline|virtual|using|asm|namespace'
#define RUBY_NOT_FUNCTION_WORDS  ' int long double float boolean short unsigned char catch do for if return sizeof switch while '


//########################################################################
//////////////////////////////////////////////////////////////////////////
// SET UP "RUBY" EXTENSION
//
// 8/11/2004
// Extension setup is now done in rubyext.e. Load rubyext.e before
// loading this module.
//


//########################################################################
//////////////////////////////////////////////////////////////////////////
// EXTENSION-SPECIFIC EVENT TABLE
//

/*
 ##SKELETON## -- keymaps for Ruby language to trigger
                 auto function help or auto code help
*/

//########################################################################
//////////////////////////////////////////////////////////////////////////
// HOOK FUNCTIONS and UTILITY FUNCTIONS
//

/**
 * <B>Hook Function</B> -- _ext_get_expression_info
 * <P>
 * If this function is not implemented, the editor will
 * default to using {@link _do_default_get_expression_info()}, which simply
 * returns the current identifier under the cursor and no prefix
 * expression.
 * <P>
 * This function is used to get information about the code at
 * the current buffer location, including the current ID under
 * the cursor, the expression before the current ID, and other
 * supplementary information useful to list-members.
 * <P>
 * The caller must check whether text is in a comment or string.
 * For now, set info_flags to 0.  In the future we could
 * have a LASTID_FOLLOWED_BY_PAREN flag and optionally do an
 * exact match instead of a prefix match.
 *
 * @param PossibleOperator       Was the last character typed an operator?
 * @param idexp_info             (reference) VS_TAG_IDEXP_INFO whose members are set by this call.
 *
 * @return int
 *      return 0 if successful<BR>
 *      return 1 if expression too complex<BR>
 *      return 2 if not valid operator
 *
 * @since 11.0
 */
int _ruby_get_expression_info(boolean PossibleOperator, VS_TAG_IDEXP_INFO &idexp_info,
                              VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_get_expression_info(PossibleOperator,idexp_info,visited,depth);
}

/**
 * Useful utility function for getting the next token, symbol, or
 * identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string)
 *
 * @return next token or ''
 */
static _str ruby_next_sym()
{
   //##SKELETON -- implement [ext]_next_sym, it will make it easier
   //              to write the get_expression_info and fcthelp_get hook functions.
   if (p_col>_text_colc()) {
      if(down()) {
         gtk=gtkinfo='';
         return('');
      }
      _begin_line();
   }
   _str ch=get_text();
   int status=0;
   if (ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(ruby_next_sym());
   }
   int start_col=0;
   int start_line=0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   if (ch=='-' && get_text()=='>') {
      right();
      gtk=gtkinfo='->';
      return(gtk);

   }
   if (ch==':' && get_text()==':') {
      right();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);
}

/**
 * Useful utility function for getting the previous token on the
 * same linenext token, symbol, or '' if the previous token is
 * on a different line.
 *
 * @return
 *    previous token or '' if no previous token on current line
 */
static _str ruby_prev_sym_same_line()
{
   //##SKELETON -- implement [ext]_prev_sym_same_line, it will make
   //              to write the get_expression_info and fcthelp_get hook functions.
   if (gtk!='(' && gtk!='::') {
      return(ruby_prev_sym());
   }
   int orig_linenum=p_line;
   _str result=ruby_prev_sym();
   if (p_line!=orig_linenum && (p_col<=_text_colc() || p_line!=orig_linenum-1) ) {
      gtk=gtkinfo="";
      return(gtk);
   }
   return(result);
}

/**
 * Useful utility function for getting the previous token, symbol,
 * or identifier from the current cursor location.  Returns results
 * through the global variables gtk and gtkinfo.  (See above).
 * Returns the value assigned to gtk (a string).
 *
 * @return previous token or ''
 */
static _str ruby_prev_sym()
{
   //##SKELETON## -- implement [ext]_prev_sym, it will make it easier
   //              to write the get_expression_info and fcthelp_get hook functions.
   _str ch=get_text();
   int status=0;
   if (ch=="\n" || ch=="\r" || ch=='' || (ch=='/' && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks('-');
      if (status) {
         gtk=gtkinfo='';
         return(gtk);
      }
      return(ruby_prev_sym());
   }
   int end_col=0;
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      end_col=p_col+1;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col==1) break;
            left();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               right();
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      } else {
         search('[~'word_chars']\c|^\c','@rh-');
         gtk=TK_ID;
         gtkinfo=_expand_tabsc(p_col,end_col-p_col);
      }
      if (p_col==1) {
         up();_end_line();
      } else {
         left();
      }
      return(gtk);
   }
   if (p_col==1) {
      up();_end_line();
      if (_on_line0()) {
         gtk=gtkinfo="";
         return(gtk);
      }
      gtk=gtkinfo=ch;
      return(gtk);
   }
   left();
   if (ch=='>' && get_text()=='-') {
      left();
      gtk=gtkinfo='->';
      return(gtk);

   }
   if (ch=='=' && pos(get_text(),'=+!%^*&|/><')) {
      gtk=gtkinfo=get_text()'=';
      left();
      return(gtk);
   }
   if (ch==':' && get_text()==':') {
      left();
      gtk=gtkinfo='::';
      return(gtk);
   }
   gtk=gtkinfo=ch;
   return(gtk);

}
/**
 * Utility function for parsing part of prefix expression before a
 * dot (member access operator), called starting from 
 * _ruby_get_expression_info or ruby_before_id, etc.  Basic plan
 * is to parse code backwards from the cursor location until you 
 * reach a stopping point. 
 *
 * @param prefixexp              (reference), prefix expression to prepend
 *                               new parts of expression onto
 * @param prefixexpstart_offset  (reference) start of prefix expression
 * @param lastid                 (reference, unused)
 *
 * @return
 * <LI>0  -- finished
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int ruby_before_dot(_str &prefixexp,
                           int &prefixexpstart_offset,
                           _str &lastid)
{
   int status=0;
   int nest_level=0;
outer_loop:
   for (;;) {
      prefixexpstart_offset=(int)point('s')+1;
      switch (gtk) {
      case ']':
         prefixexp='[]':+prefixexp;
         right();
         status=find_matching_paren(true);
         if (status) {
            return(VSCODEHELPRC_CONTEXT_NOT_VALID);
         }
         left();
         gtk=ruby_prev_sym();
         if (gtk!=']') {
            if (gtk!=TK_ID) {
               if (gtk==')') {
                  continue;
               }
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            prefixexp=gtkinfo:+prefixexp;
            prefixexpstart_offset=(int)point('s')+1;
            gtk=ruby_prev_sym();
            return(2);  // continue
         }
         break;
      case ')':
         nest_level=0;
         int count=0;
         for (count=0;;++count) {
            if (count>200) {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk:=='') {
               return(VSCODEHELPRC_CONTEXT_NOT_VALID);
            }
            if (gtk==']') {
               prefixexp='[]':+prefixexp;
               right();
               status=find_matching_paren(true);
               if (status) {
                  return(VSCODEHELPRC_CONTEXT_NOT_VALID);
               }
               left();
            } else {
               if (gtk==TK_ID) {
                  prefixexp=gtkinfo' ':+prefixexp;
               } else {
                  prefixexp=gtkinfo:+prefixexp;
               }
            }
            prefixexpstart_offset=(int)point('s')+1;
            if (gtk=='(') {
               --nest_level;
               if (nest_level<=0) {
                  gtk=ruby_prev_sym_same_line();
                  if (gtk!=TK_ID) {

                     if (gtk==']') {
                        continue outer_loop;
                     }
                     if (gtk==')') {
                        continue;
                     }
                     if (gtk=='') {
                        return(0);
                     }
                     return(0);
                  }
                  prefixexp=gtkinfo:+prefixexp;
                  prefixexpstart_offset=(int)point('s')+1;
                  gtk=ruby_prev_sym_same_line();
                  return(2);// Tell call to continue processing
               }
            } else if (gtk==')') {
               ++nest_level;
            }
            gtk=ruby_prev_sym();
         }
         break;
      default:
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
   }
   return(VSCODEHELPRC_CONTEXT_NOT_VALID);
}
/**
 * Utility function for parsing part of prefix expression before
 * an identifier, called starting from _ruby_get_expression_info 
 * or ruby_before_dot, etc.  Basic plan is to parse code backwards
 * from the cursor location until you reach a stopping point. 
 *
 * @param prefixexp              (reference), prefix expression to prepend new
 * @param prefixexpstart_offset               parts of expression onto
 * @param lastid                 (reference, unused)
 * @param info_flags             (reference) VSCODEHELPFLAG_* bitset
 * @param otherinfo              (reference) auxilliary info
 *
 * @return
 * <LI>0  -- finished
 * <LI>1  -- context invalid
 * <LI>2  -- continue parsing expression before the dot
 */
static int ruby_before_id(_str &prefixexp,int &prefixexpstart_offset,
                          _str &lastid,int &info_flags,typeless &otherinfo)
{
   int status=0;
   for (;;) {
      switch (gtk) {
      case '*':
      case '&':
         info_flags|=VSAUTOCODEINFO_HAS_REF_OPERATOR;
         otherinfo=gtk;
         return(0);
      case '->':
      case '.':
         prefixexp=gtkinfo:+prefixexp;
         prefixexpstart_offset=(int)point('s')+1;
         gtk=ruby_prev_sym();
         if (gtk!=TK_ID) {
            status=ruby_before_dot(prefixexp,prefixexpstart_offset,lastid);
            if (status!=2) {
               return(status);
            }
         } else {
            prefixexp=gtkinfo:+prefixexp;
            prefixexpstart_offset=(int)point('s')+1;
            gtk=ruby_prev_sym();
         }
         break;
      case '::':
         for (;;) {
            prefixexp=gtkinfo:+prefixexp;
            gtk=ruby_prev_sym_same_line();
            if (gtk!=TK_ID) {
               return(0);
            }
            prefixexp=gtkinfo:+prefixexp;
            gtk=ruby_prev_sym_same_line();
            if (gtk!='::') {
               return(0);
            }
         }
         return(0);
      case TK_ID:
         if (gtkinfo=='new') {
            gtk=ruby_prev_sym();
            prefixexp='new ':+prefixexp;
            prefixexpstart_offset=(int)point('s')+1;
            gtk=ruby_prev_sym();
            if (gtk!='.') {
               return(0);
            }
            continue;
         } else if (gtkinfo=='goto') {
            info_flags |= VSAUTOCODEINFO_IN_GOTO_STATEMENT;
         }
         return(0);

      default:
         return(0);

      }
   }
}

/**
 * Utility function for parsing the syntax of a return type
 * pulled from the tag database, tag_get_detail(VS_TAGDETAIL_return, ...)
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs          array of strings for error message arguments
 *                           refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files          list of extension specific tag files
 * @param symbol             name of symbol having given return type
 * @param search_class_name  class context to evaluate return type relative to
 * @param file_name          file from which return type string comes
 * @param return_type        return type string to be parsed (e.g. FooBar **)
 * @param rt                 (reference) return type information
 * @param visited            (reference) types analyzed thus far
 * @param depth              search depth, to prevent recursion
 *
 * @return
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _ruby_parse_return_type(_str (&errorArgs)[], typeless tag_files,
                                   _str symbol, _str search_class_name,
                                   _str file_name, _str return_type,
                                   struct VS_TAG_RETURN_TYPE &rt,
                                   VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   // filter out mutual recursion
   _str input_args='parse;'symbol';'search_class_name';'file_name';'return_type;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         //say("_ruby_parse_return_type: SHORTCUT failure");
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         //say("_ruby_parse_return_type: SHORTCUT success");
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;
   //say("_ruby_parse_return_type: COMPUTE key="input_args);

   //say("_ruby_parse_return_type("symbol","search_class_name","return_type","file_name")");
   boolean found_seperator = false;
   boolean allow_local_class= true;
   _str orig_return_type = return_type;
   _str found_type = '';
   rt.return_type = '';

   _UpdateContext(true);
   _str package_name = '';
   _str ch='';
   int num_args=0;

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);

   while (return_type != '') {
      // if the return type is simply a builtin, then stop here
      if (_ruby_is_builtin_type(strip(return_type)) && found_type=='' && rt.pointer_count==0) {
         //say("_ruby_parse_return_type: builtin");
         rt.return_type = strip(return_type);
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
         if (_ruby_is_builtin_type(rt.return_type,true)) {
             visited:[input_args]=rt;
             return 0;
         }
         errorArgs[1] = rt.return_type;
         errorArgs[2] = orig_return_type;
         return VSCODEHELPRC_BUILTIN_TYPE;
      }
      int p = pos('^ @{\:\:|\:\[|\[|\]|[.<>*&()]|:v|\@:i:v|\@:i}', return_type, 1, 'r');
      if (p <= 0) {
         break;
      }
      p = pos('S0');
      int n = pos('0');
      ch = substr(return_type, p, n);
      return_type = substr(return_type, p+n);
      //say("return ch="ch" return_type="return_type);
      switch (ch) {
      case 'struct':
      case 'class':
      case 'union':
         break;
      case '::':
         found_seperator = true;
         if (found_type == '') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
            allow_local_class=false;
         } else {
            allow_local_class=true;
         }
         break;
      case '.':
         break;
      case '*':
         if (found_type != '') {
            rt.pointer_count++;
         }
         break;
      case '&':
         break;
      case '[':
         if (!match_brackets(return_type, num_args)) {
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_BRACKETS_MISMATCH;
         }
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_ARRAY;
         rt.pointer_count++;
         break;
      case ']':
         break;
      case '(':
         _str parenexp='';
         if (!match_parens(return_type, parenexp, num_args)) {
            // this is not good
            errorArgs[1] = orig_return_type;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
         while (pos('[', parenexp)) {
            parenexp = substr(parenexp, pos('S')+1);
            if (!match_brackets(parenexp, num_args)) {
               errorArgs[1] = orig_return_type;
               return VSCODEHELPRC_BRACKETS_MISMATCH;
            }
            rt.pointer_count++;
         }
         break;
      case ')':
         break;
      case 'const':
      case 'extern':
         if (ch:=='const') {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         } else if (ch:=='interface' && return_type=='' && found_type=='') {
            found_type=ch;
         }
         break;
      default:
         // this must be an identifier
         // try simple macro substitution
         _UpdateContext(true);
         if (tag_check_for_define(ch, 0, tag_files, ch)) {
            switch (ch) {
            case '':
            case 'struct':
            case 'class':
            case 'union':
               continue;
            case 'const':
               rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
               continue;
            }
         }
         package_name = package_name :+ ch;
         if (found_type != '' && allow_local_class && found_seperator) {
            found_type = found_type :+ VS_TAGSEPARATOR_class :+ ch;
            found_seperator = false;
         } else if (found_type != '' && _ruby_is_builtin_type(found_type) && !found_seperator) {
            found_type = found_type ' ' ch;
         } else {
            found_type = ch;
         }
      }
   }
   //say("LOCAL search_class="search_class_name" found_type="found_type);
   int status=0;
   _str qualified_name = found_type;
   if (allow_local_class) {
      _str inner_name, outer_name;
      tag_split_class_name(found_type, inner_name, outer_name);
      qualified_name='';
      if (length(outer_name) < length(search_class_name)) {
         outer_name = tag_join_class_name(inner_name, search_class_name, tag_files, true, true);
         qualified_name = outer_name;
         if (outer_name :== '' && search_class_name :!= '' && found_type :!= inner_name) {
            outer_name = found_type;
         }
      }
      if (qualified_name=='') {
         if (outer_name=='' && search_class_name!='') {
            status = tag_qualify_symbol_name(qualified_name, inner_name, search_class_name, file_name, tag_files, true);
         } else {
            status = tag_qualify_symbol_name(qualified_name, inner_name, outer_name, file_name, tag_files, true);
         }
      }
      if (qualified_name=='') {
         qualified_name = found_type;
      }
   }

   // try to handle typedefs
   if (depth < VSCODEHELP_MAXRECURSIVETYPESEARCH) {
      _str qualified_inner='';
      _str qualified_outer='';
      tag_split_class_name(qualified_name, qualified_inner, qualified_outer);
      //say("_ruby_parse_return_type: inner="qualified_inner" outer="qualified_outer);
      if (tag_check_for_typedef(/*found_type*/qualified_inner, tag_files, true, qualified_outer)) {
         //say(qualified_name" is a typedef");
         //say(indent_string(depth*2)"_ruby_parse_return_type: typedef="qualified_name);
         int orig_const_only    = (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY);
         int orig_is_array      = (rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES);
         //say("istemplate="istemplate);
         rt.return_type=qualified_name;
         status = _ruby_get_return_type_of(errorArgs, tag_files, qualified_inner, qualified_outer,
                                        0, VS_TAGFILTER_TYPEDEF, false, rt, visited, depth+1);
         if (status==VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
            return(status);
         } else {
            qualified_name=rt.return_type;
            //say(indent_string(depth*2)"_ruby_parse_return_type: typedef="qualified_name" time="(int)_time('b')-orig_time);
            //say("_ruby_parse_return_type: match_tag="match_tag" status="status", qual="qualified_name);
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags |= orig_const_only;
            }
            if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
               rt.return_flags |= orig_is_array;
            }
            if (status) {
               return status;
            }
         }
      }
      //say("qualify = "qualified_name" found_type="found_type);
   } else {
      errorArgs[1] = orig_return_type;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }

   if (qualified_name == '' || qualified_name==found_type) {
      if (rt.pointer_count==0 && _ruby_is_builtin_type(found_type)) {
         rt.return_type = found_type;
         if (_ruby_is_builtin_type(found_type,true)) {
            visited:[input_args]=rt;
            return 0;
         }
         //say("_ruby_parse_return_type: 222");
         errorArgs[1] = symbol;
         errorArgs[2] = orig_return_type;
         return VSCODEHELPRC_BUILTIN_TYPE;
      }
   }

   rt.return_type = qualified_name;
   //say("_ruby_parse_return_type returns "rt.return_type);
   if (rt.return_type == '') {
      errorArgs[1] = orig_return_type;
      //say("_ruby_parse_return_type: HERE 4");
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   visited:[input_args]=rt;
   return 0;
}

/**
 * Utility function for retrieving the return type of the given symbol.
 * The return type is evaluated relative to the current class context
 * and in the context of the file in which it was seen.  This is
 * necessary in order to resolve imported namespaces, etc.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs                  instruction_case; * @param tag_files
 *                                   refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files                  list of extension specific tag files
 * @param symbol                     name of symbol having given return type
 * @param search_class_name          class context to evaluate return type relative to
 * @param min_args                   minimum number of arguments for function, used
 *                                   to resolve overloading.
 * @param pushtag_mask               bitset of VS_TAGFILTER_*, allows us to search only
 *                                   certain items in the database (e.g. functions only)
 * @param maybe_class_name           Could the symbol be a class name, for example
 *                                   C++ syntax of BaseObject::method, BaseObject might
 *                                   be a class name.
 * @param rt                         (reference) set to return type information
 * @param visited                    (reference) have we evalued this return type before?
 * @param depth                      depth of recursion (for handling typedefs)
 * @param match_type
 * @param pointer_count
 * @param ruby_return_flags
 * @param match_tag
 * @param depth
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _ruby_get_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                    _str symbol, _str search_class_name,
                                    int min_args, int pushtag_mask, boolean maybe_class_name,
                                    struct VS_TAG_RETURN_TYPE &rt,
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //say("_ruby_get_return_type_of("symbol","search_class_name")");

   // filter out mutual recursion
   _str input_args='get;'symbol';'search_class_name';'min_args';'pushtag_mask';'maybe_class_name';'p_buf_name;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         //say("_ruby_get_return_type_of: SHORTCUT failure");
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         //say("_ruby_get_return_type_of: SHORTCUT success");
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;
   //say("_ruby_get_return_type_of: COMPUTE key="input_args);

   // initialize ruby_return_flags
   rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_STATIC_ONLY|
                         VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS|
                         VSCODEHELP_RETURN_TYPE_ARRAY
                        );
   if (search_class_name == '::') {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
      search_class_name = '';
   }

   // get the current class from the context
   _str cur_tag_name='';
   int cur_tag_flags=0;
   _str cur_type_name='';
   int cur_type_id=0;
   _str cur_class_name='';
   _str cur_class_only='';
   _str cur_package_name='';
   int context_id = tag_get_current_context(cur_tag_name,cur_tag_flags,
                                            cur_type_name,cur_type_id,
                                            cur_class_name,cur_class_only,
                                            cur_package_name);

   // special case keyword 'this'
   if (symbol :== 'this' && !(cur_tag_flags & VS_TAGFLAG_static)) {
      if (search_class_name :== '' && context_id > 0 &&
          !(cur_tag_flags & VS_TAGFLAG_static)) {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         if (cur_tag_flags & VS_TAGFLAG_const) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
         }
         if (cur_tag_flags & VS_TAGFLAG_volatile) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         } else {
            rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
         }
         rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
         // attempt to resolve the class name to a package
         // need this for C++ namespaces
         _str inner_name='';
         _str outer_name='';
         tag_split_class_name(cur_class_name,inner_name,outer_name);
         tag_qualify_symbol_name(rt.return_type,inner_name,outer_name,p_buf_name,tag_files,true);
         if (rt.return_type=='' || rt.return_type==inner_name) {
            rt.return_type = cur_class_name;
         }
         rt.pointer_count = 1;
         visited:[input_args]=rt;
         return 0;
      }
   }

   int status = _ruby_match_return_type_of(errorArgs,tag_files,
                                          symbol,search_class_name,
                                          cur_class_name, min_args,
                                          maybe_class_name,
                                          pushtag_mask, rt.return_flags,
                                          rt, visited, depth);
   // check for error condition
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   }
   return status;
}

/**
 * Utility function for searching the current context and tag files
 * for symbols matching the given symbol and search class, filtering
 * based on the pushtag_mask and ruby_return_flags.  The number of
 * matches is returned and can be obtained using TAGSDB function
 * tag_get_match(...).
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param cur_class_name      current class context
 * @param min_args            minimum number of args, for resolving overloading
 * @param maybe_class_name    maybe the given symbol is a class name?
 * @param pushtag_mask        bitset of VS_TAGFILTER_*, allows us to search only
 *                            certain items in the database (e.g. functions only)
 * @param ruby_return_flags    VSCODEHELP_RETURN_TYPE_* flags
 * @param rt                  (reference) return type to match
 * @param visited             (reference) prevent recursion, cache results
 * @param depth               prevent deep recursion when evaluating results
 *
 * @return number of matches on success,
 *         <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _ruby_match_return_type_of(_str (&errorArgs)[], typeless tag_files,
                                      _str symbol, _str search_class_name,
                                      _str cur_class_name, int min_args,
                                      boolean maybe_class_name,
                                      int pushtag_mask, int ruby_return_flags,
                                      struct VS_TAG_RETURN_TYPE &rt,
                                      VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //say("_ruby_match_return_type_of("symbol","search_class_name")");
   // filter out mutual recursion
   _str input_args='match;'symbol';'search_class_name';'cur_class_name';'min_args';'maybe_class_name';'pushtag_mask';'ruby_return_flags;
   if (visited._indexin(input_args)) {
      if (visited:[input_args].return_type==null) {
         //say("_ruby_match_return_type_of: SHORTCUT failure");
         errorArgs[1]=symbol;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      } else {
         //say("_ruby_match_return_type_of: SHORTCUT success");
         rt=visited:[input_args];
         return(0);
      }
   }
   visited:[input_args]=gnull_return_type;

   // try to find match for 'symbol' within context, watch for
   // C++ global designator (leading ::)
   int i, num_matches = 0;
   tag_clear_matches();
   if (ruby_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) {
      tag_list_context_globals(0, 0, symbol, true, tag_files, pushtag_mask,
                               VS_TAGCONTEXT_ONLY_non_static,
                               num_matches, VSCODEHELP_MAXFUNCTIONHELPPROTOS, true, true);
   } else {
      tag_list_symbols_in_context(symbol, search_class_name, 
                                  0, 0, tag_files, '',
                                  num_matches, VSCODEHELP_MAXFUNCTIONHELPPROTOS,
                                  pushtag_mask, VS_TAGCONTEXT_ALLOW_locals,
                                  true, true, visited, depth);
   }

   // check for error condition
   //say("_ruby_get_return_type_of: num_matches="num_matches);
   if (num_matches < 0) {
      return num_matches;
   }

   // resolve the type of the matches
   rt.taginfo = '';
   int status = _ruby_get_type_of_matches(errorArgs, tag_files, symbol,
                                         search_class_name, cur_class_name,
                                         min_args, maybe_class_name,
                                         rt, visited, depth);
   if (!status && (ruby_return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
   }
   if (!status || status==VSCODEHELPRC_BUILTIN_TYPE) {
      visited:[input_args]=rt;
   }
   return status;
}

/**
 * Utility function for evaluating the return types of a match set
 * for a given symbol in order to resolve function overloading and
 * come to a consensus on the return type of the given symbol.
 * Returns the class name of the match, depth of pointer indirection
 * in return type, return type flags, and tag information for match.
 * If the given symbol is overloaded and returns different types,
 * this may return an error if it cannot resolve the overloading.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_*
 * @param tag_files           list of extension specific tag files
 * @param symbol              name of symbol having given return type
 * @param search_class_name   class context to evaluate return type relative to
 * @param cur_class_name      current class context (from tag_current_context)
 * @param min_args            minimum number of arguments for function, used
 *                            to resolve overloading.
 * @param maybe_class_name    Could the symbol be a class name, for example
 *                            C++ syntax of BaseObject::method, BaseObject might
 *                            be a class name.
 * @param rt                  (reference) set to return type (result)
 * @param visited             (reference) used to cache results and avoid recursion
 * @param depth               used to avoid recursion
 *
 * @return int
 *    0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _ruby_get_type_of_matches(_str (&errorArgs)[], typeless tag_files,
                                     _str symbol, _str search_class_name,
                                     _str cur_class_name, int min_args,
                                     boolean maybe_class_name,
                                     struct VS_TAG_RETURN_TYPE &rt,
                                     VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //say("_ruby_get_type_of_matches("symbol","search_class_name")");

   // make sure that the context doesn't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockContext(false);
   sentry.lockMatches(false);

   // filter out matches based on number of arguments
   _str matchlist[];
   matchlist._makeempty();
   boolean check_args=true;
   int num_matches = tag_get_num_of_matches();

   int i=0;
   _str tag_file='';
   _str proc_name='';
   _str type_name='';
   _str file_name='';
   int line_no=0;
   _str class_name='';
   int tag_flags=0;
   _str signature='';
   _str return_type='';

   for (;;) {
      for (i=1; i<=num_matches; i++) {
         tag_get_match(i,tag_file,proc_name,type_name,
                       file_name,line_no,class_name,tag_flags,signature,return_type);

         // check that number of argument matches.
         if (check_args && num_matches>1 && tag_tree_type_is_func(type_name) &&
             !(tag_flags & VS_TAGFLAG_operator)) {
            int num_args = 0;
            int def_args = 0;
            int arg_pos  = 0;
            for (;;) {
               _str parm='';
               tag_get_next_argument(signature, arg_pos, parm);
               if (parm == '') {
                  break;
               }
               if (pos('=', parm)) {
                  def_args++;
               }
               if (parm :== '...') {
                  num_args = min_args;
                  break;
               }
               num_args++;
            }
            // this prototype doesn't take enough arguments?
            if (num_args < min_args) {
               continue;
            }
            // this prototype requires too many arguments?
            if (num_args - def_args > min_args) {
               continue;
            }
         } else if (type_name=='typedef') {
            // skip over recursive typedefs
            _str p1='';
            _str p2='';
            parse return_type with p1 ' ' p2;
            if (symbol==return_type || symbol==p2) {
               continue;
            }
         }
         if ((tag_flags & VS_TAGFLAG_operator) && class_name :!= search_class_name) {
            continue;
         }
         if (rt.taginfo == '') {
            rt.taginfo = tag_tree_compose_tag(proc_name, class_name, type_name,
                                              tag_flags, signature, return_type);
         }
         if (tag_tree_type_is_class(type_name)) {
            return_type = proc_name;
         }
         if (return_type != '') {
            matchlist[matchlist._length()] = proc_name "\t" class_name "\t" file_name "\t" return_type;
         }
      }
      // break out of loop if we found something or check args is off
      if (min_args>0 || matchlist._length()>0 || !check_args) break;
      check_args=false;
   }

   // for each match in list, (have to do it this way because
   VS_TAG_RETURN_TYPE found_rt;tag_return_type_init(found_rt);
   VS_TAG_RETURN_TYPE match_rt;tag_return_type_init(match_rt);
   rt.return_type = '';
   errorArgs[1]=symbol;
   int status=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   int found_status=status;
   int num_repeats=0;
   for (i=0; i<matchlist._length(); i++) {

      parse matchlist[i] with proc_name "\t" class_name "\t" file_name "\t" return_type;

      tag_return_type_init(found_rt);
      found_rt.template_args = rt.template_args;
      found_rt.istemplate    = rt.istemplate;
      if (class_name=='') {
         status = _ruby_parse_return_type(errorArgs, tag_files, proc_name, cur_class_name,
                                         file_name, return_type, found_rt, visited, depth);
      } else {
         status = _ruby_parse_return_type(errorArgs, tag_files, proc_name, class_name,
                                         file_name, return_type, found_rt, visited, depth);
      }
      //say("**found_type="found_rt.return_type" match_type="rt.return_type" flags="found_rt.return_flags" status="status);
      if (status && status!=VSCODEHELPRC_BUILTIN_TYPE) {
         // skip over overloaded return types we can't handle
         status=found_status;
         found_rt=match_rt;
         continue;
      }
      if (found_rt.return_type != '') {

         if (rt.return_type=='') {
            found_status=status;
            match_rt=found_rt;
            rt.return_type = found_rt.return_type;
            rt.return_flags = found_rt.return_flags;
            rt.pointer_count += found_rt.pointer_count;
            match_rt.pointer_count = found_rt.pointer_count;
         } else {
            // different opinions on static_only or const_only, chose more general
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_STATIC_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_VOLATILE_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_CONST_ONLY;
            }
            if (!(found_rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
               rt.return_flags &= ~VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
            }
            if (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2)) {
               rt.return_flags &= ~(VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2);
               rt.return_flags |= (found_rt.return_flags & (VSCODEHELP_RETURN_TYPE_ARRAY|VSCODEHELP_RETURN_TYPE_HASHTABLE|VSCODEHELP_RETURN_TYPE_HASHTABLE2));
            }
            if (rt.return_type :!= found_rt.return_type || match_rt.pointer_count != found_rt.pointer_count) {
               // different return type, this is not good.
               errorArgs[1] = symbol;
               return VSCODEHELPRC_OVERLOADED_RETURN_TYPE;
            }
         }
         // if we have over five matching return types, then call it good
         num_repeats++;
         if (num_repeats>=4) {
            break;
         }
      }
   }
   if (status && status!=VSCODEHELPRC_BUILTIN_TYPE &&
       status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
      return status;
   }
   rt.template_args._makeempty();
   rt.istemplate = found_rt.istemplate;
   if (found_rt.istemplate) {
      rt.template_args = found_rt.template_args;
   }

   //say("maybe class name, num_matches="num_matches);
   // Java syntax like Class.blah... or C++ style iostream::blah
   if (maybe_class_name && num_matches==0) {
      //say("111 searching for class name, symbol="symbol" class="search_class_name);
      int filter_flags = VS_TAGFILTER_PACKAGE|VS_TAGFILTER_STRUCT|VS_TAGFILTER_INTERFACE|VS_TAGFILTER_UNION;
      int context_flags = (rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)? 0:VS_TAGCONTEXT_ALLOW_locals;
      tag_list_symbols_in_context(symbol, search_class_name, 
                                  0, 0, tag_files, '',
                                  num_matches, VSCODEHELP_MAXFUNCTIONHELPPROTOS,
                                  filter_flags, context_flags,
                                  true, true, visited, depth);

      //say("found "num_matches" matches");
      if (num_matches > 0) {
         _str x_tag_file='';
         _str x_tag_name='';
         _str x_type_name='';
         _str x_file_name='';
         int x_line_no=0;
         _str x_class_name='';
         int x_tag_flags=0;
         _str x_signature='';
         _str x_return_type='';
         tag_get_match(1, x_tag_file, x_tag_name, x_type_name, x_file_name, x_line_no, x_class_name, x_tag_flags, x_signature, x_return_type);
         rt.return_type = symbol;
         if (search_class_name == '' || search_class_name == cur_class_name) {
            _str outer_class_name = cur_class_name;
            int local_matches=0;
            if (x_tag_flags & VS_TAGFLAG_template) {
               rt.istemplate=true;
            }
            for (;;) {
               tag_list_symbols_in_context(rt.return_type, cur_class_name, 
                                           0, 0, tag_files, '',
                                           local_matches, def_tag_max_function_help_protos,
                                           filter_flags, context_flags, 
                                           true, true, visited, depth); 
               if (local_matches > 0) {
                  _str rel_tag_file='';
                  _str rel_tag_name='';
                  _str rel_type_name='';
                  _str rel_file_name='';
                  int rel_line_no=0;
                  _str rel_class_name='';
                  int rel_tag_flags=0;
                  _str rel_signature='';
                  _str rel_return_type='';
                  tag_get_match(1, rel_tag_file, rel_tag_name, rel_type_name, rel_file_name, rel_line_no, rel_class_name, rel_tag_flags, rel_signature, rel_return_type);
                  rt.return_type = tag_join_class_name(rt.return_type, rel_class_name, tag_files, true, true);
                  break;
               }
               _str junk='';
               tag_split_class_name(outer_class_name, junk, outer_class_name);
               if (outer_class_name=='') {
                  break;
               }
            }
         } else if (search_class_name != '') {
            rt.return_type = tag_join_class_name(rt.return_type, search_class_name, tag_files, true, true);
         }
      }
   }


   // no matches?
   if (num_matches == 0) {
      //say("_ruby_get_type_of_matches: no symbols found");
      errorArgs[1] = symbol;
      return VSCODEHELPRC_NO_SYMBOLS_FOUND;
   }

   // check if we should list private class members
   _str import_type='';
   if (tag_current_context()==0) {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
   } else {
      // current method is from same class, then we have private access
      int class_pos = lastpos(cur_class_name,rt.return_type);
      if (class_pos>0 && class_pos+length(cur_class_name)==length(rt.return_type)+1) {
         if (class_pos==1) {
            rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
         } else if (substr(rt.return_type,class_pos-1,1)==VS_TAGSEPARATOR_package) {
            // maybe class comes from imported namespace
            _str import_name = substr(rt.return_type,1,class_pos-2);
            int import_id = tag_find_local_iterator(import_name,true,true,false,'');
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_local_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_local_iterator(import_name,import_id,true,true,false,'');
            }
            import_id = tag_find_context_iterator(import_name,true,true,false,'');
            while (import_id > 0) {
               tag_get_detail2(VS_TAGDETAIL_context_type,import_id,import_type);
               if (import_type == 'import' || import_type == 'package' ||
                   import_type == 'library' || import_type == 'program') {
                  rt.return_flags |= VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS;
                  break;
               }
               import_id = tag_next_context_iterator(import_name,import_id,true,true,false,'');
            }
         }
      }
   }
   //say("_ruby_get_type_of_matches() returns "match_type" pointers="pointer_count);
   return 0;
}

/*
 * Utility function for getting the next token from the given prefix
 * expression string.
 *
 * @param prefixexp     (reference), prefix expression, after the function
 *                                   returns, contains prefix expression
 *                                   with the first token removed.
 *
 * @return string containing the next token in the prefix expression. '' if nothing.
 */
static _str _ruby_get_expr_token(_str &prefixexp)
{
   // get next token from expression
   int p = pos('^ @{->|\:\:|<<|>>|\&\&|\|\||[<>=\|\&\*\+-/~\^\%](=|)|:v|[()\.]|\[|\]}', prefixexp, 1, 'r');
   if (!p) {
      return '';
   }
   p = pos('S0');
   int n = pos('0');
   _str ch = substr(prefixexp, p, n);
   prefixexp = substr(prefixexp, p+n);
   return ch;
}

/**
 * Utility function for parsing the next part of the prefix expression.
 * This is called repeatedly by _ruby_get_type_of_prefix (below) as it
 * parses the prefix expression from left to right, tracking the return
 * type as it goes along.
 * <P>
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 *
 * @param errorArgs           array of strings for error message arguments
 *                            refer to codehelp.e VSCODEHELPRC_
 * @param tag_files           list of extension specific tag files
 * @param previous_id         the last identifier seen in the prefix expression
 * @param ch                  the last token removed from the prefix expression
 *                            (parsed out using _ruby_get_expr_token, above)
 * @param prefixexp           (reference) The remainder of the prefix expression
 * @param full_prefixexp      The entire prefix expression
 * @param rt                  (reference) set to return type result
 * @param visited             (reference) prevent recursion, cache results
 * @param reference_count     current class context (from tag_current_context)
 * @param depth               depth of recursion (for handling typedefs)
 *
 * @return 0 on success, <0 on error (one of VSCODEHELPRC_*, errorArgs must be set)
 */
static int _ruby_get_type_of_part(_str (&errorArgs)[], typeless tag_files,
                                  _str &previous_id, _str ch,
                                  _str &prefixexp, _str &full_prefixexp,
                                  struct VS_TAG_RETURN_TYPE &rt,
                                  struct VS_TAG_RETURN_TYPE (&visited):[],
                                  int &reference_count, int depth=0)
{
   //say("_ruby_get_type_of_part("previous_id","ch","prefixexp","full_prefixexp")");
   // was the previous identifier a builtin type?
   _str current_id = previous_id;
   boolean previous_builtin = false;
   if (_ruby_is_builtin_type(previous_id)) {
      previous_builtin=true;
   }

   // number of arguments in paren or brackets group
   int num_args = 0;
   int var_filters=0;

   // is the current token a builtin?
   if (_ruby_is_builtin_type(ch)) {
      previous_builtin=true;
      previous_id = ch;
      return 0;
   }

   // process token
   int status=0;
   int p=0;
   switch (ch) {
   case '->':     // pointer to member
      if (previous_id != '') {
         status = _ruby_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          VS_TAGFILTER_ANYDATA, true,
                                          rt,visited);
         if (status) {
            return status;
         }
         previous_id = '';
      }
      if (rt.pointer_count != 1) {
         errorArgs[1] = '->';
         errorArgs[2] = current_id;
         if (rt.pointer_count < 1) {
            return (VSCODEHELPRC_DASHGREATER_FOR_NON_POINTER);
         } else {
            return (VSCODEHELPRC_DASHGREATER_FOR_PTR_TO_POINTER);
         }
      }
      rt.pointer_count = 0;
      break;

   case '.':     // member access operator
      if (previous_id != '') {
         status = _ruby_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_ANYDATA, true,
                                          rt,visited);
         if (status) {
            return status;
         }
         previous_id = '';
      }
      if (rt.pointer_count > 0) {
         errorArgs[1] = '.';
         errorArgs[2] = current_id;
         return(VSCODEHELPRC_DOT_FOR_POINTER);
      } else if (rt.pointer_count < 0) {
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }
      break;

   case '::':    // static member or global scope indicator
      if (previous_id == '' && rt.return_type=='') {
         rt.return_flags |= VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY;
         rt.return_type = '::';
      } else if (previous_id != '') {
         _str orig_match_class=rt.return_type;
         _str orig_istemplate=rt.istemplate;
         typeless orig_template_args=rt.template_args;
         status = _ruby_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYSTRUCT, true,
                                          rt,visited);
         if (status) {
            rt.return_type=orig_match_class;
         }
         // THIS could be just a class qualification for making an
         // assignment to a pointer to member or pointer to member func.
         // SO, we have to list everything, not just statics.
         // ALSO, the class could be a base class qualification for a
         // function call BASE::myvirtualfunc();
         previous_id = '';
      } else {
         //say(":: already processed previous ID");
      }
      break;

   case 'new':   // new keyword
      // Just ignore 'new' if we don't know what to do with it
      if (depth==0 && !pos('[(.-]',prefixexp,1,'r')) {
         break;
      }
      p = pos('^:b{:v}:b', prefixexp, 1, 'r');
      if (!p) {
         // this is not good news...
         errorArgs[1] = 'new ' prefixexp;
         return VSCODEHELPRC_INVALID_NEW_EXPRESSION;
      }
      ch = substr(prefixexp, pos('S0'), pos('0'));
      prefixexp = substr(prefixexp, p+pos(''));
      rt.return_type = ch;
      if (substr(prefixexp, 1, 1):=='(') {
         prefixexp = substr(prefixexp, 2);
         _str parenexp='';
         if (!match_parens(prefixexp, parenexp, num_args)) {
            // this is not good
            errorArgs[1] = 'new 'ch' 'prefixexp;
            return VSCODEHELPRC_PARENTHESIS_MISMATCH;
         }
      }
      previous_id = '';
      rt.pointer_count=1;
      break;

   case '[':     // array subscript introduction
      if (!match_brackets(prefixexp, num_args)) {
         // this is not good
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_BRACKETS_MISMATCH;
      }
      if (previous_id != '') {
         current_id = previous_id;
         status = _ruby_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          VS_TAGFILTER_ANYDATA, false,
                                          rt,visited);
         if (status) {
            return status;
         }
         previous_id = '';
      }
      rt.pointer_count--;
      break;

   case ']':     // array subscript close
      // what do I do here?
      break;

   case '(':     // function call, cast, or expression grouping
      _str cast_type='';
      if (!match_parens(prefixexp, cast_type, num_args)) {
         // this is not good
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_PARENTHESIS_MISMATCH;
      }
      if (previous_id != '') {
         if (previous_builtin) {
            rt.return_type = previous_id;
            rt.pointer_count = 0;
         } else {
            // this was a function call
            _str orig_return_type = rt.return_type;
            status = _ruby_get_return_type_of(errorArgs,tag_files,previous_id,
                                             rt.return_type, num_args,
                                             VS_TAGFILTER_ANYPROC, false,
                                             rt,visited);
            _str new_match_class=rt.return_type;
            rt.return_type=orig_return_type;
            if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND &&
                status!=VSCODEHELPRC_RETURN_TYPE_NOT_FOUND) {
               return status;
            }
            // could not find match class, maybe this is a function-style cast?
            if (new_match_class == '') {
               int num_matches = 0;
               tag_list_symbols_in_context(previous_id, rt.return_type, 
                                           0, 0, tag_files, '',
                                           num_matches, VSCODEHELP_MAXFINDCONTEXTTAGS,
                                           VS_TAGFILTER_ANYSTRUCT|VS_TAGFILTER_TYPEDEF,
                                           VS_TAGCONTEXT_ALLOW_locals|VS_TAGCONTEXT_FIND_all,
                                           true, true, visited, depth, rt.template_args);
               if (num_matches > 0) {
                  _str dummy_tag = '';
                  status = _ruby_parse_return_type(errorArgs, tag_files, '', '', p_buf_name,
                                                previous_id, rt, visited);
               } else if (rt.return_type != '') {
                  rt.pointer_count = 0;
               }
            } else {
               rt.return_type = new_match_class;
               previous_id='';
            }
            previous_id = '';
         }
      } else {
         if (pos("^[*&(]@:v",prefixexp,1,'r')) {
            // a cast will be followed by an identifier, (, *, or &
            //say("think it's a cast, depth="depth);
            if (depth > 0) {
               status = _ruby_parse_return_type(errorArgs, tag_files,
                                               '', '', p_buf_name,
                                               cast_type, rt, visited);
               prefixexp='';
               return status;
            }
            // otherwise, just ignore the cast
         } else {
            // not a cast, must be an expression, go recursive
            status = _ruby_get_type_of_prefix(errorArgs, cast_type, rt, visited, depth+1);
            if (status) {
               return status;
            }
         }
      }
      break;

   case ')':
      // what do I do here?
      errorArgs[1] = full_prefixexp;
      return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;

   case 'char':
   case 'short':
   case 'int':
   case 'long':
   case 'signed':
   case 'unsigned':
   case 'float':
   case 'double':
   case 'void':
      previous_id = ch;
      previous_builtin = true;
      break;

   case 'this':
      status = _ruby_get_return_type_of(errorArgs, tag_files, ch, '', 0,
                                       VS_TAGFILTER_ANYDATA,
                                       false, rt, visited);
      if (status) {
         return status;
      }
      previous_id = '';
      rt.pointer_count = 1;
      break;

   case '*':     // dereference pointer
      reference_count--;
      break;
   case '&':     // get reference to object
      reference_count++;
      break;
   case '=':     // binary operators within expression
   case '-':
   case '+':
   case '/':
   case '%':
   case '^':
   case '<<':
   case '>>':
   case '&&':
   case '|':
   case '||':
   case '<=':
   case '>=':
   case '==':
   case '>':   // '<' is needed for templates, above
      if (depth <= 0) {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      if (previous_id != '') {
         rt.taginfo = '';
         status = _ruby_get_return_type_of(errorArgs, tag_files,
                                          previous_id, rt.return_type, 0,
                                          VS_TAGFILTER_ANYDATA,
                                          true, rt, visited);
         if (status) {
            return status;
         }
         previous_id = '';
      }
      // check for operator overloading
      if (rt.return_type != '') {
         _str orig_match_class=rt.return_type;
         status = _ruby_get_return_type_of(errorArgs, tag_files, ch, rt.return_type, 0,
                                          VS_TAGFILTER_ANYPROC, true, rt, visited);
         if (status && status!=VSCODEHELPRC_NO_SYMBOLS_FOUND) {
            rt.return_type=orig_match_class;
            return status;
         }
      }
      if (rt.return_type == '') {
         errorArgs[1] = full_prefixexp;
         return VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX;
      }
      prefixexp = '';  // breaks us out of loop
      break;

   default:
      // this must be an identifier (or drop-through case)
      rt.taginfo = '';
      previous_id = ch;
      var_filters = VS_TAGFILTER_VAR;
      if (rt.return_type == '') {
         var_filters |= VS_TAGFILTER_LVAR|VS_TAGFILTER_GVAR;
      }
      break;
   }

   // successful so far, cool.
   return 0;
}

/**
 * Utility function for determining the effective type of a prefix
 * expression.  It parses the expression from left to right, keeping
 * track of the current type of the prefix expression and using that
 * to evaluate the type of the next part of the expression in context.
 * The class context of the return type is returned in 'match_type',
 * along with a counter of the depth of pointers involved, return type
 * flags, and the tag corresponding to the item returned.
 * <P>
 * This function is technically private, use the public
 * function {@link _ruby_analyze_return_type()} instead.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param prefixexp      Prefix expression
 * @param rt             (reference) return type structure
 * @param depth          (optional) depth of recursion
 *
 * @return 0 on success, non-zero on error
 */
static int _ruby_get_type_of_prefix(_str (&errorArgs)[], _str prefixexp,
                                    struct VS_TAG_RETURN_TYPE &rt, 
                                    VS_TAG_RETURN_TYPE (&visited):[], int depth=0)
{
   //say("_ruby_get_type_of_prefix("prefixexp")");

   // initiialize return values
   rt.return_type   = '';
   rt.pointer_count = 0;
   rt.return_flags  = 0;

   // loop variables
   typeless tag_files       = tags_filenamea(p_LangId);
   _str     full_prefixexp  = prefixexp;
   _str     previous_id     = '';
   int      reference_count = 0;
   boolean  found_define    = false;

   // save the arguments, for retries later
   VS_TAG_RETURN_TYPE orig_rt = rt;
   _str     orig_prefixexp       = prefixexp;
   int      orig_reference_count = reference_count;
   _str     orig_previous_id     = previous_id;
   int status=0;

   // process the prefix expression, token by token, delegate
   // most of processing to recursive func _ruby_get_type_of_part
   while (prefixexp != '') {

      // get next token from expression
      _str ch = _ruby_get_expr_token(prefixexp);
      //say("get prefixexp = "prefixexp" ch="ch);
      if (ch == '') {
         // don't recognize something we saw
         errorArgs[1] = full_prefixexp;
         return(VSCODEHELPRC_CONTEXT_EXPRESSION_TOO_COMPLEX);
      }

      // process this part of the prefix expression
      status = _ruby_get_type_of_part(errorArgs, tag_files,
                                   previous_id, ch, prefixexp, full_prefixexp,
                                   rt, visited, reference_count, depth);

      if (status && found_define) {
         // try the original ID, not what the define said it was
         prefixexp        = orig_prefixexp;
         previous_id      = orig_previous_id;
         rt               = orig_rt;
         reference_count  = orig_reference_count;
         status = _ruby_get_type_of_part(errorArgs, tag_files,
                                      previous_id, ch, prefixexp, full_prefixexp,
                                      rt, visited, reference_count, depth);
      }
      if (status) {
         return status;
      }

      // check if 'previous' ID was a define
      found_define = false;
      orig_previous_id = previous_id;
      if (isid_valid(previous_id)) {
         tag_check_for_define(previous_id, p_line, tag_files, previous_id);
         if (previous_id != orig_previous_id) {
            found_define=true;
         }
      }

      // save the arguments, for retries later
      orig_prefixexp       = prefixexp;
      orig_rt              = rt;
      orig_reference_count = reference_count;
   }

   if (previous_id != '') {
      int var_filters = VS_TAGFILTER_ANYDATA|VS_TAGFILTER_ANYPROC;
      status = _ruby_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                       var_filters, true, rt, visited);
      if (status && found_define) {
         // try the original ID, not what the define said it was
         prefixexp        = orig_prefixexp;
         rt               = orig_rt;
         reference_count  = orig_reference_count;
         previous_id      = orig_previous_id;

         status = _ruby_get_return_type_of(errorArgs, tag_files, previous_id, rt.return_type, 0,
                                        var_filters, true, rt, visited);
      }
      if (status) {
         return status;
      }
      previous_id = '';
   }
   rt.pointer_count += reference_count;

   // is the current token a builtin?
   if (rt.pointer_count==0 && _ruby_is_builtin_type(rt.return_type)) {
      rt.return_flags |= VSCODEHELP_RETURN_TYPE_BUILTIN;
      if (_ruby_is_builtin_type(rt.return_type,true)) {
         return 0;
      }
      errorArgs[1]=previous_id;
      errorArgs[2]=rt.return_type;
      return VSCODEHELPRC_BUILTIN_TYPE;
   }

   //say("_ruby_get_type_of_prefix: returns "match_class);
   return 0;
}

void _ruby_autocomplete_before_replace(AUTO_COMPLETE_INFO &word,
                                       VS_TAG_IDEXP_INFO &idexp_info, 
                                       _str terminationKey="")
{
   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & VS_TAGFLAG_operator) &&
       last_char(idexp_info.prefixexp) == ".") {
      word.insertWord = word.symbol.member_name;
      word.symbol.type_name = "statement";
   }
}

boolean _ruby_autocomplete_after_replace(AUTO_COMPLETE_INFO &word,
                                         VS_TAG_IDEXP_INFO &idexp_info, 
                                         _str terminationKey="")
{
   // special handling for overloaded operators
   if (idexp_info != null && word.symbol != null &&
       (word.symbol.flags & VS_TAGFLAG_operator) &&
       last_char(idexp_info.prefixexp) == ".") {
      // delete the '.' charactor
      if (!_clex_is_identifier_char(first_char(word.insertWord))) {
         p_col -= length(word.insertWord)+1;
         _delete_char();
         if (terminationKey == " ") {
            _insert_text(" ");
         }
         p_col += length(word.insertWord);
      }
      // do not double-insert the operator
      if (terminationKey == first_char(word.insertWord)) {
         if (length(word.insertWord) == 1) {
            p_col--;
            _delete_char();
         } else {
            last_event("");
         }
      }
   }

   return true;
}



/**
 * <B>Hook Function</B> -- _[ext]_find_context_tags
 * <P>
 * Find tags matching the identifier at the current cursor position
 * using the information extracted by {@link 
 * _ruby_get_expression_info()}. 
 *
 * @param errorArgs          List of argument for codehelp error messages
 * @param prefixexp          prefix expression, see {@link 
 *                           _ruby_get_expression_info}
 * @param lastid             identifier under cursor
 * @param lastid_prefix      prefix of identifier under cursor
 * @param lastidstart_offset start offset of identifier under cursor
 * @param info_flags         bitset of VSAUTOCODEINFO_*
 * @param otherinfo          extension specific information
 * @param find_parents       find matches in parent classes
 * @param max_matches        maximum number of matches to find
 * @param exact_match        exact match or prefix match for lastid?
 * @param case_sensitive     case sensitive match?
 * @param filter_flags       bitset of VS_TAGFILTER_*
 * @param context_flags      bitset of VS_TAGCONTEXT_*
 * @param visited            hash table of prior results
 * @param depth              depth of recursive search
 *
 * @return 0 on sucess, nonzero on error
 */
int _ruby_find_context_tags(_str (&errorArgs)[],_str prefixexp,
                            _str lastid,int lastidstart_offset,
                            int info_flags,typeless otherinfo,
                            boolean find_parents,int max_matches,
                            boolean exact_match,boolean case_sensitive,
                            int filter_flags=VS_TAGFILTER_ANYTHING,
                            int context_flags=VS_TAGCONTEXT_ALLOW_locals,
                            VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   //say("_ruby_find_context_tags("prefixexp","lastid);
   // id followed by paren, then limit search to functions
   errorArgs._makeempty();
   if (info_flags & VSAUTOCODEINFO_LASTID_FOLLOWED_BY_PAREN) {
      context_flags |= VS_TAGCONTEXT_ONLY_funcs;
   }

   // watch out for unwelcome 'new' as prefix expression
   if (strip(prefixexp)=='new') {
      prefixexp='';
   }

   // context is a goto statement?
   if (info_flags & VSAUTOCODEINFO_IN_GOTO_STATEMENT) {
      label_count := 0;
      if (context_flags & VS_TAGCONTEXT_ALLOW_locals) {
         _CodeHelpListLabels(0, 0, lastid, '',
                             label_count, max_matches,
                             exact_match, case_sensitive, 
                             visited, depth);
      }
      return (label_count>0)? 0 : VSCODEHELPRC_NO_LABELS_DEFINED;
   }

   // get the tag file list
   tag_files := tags_filenamea(p_LangId);
   if ((context_flags & VS_TAGCONTEXT_ONLY_this_file) ||
       (context_flags & VS_TAGCONTEXT_ONLY_locals)) {
      tag_files._makeempty();
   }

   // no prefix expression, update globals and symbols from current context
   if (prefixexp == '') {
      return _do_default_find_context_tags(errorArgs,
                                           prefixexp,
                                           lastid, lastidstart_offset,
                                           info_flags, otherinfo,
                                           find_parents,
                                           max_matches,
                                           exact_match, case_sensitive,
                                           filter_flags, context_flags,
                                           visited, depth);
   }

   // evaluate prefix expression and list members of class
   VS_TAG_RETURN_TYPE rt;
   tag_return_type_init(rt);
   is_package := false;

   // maybe prefix expression is a package name or prefix of package name
   num_matches := 0;
   if (tag_check_for_package(prefixexp:+lastid, tag_files, false, true)) {
      is_package=true;
      tag_list_context_packages(0, 0, 
                                prefixexp, tag_files,
                                num_matches, max_matches,
                                exact_match,  case_sensitive);
   }

   // analyse prefix expression to determine effective class type
   status := _ruby_get_type_of_prefix(errorArgs, prefixexp, rt, visited);
   if (status) {
      return status;
   }
   context_flags = VS_TAGCONTEXT_ONLY_inclass;
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_PRIVATE_ACCESS) {
      context_flags |= VS_TAGCONTEXT_ACCESS_private;
   }
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_CONST_ONLY) {
      context_flags |= VS_TAGCONTEXT_ONLY_const;
   }
   if (rt.return_flags & VSCODEHELP_RETURN_TYPE_STATIC_ONLY) {
      context_flags |= VS_TAGCONTEXT_ONLY_static;
   }
   if (!(rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY)) {
      context_flags |= VS_TAGCONTEXT_ALLOW_locals;
   }

   if ((rt.return_flags & VSCODEHELP_RETURN_TYPE_GLOBALS_ONLY) &&
       (rt.return_type=='::' || rt.return_type=='')) {
      // :: operator
      tag_list_context_globals(0, 0, lastid,
                               true, tag_files,
                               filter_flags, context_flags,
                               num_matches, max_matches,
                               exact_match, case_sensitive,
                               visited, depth);
   } else {
      tag_list_in_class(lastid, rt.return_type,
                        0, 0, tag_files,
                        num_matches, VSCODEHELP_MAXLISTMEMBERSSYMBOLS,
                        filter_flags, context_flags,
                        exact_match, case_sensitive, 
                        null, null, visited, depth);
   }

   // Return 0 indicating success if anything was found
   errorArgs[1] = (lastid=='')? rt.return_type:lastid;
   return (num_matches <= 0)? VSCODEHELPRC_NO_SYMBOLS_FOUND:0;
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get_start
 * <P>
 * Context Tagging&reg; hook function for function help.  Finds the start
 * location of a function call and the function name.  This determines
 * quickly whether or not we are in the context of a function call.
 *
 * @param errorArgs                List of argument for codehelp error messages
 * @param OperatorTyped            When true, user has just typed last
 *                                 character of operator.
 *                                 <PRE>
 *                                    p->myfunc( &lt;Cursor Here&gt;
 *                                 </PRE>
 *                                 This should be false if
 *                                 cursorInsideArgumentList is true.
 * @param cursorInsideArgumentList When true, user requested function help when
 *                                 the cursor was inside an argument list.
 *                                 <PRE>
 *                                    MessageBox(...,&lt;Cursor Here&gt;...)
 *                                 </PRE>
 *                                 Here we give help on MessageBox
 * @param FunctionNameOffset       (reference) Offset to start of first argument
 * @param ArgumentStartOffset      (reference) set to seek position of argument
 * @param flags                    (reference) bitset of VSAUTOCODEINFO_*
 *
 * @return
 *    0    Successful<BR>
 *    VSCODEHELPRC_CONTEXT_NOT_VALID<BR>
 *    VSCODEHELPRC_NOT_IN_ARGUMENT_LIST<BR>
 *    VSCODEHELPRC_NO_HELP_FOR_FUNCTION
 */
int _ruby_fcthelp_get_start(_str (&errorArgs)[],
                            boolean OperatorTyped,
                            boolean cursorInsideArgumentList,
                            int &FunctionNameOffset,
                            int &ArgumentStartOffset,
                            int &flags
                           )
{
   return(_c_fcthelp_get_start(errorArgs,OperatorTyped,
                               cursorInsideArgumentList,
                               FunctionNameOffset,
                               ArgumentStartOffset,flags));
}

/**
 * <B>Hook Function</B> -- _ext_fcthelp_get
 * <P>
 * Context Tagging&reg; hook function for retrieving the information
 * about each function possibly matching the current function call
 * that function help has been requested on.
 * <P>
 * If there is no help for the first function, a non-zero value
 * is returned and message is usually displayed.
 * <P>
 * If the end of the statement is found, a non-zero value is
 * returned.  This happens when a user to the closing brace
 * to the outer most function caller or does some weird
 * paste of statements.
 * <P>
 * If there is no help for a function and it is not the first
 * function, FunctionHelp_list is filled in with a message
 * <PRE>
 *     FunctionHelp_list._makeempty();
 *     FunctionHelp_list[0].proctype=message;
 *     FunctionHelp_list[0].argstart[0]=1;
 *     FunctionHelp_list[0].arglength[0]=0;
 *     FunctionHelp_list[0].return_type='';
 * </PRE>
 *
 * @param errorArgs                    (reference) error message arguments
 *                                     refer to codehelp.e VSCODEHELPRC_*
 * @param FunctionHelp_list            (reference) Structure is initially empty.
 *                                     FunctionHelp_list._isempty()==true
 *                                     You may set argument lengths to 0.
 *                                     See VSAUTOCODE_ARG_INFO structure in slick.sh.
 * @param FunctionHelp_list_changed    (reference) Indicates whether the data in
 *                                     FunctionHelp_list has been changed.
 *                                     Also indicates whether current
 *                                     parameter being edited has changed.
 * @param FunctionHelp_cursor_x        Indicates the cursor x position
 *                                     in pixels relative to the edit window
 *                                     where to display the argument help.
 * @param FunctionHelp_HelpWord        (reference) set to name of function
 * @param FunctionNameStartOffset      Offset to start of function name.
 * @param flags                        bitset of VSAUTOCODEINFO_*
 *
 * @return
 *    Returns 0 if we want to continue with function argument
 *    help.  Otherwise a non-zero value is returned and a
 *    message is usually displayed.
 *    <PRE>
 *    1    Not a valid context
 *    (not implemented yet)
 *    10   Context expression too complex
 *    11   No help found for current function
 *    12   Unable to evaluate context expression
 *    </PRE>
 */
int _ruby_fcthelp_get(_str (&errorArgs)[],
                      VSAUTOCODE_ARG_INFO (&FunctionHelp_list)[],
                      boolean &FunctionHelp_list_changed,
                      int &FunctionHelp_cursor_x,
                      _str &FunctionHelp_HelpWord,
                      int FunctionNameStartOffset,
                      int flags,
                      VS_TAG_BROWSE_INFO symbol_info=null,
                      VS_TAG_RETURN_TYPE (&visited):[]=null, int depth=0)
{
   return _c_fcthelp_get(errorArgs,
                         FunctionHelp_list,FunctionHelp_list_changed,
                         FunctionHelp_cursor_x,
                         FunctionHelp_HelpWord,
                         FunctionNameStartOffset,
                         flags, symbol_info,
                         visited, depth);
}

/**
 * <B>Hook function</B> -- _ext_analyze_return_type
 * <P>
 * Hook function for analyzing variable or function return types.
 * This is used by function argument type matching to determine the
 * precise type of the argument required, and the types of all the
 * candidate variables.
 *
 * @param errorArgs      List of argument for codehelp error messages
 * @param tag_files      list of tag files
 * @param tag_name       name of tag to analyze return type of
 * @param class_name     name of class that the tag belongs to
 * @param type_name      type name of tag (see VS_TAGTYPE_*)
 * @param tag_flags      tag flags (bitset of VS_TAGFLAG_*)
 * @param file_name      file that the tag is found in
 * @param return_type    return type to analyze (VS_TAGDETAIL_return_only)
 * @param rt             (reference) returned return type information
 * @param visited        (reference) hash table of previous results
 *
 * @return 0 on success, nonzero otherwise.
 */
/*
int _ruby_analyze_return_type(_str (&errorArgs)[],typeless tag_files,
                              _str tag_name, _str class_name,
                              _str type_name, int tag_flags,
                              _str file_name, _str return_type,
                              struct VS_TAG_RETURN_TYPE &rt,
                              struct VS_TAG_RETURN_TYPE (&visited):[])
{
   //say("_ruby_analyze_return_type: tag="tag_name" type="return_type);
   errorArgs._makeempty();
   // check for #define'd constants
   if (type_name=='define') {
      rt.istemplate=false;
      rt.taginfo=tag_tree_compose_tag(tag_name,class_name,type_name,tag_flags,"",return_type);
      if (pos("^:i$",return_type,1,'r')) {
         rt.return_type='int';
      } else if (pos("^:n$",return_type,1,'r')) {
         rt.return_type='float';
      } else if (pos("^['](\\\\?|?)[']$",return_type,1,'r')) {
         rt.return_type='char';
      } else if (pos("^:q$",return_type,1,'r')) {
         rt.return_type='char';
         rt.pointer_count=1;
      } else if (return_type=='false' || return_type=='true') {
         rt.return_type='bool';
      }
      if (rt.return_type=='') {
         rt.taginfo="";
         errorArgs[1]=tag_name;
         return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
      }
      return(0);
   } else if (type_name=='enumc') {
      rt.istemplate=false;
      rt.taginfo=tag_tree_compose_tag(tag_name,class_name,type_name,tag_flags);
      rt.return_type=class_name;
      rt.pointer_count=0;
      return(0);
   } else if (type_name=='enum') {
      rt.taginfo="";
      errorArgs[1]=tag_name;
      return VSCODEHELPRC_RETURN_TYPE_NOT_FOUND;
   }
   // delegate to the return type analysis functions
   int status = _ruby_parse_return_type(errorArgs,tag_files,
                                       tag_name,class_name,file_name,
                                       return_type,rt,visited);
   //say("_ruby_analyze_return_type: tag="tag_name" status="status" type="rt.return_type);

   // that's all, return result, allow builtin types
   if ((status && status!=VSCODEHELPRC_BUILTIN_TYPE)) {
      return(status);
   }
   return(0);
}
*/

// Table of type conversions for each ruby's builtin types.
// If the first char of the list of candidate types is '*', the
// type is a builtin type, but has intrinsic methods, so should not
// be treated as a builtin type in all cases.
//
static _str _ruby_type_conversions:[] = {

   // EXPECTED TYPE     => CANDIDATE TYPE
   // --------------------------------------------------------------------
   'bool'               => ':bool:int:long:',
   'char'               => ':char:',
   'double'             => ':double:float:',
   'float'              => ':float:',
   'int'                => ':bool:enum:int:short:signed int:signed:',
   'long'               => ':enum:long:signed long:long int:',
   'short'              => ':sort:signed short:short int:',
   'unsigned char'      => ':char:unsigned char:',
   'unsigned int'       => ':unsigned int:unsigned short:unsigned:',
   'unsigned long'      => ':unsigned long:unsigned int:',
   'unsigned short'     => ':unsigned short:',
   'unsigned'           => ':unsigned int:unsigned short:unsigned:'
};

/**
 * <B>Hook function</B> -- _ext_is_builtin_type
 *
 * Is the given return type a builtin type?
 *
 * @param return_type    Return type to check if it is builtin
 * @param no_class_types Do not include objects, such as _str in Slick-C
 *
 * @return true if it is builtin, false otherwise
 */
boolean _ruby_is_builtin_type(_str return_type, boolean no_class_types=false)
{
   // void is a special case, can't assign to this
   if (return_type=='void') {
      return(true);
   }
   // Is the return type in the table?
   if (_ruby_type_conversions._indexin(return_type)) {
      // is it a class type?
      if (no_class_types && substr(_ruby_type_conversions:[return_type],1,1)!='*') {
         return(false);
      }
      // this is a built-in
      return(true);
   }
   // this is not a built-in type
   return(false);
}

/**
 * <B>Hook function</B> -- _ext_builtin_assignment_compatible
 * <P>
 * Can a variable of the 'candidate_type' be assigned to a variable
 * of the 'expected_type', where both types are builtin types?
 *
 * @param expected_type        Expected type to assign to
 * @param candidate_type       Candidate type to check compability of
 * @param candidate_is_pointer Is the candidate type a pointer?
 *
 * @return true if assignment compatible, false otherwise
 */
/*
boolean _ruby_builtin_assignment_compatible(_str expected_type,
                                            _str candidate_type,
                                            boolean candidate_is_pointer)
{
   // if the types match exactly, then always return true,
   // no matter what language, except for 'enum' and 'void'
   if (!candidate_is_pointer && expected_type:==candidate_type &&
       expected_type:!='enum' && expected_type!='void') {
      return(true);
   }

   // special case for 'c', pointers are assignment compatible with bool
   if (candidate_is_pointer) {
      return(expected_type=='bool');
   }

   // void is a special case, can't assign to this
   if (expected_type=='void' && !candidate_is_pointer) {
      return(false);
   }

   // otherwise, the answer is in the mighty table
   if (_ruby_type_conversions._indexin(expected_type)) {
      _str allowed_list = _ruby_type_conversions:[expected_type];
      return (pos(":"candidate_type":",allowed_list))? true:false;
   }

   // didn't find a match, assume that it doesn't match
   return(false);
}
*/

/**
 * <B>Hook function</B> -- _ext_get_expression_pos
 * <P>
 * Get the position of a comparible identifier in the
 * current expression that we can use to determine the expected
 * return type
 *
 * @param lhs_start_offset   (reference) seek position of matching identifier
 * @param expression_op      (reference) expression operator
 * @param pointer_count      (reference) set to number of times lhs is dereferenced
 *                           either through an array operator or * (future fix)
 *
 * @return 0 on success, non-zero otherwise
 */
/*
int _ruby_get_expression_pos(int &lhs_start_offset,
                             _str &expression_op,
                             int &pointer_count)
{
   // first check for a compatible operator
   save_pos(auto p);
   if (get_text()!='') {
      left();
   }
   gtk=ruby_prev_sym();

   // allow one open parenthesis, no more (this is a fudge-factor)
   if (gtk=='(') {
      gtk=ruby_prev_sym();
   }

   // handle return statements
   if (gtkinfo=='return') {
      expression_op=gtkinfo;
      _UpdateContext(true);
      int context_id=tag_current_context();
      if (context_id > 0) {
         _str type_name='';
         tag_get_detail2(VS_TAGDETAIL_context_type,context_id,type_name);
         if (tag_tree_type_is_func(type_name)) {
            int start_seekpos=0;
            _str proc_name='';
            tag_get_detail2(VS_TAGDETAIL_context_start_seekpos,context_id,start_seekpos);
            tag_get_detail2(VS_TAGDETAIL_context_name,context_id,proc_name);
            _GoToROffset(start_seekpos);
            save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
            int search_status=search(_escape_re_chars(proc_name)'[ \t]*[(]','@r');
            if (!search_status) {
               lhs_start_offset=(int)_QROffset();
               restore_search(s1,s2,s3,s4,s5);
               restore_pos(p);
               return(0);
            }
            restore_search(s1,s2,s3,s4,s5);
         }
      }
      // must have failed here
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }

   // check list of other allowed expression operators
   _str allowed=" = == += -= != %= ^= *= &= |= /= >= <= > < + - * / % ^ & | ";
   if (p_LangId=='e') {
      allowed=allowed:+':== :!= .= ';
   }
   if (!pos(' 'gtkinfo' ',allowed)) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   expression_op=gtkinfo;

   // ok, now what is on the other side of the expresson?
   gtk=ruby_prev_sym();

   // watch for array arguments
   while (gtk==']') {
      right();
      int status=find_matching_paren();
      if (status) {
         restore_pos(p);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      pointer_count++;
      left();
      gtk=ruby_prev_sym();
   }

   // watch for function call
   if (gtk==')') {
      right();
      int status=find_matching_paren();
      if (status) {
         restore_pos(p);
         return(VSCODEHELPRC_CONTEXT_NOT_VALID);
      }
      left();
      gtk=ruby_prev_sym();
   }

   // didn't found an ID after all that work...
   if (gtk!=TK_ID) {
      restore_pos(p);
      return VSCODEHELPRC_CONTEXT_NOT_VALID;
   }
   right();
   lhs_start_offset=(int)point('s');
   restore_pos(p);
   return(0);
}
*/

/**
 * <B>Hook function</B> -- _ext_generate_match_signature
 * <P>
 * Generate the signature for the given match from the
 * match.  See {@link tag_get_match()}.
 * <p> 
 * For synchronization, macros should perform a 
 * tag_lock_matches(false) prior to invoking this
 * function.
 *
 * @param match_id             match ID from tagsdb match set
 * @param ruby_access_flags     bitset of VS_TAGFLAG_* (VS_TAGFLAG_access)
 * @param header_list          list of lines to insert as header comment
 * @param indent_col           indentation column
 * @param begin_col            start column (for class)
 * @param make_proto           make a prototype or definition?
 * @param in_class_scope       are we in the class scope or outside?
 * @param className            class name (if we are outside class scope)
 * @param class_signature      class signature (for templates)
 *
 * @return Returns the necessary cursor position
 */
int _ruby_generate_match_signature(int match_id, int &ruby_access_flags,
                                   _str (&header_list)[],
                                   int indent_col, int begin_col,
                                   boolean make_proto=false,
                                   boolean in_class_scope=true,
                                   _str className='',
                                   _str class_signature='')
{
   // make sure that the matches don't get modified by a background thread.
   se.tags.TaggingGuard sentry;
   sentry.lockMatches(true);

   // get the information about this match
   _str tag_file='';
   _str tag_name='';
   _str type_name='';
   _str file_name='';
   int line_no=0;
   _str class_name='';
   int tag_flags=0;
   _str signature='';
   _str return_type='';
   _str exceptions='';
   _str access='';
   tag_get_match(match_id,tag_file,tag_name,type_name,file_name,
                 line_no,class_name,tag_flags,signature,return_type);
   tag_get_detail2(VS_TAGDETAIL_match_throws,match_id,exceptions);
   // generate access specifier keywords
   _str before_return='';
   boolean is_java = false;
   int show_access=0;
   switch (ruby_access_flags) {
   case VS_TAGFLAG_public:
   case VS_TAGFLAG_package:
      access="public";
      break;
   case VS_TAGFLAG_protected:
      access="protected";
      break;
   case VS_TAGFLAG_private:
      access="private";
      break;
   }
   // show access flags
   if ((tag_flags & VS_TAGFLAG_access) != ruby_access_flags) {
      ruby_access_flags = (tag_flags & VS_TAGFLAG_access);
      show_access=VSCODEHELPDCLFLAG_SHOW_ACCESS;
   }

   // generate comment block
   int i=0;
   for (i=0;i<header_list._length();++i) {
      insert_line(header_list[i]);
   }

   int show_inline=0;
   if (!in_class_scope &&
       file_eq(file_name,p_buf_name) &&
       pos('h',_get_extension(p_buf_name))) {
      show_inline=VSCODEHELPDCLFLAG_SHOW_INLINE;
      strappend(before_return,'inline ');
   }
   int show_class=0;
   if (!in_class_scope && class_name!='') {
      show_class=VSCODEHELPDCLFLAG_SHOW_CLASS;
   }
   int in_class_def=(in_class_scope)?VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF:0;
   VS_TAG_BROWSE_INFO info;
   tag_browse_info_init(info);
   info.class_name=class_name;
   info.member_name=tag_name;
   info.type_name=type_name;
   if (make_proto) {
      info.flags=tag_flags;
   } else {
      info.flags=tag_flags & ~VS_TAGFLAG_native;
   }
   info.return_type=return_type;
   info.arguments=signature;
   info.exceptions=exceptions;
   info.language=p_LangId;

   if (!in_class_scope &&
       file_eq(file_name,p_buf_name) &&
       pos('h',_get_extension(p_buf_name))) {
      strappend(before_return,'inline ');
   }
   _str result=_ruby_get_decl(p_LangId,info,
                      VSCODEHELPDCLFLAG_VERBOSE|show_access|show_inline|show_class|in_class_def,
                      indent_string(indent_col),
                      indent_string(begin_col));

   _str punctuation = (make_proto)? ';':' {';
   _end_line();
   _insert_text("\n"result:+punctuation);
   typeless AfterKeyinPos;
   save_pos(AfterKeyinPos);
   if (!make_proto) {
      insert_line(indent_string(indent_col):+'}');
   }
   return (AfterKeyinPos);
}

/**
 * <B>Hook function</B> -- _[lang]_get_decl
 * <P>
 * Format the given tag for display as the variable definition part
 * in list-members or function help.  This function is also used
 * for generating code (override method, add class member, etc.).
 * The current object must be an editor control.
 *
 * @param lang           Current language ID {@see p_LangId} 
 * @param info           tag information
 *                       <UL>
 *                       <LI>info.class_name
 *                       <LI>info.member_name
 *                       <LI>info.type_name;
 *                       <LI>info.flags;
 *                       <LI>info.return_type;
 *                       <LI>info.arguments
 *                       <LI>info.exceptions
 *                       </UL>
 * @param flags          bitset of VSCODEHELPDCLFLAG_*
 * @param decl_indent_string    string to indent declaration with.
 * @param access_indent_string  string to indent public: with.
 *
 * @return string holding formatted declaration.
 */
_str _ruby_get_decl(_str lang,
                    VS_TAG_BROWSE_INFO &info,
                    int flags=0,
                    _str decl_indent_string="",
                    _str access_indent_string="")
{
   int tag_flags=info.flags;
   _str tag_name=info.member_name;
   _str class_name=info.class_name;
   _str type_name=info.type_name;
   int in_class_def=(flags&VSCODEHELPDCLFLAG_OUTPUT_IN_CLASS_DEF);
   int verbose=(flags&VSCODEHELPDCLFLAG_VERBOSE);
   int show_class=(flags&VSCODEHELPDCLFLAG_SHOW_CLASS);
   int show_access=(flags&VSCODEHELPDCLFLAG_SHOW_ACCESS);
   _str arguments = (info.arguments!='')? '('info.arguments')':'';
   _str class_sep = '::';

   //say("_ruby_get_decl: type_name="type_name);
   switch (type_name) {
   case 'proc':         // procedure or command
   case 'proto':        // function prototype
   case 'constr':       // class constructor
   case 'destr':        // class destructor
   case 'func':         // function
   case 'procproto':    // Prototype for procedure
   case 'subfunc':      // Nested function or cobol paragraph
   case 'subproc':      // Nested procedure or cobol paragraph
      _str before_return=decl_indent_string;
      if (show_access) {
         int ruby_access_flags = (tag_flags & VS_TAGFLAG_access);
         switch (ruby_access_flags) {
         case VS_TAGFLAG_public:
         case VS_TAGFLAG_package:
            before_return='';
            strappend(before_return,access_indent_string:+"public:\n");
            strappend(before_return,decl_indent_string);
            break;
         case VS_TAGFLAG_protected:
            before_return='';
            strappend(before_return,access_indent_string:+"protected:\n");
            strappend(before_return,decl_indent_string);
            break;
         case VS_TAGFLAG_private:
            before_return='';
            // yes, this can not happen
            strappend(before_return,access_indent_string:+"private:\n");
            strappend(before_return,decl_indent_string);
            break;
         }
      }
      // other keywords before return type
      if (verbose) {
         if (in_class_def && (tag_flags & VS_TAGFLAG_static)) {
            strappend(before_return,'static ');
         }
         if (tag_flags & VS_TAGFLAG_native) {
            strappend(before_return,'native ');
         }
         if ((tag_flags & VS_TAGFLAG_virtual) && in_class_def) {
            strappend(before_return,'virtual ');
         }
         if (tag_flags & VS_TAGFLAG_final) {
            strappend(before_return,'final ');
         }
      }

      // prepend qualified class name for C++
      if (tag_flags & VS_TAGFLAG_operator) {
         tag_name = 'operator 'tag_name;
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }

      // compute keywords falling in after the signature
      _str after_sig='';
      if (tag_flags & VS_TAGFLAG_const) {
         strappend(after_sig, ' const');
      }
      // finally, insert the line
      _str return_type = info.return_type;
      return_type = (return_type=='')? 'int ':return_type:+' ';
      return before_return:+return_type:+tag_name:+'('info.arguments')':+after_sig;

   case 'define':       // preprocessor macro definition
      return(decl_indent_string'#define ':+tag_name:+arguments:+' 'info.return_type);

   case 'typedef':      // type definition
      return(decl_indent_string'typedef 'info.return_type:+arguments' 'tag_name);

   case 'gvar':         // global variable declaration
   case 'var':          // member of a class / struct / package
   case 'lvar':         // local variable declaration
   case 'prop':         // property
   case "param":        // function or procedure parameter
   case 'group':        // Container variable
      _str return_start='';
      _str array_arguments='';
      parse info.return_type with return_start '[' array_arguments ']';
      if (array_arguments!='') {
         array_arguments='['array_arguments']';
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }
      return(decl_indent_string:+return_start' 'tag_name:+array_arguments);

   case 'struct':       // structure definition
   case 'enum':         // enumerated type
   case 'class':        // class definition
   case 'union':        // structure / union definition
   case 'interface':    // interface, eg, for Java
   case 'package':      // package / module / namespace
   case 'prog':         // pascal program
   case 'lib':          // pascal library
      if (!in_class_def && show_class && class_name!='') {
         class_name = stranslate(class_name,class_sep,':');
         class_name = stranslate(class_name,class_sep,'/');
         tag_name   = class_name:+class_sep:+tag_name;
      }
      arguments = (info.arguments!='')? '<'info.arguments'>' : '';
      if (type_name:=='package') {
         type_name='namespace';
      }
      return(decl_indent_string:+type_name' 'tag_name:+arguments);

   case 'label':        // label
      return(decl_indent_string:+tag_name':');

   case 'import':       // package import or using
      return(decl_indent_string:+'import 'tag_name);

   case 'friend':       // C++ friend relationship
      return(decl_indent_string:+'friend 'tag_name:+arguments);

   case 'include':      // C++ include or Ada with (dependency)
      return(decl_indent_string:+'#include 'tag_name);

   case 'form':         // GUI Form or window
      return(decl_indent_string:+'_form 'tag_name);
   case 'menu':         // GUI Menu
      return(decl_indent_string:+'_menu 'tag_name);
   case 'control':      // GUI Control or Widget
      return(decl_indent_string:+'_control 'tag_name);
   case 'eventtab':     // GUI Event table
      return(decl_indent_string:+'defeventtab 'tag_name);

   case 'const':        // pascal constant
   case "enumc":        // enumeration value
      _str proto=decl_indent_string;
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,class_sep,':');
         class_name= stranslate(class_name,class_sep,'/');
         strappend(proto,class_name:+class_sep);
      }
      strappend(proto,info.member_name);
      if (info.return_type!='') {
         strappend(proto," = "info.return_type);
      }
      return(proto);


   case "database":     // SQL/OO Database
   case "table":        // Database Table
   case "column":       // Database Column
   case "index":        // Database index
   case "view":         // Database view
   case "trigger":      // Database trigger
   case "task":         // Ada task
   case "file":         // COBOL file descriptor
   case "cursor":       // Database result set cursor
      return(decl_indent_string:+type_name' 'tag_name);

   case "tag":          // HTML / XML / SGML tag
      return(decl_indent_string:+'&lt;'info.member_name'&lt;');

   default:
      proto=decl_indent_string;
      if (info.return_type!='') {
         strappend(proto,info.return_type' ');
      }
      if (!in_class_def && show_class && class_name!='') {
         class_name= stranslate(class_name,class_sep,':');
         class_name= stranslate(class_name,class_sep,'/');
         strappend(proto,class_name:+class_sep);
      }
      strappend(proto,info.member_name);
      return(proto);
   }
}

/**
 * <B>Hook function</B> -- _ext_insert_constants_of_type
 * <P>
 * Insert the language-specific constants matching the expected type.
 *
 * @param rt_expected    expected return type
 * @param tree_wid       window ID for tree to insert into
 * @param tree_index     tree index to insert at
 * @param lastid_prefix  word prefix to search for 
 * @param exact_match    search for an exact match or a prefix 
 * @param case_sensitive case-sensitive identifier match?
 * 
 * @return number of items inserted
 */
/*
int _ruby_insert_constants_of_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                                 int tree_wid, int tree_index,
                                 _str lastid_prefix, boolean
                                 exact_match, boolean case_sensitive)
{
   // number of matches inserted
   int match_count=0;

   // insert NULL, if it isn't #defined, screw them
   int k=0;
   if (rt_expected.pointer_count>0) {
      if (!(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"NULL","const","",0,"",0,"");
         match_count++;
      }
      // maybe insert 'this'
      if (rt_expected.pointer_count==1) {
         _str this_class_name = _MatchThisOrSelf();
         if (this_class_name!='') {
            typeless tag_files=tags_filenamea();
            if (this_class_name == rt_expected.return_type ||
                tag_is_parent_class(rt_expected.return_type,this_class_name,tag_files,true,true)) {
               k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"this","const","",0,"",0,"");
               match_count++;
            }
         }
      }
      // insert constant string
      if (rt_expected.pointer_count==1 && rt_expected.return_type=='char') {
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"\"\"","const","",0,"",0,"");
         match_count++;
      }
      // that's all
      return 0;
   }

   // insert character constant
   if (rt_expected.pointer_count==0 && rt_expected.return_type=='char') {
      k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"'\\0'","const","",0,"",0,"");
      match_count++;
   }

   // Insert boolean
   if (rt_expected.return_type=='bool') {
      k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"true","const","",0,"",0,"");
      match_count++;
      k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"false","const","",0,"",0,"");
      match_count++;
   }


   // Insert sizeof function
   if (rt_expected.return_type=='int' || rt_expected.return_type=='unsigned int') {
      k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"sizeof()","const","",0,"",0,"");
      match_count++;
   }

   // that's all folks
   return(match_count);
}
*/

/**
 * <B>Hook function</B> -- _ext_match_return_type
 * <P>
 * This is the default function for matching return types.
 * It simply compares types for an exact match and inserts the
 * candidate tag if they match.
 * <P>
 * The extension specific hook function _[ext]_match_return_type()
 * is normally used to perform type matching, and account for
 * language specific features, such as pointer dereferencing,
 * class construction, function call, array access, etc.
 *
 * @param rt_expected    expected return type for this context
 * @param rt_candidate   candidate return type
 * @param tag_name       candidate tag name
 * @param type_name      candidate tag type
 * @param tag_flags      candidate tag flags
 * @param file_name      candidate tag file location
 * @param line_no        candidate tag line number
 * @param prefixexp      prefix to prepend to tag name when inserting ('')
 * @param tag_files      tag files to search (not used)
 * @param tree_wid       tree to insert directly into (gListHelp_tree_wid)
 * @param tree_index     index of tree to insert items at (TREE_ROOT_INDEX)
 * 
 * @return number of items inserted into the tree
 */
/*
int _ruby_match_return_type(struct VS_TAG_RETURN_TYPE &rt_expected,
                            struct VS_TAG_RETURN_TYPE &rt_candidate,
                            _str tag_name,_str type_name, int tag_flags,
                            _str file_name, int line_no,
                            _str prefixexp,typeless tag_files,
                            int tree_wid, int tree_index)
{
   //say("_ruby_match_return_type: expected="rt_expected.return_type" pointers="rt_expected.pointer_count);
   //say("_ruby_match_return_type: candidate="rt_candidate.return_type" pointers="rt_candidate.pointer_count);

   // number of matches found
   _str array_operator="[]";
   boolean dereference_compatible=true;
   boolean reference_compatible=false;
   boolean insert_tags=false;
   int match_count=0;

   // is this a builtin type?
   boolean expected_is_builtin =_ruby_is_builtin_type(rt_expected.return_type);
   boolean candidate_is_builtin=_ruby_is_builtin_type(rt_candidate.return_type);

   // check the return flags for assignment compatibility
   if (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) {
      dereference_compatible=false;
   }

   // decompose the match tag in order to determine the tag type
   _str expected_tag_type='';
   _str expected_tag_name='';
   _str expected_class='';
   int expected_flags=0;
   int expected_tag_flags=0;
   if (rt_expected.taginfo!='') {
      tag_tree_decompose_tag(rt_expected.taginfo,expected_tag_name,
                             expected_class,expected_tag_type,expected_tag_flags);
   }
   _str candidate_tag_type='';
   _str candidate_tag_name='';
   _str candidate_class='';
   int candidate_flags=0;
   int candidate_tag_flags=0;
   if (rt_candidate.taginfo!='') {
      tag_tree_decompose_tag(rt_candidate.taginfo,candidate_tag_name,
                             candidate_class,candidate_tag_type,candidate_tag_flags);
   }

   // check if both are builtin types and if they are assignment compatible
   if (expected_is_builtin && candidate_is_builtin) {
      if (rt_candidate.return_type:==rt_expected.return_type) {
         insert_tags=true;
         reference_compatible=true;
      } else if (rt_expected.pointer_count==0 &&
                 _ruby_builtin_assignment_compatible(rt_expected.return_type,
                                                    rt_candidate.return_type,
                                                    rt_candidate.pointer_count>0)
                ) {
         insert_tags=true;
         reference_compatible=true;
      } else {
         return(0);
      }
   }

   // check if expected type is enumerated type
   if (!expected_is_builtin && expected_tag_type=='enumc' && candidate_is_builtin) {
      if (candidate_is_builtin && rt_candidate.pointer_count==0 &&
          _ruby_builtin_assignment_compatible("enum",
                                             rt_candidate.return_type,
                                             rt_candidate.pointer_count>0)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         return(0);
      }
   }

   // check if candidate type is enumerated type
   if (!candidate_is_builtin && candidate_tag_type=='enumc' && expected_is_builtin) {
      if (expected_is_builtin && rt_expected.pointer_count==0 &&
          _ruby_builtin_assignment_compatible(rt_expected.return_type,"enum",false)
         ) {
         insert_tags=true;
         reference_compatible=false;
      } else {
         return(0);
      }
   }

   // list any pointer if assigning to a void * parameter
   if (rt_candidate.pointer_count >= 1 &&
       rt_expected.pointer_count==1 && rt_expected.return_type=='void') {
      insert_tags=true;
   }

   // check if both are not builtin and match in type heirarchy
   if (!expected_is_builtin && !candidate_is_builtin) {
      if (rt_candidate.return_type:==rt_expected.return_type) {
         insert_tags=true;
         reference_compatible=true;
      } else if (tag_is_parent_class(rt_expected.return_type,rt_candidate.return_type,tag_files,true,true)) {
         insert_tags=true;
      } else {
         // more to do here, check for type conversion operator
         return(0);
      }
   }

   // if one is a builtin, but the other isn't, give up
   if (!insert_tags && expected_is_builtin != candidate_is_builtin) {
      return(0);
   }

   // Can only dereference variables
   if (type_name!='var' && type_name!='gvar' && type_name!='param' && type_name!='lvar') {
      dereference_compatible=false;
      reference_compatible=false;
      array_operator='';
      // technically, references are OK here, but it's uncommon to do that
   }

   // type must match exactly
   // return flags must match exactly
   if (tag_return_type_equal(rt_expected,rt_candidate,p_LangCaseSensitive)) {
      insert_tags=true;
   }

   // OK, the types seem to match, 
   // compute pointer_prefix and pointer_postfix operators to
   // handle pointer indirection mismatches
   if (insert_tags) {
      if (prefixexp!='') {
         dereference_compatible=false;
         reference_compatible=false;
      }
      int k=0;
      switch (rt_expected.pointer_count-rt_candidate.pointer_count) {
      case -2:
         if (dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"**":+tag_name,type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*"tag_name:+"[]",type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
         }
         break;
      case -1:
         if (dereference_compatible) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"*":+tag_name,type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
         }
         if (array_operator!='') {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,tag_name:+array_operator,type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
         }
         break;
      case 0:
         k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,tag_name,type_name,file_name,line_no,"",tag_flags,"");
         if (tree_wid) {
            tree_wid._TreeSetUserInfo(k,file_name":"line_no);
         }
         match_count++;
         if (rt_candidate.pointer_count==1 && reference_compatible && array_operator!='' &&
             (rt_candidate.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES) &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,'&':+tag_name:+array_operator,type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
         }
         break;
      case 1:
         if (reference_compatible &&
             !(rt_expected.return_flags & VSCODEHELP_RETURN_TYPE_ARRAY_TYPES)) {
            k=tag_tree_insert_tag(tree_wid,tree_index,0,-1,TREE_ADD_AS_CHILD,"&":+tag_name,type_name,file_name,line_no,"",tag_flags,"");
            if (tree_wid) {
               tree_wid._TreeSetUserInfo(k,file_name":"line_no);
            }
            match_count++;
         }
         break;
      }
   }

   // that's all folks
   return(match_count);
}
*/

/**
 * <B>Hook function</B> -- _ext_MaybeBuildTagFile
 * <P>
 * Build a tag file for 'ruby' if there isn't one already.
 * 
 * @param tfindex        Set to the index of the extension specific tag file
 *
 * @return 0 on success, nonzero on error
 */
int _ruby_MaybeBuildTagFile(int &tfindex)
{
   // maybe we can recycle tag file(s)
   _str ext='ruby';
   _str tagfilename='';
   if (ext_MaybeRecycleTagFile(tfindex,tagfilename,ext,ext)) {
      return(0);
   }
   
   int status=0;
   _str ruby_dir='';
#if !__UNIX__
   status = _ntRegFindValue(HKEY_LOCAL_MACHINE,
                            "SOFTWARE\\RubyInstaller",
                            "Path", ruby_dir);
   if (status) ruby_dir='';
#endif
   if (ruby_dir=='') {
      // example only, there is not 'rubycc'
      ruby_dir=path_search("rubycc","","P");
      if (ruby_dir!='') {
         ruby_dir=_strip_filename(ruby_dir,"n");
      }
   }
#if __UNIX__
   if (ruby_dir=='' || ruby_dir=='/' || ruby_dir=='/usr/') {
      ruby_dir=latest_version_path('/usr/lib/ruby');
      if (ruby_dir=='') {
         ruby_dir=latest_version_path('/opt/ruby');
      }
   }
#endif

   _str std_libs="";
   if (ruby_dir!="") {
      source_path := ruby_dir;
      _maybe_append_filesep(source_path);
      source_path=source_path:+"lib":+FILESEP;
      std_libs=maybe_quote_filename(source_path:+"*.rb");
   }

   return ext_BuildTagFile(tfindex,tagfilename,ext,"Ruby Libraries",
                           true,std_libs,ext_builtins_path(ext,'ruby'));
}

defeventtab _ruby_extform;


#region Options Dialog Helper Functions

void _ruby_extform_init_for_options(_str langID)
{
   _set_language_form_lang_id(langID);

   // set the brace style options
   be_style := LanguageSettings.getBeginEndStyle(langID);
   if (be_style == BES_BEGIN_END_STYLE_3) {
      _style1.p_value = 1;
   } else {
      _style0.p_value = 1;
   }

   // line insert option?
   ruby_options := LanguageSettings.getRubyStyle(langID);
   if (ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG) {
      _insert_blank_line.p_value = 1;
      _modifiers.p_value = 0;
   } else if(ruby_options == VS_RUBY_OPTIONS_MODIFIER_FLAG) {
      _insert_blank_line.p_value = 0;
      _modifiers.p_value = 1;
   } else if (ruby_options == VS_RUBY_OPTIONS_INSERT_LINE_FLAG+VS_RUBY_OPTIONS_MODIFIER_FLAG) {
      _insert_blank_line.p_value = 1;
      _modifiers.p_value = 1;
   } else {
      _insert_blank_line.p_value = 0;
      _modifiers.p_value = 0;
   }

   // use this to set the common form values
   _language_form_init_for_options(langID, _language_formatting_form_get_value, _language_formatting_form_is_lang_included);

   // some of the formatting forms have links to Adaptive Formatting
   // info - this will set them if they are present
   setAdaptiveLinks(langID);
}

boolean _ruby_extform_apply()
{
   langID := _get_language_form_lang_id();

   // brace style
   be_style := 0;
   if (_style1.p_value == 1) {
      be_style = BES_BEGIN_END_STYLE_3;
   } else {
      be_style = BES_BEGIN_END_STYLE_2;
   }
   _update_buffers(langID, BEGIN_END_STYLE_UPDATE_KEY'='be_style);
   LanguageSettings.setBeginEndStyle(langID, be_style);

   ruby_options := 0;
   if (_modifiers.p_value == 1 && _insert_blank_line.p_value == 1) {
      ruby_options = VS_RUBY_OPTIONS_INSERT_LINE_FLAG+VS_RUBY_OPTIONS_MODIFIER_FLAG;
   } else if (_modifiers.p_value == 1 && _insert_blank_line.p_value == 0) {
      ruby_options = VS_RUBY_OPTIONS_MODIFIER_FLAG;
   } else if (_modifiers.p_value == 0 && _insert_blank_line.p_value == 1) {
      ruby_options = VS_RUBY_OPTIONS_INSERT_LINE_FLAG;
   } else {
      ruby_options = 0;
   }
   LanguageSettings.setRubyStyle(langID, ruby_options);

   _language_form_apply(_language_formatting_form_apply_control);

   return true;
}

#endregion Options Dialog Helper Functions

int ruby_indent_col(int non_blank_col, boolean paste_open_block = false)
{
   if (p_SyntaxIndent < 0 || p_indent_style!=INDENT_SMART) {
      return non_blank_col;
   }

   _str line = '';
   _str first_word = '';
   _str second_word = '';

   // Get the name of the command that the Enter key is bound to 
   _str enter_cmd=name_on_key(ENTER);
   if (enter_cmd=='nosplit-insert-line') {
      // If the key is bound to "nosplit-insert-line"
      // Go to the end of the line to insure proper behavior
      _end_line();
   }
   get_line(line);

   if (line == '') {
      return(1);
   }

   parse line with first_word second_word .;

   _str lower_first_word=lowcase(first_word);
   _str lower_second_word=lowcase(second_word);

   if ((pos(' 'lower_first_word' ',RUBY_ENTER_WORDS) || pos(' 'lower_second_word' ', RUBY_ENTER_WORDS)) 
       && (p_col >= _rawLength(line))) {

      updateAdaptiveFormattingSettings(AFF_SYNTAX_INDENT);
      return non_blank_col + p_SyntaxIndent;
   } 
   return non_blank_col;
}

