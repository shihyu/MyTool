#pragma option(pedantic,on)
#region Imports
#include "slick.sh"
#import "stdprocs.e"
#import "cfg.e"
#import "se/vc/VersionControlSettings.e"
#import "ini.e"
#endregion


using se.vc.VersionControlSettings;

static void convert_vc_provider(_str profileName,VersionControlProvider &value) {
   VersionControlProfile profile;
   profile.m_vcsproject=value.VCSProject;
   profile.m_archive_filespec=value.ArchiveFileSpec;
   profile.m_styles=value.Styles;
   _str commands:[];
   while (value.Commands._length()<10) {
      value.Commands[value.Commands._length()]='';
   }
   commands:['get']=value.Commands[0];
   commands:['checkout']=value.Commands[1];
   commands:['checkin']=value.Commands[2];
   commands:['unlock']=value.Commands[3];
   commands:['add']=value.Commands[4];
   commands:['lock']=value.Commands[5];
   commands:['remove']=value.Commands[6];
   commands:['history']=value.Commands[7];
   commands:['difference']=value.Commands[8];
   commands:['properties']=value.Commands[9];
   commands:['manager']=value.Commands[10];
   profile.m_commands=commands;

   VersionControlSettings.saveProfile(profileName,profile);
}


defmain()
{
   index:=find_index('def_vc_providers',VAR_TYPE);
   if (index<=0) return 0;
   t:=_get_var(index);
   VersionControlProvider value;

   foreach (auto key=>value in t) {
      if (pos('OS/2',key) || 
          // These don't have commands any more.
          key=='Git' || key=='CVS' || key=='Perforce' || key=='Subversion' || key=='Mercurial') {
         continue;
      }
      convert_vc_provider(key,value);
   }

}
