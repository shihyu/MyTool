////////////////////////////////////////////////////////////////////////////////////
// $Revision: 44847 $
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
#pragma option(pedantic, on)
#region Imports
#require "sc/lang/IToString.e"
#require "sc/lang/IAssignTo.e"
#require "sc/lang/IEquals.e"
#require "sc/lang/IComparable.e"
#require "sc/lang/IHashable.e"
#require "sc/lang/IIndexable.e"
#require "sc/lang/String.e"
#import "slick.sh"
#import "stdprocs.e"
#endregion



namespace se.datetime



enum DTType {
   DT_LOCALTIME=0,
   DT_UTCTIME,
};


enum DTSpan {
   DT_YEAR=0,
   DT_MONTH,
   DT_DAY,
   DT_HOUR,
   DT_MINUTE,
   DT_SECOND,
   DT_FRACTIONALSECOND
};


enum DTParts {
   DT_DATE_TIME=0,
   DT_DATE,
   DT_TIME
};


class DateTime :
   sc.lang.IToString,
   sc.lang.IAssignTo,
   sc.lang.IEquals,
   sc.lang.IComparable,
   sc.lang.IHashable,
   sc.lang.IIndexable
{
   private boolean validDate (int yyyy=0, int mm=0, int dd=0);
   private boolean validTime (int hh=0, int mm=0, int ss=0, double fs=0);
   static public void utcOffset (int& hh, int& mm);  
   static public boolean isLeapYear (int iyear);
   public long toTimeB ();
   public long toTimeF ();
   public _str toString (); //IToString
   public _str toStringISO8601 ();
   public _str toStringLocal ();
   public _str toStringParts (DTType dtType=DT_UTCTIME,
                              DTParts dtParts=DT_DATE_TIME);
   static public DateTime fromTimeB (_str strTB='');
   static public DateTime fromTimeF (_str strTF='');
   static public DateTime fromString (_str strDT='');
   public boolean equalsByInterval (sc.lang.IEquals& rhs,
                                    DTSpan interval=DT_FRACTIONALSECOND);
   public DateTime add (double value=0, DTSpan interval=DT_FRACTIONALSECOND);

   public int dayOfWeek (_str& dOW=null, DTType dateType=DT_LOCALTIME);
   public int dayOfYear (DTType dateType=DT_LOCALTIME);
   public int year (DTType dateType=DT_LOCALTIME);
   public int month (DTType dateType=DT_LOCALTIME);
   public int day (DTType dateType=DT_LOCALTIME);
   public int hour (DTType dateType=DT_LOCALTIME);
   public int minute (DTType dateType=DT_LOCALTIME);
   public int second (DTType dateType=DT_LOCALTIME);
   public double fractionalSecond (DTType dateType=DT_LOCALTIME);
   public int millisecond (DTType dateType=DT_LOCALTIME);
   public void toParts(int& year, int& month, int& day,
                       int& hour, int& minute, int& second,
                       int& milliseconds, DTType dateType=DT_LOCALTIME);

   static private int s_months[] = {0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5};
   static private int s_monthLengths[] = {31, 28, 31, 30, 31, 30, 31, 31, 30,
                                          31, 30, 31};
   static private _str s_dayNames[] = {'Sunday', 'Monday', 'Tuesday',
                                       'Wednesday', 'Thursday', 'Friday',
                                       'Saturday'};
   private _str m_ISO8601_DateTime;


   /**
    * 
    * 
    * @param year 
    * @param month 
    * @param day 
    * @param hour 
    * @param minute 
    * @param second 
    * @param fractionalsecond 
    * @param dateType 
    * 
    * @return 
    */
   DateTime (int year=-1, int month=0, int day=0,
             int hour=-1, int minute=-1, int second=-1, double fractionalsecond=1.0,
             DTType dateType=DT_LOCALTIME)
   {
      if ((hour == -1) && (minute == -1) && (second == -1) && (fractionalsecond == 1.0)) {
         if ((year == -1) && (month == 0) && (day == 0)) {
            _str time = '';
            time = _time('F');
            year = (int)substr(time, 1, 4);
            month = (int)substr(time, 5, 2);
            day = (int)substr(time, 7, 2);
            hour = (int)substr(time, 9, 2);
            minute = (int)substr(time, 11, 2);
            second = (int)substr(time, 13, 2);
            fractionalsecond = (double)('.'substr(time, 15));
            dateType = DT_UTCTIME; //If we're generating a date, it will be UTC.
         } else {
            hour = 0;
            minute = 0;
            second = 0;
            fractionalsecond = 0.0;
         }         
      }

      //ASSERT(validDate(year, month, day));
      //ASSERT(validTime(hour, minute, second, fractionalsecond));
      
      _str YYYY = year;
      _str MM = month;
      _str DD = day;
      _str hh = hour;
      _str mm = minute;
      _str ss = second;
      _str fs = fractionalsecond;
      parse fs with . '.' fs;
      fs = '.'fs;
      if (fs != '.0') {
         while (last_char(fs) == '0') {
            fs = substr(fs, 1, length(fs)-1);
         }
      }
      if (last_char(fs) == '.') {
         fs = '.0';
      }
                           
      switch (length(YYYY)) {
      case 1:
         YYYY = '0'YYYY;
      case 2:
         YYYY = '0'YYYY;
      case 3:
         YYYY = '0'YYYY;
      }
      if (length(MM) == 1) MM = '0'MM;
      if (length(DD) == 1) DD = '0'DD;
      if (length(hh) == 1) hh = '0'hh;
      if (length(mm) == 1) mm = '0'mm;
      if (length(ss) == 1) ss = '0'ss;

      this.m_ISO8601_DateTime = YYYY'-'MM'-'DD'T'hh':'mm':'ss:+fs'Z';

      if (dateType == DT_LOCALTIME) {
         int offsetH = 0;
         int offsetM = 0;
         utcOffset(offsetH, offsetM);

         DateTime minuteAdjusted = this.add(offsetM, DT_MINUTE);
         ASSERT(minuteAdjusted != null);
         DateTime hourAdjusted = minuteAdjusted.add(-offsetH, DT_HOUR);
         ASSERT(hourAdjusted != null);

         this.m_ISO8601_DateTime = hourAdjusted.toStringISO8601();
      }
   }
   ~DateTime ()
   {
   }


   private boolean validDate (int YYYY=0, int MM=0, int DD=0)
   {
      //Is the year in the proper range?
      if ((YYYY < 0) || (YYYY > 9999)) {
         return false;
      }
      //Is the month in the proper range?
      if ((MM < 1) || (MM > 12)) {
         return false;
      }
      //Is the day in the proper range?
      if (DD < 1) {
         return false;
      } 
      if (MM != 2) { 
         if (DD > s_monthLengths[MM-1]) {
            return false;
         }
      } else {
         if (isLeapYear(YYYY)) {
            if (DD > 29) {
               return false;
            }
         } else if (DD > 28) {
            return false;
         }
      }

      return true;
   }


   private boolean validTime (int hh=0, int mm=0, int ss=0, double fs=0)
   {
      if ((hh < 0) || (hh > 24)) {
         return false;
      }
      if (hh == 24) { //24:00:00.0 is valid (midnight)
         if ((mm != 0) || (ss != 0) || (fs != 0)) {
            return false;
         }
      }
      if ((mm < 0) || (mm > 59)) {
         return false;
      }
      if ((ss < 0) || (ss > 59)) {
         return false;
      }
      if (fs < 0) { // There's nothing in ISO8601 about fractions of seconds.
         return false;
      }

      return true;
   }


   //Caracas, Venezuala is a good test case. No daylight savings, but UTC-4:30
   //Katmandu, Nepal is another good test case: UTC+5:45
   static public void utcOffset (int& hh, int& mm)
   {
      // get the parts of a current file time
      _str fileTime = _time('F');
      int uDay = (int)substr(fileTime, 7, 2);
      int uHour = (int)substr(fileTime, 9, 2);
      int uMinute = (int)substr(fileTime, 11, 2);

      _str localDate = _date('u');
      _str lDay;
      parse localDate with . '/' lDay '/' .;
      _str localTime = _time('m');
      _str lHour;
      _str lMinute;
      parse localTime with lHour ':' lMinute ':' .;

      if (uDay > lDay) {
         if ((lDay == 1) && (uDay > 2)) {
            uHour = uHour - 24;
         } else {
            uHour = uHour + 24;
         }
      } else if (uDay < lDay) {
         if ((uDay == 1) && (lDay > 2)) {
            uHour = uHour + 24;
         } else {
            uHour = uHour - 24;
         }
      }
      if (lMinute < uMinute) { // Carry an hour down to minutes, if we need to.
         lMinute = (int)lMinute + 60;
         lHour = (int)lHour - 1;
      }
      hh = ((int)lHour - (int)uHour);
      mm = ((int)lMinute - (int)uMinute);
   }


   /**
    * Determines if the given year, according to the Gregorian
    * calendar, is a leap year.
    * 
    * @author dobrien (Apr. 02, 2008)
    * 
    * @param iyear Year to check if a leap year 
    * 
    * @return (boolean) True is if <i>iyear</i> is a leap year.
    */
   static public boolean isLeapYear (int iyear) {
      return(!(iyear % 4) && (!(iyear % 400) || (iyear % 100)));
   }

   public long toTimeB ()
   {
      timePart := ((hour(DT_UTCTIME) * 60 * 60 * 1000) + 
                   (minute(DT_UTCTIME) * 60 * 1000) + 
                   (second(DT_UTCTIME) * 1000) + 
                   (int)(fractionalSecond(DT_UTCTIME) * 1000));
      datePart := ((year(DT_UTCTIME) * 32 * 16) +
                   (month(DT_UTCTIME) * 32) +
                   (day(DT_UTCTIME)));

      timeB := (long)datePart*10000000000 + timePart;
      return timeB;
   }

   /**
    * @return A string representing this object as a filetime
    */
   public long toTimeF()
   {
      timePart := ((hour(DT_UTCTIME) * 100 * 100 * 1000) + 
                   (minute(DT_UTCTIME) * 100 * 1000) + 
                   (second(DT_UTCTIME) * 1000) + 
                   (int)(fractionalSecond(DT_UTCTIME) * 1000));
      datePart := ((year(DT_UTCTIME) * 100 * 100) +
                   (month(DT_UTCTIME) * 100) +
                   (day(DT_UTCTIME)));

      timeB := (long)datePart*1000000000 + timePart;
      return timeB;
   }

   /**
    * @return A string representing this object.
    */
   public _str toString ()
   {
      return this.toStringISO8601();
   }


   /**
    * @return A string representing this object in ISO8601 format.
    */
   public _str toStringISO8601 ()
   {
      return this.m_ISO8601_DateTime;
   }


   /**
    * @return A string representing this object in the local system 
    *         format.
    */
   public _str toStringLocal ()
   {
      // if this isn't set, then we can't do anything
      if (this.m_ISO8601_DateTime == null) return null;

      // get the offset for the minute and the hour
      int offsetH = 0;
      int offsetM = 0;
      DateTime.utcOffset(offsetH, offsetM);
      if ((offsetH == 0) && (offsetM == 0)) {
         return this.toStringISO8601();
      }

      // adjust the minutes
      DateTime adjusted = this;
      if (offsetM) {
         if (offsetH > 0) {
            adjusted = adjusted.add(offsetM, DT_MINUTE);
         } else {
            adjusted = adjusted.add(-offsetM, DT_MINUTE);
         }
      }
      if (adjusted == null) {
         return null;
      }

      // now adjust the hours
      adjusted = adjusted.add(offsetH, DT_HOUR);
      if (adjusted == null) {
         return null;
      }
      if (offsetM < 0) {
         offsetM = -offsetM;
      }

      _str localizedDateTime;
      parse adjusted.toStringISO8601() with localizedDateTime 'Z';

      _str offsetHStr = offsetH;
      _str offsetMStr = offsetM;
      
      // If we're not using zulu time, we need a sign +/-.
      if ((offsetHStr > 0) ||
          ((offsetHStr == 0) && (offsetMStr > 0))) {
         offsetHStr = '+'offsetHStr;
      }

      // Hour offsets must be two digits and with a sign.
      if (length(offsetHStr) == 2) {
         offsetHStr = substr(offsetHStr, 1, 1):+'0':+substr(offsetHStr, 2, 1);
      }
      // Minute offsets must be two digits as well.
      if (length(offsetMStr) == 1) {
         offsetMStr = '0'offsetMStr;
      }
      
      return localizedDateTime:+offsetHStr':'offsetMStr;
   }


   public _str toStringParts (DTType dtType=DT_UTCTIME,
                              DTParts dtParts=DT_DATE_TIME)
   {
      _str tmpStr = '';
      if (dtType == DT_LOCALTIME) {
         tmpStr = this.toStringLocal();
      } else { //DT_UTCTIME and undefined values
         tmpStr = this.toStringISO8601();
      }

      switch (dtParts) {
      case DT_DATE:
         parse tmpStr with tmpStr 'T' .;
         break;
      case DT_TIME:
         parse tmpStr with . 'T' tmpStr;
         break;
      default: //DT_DATE_TIME and undefined values
         break;
      }

      return tmpStr; 
   }

   /**
    * Convert the output of _time('B') to a DateTime.  Note that this can only 
    * be used with values generated by _time('B') in v14 or later.  There was a 
    * bug in pre-v14 that caused _time('B') to be a little off. 
    * 
    * @param strTB 
    * 
    * @return 
    */
   static public DateTime fromTimeB (_str strTB='')
   {
      // use now for default parameter
      if (strTB == "") strTB = _time('B');

      // this value is the number of days
      temps := (int)substr(strTB, 1, length(strTB) - 10);
      tday := temps % 32;

      // subtract out the days
      temps -= tday;    

      // calculate the number of months
      temps /= 32;
      tmonth := temps % 16;

      // subtract the months - you get the years in days
      temps -= tmonth;     
      tyear := (int)temps / 16;

      // last ten characters are the time - that didn't change in the new format, 
      // this value is the number of milliseconds
      temps = (int)substr(strTB, length(strTB) - 10 + 1);

      // divide by (60 * 60 * 1000) to get the hours
      // divide by (60 * 1000) to get the minutes
      // what's left is the milliseconds
      thours := temps / (60 * 60 * 1000);
      temps -= (thours * 60 * 60 * 1000);
      tminutes := temps / (60 * 1000);
      temps -= (tminutes * 60 * 1000);
      tseconds := temps / 1000;
      tmilliseconds := temps % 1000;

      DateTime tmpDT(tyear, tmonth, tday, thours, tminutes, tseconds, ((double)(tmilliseconds)/1000), DT_UTCTIME);

      return tmpDT;
   }

   /**
    * Convert the output of _time('F') to a DateTime
    * 
    * @param strTF 
    * 
    * @return 
    */
   static public DateTime fromTimeF (_str strTF='')
   {
      // use now for default parameter
      if (strTF == "") strTF = _time('F');
      ASSERT(length(strTF) == 17);

      // convert the date time spec to a long integer
      dateTF := (long)substr(strTF,1,length(strTF)-9);
      timeTF := (long)substr(strTF,length(strTF)-8);

      // break down date into its parts
      tmilliseconds := (double)(timeTF % 1000);
      timeTF = timeTF intdiv 1000;
      tseconds := (int)(timeTF % 100);
      timeTF = timeTF intdiv 100;
      tminutes := (int)(timeTF % 100);
      timeTF = timeTF intdiv 100;
      thours := (int)(timeTF % 100);
      timeTF = timeTF intdiv 100;
      tday := (int)(dateTF % 100);
      dateTF = dateTF intdiv 100;
      tmonth := (int)(dateTF % 100);
      dateTF = dateTF intdiv 100;
      tyear := (int)dateTF;

      // construct the date time object
      DateTime tmpDT(tyear, tmonth, tday, 
                     thours, tminutes, tseconds, 
                     (tmilliseconds / 1000), 
                     DT_UTCTIME);
      return tmpDT;
   }

   static public DateTime fromString (_str strDT='')
   {
      _str date = '';
      _str time = '';
      _str YYYY = '';
      _str MM = '';
      _str DD = '';
      _str hh = '0';
      _str mm = '0';
      _str ss = '0';
      _str fs = '0.0';
      _str inOffset = '';

      parse strDT with date 'T' time;
      if ((date == '') && (time == '')) {
         return null;
      } else if (time == '') {
         if (pos(':', date) == 0) { // Date only
            parse date with YYYY '-' MM '-' DD;
            // Using local time.
            DateTime tmpDT((int)YYYY, (int)MM, (int)DD);
            return tmpDT;
         } else { // Time only, 'date' actually holds the time. 
            parse date with time '[Z+-]','r' inOffset;
            parse time with hh ':' mm ':' ss '.' fs;
            _str fTime = _time('F');
            int year = (int)substr(fTime, 1, 4);
            int month = (int)substr(fTime, 5, 2);
            int day = (int)substr(fTime, 7, 2);
            DateTime tmpDT(year, month, day, (int)hh, (int)mm, (int)ss,
                           (double)(0'.'fs), DT_UTCTIME);
            if (substr(inOffset, 1, 1) == '-') {
               tmpDT = tmpDT.add((int)substr(inOffset, 2), DT_HOUR);
            } else if (substr(inOffset, 1, 1) == '+') {
               tmpDT = tmpDT.add(-(int)substr(inOffset, 2), DT_HOUR);
            }
            return tmpDT;
         }
      } else { // This should be both Date and Time.
         parse date with YYYY '-' MM '-' DD;
         parse time with hh ':' mm ':' ss '.' fs '[Z+-]','r' inOffset;
         DateTime tmpDT((int)YYYY, (int)MM, (int)DD, (int)hh, (int)mm, (int)ss,
                        (double)(strip(0'.'fs)), DT_UTCTIME);
         _str hours;
         _str minutes;
         parse inOffset with hours ':' minutes;
         if (minutes == '') {
            minutes = '0';
         }
         if (pos('-', time) != 0) {
            tmpDT = tmpDT.add((int)hours, DT_HOUR);
            tmpDT = tmpDT.add((int)minutes, DT_MINUTE);
         } else if (pos('+', time) != 0) {
            tmpDT = tmpDT.add(-(int)hours, DT_HOUR);
            tmpDT = tmpDT.add(-(int)minutes, DT_MINUTE);
         }
         return tmpDT;
      }

      return null;
   }


   /**
    * Copy this object to the given destination. The destination
    * class instance will always be valid and initialized.
    * 
    * @param dest    Destination object, expected to be
    *                the same type as this class.
    * 
    */
   public void copy (sc.lang.IAssignTo& dest)
   {
      ((DateTime)dest).m_ISO8601_DateTime = this.m_ISO8601_DateTime;
   }


   /**
    * 
    * From IEquals 
    * 
    */
   public boolean equals (sc.lang.IEquals& rhs)
   {
      if (rhs == null) {
         return (this == null);
      }
      if (!(rhs instanceof se.datetime.DateTime)) {
         return false;
      }
      if (((DateTime)rhs).m_ISO8601_DateTime == null) {
         return (this.m_ISO8601_DateTime == null);
      }
      if (this.m_ISO8601_DateTime == null) return 1;
      return (this.m_ISO8601_DateTime :== ((DateTime)rhs).m_ISO8601_DateTime);
   }


   /**
    * Compare this DateTime to the given object.
    * 
    * @param rhs 
    * 
    * @return &lt;0 if 'this' is less than 'rhs', 0 if 'this'
    *         equals 'rhs', and &gt;0 if 'this' is greater than
    *         'rhs'.
    */
   public int compare (sc.lang.IComparable& rhs)
   {
      if (rhs == null) {
         return (this == null) ? 0 : -1;
      }
      if (((DateTime)rhs).m_ISO8601_DateTime == null) {
         return (this.m_ISO8601_DateTime == null) ? 0 : -1;
      }
      if (this.m_ISO8601_DateTime == null) return 1;
      if (this.m_ISO8601_DateTime :== ((DateTime)rhs).m_ISO8601_DateTime) return 0;
      return (this.m_ISO8601_DateTime < ((DateTime)rhs).m_ISO8601_DateTime) ? -1 : 1;
   }


   /**
    * @return Generate a string as the hash key for this object.
    */
   public _str getHashKey ()
   {
      return this.m_ISO8601_DateTime;
   }


   /**
    * @return
    * Returns a reference to an element in a collection, addressing
    * the element by the given index.  Returns null if there is no
    * such key.
    *
    * @param i  index of item to look up
    */
   public typeless _array_el(int i) {
      if ((i < 0) || (i > (length(this.m_ISO8601_DateTime)-1))) {
         return null;
      }
      return substr(this.m_ISO8601_DateTime, i+1, 1);
   }


   public boolean equalsByInterval (sc.lang.IEquals& rhs,
                                    DTSpan interval=DT_FRACTIONALSECOND)
   {
      if (rhs == null) {
         return (this == null);
      }
      if (!(rhs instanceof se.datetime.DateTime)) {
         return false;
      }
      if (((DateTime)rhs).m_ISO8601_DateTime == null) {
         return (this.m_ISO8601_DateTime == null);
      }
      if (this.m_ISO8601_DateTime == null) return 1;

      _str lhsDateTime;
      _str rhsDateTime;
      switch (interval) {
      case DT_YEAR:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 4);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 4);
         break;
      case DT_MONTH:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 7);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 7);
         break;
      case DT_DAY:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 10);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 10);
         break;
      case DT_HOUR:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 13);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 13);
         break;
      case DT_MINUTE:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 16);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 16);
         break;
      case DT_SECOND:
         lhsDateTime = substr(this.m_ISO8601_DateTime, 1, 19);
         rhsDateTime = substr(((DateTime)rhs).m_ISO8601_DateTime, 1, 19);
         break;
      case DT_FRACTIONALSECOND:
         lhsDateTime = this.m_ISO8601_DateTime;
         rhsDateTime = ((DateTime)rhs).m_ISO8601_DateTime;
         break;
      }

      return (lhsDateTime :== rhsDateTime);
   }


   public DateTime add (double value=0, DTSpan interval=DT_FRACTIONALSECOND)
   {
      int iValue = (int)value;
      int tmpYear = this.year(DT_UTCTIME);
      int tmpMonth = this.month(DT_UTCTIME);
      int tmpDay = this.day(DT_UTCTIME);
      int tmpHour = this.hour(DT_UTCTIME);
      int tmpMinute = this.minute(DT_UTCTIME);
      int tmpSecond = this.second(DT_UTCTIME);
      double tmpFSecond = this.fractionalSecond(DT_UTCTIME);
      int monthLength;

      if (interval == DT_FRACTIONALSECOND) tmpFSecond = tmpFSecond + value;
      if (interval == DT_SECOND) tmpSecond = tmpSecond + iValue;
      if (interval == DT_MINUTE) tmpMinute = tmpMinute + iValue;
      if (interval == DT_HOUR) tmpHour = tmpHour + iValue;
      if (interval == DT_DAY) tmpDay = tmpDay + iValue;
      if (interval == DT_YEAR) {
         tmpYear = tmpYear + iValue;
         monthLength = s_monthLengths[tmpMonth-1];
         if (isLeapYear(tmpYear) && (tmpMonth == 2)) {
            ++monthLength;
         }
         if (tmpDay > monthLength) {
            tmpDay = monthLength;
         }
      } else if (interval == DT_MONTH) {
         //Adding months is a special case. Some days at the end of some months
         //are not in the next month. In that case, truncate.
         tmpMonth = tmpMonth + iValue;
         while (tmpMonth > 12) {
            ++tmpYear;
            tmpMonth = tmpMonth - 12;
         }
         while (tmpMonth <= 0) {
            --tmpYear;
            tmpMonth = tmpMonth + 12;
         }
         monthLength = s_monthLengths[tmpMonth-1];
         if (isLeapYear(tmpYear) && (tmpMonth == 2)) {
            ++monthLength;
         }
         if (tmpDay > monthLength) {
            tmpDay = monthLength;
         }
      } else {
         while (tmpFSecond >= 1.0) {
            ++tmpSecond;
            tmpFSecond = tmpFSecond - 1.0;
         }
         while (tmpFSecond < 0.0) {
            --tmpSecond;
            tmpFSecond = tmpFSecond + 1.0;
         }
         while (tmpSecond >= 60) {
            ++tmpMinute;
            tmpSecond = tmpSecond - 60;
         }
         while (tmpSecond < 0) {
            --tmpMinute;
            tmpSecond = tmpSecond + 60;
         }
   
         while (tmpMinute >= 60) {
            ++tmpHour;
            tmpMinute = tmpMinute - 60;
         }
         while (tmpMinute < 0) {
            --tmpHour;
            tmpMinute = tmpMinute + 60;
         }
   
         while (tmpHour >= 24) {
            ++tmpDay;
            tmpHour = tmpHour - 24;
         }
         while (tmpHour < 0) {
            --tmpDay;
            tmpHour = tmpHour + 24;
         }

         if (tmpDay <= 0) {
            do {
               if (tmpMonth > 1) {
                  --tmpMonth;
               } else {
                  tmpMonth = 12;
                  --tmpYear;
               }
               monthLength = s_monthLengths[tmpMonth-1];
               if (isLeapYear(tmpYear) && (tmpMonth == 2)) {
                  ++monthLength;
               }
               tmpDay = tmpDay + monthLength;
            } while (tmpDay <= 0);
         } else {
            monthLength = s_monthLengths[tmpMonth-1];
            if (isLeapYear(tmpYear) && (tmpMonth == 2)) {
               ++monthLength;
            }
            while (tmpDay > monthLength) {
               tmpDay = tmpDay - monthLength;
               if (tmpMonth < 12) {
                  ++tmpMonth;
               } else {
                  tmpMonth = 1;
                  ++tmpYear;
               }
               monthLength = s_monthLengths[tmpMonth-1];
               if (isLeapYear(tmpYear) && (tmpMonth == 2)) {
                  ++monthLength;
               }
            }
         }

         while (tmpMonth > 12) {
            ++tmpYear;
            tmpMonth = tmpMonth - 12;
         }
         while (tmpMonth < 0) {
            --tmpYear;
            tmpMonth = tmpMonth + 12;
         }
      }

      DateTime resultingDate(tmpYear, tmpMonth, tmpDay, tmpHour, tmpMinute,
                             tmpSecond, tmpFSecond, DT_UTCTIME);
      return resultingDate;
   }
   

   /**
    * Returns the number of the day of the week: 0 = Monday ... 6 =
    * Sunday.
    *  
    * If a string is passed in, the English name of the day of the 
    * week is returned in that string.
    * 
    * @param dOW 
    * 
    * @return 
    */
   public int dayOfWeek (_str& dOW=null, DTType dateType=DT_LOCALTIME)
   {
      int year = this.year(dateType);
      int month = this.month(dateType);
      int day = this.day(dateType);
      int shortYear = year%100;
      int y = shortYear + shortYear/4;
      int century = (year-shortYear)/100;
      int c = (3 - (century%4))*2;
      int m = s_months[month-1];
      int sum = c + y + m + day;
      if ((month <= 2) && isLeapYear(year)) {
         --sum; //Deduct 1 from the final sum in leap years if the month is
                //January or February.
      }

      if (dOW != null) {
         dOW = s_dayNames[sum%7];
      }
      return (sum%7);
   }


   public int dayOfYear (DTType dateType=DT_LOCALTIME)
   {
      int mon;
      int dOY = 0;

      int year = this.year(dateType);
      int month = this.month(dateType);
      int day = this.day(dateType);

      for (mon = 0; mon < (month-1); ++mon) {
         dOY = dOY + s_monthLengths[mon];
      }
      if ((month > 2) && isLeapYear(year)) {
         ++dOY;
      }
      dOY = dOY + day;

      //Compare to http://www.vpcalendar.net/Julian_Date.html for non-leap years.
      return dOY;
   }


   public int year (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 1, 4);
   }


   public int month (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 6, 2);
   }


   public int day (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 9, 2);
   }


   public int hour (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 12, 2);
   }


   public int minute (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 15, 2);
   }


   public int second (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      return(int)substr(timeString, 18, 2);
   }


   public double fractionalSecond (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();
      
      //ISO8601 doesn't specify the number of characters for fractional seconds.
      _str fs;
      parse timeString with . '.' fs '[Z+-]','r' .;
      return (double)('.'fs);
   }

   public int millisecond (DTType dateType=DT_LOCALTIME)
   {
      if (this.m_ISO8601_DateTime == null) {
         return -1;
      }
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      //ISO8601 doesn't specify the number of characters for fractional seconds.
      _str fs;
      parse timeString with . '.' fs '[Z+-]','r' .;
      return (int)fs;
   }

   public void toParts(int& year, int& month, int& day, int& hour, int& minute, int& second, int& milliseconds, DTType dateType=DT_LOCALTIME)
   {
      year = month = day = hour = minute = second = milliseconds = 0;

      // can't do anything if this isn't set
      if (this.m_ISO8601_DateTime == null) {
         return;
      }

      // get the time string, then we'll parse it
      _str timeString = '';
      if (dateType == DT_LOCALTIME) timeString = this.toStringLocal();
      else if (dateType == DT_UTCTIME) timeString = this.toStringISO8601();

      year = (int)substr(timeString, 1, 4);
      month = (int)substr(timeString, 6, 2);
      day = (int)substr(timeString, 9, 2);
      hour = (int)substr(timeString, 12, 2);
      minute = (int)substr(timeString, 15, 2);
      second = (int)substr(timeString, 18, 2);

      //ISO8601 doesn't specify the number of characters for fractional seconds.
      _str fs;
      parse timeString with . '.' fs '[Z+-]','r' .;
      milliseconds = (int)fs;
   }
};
