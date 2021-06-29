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
#import "varedit.e"
#import "stdprocs.e"
#endregion Imports

/**
 * The "se.vc" namespace contains interfaces and classes that 
 * are intrinisic to supporting 3rd party verrsion control 
 * systems. 
 */
namespace se.vc;

class WWTSLine {
   // These fields are all information available in from version control, 
   // this is why there is no description here
   private _str m_versionNumber;
   private _str m_userName;
   private int m_year;
   private int m_month;
   private int m_day;

   static private _str s_monthTable[]= _reinit {
      "January","Febuary","March","April","May","June",
      "July","August","September","October","November","December"
   };

   WWTSLine(_str userName="",_str versionNumber="",int month=-1,int day=-1,int year=-1) {
      m_versionNumber = versionNumber;
      m_userName      = userName;
      m_year          = year;
      m_month         = month;
      m_day           = day;
   }

   /** 
    * @param fieldSpec <BR>%M = Month<BR>
    *                      %MN = Month name<BR>
    *                      %D  = Day (numeric)<BR>
    *                      %Y  = Year<BR>  Padded backwards (%2Y
    *                      gives last 2 chars, not first 2)<BR>
    *                      %U = User name<BR>
    *                      %V = Version number<BR>
    *                      %% = %<BR>
    *  
    * Field names are case insensitive.<BR>
    * 
    * All fields support a numeric prefix.  For 
    * example for a three letter month you would use %3mn.
    * 
    * @return _str
    */
   public _str getCaption(_str fieldSpec="%12v (%8u %2d-%3mn-%2y): ") {
      outputString := "";

      len := fieldSpec._length();
      for (i:=1;i<=len;++i) {
         ch := substr(fieldSpec,i,1);
         if ( ch=='%' ) {
            // This is a field to be filled in
            numPrefix := 0;

            nextch := substr(fieldSpec,i+1,1);

            while ( isinteger(nextch) ) {
               numPrefix *= 10;
               numPrefix += (int)nextch;
               ++i;
               nextch = substr(fieldSpec,i+1,1);
            }

            appendString := "";;
            switch ( upcase(nextch) ) {
            case 'U':
               // 'U' user name
               appendString = m_userName;
               break;
            case 'V':
               // 'V' Version number
               appendString = m_versionNumber;
               break;
            case "M":
               // Month
               nextch = upcase(substr(fieldSpec,i+2,1));
               if ( nextch=='N' ) {
                  // Month name
                  if ( m_month>-1 && m_month <= s_monthTable._length() ) {
                     appendString = s_monthTable[m_month-1];
                  }
                  ++i;
                  break;
               }
               // 'm' is a numeric month.  Since it is 2 chars wide, we
               if ( numPrefix>1 && length(m_month)<2 ) {
                  appendString = '0':+m_month;
               }else{
                  appendString = m_month;
               }
               break;
            case "D":
               // Day
               if ( numPrefix>1 && length(m_day)<2 ) {
                  appendString = '0':+m_day;
               }else{
                  appendString = m_day;
               }
               break;
            case "Y":
               // Year, prefix is backwards
               appendString = m_year;
               if ( numPrefix ) {
                  appendString = substr(m_year,5-numPrefix);
                  numPrefix = 0;
               }
               break;
            case "%":
               // '%%' means insert one '%'
               appendString = '%';
               break;
            }
            if ( appendString=='%' ) {
               outputString:+=appendString;
            }else if ( numPrefix ) {
               outputString:+=substr(appendString,1,numPrefix);
            }else if ( !numPrefix ) {
               outputString:+=appendString;
            }
            ++i;
         }else{
            // This is a normal character, just append it to the output
            outputString :+= ch;
         }
      }

      return outputString;
   }

   public _str getVersion() {
      return m_versionNumber;
   }

   public _str getUserName() {
      return m_userName;
   }

   public _str getStrDate() {
      return getCaption("%2d-%2m-%2y");
   }
};
