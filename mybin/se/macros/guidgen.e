////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44125 $
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
#include "slick.sh"
#include "guidgen.sh"

#pragma option(strictsemicolons,on)
#pragma option(strictparens,on)
#pragma option(autodeclvars,off)


#if __NT__
extern void ntGetGUID(GUID& guid);
#endif

/**
 * Creates a new GUID and inserts the textual
 *     representation at the current edit position
 * 
 * @param outputFormat Format specifier, default is 'B'
 * <dl>
 * <dt>'B' - Brace format</dt><dd>{F3410386-1DBB-4035-A293-440A106A6665}</dd>
 * <dt>'G' - General format</dt><dd>F3410386-1DBB-4035-A293-440A106A6665</dd>
 * <dt>'P' - Paren format</dt><dd>(F3410386-1DBB-4035-A293-440A106A6665)</dd>
 * <dt>'N' - Number format</dt><dd>F34103861DBB4035A293440A106A6665</dd>
 * <dt>'C' - Const declaration</dt><dd>static const GUID <<name>> = { 0xf3410386, 0x1dbb, 0x4035, { 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65 } };</dd>
 * <dt>'D' - DEFINE_GUID macro</dt><dd>DEFINE_GUID(<<name>>, 0x17342D4B, 0x906F, 0x4706, 0x0F, 0xAC, 0xC5, 0x8E, 0x4D, 0xE7, 0x32, 0x29);</dd>
 * <dt>'O' - IMPLEMENT_OLECREATE macro</dt><dd>IMPLEMENT_OLECREATE(<<class>>, <<external_name>>, 0xf3410386, 0x1dbb, 0x4035, 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65);</dd>
 * </dl>
 * 
 * @see guid_create_string
 * @see guid_create
 * @see copy_guid
 */
_command void insert_guid(_str outputFormat = 'B') name_info(','VSARG2_REQUIRES_EDITORCTL)
{
   _str toInsert = guid_create_string(outputFormat);
   _insert_text(toInsert);
}


/**
 * Creates a new GUID and copies the textual representation to
 * the clipboard
 * @param outputFormat Format specifier, default is 'B'. See
 *                     documentation for insert_guid for valid
 *                     format specifier values.
 * @see guid_create_string
 * @see guid_create
 */
_command void copy_guid(_str outputFormat = 'B') name_info(',')
{
   _str toCopy = guid_create_string(outputFormat);
   push_clipboard_itype('CHAR');
   append_clipboard_text(toCopy);
}

/**
 * Displays the GUID generator dialog
 * 
 * @see insert_guid
 */
_command void gui_insert_guid()
{
   show('_guidgen_form');
}

// See javadoc in guidgen.sh
_str guid_create_string(_str outputFormat = 'B')
{
   GUID g = _guid_new();
   return _guid_format(g, outputFormat);
}

/**
 * Creates a new GUID, a 128 bit unique identifier
 * 
 * @param rguidDest GUID struct to populate (Output parameter)
 * 
 * @see guid_create_string
 * @see guid_to_string
 * @see insert_guid
 */
static void guid_create(GUID& rguidDest)
{
   rguidDest = _guid_new();
}


/**
 * Formats a GUID into a string representation
 * 
 * @param rGuid  GUID structure to be formatted
 * @param outputFormat Format specifier:
 * <dl>
 * <dt>'B' - Brace format</dt><dd>{F3410386-1DBB-4035-A293-440A106A6665}</dd>
 * <dt>'G' - General format</dt><dd>F3410386-1DBB-4035-A293-440A106A6665</dd>
 * <dt>'P' - Paren format</dt><dd>(F3410386-1DBB-4035-A293-440A106A6665)</dd>
 * <dt>'N' - Number format</dt><dd>F34103861DBB4035A293440A106A6665</dd>
 * <dt>'C' - Const declaration</dt><dd>static const GUID <<name>> = { 0xf3410386, 0x1dbb, 0x4035, { 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65 } };</dd>
 * <dt>'D' - DEFINE_GUID macro</dt><dd>DEFINE_GUID(<<name>>, 0x17342D4B, 0x906F, 0x4706, 0x0F, 0xAC, 0xC5, 0x8E, 0x4D, 0xE7, 0x32, 0x29);</dd>
 * <dt>'O' - IMPLEMENT_OLECREATE macro</dt><dd>IMPLEMENT_OLECREATE(<<class>>, <<external_name>>, 0xf3410386, 0x1dbb, 0x4035, 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65);</dd>
 * </dl>
 * @return string representation of the guid, or '' if the guid is invalid
 */
static _str guid_to_string(GUID& rGuid, _str outputFormat = 'B')
{
   return _guid_format(rGuid, outputFormat);
}


/**
 * Parses a guid string and returns the GUID struct representation
 * 
 * @param guidString
 *             Guid formatted in any of the following formats:
 * <dl>
 * <dt>'B' - Brace format</dt><dd>{F3410386-1DBB-4035-A293-440A106A6665}</dd>
 * <dt>'G' - General format</dt><dd>F3410386-1DBB-4035-A293-440A106A6665</dd>
 * <dt>'P' - Paren format</dt><dd>(F3410386-1DBB-4035-A293-440A106A6665)</dd>
 * <dt>'N' - Number format</dt><dd>F34103861DBB4035A293440A106A6665</dd>
 * </dl>
 *  Note: Not all the formats valid for output (guid_to_string, 
 *  guid_create_string) can be parsed
 * @param rguidDest      GUID structure to fill (Output parameter)
 * 
 * @return True if the guid was successfully parsed. False means the format
 *         couldn't be recognized.
 * @see guid_to_string
 * @see guid_create_string
 */
static boolean guid_parse(_str guidString, GUID& rguidDestination)
{
   return _guid_parse(guidString, rguidDestination);
}

/**
 * Determines if a GUID has been initialized to all zeros
 * 
 * @param rGuid  GUID to test
 * 
 * @return True if all values are 0.
 * @see guid_init
 */
static boolean guid_is_empty(GUID& rGuid)
{
   return (rGuid.Data1 == 0 && rGuid.Data23 == 0 && rGuid.Data4A == 0 && rGuid.Data4B == 0);
}

/**
 * Initializes a GUID to all zeros
 * 
 * @param rGuid  GUID to initialize
 * 
 * @see guid_is_empty
 */
static void guid_init(GUID& rGuid)
{
   rGuid.Data1 = 0;
   rGuid.Data23 = 0;
   rGuid.Data4A = 0;
   rGuid.Data4B = 0;
}

/**
 * Tranforms a guid from one string format to another
 * 
 * @param originalGuid
 *               Original guid string, formatted in one of the following
 *               formats:
 * <dl>
 * <dt>'B' - Brace format</dt><dd>{F3410386-1DBB-4035-A293-440A106A6665}</dd>
 * <dt>'G' - General format</dt><dd>F3410386-1DBB-4035-A293-440A106A6665</dd>
 * <dt>'P' - Paren format</dt><dd>(F3410386-1DBB-4035-A293-440A106A6665)</dd>
 * <dt>'N' - Number format</dt><dd>F34103861DBB4035A293440A106A6665</dd>
 * </dl>
 *  Note: Not all the formats valid for output (guid_to_string, 
 *  guid_create_string) can be parsed
 * @param outputFormat
 *               Format specifier:
 * <dl>
 * <dt>'B' - Brace format</dt><dd>{F3410386-1DBB-4035-A293-440A106A6665}</dd>
 * <dt>'G' - General format</dt><dd>F3410386-1DBB-4035-A293-440A106A6665</dd>
 * <dt>'P' - Paren format</dt><dd>(F3410386-1DBB-4035-A293-440A106A6665)</dd>
 * <dt>'N' - Number format</dt><dd>F34103861DBB4035A293440A106A6665</dd>
 * <dt>'C' - Const declaration</dt><dd>static const GUID <<name>> = { 0xf3410386, 0x1dbb, 0x4035, { 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65 } };</dd>
 * <dt>'D' - DEFINE_GUID macro</dt><dd>DEFINE_GUID(<<name>>, 0x17342D4B, 0x906F, 0x4706, 0x0F, 0xAC, 0xC5, 0x8E, 0x4D, 0xE7, 0x32, 0x29);</dd>
 * <dt>'O' - IMPLEMENT_OLECREATE macro</dt><dd>IMPLEMENT_OLECREATE(<<class>>, <<external_name>>, 0xf3410386, 0x1dbb, 0x4035, 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65);</dd>
 * </dl>
 * 
 * @return The guid in the new string format, or '' if the original format could not be parsed
 */
static _str guid_translate(_str originalGuid, _str outputFormat)
{
   GUID gTemp;
   if(_guid_parse(originalGuid, gTemp))
   {
      return _guid_format(gTemp, outputFormat);
   }
   return '';
}

// Generates a new GUID structure using 4 randomly-generated ints
static GUID _guid_new()
{
   GUID gRet;
#if __NT__
   ntGetGUID(gRet);

#else
   // Take the last 7 characters from the binary time
   _str tmB = _time('B');
   _str lastSeven = substr(tmB, length(tmB) - 6, 7);
   int seedTime1 = (int)lastSeven * -1;

   // Take the last 8 chars from the 'G' time
   _str tmG = _time('G');
   _str lastEight = substr(tmG, length(tmG) - 7, 8);
   int seedTime2 = (int)lastEight * -1;

   // Create some psuedo-random seeds
   int seed1 = random(0, 0XFFFFFF);
   if(seed1 < 0)
      seed1 *= -1;
   int seed2 = random(1, 0xFFFF);
   if(seed2 < 0)
      seed2 *= -1;
   
   // Create 8 random numbers using the random
   // seeds and the time values
   int r1b = random(seedTime1, seed1);
   int r2b = random(seedTime2, seed2);
   int r3b = random(seedTime2, seed1);
   int r4b = random(seedTime1, seed2);

   int r1a = random(seedTime1, seed1);
   int r2a = random(seedTime2, seed2);
   int r3a = random(seedTime2, seed1);
   int r4a = random(seedTime1, seed2);

   // TODO: Maybe set the version and format flags
   // here before calling _makeLong (rather than doing it after)?

   // The top four bytes do not have any
   // modifications needed
   gRet.Data1 = _makeLongI(r1a, r1b);

   // We have to add a version flag here
   gRet.Data23 = _guid_setVersionNumber(_makeLongI(r2a, r2b));

   // ... and variant format here
   gRet.Data4A = _guid_setVariantType(_makeLongI(r3a, r3b));

   // Last four bytes are unmodified
   gRet.Data4B = _makeLongI(r4a, r4b);
#endif
   return gRet;

}

// Returns a textual representation of a GUID
static _str _guid_format(GUID& rGuid, _str formatString='B')
{
   // Format each of the 4 integral parts into
   // an 8-char hex string, without the leading 0x
   // eg:- 2FEE11AC
   _str part1 = _formatHex8(rGuid.Data1);
   _str part2 = _formatHex8(rGuid.Data23);
   _str part3 = _formatHex8(rGuid.Data4A);
   _str part4 = _formatHex8(rGuid.Data4B);
   _str opt = substr(upcase(formatString), 1, 1, 'B');
   _str retVal = '';

   // Format the pieces-parts according to the provided specifier
   if (opt == 'B') 
   {
      // Brace format
      // {F3410386-1DBB-4035-A293-440A106A6665}
      retVal = '{'part1'-'substr(part2, 1, 4)'-'substr(part2,5,4)'-'substr(part3,1,4)'-'substr(part3,5,4)''part4'}';
   }
   else if (opt == 'P') 
   {
      // Paren format
      // (F3410386-1DBB-4035-A293-440A106A6665)
      retVal = '('part1'-'substr(part2, 1, 4)'-'substr(part2,5,4)'-'substr(part3,1,4)'-'substr(part3,5,4)''part4')';
   }
   else if (opt == 'G') 
   {
      // General format
      // F3410386-1DBB-4035-A293-440A106A6665
      retVal = part1'-'substr(part2, 1, 4)'-'substr(part2,5,4)'-'substr(part3,1,4)'-'substr(part3,5,4)''part4;
   }
   else if (opt == 'N') 
   {
      // Number-only format
      // F34103861DBB4035A293440A106A6665
      retVal = part1''part2''part3''part4;
   }
   else if (opt == 'C') 
   {
      // Const declaration format
      //static const GUID <<name>> = { 0xf3410386, 0x1dbb, 0x4035, { 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65 } };
      _str comment = '/*'_guid_format(rGuid, 'B')'*/';
      _str first = 'static const GUID <<name>> = { 0x'part1', 0x'substr(part2, 1, 4)', 0x'substr(part2,5,4)', ';
      _str second = '{ 0x'substr(part3,1,2)', 0x'substr(part3,3,2)', 0x'substr(part3,5,2)', 0x'substr(part3,7,2);
      _str third = ', 0x'substr(part4,1,2)', 0x'substr(part4,3,2)', 0x'substr(part4,5,2)', 0x'substr(part4,7,2)' } };';
      retVal = comment:+ "\r\n" :+ first :+ second :+ third;
   }
   else if (opt == 'D') 
   {
      // DEFINE_GUID macro format
      //DEFINE_GUID(<<name>>, 0xf3410386, 0x1dbb, 0x4035, 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65);
      _str comment = '/*'_guid_format(rGuid, 'B')'*/';
      _str first = 'DEFINE_GUID(<<name>>, 0x'part1', 0x'substr(part2, 1, 4)', 0x'substr(part2,5,4);
      _str second = ', 0x'substr(part3,1,2)', 0x'substr(part3,3,2)', 0x'substr(part3,5,2)', 0x'substr(part3,7,2);
      _str third = ', 0x'substr(part4,1,2)', 0x'substr(part4,3,2)', 0x'substr(part4,5,2)', 0x'substr(part4,7,2)');';
      retVal = comment:+ "\r\n" :+ first :+ second :+ third;
   }
   else if (opt == 'O') 
   {
      // IMPLEMENT_OLECREATE macro format
      //IMPLEMENT_OLECREATE(<<class>>, <<external_name>>, 0xf3410386, 0x1dbb, 0x4035, 0xa2, 0x93, 0x44, 0xa, 0x10, 0x6a, 0x66, 0x65);
      _str comment = '/*'_guid_format(rGuid, 'B')'*/';
      _str first = 'IMPLEMENT_OLECREATE(<<name>>, <<external_name>> 0x'part1', 0x'substr(part2, 1, 4)', 0x'substr(part2,5,4);
      _str second = ', 0x'substr(part3,1,2)', 0x'substr(part3,3,2)', 0x'substr(part3,5,2)', 0x'substr(part3,7,2);
      _str third = ', 0x'substr(part4,1,2)', 0x'substr(part4,3,2)', 0x'substr(part4,5,2)', 0x'substr(part4,7,2)');';
      retVal = comment:+ "\r\n" :+ first :+ second :+ third;
   }
   else
   {
      // Format not recognized. If another format is added, update the
      // Javadoc comments.
      retVal = 'Format ['opt'] Not recognized';
   }
   return retVal;
}

// Parse a text string containing a guid value, and populate
// a GUID structure. This is useful for taking a guid in one
// format and translating it into another.
static boolean _guid_parse(_str guidString, GUID& rGuid)
{
   // Regular expression to support parsing GUID formats B, P, D, and N
   _str formatParseRE = '^[\{\(]{0,1}([0-9a-fA-F]{8,8})[\-]{0,1}([0-9a-fA-F]{4,4})[\-]{0,1}([0-9a-fA-F]{4,4})[\-]{0,1}([0-9a-fA-F]{4,4})[\-]{0,1}([0-9a-fA-F]{12,12})[\}\)]{0,1}$';
   // We are looking to parse out 5 groups of hex digits
   // 8 - 4 - 4 - 4 - 12
   _str inputGuid = strip(guidString);
   if(pos(formatParseRE, inputGuid, 1, 'UI'))
   {
      _str part1, part2, part3, part4, part5;
      int groupStart = pos('S1');
      int groupLen = pos('1');
      part1 = substr(inputGuid, groupStart, groupLen);

      groupStart = pos('S2');
      groupLen = pos('2');
      part2 = substr(inputGuid, groupStart, groupLen);

      groupStart = pos('S3');
      groupLen = pos('3');
      part3 = substr(inputGuid, groupStart, groupLen);

      groupStart = pos('S4');
      groupLen = pos('4');
      part4 = substr(inputGuid, groupStart, groupLen);

      groupStart = pos('S5');
      groupLen = pos('5');
      part5 = substr(inputGuid, groupStart, groupLen);

      if(length(part1) == 8 &&
         length(part2) == 4 &&
         length(part3) == 4 &&
         length(part4) == 4 &&
         length(part5) == 12)
      {
         // They all look good so far. Now we need to 
         // break them into 8 shorts and then place them
         // into 4 integers
         _str val1Hi = hex2dec('0x'substr(part1, 1, 4));
         _str val1Lo = hex2dec('0x'substr(part1, 5, 4));

         _str val2Hi = hex2dec('0x'part2);
         _str val2Lo = hex2dec('0x'part3);

         _str val3Hi = hex2dec('0x'part4);
         _str val3Lo = hex2dec('0x'substr(part5, 1, 4));

         _str val4Hi = hex2dec('0x'substr(part5, 5, 4));
         _str val4Lo = hex2dec('0x'substr(part5, 9, 4));
      
         rGuid.Data1 = _makeLong(val1Lo, val1Hi);
         rGuid.Data23 = _makeLong(val2Lo, val2Hi);
         rGuid.Data4A = _makeLong(val3Lo, val3Hi);
         rGuid.Data4B = _makeLong(val4Lo, val4Hi);
         return true;
      }
   }
   guid_init(rGuid);
   return false;
}

// Pads the hex string so that each integer fits all
// 8 character positions. Positive numbers are lead padded
// with zeros to make 0x002011EA
static _str _formatHex8(long data)
{
   _str hexString = dec2hex((0x00000000FFFFFFFFL & data));
   // Strip off the leading 0x
   hexString = substr(hexString, 3);
   n := length(hexString);
   if (n < 8) {
      hexString = substr("", 1, 8 - n, '0') :+ hexString;
   } else if (n > 8) {
      hexString = substr(hexString, n - 8, 8);
   }
   return hexString;
}

// Take two strings (that have ints), take the lower 2 bytes of each, and
// create a HI|LO 4-byte from them
static int _makeLong(_str loword, _str hiword)
{
   if(isnumber(hiword) && isnumber(loword))
   {
      return _makeLongI((int)loword, (int)hiword);
   }
   return 0;
}

// Take two ints, take the lower 2 bytes of each, and
// create a HI|LO 4-byte from them
static int _makeLongI(int lo, int hi)
{
   int lopart = (lo & 0xFFFF);
   int highpart = (hi & 0xFFFF) << 16;
   return (highpart | lopart);
}

// Modifies an int to set the GUID version bit flags
// The top 4 bits of the lower 2 bytes (LOWORD) are set
// to 0x40?? (0100????)
// This is "Version 4" in GUID versioning, which means
// that all bytes are created using random numbers
static int _guid_setVersionNumber(int data)
{
   int temp = data & 0xFFFF0FFF; // or... temp = data & (~0x0000F000);
       temp = temp | 0x00004000;
   return temp;
}

// Modifies the top 2 bits to contain 0b10??????. 
// This flag signifies 'standard GUID format'
static int _guid_setVariantType(int data)
{
   /*
   0xFFFFFFFF
   11111111111111111111111111111111
   0x3FFFFFFF
   00111111111111111111111111111111
   0x80000000
   10000000000000000000000000000000
   */
   int temp = data & 0x3FFFFFFF;
       temp = temp | 0x80000000;
   return temp;
}

/////////////////////////
// Guid generator UI Form
/////////////////////////
_form _guidgen_form {
   p_backcolor=0x80000005;
   p_border_style=BDS_DIALOG_BOX;
   p_caption='GUID Generator';
   p_clip_controls=false;
   p_forecolor=0x80000008;
   p_height=1692;
   p_help='Tools menu';
   p_width=5988;
   p_x=18746;
   p_y=4428;
   p_eventtab=_guidgen_form;
   _label ctllabel1 {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='GUID &Format:';
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=242;
      p_tab_index=1;
      p_width=1200;
      p_word_wrap=false;
      p_x=120;
      p_y=168;
   }
   _combo_box ctlcombo_formats {
      p_auto_size=true;
      p_backcolor=0x80000005;
      p_case_sensitive=false;
      p_completion=NONE_ARG;
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=228;
      p_style=PSCBO_NOEDIT;
      p_tab_index=2;
      p_tab_stop=true;
      p_width=3240;
      p_x=1320;
      p_y=157;
      p_eventtab2=_ul2_combobx;
   }
   _command_button ctlbtn_newguid {
      p_cancel=false;
      p_caption='&New';
      p_default=false;
      p_font_name='MS Sans Serif';
      p_height=365;
      p_tab_index=3;
      p_tab_stop=true;
      p_width=1000;
      p_x=4862;
      p_y=72;
   }
   _command_button ctlbtn_copyguid {
      p_cancel=false;
      p_caption='&Copy';
      p_default=false;
      p_font_name='MS Sans Serif';
      p_height=365;
      p_tab_index=4;
      p_tab_stop=true;
      p_width=1000;
      p_x=4862;
      p_y=460;
   }
   _command_button ctlbtn_insert {
      p_cancel=false;
      p_caption='&Insert';
      p_default=false;
      p_font_name='MS Sans Serif';
      p_height=365;
      p_tab_index=5;
      p_tab_stop=true;
      p_width=1000;
      p_x=4862;
      p_y=856;
   }
   _command_button ctlbtn_close {
      p_cancel=false;
      p_caption='Cl&ose';
      p_default=false;
      p_font_name='MS Sans Serif';
      p_height=360;
      p_tab_index=6;
      p_tab_stop=true;
      p_width=1001;
      p_x=4861;
      p_y=1260;
   }
   _label ctllabel2 {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='Current GUID:';
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=242;
      p_tab_index=7;
      p_width=1200;
      p_word_wrap=false;
      p_x=120;
      p_y=503;
   }
   _label ctllabel_current_guid {
      p_alignment=AL_LEFT;
      p_auto_size=false;
      p_backcolor=0x80000005;
      p_border_style=BDS_NONE;
      p_caption='';
      p_font_name='MS Sans Serif';
      p_forecolor=0x80000008;
      p_height=442;
      p_tab_index=8;
      p_width=4640;
      p_word_wrap=false;
      p_x=120;
      p_y=778;
   }
}

static GUID _currentGuid;
defeventtab _guidgen_form;
void ctlbtn_insert.lbutton_up()
{
   // Insert into the current active edit window
   if (_mdi.p_child > 0)
   {
      if (_mdi.p_child._isEditorCtl())
      {
         // Read the format specifier from the combo box
         _str formatSpec = ctlcombo_formats.p_text;
         _str formatChar = '';
         parse formatSpec with .'('formatChar')';

         _str formattedGuid = guid_to_string(_currentGuid, formatChar);
         // The multi-line ones we'll place on their own lines
         // See if there is a cr/lf anywhere in here
         if(pos('(\r|\n)', formattedGuid, 1, 'UI'))
         {
            // See if the current line has any text in it
            _str curLine = '';
            _mdi.p_child.get_line(curLine);
            if(length(curLine))
            {
               _mdi.p_child.end_line();
               _mdi.p_child.split_insert_line();
            }
         }
         _mdi.p_child._insert_text(formattedGuid);
         
         return;
      }
   }
   say('No active editor to insert GUID into');
}

void ctlbtn_newguid.lbutton_up()
{
   // Generate a new guid and update the display
   guid_create(_currentGuid);
   _str formatSpec = ctlcombo_formats.p_text;
   _str formatChar = '';
   parse formatSpec with .'('formatChar')';
   ctllabel_current_guid.p_caption = guid_to_string(_currentGuid, formatChar);
}

void ctlbtn_copyguid.lbutton_up()
{
   // Read the format specifier from the combo box
   _str formatSpec = ctlcombo_formats.p_text;
   _str formatChar = '';
   parse formatSpec with .'('formatChar')';
   _str formattedGuid = guid_to_string(_currentGuid, formatChar);

   push_clipboard_itype('CHAR');
   append_clipboard_text(formattedGuid);
}

void ctlbtn_close.lbutton_up()
{
   p_active_form._delete_window();
}

void _guidgen_form.on_load()
{  
   guid_create(_currentGuid);
   ctllabel_current_guid.p_caption = guid_to_string(_currentGuid, 'B');
}

void ctlcombo_formats.on_create()
{
   _lbadd_item('Brace format (B)');
   _lbadd_item('General format (G)');
   _lbadd_item('Paren format (P)');
   _lbadd_item('Number format (N)');
   _lbadd_item('const declaration (C)');
   _lbadd_item('DEFINE_GUID (D)');
   _lbadd_item('IMPLEMENT_OLECREATE (O)');
   p_text = 'Brace format (B)';
}

void ctlcombo_formats.on_change(int reason)
{
   if(reason == CHANGE_CLINE)
   {
      _str formatSpec = ctlcombo_formats.p_text;
      _str formatChar = '';
      parse formatSpec with .'('formatChar')';
      ctllabel_current_guid.p_caption = guid_to_string(_currentGuid, formatChar);
   }
}

void _guidgen_form.ESC()
{
   p_active_form._delete_window();
}

definit()
{
   guid_init(_currentGuid);
}


///////////////////////////////////
// Unit tests
///////////////////////////////////
// Create gobs of GUIDs into a buffer, sort it, and look for duplicates
// Currently saving into GUIDDUPES.txt
/*
_command guid_unittest_duplicates(int numGuids = 1000) name_info(','VSARG2_MACRO|VSARG2_MARK|VSARG2_REQUIRES_MDI_EDITORCTL)
{
   // Create a bunch of GUIDs
   _str tmB = _time('B');
   _str lastSeven = substr(tmB, length(tmB) - 6, 7);
   int timerValue = (int)lastSeven;

   int idx = 0;
   for(idx = 0; idx < numGuids; ++idx)
   {
      execute('insert-guid B','');
      split_insert_line();
   }
   delete_line();
   timerValue = _guid_unittests_checkpoint(timerValue, 'Created '(idx)' guids');

   // Sort the results (so that any encountered duplicates are obvious)
   sort_buffer();
   top();
   up();
   timerValue = _guid_unittests_checkpoint(timerValue, 'Sorted buffer');

   // Walk the entire sorted list, looking for consecutive lines that match
   _str prevGuid = '';
   _str currentGuid = '';
   get_line(prevGuid);
   int status = down();
   int linesChecked = 0;
   while(status != BOTTOM_OF_FILE_RC)
   {
      ++linesChecked;
      get_line(currentGuid);
      if(currentGuid == prevGuid)
      {
         if(length(currentGuid) > 5)
            say('Duplicate found on line ['p_line'] :'currentGuid);
      }
      prevGuid = currentGuid;
      status = down();
   }
   timerValue = _guid_unittests_checkpoint(timerValue, 'Dupe check on 'linesChecked' lines completed');
}
*/

/*
static int _guid_unittests_checkpoint(int previousValue, _str msg)
{
   _str tmB = _time('B');
   _str lastSeven = substr(tmB, length(tmB) - 6, 7);
   int seedTime1 = (int)lastSeven;

   int elapsed = seedTime1 - previousValue;
   double fseconds = (double)elapsed / 1000.0;
   say(msg' in 'fseconds' seconds');
   return seedTime1;
}
*/

// Round-trip test to make sure a guid can be correctly created,
// parsed, and re-formatted as the same text
// Un-comment and use this unit test if you create a new format specifier
/*
_command void guid_unittest_roundtrip()
{
   GUID gOrig;
   
   guid_create(gOrig);
   _str orig = guid_to_string(gOrig, 'B');
      
   GUID gdTemp;
   if(guid_parse(orig, gdTemp))
   {
      _str newer = guid_to_string(gdTemp, 'B');
      if(newer != orig)
      {
         say('Original Vals: 1)'gOrig.Data1' 2)'gOrig.Data23' 3)'gOrig.Data4A' 4)'gOrig.Data4B);
         say('Original guid      :'orig);
         say('Parsed Vals  : 1)'gdTemp.Data1' 2)'gdTemp.Data23' 3)'gdTemp.Data4A' 4)'gdTemp.Data4B);
         say('Round-tripped into :'newer);
      }
      else
      {
         say('Correct round-trip for :'orig);
      }
   }
}
*/

