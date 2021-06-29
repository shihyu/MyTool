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
#require "sc/lang/String.e"
#require "se/datetime/DateTime.e"
#endregion



namespace se.datetime



enum DateTimeDurationType {
   DTD_YMDHMS=0,
   DTD_W
};



class DateTimeDuration :
   sc.lang.IToString,
   sc.lang.IAssignTo,
   sc.lang.IEquals,
   sc.lang.IComparable,
   sc.lang.IHashable
{
   public _str toString (); //IToString
   static public DateTimeDuration fromString (_str strDTD='');
   public void copy (sc.lang.IAssignTo& dest); //IAssignTo
   public bool equals (sc.lang.IEquals& rhs); //IEquals
   public int compare (sc.lang.IComparable& rhs); //IComparable
   public _str getHashKey (); //IHashable

   public DateTimeDuration add (DateTimeDuration& rhs);

   public int years ();
   public int months ();
   public int weeks ();
   public int days ();
   public int hours ();
   public int minutes ();
   public int seconds ();

   private _str m_DateTimeDuration;


   /**
    * Author: nbeddes
    * Date:   8/12/2008
    *
    * Disallow fractional seconds for now. It is unclear to me if 
    * ISO 8601 Durations allow for them. 
    *  
    * Disallow fractional anything else too for now. It is also 
    * unclear to me how to define things like "0.5 months". 
    *  
    * In this implementation, date and time values may not  
    * 
    * @param DTDType 
    * @param yearOrWeek 
    * @param month 
    * @param day 
    * @param hour 
    * @param minute 
    * @param second 
    * 
    * @return 
    */
   DateTimeDuration (DateTimeDurationType DTDType=DTD_YMDHMS, int yearOrWeek=0,
                     int month=0, int day=0, int hour=0, int minute=0,
                     double second=0)
   {
      if (DTDType == DTD_W) {
         if (yearOrWeek < 0) {
            this.m_DateTimeDuration = null;
            return;
         }
         this.m_DateTimeDuration = 'P'yearOrWeek'W';
         return;
      } else if (DTDType != DTD_YMDHMS) {
         this.m_DateTimeDuration = null;
         return;
      }

      this.m_DateTimeDuration = 'P';

      timeUsed := false;
      if (yearOrWeek < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (yearOrWeek > 0) {
         this.m_DateTimeDuration = this.m_DateTimeDuration:+yearOrWeek'Y';
      }
      if (month < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (month > 0) {
         this.m_DateTimeDuration = this.m_DateTimeDuration:+month'M';
      }
      if (day < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (day > 0) {
         this.m_DateTimeDuration = this.m_DateTimeDuration:+day'D';
      }
      if (hour < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (hour > 0) {
         this.m_DateTimeDuration = this.m_DateTimeDuration:+'T'hour'H';
         timeUsed = true;
      }
      if (minute < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (minute > 0) {
         if (!timeUsed) {
            this.m_DateTimeDuration = this.m_DateTimeDuration:+'T';
            timeUsed = true;
         }
         this.m_DateTimeDuration = this.m_DateTimeDuration:+minute'M';
      }
      if (second < 0) {
         this.m_DateTimeDuration = null;
         return;
      } else if (second > 0) {
         if (!timeUsed) {
            this.m_DateTimeDuration = this.m_DateTimeDuration:+'T';
            timeUsed = true;
         }
         this.m_DateTimeDuration = this.m_DateTimeDuration:+second'S';
      }
   }
   ~DateTimeDuration ()
   {
   }


   /**
    * @return A string representing this object.
    */
   public _str toString ()
   {
      return this.m_DateTimeDuration;
   }


   static public DateTimeDuration fromString (_str strDTD='')
   {
      if (substr(strDTD, 1, 1) != 'P') {
         return null;
      }

      _str year = 0;
      _str month = 0;
      _str week = 0;
      _str day = 0;
      _str hour = 0;
      _str minute = 0;
      _str second = 0;

      _str dt;
      int i;

      if (pos('W', strDTD, 1) != 0) {
         // Weeks
         parse strDTD with dt 'T' .;
         i = pos('[0-9]*W', dt, 1, 'U');
         if (i > 0) {
            parse substr(dt, i) with week 'W' .;
         }
         DateTimeDuration tmpDTD(DTD_W, (int)week);
         return tmpDTD;
      }

      // Years
      parse strDTD with dt 'T' .;
      i = pos('[0-9]*Y', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with year 'Y' .;
      }
      // Months
      parse strDTD with dt 'T' .;
      i = pos('[0-9]*M', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with month 'M' .;
      }
      // Days
      parse strDTD with dt 'T' .;
      i = pos('[0-9]*D', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with day 'D' .;
      }
      // Hours
      parse strDTD with . 'T' dt;
      i = pos('[0-9]*H', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with hour 'H' .;
      }
      // Minutes
      parse strDTD with . 'T' dt;
      i = pos('[0-9]*M', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with minute 'M' .;
      }
      // Seconds
      parse strDTD with . 'T' dt;
      i = pos('[0-9]*S', dt, 1, 'U');
      if (i > 0) {
         parse substr(dt, i) with second 'S' .;
      }

      DateTimeDuration tmpDTD(DTD_YMDHMS, (int)year, (int)month, (int)day,
                              (int)hour, (int)minute, (int)second);
      return tmpDTD;
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
      ((DateTimeDuration)dest).m_DateTimeDuration = this.m_DateTimeDuration;
   }


   /**
    * 
    * From IEquals 
    * 
    */
   public bool equals (sc.lang.IEquals& rhs)
   {
      if (rhs == null) {
         return (this == null);
      }
      if (!(rhs instanceof se.datetime.DateTimeDuration)) {
         return false;
      }
      if (((DateTimeDuration)rhs).m_DateTimeDuration == null) {
         return (this.m_DateTimeDuration == null);
      }
      if (this.m_DateTimeDuration == null) return true;
      return (this.m_DateTimeDuration :== ((DateTimeDuration)rhs).m_DateTimeDuration);
   }


   /**
    * Compare this DateTimeDuration to the given object. 
    *  
    * The default ISO 8601 representation of durations does not 
    * care if individual date and time values exceed their 
    * "carry-over points". For example "P60D" is a valid duration. 
    * Therefore, duration comparisons compare individual date and 
    * time values, from large to small: P2M is 'longer' than 
    * P1M35D. 
    * 
    * @param rhs 
    * 
    * @return &lt;0 if 'this' is shorter than 'rhs', 0 if 'this' 
    *         equals 'rhs', and &gt;0 if 'this' is longer than
    *         'rhs'.
    */
   public int compare (sc.lang.IComparable& rhs)
   {
      if (rhs == null) {
         return (this == null) ? 0 : -1;
      }
      if (((DateTimeDuration)rhs).m_DateTimeDuration == null) {
         return (this.m_DateTimeDuration == null) ? 0 : -1;
      }
      if (this.m_DateTimeDuration == null) return 1;
      if (this.m_DateTimeDuration :== ((DateTimeDuration)rhs).m_DateTimeDuration) {
         return 0;
      }

      DateTimeDuration leftDTD(DTD_YMDHMS);
      leftDTD = leftDTD.add(this);
      DateTimeDuration rightDTD(DTD_YMDHMS);
      rightDTD = rightDTD.add((DateTimeDuration)rhs);
      int leftDuration, rightDuration;
      leftDuration = leftDTD.years();
      rightDuration = rightDTD.years();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.months();
      rightDuration = rightDTD.months();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.weeks();
      rightDuration = rightDTD.weeks();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.days();
      rightDuration = rightDTD.days();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.hours();
      rightDuration = rightDTD.hours();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.minutes();
      rightDuration = rightDTD.minutes();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      leftDuration = leftDTD.seconds();
      rightDuration = rightDTD.seconds();
      if (leftDuration > rightDuration) return -1;
      if (leftDuration < rightDuration) return 1;
      return 0;
   }


   /**
    * @return Generate a string as the hash key for this object.
    */
   public _str getHashKey ()
   {
      return this.m_DateTimeDuration;
   }


   public DateTimeDuration add (DateTimeDuration& rhs)
   {
      DateTimeDurationType DTDType;
      tmpYearOrWeek := 0;
      tmpWeek := 0;
      tmpYear := 0;
      tmpMonth := 0;
      tmpDay := 0;
      tmpHour := 0;
      tmpMinute := 0;
      tmpSecond := 0;

      lhsWeek := (this.weeks() != 0);
      rhsWeek := (rhs.weeks() != 0);

      if (lhsWeek || rhsWeek) {
         DTDType = DTD_W;
         tmpWeek = this.weeks() + rhs.weeks();
         tmpYearOrWeek = tmpWeek;
      }
      if (!lhsWeek || !rhsWeek) {
         DTDType = DTD_YMDHMS;
         tmpYear = this.years() + rhs.years();
         tmpMonth = this.months() + rhs.months();
         tmpDay = this.days() + rhs.days();
         tmpHour = this.hours() + rhs.hours();
         tmpMinute = this.minutes() + rhs.minutes();
         tmpSecond = this.seconds() + rhs.seconds();
         tmpYearOrWeek = tmpYear;
      }
      if (lhsWeek != rhsWeek) {
         tmpDay = 7*tmpWeek;
      }

      DateTimeDuration tmpDTD(DTDType, tmpYearOrWeek, tmpMonth, tmpDay, tmpHour,
                              tmpMinute, tmpSecond);
      return tmpDTD;
   }
   

   public int years ()
   {
      _str output;
      _str date;
      parse this.m_DateTimeDuration with date 'T' .;
      start := pos('[0-9]*Y', date, 1, 'U');
      if (start > 0) {
         parse substr(date, start) with output 'Y' .;
         return (int)output;
      }

      return 0;
   }


   public int months ()
   {
      _str output;
      _str date;
      parse this.m_DateTimeDuration with date 'T' .;
      start := pos('[0-9]*M', date, 1, 'U');
      if (start > 0) {
         parse substr(date, start) with output 'M' .;
         return (int)output;
      }

      return 0;
   }


   public int weeks ()
   {
      _str output;
      _str date;
      parse this.m_DateTimeDuration with date 'T' .;
      start := pos('[0-9]*W', date, 1, 'U');
      if (start > 0) {
         parse substr(date, start) with output 'W' .;
         return (int)output;
      }

      return 0;
   }


   public int days ()
   {
      _str output;
      _str date;
      parse this.m_DateTimeDuration with date 'T' .;
      start := pos('[0-9]*D', date, 1, 'U');
      if (start > 0) {
         parse substr(date, start) with output 'D' .;
         return (int)output;
      }

      return 0;
   }


   public int hours ()
   {
      _str output;
      _str time;
      parse this.m_DateTimeDuration with . 'T' time;
      start := pos('[0-9]*H', time, 1, 'U');
      if (start > 0) {
         parse substr(time, start) with output 'H' .;
         return (int)output;
      }

      return 0;
   }


   public int minutes ()
   {
      _str output;
      _str time;
      parse this.m_DateTimeDuration with . 'T' time;
      start := pos('[0-9]*M', time, 1, 'U');
      if (start > 0) {
         parse substr(time, start) with output 'M' .;
         return (int)output;
      }

      return 0;
   }


   public int seconds ()
   {
      _str output;
      _str time;
      parse this.m_DateTimeDuration with . 'T' time;
      start := pos('[0-9]*S', time, 1, 'U');
      if (start > 0) {
         parse substr(time, start) with output 'S' .;
         return (int)output;
      }

      return 0;
   }
};
