////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47496 $
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
#import "adaptiveformatting.e"
#import "cformat.e"
#import "codehelp.e"
#import "complete.e"
#import "diff.e"
#import "dlgman.e"
#import "fileman.e"
#import "guiopen.e"
#import "hformat.e"
#import "html.e"
#import "ini.e"
#import "listbox.e"
#import "listproc.e"
#import "main.e"
#import "markfilt.e"
#import "math.e"
#import "picture.e"
#import "put.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "util.e"
#require "se/lang/api/LanguageSettings.e"
#endregion

using se.lang.api.LanguageSettings;

/*
   def_options_html contains the following default values and has the
   following format:
  def-options-html = '4 1 1 1 1 1 0 0 1 0...'

  rem1 = 4
  rem2 = 1
  tag_case = 1     Case html tags
  attrib_case = 1  Case attributes
  sword_case = 1  Case Single word values
  filenames = 1    Use lower case filenames when inserting links
  num_quotes = 1  Use quotes around numerical values
  sword_quotes = 1  Use quotes around single word values
  color_name = 0   Use insert colors using color name (if possible)
  align_tag   = 0     Use <DIV> for alignment tags
  file_path   = 0     Use full paths for file entries
  hex_case    = 1     Case Hex Values
  Last value is Rest

*/

#define MAX_HLINE_THICKNESS 10
#define MAX_BORDER_THICKNESS 15
#define IMG_FILE_EXT "*.bmp;*.jpg;*.jpeg;*.gif"
#define GIF_FILE_EXT "*.gif"
#define HTML_FILE_EXT"*.htm;*.html;*.shtml;*.asp;*.jsp;*.php3;*.php;*.rhtml"
#define APPLET_FILE_EXT"*.class"
#define JAVASCRIPT_FILE_EXT"*.js"
#define PHP_FILE_EXT"*.php3;*.php"
#define STYLE_FILE_EXT"*.css;*.htm;*.html"
#define VBSCRIPT_FILE_EXT"*.bas;*.vbs"
#define CHANGING_NAME_LIST    _font_name_list.p_user
#define RGB_DEFAULT 0x000000
#define MAX_HEX_LENGTH 6
#define MAX_HTML_SIZE 7
#define DEFAULT_HTML_FONT 3

//#define HF_DEFAULT_SCHEME_NAME "Default"
//#define HF_NONE_SCHEME_NAME    "(None)"

struct style_entry {
   int onoffval;
   _str style_name;
};

struct colorEntry {
   int rgb_val;       //The BGR color value for display
   _str color_name;   //The name of the color
};
struct tag_attribute {
   _str attribute_name;  //Actual Name of the Attribute
   _str attribute_val;   //Value found
   int attribute_color;  //If it is a color, the converted BGR value
};

static struct colorEntry ColorEntryList[]={
   {0xD7EBFA,"antiquewhite"}
   ,{0xffff00,"aqua"}
   ,{0xD4FF7F,"aquamarine"}
   ,{0xFFFFF0,"azure"}
   ,{0xDCF5F5,"beige"}
   ,{0xC4E4FF,"bisque"}
   ,{0x000000,"black"}
   ,{0xCDEBFF,"blanchedalmond"}
   ,{0xFF0000,"blue"}
   ,{0xE22B8A,"blueviolet"}
   ,{0x2A2AA5,"brown"}
   ,{0x87B8DE,"burlywood"}
   ,{0xA09E5F,"cadetblue"}
   ,{0x00FF7F,"chartreuse"}
   ,{0x1E69D2,"chocolate"}
   ,{0x507FFF,"coral"}
   ,{0xED9564,"cornflowerblue"}
   ,{0xDCF8FF,"cornsilk"}
   ,{0x0000dc,"crimson"}
   ,{0xFFFF00,"cyan"}
   ,{0x8B0000,"darkblue"}
   ,{0x8B8B00,"darkcyan"}
   ,{0x0B86B8,"darkgoldenrod"}
   ,{0xA9A9A9,"darkgray"}
   ,{0x006400,"darkgreen"}
   ,{0x6BB7BD,"darkkhaki"}
   ,{0x8B008B,"darkmagenta"}
   ,{0x2F6B55,"darkolivegreen"}
   ,{0x008CFF,"darkorange"}
   ,{0xCC3299,"darkorchid"}
   ,{0x00008B,"darkred"}
   ,{0x7A96E9,"darksalmon"}
   ,{0x006400,"darkseagreen"}
   ,{0x8B3D48,"darkslateblue"}
   ,{0x4F4F2F,"darkslategray"}
   ,{0xD1CE00,"darkturquoise"}
   ,{0xD30094,"darkviolet"}
   ,{0x9314FF,"deeppink"}
   ,{0xFFBF00,"deepskyblue"}
   ,{0x696969,"dimgray"}
   ,{0xFF901E,"dodgerblue"}
   ,{0x2222B2,"firebrick"}
   ,{0xF0FAFF,"floralwhite"}
   ,{0x228B22,"forestgreen"}
   ,{0xff00ff,"Fuchsia"}
   ,{0xDCDCDC,"gainsboro"}
   ,{0xFFF8F8,"ghostwhite"}
   ,{0xAAE8EE,"gold"}
   ,{0x20A5DA,"goldenrod"}
   ,{0x808080,"gray"}
   ,{0x008000,"green"}
   ,{0x2FFFAD,"greenyellow"}
   ,{0xF0FFF0,"honeydew"}
   ,{0xB469FF,"hotpink"}
   ,{0x5C5CCD,"indianred"}
   ,{0x800045,"indigo"}
   ,{0xF0FFFF,"ivory"}
   ,{0x8CE6F0,"khaki"}
   ,{0xFAE6E6,"lavender"}
   ,{0xF5F0FF,"lavenderblush"}
   ,{0x00FC7C,"lawngreen"}
   ,{0xCDFAFF,"lemonchiffon"}
   ,{0xE6D8AD,"lightblue"}
   ,{0x8080F0,"lightcoral"}
   ,{0xFFFFE0,"lightcyan"}
   ,{0xD2FAFA,"lightgoldenrodyellow"}
   ,{0x90EE90,"lightgreen"}
   ,{0xD3D3D3,"lightgrey"}
   ,{0xC1B6FF,"lightpink"}
   ,{0x7AA0FF,"lightsalmon"}
   ,{0xAAB220,"lightseagreen"}
   ,{0xFACE87,"lightskyblue"}
   ,{0x998877,"lightslategray"}
   ,{0xDEC4B0,"lightsteelblue"}
   ,{0xE0FFFF,"lightyellow"}
   ,{0x00ff00,"lime"}
   ,{0x32CD32,"limegreen"}
   ,{0xE6F0FA,"linen"}
   ,{0xFF00FF,"magenta"}
   ,{0x000080,"maroon"}
   ,{0xAACD66,"mediumaquamarine"}
   ,{0xCD0000,"mediumblue"}
   ,{0xD355BA,"mediumorchid"}
   ,{0xDB7093,"mediumpurple"}
   ,{0x71B33C,"mediumseagreen"}
   ,{0xEE687B,"mediumslateblue"}
   ,{0x9AFA00,"mediumspringgreen"}
   ,{0xCCD148,"mediumturquoise"}
   ,{0x8515C7,"mediumvioletred"}
   ,{0x701919,"midnightblue"}
   ,{0xFAFFF5,"mintcream"}
   ,{0xE1E4FF,"mistyrose"}
   ,{0xB5E4FF,"moccasin"}
   ,{0xADDEFF,"navajowhite"}
   ,{0x800000,"navy"}
   ,{0xE6F5FD,"oldlace"}
   ,{0x008080,"olive"}
   ,{0x238E6B,"olivedrab"}
   ,{0x00A5FF,"orange"}
   ,{0x0045FF,"orangered"}
   ,{0xD670DA,"orchid"}
   ,{0xAAE8EE,"palegoldenrod"}
   ,{0x98FB98,"palegreen"}
   ,{0xEEEEAF,"paleturquoise"}
   ,{0x9370DB,"palevioletred"}
   ,{0xD5EFFF,"papayawhip"}
   ,{0xB9DAFF,"peachpuff"}
   ,{0x3F85CD,"peru"}
   ,{0xCBC0FF,"pink"}
   ,{0xDDA0DD,"plum"}
   ,{0xE6E0B0,"powderblue"}
   ,{0x800080,"purple"}
   ,{0x0000ff,"red"}
   ,{0x8F8FBC,"rosybrown"}
   ,{0xE16941,"royalblue"}
   ,{0x13458B,"saddlebrown"}
   ,{0x7280FA,"salmon"}
   ,{0x60A4F4,"sandybrown"}
   ,{0x578B2E,"seagreen"}
   ,{0xEEF5FF,"seashell"}
   ,{0x2D52A0,"sienna"}
   ,{0xc0c0c0,"silver"}
   ,{0xEBCE87,"skyblue"}
   ,{0x8B3D48,"slateblue"}
   ,{0x908070,"slategray"}
   ,{0xFAFAFF,"snow"}
   ,{0x7FFF00,"springgreen"}
   ,{0xB48246,"steelblue"}
   ,{0x8CB4D2,"tan"}
   ,{0x808000,"teal"}
   ,{0xD8BFD8,"thistle"}
   ,{0x4763FF,"tomato"}
   ,{0xD0E040,"turquoise"}
   ,{0xEE82EE,"violet"}
   ,{0xB3DEF5,"wheat"}
   ,{0xffffff,"white"}
   ,{0xF5F5F5,"whitesmoke"}
   ,{0x00ffff,"yellow"}
   ,{0x32CD9A,"yellowgreen"}
};
/*<table width="20"
         border="20"
         cellspacing="4"
         cellpadding="4"
         align="LEFT"
         valign="TOP"
         background="C:\public\examples\webstuff\justgizmo.gif"
         nowrap title="The example table"></table>
*/
/*

Tagging information based upon referencese provided by netscape at

      http://developer.netscape.com/docs/manuals/htmlguid/alphlist.htm

 Tag forms to be used

 Bold:     <B> </B>
 Italic:     <I> </I>
 Underline:  <U> </U>
 Strikethrough: <STRIKE> </STRIKE>
 Emphasized:   <EM> </EM>
 Strong:       <STRONG> </STRONG>
 Preformated:   <PRE> </PRE>
 Big:     <BIG> </BIG>
 Small:   <SMALL> </SMALL>
 SuperScript: <SUP> </SUP>
 SubScript:   <SUB> </SUB>
 Blinking:  <BLINK> </BLINK>
 NonBreaking:  <NOBR> </NOBR>
 MonoSpaced:   <MONO> </MONO>
 Cite:  <CITE> </CITE>
 CODE:  <CODE> </CODE>
 Variable: <VAR> </VAR>
 Typewriter: <TT> </TT>
 PlainText: <PLAINTEXT> </PLAINTEXT>
 Keyboard:  <KBD> </KBD>

 Font:  <FONT Color ="" FACE="" SIZE=""> </FONT>

 Alignment: <DIV ALIGN =""> </ALIGN>
 <TABLE
  ALIGN="LEFT|RIGHT"
  BGCOLOR="color"
  BORDER="value"
  CELLPADDING="value"
  CELLSPACING="value"
  HEIGHT="height"
  WIDTH="width"
  COLS="numOfCols"
  HSPACE="horizMargin"
  VSPACE="vertMargin"
>
...
</TABLE>
*/

/**
 * Extract the width and height of a JPEG (JFIF compliant only) image
 *
 * @param filename      name of file
 * @param width         (reference) width of image
 * @param width         (reference) height of image
 *
 * @return 0 on success, <0 on error.
 *
 * @author Rodney Bloom
*/
int GetJpegDimension(_str filename,int &width,int &height)
{
   int temp_view_id, orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,"+LB");
   for (;;) {   // Use this for quick error handling
      if ( status ) break;
      // SOI - Start Of Image - 0xff,0xd8
      _nrseek(0);
      _str temp=get_text_raw(2);
      int ch1=_asc(substr(temp,1,1));
      int ch2=_asc(substr(temp,2,1));
      if ( ch1!=0xff || ch2!=0xd8 ) {
         status=1;
         break;
      }

      // Check for: (any number, in any order)
      //   APP0..APP15 - Application marker 0..15 - 0xff,0xe0..0xef
      //   COM - Comment - 0xff,0xfe
      //   DQT - Define Quantization Table - 0xff,0xdb
      //   DHT - Define Huffman Table - 0xff,0xc4
      _nrseek(_nrseek()+2);
      for (;;) {
         temp=get_text_raw(2);
         ch1=_asc(substr(temp,1,1));
         ch2=_asc(substr(temp,2,1));
         if ( ch1!=0xff ) {
            status=1;
            break;
         }
         boolean process_this_marker=false;
         switch ( ch2 ) {
         case 0xe0:
         case 0xe1:
         case 0xe2:
         case 0xe3:
         case 0xe4:
         case 0xe5:
         case 0xe6:
         case 0xe7:
         case 0xe8:
         case 0xe9:
         case 0xea:
         case 0xeb:
         case 0xec:
         case 0xed:
         case 0xee:
         case 0xef:
            // Application marker
         case 0xfe:
            // Comment
         case 0xdb:
            // Quantization table
         case 0xc4:
            // Huffman table
            process_this_marker=true;
         }
         if ( !process_this_marker ) {
            break;
         }
         _nrseek(_nrseek()+2);
         temp=get_text_raw(2);
         ch1=_asc(substr(temp,1,1));
         ch2=_asc(substr(temp,2,1));
         // Length of data (including these 2 bytes)
         int len= (ch1<<8)+ch2;
         _nrseek(_nrseek()+len);
      }
      if ( status ) break;

      // Check for SOF0 - Start Of Frame - 0xff,0xc0
      temp=get_text_raw(2);
      ch1=_asc(substr(temp,1,1));
      ch2=_asc(substr(temp,2,1));
      if ( ch1!=0xff ) {
         status=1;
         break;
      }
      if ( ch2!=0xc0 ) {
         // No Start-Of-Frame info
         status=1;
         break;
      }
      // Seek past the length (2 bytes), data precision (1 byte)
      _nrseek(_nrseek()+5);
      // Height (2 bytes)
      temp=get_text_raw(2);
      ch1=_asc(substr(temp,1,1));
      ch2=_asc(substr(temp,2,1));
      height= (ch1<<8)+ch2;
      _nrseek(_nrseek()+2);
      // Width (2 bytes)
      temp=get_text_raw(2);
      ch1=_asc(substr(temp,1,1));
      ch2=_asc(substr(temp,2,1));
      width= (ch1<<8)+ch2;
      break;
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(status);
}

/**
 * Extract the width and height of a GIF image
 *
 * @author Rodney Bloom
 * @param filename              The file to check
 * @param width                 (reference) width of image
 * @param height                (reference) height of image
 *
 * @return 0 on success, <0 on error
 */
int GetGifDimension(_str filename,int &width,int &height)
{
   int temp_view_id, orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,"+LB");
   for (;;) {   // Use this for quick error handling
      if ( status ) break;
      _nrseek(0);
      _str id=get_text_raw(6);
      id=lowcase(id);
      if ( id!="gif89a" && id!="gif87a" ) {
         // Not a valid gif file
         status=1;
         break;
      }
      _nrseek(_nrseek()+6);
      // Width (2 bytes)
      _str temp=get_text_raw(2);
      int ch1=_asc(substr(temp,1,1));
      int ch2=_asc(substr(temp,2,1));
      width= (ch2<<8)+ch1;
      _nrseek(_nrseek()+2);
      // Height (2 bytes)
      temp=get_text_raw(2);
      ch1=_asc(substr(temp,1,1));
      ch2=_asc(substr(temp,2,1));
      height= (ch2<<8)+ch1;
      break;
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(status);
}
/**
 * Extract the width and height of a Bmp image
 *
 * @author Chris Cunning
 * @param filename              The file to check
 * @param width                 (reference) the width of the image
 * @param height                (reference) height of the image
 *
 * @return 0 on success, <0 on error
 */
int GetBmpDimension(_str filename,int &width,int &height)
{
   int temp_view_id, orig_view_id;
   int status=_open_temp_view(filename,temp_view_id,orig_view_id,"+LB");
   for (;;) {   // Use this for quick error handling
      if ( status ) break;
      _nrseek(0);
      _str id=get_text_raw(2);
      id=lowcase(id);
      if ( id!="bm") {
         // Not a valid bitmap file
         status=1;
         break;
      }
      _nrseek(_nrseek()+18);
      // Width (4 bytes)
      _str temp=get_text_raw(4);
      int ch1=_asc(substr(temp,1,1));
      int ch2=_asc(substr(temp,2,1));
      int ch3=_asc(substr(temp,3,1));
      int ch4=_asc(substr(temp,4,1));
      //_message_box(ch1' 'ch2' 'ch3' 'ch4);
      width= (ch4<<16)+(ch3<<12)+(ch2<<8)+ch1;
      _nrseek(_nrseek()+4);
      // Height (4 bytes)
      temp=get_text_raw(4);
      ch1=_asc(substr(temp,1,1));
      ch2=_asc(substr(temp,2,1));
      ch3=_asc(substr(temp,3,1));
      ch4=_asc(substr(temp,4,1));
      height= (ch4<<16)+(ch3<<12)+(ch2<<8)+ch1;
      break;
   }
   _delete_temp_view(temp_view_id);
   p_window_id=orig_view_id;

   return(status);
}


/**
 * Slick-C&reg; uses BGR for color rather than RGB.
 * This macro converts it to that format.
 *
 * @param val                   The BGR value to be converted
 *
 * @param use_name
 *
 * @return Returns the converted value as a string for printing.
 */
static _str convert_2_html_color( int val = 0, boolean use_name = false)
{
   _str html_val;
   _str red;
   _str green;
   _str blue;

   hex_case := getHexValueCasing();
                                            //4 1 0 0 0 0 0 1 1 0 0 0 1
   if (LanguageSettings.getUseColorNames(html_langId()) || use_name) {  //Check to see if the word name is to be used
      int x;
      for (x = 0; x < ColorEntryList._length(); x++) {
         if (ColorEntryList[x].rgb_val == val) {
            return(ColorEntryList[x].color_name);
         }
      }
   }
   //If don't have an exact match or the want a hex value, we keep going.
   html_val = dec2hex(val);
   parse html_val with '0x'html_val;
   //messageNwait('html_val 'html_val);
   for (;;) {
      if (length(html_val) == MAX_HEX_LENGTH) {
         break;
      }
      html_val = '0':+html_val; //Pad the value
   }
   //_str substr(_str string,int start,int length=-1,_str pad=" ")
   blue  = substr(html_val,1,2);
   green = substr(html_val,3,2);
   red   = substr(html_val,5,2);
   //messageNwait('red 'red 'green 'green' blue 'blue);
   html_val ='#':+red:+green:+blue;
   if (hex_case == WORDCASE_LOWER) {   //Is it set to lowercase hex values?
      return(lowcase(html_val));
   }
   return(html_val);
}
/**
 * Checks to see if quotes should be used around value,
 * and if so, adds them.
 *
 * @param value                 value to be quoted
 *
 * @return quote or no qoute
 */
static _str html_use_quote( _str value)
{
   if (LanguageSettings.getQuotesForNumericValues(html_langId())) {  //Check to see if they want quotes around numbers
      return('"':+value:+'"');
   }
   return(value);
}

static _str html_langId()
{
   if (_inJavadoc()) return 'html';
   else return p_LangId;
}

/**
 * Look up options index to use for HTML formatting
 */
static int html_index()
{
   if (_inJavadoc()) {
      int index = find_index('def-options-html', MISC_TYPE);
      if (index) return index;
   }
   return p_index;
}
/**
 * Checks to see if tags should be upper or lower case
 * and cases the tag appropriately.
 *
 * @param tag                   The string to be up or low cased
 * @param type                  indicating a tag(0),attribute (1) single word val(2)
 *
 * @return cased tag
 */
_str case_html_string( _str tag, int type = 0)
{
   int scase;
   if (!type) {  //If it is not an attrib, use casing for tags
      scase=getTagCasing();
   } else if (type == 1) {
      scase=getAttributeCasing();
   } else {
      scase= getStringValueCasing();
      if (LanguageSettings.getQuotesForSingleWordValues(html_langId())) {
         tag = '"'tag'"';
      }
   }
   // Bulletin Board Code tags are all lowercase
   if (_LanguageInheritsFrom('bbc')) {
      scase = WORDCASE_LOWER;
   }

   if (scase==WORDCASE_CAPITALIZE) {
      /* Capitalize language key words. */
      return(tag);
   } else if (scase==WORDCASE_LOWER) {
      /* Lower case language key words. */
      return(lowcase(tag));
   } else {
      return(upcase(tag));
   }
}
/**
 * Checks to see if tags should be upper or lower
 * case and cases the tag appropriately.
 *
 * @param tag                   The tag to be up or low cased
 * @param attrib                boolean indicating an attribute
 *
 * @return cased tag
 */
_str case_html_tag( _str tag, boolean attrib = false)
{
   if (p_EmbeddedCaseSensitive) return tag;

   // check for case sensitive JSP attributes
   if (attrib){
      if (pos('[a-z]+[A-Z]?*',tag,1,'R')){
         return(tag);
      } else {
         save_pos(auto p);
         _str status = _html_goto_previous_tag();
         if (status != '') {
            restore_pos(p);
            if (pos(':',status)) {
               return(tag);
            }
         }
      }
   }

   int scase;
   if (!attrib) {   //If it is not an attribute, use the tag casing
      scase=getTagCasing();
      // JavaScript taglib tags are case-sensitive
      if (pos(':',tag)) {
         return(tag);
      }
   } else {
      scase=getAttributeCasing();
      // HREF links are case-sensitive
      if (substr(tag,1,1)=='#') {
         return(tag);
      }
      // Javadoc keywords are case-sensitive
      if (substr(tag,1,1)=='@') {
         return(tag);
      }
   }
   if ( scase < 0) {
      return(tag);
   } else if ( scase==WORDCASE_UPPER ) {
      /* Upper case language key words. */
      return(upcase(tag));
   } else if ( scase==WORDCASE_LOWER ) {
      /* Lower case language key words. */
      return(lowcase(tag));
   }
   return(upcase(substr(tag,1,1)):+lowcase(substr(tag,2)));  /* Capitalize */
}
/**
 * Determines it the file name should be converted to lower
 * case and if lower cases the file name.
 *
 * @param filename              the file name to be cased
 *
 * @return the cased file name
 */
static _str html_lowcase_filename(_str filename)
{
   if (LanguageSettings.getLowercaseFilenamesWhenInsertingLinks(html_langId())) {
      return(lowcase(filename));
   }
   return(filename);
}

/** 
 * Gets the casing method for tags.  
 * 
 * @return int       casing method - see WORDCASE_???
 */
static int getTagCasing()
{
   typeless scase='';

   // if we're in javadoc, we need to get the html settings manually
   if (_inJavadoc()) {
      scase = LanguageSettings.getTagCase('html');
   } else {       // otherwise use buffer settings
      updateAdaptiveFormattingSettings(AFF_TAG_CASING);
      scase = p_tag_casing;
   }

   return scase;
}

/** 
 * Gets the casing method for attributes.  
 * 
 * @return int       casing method - see WORDCASE_???
 */
static int getAttributeCasing()
{
   typeless scase='';

   // if we're in javadoc, we need to get the html settings manually
   if (_inJavadoc()) {
      scase = LanguageSettings.getAttributeCase('html');
   } else {       // otherwise use buffer settings
      updateAdaptiveFormattingSettings(AFF_ATTRIBUTE_CASING);
      scase = p_attribute_casing;
   }

   return scase;
}

/** 
 * Gets the casing method for string values.  
 * 
 * @return int       casing method - see WORDCASE_???
 */
static int getStringValueCasing()
{
   typeless scase='';

   // if we're in javadoc, we need to get the html settings manually
   if (_inJavadoc()) {
      scase = LanguageSettings.getValueCase('html');
   } else {       // otherwise use buffer settings
      updateAdaptiveFormattingSettings(AFF_VALUE_CASING);
      scase = p_value_casing;
   }

   return scase;
}

/** 
 * Gets the casing method for hex values.  
 * 
 * @return int       casing method - see WORDCASE_???
 */
static int getHexValueCasing()
{
   typeless scase='';

   // if we're in javadoc, we need to get the html settings manually
   if (_inJavadoc()) {
      scase = LanguageSettings.getHexValueCase('html');
   } else {       // otherwise use buffer settings
      updateAdaptiveFormattingSettings(AFF_HEX_VALUE_CASING);
      scase = p_hex_value_casing;
   }

   return scase;
}

static int htmlOnUpdate(int target_wid, _str supportBBC=false)
{
   if ( !target_wid || !target_wid._isEditorCtl()) {
      return(MF_GRAYED);
   }
   if (_inJavadoc()) {
      return(MF_ENABLED);
   }
   if (target_wid._LanguageInheritsFrom('html')) {
      return(MF_ENABLED);
   }
   // is this command allowed for Bulletin Board Code?
   if (supportBBC && target_wid._LanguageInheritsFrom('bbc')) {
      return(MF_ENABLED);
   }
   return(MF_GRAYED);
}
int _OnUpdate_insert_html_bold(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}

int extract_html_scheme_value(_str tagname)
{
   typeless value;
   if (_ini_get_value(FormatUserIniFilename(), "html-scheme-"HF_DEFAULT_SCHEME_NAME,tagname, value, "")) {
      //We can not find the default scheme, so we generate a default scheme
      HFormatMaybeCreateDefaultScheme();
      if (_ini_get_value(FormatUserIniFilename(), "html-scheme-"HF_DEFAULT_SCHEME_NAME,tagname, value, "")) {

         // just return -1 if we cannot find any scheme information

         //_message_box("Unable to locate scheme information for HTML tag "tagname);

         return(-1);
      }
   }
   return(value);
   //_message_box('status 'status ' tagname 'tagname' value 'value);
}
int set_html_scheme_value(_str tagname, int ext_options_val, boolean binary_value = false)
{
   typeless value;
   if (_ini_get_value(FormatUserIniFilename(), "html-scheme-"HF_DEFAULT_SCHEME_NAME,tagname, value, "")) {
      //We can not find the default scheme, so we generate a default scheme
      HFormatMaybeCreateDefaultScheme();
      if (_ini_get_value(FormatUserIniFilename(), "html-scheme-"HF_DEFAULT_SCHEME_NAME,tagname, value, "")) {
         _message_box("Unable to locate scheme information for HTML tag "tagname);
         return(-1);
      }
   }
   if (value == WORDCASE_PRESERVE) {
      return(0);
   }
   if ((value != ext_options_val)) {
      //If the beautifier scheme and the extension options scheme are different...
      /*if (!binary_value && !value) {
         return(0);
      } */
      MaybeCreateFormatUserIniFile();
      return _ini_set_value(FormatUserIniFilename(),'html-scheme-':+HF_DEFAULT_SCHEME_NAME,tagname,ext_options_val);
   }


   return(0);
   //_message_box('status 'status ' tagname 'tagname' value 'value);
}
/**
 * Check if we are in a mode supporting HTML editing.
 *
 * @return 'true' if we are in an HTML context.
 *         'false' otherwise, and shows warning.
 */
boolean checkHTMLContext(boolean quiet=false)
{
   if (!_inJavadoc() && !_LanguageInheritsFrom('html') && !_LanguageInheritsFrom('bbc')) {
      //Check to see if we are in HTML mode.  If not, exit
      if (!quiet) {
         message(nls('Command not allowed while not in HTML mode'));
      }
      return false;
   }
   return true;
}
/**
 * Inserts bold html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_bold() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('B');
}
int _OnUpdate_insert_html_styles(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * Inserts the tags into a single line
 *
 * @param start_tag             The Opening tag
 * @param end_tag               The end tag
 */
static void insert_single_line_tags(_str start_tag, _str end_tag)
{
   typeless p;
   _save_pos2(p);     //Save the current cursor position

   // Bulletin Board Code tags use brackets
   _str tagname='', junk='';
   if (_LanguageInheritsFrom('bbc')) {
      parse start_tag with '[' tagname'( |\])','r' junk; //Extract the tag name
   } else {
      parse start_tag with '<' tagname'( |\>)','r' junk; //Extract the tag name
   }
   int standalone_val = extract_html_scheme_value('tag*'tagname'*standalone');
   int begin_val = extract_html_scheme_value('tag*'tagname'*noflines_before');
   int after_val = extract_html_scheme_value('tag*'tagname'*noflines_after');
   int indent_col = p_col;  //Establish the current indent level

   if (select_active()) {
      begin_select();
      begin_line();
      first_non_blank();
      if (_select_type()== 'BLOCK') {// Perhaps switch to char instead?
         message(nls('Block marks not supported'));
         return;
      }
      end_select();   //Move to the end of the selection
      if (_select_type()== 'LINE') {
         //If it is a line select, set p_col to 1 and insert a new line
         insert_line('');
         p_col = indent_col;
      }
      if (_select_type() == 'CHAR') {
         if (p_line > 1 && p_col == 1) { //Just in case
            up();
            end_line();
         }
      }
   }
   _insert_text(end_tag);   //Insert the end tag
   if (standalone_val || after_val) {
      _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
      if (textAfterCursor!="") {
         textAfterCursor = strip(textAfterCursor,'L');
         _delete_text(-1);
         insert_line(indent_string(indent_col-1):+textAfterCursor);
         up();_end_line();
      }
   }
   _restore_pos2(p);
   //_save_pos2(p);     //Save the current cursor position

   if (select_active()) {
      begin_select();       //Move to the beginning of the selection
      if (_select_type()== 'LINE') {
         //If it is a line selection, insert a new line
         up();
         insert_line('');
         p_col = indent_col;
      }
   }
   if (standalone_val || begin_val) {
      indent_col=p_col;
      _str textBeforeCursor=_expand_tabsc(1,p_col-1,'S');
      if (textBeforeCursor!="") {
         textBeforeCursor = strip(_expand_tabsc(p_col,-1,'S'),'L');
         _delete_text(-1);
         insert_line(indent_string(indent_col-1):+textBeforeCursor);
         up();_end_line();
      }
   }
   _insert_text(start_tag); //Insert the start tag

   //_restore_pos2(p);        //Restore cursor position
   deselect();              //Deselect the text
}
/**
 * Inserts the tags in a block format and then places the cursor
 * in the middle line.  Do not call this function if the "standalone" style
 * is on for this tag.
 *
 * @param begin_tag The opening tag
 * @param end_tag The closing tag
 */
static void insert_block_tags(_str begin_tag,_str end_tag)
{

   int indent = 0;

   // Bulletin Board Code tags use brackets
   _str tagname='', junk='';
   if (_LanguageInheritsFrom('bbc')) {
      parse begin_tag with '[' tagname'( |\])','r' junk; //Extract the tag name
   } else {
      parse begin_tag with '<' tagname'( |\>)','r' junk; //Extract the tag name
   }
   if (tagname!= '') {
      indent = extract_html_scheme_value('tag*'tagname'*indent_content');
   }
   int indent_col = p_col;  //Establish indent level
   if (select_active()) {   //Check to see if we are working with selected text
      if (_select_type()== 'BLOCK') {// Perhaps switch to char instead?
         message(nls('Block marks not supported'));
         return;
      }
      lock_selection('q');
      begin_select();
      begin_line();
      first_non_blank();
      if (_select_type()== 'LINE') {
         end_select();
         if (end_tag != '') {
            insert_line(indent_string(indent_col-1)end_tag);
         }
         begin_select();
         up();
         insert_line(indent_string(indent_col-1)begin_tag);
      }
      if (_select_type() == 'CHAR') {
         begin_select;
         int sline= p_line;
         end_select();
         int eline= p_line;
         if (p_col==1) {
            up();
            eline= p_line;
            down();
         }
         if (end_tag !='') {
            _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
            if (textAfterCursor!="") {
               textAfterCursor = strip(textAfterCursor,'L');
               _delete_text(-1);
               insert_line(indent_string(indent_col-1):+textAfterCursor);
               if (eline != sline) {
                  //Occurance where same line character selection w/ text after
                  up();
                  eline=p_line;
               }
            }
            //insert_line(indent_string(indent_col-1)end_tag);
         }
         begin_select();
         _str textBeforeCursor=_expand_tabsc(1,p_col-1,'S');
         if (textBeforeCursor!="") {
            _str textAfterCursor = strip(_expand_tabsc(p_col,-1,'S'),'L');
            _delete_text(-1);
            insert_line(indent_string(indent_col-1):+textAfterCursor);
            sline = p_line;
            eline++; //We moved the selection, so we have adjust the eline accordingly
         }
         if (eline < sline) {
            //Case where we are dealing with a same line char selection
            eline = sline;
         }
         p_line = sline;
         select_line();
         p_line = eline;
         select_line();
         insert_block_tags(begin_tag,end_tag);
         return;
      }
      if (indent) {
         indent_selection();
      }
      deselect();
      down();first_non_blank();
      //Put us in the tag and at the beginning of the content
      //This is important for the table dialog so we can place caption properly
      return;
   }
   if (p_line==0) {
      insert_line(begin_tag);
      insert_line('');
      if (end_tag!='') {
         insert_line(end_tag);
         up();
      }
      p_col=1;
      if (indent) {
         p_col =p_col + p_SyntaxIndent;
      }
      return;
   }
   if (_expand_tabsc()=='') {
      indent_col=p_col;
      replace_line(indent_string(indent_col-1)begin_tag);
      insert_line('');
      if (end_tag!='') {
         insert_line(indent_string(indent_col-1)end_tag);
         up();
      }
      p_col=indent_col;
      if (indent) {
         p_col=p_col+p_SyntaxIndent;
      }
      return;
   }
   int orig_col=p_col;
   if (_expand_tabsc(1,p_col-1)!="") {
      first_non_blank();
   }
   indent_col=p_col;
   p_col=orig_col;
   _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
   if (textAfterCursor!="") {
      _delete_text(-1);
      insert_line(indent_string(indent_col-1):+textAfterCursor);
      up();
   }
   if (_expand_tabsc(1,p_col-1)!="") {
      first_non_blank();
      insert_line(indent_string(indent_col-1)begin_tag);
      insert_line('');
      if (end_tag!='') {
         insert_line(indent_string(indent_col-1)end_tag);
         up();
      }
      p_col=indent_col;
      if (indent) {
         p_col=p_col+p_SyntaxIndent;
      }
      return;
   }
   replace_line(indent_string(indent_col-1)begin_tag);
   insert_line('');
   if (end_tag!='') {
      insert_line(indent_string(indent_col-1)end_tag);
      up();
   }
   p_col=indent_col;
   if (indent) {
      p_col=p_col+p_SyntaxIndent;
   }
   return;

#if 0



   if (p_line==0) {
      insert_line(begin_tag);
      if (end_tag != '') {
         insert_line('');
         insert_line(end_tag);
         up();p_col=1;
      }
      return;
   }
   get_line(line);
   if (line=='') {
      indent_col=p_col;
      replace_line(indent_string(indent_col-1)begin_tag);
      if (end_tag != '') {
         insert_line('');
         insert_line(indent_string(indent_col-1)end_tag);
         up();p_col=indent_col;
      } else {
         p_col = p_col + length(begin_tag);
      }
      return;
   }
   orig_col=p_col;
   if (_expand_tabsc(1,p_col-1)!="") {
      first_non_blank();
   }
   indent_col=p_col;
   p_col=orig_col;
   textAfterCursor=_expand_tabsc(p_col,-1,'S');
   if (textAfterCursor!="") {
      if (end_tag !='') {
         _delete_text(-1);
         insert_line(indent_string(indent_col-1):+textAfterCursor);
         up();
         p_col = orig_col;
      }
   }
   if (_expand_tabsc(1,p_col-1)!="") {
      _insert_text(begin_tag);
      if (end_tag !='') {
         insert_line('');
         insert_line(indent_string(indent_col-1)end_tag);
         up();p_col=indent_col;
      } else {
         //p_col = p_col + length(begin_tag);
      }
      return;
   }
   if (end_tag !='') {
      replace_line(indent_string(indent_col-1)begin_tag);
      insert_line('');
      insert_line(indent_string(indent_col-1)end_tag);
      up();p_col=indent_col;
   } else {
      _insert_text(begin_tag);
      p_col = p_col + length(begin_tag);
   }
#endif
}
/**
 * Inserts either a styles tag or a link to a Style Sheet
 *
 * @return
 */
_command insert_html_styles() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   _str result=show('-modal _html_insert_styles_form');
   //Bring up the _html_insert_styles dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   if (_param1) {
      _str begin_tag = case_html_string('<Style'):+case_html_string(' Type=',1):+case_html_string(_param3,2):+'>';
      _str end_tag=case_html_string('</Style>');
      insert_html_tag(begin_tag,end_tag,true,false);
   } else {
      _str styles_line = case_html_string('<Link'):+case_html_string(' Rel=',1)case_html_string('Stylesheet',2):+case_html_string(' Type=',1):+case_html_string(_param3,2):+case_html_string(' Src="',1):+_param2'">';
      insert_html_tag(styles_line,'',true,false);

   }
}

/**
 * inserts italic html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_italic() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('I');
}
int _OnUpdate_insert_html_italic(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts emphasis html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_em() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Em');
}
int _OnUpdate_insert_html_em(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * inserts code sample html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_code() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Code');
}
int _OnUpdate_insert_html_code(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts underline html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_uline() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('U');
}
int _OnUpdate_insert_html_uline(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts table caption html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_table_caption() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Caption');
}
int _OnUpdate_insert_html_table_caption(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * inserts table row html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_table_row() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Tr');
}
int _OnUpdate_insert_html_table_row(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts table column html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_table_col() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Td');
}
int _OnUpdate_insert_html_table_col(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts table header tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_table_header() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');
   insert_html_tag('Th');
}
int _OnUpdate_insert_html_table_header(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * inserts paragraph html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_paragraph() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   if (!extract_html_scheme_value('tag*p*endtag')) {
      insert_html_tag('<P>','',true);
      return('');
   }
   insert_html_tag('P');
}
int _OnUpdate_insert_html_paragraph(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * inserts center alignment html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_center() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   div_align := LanguageSettings.getUseDivTagsForAlignment(html_langId());
   if (div_align && !_LanguageInheritsFrom('bbc')) {
      insert_html_tag(case_html_string('<Div ') case_html_string('Align=',1) case_html_string('Center',2):+'>',case_html_string('</Div>'),true,false);
   } else {
      insert_html_tag('Center');
   }
}
int _OnUpdate_insert_html_center(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts right alignment html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_right() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   div_align := LanguageSettings.getUseDivTagsForAlignment(html_langId());
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('right');
   } else if (div_align) {
      insert_html_tag(case_html_string('<Div'):+case_html_string(' Align=',1)case_html_string('Right',2):+'>',case_html_string('</Div>'),true,false);
   } else {
      insert_html_tag(case_html_string('<P'):+case_html_string(' Align=',1)case_html_string('Right',2):+'>',case_html_string('</P>'),true,false);
   }
}
int _OnUpdate_insert_html_right(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts left alignment html tags into the file at cursor or if text
 * is selected, at the beginning or end of the file
 *
 * @return
 */
_command insert_html_left() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   div_align := LanguageSettings.getUseDivTagsForAlignment(html_langId());
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('right');
   } else if (div_align) {
      insert_html_tag(case_html_string('<Div'):+case_html_string(' Align=',1)case_html_string('Left',2):+'>',case_html_string('</Div>'),true,false);
   } else {
      insert_html_tag(case_html_string('<P'):+case_html_string(' Align=',1)case_html_string('Left',2):+'>',case_html_string('</P>'),true,false);
   }
}
int _OnUpdate_insert_html_left(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
void insert_html40_attributes(_str &line)
{

   if (_param8!='') {
      line= line:+case_html_string(' Style="',1):+_param8:+'"';
   }
   if (_param9!='') {
      line= line:+case_html_string(' Class="',1):+_param9:+'"';
   }
   if (_param10!='') {
      line= line:+case_html_string(' Id="',1):+_param10:+'"';
   }
}

/**
 * Brings up the HTML table dialog and inserts the results
 * into an HTML table tag
 *
 * @return
 */
_command insert_html_table() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   // Bulletin Board Code table tags have no attributes
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('table');
      return 0;
   }

   _str caption_line = '';
   _str result=show('-modal _html_insert_table_form');
   //Bring up the _html_insert_table dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str table_line = case_html_string('<Table');
   _str end_tag=case_html_string('</Table>');
   insert_html40_attributes(table_line);
   _str begin_tag = table_line:+_param1:+'>';
   if (!extract_html_scheme_value('tag*table*endtag')) {
      /*     indent_col=p_col;
           _insert_text(begin_tag"\n\n"indent_string(indent_col-1));
           up(1);p_col=indent_col;
      */
      insert_html_tag(begin_tag,'',true,false);
   } else {
      insert_html_tag(begin_tag,end_tag,true,false);
   }
   int indent_col = p_col;
   if (_param2 !='') {
#if 0
      if (extract_html_scheme_value('tag*table*standalone')) {
         insert_html_tag(case_html_string('<Caption'):+case_html_string(' Align=',1):+case_html_string(_param3,2):+'>',case_html_string('</Caption>'),true,false);
         _insert_text(_param2);
      } else {
         _insert_text((case_html_string('<Caption'):+case_html_string(' Align=',1):+case_html_string(_param3,2):+'>':+_param2:+case_html_string('</Caption>')));
      }
#endif
      insert_html_tag(case_html_string('<Caption'):+case_html_string(' Align=',1):+case_html_string(_param3,2):+'>',case_html_string('</Caption>'),true,false);
      _insert_text(_param2);
   }
   return(0);
}
int _OnUpdate_insert_html_table(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * Insert a hex RGB value or name at the cursor
 *
 * @return
 */
_command insert_rgb_value() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   _str result=show('-modal _html_insert_rgb_color_form');
   //Bring up the _html_insert_rgb dialog

   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // For Bulletin Board Code tags, insert a color tag.
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('[color='convert_2_html_color((int)result)']','[/color]',true,false);
      return 0;
   }

   _insert_text(html_use_quote(convert_2_html_color((int)result)));
}
int _OnUpdate_insert_rgb_value(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}

/**
 * Takes the tag values and inserts them either at the cursor
 * or around selected text.  If tag2 is empty, it uses tag1 to
 * create the end tag.  If preset_tags is true, then it inserts
 * the tags without adding the '<>', i.e. no change.
 *
 * @param tagopen               The begin tag or tag value
 * @param tagclose              The end tag or tag value
 * @param preset_tags           boolean indicating that the tags are already encapsulated by '<>'
 * @param caps                  Indicates wether or not the tag should be cased.
 */
void insert_html_tag( _str tagopen = '', _str tagclose = '', boolean preset_tags = false, boolean caps = true)
{
   _str start_tag = '';      //Opening tag
   _str end_tag   = '';      //Ending tag
   if (caps) {
      tagopen = case_html_string(tagopen);
      tagclose = case_html_string(tagclose);
   }
   if (!preset_tags) {  //If the tags are not already made, create them
      if (_LanguageInheritsFrom('bbc')) {
         // Bulletin Board Code tags use brackets
         start_tag = '[':+tagopen:+']';
         if (tagclose == '') { //If tag2 is empty, use tag 1
            end_tag   = '[/':+tagopen:+']';
         }
      } else {
         start_tag = '<':+tagopen:+'>';
         if (tagclose == '') { //If tag2 is empty, use tag 1
            end_tag   = '</':+tagopen:+'>';
         }
      }
   } else {             //Else use the direct values
      start_tag = tagopen;
      end_tag   = tagclose;
   }

   // Bulletin Board Code tags use brackets
   _str tagname='', junk='';
   if (_LanguageInheritsFrom('bbc')) {
      parse start_tag with '[' tagname'( |\])','r' junk;
   } else {
      parse start_tag with '<' tagname'( |\>)','r' junk;
   }

   int standalone_val = extract_html_scheme_value('tag*'tagname'*standalone');

   if (standalone_val) {
      insert_block_tags(start_tag,end_tag);
   } else {
      insert_single_line_tags(start_tag,end_tag);
   }

}

/**
 * Inserts HTML tag for a script into the current HTML document
 *
 * @return
 */
_command insert_html_script()name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   _str script_line = '';
   _str result=show('-modal _html_insert_script_form');
   //Bring up the _html_insert_script dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   int col = p_col;
   _str end_tag = case_html_string('</Script>');
   script_line = case_html_string('<Script');
   insert_html40_attributes(script_line);
   script_line = script_line:+case_html_string(' Language="',1):+_param1:+'"';
   //<SCRIPT LANGUAGE="" SRC="">
   _str begin_tag='';
   if (_param3) {
      begin_tag = script_line:+case_html_string(' Src="',1):+_param2:+'">';
      insert_html_tag(begin_tag,end_tag,true,false);
   } else {
      begin_tag = script_line:+'>';
      insert_html_tag(begin_tag,end_tag,true,false);
      int value = extract_html_scheme_value('tag*script*standalone');
      //If it is not set to a block tag, we do not want to insert the code
      if (_param2 != '') {
         if (!value) {
            _str textAfterCursor=_expand_tabsc(p_col,-1,'S');
            textAfterCursor = strip(textAfterCursor,'L');
            _delete_text(-1);
            begin_line();
            first_non_blank();
            int indent_col = p_col;
            insert_line(indent_string(indent_col-1):+textAfterCursor);
            up();
         }
         get(maybe_quote_filename(_param2));
      }
   }
}
int _OnUpdate_insert_html_script(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}

/**
 * Inserts a heading tag of size 1-6 into the current HTML document
 *
 * @return
 */
_command insert_html_heading() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   _str result=show('-modal _html_insert_heading_form');
   //Bring up the _html_insert_applet dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   insert_html_tag('H':+_param1);
}
int _OnUpdate_insert_html_heading(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}

/**
 * Inserts a link to an java applet into the current HTML document
 *
 * @return
 */
_command insert_html_applet()name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   _str applet_line = '';
   _str result=show('-modal _html_insert_applet_form');
   //Bring up the _html_insert_applet dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   //<APPLET CODEBASE="www.foo.com" CODE="foo.class" WIDTH="" HEIGHT="" ALT="" BORDER="">
   //_message_box('_param1 ' _param1' _param2 '_param2' _param3 ' _param3' _param4 '_param4' _param5 ' _param5'_param6 '_param6);

   applet_line = case_html_string('<Applet');
   insert_html40_attributes(applet_line);
   if (_param1 != '') {
      applet_line = applet_line:+case_html_string(' Codebase="',1):+_param1:+'"';

   }

   applet_line = applet_line:+case_html_string(' Code="',1):+_param2:+'"';

   if (_param3 !='') {
      if (_param4 !='') {
         applet_line = applet_line:+case_html_string(' Width=',1):+html_use_quote(_param3);
         applet_line = applet_line:+case_html_string(' Height=',1):+html_use_quote(_param4);
      }
   }
   if (_param5 !='') {
      applet_line = applet_line:+case_html_string(' Alt="',1):+_param5:+'"';
   }
   if (_param6 !='' && _param6 != 0) {
      applet_line = applet_line:+case_html_string(' Border=',1):+html_use_quote(_param6);
   }

   _str begin_tag = applet_line:+'>';
   _str end_tag = case_html_string('</Applet>');
   insert_html_tag(begin_tag,end_tag,true,false);
}
int _OnUpdate_insert_html_applet(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * Inserts an HTML anchor tag into the current document at the cursor
 *
 * @return
 */
_command insert_html_anchor() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   _str anchor_line = '';
   _str result=show('-modal _html_insert_anchor_form');
   //Bring up the _insert_anchor dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   //anchor_line = case_html_string('<A NAME="'):+_param1:+case_html_string('"></A>');
   _str begin_tag = case_html_string('<A');
   insert_html40_attributes(begin_tag);
   begin_tag = begin_tag:+case_html_string(' Name="',1):+_param1:+'">';
   _str end_tag = case_html_string('</A>');

   //<A NAME=""></A>
   insert_html_tag(begin_tag,end_tag,true,false);

}
int _OnUpdate_insert_html_anchor(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
/**
 * Inserts an html horizontal line tag into the current document
 * at the cursor
 *
 * @return
 */
_command insert_html_hline() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   // Bulletin Board Code HR tag has no attributes
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('[hr]','',true,false);
      return 0;
   }

   _str hline_line = '';
   _str result=show('-modal _html_insert_hline_form');
   //Bring up the _html_insert_link dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   //messageNwait('_param1 '_param1' _param2 '_param2' _param3 '_param3' _param4'_param4);
   //<HR SIZE="" WIDTH="" ALIGN="" NOSHADE>
   //hline_line = '<HR WIDTH=':+use_number_quote(_param1);
   hline_line = case_html_string('<Hr');
   insert_html40_attributes(hline_line);
   if (_param1 !='') {
      hline_line = hline_line:+case_html_string(' Width=',1):+html_use_quote(_param1);
   }
   if (_param2 != '') {
      hline_line = hline_line:+case_html_string(' Size=',1):+html_use_quote(_param2);
   }
   if (_param3 != '') {
      hline_line = hline_line:+case_html_string(' Align=',1):+case_html_string(_param3,2);
   }
   if (_param4) {
      hline_line = hline_line:+case_html_string(' Noshade',1);
   }
   hline_line = hline_line:+'>';
   //messageNwait('hline 'hline_line);
   insert_html_tag(hline_line,'',true,false);

}
int _OnUpdate_insert_html_hline(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * inserts a link to a file or URL in the current document at
 * the cursor
 *
 * @return
 */
_command insert_html_link() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');

   _str link_line = '';
   _str result=show('-modal _html_insert_link_form',_LanguageInheritsFrom('bbc'));
   //Bring up the _html_insert_link dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // Bulletin Board Code URL tags
   if (_LanguageInheritsFrom('bbc')) {
      if (_param2!='') {
         insert_html_tag('[url="'_param1'"]', '[/url]', true, false);
         _insert_text(_param2);   //Insert text for the link
      } else {
         insert_html_tag('url');
         _insert_text(_param1);
      }
      return 0;
   }
   //link_line = case_html_string('<A HREF="':+_param1:+'">'):+_param2:+case_html_string('</A>');
   _str begin_tag = case_html_string('<A');
   insert_html40_attributes(begin_tag);
   begin_tag= begin_tag:+case_html_string(' Href="',1):+_param1:+'">';
   _str end_tag = case_html_string('</A>');
   //<A HREF=""></A>
   insert_html_tag(begin_tag,end_tag,true,false);
   _insert_text(_param2);   //Insert text for the link

}
int _OnUpdate_insert_html_link(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * Searches the file for anchor anchors and stores them in the
 * anchor list.
 *
 * @param anchor_list           array of strings for containing anchor names
 * @param file_name             name of file to search
 */
void get_anchor_list(_str (&anchor_list)[],_str file_name = p_buf_name)
{
   //\<A NAME\=\"?@\"?*\>
   anchor_list._makeempty();
   if (file_name =='') {
      //we should never get here, but just in case...
      return;
   }
   _str anchor_re ='\<A NAME\=\"?@\"?*\>';
   //RE for at anchor name
   int temp_view_id, orig_view_id;
   int status = _open_temp_view(file_name,temp_view_id,orig_view_id,"");
   //Create temp view to search
   if (status) {
      //If for some reason unable to open the temp buffer, return
      return;
   }
   top();
   //Move to the top of the buffer
   int x = 0;
   //Counter to 0
   status = search(anchor_re,'+<@hixcsr');
   //Search for anchor RE
   for (;;) {
      if (status) {
         //If it fails, break
         break;
      }
      get_line(auto line);
      _str anchor='',junk;
      parse line with '\<A NAME\=\"','ri' anchor '\"','ri' junk;
      //Get line and parse it to extract anchor name
      if (anchor != '') {
         anchor_list[x] = anchor;
         //Add anchor to array
         //messageNwait('anchor 'anchor);
         x++;
      }
      status = repeat_search();
      //Repeat search
   }
   p_window_id = orig_view_id;
   //Switch Back to file
   _delete_temp_view(temp_view_id);
   //Delete temp view
   return;
}

/**
 * inserts an image file into the current document at the cursor
 *
 * @return
 */
_command insert_html_image() name_info(','VSARG2_REQUIRES_EDITORCTL|VSARG2_MARK)
{
   if (!checkHTMLContext()) return('');
   _str image_line = '';

   _str result=show('-modal _html_insert_image_form',_LanguageInheritsFrom('bbc'));
   //Bring up the _html_insert_image dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   // Bulletin Board Code img tags just set width and height
   if (_LanguageInheritsFrom('bbc')) {
      insert_html_tag('[img width='_param3' height='_param2']'_param1,'[/img]', true, false);
      return 0;
   }

   //_message_box('location '_param1' height '_param2' width '_param3' alignment '_param4);
   image_line = case_html_string('<Img');
   insert_html40_attributes(image_line);
   image_line= image_line:+case_html_string(' Src="',1):+_param1:+'"';
   if (_param2 != '') {
      image_line = image_line:+case_html_string(' Height=',1):+html_use_quote(_param2);
   }
   if (_param3 != '') {
      image_line = image_line:+case_html_string(' Width=',1):+html_use_quote(_param3);
   }

   //Insert the source image name, height, width

   if (_param4 != '(Default)') {
      //Check for an alignment.  If there is one, insert it
      image_line = image_line:+case_html_string(' Align=',1):+case_html_string(_param4,2);
   }
   if (_param6 != '' && _param6 != 0) {
      image_line = image_line:+case_html_string(' Border=',1):+html_use_quote(_param6);

   }
   if (_param5 != '') {
      //Check for Alternate text.  If there is any, insert it
      image_line = image_line:+case_html_string(' Alt="',1):+_param5:+'"';
   }
   image_line = image_line:+'>';
   //End the HTML image tag
   //<IMG SRC= HEIGHT= WIDTH= ALIGN= Alt=>

   //_message_box(image_line);
   insert_html_tag(image_line,'',true,false);
   //Insert the HTML image tag at the cursor
   return(0);
}
int _OnUpdate_insert_html_image(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}

/**
 * Inserts HTML font tags either around selected text or at the cursor.
 *
 * @return
 */
_command insert_html_font() name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   // Bulletin Board Code font tags only set font type face
   if (_LanguageInheritsFrom('bbc')) {
      _str fontface = show('-modal _html_font_form');
      if (fontface =='') {
         return(COMMAND_CANCELLED_RC);
      }
      insert_html_tag('[font='fontface']','[/font]', true, false);
      return 0;
   }

   _str font_line = '';
   _str result=show('-modal _html_insert_font_form');
   //Bring up the _html_insert_image dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }

   //_message_box('_param1 '_param1' _param2'_param2);
   set_font_tags(_param3);
   if (_param4 != '') {
      execute('insert_html_'_param4);
   }
   if (!strieq(_param1,"<font>")) {
      insert_html_tag(_param1,_param2,true,false);
   }
}
int _OnUpdate_insert_html_font(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
/**
 * Sets the values for the styles tags based on the checkboxes
 * turned on for the _html_insert_font dialog
 *
 * @param styles_tags
 */
static void set_font_tags(struct style_entry (styles_tags)[] ){

   int x;
   for (x = 0; x < styles_tags._length(); x++ ) {
      if (styles_tags[x].onoffval) {
         add_font_param(styles_tags[x].onoffval,styles_tags[x].style_name);
      }
   }
   return;
}
/**
 * Determines if val should be added to the list of opening and closing tags.
 *
 * @param onOffval              switch value
 * @param val
 *                              the tag value to add
 */
static void add_font_param( int onOffval, _str val){
   if (onOffval) {  //A needless check, but you can never be too careful
      insert_html_tag(val);
   }
   return;
}


_command insert_html_list()name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL)
{
   if (!checkHTMLContext()) return('');

   // Bulletin Board Code list tag has no options
   if (_LanguageInheritsFrom('bbc')) {
      insert_block_tags('[list]','[/list]');
      return 0;
   }

   _str result=show('-modal _html_insert_list_form');
   //Bring up the _html_insert_image dialog
   if (result=='') {
      return(COMMAND_CANCELLED_RC);
   }
   _str list_tag='';
   if (_param1) {
      list_tag = case_html_string('Ol');
   } else {
      list_tag = case_html_string('Ul');
   }
   _str start_tag = '<':+list_tag;
   _str end_tag = '</':+list_tag:+'>';

   insert_html40_attributes(start_tag);

   if (_param3 != '') {
      start_tag = start_tag:+case_html_string(' Start=',1):+html_use_quote(_param3);
   }
   if (_param2 != '') {
      start_tag = start_tag:+case_html_string(' Type="',1):+_param2:+'"';
   }
   start_tag = start_tag:+'>';
   int col = p_col;
   insert_html_tag(start_tag,end_tag,true,false);
}
int _OnUpdate_insert_html_list(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid,true));
}
_command insert_html_body()name_info(','VSARG2_MARK|VSARG2_REQUIRES_EDITORCTL){

   if (!checkHTMLContext()) return('');

   struct tag_attribute attribute_list[];
   boolean prev_val = false;

   typeless p;
   _save_pos2(p);
   int col = 0;
   int start_col = p_col;
   int start_line= p_line;
   top();
   int p3=-1;
   int p2=-1;
   if (!search('\<BODY?*','@<hrixcs')) {  //Search for body
      //If found, we have to alter the old one...
      prev_val=true;
      col=p_col;
      _save_pos2(p2);
      select_char();
      if (search('\>','@>rhixcs')) {  //Look for the end
         _restore_pos2(p);
         if (p2>=0 ) _free_selection(p2);
         message(nls("Unable to locate closing '>' for <BODY>"));
         return('');
      } else {
         //Locate the end
         _save_pos2(p3);
         lock_selection('q');
         extract_body_attributes(attribute_list);
      }
   } else {  // If no pre-existing body tag, insert a new one
      _restore_pos2(p);
      p= -1;
      col=p_col;
   }

   _str result=show('-modal _html_insert_body_tag_form',attribute_list);
   //Bring up the _html_insert_image dialog
   if (result=='') {
      if (p3>=0) _free_selection(p3);
      if (p2>=0 ) _free_selection(p2);
      if (p>=0) {
         _restore_pos2(p);
      }
      deselect();
      return(COMMAND_CANCELLED_RC);
   }
   //Add on the attributes
   _str body_line = case_html_string('<Body');
   if (_param1 !='') {
      body_line= body_line:+_param1;
   }
   body_line=body_line:+'>';
   //messageNwait('body' body_line);

   if (prev_val) {
      typeless beginning;
      _save_pos2(beginning);
      _restore_pos2(p2);  //Go to the beginning of the body tag
      p2=-1;
      // select_char();      //Start a selection
      int markid=_alloc_selection();
      _select_char(markid);
      _restore_pos2(p3);  //Go to the end of the body tag
      p3=-1;
      _select_char(markid);
      _delete_selection(markid); //Delete the body tag
      _free_selection(markid);
      _restore_pos2(beginning);
      _insert_text(body_line); //Insert the tag
      search('\<\/BODY\>','@<rhixcs');
      //select_char();
      markid=_alloc_selection();
      _select_char(markid);
      typeless b4del;
      _save_pos2(b4del);
      search('\>','@>rhixcs');
      _select_char(markid);
      _delete_selection(markid);
      _free_selection(markid);
      _restore_pos2(b4del);
      _insert_text(case_html_string('</Body>'));
      _restore_pos2(p);
      p= -1;
      p_col = start_col;
      p_line = start_line;
   } else {
      _str begin_tag = body_line;
      _str end_tag = case_html_string('</Body>');
      insert_html_tag(begin_tag,end_tag,true,false);
   }
   if (p3>=0) _free_selection(p3);
   if (p2>=0 ) _free_selection(p2);
   if (p>=0) _free_selection(p);
   deselect();
}
int _OnUpdate_insert_html_body(CMDUI cmdui,int target_wid,_str command)
{
   return(htmlOnUpdate(target_wid));
}
static  _str attribute_names[] = {"BACKGROUND","BGCOLOR","TEXT","LINK","ALINK","VLINK"};

void extract_body_attributes(struct tag_attribute (&attribute_list)[])
{
   attribute_list._makeempty();
   int a, x, y=0;
   _str line='';
   _str attrib_val='';
   _str rest='';
   for (x = 0; x < attribute_names._length() ;x++) {
      begin_select();
      int status=search(attribute_names[x]:+'=','@+hIWXC');
      if (!status) {
         if (attribute_names[x] == "BACKGROUND" ) {
            get_line(line);
            parse line with (attribute_names[x]:+'="'),'ir' attrib_val '"','r' rest;
            if (attrib_val !='') {
               attribute_list[y].attribute_name = attribute_names[x];
               attribute_list[y].attribute_val= attrib_val;
               y++;
            }
         } else {
            get_line(line);
            parse line with (attribute_names[x]:+'=("|)'),'ir' attrib_val '([ ">$])','r' rest;
            int loc = pos('\#',attrib_val,1,'r');

            if (loc) { //We have a hex val
               attribute_list[y].attribute_name = attribute_names[x];
               attrib_val = substr(attrib_val,loc+1,length(attrib_val));
               attribute_list[y].attribute_val= attrib_val;

               _str red = substr(attrib_val,1,2);
               _str green = substr(attrib_val,3,2);
               _str blue = substr(attrib_val,5,2);
               attribute_list[y].attribute_color= hex2dec('0x':+blue:+green:+red);

               for (a = 0; a < ColorEntryList._length(); a++) {
                  if (ColorEntryList[a].rgb_val == attribute_list[y].attribute_color) {
                     attribute_list[y].attribute_val = ColorEntryList[a].color_name;
                     break;
                  }
               }
               y++;
            } else {
               for (a = 0; a < ColorEntryList._length(); a++) {
                  if (ColorEntryList[a].color_name == attrib_val) {
                     attribute_list[y].attribute_name = attribute_names[x];
                     attribute_list[y].attribute_color = ColorEntryList[a].rgb_val;
                     attribute_list[y].attribute_val= attrib_val;
                     y++;
                     break;
                  }
               }

            }
         }
      }
   }
}


/*************************************************************************/
defeventtab _html_insert_list_form;

static _str html_ordered_listvals[] = {"A","a","I","i","1"};
static _str html_unordered_listvals[] = {"Circle","Disc","Square"};

ctlok.on_create(){
   initialize_style_vals();
}
_ordered_list.lbutton_up()
{
   _list_types._lbclear();
   int x;
   for (x = 0; x < html_ordered_listvals._length(); x++ ) {
      _list_types._lbadd_item(html_ordered_listvals[x]);
   }
}

_unordered_list.lbutton_up()
{
   _list_types._lbclear();
   int x;
   for (x = 0; x < html_unordered_listvals._length(); x++ ) {
      _list_types._lbadd_item(html_unordered_listvals[x]);
   }
}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
void ctlok.lbutton_up()
{
   _param1 = _ordered_list.p_value;
   _param2 = _list_types.p_text;
   if (_list_start.p_text!="" && (!isinteger(_list_start.p_text) || _list_start.p_text<1)) {
      _list_start._text_box_error('Specify an integer value greater than or equal to 1');
      return;
   }
   _param3 = _list_start.p_text;
   p_active_form._delete_window(1);
}
/*************************************************************************/
defeventtab _tag_style_form;
ctlok.on_create()
{
   _style_val.p_text = _param8;
   _style_class.p_text = _param9;
   _style_id.p_text = _param10;
}
ctlok.lbutton_up()
{
   if (_style_val.p_text!='') {
      _param8 = _style_val.p_text;
   } else {
      _param8='';
   }
   if (_style_class.p_text!='') {
      _param9 =_style_class.p_text;
   } else {
      _param9='';
   }
   if (_style_id.p_text!='') {
      _param10 =_style_id.p_text;
   } else {
      _param10='';
   }
   p_active_form._delete_window(1);
}
/*************************************************************************/
defeventtab _html_insert_styles_form;
void _styles_url.lbutton_up()
{
   if (_styles_link.p_value) {
      ctl_stylesbrowse.p_enabled=false;
   }
}
void _styles_file.lbutton_up()
{
   if (_styles_link.p_value) {
      ctl_stylesbrowse.p_enabled=true;
   }
}
ctlok.on_create()
{
   _styles_tag.p_value = 1;
   _styles_css.p_value = 1;
   _styles_loc.p_enabled = 0;
   _styles_tag.call_event(_styles_tag,LBUTTON_UP,'W');

}
void ctlok.lbutton_up(){
   if (_styles_tag.p_value) {
      _param1= 1;
   } else {
      _param1=0;
      _param2=_styles_loc.p_text;
      if (_param2 == '') {
         _styles_loc._text_box_error("No entry for style sheet location");
         return;
      }
   }
   if (_styles_css.p_value) {
      _param3 = 'text/css';
   } else {
      _param3 = 'text/javascript';
   }
   p_active_form._delete_window(1);
}
void _styles_link.lbutton_up(){
   if (_styles_link.p_value) {
      _styles_loc.p_enabled = 1;
      ctl_stylesbrowse.p_enabled = 1;
      _styles_url.p_enabled=1;
      _styles_file.p_enabled=1;
   } else {
      _styles_loc.p_enabled = 0;
      ctl_stylesbrowse.p_enabled = 0;
      _styles_url.p_enabled=0;
      _styles_file.p_enabled=0;
   }
}
void ctl_stylesbrowse.lbutton_up()
{
   _str format_list='Style sheets('STYLE_FILE_EXT')';
   _str default_exts= STYLE_FILE_EXT;
   format_list = format_list:+', All Files('ALLFILES_RE')';

   _str result=_OpenDialog('-new -modal',
                      'Open Style Sheet',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      default_exts,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open style sheet dialog box"
                     );
   //Open the file open dialog set to the html browser
   if (result=='') {
      return;
   }
   _styles_loc.p_text = _form_parent().convert_filename_to_link(result);
}

/*************************************************************************/
defeventtab _html_insert_table_form;

ctlok.on_create()
{
   initialize_style_vals();
   _table_top.p_value = 1;
   _table_none.p_value = 1;
   _table_percent.p_value = 1;
   _bg_color_sample.p_enabled = 0;
   _bg_border_sample.p_enabled = 0;
}
void ctlbgcolors.lbutton_up(){

   _str result = show('-modal _html_insert_rgb_color_form');
   if (result != '') {
      _bg_color_sample.p_enabled = 1;
      _bg_color_sample.p_backcolor = (int)result;

   }
}
void ctlbgborder.lbutton_up(){

   _str result = show('-modal _html_insert_rgb_color_form');
   if (result != '') {
      _bg_border_sample.p_enabled = 1;
      _bg_border_sample.p_backcolor = (int)result;

   }
}

void ctlok.lbutton_up(){
   _param1 = '';
   _param2 = '';

   if (!_table_none.p_value) {
      _param1 = _param1:+_form_parent().case_html_string(' Align=',1);
      if (_table_left.p_value) {
         _param1 = _param1:+_form_parent().case_html_string('Left',2);
      } else if (_table_right.p_value) {
         _param1 = _param1:+_form_parent().case_html_string('Right',2);
      } else {
         _param1 = _param1:+_form_parent().case_html_string('Center',2);
      }
   }
   if (_bg_color_sample.p_enabled) {
      _param1 = _param1:+_form_parent().case_html_string(' Bgcolor="',1):+_form_parent().convert_2_html_color(_bg_color_sample.p_backcolor):+'"';
   }
   if (_table_border.p_text !='') {
      if (!isinteger(_table_border.p_text) || _table_border.p_text<0) {
         _table_border._text_box_error('Specify an integer value greater than or equal to 0');
         return;
      }
      _param1 = _param1:+_form_parent().case_html_string(' Border=',1):+_form_parent().html_use_quote(_table_border.p_text);

   }
   if (_bg_border_sample.p_enabled) {
      _param1 = _param1:+_form_parent().case_html_string(' Bordercolor="',1):+_form_parent().convert_2_html_color(_bg_border_sample.p_backcolor):+'"';
   }
   if (_table_padding.p_text !='') {
      if (!isinteger(_table_padding.p_text) || _table_padding.p_text<0) {
         _table_padding._text_box_error('Specify an integer value greater than or equal to 0');
         return;
      }
      _param1 = _param1:+_form_parent().case_html_string(' Cellpadding=',1):+_form_parent().html_use_quote(_table_padding.p_text);

   }
   if (_table_spacing.p_text !='') {
      if (!isinteger(_table_spacing.p_text) || _table_spacing.p_text<0) {
         _table_spacing._text_box_error('Specify an integer value greater than or equal to 0');
         return;
      }
      if (_table_spacing.p_text < 0 || _table_spacing.p_text >10000 ) {
         _table_spacing._text_box_error('Specify value between 0 and 10000');
         return;
      }
      _param1 = _param1:+_form_parent().case_html_string(' Cellspacing=',1):+_form_parent().html_use_quote(_table_spacing.p_text);

   }

   _str percent ='';
   if (_table_percent.p_value) {
      percent = '%';
   }
   if (_table_width.p_text !='') {    //Checks for the table Width
      if (_table_percent.p_value) {
         if (_table_width.p_text < 1 || _table_width.p_text > 100) {
            _table_width._text_box_error('Specify integer value between 0 and 100');
            return;
         }
      } else {
         if (!isinteger(_table_width.p_text) || _table_width.p_text < 0 ) {
            _table_width._text_box_error('Specify an integer value greater than or equal to 0');
            return;
         }
      }
      _param1 =_param1:+_form_parent().case_html_string(' Width=',1):+_form_parent().html_use_quote(_table_width.p_text:+percent);

   }
   if (_table_height.p_text != '') {   //Checks for the table Height
      if (_table_percent.p_value) {
         if (_table_height.p_text < 1 || _table_height.p_text > 100) {
            _table_height._text_box_error('Specify integer value between 0 and 100');
            return;
         }
      } else {
         if (!isinteger(_table_height.p_text) || _table_height.p_text < 0 ) {
            _table_height._text_box_error('Specify an integer value greater than or equal to 0');
            return;
         }
      }
      _param1 =_param1:+_form_parent().case_html_string(' Height=',1):+_form_parent().html_use_quote(percent:+_table_height.p_text);
   }
   if (_table_hspace.p_text !='') {    //Checks for the table HSpace
      if (!isinteger(_table_hspace.p_text) || _table_hspace.p_text<0) {
         _table_hspace._text_box_error('Specify an integer value greater than or equal to 0');
         return;
      }
      if (_table_hspace.p_text < 0 || _table_hspace.p_text >10000 ) {
         _table_hspace._text_box_error('Specify value between 0 and 10000.');
         return;
      }
      _param1 = _param1:+_form_parent().case_html_string(' Hspace=',1):+_form_parent().html_use_quote(_table_hspace.p_text);

   }
   if (_table_vspace.p_text !='') {    //Checks for the table VSpace
      if (!isinteger(_table_vspace.p_text) || _table_vspace<0) {
         _table_vspace._text_box_error('Vertical space must be an integer value.');
         return;
      }
      if (_table_vspace.p_text < 0 || _table_vspace.p_text >10000 ) {
         _table_vspace._text_box_error('Specify value between 0 and 10000.');
         return;
      }
      _param1 = _param1:+_form_parent().case_html_string(' Vspace=',1):+_form_parent().html_use_quote(_table_vspace.p_text);

   }
   _param2 = _table_caption.p_text;
   if (_table_top.p_value) {
      _param3 = 'Top';
   } else {
      _param3 = 'Bottom';
   }
   p_active_form._delete_window(1);
}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_font_form;

ctlok.on_create(boolean isgeneric = false){
   initialize_style_vals();
   FillInFontNameList(isgeneric);
}
ctlok.lbutton_up(){
   p_active_form._delete_window(_font_name_list.p_text);
}

/**
 * Inserts the list of fonts found in the OS into the insert_font dialog
 * Parameters:   None  (Originally written by C. Maurer, altered by C. Cunning
 */
_str generic_font_types[] = {"Monospace","Fantasy","Serif","Sans Serif","Cursive"};
static void FillInFontNameList(boolean isgeneric = false)
{
   _font_name_list.p_redraw=0;
   _font_name_list.p_picture=0;
   boolean first_time=!_font_name_list.p_Noflines;
   _font_name_list._lbclear();
   /*Handle Font Name List*/
   p_window_id=_font_name_list;
   if (!isgeneric) {
      _font_name_list._insert_font_list(_font_name_list.p_user); //Put names of fonts in list box
   } else {
      int x;
      for (x = 0;x < generic_font_types._length(); x++) {
         _font_name_list._lbadd_item(generic_font_types[x]);

      }
   }

   //messageNwait("FillInFontNameList: _font_name_list="_font_name_list" _font_name_list.p_user="_font_name_list.p_user" N="_font_name_list.p_cb_list_box.p_Noflines);
   //messageNwait('_font_name_list.p_user='_font_name_list.p_user);
   int orig_wid=0;
   _font_name_list._lbsort();
   _font_name_list.p_line = 1;
   //font_name = _font_name_list.p_cb_list_box._lbget_text();
   //_font_name_list.p_text = font_name;

   _font_name_list._lbremove_duplicates();
   int old_line = _font_name_list.p_line;
   orig_wid=p_window_id;
   p_window_id=_font_name_list;
   top();up();
   for (;;) {
      if (down()) break;
      _str name = _lbget_text();
      typeless ft;
      ft=_font_type(name,_font_name_list.p_user);
      int picture=0;
      if (ft & TRUETYPE_FONTTYPE) {
         picture = _pic_tt;
      } else if (ft & DEVICE_FONTTYPE) {
         picture = _pic_printer;
      } else {
         picture=0;
      }
      _lbset_item(name, 60, picture);
   }
   p_after_pic_indent_x=80;
   p_line = old_line;
   //messageNwait('h1 p_auto_size='_font_name_list.p_auto_size);
   //_font_name_list.p_auto_size=0;
   p_picture = _pic_tt;
   _font_name_list.p_redraw=1;
   p_window_id=orig_wid;
   /*End Handle Font Name List*/
   if (first_time) {
      _font_name_list.p_auto_size=1;
   }
   _font_name_list._lbtop();
}
void _font_name_list.on_change(int reason)
{
   if (CHANGING_NAME_LIST) {
      _str font_name=p_text;
      _str lbtext=_lbget_text();
      if (lowcase(font_name)!=lowcase(lbtext)) {
         return;
      }
      _lbselect_line();
      if (font_name == "Serif") {
         _sample_text.p_font_name = "MS Serif";
      } else if (font_name == "Sans Serif") {
         _sample_text.p_font_name = "MS Sans Serif";

      }if (font_name == "Cursive") {
         _sample_text.p_font_name = "Script";
      } else {
         _sample_text.p_font_name = font_name;
      }
   }
}
/*************************************************************************/
defeventtab _html_insert_font_form;

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _html_insert_font_form_initial_alignment()
{
   rightAlign := p_active_form.p_width - 120;
   sizeBrowseButtonToTextBox(_fontname1.p_window_id, ctlfont_browse1.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_fontname2.p_window_id, ctlfont_browse2.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_fontname3.p_window_id, ctlfont_browse3.p_window_id, 0, rightAlign);
   sizeBrowseButtonToTextBox(_fontnameg.p_window_id, ctlfont_browseg.p_window_id);
}

void ctlcolors.lbutton_up(){

   _str result = show('-modal _html_insert_rgb_color_form');
   if (result != '') {
      sample.p_enabled = 1;
      sample.p_backcolor = (int)result;
   }
}

void ctlok.lbutton_up()
{
   _str alignval = _param1 = _param2 = '';

   if (_fontname1.p_text !='' || _fontname2.p_text !='' || _fontname3.p_text != ''
       || _fontnameg.p_text != '' || sample.p_enabled || _font_size.p_text !=''|| _param1 == '') {
      _str htmlfonts = '';
      concat_fontnames(htmlfonts, _fontname1.p_text);
      concat_fontnames(htmlfonts, _fontname2.p_text);
      concat_fontnames(htmlfonts, _fontname3.p_text);
      concat_fontnames(htmlfonts, _fontnameg.p_text);
      _param1 = _param1:+_form_parent().case_html_string('<Font');
      if (sample.p_enabled) {
         _param1 = _param1:+_form_parent().case_html_string(' Color="',1):+_form_parent().convert_2_html_color(sample.p_backcolor):+'"';

      }

      if (htmlfonts != '') {
         _param1 = _param1:+_form_parent().case_html_string(' Face="',1):+htmlfonts:+'"';
      }

      if (_font_size.p_text !='') {
         _param1 = _param1:+_form_parent().case_html_string(' Size=',1):+_form_parent().html_use_quote(_font_size.p_text);
      }
      _param1 = _param1:+'>';
      _param2 = _form_parent().case_html_string('</Font>'):+_param2;
   }
   _param3 = set_styles_tags();

   if (!_fontal_none.p_value) {
      if (_fontal_left.p_value) {
         alignval='left';
      } else if (_fontal_right.p_value) {
         alignval='right';
      } else {
         alignval='center';
      }
   }
   _param4 = alignval;
   _save_form_response();
   p_active_form._delete_window(1);
}

static typeless set_styles_tags() {
   style_entry style_tags[];
   style_tags._makeempty();

   set_styles_tags2(style_tags[0],_bold.p_value,'B');
   set_styles_tags2(style_tags[1],_italic.p_value,'I');
   set_styles_tags2(style_tags[2],_strikethrough.p_value,'Strike');
   set_styles_tags2(style_tags[3],_underline.p_value,'U');
   set_styles_tags2(style_tags[4],_emphasized.p_value,'Em');
   set_styles_tags2(style_tags[5],_strong.p_value,'Strong');
   set_styles_tags2(style_tags[6],_preformated.p_value,'Pre');
   set_styles_tags2(style_tags[7],_code.p_value,'Code');
   set_styles_tags2(style_tags[8],_cite.p_value,'Cite');
   set_styles_tags2(style_tags[9],_plaintext.p_value,'Plaintext');
   set_styles_tags2(style_tags[10],_big.p_value,'Big');
   set_styles_tags2(style_tags[11],_small.p_value,'Small');
   set_styles_tags2(style_tags[12],_superscript.p_value,'Sup');
   set_styles_tags2(style_tags[13],_subscript.p_value,'Sub');
   set_styles_tags2(style_tags[14],_blinking.p_value,'Blink');
   set_styles_tags2(style_tags[15],_nonbreaking.p_value,'Nobr');
   set_styles_tags2(style_tags[16],_address.p_value,'Address');
   set_styles_tags2(style_tags[17],_variable.p_value,'Var');
   set_styles_tags2(style_tags[18],_typewriter.p_value,'Tt');
   set_styles_tags2(style_tags[19],_keyboard.p_value,'Kbd');

   return(style_tags);
}
static void set_styles_tags2(struct style_entry &styles_tag, typeless value, _str name)
{
   styles_tag.onoffval = value;
   styles_tag.style_name = name;
   return;
}

/**
 * Adds nufont to the list of fonts to be used in the &lt;Font&gt; tag
 *
 * @param fontlist              the string containing the current fonts set
 * @param nufont
 *                              the font to be added
 */
static void concat_fontnames( _str &fontlist = '', _str nufont = ''){
   if (nufont != '' ) {
      if (fontlist != '') {
         fontlist = fontlist:+',':+nufont;
      } else {
         fontlist = nufont;
      }
   }
   return;
}
void _fontname1.on_drop_down(int reason){
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
void _fontname2.on_drop_down(int reason){
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
void _fontname3.on_drop_down(int reason){
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
void _fontnameg.on_drop_down(int reason){
   if (p_user=='') {
      _retrieve_list();
      p_user=1; // Indicate that retrieve list has been done
   }
}
void ctlfont_browse1.lbutton_up(){
   _str result = show('-modal _html_font_form');
   if (result !='') {
      p_prev.p_text = result;
      p_prev._set_focus();
   }
}
void ctlfont_browseg.lbutton_up(){
   _str result = show('-modal _html_font_form',1);
   if (result != '') {
      _fontnameg.p_text = result;
      _fontnameg._set_focus();
   }
}
void ctlok.on_create(){
   _html_insert_font_form_initial_alignment();
   initialize_style_vals();
   _fontal_none.p_value = 1;
   int x;
   for (x=-3; x <= MAX_HTML_SIZE; x++) {
      if (x != 0) {
         //Insert the alignment list into the dropdown listbox
         _font_size._lbadd_item(x);
      }
   }
   //_font_size.p_text = DEFAULT_HTML_FONT;
   _retrieve_prev_form();
   sample.p_enabled = 0;

   _bold.p_value= _italic.p_value= _strikethrough.p_value=
   _underline.p_value= _emphasized.p_value= _strong.p_value=
   _preformated.p_value= _code.p_value= _cite.p_value= _plaintext.p_value=
   _big.p_value= _small.p_value= _superscript.p_value= _subscript.p_value=
   _blinking.p_value= _nonbreaking.p_value= _address.p_value=
   _variable.p_value= _typewriter.p_value= _keyboard.p_value=0;

}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*_italic.lbutton_up()
{
   _sample_text.p_font_italic = p_value!=0;
}

_underline.lbutton_up()
{
   _sample_text.p_font_underline = p_value!=0;
}

_bold.lbutton_up()
{
   _sample_text.p_font_bold = p_value!=0;
}

_strikethrough.lbutton_up()
{
   _sample_text.p_font_strike_thru = p_value!=0;
}
*/
/*************************************************************************/
defeventtab _html_insert_script_form;

static _str script_list[] = {"JavaScript","JavaScript1.1","JavaScript1.2","JScript","VBScript","php"};

void ctl_scriptbrowse.on_create()
{
   initialize_style_vals();

   int x;
   for (x=0; x < script_list._length(); x++) {
      _script_lang._lbadd_item(script_list[x]);
   }
   _script_lang._lbsort("a":+_fpos_case);
   _script_file.p_value = 1;
}
void ctlok.lbutton_up()
{
   _param2 = '';
   _param1 = _script_lang.p_text;
   if (_param1 == '') {
      _script_lang._text_box_error('No entry for Script Language');
      return;
   }

   if (_script_file.p_value && _script_filename.p_text != '') {
      _param2 = _script_filename.p_text;
      if ((file_match(maybe_quote_filename(_param2)'  -p',1))== '') {                                         //If there is no such file...
         _script_filename._text_box_error('File does not exist or has not been saved');
         return;
      }
   }
   if (_script_url.p_value) {
      _param2 = _script_filename.p_text;
      _param3 = 1;
   } else {
      _param3 = 0;
   }
   p_active_form._delete_window(1);
}

void _script_file.on_got_focus(){
   ctl_scriptbrowse.p_enabled = 1;
}
void _script_url.on_got_focus(){
   ctl_scriptbrowse.p_enabled = 0;
}

void ctl_scriptbrowse.lbutton_up()
{
   _str format_list='';
   _str default_exts='';
   if (_script_lang.p_text == 'VBScript') {
      format_list='Script Files('VBSCRIPT_FILE_EXT')';
      default_exts= VBSCRIPT_FILE_EXT;
   } else if (_script_lang.p_text == 'PHP') {
      format_list='Script Files('PHP_FILE_EXT')';
      default_exts= PHP_FILE_EXT;
   } else {
      format_list='Script Files('JAVASCRIPT_FILE_EXT')';
      default_exts= JAVASCRIPT_FILE_EXT;
   }
   format_list = format_list:+', All Files('ALLFILES_RE')';

   _str result=_OpenDialog('-new -modal',
                      'Open Script File',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      default_exts,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open Script file dialog box"
                     );
   //Open the file open dialog set to the html browser
   if (result=='') {
      return;
   }
   if (_script_file.p_value) {
      _script_filename.p_text = _form_parent().convert_filename_to_link(result);
   }
   _script_filename.p_text = result;
}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_insert_heading_form;

void _html_insert_heading1.lbutton_up()
{
   _param1 = 1;
   p_active_form._delete_window(1);
}
void _html_insert_heading2.lbutton_up()
{
   _param1 = 2;
   p_active_form._delete_window(1);
}
void _html_insert_heading3.lbutton_up()
{
   _param1 = 3;
   p_active_form._delete_window(1);
}
void _html_insert_heading4.lbutton_up()
{
   _param1 = 4;
   p_active_form._delete_window(1);
}
void _html_insert_heading5.lbutton_up()
{
   _param1 = 5;
   p_active_form._delete_window(1);
}
void _html_insert_heading6.lbutton_up()
{
   _param1 = 6;
   p_active_form._delete_window(1);
}
/*************************************************************************/
defeventtab _html_insert_anchor_form;

void ctlok.on_create(){
   initialize_style_vals();
}
void ctlok.lbutton_up()
{
   _param1 = _anchor_name.p_text;
   if (_param1 == '') {
      _anchor_name._text_box_error("Please specify a anchor name");
      return;
   }
   p_active_form._delete_window(1);
}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_insert_link_form;
void _anchor_selected.lbutton_up()
{
   typeless anchor_list;
   anchor_list._makeempty();
   _str filename=_link_name.p_text;
   _str path=_strip_filename(_form_parent().p_buf_name,'N');
   filename=absolute(filename,path);
   if (file_match('-p 'maybe_quote_filename(filename),1)!="") {
      get_anchor_list(anchor_list, filename);
   }
   //Set anchor list to current list
   load_anchor_lb(anchor_list);

}
void _anchor_current.lbutton_up()
{
   typeless anchor_list;
   anchor_list._makeempty();
   get_anchor_list(anchor_list, _form_parent().p_buf_name);
   //Set anchor list to current list
   load_anchor_lb(anchor_list);
}


void ctl_linkbrowse.on_create(boolean supportBBC=false)
{
   initialize_style_vals();

   _anchor_current.p_value = 1;

   typeless anchor_list;
   anchor_list._makeempty();
   get_anchor_list(anchor_list, _form_parent().p_buf_name);
   //Set anchor list to current list
   load_anchor_lb(anchor_list);
   //Load the anchor list box

   // Disable options that do not apply to Bulletin Board Code tags
   if (supportBBC) {
      _anchor_list.p_enabled=false;
      _anchor_list.p_prev.p_enabled=false;
      _anchor_list.p_next.p_enabled=false;
      _anchor_list.p_next.p_next.p_enabled=false;
      ctl_style.p_enabled=false;
   }

}
/**
 * Loads the Anchor list box wit the list of anchors stored in
 * the array anchor_list
 *
 * @param anchor_list
 */
void load_anchor_lb(_str (&anchor_list)[])
{
   _anchor_list._lbclear();
   if (anchor_list._length() ==0) {
      return;
   }

   int x;
   for (x = 0; x < anchor_list._length(); x++ ) {
      _anchor_list._lbadd_item(anchor_list[x]);

   }
   _anchor_list._lbdeselect_all();

   return;
}

void ctlok.lbutton_up()
{
   _param1 = _link_name.p_text;
   _param2 = _link_text.p_text;
   if (_param2 =='' && ctl_style.p_enabled /* html, not bbc */) {
      _link_text._text_box_error("No entry for text to be displayed for link");
      return;
   }
   if (!pos('http:',_param1,1,'I') && pos('www',_param1,1,'I')) {
      _param1='http://':+_param1;
   }

   if (_param1 == '') {
      if (_anchor_current.p_value && !_anchor_list._lbfind_selected(1)) {
         _param1='#':+ _anchor_list._lbget_seltext();

      } else {
         _message_box("No entry for file or URL to be linked");
         return;
      }

   }

   if (_anchor_selected.p_value) {
      _param1= _link_name.p_text;
      //_message_box(_param1);
      _param1=_param1:+'#':+ _anchor_list._lbget_seltext();
   }


   p_active_form._delete_window(1);
}

/**
 * converts the filename provided to proper HTML format
 *
 * @param filename              filename to be converted
 *
 * @return
 *         the converted filename
 */
_str convert_filename_to_link(_str filename)
{

   if (filename == '') {
      return('');
   } else if (last_char(filename) == '"') {
      filename = strip(filename,'B','"');
   }

   if (!LanguageSettings.getUsePathsForFileEntries(html_langId())) {
      return(_strip_filename(filename,'P'));
   }

   filename= stranslate(filename,'|',':');
   //Change colon to pipe
   filename= stranslate(filename,'/','\');
   //Change backslash to forward slash
   filename= 'file://':+filename;
   //Add the beginning of the file declaration
   //file:///<drive>|/<path>/<file>
   return(html_lowcase_filename(filename));
}
void ctl_linkbrowse.lbutton_up()
{

   _str format_list='HTML Files('HTML_FILE_EXT'), All Files('ALLFILES_RE')';
   _str result=_OpenDialog('-new -modal',
                      'Open HTML File',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      HTML_FILE_EXT,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open HTML file dialog box"
                     );
   //Open the file open dialog set to the html browser
   if (result=='') {
      return;
   }
   _link_name.p_text = _form_parent().convert_filename_to_link(result);
   //Set the location to the result returned

   typeless anchor_list;
   anchor_list._makeempty();
   get_anchor_list(anchor_list,result);
   load_anchor_lb(anchor_list);
   //Type is set to File
   //_message_box(result);
   _anchor_selected.p_value= 1;
}

void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_insert_applet_form;

void ctl_appletbrowse.on_create()
{
   initialize_style_vals();

   _applet_loc.p_enabled = 0;
   int x;
   for (x=0; x <= MAX_BORDER_THICKNESS ; x++) {
      //Insert the list of values into the dropdown listbox
      _applet_borderlb._lbadd_item(x);
   }
   int wid=p_window_id;
   p_window_id=_applet_borderlb;
   _lbtop();
   p_window_id=wid;
   _applet_borderlb.p_text=_applet_borderlb._lbget_text();
   //Set the first value to the top


}

void _applet_url.lbutton_up()
{
   if (_applet_url.p_value) {
      _applet_loc.p_enabled = 1;
   } else {
      _applet_loc.p_enabled = 0;
   }
}
void ctl_appletbrowse.lbutton_up()
{

   _str format_list='Class Files('APPLET_FILE_EXT'), All Files('ALLFILES_RE')';
   _str result=_OpenDialog('-new -modal',
                      'Open Class File',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      APPLET_FILE_EXT,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open Class file dialog box"
                     );
   //Open the file open dialog set to the html browser
   if (result=='') {
      return;
   }
   _applet_name.p_text = _form_parent().convert_filename_to_link(result);
   //Set the location to the result returned
}

void ctlok.lbutton_up()
{

   if (_applet_url.p_value && _applet_loc.p_text == '') {
      _message_box('No entry for URL');
      return;
   }
   _param1="";
   if (_applet_loc.p_enabled && _applet_loc.p_text !='') {
      if (!pos('http:',_param1,1,'I') && pos('www',_param1,1,'I')) {
         _param1='http://';
      }
      _param1 = _param1:+_applet_loc.p_text;
   }
   if (_applet_name.p_text == '') {
      _message_box('No entry for Applet Name');
      return;
   }
   if (_applet_height.p_text != '') {
      if (!isinteger(_applet_height.p_text)||_applet_height.p_text < 0 ) {
         _applet_height._text_box_error('Specify integer value greater than or equal to 0');
         return;
      }
   }
   if (_applet_width.p_text != '') {
      if (!isinteger(_applet_width.p_text)||_applet_width.p_text < 0 ) {
         _applet_width._text_box_error('Specify integer value greater than or equal to 0');
         return;
      }
   }
   if (_applet_borderlb.p_text != '') {
      if (!isinteger(_applet_borderlb.p_text)||_applet_borderlb.p_text < 0 ) {
         _applet_borderlb._text_box_error('Specify integer value greater than or equal to 0');
         return;
      }
   }
   _param2 = _applet_name.p_text;
   //<APPLET CODEBASE="www.foo.com" CODE="foo.class" WIDTH="" HEIGHT="" ALT="" BORDER="">
   _param3 = _applet_width.p_text;
   _param4 = _applet_height.p_text;
   _param5 = _applet_alt.p_text;
   _param6 = _applet_borderlb.p_text;
   p_active_form._delete_window(1);
}

void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_insert_hline_form;

void ctlok.on_create(){
   initialize_style_vals();
   _width_percent.p_value = 1;

   int x;
   for (x=1; x <= MAX_HLINE_THICKNESS ; x++) {
      //Insert the list of values into the dropdown listbox
      _thicknesslb._lbadd_item(x);
   }

   _lineal_none.p_value = 1;
   //Alignment Defaults to none
}

void ctlok.lbutton_up(){

   if (_width_percent.p_value && _line_width.p_text != '') {
      //Make sure that the values is within a percent value
      if (_line_width.p_text > 100 || _line_width.p_text < 0 ) {
         _line_width._text_box_error('Specify integer value between 0 and 100');
         return;
      }
      _param1 = _line_width.p_text:+'%';
   } else {
      if (_line_width.p_text != '' && (!isinteger(_line_width.p_text) || _line_width.p_text <0) ) {
         _line_width._text_box_error('Speicfy an integer value greater than or equal to 0');
         return;
      }
      _param1 = _line_width.p_text;
   }
   _param2 = _thicknesslb.p_text;
   //Set the thickness of the line

   //SEt the alignment....
   if (_lineal_left.p_value) {
      _param3 = "Left";
   } else if (_lineal_right.p_value) {
      _param3 = "Right";
   } else if (_lineal_center.p_value) {
      _param3 = "Center";
   } else {
      _param3 ='';
   }
   _param4 = _shading_off.p_value;
   //Set the shading
   p_active_form._delete_window(1);

}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}
/*************************************************************************/
defeventtab _html_insert_image_form;

static _str alignList[] = {"(Default)","Top","Left","Right","Center","Middle","Bottom","Textop","Absbottom","Absmiddle","Baseline"};
//bottom|middle|top|left|right|texttop|absmiddle|baseline|absbottom

void ctl_imagebrowse.on_create(boolean supportBBC=false)
{

   initialize_style_vals();
   _dim_percent.p_value = 1;
   //By default we start with file

   // Disable options that do not apply to Bulletin Board Code tags
   if (supportBBC) {
      _image_alttext.p_enabled=false;
      _image_alttext.p_prev.p_enabled=false;
      _dim_percent.p_value=0;
      _dim_pixel.p_value=1;
      _dim_percent.p_enabled=false;
      ctl_style.p_enabled=false;
      frame1.p_enabled=false;
      _image_alignlb.p_enabled=false;
      _image_border.p_enabled=false;
      _image_border.p_prev.p_enabled=false;
   }

   int x;
   for (x=0; x < alignList._length(); x++) {
      //Insert the alignment list into the dropdown listbox
      _image_alignlb._lbadd_item(alignList[x]);
   }
   _image_alignlb._lbsort("a":+_fpos_case);
   //Sort them

   int wid=p_window_id;
   p_window_id=_image_alignlb;
   _lbtop();
   p_window_id=wid;
   _image_alignlb.p_text=_image_alignlb._lbget_text();
   //Set the first value to the top
   _image_border.p_text = 0;
}

void ctlok.lbutton_up()
{
   _param1= _image_loc.p_text;
   //Get the location of the image file
   if (_param1 == '') {
      _image_loc._text_box_error('No entry for image location');
      return;
   }

   if (!pos('http:',_param1,1,'I') && pos('www',_param1,1,'I')) {
      _param1='http://':+_param1;
   }

   _param2 = _image_height.p_text;
   _param3 = _image_width.p_text;
   //set the height and width
   if (_param2 != '' && _param3 != '') {
      if (_dim_percent.p_value ) {

         if (_param2 > 100 || _param2 < 0 ) {
            _image_height._text_box_error('Specify integer value between 0 and 100');
            return;
         }
         if (_param3 > 100 || _param3 < 0  ) {
            _image_width._text_box_error('Specify integer value between 0 and 100');
            return;
         }
         _param2=_param2:+'%';
         _param3=_param3:+'%';
      } else {
         if (!isinteger(_param2) || _param2<0) {
            _image_height._text_box_error('Specify integer value greater than or equal to 0');
            return;
         }
         if (!isinteger(_param3) || _param3<=0) {
            _image_width._text_box_error('Specify integer value greater than or equal to 0');
            return;
         }

      }
   }
   if (_image_border.p_text != '' && (!isinteger(_image_border.p_text) ||_image_border.p_text<0)) {
      _image_border._text_box_error('Specify integer value greater than or equal to 0');
      return;
   }
   _param4 = _image_alignlb.p_text;
   _param5 = _image_alttext.p_text;
   _param6 = _image_border.p_text;
   //Set the alternate text

   p_active_form._delete_window(1);

}

void ctl_imagebrowse.lbutton_up()
{

   _str format_list='Image Files('IMG_FILE_EXT'), All Files('ALLFILES_RE')';
   _str result=_OpenDialog('-new -modal',
                      'Open Image File',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      IMG_FILE_EXT,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open Image dialog box"
                     );
   //Open the file open dialog set to the image browser
   if (result=='') {
      return;
   }
   _image_loc.p_text = _form_parent().convert_filename_to_link(result);
   _str ext = _get_extension(result);
   if (pos(ext,IMG_FILE_EXT,1,'I')) {
      int status;
      int width=0,height=0;
      if (file_eq(ext,'gif')) {
         status = GetGifDimension(result,width,height);
      } else if (file_eq(ext,'jpg') || file_eq(ext,'jpeg')) {
         status = GetJpegDimension(result,width,height);
      } else {
         status = GetBmpDimension(result,width,height);
      }
      //_message_box('height ' height ' width ' width);
      _image_height.p_text = height;
      _image_width.p_text = width;
      _dim_pixel.p_value  = 1;
   }


}
void ctl_style.lbutton_up()
{
   show('-modal _tag_style_form');
}

/*************************************************************************/

static struct tag_attribute cleanlist()[] {
   struct tag_attribute x[];
   x._makeempty();
   return(x);

}
defeventtab _html_insert_body_tag_form;

#define UNASSIGNED_COLOR_TEXT             '(Unassigned)'

ctlok.on_create(struct tag_attribute attribute_list[]= cleanlist())
{
   _html_insert_body_tag_form_initial_alignment();

   _bg_color.p_ReadOnly=
   _text_color.p_ReadOnly=
   _link_color.p_ReadOnly=
   _vlink_color.p_ReadOnly=
   _alink_color.p_ReadOnly=0;

   _bg_color.p_text=
   _text_color.p_text=
   _link_color.p_text=
   _vlink_color.p_text=
   _alink_color.p_text=UNASSIGNED_COLOR_TEXT;

   _text_sample.p_forecolor =0x000000;
   _link_sample.p_forecolor =0xFF0000;
   _alink_sample.p_forecolor=0x800080;
   _vlink_sample.p_forecolor=0x0000FF;

   int x;
   for (x = 0; x < attribute_list._length(); x++) {
      switch (attribute_list[x].attribute_name) {
      case 'BACKGROUND':
         {
            _body_image.p_text= attribute_list[x].attribute_val;
            break;}
      case 'BGCOLOR':
         {
            _bg_color.p_text= attribute_list[x].attribute_val;
            _text_sample.p_backcolor =
            _link_sample.p_backcolor =
            _alink_sample.p_backcolor=
            _vlink_sample.p_backcolor=
            _bg_sample.p_backcolor =attribute_list[x].attribute_color;
            break;
         }
      case 'TEXT':
         {
            _text_color.p_text= attribute_list[x].attribute_val;
            _text_sample.p_forecolor =attribute_list[x].attribute_color;
            break;
         }
      case 'LINK':
         {
            _link_color.p_text= attribute_list[x].attribute_val;
            _link_sample.p_forecolor =attribute_list[x].attribute_color;
            break;
         }
      case 'VLINK':
         {
            _vlink_color.p_text= attribute_list[x].attribute_val;
            _vlink_sample.p_forecolor =attribute_list[x].attribute_color;
            break;
         }
      case 'ALINK':
         {
            _alink_color.p_text= attribute_list[x].attribute_val;
            _alink_sample.p_forecolor =attribute_list[x].attribute_color;
            break;
         }
      }
   }
   _bg_color.p_ReadOnly=
   _text_color.p_ReadOnly=
   _link_color.p_ReadOnly=
   _vlink_color.p_ReadOnly=
   _alink_color.p_ReadOnly=0;
}
ctlok.lbutton_up()
{
   //<body bgcolor="White" text="Black" link="Blue" vlink="Purple" alink="Red">
   _param1='';

   if ((_body_image.p_text!='')) {
      _param1= _param1:+_form_parent().case_html_string(' Background="',1):+_body_image.p_text:+'"';
   }
   if ((_bg_color.p_text!='') && (_bg_color.p_text!='(Unassigned)')) {
      _param1= _param1:+_form_parent().case_html_string(' Bgcolor=',1):+_form_parent().html_use_quote(_form_parent().convert_2_html_color(_bg_sample.p_backcolor));
   }
   if ((_text_color.p_text!='') && (_text_color.p_text!='(Unassigned)')) {
      _param1= _param1:+_form_parent().case_html_string(' Text=',1):+_form_parent().html_use_quote(_form_parent().convert_2_html_color(_text_sample.p_forecolor));
   }
   if ((_link_color.p_text!='') && (_link_color.p_text!='(Unassigned)')) {
      _param1= _param1:+_form_parent().case_html_string(' Link=',1):+_form_parent().html_use_quote(_form_parent().convert_2_html_color(_link_sample.p_forecolor));
   }
   if ((_vlink_color.p_text!='') && (_vlink_color.p_text!='(Unassigned)')) {
      _param1= _param1:+_form_parent().case_html_string(' Vlink=',1):+_form_parent().html_use_quote(_form_parent().convert_2_html_color(_vlink_sample.p_forecolor));
   }
   if ((_alink_color.p_text!='') && (_alink_color.p_text!='(Unassigned)')) {
      _param1= _param1:+_form_parent().case_html_string(' Alink=',1):+_form_parent().html_use_quote(_form_parent().convert_2_html_color(_alink_sample.p_forecolor));
   }
   p_active_form._delete_window(1);
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _html_insert_body_tag_form_initial_alignment()
{
   sizeBrowseButtonToTextBox(_body_image.p_window_id, ctl_image_browse.p_window_id, 0, _bg_sample.p_x + _bg_sample.p_width);
   sizeBrowseButtonToTextBox(_bg_color.p_window_id, ctl_bg_color.p_window_id);
   sizeBrowseButtonToTextBox(_text_color.p_window_id, ctl_text_color.p_window_id);
   sizeBrowseButtonToTextBox(_link_color.p_window_id, ctl_link_color.p_window_id);
   sizeBrowseButtonToTextBox(_vlink_color.p_window_id, ctl_vlink_color.p_window_id);
   sizeBrowseButtonToTextBox(_alink_color.p_window_id, ctl_alink_color.p_window_id);
}

void ctl_image_browse.lbutton_up(){

   _str format_list='Image Files('IMG_FILE_EXT'), All Files('ALLFILES_RE')';
   _str result=_OpenDialog('-new -modal',
                      'Open Image File',
                      '',     // Initial wildcards
                      format_list,  // file types
                      OFN_FILEMUSTEXIST,
                      IMG_FILE_EXT,      // Default extensions
                      '',      // Initial filename
                      '',      // Initial directory
                      '',      // Reserved
                      "Open Image dialog box"
                     );
   //Open the file open dialog set to the image browser
   if (result=='') {
      return;
   }
   _body_image.p_text = _form_parent().convert_filename_to_link(result);

}

void ctl_bg_color.lbutton_up()
{

   _str result = show(' -modal _html_insert_rgb_color_form');
   if (result != '') {
      _vlink_sample.p_backcolor=
      _alink_sample.p_backcolor=
      _link_sample.p_backcolor=
      _text_sample.p_backcolor=
      _bg_sample.p_backcolor = (int)result;

      _bg_color.p_ReadOnly=0;
      _bg_color.p_text=_form_parent().convert_2_html_color((int)result,true);
      _bg_color.p_ReadOnly=1;

   }
}
void ctl_text_color.lbutton_up()
{

   _str result = show(' -modal _html_insert_rgb_color_form');
   if (result != '') {
      _text_sample.p_forecolor=(int)result;
      _text_color.p_ReadOnly=0;
      _text_color.p_text=_form_parent().convert_2_html_color((int)result,true);
      _text_color.p_ReadOnly=1;

   }
}
void ctl_link_color.lbutton_up()
{

   _str result = show(' -modal _html_insert_rgb_color_form');
   if (result != '') {
      _link_sample.p_forecolor=(int)result;
      _link_color.p_ReadOnly=0;
      _link_color.p_text=_form_parent().convert_2_html_color((int)result,true);
      _link_color.p_ReadOnly=1;

   }
}
void ctl_alink_color.lbutton_up()
{

   _str result = show(' -modal _html_insert_rgb_color_form');
   if (result != '') {
      _alink_sample.p_forecolor=(int)result;
      _alink_color.p_ReadOnly=0;
      _alink_color.p_text=_form_parent().convert_2_html_color((int)result,true);
      _alink_color.p_ReadOnly=1;

   }
}
void ctl_vlink_color.lbutton_up()
{

   _str result = show(' -modal _html_insert_rgb_color_form');
   if (result != '') {
      _vlink_sample.p_forecolor=(int)result;
      _vlink_color.p_ReadOnly=0;
      _vlink_color.p_text=_form_parent().convert_2_html_color((int)result,true);
      _vlink_color.p_ReadOnly=1;

   }
}
/*************************************************************************/
defeventtab _html_insert_rgb_color_form;
static _str _ignore_change=0;

static rgb_update_values()
{
   int this_color=sample.p_backcolor;
   int red=this_color & 0x0000FF;
   int green=(this_color & 0x00FF00) >> 8;
   int blue=(this_color & 0xFF0000) >> 16;
   if (!_rgb_dec.p_value) {
      _ignore_change=1;
      _red.p_text = substr(dec2hex(red),3);
      _green.p_text = substr(dec2hex(green),3);
      _blue.p_text = substr(dec2hex(blue),3);
      _ignore_change=0;
   } else {
      _red.p_text=red;
      _green.p_text=green;
      _blue.p_text=blue;
   }

}
static rgb_update_sample(typeless red,typeless green,typeless blue)
{
   if (isinteger(red) && isinteger(green) && isinteger(blue)) {
      if ((red <= 255 && red >= 0) && (green <= 255 && green >= 0) && (blue <= 255 && blue >= 0)) {
         sample.p_backcolor=_rgb(red,green,blue);
         sample.refresh();
      } else {
         _message_box('RGB values must be between 0 and 255.');
      }
   } else {
      _message_box('RGB values must be between 0 and 255.');
   }

}

void _colorlb.on_change(int reason){
   if (reason == CHANGE_SELECTED) {
      _str color = _lbget_seltext();
      int x;
      for (x = 0; x < ColorEntryList._length(); x++) {
         if (ColorEntryList[x].color_name == color) {
            //_message_box('we have a match. RGB = 'ColorEntryList[x].rgb_val);
            sample.p_backcolor=ColorEntryList[x].rgb_val;
            rgb_update_values();
            break;
         }
      }
   }
}
void _colorlb.'!'-'~'()
{
   boolean found_one;

   found_one=true;

   _str event=last_event();
   if( length(event)!=1 ) {
      return;
   }
   int old_line=p_line;
   _lbdeselect_all();
   int status=search('^(\>| )'event,'irh@');
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
   //_lbselect_line();
   return;
}
ctlok.lbutton_up(){

   int color = sample.p_backcolor;
   p_active_form._delete_window(color);
}
ctlok.on_create(){

   _rgb_dec.p_value = 1;
   int x;
   for (x = 0; x < ColorEntryList._length(); x++ ) {
      /*if (ColorEntryList[x].rgb_val  == RGB_DEFAULT) {
         _colorlb._lbselect_line();
      } */
      _colorlb._lbadd_item(ColorEntryList[x].color_name);
   }

   _colorlb.deselect_all();

   _colorlb._lbtop();
   //_colorlb.select_line();

   sample.p_backcolor=ColorEntryList[0].rgb_val;
   rgb_update_values();

}
_red_spin.on_spin_up()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   inc_rgb_color(red);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _red.p_text = substr(dec2hex(red),3);
      _ignore_change = 0;
   } else {
      _red.p_text=red;
   }
   rgb_update_sample(red,green,blue);
}

_red_spin.on_spin_down()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   dec_rgb_color(red);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _red.p_text = substr(dec2hex(red),3);
      _ignore_change = 0;
   } else {
      _red.p_text=red;
   }
   rgb_update_sample(red,green,blue);

}


_green_spin.on_spin_up()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   inc_rgb_color(green);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _green.p_text = substr(dec2hex(green),3);
      _ignore_change = 0;
   } else {
      _green.p_text=green;
   }
   rgb_update_sample(red,green,blue);
}

_green_spin.on_spin_down()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   dec_rgb_color(green);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _green.p_text = substr(dec2hex(green),3);
      _ignore_change = 0;
   } else {
      _green.p_text=green;
   }
   rgb_update_sample(red,green,blue);
}


_blue_spin.on_spin_up()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   inc_rgb_color(blue);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _blue.p_text = substr(dec2hex(blue),3);
      _ignore_change = 0;
   } else {
      _blue.p_text=blue;
   }
   rgb_update_sample(red,green,blue);
}


_blue_spin.on_spin_down()
{
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   dec_rgb_color(blue);
   if (!_rgb_dec.p_value) {
      _ignore_change = 1;
      _blue.p_text = substr(dec2hex(blue),3);
      _ignore_change = 0;
   } else {
      _blue.p_text=blue;
   }
   rgb_update_sample(red,green,blue);
}

void _rgb_spin_box.on_change()
{
   if (p_user=='') {
      //dialog coming up
      p_user=0;
      return;
   }
   if (_ignore_change) return;
   if (_rgb_dec.p_value && (p_text < 0 || p_text > 255) && p_text!='') {
      _message_box('RGB values must be between 0 and 255!');
      //look up default value here maybe
      return;
   }
   if (_rgb_hex.p_value && (hex2dec('0x'p_text) < 0 || hex2dec('0x'p_text) > 255) && hex2dec('0x'p_text)!='') {
      _message_box('RGB values must be between 0 and 255!');
      //look up default value here maybe
      return;
   }
   int red=0, green=0, blue=0;
   get_rgb_colors(red,green,blue);
   if (p_text!='') {
      rgb_update_sample(red,green,blue);
   }
}
void get_rgb_colors(typeless &red = 0, typeless &green = 0, typeless &blue = 0)
{

   red=_red.p_text;
   green=_green.p_text;
   blue=_blue.p_text;
   if (_rgb_hex.p_value) {
      red = hex2dec('0x'red);
      green = hex2dec('0x'green);
      blue= hex2dec('0x'blue);
   }
   //_message_box('red 'red' green' green' blue' blue);
   return;
}
void inc_rgb_color(int &color = 0)
{
   if (color == 255) {
      color=0;
   } else {
      color+=1;
   }
}
void dec_rgb_color(int &color = 0)
{
   if (color == 0) {
      color=255;
   } else {
      color-=1;
   }
}
_rgb_dis_type.on_got_focus()
{
   _ignore_change = 1;
   p_value=1;
   if (_rgb_hex.p_value) {
      _red.p_text = substr(dec2hex((typeless)_red.p_text),3);
      _green.p_text = substr(dec2hex((typeless)_green.p_text),3);
      _blue.p_text = substr(dec2hex((typeless)_blue.p_text),3);
      //_message_box('red 'red' green' green' blue' blue);
   } else {
      _red.p_text=hex2dec('0x'_red.p_text);
      _green.p_text=hex2dec('0x'_green.p_text);
      _blue.p_text=hex2dec('0x'_blue.p_text);
      //_message_box('red 'red' green' green' blue' blue);
   }
   _ignore_change = 0;

}
static void initialize_style_vals()
{
   _param8 = _param9 = _param10 = '';
}
