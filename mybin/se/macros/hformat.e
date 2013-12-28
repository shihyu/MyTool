////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47587 $
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
#import "annotations.e"
#import "bookmark.e"
#import "cformat.e"
#import "cutil.e"
#import "debug.e"
#import "files.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "picture.e"
#import "saveload.e"
#import "seldisp.e"
#import "setupext.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "xml.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

#define HFDEBUG_WINDOW   0
#define HFDEBUG_FILE     0

#define HFDEBUGFLAG_WINDOW 0x1000
#define HFDEBUGFLAG_FILE   0x2000

#define HF_NONE_SCHEME_NAME "(None)"
#define HF_DEFAULT_TAG_NAME "<DEFAULT TAG>"

#define BROKENTAG_STYLE_INDENT   (1)
#define BROKENTAG_STYLE_REL      (2)
#define BROKENTAG_STYLE_PRESERVE (3)

#define TCOMMENT_COLUMN   (1)
#define TCOMMENT_RELATIVE (2)
#define TCOMMENT_ABSOLUTE (3)

#define HFMAX_MLCOMMENTS (2)

#define HFPRESERVE (-1)
#define HFOFF      (0)
#define HFON       (1)

#define DEF_INDENT (2)

struct htmScheme_t {
   typeless style:[];
   typeless tags:[];
#define HFCOMMENT_MULTILINE (0)
#define HFCOMMENT_LINE      (1)
   typeless comments[];
};

static void _InitTag(_str tagname,typeless (&tags):[],_str lang)
{
   boolean reformat_content=true;
   boolean indent_content=false;
   boolean literal_content=false;
   boolean preserve_body=false;
   boolean preserve_position=false;
   boolean standalone=true;
   boolean endtag=true;
   boolean endtag_required=true;
   int noflines_before=1;
   int noflines_after=1;

   if( _LanguageInheritsFrom('xml',lang) ) {
      reformat_content=false;
      indent_content=true;
      literal_content=false;
      preserve_body=false;
      preserve_position=false;
      standalone=false;
      noflines_before=1;
      noflines_after=1;
      endtag=true;
      endtag_required=true;
   }

   // no_settings is used to indicate whether there were settings for the tagname
   // passed in.
   boolean no_settings=false;
   switch( tagname ) {
   case '%':
      preserve_body=true;
      preserve_position=true;
      //standalone=false;
      //noflines_before=0;
      //noflines_after=0;
      endtag=false;
      endtag_required=false;
      break;
   case '%!':
      preserve_body=true;
      preserve_position=true;
      //standalone=false;
      //noflines_before=0;
      //noflines_after=0;
      endtag=false;
      endtag_required=false;
      break;
   case '%=':
      preserve_body=true;
      preserve_position=true;
      //standalone=false;
      //noflines_before=0;
      //noflines_after=0;
      endtag=false;
      endtag_required=false;
      break;
   case '%@':
      preserve_body=true;
      preserve_position=true;
      //standalone=false;
      //noflines_before=0;
      //noflines_after=0;
      endtag=false;
      endtag_required=false;
      break;
   case '?':
      preserve_body=true;
      if( _LanguageInheritsFrom('xml',lang) ) {
         preserve_position=false;
         indent_content=false;
      } else {
         preserve_position=true;
      }
      //standalone=false;
      //noflines_before=0;
      //noflines_after=0;
      endtag=false;
      endtag_required=false;
      break;
   case '!DOCTYPE':
      indent_content=false;
      endtag=false;
      endtag_required=false;
      preserve_body=true;
   case '![CDATA[':
      indent_content=false;
      endtag=false;
      endtag_required=false;
      preserve_body=true;
   case 'A':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'ABBREV':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'ACRONYM':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'ADDRESS':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'APP':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'APPLET':
      indent_content=true;
      break;
   case 'AREA':
      endtag=false;
      endtag_required=false;
      break;
   case 'AU':
      break;
   case 'B':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'BANNER':
      indent_content=true;
      break;
   case 'BASE':
      indent_content=true;
      break;
   case 'BASEFONT':
      indent_content=true;
      endtag_required=false;
      break;
   case 'BDO':
      break;
   case 'BGSOUND':
      break;
   case 'BIG':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'BLINK':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'BLOCKQUOTE':
      indent_content=true;
      break;
   case 'BODY':
      break;
   case 'BQ':
      break;
   case 'BR':
      standalone=false;
      noflines_before=0;
      noflines_after=1;
      endtag=false;
      endtag_required=false;
      break;
   case 'BUTTON':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'CAPTION':
      indent_content=true;
      break;
   case 'CENTER':
      indent_content=true;
      break;
   case 'CITE':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'CODE':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'COL':
      break;
   case 'COLGROUP':
      break;
   case 'CREDIT':
      break;
   case 'DD':
      standalone=false;
      noflines_before=1;
      noflines_after=1;
      endtag_required=false;
      break;
   case 'DEL':
      break;
   case 'DFN':
      break;
   case 'DIR':
      indent_content=true;
      break;
   case 'DIV':
      indent_content=true;
      break;
   case 'DL':
      indent_content=true;
      break;
   case 'DT':
      standalone=false;
      noflines_before=1;
      noflines_after=1;
      endtag_required=false;
      break;
   case 'EM':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'EMBED':
      indent_content=true;
      break;
   case 'FIG':
      break;
   case 'FN':
      break;
   case 'FONT':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'FORM':
      indent_content=true;
      break;
   case 'FRAME':
      endtag=false;
      endtag_required=false;
      break;
   case 'FRAMESET':
      indent_content=true;
      break;
   case 'H1':
   case 'H2':
   case 'H3':
   case 'H4':
   case 'H5':
   case 'H6':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'HEAD':
      indent_content=true;
      break;
   case 'HP':
      break;
   case 'HR':
      endtag=false;
      break;
   case 'HTML':
      break;
   case 'I':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'IMG':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      endtag=false;
      break;
   case 'INPUT':
      endtag=false;
      break;
   case 'INS':
      break;
   case 'ISINDEX':
      endtag_required=false;
      break;
   case 'JAVA':
      literal_content=true;
      break;
   case 'JSP:FORWARD':
      endtag_required=false;
      break;
   case 'JSP:GETPROPERTY':
      endtag=false;
      endtag_required=false;
      break;
   case 'JSP:INCLUDE':
      endtag_required=false;
      break;
   case 'JSP:PLUGIN':
      endtag_required=false;
      break;
   case 'JSP:PARAMS':
      endtag_required=false;
      break;
   case 'JSP:FALLBACK':
      break;
   case 'JSP:SETPROPERTY':
      endtag=false;
      endtag_required=false;
      break;
   case 'JSP:USEBEAN':
      endtag_required=false;
      break;
   case 'KBD':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'KEYGEN':
      endtag=false;
      break;
   case 'LANG':
      break;
   case 'LAYER':
      indent_content=true;
      break;
   case 'LH':
      break;
   case 'LI':
      indent_content=true;
      endtag_required=false;
      break;
   case 'LINK':
      break;
   case 'LISTING':
      break;
   case 'MAP':
      indent_content=true;
      break;
   case 'MARQUEE':
      break;
   case 'MENU':
      indent_content=true;
      break;
   case 'META':
      endtag=false;
      break;
   case 'MULTICOL':
      indent_content=true;
      break;
   case 'NEXTID':
      break;
   case 'NOBR':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'NOEMBED':
      indent_content=true;
      break;
   case 'NOFRAMES':
      indent_content=true;
      break;
   case 'NOLAYER':
      indent_content=true;
      break;
   case 'NOSCRIPT':
      indent_content=true;
      break;
   case 'NOTE':
      break;
   case 'OBJECT':
      //standalone=true;
      endtag_required=false;
      break;
   case 'OL':
      indent_content=true;
      break;
   case 'OPTION':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      endtag_required=false;
      break;
   case 'OVERLAY':
      break;
   case 'P':
      endtag_required=false;
      break;
   case 'PARAM':
      endtag=false;
      break;
   case 'PERSON':
      break;
   case 'PLAINTEXT':
      reformat_content=false;
      literal_content=true;
      endtag=false;
      break;
   case 'PRE':
      reformat_content=false;
      standalone=false;
      break;
   case 'Q':
      break;
   case 'S':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'SAMP':
      break;
   case 'SCRIPT':
      reformat_content=true;
      literal_content=true;
      break;
   case 'SELECT':
      indent_content=true;
      break;
   case 'SERVER':
      reformat_content=true;
      literal_content=true;
      break;
   case 'SERVLET':
      break;
   case 'SMALL':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'SPACER':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      endtag=false;
      break;
   case 'SPAN':
      break;
   case 'STRIKE':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'STRONG':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'STYLE':
      reformat_content=true;
      literal_content=true;
      break;
   case 'SUB':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'SUP':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'TAB':
      break;
   case 'TABLE':
      indent_content=true;
      break;
   case 'TBODY':
      break;
   case 'TD':
      /* <TD> is "blanks-sensitive", so we never force a linebreak
       * after the open tag or before the close tag.
       */
      standalone=false;
      noflines_before=1;
      noflines_after=1;
      indent_content=true;
      endtag_required=false;
      break;
   case 'TEXTAREA':
      literal_content=true;
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'TFOOT':
      break;
   case 'TH':
      /* <TH> is "blanks-sensitive", so we never force a linebreak
       * after the open tag or before the close tag.
       */
      standalone=false;
      noflines_before=1;
      noflines_after=1;
      indent_content=true;
      endtag_required=false;
      break;
   case 'THEAD':
      break;
   case 'TITLE':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'TR':
      indent_content=true;
      endtag_required=false;
      break;
   case 'TT':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'U':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'UL':
      indent_content=true;
      break;
   case 'VAR':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      break;
   case 'WBR':
      standalone=false;
      noflines_before=0;
      noflines_after=0;
      endtag=false;
      break;
   case 'XMP':
      reformat_content=false;
      literal_content=true;
      break;
   default:
      no_settings=true;
   }
   boolean eo_insert_endtag = endtag && endtag_required;
   if( no_settings && !tags._indexin(tagname) && tags._indexin(HF_DEFAULT_TAG_NAME) ) {
      // Use the default tag settings
      reformat_content=  tags:[HF_DEFAULT_TAG_NAME]:["reformat_content"];
      indent_content=    tags:[HF_DEFAULT_TAG_NAME]:["indent_content"];
      literal_content=   tags:[HF_DEFAULT_TAG_NAME]:["literal_content"];
      preserve_body=     tags:[HF_DEFAULT_TAG_NAME]:["preserve_body"];
      preserve_position= tags:[HF_DEFAULT_TAG_NAME]:["preserve_position"];
      standalone=        tags:[HF_DEFAULT_TAG_NAME]:["standalone"];
      noflines_before=   tags:[HF_DEFAULT_TAG_NAME]:["noflines_before"];
      noflines_after=    tags:[HF_DEFAULT_TAG_NAME]:["noflines_after"];
      endtag=            tags:[HF_DEFAULT_TAG_NAME]:["endtag"];
      endtag_required=   tags:[HF_DEFAULT_TAG_NAME]:["endtag_required"];
   }
   tags:[tagname]:["reformat_content"]=  reformat_content;
   tags:[tagname]:["indent_content"]=    indent_content;
   tags:[tagname]:["literal_content"]=   literal_content;
   tags:[tagname]:["preserve_body"]=     preserve_body;
   tags:[tagname]:["preserve_position"]= preserve_position;
   tags:[tagname]:["standalone"]=        standalone;
   tags:[tagname]:["noflines_before"]=   noflines_before;
   tags:[tagname]:["noflines_after"]=    noflines_after;
   tags:[tagname]:["endtag"]=            endtag;
   tags:[tagname]:["endtag_required"]=   endtag_required;
   tags:[tagname]:["eo_insert_endtag"]=  eo_insert_endtag;

   return;
}

static _str taglist[]= {
   '%','%!','%=','%@','?','A','ABBREV','ACRONYM','ADDRESS','APP','APPLET','AREA','AU',
   'B','BANNER','BASE','BASEFONT','BDO','BGSOUND','BIG','BLINK','BLOCKQUOTE',
   'BODY','BQ','BR','BUTTON','CAPTION','CENTER','CITE','CODE','COL',
   'COLGROUP','CREDIT','DD','DEL','DFN','DIR','DIV','DL','DT','EM','EMBED',
   'FIG','FN','FONT','FORM','FRAME','FRAMESET','H1','H2','H3','H4','H5','H6',
   'HEAD','HP','HR','HTML','I','IMG','INPUT','INS','ISINDEX','JAVA',
   'JSP:FORWARD','JSP:GETPROPERTY','JSP:INCLUDE','JSP:PLUGIN','JSP:PARAMS',
   'JSP:FALLBACK','JSP:SETPROPERTY','JSP:USEBEAN','KBD',
   'KEYGEN','LANG','LAYER','LH','LI','LINK','LISTING','MAP','MARQUEE','MENU',
   'META','MULTICOL','NEXTID','NOBR','NOEMBED','NOFRAMES','NOLAYER','NOSCRIPT',
   'NOTE','OBJECT','OL','OPTION','OVERLAY','P','PARAM','PERSON','PLAINTEXT',
   'PRE','Q','S','SAMP','SCRIPT','SELECT','SERVER','SERVLET','SMALL','SPACER',
   'SPAN','STRIKE','STRONG','STYLE','SUB','SUP','TAB','TABLE','TBODY','TD',
   'TEXTAREA','TFOOT','TH','THEAD','TITLE','TR','TT','U','UL','VAR','WBR','XMP'
};
static _str xml_taglist[]= {
   '!DOCTYPE','?','![CDATA['
};
static void _InitAllTags(typeless (&tags):[],_str lang)
{
   _str *ptaglist[];

   // Special tag settings for "Default Tag" element that specifies tag
   // settings for tags not in list or unknown.
   _InitTag(HF_DEFAULT_TAG_NAME,tags,lang);

   int i=0;
   if( _LanguageInheritsFrom('xml',lang) ) {
      for( i=0;i<xml_taglist._length();++i ) {
         _InitTag(xml_taglist[i],tags,lang);
      }
   } else {
      for( i=0;i<taglist._length();++i ) {
         _InitTag(taglist[i],tags,lang);
      }
   }

   return;
}

static void _InitStyle(typeless (&style):[],_str lang)
{
   if( _LanguageInheritsFrom('xml',lang) ) {
      style:["indent_amount"]=DEF_INDENT;
      style:["indent_with_tabs"]=false;
      style:["tabsize"]=4;
      style:["orig_tabsize"]=4;
      style:["max_line_length"]=0;
      style:["brokentag_style"]=BROKENTAG_STYLE_REL;
      style:["brokentag_indent"]=0;
      style:["tagcase"]=WORDCASE_PRESERVE;
      style:["attribcase"]=WORDCASE_PRESERVE;
      style:["indent_comments"]=true;
      style:["indent_col1_comments"]=true;
      style:["tcomment"]=TCOMMENT_RELATIVE;
      style:["tcomment_col"]=0;
      style:["eat_blank_lines"]=false;
      style:["quote_all_vals"]=false;
      // Not used by XML
      style:["wordvalcase"]=WORDCASE_PRESERVE;
      style:["hexvalcase"]=WORDCASE_PRESERVE;
      style:["quote_numval"]=HFPRESERVE;
      style:["quote_wordval"]=HFPRESERVE;
      style:["popp_on_p"]=false;
      style:["popp_on_standalone"]=false;
      style:["beautify_javascript"]=false;
   } else {
      style:["indent_amount"]=DEF_INDENT;
      style:["indent_with_tabs"]=false;
      style:["tabsize"]=4;
      style:["orig_tabsize"]=4;
      style:["max_line_length"]=80;
      style:["brokentag_style"]=BROKENTAG_STYLE_REL;
      style:["brokentag_indent"]=0;
      style:["tagcase"]=WORDCASE_PRESERVE;
      style:["attribcase"]=WORDCASE_PRESERVE;
      style:["wordvalcase"]=WORDCASE_PRESERVE;
      style:["hexvalcase"]=WORDCASE_PRESERVE;
      style:["quote_numval"]=true;
      style:["quote_wordval"]=true;
      style:["quote_all_vals"]=false;
      style:["indent_comments"]=true;
      style:["indent_col1_comments"]=true;
      style:["tcomment"]=TCOMMENT_RELATIVE;
      style:["tcomment_col"]=0;
      style:["popp_on_p"]=true;
      style:["popp_on_standalone"]=true;
      style:["eat_blank_lines"]=false;
      style:["beautify_javascript"]=true;
   }

   return;
}

static void _InitComments(typeless (&comments)[],_str lang)
{
   comments._makeempty();
   return;
}

static int _GetScheme(htmScheme_t (&s):[],_str name,_str lang,boolean sync_lang_options)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if( FormatSystemIniFilename()=='' || _open_temp_view(FormatSystemIniFilename(),temp_view_id,orig_view_id) ) {
      return(1);
   }

   _str prefix=lang:+'-scheme-';
   _GetScheme2(s,prefix,name,sync_lang_options);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(0);
}

static int _GetUserScheme(htmScheme_t (&s):[],_str name,_str lang,boolean sync_lang_options)
{
   int temp_view_id=0;
   int orig_view_id=0;
   if( FormatUserIniFilename()=='' || _open_temp_view(FormatUserIniFilename(),temp_view_id,orig_view_id) ) {
      return(1);
   }

   _str prefix=lang:+'-scheme-';
   int status=_GetScheme2(s,prefix,name,sync_lang_options);

   // Delete the temp view
   p_window_id=orig_view_id;
   _delete_temp_view(temp_view_id);

   return(status);
}

/**
 * This function assumes we are in an ini view
 * Styles have the format: varname=val
 * Tags have the format: tag*&lt;tagname&gt;*varname=val
 * Comments have the format: mlcomment|linecomment=startstr endstr [nesting]
 */
static int _GetScheme2(htmScheme_t (&s):[],_str prefix,_str name,boolean sync_lang_options)
{
   typeless comment:[];

   _str ss="";
   if( name!="" ) {
      ss=prefix:+name;
   }

   parse prefix with auto lang '-' .;

   _str line="";
   _str tagname="";
   _str varname="";
   _str val="";
   _str section_name="";
   _str scheme_name="";
   _str msg="";
   _str startstr="";
   _str endstr="";
   _str rest="";
   _str nesting="";
   int sl=0, el=0;
   int nofmlcomments=0;

   top();
   boolean found_one=false;
   do {
      if( _ini_find_section(ss) ) {
         break;
      }
      get_line(line);
      parse line with '[' section_name ']';
      parse section_name with (prefix) scheme_name;
      if( scheme_name=="" ) {
         // Not a valid scheme
         if( down() ) break;   // Bottom of file, so done!
         continue;
      }
      found_one=true;
      down();   // Move off the section line
      sl=p_line;
      // Now find the next section so we can bracket this section
      if( _ini_find_section('') ) {
         bottom();
      } else {
         up();   // Move off the the next section name
      }
      el=p_line;

      // Get the values
      // Load default values for style
      _InitStyle(s:[scheme_name].style,lang);
      // Load default values for all known tags
      _InitAllTags(s:[scheme_name].tags,lang);
      _InitComments(s:[scheme_name].comments,lang);
      nofmlcomments=0;
      p_line=sl;
      while( p_line<=el ) {
         get_line(line);
         line=strip(line,'L');
         if( line=="" || substr(line,1,1)==';' ) {
            // Blank line OR comment line
            if( down() ) break;  // Done!
            continue;
         }
         parse line with line ';' .;   // Get rid of a trailing comment (not sure if we need this)
         parse line with varname '=' val;
         if( val=="" ) {
            if( down() ) break;   // Done!
            continue;   // Not a valid value
         }
         if( substr(lowcase(varname),1,4)=="tag*" ) {
            parse varname with 'tag*','i' tagname '*' varname;
            if( tagname=='' || varname=='' ) {
               if( down() ) break;   // Done!
               continue;
            }

            if( !_LanguageInheritsFrom('xml',lang) ) {
               // HTML:
               // Always save upper-case tagname for consistency.
               tagname=upcase(tagname);
            }

            if( !s:[scheme_name].tags._indexin(tagname) ) {
               // Unknown tag, so load with default values
               _InitTag(tagname,s:[scheme_name].tags,lang);
            }
            s:[scheme_name].tags:[tagname]:[varname]=val;
         } else if( varname=="mlcomment" || varname=="linecomment" ) {
            if( varname=="mlcomment" ) {
               if( nofmlcomments>=HFMAX_MLCOMMENTS ) {
                  // Doing the check this way guarantees that the user gets the warning only once
                  if( nofmlcomments==HFMAX_MLCOMMENTS ) {
                     ++nofmlcomments;
                     msg="Too many MultiLine comments\n\n":+
                         'Use the "Define Comments" button to remove some';
                     _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
                  }
                  if( down() ) break;   // Done!
                  continue;
               }
               parse val with startstr endstr rest;
               if( endstr=="" ) {
                  if( down() ) break;   // Done!
                  continue;
               }
               nesting= (lowcase(strip(rest))=="nesting");
               comment:["startstr"]=startstr;
               comment:["endstr"]=endstr;
               comment:["type"]=HFCOMMENT_MULTILINE;
               comment:["nesting"]=nesting;
               ++nofmlcomments;
            } else {
               parse val with startstr .;
               comment:["startstr"]=startstr;
               comment:["endstr"]="";
               comment:["type"]=HFCOMMENT_LINE;
               comment:["nesting"]=false;
            }
            s:[scheme_name].comments[s:[scheme_name].comments._length()]=comment;
         } else {
            s:[scheme_name].style:[varname]=val;
         }
         if( down() ) break;   // Done!
      }
   } while( name=="" );

   if( name=="" ) return( found_one?0:1 );   // Done

   typeless syntax_indent=0;
   typeless tagcase=0;
   typeless attribcase=0;
   typeless wordvalcase=0;
   typeless quote_numval=0;
   typeless quote_wordval=0;
   typeless hexvalcase=0;
   scheme_name=name;
   if( sync_lang_options ) {
      syntax_indent = LanguageSettings.getSyntaxIndent(lang);
      if( isinteger(syntax_indent) && syntax_indent>0 ) {
         s:[scheme_name].style:["indent_amount"]=syntax_indent;
      }
      // HTML:
      // If tagcase/attribcase/wordvalcase/hexvalcase is set to WORDCASE_PRESERVE
      // then we do not want to sync the options because the user would
      // never be able to keep the setting.
      tagcase = LanguageSettings.getTagCase(lang);
      if( isinteger(tagcase) && tagcase>=WORDCASE_PRESERVE && tagcase<=WORDCASE_CAPITALIZE ) {
         if( _LanguageInheritsFrom('xml',lang) || s:[scheme_name].style:["tagcase"]!=WORDCASE_PRESERVE ) {
            s:[scheme_name].style:["tagcase"]=tagcase;
         }
      }
      attribcase = LanguageSettings.getAttributeCase(lang);
      if( isinteger(attribcase) && attribcase>=WORDCASE_PRESERVE && attribcase<=WORDCASE_CAPITALIZE ) {
         if( _LanguageInheritsFrom('xml',lang) || s:[scheme_name].style:["attribcase"]!=WORDCASE_PRESERVE ) {
            s:[scheme_name].style:["attribcase"]=attribcase;
         }
      }
      wordvalcase = LanguageSettings.getValueCase(lang);
      if( isinteger(wordvalcase) && wordvalcase>=WORDCASE_PRESERVE && wordvalcase<=WORDCASE_CAPITALIZE ) {
         if( _LanguageInheritsFrom('xml',lang) ) {
            // XML:
            // Not currently supported.
            s:[scheme_name].style:["wordvalcase"]=WORDCASE_PRESERVE;
         } else if( s:[scheme_name].style:["wordvalcase"]!=WORDCASE_PRESERVE ) {
            s:[scheme_name].style:["wordvalcase"]=wordvalcase;
         }
      }
      hexvalcase = LanguageSettings.getHexValueCase(lang);
      if( isinteger(hexvalcase) && hexvalcase>=WORDCASE_PRESERVE && hexvalcase<=WORDCASE_UPPER ) {
         if( _LanguageInheritsFrom('xml',lang) ) {
            // XML:
            // Not currently supported.
            s:[scheme_name].style:["hexvalcase"]=WORDCASE_PRESERVE;
         } else if( s:[scheme_name].style:["hexvalcase"]!=WORDCASE_PRESERVE ) {
            s:[scheme_name].style:["hexvalcase"]=hexvalcase;
         }
      }
      // HTML:
      // If quote_wordval/quote_numval is set to HFPRESERVE
      // then we do not want to sync the options because the user would
      // never be able to keep the setting.
      quote_wordval = LanguageSettings.getQuotesForSingleWordValues(lang);
      if( isinteger(quote_wordval) && quote_wordval>=HFPRESERVE && quote_wordval<=HFON ) {
         if( _LanguageInheritsFrom('xml',lang) ) {
            // XML:
            // Not currently supported.
            s:[scheme_name].style:["quote_wordval"]= HFPRESERVE;
         } else {
            if( s:[scheme_name].style:["quote_wordval"]!=HFPRESERVE ) {
               s:[scheme_name].style:["quote_wordval"]= quote_wordval;
            }
         }
      }
      quote_numval = LanguageSettings.getQuotesForNumericValues(lang);
      if( isinteger(quote_numval) && quote_numval>=HFPRESERVE && quote_numval<=HFON ) {
         if( _LanguageInheritsFrom('xml',lang) ) {
            // XML:
            // Not currently supported.
            s:[scheme_name].style:["quote_numval"]= HFPRESERVE;
         } else {
            if( s:[scheme_name].style:["quote_numval"]!=HFPRESERVE ) {
               s:[scheme_name].style:["quote_numval"]= quote_numval;
            }
         }
      }

      s:[scheme_name].style:["indent_with_tabs"]= LanguageSettings.getIndentWithTabs(lang);
   }

   // Make sure all values are legal

   // Styles
   typeless indent_amount=s:[scheme_name].style:["indent_amount"];
   if( !isinteger(indent_amount) || indent_amount<0 ) {
      s:[scheme_name].style:["indent_amount"]=DEF_INDENT;
   }
   if( !isinteger(s:[scheme_name].style:["indent_with_tabs"]) ) {
      s:[scheme_name].style:["indent_with_tabs"]=false;
   }
   typeless tabsize=s:[scheme_name].style:["tabsize"];
   if( !isinteger(tabsize) || tabsize<0 ) {
      s:[scheme_name].style:["tabsize"]=s:[scheme_name].style:["indent_amount"];
   }
   typeless orig_tabsize=s:[scheme_name].style:["orig_tabsize"];
   if( !isinteger(orig_tabsize) || orig_tabsize<0 ) {
      s:[scheme_name].style:["orig_tabsize"]=s:[scheme_name].style:["indent_amount"];
   }
   typeless max_line_length=s:[scheme_name].style:["max_line_length"];
   if( !isinteger(max_line_length) || max_line_length<0 ) {
      s:[scheme_name].style:["max_line_length"]=0;
   }
   typeless brokentag_style=s:[scheme_name].style:["brokentag_style"];
   if( !isinteger(brokentag_style) || brokentag_style<BROKENTAG_STYLE_INDENT || brokentag_style>BROKENTAG_STYLE_PRESERVE ) {
      s:[scheme_name].style:["brokentag_style"]=BROKENTAG_STYLE_REL;
   }
   typeless brokentag_indent=s:[scheme_name].style:["brokentag_indent"];
   if( !isinteger(brokentag_indent) || brokentag_indent<0 ) {
      brokentag_indent=0;
   }
   typeless tcomment=s:[scheme_name].style:["tcomment"];
   if( !isinteger(tcomment) || tcomment<TCOMMENT_COLUMN || tcomment>TCOMMENT_ABSOLUTE ) {
      s:[scheme_name].style:["tcomment"]=TCOMMENT_RELATIVE;
   }
   typeless tcomment_col=s:[scheme_name].style:["tcomment_col"];
   if( !isinteger(tcomment_col) || tcomment_col<1 ) {
      tcomment_col=0;
      if( tcomment==TCOMMENT_COLUMN ) {
         // An invalid comment column invalidates this setting
         tcomment=TCOMMENT_RELATIVE;
      }
   }
   tagcase=s:[scheme_name].style:["tagcase"];
   if( !isinteger(tagcase) || tagcase<WORDCASE_PRESERVE || tagcase>WORDCASE_CAPITALIZE ) {
      s:[scheme_name].style:["tagcase"]=WORDCASE_PRESERVE;
   }
   attribcase=s:[scheme_name].style:["attribcase"];
   if( !isinteger(attribcase) || attribcase<WORDCASE_PRESERVE || attribcase>WORDCASE_CAPITALIZE ) {
      s:[scheme_name].style:["attribcase"]=WORDCASE_PRESERVE;
   }
   wordvalcase=s:[scheme_name].style:["wordvalcase"];
   if( !isinteger(wordvalcase) || wordvalcase<WORDCASE_PRESERVE || wordvalcase>WORDCASE_CAPITALIZE ) {
      s:[scheme_name].style:["wordvalcase"]=WORDCASE_PRESERVE;
   }
   hexvalcase=s:[scheme_name].style:["hexvalcase"];
   if( !isinteger(hexvalcase) || hexvalcase<WORDCASE_PRESERVE || hexvalcase>WORDCASE_UPPER ) {
      s:[scheme_name].style:["hexvalcase"]=WORDCASE_PRESERVE;
   }
   quote_numval=s:[scheme_name].style:["quote_numval"];
   if( !isinteger(quote_numval) || quote_numval<HFPRESERVE || quote_numval>HFON ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["quote_numval"]=HFPRESERVE;
      } else {
         s:[scheme_name].style:["quote_numval"]=HFON;
      }
   }
   quote_wordval=s:[scheme_name].style:["quote_wordval"];
   if( !isinteger(quote_wordval) || quote_wordval<HFPRESERVE || quote_wordval>HFON ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["quote_wordval"]=HFPRESERVE;
      } else {
         s:[scheme_name].style:["quote_wordval"]=HFON;
      }
   }
   if( !isinteger(s:[scheme_name].style:["quote_all_vals"]) ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["quote_all_vals"]=false;
      } else {
         s:[scheme_name].style:["quote_all_vals"]=false;
      }
   }
   if( !isinteger(s:[scheme_name].style:["popp_on_p"]) ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["popp_on_p"]=false;
      } else {
         s:[scheme_name].style:["popp_on_p"]=true;
      }
   }
   if( !isinteger(s:[scheme_name].style:["popp_on_standalone"]) ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["popp_on_standalone"]=false;
      } else {
         s:[scheme_name].style:["popp_on_standalone"]=true;
      }
   }
   if( !isinteger(s:[scheme_name].style:["eat_blank_lines"]) ) {
      s:[scheme_name].style:["eat_blank_lines"]=false;
   }

   // JavaScript
   if( !isinteger(s:[scheme_name].style:["beautify_javascript"]) ) {
      if( _LanguageInheritsFrom('xml',lang) ) {
         s:[scheme_name].style:["beautify_javascript"]=false;
      } else {
         s:[scheme_name].style:["beautify_javascript"]=true;
      }
   }

   // Comments
   typeless type="";
   int i;
   for( i=0;i<s:[scheme_name].comments._length(); ) {
      comment=s:[scheme_name].comments[i];
      type=comment:["type"];
      nesting=comment:["nesting"]!=0;
      startstr=comment:["startstr"];
      endstr=comment:["endstr"];
      if( type==HFCOMMENT_MULTILINE ) {
         if( startstr=="" || endstr=="" ) {
            s:[scheme_name].comments._deleteel(i);
            continue;
         }
      } else if( type==HFCOMMENT_LINE ) {
         if( startstr=="" ) {
            s:[scheme_name].comments._deleteel(i);
            continue;
         }
         nesting=false;   // Just in case
      } else {
         // Invalid type
         s:[scheme_name].comments._deleteel(i);
         continue;
      }
      ++i;
   }
   if( !s:[scheme_name].comments._length() ) {
      // <!-- ... --> multiline comment
      s:[scheme_name].comments[0]:["type"]=HFCOMMENT_MULTILINE;
      s:[scheme_name].comments[0]:["startstr"]="<!--";
      s:[scheme_name].comments[0]:["endstr"]="-->";
      s:[scheme_name].comments[0]:["nesting"]=false;
   }
   if( s:[scheme_name].comments._length()<2 ) {
      if( s:[scheme_name].comments[0]:["startstr"]!="<!--" ) {
         // <!-- ... --> multiline comment
         s:[scheme_name].comments[1]:["type"]=HFCOMMENT_MULTILINE;
         s:[scheme_name].comments[1]:["startstr"]="<!--";
         s:[scheme_name].comments[1]:["endstr"]="-->";
         s:[scheme_name].comments[1]:["nesting"]=false;
      } else {
         if( !_LanguageInheritsFrom('xml',lang) ) {
            // <%-- ... --%> JSP multiline comment
            s:[scheme_name].comments[1]:["type"]=HFCOMMENT_MULTILINE;
            s:[scheme_name].comments[1]:["startstr"]="<%--";
            s:[scheme_name].comments[1]:["endstr"]="--%>";
            s:[scheme_name].comments[1]:["nesting"]=false;
         }
      }
   }

   return( found_one?0:1 );
}

static boolean _xmlOptionNotUsed(_str option)
{
   switch( option ) {
   case "wordvalcase":
   case "hexvalcase":
   case "quote_numval":
   case "quote_wordval":
   case "popp_on_p":
   case "popp_on_standalone":
   case "beautify_javascript":
      return(true);
   }

   return(false);
}

//typeless def_mytest;
static int _SaveScheme(htmScheme_t *s_p,_str section_name,boolean sync_language_options)
{
   typeless status=0;

   _str msg="";
   _str scheme_name="";
   parse section_name with auto lang '-scheme-' scheme_name;

   int idx=0;
   typeless syntax_indent=0;
   typeless o2,o6,o9,o10,o11;
   typeless tagcase=0;
   typeless attribcase=0;
   typeless wordvalcase=0;
   typeless quote_numval=0;
   typeless quote_wordval=0;
   typeless hexvalcase=0;
   _str rest="";
   _str new_options="";

   if( sync_language_options ) {
      // NOTE:
      // Currently, The XML options forms uses the same event handler as
      // the HTML options form. Therefore, the def-options-xml uses
      // the same format.
      LanguageSettings.setSyntaxIndent(lang, s_p->style:["indent_amount"]);
      updateList := SYNTAX_INDENT_UPDATE_KEY'='s_p->style:["indent_amount"]',';

      // HTML:
      // If tagcase/attribcase/wordvalcase/hexvalcase is set to WORDCASE_PRESERVE
      // then we do not want to sync the options because they would
      // make no sense to the HTML toolbar analogs.
      if( _LanguageInheritsFrom('xml',lang) || s_p->style:["tagcase"]!=WORDCASE_PRESERVE ) {
         LanguageSettings.setTagCase(lang, s_p->style:["tagcase"]);
         updateList :+= TAG_CASING_UPDATE_KEY'='s_p->style:["tagcase"]',';
      }
      if( _LanguageInheritsFrom('xml',lang) || s_p->style:["attribcase"]!=WORDCASE_PRESERVE ) {
         LanguageSettings.setAttributeCase(lang, s_p->style:["attribcase"]);
         updateList :+= ATTRIBUTE_CASING_UPDATE_KEY'='s_p->style:["attribcase"]',';
      }
      if( s_p->style:["wordvalcase"]!=WORDCASE_PRESERVE ) {
         // XML:
         // Not currently supported.
         if( _LanguageInheritsFrom('xml',lang) ) {
            LanguageSettings.setValueCase(lang, s_p->style:["wordvalcase"]);
            updateList :+= VALUE_CASING_UPDATE_KEY'='s_p->style:["wordvalcase"]',';
         }
      }
      if( s_p->style:["hexvalcase"]!=WORDCASE_PRESERVE ) {
         // XML:
         // Not currently supported.
         if( !_LanguageInheritsFrom('xml',lang) ) {
            LanguageSettings.setHexValueCase(lang, s_p->style:["hexvalcase"]);
            updateList :+= HEX_VALUE_CASING_UPDATE_KEY'='s_p->style:["hexvalcase"]',';
         }
      }
      // XML:
      // Not currently supported.
      //
      // HTML:
      // If quote_wordval/quote_numval is set to HFPRESERVE
      // then we do not want to sync the options because they would
      // make no sense to the HTML toolbar analogs.
      if( !_LanguageInheritsFrom('xml',lang) ) {
         LanguageSettings.setQuotesForSingleWordValues(lang, s_p->style:["quote_wordval"]==HFON);
         LanguageSettings.setQuotesForNumericValues(lang, s_p->style:["quote_numval"]==HFON);
      }

      _config_modify_flags(CFGMODIFY_DEFDATA);

      LanguageSettings.setIndentWithTabs(lang, s_p->style:["indent_with_tabs"]!=0);
      updateList :+= INDENT_WITH_TABS_UPDATE_KEY'='s_p->style:["indent_with_tabs"]',';
      _update_buffers(lang,updateList);

   }

   int temp_view_id=0;
   int orig_view_id=_create_temp_view(temp_view_id);
   if( orig_view_id=='' ) {
      _message_box('Error creating temp view');
      return(1);
   }
   _delete_line();

   //def_mytest= *s_p;

   // Styles
   typeless i,style:[];
   style=s_p->style;
   for( i._makeempty();; ) {
      style._nextel(i);
      if( i._isempty() ) break;
      if( _LanguageInheritsFrom('xml',lang) && _xmlOptionNotUsed(i) ) continue;
      insert_line(i:+'=':+style:[i]);
   }
   // Comments
   _str line="";
   typeless comment:[];
   typeless comments[];
   comments=s_p->comments;
   for( i=0;i<comments._length();++i ) {
      comment=s_p->comments[i];
      if( comment:["type"]==HFCOMMENT_MULTILINE ) {
         line="mlcomment=":+comment:["startstr"]:+" ":+comment:["endstr"];
         if( comment:["nesting"] ) {
            line=line:+" nesting";
         }
         insert_line(line);
      } else {
         line="linecomment=":+comment:["startstr"];
         insert_line(line);
      }
   }
   // Sort
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      msg=get_message(mark);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   _select_line(mark);
   top();
   _select_line(mark);
   _sort_selection('i',mark);
   _delete_selection(mark);
   bottom();

   // Tags
   typeless tags:[];
   typeless parm:[];
   tags=s_p->tags;
   int noflines=0;
   typeless j;
   for( i._makeempty();; ) {
      tags._nextel(i);
      if( i._isempty() ) break;
      parm=tags:[i];
      for( j._makeempty();; ) {
         parm._nextel(j);
         if( j._isempty() ) break;
         // tag*<tagname>*<varname>=val
         insert_line('tag*':+i:+'*':+j:+'=':+tags:[i]:[j]);
         ++noflines;
      }
   }
   // Sort
   if( noflines>1 ) {
      mark=_alloc_selection();
      if( mark<0 ) {
         msg=get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
      up(noflines-1);
      _select_line(mark);
      bottom();
      _select_line(mark);
      _sort_selection('i',mark);
      _delete_selection(mark);
      bottom();
   }

   p_window_id=orig_view_id;

   // Whatever calls this function is responsible for calling
   // MaybeCreateFormatUserIniFile() first.

   // Do not need to use _delete_temp_view() because _ini_put_section() will get rid of it for us
   // Do not need to worry if the file does not exist, _ini_put_section() will create it
   status=_ini_put_section(FormatUserIniFilename(),section_name,temp_view_id);
   if( status ) {
      msg=nls('Unable to update file "%s".',FormatUserIniFilename()):+"  ":+get_message(status);
      _message_box(msg,"Error",MB_OK|MB_ICONEXCLAMATION);
      return(status);
   }
   // call_list for _hformatSaveScheme_
   call_list('_hformatSaveScheme_',lang,scheme_name);

   return(0);
}

/**
 * Make sure a default HTML Beautifier scheme exists in "uformat.ini".
 * Wrote this function so it could be called from the HTML toolbar.
 */
int HFormatMaybeCreateDefaultScheme()
{
   htmScheme_t scheme;
   _str languages[];

   MaybeCreateFormatUserIniFile();

   languages._makeempty();
   languages[languages._length()]='html';
   languages[languages._length()]='cfml';
   languages[languages._length()]='xml';

   // Sync with language options?
   typeless sync_lang_options="";
   typeless status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
   if( status ) sync_lang_options=true;

   _str lang="";
   typeless writedefaultoptions=0;

   int i;
   for( i=0;i<languages._length();++i ) {
      lang=languages[i];
      _InitStyle(scheme.style,lang);
      // Guarantee that these atleast get set to the same value as "indent_amount"
      scheme.style:["tabsize"]= -1;
      scheme.style:["orig_tabsize"]= -1;
      _InitAllTags(scheme.tags,lang);
      _InitComments(scheme.comments,lang);
      // Get [[lang]-scheme-Default] section and put into scheme
      htmScheme_t temp:[];
      temp._makeempty();
      temp:[HF_DEFAULT_SCHEME_NAME]=scheme;
      writedefaultoptions=_GetUserScheme(temp,HF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
      scheme=temp:[HF_DEFAULT_SCHEME_NAME];
      if( writedefaultoptions ) {
         // If we are here, then (for some reason) there were no default options
         // in the user scheme file, so write the default options.
         status=_SaveScheme(&scheme,lang:+'-scheme-':+HF_DEFAULT_SCHEME_NAME,sync_lang_options);
         if( status ) {
            _str msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return(1);
         }
      }
   }

   return(0);
}

static int _format(htmScheme_t *pscheme,
                   _str lang,
                   _str orig_encoding,
                   _str infilename,
                   _str inview_id,
                   _str outfilename,
                   int  start_indent,
                   int  start_linenum)
{
   _str debugfilename="";
   int vse_flags=0;
   if( HFDEBUG_WINDOW || HFDEBUG_FILE ) {
      if( HFDEBUG_WINDOW ) {
         vse_flags|=HFDEBUGFLAG_WINDOW;
      }
      if( HFDEBUG_FILE ) {
         vse_flags|=HFDEBUGFLAG_FILE;
      }
   }

   typeless status=0;
   if( _LanguageInheritsFrom('xml',lang) ) {
      status=vsx_format((int)orig_encoding,
                        infilename,
                        (int)inview_id,
                        outfilename,
                        start_indent,
                        start_linenum,
                        pscheme->style,
                        pscheme->tags,
                        pscheme->comments,
                        vse_flags);
   } else {
      status=vsh_format((int)orig_encoding,
                        infilename,
                        (int)inview_id,
                        outfilename,
                        start_indent,
                        start_linenum,
                        pscheme->style,
                        pscheme->tags,
                        pscheme->comments,
                        vse_flags);
   }

   return(0);
}

static int _script_format(htmScheme_t *pscheme,int src_view_id,_str lang)
{
   int orig_view_id=p_window_id;
   p_window_id=src_view_id;

   int adjusted_linenum=p_line;

   top();
   if( _on_line0() ) return(0);   // Nothing to beautify

   if( p_lexer_name=="" && lang!="" ) {
      // Probably a temp view passed in by h_format_selection()
      p_lexer_name=_LangId2LexerName(lang);
      p_color_flags=LANGUAGE_COLOR_FLAG;
      p_LangId=lang;
   }
   if( p_lexer_name=="" ) {
      _str msg="No lexer information available for script";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   boolean is_javascript=false;
   typeless status=0;
   typeless format_status=0;
   typeless mark="";
   typeless val="";
   typeless replace_mark="";
   typeless junk="";
   typeless utf8=0;
   typeless encoding=0;
   _str line="";
   _str tagname="";
   _str attrib="";
   _str msg="";
   int temp_view_id=0;
   int end_pcol=0;
   int indent_col=0;
   int start_linenum=0;
   int start_col=0;
   int end_linenum=0;
   int end_col=0;
   int noflines=0;
   int new_linenum=0;
   int top_linenum=0;
   int bottom_linenum=0;
   int new_noflines=0;
   int error_linenum=0;

   for(;;) {
      // Find next <script|server ...> tag that is not in a comment or string.
      status=search('{#0\<(script|server)[~\>]@\>}','@irhXCS');
      if( status ) break;
      if( p_EmbeddedLexerName!="" ) {
         // Already inside a <script ...> block
         //move once to the right so the search does not repeatedly find the same location; 
         right();
         continue;
      }

      // Make sure this is script source we can beautify
      is_javascript=true;   // If there are no attributes then this will remain true
      line=get_match_text(0);
      // Strip leading <
      line=strip(line,'L','<');
      // Strip trailing >
      line=strip(line,'T','>');
      // Separate tag name from attribute(s)
      parse line with tagname line;
      tagname=upcase(tagname);
      if( tagname=='SCRIPT' ) {
         // Strip leading and trailing spaces
         line=strip(line);
         // Find language
         while( line!="" ) {
            parse line with attrib '=' val line;
            val=strip(val,'B','"');
            val=strip(val);
            attrib=lowcase(attrib);
            val=lowcase(val);
            if( attrib=="language" ) {
               if( substr(val,1,length("javascript"))!="javascript" ) {
                  is_javascript=false;
                  break;
               }
            }
         }
      }
      if( !is_javascript ) {
         // Position cursor after <script|server ...> tag so we don't find it again
         end_pcol=_text_colc(p_col,'P')+match_length('0');
         p_col=_text_colc(end_pcol,'I');
         continue;
      }

      // This is the column we will start indenting the script from
      indent_col=p_col;
      if( pscheme->tags:[tagname]:["indent_content"] ) {
         indent_col+=pscheme->style:["indent_amount"];
      }

      // Position cursor after <script|server ...> tag
      end_pcol=_text_colc(p_col,'P')+match_length('0');
      p_col=_text_colc(end_pcol,'I');
      if( _expand_tabsc(p_col,-1,'E')=="" ) {
         // Nothing after the <script|server ...> tag, so start selection on the next line
         if( down() ) break;   // <script|server ...> was the last line of file
         p_col=1;
      }

      // Keep track of the starting line number so we can adjust adjusted_linenum later
      start_linenum=p_line;
      start_col=p_col;

      mark=_alloc_selection();
      if( mark<0 ) {
         msg="Unable to select script block.  ":+get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         format_status=mark;
         break;
      }
      _select_char(mark,'EI');

      // Find the end of the script
      status=search('{#0\</'tagname'[~\>]@\>}','@irhXCS');
      if( status ) {
         _free_selection(mark);
         break;
      }
      if( _expand_tabsc(1,p_col-1,'E')=="" ) {
         // Nothing before the </script|server>, so end the selection on the previous line
         up();_end_line();
      }

      // Keep track of the ending line number so we can adjust adjusted_linenum later
      end_linenum=p_line;
      end_col=p_col-1;
      noflines=end_linenum-start_linenum+1;

      if( !noflines || (noflines==1 && _expand_tabsc(start_col,end_col-start_col+1,'E')=="") ) {
         // Nothing to beautify
         // Make sure we do not find the same <script|server ...>
         p_line=end_linenum;
         p_col=end_col;
         _free_selection(mark);
         continue;
      }

      _select_char(mark,'EN');

      // Duplicate the selection so we can delete and replace with beautiful stuff after we are done
      replace_mark=_duplicate_selection(mark);

      // Now set up the temp view to hold the script source
      if( _create_temp_view(temp_view_id)=="" ) {
         format_status=1;
         break;
      }

      // Set the encoding of the temp view to the same thing as the original buffer
      _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
      p_UTF8=utf8;
      p_encoding=encoding;

      // _create_temp_view() creates a buffer with 0 lines which would
      // mess up using _copy_to_cursor() with a character selection, so
      // fix it.
      insert_line("");
      // Get rid of the newline chars so we don't get an extra newline
      // after the _copy_to_cursor().
      _delete_text(-2);
      p_window_id=temp_view_id;
      _copy_to_cursor(mark);
      _free_selection(mark);
      p_LangId="js";
      p_tabs=LanguageSettings.getTabs(lang);
      #if 0
      _save_file('+o in');
      #endif

      //messageNwait('adjusted_linenum='adjusted_linenum'  start_linenum='start_linenum'  end_linenum='end_linenum);
      if( adjusted_linenum>=start_linenum && adjusted_linenum<=end_linenum ) {
         // The original current line number was in the middle of
         // the JavaScript block, so put it back so c_format() can
         // adjust it.
         p_line=adjusted_linenum-start_linenum+1;
      }
      // Beautify it
      format_status=c_format(temp_view_id,indent_col-1);
      p_window_id=temp_view_id;   // Just in case
      if( !format_status ) {
         #if 0
         _save_file('+o out');
         #endif
         new_linenum=p_line;
         top();
         top_linenum=p_line;
         mark=_alloc_selection();
         if( mark<0 ) {
            msg=get_message(mark);
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            format_status=mark;
            break;
         }
         _select_char(mark,'EI');
         bottom();
         bottom_linenum=p_line;
         new_noflines=bottom_linenum-top_linenum+1;
         _select_char(mark,'EN');
         p_window_id=src_view_id;
         _begin_select(replace_mark);
         _delete_selection(replace_mark);
         _copy_to_cursor(mark);
         _free_selection(mark);
         //messageNwait('adjusted_linenum='adjusted_linenum'  start_linenum='start_linenum'  end_linenum='end_linenum'  new_linenum='new_linenum);
         if( adjusted_linenum>start_linenum ) {
            // The original line (before beautifying JavaScript) was
            // in the middle of, or after, the JavaScript block, so we have
            // to adjust the line number.
            if( adjusted_linenum>end_linenum ) {
               // After the JavaScript block
               int diff=new_noflines-noflines;   // OK if this is negative
               adjusted_linenum+=diff;
            } else {
               // In the middle of JavaScript block
               //messageNwait('new_linenum='new_linenum);
               adjusted_linenum=start_linenum+new_linenum-1;
            }
            if( adjusted_linenum<1 ) adjusted_linenum=1;   // Just in case
         }
      } else {
         error_linenum=p_line;
         p_window_id=src_view_id;
         if( format_status==2 ) {
            error_linenum+=start_linenum-1;
            p_line=error_linenum;
            msg=vscf_iserror();
            if( isinteger(msg) ) {
               // Got one of the *_RC constants in rc.sh
               msg=get_message((int)msg);
            } else {
               parse msg with . ':' msg;
               msg=error_linenum:+':':+msg;
            }
            _message_box(msg);
         }
      }
      _delete_temp_view(temp_view_id);
      p_window_id=src_view_id;
      if( format_status ) break;
   }

   p_window_id=orig_view_id;

   if( !format_status ) {
      p_line=adjusted_linenum;
   }

   return(format_status);
}

int _OnUpdate_h_beautify(CMDUI cmdui,int target_wid,_str command)
{
   if( !target_wid || !target_wid._isEditorCtl() ) {
      return(MF_GRAYED);
   }

   _str lang=target_wid.p_LangId;
   return((_LanguageInheritsFrom('html',lang) || _LanguageInheritsFrom('xml',lang) )?MF_ENABLED:MF_GRAYED);
}

/**
 * Beautifies the current buffer using the current options.  Use the <b>HTML 
 * Beautifier dialog box</b> set beautifier options used by this command.
 * 
 * @param in_wid Input window id to format. If 0, then current window is formatted.
 *               Defaults to 0.
 * @param start_indent Starting indent for formatted lines.
 *                     Defaults to 0.
 * @param lang    Canonical language ID of window being formatted. 
 *                If "", then p_LangId of the window is used. Defaults to "".
 * @param pscheme Pointer to formatter settings to use. Defaults to 0 (NULL). 
 * @param quiet  (optional). Set to true if you do not want to see status messages or be prompted 
 *               for options (e.g. tab mismatch). More serious errors (e.g. failed to save default
 *               options, etc.) will still be displayed loudly. Defaults to false.
 * 
 * @see gui_beautify
 * @see h_beautify_selection
 * @see xml_beautify_selection
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods, Editor_Control_Methods
 * 
 * @return 0 if sucessful, non-zero for error.  value==2 means there was an
 * error beautifying and calling function should get the error message with 
 * vscf_iserror().
 */
_command int h_format,h_beautify,html_format,html_beautify,xml_format,xml_beautify(int in_wid=0, int start_indent=0, _str lang="", htmScheme_t* pscheme=null, boolean quiet=false) name_info(','VSARG2_ICON|VSARG2_REQUIRES_EDITORCTL|VSARG2_READ_ONLY)
{
   htmScheme_t scheme;

   if( start_indent<0 ) {
      start_indent=0;
   }
   scheme._makeempty();
   if( pscheme ) {
      scheme= *pscheme;
   }

   if( p_Nofhidden ) {
      show_all();
   }

   boolean old_modify=p_modify;   // Save in the case of doing the entire buffer so we can set it back when we "undo"
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;
   save_pos(auto p);

   _str msg="";
   _str orig_lang="";
   _str infilename="";
   _str outfilename="";
   int editorctl_wid=p_window_id;
   if( !_isEditorCtl() ) {
      editorctl_wid=0;
   }

   typeless status=0;
   typeless sync_lang_options=0;
   typeless writedefaultoptions=0;

   // Do the current buffer
   if( scheme._isempty() ) {
      if( !_isEditorCtl() ) {
         msg="No buffer!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
      if( lang=="" ) {
         lang=p_LangId;
      }
      orig_lang=lang;
      if( BeautifyCheckSupport(lang) ) {
         if( !quiet ) {
            msg='Beautifying not supported for "':+p_mode_name:+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return(1);
      }
      lang=orig_lang;

      // Sync with language options?
      status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
      if( status ) sync_lang_options=true;

      _InitStyle(scheme.style,lang);
      // Guarantee that these atleast get set to the same value as "indent_amount"
      scheme.style:["tabsize"]= -1;
      scheme.style:["orig_tabsize"]= -1;
      _InitAllTags(scheme.tags,lang);
      _InitComments(scheme.comments,lang);
      // Get [[lang]-scheme-Default] section and put into scheme
      htmScheme_t temp:[];
      temp._makeempty();
      temp:[HF_DEFAULT_SCHEME_NAME]=scheme;
      writedefaultoptions=_GetUserScheme(temp,HF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
      scheme=temp:[HF_DEFAULT_SCHEME_NAME];
      if( writedefaultoptions ) {
         // If we are here, then (for some reason) there were no default options
         // in the user scheme file, so write the default options.
         HFormatMaybeCreateDefaultScheme();
         status=_SaveScheme(&scheme,lang:+'-scheme-':+HF_DEFAULT_SCHEME_NAME,sync_lang_options);
         if( status ) {
            msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return(1);
         }
         _GetUserScheme(temp,HF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
         scheme=temp:[HF_DEFAULT_SCHEME_NAME];
      }
   } else {
      if( lang=="" ) {
         msg="No language specified!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
   }

   typeless i;
   _str tagcase=scheme.style:["tagcase"];
   if( ( _LanguageInheritsFrom('xml',lang) ) && isinteger(tagcase) && tagcase!=HFPRESERVE ) {
      // XML:
      // If the user specified to case tag names, then we must include all tag names
      // cased identically in order to make case-insensitive comparison possible. This
      // macro and vsx_format() agree to do such comparisons in UPPER-case.
      //
      // Note: This will effectively double the size of the hash table.
      typeless itags:[];
      itags._makeempty();
      for( i._makeempty();; ) {
         scheme.tags._nextel(i);
         if( i._isempty() ) break;
         if( upcase(i):==i ) continue;
         _str temp=scheme.tags:[i];
         itags:[upcase(i)]=temp;
         //scheme.tags:[upcase(i)]=temp;
      }
      for( i._makeempty();; ) {
         itags._nextel(i);
         if( i._isempty() ) break;
         scheme.tags:[i]=itags:[i];
      }
   }
   #if 0
   // Debug
   for ( i._makeempty();; ) {
      scheme.tags._nextel(i);
      if( i._isempty() ) break;
      say('i='i);
   }
   #endif

   if( _MyCheckTabs(editorctl_wid,&scheme) ) return(1);

   boolean orig_utf8=p_UTF8;
   int orig_encoding=p_encoding;
   // This is the +fxxx flag that p_encoding is equivalent to.
   // This is very important when creating the temp view to output
   // to, and when saving the temp file for the beautifier to process.
   typeless encoding_loadsave_flag=_EncodingToOption(orig_encoding);


   // Switch to temp view
   int orig_view_id=p_window_id;
   if( in_wid ) {
      p_window_id=in_wid;
   }

   // Make a temp file to use as the input source file
   infilename=mktemp();
   if( infilename=="" ) {
      msg="Error creating temp file";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   //_save_file(encoding_loadsave_flag' +o junk');
   status=_save_file(encoding_loadsave_flag' +o ':+maybe_quote_filename(infilename));   // This is the source file
   if( status ) {
      msg='Error creating temp file "':+infilename:+'".  ':+get_message(status);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   int start_linenum=p_line;
   bottom();
   boolean last_line_was_bare=(_line_length()==_line_length(1));

   // Create a temporary view for beautifier output *with* p_undo_steps=0
   _str arg2="+td";   // DOS \r\n linebreak
   if( length(p_newline)==1 ) {
      if( substr(p_newline,1,1)=='\r' ) {
         arg2="+tm";   // Macintosh \r linebreak
      } else {
         arg2="+tu";   // UNIX \n linebreak
      }
   }
   arg2=encoding_loadsave_flag' 'arg2;
   //say('arg2='arg2);
   int output_view_id=0;
   status=_create_temp_view(output_view_id,arg2);
   if( status=="" ) {
      msg="Error creating temp view";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }
   // _create_temp_view() _always_ sets p_UTF8=1, so must override
   p_UTF8=orig_utf8;
   _delete_line();

   mou_hour_glass(1);
   status=_format(&scheme,
                  lang,
                  orig_encoding,
                  infilename,
                  0,   // Input view id
                  outfilename,
                  start_indent,
                  start_linenum);
   mou_hour_glass(0);

   // Cleanup temp files that were created
   delete_file(infilename);   // Delete the temp file
   if( !_line_length(true) ) {
      // Get rid of the zero-length line at the bottom
      _delete_line();
   }

   typeless mark=0;
   typeless linenum=0;
   msg=vshf_iserror();
   if( msg!="" ) {
      _delete_temp_view(output_view_id);
      if( in_wid ) {
         p_window_id=in_wid;   // Do this instead of orig_view_id so we can set the error line number correctly
      } else {
         p_window_id=orig_view_id;
      }

      // Show the message and position at the error
      if( isinteger(msg) ) {
         // Got one of the *_RC constants in rc.sh
         msg=get_message((int)msg);
      } else {
         parse msg with linenum ':' .;
         if( isinteger(linenum) ) {   // Just in case
            p_line=linenum;
         }
      }
      if( in_wid ) {
         /* Don't show the error yet.  Let h_beautify_selection() do that, otherwise
          * the linenumber it displays will be completely wrong
          */
         p_window_id=in_wid;
         return(2);
      } else {
         if( !quiet ) {
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
      return(2);
   } else {
      // Everything is good, so clear the temp view and put the beautiful stuff in
      mark=_alloc_selection();
      if( mark<0 ) {
         msg=get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         _delete_temp_view(output_view_id);
         p_window_id=orig_view_id;
         return(1);
      }
      if( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      _lbclear();   // _lbclear() does a _delete_selection(), so don't have to worry about a lot of undo steps
      p_window_id=output_view_id;
      //_save_file('+o out');
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      if( in_wid ) {
         p_window_id=in_wid;
      } else {
         p_window_id=orig_view_id;
      }
      _copy_to_cursor(mark);
      _free_selection(mark);
      bottom();
      if( last_line_was_bare ) {
         // The last line of the file had no newline at the end, so fix it
         _end_line();
         _delete_text(-2);
      }
      int adjusted_linenum=vshf_adjusted_linenum();
      p_line= (adjusted_linenum)?(adjusted_linenum):(1);   // Don't allow line 0
      _begin_line();
      _delete_temp_view(output_view_id);

      if( scheme.style:["beautify_javascript"] && !_LanguageInheritsFrom('xml',lang) ) {
         // Now beautify embedded JavaScript
         status=_script_format(&scheme,p_window_id,lang);
         if( status ) return(status);
      }
      set_scroll_pos(old_left_edge,old_cursor_y);
   }

   return(0);
}

static int _FindBeginContext(int mark, int &sl, int &el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;

   _str msg="";
   _begin_select(mark);

   while( p_line>1 ) {
      _begin_line();   // Goto to beginning of line so not fooled by start of comment
      if( _in_comment(1) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to beginning of it
         if( p_line==1 ) {
            // Should never get here
            // There is no way we will find the beginning of this comment
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         up();
         while( p_line && _clex_find(0,'G')==CFG_COMMENT ) {
            up();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the top of file
            if( !quiet ) {
               msg="Cannot find beginning of context:\n\n":+
                   "\tCannot find beginning of comment at line 1";
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         _end_line();
         // Check to see if we are ON the multiline comment
         if( _clex_find(0,'G')!=CFG_COMMENT ) {
            down();   // Move back onto the first line of the comment
         }
      } else if( p_EmbeddedLexerName!="" && p_line>1 ) {
         // If we are inside embedded script, then skip to beginning of it.
         // p_line>1 so we don't get into any weird situations where the
         // script starts on line 1 and we would have gotten into an infinite
         // loop while looking for the beginning of the script.
         while( p_EmbeddedLexerName!="" && p_EmbeddedLexerName!=p_lexer_name ) {
            up();
            if( _on_line0() ) {
               down();
               break;
            }
         }
         // It is safe to assume that we are on the <script ...> line now,
         // so no adjustment needed.
      } else {
         break;
      }
   }
   sl=p_line;
   if( sl!=old_sl ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   _begin_select(mark);

   // Beginning of context is top-of-file
   top();

   return(0);
}

static int _FindEndContext(int mark ,int &sl, int &el, boolean quiet=false)
{
   int old_sl=sl;
   int old_el=el;
   _str msg="";

   _end_select(mark);
   _end_line();   // Goto end of line so not fooled by start of comment

   while( p_line<p_Noflines ) {
      if( _in_comment(1) ) {
         // If we are in the middle of a multi-line comment,
         // then skip to end of it
         if( down() ) {
            // Should never get here
            // There is no way that this multi-line comment has an end
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         _begin_line();
         while( _clex_find(0,'G')==CFG_COMMENT ) {
            if( down() ) break;   // Comment might extend to bottom of file
            _begin_line();
         }
         if( _clex_find(0,'G')==CFG_COMMENT ) {
            // We are at the bottom of file
            if( !quiet ) {
               msg="Cannot find end of context:\n\n":+
                   "\tCannot find end of comment at line ":+p_line;
               _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            }
            sl=0;
            el=0;
            return(1);
         }
         up();   // Move back onto the last line of the comment
         // Will get infinite loop if we don't move outside the comment
         _end_line();
      } else if( p_EmbeddedLexerName!="" && p_line<p_Noflines ) {
         // If we are inside embedded script, then skip to beginning of it.
         // p_line>1 so we don't get into any weird situations where the
         // script starts on line 1 and we would have gotten into an infinite
         // loop while looking for the beginning of the script.
         while( p_EmbeddedLexerName!="" && p_EmbeddedLexerName!=p_lexer_name ) {
            if( down() ) break;
         }
         // It is safe to assume that we are on the <script ...> line now,
         // so no adjustment needed.
      } else {
         break;
      }
   }
   el=p_line;
   if( el!=old_el ) {
      // Reset the selection
      _deselect(mark);
      p_line=sl;
      _select_line(mark);
      p_line=el;
      _select_line(mark);
   }

   // End of context is bottom-of-file
   bottom();

   return(0);
}

static int _CreateContextView(_str mlc_startstr,_str mlc_endstr,
                              int &temp_view_id,
                              int &context_mark,
                              int &soc_linenum,   // StartOfContext line number
                              boolean &last_line_was_bare,
                              boolean quiet=false)
{
   last_line_was_bare=false;
   save_pos(auto p);
   int old_linenum=p_line;
   typeless orig_mark=_duplicate_selection("");
   context_mark=_duplicate_selection();
   typeless mark=_alloc_selection();
   if( mark<0 ) {
      _free_selection(context_mark);
      return(mark);
   }
   int start_col=0;
   int end_col=0;
   int startmark_linenum=0;
   typeless dummy;
   typeless stype=_select_type();
   if( stype!='LINE' ) {
      // Change the duplicated selection into a LINE selection
      if( stype=='CHAR' ) {
         _get_selinfo(start_col,end_col,dummy);
         if( end_col==1 ) {
            // Throw out the last line of the selection
            _deselect(context_mark);
            _begin_select();
            startmark_linenum=p_line;
            _select_line(context_mark);
            _end_select();
            // Check to be sure it's not a case of a character-selection of 1 char on the same line
            if( p_line!=startmark_linenum ) {
               up();
            }
            _select_line(context_mark);
         } else {
            _select_type(context_mark,'T','LINE');
         }
      } else {
         _select_type(context_mark,'T','LINE');
      }
   }

   // Define the line boundaries of the selection
   _begin_select(context_mark);
   int sl=p_line;   // start line
   _end_select(context_mark);
   int el=p_line;   // end line
   int orig_sl=sl;
   int orig_el=el;

   // Find the top context
   if( _FindBeginContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
         /* Probably in the middle of a comment that
          * extended to the bottom of file, so could
          * do nothing.
          */
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return(1);
      }
      top();
   }
   int tl=p_line;   // Top line
   soc_linenum=sl;
   int diff=old_linenum-tl;
   _select_line(mark);
   _begin_select(context_mark);
   first_non_blank();
   int start_indent=p_col-1;

   // Find the bottom context
   if( _FindEndContext(context_mark,sl,el,quiet) ) {
      if( !sl || !el ) {
         _free_selection(context_mark);
         _free_selection(mark);
         restore_pos(p);
         return(1);
      }
      bottom();
   }
   _select_line(mark);
   _end_select(context_mark);

   // Check to see if last line was bare of newline
   last_line_was_bare= (_line_length()==_line_length(1));

   // Create a temporary view to hold the code selection and move it there
   _str arg2="+td";   // DOS \r\n linebreak
   if( length(p_newline)==1 ) {
      if( substr(p_newline,1,1)=='\r' ) {
         arg2="+tm";   // Macintosh \r linebreak
      } else {
         arg2="+tu";   // UNIX \n linebreak
      }
   }
   int orig_view_id=_create_temp_view(temp_view_id,arg2);
   if( orig_view_id=='' ) return(1);

   // Set the encoding of the temp view to the same thing as the original buffer
   typeless junk;
   typeless utf8=0;
   typeless encoding=0;
   _get_selinfo(junk,junk,junk,mark,junk,utf8,encoding);
   p_UTF8=utf8;
   p_encoding=encoding;

   _copy_to_cursor(mark);
   _free_selection(mark);       // Can free this because it was never shown
   top();up();
   insert_line(mlc_startstr:+' HFORMAT-SUSPEND-WRITE ':+mlc_endstr);
   down();
   p_line=sl-tl+1;   // +1 to compensate for the previously inserted line at the top
   insert_line(mlc_startstr:+' HFORMAT-RESUME-WRITE ':+mlc_endstr);
   p_line=el-tl+1+2;   // +2 to compensate for the 2 previously inserted lines
   insert_line(mlc_startstr:+' HFORMAT-SUSPEND-WRITE ':+mlc_endstr);
   top();
   // +2 to adjust for the HFORMAT-SUSPEND-WRITE and HFORMAT-RESUME-WRITE above
   p_line=p_line+diff+2;
   p_window_id=orig_view_id;

   return(0);
}

static void _DeleteContextSelection(int context_mark)
{
   /* If we were on the last line, then beautified text will get inserted too
    * early in the buffer
    */
   _end_select();
   boolean last_line_was_empty=0;
   if( down() ) {
      last_line_was_empty=1;   // We are on the last line of the file
   } else {
      up();
   }

   _begin_select(context_mark);
   _begin_line();

   // Now delete the originally selected lines
   _delete_selection(context_mark);
   _free_selection(context_mark);   // Can free this because it was never shown
   if( !last_line_was_empty ) up();

   return;
}

int _OnUpdate_h_beautify_selection(CMDUI cmdui,int target_wid,_str command)
{
   return(_OnUpdate_h_beautify(cmdui,target_wid,command));
}

/**
 * Beautifies the current selection using the current options.  If there is 
 * no current selection the entire buffer is beautified.  Use the <b>HTML 
 * Beautifier dialog box</b> set beautifier options used by this command.
 * 
 * @param lang    Canonical language ID of window being formatted. 
 *                If "", then p_LangId of the window is used. Defaults to "".
 * @param pscheme Pointer to formatter settings to use. Defaults to 0 (NULL). 
 * @param quiet  (optional). Set to true if you do not want to see status messages or be prompted 
 *               for options (e.g. tab mismatch). More serious errors (e.g. failed to save default
 *               options, etc.) will still be displayed loudly. Defaults to false.
 * 
 * @see gui_beautify
 * @see h_beautify
 * 
 * @appliesTo Edit_Window, Editor_Control
 * 
 * @categories Edit_Window_Methods
 * 
 */
_command int h_format_selection,h_beautify_selection,html_beautify_selection,xml_beautify_selection(_str lang="", htmScheme_t* pscheme=null, boolean quiet=false) name_info(','VSARG2_EDITORCTL|VSARG2_REQUIRES_MDI_EDITORCTL|VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   htmScheme_t scheme;

   if( !select_active() ) {
      return(h_format(0,0,lang,pscheme,quiet));
   }

   scheme._makeempty();
   if( pscheme ) {
      scheme= *pscheme;
   }

   if( p_Nofhidden ) {
      show_all();
   }

   int editorctl_wid=p_window_id;
   if( !_isEditorCtl() ) {
      editorctl_wid=0;
   }

   typeless status=0;
   typeless sync_lang_options=0;
   typeless writedefaultoptions=0;
   _str msg="";

   // Do the current buffer
   if( scheme._isempty() ) {
      if( !_isEditorCtl() ) {
         msg="No buffer!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
      if( lang=="" ) {
         lang=p_LangId;
      }
      _str orig_lang=lang;
      if( BeautifyCheckSupport(lang) ) {
         if( !quiet ) {
            msg='Beautifying not supported for language "':+_LangId2Modename(lang):+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
         return(1);
      }
      lang=orig_lang;

      // Sync with language options?
      status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,"1");
      if( status ) sync_lang_options=true;

      // Get [[lang]-scheme-Default] section and put into scheme
      _InitStyle(scheme.style,lang);
      // Guarantee that these atleast get set to the same value as "indent_amount"
      scheme.style:["tabsize"]= -1;
      scheme.style:["orig_tabsize"]= -1;
      _InitAllTags(scheme.tags,lang);
      _InitComments(scheme.comments,lang);
      htmScheme_t temp:[];
      temp._makeempty();
      temp:[HF_DEFAULT_SCHEME_NAME]=scheme;
      writedefaultoptions=_GetUserScheme(temp,HF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
      scheme=temp:[HF_DEFAULT_SCHEME_NAME];
      if( writedefaultoptions ) {
         /* If we are here, then (for some reason) there were no default options
          * in the user scheme file, so write the default options
          */
         status=_SaveScheme(&scheme,lang:+'-scheme-':+HF_DEFAULT_SCHEME_NAME,sync_lang_options);
         if( status ) {
            msg='Failed to write default options to "':+FormatUserIniFilename():+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return(1);
         }
      }
   } else {
      if( lang=="" ) {
         msg="No language specified!";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
   }

   // Must have atleast 1 multiline comment defined so we can bracket the context
   _str mlc_startstr="";
   _str mlc_endstr="";
   typeless comment="";
   typeless type="";
   int i;
   for( i=0;i<scheme.comments._length();++i ) {
      comment=scheme.comments[i];
      type=comment:["type"];
      if( type!=HFCOMMENT_MULTILINE ) continue;
      mlc_startstr=comment:["startstr"];
      mlc_endstr=comment:["endstr"];
      break;
   }
   if( mlc_startstr=="" || mlc_endstr=="" ) {
      msg="You need to define at least 1 multiline comment in order for beautifying selection to work";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return(1);
   }

   save_pos(auto p);
   int orig_view_id=p_window_id;
   int old_left_edge=p_left_edge;
   int old_cursor_y=p_cursor_y;

   _begin_select();
   int tom_linenum=p_line;
   restore_pos(p);

   // Find the context
   typeless context_mark=0;
   boolean last_line_was_bare=false;
   int soc_linenum=0;
   int temp_view_id=0;
   if( _CreateContextView(mlc_startstr,mlc_endstr,temp_view_id,context_mark,soc_linenum,last_line_was_bare,quiet) ) {
      if( !quiet ) {
         _message_box('Failed to derive context for selection');
      }
      return(1);
   }

   int start_indent=0;
   typeless old_mark=0;
   typeless mark=0;
   int new_linenum=0;
   int error_linenum=0;

   // Do this before calling h_format() so do not end up somewhere funky
   restore_pos(p);
   status=h_format(temp_view_id,start_indent,lang,&scheme,quiet);
   if( !status ) {
      p_window_id=orig_view_id;
      old_mark=_duplicate_selection("");
      mark=_alloc_selection();
      if( mark<0 ) {
         _delete_temp_view(temp_view_id);
         msg=get_message(mark);
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(mark);
      }

      /* Delete the selection and position cursor so we are sure
       * we start inserting beautified text at the correct place
       */
      _DeleteContextSelection(context_mark);

      // Get the beautified text from the temp view
      p_window_id=temp_view_id;
      new_linenum=p_line;
      top();
      _select_line(mark);
      bottom();
      _select_line(mark);
      p_window_id=orig_view_id;
      _copy_to_cursor(mark);
      _end_select(mark);
      _free_selection(mark);
      // Check to see if we need to strip off the last newline
      if( last_line_was_bare ) {
         _end_line();
         _delete_text(-2);
      }
      new_linenum=new_linenum+soc_linenum-1;
      p_line=new_linenum;
      set_scroll_pos(old_left_edge,old_cursor_y);
      /* HERE - Need to account for extended selection because started/ended
       * in the middle of a comment.  Need to do an adjustment.
       */
   } else {
      if( status==2 ) {
         /* There was an error, so transform the error line number
          * from the temp view into the correct line number
          */
         error_linenum=p_line;
         p_window_id=orig_view_id;
         _deselect();
         /* -2 to correct for the
          * HFORMAT-SUSPEND-WRITE and HFORMAT-RESUME-WRITE directives
          * in the temp view.
          */
         error_linenum=error_linenum+soc_linenum-1-2;
         if( error_linenum>0 ) {
            p_line=error_linenum;
         }
         set_scroll_pos(old_left_edge,old_cursor_y);
         msg=vscf_iserror();
         if( isinteger(msg) ) {
            // Got one of the *_RC constants in rc.sh
            msg=get_message((int)msg);
         } else {
            parse msg with . ':' msg;
            msg=error_linenum:+':':+msg;
         }
         if( !quiet ) {
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         }
      }
   }

   // Cleanup
   _delete_temp_view(temp_view_id);

   return(status);
}

static htmScheme_t _Schemes:[];
static htmScheme_t _UserSchemes:[];

static boolean gchange_scheme=true;
static htmScheme_t gorig_scheme;
static _str gorig_scheme_name="";
static _str gLangId="";

#define INDENTTAB   (0)
#define TAGSTAB     (1)
#define ATTRIBSTAB  (2)
#define COMMENTSTAB (3)
#define ADVANCEDTAB (4)
#define SCHEMESTAB  (5)

defeventtab _html_beautify_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _html_beautify_form_initial_alignment()
{
   padding := ctltag_list.p_x;
   tabWidth := ctlsstab.p_child.p_width;

   // indent tab
   ctlindent_with_tabs.p_x = tabWidth - (ctlindent_with_tabs.p_width + padding);

   // try putting the text box next to the label
   ctlindent.p_x = label1.p_x + label1.p_width + 60;
   rightMostPos := ctlindent_with_tabs.p_x - padding;

   // maybe that is messing with the indent with tabs checkbox?
   if( ctlindent.p_x > rightMostPos ) {
      ctlindent.p_x = rightMostPos;
   }
   ctltabsize.p_x = ctlorig_tabsize.p_x = ctlmax_line_length.p_x = ctlindent.p_x;

   // tags tab
   alignUpDownListButtons(ctltag_list.p_window_id, ctl_tag_content_frame.p_x - padding,
                          ctladd_tag.p_window_id, ctlremove_tag.p_window_id);

   ctlstandalone.p_x = ctl_tag_linebreaks_frame.p_width - (ctlstandalone.p_width + padding);

   shift := (ctlstandalone.p_x - padding - ctlnoflines_before_spin.p_width) - ctlnoflines_before_spin.p_x;
   ctlnoflines_before_spin.p_x += shift;
   ctlnoflines_before.p_x += shift;
   ctlnoflines_after_spin.p_x += shift;
   ctlnoflines_after.p_x += shift;

   ctllabel2.p_x = ctlnoflines_before.p_x - (ctllabel2.p_width + 20);
   ctllabel3.p_x = ctlnoflines_before.p_x - (ctllabel3.p_width + 20);
}

static void _enable_children(int parent,boolean enable)
{
   int firstwid,wid;

   if( !parent ) return;

   firstwid=parent.p_child;
   if( !firstwid ) return;
   wid=firstwid;
   for(;;) {
      if( wid.p_enabled!=enable ) wid.p_enabled=enable;
      wid=wid.p_next;
      if( wid==firstwid ) break;
   }

   return;
}

static void oncreateIndent(htmScheme_t *s_p)
{
   typeless indent_amount=s_p->style:["indent_amount"];
   if( !isinteger(indent_amount) || indent_amount<0 ) {
      indent_amount=DEF_INDENT;
   }
   typeless tabsize=s_p->style:["tabsize"];
   if( !isinteger(tabsize) || tabsize<0 ) {
      tabsize=indent_amount;
   }
   typeless orig_tabsize=s_p->style:["orig_tabsize"];
   if( !isinteger(orig_tabsize) || orig_tabsize<0 ) {
      orig_tabsize=indent_amount;
   }
   typeless indent_with_tabs= (s_p->style:["indent_with_tabs"]!=0);
   typeless max_line_length= (s_p->style:["max_line_length"]);
   if( !isinteger(max_line_length) || max_line_length<0 ) {
      max_line_length=0;
   }
   typeless brokentag_style=s_p->style:["brokentag_style"];
   if( !isinteger(brokentag_style) || brokentag_style<BROKENTAG_STYLE_INDENT || brokentag_style>BROKENTAG_STYLE_PRESERVE ) {
      brokentag_style=BROKENTAG_STYLE_REL;
   }
   typeless brokentag_indent=s_p->style:["brokentag_indent"];
   if( !isinteger(brokentag_indent) || brokentag_indent<0 ) {
      brokentag_indent=0;
   }

   // Now set the controls
   ctlindent.p_text=indent_amount;

   ctltabsize.p_text=tabsize;

   ctlorig_tabsize.p_text=orig_tabsize;

   ctlindent_with_tabs.p_value=indent_with_tabs;

   ctlmax_line_length.p_text=max_line_length;

   ctl_brokentag_style_indent.p_value=0;
   ctl_brokentag_style_rel.p_value=0;
   ctl_brokentag_style_preserve.p_value=0;
   ctl_brokentag_indent.p_text=brokentag_indent;
   ctl_brokentag_indent.p_enabled=false;
   switch( brokentag_style ) {
   case BROKENTAG_STYLE_INDENT:
      ctl_brokentag_style_indent.p_value=1;
      ctl_brokentag_indent.p_enabled=true;
      break;
   case BROKENTAG_STYLE_REL:
      ctl_brokentag_style_rel.p_value=1;
      break;
   case BROKENTAG_STYLE_PRESERVE:
      ctl_brokentag_style_preserve.p_value=1;
      break;
   }

   return;
}
static void oncreateTags(htmScheme_t *s_p)
{
   typeless tagcase=s_p->style:["tagcase"];
   if( tagcase<WORDCASE_PRESERVE || tagcase>WORDCASE_CAPITALIZE ) {
      tagcase=WORDCASE_PRESERVE;
   }

   // Initialize tagcase radio buttons
   ctltagcase_upper.p_value=ctltagcase_lower.p_value=0;
   ctltagcase_capitalize.p_value=ctltagcase_preserve.p_value=0;
   switch( tagcase ) {
   case WORDCASE_UPPER:
      ctltagcase_upper.p_value=1;
      break;
   case WORDCASE_LOWER:
      ctltagcase_lower.p_value=1;
      break;
   case WORDCASE_CAPITALIZE:
      ctltagcase_capitalize.p_value=1;
      break;
   case WORDCASE_PRESERVE:
      ctltagcase_preserve.p_value=1;
      break;
   }

   // Fill the tag list
   typeless i;
   ctltag_list._lbclear();
   for( i._makeempty();; ) {
      s_p->tags._nextel(i);
      if( i._isempty() ) break;
      ctltag_list._lbadd_item(i);
   }
   ctltag_list._lbsort();
   ctltag_list._lbtop();

   // Put the default tag at the top
   _str line="";
   typeless status=ctltag_list._lbsearch(HF_DEFAULT_TAG_NAME);
   if( !status && ctltag_list.p_line>1 ) {
      ctltag_list.get_line(line);
      ctltag_list._lbdelete_item();
      ctltag_list._lbtop();
      ctltag_list.up();
      ctltag_list._lbadd_item(HF_DEFAULT_TAG_NAME);
      ctltag_list.down();
   }

   ctltag_list.p_user=s_p->tags;
   // Remember the last tag selected
   _str tagname=ctltag_list._retrieve_value("_html_beautify_form.lasttag");
   ctltag_list._lbsearch(tagname);
   ctltag_list._lbselect_line();

   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE, "W");

   return;
}
static void oncreateAttribs(htmScheme_t *s_p)
{
   typeless attribcase=s_p->style:["attribcase"];
   if( attribcase<WORDCASE_PRESERVE || attribcase>WORDCASE_CAPITALIZE ) {
      attribcase=WORDCASE_PRESERVE;
   }
   typeless wordvalcase=WORDCASE_PRESERVE;
   typeless hexvalcase=WORDCASE_PRESERVE;
   typeless quote_wordval= HFPRESERVE;
   typeless quote_numval= HFPRESERVE;
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      wordvalcase=WORDCASE_PRESERVE;
      hexvalcase=WORDCASE_PRESERVE;
      quote_wordval= HFPRESERVE;
      quote_numval= HFPRESERVE;
   } else {
      wordvalcase=s_p->style:["wordvalcase"];
      if( wordvalcase<WORDCASE_PRESERVE || wordvalcase>WORDCASE_CAPITALIZE ) {
         wordvalcase=WORDCASE_PRESERVE;
      }
      hexvalcase=s_p->style:["hexvalcase"];
      if( hexvalcase<WORDCASE_PRESERVE || hexvalcase>WORDCASE_UPPER ) {
         hexvalcase=WORDCASE_PRESERVE;
      }
      quote_wordval=s_p->style:["quote_wordval"];
      if( quote_wordval<HFPRESERVE || quote_wordval>HFON ) {
         quote_wordval=HFPRESERVE;
      }
      quote_numval=s_p->style:["quote_numval"];
      if( quote_numval<HFPRESERVE || quote_numval>HFON ) {
         quote_numval=HFPRESERVE;
      }
   }
   typeless quote_all_vals= (s_p->style:["quote_all_vals"]!=0);

   if( _LanguageInheritsFrom('xml',gLangId) ) {
      // XML:
      // Not currently supported.
      ctl_wordvalcase_frame.p_enabled=false;
      _enable_children(ctl_wordvalcase_frame,false);
      ctl_hexvalcase_frame.p_enabled=false;
      _enable_children(ctl_hexvalcase_frame,false);
      ctl_quote_wordval_frame.p_enabled=false;
      _enable_children(ctl_quote_wordval_frame,false);
      ctl_quote_numval_frame.p_enabled=false;
      _enable_children(ctl_quote_numval_frame,false);
   }

   // Initialize attribcase radio buttons
   ctlattribcase_upper.p_value=ctlattribcase_lower.p_value=0;
   ctlattribcase_capitalize.p_value=ctlattribcase_preserve.p_value=0;
   switch( attribcase ) {
   case WORDCASE_UPPER:
      ctlattribcase_upper.p_value=1;
      break;
   case WORDCASE_LOWER:
      ctlattribcase_lower.p_value=1;
      break;
   case WORDCASE_CAPITALIZE:
      ctlattribcase_capitalize.p_value=1;
      break;
   case WORDCASE_PRESERVE:
      ctlattribcase_preserve.p_value=1;
      break;
   }

   // Initialize wordvalcase radio buttons
   ctlwordcase_upper.p_value=ctlwordcase_lower.p_value=0;
   ctlwordcase_capitalize.p_value=ctlwordcase_preserve.p_value=0;
   switch( wordvalcase ) {
   case WORDCASE_UPPER:
      ctlwordcase_upper.p_value=1;
      break;
   case WORDCASE_LOWER:
      ctlwordcase_lower.p_value=1;
      break;
   case WORDCASE_CAPITALIZE:
      ctlwordcase_capitalize.p_value=1;
      break;
   case WORDCASE_PRESERVE:
      ctlwordcase_preserve.p_value=1;
      break;
   }

   // Initialize hexvalcase radio buttons
   ctlhexcase_upper.p_value=ctlhexcase_lower.p_value=0;
   ctlhexcase_preserve.p_value=0;
   switch( hexvalcase ) {
   case WORDCASE_UPPER:
      ctlhexcase_upper.p_value=1;
      break;
   case WORDCASE_LOWER:
      ctlhexcase_lower.p_value=1;
      break;
   case WORDCASE_PRESERVE:
      ctlhexcase_preserve.p_value=1;
      break;
   }

   // Initialize quote_wordval radio buttons
   ctl_quote_wordval_yes.p_value=ctl_quote_wordval_no.p_value=ctl_quote_wordval_preserve.p_value=0;
   switch( quote_wordval ) {
   case HFPRESERVE:
      ctl_quote_wordval_preserve.p_value=1;
      break;
   case HFOFF:
      ctl_quote_wordval_no.p_value=1;
      break;
   case HFON:
      ctl_quote_wordval_yes.p_value=1;
      break;
   }

   // Initialize quote_numval radio buttons
   ctl_quote_numval_yes.p_value=ctl_quote_numval_no.p_value=ctl_quote_numval_preserve.p_value=0;
   switch( quote_numval ) {
   case HFPRESERVE:
      ctl_quote_numval_preserve.p_value=1;
      break;
   case HFOFF:
      ctl_quote_numval_no.p_value=1;
      break;
   case HFON:
      ctl_quote_numval_yes.p_value=1;
      break;
   }

   // Quote all values
   ctl_quote_all_vals.p_value= (int)(quote_all_vals!=0);
   ctl_quote_all_vals.call_event(ctl_quote_all_vals,LBUTTON_UP,'W');

   return;
}
static void oncreateComments(htmScheme_t *s_p)
{
   typeless indent_comments= (s_p->style:["indent_comments"]!=0);
   typeless indent_col1_comments= (s_p->style:["indent_col1_comments"]!=0);
   typeless tcomment=s_p->style:["tcomment"];
   if( !isinteger(tcomment) || tcomment<TCOMMENT_COLUMN || tcomment>TCOMMENT_ABSOLUTE ) {
      tcomment=TCOMMENT_RELATIVE;
   }
   typeless tcomment_col=s_p->style:["tcomment_col"];
   if( !isinteger(tcomment_col) || tcomment_col<1 ) {
      tcomment_col=0;
      if( tcomment==TCOMMENT_COLUMN ) {
         // An invalid comment column invalidates this setting
         tcomment=TCOMMENT_RELATIVE;
      }
   }

   // Now set the controls
   ctlindent_comments.p_value=indent_comments;

   ctlindent_col1_comments.p_value=indent_col1_comments;

   ctltcomment_col_enable.p_value=0;
   ctltcomment_relative.p_value=0;
   ctltcomment_absolute.p_value=0;
   ctltcomment_col.p_text=tcomment_col;
   ctltcomment_col.p_enabled=false;
   switch( tcomment ) {
   case TCOMMENT_COLUMN:
      ctltcomment_col_enable.p_value=1;
      ctltcomment_col.p_enabled=true;
      break;
   case TCOMMENT_RELATIVE:
      ctltcomment_relative.p_value=1;
      break;
   case TCOMMENT_ABSOLUTE:
      ctltcomment_absolute.p_value=1;
      break;
   }

   ctldefine_comments.p_user=s_p->comments;

   return;
}
static void oncreateAdvanced(htmScheme_t *s_p)
{
   typeless popp_on_p=false;
   typeless popp_on_standalone=false;
   typeless eat_blank_lines=false;
   typeless beautify_javascript=false;
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      popp_on_p=false;
      popp_on_standalone=false;
      eat_blank_lines= (s_p->style:["eat_blank_lines"]!=0);
      beautify_javascript=false;
   } else {
      popp_on_p= (s_p->style:["popp_on_p"]!=0);
      popp_on_standalone= (s_p->style:["popp_on_standalone"]!=0);
      eat_blank_lines= (s_p->style:["eat_blank_lines"]!=0);
      beautify_javascript= (s_p->style:["beautify_javascript"]!=0);
   }

   if( _LanguageInheritsFrom('xml',gLangId) ) {
      ctl_p_frame.p_enabled=false;
      _enable_children(ctl_p_frame,false);
      ctlbeautify_javascript.p_enabled=false;
      ctljavascript_settings.p_enabled=false;
   }

   ctlpopp_on_p.p_value=popp_on_p;
   ctlpopp_on_standalone.p_value=popp_on_standalone;
   ctleat_blank_lines.p_value=eat_blank_lines;
   ctlbeautify_javascript.p_value=beautify_javascript;
   ctlbeautify_javascript.call_event(ctlbeautify_javascript,LBUTTON_UP);

   return;
}
static void oncreateSchemes(htmScheme_t *s_p)
{
   // Schemes
   gorig_scheme._makeempty();
   gorig_scheme_name="";
   _Schemes._makeempty();
   _UserSchemes._makeempty();

   // Get the last scheme used
   _str last_scheme="";
   if( _ini_get_value(FormatUserIniFilename(),gLangId:+"-scheme-":+HF_DEFAULT_SCHEME_NAME,"last_scheme",last_scheme) ) {
      last_scheme=HF_NONE_SCHEME_NAME;
   }
   // Save this for the Reset button
   gorig_scheme= *s_p;
   gorig_scheme_name=last_scheme;

   typeless i;
   boolean old_change_scheme=gchange_scheme;
   gchange_scheme=false;
   if( !_GetScheme(_Schemes,"",gLangId,false) ) {
      for( i._makeempty();; ) {
         _Schemes._nextel(i);
         if( i._isempty() ) break;
         ctlschemes_list._lbadd_item(i);
      }
   }
   if( !_GetUserScheme(_UserSchemes,"",gLangId,false) ) {
      for( i._makeempty();; ) {
         _UserSchemes._nextel(i);
         if( i._isempty() ) break;
         // We don't want to blast the default scheme because it is already set
         if( i!=HF_DEFAULT_SCHEME_NAME ) {
            ctlschemes_list._lbadd_item(i);
         }
      }
   }
   ctlschemes_list._lbsort();
   ctlschemes_list.p_text=last_scheme;
   ctlschemes_list.p_user=last_scheme;
   gchange_scheme=old_change_scheme;

   return;
}
typeless ctlgo.on_create(_str notused_arg1="", _str lang="", 
                         _str notused_arg3="", _str caption="")
{
   htmScheme_t scheme;
   htmScheme_t s:[];

   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }

   _html_beautify_form_initial_alignment();

   // arg(1) is historically the extension used to find the beautifier
   // form (e.g. CFML uses the HTML form, so arg(1)='html'.
   // arg(2) is the canonical language ID of the file being beautified.

   gchange_scheme=true;

   gorig_scheme._makeempty();
   gorig_scheme_name="";
   s._makeempty();

   int editorctl_wid=_form_parent();
   if ((editorctl_wid && !editorctl_wid._isEditorCtl()) ||
       (editorctl_wid._QReadOnly())) {
      editorctl_wid=0;
   }

   _str msg="";
   if( lang=="" ) {
      lang=_mdi.p_child.p_LangId;
   }
   if( lang=="" ) {
      msg="No buffer, read only buffer or unrecognized language.  Cannot continue.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_active_form._delete_window();
      return("");
   }
   gLangId=lang;
   if( !editorctl_wid ) ctlgo.p_enabled=false;

   // Sync with language options?
   typeless sync_lang_options=0;
   int status=_ini_get_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options,true);
   if( status ) sync_lang_options=true;
   ctlsync_ext_options.p_value=sync_lang_options;

   scheme._makeempty();
   _InitStyle(scheme.style,lang);
   // Guarantee that these atleast get set to the same value as "indent_amount"
   scheme.style:["tabsize"]= -1;
   scheme.style:["orig_tabsize"]= -1;
   _InitAllTags(scheme.tags,lang);
   _InitComments(scheme.comments,lang);
   s:[HF_DEFAULT_SCHEME_NAME]=scheme;
   _GetUserScheme(s,HF_DEFAULT_SCHEME_NAME,lang,sync_lang_options);
   scheme=s:[HF_DEFAULT_SCHEME_NAME];

   // Set the help by language
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      ctlhelp.p_help="XML Beautifier dialog box";
   } else {
      ctlhelp.p_help="HTML Beautifier dialog box";
   }

   gchange_scheme=false;
   oncreateIndent(&scheme);
   oncreateTags(&scheme);
   oncreateAttribs(&scheme);
   oncreateComments(&scheme);
   oncreateAdvanced(&scheme);
   oncreateSchemes(&scheme);
   gchange_scheme=true;

   // Remember the active tab
   ctlsstab._retrieve_value();
   //ctlsstab.p_ActiveTab=INDENTTAB;

   // Selection
   if( _mdi.p_child.select_active() ) {
      ctlselection_only.p_enabled=true;
      ctlselection_only.p_value=1;
   } else {
      ctlselection_only.p_enabled=false;
   }

   return(0);
}

static int _MyCheckTabs(int editorctl_wid,htmScheme_t *s_p)
{
   // Check to see if the current buffer's tab settings differ from the (syntax_indent && indent_with_tabs)
   if( s_p->style:["indent_with_tabs"] && editorctl_wid ) {
      typeless t1=0, t2=0;
      if( editorctl_wid.p_tabs!="" ) {
         parse editorctl_wid.p_tabs with t1 t2 .;
      }
      int interval=t2-t1;
      if( interval!=s_p->style:["tabsize"] ) {
         _str msg="Your current buffer's tab settings do not match your chosen tab size.\n\n":+
             "OK will change your current buffer's tab settings to match those you have chosen";
         int status=_message_box(msg,
                             "",
                             MB_OKCANCEL);
         if( status==IDOK ) {
            editorctl_wid.p_tabs='+':+s_p->style:["tabsize"];
         } else {
            return(1);
         }
      }
   }

   return(0);
}

void ctlgo.lbutton_up()
{
   // Save the user default and dialog settings
   typeless status=ctlsave.call_event(ctlsave,LBUTTON_UP);
   if( status ) {
      return;
   }

   // Check to see if the current buffer's tab settings matches the tab size chosen
   if( _MyCheckTabs(_form_parent(),&_UserSchemes:[HF_DEFAULT_SCHEME_NAME]) ) {
      return;
   }

   boolean selection= (ctlselection_only.p_enabled && ctlselection_only.p_value!=0);

   int editorctl_wid=_form_parent();
   p_active_form._delete_window();
   p_window_id=editorctl_wid;

   // save bookmark, breakpoint, and annotation information
   editorctl_wid._SaveBookmarksInFile(auto bmSaves);
   editorctl_wid._SaveBreakpointsInFile(auto bpSaves);
   editorctl_wid._SaveAnnotationsInFile(auto annoSaves);

   if( selection ) {
      h_beautify_selection(gLangId,&_UserSchemes:[HF_DEFAULT_SCHEME_NAME]);
   } else {
      h_beautify(0,0,gLangId,&_UserSchemes:[HF_DEFAULT_SCHEME_NAME]);
   }

   // restore bookmarks, breakpoints, and annotation locations
   editorctl_wid._RestoreBookmarksInFile(bmSaves);
   editorctl_wid._RestoreBreakpointsInFile(bpSaves);
   editorctl_wid._RestoreAnnotationsInFile(annoSaves);
   return;
}

void ctlgo.on_destroy()
{
   // Remember the active tab
   ctlsstab._append_retrieve(ctlsstab,ctlsstab.p_ActiveTab);

   // Cleanup
   _Schemes._makeempty();
   _UserSchemes._makeempty();

   return;
}

int ctlsave.lbutton_up()
{
   htmScheme_t scheme;

   boolean sync_lang_options= (ctlsync_ext_options.p_value!=0);

   MaybeCreateFormatUserIniFile();

   // Save the settings to [<gLangId>-scheme-Default] section of user schemes
   _str scheme_name="";
   scheme._makeempty();
   if( _GetFormScheme(&scheme,scheme_name) || _SaveScheme(&scheme,gLangId:+'-scheme-':+HF_DEFAULT_SCHEME_NAME,sync_lang_options) ) {
      return(1);
   }
   _UserSchemes:[HF_DEFAULT_SCHEME_NAME]=scheme;

   // Save the last scheme name used
   _ini_set_value(FormatUserIniFilename(),gLangId:+'-scheme-':+HF_DEFAULT_SCHEME_NAME,'last_scheme',scheme_name);

   /* Now write common options.  We do this after the call to _SaveScheme()
    * because _SaveScheme() gaurantees that the file will exist.
    */
   _ini_set_value(FormatUserIniFilename(),"common","sync_ext_options",sync_lang_options);

   // Remember the last tag selected
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      _append_retrieve(0,tagname,"_html_beautify_form.lasttag");
   }

   // Configuration was saved, so change the "Cancel" caption to "Close"
   ctlcancel.p_caption='Cl&ose';

   return(0);
}

void ctlreset.lbutton_up()
{
   // Remember the current tab and the tag list position
   typeless p;
   _str tagname="";
   typeless isline_selected=false;
   typeless old_tabinfo=ctlsstab.p_ActiveTab;
   int line=ctltag_list.p_line;
   if( line ) {
      tagname=ctltag_list._lbget_text();
      isline_selected=ctltag_list._lbisline_selected();
      ctltag_list.save_pos(p);
      old_tabinfo=old_tabinfo" "tagname" "isline_selected" "p;
   }

   gchange_scheme=false;
   ctlschemes_list.p_text=gorig_scheme_name;
   ctlschemes_list.p_user="";   // Set this so ctlschemes_list.on_change doesn't try to save old scheme
   oncreateIndent(&gorig_scheme);
   oncreateTags(&gorig_scheme);
   oncreateAttribs(&gorig_scheme);
   oncreateComments(&gorig_scheme);
   gchange_scheme=true;

   // Restore the current tab and the tag list pos
   typeless activetab=0;
   typeless rest="";
   parse old_tabinfo with activetab rest;
   ctlsstab.p_ActiveTab=activetab;
   if( rest!="" ) {
      parse rest with tagname isline_selected p;
      typeless status=ctltag_list._lbsearch(tagname);
      if( !status ) {
         // The previously active tag still exists, so restore list position
         ctltag_list.restore_pos(p);
         if( isline_selected ) ctltag_list._lbselect_line();
         ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
      }
   }

   return;
}

static void _ModifyScheme()
{
   if( !gchange_scheme ) return;

   gchange_scheme=false;
   _str name=ctlschemes_list.p_text;
   if( !pos("(Modified)",name,1,'i') && name!=HF_NONE_SCHEME_NAME ) {
      name=strip(name,'B'):+' (Modified)';
      ctlschemes_list.p_text=name;
      ctlschemes_list.p_user=name;
   }
   gchange_scheme=true;
}

void ctlindent.on_change()
{
   _ModifyScheme();

   return;
}
void ctlindent_with_tabs.lbutton_up()
{
   _ModifyScheme();

   return;
}
void ctl_brokentag_style_indent.lbutton_up()
{
   // Text box is enabled when radio button is checked
   ctl_brokentag_indent.p_enabled= (ctl_brokentag_style_indent.p_value!=0);

   _ModifyScheme();

   return;
}
void ctl_brokentag_indent.on_change()
{
   _ModifyScheme();

   return;
}
void ctltagcase_upper.lbutton_up()
{
   _ModifyScheme();

   return;
}
void ctlindent_comments.lbutton_up()
{
   _ModifyScheme();

   return;
}
void ctltcomment_col_enable.lbutton_up()
{
   // Text box is enabled when radio button is checked
   ctltcomment_col.p_enabled= (ctltcomment_col_enable.p_value!=0);

   _ModifyScheme();

   return;
}
void ctltcomment_col.on_change()
{
   _ModifyScheme();

   return;
}
void ctldefine_comments.lbutton_up()
{
   typeless comments[];

   comments=p_user;
   typeless status=show("-modal _html_beautify_comments_form","HTML Comments",&comments);
   if( status=="" || status ) {
      // User cancelled or something went wrong
      return;
   }
   p_user=comments;
   _ModifyScheme();

   return;
}

void ctltag_list.on_change()
{
   typeless tags:[];
   typeless tag:[];
   _str tagname="";
   _str msg="";
   typeless reformat_content=false;
   typeless indent_content=false;
   typeless literal_content=false;
   typeless endtag=false;
   typeless endtag_required=false;
   typeless preserve_body=false;
   typeless preserve_position=false;
   typeless standalone=false;
   int noflines_before=0;
   int noflines_after=0;

   if( p_Nofselected ) {
      tagname=_lbget_text();
      if( tagname!="" ) {
         tags=p_user;
         if( !tags._indexin(tagname) ) {
            // This should never happen
            msg='Invalid tag entry for "':+tagname:+'"';
            _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
            return;
         }
         tag=tags:[tagname];
         // Content
         reformat_content= (tag._indexin("reformat_content") && tag:["reformat_content"]);
         if( _LanguageInheritsFrom('xml',gLangId) ) {
            // XML:
            // indent_content value allowed and valid even when reformat_content is false.
            indent_content= (tag._indexin("indent_content") && tag:["indent_content"]);
         } else {
            indent_content= (reformat_content && tag._indexin("indent_content") && tag:["indent_content"]);
         }
         literal_content= (tag._indexin("literal_content") && tag:["literal_content"]);

         endtag= (!tag._indexin("endtag") || tag:["endtag"]);
         endtag_required= (endtag && tag._indexin("endtag_required") && tag:["endtag_required"]);
         preserve_body= (!tag._indexin("preserve_body") || tag:["preserve_body"]);
         preserve_position= (!tag._indexin("preserve_position") || tag:["preserve_position"]);

         standalone= (!tag._indexin("standalone") || tag:["standalone"]);
         noflines_before=tag:["noflines_before"];
         if( !isinteger(noflines_before) || noflines_before<0 ) {
            noflines_before=0;
         } else if( standalone && noflines_before==0 ) {
            // Standalone implies atleast 1 blank line before open tag
            noflines_before=1;
         }
         noflines_after=tag:["noflines_after"];
         if( !isinteger(noflines_after) || noflines_after<0 ) {
            noflines_after=0;
         } else if( standalone && noflines_after==0 ) {
            // Standalone implies atleast 1 blank line after close tag
            noflines_after=1;
         }

         ctlreformat_content.p_enabled=true;
         ctlindent_content.p_enabled=true;
         ctlliteral_content.p_enabled=true;
         ctlendtag.p_enabled=true;
         ctlendtag_required.p_enabled=true;
         ctlpreserve_body.p_enabled=true;
         ctlpreserve_position.p_enabled=true;
         ctlstandalone.p_enabled=true;
         ctlnoflines_before.p_enabled=true;
         ctlnoflines_after.p_enabled=true;
         ctlremove_tag.p_enabled=true;

         ctlreformat_content.p_value=reformat_content;
         ctlindent_content.p_value=indent_content;
         ctlindent_content.p_enabled= (_LanguageInheritsFrom('xml',gLangId) || ctlreformat_content.p_value!=0);
         ctlliteral_content.p_value=literal_content;

         ctlendtag.p_value=endtag;
         ctlendtag_required.p_value=endtag_required;
         ctlendtag_required.p_enabled= (ctlendtag.p_value!=0);
         ctlpreserve_body.p_value=preserve_body;
         ctlpreserve_position.p_value=preserve_position;

         ctlstandalone.p_value=standalone;
         ctlstandalone.p_enabled= (ctlpreserve_position.p_value==0);
         // Linebreaks before open tag
         ctlnoflines_before.p_ReadOnly=false;
         ctlnoflines_before.p_text=noflines_before;
         ctlnoflines_before.p_ReadOnly=true;
         ctlnoflines_before.p_enabled= (ctlpreserve_position.p_value==0);
         // Linebreaks after close tag
         ctlnoflines_after.p_ReadOnly=false;
         ctlnoflines_after.p_text=noflines_after;
         ctlnoflines_after.p_ReadOnly=true;
         ctlnoflines_after.p_enabled= (ctlpreserve_position.p_value==0);
      }
   } else {
      // No tag selected, so gray out options
      ctlreformat_content.p_enabled=false;
      ctlindent_content.p_enabled=false;
      ctlliteral_content.p_enabled=false;
      ctlendtag.p_enabled=false;
      ctlendtag_required.p_enabled=false;
      ctlpreserve_body.p_enabled=false;
      ctlpreserve_position.p_enabled=false;
      ctlstandalone.p_enabled=false;
      ctlnoflines_before.p_enabled=false;
      ctlnoflines_after.p_enabled=false;
      ctlremove_tag.p_enabled=false;
   }

   return;
}
void ctltag_list.'!'-'~'()
{
   boolean found_one;

   found_one=true;

   _str event=last_event();
   if( length(event)!=1 ) {
      return;
   }
   int old_line=p_line;
   _lbdeselect_all();
   int status=search('^(\>| )'event,'ir@');
   if( status ) {
      // String not found, so try it from the top
      save_pos(auto p);
      _lbtop();
      status=repeat_search();
      if( status ) {
         // String not found, so restore to previous line
         restore_pos(p);
         found_one=false;
      }
   } else {
      if( old_line==p_line && p_line!=p_Noflines ) {
         // On the same line, so find next occurrence
         status=repeat_search();
         if( status ) {
            // String not found, so try it from the top
            _lbtop();
            status=repeat_search();
         }
         if( status ) {
            // String not found
            found_one=false;
         }
      }
   }
   _lbselect_line();

   if( found_one ) {
      ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
   }

   return;
}

void ctlreformat_content.lbutton_up()
{
   typeless tags:[];

   ctlindent_content.p_enabled= (_LanguageInheritsFrom('xml',gLangId) || p_value!=0);
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["reformat_content"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlindent_content.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["indent_content"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlliteral_content.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["literal_content"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}

void ctlendtag.lbutton_up()
{
   typeless tags:[];

   ctlendtag_required.p_enabled= (p_value!=0);
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["endtag"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlendtag_required.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["endtag_required"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlpreserve_body.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["preserve_body"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlpreserve_position.lbutton_up()
{
   typeless tags:[];

   ctlstandalone.p_enabled= (p_value==0);
   ctlnoflines_before.p_enabled= (p_value==0);
   ctlnoflines_after.p_enabled= (p_value==0);
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["preserve_position"]= (p_value!=0);
      ctltag_list.p_user=tags;
   }

   return;
}

void ctlstandalone.lbutton_up()
{
   typeless tags:[];

   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["standalone"]= (p_value!=0);
      typeless noflines_before=ctlnoflines_before.p_text;
      typeless noflines_after=ctlnoflines_after.p_text;
      if( p_value ) {
         if( !isinteger(noflines_before) || noflines_before<1 ) {
            ctlnoflines_before.p_ReadOnly=false;
            ctlnoflines_before.p_text=1;
            ctlnoflines_before.p_ReadOnly=true;
            tags:[tagname]:["noflines_before"]=1;
         }
         if( !isinteger(noflines_after) || noflines_after<1 ) {
            ctlnoflines_after.p_ReadOnly=false;
            ctlnoflines_after.p_text=1;
            ctlnoflines_after.p_ReadOnly=true;
            tags:[tagname]:["noflines_after"]=1;
         }
      }
      ctltag_list.p_user=tags;
   }

   return;
}
void ctlnoflines_before_spin.on_spin_up()
{
   typeless tags:[];

   boolean standalone= (ctlstandalone.p_value!=0);
   typeless noflines_before=ctlnoflines_before.p_text;
   if( !isinteger(noflines_before) || noflines_before<0 ) {
      noflines_before=0;
      if( standalone ) ++noflines_before;
   } else {
      ++noflines_before;
   }
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["noflines_before"]=noflines_before;
      ctltag_list.p_user=tags;
   }
   ctlnoflines_before.p_ReadOnly=false;
   ctlnoflines_before.p_text=noflines_before;
   ctlnoflines_before.p_ReadOnly=true;

   return;
}
void ctlnoflines_before_spin.on_spin_down()
{
   typeless tags:[];

   boolean standalone= (ctlstandalone.p_value!=0);
   typeless noflines_before=ctlnoflines_before.p_text;
   if( !isinteger(noflines_before) || noflines_before<=0 ) {
      noflines_before=0;
      if( standalone ) ++noflines_before;
   } else {
      --noflines_before;
      if( standalone && noflines_before<1 ) noflines_before=1;
   }
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["noflines_before"]=noflines_before;
      ctltag_list.p_user=tags;
   }
   ctlnoflines_before.p_ReadOnly=false;
   ctlnoflines_before.p_text=noflines_before;
   ctlnoflines_before.p_ReadOnly=true;

   return;
}
void ctlnoflines_after_spin.on_spin_up()
{
   typeless tags:[];

   boolean standalone= (ctlstandalone.p_value!=0);
   typeless noflines_after=ctlnoflines_after.p_text;
   if( !isinteger(noflines_after) || noflines_after<0 ) {
      noflines_after=0;
      if( standalone ) ++noflines_after;
   } else {
      ++noflines_after;
   }
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["noflines_after"]=noflines_after;
      ctltag_list.p_user=tags;
   }
   ctlnoflines_after.p_ReadOnly=false;
   ctlnoflines_after.p_text=noflines_after;
   ctlnoflines_after.p_ReadOnly=true;

   return;
}
void ctlnoflines_after_spin.on_spin_down()
{
   typeless tags:[];

   boolean standalone= (ctlstandalone.p_value!=0);
   typeless noflines_after=ctlnoflines_after.p_text;
   if( !isinteger(noflines_after) || noflines_after<=0 ) {
      noflines_after=0;
      if( standalone ) ++noflines_after;
   } else {
      --noflines_after;
      if( standalone && noflines_after<1 ) noflines_after=1;
   }
   _ModifyScheme();
   _str tagname=ctltag_list._lbget_text();
   if( tagname!="" ) {
      tags=ctltag_list.p_user;
      tags:[tagname]:["noflines_after"]=noflines_after;
      ctltag_list.p_user=tags;
   }
   ctlnoflines_after.p_ReadOnly=false;
   ctlnoflines_after.p_text=noflines_after;
   ctlnoflines_after.p_ReadOnly=true;

   return;
}

void ctladd_tag.lbutton_up()
{
   typeless tags:[];

   //status=show("-modal _textbox_form","Add Tag",0,"","?Type in the name of the tag you want to add without <>","","","Tag");
   typeless status=show("-modal _html_beautify_add_tag_form");
   if( status=="" ) {
      // User probably cancelled
      return;
   }
   typeless result=_param1;
   if( result=="" ) {
      return;
   }

   int wid=0;
   _str msg="";
   _str tag_filename="";
   _str tagname="";
   _str tag_type="";
   _str file_name="";
   _str class_name="";
   int line_no=0;
   int tag_flags=0;

   _str list[];
   list._makeempty();
   if( upcase(result)=='.DTD.' ) {
      // User wants us to get tags from current file's DTD
      wid=_mdi.p_child;
      if( !wid._isEditorCtl() || !wid._LanguageInheritsFrom('xml') || substr(wid.p_mode_name,1,3)!='XML' ) {
         msg="No DTD specified or cannot get elements from DTD";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      tag_filename=wid._xml_GetConfigTagFile();
      if( tag_filename!="" ) {
         tag_close_db(tag_filename);
         status=tag_read_db(tag_filename);
         if( status >= 0 ) {
            status=tag_find_global(VS_TAGTYPE_tag,0,0);
            while( !status ) {
               tag_get_info(tagname,tag_type,file_name,line_no,class_name,tag_flags);
               list[list._length()]=tagname;
               status=tag_next_global(VS_TAGTYPE_tag,0,0);
            }
            tag_reset_find_in_class();
         }
      }
      tag_close_db(tag_filename);
   } else {
      // One or more tags in a space-delimited list
      while( result!="" ) {
         parse result with tagname result;
         tagname=strip(tagname,'L','<');
         tagname=strip(tagname,'T','>');
         if( '<'upcase(tagname)'>':==HF_DEFAULT_TAG_NAME ) continue;
         if( !_LanguageInheritsFrom('xml',gLangId) ) tagname=upcase(tagname);
         list[list._length()]=tagname;
      }
   }
   list._sort();

   int i;
   tags=ctltag_list.p_user;
   for( i=0;i<list._length();++i ) {
      tagname=list[i];
      if( tags._indexin(tagname) ) {
         msg='Tag "':+tagname:+'" already exists. Do you want to replace it?';
         status=_message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
         if( status!=IDYES ) {
            list._deleteel(i);
            continue;
         }
      }
      _InitTag(tagname,tags,gLangId);
   }
   ctltag_list.p_user=tags;

   _str line="";
   for( i=0;i<list._length();++i ) {
      tagname=list[i];
      status=ctltag_list._lbsearch(tagname,'e');
      if( status ) {
         // It is not in the list, so put it there sorted
         ctltag_list._lbtop();
         line=ctltag_list._lbget_text();
         // Do not allow user to remove the default tag
         if( line:==HF_DEFAULT_TAG_NAME ) ctltag_list._lbdown();
         for(;;) {
            line=ctltag_list._lbget_text();
            if( tagname:<line ) {
               ctltag_list._lbup();
               ctltag_list._lbadd_item(tagname);
               break;
            }
            if( ctltag_list._lbdown() ) {
               ctltag_list._lbadd_item(tagname);
               break;
            }
         }
      }
   }

   _ModifyScheme();

   // Select the first tag in the list
   tagname="";
   if( list._length() ) tagname=list[0];
   ctltag_list._lbsearch(tagname,'e');
   ctltag_list._lbdeselect_all();
   ctltag_list._lbselect_line();
   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");

   return;
}
void ctlremove_tag.lbutton_up()
{
   typeless tags:[];
   _str tagname="";

   if( !ctltag_list.p_Nofselected ) {
      return;
   }

   tags=ctltag_list.p_user;
   #if 1
   typeless status=ctltag_list._lbfind_selected(1);
   while( !status ) {
      tagname=ctltag_list._lbget_text();
      if( tagname!="" && tagname!=HF_DEFAULT_TAG_NAME ) {
         tags._deleteel(tagname);
         ctltag_list._lbdelete_item();
         ctltag_list._lbup();
      }
      status=ctltag_list._lbfind_selected(0);
   }
   ctltag_list.p_user=tags;
   ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE,"W");
   #else
   tagname=ctltag_list._lbget_seltext();
   if( tagname!="" ) {
      if( tagname:==HF_DEFAULT_TAG_NAME ) {
         msg="Cannot remove the default tag";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      tags=ctltag_list.p_user;
      tags._deleteel(tagname);
      ctltag_list.p_user=tags;
      ctltag_list._lbdelete_item();
      ctltag_list.call_event(CHANGE_OTHER,ctltag_list,ON_CHANGE);
   }
   #endif

   _ModifyScheme();

   return;
}

void ctlattribcase_upper.lbutton_up()
{
   _ModifyScheme();

   return;
}

void ctl_quote_all_vals.lbutton_up()
{
   boolean enable= (_LanguageInheritsFrom('xml',gLangId) && p_value==0);
   ctl_quote_wordval_frame.p_enabled=enable;
   _enable_children(ctl_quote_wordval_frame,enable);
   ctl_quote_numval_frame.p_enabled=enable;
   _enable_children(ctl_quote_numval_frame,enable);
}

void ctlpopp_on_p.lbutton_up()
{
   _ModifyScheme();

   return;
}

void ctlbeautify_javascript.lbutton_up()
{
   ctljavascript_settings.p_enabled= (p_value!=0);

   _ModifyScheme();

   return;
}

void ctljavascript_settings.lbutton_up()
{
   int index=find_index("_c_beautify_form",oi2type(OI_FORM));
   if( !index ) {
      _str msg="Can't find form: ":+"_c_beautify_form";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   // arg(3) forces _c_beautify_form to gray out the "Beautify" button
   show("-modal "index,"js","js",1);

   return;
}

static int _GetIndent(htmScheme_t *s_p)
{
   _str msg="";
   typeless indent_amount=ctlindent.p_text;
   if( !isinteger(indent_amount) || indent_amount<0 ) {
      msg="Invalid indent amount";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlindent;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless tabsize=ctltabsize.p_text;
   if( !isinteger(tabsize) || tabsize<0 ) {
      msg="Invalid tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctltabsize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless orig_tabsize=ctlorig_tabsize.p_text;
   if( !isinteger(orig_tabsize) || orig_tabsize<0 ) {
      msg="Invalid original tab size";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlorig_tabsize;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless indent_with_tabs= (ctlindent_with_tabs.p_value!=0);
   typeless max_line_length= (ctlmax_line_length.p_text);
   if( !isinteger(max_line_length) || max_line_length<0 ) {
      msg="Invalid maximum line length";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlmax_line_length;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return(1);
   }
   typeless brokentag_style=0;
   typeless brokentag_indent=ctl_brokentag_indent.p_text;
   if( ctl_brokentag_style_indent.p_value ) {
      brokentag_style=BROKENTAG_STYLE_INDENT;
      if( !isinteger(brokentag_indent) || brokentag_indent<0 ) {
         msg="Invalid indent amount for broken tag lines.";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctl_brokentag_indent;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return(1);
      }
   } else if( ctl_brokentag_style_rel.p_value ) {
      brokentag_style=BROKENTAG_STYLE_REL;
   } else if( ctl_brokentag_style_preserve.p_value ) {
      brokentag_style=BROKENTAG_STYLE_PRESERVE;
   } else {
      // This should never happen
      msg="You must choose an option for broken tag lines.";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctltcomment_col_enable;
      _set_focus();
      return(1);
   }
   if( !isinteger(brokentag_indent) || brokentag_indent<0 ) {
      brokentag_indent=0;
   }

   s_p->style:["indent_amount"]=indent_amount;
   s_p->style:["tabsize"]=tabsize;
   s_p->style:["orig_tabsize"]=orig_tabsize;
   s_p->style:["indent_with_tabs"]=indent_with_tabs;
   s_p->style:["max_line_length"]=max_line_length;
   s_p->style:["brokentag_style"]=brokentag_style;
   s_p->style:["brokentag_indent"]=brokentag_indent;

   return(0);
}
static int _GetTags(htmScheme_t *s_p)
{
   typeless tags:[];
   int tagcase=0;

   if( ctltagcase_upper.p_value ) {
      tagcase=WORDCASE_UPPER;
   } else if( ctltagcase_lower.p_value ) {
      tagcase=WORDCASE_LOWER;
   } else if( ctltagcase_capitalize.p_value ) {
      tagcase=WORDCASE_CAPITALIZE;
   } else if( ctltagcase_preserve.p_value ) {
      tagcase=WORDCASE_PRESERVE;
   } else {
      _str msg="Must choose tag case";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctltagcase_upper;
      _set_focus();
      return(1);
   }
   tags=ctltag_list.p_user;

   s_p->style:["tagcase"]=tagcase;

   s_p->tags=tags;

   return(0);
}
static int _GetAttribs(htmScheme_t *s_p)
{
   _str msg="";
   int attribcase=0;
   if( ctlattribcase_upper.p_value ) {
      attribcase=WORDCASE_UPPER;
   } else if( ctlattribcase_lower.p_value ) {
      attribcase=WORDCASE_LOWER;
   } else if( ctlattribcase_capitalize.p_value ) {
      attribcase=WORDCASE_CAPITALIZE;
   } else if( ctlattribcase_preserve.p_value ) {
      attribcase=WORDCASE_PRESERVE;
   } else {
      msg="Must choose attribute case";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlattribcase_upper;
      _set_focus();
      return(1);
   }

   typeless wordvalcase=WORDCASE_PRESERVE;
   typeless hexvalcase=WORDCASE_PRESERVE;
   typeless quote_wordval=HFPRESERVE;
   typeless quote_numval=HFPRESERVE;
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      wordvalcase=WORDCASE_PRESERVE;
      hexvalcase=WORDCASE_PRESERVE;
      quote_wordval=HFPRESERVE;
      quote_numval=HFPRESERVE;
   } else {
      if( ctlwordcase_upper.p_value ) {
         wordvalcase=WORDCASE_UPPER;
      } else if( ctlwordcase_lower.p_value ) {
         wordvalcase=WORDCASE_LOWER;
      } else if( ctlwordcase_capitalize.p_value ) {
         wordvalcase=WORDCASE_CAPITALIZE;
      } else if( ctlwordcase_preserve.p_value ) {
         wordvalcase=WORDCASE_PRESERVE;
      } else {
         msg="Must choose word value case";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctlwordcase_upper;
         _set_focus();
         return(1);
      }

      if( ctlhexcase_upper.p_value ) {
         hexvalcase=WORDCASE_UPPER;
      } else if( ctlhexcase_lower.p_value ) {
         hexvalcase=WORDCASE_LOWER;
      } else if( ctlhexcase_preserve.p_value ) {
         hexvalcase=WORDCASE_PRESERVE;
      } else {
         msg="Must choose hex value case";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctlhexcase_upper;
         _set_focus();
         return(1);
      }

      if( ctl_quote_wordval_yes.p_value ) {
         quote_wordval=1;
      } else if( ctl_quote_wordval_no.p_value ) {
         quote_wordval=0;
      } else if( ctl_quote_wordval_preserve.p_value ) {
         quote_wordval= HFPRESERVE;
      } else {
         msg="Must choose option for Quote word values";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }

      if( ctl_quote_numval_yes.p_value ) {
         quote_numval=1;
      } else if( ctl_quote_numval_no.p_value ) {
         quote_numval=0;
      } else if( ctl_quote_numval_preserve.p_value ) {
         quote_numval= HFPRESERVE;
      } else {
         msg="Must choose option for Quote number values";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return(1);
      }
   }

   boolean quote_all_vals= (ctl_quote_all_vals.p_value!=0);

   s_p->style:["attribcase"]=attribcase;
   s_p->style:["wordvalcase"]=wordvalcase;
   s_p->style:["hexvalcase"]=hexvalcase;
   s_p->style:["quote_wordval"]=quote_wordval;
   s_p->style:["quote_numval"]=quote_numval;
   s_p->style:["quote_all_vals"]=quote_all_vals;

   return(0);
}
static int _GetComments(htmScheme_t *s_p)
{
   _str msg="";
   typeless comments[];

   typeless tcomment=0;
   typeless indent_comments= (ctlindent_comments.p_value!=0);
   typeless indent_col1_comments= (ctlindent_col1_comments.p_value!=0);
   typeless tcomment_col=ctltcomment_col.p_text;
   if( ctltcomment_col_enable.p_value ) {
      tcomment=TCOMMENT_COLUMN;
      if( !isinteger(tcomment_col) || tcomment_col<1 ) {
         msg="Invalid trailing comment column";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_window_id=ctltcomment_col;
         _set_sel(1,length(p_text)+1);
         _set_focus();
         return(1);
      }
   } else if( ctltcomment_absolute.p_value ) {
      tcomment=TCOMMENT_ABSOLUTE;
   } else if( ctltcomment_relative.p_value ) {
      tcomment=TCOMMENT_RELATIVE;
   } else {
      // This should never happen
      msg="You must choose a trailing comment style";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctltcomment_col_enable;
      _set_focus();
      return(1);
   }
   if( !isinteger(tcomment_col) || tcomment_col<1 ) {
      tcomment_col=0;
   }
   comments=ctldefine_comments.p_user;

   s_p->style:["indent_comments"]=indent_comments;
   s_p->style:["indent_col1_comments"]=indent_col1_comments;
   s_p->style:["tcomment"]=tcomment;
   s_p->style:["tcomment_col"]=tcomment_col;
   s_p->comments=comments;

   return(0);
}
static int _GetAdvanced(htmScheme_t *s_p)
{
   typeless popp_on_p=false;
   typeless popp_on_standalone=false;
   typeless eat_blank_lines= false;
   typeless beautify_javascript=false;

   if( _LanguageInheritsFrom('xml',gLangId) ) {
      popp_on_p=false;
      popp_on_standalone=false;
      eat_blank_lines= (ctleat_blank_lines.p_value!=0);
      beautify_javascript=false;
   } else {
      popp_on_p= (ctlpopp_on_p.p_value!=0);
      popp_on_standalone= (ctlpopp_on_standalone.p_value!=0);
      eat_blank_lines= (ctleat_blank_lines.p_value!=0);
      beautify_javascript= (ctlbeautify_javascript.p_value!=0);
   }

   s_p->style:["popp_on_p"]=popp_on_p;
   s_p->style:["popp_on_standalone"]=popp_on_standalone;
   s_p->style:["eat_blank_lines"]=eat_blank_lines;
   s_p->style:["beautify_javascript"]=beautify_javascript;

   return(0);
}
static int _GetFormScheme(htmScheme_t *s_p,_str &scheme_name)
{
   typeless status=_GetIndent(s_p);
   if( status ) return(status);
   status=_GetTags(s_p);
   if( status ) return(status);
   status=_GetAttribs(s_p);
   if( status ) return(status);
   status=_GetComments(s_p);
   if( status ) return(status);
   status=_GetAdvanced(s_p);
   if( status ) return(status);
   scheme_name=ctlschemes_list.p_text;

   return(0);
}

int ctlsave_scheme.lbutton_up(typeless do_rename_arg="")
{
   htmScheme_t scheme;

   _str old_name=ctlschemes_list.p_text;
   if( old_name==HF_NONE_SCHEME_NAME ) {
      old_name="";
   } else if( pos("(Modified)",old_name,1,'i') ) {
      parse old_name with old_name '(Modified)';
   }

   boolean do_rename= (do_rename_arg!="");

   if( do_rename && !_UserSchemes._indexin(old_name) ) {
      _message_box(nls('Cannot find user scheme "%s".  System schemes cannot be renamed',old_name));
      return(1);
   }

   // Prompt user for name of scheme
   _str system_schemes=' "'HF_DEFAULT_SCHEME_NAME'" ';
   typeless i;
   for( i._makeempty();; ) {
      _Schemes._nextel(i);
      if( i._isempty() ) break;
      system_schemes=system_schemes:+' "'i'" ';
   }
   _str user_schemes='';
   for( i._makeempty();; ) {
      _UserSchemes._nextel(i);
      if( i._isempty() ) break;
      if( i==HF_DEFAULT_SCHEME_NAME ) continue;
      user_schemes=user_schemes:+' "'i'" ';
   }
   _str name=show("-modal _beautify_save_scheme_form",old_name,do_rename,system_schemes,user_schemes);
   if( name=="" ) {
      // User cancelled
      return(0);
   }

   MaybeCreateFormatUserIniFile();

   typeless status=0;
   if( do_rename ) {
      // Delete the existing scheme
      _UserSchemes._deleteel(old_name);
      _ini_delete_section(FormatUserIniFilename(),gLangId:+'-scheme-':+old_name);
      ctlschemes_list._lbfind_and_delete_item(old_name,'i');
      ctlschemes_list._lbtop();
   }

   // Save the user settings to [[lang]-scheme-<scheme name>] section of user schemes
   scheme._makeempty();
   typeless dummy;
   if( _GetFormScheme(&scheme,dummy) || _SaveScheme(&scheme,gLangId:+'-scheme-'name,false) ) {
      _message_box('Failed to write scheme to "':+FormatUserIniFilename():+'"');
      return(1);
   }
   boolean old_gchange_scheme=gchange_scheme;
   gchange_scheme=false;
   ctlschemes_list._lbadd_item_no_dupe(name, 'i', LBADD_SORT, true);
   ctlschemes_list.p_user="";   // Set this so ctlschemes_list.on_change doesn't try to save old scheme
   gchange_scheme=old_gchange_scheme;
   _UserSchemes:[name]=scheme;

   return(0);
}

void ctldelete_scheme.lbutton_up()
{
   _str msg="";
   _str old_name=ctlschemes_list.p_text;
   if( old_name==HF_NONE_SCHEME_NAME ) {
      msg="Cannot remote empty scheme";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   } else if( !_UserSchemes._indexin(old_name) ) {
      msg=nls('Cannot find user scheme "%s".  System schemes cannot be removed',old_name);
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   MaybeCreateFormatUserIniFile();

   // Delete the existing scheme
   _UserSchemes._deleteel(old_name);
   _ini_delete_section(FormatUserIniFilename(),gLangId:+'-scheme-':+old_name);
   gchange_scheme=false;
   ctlschemes_list._lbfind_and_delete_item(old_name,'i');
   ctlschemes_list._lbtop();
   ctlschemes_list.p_text=HF_NONE_SCHEME_NAME;
   ctlschemes_list.p_user="";   // Set this so ctlschemes_list.on_change doesn't try to save old scheme
   gchange_scheme=true;

   return;
}

void ctlrename_scheme.lbutton_up()
{
   call_event(1,ctlsave_scheme,LBUTTON_UP,'W');

   return;
}

void ctlschemes_list.on_change(int reason)
{
   htmScheme_t *scheme_p;

   if( !gchange_scheme ) return;

   // Yes, changing things in an on_change() can cause more on_change events
   typeless status=0;
   _str msg="";
   _str name="";
   _str old_name="";
   gchange_scheme=false;
   // Use this loop for easy error handling (like a goto)
   for(;;) {
      name=p_text;
      //old_name=gorig_scheme_name;
      old_name=p_user;
      // IF name has not changed OR no scheme chosen
      if( name==old_name || name==HF_NONE_SCHEME_NAME ) {
         break;
      }
      if( !_Schemes._indexin(name) && !_UserSchemes._indexin(name) ) {
         msg='The scheme "':+name:+'" is empty';
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         p_text=old_name;
         break;
      } else {
         if( pos("(Modified)",old_name,1,'i') ) {
            msg="You have a modified scheme.\n":+
                "Do you wish to save it?";
            status=_message_box(msg,"",MB_YESNOCANCEL|MB_ICONQUESTION);
            if( status==IDCANCEL ) {
               p_text=old_name;
               break;
            } else if( status==IDYES ) {
               p_text=old_name;   // Put the old name in so we know which scheme to save
               status=call_event(ctlsave_scheme,LBUTTON_UP);
               if( status ) {
                  // There was a problem, so do not put the new name back in its place
                  break;
               }
               ctlschemes_list.p_text=name;   // Put it back
            }

         }

         scheme_p=_Schemes._indexin(name);
         if( !scheme_p ) {
            scheme_p=_UserSchemes._indexin(name);
         }
         oncreateIndent(scheme_p);
         oncreateTags(scheme_p);
         oncreateAttribs(scheme_p);
         oncreateComments(scheme_p);
      }
      break;
   }
   p_user=name;
   gchange_scheme=true;

   return;
}

defeventtab _html_beautify_comments_create_form;
void ctlok.on_create(_str caption="", typeless userData=null)
{
   typeless comment:[];

   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }
   comment._makeempty();
   p_user=0;
   if( arg()>1 ) {
      comment= *((typeless *)userData);
      p_user=userData;
   }
   _str startstr="";
   _str endstr="";
   typeless nesting=false;
   typeless type=HFCOMMENT_MULTILINE;
   if( !comment._isempty() ) {
      type=comment:["type"];
      if( type==HFCOMMENT_MULTILINE ) {
         startstr=comment:["startstr"];
         endstr=comment:["endstr"];
         nesting= (comment:["nesting"]!=0);
      } else if( type==HFCOMMENT_LINE ) {
         startstr=comment:["startstr"];
         endstr="";
         nesting=false;
      }
   }
   ctlstart_delim.p_text=startstr;
   ctlend_delim.p_text=endstr;
   ctlnesting.p_value=nesting;
   boolean enable= (type==HFCOMMENT_MULTILINE);
   ctlend_delim_label.p_enabled=enable;
   ctlend_delim.p_enabled=enable;
   ctlnesting.p_enabled=enable;

   return;
}

void ctlok.lbutton_up()
{
   _str msg="";
   typeless *p;

   typeless type=HFCOMMENT_MULTILINE;
   if( !ctlend_delim.p_enabled ) {
      type=HFCOMMENT_LINE;
   }
   _str startstr=ctlstart_delim.p_text;
   if( startstr=="" ) {
      msg="Must specify a starting delimiter";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlstart_delim;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return;
   }
   _str endstr=ctlend_delim.p_text;
   if( type==HFCOMMENT_MULTILINE && endstr=="" ) {
      msg="Must specify an ending delimiter";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      p_window_id=ctlend_delim;
      _set_sel(1,length(p_text)+1);
      _set_focus();
      return;
   }
   boolean nesting= (ctlnesting.p_enabled && ctlnesting.p_value!=0);

   p=p_user;
   if( p ) {
      (*p):["startstr"]=startstr;
      (*p):["endstr"]=endstr;
      (*p):["nesting"]=nesting;
   }

   p_active_form._delete_window(0);

   return;
}

void ctlcancel.lbutton_up()
{
   p_active_form._delete_window("");

   return;
}

defeventtab _html_beautify_comments_type_form;
void ctlok.on_create(typeless nofmlcomments="")
{
   if( !isinteger(nofmlcomments) ) {
      nofmlcomments=0;
   }
   if( nofmlcomments>=HFMAX_MLCOMMENTS ) {
      ctlmulti.p_enabled=false;
   }

   return;
}

void _html_beautify_comments_type_form.on_load()
{
   ctlmulti.p_value=0;
   ctlline.p_value=0;

   return;
}

void ctlok.lbutton_up()
{
   if( ctlmulti.p_value ) {
      p_active_form._delete_window(HFCOMMENT_MULTILINE);
   } else if( ctlline.p_value ) {
      p_active_form._delete_window(HFCOMMENT_LINE);
   } else {
      _str msg='Must choose either "MultiLine" or "Line" comment';
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   }

   return;
}

void ctlcancel.lbutton_up()
{
   p_active_form._delete_window("");

   return;
}

defeventtab _html_beautify_comments_form;
// This expects the current object to be a list box
static void _FillCommentList(typeless comments[])
{
   _lbclear();
   _str startstr="";
   _str endstr="";
   _str line="";
   typeless nesting=false;
   typeless comment;
   typeless type="";
   int i;
   for( i=0;i<comments._length();++i ) {
      comment=comments[i];
      type=comment:["type"];
      if( type==HFCOMMENT_MULTILINE ) {
         startstr=comment:["startstr"];
         endstr=comment:["endstr"];
         nesting=comment:["nesting"]!=0;
         line="MultiLine":+"\t":+startstr:+"\t"endstr;
      } else if( type==HFCOMMENT_LINE ) {
         startstr=comment:["startstr"];
         endstr="";
         nesting=false;
         line="LineComment":+"\t":+startstr;
      } else {
         continue;
      }
      _lbadd_item(line);
   }
   _lbsort('D');
   _col_width(0,1200);
   _col_width(1,500);
   _col_width(2,500);

   return;
}
void ctlok.on_create(_str caption="", typeless userData=null)
{
   typeless comments[];
   typeless comment:[];

   if( caption!="" ) {
      p_active_form.p_caption=caption;
   }
   // If there is no pointer to an array of comments passed in, then the results go to nowhere's land
   p_user=0;
   comments._makeempty();
   if( arg()>1 ) {
      comments= *((typeless *)userData);
      p_user=userData;
   }
   ctlcomment_list._FillCommentList(comments);
   ctlcomment_list._lbtop();
   ctlcomment_list._lbselect_line();

   ctlcomment_list.call_event(CHANGE_OTHER,ctlcomment_list,ON_CHANGE,"W");

   return;
}

void ctlok.lbutton_up()
{
   p_active_form._delete_window(0);

   return;
}

void ctledit.lbutton_up()
{
   typeless *p;
   typeless comment:[];
   _str msg="";

   _str line=ctlcomment_list._lbget_text();
   if( line=="" ) {
      // This should never happen
      return;
   }
   typeless was_selected=false;
   typeless nesting=0;
   typeless type=0;
   _str startstr="";
   _str endstr="";
   parse line with type "\t" startstr "\t" endstr;
   if( type=="MultiLine" ) {
      type=HFCOMMENT_MULTILINE;
   } else {
      type=HFCOMMENT_LINE;
   }
   // Now find it in the list
   int i=0;
   comment._makeempty();
   p=ctlok.p_user;
   if( p ) {
      for( i=0;(*p)._length();++i ) {
         typeless t=(*p)[i]:["type"];
         typeless s=(*p)[i]:["startstr"];
         if( t==type && s==startstr ) {
            // Found it
            comment=(*p)[i];
            break;
         }
      }
   }
   _str caption="";
   if( type==HFCOMMENT_MULTILINE ) {
      caption="Edit MultiLine Comment";
   } else {
      caption="Edit Line Comment";
   }
   typeless status=show("-modal _html_beautify_comments_create_form",caption,&comment);
   if( status=="" || status ) {
      // User cancelled or something went wrong
      return;
   }
   if( p && !comment._isempty() ) {
      startstr=comment:["startstr"];
      if( startstr=="" ) {
         // This should never happen
         msg="No starting delimiter specified";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      endstr=comment:["endstr"];
      if( type==HFCOMMENT_MULTILINE && endstr=="" ) {
         // This should never happen
         msg="No ending delimiter specified";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      if( type==HFCOMMENT_LINE ) {
         nesting=false;
      } else {
         nesting= (comment:["nesting"]!=0);
      }
      (*p)[i]:["startstr"]=startstr;
      (*p)[i]:["endstr"]=endstr;
      (*p)[i]:["nesting"]=nesting;
      was_selected=ctlcomment_list._lbisline_selected();
      ctlcomment_list._FillCommentList(*p);

      ctlcomment_list.top();
      _str ss='^(\>| )';
      if( type==HFCOMMENT_MULTILINE ) {
         ss=ss:+'MultiLine\t';
      } else {
         ss=ss:+'LineComment\t';
      }
      ss=ss:+_escape_re_chars(startstr):+'\t';
      status=ctlcomment_list.search(ss,'@er');
      if( !status && was_selected ) {
         ctlcomment_list._lbselect_line();
      }
      ctlcomment_list.call_event(CHANGE_OTHER,ctlcomment_list,ON_CHANGE,"W");
   }

   return;
}

void ctlnew.lbutton_up()
{
   _str msg="";
   typeless *p;
   typeless comment:[];

   p=ctlok.p_user;
   int i=0;
   int nofmlcomments=0;
   if( p ) {
      for( i=0;i<(*p)._length();++i ) {
         if( (*p)[i]:["type"]==HFCOMMENT_MULTILINE ) ++nofmlcomments;
      }
   }
   typeless type=show("-modal _html_beautify_comments_type_form",nofmlcomments);
   if( type=="" ) {
      // User cancelled
      return;
   }
   if( type<HFCOMMENT_MULTILINE || type>HFCOMMENT_LINE ) {
      // This should never happen
      msg="Invalid comment type";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   comment._makeempty();
   comment:["type"]=type;
   comment:["startstr"]="";
   comment:["endstr"]="";
   comment:["nesting"]=false;

   _str caption="";
   if( type==HFCOMMENT_MULTILINE ) {
      caption="New MultiLine Comment";
   } else {
      caption="New Line Comment";
   }
   typeless status=show("-modal _html_beautify_comments_create_form",caption,&comment);
   if( status=="" || status ) {
      // User cancelled or something went wrong
      return;
   }
   _str startstr="";
   _str endstr="";
   typeless nesting=false;
   if( p && !comment._isempty() ) {
      startstr=comment:["startstr"];
      if( startstr=="" ) {
         // This should never happen
         msg="No starting delimiter specified";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      endstr=comment:["endstr"];
      if( type==HFCOMMENT_MULTILINE && endstr=="" ) {
         // This should never happen
         msg="No ending delimiter specified";
         _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
         return;
      }
      if( type==HFCOMMENT_LINE ) {
         nesting=false;
      } else {
         nesting= (comment:["nesting"]!=0);
      }
      i=(*p)._length();
      (*p)[i]:["type"]=type;
      (*p)[i]:["startstr"]=startstr;
      (*p)[i]:["endstr"]=endstr;
      (*p)[i]:["nesting"]=nesting;
      ctlcomment_list._FillCommentList(*p);

      ctlcomment_list.top();
      _str ss='^(\>| )';
      if( type==HFCOMMENT_MULTILINE ) {
         ss=ss:+'MultiLine\t':+_escape_re_chars(startstr):+'\t';
      } else {
         ss=ss:+'LineComment\t':+_escape_re_chars(startstr):+'$';
      }
      status=ctlcomment_list.search(ss,'@er');
      if( !status ) {
         ctlcomment_list._lbselect_line();
      }
      ctlcomment_list.call_event(CHANGE_OTHER,ctlcomment_list,ON_CHANGE,"W");
   }

   return;
}

void ctldelete.lbutton_up()
{
   _str msg="";
   typeless *p;
   typeless comment:[];

   _str line=ctlcomment_list._lbget_text();
   if( line=="" ) {
      // This should never happen
      return;
   }
   typeless type=0;
   _str startstr="";
   _str endstr="";
   parse line with type "\t" startstr "\t" endstr;
   if( type=="MultiLine" ) {
      type=HFCOMMENT_MULTILINE;
   } else {
      type=HFCOMMENT_LINE;
   }
   // Now find it in the list
   int i=0;
   comment._makeempty();
   p=ctlok.p_user;
   if( p ) {
      for( i=0;(*p)._length();++i ) {
         typeless t=(*p)[i]:["type"];
         typeless s=(*p)[i]:["startstr"];
         if( t==type && s==startstr ) {
            // Found it
            break;
         }
      }
   }
   if( i<(*p)._length() ) {
      msg='Delete ';
      if( type==HFCOMMENT_MULTILINE ) {
         msg=msg:+'MultiLine comment "':+startstr:+'"  "':+endstr:+'"';
      } else {
         msg=msg:+'Line comment "':+startstr:+'"';
      }
      msg=msg:+"\n\nAre you sure?";
      int status=_message_box(msg,"",MB_YESNO|MB_ICONQUESTION);
      if( status!=IDYES ) {
         // User said no or cancelled
         return;
      }
      (*p)._deleteel(i);
      int old_line=ctlcomment_list.p_line;
      ctlcomment_list._FillCommentList(*p);
      if( old_line<=ctlcomment_list.p_Noflines ) {
         ctlcomment_list.p_line=old_line;
      } else {
         ctlcomment_list._lbtop();
      }
      ctlcomment_list._lbselect_line();
      ctlcomment_list.call_event(CHANGE_OTHER,ctlcomment_list,ON_CHANGE,"W");
   }

   return;
}

void ctlcancel.lbutton_up()
{
   p_active_form._delete_window("");

   return;
}

void ctlcomment_list.on_change(int reason)
{
   boolean enable= (p_Nofselected!=0);
   ctledit.p_enabled=enable;
   ctldelete.p_enabled=enable;

   return;
}

defeventtab _html_beautify_add_tag_form;
void ctl_ok.on_create()
{
   if( !_LanguageInheritsFrom('xml',gLangId) || !_mdi.p_child._isEditorCtl() ) {
      ctl_from_dtd.p_enabled=false;
   }
   ctl_single_tag.p_value=1;
}

void ctl_ok.lbutton_up()
{
   if( ctl_single_tag.p_value ) {
      _param1=ctl_tag.p_text;
   } else {
      // From the current file's DTD
      _param1='.DTD.';
   }

   p_active_form._delete_window(0);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

void ctl_from_dtd.lbutton_up()
{
   ctl_tag.p_enabled= (ctl_from_dtd.p_value==0);
}

void ctl_help.lbutton_up()
{
   _str msg="Single tag:\n":+
       "\tType in the name of the tag you want to add without <>. You\n":+
       "specify multiple tags by separating each tag by a space.";
   if( _LanguageInheritsFrom('xml',gLangId) ) {
      msg=msg:+
          "\n\n":+
          "Add DTD elements from current file:\n":+
          "\tIf the current file has a parsable DTD, then select this\n":+
          "\toption to add all elements from the DTD.";

   }
}

