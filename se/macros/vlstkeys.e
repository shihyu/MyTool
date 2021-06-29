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
#include "vsevents.sh"
#import "files.e"
#import "main.e"
#import "slickc.e"
#import "stdprocs.e"
#endregion

defmain()
{
  if ( arg(1)!='' ) {
    if ( upcase(strip(arg(1)))!='INSERT' ) {
      message(nls('Expecting INSERT option'));
      return(1);
    }
  } else {
    temp_name := absolute('keydefs'_macro_ext);
    rc=edit('+b '_maybe_quote_filename(temp_name));
    if ( ! rc ) {
       clear_message();
       temp_name='keydefs..';
    }
    int status=edit('+t '_maybe_quote_filename(temp_name));
    if ( status ) { return(status); }
  }
  int index=name_match('',1,EVENTTAB_TYPE);
  for (;;) {
     if ( rc ) {
        break;
     }
     name := name_name(index);
     if ( ! (name=='root-keys' || name=='mode-keys' ||
             pos('[:.]',name_name(index),1,'r') || find_index(name_name(index),OBJECT_TYPE) ||
             substr(name,1,4)=='-ul2' ||  substr(name,1,4)=='-ul1' ||substr(name,1,5)=='-ainh') ) {
        insert_keydefs(index,'');
#if 0
        if ( name_name(index)=='default-keys' ) {
           get_fkeytext text;
           insert_line 'def  FKEYTEXT = nls("'text'");';
        }
#endif
     }
     index=name_match('',0,EVENTTAB_TYPE);
  }

  clear_message();
  if ( arg(1)=='' ) { top(); }
  return(0);

}
static void insert_keydefs(typeless _root_keys,typeless prefix_keys)
{
  prefix := "def ";
  // Find first non-null key binding
  VSEVENT_BINDING list[];
  list_bindings(_root_keys,list);
  NofBindings := list._length();
  i := 0;
  index := 0;
  if (prefix_keys=='') {
     for (; i<NofBindings ; ++i) {
        index= list[i].binding;//eventtab_index(_root_keys,_root_keys,i);
        if (index) {
           if (index & 0xffff0000) {
              return;
           }
           message('Inserting key definitions for 'name_name(_root_keys)'...');
           insert_line('defeventtab 'translate(name_name(_root_keys),'_','-')';');
           if (name_name(_root_keys)=='default-keys') {
              insert_line("def  'A-a'-'A-z'= ;");
              insert_line("def  'A-F6'= ;");
              insert_line("def  'F10'= ;");
           }
           break;
        }
     }
  }
  for (; i<NofBindings ; ++i) {
    /* if prefix<>'' then iterate endif */
     index= list[i].binding;//eventtab_index(_root_keys,_root_keys,i);
     if ( index && (name_type(index)& (COMMAND_TYPE|PROC_TYPE)) ) {
        if (!(list[i].iEvent>=VSEV_FIRST_ON && list[i].iEvent<=VSEV_LAST_ON)) {
           if (source_key_name(list[i].iEvent) :== "") continue;
           line := prefix " "prefix_keys;
           /* Try to reduce output by recognizing ranges. */
           if (list[i].iEvent!=list[i].iEndEvent) {
              insert_line(line:+source_key_name(list[i].iEvent)'-':+
                          source_key_name(list[i].iEndEvent)'= 'source_name(index)';');
           } else {
              insert_line(line:+source_key_name(list[i].iEvent):+'= 'source_name(index)';');
           }
        }
     }
  }
  for (i=0; i<NofBindings ; ++i) {
     index= list[i].binding;//eventtab_index(_root_keys,_root_keys,i);
     if ( index && (name_type(index) & EVENTTAB_TYPE) ) {
        insert_keydefs(index,prefix_keys:+source_key_name(list[i].iEvent)' ');
     }
  }
  if (prefix_keys=='') {
     insert_line('');
  }
}
static typeless source_name(int index)
{
   _str name=translate(name_name(index),'_','-');
   if (!isid_valid(name)) {
      if (name=="/") {
         name="find";
      } else {
         name="";
      }
   }
   return(name);
}
// This function is (or at least was) identical to source_event_name()
static _str source_key_name(int index)
{
   // IF this is a Unicode character
   _str key_name=event2name(index2event(index));
   if ( pos("'",key_name) || pos('\x{',key_name,1,'i')) {
      return('"'key_name'"');
   }
   if (length(key_name)==1 && _asc(key_name)>127) {
      return('\'_asc(key_name));
   }
   return("'"key_name"'");
/*
  key_name= translate(event2name(index2event(index)),'_','-')
  if length(key_name)>1 then return(key_name) endif
  if index=_asc("'") then
    return('"''"')
  endif
  return("'"_chr(index)"'")
*/
}
