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
#include "slick.sh"
#require "DateTime.e"
#require "DateTimeDuration.e"
#require "se/util/IFilter.e"
#import "calendar.e"
#import "listbox.e"
#endregion



namespace se.datetime;



enum DTIType {
   DTI_START_END=0, // In ISO 8601
   DTI_START_DURATION, // In ISO 8601
   DTI_DURATION_END, // In ISO 8601
   DTI_DURATION, //In ISO 8601 ... but it also needs "context information" (?).
   DTI_AUTO_THIS_MINUTE,
   DTI_AUTO_THIS_HOUR,
   DTI_AUTO_YESTERDAY,
   DTI_AUTO_TODAY,
   DTI_AUTO_TOMORROW,
   DTI_AUTO_THIS_WEEK,
   DTI_AUTO_THIS_MONTH,
   DTI_AUTO_THIS_YEAR
};



DTIType g_autoDateTimeIntervals:[];
void init_auto_datetimeintervals() // Called from definit() in DateTimeFilter.e
{
   g_autoDateTimeIntervals:['This Minute'] = DTI_AUTO_THIS_MINUTE;
   g_autoDateTimeIntervals:['This Hour'] = DTI_AUTO_THIS_HOUR;
   g_autoDateTimeIntervals:['Yesterday'] = DTI_AUTO_YESTERDAY;
   g_autoDateTimeIntervals:['Today'] = DTI_AUTO_TODAY;
   g_autoDateTimeIntervals:['Tomorrow'] = DTI_AUTO_TOMORROW;
   g_autoDateTimeIntervals:['This Week'] = DTI_AUTO_THIS_WEEK;
   g_autoDateTimeIntervals:['This Month'] = DTI_AUTO_THIS_MONTH;
   g_autoDateTimeIntervals:['This Year'] = DTI_AUTO_THIS_YEAR;
}



enum DTIStringType {
   DTIS_ISO8601=0,
   DTIS_LOCAL,
   DTIS_PLAIN_ISO8601,
   DTIS_PLAIN_LOCAL
};


class DateTimeInterval :
   sc.lang.IAssignTo,
   sc.lang.IEquals,
   sc.lang.IHashable,
   sc.lang.IToString,
   se.util.IFilter
{
   public void copy (sc.lang.IAssignTo& dest); //IAssignTo
   public bool equals (sc.lang.IEquals& rhs); //IEquals
   public _str getHashKey (); //IHashable
   public _str toString (); //IToString
   public bool filter (typeless& rhs); //IFilter
   
   public void update ();

   public void setStringFormat (DTIStringType stringType);
   public void setDateTimeParts (DTParts DateTimeParts);

   private _str toStringISO8601 ();
   private _str toStringPlain ();
   static public DateTimeInterval fromString (_str name = '', _str strDTI='');

   private void refreshThisMinute ();
   private void refreshThisHour ();
   private void refreshYesterday ();
   private void refreshToday ();
   private void refreshTomorrow ();
   private void refreshThisWeek ();
   private void refreshThisMonth ();
   private void refreshThisYear ();

   private DTIType m_DTIType;
   private DTIStringType m_DTIStringType;
   private DTParts m_DTParts;
   private DateTime m_start;
   private DateTime m_end;
   private DateTimeDuration m_duration;
   private _str m_filterName;
   private _str m_repetitions;
   private int m_weekStart; // 0 = Monday ... 6 = Sunday
   public bool m_activeFilterLists:[];


   /**
    * Author: nbeddes
    * Date:   8/19/2008
    *
    * If the start or end DateTime is null when the DTIType 
    * indicates it shouldn't be, it is set to the current time. 
    *  
    * If duration is null for DTI_START_DURATION or 
    * DTI_DURATION_END then the interval is all time before or 
    * after the end or start time, respectively.
    *  
    * When the DTIType is DTI_START_DURATION or DTI_DURATION_END, 
    * if repetitions is less than 0, then there are an unbounded 
    * number of repetitions. 
    * 
    * @param DTIType 
    * @param name 
    * @param startOrDuration 
    * @param durationOrEnd 
    * @param repetitions 
    * 
    * @return 
    */
   DateTimeInterval (DTIType DTIType=DTI_START_END, _str name='',
                     typeless& startOrDuration=null,
                     typeless& durationOrEnd=null, typeless& repetitions=null)
   {
      this.m_DTIType = DTIType;
      this.m_DTIStringType = DTIS_ISO8601;
      this.m_DTParts = DT_DATE_TIME;
      this.m_filterName = name;
      this.m_weekStart = 0; // 0 = Sunday ... 6 = Saturday
      
      if (repetitions == null) {
         this.m_repetitions = 0;
      } else if (repetitions._varformat() == VF_INT) {
         if (repetitions > 0) {
            this.m_repetitions = repetitions;
         } else {
            this.m_repetitions = 0;
         }
      } else if (repetitions._varformat() == VF_LSTR) {
         if (repetitions :== '*') {
            this.m_repetitions = '';
         } else {
            this.m_repetitions = 0;
         }
      }

      this.m_start = null;
      this.m_end = null;
      this.m_duration = null;

      switch (this.m_DTIType) {
      case DTI_START_END:
         if (startOrDuration instanceof se.datetime.DateTime) {
            this.m_start = (DateTime)startOrDuration;
         } else {
            this.m_start = null;
         }
         if (this.m_start == null) {
            DateTime startNow;
            this.m_start = startNow;
         }
         if (durationOrEnd instanceof se.datetime.DateTime) {
            this.m_end = (DateTime)durationOrEnd;
         } else {
            this.m_end = null;
         }
         if (this.m_end == null) {
            DateTime endNow;
            this.m_end = endNow;
         }
         break;
      case DTI_START_DURATION:
         if (startOrDuration instanceof se.datetime.DateTime) {
            this.m_start = (DateTime)startOrDuration;
         } else {
            this.m_start = null;
         }
         if (this.m_start == null) {
            DateTime startNow;
            this.m_start = startNow;
         }
         if (durationOrEnd instanceof se.datetime.DateTimeDuration) {
            this.m_duration = (DateTimeDuration)durationOrEnd;
         } else {
            this.m_duration = null;
         }
         if (this.m_repetitions == 0) {
            if (this.m_duration == null) {
               // Make a DateTimeDuration that is longer than DateTimes are allowed
               // to be large.
               DateTimeDuration longDuration(DTD_YMDHMS, 10000);
               this.m_duration = longDuration;
            }
            if (this.m_duration.toString() :== 'P10000Y') {
               //Go out to 9999-12-30 instead of 9999-12-31, because we don't
               //want to cause DateTime to assert that we've given it a bad
               //date in some timezones, which would roll over to the year 10000.
               DateTime endDate(9999, 12, 30, 24, 0, 0, 0.0);
               this.m_end = endDate;
            } else {
               this.m_end = this.m_start;
               this.m_end = this.m_end.add(this.m_duration.years(), DT_YEAR);
               this.m_end = this.m_end.add(this.m_duration.months(), DT_MONTH);
               this.m_end = this.m_end.add((this.m_duration.weeks()*7), DT_DAY);
               this.m_end = this.m_end.add(this.m_duration.days(), DT_DAY);
               this.m_end = this.m_end.add(this.m_duration.hours(), DT_HOUR);
               this.m_end = this.m_end.add(this.m_duration.minutes(), DT_MINUTE);
               this.m_end = this.m_end.add(this.m_duration.seconds(), DT_SECOND);
            }
         }
         break;
      case DTI_DURATION_END:
         if (startOrDuration instanceof se.datetime.DateTimeDuration) {
            this.m_duration = (DateTimeDuration)startOrDuration;
         } else {
            this.m_duration = null;
         }
         
         if (durationOrEnd instanceof se.datetime.DateTime) {
            this.m_end = (DateTime)durationOrEnd;
         } else {
            this.m_end = null;
         }
         if (this.m_end == null) {
            DateTime endNow;
            this.m_end = endNow;
         }
         if (this.m_repetitions == 0) {
            if (this.m_duration == null) {
               // Make a DateTimeDuration that is longer than DateTimes are allowed
               // to be large.
               DateTimeDuration longDuration(DTD_YMDHMS, 10000);
               this.m_duration = longDuration;
            }
            if (this.m_duration.toString() :== 'P10000Y') {
               DateTime zeroDate(0, 1, 1, 0, 0, 0, 0.0);
               this.m_start = zeroDate;
            } else {
               this.m_start = this.m_end;
               this.m_start = this.m_start.add(-this.m_duration.years(), DT_YEAR);
               this.m_start = this.m_start.add(-this.m_duration.months(), DT_MONTH);
               this.m_start = this.m_start.add(-(this.m_duration.weeks()*7), DT_DAY);
               this.m_start = this.m_start.add(-this.m_duration.days(), DT_DAY);
               this.m_start = this.m_start.add(-this.m_duration.hours(), DT_HOUR);
               this.m_start = this.m_start.add(-this.m_duration.minutes(), DT_MINUTE);
               this.m_start = this.m_start.add(-this.m_duration.seconds(), DT_SECOND);
            }
         }
         break;
      case DTI_DURATION:
         if (startOrDuration instanceof se.datetime.DateTimeDuration) {
            this.m_duration = (DateTimeDuration)startOrDuration;
         } else {
            DateTimeDuration longDuration(DTD_YMDHMS, 10000);
            this.m_duration = longDuration;
         }
         break;
      case DTI_AUTO_THIS_MINUTE:
         refreshThisMinute();
         break;
      case DTI_AUTO_THIS_HOUR:
         refreshThisHour();
         break;
      case DTI_AUTO_YESTERDAY:
         refreshYesterday();
         break;
      case DTI_AUTO_TODAY:
         refreshToday();
         break;
      case DTI_AUTO_TOMORROW:
         refreshTomorrow();
         break;
      case DTI_AUTO_THIS_WEEK:
         if ((startOrDuration != null) &&
             (startOrDuration._varformat() != VF_OBJECT) &&
             (isinteger(startOrDuration))) {
            this.m_weekStart = startOrDuration;
         }
         refreshThisWeek();
         break;
      case DTI_AUTO_THIS_MONTH:
         refreshThisMonth();
         break;
      case DTI_AUTO_THIS_YEAR:
         refreshThisYear();
         break;
      }
   }
   ~DateTimeInterval ()
   {
   }


   /**
    *
    * from IAssignTo
    * 
    * Copy this object to the given destination.  The destination
    * class will always be a valid and initialized class instance.
    *
    * @param dest   Destination object, expected to be
    *               the same type as this class.
    */
   public void copy (sc.lang.IAssignTo& dest)
   {
      ((DateTimeInterval)dest).m_DTIType = this.m_DTIType;
      ((DateTimeInterval)dest).m_filterName = this.m_filterName;
      ((DateTimeInterval)dest).m_start = this.m_start;
      ((DateTimeInterval)dest).m_end = this.m_end;
      ((DateTimeInterval)dest).m_duration = this.m_duration;
      ((DateTimeInterval)dest).m_repetitions = this.m_repetitions;
      ((DateTimeInterval)dest).m_activeFilterLists = this.m_activeFilterLists;
      ((DateTimeInterval)dest).m_weekStart = this.m_weekStart;
   }


   /**
    *
    * from IEquals
    * 
    */
   public bool equals (sc.lang.IEquals& rhs)
   {
      if (rhs == null) {
         return (this == null);
      }
      if (!(rhs instanceof se.datetime.DateTimeInterval)) {
         return false;
      }
      // Need to check each element in the m_activeFilterLists
      return ((this.m_DTIType :== ((DateTimeInterval)rhs).m_DTIType) &&
              (this.m_filterName :== ((DateTimeInterval)rhs).m_filterName) &&
              (this.m_start == ((DateTimeInterval)rhs).m_start) &&
              (this.m_end == ((DateTimeInterval)rhs).m_end) &&
              (this.m_duration == ((DateTimeInterval)rhs).m_duration) &&
              (this.m_repetitions :== ((DateTimeInterval)rhs).m_repetitions) &&
              (this.m_weekStart :== ((DateTimeInterval)rhs).m_weekStart));
   }


   /**
    *
    * from IHashable
    * 
    */
   public _str getHashKey ()
   {
      return this.m_filterName;
   }


   /**
    *  
    * from IToString 
    *  
    */
   public _str toString () {
      switch (m_DTIType) {
      case DTI_AUTO_THIS_MINUTE:
         return '(This Minute)';
      case DTI_AUTO_THIS_HOUR:
         return '(This Hour)';
      case DTI_AUTO_YESTERDAY:
         return '(Yesterday)';
      case DTI_AUTO_TODAY:
         return '(Today)';
      case DTI_AUTO_TOMORROW:
         return '(Tomorrow)';
      case DTI_AUTO_THIS_WEEK:
         return '(This Week)';
      case DTI_AUTO_THIS_MONTH:
         return '(This Month)';
      case DTI_AUTO_THIS_YEAR:
         return '(This Year)';
      }
 
      switch (m_DTIStringType) {
      case DTIS_ISO8601:
      case DTIS_LOCAL:
         return toStringISO8601();
         break;
      case DTIS_PLAIN_ISO8601:
      case DTIS_PLAIN_LOCAL:
         return toStringPlain();
         break;
      default:
         break;
      }
      return toStringISO8601();
   }



   private _str toStringISO8601 ()
   {
      interval := "";
      if ((this.m_repetitions > 0) || (this.m_repetitions :== '')) {
         interval = 'R'this.m_repetitions'/';
      }

      DTType dtType;
      if (m_DTIStringType == DTIS_ISO8601) {
         dtType = DT_UTCTIME;
      } else {
         dtType = DT_LOCALTIME;
      }

      switch (this.m_DTIType) {
      case DTI_START_END:
      case DTI_AUTO_THIS_MINUTE:
      case DTI_AUTO_THIS_HOUR:
      case DTI_AUTO_YESTERDAY:
      case DTI_AUTO_TODAY:
      case DTI_AUTO_TOMORROW:
      case DTI_AUTO_THIS_WEEK:
      case DTI_AUTO_THIS_MONTH:
      case DTI_AUTO_THIS_YEAR:
         interval = interval:+this.m_start.toStringParts(dtType, m_DTParts)"/":+
            this.m_end.toStringParts(dtType, m_DTParts);
         break;
      case DTI_START_DURATION:
         interval = interval:+this.m_start.toStringParts(dtType, m_DTParts)"/":+
            this.m_duration.toString();
         break;
      case DTI_DURATION_END:
         interval = interval:+this.m_duration.toString()"/":+
            this.m_end.toStringParts(dtType, m_DTParts);
         break;
      case DTI_DURATION:
         interval :+= this.m_duration.toString();
         break;
      default:
         break;
      }

      return interval;
   }


   private _str toStringPlain ()
   {
      interval := "";

      DTType dtType;
      if (m_DTIStringType == DTIS_PLAIN_ISO8601) {
         dtType = DT_UTCTIME;
      } else {
         dtType = DT_LOCALTIME;
      }

      startDT := "";
      endDT := "";
      duration := "";
      _str dateAndHour;
      _str minute;

      switch (this.m_DTIType) {
      case DTI_START_END:
      case DTI_AUTO_THIS_MINUTE:
      case DTI_AUTO_THIS_HOUR:
      case DTI_AUTO_YESTERDAY:
      case DTI_AUTO_TODAY:
      case DTI_AUTO_TOMORROW:
      case DTI_AUTO_THIS_WEEK:
      case DTI_AUTO_THIS_MONTH:
      case DTI_AUTO_THIS_YEAR:
         startDT = this.m_start.toStringParts(dtType, m_DTParts);
         parse startDT with dateAndHour ':' minute ':' .;
         startDT = dateAndHour;
         if (minute != '') {
            startDT :+= ':'minute;
         }
         endDT = this.m_end.toStringParts(dtType, m_DTParts);
         parse endDT with dateAndHour ':' minute ':' .;
         endDT = dateAndHour;
         if (minute != '') {
            endDT :+= ':'minute;
         }
         if (startDT :== endDT) {
            interval = 'Equal to 'startDT;
         } else {
            interval = 'From 'startDT' until 'endDT;
         }
         break;
      case DTI_START_DURATION:
         startDT = this.m_start.toStringParts(dtType, m_DTParts);
         parse startDT with dateAndHour ':' minute ':' .;
         startDT = dateAndHour;
         if (minute != '') {
            startDT :+= ':'minute;
         }
         duration = this.m_duration.toString();
         interval = 'Starting 'startDT;
         if (duration :!= 'P10000Y') {
            interval :+= ', for 'duration;
         }
         break;
      case DTI_DURATION_END:
         duration = this.m_duration.toString();
         endDT = this.m_end.toStringParts(dtType, m_DTParts);
         parse endDT with dateAndHour ':' minute ':' .;
         endDT = dateAndHour;
         if (minute != '') {
            endDT :+= ':'minute;
         }
         if (duration :== 'P10000Y') {
            interval = 'Until 'endDT;
         } else {
            interval = 'For 'duration', until 'endDT;
         }
         break;
      case DTI_DURATION:
         interval = 'For 'this.m_duration.toString();
         break;
      default:
         break;
      }

      if ((this.m_repetitions > 0) || (this.m_repetitions :== '')) {
         interval :+= ', repeated 'this.m_repetitions' times';
      }

      return interval;
   }


   static public DateTimeInterval fromString (_str name = '', _str strDTI='')
   {
      reps := 0;

      // If there are repetitions, save and remove from string.
      if (pos('R', strDTI, 1) == 1) {
         _str R;
         parse strDTI with 'R' R '/' strDTI;
         reps = (int) R;
      }

      // DTI_DURATION or garbage
      if (pos('/', strDTI, 1) == 0) {
         DateTimeDuration tmpDTD;
         tmpDTD = DateTimeDuration.fromString(strDTI);
         if (tmpDTD != null) {
            DateTimeInterval tmpDTI(DTI_DURATION, name, tmpDTD, null, reps);
            return tmpDTI;
         }
         return null;
      }

      l := "";
      r := "";
      parse strDTI with l '/' r;

      if (pos('P', l, 1) == 1) { // should be DTI_DURATION_END
         DateTimeDuration tmpDTD;
         tmpDTD = DateTimeDuration.fromString(l);
         DateTime tmpDT;
         tmpDT = DateTime.fromString(r);
         if ((tmpDTD == null) || (tmpDT == null)) {
            return null;
         }
         DateTimeInterval tmpDTI(DTI_DURATION_END, name, tmpDTD, tmpDT, reps);
         return tmpDTI;
      } else if (pos('P', r, 1) == 1) { // should be DTI_START_DURATION
         DateTime tmpDT;
         tmpDT = DateTime.fromString(l);
         DateTimeDuration tmpDTD;
         tmpDTD = DateTimeDuration.fromString(r);
         if ((tmpDT == null) || (tmpDTD == null)) {
            return null;
         }
         DateTimeInterval tmpDTI(DTI_START_DURATION, name, tmpDT, tmpDTD, reps);
         return tmpDTI;
      } else { // should be DTI_START_END
         DateTime tmpDT_l;
         tmpDT_l = DateTime.fromString(l);
         DateTime tmpDT_r;
         tmpDT_r = DateTime.fromString(r);
         if ((tmpDT_l == null) || (tmpDT_r == null)) {
            return null;
         }
         DateTimeInterval tmpDTI(DTI_START_END, name, tmpDT_l, tmpDT_r, reps);
         return tmpDTI;
      }

      return null;
   }


   private void refreshThisMinute ()
   {
      DateTime now;
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now;
      this.m_end = this.m_start.add(1, DT_MINUTE);
   }


   private void refreshThisHour ()
   {
      DateTime now;
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now;
      this.m_end = this.m_start.add(1, DT_HOUR);
   }


   private void refreshYesterday ()
   {
      DateTime now;
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now.add(-1, DT_DAY);
      this.m_end = this.m_start.add(1, DT_DAY);
   }


   private void refreshToday ()
   {
      DateTime now;
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now;
      this.m_end = this.m_start.add(1, DT_DAY);
   }


   private void refreshTomorrow ()
   {
      DateTime now;
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now.add(1, DT_DAY);
      this.m_end = this.m_start.add(1, DT_DAY);
   }


   private void refreshThisWeek ()
   {
      DateTime now;
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      int dayDiff = ((now.dayOfWeek() - this.m_weekStart)%7+7)%7;


      this.m_start = now.add(-dayDiff, DT_DAY);;
      this.m_end = this.m_start.add(7, DT_DAY);
   }


   private void refreshThisMonth ()
   {
      DateTime now;
      now = now.add(-now.day(), DT_DAY);
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now.add(1, DT_DAY);
      this.m_end = this.m_start.add(1, DT_MONTH);
      this.m_end = this.m_end.add(-1, DT_DAY);
   }


   private void refreshThisYear ()
   {
      DateTime now;
      now = now.add(-now.month(), DT_MONTH);
      now = now.add(1, DT_MONTH);
      now = now.add(-now.day(), DT_DAY);
      now = now.add(-now.hour(), DT_HOUR);
      now = now.add(-now.minute(), DT_MINUTE);
      now = now.add(-now.second(), DT_SECOND);
      now = now.add(-now.fractionalSecond(), DT_FRACTIONALSECOND);

      this.m_start = now.add(1, DT_DAY);
      this.m_end = now.add(1, DT_YEAR);
      this.m_end = this.m_end.add(1, DT_DAY);
   }


   /**
    * Author: nbeddes
    * Date:   7/28/2008
    *
    * 
    * 
    * @param rhs 
    * 
    * @return 
    */
   public bool filter (typeless& rhs)
   {
      if (!(rhs instanceof DateTime)) {
         return false;
      }

      switch (this.m_DTIType) {
      case DTI_START_END:
      case DTI_AUTO_THIS_MINUTE:
      case DTI_AUTO_THIS_HOUR:
      case DTI_AUTO_YESTERDAY:
      case DTI_AUTO_TODAY:
      case DTI_AUTO_TOMORROW:
      case DTI_AUTO_THIS_WEEK:
      case DTI_AUTO_THIS_MONTH:
      case DTI_AUTO_THIS_YEAR:
         if ((this.m_start.compare(rhs) <= 0) && (this.m_end.compare(rhs) >= 0)) {
            return true;
         }
         break;
      case DTI_START_DURATION:
         if ((this.m_repetitions == 0) &&
             (this.m_start.compare(rhs) < 0) && 
             (this.m_end.compare(rhs) >= 0)) {
            return true;
         }
         // All comparisons to repeating intervals return false for now. When
         // there's a need, we'll figure it out.
         break;
      case DTI_DURATION_END:
         if ((this.m_repetitions == 0) &&
             (this.m_start.compare(rhs) <= 0) && 
             (this.m_end.compare(rhs) > 0)) {
            return true;
         }
         // All comparisons to repeating intervals return false for now. When
         // there's a need, we'll figure it out.
         break;
      case DTI_DURATION:
         break;
      }

      return false;
   }


   /**
    * Author: nbeddes
    * Date:   9/29/2008
    *
    * 
    */
   public void update ()
   {
      switch (m_DTIType) {
      case DTI_START_END:
      case DTI_START_DURATION:
      case DTI_DURATION_END:
      case DTI_DURATION:
         break;
      case DTI_AUTO_THIS_MINUTE:
         refreshThisMinute();
         break;
      case DTI_AUTO_THIS_HOUR:
         refreshThisHour();
         break;
      case DTI_AUTO_YESTERDAY:
         refreshYesterday();
         break;
      case DTI_AUTO_TODAY:
         refreshToday();
         break;
      case DTI_AUTO_TOMORROW:
         refreshTomorrow();
         break;
      case DTI_AUTO_THIS_WEEK:
         refreshThisWeek();
         break;
      case DTI_AUTO_THIS_MONTH:
         refreshThisMonth();
         break;
      case DTI_AUTO_THIS_YEAR:
         refreshThisYear();
         break;
      default:
         break;
      }
   }


   /**
    * Author: nbeddes
    * Date:   9/10/2008
    *
    * 
    * 
    * @param stringType 
    * 
    * @return 
    */
   public void setStringFormat (DTIStringType stringType)
   {
      m_DTIStringType = stringType;
   }


   public void setDateTimeParts (DTParts DateTimeParts)
   {
      m_DTParts = DateTimeParts;
   }
};
