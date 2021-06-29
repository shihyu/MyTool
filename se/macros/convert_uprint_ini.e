#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#include "plugin.sh"
#import "cfg.e"
#import "stdprocs.e"
#import "ini.e"
#endregion

static void xlat_property(_str profileName,_str name,_str value) {
   _str apply=null;
   origname:=name;
   switch (name) {
   case 'portrait':
      name=VSCFGP_PRINTING_PORTRAIT;
      break;
   case 'numberlinesevery':
      name=VSCFGP_PRINTING_NUMBER_LINES_EVERY;
      break;
   case 'printcolor':
      name=VSCFGP_PRINTING_PRINT_COLOR;
      break;
   case 'printbgcolor':
      name=VSCFGP_PRINTING_PRINT_BG_COLOR;
      break;
   case 'numberofcopies':
      name=VSCFGP_PRINTING_NUMBER_OF_COPIES;
      break;
   case 'printhex':
      name=VSCFGP_PRINTING_PRINT_HEX;
      break;
   case 'leftmargin':
      name=VSCFGP_PRINTING_LEFT_MARGIN;
      break;
   case 'beforefooter':
      name=VSCFGP_PRINTING_BEFORE_FOOTER;
      break;
   case 'rightfooter':
      name=VSCFGP_PRINTING_RIGHT_FOOTER;
      break;
   case 'leftfooter':
      name=VSCFGP_PRINTING_LEFT_FOOTER;
      break;
   case 'afterheader':
      name=VSCFGP_PRINTING_AFTER_HEADER;
      break;
   case 'rightheader':
      name=VSCFGP_PRINTING_RIGHT_HEADER;
      break;
   case 'selectiononly':
      name=VSCFGP_PRINTING_SELECTION_ONLY;
      break;
   case 'rightmargin':
      name=VSCFGP_PRINTING_RIGHT_MARGIN;
      break;
   case 'bottommargin':
      name=VSCFGP_PRINTING_BOTTOM_MARGIN;
      break;
   case 'centerfooter':
      name=VSCFGP_PRINTING_CENTER_FOOTER;
      break;
   case 'leftheader':
      name=VSCFGP_PRINTING_LEFT_HEADER;
      break;
   case 'twoup':
      name=VSCFGP_PRINTING_TWO_UP;
      break;
   case 'visiblelinesonly':
      name=VSCFGP_PRINTING_VISIBLE_LINES_ONLY;
      break;
   case 'landscape':
      name=VSCFGP_PRINTING_LANDSCAPE;
      break;
   case 'topmargin':
      name=VSCFGP_PRINTING_TOP_MARGIN;
      break;
   case 'centerheader':
      name=VSCFGP_PRINTING_CENTER_HEADER;
      break;
   case 'spacebetween':
      name=VSCFGP_PRINTING_SPACE_BETWEEN;
      break;
   case 'printcolorcoding':
      name=VSCFGP_PRINTING_PRINT_COLOR_CODING;
      break;
   case 'fonttext':
      name=VSCFGP_PRINTING_FONT_TEXT;
      {
         typeless font_style;
         parse value with auto font_name','auto font_size','font_style',';
         handle:=_xmlcfg_create('',VSENCODING_UTF8);
         property_node:=_xmlcfg_add_property(handle,0,name);
         attrs_node:=property_node;
         _xmlcfg_set_attribute(handle,attrs_node,'font_name',font_name);
         _xmlcfg_set_attribute(handle,attrs_node,'sizex10',((int)font_size)*10);
         _xmlcfg_set_attribute(handle,attrs_node,'flags',"0x":+_dec2hex(font_style));
         _plugin_set_property_xml(VSCFGPACKAGE_PRINTING_PROFILES,profileName,VSCFGPROFILE_PRINTING_VERSION,name,handle);
         _xmlcfg_close(handle);
         return ;
      }
      break;
   }
   _plugin_set_property(VSCFGPACKAGE_PRINTING_PROFILES,profileName,VSCFGPROFILE_PRINTING_VERSION,name,value);
}


static void convert_old_uprint_ini(_str filename) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   top();up();
   status=search('^\[','@r');
   while (!status) {
      get_line(auto line);
      parse line with '[' auto profileName ']';
      if (profileName=='SlickEdit') {
         profileName='Default';
      }

      for (;;) {
         if (down()) {
            status=repeat_search();
            break;
         }
         get_line(line);
         if (isalpha(substr(line,1,1))) {
            parse line with auto name '=' auto value;
            xlat_property(profileName,name,value);
         }
         if (substr(line,1,1)=='[') {
            up();_end_line();
            status=repeat_search();
            break; 
         }
      }
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
   convert_old_uprint_ini(filename);

}
