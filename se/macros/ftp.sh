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
#pragma option(metadata,"ftp.e")


enum FtpXferType {
   FTPXFER_DEFAULT = 0,
   // Ascii translation mode
   FTPXFER_ASCII = 1,
   // Binary mode
   FTPXFER_BINARY = 2
};

enum FtpXferFlags {
   // Used by SFTP to disable the choice of transfer type on upload/download
   FTPXFERFLAG_NOCHOICE = 0x1,
   // No flags
   FTPXFERFLAG_NONE = 0x0
};

/**
 * Used with _ftpQEHandler_RecvCmd() handler.
 * Pointer-to-function to call when tracking transfer progress.
 */
typedef void (*FtpProgressCallback)(_str operation, typeless nofbytes, typeless total_nofbytes);

/**
 * Used with _ftpQEHandler_RecvCmd(), _sftpQEHandler_Get() handlers.
 * Struct that is passed with QE_RECV_CMD, QE_SFTP_GET.
 */
struct FtpRecvCmd {

   bool pasv;
   _str cmdargv[];
   _str dest;
   _str datahost;
   _str dataport;
   // .size must be typeless in case it is larger than an int
   typeless size;
   // Ascii or Binary
   FtpXferType xfer_type;
   // Optional info specific to the caller
   _str extra;
   // Remote cwd before starting the receive (used for RETRs on VM hosts)
   _str orig_cwd;
   // Command(s) issued before RETR, etc.
   _str pre_cmds[];
   // Command(s) issued after RETR, etc.
   _str post_cmds[];
   FtpProgressCallback progressCb;

   // These members used specifically by SFTP while receiving transfer

   // Handle to SFTP handle
   int  hhandle;
   // Handle to open file.
   int  hfile;
   // Offset to read/write from/to into file.
   // .offset must be typeless in case it is larger than an int
   typeless offset;

};

/**
 * Used with _ftpQEHandler_SendCmd(), _sftpQEHandler_Put() handlers.
 * Struct that is passed with QE_SEND_CMD, QE_SFTP_PUT.
 */
struct FtpSendCmd {

   bool pasv;
   _str cmdargv[];
   _str src;
   _str datahost;
   _str dataport;
   // .size must be typeless in case it is larger than an int
   typeless size;
   // Ascii or Binary
   FtpXferType xfer_type;
   // Remote cwd before starting the send (used for STORs on VM hosts)
   _str orig_cwd;
   // Command(s) issued before STOR, etc.
   _str pre_cmds[];
   // Command(s) issued after STOR, etc.
   _str post_cmds[];
   FtpProgressCallback progressCb;

   // These members used specifically by SFTP while receiving transfer

   // Handle to SFTP handle
   int  hhandle;
   // Handle to open file.
   int  hfile;
   // Offset to read/write from/to into file.
   // .offset must be typeless in case it is larger than an int/long
   typeless offset;
};

struct FtpCustomCmd {
   _str pattern;
   _str cmdargv[];
};


const QE_FIRST= (1);
const QE_START_CONN_PROFILE=     (QE_FIRST);
const QE_PROXY_CONNECT=          (QE_FIRST+1);
const QE_RELAY_CONNECT=          (QE_FIRST+2);
const QE_PROXY_OPEN=             (QE_FIRST+3);
const QE_OPEN=                   (QE_FIRST+4);
const QE_FIREWALL_SPECIAL=       (QE_FIRST+5);
const QE_USER=                   (QE_FIRST+6);
const QE_PASS=                   (QE_FIRST+7);
const QE_CDUP=                   (QE_FIRST+8);
const QE_CWD=                    (QE_FIRST+9);
const QE_PWD=                    (QE_FIRST+10);
const QE_MKD=                    (QE_FIRST+11);
const QE_DELE=                   (QE_FIRST+12);
const QE_RMD=                    (QE_FIRST+13);
const QE_RENAME=                 (QE_FIRST+14);
const QE_RECV_CMD=               (QE_FIRST+15);
const QE_SEND_CMD=               (QE_FIRST+16);
const QE_END_CONN_PROFILE=       (QE_FIRST+17);
const QE_PROXY_QUIT=             (QE_FIRST+18);
const QE_KEEP_ALIVE=             (QE_FIRST+19);
const QE_CUSTOM_CMD=             (QE_FIRST+20);
const QE_SYST=                   (QE_FIRST+21);
const QE_ERROR=                  (QE_FIRST+22);

const QE_SSH_START_CONN_PROFILE= (QE_FIRST+23);
const QE_SSH_START=              (QE_FIRST+24);
const QE_SSH_AUTH_PASSWORD=      (QE_FIRST+25);
const QE_SFTP_INIT=              (QE_FIRST+26);
const QE_SFTP_PUT=               (QE_FIRST+27);
const QE_SFTP_DIR=               (QE_FIRST+28);
const QE_SFTP_GET=               (QE_FIRST+29);
const QE_SFTP_STAT=              (QE_FIRST+30);
const QE_SFTP_REMOVE=            (QE_FIRST+31);
const QE_SFTP_RMDIR=             (QE_FIRST+32);
const QE_SFTP_MKDIR=             (QE_FIRST+33);
const QE_SFTP_RENAME=            (QE_FIRST+34);
const QE_SSH_END_CONN_PROFILE=   (QE_FIRST+35);

const QE_NONE=                   (QE_FIRST+36);
const QE_LAST=                   QE_NONE;

const QS_FIRST= (1);
const QS_BEGIN=                              (QS_FIRST);
const QS_WAITING_FOR_REPLY=                  (QS_FIRST+1);
const QS_LISTENING=                          (QS_FIRST+2);
const QS_PROMPT=                             (QS_FIRST+3);
const QS_PORT_BEGIN=                         (QS_FIRST+4);
const QS_PORT_WAITING_FOR_REPLY=             (QS_FIRST+5);
const QS_PASV_BEGIN=                         (QS_FIRST+6);
const QS_PASV_WAITING_FOR_REPLY=             (QS_FIRST+7);
const QS_EPRT_BEGIN=                         (QS_FIRST+8);
const QS_EPRT_WAITING_FOR_REPLY=             (QS_FIRST+9);
const QS_EPSV_BEGIN=                         (QS_FIRST+10);
const QS_EPSV_WAITING_FOR_REPLY=             (QS_FIRST+11);
const QS_PROXY_OPENDATA_BEGIN=               (QS_FIRST+12);
const QS_PROXY_OPENDATA_WAITING_FOR_REPLY=   (QS_FIRST+13);
const QS_PROXY_LISTENDATA_BEGIN=             (QS_FIRST+14);
const QS_PROXY_LISTENDATA_WAITING_FOR_REPLY= (QS_FIRST+15);
const QS_TYPE_BEGIN=                         (QS_FIRST+16);
const QS_TYPE_WAITING_FOR_REPLY=             (QS_FIRST+17);
const QS_CMD_BEGIN=                          (QS_FIRST+18);
const QS_CMD_WAITING_FOR_REPLY=              (QS_FIRST+19);
const QS_PROXY_RECVDATA_BEGIN=               (QS_FIRST+20);
const QS_PROXY_RECVDATA_WAITING_FOR_REPLY=   (QS_FIRST+21);
const QS_PROXY_SENDDATA_BEGIN=               (QS_FIRST+22);
const QS_PROXY_SENDDATA_WAITING_FOR_REPLY=   (QS_FIRST+23);
const QS_PROXY_DATASTAT_BEGIN=               (QS_FIRST+24);
const QS_PROXY_DATASTAT_WAITING_FOR_REPLY=   (QS_FIRST+25);
const QS_PROXY_CLOSEDATA_BEGIN=              (QS_FIRST+26);
const QS_PROXY_CLOSEDATA_WAITING_FOR_REPLY=  (QS_FIRST+27);
const QS_END_TRANSFER_WAITING_FOR_REPLY=     (QS_FIRST+28);
const QS_CWD_BEFORE_BEGIN=                   (QS_FIRST+29);
const QS_CWD_BEFORE_WAITING_FOR_REPLY=       (QS_FIRST+30);
const QS_PWD_BEFORE_WAITING_FOR_REPLY=       (QS_FIRST+31);
const QS_CWD_AFTER_BEGIN=                    (QS_FIRST+32);
const QS_CWD_AFTER_WAITING_FOR_REPLY=        (QS_FIRST+33);
const QS_PWD_AFTER_WAITING_FOR_REPLY=        (QS_FIRST+34);

const QS_CMD_BEFORE_BEGIN=                   (QS_FIRST+35);
const QS_CMD_BEFORE_WAITING_FOR_REPLY=       (QS_FIRST+36);
const QS_CMD_AFTER_BEGIN=                    (QS_FIRST+37);
const QS_CMD_AFTER_WAITING_FOR_REPLY=        (QS_FIRST+38);

const QS_RNFR_WAITING_FOR_REPLY=             (QS_FIRST+39);
const QS_RNTO_WAITING_FOR_REPLY=             (QS_FIRST+40);
const QS_ERROR=                              (QS_FIRST+41);
const QS_ABORT=                              (QS_FIRST+42);
const QS_ABORT_WAITING_FOR_REPLY=            (QS_FIRST+43);
const QS_FWUSER_WAITING_FOR_REPLY=           (QS_FIRST+44);
const QS_FWPASS_WAITING_FOR_REPLY=           (QS_FIRST+45);
const QS_FWOPEN_WAITING_FOR_REPLY=           (QS_FIRST+46);

const QS_WAITING_FOR_PROMPT=                 (QS_FIRST+47);

const QS_FXP_INIT_WAITING_FOR_REPLY=         (QS_FIRST+48);
const QS_FXP_ATTRS_WAITING_FOR_REPLY=        (QS_FIRST+49);
const QS_FXP_HANDLE_WAITING_FOR_REPLY=       (QS_FIRST+50);
const QS_FXP_NAME_WAITING_FOR_REPLY=         (QS_FIRST+51);
const QS_FXP_STATUS_WAITING_FOR_REPLY=       (QS_FIRST+52);
const QS_FXP_READDIR=                        (QS_FIRST+53);
const QS_FXP_READ=                           (QS_FIRST+54);
const QS_PASSWORD=                           (QS_FIRST+55);
const QS_FXP_DATA_WAITING_FOR_REPLY=         (QS_FIRST+56);
const QS_FXP_WRITE=                          (QS_FIRST+57);
const QS_FXP_WRITESTATUS_WAITING_FOR_REPLY=  (QS_FIRST+58);

const QS_MAYBE_WAITING_FOR_PROMPT=           (QS_FIRST+59);
const QS_WAITING_FOR_DONE=                   (QS_FIRST+60);

const QS_END=                                (QS_FIRST+61);
const QS_NONE=                               (QS_FIRST+62);
const QS_LAST=                               (QS_NONE);

const FTP_EOL= "\n";
const FTP_ALLFILES_RE= "*";

const FTP_ERRORBOX_TITLE=   "FTP Error";
const FTP_WARNINGBOX_TITLE= "FTP Warning";
const FTP_INFOBOX_TITLE=    "FTP";

// Default values for a connection profile
const FTPDEF_TIMEOUT= (30);
const FTPDEF_ANONYMOUS_USERID= "anonymous";
const FTPDEF_ANONYMOUS_PASS=   "guest@";
const FTPDEF_PORT= (21);

// ON_CREATE flags for _ftpCreateProfile_form
const FCPFLAG_LOGIN=           (0x1);
const FCPFLAG_NOSAVEPROFILE=   (0x2);
const FCPFLAG_HIDESAVEPROFILE= (0x4);
const FCPFLAG_SAVEPROFILEOFF=  (0x8);
const FCPFLAG_DISABLEPROFILE=  (0x10);
const FCPFLAG_EDIT=            (0x20);

const FTPFILECASE_PRESERVE= (0x1);
const FTPFILECASE_LOWER=    (0x2);
const FTPFILECASE_UPPER=    (0x3);

struct FtpOptions {

   _str    email;
   _str    deflocaldir;
   int     put;
   bool    resolvelinks;
   int     timeout;
   int     port;
   bool    keepalive;
   int     uploadcase;
   _str    fwhost;
   int     fwport;
   _str    fwuserid;
   _str    fwpassword;
   int     fwtype;
   bool    fwpasv;
   bool    fwenable;
   _str    sshexe;
   _str    sshsubsystem;

};

const FTPFILETYPE_DIR=  (0x1);
const FTPFILETYPE_LINK= (0x2);
const FTPFILETYPE_CREATED= (0x4);
const FTPFILETYPE_DELETED= (0x8);
const FTPFILETYPE_RENAMED= (0x10);
const FTPFILETYPE_FAKED=   (FTPFILETYPE_CREATED|FTPFILETYPE_DELETED|FTPFILETYPE_RENAMED);

struct FtpFile {

   _str filename;
   // Is this file a directory/symlink?
   int  type;
   // .size is typeless because it could be larger than an int
   typeless size;
   _str month;
   int  day;
   int  year;
   _str time;
   // .mtime field suitable for sorting (not the same as UNIX mtime)
   _str mtime;
   _str attribs;
   _str owner;
   _str group;
   // Number of file references
   int  refs;

};

const FTPDIRTYPE_MVS_VOLUME= (0x1);
struct FtpDirectory {
   int flags;
   FtpFile files[];
};

/* Used for recursive operations (e.g. upload, download).
 */
struct FtpDirStack {

   // Current local working directory
   _str localcwd;
   // Current remote working directory
   _str remotecwd;
   // Index of next file to be processed in dir.files[]
   int  next;
   // Directory file listing
   FtpDirectory dir;
   // Saved tree position so can restore later
   typeless tree_pos;

};

// Pointer-to-function to call when the queue processes the last event and goes idle
typedef void (*FtpPostEventCallback)(.../*ftpQEvent_t *e_p*/);

// Pointer-to-function to call for notification (e.g. error, warning, etc.)
typedef void (*FtpNotifyCallback)(_str msg);

// Sort by name
const FTPSORTFLAG_NAME=    (0x1);
// Sort by extension
const FTPSORTFLAG_EXT=     (0x2);
// Sort by size
const FTPSORTFLAG_SIZE=    (0x4);
// Sort by date
const FTPSORTFLAG_DATE=    (0x8);
// Sort in ascending order
const FTPSORTFLAG_ASCEND=  (0x10);
// Sort in descending order
const FTPSORTFLAG_DESCEND= (0x20);

const FTPSERVERTYPE_FTP=  (0);
const FTPSERVERTYPE_SFTP= (1);

const SSHAUTHTYPE_AUTO=      (0);
const SSHAUTHTYPE_PASSWORD=  (1);
const SSHAUTHTYPE_PUBLICKEY= (2);
const SSHAUTHTYPE_HOSTBASED= (3);
const SSHAUTHTYPE_KEYBOARD_INTERACTIVE= (4);

const FTPSYST_AUTO=         (0);
// UNIX on anything
const FTPSYST_UNIX=         (1);
// Windows NT on Intel
const FTPSYST_WINNT=        (2);
// VOS on a Stratus box
const FTPSYST_VOS=          (3);
// MVS on a S/390 box
const FTPSYST_MVS=          (4);
// VMS on a VAX box
const FTPSYST_VMS=          (5);
// VMS Multinet on a VAX box
const FTPSYST_VMS_MULTINET= (6);
// VM/ESA on an IBM S/390
const FTPSYST_VMESA=        (7);
// OS/400 on a AS/400
const FTPSYST_OS400=        (8);
// OS/2 Warp on Intel
const FTPSYST_OS2=          (9);
// VM on an IBM S/390
const FTPSYST_VM=           (10);
// Novell Netware on Intel
const FTPSYST_NETWARE=      (11);
// Hummingbird on NT
const FTPSYST_HUMMINGBIRD=  (12);
// MacOS on Apple
const FTPSYST_MACOS=        (13);
// VxWorks on embedded system
const FTPSYST_VXWORKS=      (14);
const FTPSYST_DEFAULT= FTPSYST_UNIX;
struct FtpConnProfile {

   _str    profileName;
   /** 
    * Connection instance. This will normally be 0, but if the user
    * starts the same connection profile more than once, then this
    * number will be incremented to reflect the number of instances
    * currently started.
    */
   int     instance;

   // Name of the FTP server
   _str host;
   // Remote FTP port to connect to (default=21)
   int port;
   // User/Login ID
   _str userId;
   // This will be scrambled
   _str password;
   // true='anonymous' ftp login
   bool anonymous;
   // true=save password
   bool savePassword;

   // Transfer type (i.e. ascii/binary)
   FtpXferType xferType;
   // Default remote host directory
   _str defRemoteDir;
   // Default local directory
   _str defLocalDir;
   // (seconds) timeout to wait for a response from FTP server
   int timeout;
   // true=Use firewall/proxy to connect
   bool useFirewall;
   // true=Keep connection alive
   bool keepAlive;
   // File-case to use when STORing files (i.e. preserve, lower, upper)
   int uploadCase;
   // Resolve file/directory links?
   bool resolveLinks;

   // Global ftp options (e.g. firewall settings, etc.)
   FtpOptions global_options;

   /**
    * Last response line from ftp server that had a code. Example:
    *
    * <pre>200 PORT command successful.</pre>
    *
    * Note: In the case of an SFTP server, this would be the last 
    * error from stderr. 
    */
   _str lastStatusLine;

   /** 
    * Previous response line from ftp server.
    * <p>
    * Note: In the case of an SFTP server, this would be the
    * previous error from stderr.
    */
   _str prevStatusLine;

   // Currently connected FTP control socket (FTP only)
   int sock;
   // Currently connected control socket to the SlickEdit proxy (FTP only)
   int vsproxy_sock;
   // Process id for SlickEdit proxy (FTP only)
   int vsproxy_pid;
   // Handle to ssh client process
   int ssh_hprocess;
   // Handle to input pipe for piped ssh connections
   int ssh_hin;
   // Handle to output pipe for piped ssh connections
   int ssh_hout;
   // Handle to err pipe for piped ssh connections
   int ssh_herr;
   // true=Check ssh client stderr pipe for errors
   bool ssh_checkerrors;
   // Current operation id (monotonically increasing 0..2^31 modulo 2^31)
   int sftp_opid;
   // true=Asynchronous operation so SE is not tied up
   bool vsproxy;
   // buffer name of the log buffer
   _str logBufName;
   // Remote file/directory list struct
   FtpDirectory remoteDir;
   // Local Current Working Directory
   _str localCwd;
   // Remote Current Working Directory
   _str remoteCwd;
   // History of all directories the user changed to
   _str cwdHist[];
   // Filespec to filter local directory listings
   _str localFileFilter;
   _str remoteFileFilter;

   // Flags for sorting (i.e. by name, date, etc.)
   int localSortFlags;
   int remoteSortFlags;

   // Auto refresh the remote directory listing on upload, delete, rename, etc?
   bool autoRefresh;
   // Used to map remote paths onto local paths
   _str remoteRoot;
   // Used to map remote paths onto local paths
   _str localRoot;

   /** 
    * Buffered reply from ftp server or VSE proxy. This is used in
    * asynchronous operation to keep track of a server/SE proxy
    * response.
    */
   _str reply;

   /** 
    * Used to keep track of how long a connection is idle by the
    * ftp queue for the purpose of keeping the connection alive.
    */
   double idle;

   // Server type (e.g. FTP, SFTP)
   int serverType;

   // Authentication type (e.g. password, publickey, hostbased)
   int sshAuthType;

   // Host operating system name returned by SYST command
   int system;

   /**
    * Call when the queue processes the last event and goes idle. 
    */
   FtpPostEventCallback postedCb;

   /**
    * Call when notifying of an error. 
    */
   FtpNotifyCallback errorCb;

   /**
    * Call when notifying of a warning. 
    */
   FtpNotifyCallback warnCb;

   /**
    * Call when notifying of info. 
    */
   FtpNotifyCallback infoCb;

   /**
    * Used as a directory stack for recursive operations (e.g. upload,
    * download).
    */
   FtpDirStack dir_stack[];

   /** 
    * Recurse subdirectories when uploading/downloading? 
    */
   bool recurseDirs;

   /**
    * When on, errors from LIST command are ignored and an empty listing is
    * returned instead.
    *
    * This is useful for hosts like MVS that give an error when a PDS has
    * no contents, instead of just returning a 0 bytes list like every
    * other host type.
    */
   bool ignoreListErrors;

   /**
    * Operation defined. When true, links are downloaded/opened as files
    * instead of directories.
    */
   bool downloadLinks;

   /**
    * Operation defined.
    */
   typeless extra;

   /** 
    * Connection address of the remote FTP host. This is NOT the 
    * same as the address of the vsproxy control connection 
    * (.vsproxy_sock), or the relay connection (.sock). We get this 
    * from the response from the OPEN command sent to vsproxy. If 
    * the user is connecting through a proxy host, then this will 
    * be the address of the proxy host. We need this in order to 
    * determine if the connection to the FTP server is IPv4 or 
    * IPv6.
    */
   _str remote_address;

};

struct FtpQEvent {

   // Event to be processed (see QE_*)
   int event;
   // State of the event (i.e. waiting for a reply, etc.)
   int state;
   // Time (in milliseconds) that this event started
   double start;
   // Connection profile that this event affects
   FtpConnProfile fcp;
   // Extra info depending on the event
   typeless info[];

};

struct FtpFileHistFile {

   /** 
    * Local filename (this would be mapped to an absolute remote
    * path on an 8.3 file system).
    */
   _str local_path;

};

struct FtpFileHist {

   /** 
    * This hash table is indexed by the absolute remote path and
    * contains various information about the remote file (e.g.
    * local filename mapping when on 8.3 file systems, trasfer
    * type, etc.).
    */
   FtpFileHistFile files:[];

};

// Common options
const FTPOPT_EXPLICIT_PUT= (0);
const FTPOPT_PROMPTED_PUT= (1);
const FTPOPT_ALWAYS_PUT=   (2);
const FTPOPT_FWTYPE_USERAT=    (0);
const FTPOPT_FWTYPE_OPEN=      (1);
const FTPOPT_FWTYPE_ROUTER=    (2);
const FTPOPT_FWTYPE_USERLOGON= (3);

/* _ftpQ cannot be static, otherwise it would get blown away when user
 * re-load()s.
 */
FtpQEvent _ftpQ[];

//
// Timer callback for the FTP queue
//

extern void _ftpQTimerCallback();
extern void _ftpQKillTimer();

//
// Event callbacks for the FTP queue
//


extern void __ftpopenConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" );
extern void __ftpopenConnect2CB( FtpQEvent *pEvent );

extern void __ftpclientConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" );
extern void __ftpclientConnect2CB( FtpQEvent *pEvent );

extern void __ftpclientCwdCB( FtpQEvent *pEvent );
extern void __ftpclientCwdLinkCB( FtpQEvent *pEvent );

extern void __sftpopenConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" );
extern void __sftpopenConnect2CB( FtpQEvent *pEvent );
extern void __sftpopenDisconnectCB( FtpQEvent *pEvent );
extern void __sftpopenCwdCB( FtpQEvent *pEvent, typeless isLink="" );
extern void __sftpopenCwdLinkCB( FtpQEvent *pEvent );
extern void __sftpopenUpdateSessionCB( FtpQEvent *pEvent );
extern void __sftpopenDelFile1CB( FtpQEvent *pEvent );

extern void __sftpclientConnectCB( FtpQEvent *pEvent, typeless isReconnecting="" );
extern void __sftpclientConnect2CB( FtpQEvent *pEvent );
extern void __sftpclientCwdCB( FtpQEvent *pEvent, typeless isLink="" );
extern void __sftpclientCwdLinkCB( FtpQEvent *pEvent );
extern void __sftpclientUpdateRemoteSessionCB( FtpQEvent *pEvent );
extern void __sftpclientDelRemoteFile1CB( FtpQEvent *pEvent );
extern void __sftpclientDownload1CB( FtpQEvent *pEvent, typeless doDownloadLinks="" );
extern void __sftpclientUpload1CB( FtpQEvent *pEvent );

/* FTP files that have been opened within Visual SlickEdit for editing.
 * This hash table will be indexed by the host name of an ftp file.
 * Each entry contains another hash table of the remote files that have
 * been opened for the particular host along with various properties
 * (i.e. locally mapped filename, transfer type, etc.).
 */
FtpFileHist _ftpFileHist:[];

/* This MUST be global because a load() would wipe out the list and we
 * would be left with a bunch of "zombie" sockets left open without any
 * way of getting to them. _exit_ftp() takes care of emptying this array
 * when the editor exits.
 */
FtpConnProfile _ftpCurrentConnections:[];

// Picture indices for bitmaps
int _pic_ftpcdup;
int _pic_ftpfile;
int _pic_ftpfold;
int _pic_ftplfol;
int _pic_ftplfil;
int _pic_ftpfild;
int _pic_ftpfod;
int _pic_ftpnfil;
int _pic_ftpnfol;
int _pic_ftpdfil;
int _pic_ftpdfol;
int _pic_ftprfil;
int _pic_ftprfol;

extern void _ftpopenProgressCB(_str operation, typeless nofbytes, typeless total_nofbytes);
extern void _ftpopenProgressDlgCB(_str operation, typeless nofbytes, typeless total_nofbytes);

extern void _ftpclientProgressCB(_str operation, typeless nofbytes, typeless total_nofbytes);

const FTPDEBUG_LOG_PROXY=   (0x1);
const FTPDEBUG_SAY_EVENTS=  (0x2);
const FTPDEBUG_SAVE_LOG=    (0x4);
const FTPDEBUG_TIME_STAMP=  (0x8);
const FTPDEBUG_SAVE_LIST=   (0x10);
const FTPDEBUG_VSPROXY=     (0x20);
const FTPDEBUG_SSH_VERBOSE= (0x40);
int _ftpdebug=0;

bool gftpAbort;   // Used by _ftpProgress_form

// Used for remote and local file/directory name completion
const FTPFILE_ARG= "ftpfile";
const FTPLOCALFILE_ARG= "ftplocalfile";
const FTPLOCALDIR_ARG= "ftplocaldir";


const SFTPDEF_PORT= (22);
const SFTPDEF_SUBSYSTEM= "sftp";

const VS_SSH_ASKPASS_ARGS_ENVVAR= "VS_SSH_ASKPASS_ARGS";

const VS_SSH_ASKPASS_PROMPT= "vs-ssh-askpass password: ";
const VS_SSH_ASKPASS_DONE=   "vs-ssh-askpass done.";
const VS_SSH_ASKPASS_CANCELLED= "vs-ssh-askpass cancelled.";

//
// SSH definitions from the secsh-filexfer draft
//

// Packet types
const SSH_FXP_INIT=           1;
const SSH_FXP_VERSION=        2;
const SSH_FXP_OPEN=           3;
const SSH_FXP_CLOSE=          4;
const SSH_FXP_READ=           5;
const SSH_FXP_WRITE=          6;
const SSH_FXP_LSTAT=          7;
const SSH_FXP_FSTAT=          8;
const SSH_FXP_SETSTAT=        9;
const SSH_FXP_FSETSTAT=       10;
const SSH_FXP_OPENDIR=        11;
const SSH_FXP_READDIR=        12;
const SSH_FXP_REMOVE=         13;
const SSH_FXP_MKDIR=          14;
const SSH_FXP_RMDIR=          15;
const SSH_FXP_REALPATH=       16;
const SSH_FXP_STAT=           17;
const SSH_FXP_RENAME=         18;
const SSH_FXP_READLINK=       19;
const SSH_FXP_SYMLINK=        20;
const SSH_FXP_STATUS=         101;
const SSH_FXP_HANDLE=         102;
const SSH_FXP_DATA=           103;
const SSH_FXP_NAME=           104;
const SSH_FXP_ATTRS=          105;
const SSH_FXP_EXTENDED=       200;
const SSH_FXP_EXTENDED_REPLY= 201;

// File attribute flags
const SSH_FILEXFER_ATTR_SIZE=        0x00000001;
const SSH_FILEXFER_ATTR_UIDGID=      0x00000002;
const SSH_FILEXFER_ATTR_PERMISSIONS= 0x00000004;
const SSH_FILEXFER_ATTR_ACMODTIME=   0x00000008;
const SSH_FILEXFER_ATTR_EXTENDED=    0x80000000;

// File open, create, close flags
const SSH_FXF_READ=   0x00000001;
const SSH_FXF_WRITE=  0x00000002;
const SSH_FXF_APPEND= 0x00000004;
const SSH_FXF_CREAT=  0x00000008;
const SSH_FXF_TRUNC=  0x00000010;
const SSH_FXF_EXCL=   0x00000020;

// Responses from server
const SSH_FX_OK=                0;
const SSH_FX_EOF=               1;
const SSH_FX_NO_SUCH_FILE=      2;
const SSH_FX_PERMISSION_DENIED= 3;
const SSH_FX_FAILURE=           4;
const SSH_FX_BAD_MESSAGE=       5;
const SSH_FX_NO_CONNECTION=     6;
const SSH_FX_CONNECTION_LOST=   7;
const SSH_FX_OP_UNSUPPORTED=    8;

struct SftpAttrs {

   int flags;
   // .size must be typeless in case it is larger than an int/long
   typeless size;
   int uid;
   int gid;
   int permissions;
   int atime;
   int mtime;
   _str extended_data:[];

};

//
// POSIX stat defines for manipulating permissions bits
//

const	_IFMT=	0170000;	/* type of file */
const	_IFDIR=	0040000;	/* directory */
const	_IFCHR=	0020000;	/* character special */
const	_IFBLK=	0060000;	/* block special */
const	_IFREG=	0100000;	/* regular */
const	_IFLNK=	0120000;	/* symbolic link */
const	_IFSOCK=	0140000;	/* socket */
const	_IFIFO=	0010000;	/* fifo */

const S_BLKSIZE=  1024; /* size of a block */

const	S_ISUID=		0004000;	/* set user id on execution */
const	S_ISGID=		0002000;	/* set group id on execution */
const	S_ISVTX=		0001000;	/* save swapped text even after use */
const	S_IREAD=		0000400;	/* read permission, owner */
const	S_IWRITE= 	0000200;	/* write permission, owner */
const	S_IEXEC=		0000100;	/* execute/search permission, owner */
const	S_ENFMT=	 	0002000;	/* enforcement-mode locking */

const	S_IFMT=		_IFMT;
const	S_IFDIR=		_IFDIR;
const	S_IFCHR=		_IFCHR;
const	S_IFBLK=		_IFBLK;
const	S_IFREG=		_IFREG;
const	S_IFLNK=		_IFLNK;
const	S_IFSOCK=	_IFSOCK;
const	S_IFIFO=		_IFIFO;

const		S_IRUSR=	0000400;	/* read permission, owner */
const		S_IWUSR=	0000200;	/* write permission, owner */
const		S_IXUSR=	0000100;	/* execute/search permission, owner */
const	S_IRWXU= 	(S_IRUSR | S_IWUSR | S_IXUSR);
const		S_IRGRP=	0000040;	/* read permission, group */
const		S_IWGRP=	0000020;	/* write permission, grougroup */
const		S_IXGRP=	0000010;	/* execute/search permission, group */
const	S_IRWXG=		(S_IRGRP | S_IWGRP | S_IXGRP);
const		S_IROTH=	0000004;	/* read permission, other */
const		S_IWOTH=	0000002;	/* write permission, other */
const		S_IXOTH=	0000001;	/* execute/search permission, other */
const	S_IRWXO=		(S_IROTH | S_IWOTH | S_IXOTH);

struct SftpName {
   _str filename;
   _str longname;
   SftpAttrs attrs;
};

struct SftpDirectory {
   int flags;
   SftpName names[];
};
