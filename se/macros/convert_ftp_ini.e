#pragma option(pedantic,on)
#include "slick.sh"
#import "cfg.e"
#import "stdprocs.e"


static void xlat_ftp_option_property(int iprofile,_str name,_str value) {
   switch (name) {
   case 'email':
   case 'deflocaldir':
   case 'put':
   case 'resolvelinks':
   case 'timeout':
   case 'port':
   case 'keepalive':
   case 'uploadcase':
   case 'fwhost':
   case 'fwport':
   case 'fwuserid':
   case 'fwpassword':
   case 'fwtype':
   case 'fwpasv':
   case 'fwenable':
   case 'sshexe':
   case 'sshsubsystem':
      break;
   default:
      return;
   }
   if (name=='') {
      return;
   }
   _profile_set_property(iprofile,name,value);
}
static void xlat_ftp_profile_property(int iprofile,_str name,_str value) {
   switch (name) {
   case 'host':
   case 'servertype':
   case 'sshauthtype':
   case 'hosttype':
   case 'userid':
   case 'password':
   case 'anonymous':
   case 'savepassword':
   case 'defremotehostdir':
   case 'deflocaldir':
   case 'remotefilter':
   case 'localfilter':
   case 'autorefresh':
   case 'remoteroot':
   case 'localroot':
   case 'xfertype':
   case 'port':
   case 'timeout':
   case 'usefw':
   case 'keepalive':
   case 'uploadcase':
   case 'resolvelinks':
      break;
   default:
      return;
   }
   if (name=='') {
      return;
   }
   _profile_set_property(iprofile,name,value);
}

static void convert_old_ftp_ini(_str filename) {
   status:=_open_temp_view(filename,auto temp_wid,auto orig_wid);
   if (status) {
      return;
   }
   top();up();
   status=search('^\[','@r');
   while (!status) {
      get_line(auto line);
      parse line with '[' auto profileName']';
      is_options := false;
      is_profile := false;
      package := "";
      if (strieq(profileName,'options')) {
         is_options=true;
         package=VSCFGPACKAGE_FTP;
      } else if (substr(profileName,1,8)=='profile-'){
         profileName=substr(profileName,9);
         package=VSCFGPACKAGE_FTP_PROFILES;
         is_profile=true;
      } else {
         status=repeat_search();
         continue;
      }
      iprofile:=_profile_create();
      for (;;) {
         if (down()) {
            status=repeat_search();
            break;
         }
         get_line(line);
         if (isalpha(substr(line,1,1))) {
            parse line with auto name '=' auto value;
            if (is_options) {
               xlat_ftp_option_property(iprofile,name,value);
            } else if (is_profile) {
               xlat_ftp_profile_property(iprofile,name,value);
            }
         }
         if (substr(line,1,1)=='[') {
            up();_end_line();
            status=repeat_search();
            break; 
         }
      }
      _profile_save(iprofile,package,profileName,VSCFGPROFILE_FTP_VERSION);
      _profile_close(iprofile);
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
   convert_old_ftp_ini(filename);

}
