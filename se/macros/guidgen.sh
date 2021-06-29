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

/**
 * Slick-C structure representing a 128 bit unique identifier.
 *     Analagous to the GUID structure defined in Rpcdce.h
 */
struct GUID{
   // Layout of the original C structure
      /*                                                              
      int Data1;
      short Data2;
      short Data3;
      byte Data4[8];                                                                
      */
   // To keep the implementation simple, instead of using shorts
   // and arrays of bytes, I'm just using ints to construct
   // the equivalent number of bytes.
   int Data1;
   int Data23;    
   int Data4A;    
   int Data4B;
};

// Global functions
/**
 * Creates a new GUID and returns a string representation
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
 * @return Formatted GUID string
 * @see guid_create
 */
_str guid_create_string(_str outputFormat = 'B');

