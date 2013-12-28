////////////////////////////////////////////////////////////////////////////////////
// $Revision: 40327 $
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
#include "ftp.sh"
#include "blob.sh"
#import "main.e"
#import "stdcmds.e"
#import "stdprocs.e"
#endregion

int _sftpCurrentOpId(FtpConnProfile *fcp_p)
{
   return(fcp_p->sftp_opid);
}

int _sftpNextOpId(FtpConnProfile *fcp_p)
{
   long id;

   id= (long)(fcp_p->sftp_opid);
   id= (id+1)%(pow(2,31));
   fcp_p->sftp_opid= (int)id;

   return(fcp_p->sftp_opid);
}

/**
 * Parse the id, status code, and message from a SSH_FXP_STATUS packet.
 *
 * <p>
 * Note:<br>
 * This function accepts packets from _sftpPacketGet, which means
 * that the packet will not have a leading length or type, just the
 * packet payload.
 * </p>
 *
 * @param hpacket        Handle to packet.
 * @param id             Set on return. Operation id.
 * @param status_code    Set on return. Status code stored in packet.
 * @param status_message Set on return. Status string message stored in packet.
 *
 * @return 0 on success, <0 on error.
 */
int _sftpPacketParseStatus(int hpacket,int &id,int &status_code,_str &status_message)
{
   int saveOffset;
   int status;
   int offset;
   int len;

   saveOffset=_BlobGetOffset(hpacket);
   if( saveOffset<0 ) {
      // Error
      return(saveOffset);
   }
   offset=_BlobSetOffset(hpacket,0,0);
   if( offset<0 ) {
      return(offset);
   }
   // Id
   status=_BlobGetInt32(hpacket,id,1);
   if( status ) {
      return(status);
   }
   // Status code
   status=_BlobGetInt32(hpacket,status_code,1);
   if( status ) {
      return(status);
   }
   // Status message
   status=_BlobGetInt32(hpacket,len,1);
   if( status ) {
      return(status);
   }
   status=_BlobGetString(hpacket,status_message,len);
   if( status ) {
      return(status);
   }
   _BlobSetOffset(hpacket,saveOffset,0);

   return(0);
}

/**
 * This function assumes that we are already at the correct offset
 * in the blob to start parsing the attributes.
 */
static int _sftpParseAttrs(int hpacket,SftpAttrs *attrs_p)
{
   int status;
   // size must be typeless in case it is larger than an int/long
   typeless size;
   int uid,gid;
   int permissions;
   int atime,mtime;
   _str extended_data:[];
   int i;
   int len;
   _str type,data;

   // Flags
   int flags=0;
   status=_BlobGetInt32(hpacket,flags,1);
   if( status ) {
      return(status);
   }
   if( flags<0 ) {
      return(INVALID_ARGUMENT_RC);
   }
   // Size
   size=0;
   if( flags&SSH_FILEXFER_ATTR_SIZE ) {
      status=_BlobGetInt64(hpacket,size,1);
      if( status ) {
         return(status);
      }
   }
   // Uid, Gid
   uid=gid=0;
   if( flags&SSH_FILEXFER_ATTR_UIDGID ) {
      status=_BlobGetInt32(hpacket,uid,1);
      if( status ) {
         return(status);
      }
      status=_BlobGetInt32(hpacket,gid,1);
      if( status ) {
         return(status);
      }
   }
   // Permissions
   permissions=0;
   if( flags&SSH_FILEXFER_ATTR_PERMISSIONS ) {
      status=_BlobGetInt32(hpacket,permissions,1);
      if( status ) {
         return(status);
      }
   }
   // Atime, Mtime
   atime=0;
   mtime=0;
   if( flags&SSH_FILEXFER_ATTR_ACMODTIME ) {
      status=_BlobGetInt32(hpacket,atime,1);
      if( status ) {
         return(status);
      }
      status=_BlobGetInt32(hpacket,mtime,1);
      if( status ) {
         return(status);
      }
   }
   // Extended attributes
   if( flags&SSH_FILEXFER_ATTR_EXTENDED ) {
      int extended_count=0;
      extended_data._makeempty();
      status=_BlobGetInt32(hpacket,extended_count,1);
      if( status ) {
         return(status);
      }
      if( extended_count<0 ) {
         return(INVALID_ARGUMENT_RC);
      }
      for( i=0;i<extended_count;++i ) {
         // Extended type
         len=0;
         status=_BlobGetInt32(hpacket,len,1);
         if( status ) {
            return(status);
         }
         type="";
         status=_BlobGetString(hpacket,type,len);
         if( status ) {
            return(status);
         }
         // Extended data
         len=0;
         status=_BlobGetInt32(hpacket,len,1);
         if( status ) {
            return(status);
         }
         data="";
         status=_BlobGetString(hpacket,data,len);
         if( status ) {
            return(status);
         }
         // Insert into extended data table
         extended_data:[type]=data;
      }
   }

   attrs_p->flags=flags;
   attrs_p->size=size;
   attrs_p->uid=uid;
   attrs_p->gid=gid;
   attrs_p->permissions=permissions;
   attrs_p->atime=atime;
   attrs_p->mtime=mtime;
   attrs_p->extended_data=extended_data;

   return(0);
}

/**
 * Parse the file attributes from a SSH_FXP_ATTRS packet.
 *
 * <p>
 * Note:<br>
 * This function accepts packets from _sftpPacketGet, which means
 * that the packet will not have a leading length or type, just the
 * packet payload.
 * </p>
 *
 * @param hpacket Handle to packet.
 * @param id      Set on return. Operation id.
 * @param attrs_p Set on return. File attributes stored in packet.
 *
 * @return 0 on success, <0 on error.
 */
int _sftpPacketParseAttrs(int hpacket,int &id,SftpAttrs *attrs_p)
{
   int saveOffset;
   int status;
   int offset;

   saveOffset=_BlobGetOffset(hpacket);
   if( saveOffset<0 ) {
      return(saveOffset);
   }
   offset=_BlobSetOffset(hpacket,0,0);
   if( offset<0 ) {
      return(offset);
   }
   // Id
   status=_BlobGetInt32(hpacket,id,1);
   if( status ) {
      return(status);
   }
   // Attributes
   status=_sftpParseAttrs(hpacket,attrs_p);
   if( status ) {
      return(status);
   }

   // Restore previous position
   _BlobSetOffset(hpacket,saveOffset,0);

   return(0);
}

/**
 * Put file attributes into packet starting at current offset.
 *
 * @param hpacket Handle to packet.
 * @param Pointer to sftpAttrs_t structure.
 *
 * @return 0 on success, <0 on error.
 */
int _sftpPacketPutAttrs(int hpacket,SftpAttrs *attrs_p)
{
   typeless i;
   int extended_count;
   int status;

   status=_BlobPutInt32(hpacket,attrs_p->flags,1);
   if( status ) {
      return(status);
   }
   // size
   if( attrs_p->flags&SSH_FILEXFER_ATTR_SIZE ) {
      status=_BlobPutInt64(hpacket,attrs_p->size,1);
      if( status ) {
         return(status);
      }
   }
   // uid, gid
   if( attrs_p->flags&SSH_FILEXFER_ATTR_UIDGID ) {
      status=_BlobPutInt32(hpacket,attrs_p->uid,1);
      if( status ) {
         return(status);
      }
      status=_BlobPutInt32(hpacket,attrs_p->gid,1);
      if( status ) {
         return(status);
      }
   }
   // permissions
   if( attrs_p->flags&SSH_FILEXFER_ATTR_PERMISSIONS ) {
      status=_BlobPutInt32(hpacket,attrs_p->permissions,1);
      if( status ) {
         return(status);
      }
   }
   // atime, mtime
   if( attrs_p->flags&SSH_FILEXFER_ATTR_ACMODTIME ) {
      status=_BlobPutInt32(hpacket,attrs_p->atime,1);
      if( status ) {
         return(status);
      }
      status=_BlobPutInt32(hpacket,attrs_p->mtime,1);
      if( status ) {
         return(status);
      }
   }
   // extended data
   extended_count=0;
   for( i._makeempty();; ) {
      attrs_p->extended_data._nextel(i);
      if( i._isempty() ) break;
      ++extended_count;
   }
   if( attrs_p->flags&SSH_FILEXFER_ATTR_EXTENDED ) {
      status=_BlobPutInt32(hpacket,extended_count,1);
      if( status ) {
         return(status);
      }
      for( i._makeempty();; ) {
         attrs_p->extended_data._nextel(i);
         if( i._isempty() ) break;
         status=_BlobPutString(hpacket,i);
         if( status ) {
            return(status);
         }
         status=_BlobPutString(hpacket,attrs_p->extended_data:[i]);
         if( status ) {
            return(status);
         }
      }
   }

   return(0);
}

/**
 * Parse the names from a SSH_FXP_NAME packet.
 *
 * <p>
 * Note:<br>
 * This function accepts packets from _sftpPacketGet, which means
 * that the packet will not have a leading length or type, just the
 * packet payload.
 * </p>
 *
 * @param hpacket Handle to packet.
 * @param id      Set on return. Operation id.
 * @param names   Set on return. Array of names stored in packet.
 *
 * @return 0 on success, <0 on error.
 */
int _sftpPacketParseName(int hpacket,int &id,SftpName (&names)[])
{
   int saveOffset;
   int status;
   int offset;
   int count;
   int i;
   int len;
   _str filename;
   _str longname;
   SftpAttrs attrs;
   int index;

   names._makeempty();

   saveOffset=_BlobGetOffset(hpacket);
   if( saveOffset<0 ) {
      return(saveOffset);
   }
   offset=_BlobSetOffset(hpacket,0,0);
   if( offset<0 ) {
      return(offset);
   }
   // Id
   status=_BlobGetInt32(hpacket,id,1);
   if( status ) {
      return(status);
   }
   // Count
   count=0;
   status=_BlobGetInt32(hpacket,count,1);
   if( status ) {
      return(status);
   }
   // Names
   for( i=0;i<count;++i ) {
      // Filename
      len=0;
      status=_BlobGetInt32(hpacket,len,1);
      if( status ) {
         return(status);
      }
      if( len<0 ) {
         return(INVALID_ARGUMENT_RC);
      }
      filename="";
      status=_BlobGetString(hpacket,filename,len);
      if( status ) {
         return(status);
      }
      // Longname
      len=0;
      status=_BlobGetInt32(hpacket,len,1);
      if( status ) {
         return(status);
      }
      if( len<0 ) {
         return(INVALID_ARGUMENT_RC);
      }
      longname="";
      status=_BlobGetString(hpacket,longname,len);
      if( status ) {
         return(status);
      }
      // Attrs
      attrs._makeempty();
      status=_sftpParseAttrs(hpacket,&attrs);
      if( status ) {
         return(status);
      }
      index=names._length();
      names[index].filename=filename;
      names[index].longname=longname;
      names[index].attrs=attrs;
   }

   _BlobSetOffset(hpacket,saveOffset,0);

   return(0);
}

int _sftpPacketWriteToFile(int hpacket,int hfile,int len=-1)
{
   int nofbytes;

   if( hpacket<0 || hfile<0 ) {
      return(INVALID_ARGUMENT_RC);
   }
   nofbytes=_BlobWriteToFile(hpacket,hfile,len);
   if( nofbytes<0 ) {
      // Error
      return(nofbytes);
   }

   return(0);
}
