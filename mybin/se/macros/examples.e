////////////////////////////////////////////////////////////////////////////////////
// $Revision: 47103 $
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
#import "listbox.e"
#import "markfilt.e"
#import "stdprocs.e"
#endregion

/*
 * Various Slick-C macro examples.
 */

/////////////////////////////////////////////////////////////////////
// Event table code to run a form called example_form1, and a
// command that shows the form.
//
// To create the form go to "Macro", "New Form" and set the "name"
// property on the form to "example_form1". Create a list box control
// whose name is "ctl_list1", create a text box control whose name is
// "ctl_choice", create an "OK" button whose name is "ctl_ok", create
// a "Cancel" button whose name is "ctl_cancel".
//
// If you need to generate the source for the form (to distribute it to
// colleagues for example), then run "insert-object <form name>" from
// the SlickEdit command line.

// Event table for example_form1
defeventtab example_form1;

// on-create event for the form.
// Use this event for any form initialization. Typically, the
// on-create event is attached to a common control like an
// "OK" button.
void ctl_ok.on_create()
{
   // Set the title bar caption for the form
   p_active_form.p_caption="Example Form 1";

   // Insert items into list box control ctl_list1
   ctl_list1._lbadd_item("item 1");
   ctl_list1._lbadd_item("item 2");
   ctl_list1._lbadd_item("item 3");
   ctl_list1._lbadd_item("item 4");
   ctl_list1._lbtop();
   ctl_list1._lbselect_line();
   // Call the on_change() event so that the ctl_choice text box is set
   ctl_list1.call_event(CHANGE_SELECTED,ctl_list1,ON_CHANGE,'W');

   return;
}

// on-change event for the list box ctl_list1.
// The on-change event is called with a reason. See help for "on_change"
// for more information.
void ctl_list1.on_change(int reason)
{
   if( reason==CHANGE_SELECTED ) {
      // Get the currently selected item in the list and put it
      // into the ctl_choice text box control.
      _str item=_lbget_seltext();
      ctl_choice.p_text=item;
   }

   return;
}

// lbutton-up event for the "OK" button ctl_ok.
void ctl_ok.lbutton_up()
{
   // Return the item in the ctl_choice text box to
   // the caller and destroy the form.
   _str item=ctl_choice.p_text;
   // If the form was shown modeless (no '-modal' option)
   // then set the global variable _param1 to the item.
   _param1=item;
   // If the form was shown with a '-modal' option, then
   // return the item in the call _delete_window().
   p_active_form._delete_window(item);

   return;
}

// lbutton-up event for the "Cancel" button ctl_cancel.
void ctl_cancel.lbutton_up()
{
   // Destroy the form and pass back '' to indicate cancelled.
   p_active_form._delete_window('');
}

// A Slick-C command that shows the example_form1 form modally,
// then displays a message box with the result of the form.
// Run this command from the SlickEdit command line.
_command void example1()
{
   typeless result=show("-modal example_form1");
   if( result=="" ) {
      _str msg="Command cancelled";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
   } else {
      _str msg="Result = ":+result;
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
   }

   return;
}

/////////////////////////////////////////////////////////////////////
// Example of using the filter_* functions to get selected text
// into a macro variable.
//
// Explanation of VSARG2_* constants are in "slick.sh", or just press
// Alt+Period while your cursor is on one of the constants, for an
// explanation of each. These constants tell SlickEdit where
// this command is allowed to operate.
//
// Note: The VSARG2_MARK constant is crucial to this command working
// properly.
_command void example2() name_info(','VSARG2_MARK|VSARG2_READ_ONLY|VSARG2_REQUIRES_EDITORCTL)
{
   _str msg='';
   if( !select_active() ) {
      msg="No active selection";
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }

   // Initialize filtering. This will put us at the beginning of the
   // selection and save the position so we can call filter_restore_pos()
   // at the end.
   filter_init();

   // Get the selected portion of the first selected line and store in
   // the 'text' variable.
   _str text='';
   typeless status=filter_get_string(text);
   // If you were processing a multi-line selection, then you would
   // call filter_get_string() to get the next line, checking status
   // as you go to know when you have reached the end of the selection.

   // Restore the original position of the cursor
   filter_restore_pos();

   msg="Selection = ":+text;
   _message_box(msg,"",MB_OK|MB_ICONINFORMATION);

   return;
}

/////////////////////////////////////////////////////////////////////
// Using _sellist_form form to present user with a selection list
// to choose from.
//
// The form is shown modally so that we may return the user selected
// item from the list.
//
// There are many more options that can be used with _sellist_form.
// See the help on "_sellist_form" for more information.
_command void example3()
{
   _str items[];

   // Initialize an array of strings to pass to _sellist_form for
   // selection.
   int i;
   for( i=0;i<5;++i ) {
      items[i]="Item ":+i;
   }
   typeless result=show("-modal _sellist_form","Title",0,items);
   _str msg="You selected \"":+result:+"\"";
   _message_box(msg,"",MB_OK|MB_ICONINFORMATION);

   return;
}

/////////////////////////////////////////////////////////////////////
// Using _textbox_form form to query user for values.
//
// The form is shown modally so that we may return a status. Results
// are stored in _param1 ... _param10 global variables.
//
// There are many more options that can be used with _textbox_form.
// See the help on "_textbox_form" for more information.
_command void example4()
{
   _str items[];

   // Initialize an array of strings to pass to _sellist_form for
   // selection.
   int i;
   for( i=0;i<5;++i ) {
      items[i]="Item ":+i;
   }
   _str helpmsg="?Help to be displayed in a message box goes here";
   typeless status=show("-modal _textbox_form","Title",0,"",helpmsg,"","",
               "Prompt 1:initial value 1",
               "Prompt 2:initial value 2",
               "Prompt 3:initial value 3");
   if( status==1 ) {
      _str msg="You selected:\n\n":+
          "Prompt 1 = ":+_param1:+"\n":+
          "Prompt 2 = ":+_param2:+"\n":+
          "Prompt 3 = ":+_param3:+"\n";
      _message_box(msg,"",MB_OK|MB_ICONINFORMATION);
   }

   return;
}

/////////////////////////////////////////////////////////////////////
// Demonstrates:
// 1) Using FILE_ARG to support completion of 1 or more filenames
//    on the command line.
// 2) Decomposing a filename into its parts.
//
// Note the use of preprocessing to exclude the drive part of the
// filename for UNIX platforms.
//
// Type the name of the command on the SlickEdit command
// line. Then use SPACE and '?' to automatically complete a
// filename.
_command void example5(_str list='') name_info(FILE_ARG'*')
{
   // An array of structs to hold the decomposed filenames
   struct {
#if !__UNIX__
      _str drive;
#endif
      _str path;
      _str name;
      _str ext;
   } decomp[];

   // Arguments are retrieved with the arg() function.
   // All arguments to a Slick-C command are passed in arg(1).
   if( list=="" ) {
      // Display a message on the SlickEdit message line
      // about command usage.
      //
      // Use last_index() to retrieve the index of the very last
      // command executed. Use name_name() to get the name
      // associated with the index.
      _str this_command=name_name(last_index("",'C'));
      _str msg="Usage: ":+this_command" filename [filename[filename ...]]";
      message(msg);
      return;
   }

   int i=0;
   _str filename='';
   while( list!="" ) {
      filename=parse_file(list);
      // Use the absolute() function to change a relative path into
      // an absolute path.
      filename=absolute(filename);
      i=decomp._length();
#if !__UNIX__
      decomp[i].drive="";
      if( substr(filename,2,1)==':' ) {
         decomp[i].drive=substr(filename,1,2);
      }
#endif
      decomp[i].path=_strip_filename(filename,'ND');
      decomp[i].name=_strip_filename(filename,'PE');
      decomp[i].ext=_get_extension(filename);
   }

   // Display list of decomposed filenames
   _str drive='', path='', name='', ext='';
   _str msg="Decomposed files:\n\n";
   for( i=0;i<decomp._length();++i ) {
#if __UNIX__
      drive='';
#else
      drive=decomp[i].drive;
#endif
      path=decomp[i].path;
      name=decomp[i].name;
      ext=decomp[i].ext;
      // Note when we are not using the :+ operator to concatenate
      // because concatenation is automatic between quoted strings
      // and variables.
      msg=msg"filename="drive:+path:+name"."ext"\n":+
          "\tdrive="drive"\tpath="path"\tname="name"\text="ext"\n\n";
   }
   _message_box(msg,"",MB_OK|MB_ICONINFORMATION);

   return;
}

defmain()
{
   _str msg="Do not load this module. It contains example macros and is only for ":+
       "illustration.";
   _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
}

