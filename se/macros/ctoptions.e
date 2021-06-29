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
#include "codetemplate.sh"
#import "codetemplate.e"
#import "ctviews.e"
#import "picture.e"
#endregion


_command void template_options() name_info(","VSARG2_READ_ONLY)
{
   show("-mdi _ctTemplateOptions_form");
}

defeventtab _ctTemplateOptions_form;

void ctl_ok.on_create()
{
   // make the form pretty
   _ctTemplateOptions_form_initial_alignment();

   _control ctl_params_view;
   // Parameters view inside a frame does not have its on_create() event
   // called automatically, which set its InOnChange variable to false,
   // so we must do it here.
   ctl_params_view.call_event(ctl_params_view,ON_CREATE,'w');
   _str filename = _ctOptionsGetOptionsFilename();
   ctOptions_t options;
   int status = _ctOptionsGetOptions(filename,options);
   if( status!=0 ) {
      _str msg = "Error opening options filename. "get_message(status):+"\n\n":+
                 filename;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   // The parameters view only understands template content, so oblige it
   ctTemplateContent_t content; content._makeempty();
   content.Parameters=options.Parameters;
   ctl_params_view._ctParametersViewInit("",null,content,true);
}

void ctl_ok.lbutton_up()
{
   _control ctl_params_view;
   if( !ctl_params_view._ctParametersViewVerifyInput() ) {
      // Error
      return;
   }
   // The parameters view stores its results in a ctTemplateContent_t object
   // on the active form. We are only interested in the parameters.
   ctTemplateContent_t content = _ctViewContent();
   ctOptions_t options; options._makeempty();
   options.Parameters=content.Parameters;
   _str filename = _ctOptionsGetOptionsFilename();
   int status = _ctOptionsPutOptions(filename,options);
   if( status!=0 ) {
      _str msg = "Error saving options file. "get_message(status):+"\n\n":+
                 filename;
      _message_box(msg,"",MB_OK|MB_ICONEXCLAMATION);
      return;
   }
   //ctTemplateContent_ParameterValue_t Parameters:[] = content.Parameters;
   //typeless Name;
   //for( Name._makeempty();; ) {
   //   Parameters._nextel(Name);
   //   if( Name._isempty() ) {
   //      break;
   //   }
   //   say('ctl_ok.lbutton_up: Name='Name'  Value='Parameters:[Name].Value);
   //}
   p_active_form._delete_window(status);
}

void ctl_cancel.lbutton_up()
{
   p_active_form._delete_window("");
}

/**
 * Does any necessary adjustment of auto-sized controls.
 */
static void _ctTemplateOptions_form_initial_alignment()
{
   ctl_param_edit.p_auto_size = false;
   ctl_param_edit.p_width = ctl_param_add.p_width;
   ctl_param_edit.p_height = ctl_param_add.p_height;

   // parameter tree buttons
   alignUpDownListButtons(ctl_params.p_window_id, 
                          0, 
                          ctl_param_add.p_window_id, 
                          ctl_param_edit.p_window_id, 
                          ctl_param_remove.p_window_id);
}
