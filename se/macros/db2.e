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
#include "tagsdb.sh"
#import "c.e"
#import "context.e"
#import "slickc.e"
#import "seek.e"
#import "stdcmds.e"
#import "stdprocs.e"
#import "tags.e"


static _str gtkinfo;
static _str gtk;

static _str db2_next_sym(bool multiline=false)
{
   if (p_col>_text_colc()) {
      if (!multiline) {
         gtk=gtkinfo="";
         return(gtk);
      }
      if(down()) {
         gtk=gtkinfo="";
         return("");
      }
      _begin_line();
   }
   status := 0;
   ch := get_text();
   if (ch=="" || ((ch=="/" || ch=="-") && _clex_find(0,'g')==CFG_COMMENT)) {
      status=_clex_skip_blanks();
      if (status) {
         gtk=gtkinfo="";
         return(gtk);
      }
      return(db2_next_sym(multiline));
   }
   start_col := start_line := 0;
   if ((ch=='"' || ch=="'" ) && _clex_find(0,'g')==CFG_STRING) {
      start_col=p_col;
      start_line=p_line;
      status=_clex_find(STRING_CLEXFLAG,'n');
      if (status) {
         _end_line();
      } else if (p_col==1) {
         up();_end_line();
      }
      gtk=TK_STRING;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
      return(gtk);
   }
   word_chars := _clex_identifier_chars();
   if (pos('['word_chars']',ch,1,'r')) {
      start_col=p_col;
      if(_clex_find(0,'g')==CFG_NUMBER) {
         for (;;) {
            if (p_col>_text_colc()) break;
            right();
            if(_clex_find(0,'g')!=CFG_NUMBER) {
               break;
            }
         }
         gtk=TK_NUMBER;
         gtkinfo=_expand_tabsc(start_col,p_col-start_col+1);
         return(gtk);
      }
      //search('[~'p_word_chars']|$','@r');
      _TruncSearchLine('[~'word_chars']|$','r');
      gtk=TK_ID;
      gtkinfo=_expand_tabsc(start_col,p_col-start_col);
      return(gtk);
   }
   right();
   gtk=gtkinfo=ch;
   return(gtk);

}

static int db2_get_next_decl(_str &name,_str &type,_str &return_type)
{
   save_search(auto s1,auto s2,auto s3,auto s4,auto s5);
   db2_next_sym();
   if (gtk=="") {
      restore_search(s1,s2,s3,s4,s5);
      return(1);
   }
   if (gtkinfo==",") {
      db2_next_sym(true);
      if (gtk=="") {
         restore_search(s1,s2,s3,s4,s5);
         return(1);
      }
   }
   // If we are NOT sitting on a variable
   if (gtk!=TK_ID) {
      restore_search(s1,s2,s3,s4,s5);
      return(1);
   }
   name=gtkinfo;
   type="var";
   // Skip over variable name
   //search('[~'p_word_chars']|$','ri@');
   word_chars := _clex_identifier_chars();
   _TruncSearchLine('[~'word_chars']|$','ri');
   int start=_nrseek();
   for(;;) {
      db2_next_sym();
      if (gtk=="" || gtk==",") {
         break;
      }
   }
   if (gtk==",") {
      return_type=strip(get_text(_nrseek()-start-1,start));
   } else {
      return_type=strip(get_text(_nrseek()-start,start));
   }
   if (lowcase(return_type)=="cursor") {
      type="cursor";
   }
   return(0);
}

/**
 * Search for tags in DB2 SQL code.
 *
 * @param proc_name    (reference) proc to search for, or set to name of proc found
 * @param find_first   find first proc, or find next?
 *
 * @return 0 on success, nonzero on error or if no more tags.
 */
int db2_proc_search(_str &proc_name,int find_first)
{
   variable_re := re := "";
   status := 0;
   static int state;
   if ( find_first ) {
      state=0;
      word_chars := _clex_identifier_chars();
      variable_re='(['word_chars']#)';
      re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
         //_mdi.p_child.insert_line(re);
      mark_option := (p_EmbeddedLexerName != "")? 'm':"";
      status=search(re,'w:phri'mark_option'@xcs');
   } else {
      if (state) {
         status=0;
      } else {
         status=repeat_search();
      }
   }

   typeless orig_pos;
   save_pos(orig_pos);
   for (;;) {
      if ( status ) {
         restore_pos(orig_pos);
         break;
      }
      name := type := return_type := "";
      if (state) {
         status=db2_get_next_decl(name,type,return_type);
         //messageNwait('n='name' type='type);
         if (status) {
            state=0;
            word_chars := _clex_identifier_chars();
            variable_re='(['word_chars']#)';
            re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
            status=search(re,'w:phri@xcs');
            continue;
         }
      } else {
         name=get_match_text(0);
         keyword := get_match_text(1);
         if (lowcase(keyword)=="declare") {
            state=1;
            status=db2_get_next_decl(name,type,return_type);
            //messageNwait('s='status' n='name' t='type);
            if (status) {
               state=0;
               word_chars := _clex_identifier_chars();
               variable_re='(['word_chars']#)';
               re='{#1(declare)}[ \t]+\c{#0'variable_re'}';
               status=search(re,'w:phri@xcs');
               continue;
            }
         } else {
            // make sure the first word on this line is NOT DROP
            _str line;
            _str first_word;
            get_line(line);
            parse line with first_word .;
            if (lowcase(first_word)=="drop") {
               status=repeat_search();
               continue;
            }
            type="func";
            return_type="";
         }
      }
      tag_init_tag_browse_info(auto cm, name, "", type, SE_TAG_FLAG_NULL);
      cm.return_type = return_type;
      name=tag_compose_tag_browse_info(cm);
      if (proc_name:=="") {
         proc_name=name;
         return(0);
      }
      if (proc_name==name) {
         return(0);
      }
      if (state) {
         status=0;
      } else {
         status=repeat_search();
      }
   }
   return(status);
}

/**
 * @see ext_MaybeBuildTagFIle
 */
int _db2_MaybeBuildTagFile(int &tfindex, bool withRefs=false, bool useThread=false, bool forceRebuild=false)
{
   return ext_MaybeBuildTagFile(tfindex, "db2", "db2", 
                                "DB2 SQL Builtins",
                                "", false, withRefs, useThread, forceRebuild);
}

_str _db2_keyword_case(_str s, bool confirm=true, _str sample="")
{
   return _word_case(s, confirm, sample);
}

