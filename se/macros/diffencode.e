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
#include "minihtml.sh"
#import "listbox.e"
#import "main.e"
#import "setupext.e"
#endregion

defeventtab _diff_encoding_form;

ctlok.on_create(_str filename1, _str filename2,
                _str encoding1, _str encoding2,
                bool modify1, bool modify2)
{
   //This seems really funny, but there is a reason for it.
   //When loading a file and a buffer of the same name, I put a backslash on
   //the first one that gets loaded so that if the buffer gets loaded second
   //I don't accidently get the same file.
   filename1=strip(filename1,'T','\');
   filename2=strip(filename2,'T','\');

   _str unencoded_filename=encoding1?filename2:filename1;
   _str encoded_filename=encoding1?filename1:filename2;

   wid := p_window_id;
   _control ctlminihtml1;
   p_window_id=ctlminihtml1;
   p_backcolor=0x80000022;
   p_text=nls('<B>%s1</B> is a unicode file and <B>%s2</B> is not.<P><B>%s3</B> must be temporarily converted to a Unicode.<p>Select the current encoding of your file so it can be converted to Unicode and compared.',encoded_filename,unencoded_filename,unencoded_filename);
   p_window_id=wid;

   wid=p_window_id;
   _control ctlencoding;
   p_window_id=ctlencoding;

   _EncodingFillComboList('','Default',OEFLAG_REMOVE_FROM_DIFF);
	_lbfind_and_select_item('Text', '', true);
   p_window_id=wid;
}

_str ctlok.lbutton_up()
{
   _str option=_EncodingGetOptionFromTitle(ctlencoding.p_text);
   p_active_form._delete_window(option);
   return(option);
}

int ctlno_encoding.lbutton_up()
{
   p_active_form._delete_window(-1);
   return(-1);
}
