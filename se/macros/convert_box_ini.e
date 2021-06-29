#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "plugin.sh"
#import "cfg.e"
#import "stdprocs.e"
#import "ini.e"
#require "se/lang/api/BlockCommentSettings.e"
#endregion

using se.lang.api.BlockCommentSettings;

/*
 * \s=space
 * \e=empty
 */
static _str _xlat_ini2chars(_str str)
{
   _str new_str=str;
   if (new_str :== '\e') {
      new_str = '';
   }
   new_str=stranslate(new_str,' ','\s');

   return(new_str);
}

static _str _xlat_chars2ini(_str str)
{
   _str new_str=str;
   new_str=stranslate(new_str,'\s',' ');
   if ( new_str=='' ) {
      new_str='\e';
   } else {
      new_str=stranslate(new_str,'\s',' ');
   }

   return(new_str);
}
static void _box_parse_settings(_str line,
                                _str &tlc,_str &trc,
                                _str &blc,_str &brc,
                                _str &bhside,_str &thside,
                                _str &lvside,_str &rvside)
{
   tlc=eq_name2value('tlc',line,true);
   trc=eq_name2value('trc',line,true);
   blc=eq_name2value('blc',line,true);
   brc=eq_name2value('brc',line,true);
   bhside=eq_name2value('bhside',line,true);
   thside=eq_name2value('thside',line,true);
   lvside=eq_name2value('lvside',line,true);
   rvside=eq_name2value('rvside',line,true);

   return;
}
static void _comment_parse_settings(_str line,
                                    _str &comment_left,_str &comment_right)
{
   comment_left=eq_name2value('left',line,true);
   comment_right=eq_name2value('right',line,true);

   return;
}
static void getCommentSettings_old(_str user_ini_filename,_str lang,BlockCommentSettings &comment_box_options)
{
   line := "";
   tlc := "";
   trc := "";
   blc := "";
   brc := "";
   bhside := "";
   thside := "";
   lvside := "";
   rvside := "";
   comment_left := "";
   comment_right := "";
   //int boxchars_status=0;
   //int nonboxchars_status=0;
   //int comment_col_status=0;
   //COMMENT_LINE_MODE mode = LEFT_MARGIN;
   typeless status=1;
   {
      // Check the user settings first
      temp_wid := orig_wid := 0;
      int status2=_open_temp_view(user_ini_filename,temp_wid,orig_wid);
      if (!status2) activate_window(orig_wid);
      if (status2) {
         temp_wid=0;
      }
      int boxchars_status=_ini_get_value(user_ini_filename,lang,'boxchars',line);
      if ( !boxchars_status ) {
         _box_parse_settings(line,tlc,trc,blc,brc,bhside,thside,lvside,rvside);
         comment_box_options.m_tlc=_xlat_ini2chars(tlc);
         comment_box_options.m_trc=_xlat_ini2chars(trc);
         comment_box_options.m_blc=_xlat_ini2chars(blc);
         comment_box_options.m_brc=_xlat_ini2chars(brc);
         comment_box_options.m_bhside=_xlat_ini2chars(bhside);
         comment_box_options.m_thside=_xlat_ini2chars(thside);
         comment_box_options.m_lvside=_xlat_ini2chars(lvside);
         comment_box_options.m_rvside=_xlat_ini2chars(rvside);
         status=_ini_get_value(user_ini_filename,lang,'firstline_is_top',line);
         if ( !status ) {
            comment_box_options.m_firstline_is_top=(line!=0);
         } else {
            comment_box_options.m_firstline_is_top=false;
         }
         status=_ini_get_value(user_ini_filename,lang,'lastline_is_bottom',line);
         if ( !status ) {
            comment_box_options.m_lastline_is_bottom=(line!=0);
         } else {
            comment_box_options.m_lastline_is_bottom=false;
         }
      } else {
         comment_box_options.m_tlc='';
         comment_box_options.m_trc='';
         comment_box_options.m_blc='';
         comment_box_options.m_brc='';
         comment_box_options.m_bhside='';
         comment_box_options.m_thside='';
         comment_box_options.m_lvside='';
         comment_box_options.m_rvside='';
         comment_box_options.m_firstline_is_top=false;
         comment_box_options.m_lastline_is_bottom=false;
      }
      int nonboxchars_status=_ini_get_value(user_ini_filename,lang,'nonboxchars',line);
      if ( !nonboxchars_status ) {
         _comment_parse_settings(line,comment_left,comment_right);
         comment_box_options.m_comment_left=_xlat_ini2chars(comment_left);
         comment_box_options.m_comment_right=_xlat_ini2chars(comment_right);
      } else {
         comment_box_options.m_comment_left='';
         comment_box_options.m_comment_right='';
      }
      int comment_col_status=_ini_get_value(user_ini_filename,lang,'comment_col',line);
      if ( !comment_col_status ) {
         comment_box_options.m_comment_col=(int)line;
      } else {
         comment_box_options.m_comment_col=0;
      }
      status=_ini_get_value(user_ini_filename,lang,'line_comment_mode',line);
      if ( !status ) {
         comment_box_options.m_mode = (COMMENT_LINE_MODE)line;
      } else {
         comment_box_options.m_mode=LEFT_MARGIN;
      }
      if (temp_wid) _delete_temp_view(temp_wid);
   }
}


static void convert_old_box_ini(_str filename) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   top();up();
   status=search('^\[','@r');
   while (!status) {
      get_line(auto line);
      parse line with '[' auto langId ']';
      if (!_LangIsDefined(langId)) {
         status=repeat_search();
         continue;
      }
      BlockCommentSettings comment_box_options;
      getCommentSettings_old(filename,langId,comment_box_options);
      _LangSetPropertyClass(langId,VSLANGPROPNAME_COMMENT_BOX_OPTIONS,comment_box_options);
      status=repeat_search();
   }
   _delete_temp_view(temp_wid);
   p_window_id=orig_wid;


}

defmain()
{
   args:=arg(1);
   filename:=parse_file(args,false);
   if (filename=='') {
      filename=p_buf_name;
   }
   convert_old_box_ini(filename);

}
