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
#import "complete.e"
#import "stdprocs.e"
#endregion

defeventtab _wizard_form;

static const SLIDE_WIDTH=  6360;
static const SLIDE_HEIGHT= 3390;

static const DIALOG_WIDTH=  6480;
static const DIALOG_HEIGHT= 4395;

static _str CUR_SLIDE_NAME(...) {
   if (arg()) ctlnext.p_user=arg(1);
   return ctlnext.p_user;
}
static WIZARD_INFO *gpWizardInfo(...) {
   if (arg()) ctlback.p_user=arg(1);
   return ctlback.p_user;
}

static const NEXT_BUTTON_CAPTION=   "&Next >";
/*

   General purpose wizard stuff:

   This is very simplified right now, but everything is here to run the dialog
   if you write the callbacks.  I hope we will do more with it in the future.
   Maybe we'll have a wizard generating wizard<g>.

   Here is how you do it:

   1. Create a dialog with all of the "slides" for your wizard in picture
   controls.  For clarity, you can turn the border on for each picture control,
   it will be turned off when it is put on the dialog.  The first slide should
   be named "ctlslide0", the next "ctlslide1" etc.  Every control on a slide
   should probably have some sort of prefix like "ctls1_" so that there are no
   conflicts if you want to have more than one text box with a similar name on
   a dialog.  The size of the dialog will be scaled to the height and width
   of the largest slide.  The minimum size for a slide is
   SLIDE_WIDTH x SLIDE_HEIGHT.

   2. Create a source file your wizard code.

   3. Declare a variable of type "WIZARD_INFO".  For our example, lets use
   "wizardInfo".

   4. Set wizardInfo.parentFormName to the name of your form that has the
   slides.

   5. Now it gets more complicated.  wizardInfo.callbackTable is just what it
   sounds like.  Every time that the "Next" button is clicked, we look in
   wizardInfo.callbackTable for an entry called "ctlslideX.next"(X is the slide
   number).  If you want to catch the next event for a button(you usually will),
   create a function to do whatever you want, and in your callbacktable set
   "ctlslideX.next" to a pointer to that function.  If you want the user to be
   able to continue, your function should return 0.  Otherwise, it should show
   an error message and return non-zero.

   6. For each slide, your callbacktable can have four entries:

         "ctlslideX.next"        - called everytime the next button is clicked
         "ctlslideX.back"        - called everytime the back button is clicked*
         "ctlslideX.shownback"   - called everytime the slide is shown (via the back button)
         "ctlslideX.shown"       - called everytime the slide is shown (via the next button)
         "ctlslideX.aftershown"  - called everytime, after the slide is shown
         "ctlslideX.create"      - called only the first time the slide is shown

   *There cannot be a "ctlslide0.back".

   Also there can be one "finish" event .
   
   "ctlslideX.next" will be called for your last slide as you may need to
   display an error before finishing the wizard.  After ".next" for your last
   slide returns 0, "finish" will be called.  That is not "ctlslideX.finish",
   just "finish." It is a good idea to only to data gathering on the
   "ctlslideX.next", and do code generation on the "finish" so that if you add
   slides you won't have to change your code as much.

   7. If you define a "ctlslideX.skip" and set it to 1 in your callbacktable,
   this will cause this slide to be skipped until you set it back to null.

   8. If you define a "ctlslideX.canceloff" and set it to 1 in your callbacktable,
   this will cause the cancel button to be disabled on this slide until you set it 
   back to null.
*/

_str gCreateEventsCalled:[]; //This table has names of the on create events
                             //that we have called so that we do not call
                             //a user clicks "Back"

/**
 * Runs a wizard.
 *
 * @param callbackTable
 *                 Callback table with functions for each slide
 *
 * @param FormName Name of of form with slides.  Each must be in
 *                 a frame named 'ctlslide&lt;num&gt;' eg. ctlslide0,
 *                 ctlslide1 ...
 *
 * @return returns 0 if wizard completes.
 */
int _Wizard(WIZARD_INFO *pWizardInfo)
{
   gCreateEventsCalled._makeempty();
   int wid=show('-hidden _wizard_form',pWizardInfo);
   int index=find_index(pWizardInfo->parentFormName,oi2type(OI_FORM));
   if (!index) {
      return(1);
   }
   int firstchild=index.p_child;
   int child=firstchild;
   if (child) {
      for (;;) {
         if (child.p_object!=OI_IMAGE) {
            //form_wid=_load_template(index, _mdi, 'HA', 1);
            // Center the form to the MDI window while the form is invisible
            int form_wid=_load_template(child,wid,'H');
            form_wid._center_window();
            form_wid.p_y+=60;
         }
         child=child.p_next;
         if (child==firstchild) break;
      }
   }
   wid.arrangeDialog(pWizardInfo);
   // Delay the centering of the _wizard_form till the form has
   // been resized to fit the largest wizard panel. 
   wid._center_window(_mdi);
   wid.p_visible=true;
   wid._WizardMaybeEnableButtons();
   _str status=_modal_wait(wid);
   if(status=='') {
      return COMMAND_CANCELLED_RC;
   }

   return((int)status);
}

WIZARD_INFO *_WizardGetPointerToInfo()
{
   return(gpWizardInfo());
}

void _WizardMaybeEnableButtons()
{
   _str curSlideName=CUR_SLIDE_NAME();
   typeless curNum='';
   parse curSlideName with 'ctlslide' curNum;
   if (!isinteger(curNum)) return;

   // check next
   int tempNum = curNum;
   tempNum++;
   nextSlideName := 'ctlslide'tempNum;
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;
   while (pWizardInfo->callbackTable:[nextSlideName'.skip']==1) {
      ++tempNum;
      nextSlideName='ctlslide'tempNum;
   }

   nextWid := _find_control(nextSlideName);
   if (nextWid) {
      TurnOnNext();
   }else{
      TurnOffNext();
   }

   // finish
   MaybeTurnOnFinish(nextSlideName);

   // check back
   tempNum = curNum;
   --tempNum;
   for (;tempNum>=0;) {
      nextSlideName='ctlslide'tempNum;
      if (pWizardInfo->callbackTable:[nextSlideName'.skip']!=1) {
         break;
      }
      --tempNum;
   }
   if (tempNum<0) {
      ctlback.p_enabled=false;
   } else {
      ctlback.p_enabled=true;
   }

   // cancel
   MaybeTurnOffCancel();
}

void _WizardRenameNextButton(_str nextText)
{
   ctlnext.p_caption = nextText;
}

static void arrangeDialog(WIZARD_INFO *pWizardInfo)
{
   gpWizardInfo(pWizardInfo);
   if (pWizardInfo->dialogCaption._varformat()==VF_LSTR) {
      p_active_form.p_caption=pWizardInfo->dialogCaption;
   }
   _nocheck _control ctlslide0;
   ctlslide0.p_border_style=BDS_NONE;
   ctlslide0.p_x=ctlslide0.p_y=0;
   //ctlslide0.p_width=SLIDE_WIDTH;ctlslide0.p_height=SLIDE_HEIGHT;
   ctlslide0.p_visible=true;
   int large_slide_width=SLIDE_WIDTH,large_slide_height=SLIDE_HEIGHT;
   i := wid := 0;;

   // find largest slide - resize dialog and move buttons accordingly
   for (i=1;;++i) {
      otherFrameName := 'ctlslide'i;
      wid=p_active_form._find_control(otherFrameName);
      if (!wid) break;
      wid.p_visible=false;
      wid.p_border_style=BDS_NONE;


      // Scale the dialog to the current slide's height/width
      if (wid.p_width>large_slide_width) {
         int diff=(wid.p_width-large_slide_width);
         p_active_form.p_width+=diff;
         ctlback.p_prev.p_width+=diff;
         large_slide_width=wid.p_width;

         // Move buttons to right
         ctlback.p_x+=diff;
         ctlnext.p_x+=diff;
         ctlfinish.p_x+=diff;
         ctlfinish.p_next.p_x+=diff;
      }
      if (wid.p_height>large_slide_height) {
         int diff=(wid.p_height-large_slide_height);
         p_active_form.p_height+=diff;
         large_slide_height=wid.p_height;

         // Move buttons to down
         ctlback.p_prev.p_y+=diff;
         ctlback.p_y+=diff;
         ctlnext.p_y+=diff;
         ctlfinish.p_y+=diff;
         ctlfinish.p_next.p_y+=diff;
      }
   }
   // p_active_form.p_width=DIALOG_WIDTH;p_active_form.p_height=DIALOG_HEIGHT;
   CUR_SLIDE_NAME('ctlslide0');
   typeless callbackTable=pWizardInfo->callbackTable;

   if (callbackTable._indexin(CUR_SLIDE_NAME()'.create')) {
      int status=(*callbackTable:[CUR_SLIDE_NAME()'.create'])();
      gCreateEventsCalled:[CUR_SLIDE_NAME()'.create']='';
      if (status) return;
   }

   if (callbackTable._indexin(CUR_SLIDE_NAME()'.shown')) {
      int status=(*callbackTable:[CUR_SLIDE_NAME()'.shown'])();
      if (status) return;
   }

   firstWid := _find_control(CUR_SLIDE_NAME());
   if (firstWid.p_child) {
      firstWid.SetFocusToRealChild();
   }

   _str curSlideName=CUR_SLIDE_NAME();
   typeless curNum='';
   parse curSlideName with 'ctlslide' curNum;
   if (!isinteger(curNum)) return;
   int tempNum = curNum;
   tempNum++;
   nextSlideName := 'ctlslide'tempNum;
   //WIZARD_INFO *pWizardInfo=gpWizardInfo;
   //typeless callbackTable=pWizardInfo->callbackTable;
   while (pWizardInfo->callbackTable:[nextSlideName'.skip']==1) {
      ++tempNum;
      nextSlideName='ctlslide'tempNum;
   }

   nextWid := _find_control(nextSlideName);
   if (nextWid) {
      TurnOnNext();
   }else{
      TurnOffNext();
   }

   // Figure out what the first slide w/o a skip setup is
   slide_name := "ctlslide";
   for (i=0;;++i) {
      if (callbackTable:[slide_name:+i'.skip']!=1) {
         break;
      }
   }
   int first_slide=i;

   // If the first slide is a skip, we can call next to update the 
   // state to the first unskipped slide.
   if (first_slide > 0) {
      ctlnext.call_event(ctlnext,LBUTTON_UP);
   }
}

/**
 * Turns on the "Finish" button and turns off the
 * "Next >" button
 */
static void TurnOnFinish()
{
   //ctlnext.p_enabled=false;
   //ctlnext.p_default=0;
   ctlfinish.p_enabled=true;
   ctlfinish.p_default=true;
}

static void TurnOffFinish()
{
   ctlfinish.p_enabled=false;
   ctlfinish.p_default=false;
}

/**
 * Turns on the "Next >" button and turns off the
 * "Finish" button
 */
static void TurnOnNext()
{
   ctlnext.p_enabled=true;
   ctlnext.p_default=true;
   //ctlfinish.p_enabled=false;
   //ctlfinish.p_default=false;
}

static void TurnOffNext()
{
   if (ctlnext.p_caption != "Register") {
      // When we have changed 'Next' to 'Register' for the final 
      // slide we do not want to disable this button
      ctlnext.p_enabled=false;
   }
   ctlnext.p_default=false;
}

static void ResetNextButtonCaption()
{
   ctlnext.p_caption = NEXT_BUTTON_CAPTION;
}

static void TurnOnCancel()
{
   ctlcancel.p_enabled=true;
}

static void TurnOffCancel()
{
   ctlcancel.p_enabled=false;
}

void ctlnext.lbutton_up()
{
   // disable button while we are doing stuff
   ctlnext.p_enabled = false;

   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;
   _str curSlideName=CUR_SLIDE_NAME();
   if (callbackTable._indexin(curSlideName'.next')) {
      int status=(*callbackTable:[curSlideName'.next'])();
      if (status) {
         ctlnext.p_enabled = true;
         return;
      }
   }
   ctlnext.p_enabled = true;
   curWid := _find_control(curSlideName);
   typeless curNum='';
   parse curSlideName with 'ctlslide' curNum;
   if (!isinteger(curNum)) return;

   ++curNum;
   nextSlideName := 'ctlslide'curNum;
   while (pWizardInfo->callbackTable:[nextSlideName'.skip']==1) {
      ++curNum;
      nextSlideName='ctlslide'curNum;
   }
   nextWid := _find_control(nextSlideName);
   if (nextWid) {

      ResetNextButtonCaption();

      if (!gCreateEventsCalled._indexin(nextSlideName'.create')) {
         if (callbackTable._indexin(nextSlideName'.create')) {
            int status=(*callbackTable:[nextSlideName'.create'])();
            if (status) return;
         }
         gCreateEventsCalled:[nextSlideName'.create']='';
      }
      if (callbackTable._indexin(nextSlideName'.shown')) {
         int status=(*callbackTable:[nextSlideName'.shown'])();
         if (status) return;
      }
      if (nextWid.p_child) {
         nextWid.SetFocusToRealChild();
      }
      nextWid.p_x=0;
      nextWid.p_y=0;
      curWid.p_visible=false;
      nextWid.p_visible=true;
      CUR_SLIDE_NAME(nextSlideName);

      for (;;) {
         ++curNum;
         nextSlideName='ctlslide'curNum;
         nextWid=_find_control(nextSlideName);
         if (!nextWid) break;
         if (pWizardInfo->callbackTable:[nextSlideName'.skip']!=1) break;
      }

      MaybeTurnOnFinish(nextSlideName);
      if (nextWid) {
         TurnOnNext();
      }else{
         TurnOffNext();
      }
   }
   //ctlback.p_enabled=true;
   MaybeTurnOnBack();
   MaybeTurnOffCancel();

   if (callbackTable._indexin(CUR_SLIDE_NAME()'.aftershown')) {
      int status=(*callbackTable:[CUR_SLIDE_NAME()'.aftershown'])();
      if (status) return;
   }
   ArgumentCompletionTerminate();
}

void ctlfinish.lbutton_up()
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;

   _str curSlideName=CUR_SLIDE_NAME();
   if (callbackTable._indexin(curSlideName'.next')) {
      int status=(*callbackTable:[curSlideName'.next'])();
      if (status) return;
   }

   if (callbackTable._indexin('finish')) {
      int status=(*callbackTable:['finish'])();
      if (status) return;
   }
   ArgumentCompletionTerminate();
   p_active_form._delete_window(0);
   return;
}

//Try to set focus to the first "real" thing on the dialog
static void SetFocusToRealChild()
{
   int childWid=p_child;
   int firstChildWid=childWid;
   for (;;) {
      if (childWid.p_object!=OI_LABEL && childWid.p_object!=OI_RADIO_BUTTON) {
         childWid._set_focus();
         break;
      }
      childWid=childWid.p_next;
      if (childWid==firstChildWid) break;
   }
}

void ctlback.lbutton_up()
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;
   _str curSlideName=CUR_SLIDE_NAME();
   if (callbackTable._indexin(curSlideName'.back')) {
      int status=(*callbackTable:[curSlideName'.back'])();
      if (status) return;
   }
   curWid := _find_control(curSlideName);
   typeless curNum='';
   parse curSlideName with 'ctlslide' curNum;
   if (!isinteger(curNum)) return;
   --curNum;
   nextSlideName := 'ctlslide'curNum;
   for (;curNum>=0;) {
      nextSlideName='ctlslide'curNum;
      if (pWizardInfo->callbackTable:[nextSlideName'.skip']!=1) {
         break;
      }
      --curNum;
   }
// if (!curNum) {
//    ctlback.p_enabled=false;
// }
   nextWid := _find_control(nextSlideName);
   if (nextWid) {

      ResetNextButtonCaption();

      if (callbackTable._indexin(nextSlideName'.shownback')) {
         int status=(*callbackTable:[nextSlideName'.shownback'])();
         if (status) return;
      }
      nextWid.p_x=0;
      nextWid.p_y=0;
      CUR_SLIDE_NAME(nextSlideName);
      curWid.p_visible=false;
      nextWid.p_visible=true;
      if (nextWid.p_child) {
         nextWid.SetFocusToRealChild();
      }
      ++curNum;
      nextWid=_find_control('ctlslide'curNum);

      TurnOnNext();
   }
   MaybeTurnOnBack();
   MaybeTurnOnFinish(nextSlideName);
   MaybeTurnOffCancel();
   ArgumentCompletionTerminate();
}

void _wizard_form.on_destroy()
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;
   typeless *pfnDestroy=callbackTable:['destroy'];
   if (pfnDestroy!=null) {
      (*pfnDestroy)();
   }
}

/**
 * Finish can be turned on two ways - if CUR_SLIDE_NAME.finishon 
 * == 1 in the callbacktable, or if there is no next slide AND 
 * CUR_SLIDE_NAME.finishon == null in the callbacktable. 
 *  
 * To allow the finish button in no circumstances, set 
 * CUR_SLIDE_NAME.finishon to 0. 
 * 
 * @param _str nextSlideName 
 * 
 */
static void MaybeTurnOnFinish(_str nextSlideName)
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   if (pWizardInfo->callbackTable:[CUR_SLIDE_NAME()'.finishon']==1) {
      TurnOnFinish();
   }else if (!_find_control(nextSlideName) && pWizardInfo->callbackTable:[CUR_SLIDE_NAME()'.finishon']!=0) {
      TurnOnFinish();
   }else{
      TurnOffFinish();
   }
}

static void MaybeTurnOffCancel()
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   if (pWizardInfo->callbackTable:[CUR_SLIDE_NAME()'.canceloff']==1) {
      TurnOffCancel();
   } else {
      TurnOnCancel();
   }
}

static void MaybeTurnOnBack()
{
   WIZARD_INFO *pWizardInfo=gpWizardInfo();
   typeless callbackTable=pWizardInfo->callbackTable;
   _str curSlideName=CUR_SLIDE_NAME();

   typeless curNum='';
   parse curSlideName with 'ctlslide' curNum;
   if (!isinteger(curNum)) return;

   --curNum;
   for (;curNum>=0;) {
      nextSlideName := 'ctlslide'curNum;
      if (pWizardInfo->callbackTable:[nextSlideName'.skip']!=1) {
         break;
      }
      --curNum;
   }
   if (curNum<0) {
      ctlback.p_enabled=false;
   } else {
      ctlback.p_enabled=true;
   }
}
