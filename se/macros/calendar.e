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
#pragma option(strict, on)
#region Imports
#include 'slick.sh'
#require 'se/datetime/DateTime.e'
#import 'alias.e'
#endregion



using namespace se.datetime;



static int months[] = {0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5};
static _str dayNames[] = {'Sunday', 'Monday', 'Tuesday', 'Wednesday',
                          'Thursday', 'Friday', 'Saturday'};
static _str dayLabels[] = {'Su', 'M', 'Tu', 'W', 'Th', 'F', 'Sa'};
static _str monthNames[] = {'January', 'February', 'March', 'April', 'May',
                            'June', 'July', 'August', 'September', 'October',
                            'November', 'December'};
static int monthNumbers:[];
int monthLengths[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};



static int backgroundColor =            0x008C8C8C; //Dark gray
static int dayLabelForeColor =          0x00FFFFFF; //White
static int otherMoBackgroundColor =     0x00B0B0B0; //Medium gray
static int otherMoForegroundColor =     0x80000008; //Black
static int currentMoBackgroundColor =   0x00DDDDDD; //Medium gray
static int currentMoForegroundColor =   0x00000000; //Black
static int weekendForegroundColor =     0x000000FF; //Red
static int currentDayForegroundColor =  0x00000000;
static int currentDayBackgroundColor =  0x00D0D080;
static int selectedDayForegroundColor = 0x00000000;
static int selectedDayBackgroundColor = 0x00000000;
static int selectedDayRingColor =       0x000000FF;
static int markedForegroundColor =      0x00000000;
static int markedBackgroundColor =      0x00ABDEBD;



/**
 * 
 * Show the calendar widget.
 * 
 * @author nbeddes (4/23/2008)
 * 
 * @param today       
 * @param startDay    0 = Sunday ... 6 = Saturday.
 * @param markedDays  Other days that are marked, besides the 
 *                    current day and the selected day.
 */
_command void calendar (DateTime& today=null, int startDay=0,
                        DateTime markedDays[]=null, DateTime* returnDate=null) name_info(',')
{
   _macro_delete_line();

   show('-modal _calendar_form', today, startDay, markedDays, returnDate);
}



defeventtab _calendar_form;
void _calendar_form.on_create (DateTime& today=null, int startDay=0,
                               DateTime markedDays[]=null, DateTime* returnDate=null)
{
   int i;

   if ((today == null) || !(today instanceof DateTime)) {
      DateTime tmpToday;
      today = tmpToday;
   }

   monthNumbers._makeempty();
   for (i = 0; i < monthNames._length(); ++i) {
      monthNumbers:[monthNames[i]] = i+1;
   }

   //_SetDialogInfoHt
   int specialDays:[]:[];
   _str indices:[];
   _str Tyyyy, Tmm, Tdd;
   _str index;
   for (i = 0; i < markedDays._length(); ++i) {
      parse markedDays[i].toStringLocal() with Tyyyy '-' Tmm '-' Tdd 'T' .;
      index = Tyyyy'-'Tmm;
      //specialDays:[index][specialDays:[index]._length()] = (int)Tdd;
      specialDays:[index]:[(int)Tdd] = (int)Tdd;
      indices:[index] = index;
   }
   foreach (auto o in indices) {
      _SetDialogInfoHt(o, specialDays:[o]);
   }

   yyyy := "";
   mm := "";
   dd := "";
   parse today.toStringLocal() with yyyy '-' mm '-' dd 'T' . ;
   _SetDialogInfoHt('today', yyyy'-'mm'-'dd);
   _SetDialogInfoHt('startDay', startDay);
   _SetDialogInfoHt('returnDate', returnDate);

   // strip leading zeros
   yyyy = strip(yyyy, "L", "0");
   mm = strip(mm, "L", "0");
   dd = strip(dd, "L", "0");

   _calendar.p_backcolor = backgroundColor;
   if (markedDays == null) {
      markedDays._makeempty();
   }

   //Set up the day labels.
   _nocheck _control _label_border0x0;
   int label = _label_border0x0;
   for (i = 0; i < 7; ++i) {
      label.p_backcolor = backgroundColor;
      label.p_child.p_caption = dayLabels[(startDay+i)%7];
      label.p_child.p_backcolor = backgroundColor;
      label.p_child.p_forecolor = dayLabelForeColor;
      label = label.p_next;
   }

   //Set up the months combo box.
   _month_combo_box._lbclear();
   for (i = 0; i < 12; ++i) {
      _month_combo_box._lbadd_item(monthNames[i]);
   }
   _month_combo_box.p_text = monthNames[(int)mm-1];

   //Set up the years combo box.
   _year_combo_box._lbclear();
   int year = (int)yyyy;
   for (i = -10; i < 11; ++i) {
      if (year + i > 0) {
         _year_combo_box._lbadd_item(year + i);
      }
   }
   _year_combo_box.p_text = yyyy;
   setupCalendar(yyyy, mm, dd);

   // initialize selected date to today
   _SetDialogInfoHt('selectedDate', today);
}



void _calendar_form.esc ()
{
   DateTime* returnDate = _GetDialogInfoHt('returnDate');
   if (returnDate) {
      *returnDate = null;
   }

   p_active_form._delete_window();
}



void _ok.lbutton_up ()
{
   DateTime selectedDate = _GetDialogInfoHt('selectedDate');
   DateTime* returnDate = _GetDialogInfoHt('returnDate');
   if (returnDate) {
      if (selectedDate != null) {
         *returnDate = selectedDate;
      } else {
         *returnDate = null;
      }
   }

   p_active_form._delete_window();
}



void _cancel.lbutton_up ()
{
   DateTime* returnDate = _GetDialogInfoHt('returnDate');
   if (returnDate) {
      *returnDate = null;
   }

   p_active_form._delete_window();
}



void _last_month.lbutton_up ()
{
   int month = monthNumbers:[_month_combo_box.p_text];
   int year = (int)_year_combo_box.p_text;

   if (month == 1) {
      month = 12;
      --year;
      _year_combo_box._lbclear();
      int i;
      for (i = -10; i < 11; ++i) {
         if (year + i > 0) {
            _year_combo_box._lbadd_item(year + i);
         }
      }
      _year_combo_box.p_text = year;
   } else {
      --month;
   }
   _month_combo_box.p_text = monthNames[month-1];

   setupCalendar(year, month, 1);
}



void _month_combo_box.on_change(int reason)
{
   setupCalendar(_year_combo_box.p_text, monthNumbers:[p_text], 1);
}



void _year_combo_box.on_change(int reason)
{
   setupCalendar(p_text, monthNumbers:[_month_combo_box.p_text], 1);
}


void _next_month.lbutton_up ()
{
   int month = monthNumbers:[_month_combo_box.p_text];
   int year = (int)_year_combo_box.p_text;

   if (month == 12) {
      month = 1;
      ++year;
      _year_combo_box._lbclear();
      int i;
      for (i = -10; i < 11; ++i) {
         if (year + i > 0) {
            _year_combo_box._lbadd_item(year + i);
         }
      }
      _year_combo_box.p_text = year;
   } else {
      ++month;
   }
   _month_combo_box.p_text = monthNames[month-1];

   setupCalendar(year, month, 1);
}



static void setupCalendar (_str yyyy='', _str mm='', _str dd='')
{
   int month;
   if ((yyyy == '') ||
       (mm == '')   ||
       (dd == '')) {
      parse _date() with mm '/' dd '/' yyyy;
   }

   _SetDialogInfoHt('selectedDay', null);
   DateTime nullDate = null;
   _SetDialogInfoHt('selectedDate', nullDate);
   //Set up for the start day of each week.
   int startDay = _GetDialogInfoHt('startDay');
   //Set up for the current day.
   currentDay := -1;
   _str today = _GetDialogInfoHt('today');
   _str Tyyyy;
   _str Tmm;
   _str Tdd;
   parse today with Tyyyy '-' Tmm '-' Tdd;
   if ((Tyyyy == yyyy) && (Tmm == mm)) {
      currentDay = (int)Tdd;
   }
   _today_label.p_caption = 'Date: 'Tyyyy'-'Tmm'-'Tdd;

   month = (int)mm;
   DateTime dOWDate((int)yyyy, month, 1);
   int dOW = dOWDate.dayOfWeek(); //finding the first day of the month
   if (dOW == -1) {
      _message_box("A bad date was passed to the calendar: "yyyy"/"mm"/"dd);
   }

   int prevNumDays;
   int numDays;
   numDays = monthLengths[month-1];
   if (month <= 1) {
      prevNumDays = monthLengths[11];
   } else {
      prevNumDays = monthLengths[month-2];
   }

   if (DateTime.isLeapYear((int)yyyy)) {
      if (prevNumDays == 28) {
         prevNumDays = 29;
      } else if (numDays == 28) {
         numDays = 29;
      }
   }

   //Setup the marked dates for this month.
   int currentMarked:[] = null;
   if (length(mm) < 2) {
      mm = '0'mm;
   }
   currentMarked = _GetDialogInfoHt(yyyy'-'mm);

   //Set up the first row.
   int i;
   i = ((dOW - startDay)%7+7)%7; //Slick-C's % can also return negative numbers
                                 //hence the extra +7)%7 to keep the results
                                 //positive.
   int dates[];
   int j = i - 1;
   k := 1;
   for (; i < 7; ++i) {
      dates[i] = k++;
   }
   for (; j >= 0; --j) {
      dates[j] = prevNumDays--;
   }
   //Populate the first row.
   _nocheck _control _border0x0;
   int day = _border0x0;
   for (i = 0; i < 7; ++i) {
      day.p_backcolor = backgroundColor;
      day.p_child.p_caption = dates[i];
      if (dates[i] > 7) {
         day.p_child.p_backcolor = otherMoBackgroundColor;
         day.p_child.p_forecolor = otherMoForegroundColor;
      } else if (dates[i] == currentDay) {
         day.p_child.p_backcolor = currentDayBackgroundColor;
         day.p_child.p_forecolor = currentDayForegroundColor;
      } else if (currentMarked._indexin(dates[i])) {
         day.p_child.p_backcolor = markedBackgroundColor;
         day.p_child.p_forecolor = markedForegroundColor;
      } else {
         day.p_child.p_backcolor = currentMoBackgroundColor;
         day.p_child.p_forecolor = currentMoForegroundColor;
      }
      day = day.p_next;
   }

   //Populate the middle three rows.
   k = dates[6];
   for (i = 0; i < 21; ++i) {
      day.p_backcolor = backgroundColor;
      day.p_child.p_caption = ++k;
      if (k == currentDay) {
         day.p_child.p_backcolor = currentDayBackgroundColor;
         day.p_child.p_forecolor = currentDayForegroundColor;
      } else if (currentMarked._indexin(k)) {
         day.p_child.p_backcolor = markedBackgroundColor;
         day.p_child.p_forecolor = markedForegroundColor;
      } else {
         day.p_child.p_backcolor = currentMoBackgroundColor;
         day.p_child.p_forecolor = currentMoForegroundColor;
      }
      day = day.p_next;
   }

   //Set up the fourth row
   dates._makeempty();
   ++k;
   i = 0;
   for (; k <= numDays; ++k) {
      dates[i++] = k;
   }
   j = 1;
   for (; i < 7; ++i) {
      dates[i] = j++;
   }
   //Populate the fourth row.
   for (i = 0; i < 7; ++i) {
      day.p_backcolor = backgroundColor;
      day.p_child.p_caption = dates[i];
      if (dates[i] < 8) {
         day.p_child.p_backcolor = otherMoBackgroundColor;
         day.p_child.p_forecolor = otherMoForegroundColor;
      } else if (dates[i] == currentDay) {
         day.p_child.p_backcolor = currentDayBackgroundColor;
         day.p_child.p_forecolor = currentDayForegroundColor;
      } else if (currentMarked._indexin(dates[i])) {
         day.p_child.p_backcolor = markedBackgroundColor;
         day.p_child.p_forecolor = markedForegroundColor;
      } else {
         day.p_child.p_backcolor = currentMoBackgroundColor;
         day.p_child.p_forecolor = currentMoForegroundColor;
      }
      day = day.p_next;
   }

   //Set up the fifth row
   k = dates[6];
   ++k;
   dates._makeempty();
   i = 0;
   for (; k <= numDays; ++k) {
      dates[i++] = k;
   }
   j = 1;
   for (; i < 7; ++i) {
      dates[i] = j++;
   }
   //Populate the fifth row.
   for (i = 0; i < 7; ++i) {
      day.p_backcolor = backgroundColor;
      day.p_child.p_caption = dates[i];
      if (dates[i] > 14) {
         if (dates[i] == currentDay) {
            day.p_child.p_backcolor = currentDayBackgroundColor;
            day.p_child.p_forecolor = currentDayForegroundColor;
         } else if (currentMarked._indexin(dates[i])) {
            day.p_child.p_backcolor = markedBackgroundColor;
            day.p_child.p_forecolor = markedForegroundColor;
         } else {
            day.p_child.p_backcolor = currentMoBackgroundColor;
            day.p_child.p_forecolor = currentMoForegroundColor;
         }
      } else {
         day.p_child.p_backcolor = otherMoBackgroundColor;
         day.p_child.p_forecolor = otherMoForegroundColor;
      }
      day = day.p_next;
   }
}



defeventtab _day_button;
void _day_button.lbutton_up ()
{
   lineStr := "";
   line := 0;
   parse p_name with '_day' lineStr 'x' .;
   line = (int)lineStr;

   newSelection := p_parent;
   int oldSelection = _GetDialogInfoHt('selectedDay');

   if (oldSelection != null) {
      oldSelection.p_backcolor = backgroundColor;
   }

   if (oldSelection == newSelection) {
      _SetDialogInfoHt('selectedDay', null);
      DateTime nullDate = null;
      _SetDialogInfoHt('selectedDate', nullDate);
   } else {
      _SetDialogInfoHt('selectedDay', newSelection);
      newSelection.p_backcolor = selectedDayRingColor;
      int y = (int)_year_combo_box.p_text;
      int m = (int)monthNumbers:[_month_combo_box.p_text];
      int d = (int)p_caption;
      if ((line == 0) && (d > 7)) {
         --m;
         if (m == 0) {
            m = 12;
            --y;
         }
      } else if ((line >=4) && (d < 15)) {
         ++m;
         if (m == 13) {
            m = 1;
            ++y;
         }
      }
      DateTime selectedDate(y, m, d);
      _SetDialogInfoHt('selectedDate', selectedDate);
   }
}
