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
#include "diff.sh"
#import "diff.e"
#import "files.e"
#endregion

bool gDiffCancel;
defeventtab _difftree_progress_form;

void _difftree_progress_form.on_got_focus()
{
   p_active_form.refresh('W');
}

void ctlcancel.on_create()
{
   gDiffCancel=false;
}

void ctlcancel.lbutton_up()
{
   gDiffCancel=true;
   //p_active_form._delete_window();
}

void _DiffSetProgressMessage(_str Prefix='',_str Filename1='',_str Filename2='')
{
   //5:52pm 6/15/1998
   //this is pretty special case stuff here
   //set label captions differently for "compares" and "build file lists"
   if (pos('Comparing',Prefix,1,'i')) {
      int FilenameWidth=label1.p_width-(label1._text_width(Prefix' '));
      label1.p_caption=Prefix' 'label1._ShrinkFilename(Filename1,FilenameWidth);
      label2.p_caption="and";
      label3.p_caption=label3._ShrinkFilename(Filename2,label2.p_width);
   }else if (pos('Building',Prefix,1,'i')) {
      label1.p_caption=Prefix;
      label2.p_caption=label2._ShrinkFilename(Filename1,label2.p_width);
      label3.p_caption=Filename2;
   }else{
      label1.p_caption=Prefix;
      label2.p_caption=Filename1;
      label3.p_caption=Filename2;
   }
   p_active_form.refresh('W');
}

void _DiffHideProgressGauge()
{
   gauge1.p_visible=false;
   ctlcancel.p_y-=gauge1.p_height;
   p_active_form.p_height-=gauge1.p_height;
   refresh();
}

void _DiffShowProgressGauge()
{
   gauge1.p_visible=true;
   ctlcancel.p_y+=gauge1.p_height;
   p_active_form.p_height+=gauge1.p_height;
   refresh();
}

/**
 * Show the generic progress form.
 *
 * @param caption    Dialog caption
 *
 * @return window ID of
 */
CTL_FORM progress_show(_str caption, int max)
{
   // show progress form
   CTL_FORM gauge_form_wid=show('-mdi _diff_progress_form');
   gauge_form_wid.p_caption=caption;
   gauge_form_wid.refresh();
   gauge_form_wid.p_child.p_min=0;
   gauge_form_wid.p_child.p_max=max;
   gauge_form_wid.p_value=0;
   gDiffCancel=false;
   return(gauge_form_wid);
}
/**
 * Return the wid of the gauge control. 
 *  
 * @param form_wid Window ID of form
 */
CTL_GAUGE progress_gauge(CTL_FORM form_wid)
{
   gauge_wid := form_wid._find_control("gauge1");
   return gauge_wid;
}

/**
 * Sets the gauge visible or invisible, and sizes dialog 
 * appropriately 
 * 
 * @param form_wid Window ID of form
 * @param showGauge 
 */
void progress_show_gauge(CTL_FORM form_wid,bool showGauge)
{
   if ( showGauge ) {
      form_wid._DiffShowProgressGauge();
   }else{
      form_wid._DiffHideProgressGauge();
   }
}

/**
 *  
 * Set the p_min and p_max properties of the progress gauge
 * 
 * @param form_wid Window ID of form
 * @param min value to set p_min
 * @param max value to set p_max
 */
void progress_set_min_max(CTL_FORM form_wid,int min,int max)
{
   if (form_wid) {
      gauge_wid := progress_gauge(form_wid);
      if ( gauge_wid ) {
         gauge_wid.p_min=min;
         gauge_wid.p_max=max;
         gauge_wid.p_value=min;
         gauge_wid.refresh();
      }
   }
}


/**
 *  
 * Set the value of the progress gauge to  <b>newval</b>
 * 
 * @param form_wid Window ID of form
 * @param newval value to set gauge to
 */
void progress_set(CTL_FORM form_wid,int newval)
{
   if (form_wid) {
      gauge_wid := progress_gauge(form_wid);
      if ( gauge_wid ) {
         gauge_wid.p_value=newval;
         gauge_wid.refresh();
      }
   }
}

/**
 *  
 * Returns the current value of the progress gauge. 
 * @return -1 if the gauge is not found.
 */
int progress_get(CTL_FORM form_wid)
{
   if (form_wid) {
      gauge_wid := progress_gauge(form_wid);
      if ( gauge_wid ) {
         return gauge_wid.p_value;
      }
   }

   return -1;
}

/**
 * Increment the progress counter
 */
void progress_increment(CTL_FORM form_wid)
{
   if (form_wid) {
      gauge_wid := form_wid._find_control("gauge1");
      if ( gauge_wid ) {
         gauge_wid.p_value++;
         gauge_wid.refresh();
      }
   }
}
/**
 * Was the cancel button hit on the progress dialog?
 * <p>
 * TBF, this doesn't work, there is no "Cancel" button.
 */
bool progress_cancelled()
{
   return gDiffCancel;
}
/**
 * Close and destroy the progress form.
 */
void progress_close(CTL_FORM form_wid)
{
   if (form_wid) {
      form_wid._delete_window();
   }
}
